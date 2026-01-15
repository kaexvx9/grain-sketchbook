//! Grain Core File ID Manager: File ID generation and mapping.
//!
//! Why: Provide file ID (UUID) generation and file ID → file path mapping
//! for Network Agent HTTP file transfer integration.
//! Architecture: Bounded in-memory mapping of file IDs to file paths.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");
const file_storage = @import("file_storage.zig");

// Bounded: Max file ID mappings.
pub const MAX_FILE_ID_MAPPINGS: u32 = 1000;

// Bounded: Max file ID length (UUID format: 36 chars with hyphens, 64 for
// flexibility).
pub const MAX_FILE_ID_LEN: u32 = 64;

// File ID mapping entry.
pub const FileIdMapping = struct {
    file_id: [MAX_FILE_ID_LEN]u8,
    file_id_len: u32,
    file_path: [file_storage.MAX_FILENAME_LEN]u8,
    file_path_len: u32,
    file_size: u64,
    created_at: u64,
    active: bool,

    pub fn init() FileIdMapping {
        var mapping = FileIdMapping{
            .file_id = undefined,
            .file_id_len = 0,
            .file_path = undefined,
            .file_path_len = 0,
            .file_size = 0,
            .created_at = 0,
            .active = false,
        };
        var i: u32 = 0;
        while (i < MAX_FILE_ID_LEN) : (i += 1) {
            mapping.file_id[i] = 0;
        }
        i = 0;
        while (i < file_storage.MAX_FILENAME_LEN) : (i += 1) {
            mapping.file_path[i] = 0;
        }
        return mapping;
    }

    pub fn set_file_id(self: *FileIdMapping, file_id: []const u8) bool {
        std.debug.assert(file_id.len > 0);
        std.debug.assert(file_id.len <= MAX_FILE_ID_LEN);
        if (file_id.len == 0 or file_id.len > MAX_FILE_ID_LEN) {
            return false;
        }
        var i: u32 = 0;
        while (i < MAX_FILE_ID_LEN) : (i += 1) {
            self.file_id[i] = 0;
        }
        const id_len = @min(file_id.len, MAX_FILE_ID_LEN);
        i = 0;
        while (i < id_len) : (i += 1) {
            self.file_id[i] = file_id[i];
        }
        self.file_id_len = id_len;
        return true;
    }

    pub fn set_file_path(self: *FileIdMapping, file_path: []const u8) bool {
        std.debug.assert(file_path.len > 0);
        std.debug.assert(file_path.len <= file_storage.MAX_FILENAME_LEN);
        if (file_path.len == 0 or file_path.len > file_storage.MAX_FILENAME_LEN) {
            return false;
        }
        var i: u32 = 0;
        while (i < file_storage.MAX_FILENAME_LEN) : (i += 1) {
            self.file_path[i] = 0;
        }
        const path_len = @min(file_path.len, file_storage.MAX_FILENAME_LEN);
        i = 0;
        while (i < path_len) : (i += 1) {
            self.file_path[i] = file_path[i];
        }
        self.file_path_len = path_len;
        return true;
    }

    pub fn get_file_id(self: *const FileIdMapping) []const u8 {
        std.debug.assert(self.file_id_len > 0);
        return self.file_id[0..self.file_id_len];
    }

    pub fn get_file_path(self: *const FileIdMapping) []const u8 {
        std.debug.assert(self.file_path_len > 0);
        return self.file_path[0..self.file_path_len];
    }
};

// File ID manager.
pub const FileIdManager = struct {
    mappings: [MAX_FILE_ID_MAPPINGS]FileIdMapping,
    mappings_len: u32,
    current_time_fn: *const fn () u64,

    pub fn init(current_time_fn: *const fn () u64) FileIdManager {
        var manager = FileIdManager{
            .mappings = undefined,
            .mappings_len = 0,
            .current_time_fn = current_time_fn,
        };
        var i: u32 = 0;
        while (i < MAX_FILE_ID_MAPPINGS) : (i += 1) {
            manager.mappings[i] = FileIdMapping.init();
        }
        return manager;
    }

    // Generate simple file ID from file path and timestamp (hash-based).
    pub fn generate_file_id(
        self: *FileIdManager,
        file_path: []const u8,
    ) [64]u8 {
        std.debug.assert(file_path.len > 0);
        const current_time = self.current_time_fn();
        var combined: [512]u8 = undefined;
        const path_len = @min(file_path.len, 256);
        var i: u32 = 0;
        while (i < path_len) : (i += 1) {
            combined[i] = file_path[i];
        }
        const time_bytes = std.mem.asBytes(&current_time);
        i = 0;
        while (i < time_bytes.len) : (i += 1) {
            combined[path_len + i] = time_bytes[i];
        }
        var hash: [32]u8 = undefined;
        std.crypto.hash.sha2.Sha256.hash(combined[0..path_len + time_bytes.len], &hash, .{});
        var file_id: [64]u8 = undefined;
        i = 0;
        while (i < 32) : (i += 1) {
            const byte = hash[i];
            const high_nibble = (byte >> 4) & 0x0F;
            const low_nibble = byte & 0x0F;
            file_id[i * 2] = if (high_nibble < 10) '0' + @as(u8, @intCast(high_nibble)) else 'a' + @as(u8, @intCast(high_nibble - 10));
            file_id[i * 2 + 1] = if (low_nibble < 10) '0' + @as(u8, @intCast(low_nibble)) else 'a' + @as(u8, @intCast(low_nibble - 10));
        }
        return file_id;
    }

    // Generate file ID string from file path (returns slice of internal buffer).
    pub fn generate_file_id_string(
        self: *FileIdManager,
        file_path: []const u8,
    ) []const u8 {
        std.debug.assert(file_path.len > 0);
        const file_id_bytes = self.generate_file_id(file_path);
        var len: u32 = 0;
        while (len < 64 and file_id_bytes[len] != 0) : (len += 1) {}
        return file_id_bytes[0..len];
    }

    // Store file ID → file path mapping.
    pub fn store_mapping(
        self: *FileIdManager,
        file_id: []const u8,
        file_path: []const u8,
        file_size: u64,
    ) bool {
        std.debug.assert(file_id.len > 0);
        std.debug.assert(file_path.len > 0);
        if (self.mappings_len >= MAX_FILE_ID_MAPPINGS) {
            return false;
        }
        if (self.get_mapping(file_id) != null) {
            return false;
        }
        const current_time = self.current_time_fn();
        var mapping = &self.mappings[self.mappings_len];
        _ = mapping.set_file_id(file_id);
        _ = mapping.set_file_path(file_path);
        mapping.file_size = file_size;
        mapping.created_at = current_time;
        mapping.active = true;
        self.mappings_len += 1;
        return true;
    }

    // Get mapping by file ID.
    pub fn get_mapping(
        self: *const FileIdManager,
        file_id: []const u8,
    ) ?*const FileIdMapping {
        std.debug.assert(file_id.len > 0);
        var i: u32 = 0;
        while (i < self.mappings_len) : (i += 1) {
            const mapping = &self.mappings[i];
            if (mapping.active and std.mem.eql(
                u8,
                mapping.get_file_id(),
                file_id,
            )) {
                return mapping;
            }
        }
        return null;
    }

    // Get file path from file ID.
    pub fn get_file_path(
        self: *const FileIdManager,
        file_id: []const u8,
    ) ?[]const u8 {
        std.debug.assert(file_id.len > 0);
        if (self.get_mapping(file_id)) |mapping| {
            return mapping.get_file_path();
        }
        return null;
    }

    // Get file size from file ID.
    pub fn get_file_size(
        self: *const FileIdManager,
        file_id: []const u8,
    ) ?u64 {
        std.debug.assert(file_id.len > 0);
        if (self.get_mapping(file_id)) |mapping| {
            return mapping.file_size;
        }
        return null;
    }

    // Remove mapping (mark as inactive).
    pub fn remove_mapping(self: *FileIdManager, file_id: []const u8) bool {
        std.debug.assert(file_id.len > 0);
        var i: u32 = 0;
        while (i < self.mappings_len) : (i += 1) {
            const mapping = &self.mappings[i];
            if (mapping.active and std.mem.eql(
                u8,
                mapping.get_file_id(),
                file_id,
            )) {
                mapping.active = false;
                return true;
            }
        }
        return false;
    }

    // Clear expired mappings (older than max_age seconds).
    pub fn clear_expired_mappings(
        self: *FileIdManager,
        max_age: u64,
    ) u32 {
        std.debug.assert(max_age > 0);
        const current_time = self.current_time_fn();
        var cleared: u32 = 0;
        var i: u32 = 0;
        while (i < self.mappings_len) : (i += 1) {
            const mapping = &self.mappings[i];
            if (mapping.active and (current_time - mapping.created_at) > max_age) {
                mapping.active = false;
                cleared += 1;
            }
        }
        return cleared;
    }
};
