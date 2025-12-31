//! Grain Core Access Control: Enhanced access control (RBAC, ACLs).
//!
//! Why: Provide role-based access control and access control lists for files.
//! Architecture: RBAC with roles, ACLs for fine-grained control.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");
const file_permissions = @import("file_permissions.zig");

// Bounded: Max roles.
pub const MAX_ROLES: u32 = 32;

// Bounded: Max role name length.
pub const MAX_ROLE_NAME_LEN: u32 = 64;

// Bounded: Max ACL entries per file.
pub const MAX_ACL_ENTRIES: u32 = 16;

// Bounded: Max users per role.
pub const MAX_USERS_PER_ROLE: u32 = 64;

// Role type.
pub const RoleType = enum(u8) {
    guest,
    user,
    admin,
    custom,
};

// Access control entry type.
pub const AceType = enum(u8) {
    allow,
    deny,
};

// Access control entry.
pub const AccessControlEntry = struct {
    user_id: u32,
    group_id: u32,
    role_type: RoleType,
    ace_type: AceType,
    permissions: file_permissions.PermissionBits,
    active: bool,

    pub fn init() AccessControlEntry {
        return AccessControlEntry{
            .user_id = 0,
            .group_id = 0,
            .role_type = RoleType.user,
            .ace_type = AceType.allow,
            .permissions = file_permissions.PermissionBits.init(),
            .active = false,
        };
    }
};

// Access control list.
pub const AccessControlList = struct {
    entries: [MAX_ACL_ENTRIES]AccessControlEntry,
    entries_len: u32,

    pub fn init() AccessControlList {
        var acl = AccessControlList{
            .entries = undefined,
            .entries_len = 0,
        };
        var i: u32 = 0;
        while (i < MAX_ACL_ENTRIES) : (i += 1) {
            acl.entries[i] = AccessControlEntry.init();
        }
        return acl;
    }

    pub fn add_entry(
        self: *AccessControlList,
        user_id: u32,
        group_id: u32,
        role_type: RoleType,
        ace_type: AceType,
        permissions: file_permissions.PermissionBits,
    ) bool {
        std.debug.assert(user_id > 0);
        std.debug.assert(self != null);
        if (self.entries_len >= MAX_ACL_ENTRIES) {
            return false;
        }
        self.entries[self.entries_len] = AccessControlEntry.init();
        self.entries[self.entries_len].user_id = user_id;
        self.entries[self.entries_len].group_id = group_id;
        self.entries[self.entries_len].role_type = role_type;
        self.entries[self.entries_len].ace_type = ace_type;
        self.entries[self.entries_len].permissions = permissions;
        self.entries[self.entries_len].active = true;
        self.entries_len += 1;
        std.debug.assert(self.entries_len <= MAX_ACL_ENTRIES);
        return true;
    }

    pub fn remove_entry(self: *AccessControlList, index: u32) bool {
        std.debug.assert(self != null);
        if (index >= self.entries_len) {
            return false;
        }
        self.entries[index].active = false;
        var i: u32 = index;
        while (i < self.entries_len - 1) : (i += 1) {
            self.entries[i] = self.entries[i + 1];
        }
        self.entries_len -= 1;
        return true;
    }
};

// Role definition.
pub const Role = struct {
    role_id: u32,
    name: [MAX_ROLE_NAME_LEN]u8,
    name_len: u32,
    role_type: RoleType,
    permissions: file_permissions.PermissionBits,
    users: [MAX_USERS_PER_ROLE]u32,
    users_len: u32,
    active: bool,

    pub fn init() Role {
        var role = Role{
            .role_id = 0,
            .name = undefined,
            .name_len = 0,
            .role_type = RoleType.user,
            .permissions = file_permissions.PermissionBits.init(),
            .users = undefined,
            .users_len = 0,
            .active = false,
        };
        var i: u32 = 0;
        while (i < MAX_ROLE_NAME_LEN) : (i += 1) {
            role.name[i] = 0;
        }
        i = 0;
        while (i < MAX_USERS_PER_ROLE) : (i += 1) {
            role.users[i] = 0;
        }
        return role;
    }

    pub fn set_name(self: *Role, name: []const u8) bool {
        std.debug.assert(name.len > 0);
        std.debug.assert(name.len <= MAX_ROLE_NAME_LEN);
        if (name.len == 0 or name.len > MAX_ROLE_NAME_LEN) {
            return false;
        }
        var i: u32 = 0;
        while (i < MAX_ROLE_NAME_LEN) : (i += 1) {
            self.name[i] = 0;
        }
        const name_len = @min(name.len, MAX_ROLE_NAME_LEN);
        i = 0;
        while (i < name_len) : (i += 1) {
            self.name[i] = name[i];
        }
        self.name_len = name_len;
        return true;
    }

    pub fn add_user(self: *Role, user_id: u32) bool {
        std.debug.assert(user_id > 0);
        std.debug.assert(self != null);
        if (self.users_len >= MAX_USERS_PER_ROLE) {
            return false;
        }
        self.users[self.users_len] = user_id;
        self.users_len += 1;
        std.debug.assert(self.users_len <= MAX_USERS_PER_ROLE);
        return true;
    }
};

// Check access using ACL.
pub fn check_acl_access(
    acl: *const AccessControlList,
    user_id: u32,
    group_id: u32,
    access_type: file_permissions.AccessType,
) bool {
    std.debug.assert(user_id > 0);
    std.debug.assert(acl != null);
    var allow_found: bool = false;
    var i: u32 = 0;
    while (i < acl.entries_len) : (i += 1) {
        if (!acl.entries[i].active) {
            continue;
        }
        const entry = &acl.entries[i];
        var matches: bool = false;
        if (entry.user_id == user_id) {
            matches = true;
        } else if (entry.group_id == group_id) {
            matches = true;
        }
        if (matches) {
            const has_access = switch (access_type) {
                .read => entry.permissions.owner_read or
                    entry.permissions.group_read or
                    entry.permissions.other_read,
                .write => entry.permissions.owner_write or
                    entry.permissions.group_write or
                    entry.permissions.other_write,
                .execute => entry.permissions.owner_execute or
                    entry.permissions.group_execute or
                    entry.permissions.other_execute,
            };
            if (entry.ace_type == AceType.deny and has_access) {
                return false;
            }
            if (entry.ace_type == AceType.allow and has_access) {
                allow_found = true;
            }
        }
    }
    return allow_found;
}

// Role-based access control manager.
pub const RbacManager = struct {
    roles: [MAX_ROLES]Role,
    roles_len: u32,
    next_role_id: u32,

    pub fn init() RbacManager {
        var manager = RbacManager{
            .roles = undefined,
            .roles_len = 0,
            .next_role_id = 1,
        };
        var i: u32 = 0;
        while (i < MAX_ROLES) : (i += 1) {
            manager.roles[i] = Role.init();
        }
        return manager;
    }

    pub fn create_role(
        self: *RbacManager,
        name: []const u8,
        role_type: RoleType,
        permissions: file_permissions.PermissionBits,
    ) ?u32 {
        std.debug.assert(name.len > 0);
        std.debug.assert(self != null);
        if (self.roles_len >= MAX_ROLES) {
            return null;
        }
        const role_id = self.next_role_id;
        self.next_role_id += 1;
        self.roles[self.roles_len] = Role.init();
        self.roles[self.roles_len].role_id = role_id;
        _ = self.roles[self.roles_len].set_name(name);
        self.roles[self.roles_len].role_type = role_type;
        self.roles[self.roles_len].permissions = permissions;
        self.roles[self.roles_len].active = true;
        self.roles_len += 1;
        std.debug.assert(self.roles_len <= MAX_ROLES);
        return role_id;
    }

    pub fn get_role(self: *RbacManager, role_id: u32) ?*Role {
        std.debug.assert(role_id > 0);
        std.debug.assert(self != null);
        var i: u32 = 0;
        while (i < self.roles_len) : (i += 1) {
            if (self.roles[i].role_id == role_id and self.roles[i].active) {
                return &self.roles[i];
            }
        }
        return null;
    }

    pub fn check_role_access(
        self: *const RbacManager,
        user_id: u32,
        role_type: RoleType,
        access_type: file_permissions.AccessType,
    ) bool {
        std.debug.assert(user_id > 0);
        std.debug.assert(self != null);
        var i: u32 = 0;
        while (i < self.roles_len) : (i += 1) {
            if (self.roles[i].active and
                self.roles[i].role_type == role_type)
            {
                var j: u32 = 0;
                while (j < self.roles[i].users_len) : (j += 1) {
                    if (self.roles[i].users[j] == user_id) {
                        return switch (access_type) {
                            .read => self.roles[i].permissions.owner_read or
                                self.roles[i].permissions.group_read or
                                self.roles[i].permissions.other_read,
                            .write => self.roles[i].permissions.owner_write or
                                self.roles[i].permissions.group_write or
                                self.roles[i].permissions.other_write,
                            .execute => self.roles[i].permissions.owner_execute or
                                self.roles[i].permissions.group_execute or
                                self.roles[i].permissions.other_execute,
                        };
                    }
                }
            }
        }
        return false;
    }
};
