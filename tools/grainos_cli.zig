//! Grain OS CLI Tool
//! Why: Unified command-line interface for Grain OS development and operations.
//! Usage: grainos [command] [flags]
//! Examples:
//!   grainos qemu run [--verbose] [--networking]
//!   grainos kernel build [--target=riscv64]
//!   grainos test [--verbose]

const std = @import("std");

const usage =
    \\Grain OS CLI — unified command-line interface for Grain OS
    \\
    \\Usage:
    \\  grainos qemu run [--verbose] [--networking] [--no-gui]
    \\  grainos qemu stop
    \\  grainos kernel build [--target=riscv64] [--verbose]
    \\  grainos kernel clean
    \\  grainos test [--verbose] [--filter=pattern]
    \\  grainos scp <file> [--dest=path]
    \\  grainos help
    \\
    \\Commands:
    \\  qemu       - QEMU emulator operations
    \\  kernel     - Kernel build operations
    \\  test       - Run tests
    \\  scp        - Transfer files to QEMU guest
    \\  help       - Show this help message
    \\
    \\Flags:
    \\  --verbose, -v    - Enable verbose debug output
    \\  --networking, -n - Enable networking in QEMU
    \\  --no-gui         - Run QEMU in terminal (no GUI)
    \\  --target=ARCH    - Build target (default: riscv64)
    \\  --filter=PATTERN - Test filter pattern
    \\  --dest=PATH      - Destination path for scp
    \\
;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var args = try std.process.argsWithAllocator(allocator);
    defer args.deinit();

    _ = args.next(); // executable name

    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout: *std.io.Writer = &stdout_writer.interface;

    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr: *std.io.Writer = &stderr_writer.interface;

    const command = args.next() orelse {
        try stdout.writeAll(usage);
        try stdout.flush();
        return;
    };

    if (std.mem.eql(u8, command, "help")) {
        try stdout.writeAll(usage);
        try stdout.flush();
        return;
    }

    if (std.mem.eql(u8, command, "qemu")) {
        try handle_qemu(allocator, &args);
    } else if (std.mem.eql(u8, command, "kernel")) {
        try handle_kernel(allocator, &args);
    } else if (std.mem.eql(u8, command, "test")) {
        try handle_test(allocator, &args);
    } else if (std.mem.eql(u8, command, "scp")) {
        try handle_scp(allocator, &args);
    } else {
        try stderr.print("Unknown command: {s}\n", .{command});
        try stderr.print("Use 'grainos help' for usage.\n", .{});
        try stderr.flush();
        return error.UnknownCommand;
    }
}

fn handle_qemu(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    _ = allocator;
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;

    const subcommand = args.next() orelse {
        try stderr.print("qemu command requires subcommand: run, stop\n", .{});
        try stderr.flush();
        return error.MissingSubcommand;
    };

    if (std.mem.eql(u8, subcommand, "run")) {
        var verbose = false;
        var networking = false;
        var no_gui = true; // Default to terminal mode

        while (args.next()) |flag| {
            if (std.mem.eql(u8, flag, "--verbose") or std.mem.eql(u8, flag, "-v")) {
                verbose = true;
            } else if (std.mem.eql(u8, flag, "--networking") or std.mem.eql(u8, flag, "-n")) {
                networking = true;
            } else if (std.mem.eql(u8, flag, "--no-gui")) {
                no_gui = true;
            } else {
                try stderr.print("Unknown flag: {s}\n", .{flag});
                try stderr.flush();
                return error.UnknownFlag;
            }
        }

        try run_qemu(verbose, networking, no_gui);
    } else if (std.mem.eql(u8, subcommand, "stop")) {
        try stop_qemu();
    } else {
        try stderr.print("Unknown qemu subcommand: {s}\n", .{subcommand});
        try stderr.flush();
        return error.UnknownSubcommand;
    }
}

fn handle_kernel(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    _ = allocator;
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;

    const subcommand = args.next() orelse {
        try stderr.print("kernel command requires subcommand: build, clean\n", .{});
        try stderr.flush();
        return error.MissingSubcommand;
    };

    if (std.mem.eql(u8, subcommand, "build")) {
        var target: []const u8 = "riscv64";
        var verbose = false;

        while (args.next()) |flag| {
            if (std.mem.startsWith(u8, flag, "--target=")) {
                target = flag["--target=".len..];
            } else if (std.mem.eql(u8, flag, "--verbose") or std.mem.eql(u8, flag, "-v")) {
                verbose = true;
            } else {
                var stderr_buffer_local: [4096]u8 = undefined;
                var stderr_writer_local = std.fs.File.stderr().writer(&stderr_buffer_local);
                const stderr_local = &stderr_writer_local.interface;
                try stderr_local.print("Unknown flag: {s}\n", .{flag});
                try stderr_local.flush();
                return error.UnknownFlag;
            }
        }

        try build_kernel(target, verbose);
    } else if (std.mem.eql(u8, subcommand, "clean")) {
        try clean_kernel();
    } else {
        try stderr.print("Unknown kernel subcommand: {s}\n", .{subcommand});
        try stderr.flush();
        return error.UnknownSubcommand;
    }
}

fn handle_test(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    _ = allocator;
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;

    var verbose = false;
    var filter: ?[]const u8 = null;

    while (args.next()) |flag| {
        if (std.mem.eql(u8, flag, "--verbose") or std.mem.eql(u8, flag, "-v")) {
            verbose = true;
        } else if (std.mem.startsWith(u8, flag, "--filter=")) {
            filter = flag["--filter=".len..];
        } else {
            try stderr.print("Unknown flag: {s}\n", .{flag});
            try stderr.flush();
            return error.UnknownFlag;
        }
    }

    try run_tests(verbose, filter);
}

fn handle_scp(allocator: std.mem.Allocator, args: *std.process.ArgIterator) !void {
    var stderr_buffer: [4096]u8 = undefined;
    var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
    const stderr = &stderr_writer.interface;

    const file = args.next() orelse {
        try stderr.print("scp requires file argument\n", .{});
        try stderr.flush();
        return error.MissingArgument;
    };

    var dest: ?[]const u8 = null;

    while (args.next()) |flag| {
        if (std.mem.startsWith(u8, flag, "--dest=")) {
            dest = flag["--dest=".len..];
        } else {
            try stderr.print("Unknown flag: {s}\n", .{flag});
            try stderr.flush();
            return error.UnknownFlag;
        }
    }

    try scp_to_qemu(allocator, file, dest);
}

fn run_qemu(verbose: bool, networking: bool, no_gui: bool) !void {
    _ = no_gui; // Always terminal mode for now

    const script = if (networking) "scripts/run_qemu_with_networking.sh" else "run_qemu.sh";

    if (verbose) {
        var stdout_buffer: [4096]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;
        try stdout.print("Starting QEMU with script: {s}\n", .{script});
        if (networking) {
            try stdout.print("Networking: enabled\n", .{});
        }
        try stdout.flush();
    }

    const script_path = try std.fs.cwd().realpathAlloc(std.heap.page_allocator, script);
    defer std.heap.page_allocator.free(script_path);

    var argv = [_][]const u8{ "bash", script_path };
    try spawn_and_wait(&argv);
}

fn stop_qemu() !void {
    // Find and kill QEMU process
    var argv = [_][]const u8{ "pkill", "-f", "qemu-system-riscv64" };
    _ = spawn_and_wait(&argv) catch {
        // pkill returns non-zero if no process found, which is fine
    };
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;
    try stdout.print("QEMU stopped (if it was running)\n", .{});
    try stdout.flush();
}

fn build_kernel(target: []const u8, verbose: bool) !void {
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout = &stdout_writer.interface;

    if (verbose) {
        try stdout.print("Building kernel for target: {s}\n", .{target});
        try stdout.flush();
    }

    var argv = [_][]const u8{ "zig", "build", "kernel-rv64" };
    try spawn_and_wait(&argv);

    if (verbose) {
        try stdout.print("Kernel build complete!\n", .{});
        try stdout.flush();
    }
}

fn clean_kernel() !void {
    var argv = [_][]const u8{ "zig", "build", "clean" };
    try spawn_and_wait(&argv);
    var stdout_buffer: [4096]u8 = undefined;
    var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
    const stdout: *std.io.Writer = &stdout_writer.interface;
    try stdout.print("Kernel build artifacts cleaned\n", .{});
    try stdout.flush();
}

fn run_tests(verbose: bool, filter: ?[]const u8) !void {
    _ = filter; // TODO: Implement test filtering

    if (verbose) {
        var stdout_buffer: [4096]u8 = undefined;
        var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
        const stdout = &stdout_writer.interface;
        try stdout.print("Running tests...\n", .{});
        try stdout.flush();
    }

    var argv = [_][]const u8{ "zig", "build", "test" };
    try spawn_and_wait(&argv);
}

fn scp_to_qemu(allocator: std.mem.Allocator, file: []const u8, dest: ?[]const u8) !void {
    const script = "scripts/scp_to_qemu.sh";
    const script_path = try std.fs.cwd().realpathAlloc(allocator, script);
    defer allocator.free(script_path);

    var argv = std.ArrayList([]const u8){};
    defer argv.deinit(allocator);

    try argv.append(allocator, "bash");
    try argv.append(allocator, script_path);
    try argv.append(allocator, file);
    if (dest) |d| {
        try argv.append(allocator, d);
    }

    const argv_slice = try argv.toOwnedSlice(allocator);
    defer allocator.free(argv_slice);
    try spawn_and_wait(argv_slice);
}

fn spawn_and_wait(argv: []const []const u8) !void {
    // Use std.process.Child for Zig 0.15.2 compatibility
    var process = std.process.Child.init(argv, std.heap.page_allocator);
    process.stdin_behavior = .Inherit;
    process.stdout_behavior = .Inherit;
    process.stderr_behavior = .Inherit;
    // Note: Child doesn't have deinit in Zig 0.15.2, cleanup happens automatically

    try process.spawn();
    const term = try process.wait();
    switch (term) {
        .Exited => |code| {
            if (code != 0) {
                return error.CommandFailed;
            }
        },
        else => {
            return error.CommandFailed;
        },
    }
}

const Error = error{
    UnknownCommand,
    UnknownSubcommand,
    UnknownFlag,
    MissingSubcommand,
    MissingArgument,
    CommandFailed,
};
