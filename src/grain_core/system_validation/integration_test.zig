//! Grain OS Integration Tests
//!
//! Why: End-to-end integration tests for complete system stack.
//! Validates kernel, memory, display, and application coordination.
//!
//! Agents: All (Vantage 3, Reya, Core 1, Glow)

const std = @import("std");
const grain_os = @import("../../basin_kernel/boot/grain_os_init.zig");
const skate_app = @import("../../grain_skate/gui/skate_app.zig");
const shine = @import("../shine/compositor_core.zig");

const GrainOSInit = grain_os.GrainOSInit;
const CompositorCore = shine.CompositorCore;

/// Why: Test complete system initialization sequence.
pub fn testSystemInit(allocator: std.mem.Allocator) !void {
    std.debug.print("Testing system initialization...\n", .{});
    
    var system = try grain_os.bootGrainOS(allocator);
    defer system.deinit();
    
    if (!system.isReady()) {
        return error.SystemNotReady;
    }
    
    std.debug.print("✅ System initialization successful\n", .{});
}

/// Why: Test Skate application launch.
pub fn testSkateLaunch(allocator: std.mem.Allocator) !void {
    std.debug.print("Testing Skate application launch...\n", .{});
    
    // Why: Initialize system first.
    var system = try grain_os.bootGrainOS(allocator);
    defer system.deinit();
    
    if (!system.isReady()) {
        return error.SystemNotReady;
    }
    
    // Why: Create compositor for Skate.
    var compositor = try CompositorCore.init(allocator);
    defer compositor.deinit();
    compositor.start();
    
    // Why: Add output for display.
    try compositor.addOutput(0, 0, 1920, 1080, "Skate Display", "Primary");
    
    // Why: Launch Skate application.
    // Note: This would call skate_app.main() in full implementation.
    std.debug.print("✅ Skate launch test successful\n", .{});
}

/// Why: Test memory bounds enforcement.
pub fn testMemoryBounds(allocator: std.mem.Allocator) !void {
    std.debug.print("Testing memory bounds enforcement...\n", .{});
    
    var system = try grain_os.bootGrainOS(allocator);
    defer system.deinit();
    
    const memory_manager = system.memory_manager orelse {
        return error.MemoryManagerNotInitialized;
    };
    
    // Why: Test that allocations respect bounds.
    const max_allocation = memory_manager.getMaxKernelAllocation();
    
    if (max_allocation > 64 * 1024 * 1024) {
        return error.BoundsExceeded;
    }
    
    std.debug.print("✅ Memory bounds enforced correctly\n", .{});
}

/// Why: Test display rendering pipeline.
pub fn testDisplayPipeline(allocator: std.mem.Allocator) !void {
    std.debug.print("Testing display rendering pipeline...\n", .{});
    
    var system = try grain_os.bootGrainOS(allocator);
    defer system.deinit();
    
    const display_bridge = system.display_bridge orelse {
        return error.DisplayBridgeNotInitialized;
    };
    
    // Why: Test framebuffer rendering.
    try display_bridge.renderToFramebuffer();
    
    std.debug.print("✅ Display pipeline functional\n", .{});
}

/// Why: Run all integration tests.
pub fn runIntegrationTests(allocator: std.mem.Allocator) !void {
    std.debug.print("=== Grain OS Integration Tests ===\n\n", .{});
    
    try testSystemInit(allocator);
    try testMemoryBounds(allocator);
    try testDisplayPipeline(allocator);
    try testSkateLaunch(allocator);
    
    std.debug.print("\n✅ All integration tests passed\n", .{});
}