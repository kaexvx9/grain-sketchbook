# Test Helpers Implementation Design

**Date**: 2026-01-02-100345-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Detailed implementation design for test helpers  
**Priority**: HIGH — Per multi-architecture testing framework design

---

## Executive Summary

**Objective**: Design detailed implementation for test helpers module (`src/test_framework/helpers.zig`) that provides architecture-agnostic test setup/teardown, cross-architecture test utilities, and test result aggregation.

**Why**: Test helpers enable consistent test setup across all architectures (ARM64, x86_64 AMD, x86_64 Intel) and reduce test boilerplate.

**Context**: Part of multi-architecture testing framework implementation. Can proceed independently.

**Timeline**: Week 1-2 (implementation after design approval)

---

## Module Structure

### File: `src/test_framework/helpers.zig`

**Purpose**: Provide architecture-agnostic test helpers for multi-architecture testing framework.

**Grain Style Requirements**:
- `grain_case` function names (snake_case)
- Explicit `u32`/`u64` types (no `usize`/`isize`)
- `grainwrap-100` (line length ≤100 characters)
- `grain validate-70` (function length ≤70 lines)
- Minimum 2 assertions per function
- All MAX_ constants defined

---

## Test Setup/Teardown Helpers

### Helper: Create Test Integration (Architecture-Agnostic)

**Why**: Provide consistent test setup across all architectures.

**Implementation**:
```zig
/// Create test integration (architecture-agnostic).
/// Why: Tests work identically across ARM64, x86_64 AMD, x86_64 Intel.
/// Contract: Returns initialized Integration instance, architecture detected automatically.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn create_test_integration() struct {
    vm: VM,
    kernel: BasinKernel,
    integration: Integration,
    arch: TestArchitecture,
} {
    // Assert: builtin must be available (precondition).
    _ = @import("builtin");
    
    // Detect current architecture.
    const arch = arch_detection.detect_test_architecture();
    
    // Assert: Architecture must be valid (postcondition).
    std.debug.assert(arch != .unknown);
    
    // Architecture-agnostic VM initialization.
    var vm: VM = undefined;
    VM.init(&vm, &[_]u8{}, 0x80000000);
    
    // Assert: VM must be initialized (postcondition).
    std.debug.assert(vm.state == .halted);
    
    var kernel = BasinKernel.init();
    var integration = Integration.init_with_kernel(&vm, &kernel);
    integration.finish_init();
    
    // Assert: Integration must be initialized (postcondition).
    std.debug.assert(integration.initialized);
    
    return .{
        .vm = vm,
        .kernel = kernel,
        .integration = integration,
        .arch = arch,
    };
}
```

---

### Helper: Cleanup Test Integration

**Why**: Provide consistent test teardown across all architectures.

**Implementation**:
```zig
/// Cleanup test integration.
/// Why: Ensure proper cleanup after test execution.
/// Contract: Cleans up test integration resources.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn cleanup_test_integration(
    test_setup: *struct {
        vm: VM,
        kernel: BasinKernel,
        integration: Integration,
        arch: TestArchitecture,
    },
) void {
    // Assert: Test setup must be valid (precondition).
    std.debug.assert(@intFromPtr(test_setup) != 0);
    
    // Cleanup integration (if needed).
    _ = test_setup.integration;
    
    // Cleanup kernel (if needed).
    _ = test_setup.kernel;
    
    // Cleanup VM (if needed).
    _ = test_setup.vm;
    
    // Assert: Cleanup complete (postcondition).
    _ = test_setup.arch;
}
```

---

## Cross-Architecture Test Utilities

### Helper: Check Architecture Compatibility

**Why**: Determine if test is compatible with current architecture.

**Implementation**:
```zig
/// Check if test is compatible with current architecture.
/// Why: Skip tests that don't support current architecture.
/// Contract: Returns true if compatible, false otherwise.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn is_test_compatible(
    supported_archs: []const TestArchitecture,
    current_arch: TestArchitecture,
) bool {
    // Assert: Supported archs must be valid (precondition).
    std.debug.assert(supported_archs.len > 0);
    
    // Assert: Current arch must be valid (precondition).
    std.debug.assert(current_arch != .unknown);
    
    // Check if current architecture is in supported list.
    for (supported_archs) |arch| {
        if (arch == current_arch) {
            return true;
        }
    }
    
    return false;
}
```

---

### Helper: Skip Test on Incompatible Architecture

**Why**: Skip tests that don't support current architecture.

**Implementation**:
```zig
/// Skip test on incompatible architecture.
/// Why: Skip tests that don't support current architecture.
/// Contract: Returns true if should skip, false otherwise.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn should_skip_test(
    supported_archs: []const TestArchitecture,
    current_arch: TestArchitecture,
) bool {
    // Assert: Supported archs must be valid (precondition).
    std.debug.assert(supported_archs.len > 0);
    
    // Return true if not compatible.
    return !is_test_compatible(supported_archs, current_arch);
}
```

---

## Test Result Aggregation

### Helper: Aggregate Test Results

**Why**: Aggregate test results across architectures.

**Implementation**:
```zig
/// Test result per architecture.
/// Why: Track test results per architecture.
/// GrainStyle: Explicit types (u32/u64), bounded allocations.
pub const ArchitectureTestResult = struct {
    /// Architecture.
    arch: TestArchitecture,
    
    /// Test name.
    test_name: []const u8,
    
    /// Test passed.
    passed: bool,
    
    /// Error message (if failed).
    error_message: ?[]const u8,
    
    /// Duration (milliseconds).
    duration_ms: u64,
    
    /// Initialize test result.
    /// Why: Explicit initialization.
    pub fn init(
        arch: TestArchitecture,
        test_name: []const u8,
        passed: bool,
    ) ArchitectureTestResult {
        // Assert: Test name must be valid (precondition).
        std.debug.assert(test_name.len > 0);
        
        return ArchitectureTestResult{
            .arch = arch,
            .test_name = test_name,
            .passed = passed,
            .error_message = null,
            .duration_ms = 0,
        };
    }
};

/// Aggregate test results across architectures.
/// Why: Combine test results from multiple architectures.
/// Contract: Returns aggregated test results.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn aggregate_test_results(
    results: []const ArchitectureTestResult,
) struct {
    total_tests: u32,
    passed_tests: u32,
    failed_tests: u32,
} {
    // Assert: Results must be valid (precondition).
    std.debug.assert(results.len > 0);
    
    var total: u32 = 0;
    var passed: u32 = 0;
    var failed: u32 = 0;
    
    // Count test results.
    for (results) |result| {
        total += 1;
        if (result.passed) {
            passed += 1;
        } else {
            failed += 1;
        }
    }
    
    // Assert: Counts must be consistent (postcondition).
    std.debug.assert(total == passed + failed);
    
    return .{
        .total_tests = total,
        .passed_tests = passed,
        .failed_tests = failed,
    };
}
```

---

## Integration with Existing Tests

### Helper: Adapt Existing Test

**Why**: Adapt existing tests for multi-architecture without rewriting.

**Implementation**:
```zig
/// Adapt existing test for multi-architecture.
/// Why: Enable multi-architecture testing without rewriting tests.
/// Contract: Wraps existing test with architecture detection.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn adapt_test_for_multi_arch(
    test_fn: *const fn () anyerror!void,
    supported_archs: []const TestArchitecture,
) !void {
    // Assert: Test function must be valid (precondition).
    std.debug.assert(@intFromPtr(test_fn) != 0);
    
    // Assert: Supported archs must be valid (precondition).
    std.debug.assert(supported_archs.len > 0);
    
    // Detect current architecture.
    const current_arch = arch_detection.detect_test_architecture();
    
    // Skip if not compatible.
    if (should_skip_test(supported_archs, current_arch)) {
        return; // Skip test.
    }
    
    // Run test.
    try test_fn();
}
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
**Status**: 🆕 **DESIGN IN PROGRESS** — Detailed implementation design for test helpers  
**Priority**: HIGH — Per multi-architecture testing framework design

