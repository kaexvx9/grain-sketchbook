//! Grain Core WebSocket: WebSocket protocol support for real-time communication.
//!
//! Why: Provide WebSocket support for Silo Agent and Carry Agent (livestream coordination).
//! Architecture: WebSocket handshake, frame parsing/generation, connection management.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const api_server = @import("api_server.zig");
const websocket_errors = @import("websocket_errors.zig");

// Bounded: Max WebSocket connections.
pub const MAX_WEBSOCKET_CONNECTIONS: u32 = 128;

// Default timeout values (milliseconds).
pub const DEFAULT_CONNECT_TIMEOUT_MS: u32 = 10000; // 10 seconds
pub const DEFAULT_MESSAGE_TIMEOUT_MS: u32 = 5000; // 5 seconds

// Bounded: Max WebSocket frame size (64KB).
pub const MAX_FRAME_SIZE: u32 = 65536;

// Bounded: Max WebSocket message size (64KB).
pub const MAX_MESSAGE_SIZE: u32 = 65536;

// Bounded: Max WebSocket key length (base64 encoded).
pub const MAX_WEBSOCKET_KEY_LEN: u32 = 32;

// Bounded: Max WebSocket accept length (base64 encoded).
pub const MAX_WEBSOCKET_ACCEPT_LEN: u32 = 32;

// WebSocket frame opcode.
pub const FrameOpcode = enum(u4) {
    continuation = 0x0,
    text = 0x1,
    binary = 0x2,
    close = 0x8,
    ping = 0x9,
    pong = 0xA,
};

// WebSocket frame flags.
pub const FrameFlags = struct {
    fin: bool,
    rsv1: bool,
    rsv2: bool,
    rsv3: bool,
    opcode: FrameOpcode,
    masked: bool,
    payload_len: u64,
    mask_key: [4]u8,
};

// WebSocket connection state.
pub const ConnectionState = enum(u8) {
    connecting,
    open,
    closing,
    closed,
};

// WebSocket connection.
pub const WebSocketConnection = struct {
    connection_id: u32,
    state: ConnectionState,
    socket_fd: u32,
    created_at: u64,
    last_activity: u64,
    path: [api_server.MAX_PATH_LEN]u8,
    path_len: u32,
    subprotocol: [64]u8,
    subprotocol_len: u32,
    active: bool,

    pub fn init(connection_id: u32, socket_fd: u32) WebSocketConnection {
        std.debug.assert(connection_id > 0);
        std.debug.assert(socket_fd > 0);
        var conn = WebSocketConnection{
            .connection_id = connection_id,
            .state = ConnectionState.connecting,
            .socket_fd = socket_fd,
            .created_at = 0,
            .last_activity = 0,
            .connect_timeout_ms = DEFAULT_CONNECT_TIMEOUT_MS,
            .message_timeout_ms = DEFAULT_MESSAGE_TIMEOUT_MS,
            .path = undefined,
            .path_len = 0,
            .subprotocol = undefined,
            .subprotocol_len = 0,
            .active = false,
        };
        var i: u32 = 0;
        while (i < api_server.MAX_PATH_LEN) : (i += 1) {
            conn.path[i] = 0;
        }
        i = 0;
        while (i < 64) : (i += 1) {
            conn.subprotocol[i] = 0;
        }
        std.debug.assert(conn.connection_id == connection_id);
        std.debug.assert(!conn.active);
        return conn;
    }

    // Set connection timeout.
    pub fn set_connect_timeout(self: *WebSocketConnection, timeout_ms: ?u32) void {
        std.debug.assert(self.connection_id > 0);
        if (timeout_ms) |timeout| {
            self.connect_timeout_ms = timeout;
            std.debug.assert(self.connect_timeout_ms > 0);
        } else {
            self.connect_timeout_ms = DEFAULT_CONNECT_TIMEOUT_MS;
            std.debug.assert(self.connect_timeout_ms == DEFAULT_CONNECT_TIMEOUT_MS);
        }
    }

    // Set message timeout.
    pub fn set_message_timeout(self: *WebSocketConnection, timeout_ms: ?u32) void {
        std.debug.assert(self.connection_id > 0);
        if (timeout_ms) |timeout| {
            self.message_timeout_ms = timeout;
            std.debug.assert(self.message_timeout_ms > 0);
        } else {
            self.message_timeout_ms = DEFAULT_MESSAGE_TIMEOUT_MS;
            std.debug.assert(self.message_timeout_ms == DEFAULT_MESSAGE_TIMEOUT_MS);
        }
    }

    // Check if connection has timed out.
    pub fn is_connect_timed_out(self: *const WebSocketConnection, current_time: u64) bool {
        std.debug.assert(self.connection_id > 0);
        if (self.created_at == 0) {
            return false;
        }
        if (self.state != ConnectionState.connecting) {
            return false;
        }
        std.debug.assert(current_time >= self.created_at);
        const elapsed_ms = (current_time - self.created_at) / 1000000;
        const timed_out = elapsed_ms > self.connect_timeout_ms;
        return timed_out;
    }

    // Check if message operation has timed out.
    pub fn is_message_timed_out(self: *const WebSocketConnection, current_time: u64) bool {
        std.debug.assert(self.connection_id > 0);
        if (self.last_activity == 0) {
            return false;
        }
        std.debug.assert(current_time >= self.last_activity);
        const elapsed_ms = (current_time - self.last_activity) / 1000000;
        const timed_out = elapsed_ms > self.message_timeout_ms;
        return timed_out;
    }
};

// WebSocket frame.
pub const WebSocketFrame = struct {
    flags: FrameFlags,
    payload: [MAX_FRAME_SIZE]u8,
    payload_len: u32,

    pub fn init() WebSocketFrame {
        var frame = WebSocketFrame{
            .flags = FrameFlags{
                .fin = false,
                .rsv1 = false,
                .rsv2 = false,
                .rsv3 = false,
                .opcode = FrameOpcode.text,
                .masked = false,
                .payload_len = 0,
                .mask_key = undefined,
            },
            .payload = undefined,
            .payload_len = 0,
        };
        var i: u32 = 0;
        while (i < MAX_FRAME_SIZE) : (i += 1) {
            frame.payload[i] = 0;
        }
        std.debug.assert(frame.payload_len == 0);
        std.debug.assert(frame.flags.payload_len == 0);
        return frame;
    }
};

// WebSocket manager: manages WebSocket connections.
pub const WebSocketManager = struct {
    connections: [MAX_WEBSOCKET_CONNECTIONS]WebSocketConnection,
    connections_len: u32,
    next_connection_id: u32,

    pub fn init() WebSocketManager {
        var manager = WebSocketManager{
            .connections = undefined,
            .connections_len = 0,
            .next_connection_id = 1,
        };
        var i: u32 = 0;
        while (i < MAX_WEBSOCKET_CONNECTIONS) : (i += 1) {
            manager.connections[i] = WebSocketConnection.init(0, 0);
        }
        std.debug.assert(manager.connections_len == 0);
        std.debug.assert(manager.next_connection_id > 0);
        return manager;
    }

    // Add WebSocket connection.
    pub fn add_connection(
        self: *WebSocketManager,
        socket_fd: u32,
        connect_timeout_ms: ?u32,
        message_timeout_ms: ?u32,
    ) ?*WebSocketConnection {
        std.debug.assert(socket_fd > 0);
        std.debug.assert(self.connections_len <= MAX_WEBSOCKET_CONNECTIONS);
        if (self.connections_len >= MAX_WEBSOCKET_CONNECTIONS) {
            return null;
        }
        const conn_id = self.next_connection_id;
        self.next_connection_id += 1;
        self.connections[self.connections_len] = WebSocketConnection.init(
            conn_id,
            socket_fd,
        );
        const conn = &self.connections[self.connections_len];
        conn.active = true;
        conn.created_at = std.time.nanoTimestamp();
        conn.last_activity = conn.created_at;
        conn.set_connect_timeout(connect_timeout_ms);
        conn.set_message_timeout(message_timeout_ms);
        self.connections_len += 1;
        std.debug.assert(self.connections_len <= MAX_WEBSOCKET_CONNECTIONS);
        return conn;
    }

    // Remove WebSocket connection.
    pub fn remove_connection(
        self: *WebSocketManager,
        connection_id: u32,
    ) bool {
        std.debug.assert(connection_id > 0);
        std.debug.assert(self.connections_len <= MAX_WEBSOCKET_CONNECTIONS);
        var i: u32 = 0;
        while (i < self.connections_len) : (i += 1) {
            if (self.connections[i].connection_id == connection_id) {
                self.connections[i].active = false;
                self.connections[i].state = ConnectionState.closed;
                var j: u32 = i;
                while (j < self.connections_len - 1) : (j += 1) {
                    self.connections[j] = self.connections[j + 1];
                }
                self.connections_len -= 1;
                std.debug.assert(self.connections_len < MAX_WEBSOCKET_CONNECTIONS);
                return true;
            }
        }
        return false;
    }

    // Find connection by ID.
    pub fn find_connection(
        self: *WebSocketManager,
        connection_id: u32,
    ) ?*WebSocketConnection {
        std.debug.assert(connection_id > 0);
        std.debug.assert(self.connections_len <= MAX_WEBSOCKET_CONNECTIONS);
        var i: u32 = 0;
        while (i < self.connections_len) : (i += 1) {
            if (self.connections[i].connection_id == connection_id) {
                std.debug.assert(self.connections[i].connection_id == connection_id);
                return &self.connections[i];
            }
        }
        return null;
    }

    // Check for timed out connections and mark them as closed.
    pub fn check_timeouts(self: *WebSocketManager, current_time: u64) void {
        std.debug.assert(self.connections_len <= MAX_WEBSOCKET_CONNECTIONS);
        var i: u32 = 0;
        while (i < self.connections_len) : (i += 1) {
            const conn = &self.connections[i];
            if (conn.is_connect_timed_out(current_time)) {
                conn.state = ConnectionState.closed;
                conn.active = false;
                std.debug.assert(conn.state == ConnectionState.closed);
            } else if (conn.is_message_timed_out(current_time)) {
                conn.state = ConnectionState.closing;
                std.debug.assert(conn.state == ConnectionState.closing);
            }
        }
    }
};

// Generate WebSocket accept key from client key.
pub fn generate_websocket_accept(
    client_key: []const u8,
    accept_buf: []u8,
) u32 {
    std.debug.assert(client_key.len > 0);
    std.debug.assert(accept_buf.len >= MAX_WEBSOCKET_ACCEPT_LEN);
    const magic_string = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
    var combined: [MAX_WEBSOCKET_KEY_LEN + 36]u8 = undefined;
    var combined_len: u32 = 0;
    const key_len = @min(client_key.len, MAX_WEBSOCKET_KEY_LEN);
    var i: u32 = 0;
    while (i < key_len) : (i += 1) {
        combined[combined_len] = client_key[i];
        combined_len += 1;
    }
    i = 0;
    while (i < 36) : (i += 1) {
        combined[combined_len] = magic_string[i];
        combined_len += 1;
    }
    var hash: [20]u8 = undefined;
    std.crypto.hash.Sha1.hash(combined[0..combined_len], &hash, .{});
    var base64_buf: [28]u8 = undefined;
    const base64_len = std.base64.standard.Encoder.calcSize(20);
    _ = std.base64.standard.Encoder.encode(&base64_buf, &hash);
    var j: u32 = 0;
    while (j < base64_len and j < accept_buf.len) : (j += 1) {
        accept_buf[j] = base64_buf[j];
    }
    return @intCast(base64_len);
}

// Check if HTTP request is WebSocket upgrade.
pub fn is_websocket_upgrade(request: *api_server.HttpRequest) bool {
    std.debug.assert(request != null);
    const upgrade_header = request.get_header("Upgrade");
    if (upgrade_header == null) {
        return false;
    }
    const upgrade_val = upgrade_header.?;
    if (upgrade_val.len < 9) {
        return false;
    }
    const websocket_str = "websocket";
    var i: u32 = 0;
    var match_count: u32 = 0;
    while (i < upgrade_val.len and match_count < 9) : (i += 1) {
        const c = upgrade_val[i];
        const ws_c = websocket_str[match_count];
        if (c == ws_c or c == (ws_c - 32)) {
            match_count += 1;
        } else {
            match_count = 0;
        }
    }
    const is_upgrade = match_count == 9;
    std.debug.assert(!is_upgrade or upgrade_val.len >= 9);
    return is_upgrade;
}

// Parse WebSocket frame payload length from buffer.
fn parse_payload_length(
    buffer: []const u8,
    initial_len: u64,
    header_len_out: *u32,
) ?u64 {
    std.debug.assert(buffer.len >= 2);
    std.debug.assert(header_len_out != null);
    var payload_len: u64 = initial_len;
    var header_len: u32 = 2;
    if (payload_len == 126) {
        if (buffer.len < 4) {
            return null;
        }
        payload_len = (@as(u64, buffer[2]) << 8) | @as(u64, buffer[3]);
        header_len = 4;
    } else if (payload_len == 127) {
        if (buffer.len < 10) {
            return null;
        }
        payload_len = (@as(u64, buffer[2]) << 56) |
            (@as(u64, buffer[3]) << 48) |
            (@as(u64, buffer[4]) << 40) |
            (@as(u64, buffer[5]) << 32) |
            (@as(u64, buffer[6]) << 24) |
            (@as(u64, buffer[7]) << 16) |
            (@as(u64, buffer[8]) << 8) |
            @as(u64, buffer[9]);
        header_len = 10;
    }
    header_len_out.* = header_len;
    std.debug.assert(header_len_out.* >= 2);
    return payload_len;
}

// Parse WebSocket frame from buffer.
pub fn parse_websocket_frame(
    buffer: []const u8,
    frame: *WebSocketFrame,
) bool {
    std.debug.assert(buffer.len > 0);
    if (buffer.len < 2) {
        return false;
    }
    const byte1 = buffer[0];
    const byte2 = buffer[1];
    frame.flags.fin = (byte1 & 0x80) != 0;
    frame.flags.rsv1 = (byte1 & 0x40) != 0;
    frame.flags.rsv2 = (byte1 & 0x20) != 0;
    frame.flags.rsv3 = (byte1 & 0x10) != 0;
    const opcode_val = @as(u4, @truncate(byte1 & 0x0F));
    frame.flags.opcode = @enumFromInt(opcode_val);
    frame.flags.masked = (byte2 & 0x80) != 0;
    const initial_len = @as(u64, byte2 & 0x7F);
    var header_len: u32 = 0;
    const payload_len_opt = parse_payload_length(buffer, initial_len, &header_len);
    if (payload_len_opt == null) {
        return false;
    }
    const payload_len = payload_len_opt.?;
    if (payload_len > MAX_FRAME_SIZE) {
        return false;
    }
    frame.flags.payload_len = payload_len;
    if (frame.flags.masked) {
        if (buffer.len < header_len + 4) {
            return false;
        }
        var i: u32 = 0;
        while (i < 4) : (i += 1) {
            frame.flags.mask_key[i] = buffer[header_len + i];
        }
        header_len += 4;
    }
    if (buffer.len < header_len + payload_len) {
        return false;
    }
    const payload_start = header_len;
    var i: u32 = 0;
    while (i < payload_len) : (i += 1) {
        if (frame.flags.masked) {
            frame.payload[i] = buffer[payload_start + i] ^
                frame.flags.mask_key[i % 4];
        } else {
            frame.payload[i] = buffer[payload_start + i];
        }
    }
    frame.payload_len = @intCast(payload_len);
    std.debug.assert(frame.payload_len <= MAX_FRAME_SIZE);
    return true;
}

// Write WebSocket frame payload length to buffer.
fn write_payload_length(
    buffer: []u8,
    offset: *u32,
    payload_len: u32,
    masked: bool,
) void {
    std.debug.assert(buffer.len > offset.*);
    std.debug.assert(offset.* < buffer.len);
    var byte2: u8 = 0;
    if (masked) {
        byte2 |= 0x80;
    }
    const initial_offset = offset.*;
    if (payload_len < 126) {
        byte2 |= @as(u8, @truncate(payload_len));
        buffer[offset.*] = byte2;
        offset.* += 1;
    } else if (payload_len < 65536) {
        byte2 |= 126;
        buffer[offset.*] = byte2;
        offset.* += 1;
        buffer[offset.*] = @as(u8, @truncate(payload_len >> 8));
        offset.* += 1;
        buffer[offset.*] = @as(u8, @truncate(payload_len));
        offset.* += 1;
    } else {
        byte2 |= 127;
        buffer[offset.*] = byte2;
        offset.* += 1;
        var i: u32 = 0;
        while (i < 8) : (i += 1) {
            const byte_idx: u32 = 7 - i;
            const shift_amt: u6 = @intCast(byte_idx * 8);
            buffer[offset.*] = @as(u8, @truncate(payload_len >> shift_amt));
            offset.* += 1;
        }
    }
    std.debug.assert(offset.* > initial_offset);
}

// Generate WebSocket frame to buffer.
pub fn generate_websocket_frame(
    frame: *const WebSocketFrame,
    buffer: []u8,
) u32 {
    std.debug.assert(buffer.len >= MAX_FRAME_SIZE + 14);
    std.debug.assert(frame.payload_len <= MAX_FRAME_SIZE);
    var offset: u32 = 0;
    var byte1: u8 = 0;
    if (frame.flags.fin) {
        byte1 |= 0x80;
    }
    if (frame.flags.rsv1) {
        byte1 |= 0x40;
    }
    if (frame.flags.rsv2) {
        byte1 |= 0x20;
    }
    if (frame.flags.rsv3) {
        byte1 |= 0x10;
    }
    byte1 |= @intFromEnum(frame.flags.opcode);
    buffer[offset] = byte1;
    offset += 1;
    write_payload_length(buffer, &offset, frame.payload_len, frame.flags.masked);
    if (frame.flags.masked) {
        var i: u32 = 0;
        while (i < 4) : (i += 1) {
            buffer[offset] = frame.flags.mask_key[i];
            offset += 1;
        }
    }
    const payload_len = frame.payload_len;
    var i: u32 = 0;
    while (i < payload_len) : (i += 1) {
        if (frame.flags.masked) {
            buffer[offset] = frame.payload[i] ^ frame.flags.mask_key[i % 4];
        } else {
            buffer[offset] = frame.payload[i];
        }
        offset += 1;
    }
    std.debug.assert(offset <= buffer.len);
    return offset;
}
