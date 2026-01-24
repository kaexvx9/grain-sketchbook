//! Why: Test bitwise conditionals for RISC-V freestanding. Issue 3 fix.
//! if ((val & mask) != 0) etc. Naked _start: globals only, no calls/locals.

const builtin = @import("builtin");
const std = @import("std");

var x: u32 = 5;
var y: u32 = 0x1234;
var z: u32 = 0x100;

pub fn _start() callconv(.naked) noreturn {
    if ((x & 0x01) != 0) {}
    x = 4;
    if ((x & 0x01) != 0) {}
    if ((y & 0x0001) != 0) {}
    y = 0x1235;
    if ((y & 0x0001) != 0) {}
    if ((z & 0xFF) == 0) {}
    z = 0x1FF;
    if ((z & 0xFF) == 0) {}
    while (true) {}
}

comptime {
    @export(&_start, .{ .name = "_start" });
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Exe
