//! Why: Test anytype parameter resolution for RISC-V freestanding.
//! This test verifies that anytype parameters are resolved to concrete types
//! before codegen, fixing Issue 2.

const builtin = @import("builtin");
const std = @import("std");

// Why: Generic function with anytype parameter.
fn generic_add(a: anytype, b: anytype) @TypeOf(a) {
    std.debug.assert(@TypeOf(a) == @TypeOf(b));
    return a + b;
}

// Why: Test anytype with multiple calls.
fn test_generic() void {
    // Why: Test with u32.
    const result1 = generic_add(@as(u32, 10), @as(u32, 20));
    std.debug.assert(result1 == 30);

    // Why: Test with u64.
    const result2 = generic_add(@as(u64, 100), @as(u64, 200));
    std.debug.assert(result2 == 300);

    // Why: Test with i32.
    const result3 = generic_add(@as(i32, -10), @as(i32, 20));
    std.debug.assert(result3 == 10);
}

// Why: Entry point for freestanding test.
pub fn _start() callconv(.naked) noreturn {
    test_generic();

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
