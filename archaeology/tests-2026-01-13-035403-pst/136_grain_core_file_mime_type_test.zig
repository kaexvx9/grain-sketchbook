//! Grain Core File MIME Type Tests.
//!
//! Why: Test MIME type detection for file operations.
//! Architecture: Unit tests for MIME type detector.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const file_mime_type = @import("grain_core").file_mime_type;

test "file mime type detector init" {
    const detector = file_mime_type.FileMimeTypeDetector.init();
    std.debug.assert(detector.mappings_len > 0);
    std.debug.assert(detector.mappings_len <= file_mime_type.MAX_MIME_MAPPINGS);
}

test "file mime type detect text file" {
    const detector = file_mime_type.FileMimeTypeDetector.init();
    const mime = detector.detect_mime_type("file.txt");
    std.debug.assert(mime != null);
    std.debug.assert(std.mem.eql(u8, mime.?, "text/plain"));
}

test "file mime type detect json file" {
    const detector = file_mime_type.FileMimeTypeDetector.init();
    const mime = detector.detect_mime_type("data.json");
    std.debug.assert(mime != null);
    std.debug.assert(std.mem.eql(u8, mime.?, "application/json"));
}

test "file mime type detect image file" {
    const detector = file_mime_type.FileMimeTypeDetector.init();
    const mime = detector.detect_mime_type("image.png");
    std.debug.assert(mime != null);
    std.debug.assert(std.mem.eql(u8, mime.?, "image/png"));
}

test "file mime type detect unknown extension" {
    const detector = file_mime_type.FileMimeTypeDetector.init();
    const mime = detector.detect_mime_type("file.unknown");
    std.debug.assert(mime != null);
    std.debug.assert(std.mem.eql(u8, mime.?, "application/octet-stream"));
}

test "file mime type detect no extension" {
    const detector = file_mime_type.FileMimeTypeDetector.init();
    const mime = detector.detect_mime_type("file");
    std.debug.assert(mime != null);
    std.debug.assert(std.mem.eql(u8, mime.?, "application/octet-stream"));
}

test "file mime type negotiate with accept header" {
    const detector = file_mime_type.FileMimeTypeDetector.init();
    const mime = detector.negotiate_file_content_type(
        "file.json",
        "application/json",
    );
    std.debug.assert(std.mem.eql(u8, mime, "application/json"));
}

test "file mime type negotiate with wildcard accept" {
    const detector = file_mime_type.FileMimeTypeDetector.init();
    const mime = detector.negotiate_file_content_type(
        "file.txt",
        "*/*",
    );
    std.debug.assert(std.mem.eql(u8, mime, "text/plain"));
}

test "file mime type negotiate without accept header" {
    const detector = file_mime_type.FileMimeTypeDetector.init();
    const mime = detector.negotiate_file_content_type(
        "file.html",
        null,
    );
    std.debug.assert(std.mem.eql(u8, mime, "text/html"));
}

test "file mime type detect with path" {
    const detector = file_mime_type.FileMimeTypeDetector.init();
    const mime = detector.detect_mime_type("/home/user/file.pdf");
    std.debug.assert(mime != null);
    std.debug.assert(std.mem.eql(u8, mime.?, "application/pdf"));
}

test "file mime type detect multiple extensions" {
    const detector = file_mime_type.FileMimeTypeDetector.init();
    const mime1 = detector.detect_mime_type("file.jpg");
    const mime2 = detector.detect_mime_type("file.jpeg");
    std.debug.assert(mime1 != null);
    std.debug.assert(mime2 != null);
    std.debug.assert(std.mem.eql(u8, mime1.?, "image/jpeg"));
    std.debug.assert(std.mem.eql(u8, mime2.?, "image/jpeg"));
}
