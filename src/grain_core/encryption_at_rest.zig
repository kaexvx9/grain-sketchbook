//! Grain Core Encryption at Rest: Transparent file encryption.
//!
//! Why: Provide transparent encryption at rest for file storage.
//! Architecture: Integration with file storage manager for automatic encryption.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");
const file_encryption = @import("file_encryption.zig");
const file_storage = @import("file_storage.zig");

// Bounded: Max encryption keys.
pub const MAX_ENCRYPTION_KEYS: u32 = 16;

// Encryption at rest configuration.
pub const EncryptionAtRestConfig = struct {
    enabled: bool,
    default_key_id: u32,
    encrypt_on_write: bool,
    decrypt_on_read: bool,

    pub fn init() EncryptionAtRestConfig {
        return EncryptionAtRestConfig{
            .enabled = false,
            .default_key_id = 0,
            .encrypt_on_write = true,
            .decrypt_on_read = true,
        };
    }
};

// Encrypted file metadata.
pub const EncryptedFileMetadata = struct {
    file_path: [file_storage.MAX_FILENAME_LEN]u8,
    file_path_len: u32,
    key_id: u32,
    nonce: [file_encryption.GCM_NONCE_SIZE]u8,
    encrypted: bool,
    created_at: u64,

    pub fn init() EncryptedFileMetadata {
        var metadata = EncryptedFileMetadata{
            .file_path = undefined,
            .file_path_len = 0,
            .key_id = 0,
            .nonce = undefined,
            .encrypted = false,
            .created_at = 0,
        };
        var i: u32 = 0;
        while (i < file_storage.MAX_FILENAME_LEN) : (i += 1) {
            metadata.file_path[i] = 0;
        }
        i = 0;
        while (i < file_encryption.GCM_NONCE_SIZE) : (i += 1) {
            metadata.nonce[i] = 0;
        }
        return metadata;
    }
};

// Encryption at rest manager.
pub const EncryptionAtRestManager = struct {
    config: EncryptionAtRestConfig,
    keys: [MAX_ENCRYPTION_KEYS]file_encryption.EncryptionKey,
    keys_len: u32,
    metadata: [file_storage.MAX_FILE_HANDLES]EncryptedFileMetadata,
    metadata_len: u32,

    pub fn init() EncryptionAtRestManager {
        var manager = EncryptionAtRestManager{
            .config = EncryptionAtRestConfig.init(),
            .keys = undefined,
            .keys_len = 0,
            .metadata = undefined,
            .metadata_len = 0,
        };
        var i: u32 = 0;
        while (i < MAX_ENCRYPTION_KEYS) : (i += 1) {
            manager.keys[i] = file_encryption.EncryptionKey.init();
        }
        i = 0;
        while (i < file_storage.MAX_FILE_HANDLES) : (i += 1) {
            manager.metadata[i] = EncryptedFileMetadata.init();
        }
        return manager;
    }

    pub fn enable_encryption(
        self: *EncryptionAtRestManager,
        key: file_encryption.EncryptionKey,
    ) bool {
        std.debug.assert(self != null);
        if (self.keys_len >= MAX_ENCRYPTION_KEYS) {
            return false;
        }
        self.keys[self.keys_len] = key;
        const key_id = self.keys_len;
        self.keys_len += 1;
        self.config.enabled = true;
        self.config.default_key_id = key_id;
        std.debug.assert(self.keys_len <= MAX_ENCRYPTION_KEYS);
        return true;
    }

    pub fn encrypt_data(
        self: *EncryptionAtRestManager,
        allocator: std.mem.Allocator,
        data: []const u8,
        file_path: []const u8,
    ) ![]u8 {
        std.debug.assert(data.len > 0);
        std.debug.assert(file_path.len > 0);
        std.debug.assert(allocator != null);
        std.debug.assert(self != null);
        if (!self.config.enabled) {
            const result = try allocator.alloc(u8, data.len);
            @memcpy(result, data);
            return result;
        }
        if (self.config.default_key_id >= self.keys_len) {
            return error.InvalidKeyId;
        }
        const key = &self.keys[self.config.default_key_id];
        const nonce = try file_encryption.generate_nonce(allocator);
        defer allocator.free(nonce);
        const encrypted = try file_encryption.encrypt_aes256_gcm(
            allocator,
            data,
            key,
            nonce,
        );
        var i: u32 = 0;
        while (i < self.metadata_len) : (i += 1) {
            const path = self.metadata[i].file_path[0..
                self.metadata[i].file_path_len];
            if (std.mem.eql(u8, path, file_path)) {
                var j: u32 = 0;
                while (j < file_encryption.GCM_NONCE_SIZE) : (j += 1) {
                    self.metadata[i].nonce[j] = nonce[j];
                }
                self.metadata[i].encrypted = true;
                return encrypted;
            }
        }
        if (self.metadata_len >= file_storage.MAX_FILE_HANDLES) {
            return error.TooManyFiles;
        }
        self.metadata[self.metadata_len] = EncryptedFileMetadata.init();
        var j: u32 = 0;
        while (j < file_path.len and j < file_storage.MAX_FILENAME_LEN) : (j += 1) {
            self.metadata[self.metadata_len].file_path[j] = file_path[j];
        }
        self.metadata[self.metadata_len].file_path_len = @intCast(file_path.len);
        self.metadata[self.metadata_len].key_id = self.config.default_key_id;
        j = 0;
        while (j < file_encryption.GCM_NONCE_SIZE) : (j += 1) {
            self.metadata[self.metadata_len].nonce[j] = nonce[j];
        }
        self.metadata[self.metadata_len].encrypted = true;
        self.metadata_len += 1;
        return encrypted;
    }

    pub fn decrypt_data(
        self: *EncryptionAtRestManager,
        allocator: std.mem.Allocator,
        encrypted_data: []const u8,
        file_path: []const u8,
    ) ![]u8 {
        std.debug.assert(encrypted_data.len > 0);
        std.debug.assert(file_path.len > 0);
        std.debug.assert(allocator != null);
        std.debug.assert(self != null);
        if (!self.config.enabled) {
            const result = try allocator.alloc(u8, encrypted_data.len);
            @memcpy(result, encrypted_data);
            return result;
        }
        var i: u32 = 0;
        while (i < self.metadata_len) : (i += 1) {
            const path = self.metadata[i].file_path[0..
                self.metadata[i].file_path_len];
            if (std.mem.eql(u8, path, file_path) and
                self.metadata[i].encrypted)
            {
                if (self.metadata[i].key_id >= self.keys_len) {
                    return error.InvalidKeyId;
                }
                const key = &self.keys[self.metadata[i].key_id];
                const nonce = self.metadata[i].nonce[0..];
                return file_encryption.decrypt_aes256_gcm(
                    allocator,
                    encrypted_data,
                    key,
                    nonce,
                );
            }
        }
        const result = try allocator.alloc(u8, encrypted_data.len);
        @memcpy(result, encrypted_data);
        return result;
    }

    pub fn is_encryption_enabled(self: *const EncryptionAtRestManager) bool {
        std.debug.assert(self != null);
        return self.config.enabled;
    }
};
