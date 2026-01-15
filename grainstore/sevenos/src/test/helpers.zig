//! test helpers: common utilities for init system testing
//!
//! this module provides test helpers, fixtures, and utilities for testing
//! the sevenos init system components.
//!
//! **grain style principles applied:**
//! - explicit types (u32/u64)
//! - bounded operations
//! - clear error handling
//!
const std = @import("std");
const testing = std.testing;

// test service configurations
// grain style: reusable test fixtures prevent duplication

// create test config helper - placeholder for future use
// grain style: explicit function signature, clear intent
pub fn create_test_config(
    allocator: std.mem.Allocator,
    name: []const u8,
    command: []const u8,
) ![]const u8 {
    // create a minimal service config line for testing
    // format: name:command:working_dir:restart_policy:dependencies
    const config_line = try std.fmt.allocPrint(
        allocator,
        "{s}:{s}:/:always:",
        .{ name, command },
    );
    return config_line;
}

// create a simple test service config
pub fn create_simple_test_config(
    allocator: std.mem.Allocator,
    name: []const u8,
) ![]const u8 {
    // create a minimal service config line for testing
    // format: name:command:working_dir:restart_policy:dependencies
    const config_line = try std.fmt.allocPrint(
        allocator,
        "{s}:/usr/bin/true:/:always:",
        .{name},
    );
    return config_line;
}

// create a test service config with dependencies
pub fn create_test_config_with_deps(
    allocator: std.mem.Allocator,
    name: []const u8,
    deps: []const []const u8,
) ![]const u8 {
    // format: name:command:working_dir:restart_policy:dependencies
    var deps_str = std.ArrayList(u8).init(allocator);
    defer deps_str.deinit();

    for (deps, 0..) |dep, i| {
        if (i > 0) {
            try deps_str.writer().writeAll(",");
        }
        try deps_str.writer().writeAll(dep);
    }

    const config_line = try std.fmt.allocPrint(
        allocator,
        "{s}:/usr/bin/true:/:always:{s}",
        .{ name, deps_str.items },
    );
    return config_line;
}

// test helper to check service state
// note: service state type should be passed from calling test
// grain style: explicit types, avoid complex imports in helpers
pub fn expect_service_state_equal(
    actual_state: u32,
    expected_state: u32,
) !void {
    if (actual_state != expected_state) {
        std.debug.print(
            "expected service state {d}, got {d}\n",
            .{ expected_state, actual_state },
        );
        return error.TestExpectedEqual;
    }
}

// test helper to verify service config name
// grain style: simple verification, explicit string comparison
pub fn verify_config_name(
    actual_name: []const u8,
    expected_name: []const u8,
) !void {
    if (!std.mem.eql(u8, actual_name, expected_name)) {
        std.debug.print(
            "expected service name '{s}', got '{s}'\n",
            .{ expected_name, actual_name },
        );
        return error.TestExpectedEqual;
    }
}

