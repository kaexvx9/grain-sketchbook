//! Multi-Architecture Testing Framework
//! Why: Provide architecture-agnostic test framework for ARM64, x86_64 AMD, and x86_64 Intel.
//! Grain Style: Explicit types (u32/u64), bounded operations, assertions.

// Architecture detection and utilities.
pub const arch = @import("arch.zig");
pub const TestArchitecture = arch.TestArchitecture;
pub const CpuVendor = arch.CpuVendor;

// Test helpers for architecture-agnostic test setup.
pub const helpers = @import("helpers.zig");
pub const TestSetup = helpers.TestSetup;
pub const ArchitectureTestResult = helpers.ArchitectureTestResult;

// Test runner for multi-architecture test execution.
pub const runner = @import("runner.zig");
pub const TestRunner = runner.TestRunner;
pub const TestResult = runner.TestResult;
pub const TestSuite = runner.TestSuite;
pub const TestMetadata = runner.TestMetadata;

// Integration test adapter for adapting existing tests.
pub const integration_adapter = @import("integration_adapter.zig");
pub const IntegrationTestAdapter = integration_adapter.IntegrationTestAdapter;
pub const IntegrationTestMetadata = integration_adapter.IntegrationTestMetadata;

// Re-export commonly used functions for convenience.
pub const detect_test_architecture = arch.detect_test_architecture;
pub const get_architecture_name = arch.get_architecture_name;
pub const supports_jit = arch.supports_jit;
pub const requires_jit = arch.requires_jit;
pub const create_test_integration = helpers.create_test_integration;
pub const is_test_compatible = helpers.is_test_compatible;
pub const should_skip_test = helpers.should_skip_test;
pub const aggregate_test_results = helpers.aggregate_test_results;
pub const create_multi_arch_test_setup = integration_adapter.create_multi_arch_test_setup;

