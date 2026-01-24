//! Why: Test global variable address calculation for RISC-V freestanding.
//! Verifies globals use PC-relative (AUIPC+ADDI) not LUI+ADDI. Issue 1 fix.
//! Naked _start: no runtime calls/locals; only global r/w.

const builtin = @import("builtin");
const std = @import("std");

var global_counter: u32 = 0;
var global_value: u64 = 0x1234567890ABCDEF;

pub fn _start() callconv(.naked) noreturn {
    _ = global_counter;
    global_counter = 42;
    _ = global_value;
    global_value = 0xDEADBEEFCAFEBABE;
    const counter_ptr = &global_counter;
    counter_ptr.* = 100;
    global_counter = 1;
    global_value = 2;
    while (true) {}
}

comptime {
    @export(&_start, .{ .name = "_start" });
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Exe
