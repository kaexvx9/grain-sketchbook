const RawIO = @import("uart.zig");
const std = @import("std");

/// Global debug/verbose flag.
/// Why: Allow toggling verbose debug output for development.
/// Set via compile-time flag or runtime (future: kernel parameter).
var debug_verbose: bool = false;

/// Enable verbose debug output.
/// Why: Allow enabling detailed debug messages.
pub fn set_verbose(enabled: bool) void {
    debug_verbose = enabled;
}

/// Check if verbose mode is enabled.
/// Why: Allow conditional debug output.
pub fn is_verbose() bool {
    return debug_verbose;
}

/// Grain Style: Explicit logging levels
pub const LogLevel = enum {
    debug,
    info,
    warn,
    error_lvl, // 'error' is a keyword
};

/// Kernel print function.
/// Why: Minimal printf for kernel output without std library atomics.
pub fn kprint(comptime fmt: []const u8, args: anytype) void {
    var arg_idx: usize = 0;
    var i: usize = 0;
    while (i < fmt.len) {
        if (fmt[i] == '{') {
            // Handle format specifier
            if (i + 1 < fmt.len and fmt[i+1] == '}') {
                // Simple {}
                print_arg(args, arg_idx);
                arg_idx += 1;
                i += 2;
            } else if (i + 2 < fmt.len and fmt[i+1] == 'd' and fmt[i+2] == '}') {
                // {d} decimal
                print_arg(args, arg_idx);
                arg_idx += 1;
                i += 3;
            } else if (i + 2 < fmt.len and fmt[i+1] == 'x' and fmt[i+2] == '}') {
                // {x} hex
                print_hex_arg(args, arg_idx);
                arg_idx += 1;
                i += 3;
            } else if (i + 2 < fmt.len and fmt[i+1] == 's' and fmt[i+2] == '}') {
                // {s} string
                print_arg(args, arg_idx);
                arg_idx += 1;
                i += 3;
            } else {
                // Unknown, just print char
                RawIO.write_byte(fmt[i]);
                i += 1;
            }
        } else {
            RawIO.write_byte(fmt[i]);
            i += 1;
        }
    }
}

fn print_arg(args: anytype, idx: usize) void {
    inline for (std.meta.fields(@TypeOf(args)), 0..) |field, i| {
        if (i == idx) {
            const val = @field(args, field.name);
            const T = @TypeOf(val);
            if (T == []const u8) {
                RawIO.write(val);
            } else {
                switch (@typeInfo(T)) {
                    .int => print_int(val),
                    .bool => if (val) RawIO.write("true") else RawIO.write("false"),
                    else => RawIO.write("?"),
                }
            }
            return;
        }
    }
}

fn print_hex_arg(args: anytype, idx: usize) void {
    inline for (std.meta.fields(@TypeOf(args)), 0..) |field, i| {
        if (i == idx) {
            const val = @field(args, field.name);
            const T = @TypeOf(val);
            switch (@typeInfo(T)) {
                .int => print_hex(val),
                else => RawIO.write("?"),
            }
            return;
        }
    }
}

fn print_int(val: anytype) void {
    if (val == 0) {
        RawIO.write_byte('0');
        return;
    }
    
    var v = val;
    var buf: [32]u8 = undefined;
    var i: usize = 0;
    
    // Handle negative for signed integers
    const info = @typeInfo(@TypeOf(val));
    if (info == .int and info.int.signedness == .signed) {
        if (v < 0) {
            RawIO.write_byte('-');
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
        RawIO.write_byte(buf[i]);
    }
}

fn print_hex(val: anytype) void {
    if (val == 0) {
        RawIO.write("0x0");
        return;
    }
    
    RawIO.write("0x");
    var v = val;
    var buf: [32]u8 = undefined;
    var i: usize = 0;
    
    while (v > 0) {
        const digit = @as(u8, @intCast(v % 16));
        if (digit < 10) {
            buf[i] = digit + '0';
        } else {
            buf[i] = digit - 10 + 'a';
        }
        v = @divTrunc(v, 16);
        i += 1;
    }
    
    while (i > 0) {
        i -= 1;
        RawIO.write_byte(buf[i]);
    }
}

/// Kernel assertion.
/// Why: Runtime invariant checking (disabled due to Zig RV64 codegen issues).
pub fn kassert(ok: bool, comptime msg: []const u8, args: anytype) void {
    // Complete no-op - any code here causes codegen issues
    _ = ok;
    _ = msg;
    _ = args;
}

/// Log with level.
/// Why: Structured logging with severity (disabled due to codegen issues).
pub fn log(comptime level: LogLevel, comptime fmt: []const u8, args: anytype) void {
    // No-op - codegen issues with kprint
    _ = level;
    _ = fmt;
    _ = args;
}

/// Debug print.
/// Why: Conditional debug output (disabled due to codegen issues).
pub fn dprint(comptime fmt: []const u8, args: anytype) void {
    // No-op - codegen issues with kprint
    _ = fmt;
    _ = args;
}

/// Verbose debug print - DISABLED due to codegen issues.
/// Why: Zig RV64 freestanding has issues with global variable reads and kprint.
pub fn vprint(comptime fmt: []const u8, args: anytype) void {
    // No-op for now - codegen issues with global var reads and kprint
    _ = fmt;
    _ = args;
}
