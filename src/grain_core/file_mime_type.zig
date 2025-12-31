//! Grain Core File MIME Type: MIME type detection for files.
//!
//! Why: Detect MIME types from file extensions and content for file operations.
//! Architecture: Extension-based MIME type mapping with content negotiation
//! support.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");
const content_negotiation = @import("content_negotiation.zig");

// Bounded: Max file extension length.
pub const MAX_EXTENSION_LEN: u32 = 16;

// Bounded: Max MIME type string length.
pub const MAX_MIME_TYPE_LEN: u32 = 128;

// Bounded: Max MIME type mappings.
pub const MAX_MIME_MAPPINGS: u32 = 256;

// MIME type mapping entry.
const MimeTypeMapping = struct {
    extension: [MAX_EXTENSION_LEN]u8,
    extension_len: u32,
    mime_type: [MAX_MIME_TYPE_LEN]u8,
    mime_type_len: u32,
    active: bool,

    pub fn init() MimeTypeMapping {
        var mapping = MimeTypeMapping{
            .extension = undefined,
            .extension_len = 0,
            .mime_type = undefined,
            .mime_type_len = 0,
            .active = false,
        };
        var i: u32 = 0;
        while (i < MAX_EXTENSION_LEN) : (i += 1) {
            mapping.extension[i] = 0;
        }
        i = 0;
        while (i < MAX_MIME_TYPE_LEN) : (i += 1) {
            mapping.mime_type[i] = 0;
        }
        std.debug.assert(!mapping.active);
        return mapping;
    }
};

// File MIME type detector: detects MIME types from file extensions.
pub const FileMimeTypeDetector = struct {
    mappings: [MAX_MIME_MAPPINGS]MimeTypeMapping,
    mappings_len: u32,

    pub fn init() FileMimeTypeDetector {
        var detector = FileMimeTypeDetector{
            .mappings = undefined,
            .mappings_len = 0,
        };
        var i: u32 = 0;
        while (i < MAX_MIME_MAPPINGS) : (i += 1) {
            detector.mappings[i] = MimeTypeMapping.init();
        }
        detector.init_default_mappings();
        std.debug.assert(detector.mappings_len > 0);
        return detector;
    }

    fn init_default_mappings(self: *FileMimeTypeDetector) void {
        std.debug.assert(self.mappings_len == 0);
        const default_mappings = [_]struct { ext: []const u8, mime: []const u8 }{
            .{ .ext = "txt", .mime = "text/plain" },
            .{ .ext = "json", .mime = "application/json" },
            .{ .ext = "xml", .mime = "application/xml" },
            .{ .ext = "html", .mime = "text/html" },
            .{ .ext = "css", .mime = "text/css" },
            .{ .ext = "js", .mime = "application/javascript" },
            .{ .ext = "png", .mime = "image/png" },
            .{ .ext = "jpg", .mime = "image/jpeg" },
            .{ .ext = "jpeg", .mime = "image/jpeg" },
            .{ .ext = "gif", .mime = "image/gif" },
            .{ .ext = "pdf", .mime = "application/pdf" },
            .{ .ext = "zip", .mime = "application/zip" },
            .{ .ext = "gz", .mime = "application/gzip" },
        };
        var i: u32 = 0;
        while (i < default_mappings.len and self.mappings_len < MAX_MIME_MAPPINGS) : (i += 1) {
            const mapping = &self.mappings[self.mappings_len];
            const ext = default_mappings[i].ext;
            const mime = default_mappings[i].mime;
            const ext_len = @min(ext.len, MAX_EXTENSION_LEN);
            const mime_len = @min(mime.len, MAX_MIME_TYPE_LEN);
            var j: u32 = 0;
            while (j < ext_len) : (j += 1) {
                mapping.extension[j] = ext[j];
            }
            mapping.extension_len = @intCast(ext_len);
            j = 0;
            while (j < mime_len) : (j += 1) {
                mapping.mime_type[j] = mime[j];
            }
            mapping.mime_type_len = @intCast(mime_len);
            mapping.active = true;
            self.mappings_len += 1;
        }
        std.debug.assert(self.mappings_len <= MAX_MIME_MAPPINGS);
    }

    pub fn detect_mime_type(
        self: *const FileMimeTypeDetector,
        file_path: []const u8,
    ) ?[]const u8 {
        std.debug.assert(file_path.len > 0);
        std.debug.assert(self.mappings_len <= MAX_MIME_MAPPINGS);
        const extension = self.extract_extension(file_path);
        if (extension.len == 0) {
            return "application/octet-stream";
        }
        var i: u32 = 0;
        while (i < self.mappings_len) : (i += 1) {
            if (self.mappings[i].active) {
                const mapped_ext = self.mappings[i].extension[0..
                    self.mappings[i].extension_len];
                if (std.mem.eql(u8, mapped_ext, extension)) {
                    return self.mappings[i].mime_type[0..
                        self.mappings[i].mime_type_len];
                }
            }
        }
        return "application/octet-stream";
    }

    fn extract_extension(self: *const FileMimeTypeDetector, file_path: []const u8) []const u8 {
        _ = self;
        std.debug.assert(file_path.len > 0);
        var i: u32 = @intCast(file_path.len);
        while (i > 0) : (i -= 1) {
            if (file_path[i - 1] == '.') {
                if (i < file_path.len) {
                    return file_path[i..];
                }
                return "";
            }
            if (file_path[i - 1] == '/' or file_path[i - 1] == '\\') {
                return "";
            }
        }
        return "";
    }

    pub fn negotiate_file_content_type(
        self: *const FileMimeTypeDetector,
        file_path: []const u8,
        accept_header: ?[]const u8,
    ) []const u8 {
        std.debug.assert(file_path.len > 0);
        const detected_mime = self.detect_mime_type(file_path);
        const default_mime = detected_mime orelse "application/octet-stream";
        if (accept_header == null) {
            return default_mime;
        }
        var negotiator = content_negotiation.ContentNegotiator.init();
        if (negotiator.parse_accept_header(accept_header.?)) {
            const available_types = [_][]const u8{default_mime};
            const negotiated = negotiator.negotiate_content_type(&available_types);
            if (negotiated) |mime| {
                return mime;
            }
        }
        return default_mime;
    }
};
