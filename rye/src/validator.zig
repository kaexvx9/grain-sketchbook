//! Rye Validator
//! Why: Enforce RyeStyle constraints on parsed AST.

const std = @import("std");
const Parser = @import("parser.zig").Parser;
const FunctionDecl = @import("parser.zig").FunctionDecl;

/// Validation error.
pub const ValidationError = struct {
    file: []const u8,
    line: u32,
    column: u32,
    message: []const u8,
    hint: []const u8,
};

/// Validator configuration.
pub const Config = struct {
    max_function_lines: u32 = 64,
    max_line_length: u32 = 128,
    require_why_comments: bool = true,
};

/// Rye validator.
pub const Validator = struct {
    config: Config,
    errors: std.ArrayListUnmanaged(ValidationError),
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize validator.
    pub fn init(allocator: std.mem.Allocator, config: Config) Self {
        return Self{
            .config = config,
            .errors = .{},
            .allocator = allocator,
        };
    }

    /// Free validator resources.
    pub fn deinit(self: *Self) void {
        self.errors.deinit(self.allocator);
    }

    /// Validate source and AST.
    pub fn validate(
        self: *Self,
        source: []const u8,
        functions: []const FunctionDecl,
        file_path: []const u8,
    ) !void {
        // Check line lengths
        try self.checkLineLengths(source, file_path);

        // Check function constraints
        for (functions) |func| {
            try self.checkFunction(func, file_path);
        }
    }

    /// Check all line lengths.
    fn checkLineLengths(self: *Self, source: []const u8, file_path: []const u8) !void {
        var line_num: u32 = 1;
        var line_start: usize = 0;

        for (source, 0..) |c, i| {
            if (c == '\n') {
                const line_len: u32 = @intCast(i - line_start);
                if (line_len > self.config.max_line_length) {
                    try self.errors.append(self.allocator, ValidationError{
                        .file = file_path,
                        .line = line_num,
                        .column = self.config.max_line_length + 1,
                        .message = "line exceeds maximum length",
                        .hint = "wrap the line or use shorter names",
                    });
                }
                line_num += 1;
                line_start = i + 1;
            }
        }
    }

    /// Check function constraints.
    fn checkFunction(self: *Self, func: FunctionDecl, file_path: []const u8) !void {
        // Check function length
        const func_lines = func.body_end_line - func.body_start_line + 1;
        if (func_lines > self.config.max_function_lines) {
            try self.errors.append(ValidationError{
                .file = file_path,
                .line = func.body_start_line,
                .column = 1,
                .message = "function exceeds maximum line limit",
                .hint = "split into smaller functions",
            });
        }

        // Check why comment for public functions
        if (func.is_pub and self.config.require_why_comments and !func.has_why_comment) {
            try self.errors.append(ValidationError{
                .file = file_path,
                .line = func.body_start_line,
                .column = 1,
                .message = "public function missing '/// Why:' documentation",
                .hint = "add a '/// Why:' comment explaining the function's purpose",
            });
        }
    }

    /// Print all errors.
    pub fn printErrors(self: *Self) void {
        for (self.errors.items) |err| {
            std.debug.print("{s}:{d}:{d}: error: {s}\n", .{
                err.file,
                err.line,
                err.column,
                err.message,
            });
            std.debug.print("  = help: {s}\n", .{err.hint});
        }
    }

    /// Get error count.
    pub fn errorCount(self: *Self) usize {
        return self.errors.items.len;
    }
};
