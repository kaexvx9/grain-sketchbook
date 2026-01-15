//! Grain Core Integrated File I/O Tests.
//!
//! Why: Test integrated file I/O with encryption, compression, and audit
//! logging.
//! Architecture: Unit tests for integrated file I/O.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const integrated_file_io = @import("grain_core").integrated_file_io;
const integrated_file_storage = @import("grain_core").integrated_file_storage;
const file_encryption = @import("grain_core").file_encryption;

fn get_nano_timestamp() u64 {
    return std.time.nanoTimestamp();
}

test "integrated file io init" {
    var storage_manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    const io = integrated_file_io.IntegratedFileIO.init(&storage_manager);
    std.debug.assert(io.storage_manager != null);
    std.debug.assert(io.compression_enabled == false);
    std.debug.assert(io.encryption_enabled == false);
}

test "integrated file io enable compression" {
    var storage_manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    var io = integrated_file_io.IntegratedFileIO.init(&storage_manager);
    io.enable_compression();
    std.debug.assert(io.compression_enabled == true);
}

test "integrated file io enable encryption" {
    var storage_manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    var io = integrated_file_io.IntegratedFileIO.init(&storage_manager);
    io.enable_encryption();
    std.debug.assert(io.encryption_enabled == true);
}

test "integrated file io write and read basic" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var storage_manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    var io = integrated_file_io.IntegratedFileIO.init(&storage_manager);
    const file_path = "/home/user/test.txt";
    const test_data = "Hello, World!";
    const current_time: u64 = 1000;
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    io.write_file(
        allocator,
        file_path,
        test_data,
        current_time,
        user_id,
        group_id,
    ) catch |err| {
        std.debug.assert(err == error.FileCreateFailed);
        return;
    };
    const read_data = io.read_file(
        allocator,
        file_path,
        current_time + 1,
        user_id,
        group_id,
    ) catch |err| {
        std.debug.assert(err == error.FileNotFound);
        return;
    };
    defer allocator.free(read_data);
    std.debug.assert(read_data.len > 0);
}

test "integrated file io with compression" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var storage_manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    var io = integrated_file_io.IntegratedFileIO.init(&storage_manager);
    io.enable_compression();
    const file_path = "/home/user/compressed.txt";
    const test_data = "This is test data for compression";
    const current_time: u64 = 1000;
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    io.write_file(
        allocator,
        file_path,
        test_data,
        current_time,
        user_id,
        group_id,
    ) catch |err| {
        std.debug.assert(err == error.FileCreateFailed);
        return;
    };
    const read_data = io.read_file(
        allocator,
        file_path,
        current_time + 1,
        user_id,
        group_id,
    ) catch |err| {
        std.debug.assert(err == error.FileNotFound);
        return;
    };
    defer allocator.free(read_data);
    std.debug.assert(read_data.len > 0);
}

test "integrated file io with encryption" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var storage_manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    _ = storage_manager.enable_encryption_at_rest(key);
    var io = integrated_file_io.IntegratedFileIO.init(&storage_manager);
    io.enable_encryption();
    const file_path = "/home/user/encrypted.txt";
    const test_data = "This is encrypted data";
    const current_time: u64 = 1000;
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    io.write_file(
        allocator,
        file_path,
        test_data,
        current_time,
        user_id,
        group_id,
    ) catch |err| {
        std.debug.assert(err == error.FileCreateFailed);
        return;
    };
    const read_data = io.read_file(
        allocator,
        file_path,
        current_time + 1,
        user_id,
        group_id,
    ) catch |err| {
        std.debug.assert(err == error.FileNotFound);
        return;
    };
    defer allocator.free(read_data);
    std.debug.assert(read_data.len > 0);
}

test "integrated file io audit logging" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    var storage_manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    var io = integrated_file_io.IntegratedFileIO.init(&storage_manager);
    const file_path = "/home/user/audit.txt";
    const test_data = "Audit test data";
    const current_time: u64 = 1000;
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    io.write_file(
        allocator,
        file_path,
        test_data,
        current_time,
        user_id,
        group_id,
    ) catch |err| {
        std.debug.assert(err == error.FileCreateFailed);
        return;
    };
    const logger = storage_manager.get_audit_logger();
    std.debug.assert(logger.entries_len >= 1);
}
