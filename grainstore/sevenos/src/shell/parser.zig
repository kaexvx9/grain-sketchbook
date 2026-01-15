//! Grainscript Shell Command Parser
//! Why: Parse shell command lines into executable command structures.
//! Grain Style: Explicit types, bounded allocations, no recursion.

const std = @import("std");

/// Shell command parser for Grainscript Shell.
/// Parses command lines like: "ls -la /tmp" or "echo hello | grep h"
pub const CommandParser = struct {
    // Bounded: Max 256 arguments per command (explicit limit)
    pub const MAX_ARGS: u32 = 256;

    // Bounded: Max 4096 characters per argument (explicit limit)
    pub const MAX_ARG_LEN: u32 = 4_096;

    // Bounded: Max 64 commands in a pipeline (explicit limit)
    pub const MAX_PIPELINE: u32 = 64;

    /// Parsed command structure.
    pub const Command = struct {
        command: []const u8, // Command name (e.g., "ls", "cd", "echo")
        args: [][]const u8, // Arguments (may be empty)
        args_len: u32, // Number of arguments
        input_file: ?[]const u8 = null, // Input redirection (< file)
        output_file: ?[]const u8 = null, // Output redirection (> file)
        append_output: bool = false, // Append mode (>> file)
        background: bool = false, // Run in background (&)
    };

    /// Parsed pipeline (chain of commands with pipes).
    pub const Pipeline = struct {
        commands: []Command, // Commands in pipeline
        commands_len: u32, // Number of commands
    };

    allocator: std.mem.Allocator,

    /// Initialize parser with allocator.
    pub fn init(allocator: std.mem.Allocator) CommandParser {
        return CommandParser{
            .allocator = allocator,
        };
    }

    /// Parse a command line into a pipeline.
    /// Returns null if parsing fails or line is empty.
    pub fn parse(self: *CommandParser, line: []const u8) !?Pipeline {
        // Trim whitespace
        const trimmed = std.mem.trim(u8, line, " \t\r\n");
        if (trimmed.len == 0) {
            return null;
        }

        // Check for comment (lines starting with #)
        if (trimmed.len > 0 and trimmed[0] == '#') {
            return null;
        }

        // Split by pipe first
        var pipeline_commands = try std.ArrayList(Command).initCapacity(self.allocator, MAX_PIPELINE);
        defer pipeline_commands.deinit(self.allocator);

        var pipe_iter = std.mem.splitScalar(u8, trimmed, '|');
        var pipe_count: u32 = 0;

        while (pipe_iter.next()) |pipe_segment| : (pipe_count += 1) {
            if (pipe_count >= MAX_PIPELINE) {
                return error.TooManyPipes;
            }

            const cmd = try self.parse_command(pipe_segment);
            try pipeline_commands.append(self.allocator, cmd);
        }

        // Copy commands to allocated array
        const commands = try self.allocator.alloc(Command, pipeline_commands.items.len);
        for (pipeline_commands.items, 0..) |cmd, i| {
            commands[i] = cmd;
        }

        return Pipeline{
            .commands = commands,
            .commands_len = @intCast(pipeline_commands.items.len),
        };
    }

    /// Parse a single command (without pipes).
    fn parse_command(self: *CommandParser, segment: []const u8) !Command {
        var trimmed = std.mem.trim(u8, segment, " \t");
        const background = check_background(&trimmed);

        var args = try std.ArrayList([]const u8).initCapacity(self.allocator, MAX_ARGS);
        defer args.deinit(self.allocator);

        var parse_state = ParseState{
            .allocator = self.allocator,
            .args = args,
            .input_file = null,
            .output_file = null,
            .append_output = false,
            .command = null,
        };

        try parse_tokens(trimmed, &parse_state);

        if (parse_state.command == null) {
            return error.EmptyCommand;
        }

        const args_array = try copy_args_array(self.allocator, &parse_state.args);

        return Command{
            .command = parse_state.command.?,
            .args = args_array,
            .args_len = @intCast(parse_state.args.items.len),
            .input_file = parse_state.input_file,
            .output_file = parse_state.output_file,
            .append_output = parse_state.append_output,
            .background = background,
        };
    }

    /// Parse state for command parsing.
    const ParseState = struct {
        allocator: std.mem.Allocator,
        args: std.ArrayList([]const u8),
        input_file: ?[]const u8,
        output_file: ?[]const u8,
        append_output: bool,
        command: ?[]const u8,
    };

    /// Check for background operator and trim if present.
    fn check_background(trimmed: *[]const u8) bool {
        if (trimmed.len > 0 and trimmed.*[trimmed.len - 1] == '&') {
            trimmed.* = std.mem.trim(u8, trimmed.*[0..trimmed.len - 1], " \t");
            return true;
        }
        return false;
    }

    /// Parse tokens from trimmed command line.
    fn parse_tokens(trimmed: []const u8, state: *ParseState) !void {

        var token_iter = std.mem.splitScalar(u8, trimmed, ' ');
        var first = true;

        while (token_iter.next()) |token| {
            const trimmed_token = std.mem.trim(u8, token, " \t");
            if (trimmed_token.len == 0) continue;

            if (try handle_redirection(trimmed_token, &token_iter, state)) {
                continue;
            }

            if (first) {
                state.command = trimmed_token;
                first = false;
            } else {
                const arg = process_quoted_arg(trimmed_token);
                if (arg.len > MAX_ARG_LEN) {
                    return error.ArgumentTooLong;
                }
                try state.args.append(state.allocator, arg);
            }
        }
    }

    /// Handle redirection tokens.
    fn handle_redirection(
        token: []const u8,
        token_iter: *std.mem.SplitIterator(u8, .scalar),
        state: *ParseState,
    ) !bool {
        if (std.mem.eql(u8, token, "<")) {
            const next = token_iter.next();
            if (next == null) return error.InvalidRedirect;
            state.input_file = std.mem.trim(u8, next.?, " \t");
            return true;
        } else if (std.mem.eql(u8, token, ">")) {
            const next = token_iter.next();
            if (next == null) return error.InvalidRedirect;
            state.output_file = std.mem.trim(u8, next.?, " \t");
            state.append_output = false;
            return true;
        } else if (std.mem.eql(u8, token, ">>")) {
            const next = token_iter.next();
            if (next == null) return error.InvalidRedirect;
            state.output_file = std.mem.trim(u8, next.?, " \t");
            state.append_output = true;
            return true;
        }
        return false;
    }

    /// Process quoted argument (remove quotes if present).
    fn process_quoted_arg(arg: []const u8) []const u8 {
        if (arg.len >= 2) {
            if ((arg[0] == '"' and arg[arg.len - 1] == '"') or
                (arg[0] == '\'' and arg[arg.len - 1] == '\'')) {
                return arg[1..arg.len - 1];
            }
        }
        return arg;
    }

    /// Copy arguments array.
    fn copy_args_array(allocator: std.mem.Allocator, args: *std.ArrayList([]const u8)) ![][]const u8 {
        const args_array = try allocator.alloc([]const u8, args.items.len);
        for (args.items, 0..) |arg, i| {
            args_array[i] = arg;
        }
        return args_array;
    }

    /// Free a pipeline and its commands.
    pub fn free_pipeline(self: *CommandParser, pipeline: *const Pipeline) void {
        // Cast away const to free (we own the memory)
        const mutable_pipeline: *Pipeline = @constCast(pipeline);
        for (mutable_pipeline.commands[0..mutable_pipeline.commands_len]) |*cmd| {
            self.free_command(cmd);
        }
        self.allocator.free(mutable_pipeline.commands);
    }

    /// Free a command.
    pub fn free_command(self: *CommandParser, cmd: *Command) void {
        self.allocator.free(cmd.args);
        if (cmd.input_file) |file| {
            self.allocator.free(file);
        }
        if (cmd.output_file) |file| {
            self.allocator.free(file);
        }
    }

    pub const Error = error{
        TooManyPipes,
        InvalidRedirect,
        ArgumentTooLong,
        EmptyCommand,
        OutOfMemory,
    };
};


