//! Rye Compiler - Phase 1: Transpiler to Zig
//! Why: Compile .ry files to .zig files, enforcing RyeStyle constraints.
//!
//! Phase 1 Strategy:
//! 1. Parse .ry files (Rye syntax ≈ Zig syntax with enforced constraints)
//! 2. Validate RyeStyle constraints (64-line functions, 128-char lines, why comments)
//! 3. Emit .zig files (minimal transformation, mostly validation)
//! 4. Invoke Zig compiler on emitted files

const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Parser = @import("parser.zig").Parser;
const Validator = @import("validator.zig").Validator;
const Emitter = @import("emitter.zig").Emitter;

/// Rye compiler configuration.
const Config = struct {
    /// Maximum lines per function (RyeStyle: 64).
    max_function_lines: u32 = 64,
    /// Maximum characters per line (RyeStyle: 128).
    max_line_length: u32 = 128,
    /// Require /// Why: comments on public functions.
    require_why_comments: bool = true,
    /// Output directory for generated .zig files.
    output_dir: []const u8 = "zig-out/rye",
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        printUsage();
        return;
    }

    const command = args[1];

    if (std.mem.eql(u8, command, "build")) {
        try buildCommand(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "check")) {
        try checkCommand(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "fmt")) {
        try fmtCommand(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "init")) {
        try initCommand(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "stats")) {
        try statsCommand(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "version")) {
        std.debug.print("rye 0.4.0\n", .{});
    } else if (std.mem.eql(u8, command, "help")) {
        printUsage();
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
        printUsage();
    }
}

fn printUsage() void {
    const usage =
        \\Rye Compiler 0.4.0
        \\
        \\Usage: rye <command> [options] [files...]
        \\
        \\Commands:
        \\  build    Compile .ry files to executable
        \\  check    Validate .ry files without compiling
        \\  fmt      Format .ry files
        \\  init     Create a new Rye project
        \\  stats    Show project statistics
        \\  version  Print version
        \\  help     Print this help
        \\
        \\Check Options:
        \\  --summary  Show aggregated error counts only
        \\  --json     Output results as JSON (for CI)
        \\
        \\Examples:
        \\  rye init myproject
        \\  rye build src/main.ry
        \\  rye check src/*.ry
        \\  rye check --json src/*.ry
        \\  rye stats src/
        \\
    ;
    std.debug.print("{s}", .{usage});
}

fn buildCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len == 0) {
        std.debug.print("Error: no input files\n", .{});
        return;
    }

    const config = Config{};

    for (args) |file_path| {
        std.debug.print("Compiling: {s}\n", .{file_path});
        try compileFile(allocator, file_path, config);
    }
}

fn checkCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len == 0) {
        std.debug.print("Error: no input files\n", .{});
        return;
    }

    // Parse flags
    var summary_mode = false;
    var json_mode = false;
    var file_start: usize = 0;
    for (args, 0..) |arg, i| {
        if (std.mem.eql(u8, arg, "--summary")) {
            summary_mode = true;
            file_start = i + 1;
        } else if (std.mem.eql(u8, arg, "--json")) {
            json_mode = true;
            file_start = i + 1;
        } else break;
    }
    const file_args = args[file_start..];

    const config = Config{};
    var error_count: u32 = 0;
    var line_errors: u32 = 0;
    var func_errors: u32 = 0;
    var why_errors: u32 = 0;
    var files_with_errors: u32 = 0;

    for (file_args) |file_path| {
        const print_errs = !summary_mode and !json_mode;
        const result = try validateFileDetailed(allocator, file_path, config, print_errs);
        error_count += result.total;
        line_errors += result.line_errors;
        func_errors += result.func_errors;
        why_errors += result.why_errors;
        if (result.total > 0) files_with_errors += 1;
    }

    if (json_mode) {
        std.debug.print("{{", .{});
        std.debug.print("\"files_checked\":{},", .{file_args.len});
        std.debug.print("\"files_with_errors\":{},", .{files_with_errors});
        std.debug.print("\"total_errors\":{},", .{error_count});
        std.debug.print("\"line_length_errors\":{},", .{line_errors});
        std.debug.print("\"func_length_errors\":{},", .{func_errors});
        std.debug.print("\"missing_why_errors\":{},", .{why_errors});
        std.debug.print("\"passed\":{s}", .{if (error_count == 0) "true" else "false"});
        std.debug.print("}}\n", .{});
    } else if (error_count == 0) {
        std.debug.print("All checks passed.\n", .{});
    } else if (summary_mode) {
        std.debug.print("\nRyeStyle Check Summary\n", .{});
        std.debug.print("======================\n", .{});
        std.debug.print("Files checked:   {}\n", .{file_args.len});
        std.debug.print("Files w/errors:  {}\n", .{files_with_errors});
        std.debug.print("Total errors:    {}\n", .{error_count});
        std.debug.print("  Line length:   {}\n", .{line_errors});
        std.debug.print("  Func length:   {}\n", .{func_errors});
        std.debug.print("  Missing Why:   {}\n", .{why_errors});
    } else {
        std.debug.print("{} error(s) found.\n", .{error_count});
    }
}

const ValidationResult = struct {
    total: u32,
    line_errors: u32,
    func_errors: u32,
    why_errors: u32,
};

fn fmtCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    if (args.len == 0) {
        std.debug.print("Error: no input files\n", .{});
        return;
    }

    for (args) |file_path| {
        std.debug.print("Formatting: {s} (not yet implemented)\n", .{file_path});
    }
}

fn compileFile(allocator: std.mem.Allocator, file_path: []const u8, config: Config) !void {
    // Read source file
    const source = std.fs.cwd().readFileAlloc(allocator, file_path, 1024 * 1024) catch |err| {
        std.debug.print("Error reading {s}: {}\n", .{ file_path, err });
        return err;
    };
    defer allocator.free(source);

    // Validate RyeStyle constraints
    const errors = try validateSource(allocator, source, file_path, config);
    if (errors > 0) {
        std.debug.print("Compilation failed with {} error(s).\n", .{errors});
        return error.ValidationFailed;
    }

    // For Phase 1, just copy to .zig (Rye ≈ Zig syntax)
    const zig_path = try std.fmt.allocPrint(allocator, "{s}.zig", .{file_path[0 .. file_path.len - 3]});
    defer allocator.free(zig_path);

    try std.fs.cwd().writeFile(.{ .sub_path = zig_path, .data = source });
    std.debug.print("Emitted: {s}\n", .{zig_path});
}

fn validateFileDetailed(
    allocator: std.mem.Allocator,
    file_path: []const u8,
    config: Config,
    print_errors: bool,
) !ValidationResult {
    const source = std.fs.cwd().readFileAlloc(allocator, file_path, 1024 * 1024) catch |err| {
        std.debug.print("Error reading {s}: {}\n", .{ file_path, err });
        return ValidationResult{ .total = 1, .line_errors = 0, .func_errors = 0, .why_errors = 0 };
    };
    defer allocator.free(source);

    return try validateSourceDetailed(allocator, source, file_path, config, print_errors);
}

fn validateFile(allocator: std.mem.Allocator, file_path: []const u8, config: Config) !u32 {
    const result = try validateFileDetailed(allocator, file_path, config, true);
    return result.total;
}

fn validateSourceDetailed(
    allocator: std.mem.Allocator,
    source: []const u8,
    file_path: []const u8,
    config: Config,
    print_errors: bool,
) !ValidationResult {
    var line_errors: u32 = 0;
    var func_errors: u32 = 0;
    var why_errors: u32 = 0;

    // Check line lengths
    var line_num: u32 = 1;
    var line_start: usize = 0;
    for (source, 0..) |c, i| {
        if (c == '\n') {
            const line_len = i - line_start;
            if (line_len > config.max_line_length) {
                if (print_errors) {
                    std.debug.print("{s}:{}: error: line exceeds {}-character limit (has {} characters)\n", .{
                        file_path, line_num, config.max_line_length, line_len,
                    });
                }
                line_errors += 1;
            }
            line_num += 1;
            line_start = i + 1;
        }
    }

    // Tokenize
    var lexer = Lexer.init(allocator, source);
    defer lexer.deinit();
    try lexer.tokenize();

    // Parse
    var parser = Parser.init(allocator, lexer.tokens.items, source);
    defer parser.deinit();
    try parser.parse();

    // Check function constraints
    for (parser.ast.functions.items) |func| {
        const func_lines = func.body_end_line - func.body_start_line + 1;

        // Check function length
        if (func_lines > config.max_function_lines) {
            if (print_errors) {
                std.debug.print("{s}:{}: error: function '{s}' exceeds {}-line limit (has {} lines)\n", .{
                    file_path,
                    func.body_start_line,
                    func.name,
                    config.max_function_lines,
                    func_lines,
                });
                std.debug.print("  = help: split into smaller functions\n", .{});
            }
            func_errors += 1;
        }

        // Check why comment for public functions
        if (func.is_pub and config.require_why_comments and !func.has_why_comment) {
            if (print_errors) {
                std.debug.print("{s}:{}: error: public function '{s}' missing '/// Why:' documentation\n", .{
                    file_path,
                    func.body_start_line,
                    func.name,
                });
                std.debug.print("  = help: add a '/// Why:' comment explaining the function's purpose\n", .{});
            }
            why_errors += 1;
        }
    }

    return ValidationResult{
        .total = line_errors + func_errors + why_errors,
        .line_errors = line_errors,
        .func_errors = func_errors,
        .why_errors = why_errors,
    };
}

fn validateSource(allocator: std.mem.Allocator, source: []const u8, file_path: []const u8, config: Config) !u32 {
    const result = try validateSourceDetailed(allocator, source, file_path, config, true);
    return result.total;
}

fn initCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    _ = allocator;
    const project_name = if (args.len > 0) args[0] else "myproject";

    std.debug.print("Creating Rye project: {s}\n", .{project_name});

    // Create directories
    std.fs.cwd().makePath(project_name) catch |err| {
        std.debug.print("Error creating directory: {}\n", .{err});
        return;
    };

    const src_path = std.fmt.comptimePrint("{s}/src", .{"{s}"});
    _ = src_path;

    // Create src directory
    var path_buf: [256]u8 = undefined;
    const src_dir = std.fmt.bufPrint(&path_buf, "{s}/src", .{project_name}) catch return;
    std.fs.cwd().makePath(src_dir) catch {};

    // Create main.ry
    const main_content =
        \\//! Main entry point
        \\//! Why: Application entry point.
        \\
        \\/// Main function.
        \\/// Why: Entry point called by runtime.
        \\pub fn main() void {
        \\    // Your code here
        \\}
        \\
    ;

    var main_path_buf: [256]u8 = undefined;
    const main_path = std.fmt.bufPrint(&main_path_buf, "{s}/src/main.ry", .{project_name}) catch return;
    std.fs.cwd().writeFile(.{ .sub_path = main_path, .data = main_content }) catch |err| {
        std.debug.print("Error creating main.ry: {}\n", .{err});
        return;
    };

    // Create build.zig
    const build_content =
        \\const std = @import("std");
        \\
        \\pub fn build(b: *std.Build) void {
        \\    const target = b.standardTargetOptions(.{});
        \\    const optimize = b.standardOptimizeOption(.{});
        \\
        \\    // TODO: Add Rye compilation step
        \\    _ = target;
        \\    _ = optimize;
        \\}
        \\
    ;

    var build_path_buf: [256]u8 = undefined;
    const build_path = std.fmt.bufPrint(&build_path_buf, "{s}/build.zig", .{project_name}) catch return;
    std.fs.cwd().writeFile(.{ .sub_path = build_path, .data = build_content }) catch {};

    std.debug.print("Created:\n", .{});
    std.debug.print("  {s}/\n", .{project_name});
    std.debug.print("  {s}/src/\n", .{project_name});
    std.debug.print("  {s}/src/main.ry\n", .{project_name});
    std.debug.print("  {s}/build.zig\n", .{project_name});
    std.debug.print("\nNext steps:\n", .{});
    std.debug.print("  cd {s}\n", .{project_name});
    std.debug.print("  rye check src/main.ry\n", .{});
}

fn statsCommand(allocator: std.mem.Allocator, args: []const []const u8) !void {
    if (args.len == 0) {
        std.debug.print("Error: no input files\n", .{});
        return;
    }

    var total_files: u32 = 0;
    var total_lines: u32 = 0;
    var total_functions: u32 = 0;
    var total_pub_functions: u32 = 0;
    var max_func_lines: u32 = 0;
    var max_func_name_buf: [64]u8 = undefined;
    var max_func_name_len: usize = 0;

    for (args) |file_path| {
        const source = std.fs.cwd().readFileAlloc(allocator, file_path, 1024 * 1024) catch continue;
        defer allocator.free(source);

        total_files += 1;

        // Count lines
        var lines: u32 = 1;
        for (source) |c| {
            if (c == '\n') lines += 1;
        }
        total_lines += lines;

        // Parse for function stats
        var lexer = Lexer.init(allocator, source);
        defer lexer.deinit();
        lexer.tokenize() catch continue;

        var parser = Parser.init(allocator, lexer.tokens.items, source);
        defer parser.deinit();
        parser.parse() catch continue;

        for (parser.ast.functions.items) |func| {
            total_functions += 1;
            if (func.is_pub) total_pub_functions += 1;

            const func_lines = func.body_end_line - func.body_start_line + 1;
            if (func_lines > max_func_lines) {
                max_func_lines = func_lines;
                const copy_len = @min(func.name.len, max_func_name_buf.len);
                @memcpy(max_func_name_buf[0..copy_len], func.name[0..copy_len]);
                max_func_name_len = copy_len;
            }
        }
    }

    std.debug.print("\nRye Project Statistics\n", .{});
    std.debug.print("======================\n", .{});
    std.debug.print("Files:           {}\n", .{total_files});
    std.debug.print("Lines:           {}\n", .{total_lines});
    std.debug.print("Functions:       {}\n", .{total_functions});
    std.debug.print("  Public:        {}\n", .{total_pub_functions});
    std.debug.print("  Private:       {}\n", .{total_functions - total_pub_functions});
    if (max_func_lines > 0) {
        std.debug.print("Longest fn:      {s} ({} lines)\n", .{
            max_func_name_buf[0..max_func_name_len],
            max_func_lines,
        });
    }
    std.debug.print("\nLimits:\n", .{});
    std.debug.print("  Max fn lines:  64\n", .{});
    std.debug.print("  Max line len:  128\n", .{});
}
