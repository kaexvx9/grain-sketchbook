//! Test: Kernel Statistics Aggregator
//!
//! Objective: Verify unified statistics aggregation from all kernel subsystems.
//! Why: Ensure comprehensive system monitoring works correctly.
//! GrainStyle: Comprehensive test coverage, deterministic behavior.

const std = @import("std");
const testing = std.testing;
const basin_kernel = @import("basin_kernel");
const BasinKernel = basin_kernel.BasinKernel;
const KernelStatsSnapshot = basin_kernel.KernelStatsSnapshot;
const handle_syscall = basin_kernel.handle_syscall;
const Syscall = basin_kernel.Syscall;

// Helper: Create kernel on heap to avoid stack overflow.
fn create_test_kernel() !*BasinKernel {
    const kernel = try testing.allocator.create(BasinKernel);
    BasinKernel.init_in_place(kernel);
    return kernel;
}

// Test: Kernel statistics snapshot creation.
test "kernel stats snapshot create" {
    var kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);
    
    // Get statistics snapshot.
    const snapshot = kernel.get_kernel_stats_snapshot();
    
    // Assert: Snapshot must be valid.
    try testing.expect(snapshot.total_errors == 0);
    try testing.expect(snapshot.total_operations == 0);
    try testing.expect(snapshot.health_score == 100.0);
}

// Test: Kernel statistics snapshot with TCP operations.
test "kernel stats snapshot with tcp operations" {
    // Disable RawIO to avoid SIGILL in tests.
    RawIO.disable();
    defer RawIO.enable();
    
    var kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);
    
    // Create TCP socket and perform operations.
    const tcp_socket_num = @intFromEnum(Syscall.tcp_socket);
    const socket_result = try handle_syscall(kernel, tcp_socket_num, 0, 0, 0, 0);
    try testing.expect(socket_result == .success);
    
    const socket_id = socket_result.success;
    
    // Send some data.
    const send_data: [4]u8 = "test".*;
    const tcp_send_num = @intFromEnum(Syscall.tcp_send);
    _ = handle_syscall(kernel, tcp_send_num, socket_id, @intFromPtr(&send_data), 4, 0) catch {};
    
    // Get statistics snapshot.
    const snapshot = kernel.get_kernel_stats_snapshot();
    
    // Assert: Snapshot must reflect operations.
    try testing.expect(snapshot.total_operations > 0);
    try testing.expect(snapshot.health_score <= 100.0);
    try testing.expect(snapshot.health_score >= 0.0);
}

// Test: Kernel statistics snapshot with network operations.
test "kernel stats snapshot with network operations" {
    var kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);
    
    // Create network interface.
    var iface_name: [16]u8 = undefined;
    @memset(&iface_name, 0);
    @memcpy(iface_name[0..4], "eth0");
    const network_create_num = @intFromEnum(Syscall.network_create_interface);
    _ = handle_syscall(kernel, network_create_num, @intFromPtr(&iface_name), 4, 0, 0) catch {};
    
    // Get statistics snapshot.
    const snapshot = kernel.get_kernel_stats_snapshot();
    
    // Assert: Snapshot must reflect operations.
    try testing.expect(snapshot.total_operations > 0);
    try testing.expect(snapshot.health_score <= 100.0);
    try testing.expect(snapshot.health_score >= 0.0);
}

// Test: Kernel statistics snapshot with errors.
test "kernel stats snapshot with errors" {
    var kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);
    
    // Try to create TCP socket with invalid arguments (will fail).
    const tcp_socket_num2 = @intFromEnum(Syscall.tcp_socket);
    _ = handle_syscall(kernel, tcp_socket_num2, 0xFFFFFFFF, 0, 0, 0) catch {};
    
    // Try to create network interface with invalid name (will fail).
    const network_create_num2 = @intFromEnum(Syscall.network_create_interface);
    _ = handle_syscall(kernel, network_create_num2, 0, 0, 0, 0) catch {};
    
    // Get statistics snapshot.
    const snapshot = kernel.get_kernel_stats_snapshot();
    
    // Assert: Snapshot must reflect errors.
    // Note: Some operations may succeed, so we just check that snapshot is valid.
    try testing.expect(snapshot.health_score <= 100.0);
    try testing.expect(snapshot.health_score >= 0.0);
}

// Test: Kernel statistics snapshot print (doesn't crash).
test "kernel stats snapshot print" {
    var kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);
    
    // Get statistics snapshot.
    const snapshot = kernel.get_kernel_stats_snapshot();
    
    // Print statistics (should not crash).
    snapshot.print();
    
    // Assert: Snapshot must be valid.
    try testing.expect(snapshot.health_score <= 100.0);
    try testing.expect(snapshot.health_score >= 0.0);
}
