//! Kernel Shell - Minimal shell for Basin Kernel
//! Why: Provides basic shell functionality running as a process in Basin Kernel VM.
//! Architecture: Uses kernel syscalls (not POSIX), freestanding environment.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2026-01-18-012944-pst: Framework x86 Basin + Vantage + Grainscript Shell Integration

const std = @import("std");
const Debug = @import("debug.zig");
const RawIO = @import("uart.zig");
const BasinKernel = @import("basin_kernel.zig").BasinKernel;
const grainscript = @import("grainscript");
const Lexer = grainscript.Lexer;
const Parser = grainscript.Parser;
const Interpreter = grainscript.Interpreter;

// Bounded: Max line length (explicit limit, in bytes)
const MAX_LINE_LEN: u32 = 512;

// Bounded: Max command arguments (explicit limit)
const MAX_ARGS: u32 = 16;

// Bounded: Max Grainscript source code length (explicit limit, in bytes)
const MAX_GRAINSCRIPT_LEN: u32 = 4096;

/// Read a line from UART (blocking, with echo and backspace handling).
/// Why: Encapsulate line input logic for cleaner main function.
/// Returns: Length of line read.
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

/// Kernel Shell main entry point.
/// Why: Entry point for shell process spawned in Basin Kernel.
/// Contract: Kernel must be initialized, shell runs as process in VM.
/// Export as C symbol for assembly entry point.
export fn main() void {
    Debug.kprint("Grainscript Shell v0.1.0 (Basin Kernel)\n", .{});
    Debug.kprint("Type 'help' for commands, 'exit' to exit.\n\n", .{});
    
    // Fixed buffer allocator for shell operations.
    var allocator_buffer: [64 * 1024]u8 = undefined;
    var fixed_allocator = std.heap.FixedBufferAllocator.init(&allocator_buffer);
    const allocator = fixed_allocator.allocator();
    
    var should_exit = false;
    var line_buf: [MAX_LINE_LEN]u8 = undefined;
    
    while (!should_exit) {
        Debug.kprint("grainscript> ", .{});
        const line_len = read_line(&line_buf);
        Debug.kprint("\n", .{});
        if (line_len > 0) {
            should_exit = process_command(allocator, line_buf[0..line_len]);
        }
    }
    Debug.kprint("Goodbye!\n", .{});
}

/// Process command line.
/// Why: Parse and execute shell commands.
/// Contract: line must be valid, allocator must be valid.
/// Returns: true if shell should exit, false otherwise.
fn process_command(allocator: std.mem.Allocator, line: []const u8) bool {
    // Assert: Line must be valid (precondition).
    std.debug.assert(line.len > 0);
    std.debug.assert(line.len <= MAX_LINE_LEN);
    
    // Trim whitespace.
    var trimmed = line;
    while (trimmed.len > 0 and (trimmed[0] == ' ' or trimmed[0] == '\t')) {
        trimmed = trimmed[1..];
    }
    while (trimmed.len > 0 and (trimmed[trimmed.len - 1] == ' ' or trimmed[trimmed.len - 1] == '\t')) {
        trimmed = trimmed[0..trimmed.len - 1];
    }
    
    if (trimmed.len == 0) {
        return false; // Empty line
    }
    
    // Parse command and arguments.
    var args: [MAX_ARGS][]const u8 = undefined;
    var arg_count: u32 = 0;
    var i: u32 = 0;
    var start: u32 = 0;
    
    while (i < trimmed.len and arg_count < MAX_ARGS) {
        if (trimmed[i] == ' ' or trimmed[i] == '\t') {
            if (i > start) {
                args[arg_count] = trimmed[start..i];
                arg_count += 1;
            }
            start = i + 1;
        }
        i += 1;
    }
    
    if (start < trimmed.len and arg_count < MAX_ARGS) {
        args[arg_count] = trimmed[start..];
        arg_count += 1;
    }
    
    if (arg_count == 0) {
        return false;
    }
    
    const command = args[0];
    const command_args = if (arg_count > 1) args[1..arg_count] else &[_][]const u8{};
    
    // Execute command.
    return execute_command(allocator, command, command_args);
}

/// Execute command.
/// Why: Handle shell built-in commands.
/// Contract: command and args must be valid, allocator must be valid.
/// Returns: true if shell should exit, false otherwise.
fn execute_command(allocator: std.mem.Allocator, command: []const u8, args: []const []const u8) bool {
    // Assert: Command must be valid (precondition).
    std.debug.assert(command.len > 0);
    
    // Help command.
    if (std.mem.eql(u8, command, "help")) {
        Debug.kprint("Available commands:\n", .{});
        Debug.kprint("  help          - Show this help message\n", .{});
        Debug.kprint("  echo <text>   - Print text\n", .{});
        Debug.kprint("  eval <code>   - Execute Grainscript code\n", .{});
        Debug.kprint("  exit          - Exit shell\n", .{});
        return false;
    }
    
    // Exit command.
    if (std.mem.eql(u8, command, "exit")) {
        return true; // Signal shell to exit
    }
    
    // Echo command.
    if (std.mem.eql(u8, command, "echo")) {
        cmd_echo(args);
        return false;
    }
    
    // Eval command (Grainscript execution).
    if (std.mem.eql(u8, command, "eval")) {
        cmd_eval(allocator, args);
        return false;
    }
    
    // Unknown command.
    Debug.kprint("Unknown command: {s}\n", .{command});
    Debug.kprint("Type 'help' for available commands.\n", .{});
    return false;
}

/// Execute echo command.
/// Why: Print text to output.
/// Contract: args must be valid.
fn cmd_echo(args: []const []const u8) void {
    // Assert: Args must be valid (precondition).
    std.debug.assert(@intFromPtr(args.ptr) != 0);
    
    // Print all arguments separated by spaces.
    var i: u32 = 0;
    while (i < args.len) : (i += 1) {
        if (i > 0) {
            Debug.kprint(" ", .{});
        }
        Debug.kprint("{s}", .{args[i]});
    }
    Debug.kprint("\n", .{});
}

/// Execute eval command (Grainscript execution).
/// Why: Execute Grainscript code in shell for testing and development.
/// Contract: allocator and args must be valid.
fn cmd_eval(allocator: std.mem.Allocator, args: []const []const u8) void {
    // Assert: Args must be valid (precondition).
    std.debug.assert(@intFromPtr(args.ptr) != 0);
    
    // Check for code argument.
    if (args.len == 0) {
        Debug.kprint("Error: eval requires code argument\n", .{});
        Debug.kprint("Usage: eval <grainscript_code>\n", .{});
        Debug.kprint("Example: eval \"42 + 8;\"\n", .{});
        return;
    }
    
    // Combine all arguments into source code (space-separated).
    var source_buf: [MAX_GRAINSCRIPT_LEN]u8 = undefined;
    var source_len: u32 = 0;
    
    var arg_i: u32 = 0;
    while (arg_i < args.len and source_len < MAX_GRAINSCRIPT_LEN) : (arg_i += 1) {
        const arg = args[arg_i];
        
        // Add space between arguments (except first).
        if (arg_i > 0 and source_len < MAX_GRAINSCRIPT_LEN) {
            source_buf[source_len] = ' ';
            source_len += 1;
        }
        
        // Copy argument to source buffer.
        var i: u32 = 0;
        while (i < arg.len and source_len < MAX_GRAINSCRIPT_LEN) : (i += 1) {
            source_buf[source_len] = arg[i];
            source_len += 1;
        }
    }
    
    const source = source_buf[0..source_len];
    
    // Execute Grainscript code.
    execute_grainscript(allocator, source);
}

/// Execute Grainscript code.
/// Why: Run Grainscript interpreter on source code.
/// Contract: allocator and source must be valid.
fn execute_grainscript(allocator: std.mem.Allocator, source: []const u8) void {
    // Assert: Source must be valid (precondition).
    std.debug.assert(source.len > 0);
    std.debug.assert(source.len <= MAX_GRAINSCRIPT_LEN);
    
    // Initialize Grainscript components.
    var lexer = Lexer.init(allocator, source) catch |err| {
        Debug.kprint("Error: Failed to create lexer: {s}\n", .{@errorName(err)});
        return;
    };
    defer lexer.deinit();
    
    // Tokenize source code.
    lexer.tokenize() catch |err| {
        Debug.kprint("Error: Failed to tokenize: {s}\n", .{@errorName(err)});
        return;
    };
    
    // Create parser.
    var parser = Parser.init(allocator, &lexer) catch |err| {
        Debug.kprint("Error: Failed to create parser: {s}\n", .{@errorName(err)});
        return;
    };
    defer parser.deinit();
    
    // Parse source code.
    parser.parse() catch |err| {
        Debug.kprint("Error: Failed to parse: {s}\n", .{@errorName(err)});
        return;
    };
    
    // Create interpreter.
    var interpreter = Interpreter.init(allocator, &parser) catch |err| {
        Debug.kprint("Error: Failed to create interpreter: {s}\n", .{@errorName(err)});
        return;
    };
    defer interpreter.deinit();
    
    // Execute Grainscript code.
    interpreter.execute() catch |err| {
        Debug.kprint("Error: Failed to execute: {s}\n", .{@errorName(err)});
        return;
    };
    
    // Print output from interpreter (freestanding-compatible).
    const output = interpreter.get_output();
    if (output.len > 0) {
        Debug.kprint("{s}", .{output});
    }
}
