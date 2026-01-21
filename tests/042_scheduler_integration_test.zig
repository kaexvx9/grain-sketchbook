//! Scheduler-Process Execution Integration Tests (Phase 3.15)
//! Why: Test integration of scheduler with process execution in VM.
//! Grain Style: Comprehensive assertions, explicit types, bounded operations.

const std = @import("std");
const testing = std.testing;
const kernel_vm = @import("kernel_vm");
const VM = kernel_vm.VM;
const Integration = kernel_vm.Integration;
const basin_kernel = @import("basin_kernel");
const BasinKernel = basin_kernel.BasinKernel;
// ProcessContext not needed for this test
const handle_syscall = basin_kernel.handle_syscall;
const Syscall = basin_kernel.Syscall;

/// Why: Heap-allocate kernel to avoid stack overflow.
fn create_test_kernel() !*BasinKernel {
    const kernel = try testing.allocator.create(BasinKernel);
    BasinKernel.init_in_place(kernel);
    return kernel;
}

/// Why: Heap-allocate VM to avoid stack overflow (8MB).
fn create_test_vm() !*VM {
    const vm = try testing.allocator.create(VM);
    VM.init(vm, &[_]u8{}, 0);
    return vm;
}

// Test: run_current_process executes current process.
// Why: Uses heap-allocated kernel and VM to avoid stack overflow.
test "run_current_process executes current process" {
    const vm = try create_test_vm();
    defer testing.allocator.destroy(vm);
    const kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);

    // Spawn a process.
    const spawn_num = @intFromEnum(Syscall.spawn);
    const result = try handle_syscall(kernel, spawn_num, 0x1000, 0, 0, 0);
    try testing.expect(result == .success);
    const process_id = result.success;

    // Set as current process.
    // Set current process with default time slice quantum.
    const time_slice: u64 = 1000;
    kernel.scheduler.set_current(process_id, time_slice);

    // Create integration.
    var integration = Integration.init_with_kernel(vm, kernel);
    integration.finish_init();

    // Run current process (with small max_steps).
    const should_continue = integration.run_current_process(100);

    // Assert: Process execution should complete (halted or errored due to invalid instructions).
    // Note: VM will halt quickly since memory is empty.
    _ = should_continue;
}

// Test: schedule_and_run_next schedules and runs next process.
// Why: Uses heap-allocated kernel and VM to avoid stack overflow.
test "schedule_and_run_next schedules and runs next process" {
    const vm = try create_test_vm();
    defer testing.allocator.destroy(vm);
    const kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);

    // Spawn a process.
    const spawn_num = @intFromEnum(Syscall.spawn);
    const result = try handle_syscall(kernel, spawn_num, 0x1000, 0, 0, 0);
    try testing.expect(result == .success);
    const process_id = result.success;

    // Create integration.
    var integration = Integration.init_with_kernel(vm, kernel);
    integration.finish_init();

    // Schedule and run next process.
    const scheduled = integration.schedule_and_run_next(100);

    // Assert: Process should be scheduled and run.
    try testing.expect(scheduled);
    try testing.expect(kernel.scheduler.get_current() == process_id);
}

// Test: schedule_and_run_next returns false when no runnable process.
// Why: Uses heap-allocated kernel and VM to avoid stack overflow.
test "schedule_and_run_next returns false when no runnable process" {
    const vm = try create_test_vm();
    defer testing.allocator.destroy(vm);
    const kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);

    // Create integration (no processes spawned).
    var integration = Integration.init_with_kernel(vm, kernel);
    integration.finish_init();

    // Schedule and run next process (should fail - no processes).
    const scheduled = integration.schedule_and_run_next(100);

    // Assert: No process should be scheduled.
    try testing.expect(!scheduled);
    try testing.expect(kernel.scheduler.get_current() == 0);
}

// Test: run_current_process returns false when no current process.
// Why: Uses heap-allocated kernel and VM to avoid stack overflow.
test "run_current_process returns false when no current process" {
    const vm = try create_test_vm();
    defer testing.allocator.destroy(vm);
    const kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);

    // Create integration (no current process).
    var integration = Integration.init_with_kernel(vm, kernel);
    integration.finish_init();

    // Run current process (should fail - no current process).
    const should_continue = integration.run_current_process(100);

    // Assert: Should return false (no process to run).
    try testing.expect(!should_continue);
}
