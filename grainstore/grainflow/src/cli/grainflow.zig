//! Grainflow CLI: Command-line interface for media processing.
//! Why: Interactive CLI and REPL for media operations.
//! Architecture: CLI entry point, command parsing, REPL integration.
//!
//! GrainStyle compliance:
//! - grain_case function names
//! - u32/u64 types (not usize/isize)
//! - MAX_ constants for bounded allocations
//! - Assertions for preconditions/postconditions
//! - No recursion (iterative algorithms, stack-based)

const std = @import("std");
const grainflow_media = @import("grainflow_media");
const grainflow_dag = @import("grainflow_dag");
const grainflow_grainscript = @import("grainflow_grainscript");

/// Main CLI entry point.
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Initialize engine
    var engine = grainflow_media.GrainflowEngine.init(allocator);

    // Parse command-line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        // No arguments: start REPL mode
        try start_repl(allocator, &engine);
        return;
    }

    // Parse command
    const command = args[1];

    if (std.mem.eql(u8, command, "repl")) {
        try start_repl(allocator, &engine);
    } else if (std.mem.eql(u8, command, "help")) {
        print_help();
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        std.debug.print("Use 'grainflow help' for usage information.\n", .{});
        return;
    }
}

/// Start interactive REPL.
fn start_repl(
    allocator: std.mem.Allocator,
    engine: *grainflow_media.GrainflowEngine,
) !void {
    // Assert: Engine must be valid
    std.debug.assert(engine.allocator.ptr != null);
    _ = allocator; // Will be used for REPL state management

    const stdout = std.io.getStdOut().writer();
    const stdin = std.io.getStdIn().reader();

    try stdout.print("Grainflow REPL v0.1.0\n", .{});
    try stdout.print("Type 'help' for commands, 'exit' to quit.\n", .{});

    var line_buf: [8192]u8 = undefined;

    while (true) {
        try stdout.print("grainflow> ", .{});

        const line = try stdin.readUntilDelimiterOrEof(
            &line_buf,
            '\n',
        ) orelse break;

        if (std.mem.eql(u8, line, "exit")) {
            break;
        } else if (std.mem.eql(u8, line, "help")) {
            print_repl_help();
        } else {
            try stdout.print("Command not implemented: {s}\n", .{line});
        }
    }
}

/// Print help information.
fn print_help() void {
    const stdout = std.io.getStdOut().writer();
    stdout.print(
        \\Grainflow: Full-Stack Media Framework
        \\
        \\Usage:
        \\  grainflow [command] [options]
        \\
        \\Commands:
        \\  repl    Start interactive REPL
        \\  help    Show this help message
        \\
        \\Examples:
        \\  grainflow repl
        \\  grainflow help
        \\
    , .{}) catch {};
}

/// Print REPL help information.
fn print_repl_help() void {
    const stdout = std.io.getStdOut().writer();
    stdout.print(
        \\REPL Commands:
        \\  help    Show this help
        \\  exit    Exit REPL
        \\
        \\Media Operations (coming soon):
        \\  load <path>     Load image from file
        \\  crop <x> <y> <w> <h>  Crop image
        \\  filter <preset> Apply filter preset
        \\  save <path>     Save image to file
        \\
    , .{}) catch {};
}

