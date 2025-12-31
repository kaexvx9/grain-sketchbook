//! Grain Core Path Resolver: Path resolution and normalization.
//!
//! Why: Provide comprehensive path resolution and normalization for file
//! operations.
//! Architecture: Iterative path resolution, normalization, validation.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");
const file_manager = @import("file_manager.zig");

// Bounded: Max path length (matches file_manager.MAX_PATH_LEN).
pub const MAX_PATH_LEN: u32 = file_manager.MAX_PATH_LEN;

// Bounded: Max path components (for stack-based resolution).
pub const MAX_PATH_COMPONENTS: u32 = 64;

// Bounded: Max symlink resolution depth (prevent infinite loops).
pub const MAX_SYMLINK_DEPTH: u32 = 32;

// Path resolution result.
pub const PathResolutionResult = struct {
    resolved_path: [MAX_PATH_LEN]u8,
    resolved_path_len: u32,
    is_absolute: bool,
    is_valid: bool,

    pub fn init() PathResolutionResult {
        var result = PathResolutionResult{
            .resolved_path = undefined,
            .resolved_path_len = 0,
            .is_absolute = false,
            .is_valid = false,
        };
        var i: u32 = 0;
        while (i < MAX_PATH_LEN) : (i += 1) {
            result.resolved_path[i] = 0;
        }
        return result;
    }
};

// Check if path is absolute.
pub fn is_absolute_path(path: []const u8) bool {
    std.debug.assert(path.len > 0);
    std.debug.assert(path.len <= MAX_PATH_LEN);
    if (path.len == 0) {
        return false;
    }
    return path[0] == '/';
}

// Normalize path: remove redundant separators, resolve . and ..
pub fn normalize_path(
    path: []const u8,
    result: *PathResolutionResult,
) bool {
    std.debug.assert(path.len > 0);
    std.debug.assert(path.len <= MAX_PATH_LEN);
    std.debug.assert(result != null);
    if (path.len == 0 or path.len > MAX_PATH_LEN) {
        result.is_valid = false;
        return false;
    }
    var components: [MAX_PATH_COMPONENTS][]const u8 = undefined;
    var components_len: u32 = 0;
    var start: u32 = 0;
    var i: u32 = 0;
    const is_abs = is_absolute_path(path);
    while (i < path.len) : (i += 1) {
        if (path[i] == '/') {
            if (i > start) {
                if (components_len >= MAX_PATH_COMPONENTS) {
                    result.is_valid = false;
                    return false;
                }
                components[components_len] = path[start..i];
                components_len += 1;
            }
            start = i + 1;
        }
    }
    if (i > start) {
        if (components_len >= MAX_PATH_COMPONENTS) {
            result.is_valid = false;
            return false;
        }
        components[components_len] = path[start..i];
        components_len += 1;
    }
    var normalized: [MAX_PATH_COMPONENTS][]const u8 = undefined;
    var normalized_len: u32 = 0;
    i = 0;
    while (i < components_len) : (i += 1) {
        const comp = components[i];
        if (comp.len == 1 and comp[0] == '.') {
            continue;
        }
        if (comp.len == 2 and comp[0] == '.' and comp[1] == '.') {
            if (normalized_len > 0) {
                normalized_len -= 1;
            }
            continue;
        }
        if (normalized_len >= MAX_PATH_COMPONENTS) {
            result.is_valid = false;
            return false;
        }
        normalized[normalized_len] = comp;
        normalized_len += 1;
    }
    var output_len: u32 = 0;
    if (is_abs) {
        if (output_len >= MAX_PATH_LEN) {
            result.is_valid = false;
            return false;
        }
        result.resolved_path[output_len] = '/';
        output_len += 1;
    }
    i = 0;
    while (i < normalized_len) : (i += 1) {
        const comp = normalized[i];
        if (output_len + comp.len + 1 > MAX_PATH_LEN) {
            result.is_valid = false;
            return false;
        }
        var j: u32 = 0;
        while (j < comp.len) : (j += 1) {
            result.resolved_path[output_len] = comp[j];
            output_len += 1;
        }
        if (i < normalized_len - 1) {
            result.resolved_path[output_len] = '/';
            output_len += 1;
        }
    }
    result.resolved_path_len = output_len;
    result.is_absolute = is_abs;
    result.is_valid = true;
    std.debug.assert(result.resolved_path_len <= MAX_PATH_LEN);
    return true;
}

// Resolve relative path against base path.
pub fn resolve_relative_path(
    base_path: []const u8,
    relative_path: []const u8,
    result: *PathResolutionResult,
) bool {
    std.debug.assert(base_path.len > 0);
    std.debug.assert(base_path.len <= MAX_PATH_LEN);
    std.debug.assert(relative_path.len > 0);
    std.debug.assert(relative_path.len <= MAX_PATH_LEN);
    std.debug.assert(result != null);
    if (is_absolute_path(relative_path)) {
        return normalize_path(relative_path, result);
    }
    var combined: [MAX_PATH_LEN * 2]u8 = undefined;
    var combined_len: u32 = 0;
    var i: u32 = 0;
    while (i < base_path.len and combined_len < MAX_PATH_LEN * 2) : (i += 1) {
        combined[combined_len] = base_path[i];
        combined_len += 1;
    }
    if (combined_len > 0 and combined[combined_len - 1] != '/') {
        if (combined_len >= MAX_PATH_LEN * 2) {
            result.is_valid = false;
            return false;
        }
        combined[combined_len] = '/';
        combined_len += 1;
    }
    i = 0;
    while (i < relative_path.len and combined_len < MAX_PATH_LEN * 2) : (i += 1) {
        combined[combined_len] = relative_path[i];
        combined_len += 1;
    }
    if (combined_len > MAX_PATH_LEN) {
        result.is_valid = false;
        return false;
    }
    return normalize_path(combined[0..combined_len], result);
}

// Validate path: check for invalid characters and patterns.
pub fn validate_path(path: []const u8) bool {
    std.debug.assert(path.len > 0);
    std.debug.assert(path.len <= MAX_PATH_LEN);
    if (path.len == 0 or path.len > MAX_PATH_LEN) {
        return false;
    }
    if (path.len == 1 and path[0] == '/') {
        return true;
    }
    var i: u32 = 0;
    while (i < path.len) : (i += 1) {
        const ch = path[i];
        if (ch == 0) {
            return false;
        }
        if (ch < 32 and ch != '\t' and ch != '\n') {
            return false;
        }
    }
    var has_dot_dot: bool = false;
    i = 0;
    while (i + 1 < path.len) : (i += 1) {
        if (path[i] == '.' and path[i + 1] == '.' and
            (i + 2 >= path.len or path[i + 2] == '/'))
        {
            has_dot_dot = true;
            break;
        }
    }
    std.debug.assert(i <= path.len);
    return true;
}

// Sanitize path: remove dangerous patterns and normalize.
pub fn sanitize_path(
    path: []const u8,
    result: *PathResolutionResult,
) bool {
    std.debug.assert(path.len > 0);
    std.debug.assert(path.len <= MAX_PATH_LEN);
    std.debug.assert(result != null);
    if (!validate_path(path)) {
        result.is_valid = false;
        return false;
    }
    if (!normalize_path(path, result)) {
        result.is_valid = false;
        return false;
    }
    std.debug.assert(result.resolved_path_len <= MAX_PATH_LEN);
    return true;
}
