//! Grain Core Integrated File Storage Tests.
//!
//! Why: Test integrated file storage manager with path resolution, audit
//! logging, and encryption at rest.
//! Architecture: Integration tests for integrated file storage.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const integrated_file_storage = @import("grain_core").integrated_file_storage;
const file_storage = @import("grain_core").file_storage;
const file_encryption = @import("grain_core").file_encryption;
const audit_logger = @import("grain_core").audit_logger;

fn get_nano_timestamp() u64 {
    return std.time.nanoTimestamp();
}

test "integrated file storage manager init" {
    const manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    std.debug.assert(manager.path_resolver_enabled == true);
    std.debug.assert(manager.permissions_enabled == true);
    std.debug.assert(manager.rate_limiting_enabled == true);
    std.debug.assert(manager.storage_manager.handles_len == 0);
}

test "integrated file storage open file with path resolution" {
    var manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    const filename = "/home/user/../other/file.txt";
    const mode = file_storage.FileMode.read_write;
    const current_time: u64 = 1000;
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    const handle = manager.open_file_with_integration(
        filename,
        mode,
        current_time,
        user_id,
        group_id,
    );
    std.debug.assert(handle != null);
    std.debug.assert(manager.storage_manager.handles_len == 1);
    std.debug.assert(manager.audit_logger.entries_len == 1);
}

test "integrated file storage open file with audit logging" {
    var manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    const filename = "/home/user/file.txt";
    const mode = file_storage.FileMode.read_write;
    const current_time: u64 = 1000;
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    const handle = manager.open_file_with_integration(
        filename,
        mode,
        current_time,
        user_id,
        group_id,
    );
    std.debug.assert(handle != null);
    const logger = manager.get_audit_logger();
    std.debug.assert(logger.entries_len == 1);
    std.debug.assert(logger.entries[0].operation ==
        audit_logger.FileOperationType.open);
    std.debug.assert(logger.entries[0].success == true);
}

test "integrated file storage close file with audit logging" {
    var manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    const filename = "/home/user/file.txt";
    const mode = file_storage.FileMode.read_write;
    const current_time: u64 = 1000;
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    const handle = manager.open_file_with_integration(
        filename,
        mode,
        current_time,
        user_id,
        group_id,
    );
    std.debug.assert(handle != null);
    const handle_id = handle.?.handle_id;
    const closed = manager.close_file_with_integration(
        handle_id,
        current_time + 1,
        user_id,
    );
    std.debug.assert(closed);
    std.debug.assert(manager.audit_logger.entries_len == 2);
    std.debug.assert(manager.audit_logger.entries[1].operation ==
        audit_logger.FileOperationType.close);
}

test "integrated file storage enable encryption at rest" {
    var manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    const enabled = manager.enable_encryption_at_rest(key);
    std.debug.assert(enabled);
    std.debug.assert(manager.is_encryption_enabled());
}

test "integrated file storage path normalization failure" {
    var manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    var invalid_path: [600]u8 = undefined;
    var i: u32 = 0;
    while (i < 600) : (i += 1) {
        invalid_path[i] = 'a';
    }
    const mode = file_storage.FileMode.read_write;
    const current_time: u64 = 1000;
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    const handle = manager.open_file_with_integration(
        &invalid_path,
        mode,
        current_time,
        user_id,
        group_id,
    );
    std.debug.assert(handle == null);
    std.debug.assert(manager.audit_logger.entries_len == 1);
    std.debug.assert(manager.audit_logger.entries[0].success == false);
}

test "integrated file storage full workflow" {
    var manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_nano_timestamp,
    );
    var key_bytes: [32]u8 = undefined;
    std.crypto.random.bytes(&key_bytes);
    const key = file_encryption.EncryptionKey.from_bytes(&key_bytes);
    _ = manager.enable_encryption_at_rest(key);
    const filename = "/home/user/../data/file.txt";
    const mode = file_storage.FileMode.read_write;
    const current_time: u64 = 1000;
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    const handle = manager.open_file_with_integration(
        filename,
        mode,
        current_time,
        user_id,
        group_id,
    );
    std.debug.assert(handle != null);
    std.debug.assert(manager.storage_manager.handles_len == 1);
    std.debug.assert(manager.audit_logger.entries_len == 1);
    std.debug.assert(manager.is_encryption_enabled());
    const handle_id = handle.?.handle_id;
    const closed = manager.close_file_with_integration(
        handle_id,
        current_time + 1,
        user_id,
    );
    std.debug.assert(closed);
    std.debug.assert(manager.audit_logger.entries_len == 2);
}

test "integrated file storage rate limiting" {
    var time_counter: u64 = 1000;
    fn get_time() u64 {
        return time_counter;
    }
    var manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_time,
    );
    const filename = "/home/user/file.txt";
    const mode = file_storage.FileMode.read_write;
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        time_counter = 1000 + i;
        const handle = manager.open_file_with_integration(
            filename,
            mode,
            time_counter,
            user_id,
            group_id,
        );
        std.debug.assert(handle != null);
        _ = manager.close_file_with_integration(
            handle.?.handle_id,
            time_counter + 1,
            user_id,
        );
    }
    std.debug.assert(manager.storage_manager.handles_len == 0);
}

test "integrated file storage rate limit exceeded" {
    var time_counter: u64 = 1000;
    fn get_time() u64 {
        return time_counter;
    }
    var manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_time,
    );
    const filename = "/home/user/file.txt";
    const mode = file_storage.FileMode.read_write;
    const user_id: u32 = 1000;
    const group_id: u32 = 100;
    var i: u32 = 0;
    while (i < 101) : (i += 1) {
        time_counter = 1000;
        const handle = manager.open_file_with_integration(
            filename,
            mode,
            time_counter,
            user_id,
            group_id,
        );
        if (i < 100) {
            std.debug.assert(handle != null);
        } else {
            std.debug.assert(handle == null);
        }
    }
}

test "integrated file storage permission checking" {
    var time_counter: u64 = 1000;
    fn get_time() u64 {
        return time_counter;
    }
    var manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_time,
    );
    const filename = "/home/user/file.txt";
    const mode = file_storage.FileMode.create;
    const current_time: u64 = 1000;
    const owner_id: u32 = 1000;
    const owner_group_id: u32 = 100;
    const handle = manager.open_file_with_integration(
        filename,
        mode,
        current_time,
        owner_id,
        owner_group_id,
    );
    std.debug.assert(handle != null);
    _ = manager.close_file_with_integration(
        handle.?.handle_id,
        current_time + 1,
        owner_id,
    );
    const other_user_id: u32 = 2000;
    const other_group_id: u32 = 200;
    const read_handle = manager.open_file_with_integration(
        filename,
        file_storage.FileMode.read_only,
        current_time + 2,
        other_user_id,
        other_group_id,
    );
    std.debug.assert(read_handle != null);
}

test "integrated file storage permission denied" {
    var time_counter: u64 = 1000;
    fn get_time() u64 {
        return time_counter;
    }
    var manager = integrated_file_storage.IntegratedFileStorageManager.init(
        get_time,
    );
    manager.permissions_enabled = false;
    const filename = "/home/user/file.txt";
    const mode = file_storage.FileMode.create;
    const current_time: u64 = 1000;
    const owner_id: u32 = 1000;
    const owner_group_id: u32 = 100;
    const handle = manager.open_file_with_integration(
        filename,
        mode,
        current_time,
        owner_id,
        owner_group_id,
    );
    std.debug.assert(handle != null);
    _ = manager.close_file_with_integration(
        handle.?.handle_id,
        current_time + 1,
        owner_id,
    );
    manager.permissions_enabled = true;
    const other_user_id: u32 = 2000;
    const other_group_id: u32 = 200;
    const write_handle = manager.open_file_with_integration(
        filename,
        file_storage.FileMode.read_write,
        current_time + 2,
        other_user_id,
        other_group_id,
    );
    std.debug.assert(write_handle == null);
    std.debug.assert(manager.audit_logger.entries_len >= 1);
}
