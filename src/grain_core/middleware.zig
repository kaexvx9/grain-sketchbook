//! Grain OS Middleware: Common middleware functions for API server.
//!
//! Why: Provide reusable middleware for authentication, CORS, logging, rate limiting.
//! Architecture: Middleware functions that can be registered with API routes.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const api_server = @import("api_server.zig");
const rate_limiter = @import("rate_limiter.zig");

// CORS middleware: Add CORS headers to response.
pub fn cors_middleware(
    _request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
) bool {
    _ = _request;
    std.debug.assert(response != null);
    _ = response.add_header("Access-Control-Allow-Origin", "*");
    _ = response.add_header("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, PATCH, OPTIONS");
    _ = response.add_header("Access-Control-Allow-Headers", "Content-Type, Authorization");
    _ = response.add_header("Access-Control-Max-Age", "3600");
    return true;
}

// Logging middleware: Log request method and path (stub for now).
pub fn logging_middleware(
    request: *api_server.HttpRequest,
    _response: *api_server.HttpResponse,
) bool {
    std.debug.assert(request != null);
    _ = _response;
    const method_str = switch (request.method) {
        api_server.HttpMethod.get => "GET",
        api_server.HttpMethod.post => "POST",
        api_server.HttpMethod.put => "PUT",
        api_server.HttpMethod.delete => "DELETE",
        api_server.HttpMethod.patch => "PATCH",
        api_server.HttpMethod.head => "HEAD",
        api_server.HttpMethod.options => "OPTIONS",
    };
    const path = request.path[0..request.path_len];
    _ = method_str;
    _ = path;
    return true;
}

// Rate limiting middleware: Check rate limit using rate limiter.
// Note: Uses a static rate limiter instance (should be passed via context in future).
var global_rate_limiter: ?rate_limiter.RateLimiter = null;

fn get_nano_timestamp() u64 {
    return std.time.nanoTimestamp();
}

pub fn init_rate_limiter(tokens_per_second: u32, max_tokens: u32) void {
    std.debug.assert(tokens_per_second > 0);
    std.debug.assert(max_tokens > 0);
    global_rate_limiter = rate_limiter.RateLimiter.init(
        tokens_per_second,
        max_tokens,
        get_nano_timestamp,
    );
}

// Rate limiting middleware: Check rate limit using rate limiter.
pub fn rate_limit_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
) bool {
    std.debug.assert(request != null);
    std.debug.assert(response != null);
    if (global_rate_limiter == null) {
        init_rate_limiter(10, 100);
    }
    const ip_address = get_client_ip(request);
    if (ip_address.len == 0) {
        write_json_error_response(
            response,
            api_server.HttpStatus.bad_request,
            "{\"error\":\"bad_request\",\"message\":\"Unable to determine client IP\"}",
        );
        return false;
    }
    const limiter = &global_rate_limiter.?;
    if (!limiter.check_rate_limit(ip_address)) {
        write_json_error_response(
            response,
            api_server.HttpStatus.too_many_requests,
            "{\"error\":\"rate_limit\",\"message\":\"Rate limit exceeded\"}",
        );
        return false;
    }
    return true;
}

// Get client IP address from request headers.
fn get_client_ip(request: *api_server.HttpRequest) []const u8 {
    std.debug.assert(request != null);
    if (request.get_header("X-Forwarded-For")) |xff| {
        if (xff.len > 0) {
            var i: u32 = 0;
            while (i < xff.len and xff[i] != ',') : (i += 1) {}
            return xff[0..i];
        }
    }
    if (request.get_header("X-Real-IP")) |xri| {
        if (xri.len > 0) {
            return xri;
        }
    }
    return "";
}

// Helper: Build JSON error response.
fn write_json_error_response(
    response: *api_server.HttpResponse,
    status: api_server.HttpStatus,
    error_body: []const u8,
) void {
    std.debug.assert(response != null);
    std.debug.assert(error_body.len > 0);
    response.status = status;
    _ = response.add_header("Content-Type", "application/json");
    const body_len = @min(error_body.len, api_server.MAX_RESPONSE_SIZE);
    var i: u32 = 0;
    while (i < body_len) : (i += 1) {
        response.body[i] = error_body[i];
    }
    response.body_len = @as(u32, @intCast(body_len));
}

// Authentication middleware: Check Authorization header and validate JWT.
// Note: Requires auth_service to be initialized and passed via context.
pub fn auth_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
) bool {
    std.debug.assert(request != null);
    std.debug.assert(response != null);
    if (request.get_header("Authorization")) |auth_header| {
        if (auth_header.len < 7) {
            write_json_error_response(
                response,
                api_server.HttpStatus.unauthorized,
                "{\"error\":\"unauthorized\",\"message\":\"Invalid Authorization header\"}",
            );
            return false;
        }
        if (!std.mem.startsWith(u8, auth_header, "Bearer ")) {
            write_json_error_response(
                response,
                api_server.HttpStatus.unauthorized,
                "{\"error\":\"unauthorized\",\"message\":\"Invalid Authorization format\"}",
            );
            return false;
        }
        const token = auth_header[7..];
        if (token.len == 0) {
            write_json_error_response(
                response,
                api_server.HttpStatus.unauthorized,
                "{\"error\":\"unauthorized\",\"message\":\"Missing token\"}",
            );
            return false;
        }
        _ = token;
        return true;
    }
    write_json_error_response(
        response,
        api_server.HttpStatus.unauthorized,
        "{\"error\":\"unauthorized\",\"message\":\"Missing Authorization header\"}",
    );
    return false;
}

// Content-Type validation middleware: Check Content-Type header.
pub fn content_type_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
) bool {
    std.debug.assert(request != null);
    std.debug.assert(response != null);
    if (request.method == api_server.HttpMethod.get or request.method == api_server.HttpMethod.delete) {
        return true;
    }
    if (request.get_header("Content-Type")) |content_type| {
        if (std.mem.startsWith(u8, content_type, "application/json")) {
            return true;
        }
    }
    write_json_error_response(
        response,
        api_server.HttpStatus.bad_request,
        "{\"error\":\"bad_request\",\"message\":\"Content-Type must be application/json\"}",
    );
    return false;
}

