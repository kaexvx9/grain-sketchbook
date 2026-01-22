//! Kernel Shell - Minimal shell for Basin Kernel
//! Why: Provides basic shell functionality running as a process in Basin Kernel VM.

const std = @import("std");
const Debug = @import("debug.zig");
const RawIO = @import("uart.zig");
const BasinKernel = @import("basin_kernel.zig").BasinKernel;
const grainscript = @import("grainscript");
const Lexer = grainscript.Lexer;
const Parser = grainscript.Parser;
const Interpreter = grainscript.Interpreter;

const MAX_LINE_LEN: u32 = 512;
const MAX_ARGS: u32 = 16;
const MAX_GRAINSCRIPT_LEN: u32 = 4096;

/// Why: Encapsulate line input logic for cleaner main function.
fn read_line(line_buf: *[MAX_LINE_LEN]u8) u32 {
    var line_len: u32 = 0;
    while (line_len < MAX_LINE_LEN) {
        const c = RawIO.read_byte_blocking();
        if (c == '\n' or c == '\r') break;
        if (c == '\x08' or c == '\x7f') {
            if (line_len > 0) {
                line_len -= 1;
                RawIO.write_byte('\x08');
                RawIO.write_byte(' ');
                RawIO.write_byte('\x08');
            }
            continue;
        }
        if (c >= 0x20 and c < 0x7f) {
            line_buf[line_len] = c;
            line_len += 1;
            RawIO.write_byte(c);
        }
    }
    return line_len;
}

/// Why: Entry point for shell process spawned in Basin Kernel.
export fn main() void {
    Debug.kprint("Grainscript Shell 20260121.194401.grainscript (Basin Kernel)\n", .{});
    Debug.kprint("Type 'help' for commands, 'exit' to exit.\n\n", .{});
    var allocator_buffer: [64 * 1024]u8 = undefined;
    var fixed_allocator = std.heap.FixedBufferAllocator.init(&allocator_buffer);
    const allocator = fixed_allocator.allocator();
    var should_exit = false;
    var line_buf: [MAX_LINE_LEN]u8 = undefined;
    while (!should_exit) {
        Debug.kprint("grainscript> ", .{});
        const line_len = read_line(&line_buf);
        Debug.kprint("\n", .{});
        if (line_len > 0) should_exit = process_command(allocator, line_buf[0..line_len]);
    }
    Debug.kprint("Goodbye!\n", .{});
}

fn trim_start(s: []const u8) []const u8 {
    var t = s;
    while (t.len > 0 and (t[0] == ' ' or t[0] == '\t')) t = t[1..];
    return t;
}

fn trim_end(s: []const u8) []const u8 {
    var t = s;
    while (t.len > 0 and (t[t.len - 1] == ' ' or t[t.len - 1] == '\t')) t = t[0..t.len - 1];
    return t;
}

fn parse_args(trimmed: []const u8, args: *[MAX_ARGS][]const u8) u32 {
    var arg_count: u32 = 0;
    var i: u32 = 0;
    var start: u32 = 0;
    while (i < trimmed.len and arg_count < MAX_ARGS) {
        if (trimmed[i] == ' ' or trimmed[i] == '\t') {
            if (i > start) { args[arg_count] = trimmed[start..i]; arg_count += 1; }
            start = i + 1;
        }
        i += 1;
    }
    if (start < trimmed.len and arg_count < MAX_ARGS) { args[arg_count] = trimmed[start..]; arg_count += 1; }
    return arg_count;
}

/// Why: Parse and execute shell commands.
fn process_command(allocator: std.mem.Allocator, line: []const u8) bool {
    std.debug.assert(line.len > 0);
    std.debug.assert(line.len <= MAX_LINE_LEN);
    const trimmed = trim_end(trim_start(line));
    if (trimmed.len == 0) return false;
    var args: [MAX_ARGS][]const u8 = undefined;
    const arg_count = parse_args(trimmed, &args);
    if (arg_count == 0) return false;
    const command = args[0];
    const command_args = if (arg_count > 1) args[1..arg_count] else &[_][]const u8{};
    return execute_command(allocator, command, command_args);
}

/// Why: Handle shell built-in commands.
fn execute_command(allocator: std.mem.Allocator, command: []const u8, args: []const []const u8) bool {
    std.debug.assert(command.len > 0);
    if (std.mem.eql(u8, command, "help")) {
        Debug.kprint("Available commands:\n", .{});
        Debug.kprint("  help          - Show this help message\n", .{});
        Debug.kprint("  echo <text>   - Print text\n", .{});
        Debug.kprint("  eval <code>   - Execute Grainscript code\n", .{});
        Debug.kprint("  exit          - Exit shell\n", .{});
        return false;
    }
    if (std.mem.eql(u8, command, "exit")) return true;
    if (std.mem.eql(u8, command, "echo")) { cmd_echo(args); return false; }
    if (std.mem.eql(u8, command, "eval")) { cmd_eval(allocator, args); return false; }
    Debug.kprint("Unknown command: {s}\n", .{command});
    Debug.kprint("Type 'help' for available commands.\n", .{});
    return false;
}

/// Why: Print text to output.
fn cmd_echo(args: []const []const u8) void {
    std.debug.assert(@intFromPtr(args.ptr) != 0);
    var i: u32 = 0;
    while (i < args.len) : (i += 1) {
        if (i > 0) Debug.kprint(" ", .{});
        Debug.kprint("{s}", .{args[i]});
    }
    Debug.kprint("\n", .{});
}

fn build_source(args: []const []const u8, buf: *[MAX_GRAINSCRIPT_LEN]u8) u32 {
    var len: u32 = 0;
    var arg_i: u32 = 0;
    while (arg_i < args.len and len < MAX_GRAINSCRIPT_LEN) : (arg_i += 1) {
        const arg = args[arg_i];
        if (arg_i > 0 and len < MAX_GRAINSCRIPT_LEN) { buf[len] = ' '; len += 1; }
        var i: u32 = 0;
        while (i < arg.len and len < MAX_GRAINSCRIPT_LEN) : (i += 1) { buf[len] = arg[i]; len += 1; }
    }
    return len;
}

/// Why: Execute Grainscript code in shell for testing and development.
fn cmd_eval(allocator: std.mem.Allocator, args: []const []const u8) void {
    std.debug.assert(@intFromPtr(args.ptr) != 0);
    if (args.len == 0) {
        Debug.kprint("Error: eval requires code argument\n", .{});
        Debug.kprint("Usage: eval <grainscript_code>\n", .{});
        Debug.kprint("Example: eval \"42 + 8;\"\n", .{});
        return;
    }
    var source_buf: [MAX_GRAINSCRIPT_LEN]u8 = undefined;
    const source_len = build_source(args, &source_buf);
    const source = source_buf[0..source_len];
    execute_grainscript(allocator, source);
}

fn init_lexer(allocator: std.mem.Allocator, source: []const u8) ?Lexer {
    return Lexer.init(allocator, source) catch |err| {
        Debug.kprint("Error: Failed to create lexer: {s}\n", .{@errorName(err)});
        return null;
    };
}

fn tokenize_source(lexer: *Lexer) bool {
    lexer.tokenize() catch |err| {
        Debug.kprint("Error: Failed to tokenize: {s}\n", .{@errorName(err)});
        return false;
    };
    return true;
}

fn init_parser(allocator: std.mem.Allocator, lexer: *Lexer) ?Parser {
    return Parser.init(allocator, lexer) catch |err| {
        Debug.kprint("Error: Failed to create parser: {s}\n", .{@errorName(err)});
        return null;
    };
}

fn parse_source(parser: *Parser) bool {
    parser.parse() catch |err| {
        Debug.kprint("Error: Failed to parse: {s}\n", .{@errorName(err)});
        return false;
    };
    return true;
}

fn init_interpreter(allocator: std.mem.Allocator, parser: *Parser) ?Interpreter {
    return Interpreter.init(allocator, parser) catch |err| {
        Debug.kprint("Error: Failed to create interpreter: {s}\n", .{@errorName(err)});
        return null;
    };
}

fn run_interpreter(interp: *Interpreter) bool {
    interp.execute() catch |err| {
        Debug.kprint("Error: Failed to execute: {s}\n", .{@errorName(err)});
        return false;
    };
    return true;
}

/// Why: Run Grainscript interpreter on source code.
fn execute_grainscript(allocator: std.mem.Allocator, source: []const u8) void {
    std.debug.assert(source.len > 0);
    std.debug.assert(source.len <= MAX_GRAINSCRIPT_LEN);
    var lexer = init_lexer(allocator, source) orelse return;
    defer lexer.deinit();
    if (!tokenize_source(&lexer)) return;
    var parser = init_parser(allocator, &lexer) orelse return;
    defer parser.deinit();
    if (!parse_source(&parser)) return;
    var interpreter = init_interpreter(allocator, &parser) orelse return;
    defer interpreter.deinit();
    if (!run_interpreter(&interpreter)) return;
    const output = interpreter.get_output();
    if (output.len > 0) Debug.kprint("{s}", .{output});
}
