//! Grain OS Content Negotiation: HTTP content type negotiation.
//!
//! Why: Support multiple content types (JSON, XML, plain text, binary) based on Accept header.
//! Architecture: Accept header parsing, content type matching, quality value handling.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const api_server = @import("api_server.zig");

// Bounded: Max content types in Accept header.
pub const MAX_ACCEPT_TYPES: u32 = 16;

// Bounded: Max content type string length.
pub const MAX_CONTENT_TYPE_LEN: u32 = 128;

// Content type with quality value.
pub const ContentTypeWithQuality = struct {
    content_type: [MAX_CONTENT_TYPE_LEN]u8,
    content_type_len: u32,
    quality: u32, // Quality * 1000 (e.g., 0.8 = 800)

    pub fn init() ContentTypeWithQuality {
        var ct = ContentTypeWithQuality{
            .content_type = undefined,
            .content_type_len = 0,
            .quality = 1000, // Default quality = 1.0
        };
        var i: u32 = 0;
        while (i < MAX_CONTENT_TYPE_LEN) : (i += 1) {
            ct.content_type[i] = 0;
        }
        std.debug.assert(ct.quality == 1000);
        std.debug.assert(ct.content_type_len == 0);
        return ct;
    }
};

// Content negotiator: handles Accept header parsing and content type matching.
pub const ContentNegotiator = struct {
    accepted_types: [MAX_ACCEPT_TYPES]ContentTypeWithQuality,
    accepted_types_len: u32,

    pub fn init() ContentNegotiator {
        var negotiator = ContentNegotiator{
            .accepted_types = undefined,
            .accepted_types_len = 0,
        };
        var i: u32 = 0;
        while (i < MAX_ACCEPT_TYPES) : (i += 1) {
            negotiator.accepted_types[i] = ContentTypeWithQuality.init();
        }
        std.debug.assert(negotiator.accepted_types_len == 0);
        return negotiator;
    }

    // Parse Accept header and extract content types with quality values.
    pub fn parse_accept_header(
        self: *ContentNegotiator,
        accept_header: []const u8,
    ) bool {
        std.debug.assert(accept_header.len > 0);
        std.debug.assert(accept_header.len <= api_server.MAX_HEADER_VALUE_LEN);
        std.debug.assert(self.accepted_types_len <= MAX_ACCEPT_TYPES);
        self.accepted_types_len = 0;
        var pos: u32 = 0;
        while (pos < accept_header.len and self.accepted_types_len < MAX_ACCEPT_TYPES) : (pos += 1) {
            while (pos < accept_header.len and accept_header[pos] == ' ') : (pos += 1) {}
            if (pos >= accept_header.len) {
                break;
            }
            const type_start = pos;
            var type_end: u32 = pos;
            var quality: u32 = 1000;
            while (type_end < accept_header.len and accept_header[type_end] != ',' and accept_header[type_end] != ';') : (type_end += 1) {}
            const type_len = @min(type_end - type_start, MAX_CONTENT_TYPE_LEN);
            if (type_len == 0) {
                pos = type_end;
                if (pos < accept_header.len and accept_header[pos] == ',') {
                    pos += 1;
                }
                continue;
            }
            var ct = ContentTypeWithQuality.init();
            var j: u32 = 0;
            while (j < type_len) : (j += 1) {
                ct.content_type[j] = accept_header[type_start + j];
            }
            ct.content_type_len = @intCast(type_len);
            pos = type_end;
            if (pos < accept_header.len and accept_header[pos] == ';') {
                pos += 1;
                while (pos < accept_header.len and accept_header[pos] == ' ') : (pos += 1) {}
                if (pos < accept_header.len and accept_header[pos] == 'q' and pos + 1 < accept_header.len and accept_header[pos + 1] == '=') {
                    pos += 2;
                    const q_start = pos;
                    var q_end = pos;
                    while (q_end < accept_header.len and accept_header[q_end] != ',' and accept_header[q_end] != ' ') : (q_end += 1) {}
                    if (q_end > q_start) {
                        const q_str = accept_header[q_start..q_end];
                        const q_float = std.fmt.parseFloat(f32, q_str) catch 1.0;
                        quality = @as(u32, @intFromFloat(q_float * 1000.0));
                        quality = @min(quality, 1000);
                        pos = q_end;
                    }
                }
            }
            ct.quality = quality;
            self.accepted_types[self.accepted_types_len] = ct;
            self.accepted_types_len += 1;
            if (pos < accept_header.len and accept_header[pos] == ',') {
                pos += 1;
            }
        }
        self.sort_by_quality();
        std.debug.assert(self.accepted_types_len <= MAX_ACCEPT_TYPES);
        std.debug.assert(self.accepted_types_len == 0 or self.accepted_types[0].quality <= 1000);
        return true;
    }

    // Sort accepted types by quality (highest first).
    fn sort_by_quality(self: *ContentNegotiator) void {
        std.debug.assert(self.accepted_types_len <= MAX_ACCEPT_TYPES);
        var i: u32 = 0;
        while (i < self.accepted_types_len) : (i += 1) {
            var j: u32 = i + 1;
            while (j < self.accepted_types_len) : (j += 1) {
                if (self.accepted_types[j].quality > self.accepted_types[i].quality) {
                    const temp = self.accepted_types[i];
                    self.accepted_types[i] = self.accepted_types[j];
                    self.accepted_types[j] = temp;
                }
            }
        }
        if (self.accepted_types_len > 1) {
            std.debug.assert(self.accepted_types[0].quality >= self.accepted_types[1].quality);
        }
    }

    // Find best matching content type from available types.
    pub fn negotiate_content_type(
        self: *const ContentNegotiator,
        available_types: []const []const u8,
    ) ?[]const u8 {
        std.debug.assert(available_types.len > 0);
        std.debug.assert(available_types.len <= 16);
        std.debug.assert(self.accepted_types_len <= MAX_ACCEPT_TYPES);
        var i: u32 = 0;
        while (i < self.accepted_types_len) : (i += 1) {
            const accepted = self.accepted_types[i].content_type[0..self.accepted_types[i].content_type_len];
            var j: u32 = 0;
            while (j < available_types.len) : (j += 1) {
                if (std.mem.eql(u8, accepted, available_types[j])) {
                    return available_types[j];
                }
                if (std.mem.eql(u8, accepted, "*/*")) {
                    if (available_types.len > 0) {
                        return available_types[0];
                    }
                }
                if (std.mem.endsWith(u8, accepted, "/*")) {
                    const prefix = accepted[0..accepted.len - 2];
                    if (std.mem.startsWith(u8, available_types[j], prefix)) {
                        return available_types[j];
                    }
                }
            }
        }
        std.debug.assert(self.accepted_types_len <= MAX_ACCEPT_TYPES);
        return null;
    }

    // Check if content type is accepted.
    pub fn accepts_content_type(
        self: *const ContentNegotiator,
        content_type: []const u8,
    ) bool {
        std.debug.assert(content_type.len > 0);
        std.debug.assert(self.accepted_types_len <= MAX_ACCEPT_TYPES);
        var i: u32 = 0;
        while (i < self.accepted_types_len) : (i += 1) {
            const accepted = self.accepted_types[i].content_type[0..self.accepted_types[i].content_type_len];
            if (std.mem.eql(u8, accepted, content_type)) {
                return true;
            }
            if (std.mem.eql(u8, accepted, "*/*")) {
                return true;
            }
            if (std.mem.endsWith(u8, accepted, "/*")) {
                const prefix = accepted[0..accepted.len - 2];
                if (std.mem.startsWith(u8, content_type, prefix)) {
                    return true;
                }
            }
        }
        return false;
    }
};
