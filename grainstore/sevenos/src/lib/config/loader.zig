//! config/loader: Service configuration loader for sevenos-init
//!
//! this module provides configuration loading and validation for
//! sevenos-init service definitions.
//!
//! **what is service configuration?**
//!
//! imagine you want to run a web server. you need to tell the init
//! system:
//! - what command to run ("/usr/bin/nginx")
//! - where to run it ("/var/www")
//! - what services must start first (database, network)
//! - how to handle crashes (restart always, or only on failure?)
//!
//! configuration files define all of this! the loader reads these
//! files, validates them, and converts them into ServiceConfig
//! structs that the supervision library can use.
//!
//! **grain style principles applied:**
//! - explicit validation (catch problems early)
//! - clear error messages (help users fix problems)
//! - bounded limits (max services, max dependencies)
//! - decomplected design (loading separate from validation)

const std = @import("std");
const supervision = @import("supervision");
const ServiceConfig = supervision.ServiceConfig;
const RestartPolicy = supervision.RestartPolicy;

// maximum configuration file size (1MB)
// grain style: explicit bounded limit prevents resource exhaustion
const MAX_CONFIG_FILE_SIZE: u64 = 1024 * 1024;

// maximum service name length (64 characters)
const MAX_SERVICE_NAME_LEN: u32 = 64;

// maximum command length (512 characters)
const MAX_COMMAND_LEN: u32 = 512;

// maximum working directory length (256 characters)
const MAX_WORKING_DIR_LEN: u32 = 256;

// maximum dependencies per service (16)
const MAX_DEPENDENCIES: u32 = 16;

// configuration error types
// grain style: explicit error types make error handling clear
pub const ConfigError = error{
    FileNotFound,
    FileTooLarge,
    InvalidFormat,
    InvalidServiceName,
    InvalidCommand,
    InvalidWorkingDir,
    InvalidRestartPolicy,
    TooManyDependencies,
    DuplicateService,
};

// parse service configuration from file
// grain style: explicit error handling, bounded operations
pub fn load_service_configs(
    allocator: std.mem.Allocator,
    file_path: []const u8,
) ![]ServiceConfig {
    // read file with size limit
    const file = try std.fs.cwd().openFile(file_path, .{});
    defer file.close();

    const stat = try file.stat();
    if (stat.size > MAX_CONFIG_FILE_SIZE) {
        return ConfigError.FileTooLarge;
    }

    const contents = try file.readToEndAlloc(
        allocator,
        MAX_CONFIG_FILE_SIZE,
    );
    defer allocator.free(contents);

    // parse configuration (simple format for now)
    return parse_config(allocator, contents);
}

// parse configuration from string
// grain style: decomplected - parsing separate from file I/O
fn parse_config(
    allocator: std.mem.Allocator,
    contents: []const u8,
) ![]ServiceConfig {
    // simple format: one service per line
    // format: name:command:working_dir:restart_policy:deps
    // example: web:/usr/bin/nginx:/var/www:always:db,network
    //
    // for now, using a simple format. future: TOML/JSON support

    var services = std.ArrayListUnmanaged(ServiceConfig){};
    errdefer services.deinit(allocator);

    var lines = std.mem.splitScalar(u8, contents, '\n');
    while (lines.next()) |line| {
        const trimmed = std.mem.trim(u8, line, " \t\r");
        if (trimmed.len == 0 or trimmed[0] == '#') {
            continue; // skip empty lines and comments
        }

        const config = try parse_service_line(allocator, trimmed);
        try services.append(allocator, config);
    }

    return try services.toOwnedSlice(allocator);
}

// parse a single service configuration line
// grain style: explicit validation, bounded operations
fn parse_service_line(
    allocator: std.mem.Allocator,
    line: []const u8,
) !ServiceConfig {
    var fields = std.mem.splitScalar(u8, line, ':');

    // name (required)
    const name_str = fields.next() orelse {
        return ConfigError.InvalidFormat;
    };
    const name = try allocator.dupe(u8, name_str);
    if (name.len == 0 or name.len > MAX_SERVICE_NAME_LEN) {
        return ConfigError.InvalidServiceName;
    }

    // command (required)
    const cmd_str = fields.next() orelse {
        return ConfigError.InvalidFormat;
    };
    const command = try parse_command(allocator, cmd_str);
    if (command.len == 0) {
        return ConfigError.InvalidCommand;
    }

    // working_dir (optional, default: "/")
    const work_dir_str = fields.next() orelse "/";
    const working_dir = try allocator.dupe(u8, work_dir_str);
    if (working_dir.len > MAX_WORKING_DIR_LEN) {
        return ConfigError.InvalidWorkingDir;
    }

    // restart_policy (optional, default: "always")
    const policy_str = fields.next() orelse "always";
    const restart_policy = try parse_restart_policy(policy_str);

    // dependencies (optional)
    const deps_str = fields.next() orelse "";
    const dependencies = try parse_dependencies(allocator, deps_str);

    return ServiceConfig{
        .name = name,
        .command = command,
        .working_dir = working_dir,
        .restart_policy = restart_policy,
        .dependencies = dependencies,
    };
}

// parse command string into command array
// grain style: explicit validation, bounded operations
fn parse_command(
    allocator: std.mem.Allocator,
    cmd_str: []const u8,
) ![]const []const u8 {
    if (cmd_str.len == 0 or cmd_str.len > MAX_COMMAND_LEN) {
        return ConfigError.InvalidCommand;
    }

    var parts = std.ArrayListUnmanaged([]const u8){};
    errdefer parts.deinit(allocator);

    var iter = std.mem.splitScalar(u8, cmd_str, ' ');
    while (iter.next()) |part| {
        const trimmed = std.mem.trim(u8, part, " \t");
        if (trimmed.len > 0) {
            const duped = try allocator.dupe(u8, trimmed);
            try parts.append(allocator, duped);
        }
    }

    if (parts.items.len == 0) {
        return ConfigError.InvalidCommand;
    }

    return try parts.toOwnedSlice(allocator);
}

// parse restart policy string
// grain style: explicit validation, clear error messages
fn parse_restart_policy(policy_str: []const u8) !RestartPolicy {
    const trimmed = std.mem.trim(u8, policy_str, " \t");
    if (std.mem.eql(u8, trimmed, "always")) {
        return RestartPolicy.always;
    } else if (std.mem.eql(u8, trimmed, "never")) {
        return RestartPolicy.never;
    } else if (std.mem.eql(u8, trimmed, "on_failure")) {
        return RestartPolicy.on_failure;
    } else if (std.mem.eql(u8, trimmed, "on_success")) {
        return RestartPolicy.on_success;
    } else {
        return ConfigError.InvalidRestartPolicy;
    }
}

// parse dependencies string
// grain style: explicit validation, bounded operations
fn parse_dependencies(
    allocator: std.mem.Allocator,
    deps_str: []const u8,
) ![]const []const u8 {
    if (deps_str.len == 0) {
        return &.{};
    }

    var deps = std.ArrayListUnmanaged([]const u8){};
    errdefer deps.deinit(allocator);

    var iter = std.mem.splitScalar(u8, deps_str, ',');
    var count: u32 = 0;
    while (iter.next()) |dep| {
        if (count >= MAX_DEPENDENCIES) {
            return ConfigError.TooManyDependencies;
        }

        const trimmed = std.mem.trim(u8, dep, " \t");
        if (trimmed.len > 0) {
            const duped = try allocator.dupe(u8, trimmed);
            try deps.append(allocator, duped);
            count += 1;
        }
    }

    return try deps.toOwnedSlice(allocator);
}

// validate service configurations
// grain style: explicit validation, helpful error messages
pub fn validate_configs(configs: []const ServiceConfig) !void {
    // check for duplicate service names
    var seen = std.StringHashMap(void).init(std.heap.page_allocator);
    defer seen.deinit();

    for (configs) |config| {
        if (seen.contains(config.name)) {
            return ConfigError.DuplicateService;
        }
        try seen.put(config.name, {});
        try config.validate();
    }
}

// tests
test "parse restart policy - valid policies" {
    const testing = std.testing;

    try testing.expect(
        try parse_restart_policy("always") == RestartPolicy.always,
    );
    try testing.expect(
        try parse_restart_policy("never") == RestartPolicy.never,
    );
    try testing.expect(
        try parse_restart_policy("on_failure") ==
            RestartPolicy.on_failure,
    );
    try testing.expect(
        try parse_restart_policy("on_success") ==
            RestartPolicy.on_success,
    );
}

test "parse restart policy - invalid policy" {
    const testing = std.testing;

    try testing.expectError(
        ConfigError.InvalidRestartPolicy,
        parse_restart_policy("invalid"),
    );
}

test "parse restart policy - whitespace trimming" {
    const testing = std.testing;

    try testing.expect(
        try parse_restart_policy("  always  ") == RestartPolicy.always,
    );
}

test "parse command - simple command" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const cmd = try parse_command(allocator, "/usr/bin/nginx");
    defer allocator.free(cmd);
    defer for (cmd) |part| allocator.free(part);

    try testing.expect(cmd.len == 1);
    try testing.expectEqualStrings("/usr/bin/nginx", cmd[0]);
}

test "parse command - command with arguments" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const cmd = try parse_command(
        allocator,
        "/usr/bin/nginx -g daemon off",
    );
    defer allocator.free(cmd);
    defer for (cmd) |part| allocator.free(part);

    try testing.expect(cmd.len == 3);
    try testing.expectEqualStrings("/usr/bin/nginx", cmd[0]);
    try testing.expectEqualStrings("-g", cmd[1]);
    try testing.expectEqualStrings("daemon", cmd[2]);
}

test "parse command - empty command" {
    const testing = std.testing;
    const allocator = testing.allocator;

    try testing.expectError(
        ConfigError.InvalidCommand,
        parse_command(allocator, ""),
    );
}

test "parse dependencies - empty string" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const deps = try parse_dependencies(allocator, "");
    defer allocator.free(deps);

    try testing.expect(deps.len == 0);
}

test "parse dependencies - single dependency" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const deps = try parse_dependencies(allocator, "db");
    defer allocator.free(deps);
    defer for (deps) |dep| allocator.free(dep);

    try testing.expect(deps.len == 1);
    try testing.expectEqualStrings("db", deps[0]);
}

test "parse dependencies - multiple dependencies" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const deps = try parse_dependencies(allocator, "db,network,storage");
    defer allocator.free(deps);
    defer for (deps) |dep| allocator.free(dep);

    try testing.expect(deps.len == 3);
    try testing.expectEqualStrings("db", deps[0]);
    try testing.expectEqualStrings("network", deps[1]);
    try testing.expectEqualStrings("storage", deps[2]);
}

test "parse dependencies - whitespace trimming" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const deps = try parse_dependencies(
        allocator,
        " db , network , storage ",
    );
    defer allocator.free(deps);
    defer for (deps) |dep| allocator.free(dep);

    try testing.expect(deps.len == 3);
    try testing.expectEqualStrings("db", deps[0]);
    try testing.expectEqualStrings("network", deps[1]);
    try testing.expectEqualStrings("storage", deps[2]);
}

test "parse service line - minimal config" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const config = try parse_service_line(allocator, "test:/bin/true");
    defer {
        allocator.free(config.name);
        allocator.free(config.command[0]);
        allocator.free(config.command);
        allocator.free(config.working_dir);
        allocator.free(config.dependencies);
    }

    try testing.expectEqualStrings("test", config.name);
    try testing.expectEqualStrings("/bin/true", config.command[0]);
    try testing.expectEqualStrings("/", config.working_dir);
    try testing.expect(config.restart_policy == RestartPolicy.always);
    try testing.expect(config.dependencies.len == 0);
}

test "parse service line - full config" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const config = try parse_service_line(
        allocator,
        "web:/usr/bin/nginx:/var/www:on_failure:db,network",
    );
    defer {
        allocator.free(config.name);
        for (config.command) |part| allocator.free(part);
        allocator.free(config.command);
        allocator.free(config.working_dir);
        for (config.dependencies) |dep| allocator.free(dep);
        allocator.free(config.dependencies);
    }

    try testing.expectEqualStrings("web", config.name);
    try testing.expectEqualStrings("/usr/bin/nginx", config.command[0]);
    try testing.expectEqualStrings("/var/www", config.working_dir);
    try testing.expect(config.restart_policy == RestartPolicy.on_failure);
    try testing.expect(config.dependencies.len == 2);
    try testing.expectEqualStrings("db", config.dependencies[0]);
    try testing.expectEqualStrings("network", config.dependencies[1]);
}

test "validate configs - duplicate service names" {
    const testing = std.testing;
    const allocator = testing.allocator;

    const config1 = try parse_service_line(allocator, "test:/bin/true");
    defer {
        allocator.free(config1.name);
        for (config1.command) |part| allocator.free(part);
        allocator.free(config1.command);
        allocator.free(config1.working_dir);
        for (config1.dependencies) |dep| allocator.free(dep);
        allocator.free(config1.dependencies);
    }

    const config2 = try parse_service_line(allocator, "test:/bin/false");
    defer {
        allocator.free(config2.name);
        for (config2.command) |part| allocator.free(part);
        allocator.free(config2.command);
        allocator.free(config2.working_dir);
        for (config2.dependencies) |dep| allocator.free(dep);
        allocator.free(config2.dependencies);
    }

    var configs = [_]ServiceConfig{ config1, config2 };

    try testing.expectError(
        ConfigError.DuplicateService,
        validate_configs(&configs),
    );
}

