//! Grain OS Connection Pool: HTTP client connection pooling and reuse.
//!
//! Why: Reuse TCP connections for multiple HTTP requests to same host (performance).
//! Architecture: Connection pool per host:port, keep-alive, idle timeout, lifecycle.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const network_stack = @import("network_stack.zig");

// Bounded: Max connections per host.
pub const MAX_CONNECTIONS_PER_HOST: u32 = 4;

// Bounded: Max total pooled connections.
pub const MAX_POOLED_CONNECTIONS: u32 = 64;

// Bounded: Max hostname length.
pub const MAX_HOSTNAME_LEN: u32 = 255;

// Bounded: Default idle timeout (milliseconds).
pub const DEFAULT_IDLE_TIMEOUT_MS: u64 = 30000; // 30 seconds

// Bounded: Default connection timeout (milliseconds).
pub const DEFAULT_CONNECTION_TIMEOUT_MS: u64 = 10000; // 10 seconds

// Connection state in pool.
pub const PooledConnectionState = enum(u8) {
    idle,
    in_use,
    closing,
    closed,
};

// Pooled connection entry.
pub const PooledConnection = struct {
    socket_id: u32,
    hostname: [MAX_HOSTNAME_LEN]u8,
    hostname_len: u32,
    port: u32,
    state: PooledConnectionState,
    created_at: u64,
    last_used_at: u64,
    use_count: u32,

    pub fn init(
        socket_id: u32,
        hostname: []const u8,
        port: u32,
        current_time: u64,
    ) PooledConnection {
        std.debug.assert(socket_id > 0);
        std.debug.assert(hostname.len > 0);
        std.debug.assert(hostname.len <= MAX_HOSTNAME_LEN);
        std.debug.assert(port > 0);
        std.debug.assert(port <= network_stack.MAX_PORT);
        var conn = PooledConnection{
            .socket_id = socket_id,
            .hostname = undefined,
            .hostname_len = 0,
            .port = port,
            .state = PooledConnectionState.idle,
            .created_at = current_time,
            .last_used_at = current_time,
            .use_count = 0,
        };
        var i: u32 = 0;
        while (i < MAX_HOSTNAME_LEN) : (i += 1) {
            conn.hostname[i] = 0;
        }
        const hostname_len = @min(hostname.len, MAX_HOSTNAME_LEN);
        i = 0;
        while (i < hostname_len) : (i += 1) {
            conn.hostname[i] = hostname[i];
        }
        conn.hostname_len = @as(u32, @intCast(hostname_len));
        std.debug.assert(conn.socket_id > 0);
        std.debug.assert(conn.hostname_len > 0);
        return conn;
    }

    // Check if connection is idle and available.
    pub fn is_idle(self: *const PooledConnection) bool {
        std.debug.assert(self.socket_id > 0);
        return self.state == PooledConnectionState.idle;
    }

    // Check if connection has timed out (idle too long).
    pub fn is_idle_timed_out(
        self: *const PooledConnection,
        current_time: u64,
        idle_timeout_ms: u64,
    ) bool {
        std.debug.assert(self.socket_id > 0);
        std.debug.assert(current_time >= self.last_used_at);
        if (self.state != PooledConnectionState.idle) {
            return false;
        }
        const idle_duration_ms = (current_time - self.last_used_at) / 1000000;
        const timed_out = idle_duration_ms > idle_timeout_ms;
        return timed_out;
    }

    // Mark connection as in use.
    pub fn mark_in_use(self: *PooledConnection, current_time: u64) void {
        std.debug.assert(self.socket_id > 0);
        std.debug.assert(self.state == PooledConnectionState.idle);
        self.state = PooledConnectionState.in_use;
        self.last_used_at = current_time;
        self.use_count += 1;
        std.debug.assert(self.state == PooledConnectionState.in_use);
    }

    // Mark connection as idle (returned to pool).
    pub fn mark_idle(self: *PooledConnection, current_time: u64) void {
        std.debug.assert(self.socket_id > 0);
        std.debug.assert(self.state == PooledConnectionState.in_use);
        self.state = PooledConnectionState.idle;
        self.last_used_at = current_time;
        std.debug.assert(self.state == PooledConnectionState.idle);
    }

    // Mark connection for closing.
    pub fn mark_closing(self: *PooledConnection) void {
        std.debug.assert(self.socket_id > 0);
        self.state = PooledConnectionState.closing;
        std.debug.assert(self.state == PooledConnectionState.closing);
    }
};

// Connection pool manager.
pub const ConnectionPool = struct {
    connections: [MAX_POOLED_CONNECTIONS]?PooledConnection,
    connections_len: u32,
    idle_timeout_ms: u64,
    current_time_fn: *const fn () u64,

    pub fn init(current_time_fn: *const fn () u64) ConnectionPool {
        std.debug.assert(@intFromPtr(current_time_fn) != 0);
        var pool = ConnectionPool{
            .connections = undefined,
            .connections_len = 0,
            .idle_timeout_ms = DEFAULT_IDLE_TIMEOUT_MS,
            .current_time_fn = current_time_fn,
        };
        var i: u32 = 0;
        while (i < MAX_POOLED_CONNECTIONS) : (i += 1) {
            pool.connections[i] = null;
        }
        std.debug.assert(pool.connections_len == 0);
        std.debug.assert(pool.idle_timeout_ms == DEFAULT_IDLE_TIMEOUT_MS);
        return pool;
    }

    // Get or create connection for hostname:port.
    pub fn get_connection(
        self: *ConnectionPool,
        hostname: []const u8,
        port: u32,
        net_stack: *network_stack.NetworkStack,
    ) ?u32 {
        std.debug.assert(hostname.len > 0);
        std.debug.assert(hostname.len <= MAX_HOSTNAME_LEN);
        std.debug.assert(port > 0);
        std.debug.assert(port <= network_stack.MAX_PORT);
        std.debug.assert(net_stack != null);
        const current_time = self.current_time_fn();
        if (self.find_idle_connection(hostname, port)) |conn| {
            conn.mark_in_use(current_time);
            std.debug.assert(conn.socket_id > 0);
            return conn.socket_id;
        }
        if (self.connections_len >= MAX_POOLED_CONNECTIONS) {
            return null;
        }
        const socket_id_opt = net_stack.create_tcp_socket();
        if (socket_id_opt == null) {
            return null;
        }
        const socket_id = socket_id_opt.?;
        var conn = PooledConnection.init(socket_id, hostname, port, current_time);
        conn.mark_in_use(current_time);
        var i: u32 = 0;
        while (i < MAX_POOLED_CONNECTIONS) : (i += 1) {
            if (self.connections[i] == null) {
                self.connections[i] = conn;
                self.connections_len += 1;
                std.debug.assert(self.connections_len <= MAX_POOLED_CONNECTIONS);
                std.debug.assert(conn.socket_id > 0);
                return socket_id;
            }
        }
        return null;
    }

    // Return connection to pool (mark as idle).
    pub fn return_connection(
        self: *ConnectionPool,
        socket_id: u32,
    ) bool {
        std.debug.assert(socket_id > 0);
        const current_time = self.current_time_fn();
        var i: u32 = 0;
        while (i < MAX_POOLED_CONNECTIONS) : (i += 1) {
            if (self.connections[i]) |*conn| {
                if (conn.socket_id == socket_id) {
                    if (conn.state == PooledConnectionState.in_use) {
                        conn.mark_idle(current_time);
                        std.debug.assert(conn.state == PooledConnectionState.idle);
                        return true;
                    }
                }
            }
        }
        return false;
    }

    // Remove connection from pool (close and remove).
    pub fn remove_connection(
        self: *ConnectionPool,
        socket_id: u32,
        net_stack: *network_stack.NetworkStack,
    ) bool {
        std.debug.assert(socket_id > 0);
        std.debug.assert(net_stack != null);
        var i: u32 = 0;
        while (i < MAX_POOLED_CONNECTIONS) : (i += 1) {
            if (self.connections[i]) |*conn| {
                if (conn.socket_id == socket_id) {
                    _ = net_stack.close_socket(socket_id);
                    self.connections[i] = null;
                    self.connections_len -= 1;
                    std.debug.assert(self.connections_len < MAX_POOLED_CONNECTIONS);
                    return true;
                }
            }
        }
        return false;
    }

    // Clean up idle timed-out connections.
    pub fn cleanup_idle_connections(
        self: *ConnectionPool,
        net_stack: *network_stack.NetworkStack,
    ) u32 {
        std.debug.assert(net_stack != null);
        const current_time = self.current_time_fn();
        var removed_count: u32 = 0;
        var i: u32 = 0;
        while (i < MAX_POOLED_CONNECTIONS) : (i += 1) {
            if (self.connections[i]) |*conn| {
                if (conn.is_idle_timed_out(current_time, self.idle_timeout_ms)) {
                    _ = self.remove_connection(conn.socket_id, net_stack);
                    removed_count += 1;
                }
            }
        }
        std.debug.assert(removed_count <= self.connections_len);
        return removed_count;
    }

    // Find idle connection for hostname:port.
    fn find_idle_connection(
        self: *ConnectionPool,
        hostname: []const u8,
        port: u32,
    ) ?*PooledConnection {
        std.debug.assert(hostname.len > 0);
        std.debug.assert(hostname.len <= MAX_HOSTNAME_LEN);
        std.debug.assert(port > 0);
        std.debug.assert(port <= network_stack.MAX_PORT);
        var host_count: u32 = 0;
        var i: u32 = 0;
        while (i < MAX_POOLED_CONNECTIONS) : (i += 1) {
            if (self.connections[i]) |*conn| {
                if (conn.port == port and conn.hostname_len == hostname.len) {
                    var match = true;
                    var j: u32 = 0;
                    while (j < conn.hostname_len) : (j += 1) {
                        if (conn.hostname[j] != hostname[j]) {
                            match = false;
                            break;
                        }
                    }
                    if (match) {
                        host_count += 1;
                        if (conn.is_idle()) {
                            std.debug.assert(conn.socket_id > 0);
                            return conn;
                        }
                    }
                }
            }
        }
        if (host_count >= MAX_CONNECTIONS_PER_HOST) {
            return null;
        }
        return null;
    }

    // Get connection count.
    pub fn get_connection_count(self: *const ConnectionPool) u32 {
        std.debug.assert(self.connections_len <= MAX_POOLED_CONNECTIONS);
        const count = self.connections_len;
        std.debug.assert(count <= MAX_POOLED_CONNECTIONS);
        return count;
    }
};
