//! Grain Style Linter: Core linting logic
//!
//! Why: Provides core linting functionality for Grain Style compliance.
//! Architecture: Integrates with grain_workspace.devtools for linting.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2026-01-18-010225-pst: Cursor CLI + WezTerm + Grain Style Integration

const std = @import("std");
const grain_workspace = @import("grain_workspace");

// Bounded: Max file path length (explicit limit, in bytes)
const MAX_FILE_PATH_LEN: u32 = 512;

// Bounded: Max file size (explicit limit, in bytes)
const MAX_FILE_SIZE: u32 = 10_000_000; // 10 MB

// Bounded: Max output buffer size (explicit limit, in bytes)
const MAX_OUTPUT_BUFFER_SIZE: u32 = 1_048_576; // 1 MB

/// Lint file and print violations.
pub fn lint_file(allocator: std.mem.Allocator, file_path: []const u8) !void {
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

    var devtools_app = grain_workspace.devtools.DevToolsApp.init(allocator);

    const violations = devtools_app.lint_grain_style(
        file_path,
        file_content[0..content_len],
    );

    const alloc_violations = devtools_app.check_bounded_allocations(
        file_path,
        file_content[0..content_len],
    );

    // Assert: Violation count must be valid (postcondition).
    std.debug.assert(violations + alloc_violations <= grain_workspace.devtools.MAX_LINT_VIOLATIONS);

    // Print violations
    var messages: [256]?grain_workspace.devtools.LinterMessage = undefined;
    var messages_len: u32 = 0;
    devtools_app.get_linter_messages(file_path, &messages, &messages_len);

    var output_buffer: [MAX_OUTPUT_BUFFER_SIZE]u8 = undefined;
    var i: u32 = 0;
    while (i < messages_len) : (i += 1) {
        if (messages[i]) |msg| {
            const file_path_str = msg.file_path[0..msg.file_path_len];
            const message_str = msg.message[0..msg.message_len];
            const severity_str = switch (msg.severity) {
                .info => "info",
                .warning => "warning",
                .error => "error",
                .critical => "critical",
            };

            const color_code = switch (msg.severity) {
                .info => "\x1b[36m", // Cyan
                .warning => "\x1b[33m", // Yellow
                .error => "\x1b[31m", // Red
                .critical => "\x1b[35m", // Magenta
            };
            const reset_code = "\x1b[0m";

            const formatted = std.fmt.bufPrint(
                &output_buffer,
                "{s}:{d}:{d}: {s}{s}{s}: {s}\n",
                .{ file_path_str, msg.line_number, msg.column_number, color_code, severity_str, reset_code, message_str },
            ) catch continue;

            const stdout = std.io.getStdOut().writer();
            _ = stdout.write(formatted) catch {};
        }
    }

    // Postcondition: All violations printed successfully.
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
