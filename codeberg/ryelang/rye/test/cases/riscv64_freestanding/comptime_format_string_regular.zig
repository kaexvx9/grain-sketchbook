//! Why: Test comptime format string in regular function (not _start).
//! Verifies format strings are fully evaluated at comptime for freestanding.
//! This test avoids naked function constraints by using regular functions.

const builtin = @import("builtin");
const std = @import("std");

// Why: Simple comptime format string function.
fn comptime_print(comptime fmt: []const u8) void {
    // Why: This should be fully evaluated at comptime.
    // Format string parsing should happen at comptime, not runtime.
    _ = fmt;
}

// Why: Test anytype parameter with format-like function.
fn test_anytype(val: anytype) void {
    // Why: anytype should be resolved to concrete type before codegen.
    _ = val;
}

// Why: Test inline for with comptime slice.
fn test_inline_for_comptime(comptime slice: []const u8) void {
    // Why: inline for should unroll at comptime.
    inline for (slice) |c| {
        _ = c;
    }
}

// Why: Regular function to test comptime format strings.
pub fn test_comptime_format() void {
    // Why: Test comptime format string.
    comptime_print("test message");

    // Why: Test anytype with different types.
    test_anytype(@as(u32, 42));
    test_anytype(@as(u64, 100));
    test_anytype(@as(i32, -1));

    // Why: Test inline for with comptime string.
    test_inline_for_comptime("hello");
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Obj
