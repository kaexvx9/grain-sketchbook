//! Basin Kernel: Grain Shine Protocol Bridge
//!
//! Why: Connects Grain Shine compositor to kernel framebuffer.
//! Provides secure kernel-userspace communication for display operations.
//!
//! Agent: Vantage 3 (Systems Implementation) + Reya (Architecture)

const std = @import("std");
const framebuffer = @import("framebuffer.zig");
const shine = @import("../../grain_core/shine/compositor_core.zig");

const Framebuffer = framebuffer.Framebuffer;
const CompositorCore = shine.CompositorCore;

/// Why: Kernel-compositor bridge for display operations.
/// Manages secure communication between kernel framebuffer and userspace compositor.
pub const ShineBridge = struct {
    const Self = @This();
    
    fb: Framebuffer,
    compositor: *CompositorCore,
    allocator: std.mem.Allocator,
    
    /// Why: Maximum number of pending display operations.
    pub const MAX_PENDING_OPS: u32 = 64;
    
    pending_operations: std.ArrayList(DisplayOperation),
    
    /// Why: Display operation types for kernel compositor coordination.
    pub const DisplayOperation = enum {
        clear_screen,
        draw_surface,
        update_region,
        flip_buffer,
    };
    
    /// Why: Initialize bridge with framebuffer and compositor.
    pub fn init(allocator: std.mem.Allocator, fb: Framebuffer, compositor: *CompositorCore) !Self {
        return Self{
            .fb = fb,
            .compositor = compositor,
            .allocator = allocator,
            .pending_operations = std.ArrayList(DisplayOperation).init(allocator),
        };
    }
    
    /// Why: Cleanup bridge resources.
    pub fn deinit(self: *Self) void {
        self.pending_operations.deinit();
    }
    
    /// Why: Process compositor output to framebuffer.
    /// Renders composited surfaces to physical display.
    pub fn renderToFramebuffer(self: *Self) !void {
        if (!self.fb.isReady()) {
            return error.FramebufferNotReady;
        }
        
        // Why: Clear framebuffer to black background.
        try self.fb.clear(0xFF000000); // Black with full alpha
        
        // Why: Get compositor statistics for validation.
        const stats = self.compositor.getStats();
        if (stats.clients == 0) {
            return; // No clients to render
        }
        
        // Why: In full implementation, this would iterate through compositor surfaces
        // and render them to framebuffer with proper z-ordering and damage regions.
        // For now, this is the integration point structure.
        
        // TODO: Implement surface rendering pipeline
        // - Get all active surfaces from compositor
        // - Sort by z-order
        // - Render each surface to framebuffer
        // - Handle damage regions efficiently
    }
    
    /// Why: Handle display refresh request from compositor.
    pub fn handleRefresh(self: *Self) !void {
        try self.renderToFramebuffer();
    }
    
    /// Why: Check if bridge is ready for operations.
    pub fn isReady(self: *const Self) bool {
        return self.fb.isReady() and self.compositor.isRunning();
    }
};

/// Why: Initialize complete display subsystem.
/// Sets up framebuffer, compositor, and bridge for kernel display operations.
pub fn initializeDisplaySubsystem(allocator: std.mem.Allocator) !ShineBridge {
    std.debug.print("Initializing Basin display subsystem...\n", .{});
    
    // Why: Initialize QEMU framebuffer.
    const fb = try framebuffer.initializeQEMUFramebuffer();
    std.debug.print("Framebuffer initialized: {}x{}\n", .{ fb.config.width, fb.config.height });
    
    // Why: Initialize Grain Shine compositor.
    var compositor = try CompositorCore.init(allocator);
    compositor.start();
    
    // Why: Add default output to compositor.
    try compositor.addOutput(0, 0, 300, 200, "Basin Display", "QEMU RISC-V");
    
    // Why: Create bridge connecting kernel and compositor.
    var bridge = try ShineBridge.init(allocator, fb, &compositor);
    
    std.debug.print("Display subsystem ready\n", .{});
    return bridge;
}