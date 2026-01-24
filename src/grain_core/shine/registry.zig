//! Grain Shine Registry Interface
//! 
//! Why: Handles global object registry for Shine protocol.
//! The registry advertises available global interfaces and allows clients
//! to bind to them with proper bounds checking and Rye Style compliance.

const std = @import("std");
const protocol = @import("protocol.zig");
const ObjectId = protocol.ObjectId;
const ArgumentParser = protocol.ArgumentParser;

/// Why: Registry interface for advertising and binding global objects.
/// Maintains bounds-checked list of global interfaces with versioning.
pub const RegistryInterface = struct {
    pub const BIND_OPCODE: u16 = 0;
    
    /// Why: Bind request - client binds to a global interface.
    pub const BindRequest = struct {
        name: u32,          // Global name
        interface: []const u8,  // Interface name string
        version: u32,       // Requested version
        id: ObjectId,       // New object ID
        
        /// Why: Parse bind request from message data with bounds checking.
        pub fn parse(parser: *ArgumentParser) !BindRequest {
            const name = try parser.parseUint();
            const interface = try parser.parseString();
            const version = try parser.parseUint(); 
            const id = try parser.parseObjectId();
            
            // Why: Validate interface name length against bounds.
            if (interface.len == 0) return error.EmptyInterfaceName;
            if (interface.len > 64) return error.InterfaceNameTooLong; // Reasonable limit
            
            return BindRequest{
                .name = name,
                .interface = interface,
                .version = version,
                .id = id,
            };
        }
    };
    
    /// Why: Global event - advertise a global interface to clients.
    pub const GlobalEvent = struct {
        name: u32,
        interface: []const u8,
        version: u32,
        
        /// Why: Serialize global event to wire format with bounds checking.
        pub fn serialize(self: GlobalEvent, buffer: []u8) !u32 {
            // Why: Calculate required buffer size with alignment.
            const interface_len = self.interface.len;
            const aligned_interface_len = (interface_len + 3) & ~@as(u32, 3);
            const total_size = 4 + 4 + 4 + aligned_interface_len; // name + interface_len + version + interface
            
            if (buffer.len < total_size) return error.BufferTooSmall;
            
            var offset: u32 = 0;
            
            // Global name
            std.mem.writeInt(u32, buffer[offset..offset + 4], self.name, .little);
            offset += 4;
            
            // Interface string length
            std.mem.writeInt(u32, buffer[offset..offset + 4], @intCast(interface_len), .little);
            offset += 4;
            
            // Interface string data
            @memcpy(buffer[offset..offset + interface_len], self.interface);
            offset += @intCast(interface_len);
            
            // Align to 32-bit boundary
            while (offset & 3 != 0) {
                buffer[offset] = 0;
                offset += 1;
            }
            
            // Version
            std.mem.writeInt(u32, buffer[offset..offset + 4], self.version, .little);
            offset += 4;
            
            return offset;
        }
    };
    
    /// Why: Global remove event - remove a global interface.
    pub const GlobalRemoveEvent = struct {
        name: u32,
        
        /// Why: Serialize global remove event to wire format.
        pub fn serialize(self: GlobalRemoveEvent, buffer: []u8) !u32 {
            if (buffer.len < 4) return error.BufferTooSmall;
            
            std.mem.writeInt(u32, buffer[0..4], self.name, .little);
            return 4;
        }
    };
};

/// Why: Registry implementation for managing global objects.
/// Maintains list of available global interfaces with proper lifecycle management.
pub const Registry = struct {
    const Self = @This();
    
    /// Why: Maximum number of global interfaces to prevent unbounded growth.
    const MAX_GLOBALS: u32 = 256;
    
    /// Why: Global interface entry with name, interface, and version.
    pub const Global = struct {
        name: u32,
        interface: []const u8,
        version: u32,
        active: bool,
    };
    
    globals: std.ArrayList(Global),
    next_name: u32,
    
    /// Why: Initialize registry with proper allocator.
    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .globals = std.ArrayList(Global).init(allocator),
            .next_name = 1, // Start from 1 (0 is reserved)
        };
    }
    
    /// Why: Cleanup registry and free all allocated memory.
    pub fn deinit(self: *Self) void {
        self.globals.deinit();
    }
    
    /// Why: Add a global interface with bounds checking.
    /// Returns the assigned global name or error if bounds exceeded.
    pub fn addGlobal(self: *Self, interface: []const u8, version: u32) !u32 {
        if (self.globals.items.len >= MAX_GLOBALS) {
            return error.TooManyGlobals;
        }
        
        if (interface.len == 0) return error.EmptyInterfaceName;
        if (interface.len > 64) return error.InterfaceNameTooLong;
        
        const name = self.next_name;
        self.next_name += 1;
        
        try self.globals.append(Global{
            .name = name,
            .interface = interface,
            .version = version,
            .active = true,
        });
        
        return name;
    }
    
    /// Why: Remove a global interface by name.
    /// Returns true if found and removed, false otherwise.
    pub fn removeGlobal(self: *Self, name: u32) bool {
        for (self.globals.items, 0..) |*global, i| {
            if (global.name == name and global.active) {
                global.active = false;
                return true;
            }
        }
        return false;
    }
    
    /// Why: Find a global interface by name for binding.
    /// Returns the global entry or null if not found.
    pub fn findGlobal(self: *const Self, name: u32) ?Global {
        for (self.globals.items) |global| {
            if (global.name == name and global.active) {
                return global;
            }
        }
        return null;
    }
    
    /// Why: Serialize all active globals to buffer for client advertisement.
    /// Returns total bytes written to buffer.
    pub fn serializeGlobals(self: *const Self, buffer: []u8) !u32 {
        var offset: u32 = 0;
        
        for (self.globals.items) |global| {
            if (!global.active) continue;
            
            const event = RegistryInterface.GlobalEvent{
                .name = global.name,
                .interface = global.interface,
                .version = global.version,
            };
            
            const bytes_written = try event.serialize(buffer[offset..]);
            offset += bytes_written;
        }
        
        return offset;
    }
};