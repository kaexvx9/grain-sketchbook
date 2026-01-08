# Multi-Architecture Testing Framework Usage Guide

**Date**: 2026-01-07-175531-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: ✅ **USAGE GUIDE** — Guide for using the multi-architecture testing framework  
**Priority**: MEDIUM — Documentation for framework usage

---

## Executive Summary

**Objective**: Provide usage guide and examples for the multi-architecture testing framework.

**Why**: Enable Agents 3b, 3d, and other agents to use the framework for multi-architecture testing.

**Context**: Phases 1-4 complete. Framework ready for use. This guide shows how to use it.

---

## Quick Start

### Import the Framework

```zig
const test_framework = @import("test_framework");
const TestArchitecture = test_framework.TestArchitecture;
const TestSetup = test_framework.TestSetup;
const TestRunner = test_framework.TestRunner;
```

### Basic Usage: Architecture Detection

```zig
// Detect current architecture.
const arch = test_framework.detect_test_architecture();

// Check if architecture is x86_64.
if (arch.is_x86_64()) {
    // x86_64 specific code (AMD or Intel).
}

// Get architecture name for reporting.
const arch_name = test_framework.get_architecture_name(arch);
```

### Basic Usage: Test Setup

```zig
// Create architecture-agnostic test setup.
const test_setup = test_framework.create_test_integration();

// Use test setup (vm, kernel, integration, arch).
const vm = test_setup.vm;
const kernel = test_setup.kernel;
const integration = test_setup.integration;
const arch = test_setup.arch;

// Cleanup after test.
test_setup.cleanup();
```

### Basic Usage: Test Compatibility

```zig
// Define supported architectures for test.
const supported_archs = [_]TestArchitecture{
    .arm64,
    .x86_64_amd,
    .x86_64_intel,
};

// Check if test is compatible with current architecture.
if (test_framework.is_test_compatible(&supported_archs, arch)) {
    // Run test.
} else {
    // Skip test on unsupported architecture.
}
```

### Basic Usage: Test Runner

```zig
// Initialize test runner.
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
var runner = TestRunner.init(gpa.allocator());
defer runner.deinit();

// Execute single test.
const test_metadata = TestMetadata{
    .name = "my_test",
    .test_fn = my_test_function,
    .supported_archs = &supported_archs,
};
try runner.execute_test(test_metadata);

// Generate test report.
const report = try runner.generate_test_report();
std.debug.print("{s}\n", .{report});
defer gpa.allocator.free(report);
```

---

## Example: Adapting Existing Test

### Original Test

```zig
test "syscall combination: file I/O sequence" {
    const test_setup = create_test_integration();
    // ... test code ...
}
```

### Adapted Test (Multi-Architecture)

```zig
test "syscall combination: file I/O sequence" {
    // Use multi-arch test setup.
    const test_setup = test_framework.create_multi_arch_test_setup();
    
    // Check architecture compatibility.
    const supported_archs = [_]TestArchitecture{
        .arm64,
        .x86_64_amd,
        .x86_64_intel,
    };
    
    if (!test_framework.is_test_compatible(
        &supported_archs,
        test_setup.arch,
    )) {
        // Skip test on unsupported architecture.
        return;
    }
    
    // Test code works identically across architectures.
    const vm = test_setup.vm;
    const kernel = test_setup.kernel;
    const integration = test_setup.integration;
    
    // ... test code ...
    
    // Cleanup.
    test_setup.cleanup();
}
```

---

## Example: JIT Testing (Agent 3b)

```zig
test "JIT compilation: RISC-V to x86_64" {
    const test_setup = test_framework.create_multi_arch_test_setup();
    const arch = test_setup.arch;
    
    // Only run on x86_64 (AMD or Intel).
    if (!arch.is_x86_64()) {
        // Skip on non-x86_64 architectures.
        return;
    }
    
    // Test JIT compilation.
    // ... JIT test code ...
    
    test_setup.cleanup();
}
```

---

## Example: Init System Testing (Agent 3d)

```zig
test "Init System: service lifecycle" {
    const test_setup = test_framework.create_multi_arch_test_setup();
    
    // Support all architectures.
    const supported_archs = [_]TestArchitecture{
        .arm64,
        .x86_64_amd,
        .x86_64_intel,
    };
    
    if (!test_framework.is_test_compatible(
        &supported_archs,
        test_setup.arch,
    )) {
        return;
    }
    
    // Test Init System service lifecycle.
    // ... Init System test code ...
    
    test_setup.cleanup();
}
```

---

## Architecture-Specific Testing

### Framework x86_64 Specific Test

```zig
test "Framework x86_64: specific feature" {
    const arch = test_framework.detect_test_architecture();
    
    // Only run on x86_64 (AMD or Intel).
    if (!arch.is_x86_64()) {
        return;
    }
    
    // Framework x86_64 specific test.
    // ... test code ...
}
```

### AMD vs Intel Specific Test

```zig
test "x86_64 AMD: specific optimization" {
    const arch = test_framework.detect_test_architecture();
    
    // Only run on x86_64 AMD.
    if (arch != .x86_64_amd) {
        return;
    }
    
    // AMD-specific test.
    // ... test code ...
}
```

---

## Integration Test Adapter Usage

### Using Integration Test Adapter

```zig
// Initialize adapter.
var gpa = std.heap.GeneralPurposeAllocator(.{}){};
defer _ = gpa.deinit();
var adapter = test_framework.IntegrationTestAdapter.init(
    gpa.allocator(),
);

// Adapt existing test.
const adapted_test = adapter.adapt_test_with_wrapper(
    "my_test",
    my_original_test_function,
    &supported_archs,
);

// Run adapted test.
try adapted_test();
```

---

## Test Result Reporting

### Human-Readable Report

```zig
// Generate human-readable report.
const report = try runner.generate_test_report();
std.debug.print("{s}\n", .{report});
defer gpa.allocator.free(report);
```

### JSON Report

```zig
// Export JSON report.
const json_report = try runner.export_test_results_json();
std.debug.print("{s}\n", .{json_report});
defer gpa.allocator.free(json_report);
```

---

## Best Practices

1. **Always check architecture compatibility** before running architecture-specific tests.

2. **Use `create_multi_arch_test_setup()`** for architecture-agnostic test setup.

3. **Clean up test setup** with `test_setup.cleanup()` after tests.

4. **Use supported architectures array** to define test compatibility.

5. **Generate test reports** for multi-architecture test runs.

---

**Date**: 2026-01-07-175531-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: ✅ **USAGE GUIDE COMPLETE** — Ready for use by Agents 3b, 3d, and other agents

