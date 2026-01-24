//! Why: Test indirect function calls for RISC-V freestanding.
//! Verifies function pointer calls work correctly, testing Issue 2 hypothesis.
//! This test avoids naked function constraints by using regular functions.

const builtin = @import("builtin");
const std = @import("std");

// Why: Test indirect function call with function pointer.
fn indirect_call(fn_ptr: *const fn (u32) u32, val: u32) u32 {
    // Why: Indirect call via function pointer.
    return fn_ptr(val);
}

// Why: Simple function to call indirectly.
fn add_one(x: u32) u32 {
    return x + 1;
}

// Why: Another function to test multiple indirect calls.
fn multiply_two(x: u32) u32 {
    return x * 2;
}

// Why: Test indirect function calls.
pub fn test_indirect_calls() void {
    // Why: Test indirect call with add_one.
    const result1 = indirect_call(add_one, 42);
    _ = result1;

    // Why: Test indirect call with multiply_two.
    const result2 = indirect_call(multiply_two, 21);
    _ = result2;

    // Why: Test multiple indirect calls.
    const result3 = indirect_call(add_one, 10);
    const result4 = indirect_call(multiply_two, 5);
    _ = result3;
    _ = result4;
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Obj
