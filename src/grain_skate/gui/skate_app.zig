//! Skate: Main Application Entry Point
//!
//! Why: Application entry point coordinating Skate editor with Grain Shine compositor.
//! Initializes system, creates window, and starts main event loop.
//!
//! Agents: All (Vantage 3, Core 1, Reya, Glow coordination)

const std = @import("std");
const skate_window = @import("skate_main_window.zig");
const shine_compositor = @import("../../grain_core/shine/compositor_core.zig");
const grain_os = @import("../../basin_kernel/boot/grain_os_init.zig");

const SkateMainWindow = skate_window.SkateMainWindow;
const CompositorCore = shine_compositor.CompositorCore;
const GrainOSInit = grain_os.GrainOSInit;

/// Why: Main Skate application entry point.
/// Initializes Grain OS, starts compositor, and launches Skate editor.
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    std.debug.print("=== Skate Application Starting ===\n", .{});
    
    // Why: Initialize Grain OS system (kernel, memory, display).
    var grain_os_system = try grain_os.bootGrainOS(allocator);
    defer grain_os_system.deinit();
    
    if (!grain_os_system.isReady()) {
        std.debug.print("ERROR: Grain OS system not ready\n", .{});
        return error.SystemNotReady;
    }
    
    // Why: Get compositor from display bridge.
    // In real implementation, this would be retrieved from GrainOSInit.
    var compositor = try CompositorCore.init(allocator);
    defer compositor.deinit();
    compositor.start();
    
    // Why: Add default output for display.
    try compositor.addOutput(0, 0, 300, 200, "Skate Display", "Primary Output");
    
    // Why: Create and initialize Skate main window.
    var window = try SkateMainWindow.init(allocator, &compositor);
    defer window.deinit();
    
    // Why: Create editor panel in window.
    try window.createEditor();
    std.debug.print("Skate editor initialized\n", .{});
    
    // Why: Initial render to display.
    try window.render();
    std.debug.print("Initial render complete\n", .{});
    
    std.debug.print("=== Skate Application Ready ===\n", .{});
    std.debug.print("Main event loop would start here\n", .{});
    
    // Why: In full implementation, main event loop would process:
    // - Keyboard/mouse input from Grain Shine seat interface
    // - Window events and surface updates
    // - File operations and editor commands
    // - Display refresh and composition
}

/// Why: Run Skate application with proper error handling.
pub fn runSkate() void {
    main() catch |err| {
        std.debug.print("Skate application error: {}\n", .{err});
        std.process.exit(1);
    };
}