# Multi-Architecture Testing Framework Design

**Date**: 2026-01-01-233240-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Phase 1: Framework design  
**Priority**: HIGH — Per Core 1 Subcore coordination plan (2026-01-01-233240-pst)

---

## Executive Summary

**Objective**: Design and implement a multi-architecture testing framework that enables integration tests to run across ARM64 (MacBook Air M2), x86_64 AMD (Framework 16), and x86_64 Intel (including legacy hardware).

**Why**: Support Framework Ubuntu x86 development, enable RISC-V → x86_64 JIT pipeline testing, support legacy Intel hardware for Dispatch software deployment, and validate system behavior across all target architectures.

**Timeline**: Week 1-4 (design and initial implementation)

---

## Architecture Support Matrix

### Target Architectures

| Architecture | Platform | Use Case | Priority |
|-------------|----------|----------|----------|
| **ARM64** | macOS (MacBook Air M2) | Development/testing | HIGH |
| **x86_64 AMD** | Framework 16 Ubuntu | Primary deployment target | HIGH |
| **x86_64 Intel** | Legacy hardware | Dispatch software deployment | HIGH |

### Architecture Detection

**Method**: Use Zig `builtin.cpu.arch` for runtime architecture detection, with CPUID for x86_64 vendor detection

**Implementation**:
```zig
//! Architecture Detection for Multi-Architecture Testing
//! Why: Detect host architecture (ARM64, x86_64 AMD, x86_64 Intel) for test framework.
//! Grain Style: Explicit types (u32/u64), bounded operations, assertions.

const std = @import("std");
const builtin = @import("builtin");

/// Test architecture enumeration.
/// Why: Explicit architecture types for test framework.
/// GrainStyle: Explicit enum values, bounded range.
pub const TestArchitecture = enum(u8) {
    arm64 = 0,
    x86_64_amd = 1,
    x86_64_intel = 2,
    unknown = 255,
    
    /// Check if architecture is x86_64 (AMD or Intel).
    /// Why: Determine if architecture is x86_64 variant.
    /// Contract: Returns true if x86_64, false otherwise.
    pub fn is_x86_64(self: TestArchitecture) bool {
        return self == .x86_64_amd or self == .x86_64_intel;
    }
    
    /// Check if architecture is supported.
    /// Why: Determine if architecture is supported for testing.
    /// Contract: Returns true if supported, false otherwise.
    pub fn is_supported(self: TestArchitecture) bool {
        return self != .unknown;
    }
};

/// CPU vendor enumeration (x86_64 only).
/// Why: Distinguish AMD vs Intel processors.
/// GrainStyle: Explicit enum values, bounded range.
pub const CpuVendor = enum(u8) {
    amd = 0,
    intel = 1,
    unknown = 255,
};

/// Detect current test architecture.
/// Why: Determine which architecture tests are running on.
/// Contract: Returns detected architecture or unknown.
/// GrainStyle: Explicit types, bounded operations, assertions.
pub fn detect_test_architecture() TestArchitecture {
    // Assert: builtin.cpu.arch must be valid (precondition).
    _ = builtin.cpu.arch;
    
    return switch (builtin.cpu.arch) {
        .aarch64 => .arm64,
        .x86_64 => {
            // Distinguish AMD vs Intel via CPUID.
            const vendor = detect_cpu_vendor();
            
            // Assert: Vendor must be valid (postcondition).
            std.debug.assert(@intFromEnum(vendor) < 255);
            
            return switch (vendor) {
                .amd => .x86_64_amd,
                .intel => .x86_64_intel,
                .unknown => .x86_64_amd, // Default to AMD (Framework 16).
            };
        },
        else => .unknown,
    };
}

/// Detect CPU vendor via CPUID (x86_64 only).
/// Why: Distinguish AMD vs Intel processors for architecture-specific testing.
/// Contract: Returns detected vendor or unknown.
/// GrainStyle: Explicit types, bounded operations, assertions.
/// Note: Uses inline assembly for CPUID instruction (x86_64 only).
fn detect_cpu_vendor() CpuVendor {
    // Assert: Must be running on x86_64 (precondition).
    if (builtin.cpu.arch != .x86_64) {
        return .unknown; // Not x86_64, cannot detect vendor.
    }
    
    // CPUID instruction: EAX=0 returns vendor string in EBX, EDX, ECX.
    // Vendor strings:
    // - "GenuineIntel" (Intel): EBX=0x756e6547, EDX=0x49656e69, ECX=0x6c65746e
    // - "AuthenticAMD" (AMD): EBX=0x68747541, EDX=0x69746e65, ECX=0x444d4163
    
    var eax: u32 = 0;
    var ebx: u32 = undefined;
    var ecx: u32 = undefined;
    var edx: u32 = undefined;
    
    // Execute CPUID with EAX=0.
    asm volatile (
        \\ cpuid
        : [eax] "={eax}" (eax),
          [ebx] "={ebx}" (ebx),
          [ecx] "={ecx}" (ecx),
          [edx] "={edx}" (edx),
        : [eax_in] "{eax}" (@as(u32, 0)),
        : "memory"
    );
    
    // Check for Intel vendor string.
    if (ebx == 0x756e6547 and edx == 0x49656e69 and ecx == 0x6c65746e) {
        return .intel;
    }
    
    // Check for AMD vendor string.
    if (ebx == 0x68747541 and edx == 0x69746e65 and ecx == 0x444d4163) {
        return .amd;
    }
    
    // Unknown vendor.
    return .unknown;
}

/// Get architecture name string.
/// Why: Provide human-readable architecture name for test reporting.
/// Contract: Returns architecture name string.
/// GrainStyle: Explicit types, bounded operations.
pub fn get_architecture_name(arch: TestArchitecture) []const u8 {
    return switch (arch) {
        .arm64 => "ARM64",
        .x86_64_amd => "x86_64 AMD",
        .x86_64_intel => "x86_64 Intel",
        .unknown => "Unknown",
    };
}

/// Check if architecture supports JIT compilation.
/// Why: Determine if architecture supports JIT compilation for testing.
/// Contract: Returns true if JIT supported, false otherwise.
/// GrainStyle: Explicit types, bounded operations.
pub fn supports_jit(arch: TestArchitecture) bool {
    // JIT compilation supported on ARM64 and x86_64 (AMD and Intel).
    return arch != .unknown;
}

/// Check if architecture requires JIT compilation.
/// Why: Determine if architecture requires JIT for RISC-V execution.
/// Contract: Returns true if JIT required, false otherwise.
/// GrainStyle: Explicit types, bounded operations.
pub fn requires_jit(arch: TestArchitecture) bool {
    // JIT required on x86_64 (AMD and Intel) for RISC-V → x86_64 translation.
    return arch.is_x86_64();
}
```

---

## Framework Architecture

### Core Components

1. **Architecture Abstraction Layer** (`src/test_framework/arch.zig`)
   - Architecture detection and selection
   - Architecture-specific test configuration
   - Architecture compatibility checking

2. **Test Helpers** (`src/test_framework/helpers.zig`)
   - Architecture-agnostic test setup/teardown
   - Cross-architecture test utilities
   - Test result aggregation

3. **Test Runner** (`src/test_framework/runner.zig`)
   - Multi-architecture test execution
   - Test result reporting
   - Architecture-specific test filtering

4. **Integration Test Adapter** (`src/test_framework/integration_adapter.zig`)
   - Adapt existing 44 integration tests for multi-arch
   - Test execution strategy
   - Test failure handling

---

## Design Patterns

### Pattern 1: Architecture-Agnostic Test Setup

**Why**: Tests should work identically across all architectures without architecture-specific code.

**Implementation**:
```zig
/// Create test integration (architecture-agnostic).
/// Why: Tests work identically across ARM64, x86_64 AMD, x86_64 Intel.
/// Contract: Returns initialized Integration instance, architecture detected automatically.
pub fn create_test_integration() struct { 
    vm: VM, 
    kernel: BasinKernel, 
    integration: Integration,
    arch: TestArchitecture,
} {
    const arch = detect_test_architecture();
    
    // Architecture-agnostic VM initialization.
    var vm: VM = undefined;
    VM.init(&vm, &[_]u8{}, 0x80000000);
    
    var kernel = BasinKernel.init();
    var integration = Integration.init_with_kernel(&vm, &kernel);
    integration.finish_init();
    
    return .{ 
        .vm = vm, 
        .kernel = kernel, 
        .integration = integration,
        .arch = arch,
    };
}
```

### Pattern 2: Architecture-Specific Test Validation

**Why**: Some tests need to validate architecture-specific behavior (e.g., JIT compilation, syscall interface).

**Implementation**:
```zig
/// Test JIT compilation across architectures.
/// Why: Validate RISC-V → ARM64 and RISC-V → x86_64 JIT compilation.
test "JIT compilation: architecture-specific" {
    const test_setup = create_test_integration();
    const arch = test_setup.arch;
    
    // Architecture-specific JIT test.
    switch (arch) {
        .arm64 => {
            // Test RISC-V → ARM64 JIT.
            test_jit_riscv_to_arm64(&test_setup);
        },
        .x86_64_amd, .x86_64_intel => {
            // Test RISC-V → x86_64 JIT.
            test_jit_riscv_to_x86_64(&test_setup);
        },
        else => {
            // Skip test on unknown architecture.
            return;
        },
    }
}
```

### Pattern 3: Architecture Compatibility Matrix

**Why**: Some tests may only run on specific architectures (e.g., Framework x86_64 specific features).

**Implementation**:
```zig
/// Architecture compatibility matrix.
/// Why: Define which tests run on which architectures.
pub const ArchitectureCompatibility = struct {
    /// Test name.
    test_name: []const u8,
    
    /// Supported architectures.
    supported_archs: []const TestArchitecture,
    
    /// Check if test is compatible with architecture.
    pub fn is_compatible(self: *const ArchitectureCompatibility, arch: TestArchitecture) bool {
        for (self.supported_archs) |supported_arch| {
            if (supported_arch == arch) {
                return true;
            }
        }
        return false;
    }
};

/// Framework x86_64 specific test compatibility.
const framework_x86_64_tests = [_]ArchitectureCompatibility{
    .{ .test_name = "Framework x86_64 JIT test", .supported_archs = &.{ .x86_64_amd, .x86_64_intel } },
    .{ .test_name = "Framework x86_64 syscall test", .supported_archs = &.{ .x86_64_amd, .x86_64_intel } },
};
```

---

## Test Execution Strategy

### Strategy 1: Sequential Execution (Default)

**Why**: Run tests sequentially on each architecture to ensure deterministic behavior.

**Implementation**:
1. Detect current architecture
2. Filter tests by architecture compatibility
3. Execute tests sequentially
4. Aggregate results per architecture

### Strategy 2: Parallel Execution (Optional)

**Why**: Run tests in parallel across architectures when multiple test environments are available.

**Implementation**:
1. Spawn test processes for each architecture
2. Execute tests in parallel
3. Collect results from all processes
4. Aggregate and report results

---

## Integration with Existing Tests

### Adapter Pattern

**Why**: Adapt existing 44 integration tests for multi-architecture without rewriting tests.

**Implementation**:
1. Wrap existing test functions with architecture detection
2. Add architecture-specific test configuration
3. Add architecture-specific test validation
4. Maintain backward compatibility

### Example: Adapting Existing Test

```zig
// Original test (architecture-agnostic).
test "syscall combination: file I/O sequence" {
    const test_setup = create_test_integration();
    // ... test implementation ...
}

// Adapted test (multi-architecture).
test "syscall combination: file I/O sequence (multi-arch)" {
    const test_setup = create_test_integration();
    const arch = test_setup.arch;
    
    // Architecture-specific validation (if needed).
    if (arch == .unknown) {
        // Skip test on unknown architecture.
        return;
    }
    
    // Original test implementation (unchanged).
    // ... test implementation ...
}
```

---

## Framework x86_64 Test Infrastructure

### Test Runner Design

**Component**: `tools/test_runner_framework_x86_64.zig`

**Features**:
- Framework x86_64 test execution
- Test result reporting
- Test failure handling
- Integration with build.zig

### Test Execution Script

**Component**: `tools/run_tests_framework_x86_64.sh`

**Features**:
- Execute all integration tests on Framework x86_64
- Report test results
- Handle test failures
- Generate test reports

---

## Test Patterns for Specific Scenarios

### Pattern 1: JIT Compilation Testing

**Why**: Validate RISC-V → ARM64 and RISC-V → x86_64 JIT compilation.

**Implementation**:
```zig
/// Test JIT compilation across architectures.
test "JIT compilation: RISC-V to host architecture" {
    const test_setup = create_test_integration();
    const arch = test_setup.arch;
    
    // Architecture-specific JIT test.
    switch (arch) {
        .arm64 => test_jit_riscv_to_arm64(&test_setup),
        .x86_64_amd, .x86_64_intel => test_jit_riscv_to_x86_64(&test_setup),
        else => return, // Skip on unknown architecture.
    }
}
```

### Pattern 2: Syscall Interface Testing

**Why**: Validate syscall interface works correctly on Framework x86_64.

**Implementation**:
```zig
/// Test syscall interface on Framework x86_64.
test "syscall interface: Framework x86_64" {
    const test_setup = create_test_integration();
    const arch = test_setup.arch;
    
    // Only run on x86_64 architectures.
    if (arch != .x86_64_amd and arch != .x86_64_intel) {
        return; // Skip on non-x86_64 architectures.
    }
    
    // Test syscall interface.
    test_syscall_interface(&test_setup);
}
```

### Pattern 3: Init System Integration Testing

**Why**: Validate sevenos Init System (3d) works correctly across architectures.

**Implementation**:
```zig
/// Test Init System integration across architectures.
test "Init System: multi-architecture integration" {
    const test_setup = create_test_integration();
    const arch = test_setup.arch;
    
    // Test Init System integration (architecture-agnostic).
    test_init_system_integration(&test_setup);
    
    // Architecture-specific validation (if needed).
    switch (arch) {
        .x86_64_amd, .x86_64_intel => {
            // Framework x86_64 specific Init System tests.
            test_init_system_framework_x86_64(&test_setup);
        },
        else => {},
    }
}
```

### Pattern 4: Grainscript Shell Integration Testing

**Why**: Validate Grainscript Shell (1e) works correctly across architectures.

**Implementation**:
```zig
/// Test Grainscript Shell integration across architectures.
test "Grainscript Shell: multi-architecture integration" {
    const test_setup = create_test_integration();
    const arch = test_setup.arch;
    
    // Test Shell integration (architecture-agnostic).
    test_shell_integration(&test_setup);
    
    // Architecture-specific validation (if needed).
    switch (arch) {
        .x86_64_amd, .x86_64_intel => {
            // Framework x86_64 specific Shell tests.
            test_shell_framework_x86_64(&test_setup);
        },
        else => {},
    }
}
```

---

## Test Result Aggregation and Reporting

### Result Format

**Structure**:
```zig
/// Test result per architecture.
pub const ArchitectureTestResult = struct {
    /// Architecture.
    arch: TestArchitecture,
    
    /// Test name.
    test_name: []const u8,
    
    /// Test passed.
    passed: bool,
    
    /// Test duration (nanoseconds).
    duration_ns: u64,
    
    /// Test error message (if failed).
    error_message: ?[]const u8,
};

/// Aggregated test results.
pub const TestResults = struct {
    /// Results per architecture.
    results: []ArchitectureTestResult,
    
    /// Total tests.
    total_tests: u32,
    
    /// Passed tests.
    passed_tests: u32,
    
    /// Failed tests.
    failed_tests: u32,
};
```

### Reporting

**Format**: JSON report for CI/CD integration

**Location**: `test_results_<architecture>_<timestamp>.json`

**Example**:
```json
{
  "architecture": "x86_64_amd",
  "timestamp": "2026-01-01T23:32:40Z",
  "total_tests": 44,
  "passed_tests": 42,
  "failed_tests": 2,
  "results": [
    {
      "test_name": "syscall combination: file I/O sequence",
      "passed": true,
      "duration_ns": 1234567
    }
  ]
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
/// Detect test architecture.
/// Why: Determine which architecture tests are running on.
/// Contract: Returns detected architecture or unknown.
/// Grain Style: Explicit types, bounded operations, assertions.
pub fn detect_test_architecture() TestArchitecture {
    // Assert: Must be called from test context (precondition).
    std.debug.assert(@inComptime() == false);
    
    const arch = builtin.cpu.arch;
    
    // Assert: Architecture must be valid (postcondition).
    const result = switch (arch) {
        .aarch64 => TestArchitecture.arm64,
        .x86_64 => TestArchitecture.x86_64_amd, // Default to AMD.
        else => TestArchitecture.unknown,
    };
    
    // Assert: Result must be valid (postcondition).
    std.debug.assert(@intFromEnum(result) < 255);
    
    return result;
}
```

---

## Implementation Phases

### Phase 1: Framework Design (WEEK 1-2)

**Status**: 🆕 **IN PROGRESS**

**Tasks**:
- [x] Create framework design document
- [x] Design architecture abstraction layer (architecture detection expanded with CPUID-based vendor detection)
- [ ] Design test helpers
- [ ] Design test runner
- [ ] Design integration test adapter
- [ ] Design test result aggregation

**Deliverables**:
- Framework design document (this document)
- Architecture abstraction layer design
- Test helper design
- Test runner design

---

### Phase 2: Framework Implementation (WEEK 2-3)

**Status**: ⏳ **PENDING** — After Phase 1 completion

**Tasks**:
- [ ] Implement architecture abstraction layer (`src/test_framework/arch.zig`)
- [ ] Implement test helpers (`src/test_framework/helpers.zig`)
- [ ] Implement test runner (`src/test_framework/runner.zig`)
- [ ] Implement integration test adapter (`src/test_framework/integration_adapter.zig`)
- [ ] Implement test result aggregation
- [ ] Add to build.zig

**Deliverables**:
- Architecture abstraction layer implementation
- Test helpers implementation
- Test runner implementation
- Integration test adapter implementation

---

### Phase 3: Existing Test Adaptation (WEEK 3-4)

**Status**: ⏳ **PENDING** — After Phase 2 completion

**Tasks**:
- [ ] Adapt existing 44 integration tests for multi-architecture
- [ ] Add architecture-specific test validation
- [ ] Add test result reporting
- [ ] Validate test execution across architectures

**Deliverables**:
- Adapted integration tests (44 tests)
- Test execution validation results
- Test result reports

---

## Coordination Needs

### With Vantage 3 Subcore

**Status**: ⏳ **PENDING APPROVAL**

**Needs**:
- Approve framework design approach
- Coordinate Framework x86_64 test infrastructure
- Coordinate sevenos Init System (3d) integration testing
- Coordinate VM Runtime (3b) JIT testing
- Coordinate Basin Kernel (3a) syscall interface testing

**Timeline**: IMMEDIATE (this week)

---

### With Core 1 Subcore

**Status**: ⏳ **PENDING REQUIREMENTS**

**Needs**:
- Framework x86_64 test infrastructure requirements
- sevenos Init System (3d) integration testing requirements
- Grainscript Shell (1e) integration testing requirements
- Core 1 services (1a-1d) integration testing requirements

**Timeline**: IMMEDIATE (this week)

---

### With VM Runtime Agent (3b)

**Status**: ⏳ **PENDING COORDINATION**

**Needs**:
- JIT compilation testing requirements
- RISC-V → ARM64 JIT testing requirements
- RISC-V → x86_64 JIT testing requirements

**Timeline**: ONGOING (as JIT implementation progresses)

---

### With Basin Kernel Agent (3a)

**Status**: ⏳ **PENDING COORDINATION**

**Needs**:
- Syscall interface documentation for testing
- Syscall interface testing requirements
- Framework x86_64 syscall interface testing requirements

**Timeline**: ONGOING (as syscall interface documentation progresses)

---

## Success Criteria

### Week 1 Success
- ✅ Framework design document complete
- ✅ Architecture abstraction layer design complete
- ✅ Test helper design complete
- ✅ Test runner design complete

### Week 2 Success
- ✅ Framework implementation complete
- ✅ Architecture abstraction layer implemented
- ✅ Test helpers implemented
- ✅ Test runner implemented

### Week 3 Success
- ✅ Existing tests adapted for multi-architecture
- ✅ Test execution validated on Framework x86_64
- ✅ Test result reporting working

### Week 4 Success
- ✅ All 44 integration tests running on Framework x86_64
- ✅ Test results aggregated and reported
- ✅ Framework x86_64 test infrastructure complete

---

**Date**: 2026-01-01-233240-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Phase 1: Framework design  
**Priority**: HIGH — Per Core 1 Subcore coordination plan (2026-01-01-233240-pst)

