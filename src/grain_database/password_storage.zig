//! Grain Database Password Storage: Helper for Grain Passwords module.
//!
//! Why: Simplify encrypted secret storage for passwords, API keys, tokens, credentials.
//! Architecture: Helper functions for password storage patterns following SLC integration.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.
//!
//! 2026-01-01-102703-pst: Grain Silo Agent

const std = @import("std");
const storage_engine = @import("storage_engine.zig");

// Password storage errors.
pub const PasswordStorageError = error{
    InvalidSecretId,
    InvalidKeyId,
    InvalidAuditId,
    TooManySecrets,
};

// Bounded: Max secret ID length (hex string).
pub const MAX_SECRET_ID_LEN: u32 = 64;

// Bounded: Max key ID length (hex string).
pub const MAX_KEY_ID_LEN: u32 = 64;

// Bounded: Max audit ID length (hex string).
pub const MAX_AUDIT_ID_LEN: u32 = 64;

// Bounded: Max secret name length.
pub const MAX_SECRET_NAME_LEN: u32 = 256;

// Bounded: Max secret type length.
pub const MAX_SECRET_TYPE_LEN: u32 = 32;

// Validate secret ID format (hex string, max 64 chars).
pub fn validate_secret_id(secret_id: []const u8) bool {
    std.debug.assert(secret_id.len > 0);
    if (secret_id.len == 0 or secret_id.len > MAX_SECRET_ID_LEN) {
        return false;
    }
    var i: u32 = 0;
    while (i < secret_id.len) : (i += 1) {
        const c = secret_id[i];
        if (!((c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F'))) {
            return false;
        }
    }
    return true;
}

// Validate key ID format (hex string, max 64 chars).
pub fn validate_key_id(key_id: []const u8) bool {
    std.debug.assert(key_id.len > 0);
    if (key_id.len == 0 or key_id.len > MAX_KEY_ID_LEN) {
        return false;
    }
    var i: u32 = 0;
    while (i < key_id.len) : (i += 1) {
        const c = key_id[i];
        if (!((c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F'))) {
            return false;
        }
    }
    return true;
}

// Validate audit ID format (hex string, max 64 chars).
pub fn validate_audit_id(audit_id: []const u8) bool {
    std.debug.assert(audit_id.len > 0);
    if (audit_id.len == 0 or audit_id.len > MAX_AUDIT_ID_LEN) {
        return false;
    }
    var i: u32 = 0;
    while (i < audit_id.len) : (i += 1) {
        const c = audit_id[i];
        if (!((c >= '0' and c <= '9') or (c >= 'a' and c <= 'f') or (c >= 'A' and c <= 'F'))) {
            return false;
        }
    }
    return true;
}

// Password storage helper.
pub const PasswordStorage = struct {
    storage_engine: *storage_engine.StorageEngine,

    // Initialize password storage.
    pub fn init(
        storage: *storage_engine.StorageEngine,
    ) PasswordStorage {
        std.debug.assert(storage != null);
        return PasswordStorage{
            .storage_engine = storage,
        };
    }

    // Store encrypted secret.
    pub fn store_secret(
        self: *PasswordStorage,
        secret_id: []const u8,
        encrypted_data: []const u8,
        metadata: []const u8,
    ) !u64 {
        std.debug.assert(secret_id.len > 0);
        std.debug.assert(secret_id.len <= MAX_SECRET_ID_LEN);
        std.debug.assert(encrypted_data.len > 0);
        std.debug.assert(metadata.len > 0);
        if (!validate_secret_id(secret_id)) {
            return error.InvalidSecretId;
        }
        const key = try std.fmt.allocPrint(
            self.storage_engine.allocator,
            "password:secret:{s}",
            .{secret_id},
        );
        defer self.storage_engine.allocator.free(key);
        const json_value = try std.fmt.allocPrint(
            self.storage_engine.allocator,
            "{{\"encrypted_data\":\"{s}\",\"metadata\":{s}}}",
            .{ encrypted_data, metadata },
        );
        defer self.storage_engine.allocator.free(json_value);
        const record_id = try self.storage_engine.create_record(key, json_value);
        std.debug.assert(record_id > 0);
        return record_id;
    }

    // Retrieve encrypted secret.
    pub fn get_secret(
        self: *PasswordStorage,
        secret_id: []const u8,
    ) ?*storage_engine.Record {
        std.debug.assert(secret_id.len > 0);
        std.debug.assert(secret_id.len <= MAX_SECRET_ID_LEN);
        const key = std.fmt.allocPrint(
            self.storage_engine.allocator,
            "password:secret:{s}",
            .{secret_id},
        ) catch return null;
        defer self.storage_engine.allocator.free(key);
        return self.storage_engine.read_record_by_key(key);
    }

    // Update encrypted secret.
    pub fn update_secret(
        self: *PasswordStorage,
        secret_id: []const u8,
        encrypted_data: []const u8,
        metadata: []const u8,
    ) !void {
        std.debug.assert(secret_id.len > 0);
        std.debug.assert(secret_id.len <= MAX_SECRET_ID_LEN);
        std.debug.assert(encrypted_data.len > 0);
        std.debug.assert(metadata.len > 0);
        const key = try std.fmt.allocPrint(
            self.storage_engine.allocator,
            "password:secret:{s}",
            .{secret_id},
        );
        defer self.storage_engine.allocator.free(key);
        const json_value = try std.fmt.allocPrint(
            self.storage_engine.allocator,
            "{{\"encrypted_data\":\"{s}\",\"metadata\":{s}}}",
            .{ encrypted_data, metadata },
        );
        defer self.storage_engine.allocator.free(json_value);
        try self.storage_engine.update_record(key, json_value);
    }

    // Delete encrypted secret.
    pub fn delete_secret(
        self: *PasswordStorage,
        secret_id: []const u8,
    ) !void {
        std.debug.assert(secret_id.len > 0);
        std.debug.assert(secret_id.len <= MAX_SECRET_ID_LEN);
        const key = try std.fmt.allocPrint(
            self.storage_engine.allocator,
            "password:secret:{s}",
            .{secret_id},
        );
        defer self.storage_engine.allocator.free(key);
        try self.storage_engine.delete_record(key);
    }

    // List all secrets (paginated).
    pub fn list_secrets_paginated(
        self: *PasswordStorage,
        page: u32,
        page_size: u32,
        output_secrets: []*storage_engine.Record,
    ) !u32 {
        std.debug.assert(page_size > 0);
        std.debug.assert(output_secrets.len > 0);
        std.debug.assert(page_size <= output_secrets.len);
        const offset = page * page_size;
        var count: u32 = 0;
        var skipped: u32 = 0;
        var i: u32 = 0;
        const prefix = "password:secret:";
        while (i < self.storage_engine.records_len) : (i += 1) {
            const record = &self.storage_engine.records[i];
            if (record.key_len >= prefix.len) {
                if (std.mem.eql(u8, record.key[0..prefix.len], prefix)) {
                    if (skipped < offset) {
                        skipped += 1;
                    } else {
                        if (count < page_size and count < output_secrets.len) {
                            output_secrets[count] = record;
                            count += 1;
                        }
                        if (count >= page_size) {
                            break;
                        }
                    }
                }
            }
        }
        return count;
    }

    // Count secrets.
    pub fn count_secrets(self: *PasswordStorage) !u64 {
        var count: u64 = 0;
        var i: u32 = 0;
        const prefix = "password:secret:";
        while (i < self.storage_engine.records_len) : (i += 1) {
            const record = &self.storage_engine.records[i];
            if (record.key_len >= prefix.len) {
                if (std.mem.eql(u8, record.key[0..prefix.len], prefix)) {
                    count += 1;
                }
            }
        }
        return count;
    }

    // Search secrets by name or type (simple text matching in metadata).
    pub fn search_secrets(
        self: *PasswordStorage,
        query: []const u8,
        output_secrets: []*storage_engine.Record,
    ) !u32 {
        std.debug.assert(query.len > 0);
        std.debug.assert(output_secrets.len > 0);
        var count: u32 = 0;
        var i: u32 = 0;
        const prefix = "password:secret:";
        while (i < self.storage_engine.records_len) : (i += 1) {
            const record = &self.storage_engine.records[i];
            if (record.key_len >= prefix.len) {
                if (std.mem.eql(u8, record.key[0..prefix.len], prefix)) {
                    const value_slice = record.value[0..record.value_len];
                    if (std.mem.indexOf(u8, value_slice, query) != null) {
                        if (count < output_secrets.len) {
                            output_secrets[count] = record;
                            count += 1;
                        }
                    }
                }
            }
        }
        return count;
    }

    // Batch store secrets (for bulk loading).
    pub fn batch_store_secrets(
        self: *PasswordStorage,
        secret_ids: []const []const u8,
        encrypted_data: []const []const u8,
        metadata: []const []const u8,
        output_record_ids: []u64,
    ) !u32 {
        std.debug.assert(secret_ids.len == encrypted_data.len);
        std.debug.assert(secret_ids.len == metadata.len);
        std.debug.assert(secret_ids.len <= output_record_ids.len);
        const MAX_BATCH_SIZE: u32 = 100;
        if (secret_ids.len > MAX_BATCH_SIZE) {
            return error.TooManySecrets;
        }
        const keys = try self.storage_engine.allocator.alloc([]const u8, secret_ids.len);
        defer self.storage_engine.allocator.free(keys);
        const values = try self.storage_engine.allocator.alloc([]const u8, secret_ids.len);
        defer self.storage_engine.allocator.free(values);
        var valid_count: u32 = 0;
        var i: u32 = 0;
        while (i < secret_ids.len) : (i += 1) {
            std.debug.assert(secret_ids[i].len <= MAX_SECRET_ID_LEN);
            if (!validate_secret_id(secret_ids[i])) {
                continue;
            }
            const key = try std.fmt.allocPrint(
                self.storage_engine.allocator,
                "password:secret:{s}",
                .{secret_ids[i]},
            );
            keys[valid_count] = key;
            const json_value = try std.fmt.allocPrint(
                self.storage_engine.allocator,
                "{{\"encrypted_data\":\"{s}\",\"metadata\":{s}}}",
                .{ encrypted_data[i], metadata[i] },
            );
            values[valid_count] = json_value;
            valid_count += 1;
        }
        defer {
            var j: u32 = 0;
            while (j < valid_count) : (j += 1) {
                self.storage_engine.allocator.free(keys[j]);
                self.storage_engine.allocator.free(values[j]);
            }
        }
        const count = try self.storage_engine.batch_create_records(
            keys[0..valid_count],
            values[0..valid_count],
            output_record_ids,
        );
        std.debug.assert(count <= valid_count);
        return count;
    }

    // Store key derivation parameters.
    pub fn store_key_params(
        self: *PasswordStorage,
        key_id: []const u8,
        derivation_params: []const u8,
    ) !u64 {
        std.debug.assert(key_id.len > 0);
        std.debug.assert(key_id.len <= MAX_KEY_ID_LEN);
        std.debug.assert(derivation_params.len > 0);
        if (!validate_key_id(key_id)) {
            return error.InvalidKeyId;
        }
        const key = try std.fmt.allocPrint(
            self.storage_engine.allocator,
            "password:key:{s}",
            .{key_id},
        );
        defer self.storage_engine.allocator.free(key);
        const json_value = try std.fmt.allocPrint(
            self.storage_engine.allocator,
            "{{\"key_id\":\"{s}\",\"derivation_params\":{s}}}",
            .{ key_id, derivation_params },
        );
        defer self.storage_engine.allocator.free(json_value);
        const record_id = try self.storage_engine.create_record(key, json_value);
        std.debug.assert(record_id > 0);
        return record_id;
    }

    // Retrieve key derivation parameters.
    pub fn get_key_params(
        self: *PasswordStorage,
        key_id: []const u8,
    ) ?*storage_engine.Record {
        std.debug.assert(key_id.len > 0);
        std.debug.assert(key_id.len <= MAX_KEY_ID_LEN);
        const key = std.fmt.allocPrint(
            self.storage_engine.allocator,
            "password:key:{s}",
            .{key_id},
        ) catch return null;
        defer self.storage_engine.allocator.free(key);
        return self.storage_engine.read_record_by_key(key);
    }

    // Store audit log entry.
    pub fn store_audit_log(
        self: *PasswordStorage,
        audit_id: []const u8,
        secret_id: []const u8,
        action: []const u8,
        user_id: []const u8,
        audit_data: []const u8,
    ) !u64 {
        std.debug.assert(audit_id.len > 0);
        std.debug.assert(audit_id.len <= MAX_AUDIT_ID_LEN);
        std.debug.assert(secret_id.len > 0);
        std.debug.assert(action.len > 0);
        std.debug.assert(user_id.len > 0);
        std.debug.assert(audit_data.len > 0);
        if (!validate_audit_id(audit_id)) {
            return error.InvalidAuditId;
        }
        const key = try std.fmt.allocPrint(
            self.storage_engine.allocator,
            "password:audit:{s}",
            .{audit_id},
        );
        defer self.storage_engine.allocator.free(key);
        const json_value = try std.fmt.allocPrint(
            self.storage_engine.allocator,
            "{{\"audit_id\":\"{s}\",\"secret_id\":\"{s}\",\"action\":\"{s}\",\"user_id\":\"{s}\",\"audit_data\":{s}}}",
            .{ audit_id, secret_id, action, user_id, audit_data },
        );
        defer self.storage_engine.allocator.free(json_value);
        const record_id = try self.storage_engine.create_record(key, json_value);
        std.debug.assert(record_id > 0);
        return record_id;
    }

    // List audit logs for secret (paginated).
    pub fn list_audit_logs_paginated(
        self: *PasswordStorage,
        secret_id: []const u8,
        page: u32,
        page_size: u32,
        output_logs: []*storage_engine.Record,
    ) !u32 {
        std.debug.assert(secret_id.len > 0);
        std.debug.assert(page_size > 0);
        std.debug.assert(output_logs.len > 0);
        std.debug.assert(page_size <= output_logs.len);
        const offset = page * page_size;
        var count: u32 = 0;
        var skipped: u32 = 0;
        var i: u32 = 0;
        const prefix = "password:audit:";
        const secret_id_str = try std.fmt.allocPrint(
            self.storage_engine.allocator,
            "\"secret_id\":\"{s}\"",
            .{secret_id},
        );
        defer self.storage_engine.allocator.free(secret_id_str);
        while (i < self.storage_engine.records_len) : (i += 1) {
            const record = &self.storage_engine.records[i];
            if (record.key_len >= prefix.len) {
                if (std.mem.eql(u8, record.key[0..prefix.len], prefix)) {
                    const value_slice = record.value[0..record.value_len];
                    if (std.mem.indexOf(u8, value_slice, secret_id_str) != null) {
                        if (skipped < offset) {
                            skipped += 1;
                        } else {
                            if (count < page_size and count < output_logs.len) {
                                output_logs[count] = record;
                                count += 1;
                            }
                            if (count >= page_size) {
                                break;
                            }
                        }
                    }
                }
            }
        }
        return count;
    }
};
