//! Grainscript Shell Integration Tests
//! Why: Test pipes, redirections, background jobs, and job management.
//! Grain Style: Explicit error handling, bounded allocations.

const std = @import("std");
const testing = std.testing;
const parser = @import("parser.zig");
const executor = @import("executor.zig");
const builtins = @import("builtins.zig");
const job_manager = @import("job_manager.zig");

// TODO: Re-enable pipeline/redirection tests after fixing execution hang
// These tests are temporarily disabled because pipeline execution with real processes
// requires more complex pipe handling that needs further investigation.
//
// test "integration: pipe execution" {
//     // Test: echo hello | cat
//     // Would test pipeline execution with real processes
// }
//
// test "integration: input redirection" {
//     // Test: cat < file.txt
//     // Would test input redirection
// }
//
// test "integration: output redirection" {
//     // Test: echo hello > file.txt
//     // Would test output redirection
// }
//
// test "integration: append redirection" {
//     // Test: echo appended >> file.txt
//     // Would test append redirection
// }

test "integration: job manager add and list" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var job_mgr = job_manager.JobManager.init(allocator);
    defer job_mgr.deinit();

    // Add a job (using a fake PID for testing)
    const job_id = try job_mgr.add_job(12345, "test command");
    try testing.expect(job_id == 1);

    // Check job count
    const jobs = job_mgr.get_all_jobs();
    try testing.expect(jobs.len == 1);

    // Get job
    const job = job_mgr.get_job(job_id);
    try testing.expect(job != null);
    try testing.expect(job.?.pid == 12345);
    try testing.expectEqualStrings("test command", job.?.command[0..job.?.command_len]);
    try testing.expect(job.?.status == .running);

    // Get all jobs again
    const all_jobs = job_mgr.get_all_jobs();
    try testing.expect(all_jobs.len == 1);
    try testing.expect(all_jobs[0].job_id == 1);
}

test "integration: job manager remove done jobs" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var job_mgr = job_manager.JobManager.init(allocator);
    defer job_mgr.deinit();

    // Add jobs
    _ = try job_mgr.add_job(12345, "running command");
    _ = try job_mgr.add_job(12346, "done command");

    // Mark one as done
    const job = job_mgr.get_job(2);
    try testing.expect(job != null);
    job.?.status = .done;
    job.?.exit_code = 0;

    // Remove done jobs
    job_mgr.remove_done_jobs();

    // Check that done job was removed
    const remaining_jobs = job_mgr.get_all_jobs();
    try testing.expect(remaining_jobs.len == 1);
    try testing.expect(job_mgr.get_job(1) != null);
    try testing.expect(job_mgr.get_job(2) == null);
}

// ServiceManager integration tests using IntegrationTestEnv
const service_manager = @import("service_manager.zig");
const integration_test_env = @import("integration_test");

test "integration: service manager - get service status" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var test_env = try integration_test_env.create_simple_test_env(allocator, "test-service");
    defer test_env.deinit();

    var sm = service_manager.ServiceManager.init(allocator, test_env.get_supervisor());

    const status = sm.get_service_status("test-service");
    try testing.expect(status != null);
    try testing.expect(status.? == .stopped);
}

test "integration: service manager - service not found" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var test_env = try integration_test_env.IntegrationTestEnv.init(allocator);
    defer test_env.deinit();

    var sm = service_manager.ServiceManager.init(allocator, test_env.get_supervisor());

    const status = sm.get_service_status("nonexistent-service");
    try testing.expect(status == null);
}

test "integration: service manager - list services" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var test_env = try integration_test_env.IntegrationTestEnv.init(allocator);
    defer test_env.deinit();

    _ = try test_env.add_test_service("service-1", "/usr/bin/true");
    _ = try test_env.add_test_service("service-2", "/usr/bin/true");

    var sm = service_manager.ServiceManager.init(allocator, test_env.get_supervisor());

    const services = try sm.list_services();
    defer allocator.free(services);

    try testing.expect(services.len == 2);
    
    // Verify service names
    const names = [_][]const u8{ "service-1", "service-2" };
    var found: [2]bool = .{ false, false };
    for (services) |service_info| {
        for (names, 0..) |name, i| {
            if (std.mem.eql(u8, service_info.name, name)) {
                found[i] = true;
                break;
            }
        }
    }
    try testing.expect(found[0] == true);
    try testing.expect(found[1] == true);
}
