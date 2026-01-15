# Test Runner Implementation Design

**Date**: 2026-01-02-100345-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Detailed implementation design for test runner  
**Priority**: HIGH — Per multi-architecture testing framework design

---

## Executive Summary

**Objective**: Design detailed implementation for test runner module (`src/test_framework/runner.zig`) that provides multi-architecture test execution, test result reporting, and architecture-specific test filtering.

**Why**: Test runner enables automated test execution across all architectures (ARM64, x86_64 AMD, x86_64 Intel) with consistent reporting.

**Context**: Part of multi-architecture testing framework implementation. Can proceed independently.

**Timeline**: Week 1-2 (implementation after design approval)

---

## Module Structure

### File: `src/test_framework/runner.zig`

**Purpose**: Provide multi-architecture test execution and reporting for multi-architecture testing framework.

**Grain Style Requirements**:
- `grain_case` function names (snake_case)
- Explicit `u32`/`u64` types (no `usize`/`isize`)
- `grainwrap-100` (line length ≤100 characters)
- `grain validate-70` (function length ≤70 lines)
- Minimum 2 assertions per function
- All MAX_ constants defined

---

## Test Runner Core

### Test Runner Structure

**Why**: Centralized test execution and reporting.

**Implementation**:
```zig
/// Test runner for multi-architecture testing.
/// Why: Execute tests across architectures with consistent reporting.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub const TestRunner = struct {
    /// Current architecture.
    arch: TestArchitecture,
    
    /// Test results.
    results: std.ArrayList(TestResult),
    
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
            .results = std.ArrayList(TestResult).init(allocator),
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
        
        self.results.deinit();
    }
};
```

---

## Test Execution

### Execute Single Test

**Why**: Execute a single test with architecture detection.

**Implementation**:
```zig
/// Test result.
/// Why: Track test execution results.
/// GrainStyle: Explicit types (u32/u64), bounded allocations.
pub const TestResult = struct {
    /// Test name.
    test_name: []const u8,
    
    /// Test passed.
    passed: bool,
    
    /// Error message (if failed).
    error_message: ?[]const u8,
    
    /// Duration (milliseconds).
    duration_ms: u64,
    
    /// Architecture.
    arch: TestArchitecture,
};

/// Execute single test.
/// Why: Run test and record result.
/// Contract: Returns test result or error.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn execute_test(
    self: *TestRunner,
    test_name: []const u8,
    test_fn: *const fn () anyerror!void,
) !TestResult {
    // Assert: Test name must be valid (precondition).
    std.debug.assert(test_name.len > 0);
    
    // Assert: Test function must be valid (precondition).
    std.debug.assert(@intFromPtr(test_fn) != 0);
    
    // Record start time.
    const start_time = std.time.nanoTimestamp();
    
    // Execute test.
    const result = test_fn() catch |err| {
        // Test failed.
        const end_time = std.time.nanoTimestamp();
        const duration_ms = @as(u64, @intCast((end_time - start_time) / 1000000));
        
        // Create error message.
        const error_msg = try std.fmt.allocPrint(
            self.allocator,
            "Test failed: {s}",
            .{@errorName(err)},
        );
        
        return TestResult{
            .test_name = test_name,
            .passed = false,
            .error_message = error_msg,
            .duration_ms = duration_ms,
            .arch = self.arch,
        };
    };
    
    // Test passed.
    const end_time = std.time.nanoTimestamp();
    const duration_ms = @as(u64, @intCast((end_time - start_time) / 1000000));
    
    // Assert: Result must be valid (postcondition).
    _ = result;
    
    return TestResult{
        .test_name = test_name,
        .passed = true,
        .error_message = null,
        .duration_ms = duration_ms,
        .arch = self.arch,
    };
}
```

---

### Execute Test Suite

**Why**: Execute multiple tests with architecture filtering.

**Implementation**:
```zig
/// Test suite.
/// Why: Group related tests.
/// GrainStyle: Explicit types (u32/u64), bounded allocations.
pub const TestSuite = struct {
    /// Suite name.
    suite_name: []const u8,
    
    /// Tests.
    tests: []const struct {
        name: []const u8,
        test_fn: *const fn () anyerror!void,
        supported_archs: []const TestArchitecture,
    },
    
    /// Maximum tests per suite (bounded allocation).
    pub const MAX_TESTS_PER_SUITE: u32 = 1000;
};

/// Execute test suite.
/// Why: Run all tests in suite with architecture filtering.
/// Contract: Returns test results or error.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn execute_test_suite(
    self: *TestRunner,
    suite: TestSuite,
) !void {
    // Assert: Suite must be valid (precondition).
    std.debug.assert(suite.suite_name.len > 0);
    std.debug.assert(suite.tests.len > 0);
    std.debug.assert(suite.tests.len <= TestSuite.MAX_TESTS_PER_SUITE);
    
    // Execute each test.
    for (suite.tests) |test| {
        // Check architecture compatibility.
        if (!test_helpers.is_test_compatible(
            test.supported_archs,
            self.arch,
        )) {
            // Skip incompatible test.
            continue;
        }
        
        // Execute test.
        const result = try self.execute_test(test.name, test.test_fn);
        
        // Assert: Result must be valid (postcondition).
        std.debug.assert(result.test_name.len > 0);
        
        // Store result.
        try self.results.append(result);
    }
}
```

---

## Test Result Reporting

### Generate Test Report

**Why**: Generate human-readable test report.

**Implementation**:
```zig
/// Generate test report.
/// Why: Create human-readable test report.
/// Contract: Returns report string or error.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn generate_test_report(
    self: *TestRunner,
) ![]const u8 {
    // Assert: Self must be valid (precondition).
    std.debug.assert(@intFromPtr(self) != 0);
    
    // Count results.
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
    
    // Assert: Counts must be consistent (postcondition).
    std.debug.assert(total == passed + failed);
    
    // Generate report.
    const report = try std.fmt.allocPrint(
        self.allocator,
        \\Test Report
        \\Architecture: {s}
        \\Total Tests: {d}
        \\Passed: {d}
        \\Failed: {d}
        \\
        \\Results:
        \\
    ,
        .{
            arch_detection.get_architecture_name(self.arch),
            total,
            passed,
            failed,
        },
    );
    
    return report;
}
```

---

### Export Test Results (JSON)

**Why**: Export test results in JSON format for CI/CD integration.

**Implementation**:
```zig
/// Export test results to JSON.
/// Why: Enable CI/CD integration with JSON reports.
/// Contract: Returns JSON string or error.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn export_test_results_json(
    self: *TestRunner,
) ![]const u8 {
    // Assert: Self must be valid (precondition).
    std.debug.assert(@intFromPtr(self) != 0);
    
    // Generate JSON report.
    var json_buffer = std.ArrayList(u8).init(self.allocator);
    defer json_buffer.deinit();
    
    try json_buffer.writer().print(
        \\{{
        \\  "architecture": "{s}",
        \\  "total_tests": {d},
        \\  "results": [
    ,
        .{
            arch_detection.get_architecture_name(self.arch),
            self.results.items.len,
        },
    );
    
    // Add test results.
    for (self.results.items, 0..) |result, i| {
        if (i > 0) {
            try json_buffer.writer().print(",", .{});
        }
        
        try json_buffer.writer().print(
            \\    {{
            \\      "test_name": "{s}",
            \\      "passed": {},
            \\      "duration_ms": {d}
            \\    }}
        ,
            .{
                result.test_name,
                result.passed,
                result.duration_ms,
            },
        );
    }
    
    try json_buffer.writer().print(
        \\  ]
        \\}}
    ,
        .{},
    );
    
    return json_buffer.toOwnedSlice();
}
```

---

## Architecture-Specific Test Filtering

### Filter Tests by Architecture

**Why**: Filter tests based on architecture compatibility.

**Implementation**:
```zig
/// Filter tests by architecture.
/// Why: Only run tests compatible with current architecture.
/// Contract: Returns filtered test list.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn filter_tests_by_architecture(
    tests: []const struct {
        name: []const u8,
        test_fn: *const fn () anyerror!void,
        supported_archs: []const TestArchitecture,
    },
    arch: TestArchitecture,
    allocator: std.mem.Allocator,
) ![]const struct {
    name: []const u8,
    test_fn: *const fn () anyerror!void,
} {
    // Assert: Tests must be valid (precondition).
    std.debug.assert(tests.len > 0);
    
    // Assert: Architecture must be valid (precondition).
    std.debug.assert(arch != .unknown);
    
    // Filter compatible tests.
    var filtered = std.ArrayList(struct {
        name: []const u8,
        test_fn: *const fn () anyerror!void,
    }).init(allocator);
    
    for (tests) |test| {
        if (test_helpers.is_test_compatible(test.supported_archs, arch)) {
            try filtered.append(.{
                .name = test.name,
                .test_fn = test.test_fn,
            });
        }
    }
    
    // Assert: Filtered list must be valid (postcondition).
    std.debug.assert(filtered.items.len <= tests.len);
    
    return filtered.toOwnedSlice();
}
```

---

## Integration with build.zig

### Test Runner Integration

**Why**: Integrate test runner with Zig build system.

**Implementation** (in `build.zig`):
```zig
// Multi-architecture test runner.
const test_runner_exe = b.addExecutable(.{
    .name = "test_runner",
    .root_source_file = b.path("src/test_framework/runner.zig"),
    .target = target,
    .optimize = optimize,
});

const test_runner_run = b.addRunArtifact(test_runner_exe);
const test_runner_step = b.step("test-multi-arch", "Run multi-architecture tests");
test_runner_step.dependOn(&test_runner_run.step);
```

---

## Grain Style Compliance

### Requirements

1. **Function Naming**: `grain_case` (snake_case)
2. **Type Usage**: Explicit `u32`/`u64`, no `usize`/`isize`
3. **Line Length**: ≤100 characters (`grainwrap-100`)
4. **Function Length**: ≤70 lines (`grain validate-70`)
5. **Assertions**: Minimum 2 assertions per function
6. **Bounded Allocations**: All MAX_ constants defined
7. **Compiler Warnings**: All warnings addressed

---

**Date**: 2026-01-02-100345-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Detailed implementation design for test runner  
**Priority**: HIGH — Per multi-architecture testing framework design

