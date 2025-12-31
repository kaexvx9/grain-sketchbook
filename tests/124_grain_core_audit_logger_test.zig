const std = @import("std");
const testing = std.testing;
const audit_logger = @import("grain_core").audit_logger;

test "audit log entry init" {
    const entry = audit_logger.AuditLogEntry.init();
    std.debug.assert(entry.entry_id == 0);
    std.debug.assert(entry.timestamp == 0);
    std.debug.assert(entry.user_id == 0);
    std.debug.assert(entry.file_path_len == 0);
    std.debug.assert(entry.success == false);
}

test "audit log entry set file path" {
    var entry = audit_logger.AuditLogEntry.init();
    const path = "/home/user/file.txt";
    const set = entry.set_file_path(path);
    std.debug.assert(set);
    std.debug.assert(entry.file_path_len == path.len);
}

test "audit log entry set file path - too long" {
    var entry = audit_logger.AuditLogEntry.init();
    var long_path: [600]u8 = undefined;
    var i: u32 = 0;
    while (i < 600) : (i += 1) {
        long_path[i] = 'a';
    }
    const set = entry.set_file_path(&long_path);
    std.debug.assert(!set);
}

test "audit logger init" {
    const logger = audit_logger.AuditLogger.init();
    std.debug.assert(logger.entries_len == 0);
    std.debug.assert(logger.next_entry_id == 1);
    std.debug.assert(logger.log_file_size == 0);
}

test "audit logger log operation" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    const logged = logger.log_operation(
        timestamp,
        user_id,
        audit_logger.FileOperationType.open,
        path,
        true,
        0,
    );
    std.debug.assert(logged);
    std.debug.assert(logger.entries_len == 1);
    std.debug.assert(logger.entries[0].timestamp == timestamp);
    std.debug.assert(logger.entries[0].user_id == user_id);
    std.debug.assert(logger.entries[0].operation ==
        audit_logger.FileOperationType.open);
    std.debug.assert(logger.entries[0].success == true);
}

test "audit logger log file open" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    const logged = logger.log_file_open(timestamp, user_id, path, true);
    std.debug.assert(logged);
    std.debug.assert(logger.entries_len == 1);
    std.debug.assert(logger.entries[0].operation ==
        audit_logger.FileOperationType.open);
}

test "audit logger log file read" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    const logged = logger.log_file_read(timestamp, user_id, path, true);
    std.debug.assert(logged);
    std.debug.assert(logger.entries_len == 1);
    std.debug.assert(logger.entries[0].operation ==
        audit_logger.FileOperationType.read);
}

test "audit logger log file write" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    const logged = logger.log_file_write(timestamp, user_id, path, true);
    std.debug.assert(logged);
    std.debug.assert(logger.entries_len == 1);
    std.debug.assert(logger.entries[0].operation ==
        audit_logger.FileOperationType.write);
}

test "audit logger log file delete" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    const logged = logger.log_file_delete(timestamp, user_id, path, true);
    std.debug.assert(logged);
    std.debug.assert(logger.entries_len == 1);
    std.debug.assert(logger.entries[0].operation ==
        audit_logger.FileOperationType.delete);
}

test "audit logger log operation - failure" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    const logged = logger.log_operation(
        timestamp,
        user_id,
        audit_logger.FileOperationType.open,
        path,
        false,
        1,
    );
    std.debug.assert(logged);
    std.debug.assert(logger.entries_len == 1);
    std.debug.assert(logger.entries[0].success == false);
    std.debug.assert(logger.entries[0].error_code == 1);
}

test "audit logger multiple entries" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    _ = logger.log_file_open(timestamp, user_id, path, true);
    _ = logger.log_file_read(timestamp + 1, user_id, path, true);
    _ = logger.log_file_write(timestamp + 2, user_id, path, true);
    std.debug.assert(logger.entries_len == 3);
    std.debug.assert(logger.entries[0].operation ==
        audit_logger.FileOperationType.open);
    std.debug.assert(logger.entries[1].operation ==
        audit_logger.FileOperationType.read);
    std.debug.assert(logger.entries[2].operation ==
        audit_logger.FileOperationType.write);
}

test "audit logger needs rotation - false" {
    var logger = audit_logger.AuditLogger.init();
    const needs = logger.needs_rotation();
    std.debug.assert(!needs);
}

test "audit logger clear entries" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    _ = logger.log_file_open(timestamp, user_id, path, true);
    std.debug.assert(logger.entries_len == 1);
    logger.clear_entries();
    std.debug.assert(logger.entries_len == 0);
    std.debug.assert(logger.log_file_size == 0);
}

test "audit logger get entry count" {
    var logger = audit_logger.AuditLogger.init();
    std.debug.assert(logger.get_entry_count() == 0);
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    _ = logger.log_file_open(timestamp, user_id, path, true);
    std.debug.assert(logger.get_entry_count() == 1);
}

test "audit logger all operation types" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    _ = logger.log_operation(
        timestamp,
        user_id,
        audit_logger.FileOperationType.create,
        path,
        true,
        0,
    );
    _ = logger.log_operation(
        timestamp + 1,
        user_id,
        audit_logger.FileOperationType.rename,
        path,
        true,
        0,
    );
    _ = logger.log_operation(
        timestamp + 2,
        user_id,
        audit_logger.FileOperationType.chmod,
        path,
        true,
        0,
    );
    _ = logger.log_operation(
        timestamp + 3,
        user_id,
        audit_logger.FileOperationType.chown,
        path,
        true,
        0,
    );
    _ = logger.log_operation(
        timestamp + 4,
        user_id,
        audit_logger.FileOperationType.close,
        path,
        true,
        0,
    );
    _ = logger.log_operation(
        timestamp + 5,
        user_id,
        audit_logger.FileOperationType.lock,
        path,
        true,
        0,
    );
    _ = logger.log_operation(
        timestamp + 6,
        user_id,
        audit_logger.FileOperationType.unlock,
        path,
        true,
        0,
    );
    std.debug.assert(logger.entries_len == 7);
}

test "audit logger log security event" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    const details = "Access denied";
    const logged = logger.log_security_event(
        timestamp,
        user_id,
        audit_logger.SecurityEventType.access_denied,
        path,
        details,
    );
    std.debug.assert(logged);
    std.debug.assert(logger.entries_len == 1);
    std.debug.assert(logger.entries[0].success == false);
}

test "audit logger log multiple security events" {
    var logger = audit_logger.AuditLogger.init();
    const timestamp: u64 = 1000;
    const user_id: u32 = 1000;
    const path = "/home/user/file.txt";
    _ = logger.log_security_event(
        timestamp,
        user_id,
        audit_logger.SecurityEventType.access_denied,
        path,
        "Access denied",
    );
    _ = logger.log_security_event(
        timestamp + 1,
        user_id,
        audit_logger.SecurityEventType.permission_denied,
        path,
        "Permission denied",
    );
    _ = logger.log_security_event(
        timestamp + 2,
        user_id,
        audit_logger.SecurityEventType.unauthorized_access,
        path,
        "Unauthorized access",
    );
    std.debug.assert(logger.entries_len == 3);
}
