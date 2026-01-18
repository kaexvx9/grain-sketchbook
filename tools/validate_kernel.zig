const std = @import("std");
const grainvalidate = @import("grainvalidate");

// Assert: Grain Style limits must be binary-aligned (64 = 2^6, 128 = 2^7).
const EXPECTED_MAX_FUNCTION_LENGTH: usize = 64;
const EXPECTED_MAX_LINE_WIDTH: usize = 128;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Assert: Default config must use correct binary-aligned limits.
    std.debug.assert(grainvalidate.default_config.max_function_length == EXPECTED_MAX_FUNCTION_LENGTH);
    std.debug.assert(grainvalidate.default_config.max_line_width == EXPECTED_MAX_LINE_WIDTH);

    // Collect all kernel .zig files
    var kernel_dir = try std.fs.cwd().openDir("src/kernel", .{ .iterate = true });
    defer kernel_dir.close();

    var targets = std.ArrayList([]const u8){};
    defer {
        for (targets.items) |path| {
            allocator.free(path);
        }
        targets.deinit(allocator);
    }

    var dir_iter = kernel_dir.iterate();
    while (try dir_iter.next()) |entry| {
        if (entry.kind == .file and std.mem.endsWith(u8, entry.name, ".zig")) {
            const full_path = try std.fmt.allocPrint(allocator, "src/kernel/{s}", .{entry.name});
            try targets.append(allocator, full_path);
        }
    }

    std.log.info("Validating {d} kernel files against Grain Style (64 lines, 128 chars)...", .{targets.items.len});

    var failure = false;
    var total_violations: usize = 0;
    var compliant_files: usize = 0;

    for (targets.items) |path| {
        var file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const contents = try file.readToEndAlloc(allocator, std.math.maxInt(usize));
        defer allocator.free(contents);

        const result = try grainvalidate.validate(
            allocator,
            contents,
            grainvalidate.default_config,
        );
        defer grainvalidate.free_result(allocator, result);

        if (!result.compliant) {
            failure = true;
            total_violations += result.violations.len;
            std.log.err("{s}: {d} violations (functions: {d}, lines: {d})", .{ path, result.violations.len, result.total_functions, result.total_lines });

            for (result.violations) |violation| {
                std.log.err("  line {d}: {s}", .{ violation.line, violation.message });
            }
        } else {
            compliant_files += 1;
            std.log.info("{s}: compliant", .{path});
        }
    }

    std.log.info("Summary: {d}/{d} files compliant, {d} total violations", .{ compliant_files, targets.items.len, total_violations });

    if (failure) {
        return error.ValidationFailed;
    }
}
