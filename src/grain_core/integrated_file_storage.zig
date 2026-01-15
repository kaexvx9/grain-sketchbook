//! Grain Core Integrated File Storage: Integrated file storage with new modules.
//!
//! Why: Integrate path resolution, permissions, audit logging, and encryption at
//! rest with file storage manager.
//! Architecture: Wrapper around FileStorageManager with integrated features.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");
const file_storage = @import("file_storage.zig");
const path_resolver = @import("path_resolver.zig");
const file_permissions = @import("file_permissions.zig");
const audit_logger = @import("audit_logger.zig");
const encryption_at_rest = @import("encryption_at_rest.zig");
const file_encryption = @import("file_encryption.zig");
const file_operation_rate_limiter = @import("file_operation_rate_limiter.zig");

// File permissions entry: stores permissions for a file path.
const FilePermissionsEntry = struct {
    file_path: [path_resolver.MAX_PATH_LEN]u8,
    file_path_len: u32,
    permissions: file_permissions.FilePermissions,
    active: bool,
};

// Bounded: Max file permission entries.
const MAX_FILE_PERMISSIONS: u32 = 1000;

// Integrated file storage manager.
pub const IntegratedFileStorageManager = struct {
    storage_manager: file_storage.FileStorageManager,
    path_resolver_enabled: bool,
    permissions_enabled: bool,
    rate_limiting_enabled: bool,
    audit_logger: audit_logger.AuditLogger,
    encryption_manager: encryption_at_rest.EncryptionAtRestManager,
    permission_manager: file_permissions.PermissionManager,
    rate_limiter: file_operation_rate_limiter.FileOperationRateLimiter,
    file_permissions_store: [MAX_FILE_PERMISSIONS]FilePermissionsEntry,
    file_permissions_len: u32,


    pub fn init(
        current_time_fn: *const fn () u64,
    ) IntegratedFileStorageManager {
        var manager = IntegratedFileStorageManager{
            .storage_manager = file_storage.FileStorageManager.init(),
            .path_resolver_enabled = true,
            .permissions_enabled = true,
            .rate_limiting_enabled = true,
            .audit_logger = audit_logger.AuditLogger.init(),
            .encryption_manager = encryption_at_rest.EncryptionAtRestManager.init(),
            .permission_manager = file_permissions.PermissionManager.init(),
            .rate_limiter = file_operation_rate_limiter.FileOperationRateLimiter.init(
                10,
                100,
                current_time_fn,
            ),
            .file_permissions_store = undefined,
            .file_permissions_len = 0,
        };
        var i: u32 = 0;
        while (i < MAX_FILE_PERMISSIONS) : (i += 1) {
            manager.file_permissions_store[i] = FilePermissionsEntry{
                .file_path = undefined,
                .file_path_len = 0,
                .permissions = file_permissions.FilePermissions.init(0, 0),
                .active = false,
            };
        }
        return manager;
    }

    pub fn open_file_with_integration(
        self: *IntegratedFileStorageManager,
        filename: []const u8,
        mode: file_storage.FileMode,
        current_time: u64,
        user_id: u32,
        group_id: u32,
    ) ?*file_storage.FileHandle {
        std.debug.assert(filename.len > 0);
        std.debug.assert(user_id > 0);
        std.debug.assert(self != null);
        if (self.rate_limiting_enabled) {
            if (!self.rate_limiter.check_rate_limit(user_id)) {
                _ = self.audit_logger.log_security_event(
                    current_time,
                    user_id,
                    audit_logger.SecurityEventType.access_denied,
                    filename,
                    "Rate limit exceeded",
                );
                return null;
            }
        }
        var resolved_path: []const u8 = filename;
        var path_result = path_resolver.PathResolutionResult.init();
        if (self.path_resolver_enabled) {
            if (!path_resolver.normalize_path(filename, &path_result)) {
                _ = self.audit_logger.log_security_event(
                    current_time,
                    user_id,
                    audit_logger.SecurityEventType.access_denied,
                    filename,
                    "Path normalization failed",
                );
                return null;
            }
            if (!path_result.is_valid) {
                return null;
            }
            resolved_path = path_result.resolved_path[0..path_result.resolved_path_len];
        }
        if (self.permissions_enabled) {
            const file_perms = self.get_or_create_file_permissions(
                resolved_path,
                user_id,
                group_id,
                mode,
            );
            const required_access = switch (mode) {
                .read_only => file_permissions.AccessType.read,
                .read_write => file_permissions.AccessType.write,
                .create => file_permissions.AccessType.write,
            };
            if (!file_permissions.check_access(
                &file_perms,
                user_id,
                group_id,
                required_access,
            )) {
                _ = self.audit_logger.log_security_event(
                    current_time,
                    user_id,
                    audit_logger.SecurityEventType.permission_denied,
                    resolved_path,
                    "Permission denied",
                );
                return null;
            }
        }
        const handle = self.storage_manager.open_file(
            resolved_path,
            mode,
            current_time,
        );
        if (handle != null) {
            _ = self.audit_logger.log_file_open(
                current_time,
                user_id,
                resolved_path,
                true,
            );
        } else {
            _ = self.audit_logger.log_file_open(
                current_time,
                user_id,
                resolved_path,
                false,
            );
        }
        std.debug.assert(handle == null or handle.?.handle_id > 0);
        return handle;
    }

    pub fn close_file_with_integration(
        self: *IntegratedFileStorageManager,
        handle_id: u32,
        current_time: u64,
        user_id: u32,
    ) bool {
        std.debug.assert(handle_id > 0);
        std.debug.assert(user_id > 0);
        std.debug.assert(self != null);
        const handle = self.storage_manager.find_handle(handle_id);
        if (handle == null) {
            return false;
        }
        const file_path = handle.?.filename[0..handle.?.filename_len];
        const closed = self.storage_manager.close_file(handle_id);
        if (closed) {
            _ = self.audit_logger.log_operation(
                current_time,
                user_id,
                audit_logger.FileOperationType.close,
                file_path,
                true,
                0,
            );
        }
        std.debug.assert(!closed or self.storage_manager.find_handle(handle_id) == null);
        return closed;
    }

    pub fn enable_encryption_at_rest(
        self: *IntegratedFileStorageManager,
        key: file_encryption.EncryptionKey,
    ) bool {
        std.debug.assert(self != null);
        return self.encryption_manager.enable_encryption(key);
    }

    pub fn is_encryption_enabled(
        self: *const IntegratedFileStorageManager,
    ) bool {
        std.debug.assert(self != null);
        return self.encryption_manager.is_encryption_enabled();
    }

    pub fn get_audit_logger(
        self: *IntegratedFileStorageManager,
    ) *audit_logger.AuditLogger {
        std.debug.assert(self != null);
        return &self.audit_logger;
    }

    fn get_or_create_file_permissions(
        self: *IntegratedFileStorageManager,
        file_path: []const u8,
        owner_id: u32,
        group_id: u32,
        mode: file_storage.FileMode,
    ) file_permissions.FilePermissions {
        std.debug.assert(file_path.len > 0);
        std.debug.assert(owner_id > 0);
        var i: u32 = 0;
        while (i < self.file_permissions_len) : (i += 1) {
            if (self.file_permissions_store[i].active) {
                const stored_path = self.file_permissions_store[i].file_path[0..
                    self.file_permissions_store[i].file_path_len];
                if (std.mem.eql(u8, stored_path, file_path)) {
                    return self.file_permissions_store[i].permissions;
                }
            }
        }
        if (mode == file_storage.FileMode.create) {
            const perms = self.permission_manager.create_file_permissions(
                owner_id,
                group_id,
            );
            if (self.file_permissions_len < MAX_FILE_PERMISSIONS) {
                const entry = &self.file_permissions_store[self.file_permissions_len];
                const path_len = @min(file_path.len, path_resolver.MAX_PATH_LEN);
                var j: u32 = 0;
                while (j < path_resolver.MAX_PATH_LEN) : (j += 1) {
                    entry.file_path[j] = 0;
                }
                j = 0;
                while (j < path_len) : (j += 1) {
                    entry.file_path[j] = file_path[j];
                }
                entry.file_path_len = @intCast(path_len);
                entry.permissions = perms;
                entry.active = true;
                self.file_permissions_len += 1;
            }
            return perms;
        }
        return self.permission_manager.create_file_permissions(owner_id, group_id);
    }
};
