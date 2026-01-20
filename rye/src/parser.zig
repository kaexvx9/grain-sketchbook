//! Rye Parser
//! Why: Parse tokenized .ry source into an AST for validation and emission.

const std = @import("std");
const Lexer = @import("lexer.zig").Lexer;
const Token = @import("lexer.zig").Token;
const TokenType = @import("lexer.zig").TokenType;

/// Function declaration in the AST.
pub const FunctionDecl = struct {
    /// Function name.
    name: []const u8,
    /// Is this a public function?
    is_pub: bool,
    /// Doc comments before the function.
    doc_comments: []const []const u8,
    /// Start line of function body.
    body_start_line: u32,
    /// End line of function body.
    body_end_line: u32,
    /// Has a /// Why: comment?
    has_why_comment: bool,
};

/// Rye AST (simplified for Phase 1).
pub const Ast = struct {
    functions: std.ArrayListUnmanaged(FunctionDecl),
    allocator: std.mem.Allocator,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .functions = .{},
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Self) void {
        self.functions.deinit(self.allocator);
    }
};

/// Rye parser.
pub const Parser = struct {
    tokens: []const Token,
    source: []const u8,
    pos: usize,
    ast: Ast,

    const Self = @This();

    /// Initialize parser with tokens and source.
    pub fn init(allocator: std.mem.Allocator, tokens: []const Token, source: []const u8) Self {
        return Self{
            .tokens = tokens,
            .source = source,
            .pos = 0,
            .ast = Ast.init(allocator),
        };
    }

    /// Free parser resources.
    pub fn deinit(self: *Self) void {
        self.ast.deinit();
    }

    /// Parse all tokens into AST.
    pub fn parse(self: *Self) !void {
        while (self.pos < self.tokens.len and self.current().type != .eof) {
            try self.parseTopLevel();
        }
    }

    fn current(self: *Self) Token {
        if (self.pos >= self.tokens.len) {
            return Token{
                .type = .eof,
                .start = 0,
                .end = 0,
                .line = 0,
                .column = 0,
            };
        }
        return self.tokens[self.pos];
    }

    fn advance(self: *Self) void {
        if (self.pos < self.tokens.len) {
            self.pos += 1;
        }
    }

    fn parseTopLevel(self: *Self) !void {
        // Collect doc comments
        var doc_comments: std.ArrayListUnmanaged([]const u8) = .{};
        defer doc_comments.deinit(self.ast.allocator);

        while (self.current().type == .doc_comment or self.current().type == .newline) {
            if (self.current().type == .doc_comment) {
                const comment_text = self.source[self.current().start..self.current().end];
                try doc_comments.append(self.ast.allocator, comment_text);
            }
            self.advance();
        }

        // Check for pub fn or fn
        var is_pub = false;
        if (self.current().type == .kw_pub) {
            is_pub = true;
            self.advance();
            // Skip whitespace/newlines
            while (self.current().type == .newline) {
                self.advance();
            }
        }

        if (self.current().type == .kw_fn) {
            try self.parseFunction(is_pub, doc_comments.items);
        } else {
            // Skip other top-level items for now
            self.advance();
        }
    }

    fn parseFunction(self: *Self, is_pub: bool, doc_comments: []const []const u8) !void {
        self.advance(); // Skip 'fn'

        // Skip whitespace
        while (self.current().type == .newline) {
            self.advance();
        }

        // Get function name
        if (self.current().type != .identifier) {
            self.advance();
            return;
        }

        const name = self.source[self.current().start..self.current().end];
        self.advance();

        // Skip to function body (find opening brace)
        var body_start_line: u32 = 0;
        while (self.current().type != .lbrace and self.current().type != .eof) {
            self.advance();
        }

        if (self.current().type == .lbrace) {
            body_start_line = self.current().line;
            self.advance();
        }

        // Find closing brace (track brace depth)
        var depth: u32 = 1;
        var body_end_line: u32 = body_start_line;
        while (depth > 0 and self.current().type != .eof) {
            if (self.current().type == .lbrace) {
                depth += 1;
            } else if (self.current().type == .rbrace) {
                depth -= 1;
                if (depth == 0) {
                    body_end_line = self.current().line;
                }
            }
            self.advance();
        }

        // Check for /// Why: in doc comments
        var has_why = false;
        for (doc_comments) |comment| {
            if (std.mem.indexOf(u8, comment, "Why:") != null) {
                has_why = true;
                break;
            }
        }

        try self.ast.functions.append(self.ast.allocator, FunctionDecl{
            .name = name,
            .is_pub = is_pub,
            .doc_comments = doc_comments,
            .body_start_line = body_start_line,
            .body_end_line = body_end_line,
            .has_why_comment = has_why,
        });
    }
};
