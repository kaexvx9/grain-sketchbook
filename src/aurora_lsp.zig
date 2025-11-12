const std = @import("std");
const GrainBuffer = @import("grain_buffer.zig").GrainBuffer;

/// LSP client for Aurora IDE: communicates with ZLS (Zig Language Server) via JSON-RPC 2.0.
/// ~<~ Glow Airbend: static allocation for message buffers; process lifecycle explicit.
pub const LspClient = struct {
    allocator: std.mem.Allocator,
    server_process: ?std.process.Child = null,
    request_id: u64 = 1,
    message_buffer: [8192]u8 = undefined,

    pub const Message = struct {
        jsonrpc: []const u8 = "2.0",
        id: ?u64 = null,
        method: ?[]const u8 = null,
        params: ?std.json.Value = null,
        result: ?std.json.Value = null,
        lsp_error: ?LspError = null,
    };

    pub const LspError = struct {
        code: i32,
        message: []const u8,
        data: ?std.json.Value = null,
    };

    pub const CompletionItem = struct {
        label: []const u8,
        kind: ?u32 = null,
        detail: ?[]const u8 = null,
        documentation: ?[]const u8 = null,
    };

    pub const Diagnostic = struct {
        range: Range,
        severity: ?u32 = null,
        message: []const u8,
        source: ?[]const u8 = null,
    };

    pub const Range = struct {
        start: Position,
        end: Position,
    };

    pub const Position = struct {
        line: u32,
        character: u32,
    };

    pub fn init(allocator: std.mem.Allocator) LspClient {
        return LspClient{
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *LspClient) void {
        if (self.server_process) |*proc| {
            _ = proc.kill() catch {};
            _ = proc.wait() catch {};
        }
        self.* = undefined;
    }

    /// Spawn ZLS process: expects `zls` in PATH or use explicit path.
    pub fn startServer(self: *LspClient, zls_path: []const u8) !void {
        if (self.server_process != null) return;

        const argv = [_][]const u8{ zls_path };
        self.server_process = try std.process.Child.init(&argv, self.allocator);
        try self.server_process.?.spawn();
    }

    /// Send initialize request to LSP server.
    pub fn initialize(self: *LspClient, root_uri: []const u8) !void {
        // Stub: full JSON-RPC serialization deferred until we wire up std.json parser.
        _ = root_uri;
        _ = try self.sendRequest("initialize", .{ .null = {} });
    }

    /// Request textDocument/completion at a position.
    pub fn requestCompletion(
        self: *LspClient,
        uri: []const u8,
        line: u32,
        character: u32,
    ) !?[]CompletionItem {
        // Stub: full JSON-RPC serialization deferred.
        _ = uri;
        _ = line;
        _ = character;
        _ = try self.sendRequest("textDocument/completion", .{ .null = {} });
        // TODO: parse completion items from response.result
        return null;
    }

    /// Send a JSON-RPC request; returns response message.
    fn sendRequest(
        self: *LspClient,
        method: []const u8,
        params: std.json.Value,
    ) !Message {
        const id = self.request_id;
        self.request_id += 1;

        const request = Message{
            .id = id,
            .method = method,
            .params = params,
        };

        // TODO: serialize to JSON, write to server stdin, read from stdout.
        _ = self.message_buffer;
        return request;
    }
};

test "lsp client lifecycle" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var client = LspClient.init(arena.allocator());
    defer client.deinit();
    // Stub: don't actually spawn ZLS in tests.
}

