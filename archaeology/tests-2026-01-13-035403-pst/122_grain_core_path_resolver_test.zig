const std = @import("std");
const testing = std.testing;
const path_resolver = @import("grain_core").path_resolver;

test "is absolute path - root" {
    const path = "/";
    const is_abs = path_resolver.is_absolute_path(path);
    std.debug.assert(is_abs);
}

test "is absolute path - absolute" {
    const path = "/home/user/file.txt";
    const is_abs = path_resolver.is_absolute_path(path);
    std.debug.assert(is_abs);
}

test "is absolute path - relative" {
    const path = "file.txt";
    const is_abs = path_resolver.is_absolute_path(path);
    std.debug.assert(!is_abs);
}

test "is absolute path - relative with dot" {
    const path = "./file.txt";
    const is_abs = path_resolver.is_absolute_path(path);
    std.debug.assert(!is_abs);
}

test "normalize path - simple" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "/home/user/file.txt";
    const normalized = path_resolver.normalize_path(path, &result);
    std.debug.assert(normalized);
    std.debug.assert(result.is_valid);
    std.debug.assert(result.is_absolute);
    std.debug.assert(result.resolved_path_len > 0);
}

test "normalize path - remove redundant separators" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "/home//user///file.txt";
    const normalized = path_resolver.normalize_path(path, &result);
    std.debug.assert(normalized);
    std.debug.assert(result.is_valid);
    const resolved = result.resolved_path[0..result.resolved_path_len];
    std.debug.assert(std.mem.indexOf(u8, resolved, "//") == null);
}

test "normalize path - resolve dot" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "/home/./user/./file.txt";
    const normalized = path_resolver.normalize_path(path, &result);
    std.debug.assert(normalized);
    std.debug.assert(result.is_valid);
    const resolved = result.resolved_path[0..result.resolved_path_len];
    std.debug.assert(std.mem.indexOf(u8, resolved, "/./") == null);
}

test "normalize path - resolve dot dot" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "/home/user/../file.txt";
    const normalized = path_resolver.normalize_path(path, &result);
    std.debug.assert(normalized);
    std.debug.assert(result.is_valid);
    const resolved = result.resolved_path[0..result.resolved_path_len];
    std.debug.assert(std.mem.indexOf(u8, resolved, "/user/") == null);
}

test "normalize path - root" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "/";
    const normalized = path_resolver.normalize_path(path, &result);
    std.debug.assert(normalized);
    std.debug.assert(result.is_valid);
    std.debug.assert(result.is_absolute);
    std.debug.assert(result.resolved_path_len == 1);
    std.debug.assert(result.resolved_path[0] == '/');
}

test "normalize path - relative" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "file.txt";
    const normalized = path_resolver.normalize_path(path, &result);
    std.debug.assert(normalized);
    std.debug.assert(result.is_valid);
    std.debug.assert(!result.is_absolute);
}

test "normalize path - empty" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "";
    const normalized = path_resolver.normalize_path(path, &result);
    std.debug.assert(!normalized);
    std.debug.assert(!result.is_valid);
}

test "normalize path - too long" {
    var result = path_resolver.PathResolutionResult.init();
    var long_path: [600]u8 = undefined;
    var i: u32 = 0;
    while (i < 600) : (i += 1) {
        long_path[i] = 'a';
    }
    const normalized = path_resolver.normalize_path(&long_path, &result);
    std.debug.assert(!normalized);
    std.debug.assert(!result.is_valid);
}

test "resolve relative path - simple" {
    var result = path_resolver.PathResolutionResult.init();
    const base = "/home/user";
    const relative = "file.txt";
    const resolved = path_resolver.resolve_relative_path(
        base,
        relative,
        &result,
    );
    std.debug.assert(resolved);
    std.debug.assert(result.is_valid);
    std.debug.assert(result.is_absolute);
}

test "resolve relative path - absolute relative" {
    var result = path_resolver.PathResolutionResult.init();
    const base = "/home/user";
    const relative = "/tmp/file.txt";
    const resolved = path_resolver.resolve_relative_path(
        base,
        relative,
        &result,
    );
    std.debug.assert(resolved);
    std.debug.assert(result.is_valid);
    std.debug.assert(result.is_absolute);
    const resolved_path = result.resolved_path[0..result.resolved_path_len];
    std.debug.assert(std.mem.startsWith(u8, resolved_path, "/tmp"));
}

test "resolve relative path - with dot dot" {
    var result = path_resolver.PathResolutionResult.init();
    const base = "/home/user";
    const relative = "../other/file.txt";
    const resolved = path_resolver.resolve_relative_path(
        base,
        relative,
        &result,
    );
    std.debug.assert(resolved);
    std.debug.assert(result.is_valid);
    std.debug.assert(result.is_absolute);
}

test "validate path - valid" {
    const path = "/home/user/file.txt";
    const valid = path_resolver.validate_path(path);
    std.debug.assert(valid);
}

test "validate path - root" {
    const path = "/";
    const valid = path_resolver.validate_path(path);
    std.debug.assert(valid);
}

test "validate path - empty" {
    const path = "";
    const valid = path_resolver.validate_path(path);
    std.debug.assert(!valid);
}

test "validate path - too long" {
    var long_path: [600]u8 = undefined;
    var i: u32 = 0;
    while (i < 600) : (i += 1) {
        long_path[i] = 'a';
    }
    const valid = path_resolver.validate_path(&long_path);
    std.debug.assert(!valid);
}

test "validate path - null byte" {
    var path_with_null: [20]u8 = undefined;
    path_with_null[0] = '/';
    path_with_null[1] = 'h';
    path_with_null[2] = 'o';
    path_with_null[3] = 'm';
    path_with_null[4] = 'e';
    path_with_null[5] = 0;
    path_with_null[6] = 'f';
    const valid = path_resolver.validate_path(path_with_null[0..7]);
    std.debug.assert(!valid);
}

test "sanitize path - valid" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "/home/user/file.txt";
    const sanitized = path_resolver.sanitize_path(path, &result);
    std.debug.assert(sanitized);
    std.debug.assert(result.is_valid);
}

test "sanitize path - with normalization" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "/home//user/./file.txt";
    const sanitized = path_resolver.sanitize_path(path, &result);
    std.debug.assert(sanitized);
    std.debug.assert(result.is_valid);
    const resolved = result.resolved_path[0..result.resolved_path_len];
    std.debug.assert(std.mem.indexOf(u8, resolved, "//") == null);
    std.debug.assert(std.mem.indexOf(u8, resolved, "/./") == null);
}

test "sanitize path - invalid" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "";
    const sanitized = path_resolver.sanitize_path(path, &result);
    std.debug.assert(!sanitized);
    std.debug.assert(!result.is_valid);
}

test "normalize path - complex dot dot" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "/home/user/../other/../file.txt";
    const normalized = path_resolver.normalize_path(path, &result);
    std.debug.assert(normalized);
    std.debug.assert(result.is_valid);
    const resolved = result.resolved_path[0..result.resolved_path_len];
    std.debug.assert(std.mem.eql(u8, resolved, "/home/file.txt"));
}

test "normalize path - trailing slash" {
    var result = path_resolver.PathResolutionResult.init();
    const path = "/home/user/";
    const normalized = path_resolver.normalize_path(path, &result);
    std.debug.assert(normalized);
    std.debug.assert(result.is_valid);
    std.debug.assert(result.is_absolute);
}
