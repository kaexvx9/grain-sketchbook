const std = @import("std");
const testing = std.testing;
const file_versioning = @import("grain_core").file_versioning;

test "file version init" {
    const version = file_versioning.FileVersion.init();
    std.debug.assert(version.version_id == 0);
    std.debug.assert(version.version_number == 0);
    std.debug.assert(version.file_size == 0);
    std.debug.assert(version.file_path_len == 0);
    std.debug.assert(version.comment_len == 0);
    std.debug.assert(version.state == file_versioning.VersionState.current);
    std.debug.assert(version.active == false);
}

test "file version set file path" {
    var version = file_versioning.FileVersion.init();
    const path = "/home/user/file.txt";
    const set = version.set_file_path(path);
    std.debug.assert(set);
    std.debug.assert(version.file_path_len == path.len);
}

test "file version set comment" {
    var version = file_versioning.FileVersion.init();
    const comment = "Initial version";
    const set = version.set_comment(comment);
    std.debug.assert(set);
    std.debug.assert(version.comment_len == comment.len);
}

test "version manager init" {
    const manager = file_versioning.VersionManager.init();
    std.debug.assert(manager.versions_len == 0);
    std.debug.assert(manager.next_version_id == 1);
}

test "version manager create version" {
    var manager = file_versioning.VersionManager.init();
    const file_path = "/home/user/file.txt";
    const file_size: u64 = 1024;
    var checksum: [32]u8 = undefined;
    std.crypto.random.bytes(&checksum);
    const created_at: u64 = 1000;
    const created_by: u32 = 1000;
    const comment = "Initial version";
    const version_id = manager.create_version(
        file_path,
        file_size,
        &checksum,
        created_at,
        created_by,
        comment,
    );
    std.debug.assert(version_id != null);
    std.debug.assert(manager.versions_len == 1);
    std.debug.assert(manager.versions[0].version_id == version_id.?);
    std.debug.assert(manager.versions[0].version_number == 1);
    std.debug.assert(manager.versions[0].file_size == file_size);
    std.debug.assert(manager.versions[0].state ==
        file_versioning.VersionState.current);
}

test "version manager get version" {
    var manager = file_versioning.VersionManager.init();
    const file_path = "/home/user/file.txt";
    const file_size: u64 = 1024;
    var checksum: [32]u8 = undefined;
    std.crypto.random.bytes(&checksum);
    const created_at: u64 = 1000;
    const created_by: u32 = 1000;
    const comment = "Initial version";
    const version_id = manager.create_version(
        file_path,
        file_size,
        &checksum,
        created_at,
        created_by,
        comment,
    );
    std.debug.assert(version_id != null);
    const version = manager.get_version(version_id.?);
    std.debug.assert(version != null);
    std.debug.assert(version.?.version_id == version_id.?);
}

test "version manager get current version" {
    var manager = file_versioning.VersionManager.init();
    const file_path = "/home/user/file.txt";
    const file_size: u64 = 1024;
    var checksum: [32]u8 = undefined;
    std.crypto.random.bytes(&checksum);
    const created_at: u64 = 1000;
    const created_by: u32 = 1000;
    const comment = "Initial version";
    _ = manager.create_version(
        file_path,
        file_size,
        &checksum,
        created_at,
        created_by,
        comment,
    );
    const current = manager.get_current_version(file_path);
    std.debug.assert(current != null);
    std.debug.assert(current.?.state == file_versioning.VersionState.current);
}

test "version manager multiple versions" {
    var manager = file_versioning.VersionManager.init();
    const file_path = "/home/user/file.txt";
    var checksum: [32]u8 = undefined;
    std.crypto.random.bytes(&checksum);
    const created_by: u32 = 1000;
    _ = manager.create_version(
        file_path,
        1000,
        &checksum,
        1000,
        created_by,
        "Version 1",
    );
    std.crypto.random.bytes(&checksum);
    _ = manager.create_version(
        file_path,
        2000,
        &checksum,
        2000,
        created_by,
        "Version 2",
    );
    std.debug.assert(manager.versions_len == 2);
    const current = manager.get_current_version(file_path);
    std.debug.assert(current != null);
    std.debug.assert(current.?.version_number == 2);
    std.debug.assert(current.?.state == file_versioning.VersionState.current);
}

test "version manager get version history" {
    var manager = file_versioning.VersionManager.init();
    const file_path = "/home/user/file.txt";
    var checksum: [32]u8 = undefined;
    std.crypto.random.bytes(&checksum);
    const created_by: u32 = 1000;
    _ = manager.create_version(
        file_path,
        1000,
        &checksum,
        1000,
        created_by,
        "Version 1",
    );
    std.crypto.random.bytes(&checksum);
    _ = manager.create_version(
        file_path,
        2000,
        &checksum,
        2000,
        created_by,
        "Version 2",
    );
    var history: [10]*file_versioning.FileVersion = undefined;
    const count = manager.get_version_history(file_path, &history);
    std.debug.assert(count == 2);
}

test "version manager delete version" {
    var manager = file_versioning.VersionManager.init();
    const file_path = "/home/user/file.txt";
    var checksum: [32]u8 = undefined;
    std.crypto.random.bytes(&checksum);
    const created_by: u32 = 1000;
    const version_id = manager.create_version(
        file_path,
        1000,
        &checksum,
        1000,
        created_by,
        "Version 1",
    );
    std.debug.assert(version_id != null);
    const deleted = manager.delete_version(version_id.?);
    std.debug.assert(deleted);
    const version = manager.get_version(version_id.?);
    std.debug.assert(version == null);
}

test "version manager version state transitions" {
    var manager = file_versioning.VersionManager.init();
    const file_path = "/home/user/file.txt";
    var checksum: [32]u8 = undefined;
    std.crypto.random.bytes(&checksum);
    const created_by: u32 = 1000;
    const v1_id = manager.create_version(
        file_path,
        1000,
        &checksum,
        1000,
        created_by,
        "Version 1",
    );
    std.debug.assert(v1_id != null);
    const v1 = manager.get_version(v1_id.?);
    std.debug.assert(v1 != null);
    std.debug.assert(v1.?.state == file_versioning.VersionState.current);
    std.crypto.random.bytes(&checksum);
    _ = manager.create_version(
        file_path,
        2000,
        &checksum,
        2000,
        created_by,
        "Version 2",
    );
    const v1_updated = manager.get_version(v1_id.?);
    std.debug.assert(v1_updated != null);
    std.debug.assert(v1_updated.?.state ==
        file_versioning.VersionState.archived);
}
