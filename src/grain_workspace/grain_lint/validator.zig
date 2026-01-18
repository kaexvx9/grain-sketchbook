//! Grain Style Validator: Function length validation (grainvalidate-64)
//!
//! Why: Provides function length validation using grainvalidate for 64-line limit.
//! Architecture: Integrates with vendor/grainvalidate for validation.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2026-01-18-010225-pst: Cursor CLI + WezTerm + Grain Style Integration

const std = @import("std");

// Bounded: Max file path length (explicit limit, in bytes)
const MAX_FILE_PATH_LEN: u32 = 512;

// Bounded: Max file size (explicit limit, in bytes)
const MAX_FILE_SIZE: u32 = 10_000_000; // 10 MB

// Assert: Function length must be binary-aligned (64 = 2^6).
const MAX_FUNCTION_LENGTH: u32 = 64;

/// Validate file function lengths (64-line limit).
pub fn validate_file(allocator: std.mem.Allocator, file_path: []const u8) !void {
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

    // TODO: Integrate with vendor/grainvalidate for actual validation
    // For now, simple function length checking
    const code = file_content[0..content_len];
    var violations: u32 = 0;
    var in_function: bool = false;
    var function_start_line: u32 = 0;
    var function_line_count: u32 = 0;
    var line_num: u32 = 1;

    var line_iter = std.mem.splitScalar(u8, code, '\n');
    while (line_iter.next()) |line| {
        const trimmed = std.mem.trim(u8, line, &std.ascii.whitespace);

        // Simple function detection (look for "fn " or "pub fn ")
        if (std.mem.startsWith(u8, trimmed, "fn ") or std.mem.startsWith(u8, trimmed, "pub fn ")) {
            // Check previous function if any
            if (in_function and function_line_count > MAX_FUNCTION_LENGTH) {
                std.debug.print("{s}:{d}: Function exceeds {d} lines ({d})\n", .{ file_path, function_start_line, MAX_FUNCTION_LENGTH, function_line_count });
                violations += 1;
            }

            // Start new function
            in_function = true;
            function_start_line = line_num;
            function_line_count = 1;
        } else if (in_function) {
            function_line_count += 1;

            // Check for function end (simple heuristic: closing brace at start of line)
            if (std.mem.startsWith(u8, trimmed, "}")) {
                if (function_line_count > MAX_FUNCTION_LENGTH) {
                    std.debug.print("{s}:{d}: Function exceeds {d} lines ({d})\n", .{ file_path, function_start_line, MAX_FUNCTION_LENGTH, function_line_count });
                    violations += 1;
                }
                in_function = false;
                function_line_count = 0;
            }
        }

        line_num += 1;
    }

    // Check last function if file ends without closing brace
    if (in_function and function_line_count > MAX_FUNCTION_LENGTH) {
        std.debug.print("{s}:{d}: Function exceeds {d} lines ({d})\n", .{ file_path, function_start_line, MAX_FUNCTION_LENGTH, function_line_count });
        violations += 1;
    }

    // Assert: Violations counted successfully (postcondition).
    std.debug.assert(violations <= 1000); // Reasonable upper bound

    if (violations > 0) {
        std.debug.print("Found {d} function length violations\n", .{violations});
    } else {
        std.debug.print("File validated correctly (all functions <= {d} lines)\n", .{MAX_FUNCTION_LENGTH});
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
