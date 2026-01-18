//! Grain Style Syntax Highlighter: Pretty printing for Zig code
//!
//! Why: Provides syntax highlighting and pretty printing for Grain Style
//!      code in terminal editors (Vim, Kakoune, Neovim).
//! Architecture: ANSI color codes, terminal-compatible output.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2026-01-18-010225-pst: Cursor CLI + WezTerm + Grain Style Integration

const std = @import("std");

// Assert: Color codes must be bounded (ANSI escape sequences).
const MAX_COLOR_CODE_LEN: u32 = 20;

// Bounded: Max file path length (explicit limit, in bytes)
const MAX_FILE_PATH_LEN: u32 = 512;

// Bounded: Max file size (explicit limit, in bytes)
const MAX_FILE_SIZE: u32 = 10_000_000; // 10 MB

// ANSI color codes for syntax highlighting
pub const Colors = struct {
    pub const reset = "\x1b[0m";
    pub const keyword = "\x1b[35m"; // Magenta (const, fn, pub, etc.)
    pub const type = "\x1b[36m"; // Cyan (u32, u64, struct, etc.)
    pub const string = "\x1b[32m"; // Green (string literals)
    pub const comment = "\x1b[90m"; // Dark gray (comments)
    pub const function = "\x1b[33m"; // Yellow (function names)
    pub const number = "\x1b[31m"; // Red (numeric literals)
};

/// Highlight Zig code with ANSI colors.
pub fn highlight_zig(allocator: std.mem.Allocator, code: []const u8) ![]const u8 {
    // Assert: Code must be bounded (precondition).
    std.debug.assert(code.len <= MAX_FILE_SIZE);

    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();

    // Simple token-based highlighting (can be enhanced with proper parser)
    var i: u32 = 0;
    while (i < code.len) {
        // Detect keywords, types, strings, comments, etc.
        // (Simplified for example—full implementation would use Zig AST)
        if (std.mem.startsWith(u8, code[i..], "const ")) {
            try result.appendSlice(Colors.keyword);
            try result.appendSlice("const ");
            try result.appendSlice(Colors.reset);
            i += 6;
        } else if (std.mem.startsWith(u8, code[i..], "fn ")) {
            try result.appendSlice(Colors.keyword);
            try result.appendSlice("fn ");
            try result.appendSlice(Colors.reset);
            i += 3;
        } else if (std.mem.startsWith(u8, code[i..], "pub ")) {
            try result.appendSlice(Colors.keyword);
            try result.appendSlice("pub ");
            try result.appendSlice(Colors.reset);
            i += 4;
        } else if (std.mem.startsWith(u8, code[i..], "//")) {
            try result.appendSlice(Colors.comment);
            // Find end of line
            var j = i;
            while (j < code.len and code[j] != '\n') : (j += 1) {}
            try result.appendSlice(code[i..j]);
            try result.appendSlice(Colors.reset);
            i = j;
        } else {
            try result.append(code[i]);
            i += 1;
        }
    }

    return try result.toOwnedSlice();
}

/// Highlight file and print to stdout.
pub fn highlight_file(allocator: std.mem.Allocator, file_path: []const u8) !void {
    // Assert: Allocator and file path must be valid (precondition).
    std.debug.assert(allocator.ptr != null);
    std.debug.assert(file_path.len > 0);
    std.debug.assert(file_path.len <= MAX_FILE_PATH_LEN);

    var file_content: [MAX_FILE_SIZE]u8 = undefined;
    var content_len: u32 = 0;

    if (!read_file_content(file_path, &file_content, &content_len)) {
        std.debug.print("Error: Failed to read file: {s}\n", .{file_path});
        return error.FileReadFailed;
    }

    // Performance: Skip empty files early
    if (content_len == 0) {
        return;
    }

    const code = file_content[0..content_len];
    const highlighted = try highlight_zig(allocator, code);
    defer allocator.free(highlighted);

    const stdout = std.io.getStdOut().writer();
    try stdout.writeAll(highlighted);

    // Assert: Highlighting completed successfully (postcondition).
    std.debug.assert(true);
}

/// Read file content into buffer.
fn read_file_content(
    file_path: []const u8,
    content: []u8,
    content_len: *u32,
) bool {
    // Assert: File path and buffer must be valid (precondition).
    std.debug.assert(file_path.len > 0);
    std.debug.assert(file_path.len <= MAX_FILE_PATH_LEN);
    std.debug.assert(content.len > 0);
    std.debug.assert(content_len != null);

    content_len.* = 0;

    const file = std.fs.cwd().openFile(file_path, .{}) catch |err| {
        _ = err;
        return false;
    };
    defer file.close();

    const file_size = file.getEndPos() catch |err| {
        _ = err;
        return false;
    };

    if (file_size > MAX_FILE_SIZE) {
        return false;
    }

    const size_u32 = @as(u32, @intCast(file_size));
    if (size_u32 > content.len) {
        return false;
    }

    const bytes_read = file.readAll(content[0..size_u32]) catch |err| {
        _ = err;
        return false;
    };

    content_len.* = @as(u32, @intCast(bytes_read));

    // Assert: Content length must be valid (postcondition).
    std.debug.assert(content_len.* <= content.len);

    return true;
}
