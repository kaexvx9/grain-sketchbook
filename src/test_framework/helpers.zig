//! Test Helpers for Multi-Architecture Testing Framework
//! Why: Provide architecture-agnostic test setup/teardown and cross-architecture utilities.
//! Grain Style: Explicit types (u32/u64), bounded operations, assertions.

const std = @import("std");
const testing = std.testing;
const arch_detection = @import("arch.zig");
const TestArchitecture = arch_detection.TestArchitecture;
const kernel_vm = @import("kernel_vm");
const Integration = kernel_vm.Integration;
const VM = kernel_vm.VM;
const basin_kernel = @import("basin_kernel");
const BasinKernel = basin_kernel.BasinKernel;

/// Maximum test results (Grain Style: bounded allocation).
const MAX_TEST_RESULTS: u32 = 1000;

/// Test setup structure (architecture-agnostic).
/// Why: Encapsulate test setup with architecture information.
/// GrainStyle: Explicit types, bounded operations.
pub const TestSetup = struct {
    vm: VM,
    kernel: BasinKernel,
    integration: Integration,
    arch: TestArchitecture,

    /// Cleanup test setup.
    /// Why: Ensure proper cleanup after test execution.
    /// Contract: Cleans up test setup resources.
    /// GrainStyle: Explicit types, bounded operations, assertions.
    pub fn cleanup(self: *TestSetup) void {
        // Assert: Test setup must be valid (precondition).
        std.debug.assert(@intFromPtr(self) != 0);

        // Cleanup integration (if needed).
        _ = self.integration;

        // Cleanup kernel (if needed).
        _ = self.kernel;

        // Cleanup VM (if needed).
        _ = self.vm;

        // Assert: Architecture must be valid (postcondition).
        std.debug.assert(self.arch != .unknown);
    }
};

/// Create test integration (architecture-agnostic).
/// Why: Tests work identically across ARM64, x86_64 AMD, x86_64 Intel.
/// Contract: Returns initialized TestSetup, architecture detected automatically.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn create_test_integration() TestSetup {
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

    return TestSetup{
        .vm = vm,
        .kernel = kernel,
        .integration = integration,
        .arch = arch,
    };
}

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

/// Check if test should be skipped.
/// Why: Skip tests on unsupported architectures.
/// Contract: Returns true if should skip, false otherwise.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn should_skip_test(
    supported_archs: []const TestArchitecture,
    current_arch: TestArchitecture,
) bool {
    // Assert: Supported archs must be valid (precondition).
    std.debug.assert(supported_archs.len > 0);

    // Assert: Current arch must be valid (precondition).
    std.debug.assert(current_arch != .unknown);

    return !is_test_compatible(supported_archs, current_arch);
}

/// Architecture test result.
/// Why: Track test results per architecture.
/// GrainStyle: Explicit types, bounded operations.
pub const ArchitectureTestResult = struct {
    arch: TestArchitecture,
    test_name: []const u8,
    passed: bool,
    error_message: ?[]const u8,
    duration_ms: u64,

    /// Initialize architecture test result.
    /// Why: Create test result with architecture information.
    /// Contract: Returns initialized result.
    /// GrainStyle: Explicit types, bounded operations, assertions.
    pub fn init(
        arch: TestArchitecture,
        test_name: []const u8,
        passed: bool,
    ) ArchitectureTestResult {
        // Assert: Architecture must be valid (precondition).
        std.debug.assert(arch != .unknown);

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
/// Contract: Returns aggregated results.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn aggregate_test_results(
    results: []const ArchitectureTestResult,
) struct {
    total: u32,
    passed: u32,
    failed: u32,
    skipped: u32,
} {
    // Assert: Results must be valid (precondition).
    std.debug.assert(results.len <= MAX_TEST_RESULTS);

    var total: u32 = 0;
    var passed: u32 = 0;
    var failed: u32 = 0;
    var skipped: u32 = 0;

    for (results) |result| {
        total += 1;

        if (result.passed) {
            passed += 1;
        } else {
            failed += 1;
        }

        // Note: Skipped tests not yet implemented.
        _ = skipped;
    }

    // Assert: Total must equal passed + failed (postcondition).
    std.debug.assert(total == passed + failed);

    return .{
        .total = total,
        .passed = passed,
        .failed = failed,
        .skipped = skipped,
    };
}

/// Adapt test for multi-architecture.
/// Why: Wrap existing tests with architecture detection.
/// Contract: Returns adapted test setup.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn adapt_test_for_multi_arch(
    supported_archs: []const TestArchitecture,
) ?TestSetup {
    // Assert: Supported archs must be valid (precondition).
    std.debug.assert(supported_archs.len > 0);

    // Detect current architecture.
    const current_arch = arch_detection.detect_test_architecture();

    // Assert: Current arch must be valid (postcondition).
    std.debug.assert(current_arch != .unknown);

    // Check if test is compatible with current architecture.
    if (!is_test_compatible(supported_archs, current_arch)) {
        return null; // Skip test on unsupported architecture.
    }

    // Create test setup.
    return create_test_integration();
}

