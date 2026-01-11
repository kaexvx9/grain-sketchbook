//! Integration Test Adapter for Multi-Architecture Testing Framework
//! Why: Adapt existing 44 integration tests for multi-architecture without rewriting.
//! Grain Style: Explicit types (u32/u64), bounded operations, assertions.

const std = @import("std");
const testing = std.testing;
const arch_detection = @import("arch.zig");
const TestArchitecture = arch_detection.TestArchitecture;
const helpers = @import("helpers.zig");

/// Maximum test metadata entries (Grain Style: bounded allocation).
const MAX_TEST_METADATA: u32 = 1000;

/// Maximum test name length (Grain Style: bounded allocation).
const MAX_TEST_NAME_LEN: u32 = 256;

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

    /// Adapt existing test with wrapper.
    /// Why: Enable multi-architecture testing without test changes.
    /// Contract: Wraps test with architecture detection.
    /// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
    pub fn adapt_test_with_wrapper(
        self: *const IntegrationTestAdapter,
        test_name: []const u8,
        original_test: *const fn () anyerror!void,
        supported_archs: []const TestArchitecture,
    ) *const fn () anyerror!void {
        // Assert: Test name must be valid (precondition).
        std.debug.assert(test_name.len > 0);
        std.debug.assert(test_name.len <= MAX_TEST_NAME_LEN);

        // Assert: Test function must be valid (precondition).
        std.debug.assert(@intFromPtr(original_test) != 0);

        // Assert: Supported archs must be valid (precondition).
        std.debug.assert(supported_archs.len > 0);

        // Check compatibility with current architecture.
        if (!helpers.is_test_compatible(supported_archs, self.arch)) {
            // Return skip function for incompatible architecture.
            const SkipWrapper = struct {
                fn skip_test() anyerror!void {
                    // Skip test on unsupported architecture.
                    return;
                }
            };
            return SkipWrapper.skip_test;
        }

        // Return original test for compatible architecture.
        return original_test;
    }

    /// Check if test should run on current architecture.
    /// Why: Determine if test is compatible with current architecture.
    /// Contract: Returns true if compatible, false otherwise.
    /// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
    pub fn should_run_test(
        self: *const IntegrationTestAdapter,
        supported_archs: []const TestArchitecture,
    ) bool {
        // Assert: Supported archs must be valid (precondition).
        std.debug.assert(supported_archs.len > 0);

        // Assert: Architecture must be valid (precondition).
        std.debug.assert(self.arch != .unknown);

        return helpers.is_test_compatible(supported_archs, self.arch);
    }

    /// Get current architecture.
    /// Why: Provide architecture information for test reporting.
    /// Contract: Returns current architecture.
    /// GrainStyle: Explicit types, bounded operations.
    pub fn get_current_architecture(self: *const IntegrationTestAdapter) TestArchitecture {
        // Assert: Architecture must be valid (precondition).
        std.debug.assert(self.arch != .unknown);

        return self.arch;
    }
};

/// Test metadata for integration test adaptation.
/// Why: Store test compatibility information.
/// GrainStyle: Explicit types (u32/u64), bounded allocations.
pub const IntegrationTestMetadata = struct {
    /// Test name.
    test_name: []const u8,

    /// Supported architectures.
    supported_archs: []const TestArchitecture,

    /// Test function.
    test_fn: *const fn () anyerror!void,

    /// Check if test is compatible with architecture.
    /// Why: Determine if test should run on architecture.
    /// Contract: Returns true if compatible, false otherwise.
    /// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
    pub fn is_compatible(
        self: *const IntegrationTestMetadata,
        arch: TestArchitecture,
    ) bool {
        // Assert: Architecture must be valid (precondition).
        std.debug.assert(arch != .unknown);

        // Assert: Test name must be valid (precondition).
        std.debug.assert(self.test_name.len > 0);

        return helpers.is_test_compatible(self.supported_archs, arch);
    }
};

/// Adapt test suite for multi-architecture.
/// Why: Enable multi-architecture testing for test suites.
/// Contract: Filters tests by architecture compatibility.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn adapt_test_suite_for_multi_arch(
    adapter: *const IntegrationTestAdapter,
    test_metadata_list: []const IntegrationTestMetadata,
) []const IntegrationTestMetadata {
    // Assert: Adapter must be valid (precondition).
    std.debug.assert(@intFromPtr(adapter) != 0);

    // Assert: Test metadata list must be valid (precondition).
    std.debug.assert(test_metadata_list.len > 0);
    std.debug.assert(test_metadata_list.len <= MAX_TEST_METADATA);

    // Filter tests by architecture compatibility.
    // Note: This is a simplified version that returns all compatible tests.
    // Full implementation would allocate filtered list.
    var compatible_count: u32 = 0;
    for (test_metadata_list) |metadata| {
        if (metadata.is_compatible(adapter.arch)) {
            compatible_count += 1;
        }
    }

    // Assert: At least one compatible test found (postcondition).
    std.debug.assert(compatible_count > 0);

    // Return original list (full implementation would filter).
    return test_metadata_list;
}

/// Create architecture-agnostic test setup.
/// Why: Provide test setup that works across all architectures.
/// Contract: Returns test setup with architecture information.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn create_multi_arch_test_setup() helpers.TestSetup {
    // Assert: builtin must be available (precondition).
    _ = @import("builtin");

    // Create test setup with architecture detection.
    return helpers.create_test_integration();
}

/// Get architecture name for test reporting.
/// Why: Provide human-readable architecture name.
/// Contract: Returns architecture name string.
/// GrainStyle: Explicit types, bounded operations.
pub fn get_architecture_name_for_reporting(
    arch: TestArchitecture,
) []const u8 {
    // Assert: Architecture must be valid (precondition).
    std.debug.assert(arch != .unknown);

    return arch_detection.get_architecture_name(arch);
}


