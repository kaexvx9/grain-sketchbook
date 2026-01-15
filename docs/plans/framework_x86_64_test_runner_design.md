# Framework x86_64 Test Runner Design

**Date**: 2026-01-01-235155-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Framework x86_64 test infrastructure design  
**Priority**: HIGH — Per Core 1 Subcore coordination plan (2026-01-01-233240-pst)

---

## Executive Summary

**Objective**: Design and implement a test runner for Framework x86_64 that enables integration tests to run natively on Framework 16 (x86_64 AMD) and legacy Intel x86_64 hardware.

**Why**: Support Framework Ubuntu x86 development, enable native x86_64 test execution, validate system behavior on Framework hardware, and support legacy Intel hardware for Dispatch software deployment.

**Timeline**: Week 2-3 (implementation after framework design approval)

---

## Framework x86_64 Environment

### Hardware Specifications

**Framework 16 (Primary Target)**:
- **Architecture**: x86_64 AMD
- **CPU**: AMD Ryzen (specific model TBD)
- **RAM**: 64GB
- **OS**: Ubuntu 24.04 LTS
- **Native Development**: Direct x86_64 compilation (no emulation)

**Legacy Intel Hardware (Secondary Target)**:
- **Architecture**: x86_64 Intel
- **CPU**: Various Intel processors (legacy systems)
- **RAM**: Variable (typically 8-16GB)
- **OS**: Ubuntu 24.04 LTS (or compatible)
- **Use Case**: Dispatch software deployment on existing first-responder systems

### Build System Configuration

**Target Architecture**: x86_64 native (Framework Ubuntu)  
**Kernel Target**: RISC-V (Basin Kernel runs in VM)  
**JIT Target**: x86_64 (VM Runtime compiles RISC-V → x86_64)  
**Language**: Zig 0.15.2

---

## Test Runner Architecture

### Core Components

1. **Test Runner Main** (`tools/test_runner_framework_x86_64.zig`)
   - Architecture detection (x86_64 AMD vs Intel)
   - Test execution orchestration
   - Test result collection and reporting

2. **Test Execution Engine** (`src/test_framework/execution.zig`)
   - Test process spawning
   - Test execution monitoring
   - Test timeout handling
   - Test failure detection

3. **Test Result Aggregator** (`src/test_framework/aggregator.zig`)
   - Test result collection
   - Test result formatting
   - Test result reporting (JSON, human-readable)

4. **Test Configuration** (`src/test_framework/config.zig`)
   - Architecture-specific test configuration
   - Test filtering (by architecture, by test name)
   - Test timeout configuration

---

## Test Runner Design

### Architecture Detection

**Why**: Distinguish between x86_64 AMD (Framework 16) and x86_64 Intel (legacy hardware) for architecture-specific testing.

**Implementation**:
```zig
/// Test architecture for x86_64.
pub const X86_64Architecture = enum(u8) {
    amd = 0,  // Framework 16 (AMD Ryzen)
    intel = 1, // Legacy Intel hardware
    unknown = 255,
};

/// Detect x86_64 architecture variant.
/// Why: Distinguish AMD vs Intel for architecture-specific testing.
/// Contract: Returns detected architecture or unknown.
/// Grain Style: Explicit types, bounded operations, assertions.
pub fn detect_x86_64_architecture() X86_64Architecture {
    // Assert: Must be running on x86_64 (precondition).
    std.debug.assert(builtin.cpu.arch == .x86_64);
    
    // Note: Use CPUID to detect vendor (AMD vs Intel).
    // For now, default to AMD (Framework 16).
    // TODO: Implement CPUID detection for Intel vs AMD.
    const vendor = detect_cpu_vendor();
    
    // Assert: Vendor must be valid (postcondition).
    std.debug.assert(@intFromEnum(vendor) < 255);
    
    return vendor;
}

/// Detect CPU vendor via CPUID.
/// Why: Distinguish AMD vs Intel processors.
/// Contract: Returns detected vendor or unknown.
/// Grain Style: Explicit types, bounded operations.
fn detect_cpu_vendor() X86_64Architecture {
    // Note: CPUID instruction returns vendor string.
    // AMD: "AuthenticAMD"
    // Intel: "GenuineIntel"
    // For now, return AMD as default (Framework 16).
    // TODO: Implement actual CPUID call.
    return .amd;
}
```

### Test Execution Strategy

**Strategy**: Sequential execution with architecture-specific filtering

**Why**: Run tests sequentially to ensure deterministic behavior and proper resource management.

**Implementation**:
```zig
/// Test execution configuration.
pub const TestExecutionConfig = struct {
    /// Target architecture.
    target_arch: X86_64Architecture,
    
    /// Test filter (optional).
    test_filter: ?[]const u8,
    
    /// Test timeout (nanoseconds).
    test_timeout_ns: u64,
    
    /// Maximum test failures before stopping.
    max_failures: u32,
    
    /// Initialize test execution configuration.
    /// Why: Set up test execution with defaults.
    /// Contract: Returns valid configuration.
    pub fn init(target_arch: X86_64Architecture) TestExecutionConfig {
        return TestExecutionConfig{
            .target_arch = target_arch,
            .test_filter = null,
            .test_timeout_ns = 30 * 1000 * 1000 * 1000, // 30 seconds default
            .max_failures = 10, // Stop after 10 failures
        };
    }
};

/// Execute tests with configuration.
/// Why: Run integration tests on Framework x86_64.
/// Contract: Returns test execution results.
/// Grain Style: Explicit types, bounded operations, assertions.
pub fn execute_tests(config: TestExecutionConfig) !TestResults {
    // Assert: Configuration must be valid (precondition).
    std.debug.assert(config.test_timeout_ns > 0);
    std.debug.assert(config.max_failures > 0);
    
    // Detect current architecture.
    const current_arch = detect_x86_64_architecture();
    
    // Assert: Current architecture must match target (postcondition).
    if (current_arch != config.target_arch) {
        // Note: Allow unknown architecture for development.
        if (current_arch != .unknown) {
            return error.ArchitectureMismatch;
        }
    }
    
    // Execute tests sequentially.
    var results = TestResults.init();
    defer results.deinit();
    
    // Filter tests by architecture compatibility.
    const compatible_tests = filter_tests_by_architecture(config.target_arch);
    
    // Execute each test.
    for (compatible_tests) |test_name| {
        const test_result = try execute_single_test(test_name, config);
        try results.add_result(test_result);
        
        // Stop if max failures reached.
        if (results.failed_tests >= config.max_failures) {
            break;
        }
    }
    
    // Assert: Results must be valid (postcondition).
    std.debug.assert(results.total_tests > 0);
    
    return results;
}
```

### Test Result Reporting

**Format**: JSON for CI/CD integration, human-readable for development

**Implementation**:
```zig
/// Test result structure.
pub const TestResult = struct {
    /// Test name.
    test_name: []const u8,
    
    /// Test passed.
    passed: bool,
    
    /// Test duration (nanoseconds).
    duration_ns: u64,
    
    /// Test error message (if failed).
    error_message: ?[]const u8,
    
    /// Architecture tested.
    architecture: X86_64Architecture,
};

/// Test results aggregation.
pub const TestResults = struct {
    /// Results array.
    results: std.ArrayList(TestResult),
    
    /// Total tests.
    total_tests: u32,
    
    /// Passed tests.
    passed_tests: u32,
    
    /// Failed tests.
    failed_tests: u32,
    
    /// Initialize test results.
    /// Why: Set up results collection.
    pub fn init() TestResults {
        return TestResults{
            .results = std.ArrayList(TestResult).init(std.heap.page_allocator),
            .total_tests = 0,
            .passed_tests = 0,
            .failed_tests = 0,
        };
    }
    
    /// Add test result.
    /// Why: Collect test execution results.
    /// Contract: Result must be valid.
    pub fn add_result(self: *TestResults, result: TestResult) !void {
        // Assert: Result must be valid (precondition).
        std.debug.assert(result.test_name.len > 0);
        
        try self.results.append(result);
        self.total_tests += 1;
        
        if (result.passed) {
            self.passed_tests += 1;
        } else {
            self.failed_tests += 1;
        }
        
        // Assert: Counts must be consistent (postcondition).
        std.debug.assert(self.passed_tests + self.failed_tests == self.total_tests);
    }
    
    /// Generate JSON report.
    /// Why: Export test results for CI/CD integration.
    /// Contract: Returns valid JSON string.
    pub fn to_json(self: *const TestResults) ![]const u8 {
        // TODO: Implement JSON serialization.
        // For now, return placeholder.
        return "{}";
    }
    
    /// Generate human-readable report.
    /// Why: Display test results for development.
    /// Contract: Returns formatted string.
    pub fn to_string(self: *const TestResults) ![]const u8 {
        // TODO: Implement human-readable formatting.
        // For now, return placeholder.
        return "";
    }
    
    /// Deinitialize test results.
    /// Why: Clean up allocated memory.
    pub fn deinit(self: *TestResults) void {
        self.results.deinit();
    }
};
```

---

## Test Execution Script

### Shell Script Design

**Component**: `tools/run_tests_framework_x86_64.sh`

**Features**:
- Execute all integration tests on Framework x86_64
- Report test results
- Handle test failures
- Generate test reports

**Implementation**:
```bash
#!/bin/bash
# Framework x86_64 Test Runner Script
# Why: Execute integration tests on Framework x86_64 hardware.
# Grain Style: Clear, direct, helpful.

set -euo pipefail

# Configuration.
ARCHITECTURE="${ARCHITECTURE:-amd}"  # Default to AMD (Framework 16)
TEST_FILTER="${TEST_FILTER:-}"       # Optional test filter
OUTPUT_DIR="${OUTPUT_DIR:-./test_results}"  # Test results directory

# Create output directory.
mkdir -p "$OUTPUT_DIR"

# Execute tests via Zig test runner.
zig build test --summary all

# Generate test report.
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REPORT_FILE="$OUTPUT_DIR/test_results_${ARCHITECTURE}_${TIMESTAMP}.json"

# Note: Test runner will generate JSON report.
# For now, create placeholder report.
echo "{\"architecture\": \"$ARCHITECTURE\", \"timestamp\": \"$TIMESTAMP\"}" > "$REPORT_FILE"

# Report results.
echo "Test execution complete."
echo "Results: $REPORT_FILE"
```

---

## Integration with build.zig

### Test Runner Integration

**Why**: Integrate Framework x86_64 test runner with existing build system.

**Implementation** (add to `build.zig`):
```zig
// Framework x86_64 test runner.
const framework_x86_64_test_runner = b.addExecutable(.{
    .name = "test_runner_framework_x86_64",
    .root_module = b.createModule(.{
        .root_source_file = b.path("tools/test_runner_framework_x86_64.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "test_framework", .module = test_framework_module },
            .{ .name = "kernel_vm", .module = kernel_vm_module },
            .{ .name = "basin_kernel", .module = basin_kernel_module },
        },
    }),
});

// Test runner run step.
const framework_x86_64_test_runner_run = b.addRunArtifact(framework_x86_64_test_runner);
const framework_x86_64_test_step = b.step("test:framework-x86-64", "Run tests on Framework x86_64");
framework_x86_64_test_step.dependOn(&framework_x86_64_test_runner_run.step);
```

---

## Test Execution Patterns

### Pattern 1: Architecture-Specific Test Execution

**Why**: Some tests may only run on specific architectures (e.g., Framework x86_64 specific features).

**Implementation**:
```zig
/// Execute architecture-specific tests.
/// Why: Run tests that are specific to Framework x86_64.
test "Framework x86_64: architecture-specific tests" {
    const arch = detect_x86_64_architecture();
    
    // Only run on x86_64 architectures.
    if (arch != .amd and arch != .intel) {
        return; // Skip on non-x86_64 architectures.
    }
    
    // Execute Framework x86_64 specific tests.
    test_framework_x86_64_features();
}
```

### Pattern 2: Cross-Architecture Test Comparison

**Why**: Compare test results across architectures to validate consistency.

**Implementation**:
```zig
/// Compare test results across architectures.
/// Why: Validate test behavior is consistent across architectures.
pub fn compare_test_results(
    arm64_results: TestResults,
    x86_64_amd_results: TestResults,
    x86_64_intel_results: ?TestResults,
) !ComparisonReport {
    // Compare test results.
    // Assert: Test counts should match (postcondition).
    std.debug.assert(arm64_results.total_tests == x86_64_amd_results.total_tests);
    
    // Generate comparison report.
    return ComparisonReport{
        .arm64 = arm64_results,
        .x86_64_amd = x86_64_amd_results,
        .x86_64_intel = x86_64_intel_results,
    };
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

### Example: Grain Style Compliant Function

```zig
/// Execute single test.
/// Why: Run one integration test with timeout handling.
/// Contract: Returns test result or error.
/// Grain Style: Explicit types, bounded operations, assertions.
fn execute_single_test(
    test_name: []const u8,
    config: TestExecutionConfig,
) !TestResult {
    // Assert: Test name must be valid (precondition).
    std.debug.assert(test_name.len > 0);
    std.debug.assert(config.test_timeout_ns > 0);
    
    const start_time = std.time.nanoTimestamp();
    
    // Execute test (with timeout).
    const test_passed = execute_test_with_timeout(test_name, config.test_timeout_ns);
    
    const end_time = std.time.nanoTimestamp();
    const duration_ns = @as(u64, @intCast(end_time - start_time));
    
    // Assert: Duration must be valid (postcondition).
    std.debug.assert(duration_ns <= config.test_timeout_ns);
    
    return TestResult{
        .test_name = test_name,
        .passed = test_passed,
        .duration_ns = duration_ns,
        .error_message = null,
        .architecture = config.target_arch,
    };
}
```

---

## Implementation Phases

### Phase 1: Test Runner Design (WEEK 2)

**Status**: 🆕 **IN PROGRESS**

**Tasks**:
- [x] Create test runner design document
- [ ] Design architecture detection
- [ ] Design test execution engine
- [ ] Design test result aggregation
- [ ] Design test configuration

**Deliverables**:
- Test runner design document (this document)
- Architecture detection design
- Test execution engine design

---

### Phase 2: Test Runner Implementation (WEEK 2-3)

**Status**: ⏳ **PENDING** — After Phase 1 completion

**Tasks**:
- [ ] Implement architecture detection (`src/test_framework/arch_x86_64.zig`)
- [ ] Implement test execution engine (`src/test_framework/execution.zig`)
- [ ] Implement test result aggregator (`src/test_framework/aggregator.zig`)
- [ ] Implement test configuration (`src/test_framework/config.zig`)
- [ ] Implement test runner main (`tools/test_runner_framework_x86_64.zig`)
- [ ] Create test execution script (`tools/run_tests_framework_x86_64.sh`)
- [ ] Integrate with build.zig

**Deliverables**:
- Test runner implementation
- Test execution script
- build.zig integration

---

### Phase 3: Test Execution Validation (WEEK 3)

**Status**: ⏳ **PENDING** — After Phase 2 completion

**Tasks**:
- [ ] Execute all 44 integration tests on Framework x86_64
- [ ] Validate test execution results
- [ ] Compare results with ARM64 execution
- [ ] Document any architecture-specific issues

**Deliverables**:
- Test execution validation results
- Architecture comparison report
- Issue tracking document

---

## Coordination Needs

### With Vantage 3 Subcore

**Status**: ⏳ **PENDING APPROVAL**

**Needs**:
- Approve test runner design approach
- Coordinate Framework x86_64 test infrastructure setup
- Coordinate test execution timeline

**Timeline**: IMMEDIATE (this week)

---

### With Core 1 Subcore

**Status**: ⏳ **PENDING REQUIREMENTS**

**Needs**:
- Framework x86_64 test infrastructure requirements
- Core 1 services (1a-1d) test execution requirements
- Grainscript Shell (1e) test execution requirements

**Timeline**: IMMEDIATE (this week)

---

## Success Criteria

### Week 2 Success
- ✅ Test runner design complete
- ✅ Architecture detection design complete
- ✅ Test execution engine design complete

### Week 3 Success
- ✅ Test runner implementation complete
- ✅ Test execution script working
- ✅ All 44 integration tests running on Framework x86_64

---

**Date**: 2026-01-01-235155-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Framework x86_64 test infrastructure design  
**Priority**: HIGH — Per Core 1 Subcore coordination plan (2026-01-01-233240-pst)

