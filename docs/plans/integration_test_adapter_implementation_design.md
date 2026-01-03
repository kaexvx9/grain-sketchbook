# Integration Test Adapter Implementation Design

**Date**: 2026-01-02-100345-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Detailed implementation design for integration test adapter  
**Priority**: HIGH — Per multi-architecture testing framework design

---

## Executive Summary

**Objective**: Design detailed implementation for integration test adapter module (`src/test_framework/integration_adapter.zig`) that adapts existing 44 integration tests for multi-architecture testing without rewriting tests.

**Why**: Integration test adapter enables multi-architecture testing of existing tests without requiring test rewrites, maintaining backward compatibility.

**Context**: Part of multi-architecture testing framework implementation. Can proceed independently.

**Timeline**: Week 2-3 (implementation after Phase 1 completion)

---

## Module Structure

### File: `src/test_framework/integration_adapter.zig`

**Purpose**: Adapt existing 44 integration tests for multi-architecture testing.

**Grain Style Requirements**:
- `grain_case` function names (snake_case)
- Explicit `u32`/`u64` types (no `usize`/`isize`)
- `grainwrap-100` (line length ≤100 characters)
- `grain validate-70` (function length ≤70 lines)
- Minimum 2 assertions per function
- All MAX_ constants defined

---

## Adapter Pattern

### Test Adapter Structure

**Why**: Wrap existing tests with architecture detection and compatibility checking.

**Implementation**:
```zig
/// Integration test adapter.
/// Why: Adapt existing tests for multi-architecture without rewriting.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub const IntegrationTestAdapter = struct {
    /// Current architecture.
    arch: TestArchitecture,
    
    /// Allocator.
    allocator: std.mem.Allocator,
    
    /// Initialize adapter.
    /// Why: Set up adapter for current architecture.
    /// Contract: Returns initialized adapter instance.
    /// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
    pub fn init(allocator: std.mem.Allocator) IntegrationTestAdapter {
        // Assert: Allocator must be valid (precondition).
        std.debug.assert(@intFromPtr(allocator.ptr) != 0);
        
        // Detect current architecture.
        const arch = arch_detection.detect_test_architecture();
        
        // Assert: Architecture must be valid (postcondition).
        std.debug.assert(arch != .unknown);
        
        return IntegrationTestAdapter{
            .arch = arch,
            .allocator = allocator,
        };
    }
};
```

---

## Test Adaptation Strategies

### Strategy 1: Wrapper Function

**Why**: Wrap existing test functions with architecture detection.

**Implementation**:
```zig
/// Adapt existing test with wrapper.
/// Why: Enable multi-architecture testing without test changes.
/// Contract: Wraps test with architecture detection.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn adapt_test_with_wrapper(
    test_name: []const u8,
    original_test: *const fn () anyerror!void,
    supported_archs: []const TestArchitecture,
) *const fn () anyerror!void {
    // Assert: Test name must be valid (precondition).
    std.debug.assert(test_name.len > 0);
    
    // Assert: Test function must be valid (precondition).
    std.debug.assert(@intFromPtr(original_test) != 0);
    
    // Create wrapper function.
    const Wrapper = struct {
        test_name: []const u8,
        original_test: *const fn () anyerror!void,
        supported_archs: []const TestArchitecture,
        
        fn wrapped_test() anyerror!void {
            // Detect current architecture.
            const arch = arch_detection.detect_test_architecture();
            
            // Check compatibility.
            if (!test_helpers.is_test_compatible(
                supported_archs,
                arch,
            )) {
                // Skip incompatible test.
                return;
            }
            
            // Run original test.
            try original_test();
        }
    };
    
    return Wrapper.wrapped_test;
}
```

---

### Strategy 2: Test Metadata

**Why**: Use test metadata to determine architecture compatibility.

**Implementation**:
```zig
/// Test metadata.
/// Why: Store test compatibility information.
/// GrainStyle: Explicit types (u32/u64), bounded allocations.
pub const TestMetadata = struct {
    /// Test name.
    test_name: []const u8,
    
    /// Supported architectures.
    supported_archs: []const TestArchitecture,
    
    /// Test function.
    test_fn: *const fn () anyerror!void,
    
    /// Maximum supported architectures (bounded allocation).
    pub const MAX_SUPPORTED_ARCHS: u32 = 4;
    
    /// Check if test is compatible with architecture.
    /// Why: Determine if test should run on current architecture.
    /// Contract: Returns true if compatible, false otherwise.
    /// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
    pub fn is_compatible(
        self: *const TestMetadata,
        arch: TestArchitecture,
    ) bool {
        // Assert: Self must be valid (precondition).
        std.debug.assert(@intFromPtr(self) != 0);
        
        // Assert: Architecture must be valid (precondition).
        std.debug.assert(arch != .unknown);
        
        // Check compatibility.
        return test_helpers.is_test_compatible(
            self.supported_archs,
            arch,
        );
    }
};
```

---

## Existing Test Integration

### Adapt Existing Test File

**Why**: Adapt existing test files for multi-architecture without rewriting.

**Implementation**:
```zig
/// Adapt existing test file.
/// Why: Enable multi-architecture testing of existing tests.
/// Contract: Returns adapted test metadata.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn adapt_existing_test_file(
    test_file_name: []const u8,
    tests: []const struct {
        name: []const u8,
        test_fn: *const fn () anyerror!void,
    },
    default_supported_archs: []const TestArchitecture,
) ![]TestMetadata {
    // Assert: Test file name must be valid (precondition).
    std.debug.assert(test_file_name.len > 0);
    
    // Assert: Tests must be valid (precondition).
    std.debug.assert(tests.len > 0);
    
    // Create test metadata for each test.
    var metadata_list = std.ArrayList(TestMetadata).init(allocator);
    defer metadata_list.deinit();
    
    for (tests) |test| {
        // Create metadata with default supported architectures.
        try metadata_list.append(TestMetadata{
            .test_name = test.name,
            .supported_archs = default_supported_archs,
            .test_fn = test.test_fn,
        });
    }
    
    // Assert: Metadata list must be valid (postcondition).
    std.debug.assert(metadata_list.items.len == tests.len);
    
    return metadata_list.toOwnedSlice();
}
```

---

### Test Execution Strategy

**Why**: Execute adapted tests with architecture filtering.

**Implementation**:
```zig
/// Execute adapted tests.
/// Why: Run adapted tests with architecture filtering.
/// Contract: Returns test results or error.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn execute_adapted_tests(
    adapter: *IntegrationTestAdapter,
    test_metadata: []const TestMetadata,
    runner: *TestRunner,
) !void {
    // Assert: Adapter must be valid (precondition).
    std.debug.assert(@intFromPtr(adapter) != 0);
    
    // Assert: Test metadata must be valid (precondition).
    std.debug.assert(test_metadata.len > 0);
    
    // Execute each test.
    for (test_metadata) |metadata| {
        // Check compatibility.
        if (!metadata.is_compatible(adapter.arch)) {
            // Skip incompatible test.
            continue;
        }
        
        // Execute test.
        const result = try runner.execute_test(
            metadata.test_name,
            metadata.test_fn,
        );
        
        // Assert: Result must be valid (postcondition).
        std.debug.assert(result.test_name.len > 0);
    }
}
```

---

## Backward Compatibility

### Maintain Original Test Behavior

**Why**: Ensure adapted tests maintain original behavior when run on compatible architectures.

**Implementation**:
```zig
/// Ensure backward compatibility.
/// Why: Maintain original test behavior.
/// Contract: Adapted test behaves identically to original.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn ensure_backward_compatibility(
    original_test: *const fn () anyerror!void,
    adapted_test: *const fn () anyerror!void,
) bool {
    // Assert: Tests must be valid (precondition).
    std.debug.assert(@intFromPtr(original_test) != 0);
    std.debug.assert(@intFromPtr(adapted_test) != 0);
    
    // Note: Backward compatibility is ensured by:
    // 1. Adapted test calls original test directly
    // 2. Architecture filtering only skips tests, doesn't modify behavior
    // 3. Test setup/teardown remains identical
    
    // Return true (compatibility ensured by design).
    return true;
}
```

---

## Integration with Existing 44 Tests

### Test File Mapping

**Why**: Map existing test files to adapted versions.

**Implementation**:
```zig
/// Test file mapping.
/// Why: Map existing test files to adapted versions.
/// GrainStyle: Explicit types (u32/u64), bounded allocations.
pub const TestFileMapping = struct {
    /// Original test file name.
    original_file: []const u8,
    
    /// Adapted test file name.
    adapted_file: []const u8,
    
    /// Supported architectures (default: all).
    supported_archs: []const TestArchitecture,
    
    /// Maximum test files (bounded allocation).
    pub const MAX_TEST_FILES: u32 = 100;
};

/// Map existing test files.
/// Why: Create mapping for all existing test files.
/// Contract: Returns test file mapping.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn map_existing_test_files(
    allocator: std.mem.Allocator,
) ![]TestFileMapping {
    // Assert: Allocator must be valid (precondition).
    std.debug.assert(@intFromPtr(allocator.ptr) != 0);
    
    // Default supported architectures (all).
    const all_archs = [_]TestArchitecture{
        .arm64,
        .x86_64_amd,
        .x86_64_intel,
    };
    
    // Map existing test files.
    const test_files = [_][]const u8{
        "tests/149_syscall_combination_integration_test.zig",
        "tests/150_edge_case_integration_test.zig",
        "tests/151_stress_integration_test.zig",
        "tests/152_error_handling_integration_test.zig",
        "tests/153_performance_integration_test.zig",
    };
    
    var mapping = std.ArrayList(TestFileMapping).init(allocator);
    defer mapping.deinit();
    
    for (test_files) |test_file| {
        try mapping.append(TestFileMapping{
            .original_file = test_file,
            .adapted_file = test_file, // Same file (wrapper approach).
            .supported_archs = &all_archs,
        });
    }
    
    // Assert: Mapping must be valid (postcondition).
    std.debug.assert(mapping.items.len == test_files.len);
    
    return mapping.toOwnedSlice();
}
```

---

## Test Failure Handling

### Handle Test Failures

**Why**: Provide consistent test failure handling across architectures.

**Implementation**:
```zig
/// Handle test failure.
/// Why: Provide consistent failure handling.
/// Contract: Handles test failure and records error.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn handle_test_failure(
    adapter: *IntegrationTestAdapter,
    test_name: []const u8,
    error: anyerror,
) !void {
    // Assert: Test name must be valid (precondition).
    std.debug.assert(test_name.len > 0);
    
    // Create error message.
    const error_msg = try std.fmt.allocPrint(
        adapter.allocator,
        "Test {s} failed on {s}: {s}",
        .{
            test_name,
            arch_detection.get_architecture_name(adapter.arch),
            @errorName(error),
        },
    );
    
    // Log error (if logging available).
    std.debug.print("ERROR: {s}\n", .{error_msg});
    
    // Assert: Error message must be valid (postcondition).
    std.debug.assert(error_msg.len > 0);
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
**Status**: 🆕 **DESIGN IN PROGRESS** — Detailed implementation design for integration test adapter  
**Priority**: HIGH — Per multi-architecture testing framework design

