// C-compatible FFI exports for Grain Carry Core API Client
// Grain Style compliant: explicit types, bounded allocations, assertions
//
// Provides C-compatible API for HTTP requests from mobile apps
// Used by mobile apps (Kotlin/Swift) for making API calls

const std = @import("std");
const client = @import("../api/client.zig");
const http_integration = @import("../api/http_client_integration.zig");

// C-compatible return codes
pub const RESULT_SUCCESS: c_int = 0;
pub const RESULT_ERROR: c_int = 1;
pub const RESULT_TIMEOUT: c_int = 2;
pub const RESULT_CONNECTION_ERROR: c_int = 3;
pub const RESULT_INVALID_URL: c_int = 4;
pub const RESULT_INVALID_METHOD: c_int = 5;
pub const RESULT_BODY_TOO_LARGE: c_int = 6;

// C-compatible HTTP method enum
pub const HTTP_METHOD_GET: c_int = 0;
pub const HTTP_METHOD_POST: c_int = 1;
pub const HTTP_METHOD_PUT: c_int = 2;
pub const HTTP_METHOD_DELETE: c_int = 3;
pub const HTTP_METHOD_PATCH: c_int = 4;

// Convert C method to Zig method
fn c_method_to_zig(method: c_int) ?client.HttpMethod {
    return switch (method) {
        HTTP_METHOD_GET => client.HttpMethod.get,
        HTTP_METHOD_POST => client.HttpMethod.post,
        HTTP_METHOD_PUT => client.HttpMethod.put,
        HTTP_METHOD_DELETE => client.HttpMethod.delete,
        HTTP_METHOD_PATCH => client.HttpMethod.patch,
        else => null,
    };
}

// C-compatible API client handle (opaque pointer)
pub const ApiClientHandle = struct {
    client: client.ApiClient,
};

// Global client handles (simple array for now, can be improved with proper memory management)
var client_handles: [16]?ApiClientHandle = [_]?ApiClientHandle{null} ** 16;
var next_handle_id: u32 = 0;

// Create API client and return handle ID
export fn grain_carry_create_api_client(
    base_url_ptr: [*c]const u8,
    base_url_len: u32,
) c_int {
    std.debug.assert(base_url_ptr != null);
    std.debug.assert(base_url_len > 0);
    std.debug.assert(base_url_len <= client.MAX_URL_LEN);
    
    if (next_handle_id >= client_handles.len) {
        return -1; // No available handles
    }
    
    const base_url = base_url_ptr[0..base_url_len];
    var api_client = client.ApiClient.init(base_url);
    
    var handle = ApiClientHandle{
        .client = api_client,
    };
    
    const handle_id = next_handle_id;
    client_handles[handle_id] = handle;
    next_handle_id += 1;
    
    std.debug.assert(handle_id < client_handles.len);
    std.debug.assert(client_handles[handle_id] != null);
    
    return @intCast(handle_id);
}

// Add default header to API client
export fn grain_carry_api_client_add_header(
    handle_id: c_int,
    name_ptr: [*c]const u8,
    name_len: u32,
    value_ptr: [*c]const u8,
    value_len: u32,
) c_int {
    std.debug.assert(handle_id >= 0);
    std.debug.assert(@as(u32, @intCast(handle_id)) < client_handles.len);
    std.debug.assert(name_ptr != null);
    std.debug.assert(name_len > 0);
    std.debug.assert(name_len <= client.MAX_HEADER_NAME_LEN);
    std.debug.assert(value_ptr != null);
    std.debug.assert(value_len <= client.MAX_HEADER_VALUE_LEN);
    
    if (client_handles[@intCast(handle_id)] == null) {
        return RESULT_ERROR;
    }
    
    const name = name_ptr[0..name_len];
    const value = value_ptr[0..value_len];
    
    const success = client_handles[@intCast(handle_id)].?.client.add_default_header(name, value);
    
    std.debug.assert(name.len == name_len);
    std.debug.assert(value.len == value_len);
    
    return if (success) RESULT_SUCCESS else RESULT_ERROR;
}

// Create HTTP request (returns request handle ID)
var request_handles: [32]?client.Request = [_]?client.Request{null} ** 32;
var next_request_id: u32 = 0;

export fn grain_carry_create_request(
    handle_id: c_int,
    method: c_int,
    path_ptr: [*c]const u8,
    path_len: u32,
) c_int {
    std.debug.assert(handle_id >= 0);
    std.debug.assert(@as(u32, @intCast(handle_id)) < client_handles.len);
    std.debug.assert(path_ptr != null);
    std.debug.assert(path_len > 0);
    std.debug.assert(path_len <= client.MAX_URL_LEN);
    
    if (client_handles[@intCast(handle_id)] == null) {
        return -1;
    }
    
    if (next_request_id >= request_handles.len) {
        return -1; // No available request handles
    }
    
    const zig_method = c_method_to_zig(method) orelse {
        return -1;
    };
    
    const path = path_ptr[0..path_len];
    const req = client_handles[@intCast(handle_id)].?.client.create_request(zig_method, path);
    
    const request_id = next_request_id;
    request_handles[request_id] = req;
    next_request_id += 1;
    
    std.debug.assert(request_id < request_handles.len);
    std.debug.assert(request_handles[request_id] != null);
    
    return @intCast(request_id);
}

// Add header to request
export fn grain_carry_request_add_header(
    request_id: c_int,
    name_ptr: [*c]const u8,
    name_len: u32,
    value_ptr: [*c]const u8,
    value_len: u32,
) c_int {
    std.debug.assert(request_id >= 0);
    std.debug.assert(@as(u32, @intCast(request_id)) < request_handles.len);
    std.debug.assert(name_ptr != null);
    std.debug.assert(name_len > 0);
    std.debug.assert(name_len <= client.MAX_HEADER_NAME_LEN);
    std.debug.assert(value_ptr != null);
    std.debug.assert(value_len <= client.MAX_HEADER_VALUE_LEN);
    
    if (request_handles[@intCast(request_id)] == null) {
        return RESULT_ERROR;
    }
    
    const name = name_ptr[0..name_len];
    const value = value_ptr[0..value_len];
    
    const success = request_handles[@intCast(request_id)].?.add_header(name, value);
    
    std.debug.assert(name.len == name_len);
    std.debug.assert(value.len == value_len);
    
    return if (success) RESULT_SUCCESS else RESULT_ERROR;
}

// Set request body
export fn grain_carry_request_set_body(
    request_id: c_int,
    body_ptr: [*c]const u8,
    body_len: u32,
) c_int {
    std.debug.assert(request_id >= 0);
    std.debug.assert(@as(u32, @intCast(request_id)) < request_handles.len);
    std.debug.assert(body_ptr != null);
    std.debug.assert(body_len <= client.MAX_BODY_LEN);
    
    if (request_handles[@intCast(request_id)] == null) {
        return RESULT_ERROR;
    }
    
    const body = body_ptr[0..body_len];
    
    if (body_len > client.MAX_BODY_LEN) {
        return RESULT_BODY_TOO_LARGE;
    }
    
    const success = request_handles[@intCast(request_id)].?.set_body(body);
    
    std.debug.assert(body.len == body_len);
    
    return if (success) RESULT_SUCCESS else RESULT_ERROR;
}

// Get request URL (for debugging/logging)
export fn grain_carry_request_get_url(
    request_id: c_int,
    url_out: [*c]u8,
    url_out_len: u32,
) c_int {
    std.debug.assert(request_id >= 0);
    std.debug.assert(@as(u32, @intCast(request_id)) < request_handles.len);
    std.debug.assert(url_out != null);
    std.debug.assert(url_out_len >= client.MAX_URL_LEN);
    
    if (request_handles[@intCast(request_id)] == null) {
        return RESULT_ERROR;
    }
    
    const req = request_handles[@intCast(request_id)].?;
    const url = req.url[0..req.url_len];
    
    if (url_out_len < req.url_len) {
        return RESULT_ERROR;
    }
    
    std.mem.copyForwards(u8, url_out[0..req.url_len], url);
    
    std.debug.assert(url.len == req.url_len);
    
    return @intCast(req.url_len);
}

// Note: Actual HTTP request sending would require integration with Core Agent's HTTP client
// This is a placeholder for the FFI interface. The actual send function would:
// 1. Get the HTTP client from http_integration
// 2. Convert the Request to Core HTTP client format
// 3. Send the request
// 4. Return response data
// This will be implemented when Core Agent HTTP event publishing is ready.
