//! RISC-V Platform Interface
//! Why: Platform runtime services for RISC-V kernels (SBI wrapper).

const std = @import("std");
const Debug = @import("debug.zig");
const sbi = @import("sbi");
const platform = @import("platform.zig");

/// Helper to create success result.
fn ok_result(value: i64) platform.PlatformResult {
    return .{ .error_code = 0, .value = value };
}

/// Helper to create error result.
fn err_result() platform.PlatformResult {
    return .{ .error_code = -1, .value = -1 };
}

/// Why: Map unified platform functions to RISC-V SBI calls.
pub fn platform_call_riscv(
    function_id: platform.PlatformFunction,
    arg0: u64,
    arg1: u64,
    arg2: u64,
    arg3: u64,
) platform.PlatformResult {
    _ = arg1;
    _ = arg2;
    _ = arg3;

    return switch (function_id) {
        .console_putchar => {
            Debug.kassert(arg0 <= 0xFF, "Character out of range", .{});
            _ = sbi.console_putchar(@truncate(arg0));
            return ok_result(0);
        },
        .console_getchar => {
            const result = sbi.console_getchar();
            return switch (result) {
                .NoChar => err_result(),
                _ => ok_result(@intFromEnum(result)),
            };
        },
        .set_timer => {
            sbi.set_timer(arg0);
            return ok_result(0);
        },
        .shutdown => {
            sbi.shutdown();
            unreachable;
        },
    };
}

// Static counter for time source (increments each call)
var time_call_counter: u64 = 0;

/// Why: Provide time source for freestanding RISC-V kernel.
pub fn get_time_ns() u64 {
    // Stub: counter-based approach (actual: read RISC-V time CSR).
    const BASE_TIME_NS: u64 = 1703000000 * 1000000000; // Jan 2024
    time_call_counter += 1;
    return BASE_TIME_NS + (time_call_counter * 1000000);
}
