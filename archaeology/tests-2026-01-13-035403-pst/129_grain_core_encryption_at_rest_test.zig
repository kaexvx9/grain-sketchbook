const std = @import("std");
const testing = std.testing;
const encryption_at_rest = @import("grain_core").encryption_at_rest;
const file_encryption = @import("grain_core").file_encryption;

test "encryption at rest config init" {
    const config = encryption_at_rest.EncryptionAtRestConfig.init();
    std.debug.assert(config.enabled == false);
    std.debug.assert(config.default_key_id == 0);
    std.debug.assert(config.encrypt_on_write == true);
    std.debug.assert(config.decrypt_on_read == true);
}

test "encrypted file metadata init" {
    const metadata = encryption_at_rest.EncryptedFileMetadata.init();
    std.debug.assert(metadata.file_path_len == 0);
    std.debug.assert(metadata.key_id == 0);
    std.debug.assert(metadata.encrypted == false);
}

test "encryption at rest manager init" {
    const manager = encryption_at_rest.EncryptionAtRestManager.init();
    std.debug.assert(manager.config.enabled == false);
    std.debug.assert(manager.keys_len == 0);
    std.debug.assert(manager.metadata_len == 0);
}

test "encryption at rest manager enable encryption" {
    var manager = encryption_at_rest.EncryptionAtRestManager.init();
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    const enabled = manager.enable_encryption(key);
    std.debug.assert(enabled);
    std.debug.assert(manager.config.enabled == true);
    std.debug.assert(manager.keys_len == 1);
    std.debug.assert(manager.config.default_key_id == 0);
}

test "encryption at rest manager encrypt data - disabled" {
    const allocator = testing.allocator;
    var manager = encryption_at_rest.EncryptionAtRestManager.init();
    const data = "Hello, World!";
    const file_path = "/home/user/file.txt";
    const encrypted = try manager.encrypt_data(allocator, data, file_path);
    defer allocator.free(encrypted);
    std.debug.assert(std.mem.eql(u8, data, encrypted));
}

test "encryption at rest manager encrypt data - enabled" {
    const allocator = testing.allocator;
    var manager = encryption_at_rest.EncryptionAtRestManager.init();
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    _ = manager.enable_encryption(key);
    const data = "Hello, World!";
    const file_path = "/home/user/file.txt";
    const encrypted = try manager.encrypt_data(allocator, data, file_path);
    defer allocator.free(encrypted);
    std.debug.assert(!std.mem.eql(u8, data, encrypted));
    std.debug.assert(encrypted.len > data.len);
}

test "encryption at rest manager decrypt data - disabled" {
    const allocator = testing.allocator;
    var manager = encryption_at_rest.EncryptionAtRestManager.init();
    const data = "Hello, World!";
    const file_path = "/home/user/file.txt";
    const decrypted = try manager.decrypt_data(allocator, data, file_path);
    defer allocator.free(decrypted);
    std.debug.assert(std.mem.eql(u8, data, decrypted));
}

test "encryption at rest manager decrypt data - enabled" {
    const allocator = testing.allocator;
    var manager = encryption_at_rest.EncryptionAtRestManager.init();
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    _ = manager.enable_encryption(key);
    const original = "Hello, World!";
    const file_path = "/home/user/file.txt";
    const encrypted = try manager.encrypt_data(allocator, original, file_path);
    defer allocator.free(encrypted);
    const decrypted = try manager.decrypt_data(allocator, encrypted, file_path);
    defer allocator.free(decrypted);
    std.debug.assert(std.mem.eql(u8, original, decrypted));
}

test "encryption at rest manager round trip" {
    const allocator = testing.allocator;
    var manager = encryption_at_rest.EncryptionAtRestManager.init();
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    _ = manager.enable_encryption(key);
    const original = "This is a test string for encryption at rest.";
    const file_path = "/home/user/test.txt";
    const encrypted = try manager.encrypt_data(allocator, original, file_path);
    defer allocator.free(encrypted);
    std.debug.assert(manager.metadata_len == 1);
    std.debug.assert(manager.metadata[0].encrypted == true);
    const decrypted = try manager.decrypt_data(allocator, encrypted, file_path);
    defer allocator.free(decrypted);
    std.debug.assert(std.mem.eql(u8, original, decrypted));
}

test "encryption at rest manager is encryption enabled" {
    var manager = encryption_at_rest.EncryptionAtRestManager.init();
    std.debug.assert(!manager.is_encryption_enabled());
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    _ = manager.enable_encryption(key);
    std.debug.assert(manager.is_encryption_enabled());
}

test "encryption at rest manager multiple files" {
    const allocator = testing.allocator;
    var manager = encryption_at_rest.EncryptionAtRestManager.init();
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    _ = manager.enable_encryption(key);
    const data1 = "File 1 content";
    const data2 = "File 2 content";
    const path1 = "/home/user/file1.txt";
    const path2 = "/home/user/file2.txt";
    const enc1 = try manager.encrypt_data(allocator, data1, path1);
    defer allocator.free(enc1);
    const enc2 = try manager.encrypt_data(allocator, data2, path2);
    defer allocator.free(enc2);
    std.debug.assert(manager.metadata_len == 2);
    const dec1 = try manager.decrypt_data(allocator, enc1, path1);
    defer allocator.free(dec1);
    const dec2 = try manager.decrypt_data(allocator, enc2, path2);
    defer allocator.free(dec2);
    std.debug.assert(std.mem.eql(u8, data1, dec1));
    std.debug.assert(std.mem.eql(u8, data2, dec2));
}
