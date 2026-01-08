//! Grainscript Media Workflow Parser: Parse Grainscript media workflows.
//! Why: Unified scripting language for media processing workflows.
//! Architecture: Parse Grainscript DSL into DAG workflow representation.
//!
//! GrainStyle compliance:
//! - grain_case function names
//! - u32/u64 types (not usize/isize)
//! - MAX_ constants for bounded allocations
//! - Assertions for preconditions/postconditions
//! - No recursion (iterative algorithms, stack-based)

const std = @import("std");
const grainflow_dag = @import("grainflow_dag");

/// Grainscript Media Workflow Parser.
pub const MediaWorkflowParser = struct {
    allocator: std.mem.Allocator,

    // Bounded: Max workflow source length (explicit limit)
    pub const MAX_WORKFLOW_SOURCE_LEN: u32 = 1_048_576; // 1 MB

    // Bounded: Max tokens per workflow (explicit limit)
    pub const MAX_TOKENS: u32 = 10_000;

    // Bounded: Max workflow nodes (explicit limit)
    pub const MAX_WORKFLOW_NODES: u32 = 1000;

    /// Token type for simple lexing.
    pub const TokenType = enum(u8) {
        identifier, // load_image, crop, resize, etc.
        string_literal, // "image.jpg"
        number, // 100, 200, etc.
        arrow, // ->
        comma, // ,
        paren_open, // (
        paren_close, // )
        brace_open, // {
        brace_close, // }
        equals, // =
        semicolon, // ;
        eof, // End of file
    };

    /// Token structure.
    pub const Token = struct {
        token_type: TokenType,
        value: []const u8,
        start: u32,
        end: u32,
    };

    /// Workflow operation type.
    pub const WorkflowOperation = enum(u8) {
        load_image, // load_image("path")
        crop, // crop(image, x, y, width, height)
        resize, // resize(image, width, height)
        filter, // filter(image, "preset") or filter(image, filter_type)
        save, // save(image, "path")
        workflow, // workflow definition
        let, // let binding
    };

    /// Parsed workflow operation.
    pub const ParsedOperation = struct {
        operation: WorkflowOperation,
        args: std.ArrayList([]const u8),
        result_var: ?[]const u8, // Variable name if result is stored
    };

    /// Initialize parser.
    pub fn init(allocator: std.mem.Allocator) MediaWorkflowParser {
        // Assert: Allocator must be valid
        std.debug.assert(allocator.ptr != null);

        return MediaWorkflowParser{
            .allocator = allocator,
        };
    }

    /// Simple tokenizer for media workflow DSL.
    fn tokenize(
        self: *MediaWorkflowParser,
        source: []const u8,
    ) !std.ArrayList(Token) {
        // Assert: Source must be valid
        std.debug.assert(source.len > 0);
        std.debug.assert(source.len <= MAX_WORKFLOW_SOURCE_LEN);

        var tokens = std.ArrayList(Token).init(self.allocator);
        errdefer tokens.deinit();

        var i: u32 = 0;
        while (i < source.len) {
            // Skip whitespace
            while (i < source.len and std.ascii.isWhitespace(source[i])) {
                i += 1;
            }
            if (i >= source.len) break;

            const start = i;
            const ch = source[i];

            // Single character tokens
            switch (ch) {
                '(' => {
                    try tokens.append(Token{
                        .token_type = .paren_open,
                        .value = source[start..start+1],
                        .start = start,
                        .end = start + 1,
                    });
                    i += 1;
                    continue;
                },
                ')' => {
                    try tokens.append(Token{
                        .token_type = .paren_close,
                        .value = source[start..start+1],
                        .start = start,
                        .end = start + 1,
                    });
                    i += 1;
                    continue;
                },
                '{' => {
                    try tokens.append(Token{
                        .token_type = .brace_open,
                        .value = source[start..start+1],
                        .start = start,
                        .end = start + 1,
                    });
                    i += 1;
                    continue;
                },
                '}' => {
                    try tokens.append(Token{
                        .token_type = .brace_close,
                        .value = source[start..start+1],
                        .start = start,
                        .end = start + 1,
                    });
                    i += 1;
                    continue;
                },
                ',' => {
                    try tokens.append(Token{
                        .token_type = .comma,
                        .value = source[start..start+1],
                        .start = start,
                        .end = start + 1,
                    });
                    i += 1;
                    continue;
                },
                '=' => {
                    try tokens.append(Token{
                        .token_type = .equals,
                        .value = source[start..start+1],
                        .start = start,
                        .end = start + 1,
                    });
                    i += 1;
                    continue;
                },
                ';' => {
                    try tokens.append(Token{
                        .token_type = .semicolon,
                        .value = source[start..start+1],
                        .start = start,
                        .end = start + 1,
                    });
                    i += 1;
                    continue;
                },
                '"' => {
                    // String literal
                    i += 1; // Skip opening quote
                    const string_start = i;
                    while (i < source.len and source[i] != '"') {
                        i += 1;
                    }
                    if (i >= source.len) {
                        return error.UnexpectedEndOfString;
                    }
                    try tokens.append(Token{
                        .token_type = .string_literal,
                        .value = source[string_start..i],
                        .start = string_start,
                        .end = i,
                    });
                    i += 1; // Skip closing quote
                    continue;
                },
                else => {},
            }

            // Identifier or number
            if (std.ascii.isAlphabetic(ch) or ch == '_') {
                // Identifier
                while (i < source.len and (std.ascii.isAlphanumeric(source[i]) or source[i] == '_')) {
                    i += 1;
                }
                try tokens.append(Token{
                    .token_type = .identifier,
                    .value = source[start..i],
                    .start = start,
                    .end = i,
                });
                continue;
            } else if (std.ascii.isDigit(ch)) {
                // Number
                while (i < source.len and std.ascii.isDigit(source[i])) {
                    i += 1;
                }
                try tokens.append(Token{
                    .token_type = .number,
                    .value = source[start..i],
                    .start = start,
                    .end = i,
                });
                continue;
            }

            // Unknown character
            i += 1;
        }

        // Add EOF token
        try tokens.append(Token{
            .token_type = .eof,
            .value = "",
            .start = @as(u32, @intCast(source.len)),
            .end = @as(u32, @intCast(source.len)),
        });

        return tokens;
    }

    /// Parse operation from tokens.
    fn parse_operation(
        self: *MediaWorkflowParser,
        tokens: *std.ArrayList(Token),
        token_idx: *u32,
    ) !?ParsedOperation {
        // Assert: Token index must be valid
        std.debug.assert(token_idx.* < tokens.items.len);

        if (token_idx.* >= tokens.items.len) {
            return null;
        }

        var current_idx = token_idx.*;
        var result_var: ?[]const u8 = null;

        // Check for let binding: "let var_name = operation(...)"
        if (current_idx < tokens.items.len and
            tokens.items[current_idx].token_type == .identifier and
            std.mem.eql(u8, tokens.items[current_idx].value, "let"))
        {
            current_idx += 1;
            if (current_idx >= tokens.items.len or tokens.items[current_idx].token_type != .identifier) {
                return error.ExpectedIdentifier;
            }
            result_var = tokens.items[current_idx].value;
            current_idx += 1;

            if (current_idx >= tokens.items.len or tokens.items[current_idx].token_type != .equals) {
                return error.ExpectedEquals;
            }
            current_idx += 1;
        }

        // Parse operation name
        if (current_idx >= tokens.items.len or tokens.items[current_idx].token_type != .identifier) {
            return null;
        }

        const op_name = tokens.items[current_idx].value;
        current_idx += 1;

        // Map identifier to operation type
        const operation: WorkflowOperation = if (std.mem.eql(u8, op_name, "load_image"))
            .load_image
        else if (std.mem.eql(u8, op_name, "crop"))
            .crop
        else if (std.mem.eql(u8, op_name, "resize"))
            .resize
        else if (std.mem.eql(u8, op_name, "filter") or std.mem.eql(u8, op_name, "apply_filter"))
            .filter
        else if (std.mem.eql(u8, op_name, "save"))
            .save
        else
            return error.UnknownOperation;

        // Parse arguments
        if (current_idx >= tokens.items.len or tokens.items[current_idx].token_type != .paren_open) {
            return error.ExpectedParenOpen;
        }
        current_idx += 1;

        var args = std.ArrayList([]const u8).init(self.allocator);
        errdefer args.deinit();

        // Parse argument list
        while (current_idx < tokens.items.len and tokens.items[current_idx].token_type != .paren_close) {
            const arg_token = tokens.items[current_idx];
            switch (arg_token.token_type) {
                .string_literal, .number, .identifier => {
                    try args.append(arg_token.value);
                    current_idx += 1;
                },
                else => return error.UnexpectedToken,
            }

            // Check for comma
            if (current_idx < tokens.items.len and tokens.items[current_idx].token_type == .comma) {
                current_idx += 1;
            }
        }

        if (current_idx >= tokens.items.len or tokens.items[current_idx].token_type != .paren_close) {
            return error.ExpectedParenClose;
        }
        current_idx += 1;

        token_idx.* = current_idx;

        return ParsedOperation{
            .operation = operation,
            .args = args,
            .result_var = result_var,
        };
    }

    /// Parse Grainscript workflow source into operations.
    pub fn parse_workflow(
        self: *MediaWorkflowParser,
        source: []const u8,
    ) !std.ArrayList(ParsedOperation) {
        // Assert: Source must be non-empty and within bounds
        std.debug.assert(source.len > 0);
        std.debug.assert(source.len <= MAX_WORKFLOW_SOURCE_LEN);

        // Tokenize source
        var tokens = try self.tokenize(source);
        defer tokens.deinit();

        // Assert: Token count must be within bounds
        std.debug.assert(tokens.items.len <= MAX_TOKENS);

        // Parse operations
        var operations = std.ArrayList(ParsedOperation).init(self.allocator);
        errdefer {
            for (operations.items) |*op| {
                op.args.deinit();
            }
            operations.deinit();
        }

        var token_idx: u32 = 0;
        while (token_idx < tokens.items.len) {
            // Skip whitespace tokens (already skipped in tokenize)
            if (tokens.items[token_idx].token_type == .eof) {
                break;
            }

            if (tokens.items[token_idx].token_type == .semicolon) {
                token_idx += 1;
                continue;
            }

            const operation = try self.parse_operation(&tokens, &token_idx);
            if (operation) |op| {
                // Assert: Operation count must be within bounds
                std.debug.assert(operations.items.len < MAX_WORKFLOW_NODES);
                try operations.append(op);
            } else {
                token_idx += 1;
            }
        }

        return operations;
    }

    /// Convert parsed operations to DAG nodes.
    pub fn build_dag_from_operations(
        self: *MediaWorkflowParser,
        dag: *grainflow_dag.DagSynthesis,
        operations: []const ParsedOperation,
        var_to_node: *std.HashMap([]const u8, u32, std.hash_map.StringContext, std.hash_map.defaultMaxLoadPercentage),
    ) !void {
        // Assert: DAG and operations must be valid
        std.debug.assert(dag.dag.nodes_len <= grainflow_dag.DagSynthesis.MAX_WORKFLOW_NODES);

        for (operations) |op| {
            // Determine DAG node type from operation
            const node_type: grainflow_dag.DagSynthesis.MediaNodeType = switch (op.operation) {
                .load_image => .data_source,
                .crop, .resize => .transform,
                .filter => .filter,
                .save => .output,
                else => return error.UnsupportedOperation,
            };

            // Serialize operation args as node data
            var node_data = std.ArrayList(u8).init(self.allocator);
            defer node_data.deinit();

            // Format: "operation_name:arg1:arg2:..."
            try node_data.writer().print("{s}", .{@tagName(op.operation)});
            for (op.args.items) |arg| {
                try node_data.writer().print(":{s}", .{arg});
            }

            // Create DAG node
            const node_id = try dag.create_media_node(node_type, node_data.items);

            // Store variable mapping if result is stored
            if (op.result_var) |var_name| {
                try var_to_node.put(var_name, node_id);
            }

            // Create edges from variable references
            // First arg is usually the input image (variable reference)
            if (op.args.items.len > 0) {
                const first_arg = op.args.items[0];
                if (var_to_node.get(first_arg)) |parent_node_id| {
                    try dag.create_media_edge(
                        parent_node_id,
                        node_id,
                        .data_flow,
                    );
                }
            }
        }
    }
};

