//! Built-in Shell Commands
//! Why: Core shell commands (cd, ls, pwd, echo, exit) implemented natively.
//! Grain Style: Explicit error handling, bounded allocations.

const std = @import("std");

/// Built-in command handler function type.
pub const BuiltinHandler = *const fn (
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult;

/// Result of built-in command execution.
pub const BuiltinResult = struct {
    exit_code: u8 = 0,
    output: []const u8 = "", // Output to stdout (if any)
    should_exit: bool = false, // True if shell should exit
};

/// Shell environment (for cd, pwd, etc.).
pub const ShellEnvironment = struct {
    current_directory: []u8,
    current_directory_max: usize,
    allocator: std.mem.Allocator,

    /// Get current directory.
    pub fn get_cwd(self: *ShellEnvironment) []const u8 {
        return self.current_directory[0..std.mem.indexOfScalar(u8, self.current_directory[0..self.current_directory_max], 0) orelse 0];
    }

    /// Set current directory.
    pub fn set_cwd(self: *ShellEnvironment, path: []const u8) !void {
        if (path.len >= self.current_directory_max) {
            return BuiltinError.PathTooLong;
        }
        @memset(self.current_directory[0..self.current_directory_max], 0);
        @memcpy(self.current_directory[0..path.len], path);
        self.current_directory[path.len] = 0;
    }
};

/// Built-in command: cd (change directory)
pub fn builtin_cd(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult {
    _ = allocator;

    const target_dir = if (args.len > 0) args[0] else {
        // Default to home directory
        const home = std.posix.getenv("HOME") orelse "/";
        std.posix.chdir(home) catch |err| {
            const stderr = std.io.getStdErr().writer();
            stderr.print("cd: {s}: {s}\n", .{ home, @errorName(err) }) catch {};
            return BuiltinResult{ .exit_code = 1 };
        };
        try env.set_cwd(home);
        return BuiltinResult{ .exit_code = 0 };
    };

    // Resolve path (handle ~ and relative paths)
    var resolved_path: [4096]u8 = undefined;
    var path_buf: []u8 = undefined;

    if (target_dir.len > 0 and target_dir[0] == '~') {
        // Handle ~ expansion
        const home = std.posix.getenv("HOME") orelse "/";
        if (target_dir.len == 1) {
            path_buf = try std.fmt.bufPrint(resolved_path[0..], "{s}", .{home});
        } else {
            path_buf = try std.fmt.bufPrint(resolved_path[0..], "{s}{s}", .{ home, target_dir[1..] });
        }
    } else {
        // Use target_dir directly (std.posix.chdir handles relative paths)
        if (target_dir.len > resolved_path.len) {
            return BuiltinError.PathTooLong;
        }
        @memcpy(resolved_path[0..target_dir.len], target_dir);
        path_buf = resolved_path[0..target_dir.len];
    }

    // Change directory (chdir handles relative path resolution)
    std.posix.chdir(path_buf) catch |err| {
        const stderr = std.io.getStdErr().writer();
        stderr.print("cd: {s}: {s}\n", .{ target_dir, @errorName(err) }) catch {};
        return BuiltinResult{ .exit_code = 1 };
    };

    // Update environment with actual current directory
    var cwd_buf: [4096]u8 = undefined;
    const actual_cwd = try std.posix.getcwd(&cwd_buf);
    try env.set_cwd(actual_cwd);
    return BuiltinResult{ .exit_code = 0 };
}

/// Built-in command: pwd (print working directory)
pub fn builtin_pwd(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult {
    _ = allocator;
    _ = args;

    const cwd = env.get_cwd();
    const output = try allocator.dupe(u8, cwd);
    return BuiltinResult{
        .exit_code = 0,
        .output = output,
    };
}

/// Built-in command: echo (print arguments)
pub fn builtin_echo(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult {
    _ = env;

    // Join arguments with spaces
    var output_list = std.ArrayList(u8).init(allocator);
    defer output_list.deinit();

    for (args, 0..) |arg, i| {
        if (i > 0) {
            try output_list.append(' ');
        }
        try output_list.writer().print("{s}", .{arg});
    }
    try output_list.append('\n');

    const output = try output_list.toOwnedSlice();
    return BuiltinResult{
        .exit_code = 0,
        .output = output,
    };
}

/// Built-in command: ls (list directory)
pub fn builtin_ls(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult {
    const target_dir = if (args.len > 0) args[0] else env.get_cwd();

    // Open directory
    var dir = std.fs.openDirAbsolute(target_dir, .{ .iterate = true }) catch |err| {
        const stderr = std.io.getStdErr().writer();
        stderr.print("ls: {s}: {s}\n", .{ target_dir, @errorName(err) }) catch {};
        return BuiltinResult{ .exit_code = 1 };
    };
    defer dir.close();

    var output_list = std.ArrayList(u8).init(allocator);
    defer output_list.deinit();

    var iter = dir.iterate();
    while (try iter.next()) |entry| {
        try output_list.writer().print("{s}\n", .{entry.name});
    }

    const output = try output_list.toOwnedSlice();
    return BuiltinResult{
        .exit_code = 0,
        .output = output,
    };
}

/// Built-in command: exit (exit shell)
pub fn builtin_exit(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult {
    _ = env;

    const exit_code: u8 = if (args.len > 0) blk: {
        const code_str = args[0];
        const code = std.fmt.parseInt(u8, code_str, 10) catch |err| {
            const stderr = std.io.getStdErr().writer();
            stderr.print("exit: invalid exit code '{s}': {s}\n", .{ code_str, @errorName(err) }) catch {};
            return BuiltinResult{ .exit_code = 1 };
        };
        break :blk code;
    } else 0;

    _ = allocator;
    return BuiltinResult{
        .exit_code = exit_code,
        .should_exit = true,
    };
}

/// Get built-in command handler by name.
pub fn get_builtin(name: []const u8) ?BuiltinHandler {
    if (std.mem.eql(u8, name, "cd")) {
        return builtin_cd;
    } else if (std.mem.eql(u8, name, "pwd")) {
        return builtin_pwd;
    } else if (std.mem.eql(u8, name, "echo")) {
        return builtin_echo;
    } else if (std.mem.eql(u8, name, "ls")) {
        return builtin_ls;
    } else if (std.mem.eql(u8, name, "exit")) {
        return builtin_exit;
    }
    return null;
}

pub const BuiltinError = error{
    PathTooLong,
    OutOfMemory,
    InvalidArgument,
};

