//! Grain Style Linter: Terminal and Editor Integration
//!
//! Why: Provides Grain Style linting, formatting, and syntax highlighting
//!      for WezTerm, Vim, Kakoune, and Neovim.
//! Architecture: Modular design with editor-specific integrations.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2026-01-18-010225-pst: Cursor CLI + WezTerm + Grain Style Integration

const std = @import("std");
const linter = @import("linter.zig");
const formatter = @import("formatter.zig");
const validator = @import("validator.zig");
const syntax_highlighter = @import("syntax_highlighter.zig");
const editor_integration = @import("editor_integration.zig");

// Assert: Grain Style limits must be binary-aligned (64 = 2^6, 128 = 2^7).
const MAX_FUNCTION_LENGTH: u32 = 64;
const MAX_LINE_WIDTH: u32 = 128;

// Bounded: Max file path length (explicit limit, in bytes)
const MAX_FILE_PATH_LEN: u32 = 512;

// Bounded: Max file size (explicit limit, in bytes)
const MAX_FILE_SIZE: u32 = 10_000_000; // 10 MB

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Assert: Allocator must be valid (precondition).
    std.debug.assert(allocator.ptr != null);

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next(); // Skip executable name

    const command = args.next() orelse {
        print_usage();
        return;
    };

    if (std.mem.eql(u8, command, "lint")) {
        try run_linter(allocator, &args);
    } else if (std.mem.eql(u8, command, "format")) {
        try run_formatter(allocator, &args);
    } else if (std.mem.eql(u8, command, "validate")) {
        try run_validator(allocator, &args);
    } else if (std.mem.eql(u8, command, "highlight")) {
        try run_syntax_highlighter(allocator, &args);
    } else {
        print_usage();
        return error.InvalidCommand;
    }

    // Assert: Command executed successfully (postcondition).
    std.debug.assert(true);
}

fn print_usage() void {
    const stdout = std.io.getStdOut().writer();
    stdout.print(
        \\Grain Style Linter — Terminal and Editor Integration
        \\
        \\Usage:
        \\  grain_lint lint <file>           Check Grain Style violations
        \\  grain_lint format <file>         Format code (grainwrap-128)
        \\  grain_lint validate <file>       Validate function length (grainvalidate-64)
        \\  grain_lint highlight <file>      Generate syntax highlighting
        \\
        \\Grain Style Limits:
        \\  - Function length: {d} lines (2^6, binary-aligned)
        \\  - Line width: {d} characters (2^7, binary-aligned)
        \\
    , .{ MAX_FUNCTION_LENGTH, MAX_LINE_WIDTH }) catch {};
}

fn run_linter(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    // Assert: Allocator must be valid (precondition).
    std.debug.assert(allocator.ptr != null);

    const file_path = args.next() orelse {
        std.debug.print("Error: No file specified\n", .{});
        return error.MissingFile;
    };

    // Assert: File path must be bounded (precondition).
    std.debug.assert(file_path.len <= MAX_FILE_PATH_LEN);

    try linter.lint_file(allocator, file_path);
}

fn run_formatter(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    // Assert: Allocator must be valid (precondition).
    std.debug.assert(allocator.ptr != null);

    const file_path = args.next() orelse {
        std.debug.print("Error: No file specified\n", .{});
        return error.MissingFile;
    };

    // Assert: File path must be bounded (precondition).
    std.debug.assert(file_path.len <= MAX_FILE_PATH_LEN);

    try formatter.format_file(allocator, file_path);
}

fn run_validator(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    // Assert: Allocator must be valid (precondition).
    std.debug.assert(allocator.ptr != null);

    const file_path = args.next() orelse {
        std.debug.print("Error: No file specified\n", .{});
        return error.MissingFile;
    };

    // Assert: File path must be bounded (precondition).
    std.debug.assert(file_path.len <= MAX_FILE_PATH_LEN);

    try validator.validate_file(allocator, file_path);
}

fn run_syntax_highlighter(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    // Assert: Allocator must be valid (precondition).
    std.debug.assert(allocator.ptr != null);

    const file_path = args.next() orelse {
        std.debug.print("Error: No file specified\n", .{});
        return error.MissingFile;
    };

    // Assert: File path must be bounded (precondition).
    std.debug.assert(file_path.len <= MAX_FILE_PATH_LEN);

    try syntax_highlighter.highlight_file(allocator, file_path);
}
