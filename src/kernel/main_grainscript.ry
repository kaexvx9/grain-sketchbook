//! Basin Kernel - Grainscript Entry Point
//! Why: Boot kernel with full Grainscript interpreter.
//! Uses FixedBufferAllocator for freestanding mode (no heap).

const std = @import("std");
const grainscript = @import("grainscript");
const Lexer = grainscript.Lexer;
const Parser = grainscript.Parser;
const Interpreter = grainscript.Interpreter;

/// Comptime-unrolled UART print.
/// Why: Avoid runtime loop codegen issues.
inline fn uart_print(comptime s: []const u8) void {
    inline for (s) |c| {
        asm volatile (
            \\lui t1, 0x10000
            \\sb %[byte], 0(t1)
            :
            : [byte] "r" (c),
        );
    }
}

/// Read byte from UART (blocking, inline ASM).
/// Why: Avoid Zig runtime loop codegen issues.
inline fn uart_getc() u8 {
    var byte: u8 = undefined;
    asm volatile (
        \\.Lwait_input:
        \\lui t1, 0x10000
        \\lbu t2, 5(t1)
        \\andi t2, t2, 1
        \\beqz t2, .Lwait_input
        \\lbu %[out], 0(t1)
        : [out] "=r" (byte),
    );
    return byte;
}

/// Write byte to UART.
inline fn uart_putc(c: u8) void {
    asm volatile (
        \\lui t1, 0x10000
        \\sb %[byte], 0(t1)
        :
        : [byte] "r" (c),
    );
}

const MAX_LINE: usize = 512;
const GARDEN_SIZE: usize = 64 * 1024;

/// Read line from UART with echo.
fn read_line(buf: *[MAX_LINE]u8) usize {
    var len: usize = 0;
    while (len < MAX_LINE) {
        const c = uart_getc();
        if (c == '\n' or c == '\r') {
            uart_putc('\n');
            break;
        }
        if (c == '\x08' or c == '\x7f') {
            if (len > 0) {
                len -= 1;
                uart_putc('\x08');
                uart_putc(' ');
                uart_putc('\x08');
            }
            continue;
        }
        if (c >= 0x20 and c < 0x7f) {
            buf[len] = c;
            len += 1;
            uart_putc(c);
        }
    }
    return len;
}

/// Execute Grainscript code and print result.
fn eval_grainscript(allocator: std.mem.Allocator, source: []const u8) void {
    var lexer = Lexer.init(allocator, source) catch {
        uart_print("Error: lexer init failed\n");
        return;
    };
    defer lexer.deinit();

    lexer.tokenize() catch {
        uart_print("Error: tokenize failed\n");
        return;
    };

    var parser = Parser.init(allocator, &lexer) catch {
        uart_print("Error: parser init failed\n");
        return;
    };
    defer parser.deinit();

    parser.parse() catch {
        uart_print("Error: parse failed\n");
        return;
    };

    var interp = Interpreter.init(allocator, &parser) catch {
        uart_print("Error: interpreter init failed\n");
        return;
    };
    defer interp.deinit();

    const result = interp.execute_repl() catch {
        uart_print("Error: execute failed\n");
        return;
    };

    // Print interpreter output buffer first (echo, print, etc.)
    const output = interp.get_output();
    for (output) |c| uart_putc(c);

    // Print last expression result (REPL mode)
    print_value(result);
}

fn print_value(val: Interpreter.Value) void {
    switch (val) {
        .integer => |v| { print_int(v); uart_putc('\n'); },
        .float => |v| { print_float(v); uart_putc('\n'); },
        .string => |s| { for (s) |c| uart_putc(c); uart_putc('\n'); },
        .boolean => |b| { if (b) uart_print("true\n") else uart_print("false\n"); },
        .null => {},
    }
}

fn print_int(v: i64) void {
    if (v < 0) { uart_putc('-'); print_int(-v); return; }
    if (v >= 10) print_int(@divTrunc(v, 10));
    uart_putc(@intCast(@as(u64, @intCast(@mod(v, 10))) + '0'));
}

fn print_float(v: f64) void {
    const int_part: i64 = @intFromFloat(v);
    print_int(int_part);
}


/// REPL loop.
fn repl(allocator: std.mem.Allocator) void {
    var line_buf: [MAX_LINE]u8 = undefined;

    while (true) {
        uart_print("grainscript> ");
        const len = read_line(&line_buf);
        if (len == 0) continue;

        const line = line_buf[0..len];

        // Built-in commands
        if (std.mem.eql(u8, line, "exit")) {
            uart_print("Goodbye!\n");
            break;
        }
        if (std.mem.eql(u8, line, "help")) {
            uart_print("Commands:\n");
            uart_print("  help        - Show this help\n");
            uart_print("  exit        - Halt kernel\n");
            uart_print("  <expr>;     - Evaluate and print result\n");
            uart_print("  var x = 1;  - Declare variable\n");
            uart_print("Examples: 6 * 7;  or  var x = 42;\n");
            continue;
        }

        // Execute as Grainscript
        eval_grainscript(allocator, line);
    }
}

pub export fn kmain() noreturn {
    uart_print("\n");
    uart_print("Basin Kernel v0.2.0 (RISC-V64 + Grainscript)\n");
    uart_print("Copyright (c) 2026 Team Libra\n");
    uart_print("\n");
    uart_print("Type 'help' for commands, 'exit' to halt.\n");
    uart_print("\n");

    // Garden-allocated memory (static, bounded)
    var garden: [GARDEN_SIZE]u8 = undefined;
    var fixed = std.heap.FixedBufferAllocator.init(&garden);

    repl(fixed.allocator());

    uart_print("[Halted]\n");
    while (true) {
        asm volatile ("wfi");
    }
}
