//! Core 1 Subcore Integration Test Runner
//!
//! Purpose: Run integration tests for Core 1 Subcore L2 sub-agents
//! (1a Auth, 1b Network, 1c Storage, 1d Compositor, 1e Grainscript Shell)
//!
//! Architecture: Test isolation, setup/teardown, cross-sub-agent scenarios
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions
//!
//! 2026-01-02-004000-pst: Initial implementation

const std = @import("std");
const testing = std.testing;

/// Integration test result.
pub const TestResult = struct {
    name: []const u8,
    passed: bool,
    error_message: ?[]const u8,
    duration_ms: u64,
};

/// Integration test runner.
pub const IntegrationTestRunner = struct {
    allocator: std.mem.Allocator,
    results: std.ArrayList(TestResult),
    
    // Bounded: Max test results
    pub const MAX_TEST_RESULTS: u32 = 1000;
    
    /// Initialize test runner.
    pub fn init(allocator: std.mem.Allocator) IntegrationTestRunner {
        std.debug.assert(allocator.ptr != null);
        
        return IntegrationTestRunner{
            .allocator = allocator,
            .results = std.ArrayList(TestResult).init(allocator),
        };
    }
    
    /// Deinitialize test runner.
    pub fn deinit(self: *IntegrationTestRunner) void {
        std.debug.assert(self.allocator.ptr != null);
        
        // Free error messages
        for (self.results.items) |result| {
            if (result.error_message) |msg| {
                self.allocator.free(msg);
            }
        }
        
        self.results.deinit();
    }
    
    /// Run a single integration test.
    pub fn run_test(
        self: *IntegrationTestRunner,
        name: []const u8,
        test_fn: *const fn (std.mem.Allocator) anyerror!void,
    ) !void {
        std.debug.assert(name.len > 0);
        std.debug.assert(name.len <= 256);
        std.debug.assert(self.results.items.len < MAX_TEST_RESULTS);
        std.debug.assert(test_fn != null);
        
        const start_time = std.time.nanoTimestamp();
        var passed = true;
        var error_message: ?[]const u8 = null;
        
        // Run test with error handling
        test_fn(self.allocator) catch |err| {
            passed = false;
            const err_str = try std.fmt.allocPrint(
                self.allocator,
                "test failed: {s}",
                .{@errorName(err)},
            );
            error_message = err_str;
        };
        
        const end_time = std.time.nanoTimestamp();
        const duration_ms = @as(u64, @intCast((end_time - start_time) / 1_000_000));
        
        // Store result
        try self.results.append(TestResult{
            .name = name,
            .passed = passed,
            .error_message = error_message,
            .duration_ms = duration_ms,
        });
    }
    
    /// Get test results summary.
    pub fn get_summary(self: *const IntegrationTestRunner) struct {
        total: u32,
        passed: u32,
        failed: u32,
    } {
        std.debug.assert(self.allocator.ptr != null);
        
        var total: u32 = 0;
        var passed: u32 = 0;
        var failed: u32 = 0;
        
        for (self.results.items) |result| {
            total += 1;
            if (result.passed) {
                passed += 1;
            } else {
                failed += 1;
            }
        }
        
        std.debug.assert(total == passed + failed);
        
        return .{
            .total = total,
            .passed = passed,
            .failed = failed,
        };
    }
    
    /// Print test results.
    pub fn print_results(self: *const IntegrationTestRunner) void {
        std.debug.assert(self.allocator.ptr != null);
        
        const summary = self.get_summary();
        
        std.debug.print(
            "\n=== Core 1 Subcore Integration Test Results ===\n",
            .{},
        );
        std.debug.print("Total: {}\n", .{summary.total});
        std.debug.print("Passed: {}\n", .{summary.passed});
        std.debug.print("Failed: {}\n", .{summary.failed});
        std.debug.print("\n", .{});
        
        // Print individual results
        for (self.results.items) |result| {
            const status = if (result.passed) "PASS" else "FAIL";
            std.debug.print(
                "[{s}] {s} ({d}ms)\n",
                .{ status, result.name, result.duration_ms },
            );
            
            if (result.error_message) |msg| {
                std.debug.print("  Error: {s}\n", .{msg});
            }
        }
    }
};

/// Test setup function type.
pub const SetupFn = *const fn (std.mem.Allocator) anyerror!void;

/// Test teardown function type.
pub const TeardownFn = *const fn (std.mem.Allocator) void;

/// Test isolation helper.
pub const TestIsolation = struct {
    allocator: std.mem.Allocator,
    setup_fn: ?SetupFn,
    teardown_fn: ?TeardownFn,
    
    /// Initialize test isolation.
    pub fn init(
        allocator: std.mem.Allocator,
        setup_fn: ?SetupFn,
        teardown_fn: ?TeardownFn,
    ) TestIsolation {
        std.debug.assert(allocator.ptr != null);
        
        return TestIsolation{
            .allocator = allocator,
            .setup_fn = setup_fn,
            .teardown_fn = teardown_fn,
        };
    }
    
    /// Run test with isolation.
    pub fn run_isolated(
        self: *TestIsolation,
        test_fn: *const fn (std.mem.Allocator) anyerror!void,
    ) !void {
        std.debug.assert(self.allocator.ptr != null);
        std.debug.assert(test_fn != null);
        
        // Setup
        if (self.setup_fn) |setup| {
            try setup(self.allocator);
        }
        
        // Run test
        errdefer {
            // Teardown on error
            if (self.teardown_fn) |teardown| {
                teardown(self.allocator);
            }
        }
        
        try test_fn(self.allocator);
        
        // Teardown
        if (self.teardown_fn) |teardown| {
            teardown(self.allocator);
        }
    }
};

test "integration test runner basic functionality" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    var runner = IntegrationTestRunner.init(allocator);
    defer runner.deinit();
    
    // Run a simple test
    try runner.run_test("test_basic", test_basic_fn);
    
    const summary = runner.get_summary();
    try testing.expect(summary.total == 1);
    try testing.expect(summary.passed == 1);
    try testing.expect(summary.failed == 0);
}

fn test_basic_fn(allocator: std.mem.Allocator) !void {
    _ = allocator;
    // Simple test that always passes
    try testing.expect(true);
}

