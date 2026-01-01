//! Grain OS DNS Client: DNS query network communication with retry logic.
//!
//! Why: Send DNS queries to DNS servers via UDP with retry and failover support.
//! Architecture: UDP socket communication, DNS server management, retry logic, timeout handling.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const network_stack = @import("network_stack.zig");
const dns_resolver = @import("dns_resolver.zig");
const dns_query = @import("dns_query.zig");

// Bounded: Max DNS servers.
pub const MAX_DNS_SERVERS: u32 = 4;

// Bounded: Default DNS server port.
pub const DNS_SERVER_PORT: u32 = 53;

// Bounded: Max retry attempts per server.
pub const MAX_RETRY_ATTEMPTS: u32 = 3;

// Bounded: DNS query timeout (milliseconds).
pub const DNS_QUERY_TIMEOUT_MS: u64 = 5000;

// DNS client: manages DNS queries and server communication.
pub const DnsClient = struct {
    dns_servers: [MAX_DNS_SERVERS]network_stack.IpAddress,
    dns_servers_len: u32,
    net_stack: *network_stack.NetworkStack,
    current_time_fn: *const fn () u64,
    next_transaction_id: u16,

    pub fn init(
        net_stack: *network_stack.NetworkStack,
        current_time_fn: *const fn () u64,
    ) DnsClient {
        std.debug.assert(net_stack != null);
        std.debug.assert(@intFromPtr(current_time_fn) != 0);
        var client = DnsClient{
            .dns_servers = undefined,
            .dns_servers_len = 0,
            .net_stack = net_stack,
            .current_time_fn = current_time_fn,
            .next_transaction_id = 1,
        };
        var i: u32 = 0;
        while (i < MAX_DNS_SERVERS) : (i += 1) {
            client.dns_servers[i] = network_stack.IpAddress.init_ipv4([4]u8{ 0, 0, 0, 0 }, 0);
        }
        std.debug.assert(client.dns_servers_len == 0);
        std.debug.assert(client.next_transaction_id > 0);
        return client;
    }

    // Add DNS server.
    pub fn add_dns_server(self: *DnsClient, server_address: network_stack.IpAddress) bool {
        std.debug.assert(server_address.port > 0);
        std.debug.assert(server_address.port <= network_stack.MAX_PORT);
        if (self.dns_servers_len >= MAX_DNS_SERVERS) {
            return false;
        }
        self.dns_servers[self.dns_servers_len] = server_address;
        self.dns_servers_len += 1;
        std.debug.assert(self.dns_servers_len <= MAX_DNS_SERVERS);
        return true;
    }

    // Send DNS query and receive response.
    pub fn query(
        self: *DnsClient,
        hostname: []const u8,
        record_type: dns_resolver.DnsRecordType,
        ip_out: []u8,
        ip_len_out: *u32,
    ) bool {
        std.debug.assert(hostname.len > 0);
        std.debug.assert(hostname.len <= dns_resolver.MAX_HOSTNAME_LEN);
        std.debug.assert(ip_out.len >= 16);
        std.debug.assert(ip_len_out != null);
        std.debug.assert(self.dns_servers_len > 0);
        if (self.dns_servers_len == 0) {
            return false;
        }
        const transaction_id = self.next_transaction_id;
        self.next_transaction_id = if (self.next_transaction_id >= 65535) 1 else self.next_transaction_id + 1;
        var query_buf: [dns_query.MAX_DNS_PACKET_SIZE]u8 = undefined;
        const query_len_opt = dns_query.build_dns_query(
            transaction_id,
            hostname,
            record_type,
            &query_buf,
        );
        if (query_len_opt == null) {
            return false;
        }
        const query_len = query_len_opt.?;
        var server_idx: u32 = 0;
        while (server_idx < self.dns_servers_len) : (server_idx += 1) {
            if (self.try_query_server(
                &query_buf,
                query_len,
                transaction_id,
                record_type,
                self.dns_servers[server_idx],
                ip_out,
                ip_len_out,
            )) {
                std.debug.assert(ip_len_out.* > 0);
                return true;
            }
        }
        return false;
    }

    // Try querying a single DNS server with retries.
    fn try_query_server(
        self: *DnsClient,
        query_buf: []const u8,
        query_len: u32,
        transaction_id: u16,
        record_type: dns_resolver.DnsRecordType,
        server_address: network_stack.IpAddress,
        ip_out: []u8,
        ip_len_out: *u32,
    ) bool {
        std.debug.assert(query_len > 0);
        std.debug.assert(query_len <= dns_query.MAX_DNS_PACKET_SIZE);
        std.debug.assert(server_address.port > 0);
        std.debug.assert(ip_out.len >= 16);
        std.debug.assert(ip_len_out != null);
        const socket_id_opt = self.net_stack.create_udp_socket();
        if (socket_id_opt == null) {
            return false;
        }
        const socket_id = socket_id_opt.?;
        defer _ = self.net_stack.close_socket(socket_id);
        if (self.net_stack.get_socket(socket_id)) |socket| {
            socket.remote_address = server_address;
            socket.state = network_stack.SocketState.connected;
        }
        var attempt: u32 = 0;
        while (attempt < MAX_RETRY_ATTEMPTS) : (attempt += 1) {
            var bytes_sent: u32 = 0;
            if (!self.net_stack.send_data(socket_id, query_buf[0..query_len], &bytes_sent)) {
                continue;
            }
            if (bytes_sent != query_len) {
                continue;
            }
            var response_buf: [dns_query.MAX_DNS_PACKET_SIZE]u8 = undefined;
            var response_len: u32 = 0;
            const start_time = self.current_time_fn();
            while (true) {
                const current_time = self.current_time_fn();
                const elapsed_ms = (current_time - start_time) / 1000000;
                if (elapsed_ms > DNS_QUERY_TIMEOUT_MS) {
                    break;
                }
                if (self.net_stack.receive_data(socket_id, &response_buf, &response_len)) {
                    if (response_len > 0) {
                        if (dns_query.parse_dns_response(
                            response_buf[0..response_len],
                            transaction_id,
                            record_type,
                            ip_out,
                            ip_len_out,
                        )) {
                            std.debug.assert(ip_len_out.* > 0);
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    // Get DNS server count.
    pub fn get_server_count(self: *const DnsClient) u32 {
        std.debug.assert(self.dns_servers_len <= MAX_DNS_SERVERS);
        const count = self.dns_servers_len;
        std.debug.assert(count <= MAX_DNS_SERVERS);
        return count;
    }
};
