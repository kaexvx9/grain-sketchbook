//! Grain Core File Compression: File compression and decompression.
//!
//! Why: Provide file compression and decompression for storage efficiency.
//! Architecture: Gzip and zstd compression support with metadata.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");

// Bounded: Max compressed data size (10x original for safety).
pub const MAX_COMPRESSED_SIZE_MULTIPLIER: u32 = 10;

// Bounded: Max compression metadata size.
pub const MAX_COMPRESSION_METADATA_SIZE: u32 = 128;

// Compression algorithm type.
pub const CompressionAlgorithm = enum(u8) {
    none,
    gzip,
    zstd,
};

// Compression metadata.
pub const CompressionMetadata = struct {
    algorithm: CompressionAlgorithm,
    original_size: u64,
    compressed_size: u64,
    compression_ratio: f32,
    timestamp: u64,

    pub fn init() CompressionMetadata {
        return CompressionMetadata{
            .algorithm = CompressionAlgorithm.none,
            .original_size = 0,
            .compressed_size = 0,
            .compression_ratio = 0.0,
            .timestamp = 0,
        };
    }

    pub fn calculate_ratio(self: *CompressionMetadata) void {
        std.debug.assert(self != null);
        if (self.original_size > 0) {
            self.compression_ratio = @as(f32, @floatFromInt(self.compressed_size)) /
                @as(f32, @floatFromInt(self.original_size));
        } else {
            self.compression_ratio = 0.0;
        }
    }
};

// Compress data using gzip.
pub fn compress_gzip(
    allocator: std.mem.Allocator,
    data: []const u8,
) ![]u8 {
    std.debug.assert(data.len > 0);
    std.debug.assert(allocator != null);
    var compressed = std.ArrayList(u8).init(allocator);
    errdefer compressed.deinit();
    var gzip_writer = std.compress.gzip.compressStream(compressed.writer(), .{});
    try gzip_writer.writeAll(data);
    try gzip_writer.finish();
    return compressed.toOwnedSlice();
}

// Decompress data using gzip.
pub fn decompress_gzip(
    allocator: std.mem.Allocator,
    compressed_data: []const u8,
) ![]u8 {
    std.debug.assert(compressed_data.len > 0);
    std.debug.assert(allocator != null);
    var decompressed = std.ArrayList(u8).init(allocator);
    errdefer decompressed.deinit();
    var gzip_reader = std.compress.gzip.decompressStream(
        allocator,
        compressed_data,
    );
    defer gzip_reader.deinit();
    const max_size: u32 = std.math.maxInt(u32);
    try gzip_reader.reader().readAllArrayList(&decompressed, max_size);
    return decompressed.toOwnedSlice();
}

// Compress data using zstd.
pub fn compress_zstd(
    allocator: std.mem.Allocator,
    data: []const u8,
) ![]u8 {
    std.debug.assert(data.len > 0);
    std.debug.assert(allocator != null);
    var compressed = std.ArrayList(u8).init(allocator);
    errdefer compressed.deinit();
    var zstd_writer = std.compress.zstd.compressStream(
        compressed.writer(),
        .{},
    );
    try zstd_writer.writeAll(data);
    try zstd_writer.finish();
    return compressed.toOwnedSlice();
}

// Decompress data using zstd.
pub fn decompress_zstd(
    allocator: std.mem.Allocator,
    compressed_data: []const u8,
) ![]u8 {
    std.debug.assert(compressed_data.len > 0);
    std.debug.assert(allocator != null);
    var decompressed = std.ArrayList(u8).init(allocator);
    errdefer decompressed.deinit();
    var zstd_reader = std.compress.zstd.decompressStream(
        allocator,
        compressed_data,
    );
    defer zstd_reader.deinit();
    const max_size: u32 = std.math.maxInt(u32);
    try zstd_reader.reader().readAllArrayList(&decompressed, max_size);
    return decompressed.toOwnedSlice();
}

// Compress data with specified algorithm.
pub fn compress(
    allocator: std.mem.Allocator,
    data: []const u8,
    algorithm: CompressionAlgorithm,
) ![]u8 {
    std.debug.assert(data.len > 0);
    std.debug.assert(allocator != null);
    return switch (algorithm) {
        .none => {
            var result = try allocator.alloc(u8, data.len);
            @memcpy(result, data);
            return result;
        },
        .gzip => compress_gzip(allocator, data),
        .zstd => compress_zstd(allocator, data),
    };
}

// Decompress data with specified algorithm.
pub fn decompress(
    allocator: std.mem.Allocator,
    compressed_data: []const u8,
    algorithm: CompressionAlgorithm,
) ![]u8 {
    std.debug.assert(compressed_data.len > 0);
    std.debug.assert(allocator != null);
    return switch (algorithm) {
        .none => {
            var result = try allocator.alloc(u8, compressed_data.len);
            @memcpy(result, compressed_data);
            return result;
        },
        .gzip => decompress_gzip(allocator, compressed_data),
        .zstd => decompress_zstd(allocator, compressed_data),
    };
}

// Compression manager: manages compression operations.
pub const CompressionManager = struct {
    default_algorithm: CompressionAlgorithm,

    pub fn init() CompressionManager {
        return CompressionManager{
            .default_algorithm = CompressionAlgorithm.gzip,
        };
    }

    pub fn compress_file(
        self: *const CompressionManager,
        allocator: std.mem.Allocator,
        data: []const u8,
        timestamp: u64,
    ) !CompressionMetadata {
        std.debug.assert(data.len > 0);
        std.debug.assert(allocator != null);
        std.debug.assert(self != null);
        const compressed = try compress(allocator, data, self.default_algorithm);
        var metadata = CompressionMetadata.init();
        metadata.algorithm = self.default_algorithm;
        metadata.original_size = data.len;
        metadata.compressed_size = compressed.len;
        metadata.timestamp = timestamp;
        metadata.calculate_ratio();
        std.debug.assert(metadata.compressed_size <=
            data.len * MAX_COMPRESSED_SIZE_MULTIPLIER);
        return metadata;
    }

    pub fn decompress_file(
        self: *const CompressionManager,
        allocator: std.mem.Allocator,
        compressed_data: []const u8,
        algorithm: CompressionAlgorithm,
    ) ![]u8 {
        std.debug.assert(compressed_data.len > 0);
        std.debug.assert(allocator != null);
        std.debug.assert(self != null);
        return decompress(allocator, compressed_data, algorithm);
    }
};
