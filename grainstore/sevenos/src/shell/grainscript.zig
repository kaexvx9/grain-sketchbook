//! Grainscript Shell - Main Shell Implementation
//! Why: First shell for Grain OS sevenos, implementing basic shell functionality.
//! Grain Style: Explicit error handling, bounded allocations, minimal dependencies.

const std = @import("std");
const parser = @import("parser.zig");
const executor = @import("executor.zig");
const builtins = @import("builtins.zig");
const stdio = @import("stdio_wrapper.zig");
const grainscript = @import("grainscript");

/// Grainscript Shell main entry point.
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Check for script file argument
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len > 1) {
        // Execute script file
        return execute_script_file(allocator, args[1]);
    }

    // Initialize shell environment
    var cwd_buf: [4096]u8 = undefined;
    const initial_cwd = try std.posix.getcwd(&cwd_buf);
    var env = try init_environment(allocator, initial_cwd);
    defer deinit_environment(allocator, &env);

    // Initialize parser and executor
    var cmd_parser = parser.CommandParser.init(allocator);
    // ServiceManager is optional (requires Supervisor reference from Init System)
    // For now, pass null - will be set when Init System integration is complete
    // JobManager is always available (independent of Init System)
    var job_mgr = @import("job_manager.zig").JobManager.init(allocator);
    defer job_mgr.deinit();
    var exec = executor.Executor.init(allocator, &env, null, &job_mgr);

    // Print welcome message (if interactive)
    const stdout_file = stdio.getStdOut();
    const stdin = stdio.getStdIn();
    const is_tty = stdin.isTty();
    
    if (is_tty) {
        const welcome_msg = "Grainscript Shell v0.1.0 (Grain OS sevenos)\n";
        const exit_msg = "Type 'exit' to exit.\n";
        try stdout_file.writeAll(welcome_msg);
        try stdout_file.writeAll(exit_msg);
    }

    // Main shell loop
    var should_exit = false;
    var line_buf: [8192]u8 = undefined;
    const stderr_file = stdio.getStdErr();

    while (!should_exit) {
        if (is_tty) {
            try stdout_file.writeAll("grainscript> ");
        }

        // Read and process input
        const input_result = read_and_process_input(
            &stdin,
            &line_buf,
            &cmd_parser,
            &exec,
            &stderr_file,
        ) catch |err| {
            if (err == error.EndOfStream) {
                break;
            }
            return err;
        };

        if (input_result.should_exit) {
            should_exit = true;
            break;
        }

        // If we processed all input and it wasn't interactive, exit
        if (!is_tty) {
            break;
        }
    }

    if (is_tty) {
        try stdout_file.writeAll("Goodbye!\n");
    }
}

/// Initialize shell environment.
fn init_environment(allocator: std.mem.Allocator, initial_cwd: []const u8) !builtins.ShellEnvironment {
    var cwd_array: [4096]u8 = undefined;
    if (initial_cwd.len >= cwd_array.len) {
        return error.PathTooLong;
    }

    @memset(cwd_array[0..], 0);
    @memcpy(cwd_array[0..initial_cwd.len], initial_cwd);
    cwd_array[initial_cwd.len] = 0;

    return builtins.ShellEnvironment{
        .current_directory = cwd_array,
        .current_directory_len = @intCast(initial_cwd.len),
        .allocator = allocator,
    };
}

/// Deinitialize shell environment.
fn deinit_environment(allocator: std.mem.Allocator, env: *builtins.ShellEnvironment) void {
    _ = allocator;
    _ = env;
    // Environment uses stack-allocated array, no cleanup needed
}

/// Result of reading and processing input.
const InputProcessResult = struct {
    should_exit: bool,
};

/// Read input and process all lines in buffer.
fn read_and_process_input(
    stdin: *const std.fs.File,
    line_buf: *[8192]u8,
    cmd_parser: *parser.CommandParser,
    exec: *executor.Executor,
    stderr_file: *const std.fs.File,
) !InputProcessResult {
    const bytes_read = stdin.readAll(line_buf) catch |err| {
        if (err == error.EndOfStream) {
            return error.EndOfStream;
        }
        return err;
    };

    if (bytes_read == 0) {
        return error.EndOfStream;
    }

    return process_input_lines(
        line_buf,
        bytes_read,
        cmd_parser,
        exec,
        stderr_file,
    );
}

/// Process all lines in input buffer.
fn process_input_lines(
    line_buf: *[8192]u8,
    bytes_read: usize,
    cmd_parser: *parser.CommandParser,
    exec: *executor.Executor,
    stderr_file: *const std.fs.File,
) !InputProcessResult {
    const bytes_read_u32: u32 = @intCast(bytes_read);
    var line_start: u32 = 0;

    while (line_start < bytes_read_u32) {
        const line_result = find_next_line(line_buf, line_start, bytes_read_u32);
        const line = line_buf[line_result.start..line_result.end];

        // Skip empty lines
        if (line.len == 0) {
            if (line_result.found_newline) {
                line_start = line_result.end + 1;
                continue;
            } else {
                break;
            }
        }

        // Parse and execute this line
        const exec_result = parse_and_execute_line(
            line,
            cmd_parser,
            exec,
            stderr_file,
        ) catch |err| {
            handle_parse_error(err, stderr_file) catch {};
            line_start = if (line_result.found_newline) line_result.end + 1 else bytes_read_u32;
            continue;
        };

        if (exec_result.should_exit) {
            return InputProcessResult{ .should_exit = true };
        }

        // Move to next line
        if (line_result.found_newline) {
            line_start = line_result.end + 1;
        } else {
            break;
        }
    }

    return InputProcessResult{ .should_exit = false };
}

/// Find next line in buffer.
const LineResult = struct {
    start: u32,
    end: u32,
    found_newline: bool,
};

fn find_next_line(line_buf: *[8192]u8, start: u32, max: u32) LineResult {
    var end: u32 = start;
    var found_newline = false;

    while (end < max) {
        if (line_buf[end] == '\n') {
            found_newline = true;
            break;
        }
        end += 1;
    }

    return LineResult{
        .start = start,
        .end = end,
        .found_newline = found_newline,
    };
}

/// Execution result.
const ExecuteResult = struct {
    should_exit: bool,
};

/// Parse and execute a single line.
fn parse_and_execute_line(
    line: []const u8,
    cmd_parser: *parser.CommandParser,
    exec: *executor.Executor,
    stderr_file: *const std.fs.File,
) !ExecuteResult {
    const pipeline_opt = cmd_parser.parse(line) catch |err| {
        return err;
    };

    const pipeline = pipeline_opt orelse {
        return ExecuteResult{ .should_exit = false };
    };

    // Execute pipeline
    _ = exec.execute_pipeline(pipeline) catch |err| {
        handle_exec_error(err, stderr_file) catch {};
        cmd_parser.free_pipeline(&pipeline);
        return ExecuteResult{ .should_exit = false };
    };

    // Check if exit was called (via builtin should_exit flag or command name)
    if (pipeline.commands_len > 0) {
        const first_cmd = pipeline.commands[0];
        if (std.mem.eql(u8, first_cmd.command, "exit")) {
            cmd_parser.free_pipeline(&pipeline);
            return ExecuteResult{ .should_exit = true };
        }
    }

    // Free pipeline
    cmd_parser.free_pipeline(&pipeline);
    return ExecuteResult{ .should_exit = false };
}

/// Handle parse error with improved error messages.
fn handle_parse_error(err: anyerror, stderr_file: *const std.fs.File) !void {
    var err_buf: [512]u8 = undefined;
    const err_msg = format_parse_error(err, &err_buf) catch {
        // Fallback to simple error name if formatting fails
        const fallback_msg = std.fmt.bufPrint(&err_buf, "Parse error: {s}\n", .{@errorName(err)}) catch {
            try stderr_file.writeAll("Parse error\n");
            return;
        };
        try stderr_file.writeAll(fallback_msg);
        return;
    };
    try stderr_file.writeAll(err_msg);
}

/// Format parse error with helpful suggestions.
fn format_parse_error(err: anyerror, buf: []u8) ![]const u8 {
    return switch (err) {
        error.TooManyPipes => std.fmt.bufPrint(buf, "Parse error: Too many pipes (max {d})\nHint: Split complex pipelines into multiple commands or reduce pipe count\n", .{parser.CommandParser.MAX_PIPELINE}),
        error.InvalidRedirect => std.fmt.bufPrint(buf, "Parse error: Invalid redirection syntax\nHint: Use '< file' for input, '> file' for output, '>> file' for append\nExample: 'cat < input.txt > output.txt'\n", .{}),
        error.ArgumentTooLong => std.fmt.bufPrint(buf, "Parse error: Argument too long (max {d} characters)\nHint: Use quotes for arguments with spaces, or split into multiple commands\n", .{parser.CommandParser.MAX_ARG_LEN}),
        error.EmptyCommand => std.fmt.bufPrint(buf, "Parse error: Empty command\nHint: Enter a command name (e.g., 'ls', 'pwd', 'echo hello')\n", .{}),
        error.OutOfMemory => std.fmt.bufPrint(buf, "Parse error: Out of memory\nHint: Command may be too complex, try splitting into simpler commands\n", .{}),
        else => std.fmt.bufPrint(buf, "Parse error: {s}\n", .{@errorName(err)}),
    };
}

/// Handle execution error with improved error messages.
fn handle_exec_error(err: anyerror, stderr_file: *const std.fs.File) !void {
    var err_buf: [512]u8 = undefined;
    const err_msg = format_exec_error(err, &err_buf) catch {
        // Fallback to simple error name if formatting fails
        const fallback_msg = std.fmt.bufPrint(&err_buf, "Execution error: {s}\n", .{@errorName(err)}) catch {
            try stderr_file.writeAll("Execution error\n");
            return;
        };
        try stderr_file.writeAll(fallback_msg);
        return;
    };
    try stderr_file.writeAll(err_msg);
}

/// Format execution error with helpful suggestions.
fn format_exec_error(err: anyerror, buf: []u8) ![]const u8 {
    return switch (err) {
        error.FileNotFound => std.fmt.bufPrint(buf, "Execution error: File not found\nHint: Check the file path and permissions\n", .{}),
        error.AccessDenied => std.fmt.bufPrint(buf, "Execution error: Access denied\nHint: Check file permissions or try with different user\n", .{}),
        error.ProcessNotFound => std.fmt.bufPrint(buf, "Execution error: Process not found\nHint: Command may not be in PATH, check spelling or use full path\n", .{}),
        error.OutOfMemory => std.fmt.bufPrint(buf, "Execution error: Out of memory\nHint: System may be low on memory, try closing other programs\n", .{}),
        else => std.fmt.bufPrint(buf, "Execution error: {s}\n", .{@errorName(err)}),
    };
}

/// Execute a script file.
fn execute_script_file(allocator: std.mem.Allocator, script_path: []const u8) !void {
    // Check if file is a .gr file (Grainscript language)
    const is_grainscript = std.mem.endsWith(u8, script_path, ".gr");
    
    if (is_grainscript) {
        // Execute as Grainscript language program
        return execute_grainscript_file(allocator, script_path);
    } else {
        // Execute as shell command script
        return execute_shell_script_file(allocator, script_path);
    }
}

/// Execute a Grainscript language file (.gr).
fn execute_grainscript_file(allocator: std.mem.Allocator, script_path: []const u8) !void {
    const stderr_file = stdio.getStdErr();
    
    // Open script file
    const script_file = std.fs.cwd().openFile(script_path, .{}) catch |err| {
        var err_buf: [512]u8 = undefined;
        const err_msg = std.fmt.bufPrint(&err_buf, "grainscript-shell: cannot open '{s}': {s}\n", .{ script_path, @errorName(err) }) catch {
            try stderr_file.writeAll("grainscript-shell: cannot open script file\n");
            return;
        };
        try stderr_file.writeAll(err_msg);
        return;
    };
    defer script_file.close();

    // Read entire file (bounded)
    var file_buf: [65536]u8 = undefined; // Max 64KB Grainscript file
    const bytes_read = script_file.readAll(&file_buf) catch |err| {
        var err_buf: [256]u8 = undefined;
        const err_msg = std.fmt.bufPrint(&err_buf, "Error reading script: {s}\n", .{@errorName(err)}) catch {
            try stderr_file.writeAll("Error reading script\n");
            return;
        };
        try stderr_file.writeAll(err_msg);
        return;
    };
    
    if (bytes_read >= file_buf.len) {
        try stderr_file.writeAll("Error: Grainscript file too large (max 64KB)\n");
        return;
    }
    
    const source = file_buf[0..bytes_read];
    
    // Initialize Grainscript language components
    var lexer = try grainscript.Lexer.init(allocator, source);
    defer lexer.deinit();
    
    // Tokenize source before parsing
    try lexer.tokenize();
    
    var grainscript_parser_instance = try grainscript.Parser.init(allocator, &lexer);
    defer grainscript_parser_instance.deinit();
    
    // Parse source into AST
    grainscript_parser_instance.parse() catch |err| {
        handle_parse_error(err, &stderr_file) catch {};
        return;
    };
    
    // Initialize interpreter
    var interpreter = try grainscript.Interpreter.init(allocator, &grainscript_parser_instance);
    defer interpreter.deinit();
    
    // Execute program
    interpreter.execute() catch |err| {
        handle_exec_error(err, &stderr_file) catch {};
        return;
    };
}

/// Execute a shell command script file (non-.gr files).
fn execute_shell_script_file(allocator: std.mem.Allocator, script_path: []const u8) !void {
    // Initialize shell environment
    var cwd_buf: [4096]u8 = undefined;
    const initial_cwd = try std.posix.getcwd(&cwd_buf);
    var env = try init_environment(allocator, initial_cwd);
    defer deinit_environment(allocator, &env);

    // Initialize parser and executor
    var cmd_parser = parser.CommandParser.init(allocator);
    // ServiceManager is optional (requires Supervisor reference from Init System)
    // For now, pass null - will be set when Init System integration is complete
    // JobManager is always available (independent of Init System)
    var job_mgr = @import("job_manager.zig").JobManager.init(allocator);
    defer job_mgr.deinit();
    var exec = executor.Executor.init(allocator, &env, null, &job_mgr);

    // Open script file
    const script_file = std.fs.cwd().openFile(script_path, .{}) catch |err| {
        const stderr_file = stdio.getStdErr();
        var err_buf: [512]u8 = undefined;
        const err_msg = std.fmt.bufPrint(&err_buf, "grainscript-shell: cannot open '{s}': {s}\n", .{ script_path, @errorName(err) }) catch {
            try stderr_file.writeAll("grainscript-shell: cannot open script file\n");
            return;
        };
        try stderr_file.writeAll(err_msg);
        return;
    };
    defer script_file.close();

    // Read and execute script line by line
    var file_buf: [8192]u8 = undefined;
    const bytes_read = script_file.readAll(&file_buf) catch |err| {
        const stderr_file = stdio.getStdErr();
        var err_buf: [256]u8 = undefined;
        const err_msg = std.fmt.bufPrint(&err_buf, "Error reading script: {s}\n", .{@errorName(err)}) catch {
            try stderr_file.writeAll("Error reading script\n");
            return;
        };
        try stderr_file.writeAll(err_msg);
        return;
    };

    const stderr_file = stdio.getStdErr();
    const bytes_read_u32: u32 = @intCast(bytes_read);
    var line_start: u32 = 0;

    while (line_start < bytes_read_u32) {
        const line_result = find_next_line(&file_buf, line_start, bytes_read_u32);
        const line = file_buf[line_result.start..line_result.end];

        // Skip empty lines and comments
        const trimmed = std.mem.trim(u8, line, " \t\r\n");
        if (trimmed.len == 0 or (trimmed.len > 0 and trimmed[0] == '#')) {
            continue;
        }

        // Parse and execute line
        const exec_result = parse_and_execute_line(
            trimmed,
            &cmd_parser,
            &exec,
            &stderr_file,
        ) catch |err| {
            handle_parse_error(err, &stderr_file) catch {};
            continue;
        };

        if (exec_result.should_exit) {
            break;
        }

        // Move to next line
        if (line_result.found_newline) {
            line_start = line_result.end + 1;
        } else {
            break;
        }
    }
}

