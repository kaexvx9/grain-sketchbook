const std = @import("std");
const testing = std.testing;
const file_encryption = @import("grain_core").file_encryption;

test "encryption key init" {
    const key = file_encryption.EncryptionKey.init();
    var i: u32 = 0;
    while (i < file_encryption.AES_256_KEY_SIZE) : (i += 1) {
        std.debug.assert(key.key[i] == 0);
    }
}

test "encryption key from bytes" {
    var key_bytes: [32]u8 = undefined;
    var i: u32 = 0;
    while (i < 32) : (i += 1) {
        key_bytes[i] = @intCast(i);
    }
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    i = 0;
    while (i < 32) : (i += 1) {
        std.debug.assert(key.key[i] == @intCast(i));
    }
}

test "encryption metadata init" {
    const metadata = file_encryption.EncryptionMetadata.init();
    std.debug.assert(metadata.algorithm_len > 0);
    std.debug.assert(metadata.encrypted_size == 0);
}

test "generate nonce" {
    const allocator = testing.allocator;
    const nonce = try file_encryption.generate_nonce(allocator);
    defer allocator.free(nonce);
    std.debug.assert(nonce.len == file_encryption.GCM_NONCE_SIZE);
}

test "encrypt decrypt aes256 gcm - round trip" {
    const allocator = testing.allocator;
    const data = "Hello, World! This is a test string for encryption.";
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
    std.debug.assert(encrypted.len == data.len + file_encryption.GCM_TAG_SIZE);
    const decrypted = try file_encryption.decrypt_aes256_gcm(
        allocator,
        encrypted,
        &key,
        nonce,
    );
    defer allocator.free(decrypted);
    std.debug.assert(std.mem.eql(u8, data, decrypted));
}

test "encryption manager init" {
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    const manager = file_encryption.EncryptionManager.init(key);
    std.debug.assert(manager.default_key.key.len == 32);
}

test "encryption manager encrypt file" {
    const allocator = testing.allocator;
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    const manager = file_encryption.EncryptionManager.init(key);
    const data = "Hello, World!";
    const metadata = try manager.encrypt_file(allocator, data);
    std.debug.assert(metadata.encrypted_size > 0);
    std.debug.assert(metadata.encrypted_size == data.len +
        file_encryption.GCM_TAG_SIZE);
}

test "encryption manager decrypt file" {
    const allocator = testing.allocator;
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    const manager = file_encryption.EncryptionManager.init(key);
    const original = "Hello, World!";
    const nonce = try file_encryption.generate_nonce(allocator);
    defer allocator.free(nonce);
    const encrypted = try file_encryption.encrypt_aes256_gcm(
        allocator,
        original,
        &key,
        nonce,
    );
    defer allocator.free(encrypted);
    const decrypted = try manager.decrypt_file(allocator, encrypted, nonce);
    defer allocator.free(decrypted);
    std.debug.assert(std.mem.eql(u8, original, decrypted));
}

test "encrypt decrypt - different data sizes" {
    const allocator = testing.allocator;
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    const test_strings = [_][]const u8{
        "A",
        "Hello",
        "Hello, World!",
        "This is a longer test string for encryption testing.",
    };
    for (test_strings) |test_data| {
        const nonce = try file_encryption.generate_nonce(allocator);
        defer allocator.free(nonce);
        const encrypted = try file_encryption.encrypt_aes256_gcm(
            allocator,
            test_data,
            &key,
            nonce,
        );
        defer allocator.free(encrypted);
        const decrypted = try file_encryption.decrypt_aes256_gcm(
            allocator,
            encrypted,
            &key,
            nonce,
        );
        defer allocator.free(decrypted);
        std.debug.assert(std.mem.eql(u8, test_data, decrypted));
    }
}
