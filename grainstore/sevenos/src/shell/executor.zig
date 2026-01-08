//! Grainscript Shell Command Executor
//! Why: Execute shell commands (built-ins and external programs).
//! Grain Style: Explicit error handling, bounded allocations.

const std = @import("std");
const builtins = @import("builtins.zig");
const parser = @import("parser.zig");
const stdio = @import("stdio_wrapper.zig");
const service_manager = @import("service_manager.zig");
const job_manager = @import("job_manager.zig");

/// Command executor for Grainscript Shell.
pub const Executor = struct {
    allocator: std.mem.Allocator,
    env: *builtins.ShellEnvironment,
    service_manager: ?*service_manager.ServiceManager,
    job_manager: ?*job_manager.JobManager,

    /// Initialize executor with allocator and environment.
    pub fn init(
        allocator: std.mem.Allocator,
        env: *builtins.ShellEnvironment,
        service_mgr: ?*service_manager.ServiceManager,
        job_mgr: ?*job_manager.JobManager,
    ) Executor {
        return Executor{
            .allocator = allocator,
            .env = env,
            .service_manager = service_mgr,
            .job_manager = job_mgr,
        };
    }

    /// Execute a parsed command.
    /// Returns exit code (0 = success, non-zero = error).
    pub fn execute_command(self: *Executor, cmd: parser.CommandParser.Command) !u8 {
        // Check if it's a service command (needs ServiceManager)
        if (std.mem.eql(u8, cmd.command, "service")) {
            if (self.service_manager) |sm| {
                return try self.execute_service_command(cmd, sm);
            } else {
                const stderr_file = stdio.getStdErr();
                try stderr_file.writeAll("service: Init System not available\n");
                return 1;
            }
        }

        // Check if it's a job management command (needs JobManager)
        if (std.mem.eql(u8, cmd.command, "jobs") or
            std.mem.eql(u8, cmd.command, "fg") or
            std.mem.eql(u8, cmd.command, "bg"))
        {
            if (self.job_manager) |jm| {
                return try self.execute_job_command(cmd, jm);
            } else {
                const stderr_file = stdio.getStdErr();
                try stderr_file.writeAll("jobs: Job manager not available\n");
                return 1;
            }
        }

        // Check if it's a built-in command
        if (builtins.get_builtin(cmd.command)) |handler| {
            return try self.execute_builtin(handler, cmd);
        }

        // Execute as external program
        return try self.execute_external(cmd);
    }

    /// Execute a built-in command.
    fn execute_builtin(
        self: *Executor,
        handler: builtins.BuiltinHandler,
        cmd: parser.CommandParser.Command,
    ) !u8 {
        const result = handler(self.allocator, cmd.args[0..cmd.args_len], self.env) catch |err| {
            const stderr_file = stdio.getStdErr();
            var err_buf: [512]u8 = undefined;
            const err_msg = std.fmt.bufPrint(&err_buf, "Error executing '{s}': {s}\n", .{ cmd.command, @errorName(err) }) catch {
                // If buffer too small, use simpler message
                try stderr_file.writeAll("Error executing command\n");
                return 1;
            };
            stderr_file.writeAll(err_msg) catch {};
            return 1;
        };

        // Write output if any
        if (result.output.len > 0) {
            const stdout_file = stdio.getStdOut();
            try stdout_file.writeAll(result.output);
            self.allocator.free(result.output);
        }

        // Note: should_exit is handled by the caller (grainscript.zig)
        return result.exit_code;
    }

    /// Execute service command (requires ServiceManager).
    fn execute_service_command(
        self: *Executor,
        cmd: parser.CommandParser.Command,
        service_mgr: *service_manager.ServiceManager,
    ) !u8 {
        const args = cmd.args[0..cmd.args_len];
        const result = builtins.builtin_service(
            self.allocator,
            args,
            self.env,
            service_mgr,
        ) catch |err| {
            const stderr_file = stdio.getStdErr();
            var err_buf: [512]u8 = undefined;
            const err_msg = std.fmt.bufPrint(&err_buf, "service: {s}\n", .{@errorName(err)}) catch {
                try stderr_file.writeAll("service: error\n");
                return 1;
            };
            stderr_file.writeAll(err_msg) catch {};
            return 1;
        };

        // Write output if any
        if (result.output.len > 0) {
            const stdout_file = stdio.getStdOut();
            try stdout_file.writeAll(result.output);
            self.allocator.free(result.output);
        }

        return result.exit_code;
    }

    /// Execute job management command (requires JobManager).
    fn execute_job_command(
        _self: *Executor,
        cmd: parser.CommandParser.Command,
        job_mgr: *job_manager.JobManager,
    ) !u8 {
        _ = _self; // Unused for now
        // Update all job statuses before processing
        try job_mgr.update_all_jobs();

        if (std.mem.eql(u8, cmd.command, "jobs")) {
            // List all jobs
            const jobs = job_mgr.get_all_jobs();
            const stdout_file = stdio.getStdOut();

            if (jobs.len == 0) {
                return 0; // No jobs
            }

            for (jobs) |*job| {
                const status_str = switch (job.status) {
                    .running => "Running",
                    .stopped => "Stopped",
                    .done => "Done",
                };

                var job_buf: [256]u8 = undefined;
                const job_line = if (job.exit_code) |code| blk: {
                    break :blk try std.fmt.bufPrint(&job_buf, "[{d}] {d} {s} (exit {d})\n", .{ job.job_id, job.pid, status_str, code });
                } else blk: {
                    break :blk try std.fmt.bufPrint(&job_buf, "[{d}] {d} {s} {s}\n", .{ job.job_id, job.pid, status_str, job.command });
                };
                try stdout_file.writeAll(job_line);
            }

            // Remove done jobs
            job_mgr.remove_done_jobs();

            return 0;
        } else if (std.mem.eql(u8, cmd.command, "fg")) {
            // Bring job to foreground
            const args = cmd.args[0..cmd.args_len];
            if (args.len == 0) {
                const stderr_file = stdio.getStdErr();
                try stderr_file.writeAll("fg: missing job number\n");
                return 1;
            }

            const job_id_str = args[0];
            const job_id = std.fmt.parseInt(u32, job_id_str, 10) catch {
                const stderr_file = stdio.getStdErr();
                try stderr_file.writeAll("fg: invalid job number\n");
                return 1;
            };

            const job = job_mgr.get_job(job_id) orelse {
                const stderr_file = stdio.getStdErr();
                var err_buf: [64]u8 = undefined;
                const err_msg = try std.fmt.bufPrint(&err_buf, "fg: job {d} not found\n", .{job_id});
                try stderr_file.writeAll(err_msg);
                return 1;
            };

            if (job.is_done()) {
                const stderr_file = stdio.getStdErr();
                var err_buf: [64]u8 = undefined;
                const err_msg = try std.fmt.bufPrint(&err_buf, "fg: job {d} is done\n", .{job_id});
                try stderr_file.writeAll(err_msg);
                return 1;
            }

            // Wait for job to complete (polling)
            while (true) {
                try job.update_status();
                if (job.is_done()) {
                    break;
                }
                // Small delay to avoid busy-waiting
                std.posix.nanosleep(0, 100_000_000); // 100ms
            }

            // Remove done job
            _ = job_mgr.remove_job(job_id);

            return job.exit_code orelse 0;
        } else if (std.mem.eql(u8, cmd.command, "bg")) {
            // Resume stopped job in background
            const args = cmd.args[0..cmd.args_len];
            if (args.len == 0) {
                const stderr_file = stdio.getStdErr();
                try stderr_file.writeAll("bg: missing job number\n");
                return 1;
            }

            const job_id_str = args[0];
            const job_id = std.fmt.parseInt(u32, job_id_str, 10) catch {
                const stderr_file = stdio.getStdErr();
                try stderr_file.writeAll("bg: invalid job number\n");
                return 1;
            };

            const job = job_mgr.get_job(job_id) orelse {
                const stderr_file = stdio.getStdErr();
                var err_buf: [64]u8 = undefined;
                const err_msg = try std.fmt.bufPrint(&err_buf, "bg: job {d} not found\n", .{job_id});
                try stderr_file.writeAll(err_msg);
                return 1;
            };

            if (!job.is_stopped()) {
                const stderr_file = stdio.getStdErr();
                var err_buf: [64]u8 = undefined;
                const err_msg = try std.fmt.bufPrint(&err_buf, "bg: job {d} is not stopped\n", .{job_id});
                try stderr_file.writeAll(err_msg);
                return 1;
            }

            // Resume job (send SIGCONT)
            std.posix.kill(job.pid, std.posix.SIG.CONT) catch |err| {
                const stderr_file = stdio.getStdErr();
                var err_buf: [128]u8 = undefined;
                const err_msg = try std.fmt.bufPrint(&err_buf, "bg: failed to resume job {d}: {s}\n", .{ job_id, @errorName(err) });
                try stderr_file.writeAll(err_msg);
                return 1;
            };

            job.status = .running;

            return 0;
        }

        return 1; // Unknown job command
    }

    /// Execute an external program.
    fn execute_external(self: *Executor, cmd: parser.CommandParser.Command) !u8 {
        // Prepare arguments
        var args_list = try std.ArrayList([]const u8).initCapacity(self.allocator, parser.CommandParser.MAX_ARGS);
        defer args_list.deinit(self.allocator);

        try args_list.append(self.allocator, cmd.command);
        for (cmd.args[0..cmd.args_len]) |arg| {
            try args_list.append(self.allocator, arg);
        }

        // Setup process
        var process = std.process.Child.init(args_list.items, self.allocator);

        // Handle input redirection (< file)
        // For file input, we'll use Pipe and copy file contents
        var input_file_handle: ?std.fs.File = null;
        if (cmd.input_file) |input_file| {
            input_file_handle = try std.fs.cwd().openFile(input_file, .{});
            process.stdin_behavior = .Pipe;
        } else {
            process.stdin_behavior = .Inherit;
        }
        defer if (input_file_handle) |file| file.close();

        // Handle output redirection (> file or >> file)
        // For file output, we'll use Pipe and copy to file
        var output_file_handle: ?std.fs.File = null;
        if (cmd.output_file) |output_file| {
            if (cmd.append_output) {
                // Append mode: open existing file or create new, then seek to end
                output_file_handle = blk: {
                    const file = std.fs.cwd().openFile(output_file, .{}) catch |err| {
                        if (err == error.FileNotFound) {
                            break :blk try std.fs.cwd().createFile(output_file, .{});
                        } else {
                            return err;
                        }
                    };
                    break :blk file;
                };
                try output_file_handle.?.seekTo(0);
                try output_file_handle.?.seekFromEnd(0); // Seek to end for append
            } else {
                // Write mode: create/truncate file
                output_file_handle = try std.fs.cwd().createFile(output_file, .{});
            }
            process.stdout_behavior = .Pipe;
            process.stderr_behavior = .Inherit; // stderr still goes to terminal
        } else {
            process.stdout_behavior = .Inherit;
            process.stderr_behavior = .Inherit;
        }
        defer if (output_file_handle) |file| file.close();

        // Spawn process
        try process.spawn();

        // Handle input file redirection (copy file to stdin)
        if (input_file_handle) |input_file| {
            if (process.stdin) |stdin_pipe| {
                var buf: [4096]u8 = undefined;
                while (true) {
                    const bytes_read = try input_file.read(&buf);
                    if (bytes_read == 0) break;
                    _ = try stdin_pipe.write(buf[0..bytes_read]);
                }
                stdin_pipe.close();
            }
        }

        // Handle output file redirection (copy stdout to file)
        if (output_file_handle) |output_file| {
            if (process.stdout) |stdout_pipe| {
                var buf: [4096]u8 = undefined;
                while (true) {
                    const bytes_read = try stdout_pipe.read(&buf);
                    if (bytes_read == 0) break;
                    _ = try output_file.write(buf[0..bytes_read]);
                }
                stdout_pipe.close();
            }
        }

        // Spawn process
        try process.spawn();

        // Wait for process (non-blocking for background processes)
        if (cmd.background) {
            // Track background process in JobManager
            if (self.job_manager) |jm| {
                // Build command string for tracking
                var cmd_buf: [512]u8 = undefined;
                var cmd_str: []u8 = cmd_buf[0..];
                var cmd_len: u32 = 0;

                // Copy command
                if (cmd.command.len < cmd_buf.len) {
                    @memcpy(cmd_str[0..cmd.command.len], cmd.command);
                    cmd_len = @intCast(cmd.command.len);
                }

                // Add arguments if space available
                for (cmd.args[0..cmd.args_len]) |arg| {
                    if (cmd_len + 1 + arg.len < cmd_buf.len) {
                        cmd_str[cmd_len] = ' ';
                        cmd_len += 1;
                        @memcpy(cmd_str[cmd_len..cmd_len + arg.len], arg);
                        cmd_len += @intCast(arg.len);
                    } else {
                        break; // Buffer full
                    }
                }

                const command_str = cmd_str[0..cmd_len];
                const job_id = try jm.add_job(process.id, command_str);
                const stdout_file = stdio.getStdOut();
                var job_msg_buf: [64]u8 = undefined;
                const job_msg = try std.fmt.bufPrint(&job_msg_buf, "[{d}] {d}\n", .{ job_id, process.id });
                try stdout_file.writeAll(job_msg);
            }
            // Process continues in background, don't wait
            return 0;
        } else {
            const term = try process.wait();
            return switch (term) {
                .Exited => |code| @intCast(code),
                .Signal => |sig| @intCast(128 + sig),
                .Stopped => |sig| @intCast(128 + sig),
                .Unknown => |code| @intCast(code),
            };
        }
    }

    /// Execute a pipeline of commands.
    pub fn execute_pipeline(self: *Executor, pipeline: parser.CommandParser.Pipeline) !u8 {
        if (pipeline.commands_len == 0) {
            return 0;
        }

        if (pipeline.commands_len == 1) {
            // Single command - no pipes needed
            return try self.execute_command(pipeline.commands[0]);
        }

        // Execute pipeline with pipes
        // For now, execute sequentially and pass data through pipes
        // TODO: Implement proper parallel execution with pipes
        var exit_code: u8 = 0;
        var prev_stdout: ?std.fs.File = null;
        defer if (prev_stdout) |file| file.close();

        for (pipeline.commands[0..pipeline.commands_len], 0..) |cmd, i| {
            // Prepare arguments
            var args_list = try std.ArrayList([]const u8).initCapacity(self.allocator, parser.CommandParser.MAX_ARGS);
            defer args_list.deinit(self.allocator);

            try args_list.append(self.allocator, cmd.command);
            for (cmd.args[0..cmd.args_len]) |arg| {
                try args_list.append(self.allocator, arg);
            }

            // Setup process
            var process = std.process.Child.init(args_list.items, self.allocator);

            // Handle stdin (from previous pipe or file redirection)
            var stdin_needs_setup = false;
            if (cmd.input_file) |_| {
                process.stdin_behavior = .Pipe;
                stdin_needs_setup = true;
            } else if (prev_stdout) |_| {
                process.stdin_behavior = .Pipe;
                stdin_needs_setup = true;
            } else {
                process.stdin_behavior = .Inherit;
            }

            // Handle stdout (to next pipe or file redirection)
            const is_last = (i == pipeline.commands_len - 1);
            var process_waited = false; // Track if we've already waited for this process
            
            // Spawn process first, then handle stdin/stdout
            if (cmd.output_file) |output_file| {
                var output_fd: std.fs.File = undefined;
                if (cmd.append_output) {
                    // Append mode: open existing file or create new, then seek to end
                    output_fd = blk: {
                        const file = std.fs.cwd().openFile(output_file, .{}) catch |err| {
                            if (err == error.FileNotFound) {
                                break :blk try std.fs.cwd().createFile(output_file, .{});
                            } else {
                                return err;
                            }
                        };
                        break :blk file;
                    };
                    try output_fd.seekTo(0);
                    try output_fd.seekFromEnd(0); // Seek to end for append
                } else {
                    // Write mode: create/truncate file
                    output_fd = try std.fs.cwd().createFile(output_file, .{});
                }
                defer output_fd.close();
                process.stdout_behavior = .Pipe;
                // Copy stdout pipe to file
                try process.spawn();
                if (process.stdout) |stdout_pipe| {
                    var buf: [4096]u8 = undefined;
                    while (true) {
                        const bytes_read = try stdout_pipe.read(&buf);
                        if (bytes_read == 0) break;
                        _ = try output_fd.write(buf[0..bytes_read]);
                    }
                    // Don't close stdout_pipe manually - wait() will handle it
                }
                // Wait for process after reading all output
                if (!cmd.background) {
                    const term = try process.wait();
                    exit_code = switch (term) {
                        .Exited => |code| @intCast(code),
                        .Signal => |sig| @intCast(128 + sig),
                        .Stopped => |sig| @intCast(128 + sig),
                        .Unknown => |code| @intCast(code),
                    };
                    process_waited = true;
                } else {
                    exit_code = 0; // Background process, don't wait
                    process_waited = true; // Mark as handled
                }
            } else if (!is_last) {
                // Not last command - capture stdout for next command
                process.stdout_behavior = .Pipe;
                try process.spawn();
                // Capture stdout to temp file for next command
                const temp_file = try std.fs.cwd().createFile("/tmp/grainscript_pipe", .{});
                defer temp_file.close();
                if (process.stdout) |stdout_pipe| {
                    var buf: [4096]u8 = undefined;
                    while (true) {
                        const bytes_read = try stdout_pipe.read(&buf);
                        if (bytes_read == 0) break;
                        _ = try temp_file.write(buf[0..bytes_read]);
                    }
                    // Don't close stdout_pipe manually - wait() will handle it
                }
                // Wait for process after reading all output
                if (!cmd.background) {
                    const term = try process.wait();
                    // Store exit code but only use last command's exit code
                    _ = term; // Discard term for now
                    process_waited = true;
                } else {
                    process_waited = true; // Mark as handled
                }
                if (prev_stdout) |file| file.close();
                prev_stdout = temp_file;
            } else {
                // Last command - stdout to terminal
                process.stdout_behavior = .Inherit;
                try process.spawn();
            }

            process.stderr_behavior = .Inherit;

            // Write to stdin if needed (AFTER spawning)
            if (stdin_needs_setup) {
                if (process.stdin) |stdin_pipe| {
                    if (cmd.input_file) |input_file| {
                        const input_fd = try std.fs.cwd().openFile(input_file, .{});
                        defer input_fd.close();
                        var buf: [4096]u8 = undefined;
                        while (true) {
                            const bytes_read = try input_fd.read(&buf);
                            if (bytes_read == 0) break;
                            _ = try stdin_pipe.write(buf[0..bytes_read]);
                        }
                    } else if (prev_stdout) |prev_file| {
                        try prev_file.seekTo(0); // Reset to beginning
                        var buf: [4096]u8 = undefined;
                        while (true) {
                            const bytes_read = try prev_file.read(&buf);
                            if (bytes_read == 0) break;
                            _ = try stdin_pipe.write(buf[0..bytes_read]);
                        }
                    }
                    // Close stdin pipe write end so process knows input is done
                    stdin_pipe.close();
                }
            }

            // Wait for process if we haven't already (for last command without file redirection)
            if (!process_waited) {
                if (cmd.background) {
                    exit_code = 0; // Background process, don't wait
                } else {
                    const term = try process.wait();
                    exit_code = switch (term) {
                        .Exited => |code| @intCast(code),
                        .Signal => |sig| @intCast(128 + sig),
                        .Stopped => |sig| @intCast(128 + sig),
                        .Unknown => |code| @intCast(code),
                    };
                }
            }
        }

        // Return exit code of last command
        return exit_code;
    }
};

