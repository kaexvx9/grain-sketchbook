//! Grain Core File Permissions: File permissions and access control.
//!
//! Why: Provide file permissions and access control for file operations.
//! Architecture: Unix-like permissions (rwx for user/group/other).
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");

// Bounded: Max user ID.
pub const MAX_USER_ID: u32 = 65535;

// Bounded: Max group ID.
pub const MAX_GROUP_ID: u32 = 65535;

// File permission bits (Unix-like: rwxrwxrwx).
pub const PermissionBits = packed struct(u16) {
    owner_read: bool,
    owner_write: bool,
    owner_execute: bool,
    group_read: bool,
    group_write: bool,
    group_execute: bool,
    other_read: bool,
    other_execute: bool,
    other_write: bool,
    setuid: bool,
    setgid: bool,
    sticky: bool,
    _padding: u4 = 0,

    pub fn init() PermissionBits {
        return PermissionBits{
            .owner_read = false,
            .owner_write = false,
            .owner_execute = false,
            .group_read = false,
            .group_write = false,
            .group_execute = false,
            .other_read = false,
            .other_write = false,
            .other_execute = false,
            .setuid = false,
            .setgid = false,
            .sticky = false,
            ._padding = 0,
        };
    }

    pub fn from_octal(octal: u16) PermissionBits {
        std.debug.assert(octal <= 0o7777);
        var bits = PermissionBits.init();
        bits.owner_read = (octal & 0o400) != 0;
        bits.owner_write = (octal & 0o200) != 0;
        bits.owner_execute = (octal & 0o100) != 0;
        bits.group_read = (octal & 0o040) != 0;
        bits.group_write = (octal & 0o020) != 0;
        bits.group_execute = (octal & 0o010) != 0;
        bits.other_read = (octal & 0o004) != 0;
        bits.other_write = (octal & 0o002) != 0;
        bits.other_execute = (octal & 0o001) != 0;
        bits.setuid = (octal & 0o4000) != 0;
        bits.setgid = (octal & 0o2000) != 0;
        bits.sticky = (octal & 0o1000) != 0;
        return bits;
    }

    pub fn to_octal(self: PermissionBits) u16 {
        var octal: u16 = 0;
        if (self.owner_read) octal |= 0o400;
        if (self.owner_write) octal |= 0o200;
        if (self.owner_execute) octal |= 0o100;
        if (self.group_read) octal |= 0o040;
        if (self.group_write) octal |= 0o020;
        if (self.group_execute) octal |= 0o010;
        if (self.other_read) octal |= 0o004;
        if (self.other_write) octal |= 0o002;
        if (self.other_execute) octal |= 0o001;
        if (self.setuid) octal |= 0o4000;
        if (self.setgid) octal |= 0o2000;
        if (self.sticky) octal |= 0o1000;
        return octal;
    }
};

// File permissions: user, group, permissions.
pub const FilePermissions = struct {
    owner_id: u32,
    group_id: u32,
    permissions: PermissionBits,

    pub fn init(owner_id: u32, group_id: u32) FilePermissions {
        std.debug.assert(owner_id <= MAX_USER_ID);
        std.debug.assert(group_id <= MAX_GROUP_ID);
        return FilePermissions{
            .owner_id = owner_id,
            .group_id = group_id,
            .permissions = PermissionBits.init(),
        };
    }

    pub fn from_octal(
        owner_id: u32,
        group_id: u32,
        octal: u16,
    ) FilePermissions {
        std.debug.assert(owner_id <= MAX_USER_ID);
        std.debug.assert(group_id <= MAX_GROUP_ID);
        std.debug.assert(octal <= 0o7777);
        return FilePermissions{
            .owner_id = owner_id,
            .group_id = group_id,
            .permissions = PermissionBits.from_octal(octal),
        };
    }

    pub fn set_permissions(self: *FilePermissions, octal: u16) void {
        std.debug.assert(octal <= 0o7777);
        self.permissions = PermissionBits.from_octal(octal);
    }
};

// Access type for permission checks.
pub const AccessType = enum(u8) {
    read,
    write,
    execute,
};

// Check if user has access to file.
pub fn check_access(
    perms: *const FilePermissions,
    user_id: u32,
    group_id: u32,
    access_type: AccessType,
) bool {
    std.debug.assert(user_id <= MAX_USER_ID);
    std.debug.assert(group_id <= MAX_GROUP_ID);
    std.debug.assert(perms != null);
    if (user_id == perms.owner_id) {
        return switch (access_type) {
            .read => perms.permissions.owner_read,
            .write => perms.permissions.owner_write,
            .execute => perms.permissions.owner_execute,
        };
    }
    if (group_id == perms.group_id) {
        return switch (access_type) {
            .read => perms.permissions.group_read,
            .write => perms.permissions.group_write,
            .execute => perms.permissions.group_execute,
        };
    }
    return switch (access_type) {
        .read => perms.permissions.other_read,
        .write => perms.permissions.other_write,
        .execute => perms.permissions.other_execute,
    };
}

// Check if user can read file.
pub fn can_read(
    perms: *const FilePermissions,
    user_id: u32,
    group_id: u32,
) bool {
    std.debug.assert(user_id <= MAX_USER_ID);
    std.debug.assert(group_id <= MAX_GROUP_ID);
    std.debug.assert(perms != null);
    return check_access(perms, user_id, group_id, AccessType.read);
}

// Check if user can write file.
pub fn can_write(
    perms: *const FilePermissions,
    user_id: u32,
    group_id: u32,
) bool {
    std.debug.assert(user_id <= MAX_USER_ID);
    std.debug.assert(group_id <= MAX_GROUP_ID);
    std.debug.assert(perms != null);
    return check_access(perms, user_id, group_id, AccessType.write);
}

// Check if user can execute file.
pub fn can_execute(
    perms: *const FilePermissions,
    user_id: u32,
    group_id: u32,
) bool {
    std.debug.assert(user_id <= MAX_USER_ID);
    std.debug.assert(group_id <= MAX_GROUP_ID);
    std.debug.assert(perms != null);
    return check_access(perms, user_id, group_id, AccessType.execute);
}

// Permission manager: manages file permissions.
pub const PermissionManager = struct {
    default_permissions: PermissionBits,

    pub fn init() PermissionManager {
        const manager = PermissionManager{
            .default_permissions = PermissionBits.from_octal(0o644),
        };
        return manager;
    }

    pub fn create_file_permissions(
        self: *const PermissionManager,
        owner_id: u32,
        group_id: u32,
    ) FilePermissions {
        std.debug.assert(owner_id <= MAX_USER_ID);
        std.debug.assert(group_id <= MAX_GROUP_ID);
        std.debug.assert(self != null);
        var perms = FilePermissions.init(owner_id, group_id);
        perms.permissions = self.default_permissions;
        return perms;
    }

    pub fn create_directory_permissions(
        self: *const PermissionManager,
        owner_id: u32,
        group_id: u32,
    ) FilePermissions {
        std.debug.assert(owner_id <= MAX_USER_ID);
        std.debug.assert(group_id <= MAX_GROUP_ID);
        std.debug.assert(self != null);
        var perms = FilePermissions.init(owner_id, group_id);
        perms.permissions = PermissionBits.from_octal(0o755);
        return perms;
    }
};
