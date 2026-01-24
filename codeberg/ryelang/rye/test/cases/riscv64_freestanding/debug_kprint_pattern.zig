//! Why: Test Debug.kprint() pattern with type-dependent operations for RISC-V freestanding.
//! This matches actual kernel usage - runtime index + inline for + type-dependent operations.
//! Verifies if the combination causes Issue 2.

const builtin = @import("builtin");
const std = @import("std");

// Why: Simulate RawIO.write for testing.
fn write_byte(b: u8) void {
    _ = b;
}

fn write(s: []const u8) void {
    _ = s;
}

// Why: Test print_int matching Debug.kprint() pattern.
fn print_int(val: anytype) void {
    if (val == 0) {
        write_byte('0');
        return;
    }
    var v = val;
    var buf: [32]u8 = undefined;
    var i: usize = 0;
    const info = @typeInfo(@TypeOf(val));
    if (info == .int and info.int.signedness == .signed) {
        if (v < 0) {
            write_byte('-');
            v = -v;
        }
    }
    while (v > 0) {
        buf[i] = @as(u8, @intCast(v % 10)) + '0';
        v = @divTrunc(v, 10);
        i += 1;
    }
    while (i > 0) {
        i -= 1;
        write_byte(buf[i]);
    }
}

// Why: Test print_hex matching Debug.kprint() pattern.
fn print_hex(val: anytype) void {
    if (val == 0) {
        write("0x0");
        return;
    }
    write("0x");
    var v = val;
    var buf: [32]u8 = undefined;
    var i: usize = 0;
    while (v > 0) {
        const digit = @as(u8, @intCast(v % 16));
        buf[i] = if (digit < 10) digit + '0' else digit - 10 + 'a';
        v = @divTrunc(v, 16);
        i += 1;
    }
    while (i > 0) {
        i -= 1;
        write_byte(buf[i]);
    }
}

// Why: Test print_arg matching Debug.kprint() pattern exactly.
fn print_arg(args: anytype, idx: usize) void {
    inline for (std.meta.fields(@TypeOf(args)), 0..) |field, i| {
        if (i == idx) {
            const val = @field(args, field.name);
            const T = @TypeOf(val);
            if (T == []const u8) {
                write(val);
            } else {
                switch (@typeInfo(T)) {
                    .int => print_int(val),
                    .bool => if (val) write("true") else write("false"),
                    else => write("?"),
                }
            }
            return;
        }
    }
}

// Why: Test print_hex_arg matching Debug.kprint() pattern exactly.
fn print_hex_arg(args: anytype, idx: usize) void {
    inline for (std.meta.fields(@TypeOf(args)), 0..) |field, i| {
        if (i == idx) {
            const val = @field(args, field.name);
            switch (@typeInfo(@TypeOf(val))) {
                .int => print_hex(val),
                else => write("?"),
            }
            return;
        }
    }
}

// Why: Test actual Debug.kprint() usage patterns.
pub fn test_debug_kprint_patterns() void {
    // Why: Test single u64 with {x} (like "PC=0x{x}\n", .{pc}).
    print_hex_arg(.{@as(u64, 0x80000000)}, 0);
    
    // Why: Test two u64 with {x} (like "PC=0x{x} addr=0x{x}\n", .{pc, val}).
    print_hex_arg(.{@as(u64, 0x80000000), @as(u64, 0x1000)}, 0);
    print_hex_arg(.{@as(u64, 0x80000000), @as(u64, 0x1000)}, 1);
    
    // Why: Test string with {s} (like "{s}\n", .{command}).
    print_arg(.{"test"}, 0);
    
    // Why: Test int with {d} (like "{d}\n", .{42}).
    print_arg(.{@as(u32, 42)}, 0);
    print_arg(.{@as(i32, -10)}, 0);
    
    // Why: Test enum with {d} (like "{d}\n", .{@intFromEnum(exc)}).
    const TestEnum = enum { a, b, c };
    print_arg(.{@intFromEnum(TestEnum.b)}, 0);
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Obj
