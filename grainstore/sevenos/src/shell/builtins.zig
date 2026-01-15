//! Built-in Shell Commands
//! Why: Core shell commands (cd, ls, pwd, echo, exit) implemented natively.
//! Grain Style: Explicit error handling, bounded allocations.

const std = @import("std");
const stdio = @import("stdio_wrapper.zig");
const service_manager = @import("service_manager.zig");

/// Built-in command handler function type.
/// Note: Service commands need ServiceManager, which is passed separately.
pub const BuiltinHandler = *const fn (
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult;

/// Service command handler (needs ServiceManager).
pub const ServiceHandler = *const fn (
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
    service_mgr: *service_manager.ServiceManager,
) BuiltinError!BuiltinResult;

/// Result of built-in command execution.
pub const BuiltinResult = struct {
    exit_code: u8 = 0,
    output: []const u8 = "", // Output to stdout (if any)
    should_exit: bool = false, // True if shell should exit
};

/// Shell environment (for cd, pwd, etc.).
pub const ShellEnvironment = struct {
    current_directory: [4096]u8,
    current_directory_len: u32,
    allocator: std.mem.Allocator,

    /// Get current directory.
    pub fn get_cwd(self: *ShellEnvironment) []const u8 {
        return self.current_directory[0..self.current_directory_len];
    }

    /// Set current directory.
    pub fn set_cwd(self: *ShellEnvironment, path: []const u8) !void {
        if (path.len >= self.current_directory.len) {
            return BuiltinError.PathTooLong;
        }
        @memset(self.current_directory[0..], 0);
        @memcpy(self.current_directory[0..path.len], path);
        self.current_directory_len = @intCast(path.len);
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
            var stderr_buf: [512]u8 = undefined;
            const stderr_file = stdio.getStdErr();
            const err_msg = std.fmt.bufPrint(&stderr_buf, "cd: {s}: {s}\n", .{ home, @errorName(err) }) catch {
                // Buffer too small, use simpler message
                stderr_file.writeAll("cd: error\n") catch {};
                return BuiltinResult{ .exit_code = 1 };
            };
            stderr_file.writeAll(err_msg) catch {};
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
        var stderr_buf: [512]u8 = undefined;
        const stderr_file = stdio.getStdErr();
        const err_msg = std.fmt.bufPrint(&stderr_buf, "cd: {s}: {s}\n", .{ target_dir, @errorName(err) }) catch {
            stderr_file.writeAll("cd: error\n") catch {};
            return BuiltinResult{ .exit_code = 1 };
        };
        stderr_file.writeAll(err_msg) catch {};
        return BuiltinResult{ .exit_code = 1 };
    };

    // Update environment with actual current directory
    var cwd_buf: [4096]u8 = undefined;
    const actual_cwd = std.posix.getcwd(&cwd_buf) catch {
        // If getcwd fails, use the path we tried to change to
        try env.set_cwd(path_buf);
        return BuiltinResult{ .exit_code = 0 };
    };
    try env.set_cwd(actual_cwd);
    return BuiltinResult{ .exit_code = 0 };
}

/// Built-in command: pwd (print working directory)
pub fn builtin_pwd(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult {
    _ = args;

    const cwd = env.get_cwd();
    const output = try std.fmt.allocPrint(allocator, "{s}\n", .{cwd});
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
    var output_list = try std.ArrayList(u8).initCapacity(allocator, 4096);
    defer output_list.deinit(allocator);

    for (args, 0..) |arg, i| {
        if (i > 0) {
            try output_list.append(allocator, ' ');
        }
        const arg_str = try std.fmt.allocPrint(allocator, "{s}", .{arg});
        defer allocator.free(arg_str);
        try output_list.appendSlice(allocator, arg_str);
    }
    try output_list.append(allocator, '\n');

    const output = try output_list.toOwnedSlice(allocator);
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
        var stderr_buf: [512]u8 = undefined;
        const stderr_file = stdio.getStdErr();
        const err_msg = std.fmt.bufPrint(&stderr_buf, "ls: {s}: {s}\n", .{ target_dir, @errorName(err) }) catch {
            stderr_file.writeAll("ls: error\n") catch {};
            return BuiltinResult{ .exit_code = 1 };
        };
        stderr_file.writeAll(err_msg) catch {};
        return BuiltinResult{ .exit_code = 1 };
    };
    defer dir.close();

    var output_list = try std.ArrayList(u8).initCapacity(allocator, 4096);
    defer output_list.deinit(allocator);

    var iter = dir.iterate();
    while (iter.next() catch |err| {
        var stderr_buf: [512]u8 = undefined;
        const stderr_file = stdio.getStdErr();
        const err_msg = std.fmt.bufPrint(&stderr_buf, "ls: iterate error: {s}\n", .{@errorName(err) }) catch {
            stderr_file.writeAll("ls: iterate error\n") catch {};
            return BuiltinResult{ .exit_code = 1 };
        };
        stderr_file.writeAll(err_msg) catch {};
        return BuiltinResult{ .exit_code = 1 };
    }) |entry| {
        const entry_line = try std.fmt.allocPrint(allocator, "{s}\n", .{entry.name});
        defer allocator.free(entry_line);
        try output_list.appendSlice(allocator, entry_line);
    }

    const output = try output_list.toOwnedSlice(allocator);
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
    _ = allocator;
    _ = env;

    const exit_code: u8 = if (args.len > 0) blk: {
        const code_str = args[0];
        const code = std.fmt.parseInt(u8, code_str, 10) catch |err| {
            var stderr_buf: [512]u8 = undefined;
            const stderr_file = stdio.getStdErr();
            const err_msg = std.fmt.bufPrint(&stderr_buf, "exit: invalid exit code '{s}': {s}\n", .{ code_str, @errorName(err) }) catch {
                stderr_file.writeAll("exit: invalid code\n") catch {};
                return BuiltinResult{ .exit_code = 1 };
            };
            stderr_file.writeAll(err_msg) catch {};
            return BuiltinResult{ .exit_code = 1 };
        };
        break :blk code;
    } else 0;
    return BuiltinResult{
        .exit_code = exit_code,
        .should_exit = true,
    };
}

/// Built-in command: env (show environment variables)
pub fn builtin_env(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult {
    _ = args;
    _ = env;

    var output_list = try std.ArrayList(u8).initCapacity(allocator, 4096);
    defer output_list.deinit(allocator);

    // Get common environment variables
    const env_vars = [_][]const u8{ "HOME", "PATH", "USER", "SHELL", "PWD" };
    for (env_vars) |var_name| {
        if (std.posix.getenv(var_name)) |value| {
            const line = try std.fmt.allocPrint(allocator, "{s}={s}\n", .{ var_name, value });
            defer allocator.free(line);
            try output_list.appendSlice(allocator, line);
        }
    }

    const output = try output_list.toOwnedSlice(allocator);
    return BuiltinResult{
        .exit_code = 0,
        .output = output,
    };
}

/// Built-in command: help (show available commands)
pub fn builtin_help(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
) BuiltinError!BuiltinResult {
    _ = args;
    _ = env;

    const help_text =
        \\Grainscript Shell v0.1.0
        \\
        \\Built-in commands:
        \\  cd [dir]     Change directory
        \\  pwd          Print working directory
        \\  ls [dir]     List directory contents
        \\  echo [args]  Print arguments
        \\  env          Show environment variables
        \\  service      Manage Init System services
        \\  exit [code]  Exit shell
        \\  help         Show this help message
        \\
        \\External programs can also be executed.
        \\
    ;

    const output = try allocator.dupe(u8, help_text);
    return BuiltinResult{
        .exit_code = 0,
        .output = output,
    };
}

/// Built-in command: service (manage Init System services)
pub fn builtin_service(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    env: *ShellEnvironment,
    service_mgr: *service_manager.ServiceManager,
) BuiltinError!BuiltinResult {
    _ = env;

    if (args.len == 0) {
        const err_msg = "service: missing subcommand\n";
        const output = try allocator.dupe(u8, err_msg);
        return BuiltinResult{
            .exit_code = 1,
            .output = output,
        };
    }

    const subcommand = args[0];
    const sub_args = args[1..];

    if (std.mem.eql(u8, subcommand, "status")) {
        return handle_service_status(allocator, sub_args, service_mgr);
    } else if (std.mem.eql(u8, subcommand, "start")) {
        return handle_service_start(allocator, sub_args, service_mgr);
    } else if (std.mem.eql(u8, subcommand, "stop")) {
        return handle_service_stop(allocator, sub_args, service_mgr);
    } else if (std.mem.eql(u8, subcommand, "restart")) {
        return handle_service_restart(allocator, sub_args, service_mgr);
    } else if (std.mem.eql(u8, subcommand, "list")) {
        return handle_service_list(allocator, service_mgr);
    } else {
        var err_buf: [256]u8 = undefined;
        const err_msg = std.fmt.bufPrint(&err_buf, "service: unknown subcommand '{s}'\n", .{subcommand}) catch {
            const output = try allocator.dupe(u8, "service: unknown subcommand\n");
            return BuiltinResult{ .exit_code = 1, .output = output };
        };
        const output = try allocator.dupe(u8, err_msg);
        return BuiltinResult{
            .exit_code = 1,
            .output = output,
        };
    }
}

/// Handle service status subcommand.
fn handle_service_status(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    service_mgr: *service_manager.ServiceManager,
) BuiltinError!BuiltinResult {
    var output_list = try std.ArrayList(u8).initCapacity(allocator, 4096);
    defer output_list.deinit(allocator);

    if (args.len == 0) {
        // List all services
        const services = service_mgr.list_services() catch |err| {
            var err_buf: [256]u8 = undefined;
            const err_msg = std.fmt.bufPrint(&err_buf, "service: {s}\n", .{@errorName(err)}) catch {
                const output = try allocator.dupe(u8, "service: error listing services\n");
                return BuiltinResult{ .exit_code = 1, .output = output };
            };
            const output = try allocator.dupe(u8, err_msg);
            return BuiltinResult{ .exit_code = 1, .output = output };
        };
        defer allocator.free(services);

        for (services) |info| {
            var status_buf: [512]u8 = undefined;
            const status_line = service_mgr.format_service_status(info.name, &status_buf) catch {
                continue;
            };
            try output_list.appendSlice(allocator, status_line);
        }
    } else {
        // Show specific service status
        const service_name = args[0];
        var status_buf: [512]u8 = undefined;
        const status_line = service_mgr.format_service_status(service_name, &status_buf) catch |err| {
            var err_buf: [256]u8 = undefined;
            const err_msg = std.fmt.bufPrint(&err_buf, "service: {s}\n", .{@errorName(err)}) catch {
                const output = try allocator.dupe(u8, "service: error\n");
                return BuiltinResult{ .exit_code = 1, .output = output };
            };
            const output = try allocator.dupe(u8, err_msg);
            return BuiltinResult{ .exit_code = 1, .output = output };
        };
        try output_list.appendSlice(allocator, status_line);
    }

    const output = try output_list.toOwnedSlice(allocator);
    return BuiltinResult{
        .exit_code = 0,
        .output = output,
    };
}

/// Handle service start subcommand.
fn handle_service_start(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    service_mgr: *service_manager.ServiceManager,
) BuiltinError!BuiltinResult {
    if (args.len == 0) {
        const err_msg = "service: missing service name\n";
        const output = try allocator.dupe(u8, err_msg);
        return BuiltinResult{ .exit_code = 1, .output = output };
    }

    const service_name = args[0];
    service_mgr.start_service(service_name) catch |err| {
        var err_buf: [256]u8 = undefined;
        const err_msg = std.fmt.bufPrint(&err_buf, "service: {s}\n", .{@errorName(err)}) catch {
            const output = try allocator.dupe(u8, "service: error starting service\n");
            return BuiltinResult{ .exit_code = 1, .output = output };
        };
        const output = try allocator.dupe(u8, err_msg);
        return BuiltinResult{ .exit_code = 1, .output = output };
    };

    return BuiltinResult{ .exit_code = 0, .output = "" };
}

/// Handle service stop subcommand.
fn handle_service_stop(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    service_mgr: *service_manager.ServiceManager,
) BuiltinError!BuiltinResult {
    if (args.len == 0) {
        const err_msg = "service: missing service name\n";
        const output = try allocator.dupe(u8, err_msg);
        return BuiltinResult{ .exit_code = 1, .output = output };
    }

    const service_name = args[0];
    service_mgr.stop_service(service_name) catch |err| {
        var err_buf: [256]u8 = undefined;
        const err_msg = std.fmt.bufPrint(&err_buf, "service: {s}\n", .{@errorName(err)}) catch {
            const output = try allocator.dupe(u8, "service: error stopping service\n");
            return BuiltinResult{ .exit_code = 1, .output = output };
        };
        const output = try allocator.dupe(u8, err_msg);
        return BuiltinResult{ .exit_code = 1, .output = output };
    };

    return BuiltinResult{ .exit_code = 0, .output = "" };
}

/// Handle service restart subcommand.
fn handle_service_restart(
    allocator: std.mem.Allocator,
    args: [][]const u8,
    service_mgr: *service_manager.ServiceManager,
) BuiltinError!BuiltinResult {
    if (args.len == 0) {
        const err_msg = "service: missing service name\n";
        const output = try allocator.dupe(u8, err_msg);
        return BuiltinResult{ .exit_code = 1, .output = output };
    }

    const service_name = args[0];
    service_mgr.restart_service(service_name) catch |err| {
        var err_buf: [256]u8 = undefined;
        const err_msg = std.fmt.bufPrint(&err_buf, "service: {s}\n", .{@errorName(err)}) catch {
            const output = try allocator.dupe(u8, "service: error restarting service\n");
            return BuiltinResult{ .exit_code = 1, .output = output };
        };
        const output = try allocator.dupe(u8, err_msg);
        return BuiltinResult{ .exit_code = 1, .output = output };
    };

    return BuiltinResult{ .exit_code = 0, .output = "" };
}

/// Handle service list subcommand.
fn handle_service_list(
    allocator: std.mem.Allocator,
    service_mgr: *service_manager.ServiceManager,
) BuiltinError!BuiltinResult {
    const services = service_mgr.list_services() catch |err| {
        var err_buf: [256]u8 = undefined;
        const err_msg = std.fmt.bufPrint(&err_buf, "service: {s}\n", .{@errorName(err)}) catch {
            const output = try allocator.dupe(u8, "service: error listing services\n");
            return BuiltinResult{ .exit_code = 1, .output = output };
        };
        const output = try allocator.dupe(u8, err_msg);
        return BuiltinResult{ .exit_code = 1, .output = output };
    };
    defer allocator.free(services);

    var output_list = try std.ArrayList(u8).initCapacity(allocator, 4096);
    defer output_list.deinit(allocator);

    // Header
    try output_list.appendSlice(allocator, "SERVICE_NAME    STATE      PID\n");

    for (services) |info| {
        const state_str = switch (info.state) {
            .stopped => "stopped",
            .starting => "starting",
            .running => "running",
            .stopping => "stopping",
            .failed => "failed",
            .restarting => "restarting",
        };

        const name_slice = info.name;
        if (info.pid) |pid| {
            const line = try std.fmt.allocPrint(allocator, "{s:<15} {s:<10} {d}\n", .{ name_slice, state_str, pid });
            defer allocator.free(line);
            try output_list.appendSlice(allocator, line);
        } else {
            const line = try std.fmt.allocPrint(allocator, "{s:<15} {s:<10} -\n", .{ name_slice, state_str });
            defer allocator.free(line);
            try output_list.appendSlice(allocator, line);
        }
    }

    const output = try output_list.toOwnedSlice(allocator);
    return BuiltinResult{
        .exit_code = 0,
        .output = output,
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
    } else if (std.mem.eql(u8, name, "env")) {
        return builtin_env;
    } else if (std.mem.eql(u8, name, "help")) {
        return builtin_help;
    }
    // Note: "service" command is handled separately in executor (needs ServiceManager)
    return null;
}

pub const BuiltinError = error{
    PathTooLong,
    OutOfMemory,
    InvalidArgument,
    NoSpaceLeft, // For bufPrint buffer overflow
};

