//! Grain Core Storage Performance Tests.
//!
//! Why: Benchmark performance of storage operations (compression, encryption,
//! path resolution).
//! Architecture: Performance benchmarks for critical operations.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const file_compression = @import("grain_core").file_compression;
const file_encryption = @import("grain_core").file_encryption;
const path_resolver = @import("grain_core").path_resolver;

test "performance - path normalization - small path" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "/home/user/file.txt";
    const start = std.time.nanoTimestamp();
    const normalized = path_resolver.normalize_path(path, &result);
    const elapsed = std.time.nanoTimestamp() - start;
    std.debug.assert(normalized);
    std.debug.assert(elapsed < 1_000_000_000);
}

test "performance - path normalization - complex path" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "/home/user/../other/./file/../../data/file.txt";
    const start = std.time.nanoTimestamp();
    const normalized = path_resolver.normalize_path(path, &result);
    const elapsed = std.time.nanoTimestamp() - start;
    std.debug.assert(normalized);
    std.debug.assert(elapsed < 1_000_000_000);
}

test "performance - gzip compression - small data" {
    const allocator = testing.allocator;
    const data = "Hello, World!";
    const start = std.time.nanoTimestamp();
    const compressed = try file_compression.compress_gzip(allocator, data);
    defer allocator.free(compressed);
    const elapsed = std.time.nanoTimestamp() - start;
    std.debug.assert(compressed.len > 0);
    std.debug.assert(elapsed < 10_000_000_000);
}

test "performance - gzip compression - large data" {
    const allocator = testing.allocator;
    var large_data: [100000]u8 = undefined;
    var i: u32 = 0;
    while (i < 100000) : (i += 1) {
        large_data[i] = @intCast(i % 256);
    }
    const start = std.time.nanoTimestamp();
    const compressed = try file_compression.compress_gzip(allocator, &large_data);
    defer allocator.free(compressed);
    const elapsed = std.time.nanoTimestamp() - start;
    std.debug.assert(compressed.len > 0);
    std.debug.assert(elapsed < 100_000_000_000);
}

test "performance - gzip decompression" {
    const allocator = testing.allocator;
    const data = "Hello, World! This is test data for decompression.";
    const compressed = try file_compression.compress_gzip(allocator, data);
    defer allocator.free(compressed);
    const start = std.time.nanoTimestamp();
    const decompressed = try file_compression.decompress_gzip(allocator, compressed);
    defer allocator.free(decompressed);
    const elapsed = std.time.nanoTimestamp() - start;
    std.debug.assert(std.mem.eql(u8, data, decompressed));
    std.debug.assert(elapsed < 10_000_000_000);
}

test "performance - aes256 gcm encryption - small data" {
    const allocator = testing.allocator;
    const data = "Hello, World!";
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    const nonce = try file_encryption.generate_nonce(allocator);
    defer allocator.free(nonce);
    const start = std.time.nanoTimestamp();
    const encrypted = try file_encryption.encrypt_aes256_gcm(
        allocator,
        data,
        &key,
        nonce,
    );
    defer allocator.free(encrypted);
    const elapsed = std.time.nanoTimestamp() - start;
    std.debug.assert(encrypted.len > data.len);
    std.debug.assert(elapsed < 10_000_000_000);
}

test "performance - aes256 gcm decryption" {
    const allocator = testing.allocator;
    const data = "Hello, World!";
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    const nonce = try file_encryption.generate_nonce(allocator);
    defer allocator.free(nonce);
    const encrypted = try file_encryption.encrypt_aes256_gcm(
        allocator,
        data,
        &key,
        nonce,
    );
    defer allocator.free(encrypted);
    const start = std.time.nanoTimestamp();
    const decrypted = try file_encryption.decrypt_aes256_gcm(
        allocator,
        encrypted,
        &key,
        nonce,
    );
    defer allocator.free(decrypted);
    const elapsed = std.time.nanoTimestamp() - start;
    std.debug.assert(std.mem.eql(u8, data, decrypted));
    std.debug.assert(elapsed < 10_000_000_000);
}

test "performance - compression then encryption" {
    const allocator = testing.allocator;
    const data = "Hello, World! This is test data.";
    const start = std.time.nanoTimestamp();
    const compressed = try file_compression.compress_gzip(allocator, data);
    defer allocator.free(compressed);
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    const nonce = try file_encryption.generate_nonce(allocator);
    defer allocator.free(nonce);
    const encrypted = try file_encryption.encrypt_aes256_gcm(
        allocator,
        compressed,
        &key,
        nonce,
    );
    defer allocator.free(encrypted);
    const elapsed = std.time.nanoTimestamp() - start;
    std.debug.assert(encrypted.len > 0);
    std.debug.assert(elapsed < 20_000_000_000);
}

test "performance - multiple path normalizations" {
    var result = path_resolver.PathResolutionResult.init();
    const paths = [_][]const u8{
        "/home/user/file1.txt",
        "/home/user/file2.txt",
        "/home/user/../other/file3.txt",
        "./file4.txt",
        "../data/file5.txt",
    };
    const start = std.time.nanoTimestamp();
    var i: u32 = 0;
    while (i < paths.len) : (i += 1) {
        _ = path_resolver.normalize_path(paths[i], &result);
    }
    const elapsed = std.time.nanoTimestamp() - start;
    std.debug.assert(elapsed < 5_000_000_000);
}

test "performance - permission checks" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const start = std.time.nanoTimestamp();
    var i: u32 = 0;
    while (i < 1000) : (i += 1) {
        _ = file_permissions.can_read(&perms, 1000, 100);
        _ = file_permissions.can_write(&perms, 1000, 100);
        _ = file_permissions.can_execute(&perms, 1000, 100);
    }
    const elapsed = std.time.nanoTimestamp() - start;
    std.debug.assert(elapsed < 1_000_000_000);
}
