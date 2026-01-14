//! Grain Core Storage Security Tests.
//!
//! Why: Test security properties of storage modules (encryption, access control,
//! audit logging).
//! Architecture: Security validation tests.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const file_encryption = @import("grain_core").file_encryption;
const file_permissions = @import("grain_core").file_permissions;
const access_control = @import("grain_core").access_control;
const audit_logger = @import("grain_core").audit_logger;
const encryption_at_rest = @import("grain_core").encryption_at_rest;

test "security - encryption key uniqueness" {
    const allocator = testing.allocator;
    var key1_bytes: [32]u8 = undefined;
    var key2_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key1_bytes);
    std.crypto.random.bytes(&key2_bytes);
    const key1 = file_encryption.EncryptionKey.from_bytes(&key1_bytes);
    const key2 = file_encryption.EncryptionKey.from_bytes(&key2_bytes);
    var different: bool = false;
    var i: u32 = 0;
    while (i < 32) : (i += 1) {
        if (key1.key[i] != key2.key[i]) {
            different = true;
            break;
        }
    }
    std.debug.assert(different);
}

test "security - encryption prevents plaintext recovery" {
    const allocator = testing.allocator;
    const data = "Sensitive data that must be encrypted";
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
    std.debug.assert(!std.mem.eql(u8, data, encrypted));
    var found_plaintext: bool = false;
    var i: u32 = 0;
    while (i < encrypted.len and i < data.len) : (i += 1) {
        if (encrypted[i] == data[i]) {
            found_plaintext = true;
            break;
        }
    }
    std.debug.assert(!found_plaintext);
}

test "security - wrong key produces different decryption" {
    const allocator = testing.allocator;
    const data = "Secret data";
    var key1_bytes: [32]u8 = undefined;
    var key2_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key1_bytes);
    std.crypto.random.bytes(&key2_bytes);
    const key1 = file_encryption.EncryptionKey.from_bytes(&key1_bytes);
    const key2 = file_encryption.EncryptionKey.from_bytes(&key2_bytes);
    const nonce = try file_encryption.generate_nonce(allocator);
    defer allocator.free(nonce);
    const encrypted = try file_encryption.encrypt_aes256_gcm(
        allocator,
        data,
        &key1,
        nonce,
    );
    defer allocator.free(encrypted);
    const decrypted_result = file_encryption.decrypt_aes256_gcm(
        allocator,
        encrypted,
        &key2,
        nonce,
    );
    if (decrypted_result) |decrypted| {
        defer allocator.free(decrypted);
        std.debug.assert(!std.mem.eql(u8, data, decrypted));
    } else |_| {
        std.debug.assert(true);
    }
}

test "security - permissions enforce access control" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o600);
    const owner_can_read = file_permissions.can_read(&perms, 1000, 100);
    const owner_can_write = file_permissions.can_write(&perms, 1000, 100);
    const other_can_read = file_permissions.can_read(&perms, 2000, 200);
    const other_can_write = file_permissions.can_write(&perms, 2000, 200);
    std.debug.assert(owner_can_read);
    std.debug.assert(owner_can_write);
    std.debug.assert(!other_can_read);
    std.debug.assert(!other_can_write);
}

test "security - acl deny overrides allow" {
    var acl = access_control.AccessControlList.init();
    var allow_perms = file_permissions.PermissionBits.from_octal(0o644);
    allow_perms.owner_read = true;
    _ = acl.add_entry(
        1000,
        100,
        access_control.RoleType.user,
        access_control.AceType.allow,
        allow_perms,
    );
    var deny_perms = file_permissions.PermissionBits.from_octal(0o644);
    deny_perms.owner_read = true;
    _ = acl.add_entry(
        1000,
        100,
        access_control.RoleType.user,
        access_control.AceType.deny,
        deny_perms,
    );
    const has_access = access_control.check_acl_access(
        &acl,
        1000,
        100,
        file_permissions.AccessType.read,
    );
    std.debug.assert(!has_access);
}

test "security - audit logging captures security events" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const file_path = "/home/user/secret.txt";
    _ = logger.log_security_event(
        timestamp,
        user_id,
        audit_logger.SecurityEventType.unauthorized_access,
        file_path,
        "Unauthorized access attempt",
    );
    std.debug.assert(logger.entries_len == 1);
    std.debug.assert(logger.entries[0].success == false);
    std.debug.assert(logger.entries[0].operation ==
        audit_logger.FileOperationType.open);
}

test "security - encryption at rest prevents plaintext storage" {
    const allocator = testing.allocator;
    var manager = encryption_at_rest.EncryptionAtRestManager.init();
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    _ = manager.enable_encryption(key);
    const data = "Sensitive file content";
    const file_path = "/home/user/sensitive.txt";
    const encrypted = try manager.encrypt_data(allocator, data, file_path);
    defer allocator.free(encrypted);
    std.debug.assert(!std.mem.eql(u8, data, encrypted));
    std.debug.assert(encrypted.len > data.len);
}

test "security - nonce uniqueness" {
    const allocator = testing.allocator;
    const nonce1 = try file_encryption.generate_nonce(allocator);
    defer allocator.free(nonce1);
    const nonce2 = try file_encryption.generate_nonce(allocator);
    defer allocator.free(nonce2);
    var different: bool = false;
    var i: u32 = 0;
    while (i < file_encryption.GCM_NONCE_SIZE) : (i += 1) {
        if (nonce1[i] != nonce2[i]) {
            different = true;
            break;
        }
    }
    std.debug.assert(different);
}

test "security - rbac enforces role-based access" {
    var manager = access_control.RbacManager.init();
    var admin_perms = file_permissions.PermissionBits.from_octal(0o755);
    admin_perms.owner_read = true;
    admin_perms.owner_write = true;
    const admin_role_id = manager.create_role(
        "admin",
        access_control.RoleType.admin,
        admin_perms,
    );
    std.debug.assert(admin_role_id != null);
    const admin_role = manager.get_role(admin_role_id.?);
    std.debug.assert(admin_role != null);
    _ = admin_role.?.add_user(1000);
    const user_has_admin_access = manager.check_role_access(
        1000,
        access_control.RoleType.admin,
        file_permissions.AccessType.read,
    );
    const user_has_user_access = manager.check_role_access(
        1000,
        access_control.RoleType.user,
        file_permissions.AccessType.read,
    );
    std.debug.assert(user_has_admin_access);
    std.debug.assert(!user_has_user_access);
}

test "security - audit log captures all file operations" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const file_path = "/home/user/file.txt";
    _ = logger.log_file_open(timestamp, user_id, file_path, true);
    _ = logger.log_file_read(timestamp + 1, user_id, file_path, true);
    _ = logger.log_file_write(timestamp + 2, user_id, file_path, true);
    _ = logger.log_file_delete(timestamp + 3, user_id, file_path, true);
    std.debug.assert(logger.entries_len == 4);
    std.debug.assert(logger.entries[0].operation ==
        audit_logger.FileOperationType.open);
    std.debug.assert(logger.entries[1].operation ==
        audit_logger.FileOperationType.read);
    std.debug.assert(logger.entries[2].operation ==
        audit_logger.FileOperationType.write);
    std.debug.assert(logger.entries[3].operation ==
        audit_logger.FileOperationType.delete);
}
