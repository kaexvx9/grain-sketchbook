//! Grain Shine Compositor Core
//!
//! Why: Core compositor implementation for Shine protocol.
//! Manages clients, event processing, and basic composition with
//! proper bounds checking and resource management.

const std = @import("std");
const protocol = @import("protocol.zig");
const registry_mod = @import("registry.zig");
const client_mod = @import("client.zig");
const compositor_iface = @import("compositor.zig");
const output_mod = @import("output.zig");

const ObjectId = protocol.ObjectId;
const MessageHeader = protocol.MessageHeader;
const ArgumentParser = protocol.ArgumentParser;
const MessageResult = protocol.MessageResult;
const MAX_CLIENTS = protocol.MAX_CLIENTS;
const Registry = registry_mod.Registry;
const Client = client_mod.Client;
const CompositorInterface = compositor_iface.CompositorInterface;
const SurfaceInterface = compositor_iface.SurfaceInterface;
const Output = output_mod.Output;

/// Why: Core compositor state and functionality.
/// Manages all clients, global registry, and basic event processing.
pub const CompositorCore = struct {
    const Self = @This();
    
    allocator: std.mem.Allocator,
    clients: std.ArrayList(Client),
    global_registry: Registry,
    outputs: std.ArrayList(Output),
    next_client_id: u32,
    running: bool,
    
    /// Why: Initialize compositor with proper allocator and global setup.
    pub fn init(allocator: std.mem.Allocator) !Self {
        var compositor = Self{
            .allocator = allocator,
            .clients = std.ArrayList(Client).init(allocator),
            .global_registry = Registry.init(allocator),
            .outputs = std.ArrayList(Output).init(allocator),
            .next_client_id = 1,
            .running = false,
        };
        
        // Why: Add core global interfaces to registry.
        try compositor.setupGlobalInterfaces();
        
        return compositor;
    }
    
    /// Why: Cleanup compositor and all resources.
    pub fn deinit(self: *Self) void {
        // Why: Disconnect all clients first.
        for (self.clients.items) |*client| {
            client.deinit();
        }
        self.clients.deinit();
        
        // Why: Clean up outputs.
        for (self.outputs.items) |*output| {
            output.deinit();
        }
        self.outputs.deinit();
        
        self.global_registry.deinit();
    }
    
    /// Why: Setup core global interfaces in registry.
    fn setupGlobalInterfaces(self: *Self) !void {
        _ = try self.global_registry.addGlobal("shine_compositor", 4);
        _ = try self.global_registry.addGlobal("shine_output", 3);
        _ = try self.global_registry.addGlobal("shine_seat", 7);
    }
    
    /// Why: Add client connection with bounds checking.
    pub fn addClient(self: *Self) !u32 {
        if (self.clients.items.len >= MAX_CLIENTS) {
            return error.TooManyClients;
        }
        
        const client_id = self.next_client_id;
        self.next_client_id += 1;
        
        var client = Client.init(self.allocator, client_id);
        
        // Why: Add display object for new client (always object ID 1).
        _ = try client.addObject(.display, "shine_display", 1);
        
        try self.clients.append(client);
        return client_id;
    }
    
    /// Why: Remove client and cleanup resources.
    pub fn removeClient(self: *Self, client_id: u32) bool {
        for (self.clients.items, 0..) |*client, i| {
            if (client.id == client_id) {
                client.deinit();
                _ = self.clients.swapRemove(i);
                return true;
            }
        }
        return false;
    }
    
    /// Why: Find client by ID for message processing.
    pub fn findClient(self: *Self, client_id: u32) ?*Client {
        for (self.clients.items) |*client| {
            if (client.id == client_id) {
                return client;
            }
        }
        return null;
    }
    
    /// Why: Add output device with validation.
    pub fn addOutput(
        self: *Self,
        x: i32,
        y: i32,
        physical_width: i32,
        physical_height: i32,
        make: []const u8,
        model: []const u8,
    ) !void {
        if (self.outputs.items.len >= 16) { // Reasonable output limit
            return error.TooManyOutputs;
        }
        
        const output_id: ObjectId = @intCast(self.outputs.items.len + 100); // Offset to avoid conflicts
        var output = try Output.init(
            self.allocator,
            output_id,
            x,
            y,
            physical_width,
            physical_height,
            make,
            model,
        );
        
        // Why: Add common display modes.
        try output.addMode(0x1, 1920, 1080, 60000); // 60Hz
        try output.addMode(0x2, 1920, 1080, 144000); // 144Hz
        try output.setCurrentMode(0);
        
        try self.outputs.append(output);
    }
    
    /// Why: Process incoming message from client.
    pub fn processMessage(self: *Self, client_id: u32, data: []const u8) !MessageResult {
        // Why: Find client for message processing.
        const client = self.findClient(client_id) orelse {
            return MessageResult.error_result(0, 0, 1); // No such client
        };
        
        if (!client.isActive()) {
            return MessageResult.error_result(0, 0, 2); // Client not active
        }
        
        // Why: Parse message header with bounds checking.
        const header = MessageHeader.parse(data) catch |err| {
            return switch (err) {
                error.InvalidMessage => MessageResult.error_result(0, 0, 3),
                error.MessageTooLarge => MessageResult.error_result(0, 0, 4),
                error.MessageTooSmall => MessageResult.error_result(0, 0, 5),
                else => MessageResult.error_result(0, 0, 6),
            };
        };
        
        try header.validate();
        
        // Why: Initialize argument parser for message data.
        var parser = ArgumentParser.init(data, 8); // Skip header
        
        // Why: Dispatch message based on object and opcode.
        return try self.dispatchMessage(client, header.object_id, header.opcode, &parser);
    }
    
    /// Why: Dispatch message to appropriate handler.
    fn dispatchMessage(
        self: *Self,
        client: *Client,
        object_id: ObjectId,
        opcode: u16,
        parser: *ArgumentParser,
    ) !MessageResult {
        // Why: Find object to determine interface.
        const obj = client.findObject(object_id) orelse {
            return MessageResult.error_result(object_id, opcode, 10); // No such object
        };
        
        // Why: Dispatch based on object type.
        return switch (obj.object_type) {
            .display => try self.handleDisplayRequest(client, object_id, opcode, parser),
            .registry => try self.handleRegistryRequest(client, object_id, opcode, parser),
            .compositor => try self.handleCompositorRequest(client, object_id, opcode, parser),
            .surface => try self.handleSurfaceRequest(client, object_id, opcode, parser),
            else => MessageResult.error_result(object_id, opcode, 11), // Unsupported object type
        };
    }
    
    /// Why: Handle display interface requests.
    fn handleDisplayRequest(
        self: *Self,
        client: *Client,
        object_id: ObjectId,
        opcode: u16,
        parser: *ArgumentParser,
    ) !MessageResult {
        _ = self;
        
        switch (opcode) {
            0 => { // sync
                _ = try parser.parseObjectId(); // callback
                return MessageResult.success(object_id, opcode);
            },
            1 => { // get_registry
                const registry_id = try parser.parseObjectId();
                _ = try client.addObject(.registry, "shine_registry", 1);
                return MessageResult.success(object_id, opcode);
            },
            else => return MessageResult.error_result(object_id, opcode, 20), // Unknown opcode
        }
    }
    
    /// Why: Handle registry interface requests.
    fn handleRegistryRequest(
        self: *Self,
        client: *Client,
        object_id: ObjectId,
        opcode: u16,
        parser: *ArgumentParser,
    ) !MessageResult {
        switch (opcode) {
            0 => { // bind
                const name = try parser.parseUint();
                const interface = try parser.parseString();
                const version = try parser.parseUint();
                const new_id = try parser.parseObjectId();
                
                // Why: Find global interface in registry.
                const global = self.global_registry.findGlobal(name) orelse {
                    return MessageResult.error_result(object_id, opcode, 30); // No such global
                };
                
                // Why: Add object based on interface type.
                const object_type: client_mod.ObjectType = if (std.mem.eql(u8, interface, "shine_compositor"))
                    .compositor
                else if (std.mem.eql(u8, interface, "shine_output"))
                    .output
                else if (std.mem.eql(u8, interface, "shine_seat"))
                    .seat
                else
                    .unknown;
                
                _ = try client.addObject(object_type, interface, version);
                return MessageResult.success(object_id, opcode);
            },
            else => return MessageResult.error_result(object_id, opcode, 21), // Unknown opcode
        }
    }
    
    /// Why: Handle compositor interface requests.
    fn handleCompositorRequest(
        self: *Self,
        client: *Client,
        object_id: ObjectId,
        opcode: u16,
        parser: *ArgumentParser,
    ) !MessageResult {
        _ = self;
        
        switch (opcode) {
            0 => { // create_surface
                const surface_id = try parser.parseObjectId();
                _ = try client.addObject(.surface, "shine_surface", 4);
                try client.addSurface(surface_id);
                return MessageResult.success(object_id, opcode);
            },
            1 => { // create_region
                const region_id = try parser.parseObjectId();
                _ = try client.addObject(.region, "shine_region", 1);
                return MessageResult.success(object_id, opcode);
            },
            else => return MessageResult.error_result(object_id, opcode, 22), // Unknown opcode
        }
    }
    
    /// Why: Handle surface interface requests.
    fn handleSurfaceRequest(
        self: *Self,
        client: *Client,
        object_id: ObjectId,
        opcode: u16,
        parser: *ArgumentParser,
    ) !MessageResult {
        _ = self;
        
        // Why: Find surface for request processing.
        const surface = client.findSurface(object_id) orelse {
            return MessageResult.error_result(object_id, opcode, 40); // No such surface
        };
        
        switch (opcode) {
            1 => { // attach
                const buffer = try parser.parseObjectId();
                const x = try parser.parseInt();
                const y = try parser.parseInt();
                try surface.attach(if (buffer == 0) null else buffer, x, y);
                return MessageResult.success(object_id, opcode);
            },
            2 => { // damage
                const x = try parser.parseInt();
                const y = try parser.parseInt();
                const width = try parser.parseInt();
                const height = try parser.parseInt();
                try surface.addDamage(x, y, width, height);
                return MessageResult.success(object_id, opcode);
            },
            3 => { // frame
                const callback = try parser.parseObjectId();
                try surface.addFrameCallback(callback);
                return MessageResult.success(object_id, opcode);
            },
            6 => { // commit
                surface.commit();
                return MessageResult.success(object_id, opcode);
            },
            else => return MessageResult.success(object_id, opcode), // Ignore unknown opcodes for now
        }
    }
    
    /// Why: Start compositor event loop.
    pub fn start(self: *Self) void {
        self.running = true;
    }
    
    /// Why: Stop compositor event loop.
    pub fn stop(self: *Self) void {
        self.running = false;
    }
    
    /// Why: Check if compositor is running.
    pub fn isRunning(self: *const Self) bool {
        return self.running;
    }
    
    /// Why: Get statistics for monitoring.
    pub fn getStats(self: *const Self) struct { clients: u32, outputs: u32, total_objects: u32 } {
        var total_objects: u32 = 0;
        for (self.clients.items) |*client| {
            total_objects += client.getObjectCount();
        }
        
        return .{
            .clients = @intCast(self.clients.items.len),
            .outputs = @intCast(self.outputs.items.len),
            .total_objects = total_objects,
        };
    }
};