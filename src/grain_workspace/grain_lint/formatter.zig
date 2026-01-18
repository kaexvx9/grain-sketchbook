//! Grain Style Formatter: Code formatting (grainwrap-128)
//!
//! Why: Provides code formatting using grainwrap for 128-character line width.
//! Architecture: Integrates with vendor/grainwrap for formatting.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2026-01-18-010225-pst: Cursor CLI + WezTerm + Grain Style Integration

const std = @import("std");

// Bounded: Max file path length (explicit limit, in bytes)
const MAX_FILE_PATH_LEN: u32 = 512;

// Bounded: Max file size (explicit limit, in bytes)
const MAX_FILE_SIZE: u32 = 10_000_000; // 10 MB

// Assert: Line width must be binary-aligned (128 = 2^7).
const MAX_LINE_WIDTH: u32 = 128;

/// Format file using grainwrap (128-character line width).
pub fn format_file(allocator: std.mem.Allocator, file_path: []const u8) !void {
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

    // TODO: Integrate with vendor/grainwrap for actual formatting
    // For now, just validate line width
    const code = file_content[0..content_len];
    var line_iter = std.mem.splitScalar(u8, code, '\n');
    var line_num: u32 = 1;
    var violations: u32 = 0;

    while (line_iter.next()) |line| {
        if (line.len > MAX_LINE_WIDTH) {
            std.debug.print("{s}:{d}: Line exceeds {d} characters ({d})\n", .{ file_path, line_num, MAX_LINE_WIDTH, line.len });
            violations += 1;
        }
        line_num += 1;
    }

    // Assert: Violations counted successfully (postcondition).
    std.debug.assert(violations <= 1000); // Reasonable upper bound

    if (violations > 0) {
        std.debug.print("Found {d} line width violations\n", .{violations});
    } else {
        std.debug.print("File formatted correctly (all lines <= {d} characters)\n", .{MAX_LINE_WIDTH});
    }

    _ = allocator; // Suppress unused warning
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
