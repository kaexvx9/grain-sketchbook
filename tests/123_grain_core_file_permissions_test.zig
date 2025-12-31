const std = @import("std");
const testing = std.testing;
const file_permissions = @import("grain_core").file_permissions;

test "permission bits init" {
    const bits = file_permissions.PermissionBits.init();
    std.debug.assert(!bits.owner_read);
    std.debug.assert(!bits.owner_write);
    std.debug.assert(!bits.owner_execute);
    std.debug.assert(!bits.group_read);
    std.debug.assert(!bits.group_write);
    std.debug.assert(!bits.group_execute);
    std.debug.assert(!bits.other_read);
    std.debug.assert(!bits.other_write);
    std.debug.assert(!bits.other_execute);
}

test "permission bits from octal - 644" {
    const bits = file_permissions.PermissionBits.from_octal(0o644);
    std.debug.assert(bits.owner_read);
    std.debug.assert(bits.owner_write);
    std.debug.assert(!bits.owner_execute);
    std.debug.assert(bits.group_read);
    std.debug.assert(!bits.group_write);
    std.debug.assert(!bits.group_execute);
    std.debug.assert(bits.other_read);
    std.debug.assert(!bits.other_write);
    std.debug.assert(!bits.other_execute);
}

test "permission bits from octal - 755" {
    const bits = file_permissions.PermissionBits.from_octal(0o755);
    std.debug.assert(bits.owner_read);
    std.debug.assert(bits.owner_write);
    std.debug.assert(bits.owner_execute);
    std.debug.assert(bits.group_read);
    std.debug.assert(!bits.group_write);
    std.debug.assert(bits.group_execute);
    std.debug.assert(bits.other_read);
    std.debug.assert(!bits.other_write);
    std.debug.assert(bits.other_execute);
}

test "permission bits to octal - 644" {
    var bits = file_permissions.PermissionBits.init();
    bits.owner_read = true;
    bits.owner_write = true;
    bits.group_read = true;
    bits.other_read = true;
    const octal = bits.to_octal();
    std.debug.assert(octal == 0o644);
}

test "permission bits to octal - 755" {
    var bits = file_permissions.PermissionBits.init();
    bits.owner_read = true;
    bits.owner_write = true;
    bits.owner_execute = true;
    bits.group_read = true;
    bits.group_execute = true;
    bits.other_read = true;
    bits.other_execute = true;
    const octal = bits.to_octal();
    std.debug.assert(octal == 0o755);
}

test "file permissions init" {
    const perms = file_permissions.FilePermissions.init(1000, 100);
    std.debug.assert(perms.owner_id == 1000);
    std.debug.assert(perms.group_id == 100);
}

test "file permissions from octal" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    std.debug.assert(perms.owner_id == 1000);
    std.debug.assert(perms.group_id == 100);
    std.debug.assert(perms.permissions.owner_read);
    std.debug.assert(perms.permissions.owner_write);
}

test "check access - owner read" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.check_access(&perms, 1000, 100, .read);
    std.debug.assert(can);
}

test "check access - owner write" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.check_access(&perms, 1000, 100, .write);
    std.debug.assert(can);
}

test "check access - owner execute denied" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.check_access(&perms, 1000, 100, .execute);
    std.debug.assert(!can);
}

test "check access - group read" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.check_access(&perms, 2000, 100, .read);
    std.debug.assert(can);
}

test "check access - group write denied" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.check_access(&perms, 2000, 100, .write);
    std.debug.assert(!can);
}

test "check access - other read" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.check_access(&perms, 3000, 200, .read);
    std.debug.assert(can);
}

test "check access - other write denied" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.check_access(&perms, 3000, 200, .write);
    std.debug.assert(!can);
}

test "can read - owner" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.can_read(&perms, 1000, 100);
    std.debug.assert(can);
}

test "can read - group" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.can_read(&perms, 2000, 100);
    std.debug.assert(can);
}

test "can read - other" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.can_read(&perms, 3000, 200);
    std.debug.assert(can);
}

test "can write - owner" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.can_write(&perms, 1000, 100);
    std.debug.assert(can);
}

test "can write - group denied" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.can_write(&perms, 2000, 100);
    std.debug.assert(!can);
}

test "can write - other denied" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.can_write(&perms, 3000, 200);
    std.debug.assert(!can);
}

test "can execute - owner denied" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o644);
    const can = file_permissions.can_execute(&perms, 1000, 100);
    std.debug.assert(!can);
}

test "can execute - allowed" {
    const perms = file_permissions.FilePermissions.from_octal(1000, 100, 0o755);
    const can = file_permissions.can_execute(&perms, 1000, 100);
    std.debug.assert(can);
}

test "permission manager init" {
    const manager = file_permissions.PermissionManager.init();
    std.debug.assert(manager.default_permissions.owner_read);
    std.debug.assert(manager.default_permissions.owner_write);
}

test "permission manager create file permissions" {
    const manager = file_permissions.PermissionManager.init();
    const perms = manager.create_file_permissions(1000, 100);
    std.debug.assert(perms.owner_id == 1000);
    std.debug.assert(perms.group_id == 100);
    std.debug.assert(perms.permissions.owner_read);
    std.debug.assert(perms.permissions.owner_write);
}

test "permission manager create directory permissions" {
    const manager = file_permissions.PermissionManager.init();
    const perms = manager.create_directory_permissions(1000, 100);
    std.debug.assert(perms.owner_id == 1000);
    std.debug.assert(perms.group_id == 100);
    std.debug.assert(perms.permissions.owner_read);
    std.debug.assert(perms.permissions.owner_write);
    std.debug.assert(perms.permissions.owner_execute);
    std.debug.assert(perms.permissions.group_read);
    std.debug.assert(perms.permissions.group_execute);
}

test "file permissions set permissions" {
    var perms = file_permissions.FilePermissions.init(1000, 100);
    perms.set_permissions(0o755);
    std.debug.assert(perms.permissions.owner_read);
    std.debug.assert(perms.permissions.owner_write);
    std.debug.assert(perms.permissions.owner_execute);
}

test "permission bits round trip" {
    const original = 0o755;
    const bits = file_permissions.PermissionBits.from_octal(original);
    const converted = bits.to_octal();
    std.debug.assert(converted == original);
}

test "permission bits setuid setgid sticky" {
    const bits = file_permissions.PermissionBits.from_octal(0o7777);
    std.debug.assert(bits.setuid);
    std.debug.assert(bits.setgid);
    std.debug.assert(bits.sticky);
}
