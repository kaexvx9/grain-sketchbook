//! Rye Lexer
//! Why: Tokenize .ry source files for parsing and validation.

const std = @import("std");

/// Token types for Rye (subset of Zig tokens we care about).
pub const TokenType = enum {
    // Keywords
    kw_fn,
    kw_pub,
    kw_const,
    kw_var,
    kw_if,
    kw_else,
    kw_while,
    kw_for,
    kw_return,
    kw_break,
    kw_continue,
    kw_struct,
    kw_enum,
    kw_union,
    kw_asm,
    kw_volatile,
    kw_inline,
    kw_noreturn,
    kw_void,
    kw_bool,
    kw_true,
    kw_false,
    kw_null,
    kw_undefined,

    // Literals
    identifier,
    integer,
    string,
    char,

    // Punctuation
    lparen,
    rparen,
    lbrace,
    rbrace,
    lbracket,
    rbracket,
    comma,
    colon,
    semicolon,
    dot,
    arrow,
    fat_arrow,
    at,
    hash,
    backslash,

    // Operators
    plus,
    minus,
    star,
    slash,
    percent,
    ampersand,
    pipe,
    caret,
    tilde,
    bang,
    lt,
    gt,
    eq,
    lt_eq,
    gt_eq,
    eq_eq,
    bang_eq,
    ampersand_ampersand,
    pipe_pipe,
    lt_lt,
    gt_gt,

    // Comments
    doc_comment,
    line_comment,

    // Special
    newline,
    eof,
    invalid,
};

/// A token from the Rye source.
pub const Token = struct {
    type: TokenType,
    start: usize,
    end: usize,
    line: u32,
    column: u32,
};

/// Rye lexer.
pub const Lexer = struct {
    source: []const u8,
    pos: usize,
    line: u32,
    column: u32,
    tokens: std.ArrayListUnmanaged(Token),
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize lexer with source code.
    pub fn init(allocator: std.mem.Allocator, source: []const u8) Self {
        return Self{
            .source = source,
            .pos = 0,
            .line = 1,
            .column = 1,
            .tokens = .{},
            .allocator = allocator,
        };
    }

    /// Free lexer resources.
    pub fn deinit(self: *Self) void {
        self.tokens.deinit(self.allocator);
    }

    /// Tokenize the entire source.
    pub fn tokenize(self: *Self) !void {
        while (self.pos < self.source.len) {
            const token = self.nextToken();
            try self.tokens.append(self.allocator, token);
            if (token.type == .eof) break;
        }
    }

    /// Get next token.
    fn nextToken(self: *Self) Token {
        self.skipWhitespace();

        if (self.pos >= self.source.len) {
            return Token{
                .type = .eof,
                .start = self.pos,
                .end = self.pos,
                .line = self.line,
                .column = self.column,
            };
        }

        const start = self.pos;
        const start_line = self.line;
        const start_column = self.column;
        const c = self.source[self.pos];

        // Comments
        if (c == '/' and self.pos + 1 < self.source.len) {
            if (self.source[self.pos + 1] == '/') {
                return self.scanComment(start, start_line, start_column);
            }
        }

        // Identifiers and keywords
        if (isAlpha(c) or c == '_') {
            return self.scanIdentifier(start, start_line, start_column);
        }

        // Numbers
        if (isDigit(c)) {
            return self.scanNumber(start, start_line, start_column);
        }

        // Strings
        if (c == '"') {
            return self.scanString(start, start_line, start_column);
        }

        // Single-character tokens
        self.pos += 1;
        self.column += 1;

        const token_type: TokenType = switch (c) {
            '(' => .lparen,
            ')' => .rparen,
            '{' => .lbrace,
            '}' => .rbrace,
            '[' => .lbracket,
            ']' => .rbracket,
            ',' => .comma,
            ':' => .colon,
            ';' => .semicolon,
            '.' => .dot,
            '@' => .at,
            '#' => .hash,
            '+' => .plus,
            '-' => .minus,
            '*' => .star,
            '/' => .slash,
            '%' => .percent,
            '&' => .ampersand,
            '|' => .pipe,
            '^' => .caret,
            '~' => .tilde,
            '!' => .bang,
            '<' => .lt,
            '>' => .gt,
            '=' => .eq,
            '\\' => .backslash,
            '\n' => blk: {
                self.line += 1;
                self.column = 1;
                break :blk .newline;
            },
            else => .invalid,
        };

        return Token{
            .type = token_type,
            .start = start,
            .end = self.pos,
            .line = start_line,
            .column = start_column,
        };
    }

    fn skipWhitespace(self: *Self) void {
        while (self.pos < self.source.len) {
            const c = self.source[self.pos];
            if (c == ' ' or c == '\t' or c == '\r') {
                self.pos += 1;
                self.column += 1;
            } else {
                break;
            }
        }
    }

    fn scanComment(self: *Self, start: usize, start_line: u32, start_column: u32) Token {
        // Check for doc comment (///)
        const is_doc = self.pos + 2 < self.source.len and self.source[self.pos + 2] == '/';
        
        // Skip to end of line
        while (self.pos < self.source.len and self.source[self.pos] != '\n') {
            self.pos += 1;
            self.column += 1;
        }

        return Token{
            .type = if (is_doc) .doc_comment else .line_comment,
            .start = start,
            .end = self.pos,
            .line = start_line,
            .column = start_column,
        };
    }

    fn scanIdentifier(self: *Self, start: usize, start_line: u32, start_column: u32) Token {
        while (self.pos < self.source.len) {
            const c = self.source[self.pos];
            if (isAlpha(c) or isDigit(c) or c == '_') {
                self.pos += 1;
                self.column += 1;
            } else {
                break;
            }
        }

        const text = self.source[start..self.pos];
        const token_type = getKeyword(text) orelse .identifier;

        return Token{
            .type = token_type,
            .start = start,
            .end = self.pos,
            .line = start_line,
            .column = start_column,
        };
    }

    fn scanNumber(self: *Self, start: usize, start_line: u32, start_column: u32) Token {
        while (self.pos < self.source.len and isDigit(self.source[self.pos])) {
            self.pos += 1;
            self.column += 1;
        }

        return Token{
            .type = .integer,
            .start = start,
            .end = self.pos,
            .line = start_line,
            .column = start_column,
        };
    }

    fn scanString(self: *Self, start: usize, start_line: u32, start_column: u32) Token {
        self.pos += 1; // Skip opening quote
        self.column += 1;

        while (self.pos < self.source.len and self.source[self.pos] != '"') {
            if (self.source[self.pos] == '\\' and self.pos + 1 < self.source.len) {
                self.pos += 2;
                self.column += 2;
            } else {
                self.pos += 1;
                self.column += 1;
            }
        }

        if (self.pos < self.source.len) {
            self.pos += 1; // Skip closing quote
            self.column += 1;
        }

        return Token{
            .type = .string,
            .start = start,
            .end = self.pos,
            .line = start_line,
            .column = start_column,
        };
    }

    fn getKeyword(text: []const u8) ?TokenType {
        const keywords = std.StaticStringMap(TokenType).initComptime(.{
            .{ "fn", .kw_fn },
            .{ "pub", .kw_pub },
            .{ "const", .kw_const },
            .{ "var", .kw_var },
            .{ "if", .kw_if },
            .{ "else", .kw_else },
            .{ "while", .kw_while },
            .{ "for", .kw_for },
            .{ "return", .kw_return },
            .{ "break", .kw_break },
            .{ "continue", .kw_continue },
            .{ "struct", .kw_struct },
            .{ "enum", .kw_enum },
            .{ "union", .kw_union },
            .{ "asm", .kw_asm },
            .{ "volatile", .kw_volatile },
            .{ "inline", .kw_inline },
            .{ "noreturn", .kw_noreturn },
            .{ "void", .kw_void },
            .{ "bool", .kw_bool },
            .{ "true", .kw_true },
            .{ "false", .kw_false },
            .{ "null", .kw_null },
            .{ "undefined", .kw_undefined },
        });
        return keywords.get(text);
    }
};

fn isAlpha(c: u8) bool {
    return (c >= 'a' and c <= 'z') or (c >= 'A' and c <= 'Z');
}

fn isDigit(c: u8) bool {
    return c >= '0' and c <= '9';
}
