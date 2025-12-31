//! Grain Core File Versioning: File version management.
//!
//! Why: Provide file versioning for tracking file history and restoration.
//! Architecture: Version metadata, history tracking, version restore.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");

// Bounded: Max versions per file.
pub const MAX_VERSIONS: u32 = 100;

// Bounded: Max version comment length.
pub const MAX_VERSION_COMMENT_LEN: u32 = 256;

// Bounded: Max file path length for version.
pub const MAX_VERSION_PATH_LEN: u32 = 512;

// Version state.
pub const VersionState = enum(u8) {
    current,
    archived,
    deleted,
};

// File version.
pub const FileVersion = struct {
    version_id: u32,
    file_path: [MAX_VERSION_PATH_LEN]u8,
    file_path_len: u32,
    version_number: u32,
    file_size: u64,
    checksum: [32]u8,
    created_at: u64,
    created_by: u32,
    comment: [MAX_VERSION_COMMENT_LEN]u8,
    comment_len: u32,
    state: VersionState,
    active: bool,

    pub fn init() FileVersion {
        var version = FileVersion{
            .version_id = 0,
            .file_path = undefined,
            .file_path_len = 0,
            .version_number = 0,
            .file_size = 0,
            .checksum = undefined,
            .created_at = 0,
            .created_by = 0,
            .comment = undefined,
            .comment_len = 0,
            .state = VersionState.current,
            .active = false,
        };
        var i: u32 = 0;
        while (i < MAX_VERSION_PATH_LEN) : (i += 1) {
            version.file_path[i] = 0;
        }
        i = 0;
        while (i < 32) : (i += 1) {
            version.checksum[i] = 0;
        }
        i = 0;
        while (i < MAX_VERSION_COMMENT_LEN) : (i += 1) {
            version.comment[i] = 0;
        }
        return version;
    }

    pub fn set_file_path(self: *FileVersion, path: []const u8) bool {
        std.debug.assert(path.len > 0);
        std.debug.assert(path.len <= MAX_VERSION_PATH_LEN);
        if (path.len == 0 or path.len > MAX_VERSION_PATH_LEN) {
            return false;
        }
        var i: u32 = 0;
        while (i < MAX_VERSION_PATH_LEN) : (i += 1) {
            self.file_path[i] = 0;
        }
        const path_len = @min(path.len, MAX_VERSION_PATH_LEN);
        i = 0;
        while (i < path_len) : (i += 1) {
            self.file_path[i] = path[i];
        }
        self.file_path_len = path_len;
        return true;
    }

    pub fn set_comment(self: *FileVersion, comment: []const u8) bool {
        std.debug.assert(comment.len <= MAX_VERSION_COMMENT_LEN);
        if (comment.len > MAX_VERSION_COMMENT_LEN) {
            return false;
        }
        var i: u32 = 0;
        while (i < MAX_VERSION_COMMENT_LEN) : (i += 1) {
            self.comment[i] = 0;
        }
        const comment_len = @min(comment.len, MAX_VERSION_COMMENT_LEN);
        i = 0;
        while (i < comment_len) : (i += 1) {
            self.comment[i] = comment[i];
        }
        self.comment_len = comment_len;
        return true;
    }
};

// Version manager: manages file versions.
pub const VersionManager = struct {
    versions: [MAX_VERSIONS]FileVersion,
    versions_len: u32,
    next_version_id: u32,

    pub fn init() VersionManager {
        var manager = VersionManager{
            .versions = undefined,
            .versions_len = 0,
            .next_version_id = 1,
        };
        var i: u32 = 0;
        while (i < MAX_VERSIONS) : (i += 1) {
            manager.versions[i] = FileVersion.init();
        }
        return manager;
    }

    pub fn create_version(
        self: *VersionManager,
        file_path: []const u8,
        file_size: u64,
        checksum: []const u8,
        created_at: u64,
        created_by: u32,
        comment: []const u8,
    ) ?u32 {
        std.debug.assert(file_path.len > 0);
        std.debug.assert(checksum.len == 32);
        std.debug.assert(created_by > 0);
        if (self.versions_len >= MAX_VERSIONS) {
            return null;
        }
        const version_id = self.next_version_id;
        self.next_version_id += 1;
        const version_number = self.versions_len + 1;
        self.versions[self.versions_len] = FileVersion.init();
        self.versions[self.versions_len].version_id = version_id;
        _ = self.versions[self.versions_len].set_file_path(file_path);
        self.versions[self.versions_len].version_number = version_number;
        self.versions[self.versions_len].file_size = file_size;
        var i: u32 = 0;
        while (i < 32) : (i += 1) {
            self.versions[self.versions_len].checksum[i] = checksum[i];
        }
        self.versions[self.versions_len].created_at = created_at;
        self.versions[self.versions_len].created_by = created_by;
        _ = self.versions[self.versions_len].set_comment(comment);
        self.versions[self.versions_len].state = VersionState.current;
        self.versions[self.versions_len].active = true;
        var j: u32 = 0;
        while (j < self.versions_len) : (j += 1) {
            if (self.versions[j].active) {
                self.versions[j].state = VersionState.archived;
            }
        }
        self.versions_len += 1;
        std.debug.assert(self.versions_len <= MAX_VERSIONS);
        return version_id;
    }

    pub fn get_version(
        self: *VersionManager,
        version_id: u32,
    ) ?*FileVersion {
        std.debug.assert(version_id > 0);
        var i: u32 = 0;
        while (i < self.versions_len) : (i += 1) {
            if (self.versions[i].version_id == version_id and
                self.versions[i].active)
            {
                return &self.versions[i];
            }
        }
        return null;
    }

    pub fn get_current_version(
        self: *VersionManager,
        file_path: []const u8,
    ) ?*FileVersion {
        std.debug.assert(file_path.len > 0);
        var i: u32 = self.versions_len;
        while (i > 0) : (i -= 1) {
            const idx = i - 1;
            if (self.versions[idx].active) {
                const path = self.versions[idx].file_path[0..
                    self.versions[idx].file_path_len];
                if (std.mem.eql(u8, path, file_path)) {
                    if (self.versions[idx].state == VersionState.current) {
                        return &self.versions[idx];
                    }
                }
            }
        }
        return null;
    }

    pub fn get_version_history(
        self: *VersionManager,
        file_path: []const u8,
        result: []*FileVersion,
    ) u32 {
        std.debug.assert(file_path.len > 0);
        std.debug.assert(result.len > 0);
        var count: u32 = 0;
        var i: u32 = 0;
        while (i < self.versions_len and count < result.len) : (i += 1) {
            if (self.versions[i].active) {
                const path = self.versions[i].file_path[0..
                    self.versions[i].file_path_len];
                if (std.mem.eql(u8, path, file_path)) {
                    result[count] = &self.versions[i];
                    count += 1;
                }
            }
        }
        return count;
    }

    pub fn delete_version(
        self: *VersionManager,
        version_id: u32,
    ) bool {
        std.debug.assert(version_id > 0);
        var i: u32 = 0;
        while (i < self.versions_len) : (i += 1) {
            if (self.versions[i].version_id == version_id) {
                self.versions[i].state = VersionState.deleted;
                self.versions[i].active = false;
                return true;
            }
        }
        return false;
    }
};
