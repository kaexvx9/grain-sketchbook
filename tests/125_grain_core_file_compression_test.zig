const std = @import("std");
const testing = std.testing;
const file_compression = @import("grain_core").file_compression;

test "compression metadata init" {
    const metadata = file_compression.CompressionMetadata.init();
    std.debug.assert(metadata.algorithm == file_compression.CompressionAlgorithm.none);
    std.debug.assert(metadata.original_size == 0);
    std.debug.assert(metadata.compressed_size == 0);
    std.debug.assert(metadata.compression_ratio == 0.0);
}

test "compression metadata calculate ratio" {
    var metadata = file_compression.CompressionMetadata.init();
    metadata.original_size = 1000;
    metadata.compressed_size = 500;
    metadata.calculate_ratio();
    std.debug.assert(metadata.compression_ratio == 0.5);
}

test "compression metadata calculate ratio - zero original" {
    var metadata = file_compression.CompressionMetadata.init();
    metadata.original_size = 0;
    metadata.compressed_size = 100;
    metadata.calculate_ratio();
    std.debug.assert(metadata.compression_ratio == 0.0);
}

test "compress gzip - basic" {
    const allocator = testing.allocator;
    const data = "Hello, World! This is a test string for compression.";
    const compressed = try file_compression.compress_gzip(allocator, data);
    defer allocator.free(compressed);
    std.debug.assert(compressed.len > 0);
    std.debug.assert(compressed.len < data.len * 2);
}

test "decompress gzip - round trip" {
    const allocator = testing.allocator;
    const original = "Hello, World! This is a test string for compression.";
    const compressed = try file_compression.compress_gzip(allocator, original);
    defer allocator.free(compressed);
    const decompressed = try file_compression.decompress_gzip(allocator, compressed);
    defer allocator.free(decompressed);
    std.debug.assert(std.mem.eql(u8, original, decompressed));
}

test "compress zstd - basic" {
    const allocator = testing.allocator;
    const data = "Hello, World! This is a test string for compression.";
    const compressed = try file_compression.compress_zstd(allocator, data);
    defer allocator.free(compressed);
    std.debug.assert(compressed.len > 0);
    std.debug.assert(compressed.len < data.len * 2);
}

test "decompress zstd - round trip" {
    const allocator = testing.allocator;
    const original = "Hello, World! This is a test string for compression.";
    const compressed = try file_compression.compress_zstd(allocator, original);
    defer allocator.free(compressed);
    const decompressed = try file_compression.decompress_zstd(allocator, compressed);
    defer allocator.free(decompressed);
    std.debug.assert(std.mem.eql(u8, original, decompressed));
}

test "compress - gzip algorithm" {
    const allocator = testing.allocator;
    const data = "Hello, World!";
    const compressed = try file_compression.compress(
        allocator,
        data,
        file_compression.CompressionAlgorithm.gzip,
    );
    defer allocator.free(compressed);
    std.debug.assert(compressed.len > 0);
}

test "compress - zstd algorithm" {
    const allocator = testing.allocator;
    const data = "Hello, World!";
    const compressed = try file_compression.compress(
        allocator,
        data,
        file_compression.CompressionAlgorithm.zstd,
    );
    defer allocator.free(compressed);
    std.debug.assert(compressed.len > 0);
}

test "compress - none algorithm" {
    const allocator = testing.allocator;
    const data = "Hello, World!";
    const compressed = try file_compression.compress(
        allocator,
        data,
        file_compression.CompressionAlgorithm.none,
    );
    defer allocator.free(compressed);
    std.debug.assert(std.mem.eql(u8, data, compressed));
}

test "decompress - gzip algorithm" {
    const allocator = testing.allocator;
    const original = "Hello, World!";
    const compressed = try file_compression.compress_gzip(allocator, original);
    defer allocator.free(compressed);
    const decompressed = try file_compression.decompress(
        allocator,
        compressed,
        file_compression.CompressionAlgorithm.gzip,
    );
    defer allocator.free(decompressed);
    std.debug.assert(std.mem.eql(u8, original, decompressed));
}

test "decompress - zstd algorithm" {
    const allocator = testing.allocator;
    const original = "Hello, World!";
    const compressed = try file_compression.compress_zstd(allocator, original);
    defer allocator.free(compressed);
    const decompressed = try file_compression.decompress(
        allocator,
        compressed,
        file_compression.CompressionAlgorithm.zstd,
    );
    defer allocator.free(decompressed);
    std.debug.assert(std.mem.eql(u8, original, decompressed));
}

test "compression manager init" {
    const manager = file_compression.CompressionManager.init();
    std.debug.assert(manager.default_algorithm ==
        file_compression.CompressionAlgorithm.gzip);
}

test "compression manager compress file" {
    const allocator = testing.allocator;
    const manager = file_compression.CompressionManager.init();
    const data = "Hello, World! This is a test string.";
    const timestamp: u64 = 1000;
    const metadata = try manager.compress_file(allocator, data, timestamp);
    std.debug.assert(metadata.algorithm ==
        file_compression.CompressionAlgorithm.gzip);
    std.debug.assert(metadata.original_size == data.len);
    std.debug.assert(metadata.compressed_size > 0);
    std.debug.assert(metadata.timestamp == timestamp);
    std.debug.assert(metadata.compression_ratio > 0.0);
}

test "compression manager decompress file" {
    const allocator = testing.allocator;
    const manager = file_compression.CompressionManager.init();
    const original = "Hello, World!";
    const compressed = try file_compression.compress_gzip(allocator, original);
    defer allocator.free(compressed);
    const decompressed = try manager.decompress_file(
        allocator,
        compressed,
        file_compression.CompressionAlgorithm.gzip,
    );
    defer allocator.free(decompressed);
    std.debug.assert(std.mem.eql(u8, original, decompressed));
}

test "compress large data" {
    const allocator = testing.allocator;
    var large_data: [10000]u8 = undefined;
    var i: u32 = 0;
    while (i < 10000) : (i += 1) {
        large_data[i] = @intCast(i % 256);
    }
    const compressed = try file_compression.compress_gzip(allocator, &large_data);
    defer allocator.free(compressed);
    std.debug.assert(compressed.len > 0);
    const decompressed = try file_compression.decompress_gzip(allocator, compressed);
    defer allocator.free(decompressed);
    std.debug.assert(std.mem.eql(u8, &large_data, decompressed));
}
