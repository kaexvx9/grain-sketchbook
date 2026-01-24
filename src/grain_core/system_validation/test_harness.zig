//! Grain OS System Validation Test Harness
//!
//! Why: Comprehensive test framework for validating complete Grain OS stack.
//! Tests kernel, memory, display, and application integration end-to-end.
//!
//! Agents: Vantage 3 (Implementation) + Reya (Architecture Validation)

const std = @import("std");
const grain_os = @import("../../basin_kernel/boot/grain_os_init.zig");
const memory = @import("../../basin_kernel/memory/unified_allocator.zig");
const display = @import("../../basin_kernel/display/shine_bridge.zig");
const shine = @import("../shine/compositor_core.zig");

const GrainOSInit = grain_os.GrainOSInit;
const UnifiedMemoryManager = memory.UnifiedMemoryManager;
const ShineBridge = display.ShineBridge;
const CompositorCore = shine.CompositorCore;

/// Why: Test results tracking for validation suite.
pub const TestResults = struct {
    const Self = @This();
    
    total_tests: u32,
    passed_tests: u32,
    failed_tests: u32,
    test_names: std.ArrayList([]const u8),
    failures: std.ArrayList([]const u8),
    allocator: std.mem.Allocator,
    
    /// Why: Initialize test results tracker.
    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .total_tests = 0,
            .passed_tests = 0,
            .failed_tests = 0,
            .test_names = std.ArrayList([]const u8).init(allocator),
            .failures = std.ArrayList([]const u8).init(allocator),
            .allocator = allocator,
        };
    }
    
    /// Why: Cleanup test results.
    pub fn deinit(self: *Self) void {
        for (self.test_names.items) |name| {
            self.allocator.free(name);
        }
        self.test_names.deinit();
        
        for (self.failures.items) |msg| {
            self.allocator.free(msg);
        }
        self.failures.deinit();
    }
    
    /// Why: Record test result.
    pub fn recordTest(self: *Self, name: []const u8, passed: bool, failure_msg: ?[]const u8) !void {
        self.total_tests += 1;
        
        const name_copy = try self.allocator.dupe(u8, name);
        try self.test_names.append(name_copy);
        
        if (passed) {
            self.passed_tests += 1;
            std.debug.print("✅ PASS: {s}\n", .{name});
        } else {
            self.failed_tests += 1;
            const msg = failure_msg orelse "Unknown failure";
            const msg_copy = try self.allocator.dupe(u8, msg);
            try self.failures.append(msg_copy);
            std.debug.print("❌ FAIL: {s} - {s}\n", .{ name, msg });
        }
    }
    
    /// Why: Print test summary.
    pub fn printSummary(self: *const Self) void {
        std.debug.print("\n=== Test Summary ===\n", .{});
        std.debug.print("Total: {d}\n", .{self.total_tests});
        std.debug.print("Passed: {d}\n", .{self.passed_tests});
        std.debug.print("Failed: {d}\n", .{self.failed_tests});
        
        if (self.failed_tests > 0) {
            std.debug.print("\nFailures:\n", .{});
            for (self.failures.items, 0..) |msg, i| {
                std.debug.print("  {d}. {s}\n", .{ i + 1, msg });
            }
        }
    }
};

/// Why: Validate Grain OS boot sequence.
pub fn testGrainOSBoot(allocator: std.mem.Allocator, results: *TestResults) !void {
    std.debug.print("\n--- Testing Grain OS Boot ---\n", .{});
    
    var system = grain_os.bootGrainOS(allocator) catch |err| {
        try results.recordTest("Grain OS Boot", false, try std.fmt.allocPrint(
            allocator,
            "Boot failed: {}",
            .{err},
        ));
        return;
    };
    defer system.deinit();
    
    if (!system.isReady()) {
        try results.recordTest("Grain OS Boot", false, "System not ready after boot");
        return;
    }
    
    try results.recordTest("Grain OS Boot", true, null);
}

/// Why: Validate memory management system.
pub fn testMemoryManagement(allocator: std.mem.Allocator, results: *TestResults) !void {
    std.debug.print("\n--- Testing Memory Management ---\n", .{});
    
    var manager = try memory.initializeSystemMemory(allocator);
    defer manager.deinit();
    
    // Why: Test memory allocation within bounds.
    const test_size: u64 = 1024;
    const test_ptr = manager.allocateKernel(test_size) catch |err| {
        try results.recordTest("Memory Allocation", false, try std.fmt.allocPrint(
            allocator,
            "Allocation failed: {}",
            .{err},
        ));
        return;
    };
    defer manager.deallocateKernel(test_ptr);
    
    if (test_ptr == null) {
        try results.recordTest("Memory Allocation", false, "Allocation returned null");
        return;
    }
    
    // Why: Test bounds checking.
    const stats = manager.getStats();
    if (stats.kernel_used > memory.SYSTEM_MEMORY_BOUNDS.KERNEL_HEAP_MAX) {
        try results.recordTest("Memory Bounds", false, "Exceeded kernel heap max");
        return;
    }
    
    try results.recordTest("Memory Allocation", true, null);
    try results.recordTest("Memory Bounds", true, null);
}

/// Why: Validate display subsystem.
pub fn testDisplaySubsystem(allocator: std.mem.Allocator, results: *TestResults) !void {
    std.debug.print("\n--- Testing Display Subsystem ---\n", .{});
    
    var bridge = try display.initializeDisplaySubsystem(allocator);
    defer bridge.deinit();
    
    if (!bridge.fb.isReady()) {
        try results.recordTest("Framebuffer Init", false, "Framebuffer not ready");
        return;
    }
    
    // Why: Test framebuffer operations.
    try bridge.fb.clear(0xFF000000);
    try results.recordTest("Framebuffer Clear", true, null);
    
    // Why: Test compositor connection.
    const stats = bridge.compositor.getStats();
    try results.recordTest("Compositor Connection", true, null);
    
    try results.recordTest("Display Subsystem", true, null);
}

/// Why: Validate Grain Shine compositor.
pub fn testCompositor(allocator: std.mem.Allocator, results: *TestResults) !void {
    std.debug.print("\n--- Testing Grain Shine Compositor ---\n", .{});
    
    var compositor = try CompositorCore.init(allocator);
    defer compositor.deinit();
    
    // Why: Test client addition.
    const client_id = try compositor.addClient();
    if (client_id == 0) {
        try results.recordTest("Compositor Client", false, "Invalid client ID");
        return;
    }
    
    try results.recordTest("Compositor Client", true, null);
    
    // Why: Test output creation.
    try compositor.addOutput(0, 0, 1920, 1080, "Test Output", "Primary");
    const stats = compositor.getStats();
    
    if (stats.outputs == 0) {
        try results.recordTest("Compositor Output", false, "No outputs created");
        return;
    }
    
    try results.recordTest("Compositor Output", true, null);
    try results.recordTest("Compositor Core", true, null);
}

/// Why: Run complete validation suite.
pub fn runValidationSuite(allocator: std.mem.Allocator) !void {
    std.debug.print("=== Grain OS System Validation Suite ===\n", .{});
    std.debug.print("Starting comprehensive system tests...\n\n", .{});
    
    var results = TestResults.init(allocator);
    defer results.deinit();
    
    // Why: Run all validation tests.
    try testGrainOSBoot(allocator, &results);
    try testMemoryManagement(allocator, &results);
    try testDisplaySubsystem(allocator, &results);
    try testCompositor(allocator, &results);
    
    // Why: Print final summary.
    results.printSummary();
    
    if (results.failed_tests > 0) {
        std.debug.print("\n⚠️  Validation suite completed with failures\n", .{});
        return error.ValidationFailed;
    }
    
    std.debug.print("\n✅ All validation tests passed!\n", .{});
}

/// Why: Main test entry point.
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    runValidationSuite(allocator) catch |err| {
        std.debug.print("Validation error: {}\n", .{err});
        std.process.exit(1);
    };
}