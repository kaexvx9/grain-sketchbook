//! Grain Core HTTP Client: HTTP client for making external API requests.
//!
//! Why: Enable agents to make HTTP requests to external APIs (Carry, Silo, etc.).
//! Architecture: HTTP/1.1 client, request building, response parsing, connection management.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const network_stack = @import("network_stack.zig");
const api_server = @import("api_server.zig");
const dns_resolver = @import("dns_resolver.zig");
const http_errors = @import("http_errors.zig");
const connection_pool = @import("connection_pool.zig");
const file_transfer = @import("file_transfer.zig");
const file_mime_type = @import("file_mime_type.zig");
const integrated_file_io = @import("integrated_file_io.zig");
const chunked_transfer = @import("chunked_transfer.zig");

// Bounded: Max concurrent requests.
pub const MAX_CONCURRENT_REQUESTS: u32 = 32;

// Bounded: Max URL length.
pub const MAX_URL_LEN: u32 = 2048;

// Bounded: Max hostname length.
pub const MAX_HOSTNAME_LEN: u32 = 255;

// Default timeout values (milliseconds).
pub const DEFAULT_API_TIMEOUT_MS: u32 = 30000; // 30 seconds
pub const DEFAULT_CONTENT_TIMEOUT_MS: u32 = 60000; // 60 seconds

// Request state.
pub const RequestState = enum(u8) {
    pending,
    connecting,
    sending,
    receiving,
    completed,
    failed,
};

// HTTP client request.
pub const HttpClientRequest = struct {
    request_id: u32,
    method: api_server.HttpMethod,
    url: [MAX_URL_LEN]u8,
    url_len: u32,
    hostname: [MAX_HOSTNAME_LEN]u8,
    hostname_len: u32,
    port: u32,
    path: [api_server.MAX_PATH_LEN]u8,
    path_len: u32,
    headers: [api_server.MAX_HEADERS]api_server.HttpHeader,
    headers_len: u32,
    body: [api_server.MAX_REQUEST_SIZE]u8,
    body_len: u32,
    state: RequestState,
    socket_id: ?u32,
    response: ?api_server.HttpResponse,
    created_at: u64,
    timeout_ms: u32,

    pub fn init(request_id: u32) HttpClientRequest {
        std.debug.assert(request_id > 0);
        var req = HttpClientRequest{
            .request_id = request_id,
            .method = api_server.HttpMethod.get,
            .url = undefined,
            .url_len = 0,
            .hostname = undefined,
            .hostname_len = 0,
            .port = 80,
            .path = undefined,
            .path_len = 0,
            .headers = undefined,
            .headers_len = 0,
            .body = undefined,
            .body_len = 0,
            .state = RequestState.pending,
            .socket_id = null,
            .response = null,
            .created_at = 0,
            .timeout_ms = DEFAULT_API_TIMEOUT_MS,
        };
        var i: u32 = 0;
        while (i < MAX_URL_LEN) : (i += 1) {
            req.url[i] = 0;
        }
        i = 0;
        while (i < MAX_HOSTNAME_LEN) : (i += 1) {
            req.hostname[i] = 0;
        }
        i = 0;
        while (i < api_server.MAX_PATH_LEN) : (i += 1) {
            req.path[i] = 0;
        }
        i = 0;
        while (i < api_server.MAX_REQUEST_SIZE) : (i += 1) {
            req.body[i] = 0;
        }
        std.debug.assert(req.request_id > 0);
        return req;
    }

    pub fn set_url(self: *HttpClientRequest, url: []const u8) bool {
        std.debug.assert(url.len > 0);
        std.debug.assert(url.len <= MAX_URL_LEN);
        const url_len = @min(url.len, MAX_URL_LEN);
        var i: u32 = 0;
        while (i < MAX_URL_LEN) : (i += 1) {
            self.url[i] = 0;
        }
        i = 0;
        while (i < url_len) : (i += 1) {
            self.url[i] = url[i];
        }
        self.url_len = url_len;
        return true;
    }

    pub fn add_header(
        self: *HttpClientRequest,
        name: []const u8,
        value: []const u8,
    ) bool {
        std.debug.assert(name.len > 0);
        std.debug.assert(value.len > 0);
        if (self.headers_len >= api_server.MAX_HEADERS) {
            return false;
        }
        if (name.len > api_server.MAX_HEADER_NAME_LEN) {
            return false;
        }
        if (value.len > api_server.MAX_HEADER_VALUE_LEN) {
            return false;
        }
        var header = api_server.HttpHeader.init();
        var i: u32 = 0;
        const name_len = @min(name.len, api_server.MAX_HEADER_NAME_LEN);
        while (i < name_len) : (i += 1) {
            header.name[i] = name[i];
        }
        header.name_len = @intCast(name_len);
        i = 0;
        const value_len = @min(value.len, api_server.MAX_HEADER_VALUE_LEN);
        while (i < value_len) : (i += 1) {
            header.value[i] = value[i];
        }
        header.value_len = @intCast(value_len);
        self.headers[self.headers_len] = header;
        self.headers_len += 1;
        return true;
    }

    // Set timeout for request.
    pub fn set_timeout(self: *HttpClientRequest, timeout_ms: ?u32) void {
        std.debug.assert(self.request_id > 0);
        if (timeout_ms) |timeout| {
            self.timeout_ms = timeout;
            std.debug.assert(self.timeout_ms > 0);
        } else {
            self.timeout_ms = DEFAULT_API_TIMEOUT_MS;
            std.debug.assert(self.timeout_ms == DEFAULT_API_TIMEOUT_MS);
        }
    }

    // Check if request has timed out.
    pub fn is_timed_out(self: *const HttpClientRequest, current_time: u64) bool {
        std.debug.assert(self.request_id > 0);
        if (self.created_at == 0) {
            return false;
        }
        std.debug.assert(current_time >= self.created_at);
        const elapsed_ms = (current_time - self.created_at) / 1000000; // Convert ns to ms
        const timed_out = elapsed_ms > self.timeout_ms;
        return timed_out;
    }
};

// HTTP client manager.
pub const HttpClient = struct {
    requests: [MAX_CONCURRENT_REQUESTS]?HttpClientRequest,
    requests_len: u32,
    next_request_id: u32,
    network_stack: *network_stack.NetworkStack,
    dns_resolver: *dns_resolver.DnsResolver,
    pool: connection_pool.ConnectionPool,
    transfer_manager: ?*file_transfer.FileTransferManager,
    mime_detector: ?*file_mime_type.FileMimeTypeDetector,
    file_io: ?*integrated_file_io.IntegratedFileIO,
    current_time_fn: ?*const fn () u64,
    allocator: ?std.mem.Allocator,

    pub fn init(
        net_stack: *network_stack.NetworkStack,
        resolver: *dns_resolver.DnsResolver,
    ) HttpClient {
        std.debug.assert(net_stack != null);
        std.debug.assert(resolver != null);
        fn get_nano_timestamp() u64 {
            return std.time.nanoTimestamp();
        }
        const pool = connection_pool.ConnectionPool.init(get_nano_timestamp);
        var client = HttpClient{
            .requests = undefined,
            .requests_len = 0,
            .next_request_id = 1,
            .network_stack = net_stack,
            .dns_resolver = resolver,
            .pool = pool,
            .transfer_manager = null,
            .mime_detector = null,
            .file_io = null,
            .current_time_fn = null,
            .allocator = null,
        };
        var i: u32 = 0;
        while (i < MAX_CONCURRENT_REQUESTS) : (i += 1) {
            client.requests[i] = null;
        }
        std.debug.assert(client.requests_len == 0);
        return client;
    }

    pub fn create_request(
        self: *HttpClient,
        method: api_server.HttpMethod,
        url: []const u8,
        timeout_ms: ?u32,
    ) ?*HttpClientRequest {
        std.debug.assert(url.len > 0);
        std.debug.assert(self.requests_len <= MAX_CONCURRENT_REQUESTS);
        if (self.requests_len >= MAX_CONCURRENT_REQUESTS) {
            return null;
        }
        const request_id = self.next_request_id;
        self.next_request_id += 1;
        var req = HttpClientRequest.init(request_id);
        req.method = method;
        req.set_timeout(timeout_ms);
        req.created_at = std.time.nanoTimestamp();
        if (!req.set_url(url)) {
            return null;
        }
        var i: u32 = 0;
        while (i < MAX_CONCURRENT_REQUESTS) : (i += 1) {
            if (self.requests[i] == null) {
                self.requests[i] = req;
                self.requests_len += 1;
                std.debug.assert(self.requests_len <= MAX_CONCURRENT_REQUESTS);
                return &self.requests[i].?;
            }
        }
        return null;
    }

    // Check for timed out requests and mark them as failed.
    pub fn check_timeouts(self: *HttpClient, current_time: u64) void {
        std.debug.assert(self.requests_len <= MAX_CONCURRENT_REQUESTS);
        var i: u32 = 0;
        while (i < MAX_CONCURRENT_REQUESTS) : (i += 1) {
            if (self.requests[i]) |*req| {
                if (req.is_timed_out(current_time)) {
                    req.state = RequestState.failed;
                    std.debug.assert(req.state == RequestState.failed);
                }
            }
        }
    }

    pub fn find_request(
        self: *HttpClient,
        request_id: u32,
    ) ?*HttpClientRequest {
        std.debug.assert(request_id > 0);
        std.debug.assert(self.requests_len <= MAX_CONCURRENT_REQUESTS);
        var i: u32 = 0;
        while (i < MAX_CONCURRENT_REQUESTS) : (i += 1) {
            if (self.requests[i]) |*req| {
                if (req.request_id == request_id) {
                    std.debug.assert(req.request_id == request_id);
                    return req;
                }
            }
        }
        return null;
    }

    pub fn remove_request(
        self: *HttpClient,
        request_id: u32,
    ) bool {
        std.debug.assert(request_id > 0);
        std.debug.assert(self.requests_len <= MAX_CONCURRENT_REQUESTS);
        var i: u32 = 0;
        while (i < MAX_CONCURRENT_REQUESTS) : (i += 1) {
            if (self.requests[i]) |*req| {
                if (req.request_id == request_id) {
                    if (req.socket_id) |socket_id| {
                        _ = self.pool.return_connection(socket_id);
                    }
                    self.requests[i] = null;
                    self.requests_len -= 1;
                    std.debug.assert(self.requests_len < MAX_CONCURRENT_REQUESTS);
                    return true;
                }
            }
        }
        return false;
    }

    // Get connection from pool for hostname:port.
    pub fn get_pooled_connection(
        self: *HttpClient,
        hostname: []const u8,
        port: u32,
    ) ?u32 {
        std.debug.assert(hostname.len > 0);
        std.debug.assert(hostname.len <= MAX_HOSTNAME_LEN);
        std.debug.assert(port > 0);
        std.debug.assert(port <= network_stack.MAX_PORT);
        return self.pool.get_connection(hostname, port, self.network_stack);
    }

    // Return connection to pool.
    pub fn return_pooled_connection(
        self: *HttpClient,
        socket_id: u32,
    ) bool {
        std.debug.assert(socket_id > 0);
        return self.pool.return_connection(socket_id);
    }

    // Clean up idle connections in pool.
    pub fn cleanup_pool(self: *HttpClient) u32 {
        std.debug.assert(self.network_stack != null);
        return self.pool.cleanup_idle_connections(self.network_stack);
    }

    // Get connection pool count.
    pub fn get_pool_connection_count(self: *const HttpClient) u32 {
        std.debug.assert(self.pool.connections_len <= connection_pool.MAX_POOLED_CONNECTIONS);
        return self.pool.get_connection_count();
    }

    pub fn get_request_count(self: *const HttpClient) u32 {
        std.debug.assert(self.requests_len <= MAX_CONCURRENT_REQUESTS);
        const count = self.requests_len;
        std.debug.assert(count <= MAX_CONCURRENT_REQUESTS);
        return count;
    }

    // Set file transfer dependencies.
    pub fn set_file_transfer_dependencies(
        self: *HttpClient,
        transfer_mgr: *file_transfer.FileTransferManager,
        mime_det: *file_mime_type.FileMimeTypeDetector,
        io: *integrated_file_io.IntegratedFileIO,
        time_fn: *const fn () u64,
        alloc: std.mem.Allocator,
    ) void {
        std.debug.assert(transfer_mgr != null);
        std.debug.assert(mime_det != null);
        std.debug.assert(io != null);
        std.debug.assert(@intFromPtr(time_fn) != 0);
        self.transfer_manager = transfer_mgr;
        self.mime_detector = mime_det;
        self.file_io = io;
        self.current_time_fn = time_fn;
        self.allocator = alloc;
        std.debug.assert(self.transfer_manager != null);
    }

    // Upload file to remote server.
    pub fn upload_file(
        self: *HttpClient,
        url: []const u8,
        local_path: []const u8,
        timeout_ms: ?u32,
    ) http_errors.HttpClientError!u32 {
        std.debug.assert(url.len > 0);
        std.debug.assert(local_path.len > 0);
        std.debug.assert(self.transfer_manager != null);
        std.debug.assert(self.file_io != null);
        std.debug.assert(self.current_time_fn != null);
        std.debug.assert(self.allocator != null);
        const transfer_mgr = self.transfer_manager.?;
        const file_io_mgr = self.file_io.?;
        const time_fn = self.current_time_fn.?;
        const alloc = self.allocator.?;
        const current_time = time_fn();
        const user_id: u32 = 1;
        const group_id: u32 = 1;
        const file_data = file_io_mgr.read_file(
            alloc,
            local_path,
            current_time,
            user_id,
            group_id,
        ) catch return http_errors.HttpClientError.file_read_error;
        defer alloc.free(file_data);
        const file_size = file_data.len;
        const transfer_id_opt = transfer_mgr.create_upload(
            local_path,
            url,
            file_size,
            current_time,
        );
        if (transfer_id_opt == null) {
            return http_errors.HttpClientError.service_unavailable;
        }
        const transfer_id = transfer_id_opt.?;
        const req_opt = self.create_request(api_server.HttpMethod.post, url, timeout_ms);
        if (req_opt == null) {
            _ = transfer_mgr.cancel_transfer(transfer_id);
            return http_errors.HttpClientError.request_failed;
        }
        const req = req_opt.?;
        const mime_type_opt = if (self.mime_detector) |det| det.detect_mime_type(local_path) else null;
        if (mime_type_opt) |mime_type| {
            _ = req.add_header("Content-Type", mime_type);
        }
        const content_len = @min(file_data.len, api_server.MAX_REQUEST_SIZE);
        var i: u32 = 0;
        while (i < content_len) : (i += 1) {
            req.body[i] = file_data[i];
        }
        req.body_len = @intCast(content_len);
        var length_buf: [32]u8 = undefined;
        const length_str = std.fmt.bufPrint(&length_buf, "{}", .{content_len}) catch {
            _ = transfer_mgr.cancel_transfer(transfer_id);
            return http_errors.HttpClientError.request_failed;
        };
        _ = req.add_header("Content-Length", length_str[0..]);
        if (content_len > file_transfer.MAX_CHUNK_SIZE) {
            _ = req.add_header("Transfer-Encoding", "chunked");
        }
        std.debug.assert(transfer_id > 0);
        return transfer_id;
    }

    // Download file from remote server.
    pub fn download_file(
        self: *HttpClient,
        url: []const u8,
        local_path: []const u8,
        timeout_ms: ?u32,
    ) http_errors.HttpClientError!u32 {
        std.debug.assert(url.len > 0);
        std.debug.assert(local_path.len > 0);
        std.debug.assert(self.transfer_manager != null);
        std.debug.assert(self.file_io != null);
        std.debug.assert(self.current_time_fn != null);
        std.debug.assert(self.allocator != null);
        const transfer_mgr = self.transfer_manager.?;
        const file_io_mgr = self.file_io.?;
        const time_fn = self.current_time_fn.?;
        const alloc = self.allocator.?;
        const current_time = time_fn();
        const file_size: u64 = 0;
        const transfer_id_opt = transfer_mgr.create_download(
            url,
            local_path,
            file_size,
            current_time,
        );
        if (transfer_id_opt == null) {
            return http_errors.HttpClientError.service_unavailable;
        }
        const transfer_id = transfer_id_opt.?;
        const req_opt = self.create_request(api_server.HttpMethod.get, url, timeout_ms);
        if (req_opt == null) {
            _ = transfer_mgr.cancel_transfer(transfer_id);
            return http_errors.HttpClientError.request_failed;
        }
        const req = req_opt.?;
        std.debug.assert(transfer_id > 0);
        return transfer_id;
    }

    // Complete file download by writing response data to file.
    pub fn complete_download(
        self: *HttpClient,
        transfer_id: u32,
        request_id: u32,
        local_path: []const u8,
    ) http_errors.HttpClientError!void {
        std.debug.assert(transfer_id > 0);
        std.debug.assert(request_id > 0);
        std.debug.assert(local_path.len > 0);
        std.debug.assert(self.transfer_manager != null);
        std.debug.assert(self.file_io != null);
        std.debug.assert(self.current_time_fn != null);
        std.debug.assert(self.allocator != null);
        const transfer_mgr = self.transfer_manager.?;
        const file_io_mgr = self.file_io.?;
        const time_fn = self.current_time_fn.?;
        const alloc = self.allocator.?;
        const current_time = time_fn();
        const user_id: u32 = 1;
        const group_id: u32 = 1;
        const response = self.get_response(request_id, current_time) catch |err| {
            _ = transfer_mgr.cancel_transfer(transfer_id);
            return err;
        };
        if (response.status != api_server.HttpStatus.ok) {
            _ = transfer_mgr.cancel_transfer(transfer_id);
            return http_errors.HttpClientError.invalid_response;
        }
        const file_data = response.body[0..response.body_len];
        file_io_mgr.write_file(
            alloc,
            local_path,
            file_data,
            current_time,
            user_id,
            group_id,
        ) catch {
            _ = transfer_mgr.cancel_transfer(transfer_id);
            return http_errors.HttpClientError.file_write_error;
        };
        if (transfer_mgr.get_transfer(transfer_id)) |transfer| {
            transfer.state = file_transfer.TransferState.completed;
        }
        std.debug.assert(transfer_id > 0);
    }

    // Get response from completed request, returning structured errors.
    pub fn get_response(
        self: *HttpClient,
        request_id: u32,
        current_time: u64,
    ) http_errors.HttpClientError!api_server.HttpResponse {
        std.debug.assert(request_id > 0);
        std.debug.assert(self.requests_len <= MAX_CONCURRENT_REQUESTS);
        const req = self.find_request(request_id) orelse {
            return http_errors.HttpClientError.invalid_response;
        };
        if (req.is_timed_out(current_time)) {
            req.state = RequestState.failed;
            return http_errors.HttpClientError.timeout;
        }
        if (req.state == RequestState.failed) {
            return http_errors.HttpClientError.network_error;
        }
        if (req.state != RequestState.completed) {
            return http_errors.HttpClientError.invalid_response;
        }
        const response = req.response orelse {
            return http_errors.HttpClientError.invalid_response;
        };
        if (response.status == api_server.HttpStatus.too_many_requests) {
            return http_errors.HttpClientError.rate_limit;
        }
        if (response.status.code >= 500) {
            return http_errors.HttpClientError.server_error;
        }
        std.debug.assert(response.status.code < 500);
        return response;
    }
};

