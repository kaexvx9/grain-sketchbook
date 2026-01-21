//! Basin Kernel Lite Tests
//! Why: Test stack-friendly kernel for unit testing.
//! Grain Style: Comprehensive assertions, explicit types.

const std = @import("std");
const basin_kernel_lite = @import("basin_kernel_lite");
const BasinKernelLite = basin_kernel_lite.BasinKernelLite;
const Syscall = basin_kernel_lite.Syscall;
const LITE_MAX_PAGES = basin_kernel_lite.LITE_MAX_PAGES;

test "lite kernel initialization" {
    var kernel = BasinKernelLite.init();
    try std.testing.expect(kernel.is_initialized());
    try std.testing.expect(kernel.interrupt_controller.initialized);
    try std.testing.expectEqual(@as(u32, 0), kernel.process_count());
}

test "lite kernel spawn process" {
    var kernel = BasinKernelLite.init();
    const pid = kernel.spawn_process(5);
    try std.testing.expect(pid != null);
    try std.testing.expectEqual(@as(u64, 1), pid.?);
    try std.testing.expectEqual(@as(u32, 1), kernel.process_count());
}

test "lite kernel multiple processes" {
    var kernel = BasinKernelLite.init();

    const p1 = kernel.spawn_process(1);
    const p2 = kernel.spawn_process(2);
    const p3 = kernel.spawn_process(3);

    try std.testing.expect(p1 != null);
    try std.testing.expect(p2 != null);
    try std.testing.expect(p3 != null);
    try std.testing.expectEqual(@as(u32, 3), kernel.process_count());
}

test "lite kernel exit process" {
    var kernel = BasinKernelLite.init();
    _ = kernel.spawn_process(5);
    try std.testing.expectEqual(@as(u32, 1), kernel.process_count());

    try std.testing.expect(kernel.exit_process(0));
    try std.testing.expectEqual(@as(u32, 0), kernel.process_count());
}

test "lite kernel yield" {
    var kernel = BasinKernelLite.init();
    _ = kernel.spawn_process(1);
    _ = kernel.spawn_process(2);

    const initial_idx = kernel.current_process_index;
    kernel.yield_process();
    try std.testing.expect(kernel.current_process_index != initial_idx);
}

test "lite kernel syscall spawn" {
    var kernel = BasinKernelLite.init();
    const result = kernel.syscall(@intFromEnum(Syscall.spawn), 5, 0, 0);
    switch (result) {
        .success => |pid| try std.testing.expectEqual(@as(u64, 1), pid),
        .err => return error.UnexpectedError,
    }
}

test "lite kernel syscall yield" {
    var kernel = BasinKernelLite.init();
    _ = kernel.spawn_process(1);
    const result = kernel.syscall(@intFromEnum(Syscall.yield), 0, 0, 0);
    switch (result) {
        .success => {},
        .err => return error.UnexpectedError,
    }
}

test "lite kernel memory pool" {
    const kernel = BasinKernelLite.init();
    try std.testing.expectEqual(LITE_MAX_PAGES, kernel.memory_pool.get_free_pages());
}

test "lite kernel interrupt controller" {
    const kernel = BasinKernelLite.init();
    try std.testing.expect(kernel.interrupt_controller.initialized);
    try std.testing.expectEqual(@as(u64, 0), kernel.interrupt_controller.pending);
}
