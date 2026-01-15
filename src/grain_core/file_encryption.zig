//! Grain Core File Encryption: File encryption and decryption.
//!
//! Why: Provide file encryption and decryption for secure storage.
//! Architecture: AES-256-GCM encryption with key management.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");

// Bounded: AES-256 key size (32 bytes).
pub const AES_256_KEY_SIZE: u32 = 32;

// Bounded: GCM nonce size (12 bytes).
pub const GCM_NONCE_SIZE: u32 = 12;

// Bounded: GCM tag size (16 bytes).
pub const GCM_TAG_SIZE: u32 = 16;

// Bounded: Max encryption metadata size.
pub const MAX_ENCRYPTION_METADATA_SIZE: u32 = 256;

// Encryption key.
pub const EncryptionKey = struct {
    key: [AES_256_KEY_SIZE]u8,

    pub fn init() EncryptionKey {
        var enc_key = EncryptionKey{
            .key = undefined,
        };
        var i: u32 = 0;
        while (i < AES_256_KEY_SIZE) : (i += 1) {
            enc_key.key[i] = 0;
        }
        return enc_key;
    }

    pub fn from_bytes(key_bytes: []const u8) EncryptionKey {
        std.debug.assert(key_bytes.len == AES_256_KEY_SIZE);
        var enc_key = EncryptionKey.init();
        var i: u32 = 0;
        while (i < AES_256_KEY_SIZE) : (i += 1) {
            enc_key.key[i] = key_bytes[i];
        }
        return enc_key;
    }
};

// Encryption metadata.
pub const EncryptionMetadata = struct {
    algorithm: [16]u8,
    algorithm_len: u32,
    nonce: [GCM_NONCE_SIZE]u8,
    tag: [GCM_TAG_SIZE]u8,
    encrypted_size: u64,

    pub fn init() EncryptionMetadata {
        var metadata = EncryptionMetadata{
            .algorithm = undefined,
            .algorithm_len = 0,
            .nonce = undefined,
            .tag = undefined,
            .encrypted_size = 0,
        };
        var i: u32 = 0;
        while (i < 16) : (i += 1) {
            metadata.algorithm[i] = 0;
        }
        i = 0;
        while (i < GCM_NONCE_SIZE) : (i += 1) {
            metadata.nonce[i] = 0;
        }
        i = 0;
        while (i < GCM_TAG_SIZE) : (i += 1) {
            metadata.tag[i] = 0;
        }
        const alg_str = "AES-256-GCM";
        i = 0;
        while (i < alg_str.len and i < 16) : (i += 1) {
            metadata.algorithm[i] = alg_str[i];
        }
        metadata.algorithm_len = alg_str.len;
        return metadata;
    }
};

// Encrypt data using AES-256-GCM.
pub fn encrypt_aes256_gcm(
    allocator: std.mem.Allocator,
    data: []const u8,
    key: *const EncryptionKey,
    nonce: []const u8,
) ![]u8 {
    std.debug.assert(data.len > 0);
    std.debug.assert(nonce.len == GCM_NONCE_SIZE);
    std.debug.assert(allocator != null);
    std.debug.assert(key != null);
    var nonce_array: [GCM_NONCE_SIZE]u8 = undefined;
    var i: u32 = 0;
    while (i < GCM_NONCE_SIZE) : (i += 1) {
        nonce_array[i] = nonce[i];
    }
    var encrypted = try allocator.alloc(
        u8,
        data.len + GCM_TAG_SIZE,
    );
    var tag: [GCM_TAG_SIZE]u8 = undefined;
    try std.crypto.aead.aes_gcm.Aes256Gcm.encrypt(
        encrypted[0..data.len],
        &tag,
        data,
        "",
        &nonce_array,
        key.key,
    );
    @memcpy(encrypted[data.len..], &tag);
    return encrypted;
}

// Decrypt data using AES-256-GCM.
pub fn decrypt_aes256_gcm(
    allocator: std.mem.Allocator,
    encrypted_data: []const u8,
    key: *const EncryptionKey,
    nonce: []const u8,
) ![]u8 {
    std.debug.assert(encrypted_data.len > GCM_TAG_SIZE);
    std.debug.assert(nonce.len == GCM_NONCE_SIZE);
    std.debug.assert(allocator != null);
    std.debug.assert(key != null);
    if (encrypted_data.len < GCM_TAG_SIZE) {
        return error.InvalidEncryptedData;
    }
    const data_len = encrypted_data.len - GCM_TAG_SIZE;
    var tag: [GCM_TAG_SIZE]u8 = undefined;
    var i: u32 = 0;
    while (i < GCM_TAG_SIZE) : (i += 1) {
        tag[i] = encrypted_data[data_len + i];
    }
    var nonce_array: [GCM_NONCE_SIZE]u8 = undefined;
    i = 0;
    while (i < GCM_NONCE_SIZE) : (i += 1) {
        nonce_array[i] = nonce[i];
    }
    const decrypted = try allocator.alloc(u8, data_len);
    try std.crypto.aead.aes_gcm.Aes256Gcm.decrypt(
        decrypted,
        encrypted_data[0..data_len],
        &tag,
        "",
        &nonce_array,
        key.key,
    );
    return decrypted;
}

// Generate random nonce.
pub fn generate_nonce(allocator: std.mem.Allocator) ![]u8 {
    std.debug.assert(allocator != null);
    const nonce = try allocator.alloc(u8, GCM_NONCE_SIZE);
    std.crypto.random.bytes(@constCast(nonce));
    return nonce;
}

// Encryption manager: manages encryption operations.
pub const EncryptionManager = struct {
    default_key: EncryptionKey,

    pub fn init(key: EncryptionKey) EncryptionManager {
        std.debug.assert(key != null);
        return EncryptionManager{
            .default_key = key,
        };
    }

    pub fn encrypt_file(
        self: *const EncryptionManager,
        allocator: std.mem.Allocator,
        data: []const u8,
    ) !EncryptionMetadata {
        std.debug.assert(data.len > 0);
        std.debug.assert(allocator != null);
        std.debug.assert(self != null);
        const nonce = try generate_nonce(allocator);
        defer allocator.free(nonce);
        const encrypted = try encrypt_aes256_gcm(
            allocator,
            data,
            &self.default_key,
            nonce,
        );
        defer allocator.free(encrypted);
        var metadata = EncryptionMetadata.init();
        var i: u32 = 0;
        while (i < GCM_NONCE_SIZE) : (i += 1) {
            metadata.nonce[i] = nonce[i];
        }
        metadata.encrypted_size = encrypted.len;
        return metadata;
    }

    pub fn decrypt_file(
        self: *const EncryptionManager,
        allocator: std.mem.Allocator,
        encrypted_data: []const u8,
        nonce: []const u8,
    ) ![]u8 {
        std.debug.assert(encrypted_data.len > 0);
        std.debug.assert(nonce.len == GCM_NONCE_SIZE);
        std.debug.assert(allocator != null);
        std.debug.assert(self != null);
        return decrypt_aes256_gcm(allocator, encrypted_data, &self.default_key, nonce);
    }
};
