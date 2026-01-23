//! Why: Test anytype resolution in regular function (not _start).
//! Verifies anytype parameters are resolved to concrete types before codegen.
//! This test avoids naked function constraints by using regular functions.

const builtin = @import("builtin");
const std = @import("std");

// Why: Generic function with anytype parameter.
fn generic_add(a: anytype, b: anytype) @TypeOf(a) {
    // Why: anytype should be resolved before codegen.
    // Both parameters should have the same type after resolution.
    return a + b;
}

// Why: Test anytype with multiple calls and types.
pub fn test_anytype_resolution() void {
    // Why: Test with u32.
    const result1 = generic_add(@as(u32, 10), @as(u32, 20));
    _ = result1;

    // Why: Test with u64.
    const result2 = generic_add(@as(u64, 100), @as(u64, 200));
    _ = result2;

    // Why: Test with i32.
    const result3 = generic_add(@as(i32, -10), @as(i32, 20));
    _ = result3;

    // Why: Test with different operations.
    const result4 = generic_add(@as(u32, 5), @as(u32, 3));
    _ = result4;
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Obj
