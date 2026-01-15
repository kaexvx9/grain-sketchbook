//! integration test helpers: utilities for testing shell ↔ init system integration
//!
//! this module provides integration test helpers for testing ServiceManager
//! with Supervisor instances, enabling end-to-end integration testing.
//!
//! **grain style principles applied:**
//! - explicit types (u32/u64)
//! - bounded operations
//! - clear error handling
//!
const std = @import("std");
const testing = std.testing;
const supervision = @import("supervision");

// integration test environment
// grain style: explicit setup/teardown, bounded resources
pub const IntegrationTestEnv = struct {
    supervisor: supervision.Supervisor,
    allocator: std.mem.Allocator,
    // track service allocations for cleanup
    // grain style: explicit resource tracking
    services: std.ArrayListUnmanaged(*supervision.Service),

    // initialize integration test environment
    // grain style: explicit initialization, fail-fast error handling
    pub fn init(allocator: std.mem.Allocator) !IntegrationTestEnv {
        const supervisor = supervision.Supervisor.init(allocator);
        const services = std.ArrayListUnmanaged(*supervision.Service){};

        return IntegrationTestEnv{
            .supervisor = supervisor,
            .allocator = allocator,
            .services = services,
        };
    }

    // cleanup integration test environment
    // grain style: explicit cleanup, resource management
    pub fn deinit(self: *IntegrationTestEnv) void {
        // stop all services before cleanup
        // grain style: ignore errors during cleanup (best effort)
        _ = self.supervisor.stop_all() catch {};
        self.supervisor.deinit();
        
        // free service allocations
        for (self.services.items) |service| {
            self.allocator.destroy(service);
        }
        self.services.deinit(self.allocator);
    }

    // add a test service to the supervisor
    // grain style: explicit service creation, clear API
    pub fn add_test_service(
        self: *IntegrationTestEnv,
        name: []const u8,
        command: []const u8,
    ) !*supervision.Service {
        const config = supervision.ServiceConfig{
            .name = name,
            .command = &.{command},
            .working_dir = "/",
            .restart_policy = .always,
        };

        const service = try self.allocator.create(supervision.Service);
        service.* = supervision.Service.init(config);

        try self.supervisor.add_service(service);
        try self.services.append(self.allocator, service);

        return service;
    }

    // add a test service with dependencies
    // grain style: explicit dependency specification
    pub fn add_test_service_with_deps(
        self: *IntegrationTestEnv,
        name: []const u8,
        command: []const u8,
        deps: []const []const u8,
    ) !*supervision.Service {
        const config = supervision.ServiceConfig{
            .name = name,
            .command = &.{command},
            .working_dir = "/",
            .restart_policy = .always,
            .dependencies = deps,
        };

        const service = try self.allocator.create(supervision.Service);
        service.* = supervision.Service.init(config);

        try self.supervisor.add_service(service);
        try self.services.append(self.allocator, service);

        return service;
    }

    // get supervisor reference (for ServiceManager)
    // grain style: explicit reference access
    pub fn get_supervisor(self: *IntegrationTestEnv) *supervision.Supervisor {
        return &self.supervisor;
    }
};

// integration test helper: create test environment with a simple service
// grain style: helper function for common test pattern
pub fn create_simple_test_env(
    allocator: std.mem.Allocator,
    service_name: []const u8,
) !IntegrationTestEnv {
    var env = try IntegrationTestEnv.init(allocator);
    errdefer env.deinit();

    _ = try env.add_test_service(service_name, "/usr/bin/true");

    return env;
}

// integration test helper: create test environment with service dependencies
// grain style: helper for dependency testing
pub fn create_dependency_test_env(
    allocator: std.mem.Allocator,
) !IntegrationTestEnv {
    var env = try IntegrationTestEnv.init(allocator);
    errdefer env.deinit();

    // create services: A and B independent, C depends on both
    _ = try env.add_test_service("service-a", "/usr/bin/true");
    _ = try env.add_test_service("service-b", "/usr/bin/true");
    _ = try env.add_test_service_with_deps(
        "service-c",
        "/usr/bin/true",
        &.{ "service-a", "service-b" },
    );

    return env;
}

// example integration test
test "integration test env - create simple test environment" {
    const allocator = testing.allocator;

    var env = try create_simple_test_env(allocator, "test-service");
    defer env.deinit();

    const supervisor = env.get_supervisor();
    try testing.expect(supervisor.services.count() == 1);
}

test "integration test env - service dependencies" {
    const allocator = testing.allocator;

    var env = try create_dependency_test_env(allocator);
    defer env.deinit();

    const supervisor = env.get_supervisor();
    try testing.expect(supervisor.services.count() == 3);
}

