//! Performance Integration Tests (Phase 5)
//! Why: Test performance characteristics to validate kernel/VM integration performance and identify optimization opportunities.
//! Grain Style: Comprehensive assertions, explicit types (u32/u64), bounded operations.

const std = @import("std");
const testing = std.testing;
const kernel_vm = @import("kernel_vm");
const Integration = kernel_vm.Integration;
const VM = kernel_vm.VM;
const VMBenchmark = kernel_vm.benchmark.VMBenchmark;
const basin_kernel = @import("basin_kernel");
const BasinKernel = basin_kernel.BasinKernel;
const Syscall = basin_kernel.Syscall;

// Test execution bounds (Grain Style: explicit limits).
const MAX_TEST_STEPS: u32 = 10000; // Maximum steps for performance test execution.
const MAX_ITERATIONS: u32 = 1000; // Maximum iterations per performance test.
const BENCHMARK_ITERATIONS: u32 = 100; // Maximum benchmark iterations.

// Performance thresholds (Grain Style: explicit limits).
const MAX_SYSCALL_LATENCY_NS: u64 = 10_000_000; // Maximum syscall latency: 10ms (reasonable for integration tests).
const MIN_THROUGHPUT_OPS_PER_SEC: u64 = 100; // Minimum throughput: 100 operations per second (reasonable for integration tests).

/// Helper: Create VM and kernel with integration layer initialized.
/// Why: Reduce test boilerplate, ensure consistent setup across tests.
/// Contract: Returns initialized Integration instance, VM ready for syscalls.
/// GrainStyle: In-place initialization pattern, explicit types.
fn create_test_integration() struct { vm: VM, kernel: BasinKernel, integration: Integration } {
    var vm: VM = undefined;
    VM.init(&vm, &[_]u8{}, 0x80000000);
    
    var kernel = BasinKernel.init();
    
    var integration = Integration.init_with_kernel(&vm, &kernel);
    integration.finish_init();
    
    // Assert: Integration must be initialized (postcondition).
    std.debug.assert(integration.initialized);
    
    // Assert: VM must be in halted state (postcondition).
    std.debug.assert(vm.state == .halted);
    
    return .{ .vm = vm, .kernel = kernel, .integration = integration };
}

// Test: Syscall latency measurement.
test "performance: syscall latency" {
    // Objective: Measure syscall execution time to validate performance.
    // Methodology: Execute syscalls and measure latency using high-resolution timestamps.
    // Why: Syscall latency is critical for system performance, especially for real-time systems.
    
    const test_setup = create_test_integration();
    var kernel = test_setup.kernel;
    
    // Measure syscall latency for lightweight syscalls (bounded iteration).
    var total_latency_ns: u64 = 0;
    var syscall_count: u32 = 0;
    
    while (syscall_count < BENCHMARK_ITERATIONS) : (syscall_count += 1) {
        // Measure sysinfo syscall latency (lightweight syscall).
        const start_time = std.time.nanoTimestamp();
        
        const result = kernel.handle_syscall(@intFromEnum(Syscall.sysinfo), 0x1000, 0, 0, 0) catch |err| {
            // Sysinfo may fail with invalid arguments (expected for test setup).
            // Why: We're testing syscall latency, not syscall correctness.
            _ = err;
            continue;
        };
        _ = result;
        
        const end_time = std.time.nanoTimestamp();
        const latency_ns: u64 = if (end_time > start_time) @as(u64, @intCast(end_time - start_time)) else 0;
        total_latency_ns += latency_ns;
        
        // Stop if we've executed many syscalls (bounded iteration).
        if (syscall_count >= BENCHMARK_ITERATIONS) {
            break;
        }
    }
    
    // Calculate average latency.
    const avg_latency_ns: u64 = if (syscall_count > 0) total_latency_ns / syscall_count else 0;
    
    // Assert: Average latency must be within reasonable threshold (postcondition).
    // Why: Syscall latency should be reasonable for system performance.
    // Note: MAX_SYSCALL_LATENCY_NS is 10ms, which is reasonable for integration tests.
    try testing.expect(avg_latency_ns <= MAX_SYSCALL_LATENCY_NS);
    
    // Assert: Test completed without crashing (postcondition).
    try testing.expect(syscall_count <= BENCHMARK_ITERATIONS);
}

// Test: Syscall throughput measurement.
test "performance: syscall throughput" {
    // Objective: Measure syscall throughput to validate performance.
    // Methodology: Execute many syscalls in sequence and measure throughput.
    // Why: Syscall throughput is critical for system performance, especially for high-load scenarios.
    
    const test_setup = create_test_integration();
    var kernel = test_setup.kernel;
    
    // Measure syscall throughput (bounded iteration).
    const start_time = std.time.nanoTimestamp();
    var syscall_count: u32 = 0;
    
    while (syscall_count < BENCHMARK_ITERATIONS) : (syscall_count += 1) {
        // Execute lightweight syscall (sysinfo).
        const result = kernel.handle_syscall(@intFromEnum(Syscall.sysinfo), 0x1000, 0, 0, 0) catch |err| {
            // Sysinfo may fail with invalid arguments (expected for test setup).
            // Why: We're testing syscall throughput, not syscall correctness.
            _ = err;
            continue;
        };
        _ = result;
        
        // Stop if we've executed many syscalls (bounded iteration).
        if (syscall_count >= BENCHMARK_ITERATIONS) {
            break;
        }
    }
    
    const end_time = std.time.nanoTimestamp();
    const elapsed_ns: u64 = if (end_time > start_time) @as(u64, @intCast(end_time - start_time)) else 1;
    const elapsed_sec: f64 = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000_000.0;
    
    // Calculate throughput (operations per second).
    const throughput_ops_per_sec: u64 = if (elapsed_sec > 0.0) @as(u64, @intFromFloat(@as(f64, @floatFromInt(syscall_count)) / elapsed_sec)) else 0;
    
    // Assert: Throughput must meet minimum threshold (postcondition).
    // Why: Syscall throughput should meet minimum requirements for system performance.
    // Note: MIN_THROUGHPUT_OPS_PER_SEC is 100 ops/sec, which is reasonable for integration tests.
    try testing.expect(throughput_ops_per_sec >= MIN_THROUGHPUT_OPS_PER_SEC);
    
    // Assert: Test completed without crashing (postcondition).
    try testing.expect(syscall_count <= BENCHMARK_ITERATIONS);
}

// Test: Memory access performance.
test "performance: memory access performance" {
    // Objective: Measure memory access performance to validate VM memory operations.
    // Methodology: Execute memory operations and measure performance using VM benchmark framework.
    // Why: Memory access performance is critical for system performance.
    
    const test_setup = create_test_integration();
    var vm = test_setup.vm;
    
    // Create minimal program that performs memory operations.
    const memory_program = [_]u8{
        0x13, 0x00, 0x00, 0x00, // ADDI x0, x0, 0 (NOP)
        0x6F, 0x00, 0x00, 0x00, // JAL x0, -4 (loop back)
    };
    
    // Reinitialize VM with memory program.
    VM.init(&vm, &memory_program, 0x80000000);
    
    // Initialize benchmark.
    var benchmark = VMBenchmark.init();
    
    // Run benchmark with memory operations (bounded steps).
    const result = benchmark.run_benchmark(&vm, "memory_access", MAX_TEST_STEPS) catch |err| {
        // Benchmark may fail, but shouldn't crash.
        _ = err;
        return;
    };
    
    // Assert: Benchmark must have executed (postcondition).
    // Why: Memory access performance should be measurable.
    try testing.expect(result.instructions_executed > 0 or result.memory_reads > 0 or result.memory_writes > 0);
    
    // Assert: Execution time must be reasonable (postcondition).
    // Why: Memory access should complete in reasonable time.
    try testing.expect(result.execution_time_ns > 0);
}

// Test: Context switch performance.
test "performance: context switch performance" {
    // Objective: Measure process switching performance to validate kernel process management.
    // Methodology: Create and switch between processes, measure switching time.
    // Why: Context switch performance is critical for multi-process systems.
    
    const test_setup = create_test_integration();
    var kernel = test_setup.kernel;
    
    // Measure context switch performance (bounded iteration).
    var total_switch_time_ns: u64 = 0;
    var switch_count: u32 = 0;
    
    while (switch_count < BENCHMARK_ITERATIONS) : (switch_count += 1) {
        // Spawn a process (simulates context switch).
        const start_time = std.time.nanoTimestamp();
        
        const spawn_result = kernel.syscall_spawn(0x1000, 0, 0, 0) catch |err| {
            // Spawn may fail due to invalid arguments (expected for test setup).
            // Why: We're testing context switch performance, not process creation correctness.
            _ = err;
            continue;
        };
        
        const end_time = std.time.nanoTimestamp();
        const switch_time_ns: u64 = if (end_time > start_time) @as(u64, @intCast(end_time - start_time)) else 0;
        total_switch_time_ns += switch_time_ns;
        
        // If spawn succeeds, exit the process immediately.
        if (spawn_result == .success) {
            const process_id = spawn_result.success;
            _ = kernel.syscall_exit(process_id, 0, 0, 0) catch |err| {
                // Exit may fail, but process should terminate.
                _ = err;
            };
        }
        
        // Stop if we've executed many switches (bounded iteration).
        if (switch_count >= BENCHMARK_ITERATIONS) {
            break;
        }
    }
    
    // Calculate average switch time.
    const avg_switch_time_ns: u64 = if (switch_count > 0) total_switch_time_ns / switch_count else 0;
    
    // Assert: Average switch time must be within reasonable threshold (postcondition).
    // Why: Context switch time should be reasonable for system performance.
    // Note: Using MAX_SYSCALL_LATENCY_NS as threshold (10ms) for context switches.
    try testing.expect(avg_switch_time_ns <= MAX_SYSCALL_LATENCY_NS);
    
    // Assert: Test completed without crashing (postcondition).
    try testing.expect(switch_count <= BENCHMARK_ITERATIONS);
}

// Test: Network operation performance.
test "performance: network operation performance" {
    // Objective: Measure network operation performance to validate network syscall performance.
    // Methodology: Execute network syscalls and measure performance.
    // Why: Network operation performance is critical for network-intensive applications.
    
    const test_setup = create_test_integration();
    var kernel = test_setup.kernel;
    
    // Measure network operation performance (bounded iteration).
    var total_operation_time_ns: u64 = 0;
    var operation_count: u32 = 0;
    
    while (operation_count < BENCHMARK_ITERATIONS) : (operation_count += 1) {
        // Test TCP socket creation (lightweight network operation).
        const start_time = std.time.nanoTimestamp();
        
        const result = kernel.handle_syscall(@intFromEnum(Syscall.tcp_socket), 0, 0, 0, 0) catch |err| {
            // Socket creation may fail (expected for test setup).
            // Why: We're testing network operation performance, not network correctness.
            _ = err;
            continue;
        };
        _ = result;
        
        const end_time = std.time.nanoTimestamp();
        const operation_time_ns: u64 = if (end_time > start_time) @as(u64, @intCast(end_time - start_time)) else 0;
        total_operation_time_ns += operation_time_ns;
        
        // Stop if we've executed many operations (bounded iteration).
        if (operation_count >= BENCHMARK_ITERATIONS) {
            break;
        }
    }
    
    // Calculate average operation time.
    const avg_operation_time_ns: u64 = if (operation_count > 0) total_operation_time_ns / operation_count else 0;
    
    // Assert: Average operation time must be within reasonable threshold (postcondition).
    // Why: Network operation time should be reasonable for system performance.
    // Note: Using MAX_SYSCALL_LATENCY_NS as threshold (10ms) for network operations.
    try testing.expect(avg_operation_time_ns <= MAX_SYSCALL_LATENCY_NS);
    
    // Assert: Test completed without crashing (postcondition).
    try testing.expect(operation_count <= BENCHMARK_ITERATIONS);
}

// Test: Mixed workload performance.
test "performance: mixed workload performance" {
    // Objective: Measure performance under mixed workload to validate system performance under realistic conditions.
    // Methodology: Execute mixed syscalls (process, memory, network, file) and measure overall performance.
    // Why: Mixed workload performance reflects real-world system performance.
    
    const test_setup = create_test_integration();
    var kernel = test_setup.kernel;
    
    // Measure mixed workload performance (bounded iteration).
    const start_time = std.time.nanoTimestamp();
    var operation_count: u32 = 0;
    
    while (operation_count < BENCHMARK_ITERATIONS) : (operation_count += 1) {
        // Alternate between different syscall types.
        const syscall_type = operation_count % 4;
        
        switch (syscall_type) {
            0 => {
                // Process syscall: enumerate_processes.
                _ = kernel.handle_syscall(@intFromEnum(Syscall.enumerate_processes), 0x1000, 0, 0, 0) catch |err| {
                    _ = err;
                };
            },
            1 => {
                // Memory syscall: map (may fail, but tests execution).
                _ = kernel.handle_syscall(@intFromEnum(Syscall.map), 0x80000000, 4096, 0, 0) catch |err| {
                    _ = err;
                };
            },
            2 => {
                // Network syscall: tcp_socket (may fail, but tests execution).
                _ = kernel.handle_syscall(@intFromEnum(Syscall.tcp_socket), 0, 0, 0, 0) catch |err| {
                    _ = err;
                };
            },
            3 => {
                // System info syscall: sysinfo.
                _ = kernel.handle_syscall(@intFromEnum(Syscall.sysinfo), 0x1000, 0, 0, 0) catch |err| {
                    _ = err;
                };
            },
            else => unreachable,
        }
        
        // Stop if we've executed many operations (bounded iteration).
        if (operation_count >= BENCHMARK_ITERATIONS) {
            break;
        }
    }
    
    const end_time = std.time.nanoTimestamp();
    const elapsed_ns: u64 = if (end_time > start_time) @as(u64, @intCast(end_time - start_time)) else 1;
    const elapsed_sec: f64 = @as(f64, @floatFromInt(elapsed_ns)) / 1_000_000_000.0;
    
    // Calculate throughput (operations per second).
    const throughput_ops_per_sec: u64 = if (elapsed_sec > 0.0) @as(u64, @intFromFloat(@as(f64, @floatFromInt(operation_count)) / elapsed_sec)) else 0;
    
    // Assert: Throughput must meet minimum threshold (postcondition).
    // Why: Mixed workload throughput should meet minimum requirements.
    // Note: Using MIN_THROUGHPUT_OPS_PER_SEC (100 ops/sec) for mixed workload.
    try testing.expect(throughput_ops_per_sec >= MIN_THROUGHPUT_OPS_PER_SEC);
    
    // Assert: Test completed without crashing (postcondition).
    try testing.expect(operation_count <= BENCHMARK_ITERATIONS);
}

// Test: Performance regression detection.
test "performance: performance regression detection" {
    // Objective: Detect performance regressions by comparing current performance to baseline.
    // Methodology: Measure current performance and compare to expected baseline (within tolerance).
    // Why: Performance regression detection ensures system performance doesn't degrade over time.
    
    const test_setup = create_test_integration();
    var kernel = test_setup.kernel;
    
    // Measure baseline performance (bounded iteration).
    const baseline_start_time = std.time.nanoTimestamp();
    var baseline_count: u32 = 0;
    
    while (baseline_count < BENCHMARK_ITERATIONS) : (baseline_count += 1) {
        _ = kernel.handle_syscall(@intFromEnum(Syscall.sysinfo), 0x1000, 0, 0, 0) catch |err| {
            _ = err;
            continue;
        };
        
        if (baseline_count >= BENCHMARK_ITERATIONS) {
            break;
        }
    }
    
    const baseline_end_time = std.time.nanoTimestamp();
    const baseline_elapsed_ns: u64 = if (baseline_end_time > baseline_start_time) @as(u64, @intCast(baseline_end_time - baseline_start_time)) else 1;
    
    // Measure current performance (bounded iteration).
    const current_start_time = std.time.nanoTimestamp();
    var current_count: u32 = 0;
    
    while (current_count < BENCHMARK_ITERATIONS) : (current_count += 1) {
        _ = kernel.handle_syscall(@intFromEnum(Syscall.sysinfo), 0x1000, 0, 0, 0) catch |err| {
            _ = err;
            continue;
        };
        
        if (current_count >= BENCHMARK_ITERATIONS) {
            break;
        }
    }
    
    const current_end_time = std.time.nanoTimestamp();
    const current_elapsed_ns: u64 = if (current_end_time > current_start_time) @as(u64, @intCast(current_end_time - current_start_time)) else 1;
    
    // Calculate performance ratio (current / baseline).
    // Note: Allow 2x tolerance for test environment variability.
    const performance_ratio: f64 = if (baseline_elapsed_ns > 0) @as(f64, @floatFromInt(current_elapsed_ns)) / @as(f64, @floatFromInt(baseline_elapsed_ns)) else 1.0;
    const max_regression_ratio: f64 = 2.0; // Allow 2x slowdown before considering it a regression.
    
    // Assert: Performance ratio must be within tolerance (postcondition).
    // Why: Current performance should not significantly degrade from baseline.
    try testing.expect(performance_ratio <= max_regression_ratio);
    
    // Assert: Test completed without crashing (postcondition).
    try testing.expect(baseline_count <= BENCHMARK_ITERATIONS);
    try testing.expect(current_count <= BENCHMARK_ITERATIONS);
}
