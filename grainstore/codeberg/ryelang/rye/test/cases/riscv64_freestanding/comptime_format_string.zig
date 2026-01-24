//! Why: Test comptime format string evaluation for RISC-V freestanding.
//! This test attempts to reproduce Issue 2: function calls with anytype/comptime.
//! Expected: Format strings should be fully evaluated at comptime for freestanding.

const builtin = @import("builtin");
const std = @import("std");

// Why: Simple comptime format string function.
fn comptime_print(comptime fmt: []const u8) void {
    // Why: This should be fully evaluated at comptime.
    _ = fmt;
    // In a real implementation, this would parse and output the format string
    // For now, we just verify it compiles
}

// Why: Test anytype parameter.
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

// Why: Entry point for freestanding test.
pub fn _start() callconv(.naked) noreturn {
    // Why: Test comptime format string.
    comptime_print("test message");

    // Why: Test anytype with different types.
    test_anytype(@as(u32, 42));
    test_anytype(@as(u64, 100));
    test_anytype(@as(i32, -1));

    // Why: Test inline for with comptime string.
    test_inline_for_comptime("hello");

    // Why: Infinite loop for freestanding (no exit).
    while (true) {}
}

comptime {
    @export(&_start, .{ .name = "_start" });
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Exe
