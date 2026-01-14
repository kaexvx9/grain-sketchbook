//! Grain Core Storage Integration Tests.
//!
//! Why: Test integration between storage modules (path resolver, permissions,
//! audit logging, compression, encryption, versioning).
//! Architecture: End-to-end scenarios testing multiple modules together.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const path_resolver = @import("grain_core").path_resolver;
const file_permissions = @import("grain_core").file_permissions;
const audit_logger = @import("grain_core").audit_logger;
const file_compression = @import("grain_core").file_compression;
const file_encryption = @import("grain_core").file_encryption;
const file_versioning = @import("grain_core").file_versioning;
const file_storage = @import("grain_core").file_storage;
const access_control = @import("grain_core").access_control;

test "integration - path resolution with permissions" {
    const allocator = testing.allocator;
    var result = path_resolver.PathResolutionResult.init();
    const path = "/home/user/file.txt";
    const normalized = path_resolver.normalize_path(path, &result);
    std.debug.assert(normalized);
    std.debug.assert(result.is_valid);
    const resolved_path = result.resolved_path[0..result.resolved_path_len];
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can_read = file_permissions.can_read(&perms, 1000, 100);
    std.debug.assert(can_read);
    std.debug.assert(resolved_path.len > 0);
}

test "integration - file operation with audit logging" {
    const allocator = testing.allocator;
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const file_path = "/home/user/file.txt";
    const logged = logger.log_file_open(timestamp, user_id, file_path, true);
    std.debug.assert(logged);
    std.debug.assert(logger.entries_len == 1);
    const entry = logger.entries[0];
    std.debug.assert(entry.operation == audit_logger.FileOperationType.open);
    std.debug.assert(entry.success == true);
}

test "integration - compress then encrypt" {
    const allocator = testing.allocator;
    const data = "Hello, World! This is test data for compression and encryption.";
    const compressed = try file_compression.compress_gzip(allocator, data);
    defer allocator.free(compressed);
    std.debug.assert(compressed.len > 0);
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
    std.debug.assert(encrypted.len > compressed.len);
}

test "integration - decrypt then decompress" {
    const allocator = testing.allocator;
    const original = "Hello, World! This is test data.";
    const compressed = try file_compression.compress_gzip(allocator, original);
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
    const decrypted = try file_encryption.decrypt_aes256_gcm(
        allocator,
        encrypted,
        &key,
        nonce,
    );
    defer allocator.free(decrypted);
    const decompressed = try file_compression.decompress_gzip(allocator, decrypted);
    defer allocator.free(decompressed);
    std.debug.assert(std.mem.eql(u8, original, decompressed));
}

test "integration - file versioning with permissions" {
    const allocator = testing.allocator;
    var version_manager = file_versioning.VersionManager.init();
    const file_path = "/home/user/file.txt";
    var checksum: [32]u8 = undefined;
    std.crypto.random.bytes(&checksum);
    const created_by: u32 = 1000;
    const version_id = version_manager.create_version(
        file_path,
        1000,
        &checksum,
        1000,
        created_by,
        "Initial version",
    );
    std.debug.assert(version_id != null);
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can_write = file_permissions.can_write(&perms, 1000, 100);
    std.debug.assert(can_write);
    const version = version_manager.get_version(version_id.?);
    std.debug.assert(version != null);
}

test "integration - path resolution with file storage" {
    const allocator = testing.allocator;
    var result = path_resolver.PathResolutionResult.init();
    const relative_path = "../data/file.txt";
    const base_path = "/home/user";
    const resolved = path_resolver.resolve_relative_path(
        base_path,
        relative_path,
        &result,
    );
    std.debug.assert(resolved);
    std.debug.assert(result.is_valid);
    const resolved_path = result.resolved_path[0..result.resolved_path_len];
    var manager = file_storage.FileStorageManager.init();
    const handle = manager.open_file(
        resolved_path,
        file_storage.FileMode.read_write,
        1000,
    );
    std.debug.assert(handle != null);
}

test "integration - audit logging with permissions check" {
    const allocator = testing.allocator;
    var logger = audit_logger.AuditLogger.init();
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const user_id: u32 = 2000;
    const group_id: u32 = 100;
    const can_read = file_permissions.can_read(&perms, user_id, group_id);
    const timestamp: u64 = 1000;
    const file_path = "/home/user/file.txt";
    if (can_read) {
        _ = logger.log_file_read(timestamp, user_id, file_path, true);
    } else {
        _ = logger.log_security_event(
            timestamp,
            user_id,
            audit_logger.SecurityEventType.permission_denied,
            file_path,
            "Read permission denied",
        );
    }
    std.debug.assert(logger.entries_len == 1);
}

test "integration - encryption at rest with compression" {
    const allocator = testing.allocator;
    var enc_manager = file_encryption.EncryptionAtRestManager.init();
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    _ = enc_manager.enable_encryption(key);
    const data = "Hello, World! This is test data.";
    const file_path = "/home/user/file.txt";
    const compressed = try file_compression.compress_gzip(allocator, data);
    defer allocator.free(compressed);
    const encrypted = try enc_manager.encrypt_data(allocator, compressed, file_path);
    defer allocator.free(encrypted);
    std.debug.assert(encrypted.len > compressed.len);
    const decrypted = try enc_manager.decrypt_data(allocator, encrypted, file_path);
    defer allocator.free(decrypted);
    const decompressed = try file_compression.decompress_gzip(allocator, decrypted);
    defer allocator.free(decompressed);
    std.debug.assert(std.mem.eql(u8, data, decompressed));
}

test "integration - access control with audit logging" {
    const allocator = testing.allocator;
    var acl = access_control.AccessControlList.init();
    var permissions = file_permissions.PermissionBits.from_octal(0o644);
    permissions.owner_read = true;
    _ = acl.add_entry(
        1000,
        100,
        access_control.RoleType.user,
        access_control.AceType.allow,
        permissions,
    );
    var logger = audit_logger.AuditLogger.init();
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    const has_access = access_control.check_acl_access(
        &acl,
        user_id,
        group_id,
        file_permissions.AccessType.read,
    );
    const timestamp: u64 = 1000;
    const file_path = "/home/user/file.txt";
    if (has_access) {
        _ = logger.log_file_read(timestamp, user_id, file_path, true);
    } else {
        _ = logger.log_security_event(
            timestamp,
            user_id,
            audit_logger.SecurityEventType.acl_violation,
            file_path,
            "ACL check failed",
        );
    }
    std.debug.assert(logger.entries_len == 1);
    std.debug.assert(has_access);
}

test "integration - file versioning with compression" {
    const allocator = testing.allocator;
    var version_manager = file_versioning.VersionManager.init();
    const file_path = "/home/user/file.txt";
    const data = "Version 1 content";
    const compressed = try file_compression.compress_gzip(allocator, data);
    defer allocator.free(compressed);
    var checksum: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(compressed, &checksum, .{});
    const version_id = version_manager.create_version(
        file_path,
        compressed.len,
        &checksum,
        1000,
        1000,
        "Compressed version",
    );
    std.debug.assert(version_id != null);
    const version = version_manager.get_version(version_id.?);
    std.debug.assert(version != null);
    std.debug.assert(version.?.file_size == compressed.len);
}

test "integration - full workflow - create, compress, encrypt, version" {
    const allocator = testing.allocator;
    const original_data = "This is a complete workflow test.";
    var logger = audit_logger.AuditLogger.init();
    var version_manager = file_versioning.VersionManager.init();
    var enc_manager = file_encryption.EncryptionAtRestManager.init();
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    _ = enc_manager.enable_encryption(key);
    const file_path = "/home/user/workflow.txt";
    const user_id: u32 = 1000;
    const timestamp: u64 = 1000;
    _ = logger.log_operation(
        timestamp,
        user_id,
        audit_logger.FileOperationType.create,
        file_path,
        true,
        0,
    );
    const compressed = try file_compression.compress_gzip(allocator, original_data);
    defer allocator.free(compressed);
    const encrypted = try enc_manager.encrypt_data(allocator, compressed, file_path);
    defer allocator.free(encrypted);
    var checksum: [32]u8 = undefined;
    std.crypto.hash.sha2.Sha256.hash(encrypted, &checksum, .{});
    const version_id = version_manager.create_version(
        file_path,
        encrypted.len,
        &checksum,
        timestamp,
        user_id,
        "Workflow version",
    );
    std.debug.assert(version_id != null);
    std.debug.assert(logger.entries_len == 1);
    std.debug.assert(version_manager.versions_len == 1);
}
