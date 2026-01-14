const std = @import("std");
const testing = std.testing;
const access_control = @import("grain_core").access_control;
const file_permissions = @import("grain_core").file_permissions;

test "access control entry init" {
    const entry = access_control.AccessControlEntry.init();
    std.debug.assert(entry.user_id == 0);
    std.debug.assert(entry.group_id == 0);
    std.debug.assert(entry.role_type == access_control.RoleType.user);
    std.debug.assert(entry.ace_type == access_control.AceType.allow);
    std.debug.assert(entry.active == false);
}

test "access control list init" {
    const acl = access_control.AccessControlList.init();
    std.debug.assert(acl.entries_len == 0);
}

test "access control list add entry" {
    var acl = access_control.AccessControlList.init();
    const permissions = file_permissions.PermissionBits.from_octal(0o644);
    const added = acl.add_entry(
        1000,
        100,
        access_control.RoleType.user,
        access_control.AceType.allow,
        permissions,
    );
    std.debug.assert(added);
    std.debug.assert(acl.entries_len == 1);
    std.debug.assert(acl.entries[0].user_id == 1000);
    std.debug.assert(acl.entries[0].active == true);
}

test "access control list remove entry" {
    var acl = access_control.AccessControlList.init();
    const permissions = file_permissions.PermissionBits.from_octal(0o644);
    _ = acl.add_entry(
        1000,
        100,
        access_control.RoleType.user,
        access_control.AceType.allow,
        permissions,
    );
    std.debug.assert(acl.entries_len == 1);
    const removed = acl.remove_entry(0);
    std.debug.assert(removed);
    std.debug.assert(acl.entries_len == 0);
}

test "check acl access - allow" {
    var acl = access_control.AccessControlList.init();
    var permissions = file_permissions.PermissionBits.from_octal(0o644);
    permissions.owner_read = true;
    _ = acl.add_entry(
        1000,
        100,
        access_control.RoleType.user,
        access_control.AceType.allow,
        permissions,
    );
    const has_access = access_control.check_acl_access(
        &acl,
        1000,
        100,
        file_permissions.AccessType.read,
    );
    std.debug.assert(has_access);
}

test "check acl access - deny" {
    var acl = access_control.AccessControlList.init();
    var permissions = file_permissions.PermissionBits.from_octal(0o644);
    permissions.owner_read = true;
    _ = acl.add_entry(
        1000,
        100,
        access_control.RoleType.user,
        access_control.AceType.deny,
        permissions,
    );
    const has_access = access_control.check_acl_access(
        &acl,
        1000,
        100,
        file_permissions.AccessType.read,
    );
    std.debug.assert(!has_access);
}

test "role init" {
    const role = access_control.Role.init();
    std.debug.assert(role.role_id == 0);
    std.debug.assert(role.name_len == 0);
    std.debug.assert(role.users_len == 0);
    std.debug.assert(role.active == false);
}

test "role set name" {
    var role = access_control.Role.init();
    const name = "admin";
    const set = role.set_name(name);
    std.debug.assert(set);
    std.debug.assert(role.name_len == name.len);
}

test "role add user" {
    var role = access_control.Role.init();
    const user_id: u32 = 1000;
    const added = role.add_user(user_id);
    std.debug.assert(added);
    std.debug.assert(role.users_len == 1);
    std.debug.assert(role.users[0] == user_id);
}

test "rbac manager init" {
    const manager = access_control.RbacManager.init();
    std.debug.assert(manager.roles_len == 0);
    std.debug.assert(manager.next_role_id == 1);
}

test "rbac manager create role" {
    var manager = access_control.RbacManager.init();
    const name = "admin";
    const permissions = file_permissions.PermissionBits.from_octal(0o755);
    const role_id = manager.create_role(
        name,
        access_control.RoleType.admin,
        permissions,
    );
    std.debug.assert(role_id != null);
    std.debug.assert(manager.roles_len == 1);
    std.debug.assert(manager.roles[0].role_id == role_id.?);
}

test "rbac manager get role" {
    var manager = access_control.RbacManager.init();
    const name = "admin";
    const permissions = file_permissions.PermissionBits.from_octal(0o755);
    const role_id = manager.create_role(
        name,
        access_control.RoleType.admin,
        permissions,
    );
    std.debug.assert(role_id != null);
    const role = manager.get_role(role_id.?);
    std.debug.assert(role != null);
    std.debug.assert(role.?.role_id == role_id.?);
}

test "rbac manager check role access" {
    var manager = access_control.RbacManager.init();
    var permissions = file_permissions.PermissionBits.from_octal(0o755);
    permissions.owner_read = true;
    permissions.owner_write = true;
    const role_id = manager.create_role(
        "admin",
        access_control.RoleType.admin,
        permissions,
    );
    std.debug.assert(role_id != null);
    const role = manager.get_role(role_id.?);
    std.debug.assert(role != null);
    _ = role.?.add_user(1000);
    const has_read = manager.check_role_access(
        1000,
        access_control.RoleType.admin,
        file_permissions.AccessType.read,
    );
    std.debug.assert(has_read);
}

test "access control list multiple entries" {
    var acl = access_control.AccessControlList.init();
    var permissions1 = file_permissions.PermissionBits.from_octal(0o644);
    permissions1.owner_read = true;
    _ = acl.add_entry(
        1000,
        100,
        access_control.RoleType.user,
        access_control.AceType.allow,
        permissions1,
    );
    var permissions2 = file_permissions.PermissionBits.from_octal(0o644);
    permissions2.group_read = true;
    _ = acl.add_entry(
        2000,
        100,
        access_control.RoleType.user,
        access_control.AceType.allow,
        permissions2,
    );
    std.debug.assert(acl.entries_len == 2);
    const has_access1 = access_control.check_acl_access(
        &acl,
        1000,
        100,
        file_permissions.AccessType.read,
    );
    std.debug.assert(has_access1);
    const has_access2 = access_control.check_acl_access(
        &acl,
        2000,
        100,
        file_permissions.AccessType.read,
    );
    std.debug.assert(has_access2);
}
