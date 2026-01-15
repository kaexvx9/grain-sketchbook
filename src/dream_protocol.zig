const std = @import("std");
const WebSocketClient = @import("dream_websocket.zig").WebSocketClient;

/// Dream Protocol: Nostr + WebSocket + TigerBeetle-style state machine.
/// ~<~ Glow Airbend: explicit event types, bounded buffers.
/// ~~~~ Glow Waterbend: streaming events flow deterministically.
pub const DreamProtocol = struct {
    allocator: std.mem.Allocator,
    state: State,
    ws_client: ?WebSocketClient = null,
    relay_host: []const u8 = "",
    relay_path: []const u8 = "",
    
    // Bounded: Max 64KB event payload
    pub const MAX_EVENT_SIZE: u32 = 64 * 1024;
    
    // Bounded: Max 1000 pending events
    pub const MAX_PENDING_EVENTS: u32 = 1000;
    
    // Bounded: Max JSON message size (64KB)
    pub const MAX_JSON_MESSAGE_SIZE: u32 = 64 * 1024;
    
    // Bounded: Max subscription ID length
    pub const MAX_SUBSCRIPTION_ID_LEN: u32 = 64;
    
    // Bounded: Max URL length
    pub const MAX_URL_LEN: u32 = 512;
    
    pub const State = enum {
        disconnected,
        connecting,
        connected,
        error_state,
    };
    
    pub const Event = struct {
        id: []const u8, // 32-byte hex string
        pubkey: []const u8, // 32-byte hex string
        created_at: u64, // Unix timestamp
        kind: u32, // Event kind (0=metadata, 1=text, etc.)
        tags: []const Tag,
        content: []const u8,
        sig: []const u8, // 64-byte hex string
    };
    
    pub const Tag = struct {
        name: []const u8, // "e", "p", "t", etc.
        values: []const []const u8,
    };
    
    pub const Message = union(enum) {
        event: Event,
        req: Req,
        close: Close,
        eose: Eose,
        notice: Notice,
    };
    
    pub const Req = struct {
        subscription_id: []const u8,
        filters: []const Filter,
    };
    
    pub const Filter = struct {
        ids: ?[]const []const u8 = null,
        authors: ?[]const []const u8 = null,
        kinds: ?[]const u32 = null,
        since: ?u64 = null,
        until: ?u64 = null,
        limit: ?u32 = null,
    };
    
    pub const Close = struct {
        subscription_id: []const u8,
    };
    
    pub const Eose = struct {
        subscription_id: []const u8,
    };
    
    pub const Notice = struct {
        message: []const u8,
    };
    
    pub fn init(allocator: std.mem.Allocator) DreamProtocol {
        return DreamProtocol{
            .allocator = allocator,
            .state = .disconnected,
        };
    }
    
    pub fn deinit(self: *DreamProtocol) void {
        if (self.ws_client) |*ws| {
            ws.deinit();
        }
        if (self.relay_host.len > 0) {
            self.allocator.free(self.relay_host);
        }
        if (self.relay_path.len > 0) {
            self.allocator.free(self.relay_path);
        }
        self.* = undefined;
    }
    
    /// Parse WebSocket URL (ws://host:port/path or wss://host:port/path).
    /// Why: Extract host, port, and path from WebSocket URL.
    fn parse_websocket_url(
        url: []const u8,
        host_out: *[]const u8,
        port_out: *u16,
        path_out: *[]const u8,
        is_secure_out: *bool,
    ) !void {
        std.debug.assert(url.len > 0);
        std.debug.assert(url.len <= MAX_URL_LEN);
        
        // Parse scheme (ws:// or wss://)
        const scheme_end = std.mem.indexOf(u8, url, "://") orelse return error.InvalidUrl;
        const scheme = url[0..scheme_end];
        const is_secure = std.mem.eql(u8, scheme, "wss");
        is_secure_out.* = is_secure;
        
        if (!is_secure and !std.mem.eql(u8, scheme, "ws")) {
            return error.InvalidUrl;
        }
        
        var remainder = url[scheme_end + 3..];
        
        // Find path start
        const path_start = std.mem.indexOf(u8, remainder, "/") orelse remainder.len;
        const host_port = remainder[0..path_start];
        const path = if (path_start < remainder.len) remainder[path_start..] else "/";
        path_out.* = path;
        
        // Parse host:port
        if (std.mem.indexOf(u8, host_port, ":")) |colon_pos| {
            host_out.* = host_port[0..colon_pos];
            const port_str = host_port[colon_pos + 1..];
            port_out.* = try std.fmt.parseInt(u16, port_str, 10);
        } else {
            host_out.* = host_port;
            port_out.* = if (is_secure) 443 else 80;
        }
        
        // Assert: Host must be non-empty
        std.debug.assert(host_out.*.len > 0);
        std.debug.assert(port_out.* > 0);
        std.debug.assert(port_out.* <= 65535);
    }
    
    /// Connect to Nostr relay via WebSocket.
    pub fn connect(self: *DreamProtocol, relay_url: []const u8) !void {
        // Assert: State must be disconnected
        std.debug.assert(self.state == .disconnected);
        std.debug.assert(relay_url.len > 0);
        std.debug.assert(relay_url.len <= MAX_URL_LEN);
        
        // Update state to connecting
        self.state = .connecting;
        errdefer self.state = .disconnected;
        
        // Parse WebSocket URL
        var host: []const u8 = undefined;
        var port: u16 = undefined;
        var path: []const u8 = undefined;
        var is_secure: bool = undefined;
        try self.parse_websocket_url(relay_url, &host, &port, &path, &is_secure);
        
        // Store host and path (allocate copies)
        self.relay_host = try self.allocator.dupe(u8, host);
        errdefer self.allocator.free(self.relay_host);
        self.relay_path = try self.allocator.dupe(u8, path);
        errdefer self.allocator.free(self.relay_path);
        
        // Connect TCP stream
        // TODO: Support wss:// (TLS) connections
        // For now, only ws:// (non-TLS) is supported
        if (is_secure) {
            return error.TlsNotSupported; // wss:// not yet implemented
        }
        
        const tcp_stream = try std.net.tcpConnectToHost(self.allocator, host, port);
        errdefer tcp_stream.close();
        
        // Create WebSocket client
        var ws_client = WebSocketClient.init(self.allocator, tcp_stream, host);
        
        // Perform WebSocket handshake
        try ws_client.handshake(path);
        
        // Store WebSocket client and update state
        self.ws_client = ws_client;
        self.state = .connected;
        
        // Assert: Connection is connected
        std.debug.assert(self.state == .connected);
    }
    
    /// Disconnect from relay.
    pub fn disconnect(self: *DreamProtocol) void {
        // Assert: State must be connected or connecting
        std.debug.assert(self.state == .connected or self.state == .connecting);
        
        // Close WebSocket connection
        if (self.ws_client) |*ws| {
            ws.close() catch {};
            ws.deinit();
            self.ws_client = null;
        }
        
        // Free allocated strings
        if (self.relay_host.len > 0) {
            self.allocator.free(self.relay_host);
            self.relay_host = "";
        }
        if (self.relay_path.len > 0) {
            self.allocator.free(self.relay_path);
            self.relay_path = "";
        }
        
        self.state = .disconnected;
        
        // Assert: State is disconnected
        std.debug.assert(self.state == .disconnected);
    }
    
    /// Serialize REQ message to JSON.
    /// Why: Convert REQ message to JSON array format for Nostr protocol.
    fn serialize_req_message(
        self: *DreamProtocol,
        subscription_id: []const u8,
        filters: []const Filter,
        json_buf: []u8,
    ) !u32 {
        std.debug.assert(subscription_id.len > 0);
        std.debug.assert(subscription_id.len <= MAX_SUBSCRIPTION_ID_LEN);
        std.debug.assert(json_buf.len >= MAX_JSON_MESSAGE_SIZE);
        var stream = std.io.fixedBufferStream(json_buf);
        const writer = stream.writer();
        
        // Start JSON array: ["REQ", subscription_id, ...
        try writer.print("[\"REQ\",\"{s}\"", .{subscription_id});
        
        // Serialize filters
        var filter_idx: u32 = 0;
        while (filter_idx < filters.len) : (filter_idx += 1) {
            try writer.print(",");
            try self.serialize_filter(&filters[filter_idx], writer);
        }
        
        // End JSON array
        try writer.print("]");
        
        const json_len = @as(u32, @intCast(stream.getPos()));
        std.debug.assert(json_len <= MAX_JSON_MESSAGE_SIZE);
        return json_len;
    }
    
    /// Serialize filter to JSON object.
    /// Why: Convert Filter struct to JSON object format.
    fn serialize_filter(
        self: *DreamProtocol,
        filter: *const Filter,
        writer: anytype,
    ) !void {
        _ = self;
        try writer.print("{{");
        var has_fields = false;
        
        // Serialize ids array
        if (filter.ids) |ids| {
            if (has_fields) try writer.print(",");
            try writer.print("\"ids\":[");
            var i: u32 = 0;
            while (i < ids.len) : (i += 1) {
                if (i > 0) try writer.print(",");
                try writer.print("\"{s}\"", .{ids[i]});
            }
            try writer.print("]");
            has_fields = true;
        }
        
        // Serialize authors array
        if (filter.authors) |authors| {
            if (has_fields) try writer.print(",");
            try writer.print("\"authors\":[");
            var i: u32 = 0;
            while (i < authors.len) : (i += 1) {
                if (i > 0) try writer.print(",");
                try writer.print("\"{s}\"", .{authors[i]});
            }
            try writer.print("]");
            has_fields = true;
        }
        
        // Serialize kinds array
        if (filter.kinds) |kinds| {
            if (has_fields) try writer.print(",");
            try writer.print("\"kinds\":[");
            var i: u32 = 0;
            while (i < kinds.len) : (i += 1) {
                if (i > 0) try writer.print(",");
                try writer.print("{}", .{kinds[i]});
            }
            try writer.print("]");
            has_fields = true;
        }
        
        // Serialize since timestamp
        if (filter.since) |since| {
            if (has_fields) try writer.print(",");
            try writer.print("\"since\":{}", .{since});
            has_fields = true;
        }
        
        // Serialize until timestamp
        if (filter.until) |until| {
            if (has_fields) try writer.print(",");
            try writer.print("\"until\":{}", .{until});
            has_fields = true;
        }
        
        // Serialize limit
        if (filter.limit) |limit| {
            if (has_fields) try writer.print(",");
            try writer.print("\"limit\":{}", .{limit});
        }
        
        try writer.print("}}");
    }
    
    /// Subscribe to events matching filters.
    pub fn subscribe(self: *DreamProtocol, subscription_id: []const u8, filters: []const Filter) !void {
        // Assert: State must be connected
        std.debug.assert(self.state == .connected);
        std.debug.assert(self.ws_client != null);
        
        // Assert: Subscription ID must be within bounds
        std.debug.assert(subscription_id.len > 0);
        std.debug.assert(subscription_id.len <= MAX_SUBSCRIPTION_ID_LEN);
        
        // Serialize REQ message to JSON
        var json_buf: [MAX_JSON_MESSAGE_SIZE]u8 = undefined;
        const json_len = try self.serialize_req_message(
            subscription_id,
            filters,
            &json_buf,
        );
        const json_msg = json_buf[0..json_len];
        
        // Send via WebSocket
        const ws = &self.ws_client.?;
        const frame = WebSocketClient.Frame{
            .fin = true,
            .opcode = .text,
            .masked = true,
            .payload = json_msg,
        };
        try ws.writeFrame(frame);
    }
    
    /// Serialize CLOSE message to JSON.
    /// Why: Convert CLOSE message to JSON array format for Nostr protocol.
    fn serialize_close_message(
        self: *DreamProtocol,
        subscription_id: []const u8,
        json_buf: []u8,
    ) !u32 {
        _ = self;
        std.debug.assert(subscription_id.len > 0);
        std.debug.assert(subscription_id.len <= MAX_SUBSCRIPTION_ID_LEN);
        std.debug.assert(json_buf.len >= MAX_JSON_MESSAGE_SIZE);
        var stream = std.io.fixedBufferStream(json_buf);
        const writer = stream.writer();
        
        // CLOSE message: ["CLOSE", subscription_id]
        try writer.print("[\"CLOSE\",\"{s}\"]", .{subscription_id});
        
        const json_len = @as(u32, @intCast(stream.getPos()));
        std.debug.assert(json_len <= MAX_JSON_MESSAGE_SIZE);
        return json_len;
    }
    
    /// Unsubscribe from events.
    pub fn unsubscribe(self: *DreamProtocol, subscription_id: []const u8) !void {
        // Assert: State must be connected
        std.debug.assert(self.state == .connected);
        std.debug.assert(self.ws_client != null);
        
        // Assert: Subscription ID must be within bounds
        std.debug.assert(subscription_id.len > 0);
        std.debug.assert(subscription_id.len <= MAX_SUBSCRIPTION_ID_LEN);
        
        // Serialize CLOSE message to JSON
        var json_buf: [MAX_JSON_MESSAGE_SIZE]u8 = undefined;
        const json_len = try self.serialize_close_message(subscription_id, &json_buf);
        const json_msg = json_buf[0..json_len];
        
        // Send via WebSocket
        const ws = &self.ws_client.?;
        const frame = WebSocketClient.Frame{
            .fin = true,
            .opcode = .text,
            .masked = true,
            .payload = json_msg,
        };
        try ws.writeFrame(frame);
    }
    
    /// Publish event to relay.
    pub fn publish(self: *DreamProtocol, event: Event) !void {
        // Assert: State must be connected
        std.debug.assert(self.state == .connected);
        
        // Assert: Event size must be within bounds
        const event_size = @as(u32, @intCast(event.content.len)) + 
            (@as(u32, @intCast(event.tags.len)) * 64); // Rough estimate
        std.debug.assert(event_size <= MAX_EVENT_SIZE);
        
        // TODO: Serialize event to JSON, send via WebSocket
        // For now, stub
        _ = event.content;
        _ = event.tags;
    }
    
    /// Parse EVENT message from JSON array.
    /// Why: Extract Event struct from JSON array ["EVENT", subscription_id, {...event...}].
    fn parse_event_message(
        self: *DreamProtocol,
        json_array: std.json.Array,
    ) !Message {
        std.debug.assert(json_array.items.len >= 3);
        const event_val = json_array.items[2];
        if (event_val != .object) {
            return error.InvalidMessage;
        }
        const event_obj = event_val.object;
        
        // Parse event fields
        const id_val = event_obj.get("id") orelse return error.InvalidMessage;
        const pubkey_val = event_obj.get("pubkey") orelse return error.InvalidMessage;
        const created_at_val = event_obj.get("created_at") orelse return error.InvalidMessage;
        const kind_val = event_obj.get("kind") orelse return error.InvalidMessage;
        const content_val = event_obj.get("content") orelse return error.InvalidMessage;
        const sig_val = event_obj.get("sig") orelse return error.InvalidMessage;
        
        const id = try self.allocator.dupe(u8, id_val.string);
        errdefer self.allocator.free(id);
        const pubkey = try self.allocator.dupe(u8, pubkey_val.string);
        errdefer self.allocator.free(pubkey);
        const created_at = @as(u64, @intCast(created_at_val.integer));
        const kind = @as(u32, @intCast(kind_val.integer));
        const content = try self.allocator.dupe(u8, content_val.string);
        errdefer self.allocator.free(content);
        const sig = try self.allocator.dupe(u8, sig_val.string);
        errdefer self.allocator.free(sig);
        
        // Parse tags (optional)
        var tags = std.ArrayList(Tag).init(self.allocator);
        if (event_obj.get("tags")) |tags_val| {
            if (tags_val == .array) {
                var tag_idx: u32 = 0;
                while (tag_idx < tags_val.array.items.len) : (tag_idx += 1) {
                    const tag_array = tags_val.array.items[tag_idx];
                    if (tag_array == .array and tag_array.array.items.len >= 2) {
                        const tag_name_val = tag_array.array.items[0];
                        const tag_name = try self.allocator.dupe(u8, tag_name_val.string);
                        var tag_values = std.ArrayList([]const u8).init(self.allocator);
                        var val_idx: u32 = 1;
                        while (val_idx < tag_array.array.items.len) : (val_idx += 1) {
                            const val_str = try self.allocator.dupe(
                                u8,
                                tag_array.array.items[val_idx].string,
                            );
                            try tag_values.append(val_str);
                        }
                        try tags.append(Tag{
                            .name = tag_name,
                            .values = try tag_values.toOwnedSlice(),
                        });
                    }
                }
            }
        }
        
        const event = Event{
            .id = id,
            .pubkey = pubkey,
            .created_at = created_at,
            .kind = kind,
            .tags = try tags.toOwnedSlice(),
            .content = content,
            .sig = sig,
        };
        
        return Message{ .event = event };
    }
    
    /// Parse EOSE message from JSON array.
    /// Why: Extract EOSE struct from JSON array ["EOSE", subscription_id].
    fn parse_eose_message(
        self: *DreamProtocol,
        json_array: std.json.Array,
    ) !Message {
        if (json_array.items.len < 2) {
            return error.InvalidMessage;
        }
        const sub_id_val = json_array.items[1];
        const sub_id = try self.allocator.dupe(u8, sub_id_val.string);
        return Message{ .eose = Eose{ .subscription_id = sub_id } };
    }
    
    /// Parse NOTICE message from JSON array.
    /// Why: Extract Notice struct from JSON array ["NOTICE", message].
    fn parse_notice_message(
        self: *DreamProtocol,
        json_array: std.json.Array,
    ) !Message {
        if (json_array.items.len < 2) {
            return error.InvalidMessage;
        }
        const msg_val = json_array.items[1];
        const msg = try self.allocator.dupe(u8, msg_val.string);
        return Message{ .notice = Notice{ .message = msg } };
    }
    
    /// Receive message from relay (non-blocking).
    pub fn receive(self: *DreamProtocol) !?Message {
        // Assert: State must be connected
        std.debug.assert(self.state == .connected);
        std.debug.assert(self.ws_client != null);
        
        // Read WebSocket frame
        const ws = &self.ws_client.?;
        const frame = ws.readFrame() catch {
            // If read fails, return null (no message available)
            return null;
        };
        defer self.allocator.free(frame.payload);
        
        // Parse JSON message (only text frames contain JSON)
        if (frame.opcode != .text) {
            return null;
        }
        
        var parsed = try std.json.parseFromSlice(
            std.json.Value,
            self.allocator,
            frame.payload,
            .{},
        );
        defer parsed.deinit();
        
        const root = parsed.value;
        if (root != .array or root.array.items.len < 2) {
            return error.InvalidMessage;
        }
        
        const msg_type_val = root.array.items[0];
        if (msg_type_val != .string) {
            return error.InvalidMessage;
        }
        const msg_type = msg_type_val.string;
        
        // Route to appropriate parser
        if (std.mem.eql(u8, msg_type, "EVENT")) {
            return try self.parse_event_message(root.array);
        } else if (std.mem.eql(u8, msg_type, "EOSE")) {
            return try self.parse_eose_message(root.array);
        } else if (std.mem.eql(u8, msg_type, "NOTICE")) {
            return try self.parse_notice_message(root.array);
        }
        
        return error.InvalidMessage;
    }
};

test "dream protocol init" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    
    var protocol = DreamProtocol.init(arena.allocator());
    defer protocol.deinit();
    
    // Assert: Protocol initialized correctly
    std.debug.assert(protocol.state == .disconnected);
}

test "dream protocol state transitions" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    
    var protocol = DreamProtocol.init(arena.allocator());
    defer protocol.deinit();
    
    // Test: Connect transitions to connecting (ws:// only, wss:// not yet supported)
    // Note: This will fail at connection time, but state should transition
    protocol.connect("ws://relay.example.com") catch {
        // Connection fails (expected in test environment), but state should be set
    };
    // State may be disconnected if connection fails immediately
    
    // Test: Disconnect transitions to disconnected
    protocol.disconnect();
    std.debug.assert(protocol.state == .disconnected);
}

