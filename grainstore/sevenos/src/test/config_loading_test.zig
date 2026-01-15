//! configuration loading integration tests
//!
//! tests for service configuration loading, validation, and dependency graph building
//!
//! **grain style principles applied:**
//! - explicit types (u32/u64)
//! - bounded operations
//! - clear error handling
//! - fail-fast on errors
//!
const std = @import("std");
const testing = std.testing;
const config_loader = @import("config_loader");
const dependency = @import("dependency");
const supervision = @import("supervision");

// test configuration loading from file
// grain style: explicit test, clear assertions
test "config loading - simple service config" {
    const allocator = testing.allocator;

    // create a temporary config file
    const config_content = "web-server:/usr/bin/nginx:/var/www:always:";
    
    // write config to a temporary file
    const tmp_file = "test_config.conf";
    const file = try std.fs.cwd().createFile(tmp_file, .{});
    defer std.fs.cwd().deleteFile(tmp_file) catch {};
    defer file.close();
    
    try file.writeAll(config_content);
    file.close();

    // load configuration
    const configs = try config_loader.load_service_configs(allocator, tmp_file);
    defer allocator.free(configs);

    // verify configuration was loaded
    try testing.expect(configs.len == 1);
    try testing.expect(std.mem.eql(u8, configs[0].name, "web-server"));
    try testing.expect(configs[0].command.len == 1);
    try testing.expect(std.mem.eql(u8, configs[0].command[0], "/usr/bin/nginx"));
    try testing.expect(std.mem.eql(u8, configs[0].working_dir, "/var/www"));
    try testing.expect(configs[0].restart_policy == .always);
}

// test configuration loading - multiple services
// grain style: explicit test, clear assertions
test "config loading - multiple services" {
    const allocator = testing.allocator;

    // create a temporary config file with multiple services
    const config_content =
        \\database:/usr/bin/postgresql:/var/lib/postgresql:always:
        \\web-server:/usr/bin/nginx:/var/www:always:database
        \\api-server:/usr/bin/node:/app:on_failure:database,web-server
    ;
    
    const tmp_file = "test_config_multi.conf";
    const file = try std.fs.cwd().createFile(tmp_file, .{});
    defer std.fs.cwd().deleteFile(tmp_file) catch {};
    defer file.close();
    
    try file.writeAll(config_content);
    file.close();

    // load configuration
    const configs = try config_loader.load_service_configs(allocator, tmp_file);
    defer allocator.free(configs);

    // verify all configurations were loaded
    try testing.expect(configs.len == 3);
    
    // verify database service
    try testing.expect(std.mem.eql(u8, configs[0].name, "database"));
    try testing.expect(configs[0].dependencies.len == 0);
    
    // verify web-server service
    try testing.expect(std.mem.eql(u8, configs[1].name, "web-server"));
    try testing.expect(configs[1].dependencies.len == 1);
    try testing.expect(std.mem.eql(u8, configs[1].dependencies[0], "database"));
    
    // verify api-server service
    try testing.expect(std.mem.eql(u8, configs[2].name, "api-server"));
    try testing.expect(configs[2].dependencies.len == 2);
    try testing.expect(std.mem.eql(u8, configs[2].dependencies[0], "database"));
    try testing.expect(std.mem.eql(u8, configs[2].dependencies[1], "web-server"));
    try testing.expect(configs[2].restart_policy == .on_failure);
}

// test configuration validation
// grain style: explicit test, clear error checking
test "config loading - validation errors" {
    const allocator = testing.allocator;

    // test duplicate service names
    const config_content_duplicate =
        \\service-a:/usr/bin/true:/:always:
        \\service-a:/usr/bin/false:/:always:
    ;
    
    const tmp_file = "test_config_duplicate.conf";
    const file = try std.fs.cwd().createFile(tmp_file, .{});
    defer std.fs.cwd().deleteFile(tmp_file) catch {};
    defer file.close();
    
    try file.writeAll(config_content_duplicate);
    file.close();

    // load configuration (should succeed)
    const configs = try config_loader.load_service_configs(allocator, tmp_file);
    defer allocator.free(configs);

    // validation should fail on duplicate names
    try testing.expectError(error.DuplicateServiceName, config_loader.validate_configs(configs));
}

// test dependency graph building
// grain style: explicit test, clear dependency verification
test "config loading - dependency graph" {
    const allocator = testing.allocator;

    // create configs with dependencies
    const config_content =
        \\service-a:/usr/bin/true:/:always:
        \\service-b:/usr/bin/true:/:always:service-a
        \\service-c:/usr/bin/true:/:always:service-a,service-b
    ;
    
    const tmp_file = "test_config_deps.conf";
    const file = try std.fs.cwd().createFile(tmp_file, .{});
    defer std.fs.cwd().deleteFile(tmp_file) catch {};
    defer file.close();
    
    try file.writeAll(config_content);
    file.close();

    // load configuration
    const configs = try config_loader.load_service_configs(allocator, tmp_file);
    defer allocator.free(configs);

    // build dependency graph
    var dep_graph = try dependency.DependencyGraph.init(allocator, configs);
    defer dep_graph.deinit();

    // verify no circular dependencies
    try testing.expect(dep_graph.detect_cycles() == null);

    // compute startup layers
    const startup_layers = try dep_graph.compute_startup_layers();
    defer {
        for (startup_layers) |*layer| layer.deinit(allocator);
        allocator.free(startup_layers);
    }

    // verify startup layers
    // layer 0: service-a (no dependencies)
    // layer 1: service-b (depends on service-a)
    // layer 2: service-c (depends on service-a and service-b)
    try testing.expect(startup_layers.len >= 2);
    try testing.expect(startup_layers[0].items.len == 1); // service-a
    try testing.expect(startup_layers[1].items.len == 1); // service-b
    try testing.expect(startup_layers[2].items.len == 1); // service-c
}

// test dependency graph - circular dependency detection
// grain style: explicit test, clear error verification
test "config loading - circular dependency detection" {
    const allocator = testing.allocator;

    // create configs with circular dependencies
    const config_content =
        \\service-a:/usr/bin/true:/:always:service-c
        \\service-b:/usr/bin/true:/:always:service-a
        \\service-c:/usr/bin/true:/:always:service-b
    ;
    
    const tmp_file = "test_config_circular.conf";
    const file = try std.fs.cwd().createFile(tmp_file, .{});
    defer std.fs.cwd().deleteFile(tmp_file) catch {};
    defer file.close();
    
    try file.writeAll(config_content);
    file.close();

    // load configuration
    const configs = try config_loader.load_service_configs(allocator, tmp_file);
    defer allocator.free(configs);

    // build dependency graph
    var dep_graph = try dependency.DependencyGraph.init(allocator, configs);
    defer dep_graph.deinit();

    // verify circular dependency is detected
    const cycle = dep_graph.detect_cycles();
    try testing.expect(cycle != null);
    defer allocator.free(cycle.?);
    
    // verify cycle contains the circular services
    try testing.expect(cycle.?.len >= 3); // should contain at least service-a, service-b, service-c
}

// test empty configuration file
// grain style: explicit test, clear edge case handling
test "config loading - empty file" {
    const allocator = testing.allocator;

    const tmp_file = "test_config_empty.conf";
    const file = try std.fs.cwd().createFile(tmp_file, .{});
    defer std.fs.cwd().deleteFile(tmp_file) catch {};
    defer file.close();

    // file is empty, no config to load
    file.close();

    // load configuration (should return empty array)
    const configs = try config_loader.load_service_configs(allocator, tmp_file);
    defer allocator.free(configs);

    try testing.expect(configs.len == 0);
}

// test configuration loading - restart policy parsing
// grain style: explicit test, clear policy verification
test "config loading - restart policies" {
    const allocator = testing.allocator;

    const config_content =
        \\service-always:/usr/bin/true:/:always:
        \\service-never:/usr/bin/true:/:never:
        \\service-on-failure:/usr/bin/true:/:on_failure:
        \\service-on-success:/usr/bin/true:/:on_success:
    ;
    
    const tmp_file = "test_config_policies.conf";
    const file = try std.fs.cwd().createFile(tmp_file, .{});
    defer std.fs.cwd().deleteFile(tmp_file) catch {};
    defer file.close();
    
    try file.writeAll(config_content);
    file.close();

    // load configuration
    const configs = try config_loader.load_service_configs(allocator, tmp_file);
    defer allocator.free(configs);

    try testing.expect(configs.len == 4);
    try testing.expect(configs[0].restart_policy == .always);
    try testing.expect(configs[1].restart_policy == .never);
    try testing.expect(configs[2].restart_policy == .on_failure);
    try testing.expect(configs[3].restart_policy == .on_success);
}

