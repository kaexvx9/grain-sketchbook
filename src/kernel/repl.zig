//! Simple REPL for Kernel Interactive Mode
//! Why: Provide interactive command interface for development and testing.
//! Grain Style: Explicit types, bounded allocations, comprehensive assertions.

const std = @import("std");
const Debug = @import("debug.zig");
const RawIO = @import("raw_io.zig");
const HarborKernel = @import("harbor_kernel.zig").HarborKernel;
const grainscript = @import("grainscript");
const Lexer = grainscript.Lexer;
const Parser = grainscript.Parser;
const Interpreter = grainscript.Interpreter;

/// Simple REPL for kernel interactive mode.
/// Why: Allow interactive commands during development.
pub const Repl = struct {
    kernel: *HarborKernel,
    running: bool,
    /// Fixed buffer allocator for Grainscript execution.
    /// Why: Provide memory allocation for Grainscript interpreter in freestanding kernel.
    /// Grain Style: Bounded allocation (64KB buffer), explicit lifetime.
    allocator_buffer: [64 * 1024]u8 = undefined, // 64KB buffer for Grainscript
    fixed_allocator: std.heap.FixedBufferAllocator,

    const Self = @This();
    const MAX_LINE_LEN: u32 = 512;
    const MAX_ARGS: u32 = 16;

    /// Initialize REPL.
    pub fn init(kernel: *HarborKernel) Self {
        var repl = Self{
            .kernel = kernel,
            .running = true,
            .allocator_buffer = undefined,
            .fixed_allocator = undefined,
        };
        // Initialize fixed buffer allocator for Grainscript
        repl.fixed_allocator = std.heap.FixedBufferAllocator.init(&repl.allocator_buffer);
        return repl;
    }

    /// Run REPL loop.
    /// Why: Read commands from UART, parse, execute, print results.
    pub fn run(self: *Self) void {
        Debug.kprint("\n", .{});
        Debug.kprint("Grainscript REPL v0.1.0\n", .{});
        Debug.kprint("Type 'help' for commands, 'exit' to quit.\n", .{});
        Debug.kprint("\n", .{});

        var line_buf: [MAX_LINE_LEN]u8 = undefined;
        var line_len: u32 = 0;

        while (self.running) {
            // Print prompt
            Debug.kprint("grainscript> ", .{});

            // Read line from UART (blocking wait for input)
            line_len = 0;
            while (line_len < MAX_LINE_LEN) {
                // Wait for character (blocking)
                const c = RawIO.read_byte_blocking();
                
                // Handle newline (enter key)
                if (c == '\n' or c == '\r') {
                    break;
                }
                
                // Handle backspace
                if (c == '\x08' or c == '\x7f') {
                    if (line_len > 0) {
                        line_len -= 1;
                        // Echo backspace (move cursor back)
                        RawIO.write_byte('\x08');
                        RawIO.write_byte(' ');
                        RawIO.write_byte('\x08');
                    }
                    continue;
                }
                
                // Add character to line
                if (c >= 0x20 and c < 0x7f) { // Printable ASCII
                    line_buf[line_len] = c;
                    line_len += 1;
                    RawIO.write_byte(c); // Echo character
                }
            }
            
            // Echo newline
            Debug.kprint("\n", .{});

            // Process command
            if (line_len > 0) {
                self.process_command(line_buf[0..line_len]);
            }
        }
    }

    /// Process command line.
    fn process_command(self: *Self, line: []const u8) void {
        // Trim whitespace
        var trimmed = line;
        while (trimmed.len > 0 and (trimmed[0] == ' ' or trimmed[0] == '\t')) {
            trimmed = trimmed[1..];
        }
        while (trimmed.len > 0 and (trimmed[trimmed.len - 1] == ' ' or trimmed[trimmed.len - 1] == '\t')) {
            trimmed = trimmed[0..trimmed.len - 1];
        }

        if (trimmed.len == 0) {
            return; // Empty line
        }

        // Parse command and arguments
        var args: [MAX_ARGS][]const u8 = undefined;
        var arg_count: u32 = 0;
        var i: u32 = 0;
        var start: u32 = 0;

        while (i < trimmed.len and arg_count < MAX_ARGS) {
            if (trimmed[i] == ' ' or trimmed[i] == '\t') {
                if (i > start) {
                    args[arg_count] = trimmed[start..i];
                    arg_count += 1;
                }
                start = i + 1;
            }
            i += 1;
        }
        
        if (start < trimmed.len and arg_count < MAX_ARGS) {
            args[arg_count] = trimmed[start..];
            arg_count += 1;
        }

        if (arg_count == 0) {
            return;
        }

        const command = args[0];
        const command_args = if (arg_count > 1) args[1..arg_count] else &[_][]const u8{};

        // Execute command
        self.execute_command(command, command_args);
    }

    /// Execute command.
    fn execute_command(self: *Self, command: []const u8, args: []const []const u8) void {
        // Help command
        if (std.mem.eql(u8, command, "help")) {
            Debug.kprint("Available commands:\n", .{});
            Debug.kprint("  help          - Show this help message\n", .{});
            Debug.kprint("  sysinfo       - Show system information\n", .{});
            Debug.kprint("  ps            - List processes\n", .{});
            Debug.kprint("  echo <text>   - Print text\n", .{});
            Debug.kprint("  eval <code>   - Execute Grainscript code\n", .{});
            Debug.kprint("  exit          - Exit REPL\n", .{});
            return;
        }

        // Exit command
        if (std.mem.eql(u8, command, "exit")) {
            Debug.kprint("Goodbye!\n", .{});
            self.running = false;
            return;
        }

        // Sysinfo command
        if (std.mem.eql(u8, command, "sysinfo")) {
            self.cmd_sysinfo();
            return;
        }

        // Process list command
        if (std.mem.eql(u8, command, "ps")) {
            self.cmd_ps();
            return;
        }

        // Echo command
        if (std.mem.eql(u8, command, "echo")) {
            self.cmd_echo(args);
            return;
        }

        // Eval command (Grainscript execution)
        if (std.mem.eql(u8, command, "eval")) {
            self.cmd_eval(args);
            return;
        }

        // Unknown command
        Debug.kprint("Unknown command: ", .{});
        for (command) |c| {
            RawIO.write_byte(c);
        }
        Debug.kprint("\n", .{});
        Debug.kprint("Type 'help' for available commands.\n", .{});
    }

    /// Execute sysinfo command.
    fn cmd_sysinfo(self: *Self) void {
        // Count processes
        const MAX_PROCESSES = 256; // From harbor_kernel_types.zig
        var process_count: u32 = 0;
        var i: u32 = 0;
        while (i < MAX_PROCESSES) : (i += 1) {
            if (self.kernel.processes[i].allocated) {
                process_count += 1;
            }
        }
        
        Debug.kprint("System Information:\n", .{});
        Debug.kprint("  Kernel: Clutch Harbor Kernel v0.1.0\n", .{});
        Debug.kprint("  Architecture: RISC-V64\n", .{});
        Debug.kprint("  Users: {d}\n", .{self.kernel.user_count});
        Debug.kprint("  Processes: {d}\n", .{process_count});
    }

    /// Execute ps command.
    fn cmd_ps(self: *Self) void {
        Debug.kprint("Process List:\n", .{});
        Debug.kprint("  PID  State\n", .{});
        
        const MAX_PROCESSES = 256; // From harbor_kernel_types.zig
        var count: u32 = 0;
        var i: u32 = 0;
        while (i < MAX_PROCESSES) : (i += 1) {
            if (self.kernel.processes[i].allocated) {
                const pid = self.kernel.processes[i].id;
                const state_str = switch (self.kernel.processes[i].state) {
                    .running => "running",
                    .exited => "exited",
                    .free => "free",
                };
                Debug.kprint("  {d}  {s}\n", .{ pid, state_str });
                count += 1;
            }
        }
        
        if (count == 0) {
            Debug.kprint("  (no processes)\n", .{});
        }
    }

    /// Execute echo command.
    fn cmd_echo(self: *Self, args: []const []const u8) void {
        _ = self;
        if (args.len == 0) {
            Debug.kprint("\n", .{});
            return;
        }

        var first = true;
        for (args) |arg| {
            if (!first) {
                RawIO.write_byte(' ');
            }
            first = false;
            for (arg) |c| {
                RawIO.write_byte(c);
            }
        }
        Debug.kprint("\n", .{});
    }

    /// Execute eval command (Grainscript execution).
    /// Why: Execute Grainscript code in kernel REPL for testing and development.
    fn cmd_eval(self: *Self, args: []const []const u8) void {
        if (args.len == 0) {
            Debug.kprint("Error: eval requires code argument\n", .{});
            Debug.kprint("Usage: eval <grainscript_code>\n", .{});
            Debug.kprint("Example: eval \"42 + 8;\"\n", .{});
            return;
        }

        // Join all arguments into source code (with spaces)
        var source_buf: [MAX_LINE_LEN]u8 = undefined;
        var source_len: u32 = 0;
        var first = true;

        for (args) |arg| {
            if (!first) {
                if (source_len < source_buf.len) {
                    source_buf[source_len] = ' ';
                    source_len += 1;
                }
            }
            first = false;

            for (arg) |c| {
                if (source_len >= source_buf.len) {
                    Debug.kprint("Error: Code too long (max {d} chars)\n", .{MAX_LINE_LEN});
                    return;
                }
                source_buf[source_len] = c;
                source_len += 1;
            }
        }

        const source = source_buf[0..source_len];

        // Reset fixed buffer allocator for new execution
        self.fixed_allocator.reset();
        const allocator = self.fixed_allocator.allocator();

        // Execute Grainscript
        cmd_eval_internal(self, allocator, source) catch |err| {
            Debug.kprint("Grainscript error: ", .{});
            // Handle various error types from Grainscript components
            const err_msg = switch (err) {
                error.OutOfMemory => "Out of memory",
                // Parser errors
                error.ExpectedIdentifier => "Expected identifier",
                error.ExpectedLeftParen => "Expected '('",
                error.ExpectedRightParen => "Expected ')'",
                error.ExpectedComma => "Expected ','",
                error.ExpectedSemicolon => "Expected ';'",
                error.ExpectedAssign => "Expected '='",
                error.ExpectedType => "Expected type",
                error.UnexpectedToken => "Unexpected token",
                error.UnexpectedEof => "Unexpected end of file",
                error.InvalidOperator => "Invalid operator",
                error.InvalidLiteral => "Invalid literal",
                error.InvalidNode => "Invalid AST node",
                // Interpreter errors
                error.variable_not_found => "Variable not found",
                error.variable_already_exists => "Variable already exists",
                error.function_not_found => "Function not found",
                error.type_mismatch => "Type mismatch",
                error.division_by_zero => "Division by zero",
                error.invalid_argument => "Invalid argument",
                error.string_too_long => "String too long",
                error.call_stack_overflow => "Call stack overflow",
                error.too_many_variables => "Too many variables",
                error.too_many_functions => "Too many functions",
                error.too_many_call_args => "Too many call arguments",
                error.runtime_error => "Runtime error",
            };
            Debug.kprint("{s}\n", .{err_msg});
        };
    }

    /// Internal Grainscript execution (with error handling).
    fn cmd_eval_internal(self: *Self, allocator: std.mem.Allocator, source: []const u8) !void {
        _ = self; // Kernel reference available if needed for syscalls

        // Initialize Grainscript components
        var lexer = try Lexer.init(allocator, source);
        defer lexer.deinit();

        try lexer.tokenize();

        var parser = try Parser.init(allocator, &lexer);
        defer parser.deinit();

        try parser.parse();

        var interpreter = try Interpreter.init(allocator, &parser);
        defer interpreter.deinit();

        // Execute Grainscript
        try interpreter.execute();

        // Print result (if any)
        const exit_code = interpreter.get_exit_code();
        if (exit_code == 0) {
            Debug.kprint("OK (exit code: {d})\n", .{exit_code});
        } else {
            Debug.kprint("Exit code: {d}\n", .{exit_code});
        }
    }
};
