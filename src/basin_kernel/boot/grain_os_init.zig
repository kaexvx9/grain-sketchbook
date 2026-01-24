//! Basin Kernel: Grain OS System Initialization
//!
//! Why: Complete system boot sequence integrating kernel, memory, display, and compositor.
//! Coordinates all subsystems for complete Grain OS startup.
//!
//! Agents: All (Vantage 3, Reya, Core 1, Glow coordination)

const std = @import("std");
const memory = @import("../memory/unified_allocator.zig");
const display = @import("../display/shine_bridge.zig");

const UnifiedMemoryManager = memory.UnifiedMemoryManager;
const ShineBridge = display.ShineBridge;

/// Why: Complete Grain OS initialization sequence.
/// Boots kernel, initializes memory, sets up display, and starts compositor.
pub const GrainOSInit = struct {
    const Self = @This();
    
    allocator: std.mem.Allocator,
    memory_manager: ?UnifiedMemoryManager,
    display_bridge: ?ShineBridge,
    initialized: bool,
    
    /// Why: Initialize complete Grain OS system.
    pub fn init(allocator: std.mem.Allocator) !Self {
        std.debug.print("=== Grain OS Initialization ===\n", .{});
        
        var system = Self{
            .allocator = allocator,
            .memory_manager = null,
            .display_bridge = null,
            .initialized = false,
        };
        
        // Why: Step 1 - Initialize unified memory management (Reya's architecture).
        std.debug.print("Step 1: Initializing memory management...\n", .{});
        system.memory_manager = try memory.initializeSystemMemory(allocator);
        std.debug.print("  Memory management ready\n", .{});
        
        // Why: Step 2 - Initialize display subsystem (Vantage 3's implementation).
        std.debug.print("Step 2: Initializing display subsystem...\n", .{});
        system.display_bridge = try display.initializeDisplaySubsystem(allocator);
        std.debug.print("  Display subsystem ready\n", .{});
        
        // Why: Step 3 - System ready for application launch.
        std.debug.print("Step 3: System ready for applications\n", .{});
        system.initialized = true;
        
        std.debug.print("=== Grain OS Initialization Complete ===\n", .{});
        
        return system;
    }
    
    /// Why: Cleanup system resources.
    pub fn deinit(self: *Self) void {
        if (self.display_bridge) |*bridge| {
            bridge.deinit();
        }
        if (self.memory_manager) |*mem| {
            mem.deinit();
        }
    }
    
    /// Why: Check if system is fully initialized.
    pub fn isReady(self: *const Self) bool {
        return self.initialized and 
               if (self.display_bridge) |*bridge| bridge.isReady() else false;
    }
    
    /// Why: Get system status for monitoring.
    pub fn getStatus(self: *const Self) struct {
        memory_stats: memory.UnifiedMemoryManager.MemoryUsageStats,
        display_ready: bool,
    } {
        return .{
            .memory_stats = if (self.memory_manager) |*mem| mem.getStats() else std.mem.zeroes(memory.UnifiedMemoryManager.MemoryUsageStats),
            .display_ready = if (self.display_bridge) |*bridge| bridge.isReady() else false,
        };
    }
};

/// Why: Main Grain OS boot entry point.
/// Initializes complete system and returns ready state.
pub fn bootGrainOS(allocator: std.mem.Allocator) !GrainOSInit {
    return GrainOSInit.init(allocator);
}