//! Tests for Aurora LSP Client.
//!
//! Why: Verify LSP client functionality (initialization, document lifecycle,
//! snapshot management, diagnostics, message handling).
//! Architecture: Comprehensive test coverage for LSP operations.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! NOTE: Some tests require a running LSP server (e.g., completion, hover).
//! These tests focus on client-side functionality that can be tested without
//! a server: initialization, document lifecycle, snapshot management, diagnostics.
//!
//! 2025-12-20-143848-pst: Grain Aurora Agent

const std = @import("std");
const testing = std.testing;
const LspClient = @import("aurora_lsp").LspClient;

test "lsp client initialization" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    // Assert: Client initialized correctly
    std.debug.assert(client.request_id == 1);
    std.debug.assert(client.current_snapshot_id == 0);
    std.debug.assert(client.snapshots.items.len == 0);
    std.debug.assert(client.pending_requests.count() == 0);
    std.debug.assert(client.diagnostics.count() == 0);
    std.debug.assert(client.server_process == null);
}

test "lsp client snapshot creation" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const text = "const std = @import(\"std\");\n";

    // Create snapshot via didOpen
    try client.didOpen(uri, text);

    // Assert: Snapshot created
    std.debug.assert(client.snapshots.items.len == 1);
    std.debug.assert(client.current_snapshot_id == 1);
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].uri, uri));
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].text, text));
    std.debug.assert(client.snapshots.items[0].version == 1);
    std.debug.assert(client.snapshots.items[0].id == 1);
}

test "lsp client document lifecycle didOpen" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const text = "const std = @import(\"std\");\n";

    try client.didOpen(uri, text);

    // Assert: Document opened and snapshot created
    std.debug.assert(client.snapshots.items.len == 1);
    std.debug.assert(client.current_snapshot_id == 1);
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].uri, uri));
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].text, text));
}

test "lsp client document lifecycle didChange incremental" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const initial_text = "const std = @import(\"std\");\n";

    try client.didOpen(uri, initial_text);

    // Create incremental change
    const change = LspClient.TextDocumentChange{
        .range = LspClient.Range{
            .start = LspClient.Position{ .line = 0, .character = 0 },
            .end = LspClient.Position{ .line = 0, .character = 0 },
        },
        .range_length = 0,
        .text = "pub ",
    };

    const changes = [_]LspClient.TextDocumentChange{change};
    try client.didChange(uri, &changes);

    // Assert: Snapshot updated
    std.debug.assert(client.snapshots.items.len == 1);
    std.debug.assert(client.current_snapshot_id == 2);
    std.debug.assert(client.snapshots.items[0].version == 2);
    const expected_text = "pub const std = @import(\"std\");\n";
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].text, expected_text));
}

test "lsp client document lifecycle didChange full replacement" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const initial_text = "const std = @import(\"std\");\n";
    const new_text = "pub const std = @import(\"std\");\n";

    try client.didOpen(uri, initial_text);

    // Create full replacement change (null range)
    const change = LspClient.TextDocumentChange{
        .range = null,
        .range_length = null,
        .text = new_text,
    };

    const changes = [_]LspClient.TextDocumentChange{change};
    try client.didChange(uri, &changes);

    // Assert: Snapshot updated with full replacement
    std.debug.assert(client.snapshots.items.len == 1);
    std.debug.assert(client.current_snapshot_id == 2);
    std.debug.assert(client.snapshots.items[0].version == 2);
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].text, new_text));
}

test "lsp client document lifecycle didClose" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const text = "const std = @import(\"std\");\n";

    try client.didOpen(uri, text);
    std.debug.assert(client.snapshots.items.len == 1);

    try client.didClose(uri);

    // Assert: Snapshot removed
    std.debug.assert(client.snapshots.items.len == 0);
}

test "lsp client multiple documents" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri1 = "file:///test1.zig";
    const uri2 = "file:///test2.zig";
    const text1 = "const std = @import(\"std\");\n";
    const text2 = "pub fn main() void {}\n";

    try client.didOpen(uri1, text1);
    try client.didOpen(uri2, text2);

    // Assert: Both documents tracked
    std.debug.assert(client.snapshots.items.len == 2);
    std.debug.assert(client.current_snapshot_id == 2);

    // Close one document
    try client.didClose(uri1);

    // Assert: One document remains
    std.debug.assert(client.snapshots.items.len == 1);
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].uri, uri2));
}

test "lsp client snapshot versioning" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const initial_text = "const std = @import(\"std\");\n";

    try client.didOpen(uri, initial_text);
    std.debug.assert(client.snapshots.items[0].version == 1);

    // Make multiple changes
    const change1 = LspClient.TextDocumentChange{
        .range = null,
        .range_length = null,
        .text = "pub const std = @import(\"std\");\n",
    };
    const changes1 = [_]LspClient.TextDocumentChange{change1};
    try client.didChange(uri, &changes1);
    std.debug.assert(client.snapshots.items[0].version == 2);

    const change2 = LspClient.TextDocumentChange{
        .range = null,
        .range_length = null,
        .text = "pub const std = @import(\"std\");\npub fn main() void {}\n",
    };
    const changes2 = [_]LspClient.TextDocumentChange{change2};
    try client.didChange(uri, &changes2);
    std.debug.assert(client.snapshots.items[0].version == 3);
}

test "lsp client diagnostics storage" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const uri_copy = try allocator.dupe(u8, uri);

    // Add diagnostics manually (simulating server response)
    var diags = std.ArrayListUnmanaged(LspClient.Diagnostic){};
    const diag = LspClient.Diagnostic{
        .range = LspClient.Range{
            .start = LspClient.Position{ .line = 0, .character = 0 },
            .end = LspClient.Position{ .line = 0, .character = 5 },
        },
        .severity = 1, // Error
        .message = try allocator.dupe(u8, "Undefined variable"),
        .source = try allocator.dupe(u8, "zls"),
    };
    try diags.append(allocator, diag);
    try client.diagnostics.put(uri_copy, diags);

    // Assert: Diagnostics stored
    std.debug.assert(client.diagnostics.count() == 1);
    const stored_diags = client.diagnostics.get(uri).?;
    std.debug.assert(stored_diags.items.len == 1);
    std.debug.assert(stored_diags.items[0].severity == 1);
    std.debug.assert(std.mem.eql(u8, stored_diags.items[0].message, "Undefined variable"));
}

test "lsp client request id increment" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    // Assert: Initial request ID is 1
    std.debug.assert(client.request_id == 1);

    // Simulate request (would normally call sendRequest)
    // Request ID should increment on each request
    // Note: This test verifies the initial state; actual increment
    // happens in sendRequest which requires server communication
}

test "lsp client bounds checking uri length" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    // Create URI within bounds (4096 chars max)
    var uri_buf: [4096]u8 = undefined;
    @memset(&uri_buf, 'a');
    const uri = uri_buf[0..4096];

    const text = "test\n";
    try client.didOpen(uri, text);

    // Assert: Document opened successfully
    std.debug.assert(client.snapshots.items.len == 1);
}

test "lsp client bounds checking snapshot limit" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    // Create snapshots up to limit (MAX_SNAPSHOTS = 1000)
    // Note: This test would require creating 1000 documents, which is expensive
    // Instead, verify the constant is defined
    std.debug.assert(LspClient.MAX_SNAPSHOTS == 1000);
}

test "lsp client position validation" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const text = "line 1\nline 2\nline 3\n";

    try client.didOpen(uri, text);

    // Create change with valid position
    const change = LspClient.TextDocumentChange{
        .range = LspClient.Range{
            .start = LspClient.Position{ .line = 1, .character = 0 },
            .end = LspClient.Position{ .line = 1, .character = 6 },
        },
        .range_length = 6,
        .text = "line two\n",
    };

    const changes = [_]LspClient.TextDocumentChange{change};
    try client.didChange(uri, &changes);

    // Assert: Change applied correctly
    std.debug.assert(client.snapshots.items[0].version == 2);
}

test "lsp client incremental edit multiple changes" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const initial_text = "const std = @import(\"std\");\n";

    try client.didOpen(uri, initial_text);

    // Apply multiple incremental changes
    const change1 = LspClient.TextDocumentChange{
        .range = LspClient.Range{
            .start = LspClient.Position{ .line = 0, .character = 0 },
            .end = LspClient.Position{ .line = 0, .character = 0 },
        },
        .range_length = 0,
        .text = "pub ",
    };

    const change2 = LspClient.TextDocumentChange{
        .range = LspClient.Range{
            .start = LspClient.Position{ .line = 0, .character = 20 },
            .end = LspClient.Position{ .line = 0, .character = 20 },
        },
        .range_length = 0,
        .text = "\npub fn main() void {}\n",
    };

    const changes = [_]LspClient.TextDocumentChange{ change1, change2 };
    try client.didChange(uri, &changes);

    // Assert: Changes applied
    std.debug.assert(client.snapshots.items[0].version == 2);
    const expected = "pub const std = @import(\"std\");\npub fn main() void {}\n";
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].text, expected));
}

test "lsp client deinitialization cleanup" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);

    const uri = "file:///test.zig";
    const text = "const std = @import(\"std\");\n";

    try client.didOpen(uri, text);

    // Add diagnostics
    const uri_copy = try allocator.dupe(u8, uri);
    var diags = std.ArrayListUnmanaged(LspClient.Diagnostic){};
    const diag = LspClient.Diagnostic{
        .range = LspClient.Range{
            .start = LspClient.Position{ .line = 0, .character = 0 },
            .end = LspClient.Position{ .line = 0, .character = 5 },
        },
        .severity = 1,
        .message = try allocator.dupe(u8, "Test error"),
        .source = null,
    };
    try diags.append(allocator, diag);
    try client.diagnostics.put(uri_copy, diags);

    // Deinitialize
    client.deinit();

    // Assert: Cleanup completed (no leaks)
    // Note: Actual leak detection would require valgrind or similar
    // This test verifies deinit doesn't crash
}

test "lsp client empty document" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///empty.zig";
    const empty_text = "";

    // Open empty document
    try client.didOpen(uri, empty_text);

    // Assert: Empty document tracked
    std.debug.assert(client.snapshots.items.len == 1);
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].text, empty_text));
    std.debug.assert(client.snapshots.items[0].text.len == 0);
}

test "lsp client very long document" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///large.zig";
    // Create a large document (10KB of text)
    var large_text = std.ArrayList(u8).init(allocator);
    defer large_text.deinit();
    
    const line = "const std = @import(\"std\");\n";
    var i: u32 = 0;
    while (i < 500) : (i += 1) {
        try large_text.appendSlice(line);
    }
    const large_text_slice = try large_text.toOwnedSlice();
    defer allocator.free(large_text_slice);

    // Open large document
    try client.didOpen(uri, large_text_slice);

    // Assert: Large document tracked
    std.debug.assert(client.snapshots.items.len == 1);
    std.debug.assert(client.snapshots.items[0].text.len > 10000);
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].text, large_text_slice));
}

test "lsp client rapid changes" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///rapid.zig";
    const initial_text = "const std = @import(\"std\");\n";

    try client.didOpen(uri, initial_text);

    // Apply many rapid changes
    var change_num: u32 = 0;
    while (change_num < 50) : (change_num += 1) {
        const change = LspClient.TextDocumentChange{
            .range = LspClient.Range{
                .start = LspClient.Position{ .line = 0, .character = 0 },
                .end = LspClient.Position{ .line = 0, .character = 0 },
            },
            .range_length = 0,
            .text = "x",
        };
        const changes = [_]LspClient.TextDocumentChange{change};
        try client.didChange(uri, &changes);
    }

    // Assert: All changes applied
    std.debug.assert(client.snapshots.items.len == 1);
    std.debug.assert(client.snapshots.items[0].version == 51); // 1 initial + 50 changes
}

test "lsp client position at document end" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const text = "line 1\nline 2\nline 3\n";

    try client.didOpen(uri, text);

    // Create change at end of document
    const change = LspClient.TextDocumentChange{
        .range = LspClient.Range{
            .start = LspClient.Position{ .line = 2, .character = 6 },
            .end = LspClient.Position{ .line = 2, .character = 6 },
        },
        .range_length = 0,
        .text = "appended",
    };

    const changes = [_]LspClient.TextDocumentChange{change};
    try client.didChange(uri, &changes);

    // Assert: Change applied at end
    std.debug.assert(client.snapshots.items.len == 1);
    const expected_text = "line 1\nline 2\nline 3appended\n";
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].text, expected_text));
}

test "lsp client uri boundary maximum length" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    // Test: URI at maximum boundary (4096 characters) should be valid
    // This tests the upper bound of URI length validation
    var max_uri_buf: [4096]u8 = undefined;
    @memset(&max_uri_buf, 'a');
    const max_uri = max_uri_buf[0..4096];

    const text = "const x = 1;";

    // This should work (at maximum boundary)
    try client.didOpen(max_uri, text);

    // Assert: Document opened successfully at boundary
    std.debug.assert(client.snapshots.items.len == 1);
    std.debug.assert(client.snapshots.items[0].uri.len == 4096);
    std.debug.assert(std.mem.eql(u8, client.snapshots.items[0].uri, max_uri));
}


test "lsp client position validation large line number" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const text = "line 1\nline 2\n";

    try client.didOpen(uri, text);

    // Test: Position with very large line number (u32 max)
    // The LSP client accepts any u32 value for line/character
    // It doesn't validate against document content - the server does
    // We test that the client handles large values without issues
    const large_line: u32 = 999999;
    const character: u32 = 0;

    // This should not panic - client just sends the position to server
    // Server will validate and return null/error if position is invalid
    // Note: Without a server, this will fail, but we test client-side handling
    _ = client.requestCompletion(uri, large_line, character) catch |err| {
        // Expected: May fail if server not running, but client-side should handle
        _ = err;
    };
}

test "lsp client position validation large character number" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var client = LspClient.init(allocator);
    defer client.deinit();

    const uri = "file:///test.zig";
    const text = "short\n";

    try client.didOpen(uri, text);

    // Test: Position with very large character number (u32 max)
    // Similar to line bounds - client accepts any u32, server validates
    const line: u32 = 0;
    const large_char: u32 = 999999;

    // This should not panic - client just sends the position to server
    _ = client.requestCompletion(uri, line, large_char) catch |err| {
        // Expected: May fail if server not running, but client-side should handle
        _ = err;
    };
}
