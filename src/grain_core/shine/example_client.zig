//! Grain Shine Protocol Example Client
//!
//! Why: Example implementation showing how to use Grain Shine protocol.
//! Demonstrates client connection, surface creation, and basic operations
//! with proper error handling and resource cleanup.

const std = @import("std");
const protocol = @import("protocol.zig");
const registry = @import("registry.zig");
const compositor_iface = @import("compositor.zig");
const compositor_core = @import("compositor_core.zig");

/// Why: Example client implementation for Grain Shine protocol.
/// Shows basic usage patterns and proper resource management.
pub const ExampleClient = struct {
    const Self = @This();
    
    allocator: std.mem.Allocator,
    compositor: *compositor_core.CompositorCore,
    client_id: u32,
    display_id: u32,
    registry_id: ?u32,
    compositor_id: ?u32,
    surface_id: ?u32,
    
    /// Why: Initialize example client with compositor connection.
    pub fn init(allocator: std.mem.Allocator, compositor: *compositor_core.CompositorCore) !Self {
        const client_id = try compositor.addClient();
        
        return Self{
            .allocator = allocator,
            .compositor = compositor,
            .client_id = client_id,
            .display_id = 1, // Display is always object ID 1
            .registry_id = null,
            .compositor_id = null,
            .surface_id = null,
        };
    }
    
    /// Why: Cleanup client resources.
    pub fn deinit(self: *Self) void {
        _ = self.compositor.removeClient(self.client_id);
    }
    
    /// Why: Connect to display and get registry.
    /// Demonstrates basic protocol handshake.
    pub fn connect(self: *Self) !void {
        std.debug.print("Connecting to Grain Shine display...\n", .{});
        
        // Why: Send get_registry request to display.
        const registry_id: u32 = 2;
        var get_registry_msg = [_]u8{
            0x01, 0x00, 0x00, 0x00, // object_id: 1 (display)
            0x0C, 0x00, 0x01, 0x00, // size: 12, opcode: 1 (get_registry)
            0x02, 0x00, 0x00, 0x00, // new registry object_id: 2
        };
        
        const result = try self.compositor.processMessage(self.client_id, &get_registry_msg);
        if (!result.processed) {
            return error.RegistryRequestFailed;
        }
        
        self.registry_id = registry_id;
        std.debug.print("Registry obtained (ID: {})\n", .{registry_id});
    }
    
    /// Why: Bind to compositor interface.
    /// Shows how clients bind to global interfaces.
    pub fn bindCompositor(self: *Self) !void {
        if (self.registry_id == null) {
            return error.RegistryNotAvailable;
        }
        
        std.debug.print("Binding to compositor interface...\n", .{});
        
        // Why: Create bind message for compositor.
        const compositor_id: u32 = 3;
        const interface_str = "shine_compositor";
        const interface_len = interface_str.len;
        const aligned_len = (interface_len + 3) & ~@as(u32, 3);
        
        var bind_msg = std.ArrayList(u8).init(self.allocator);
        defer bind_msg.deinit();
        
        // Header
        try bind_msg.appendSlice(&[_]u8{
            0x02, 0x00, 0x00, 0x00, // object_id: 2 (registry)
            0x00, 0x00, 0x00, 0x00, // size (placeholder), opcode: 0 (bind)
        });
        
        // Arguments
        try bind_msg.appendSlice(&[_]u8{ 0x01, 0x00, 0x00, 0x00 }); // name: 1
        
        // Interface string length
        try bind_msg.appendSlice(&std.mem.toBytes(@as(u32, @intCast(interface_len))));
        
        // Interface string data
        try bind_msg.appendSlice(interface_str);
        
        // Padding
        while (bind_msg.items.len & 3 != 0) {
            try bind_msg.append(0);
        }
        
        // Version and new object ID
        try bind_msg.appendSlice(&[_]u8{ 0x04, 0x00, 0x00, 0x00 }); // version: 4
        try bind_msg.appendSlice(&[_]u8{ 0x03, 0x00, 0x00, 0x00 }); // new_id: 3
        
        // Fix message size in header
        const total_size = bind_msg.items.len;
        std.mem.writeInt(u16, bind_msg.items[4..6], @intCast(total_size), .little);
        
        const result = try self.compositor.processMessage(self.client_id, bind_msg.items);
        if (!result.processed) {
            return error.CompositorBindFailed;
        }
        
        self.compositor_id = compositor_id;
        std.debug.print("Compositor bound (ID: {})\n", .{compositor_id});
    }
    
    /// Why: Create surface for rendering.
    /// Demonstrates surface creation and basic setup.
    pub fn createSurface(self: *Self) !void {
        if (self.compositor_id == null) {
            return error.CompositorNotBound;
        }
        
        std.debug.print("Creating surface...\n", .{});
        
        // Why: Send create_surface request to compositor.
        const surface_id: u32 = 4;
        var create_surface_msg = [_]u8{
            0x03, 0x00, 0x00, 0x00, // object_id: 3 (compositor)
            0x0C, 0x00, 0x00, 0x00, // size: 12, opcode: 0 (create_surface)
            0x04, 0x00, 0x00, 0x00, // new surface object_id: 4
        };
        
        const result = try self.compositor.processMessage(self.client_id, &create_surface_msg);
        if (!result.processed) {
            return error.SurfaceCreationFailed;
        }
        
        self.surface_id = surface_id;
        std.debug.print("Surface created (ID: {})\n", .{surface_id});
    }
    
    /// Why: Perform basic surface operations.
    /// Shows damage tracking, frame callbacks, and commit.
    pub fn performSurfaceOperations(self: *Self) !void {
        if (self.surface_id == null) {
            return error.SurfaceNotCreated;
        }
        
        std.debug.print("Performing surface operations...\n", .{});
        
        const surface_id = self.surface_id.?;
        
        // Why: Add damage to surface.
        var damage_msg = [_]u8{
            0x04, 0x00, 0x00, 0x00, // object_id: 4 (surface)
            0x18, 0x00, 0x02, 0x00, // size: 24, opcode: 2 (damage)
            0x00, 0x00, 0x00, 0x00, // x: 0
            0x00, 0x00, 0x00, 0x00, // y: 0
            0x00, 0x05, 0x00, 0x00, // width: 1280
            0xD0, 0x02, 0x00, 0x00, // height: 720
        };
        
        var result = try self.compositor.processMessage(self.client_id, &damage_msg);
        if (!result.processed) {
            return error.DamageFailed;
        }
        std.debug.print("Damage added to surface\n", .{});
        
        // Why: Request frame callback.
        var frame_msg = [_]u8{
            0x04, 0x00, 0x00, 0x00, // object_id: 4 (surface)
            0x0C, 0x00, 0x03, 0x00, // size: 12, opcode: 3 (frame)
            0x05, 0x00, 0x00, 0x00, // callback object_id: 5
        };
        
        result = try self.compositor.processMessage(self.client_id, &frame_msg);
        if (!result.processed) {
            return error.FrameCallbackFailed;
        }
        std.debug.print("Frame callback requested\n", .{});
        
        // Why: Commit surface state.
        var commit_msg = [_]u8{
            0x04, 0x00, 0x00, 0x00, // object_id: 4 (surface)
            0x08, 0x00, 0x06, 0x00, // size: 8, opcode: 6 (commit)
        };
        
        result = try self.compositor.processMessage(self.client_id, &commit_msg);
        if (!result.processed) {
            return error.CommitFailed;
        }
        std.debug.print("Surface committed\n", .{});
    }
    
    /// Why: Run complete client example.
    /// Demonstrates full client lifecycle and basic operations.
    pub fn runExample(self: *Self) !void {
        std.debug.print("=== Grain Shine Client Example ===\n", .{});
        
        try self.connect();
        try self.bindCompositor();
        try self.createSurface();
        try self.performSurfaceOperations();
        
        std.debug.print("Example completed successfully!\n", .{});
    }
};

/// Why: Run example client demonstration.
/// Shows complete usage of Grain Shine protocol from client perspective.
pub fn runExampleClient(allocator: std.mem.Allocator) !void {
    std.debug.print("Starting Grain Shine Example Client...\n", .{});
    
    // Why: Initialize compositor.
    var compositor = try compositor_core.CompositorCore.init(allocator);
    defer compositor.deinit();
    
    // Why: Add test output to compositor.
    try compositor.addOutput(0, 0, 300, 200, "Example Monitor", "Test Display");
    
    // Why: Initialize and run example client.
    var client = try ExampleClient.init(allocator, &compositor);
    defer client.deinit();
    
    try client.runExample();
    
    // Why: Display compositor statistics.
    const stats = compositor.getStats();
    std.debug.print("\nCompositor Statistics:\n", .{});
    std.debug.print("  Clients: {}\n", .{stats.clients});
    std.debug.print("  Outputs: {}\n", .{stats.outputs});
    std.debug.print("  Total Objects: {}\n", .{stats.total_objects});
}