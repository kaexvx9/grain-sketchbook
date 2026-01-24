//! Why: Test vtable dispatch for RISC-V freestanding.
//! Verifies function pointer calls via vtable work correctly, testing Issue 2 hypothesis.
//! This test avoids naked function constraints by using regular functions.

const builtin = @import("builtin");
const std = @import("std");

// Why: Minimal vtable-like structure.
const VTable = struct {
    call: *const fn (*const u8, usize) void,
};

// Why: Test function for vtable.
fn test_func(data: *const u8, len: usize) void {
    // Why: Simple operation to verify function is called.
    _ = data;
    _ = len;
}

// Why: Test vtable dispatch.
fn test_vtable(vtable: *const VTable, data: *const u8, len: usize) void {
    // Why: Indirect call via vtable function pointer.
    vtable.call(data, len);
}

// Why: Test vtable dispatch operations.
pub fn test_vtable_dispatch() void {
    // Why: Create vtable with test function.
    const vtable = VTable{ .call = test_func };
    
    // Why: Test data.
    const test_data: [4]u8 = "test".*;
    
    // Why: Test vtable dispatch.
    test_vtable(&vtable, &test_data, test_data.len);
    
    // Why: Test multiple vtable calls.
    test_vtable(&vtable, &test_data, 2);
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Obj
