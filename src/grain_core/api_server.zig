//! Grain OS API Server: HTTP/REST API server for mobile and database backends.
//!
//! Why: Provide REST API server for Grain Mobile Agent and Grain Database Agent.
//! Architecture: HTTP/1.1 server, REST routing, JSON handling, middleware.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");

// Bounded: Max routes.
pub const MAX_ROUTES: u32 = 128;

// Bounded: Max request size (64KB).
pub const MAX_REQUEST_SIZE: u32 = 65536;

// Bounded: Max response size (64KB).
pub const MAX_RESPONSE_SIZE: u32 = 65536;

// Bounded: Max headers per request.
pub const MAX_HEADERS: u32 = 32;

// Bounded: Max header name length.
pub const MAX_HEADER_NAME_LEN: u32 = 128;

// Bounded: Max header value length.
pub const MAX_HEADER_VALUE_LEN: u32 = 512;

// Bounded: Max path length.
pub const MAX_PATH_LEN: u32 = 2048;

// Bounded: Max query string length.
pub const MAX_QUERY_LEN: u32 = 2048;

// HTTP method.
pub const HttpMethod = enum(u8) {
    get,
    post,
    put,
    delete,
    patch,
    head,
    options,
};

// HTTP status code.
pub const HttpStatus = enum(u16) {
    ok = 200,
    created = 201,
    no_content = 204,
    bad_request = 400,
    unauthorized = 401,
    forbidden = 403,
    not_found = 404,
    conflict = 409,
    too_many_requests = 429,
    payload_too_large = 413,
    internal_server_error = 500,
    service_unavailable = 503,
};

// HTTP header.
pub const HttpHeader = struct {
    name: [MAX_HEADER_NAME_LEN]u8,
    name_len: u32,
    value: [MAX_HEADER_VALUE_LEN]u8,
    value_len: u32,

    pub fn init() HttpHeader {
        const header = HttpHeader{
            .name = undefined,
            .name_len = 0,
            .value = undefined,
            .value_len = 0,
        };
        std.debug.assert(header.name_len == 0);
        std.debug.assert(header.value_len == 0);
        return header;
    }
};

// HTTP request.
pub const HttpRequest = struct {
    method: HttpMethod,
    path: [MAX_PATH_LEN]u8,
    path_len: u32,
    query: [MAX_QUERY_LEN]u8,
    query_len: u32,
    headers: [MAX_HEADERS]HttpHeader,
    headers_len: u32,
    body: [MAX_REQUEST_SIZE]u8,
    body_len: u32,

    pub fn init() HttpRequest {
        const req = HttpRequest{
            .method = HttpMethod.get,
            .path = undefined,
            .path_len = 0,
            .query = undefined,
            .query_len = 0,
            .headers = undefined,
            .headers_len = 0,
            .body = undefined,
            .body_len = 0,
        };
        std.debug.assert(req.path_len == 0);
        std.debug.assert(req.headers_len == 0);
        return req;
    }

    // Get header by name.
    pub fn get_header(self: *const HttpRequest, name: []const u8) ?[]const u8 {
        std.debug.assert(name.len > 0);
        std.debug.assert(self.headers_len <= MAX_HEADERS);
        var i: u32 = 0;
        while (i < self.headers_len) : (i += 1) {
            if (self.headers[i].name_len == name.len) {
                var match: bool = true;
                var j: u32 = 0;
                while (j < name.len) : (j += 1) {
                    if (self.headers[i].name[j] != name[j]) {
                        match = false;
                        break;
                    }
                }
                if (match) {
                    std.debug.assert(self.headers[i].value_len > 0);
                    return self.headers[i].value[0..self.headers[i].value_len];
                }
            }
        }
        return null;
    }

    // Add header.
    pub fn add_header(
        self: *HttpRequest,
        name: []const u8,
        value: []const u8,
    ) bool {
        std.debug.assert(name.len > 0);
        std.debug.assert(value.len > 0);
        if (self.headers_len >= MAX_HEADERS) {
            return false;
        }
        if (name.len > MAX_HEADER_NAME_LEN) {
            return false;
        }
        if (value.len > MAX_HEADER_VALUE_LEN) {
            return false;
        }
        var i: u32 = 0;
        while (i < MAX_HEADER_NAME_LEN) : (i += 1) {
            self.headers[self.headers_len].name[i] = 0;
        }
        const name_len = @min(name.len, MAX_HEADER_NAME_LEN);
        i = 0;
        while (i < name_len) : (i += 1) {
            self.headers[self.headers_len].name[i] = name[i];
        }
        self.headers[self.headers_len].name_len = @as(u32, @intCast(name_len));
        i = 0;
        while (i < MAX_HEADER_VALUE_LEN) : (i += 1) {
            self.headers[self.headers_len].value[i] = 0;
        }
        const value_len = @min(value.len, MAX_HEADER_VALUE_LEN);
        i = 0;
        while (i < value_len) : (i += 1) {
            self.headers[self.headers_len].value[i] = value[i];
        }
        self.headers[self.headers_len].value_len = @as(u32, @intCast(value_len));
        self.headers_len += 1;
        return true;
    }
};

// HTTP response.
pub const HttpResponse = struct {
    status: HttpStatus,
    headers: [MAX_HEADERS]HttpHeader,
    headers_len: u32,
    body: [MAX_RESPONSE_SIZE]u8,
    body_len: u32,

    pub fn init() HttpResponse {
        const resp = HttpResponse{
            .status = HttpStatus.ok,
            .headers = undefined,
            .headers_len = 0,
            .body = undefined,
            .body_len = 0,
        };
        std.debug.assert(resp.headers_len == 0);
        std.debug.assert(resp.body_len == 0);
        return resp;
    }

    // Add header.
    pub fn add_header(
        self: *HttpResponse,
        name: []const u8,
        value: []const u8,
    ) bool {
        std.debug.assert(name.len > 0);
        std.debug.assert(value.len > 0);
        if (self.headers_len >= MAX_HEADERS) {
            return false;
        }
        if (name.len > MAX_HEADER_NAME_LEN) {
            return false;
        }
        if (value.len > MAX_HEADER_VALUE_LEN) {
            return false;
        }
        var i: u32 = 0;
        while (i < MAX_HEADER_NAME_LEN) : (i += 1) {
            self.headers[self.headers_len].name[i] = 0;
        }
        const name_len = @min(name.len, MAX_HEADER_NAME_LEN);
        i = 0;
        while (i < name_len) : (i += 1) {
            self.headers[self.headers_len].name[i] = name[i];
        }
        self.headers[self.headers_len].name_len = @as(u32, @intCast(name_len));
        i = 0;
        while (i < MAX_HEADER_VALUE_LEN) : (i += 1) {
            self.headers[self.headers_len].value[i] = 0;
        }
        const value_len = @min(value.len, MAX_HEADER_VALUE_LEN);
        i = 0;
        while (i < value_len) : (i += 1) {
            self.headers[self.headers_len].value[i] = value[i];
        }
        self.headers[self.headers_len].value_len = @as(u32, @intCast(value_len));
        self.headers_len += 1;
        return true;
    }
};

// Route handler function type (runtime function pointer).
pub const RouteHandler = *const fn (*HttpRequest, *HttpResponse) void;

// Middleware function type (runtime function pointer).
pub const Middleware = *const fn (*HttpRequest, *HttpResponse) bool;

// Route: represents a registered route.
pub const Route = struct {
    method: HttpMethod,
    path_pattern: [MAX_PATH_LEN]u8,
    path_pattern_len: u32,
    handler: ?RouteHandler,
    middleware: [8]?Middleware,
    middleware_len: u32,
    active: bool,

    pub fn init() Route {
        const route = Route{
            .method = HttpMethod.get,
            .path_pattern = undefined,
            .path_pattern_len = 0,
            .handler = null,
            .middleware = undefined,
            .middleware_len = 0,
            .active = false,
        };
        std.debug.assert(route.path_pattern_len == 0);
        std.debug.assert(!route.active);
        return route;
    }
};

// API server: manages HTTP server and routes.
pub const ApiServer = struct {
    routes: [MAX_ROUTES]Route,
    routes_len: u32,
    port: u16,
    running: bool,
    next_route_id: u32,
    server_process_id: u32,

    pub fn init(port: u16) ApiServer {
        std.debug.assert(port > 0);
        const server = ApiServer{
            .routes = undefined,
            .routes_len = 0,
            .port = port,
            .running = false,
            .next_route_id = 1,
            .server_process_id = 0,
        };
        std.debug.assert(server.port == port);
        std.debug.assert(!server.running);
        return server;
    }

    // Register route.
    pub fn register_route(
        self: *ApiServer,
        method: HttpMethod,
        path_pattern: []const u8,
        handler: RouteHandler,
    ) bool {
        std.debug.assert(path_pattern.len > 0);
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        if (self.routes_len >= MAX_ROUTES) {
            return false;
        }
        if (path_pattern.len > MAX_PATH_LEN) {
            return false;
        }
        self.routes[self.routes_len] = Route.init();
        self.routes[self.routes_len].method = method;
        self.routes[self.routes_len].handler = handler;
        self.routes[self.routes_len].active = true;
        const pattern_len = @min(path_pattern.len, MAX_PATH_LEN);
        var i: u32 = 0;
        while (i < MAX_PATH_LEN) : (i += 1) {
            self.routes[self.routes_len].path_pattern[i] = 0;
        }
        i = 0;
        while (i < pattern_len) : (i += 1) {
            self.routes[self.routes_len].path_pattern[i] = path_pattern[i];
        }
        self.routes[self.routes_len].path_pattern_len = @as(u32, @intCast(pattern_len));
        self.routes_len += 1;
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        return true;
    }

    // Add middleware to route.
    pub fn add_middleware_to_route(
        self: *ApiServer,
        method: HttpMethod,
        path_pattern: []const u8,
        middleware_fn: Middleware,
    ) bool {
        std.debug.assert(path_pattern.len > 0);
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        if (self.find_route_by_pattern(method, path_pattern)) |route| {
            if (route.middleware_len >= 8) {
                return false;
            }
            route.middleware[route.middleware_len] = middleware_fn;
            route.middleware_len += 1;
            std.debug.assert(route.middleware_len <= 8);
            return true;
        }
        return false;
    }

    // Find route by method and path pattern.
    fn find_route_by_pattern(
        self: *ApiServer,
        method: HttpMethod,
        path_pattern: []const u8,
    ) ?*Route {
        std.debug.assert(path_pattern.len > 0);
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        var i: u32 = 0;
        while (i < self.routes_len) : (i += 1) {
            if (self.routes[i].active and self.routes[i].method == method) {
                const pattern_len = self.routes[i].path_pattern_len;
                const route_pattern = self.routes[i].path_pattern[0..pattern_len];
                if (std.mem.eql(u8, route_pattern, path_pattern)) {
                    std.debug.assert(self.routes[i].active);
                    return &self.routes[i];
                }
            }
        }
        return null;
    }

    // Execute middleware chain for route.
    pub fn execute_middleware_chain(
        _self: *const ApiServer,
        route: *const Route,
        request: *HttpRequest,
        response: *HttpResponse,
    ) bool {
        _ = _self;
        std.debug.assert(route.active);
        std.debug.assert(route.middleware_len <= 8);
        var i: u32 = 0;
        while (i < route.middleware_len) : (i += 1) {
            if (route.middleware[i]) |middleware_fn| {
                if (!middleware_fn(request, response)) {
                    return false;
                }
            }
        }
        return true;
    }

    // Find route by method and path.
    pub fn find_route(
        self: *const ApiServer,
        method: HttpMethod,
        path: []const u8,
    ) ?*const Route {
        std.debug.assert(path.len > 0);
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        var i: u32 = 0;
        while (i < self.routes_len) : (i += 1) {
            if (self.routes[i].active and self.routes[i].method == method) {
                if (self.match_path_pattern(
                    self.routes[i].path_pattern[0..self.routes[i].path_pattern_len],
                    path,
                )) {
                    std.debug.assert(self.routes[i].active);
                    return &self.routes[i];
                }
            }
        }
        return null;
    }

    // Match path pattern (supports {param} placeholders).
    fn match_path_pattern(
        _self: *const ApiServer,
        pattern: []const u8,
        path: []const u8,
    ) bool {
        _ = _self;
        std.debug.assert(pattern.len > 0);
        std.debug.assert(path.len > 0);
        var pattern_pos: u32 = 0;
        var path_pos: u32 = 0;
        var in_param: bool = false;
        while (pattern_pos < pattern.len and path_pos < path.len) {
            if (pattern[pattern_pos] == '{') {
                in_param = true;
                pattern_pos += 1;
                while (path_pos < path.len and path[path_pos] != '/') : (path_pos += 1) {}
            } else if (pattern[pattern_pos] == '}') {
                in_param = false;
                pattern_pos += 1;
            } else if (!in_param) {
                if (pattern[pattern_pos] != path[path_pos]) {
                    return false;
                }
                pattern_pos += 1;
                path_pos += 1;
            } else {
                pattern_pos += 1;
            }
        }
        if (pattern_pos < pattern.len) {
            while (pattern_pos < pattern.len and (pattern[pattern_pos] == '}' or pattern[pattern_pos] == '{')) : (pattern_pos += 1) {}
            if (pattern_pos < pattern.len) {
                return false;
            }
        }
        if (path_pos < path.len) {
            return false;
        }
        return true;
    }

    // Start server (stub for now, will use network integration).
    pub fn start(self: *ApiServer) bool {
        std.debug.assert(!self.running);
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        if (self.routes_len == 0) {
            return false;
        }
        self.running = true;
        std.debug.assert(self.running);
        return true;
    }

    // Start server with network binding.
    pub fn start_with_network(
        self: *ApiServer,
        network_server: *@import("api_server_network.zig").NetworkServer,
    ) bool {
        std.debug.assert(!self.running);
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        if (self.routes_len == 0) {
            return false;
        }
        if (network_server.bind_to_port() != @import("api_server_network.zig").BindResult.success) {
            return false;
        }
        if (!network_server.start_listening()) {
            return false;
        }
        self.running = true;
        std.debug.assert(self.running);
        return true;
    }

    // Register server process with process manager.
    pub fn register_server_process(
        self: *ApiServer,
        process_manager: *@import("process_manager.zig").ProcessManager,
        parent_process_id: u32,
        process_name: []const u8,
        cmd_line: []const u8,
        start_time: u64,
    ) ?u32 {
        std.debug.assert(process_name.len > 0);
        std.debug.assert(self.running);
        const process_id = process_manager.add_process(
            parent_process_id,
            process_name,
            cmd_line,
            start_time,
        );
        if (process_id) |pid| {
            self.server_process_id = pid;
            return pid;
        }
        return null;
    }

    // Get server process ID.
    pub fn get_server_process_id(self: *const ApiServer) ?u32 {
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        if (self.server_process_id == 0) {
            return null;
        }
        const pid = self.server_process_id;
        std.debug.assert(pid > 0);
        return pid;
    }

    // Update server process state.
    pub fn update_server_process_state(
        self: *ApiServer,
        process_manager: *@import("process_manager.zig").ProcessManager,
        state: @import("process_manager.zig").ProcessState,
    ) bool {
        std.debug.assert(self.running);
        std.debug.assert(self.server_process_id > 0);
        if (self.server_process_id == 0) {
            return false;
        }
        const result = process_manager.set_process_state(self.server_process_id, state);
        std.debug.assert(self.running);
        return result;
    }

    // Stop server.
    pub fn stop(self: *ApiServer) void {
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        self.running = false;
        std.debug.assert(!self.running);
    }

    // Check if server is running.
    pub fn is_running(self: *const ApiServer) bool {
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        const running = self.running;
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        return running;
    }

    // Get route count.
    pub fn get_route_count(self: *const ApiServer) u32 {
        std.debug.assert(self.routes_len <= MAX_ROUTES);
        const count = self.routes_len;
        std.debug.assert(count <= MAX_ROUTES);
        return count;
    }

    // Parse HTTP method from string.
    fn parse_http_method(method_str: []const u8) ?HttpMethod {
        std.debug.assert(method_str.len > 0);
        if (std.mem.eql(u8, method_str, "GET")) {
            return HttpMethod.get;
        } else if (std.mem.eql(u8, method_str, "POST")) {
            return HttpMethod.post;
        } else if (std.mem.eql(u8, method_str, "PUT")) {
            return HttpMethod.put;
        } else if (std.mem.eql(u8, method_str, "DELETE")) {
            return HttpMethod.delete;
        } else if (std.mem.eql(u8, method_str, "PATCH")) {
            return HttpMethod.patch;
        } else if (std.mem.eql(u8, method_str, "HEAD")) {
            return HttpMethod.head;
        } else if (std.mem.eql(u8, method_str, "OPTIONS")) {
            return HttpMethod.options;
        }
        std.debug.assert(method_str.len > 0);
        return null;
    }

    // Find request line boundaries.
    fn find_request_line_boundaries(
        raw_request: []const u8,
        method_end: *u32,
        path_start: *u32,
        path_end: *u32,
        query_start: *u32,
    ) bool {
        std.debug.assert(raw_request.len > 0);
        std.debug.assert(method_end != null);
        std.debug.assert(path_start != null);
        method_end.* = 0;
        path_start.* = 0;
        path_end.* = 0;
        query_start.* = 0;
        var i: u32 = 0;
        while (i < raw_request.len) : (i += 1) {
            if (raw_request[i] == ' ' and method_end.* == 0) {
                method_end.* = i;
                path_start.* = i + 1;
            } else if (raw_request[i] == '?' and query_start.* == 0) {
                path_end.* = i;
                query_start.* = i + 1;
            } else if (raw_request[i] == ' ' and path_end.* == 0 and query_start.* == 0) {
                path_end.* = i;
            } else if (raw_request[i] == '\r' and i + 1 < raw_request.len) {
                if (raw_request[i + 1] == '\n') {
                    if (path_end.* == 0) {
                        path_end.* = i;
                    }
                    break;
                }
            }
        }
        return method_end.* > 0 and path_start.* < raw_request.len;
    }

    // Find body start position.
    fn find_body_start(raw_request: []const u8) ?u32 {
        std.debug.assert(raw_request.len > 0);
        std.debug.assert(raw_request.len <= MAX_REQUEST_SIZE);
        var i: u32 = 0;
        var header_end_count: u32 = 0;
        while (i < raw_request.len) : (i += 1) {
            if (raw_request[i] == '\r' and i + 1 < raw_request.len and raw_request[i + 1] == '\n') {
                header_end_count += 1;
                if (header_end_count >= 2) {
                    const body_start = i + 2;
                    std.debug.assert(body_start <= raw_request.len);
                    return body_start;
                }
                i += 1;
            }
        }
        return null;
    }

    // Parse HTTP request from raw bytes.
    pub fn parse_http_request(
        self: *ApiServer,
        raw_request: []const u8,
        request: *HttpRequest,
    ) bool {
        std.debug.assert(raw_request.len > 0);
        std.debug.assert(request != null);
        if (raw_request.len > MAX_REQUEST_SIZE) {
            return false;
        }
        request.* = HttpRequest.init();
        var method_end: u32 = 0;
        var path_start: u32 = 0;
        var path_end: u32 = 0;
        var query_start: u32 = 0;
        if (!self.find_request_line_boundaries(
            raw_request,
            &method_end,
            &path_start,
            &path_end,
            &query_start,
        )) {
            return false;
        }
        const method_str = raw_request[0..method_end];
        const method_opt = self.parse_http_method(method_str);
        if (method_opt == null) {
            return false;
        }
        request.method = method_opt.?;
        const path_end_pos = if (path_end > 0) path_end else (
            if (query_start > 0) query_start - 1 else raw_request.len
        );
        const path_len = @min(path_end_pos - path_start, MAX_PATH_LEN);
        var j: u32 = 0;
        while (j < path_len) : (j += 1) {
            request.path[j] = raw_request[path_start + j];
        }
        request.path_len = path_len;
        if (query_start > 0) {
            const query_end = if (path_end > query_start) path_end else raw_request.len;
            const query_len = @min(query_end - query_start, MAX_QUERY_LEN);
            j = 0;
            while (j < query_len) : (j += 1) {
                request.query[j] = raw_request[query_start + j];
            }
            request.query_len = query_len;
        }
        if (self.find_body_start(raw_request)) |body_start| {
            if (body_start < raw_request.len) {
                const body_len = @min(raw_request.len - body_start, MAX_REQUEST_SIZE);
                j = 0;
                while (j < body_len) : (j += 1) {
                    request.body[j] = raw_request[body_start + j];
                }
                request.body_len = body_len;
            }
        }
        std.debug.assert(request.path_len <= MAX_PATH_LEN);
        std.debug.assert(request.body_len <= MAX_REQUEST_SIZE);
        return true;
    }

    // Get HTTP status line string.
    fn get_status_line(status: HttpStatus) []const u8 {
        std.debug.assert(@intFromEnum(status) >= 200);
        const status_line = switch (status) {
            HttpStatus.ok => "HTTP/1.1 200 OK\r\n",
            HttpStatus.created => "HTTP/1.1 201 Created\r\n",
            HttpStatus.no_content => "HTTP/1.1 204 No Content\r\n",
            HttpStatus.bad_request => "HTTP/1.1 400 Bad Request\r\n",
            HttpStatus.unauthorized => "HTTP/1.1 401 Unauthorized\r\n",
            HttpStatus.forbidden => "HTTP/1.1 403 Forbidden\r\n",
            HttpStatus.not_found => "HTTP/1.1 404 Not Found\r\n",
            HttpStatus.conflict => "HTTP/1.1 409 Conflict\r\n",
            HttpStatus.too_many_requests => "HTTP/1.1 429 Too Many Requests\r\n",
            HttpStatus.internal_server_error => "HTTP/1.1 500 Internal Server Error\r\n",
            HttpStatus.service_unavailable => "HTTP/1.1 503 Service Unavailable\r\n",
        };
        std.debug.assert(status_line.len > 0);
        return status_line;
    }

    // Write status line to output.
    fn write_status_line(
        status_line: []const u8,
        output: []u8,
        pos: *u32,
    ) bool {
        std.debug.assert(status_line.len > 0);
        std.debug.assert(output.len > 0);
        if (pos.* + status_line.len > output.len) {
            return false;
        }
        var i: u32 = 0;
        while (i < status_line.len) : (i += 1) {
            output[pos.*] = status_line[i];
            pos.* += 1;
        }
        return true;
    }

    // Write headers to output.
    fn write_headers(
        response: *const HttpResponse,
        output: []u8,
        pos: *u32,
    ) bool {
        std.debug.assert(output.len > 0);
        std.debug.assert(response.headers_len <= MAX_HEADERS);
        var i: u32 = 0;
        while (i < response.headers_len) : (i += 1) {
            const name_len = response.headers[i].name_len;
            const value_len = response.headers[i].value_len;
            const header_size = name_len + 2 + value_len + 2;
            if (pos.* + header_size > output.len) {
                return false;
            }
            var j: u32 = 0;
            while (j < response.headers[i].name_len) : (j += 1) {
                output[pos.*] = response.headers[i].name[j];
                pos.* += 1;
            }
            output[pos.*] = ':';
            pos.* += 1;
            output[pos.*] = ' ';
            pos.* += 1;
            j = 0;
            while (j < response.headers[i].value_len) : (j += 1) {
                output[pos.*] = response.headers[i].value[j];
                pos.* += 1;
            }
            output[pos.*] = '\r';
            pos.* += 1;
            output[pos.*] = '\n';
            pos.* += 1;
        }
        std.debug.assert(pos.* <= output.len);
        return true;
    }

    // Write body to output.
    fn write_body(
        response: *const HttpResponse,
        output: []u8,
        pos: *u32,
    ) bool {
        std.debug.assert(output.len > 0);
        std.debug.assert(response.body_len <= MAX_RESPONSE_SIZE);
        if (response.body_len > 0) {
            if (pos.* + response.body_len > output.len) {
                return false;
            }
            var i: u32 = 0;
            while (i < response.body_len) : (i += 1) {
                output[pos.*] = response.body[i];
                pos.* += 1;
            }
        }
        std.debug.assert(pos.* <= output.len);
        return true;
    }

    // Generate HTTP response from HttpResponse struct.
    pub fn generate_http_response(
        self: *const ApiServer,
        response: *const HttpResponse,
        output: []u8,
    ) ?u32 {
        std.debug.assert(output.len > 0);
        std.debug.assert(response.body_len <= MAX_RESPONSE_SIZE);
        var pos: u32 = 0;
        const status_line = self.get_status_line(response.status);
        if (!self.write_status_line(status_line, output, &pos)) {
            return null;
        }
        if (!self.write_headers(response, output, &pos)) {
            return null;
        }
        if (pos + 2 > output.len) {
            return null;
        }
        output[pos] = '\r';
        pos += 1;
        output[pos] = '\n';
        pos += 1;
        if (!self.write_body(response, output, &pos)) {
            return null;
        }
        std.debug.assert(pos <= output.len);
        return pos;
    }

    // Extract path parameters from path pattern.
    pub fn extract_path_parameters(
        self: *const ApiServer,
        pattern: []const u8,
        path: []const u8,
        params: []const []const u8,
    ) ?u32 {
        _ = self;
        std.debug.assert(pattern.len > 0);
        std.debug.assert(path.len > 0);
        var param_count: u32 = 0;
        var pattern_pos: u32 = 0;
        var path_pos: u32 = 0;
        var param_start: u32 = 0;
        var in_param: bool = false;
        while (pattern_pos < pattern.len and path_pos < path.len) : (pattern_pos += 1) {
            if (pattern[pattern_pos] == '{') {
                in_param = true;
                param_start = path_pos;
            } else if (pattern[pattern_pos] == '}') {
                if (in_param and param_count < params.len) {
                    const param_end = path_pos;
                    if (param_end > param_start) {
                        params[param_count] = path[param_start..param_end];
                        param_count += 1;
                    }
                }
                in_param = false;
            } else if (!in_param) {
                if (pattern[pattern_pos] != path[path_pos]) {
                    return null;
                }
                path_pos += 1;
            } else {
                path_pos += 1;
            }
        }
        if (pattern_pos < pattern.len or path_pos < path.len) {
            return null;
        }
        return param_count;
    }

    // Parse JSON request body (extract string value by key).
    pub fn parse_json_string_from_request(
        self: *const ApiServer,
        request: *const HttpRequest,
        key: []const u8,
        output: []u8,
    ) ?u32 {
        _ = self;
        std.debug.assert(key.len > 0);
        std.debug.assert(output.len > 0);
        if (request.body_len == 0) {
            return null;
        }
        const body = request.body[0..request.body_len];
        const json_helpers = @import("json_helpers.zig");
        if (json_helpers.find_json_key(body, key)) |result| {
            var result_mut = result;
            return json_helpers.extract_json_string_value(body, &result_mut, output);
        }
        return null;
    }

    // Parse JSON request body (extract number value by key).
    pub fn parse_json_number_from_request(
        self: *const ApiServer,
        request: *const HttpRequest,
        key: []const u8,
    ) ?i64 {
        _ = self;
        std.debug.assert(key.len > 0);
        std.debug.assert(request.body_len <= MAX_REQUEST_SIZE);
        if (request.body_len == 0) {
            return null;
        }
        const body = request.body[0..request.body_len];
        const json_helpers = @import("json_helpers.zig");
        if (json_helpers.find_json_key(body, key)) |result| {
            var result_mut = result;
            const number = json_helpers.extract_json_number_value(body, &result_mut);
            std.debug.assert(number != null);
            return number;
        }
        return null;
    }

    // Parse JSON request body (extract boolean value by key).
    pub fn parse_json_bool_from_request(
        self: *const ApiServer,
        request: *const HttpRequest,
        key: []const u8,
    ) ?bool {
        _ = self;
        std.debug.assert(key.len > 0);
        std.debug.assert(request.body_len <= MAX_REQUEST_SIZE);
        if (request.body_len == 0) {
            return null;
        }
        const body = request.body[0..request.body_len];
        const json_helpers = @import("json_helpers.zig");
        if (json_helpers.find_json_key(body, key)) |result| {
            var result_mut = result;
            const bool_val = json_helpers.extract_json_bool_value(body, &result_mut);
            std.debug.assert(bool_val != null);
            return bool_val;
        }
        return null;
    }

    // Generate JSON response body (write string key-value pair).
    pub fn write_json_string_to_response(
        self: *const ApiServer,
        response: *HttpResponse,
        key: []const u8,
        value: []const u8,
    ) bool {
        _ = self;
        std.debug.assert(key.len > 0);
        std.debug.assert(value.len > 0);
        if (response.body_len + key.len + value.len + 16 > MAX_RESPONSE_SIZE) {
            return false;
        }
        const json_helpers = @import("json_helpers.zig");
        var pos: u32 = response.body_len;
        if (pos > 0) {
            response.body[pos] = ',';
            pos += 1;
        } else {
            response.body[pos] = '{';
            pos += 1;
        }
        if (!json_helpers.write_json_string(response.body, &pos, key)) {
            return false;
        }
        response.body[pos] = ':';
        pos += 1;
        if (!json_helpers.write_json_string(response.body, &pos, value)) {
            return false;
        }
        response.body_len = pos;
        return true;
    }

    // Generate JSON response body (write number key-value pair).
    pub fn write_json_number_to_response(
        self: *const ApiServer,
        response: *HttpResponse,
        key: []const u8,
        value: i64,
    ) bool {
        _ = self;
        std.debug.assert(key.len > 0);
        std.debug.assert(response.body_len <= MAX_RESPONSE_SIZE);
        if (response.body_len + key.len + 32 > MAX_RESPONSE_SIZE) {
            return false;
        }
        const json_helpers = @import("json_helpers.zig");
        var pos: u32 = response.body_len;
        if (pos > 0) {
            response.body[pos] = ',';
            pos += 1;
        } else {
            response.body[pos] = '{';
            pos += 1;
        }
        if (!json_helpers.write_json_string(response.body, &pos, key)) {
            return false;
        }
        response.body[pos] = ':';
        pos += 1;
        if (!json_helpers.write_json_number(response.body, &pos, value)) {
            return false;
        }
        response.body_len = pos;
        std.debug.assert(response.body_len <= MAX_RESPONSE_SIZE);
        return true;
    }

    // Generate JSON response body (write boolean key-value pair).
    pub fn write_json_bool_to_response(
        self: *const ApiServer,
        response: *HttpResponse,
        key: []const u8,
        value: bool,
    ) bool {
        _ = self;
        std.debug.assert(key.len > 0);
        std.debug.assert(response.body_len <= MAX_RESPONSE_SIZE);
        if (response.body_len + key.len + 8 > MAX_RESPONSE_SIZE) {
            return false;
        }
        const json_helpers = @import("json_helpers.zig");
        var pos: u32 = response.body_len;
        if (pos > 0) {
            response.body[pos] = ',';
            pos += 1;
        } else {
            response.body[pos] = '{';
            pos += 1;
        }
        if (!json_helpers.write_json_string(response.body, &pos, key)) {
            return false;
        }
        response.body[pos] = ':';
        pos += 1;
        if (!json_helpers.write_json_bool(response.body, &pos, value)) {
            return false;
        }
        response.body_len = pos;
        std.debug.assert(response.body_len <= MAX_RESPONSE_SIZE);
        return true;
    }

    // Finalize JSON response body (close object).
    pub fn finalize_json_response(
        self: *const ApiServer,
        response: *HttpResponse,
    ) bool {
        _ = self;
        std.debug.assert(response.body_len <= MAX_RESPONSE_SIZE);
        if (response.body_len >= MAX_RESPONSE_SIZE) {
            return false;
        }
        response.body[response.body_len] = '}';
        response.body_len += 1;
        std.debug.assert(response.body_len <= MAX_RESPONSE_SIZE);
        return true;
    }

    // Negotiate content type based on Accept header.
    pub fn negotiate_content_type(
        self: *const ApiServer,
        request: *const HttpRequest,
        available_types: []const []const u8,
    ) ?[]const u8 {
        _ = self;
        std.debug.assert(available_types.len > 0);
        std.debug.assert(available_types.len <= 16);
        const content_negotiation = @import("content_negotiation.zig");
        if (request.get_header("Accept")) |accept_header| {
            var negotiator = content_negotiation.ContentNegotiator.init();
            if (negotiator.parse_accept_header(accept_header)) {
                return negotiator.negotiate_content_type(available_types);
            }
        }
        if (available_types.len > 0) {
            return available_types[0];
        }
        return null;
    }

    // Set Content-Type header based on negotiation.
    pub fn set_negotiated_content_type(
        self: *const ApiServer,
        request: *const HttpRequest,
        response: *HttpResponse,
        available_types: []const []const u8,
    ) bool {
        std.debug.assert(available_types.len > 0);
        std.debug.assert(available_types.len <= 16);
        const negotiated = self.negotiate_content_type(request, available_types);
        if (negotiated) |content_type| {
            return response.add_header("Content-Type", content_type);
        }
        if (available_types.len > 0) {
            return response.add_header("Content-Type", available_types[0]);
        }
        return false;
    }

    // Generate chunked HTTP response (for streaming).
    pub fn generate_chunked_response(
        self: *const ApiServer,
        response: *const HttpResponse,
        output: []u8,
    ) ?u32 {
        std.debug.assert(output.len > 0);
        std.debug.assert(response.body_len <= MAX_RESPONSE_SIZE);
        const chunked_transfer_mod = @import("chunked_transfer.zig");
        var pos: u32 = 0;
        const status_line = self.get_status_line(response.status);
        if (!self.write_status_line(status_line, output, &pos)) {
            return null;
        }
        if (!self.write_headers(response, output, &pos)) {
            return null;
        }
        const transfer_encoding_header = "Transfer-Encoding: chunked\r\n";
        if (pos + transfer_encoding_header.len > output.len) {
            return null;
        }
        var i: u32 = 0;
        while (i < transfer_encoding_header.len) : (i += 1) {
            output[pos] = transfer_encoding_header[i];
            pos += 1;
        }
        if (pos + 2 > output.len) {
            return null;
        }
        output[pos] = '\r';
        pos += 1;
        output[pos] = '\n';
        pos += 1;
        const body = response.body[0..response.body_len];
        if (!chunked_transfer_mod.write_chunked_body(body, output, &pos)) {
            return null;
        }
        std.debug.assert(pos <= output.len);
        return pos;
    }
};

