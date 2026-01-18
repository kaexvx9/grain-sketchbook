//! Test Runner for Multi-Architecture Testing Framework
//! Why: Execute tests across architectures with consistent reporting.
//! Grain Style: Explicit types (u32/u64), bounded operations, assertions.

const std = @import("std");
const testing = std.testing;
const arch_detection = @import("arch.zig");
const TestArchitecture = arch_detection.TestArchitecture;
const helpers = @import("helpers.zig");
const ArchitectureTestResult = helpers.ArchitectureTestResult;

/// Maximum test results (Grain Style: bounded allocation).
const MAX_TEST_RESULTS: u32 = 10000;

/// Maximum test name length (Grain Style: bounded allocation).
const MAX_TEST_NAME_LEN: u32 = 256;

/// Maximum error message length (Grain Style: bounded allocation).
const MAX_ERROR_MSG_LEN: u32 = 1024;

/// Test result for individual test execution.
/// Why: Track test execution results per architecture.
/// GrainStyle: Explicit types, bounded operations.
pub const TestResult = struct {
    test_name: []const u8,
    passed: bool,
    error_message: ?[]const u8,
    duration_ms: u64,
    arch: TestArchitecture,

    /// Initialize test result.
    /// Why: Create test result with architecture information.
    /// Contract: Returns initialized result.
    /// GrainStyle: Explicit types, bounded operations, assertions.
    pub fn init(
        test_name: []const u8,
        passed: bool,
        arch: TestArchitecture,
    ) TestResult {
        // Assert: Test name must be valid (precondition).
        std.debug.assert(test_name.len > 0);
        std.debug.assert(test_name.len <= MAX_TEST_NAME_LEN);

        // Assert: Architecture must be valid (precondition).
        std.debug.assert(arch != .unknown);

        return TestResult{
            .test_name = test_name,
            .passed = passed,
            .error_message = null,
            .duration_ms = 0,
            .arch = arch,
        };
    }
};

/// Test suite for grouping related tests.
/// Why: Organize tests into logical groups.
/// GrainStyle: Explicit types, bounded operations.
pub const TestSuite = struct {
    name: []const u8,
    tests: []const TestMetadata,
    supported_archs: []const TestArchitecture,

    /// Check if test suite is compatible with architecture.
    /// Why: Determine if suite should run on current architecture.
    /// Contract: Returns true if compatible, false otherwise.
    /// GrainStyle: Explicit types, bounded operations, assertions.
    pub fn is_compatible(
        self: *const TestSuite,
        arch: TestArchitecture,
    ) bool {
        // Assert: Architecture must be valid (precondition).
        std.debug.assert(arch != .unknown);

        return helpers.is_test_compatible(self.supported_archs, arch);
    }
};

/// Test metadata for test execution.
/// Why: Store test function and metadata.
/// GrainStyle: Explicit types, bounded operations.
pub const TestMetadata = struct {
    name: []const u8,
    test_fn: *const fn () anyerror!void,
    supported_archs: []const TestArchitecture,
};

/// Test runner for multi-architecture testing.
/// Why: Execute tests across architectures with consistent reporting.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub const TestRunner = struct {
    /// Current architecture.
    arch: TestArchitecture,

    /// Test results (unmanaged for explicit allocator control).
    results: std.ArrayListUnmanaged(TestResult),

    /// Allocator.
    allocator: std.mem.Allocator,

    /// Maximum test results (bounded allocation).
    pub const MAX_TEST_RESULTS: u32 = 10000;

    /// Initialize test runner.
    /// Why: Set up test runner for current architecture.
    /// Contract: Returns initialized TestRunner instance.
    /// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
    pub fn init(allocator: std.mem.Allocator) TestRunner {
        // Assert: Allocator must be valid (precondition).
        std.debug.assert(@intFromPtr(allocator.ptr) != 0);

        // Detect current architecture.
        const arch = arch_detection.detect_test_architecture();

        // Assert: Architecture must be valid (postcondition).
        std.debug.assert(arch != .unknown);

        return TestRunner{
            .arch = arch,
            .results = .{},
            .allocator = allocator,
        };
    }

    /// Deinitialize test runner.
    /// Why: Clean up test runner resources.
    /// Contract: Frees all allocated resources.
    /// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
    pub fn deinit(self: *TestRunner) void {
        // Assert: Self must be valid (precondition).
        std.debug.assert(@intFromPtr(self) != 0);

        // Free test results.
        for (self.results.items) |result| {
            if (result.error_message) |msg| {
                self.allocator.free(msg);
            }
        }

        self.results.deinit(self.allocator);
    }

    /// Execute single test.
    /// Why: Run test and record result.
    /// Contract: Executes test and adds result to results list.
    /// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
    pub fn execute_test(
        self: *TestRunner,
        test_metadata: TestMetadata,
    ) !void {
        // Assert: Test metadata must be valid (precondition).
        std.debug.assert(test_metadata.name.len > 0);
        std.debug.assert(test_metadata.name.len <= MAX_TEST_NAME_LEN);

        // Assert: Results list must not exceed maximum (precondition).
        std.debug.assert(self.results.items.len < TestRunner.MAX_TEST_RESULTS);

        // Check if test is compatible with current architecture.
        if (!helpers.is_test_compatible(
            test_metadata.supported_archs,
            self.arch,
        )) {
            // Skip test on unsupported architecture.
            return;
        }

        // Record start time.
        const start_time = std.time.nanoTimestamp();

        // Execute test.
        var test_passed: bool = false;
        var error_msg: ?[]const u8 = null;

        test_metadata.test_fn() catch |err| {
            test_passed = false;
            const err_str = @errorName(err);
            error_msg = try self.allocator.dupe(u8, err_str);

            // Record end time for failed test.
            const end_time = std.time.nanoTimestamp();
            const duration_ms: u64 = @intCast((end_time - start_time) / 1000000);

            // Create test result for failed test.
            var result = TestResult.init(test_metadata.name, test_passed, self.arch);
            result.duration_ms = duration_ms;
            result.error_message = error_msg;

            // Add result to results list.
            try self.results.append(result);
            return;
        };

        test_passed = true;

        // Record end time.
        const end_time = std.time.nanoTimestamp();
        const duration_ms: u64 = @intCast((end_time - start_time) / 1000000);

        // Create test result.
        var result = TestResult.init(test_metadata.name, test_passed, self.arch);
        result.duration_ms = duration_ms;
        result.error_message = error_msg;

        // Add result to results list.
        try self.results.append(result);

        // Assert: Result added successfully (postcondition).
        std.debug.assert(self.results.items.len > 0);
    }

    /// Execute test suite.
    /// Why: Run all tests in suite and record results.
    /// Contract: Executes all compatible tests in suite.
    /// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
    pub fn execute_test_suite(
        self: *TestRunner,
        suite: TestSuite,
    ) !void {
        // Assert: Suite must be valid (precondition).
        std.debug.assert(suite.name.len > 0);
        std.debug.assert(suite.tests.len > 0);

        // Check if suite is compatible with current architecture.
        if (!suite.is_compatible(self.arch)) {
            // Skip suite on unsupported architecture.
            return;
        }

        // Execute all tests in suite.
        for (suite.tests) |test_metadata| {
            try self.execute_test(test_metadata);
        }

        // Assert: At least one result recorded (postcondition).
        std.debug.assert(self.results.items.len > 0);
    }

    /// Generate test report.
    /// Why: Create human-readable test report.
    /// Contract: Returns formatted test report string.
    /// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
    pub fn generate_test_report(self: *const TestRunner) ![]const u8 {
        // Assert: Self must be valid (precondition).
        std.debug.assert(@intFromPtr(self) != 0);

        // Calculate summary statistics.
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

        // Assert: Total must equal passed + failed (postcondition).
        std.debug.assert(total == passed + failed);

        // Generate report string.
        const arch_name = arch_detection.get_architecture_name(self.arch);
        const report_fmt =
            \\Test Report
            \\Architecture: {s}
            \\Total Tests: {}
            \\Passed: {}
            \\Failed: {}
            \\
        ;

        var report: std.ArrayListUnmanaged(u8) = .{};
        try report.writer(self.allocator).print(report_fmt, .{ arch_name, total, passed, failed });

        // Add individual test results.
        for (self.results.items) |result| {
            const status = if (result.passed) "PASS" else "FAIL";
            const result_fmt = "  {s}: {s} ({}ms)\n";
            try report.writer(self.allocator).print(result_fmt, .{ result.test_name, status, result.duration_ms });
        }

        return report.toOwnedSlice(self.allocator);
    }

    /// Export test results to JSON.
    /// Why: Enable programmatic test result analysis.
    /// Contract: Returns JSON-formatted test results.
    /// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
    pub fn export_test_results_json(self: *const TestRunner) ![]const u8 {
        // Assert: Self must be valid (precondition).
        std.debug.assert(@intFromPtr(self) != 0);

        // Generate JSON report.
        var json: std.ArrayListUnmanaged(u8) = .{};
        const w = json.writer(self.allocator);
        try w.print("{{\n", .{});

        // Architecture.
        const arch_name = arch_detection.get_architecture_name(self.arch);
        try w.print("  \"architecture\": \"{s}\",\n", .{arch_name});

        // Test results.
        try w.print("  \"results\": [\n", .{});
        for (self.results.items, 0..) |result, i| {
            if (i > 0) {
                try w.print(",\n", .{});
            }
            try w.print(
                "    {{\"name\": \"{s}\", \"passed\": {}, \"duration_ms\": {}}}",
                .{ result.test_name, result.passed, result.duration_ms },
            );
        }
        try w.print("\n  ]\n", .{});
        try w.print("}}\n", .{});

        return json.toOwnedSlice(self.allocator);
    }
};

