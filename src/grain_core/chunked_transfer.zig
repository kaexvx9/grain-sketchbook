//! Grain OS Chunked Transfer Encoding: HTTP chunked transfer encoding.
//!
//! Why: Support streaming large responses without knowing content length upfront.
//! Architecture: Chunked encoding for requests and responses, chunk parsing.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const api_server = @import("api_server.zig");

// Bounded: Max chunk size (64KB).
pub const MAX_CHUNK_SIZE: u32 = 65536;

// Bounded: Max chunk header length (hex size + CRLF).
pub const MAX_CHUNK_HEADER_LEN: u32 = 16;

// Write chunk to output buffer (chunk size + CRLF + data + CRLF).
pub fn write_chunk(
    data: []const u8,
    output: []u8,
    pos: *u32,
) bool {
    std.debug.assert(data.len <= MAX_CHUNK_SIZE);
    std.debug.assert(output.len > pos.*);
    std.debug.assert(pos.* < output.len);
    if (data.len == 0) {
        if (pos.* + 5 > output.len) {
            return false;
        }
        output[pos.*] = '0';
        pos.* += 1;
        output[pos.*] = '\r';
        pos.* += 1;
        output[pos.*] = '\n';
        pos.* += 1;
        output[pos.*] = '\r';
        pos.* += 1;
        output[pos.*] = '\n';
        pos.* += 1;
        return true;
    }
    var hex_buf: [MAX_CHUNK_HEADER_LEN]u8 = undefined;
    const hex_len = format_hex_size(data.len, &hex_buf);
    if (pos.* + hex_len + 2 + data.len + 2 > output.len) {
        return false;
    }
    var i: u32 = 0;
    while (i < hex_len) : (i += 1) {
        output[pos.*] = hex_buf[i];
        pos.* += 1;
    }
    output[pos.*] = '\r';
    pos.* += 1;
    output[pos.*] = '\n';
    pos.* += 1;
    i = 0;
    while (i < data.len) : (i += 1) {
        output[pos.*] = data[i];
        pos.* += 1;
    }
    output[pos.*] = '\r';
    pos.* += 1;
    output[pos.*] = '\n';
    pos.* += 1;
    std.debug.assert(pos.* <= output.len);
    return true;
}

// Format chunk size as hexadecimal string.
fn format_hex_size(size: u32, buf: []u8) u32 {
    std.debug.assert(size <= MAX_CHUNK_SIZE);
    std.debug.assert(buf.len >= MAX_CHUNK_HEADER_LEN);
    if (size == 0) {
        buf[0] = '0';
        return 1;
    }
    var num = size;
    var len: u32 = 0;
    var digits: [8]u8 = undefined;
    while (num > 0 and len < 8) : (len += 1) {
        const digit = @as(u8, @intCast(num % 16));
        digits[len] = if (digit < 10) ('0' + digit) else ('a' + digit - 10);
        num /= 16;
    }
    var i: u32 = 0;
    while (i < len) : (i += 1) {
        buf[i] = digits[len - 1 - i];
    }
    std.debug.assert(len > 0);
    std.debug.assert(len <= 8);
    return len;
}

// Parse chunk size from chunk header.
pub fn parse_chunk_size(
    chunk_header: []const u8,
) ?u32 {
    std.debug.assert(chunk_header.len > 0);
    std.debug.assert(chunk_header.len <= api_server.MAX_HEADER_VALUE_LEN);
    if (chunk_header.len == 0) {
        return null;
    }
    var size: u32 = 0;
    var i: u32 = 0;
    while (i < chunk_header.len) : (i += 1) {
        const c = chunk_header[i];
        if (c == '\r' or c == '\n' or c == ';') {
            break;
        }
        const digit = if (c >= '0' and c <= '9') (c - '0') else (
            if (c >= 'a' and c <= 'f') (c - 'a' + 10) else (
                if (c >= 'A' and c <= 'F') (c - 'A' + 10) else return null
            )
        );
        size = size * 16 + digit;
        if (size > MAX_CHUNK_SIZE) {
            return null;
        }
    }
    std.debug.assert(size <= MAX_CHUNK_SIZE);
    std.debug.assert(size == 0 or size > 0);
    return size;
}

// Write chunked response body to output.
pub fn write_chunked_body(
    body: []const u8,
    output: []u8,
    pos: *u32,
) bool {
    std.debug.assert(body.len <= api_server.MAX_RESPONSE_SIZE);
    std.debug.assert(output.len > pos.*);
    var remaining = body;
    while (remaining.len > 0) {
        const chunk_size = @min(remaining.len, MAX_CHUNK_SIZE);
        const chunk = remaining[0..chunk_size];
        if (!write_chunk(chunk, output, pos)) {
            return false;
        }
        remaining = remaining[chunk_size..];
    }
    if (!write_chunk("", output, pos)) {
        return false;
    }
    std.debug.assert(pos.* <= output.len);
    return true;
}

// Parse chunked body from input buffer.
pub fn parse_chunked_body(
    input: []const u8,
    body_out: []u8,
    body_len_out: *u32,
) bool {
    std.debug.assert(input.len > 0);
    std.debug.assert(input.len <= api_server.MAX_REQUEST_SIZE);
    std.debug.assert(body_out.len <= api_server.MAX_RESPONSE_SIZE);
    std.debug.assert(body_len_out != null);
    body_len_out.* = 0;
    var pos: u32 = 0;
    while (pos < input.len) {
        const chunk_header_start = pos;
        var chunk_header_end = pos;
        while (chunk_header_end < input.len and input[chunk_header_end] != '\r') : (chunk_header_end += 1) {}
        if (chunk_header_end >= input.len) {
            return false;
        }
        const chunk_header = input[chunk_header_start..chunk_header_end];
        const chunk_size_opt = parse_chunk_size(chunk_header);
        if (chunk_size_opt == null) {
            return false;
        }
        const chunk_size = chunk_size_opt.?;
        if (chunk_size == 0) {
            return true;
        }
        pos = chunk_header_end;
        if (pos + 2 >= input.len or input[pos] != '\r' or input[pos + 1] != '\n') {
            return false;
        }
        pos += 2;
        if (pos + chunk_size + 2 > input.len) {
            return false;
        }
        if (body_len_out.* + chunk_size > body_out.len) {
            return false;
        }
        var i: u32 = 0;
        while (i < chunk_size) : (i += 1) {
            body_out[body_len_out.*] = input[pos + i];
            body_len_out.* += 1;
        }
        pos += chunk_size;
        if (input[pos] != '\r' or input[pos + 1] != '\n') {
            return false;
        }
        pos += 2;
    }
    std.debug.assert(body_len_out.* <= body_out.len);
    return true;
}
