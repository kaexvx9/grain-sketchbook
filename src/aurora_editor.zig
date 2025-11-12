const std = @import("std");
const GrainBuffer = @import("grain_buffer.zig").GrainBuffer;
const GrainAurora = @import("grain_aurora.zig").GrainAurora;
const LspClient = @import("aurora_lsp.zig").LspClient;

/// Aurora code editor: integrates GrainBuffer, GrainAurora, and LSP client.
/// ~<~ Glow Waterbend: editor state flows deterministically through LSP diagnostics.
pub const Editor = struct {
    allocator: std.mem.Allocator,
    buffer: GrainBuffer,
    aurora: GrainAurora,
    lsp: LspClient,
    file_uri: []const u8,
    cursor_line: u32 = 0,
    cursor_char: u32 = 0,

    pub fn init(
        allocator: std.mem.Allocator,
        file_uri: []const u8,
        initial_text: []const u8,
    ) !Editor {
        var buffer = try GrainBuffer.fromSlice(allocator, initial_text);
        errdefer buffer.deinit();
        const aurora = try GrainAurora.init(allocator, initial_text);
        errdefer aurora.deinit();
        const lsp = LspClient.init(allocator);

        return Editor{
            .allocator = allocator,
            .buffer = buffer,
            .aurora = aurora,
            .lsp = lsp,
            .file_uri = file_uri,
        };
    }

    pub fn deinit(self: *Editor) void {
        self.lsp.deinit();
        self.aurora.deinit();
        self.buffer.deinit();
        self.* = undefined;
    }

    /// Start LSP server and initialize for this editor session.
    pub fn startLsp(self: *Editor, zls_path: []const u8, root_uri: []const u8) !void {
        try self.lsp.startServer(zls_path);
        try self.lsp.initialize(root_uri);
    }

    /// Request completions at current cursor position.
    pub fn requestCompletions(self: *Editor) !void {
        _ = try self.lsp.requestCompletion(
            self.file_uri,
            self.cursor_line,
            self.cursor_char,
        );
    }

    /// Insert text at cursor; triggers LSP didChange notification.
    pub fn insert(self: *Editor, text: []const u8) !void {
        const pos = self.cursor_line * 80 + self.cursor_char;
        try self.buffer.insert(pos, text);
        self.cursor_char += @as(u32, @intCast(text.len));
        // TODO: send textDocument/didChange to LSP.
    }

    /// Move cursor; may trigger hover requests.
    pub fn moveCursor(self: *Editor, line: u32, char: u32) void {
        self.cursor_line = line;
        self.cursor_char = char;
        // TODO: request hover info if cursor hovers over symbol.
    }

    /// Render editor view: buffer content + LSP diagnostics overlay.
    pub fn render(self: *Editor) !GrainAurora.RenderResult {
        const text = self.buffer.textSlice();
        return GrainAurora.RenderResult{
            .root = .{ .text = text },
            .readonly_spans = &.{},
        };
    }
};

test "editor lifecycle" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var editor = try Editor.init(
        arena.allocator(),
        "file:///test.zig",
        "const std = @import(\"std\");\n",
    );
    defer editor.deinit();
    try editor.insert("pub fn main() void {}\n");
}

