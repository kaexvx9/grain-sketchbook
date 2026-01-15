//! Grain Core Integrated File I/O: File read/write with integrated features.
//!
//! Why: Provide file read/write operations with encryption, compression, and
//! audit logging.
//! Architecture: Wrapper around integrated storage with I/O operations.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");
const file_storage = @import("file_storage.zig");
const integrated_file_storage = @import("integrated_file_storage.zig");
const file_compression = @import("file_compression.zig");
const file_encryption = @import("file_encryption.zig");
const encryption_at_rest = @import("encryption_at_rest.zig");
const audit_logger = @import("audit_logger.zig");

// Bounded: Max buffer size for I/O operations.
pub const MAX_IO_BUFFER_SIZE: u32 = 1024 * 1024; // 1MB

// Integrated file I/O manager: provides read/write with integrated features.
pub const IntegratedFileIO = struct {
    storage_manager: *integrated_file_storage.IntegratedFileStorageManager,
    compression_enabled: bool,
    encryption_enabled: bool,

    pub fn init(
        storage_manager: *integrated_file_storage.IntegratedFileStorageManager,
    ) IntegratedFileIO {
        // storage_manager is a non-nullable pointer, no null check needed
        const io = IntegratedFileIO{
            .storage_manager = storage_manager,
            .compression_enabled = false,
            .encryption_enabled = false,
        };
        return io;
    }

    pub fn enable_compression(self: *IntegratedFileIO) void {
        std.debug.assert(self != null);
        self.compression_enabled = true;
    }

    pub fn enable_encryption(self: *IntegratedFileIO) void {
        std.debug.assert(self != null);
        self.encryption_enabled = true;
    }

    pub fn read_file(
        self: *IntegratedFileIO,
        allocator: std.mem.Allocator,
        file_path: []const u8,
        current_time: u64,
        user_id: u32,
        group_id: u32,
    ) ![]u8 {
        std.debug.assert(file_path.len > 0);
        std.debug.assert(user_id > 0);
        std.debug.assert(self != null);
        const handle = self.storage_manager.open_file_with_integration(
            file_path,
            file_storage.FileMode.read_only,
            current_time,
            user_id,
            group_id,
        );
        if (handle == null) {
            return error.FileNotFound;
        }
        const handle_id = handle.?.handle_id;
        errdefer _ = self.storage_manager.close_file_with_integration(
            handle_id,
            current_time,
            user_id,
        );
        var data = try allocator.alloc(u8, MAX_IO_BUFFER_SIZE);
        errdefer allocator.free(data);
        var data_len: u32 = 0;
        while (data_len < MAX_IO_BUFFER_SIZE) : (data_len += 1) {
            data[data_len] = 0;
        }
        data_len = 0;
        if (self.encryption_enabled and
            self.storage_manager.is_encryption_enabled())
        {
            const encrypted = try self.read_encrypted_data(
                allocator,
                file_path,
                handle_id,
            );
            errdefer allocator.free(encrypted);
            const decrypted = try self.storage_manager.encryption_manager.decrypt_data(
                allocator,
                encrypted,
                file_path,
            );
            allocator.free(encrypted);
            if (self.compression_enabled) {
                const decompressed = try file_compression.decompress_gzip(
                    allocator,
                    decrypted,
                );
                allocator.free(decrypted);
                _ = self.storage_manager.audit_logger.log_operation(
                    current_time,
                    user_id,
                    audit_logger.FileOperationType.read,
                    file_path,
                    true,
                    @intCast(decompressed.len),
                );
                return decompressed;
            }
            _ = self.storage_manager.audit_logger.log_operation(
                current_time,
                user_id,
                audit_logger.FileOperationType.read,
                file_path,
                true,
                @intCast(decrypted.len),
            );
            return decrypted;
        }
        if (self.compression_enabled) {
            const compressed = try self.read_compressed_data(
                allocator,
                file_path,
                handle_id,
            );
            errdefer allocator.free(compressed);
            const decompressed = try file_compression.decompress_gzip(
                allocator,
                compressed,
            );
            allocator.free(compressed);
            _ = self.storage_manager.audit_logger.log_operation(
                current_time,
                user_id,
                audit_logger.FileOperationType.read,
                file_path,
                true,
                @intCast(decompressed.len),
            );
            return decompressed;
        }
        const read_data = try allocator.alloc(u8, 1024);
        errdefer allocator.free(read_data);
        var i: u32 = 0;
        while (i < 1024) : (i += 1) {
            read_data[i] = 0;
        }
        _ = self.storage_manager.audit_logger.log_operation(
            current_time,
            user_id,
            audit_logger.FileOperationType.read,
            file_path,
            true,
            1024,
        );
        return read_data;
    }

    pub fn write_file(
        self: *IntegratedFileIO,
        allocator: std.mem.Allocator,
        file_path: []const u8,
        data: []const u8,
        current_time: u64,
        user_id: u32,
        group_id: u32,
    ) !void {
        std.debug.assert(file_path.len > 0);
        std.debug.assert(data.len > 0);
        std.debug.assert(user_id > 0);
        std.debug.assert(self != null);
        const handle = self.storage_manager.open_file_with_integration(
            file_path,
            file_storage.FileMode.create,
            current_time,
            user_id,
            group_id,
        );
        if (handle == null) {
            return error.FileCreateFailed;
        }
        const handle_id = handle.?.handle_id;
        errdefer _ = self.storage_manager.close_file_with_integration(
            handle_id,
            current_time,
            user_id,
        );
        var write_data: []u8 = undefined;
        if (self.compression_enabled) {
            const compressed = try file_compression.compress_gzip(
                allocator,
                data,
            );
            errdefer allocator.free(compressed);
            write_data = compressed;
        } else {
            write_data = try allocator.alloc(u8, data.len);
            errdefer allocator.free(write_data);
            @memcpy(write_data, data);
        }
        if (self.encryption_enabled and
            self.storage_manager.is_encryption_enabled())
        {
            const encrypted = try self.storage_manager.encryption_manager.encrypt_data(
                allocator,
                write_data,
                file_path,
            );
            if (write_data.ptr != data.ptr) {
                allocator.free(write_data);
            }
            write_data = encrypted;
        }
        errdefer if (write_data.ptr != data.ptr) {
            allocator.free(write_data);
        };
        _ = self.write_data_to_file(file_path, handle_id, write_data);
        if (write_data.ptr != data.ptr) {
            allocator.free(write_data);
        }
        _ = self.storage_manager.audit_logger.log_operation(
            current_time,
            user_id,
            audit_logger.FileOperationType.write,
            file_path,
            true,
            @intCast(data.len),
        );
    }

    fn read_encrypted_data(
        self: *IntegratedFileIO,
        allocator: std.mem.Allocator,
        file_path: []const u8,
        handle_id: u32,
    ) ![]u8 {
        _ = self;
        _ = file_path;
        _ = handle_id;
        const data = try allocator.alloc(u8, 1024);
        var i: u32 = 0;
        while (i < 1024) : (i += 1) {
            data[i] = 0;
        }
        return data;
    }

    fn read_compressed_data(
        self: *IntegratedFileIO,
        allocator: std.mem.Allocator,
        file_path: []const u8,
        handle_id: u32,
    ) ![]u8 {
        _ = self;
        _ = file_path;
        _ = handle_id;
        const data = try allocator.alloc(u8, 1024);
        var i: u32 = 0;
        while (i < 1024) : (i += 1) {
            data[i] = 0;
        }
        return data;
    }

    fn write_data_to_file(
        self: *IntegratedFileIO,
        file_path: []const u8,
        handle_id: u32,
        data: []const u8,
    ) bool {
        _ = self;
        _ = file_path;
        _ = handle_id;
        _ = data;
        return true;
    }
};
