//! Tests for process enumeration syscall.
//! Why: Verify kernel can enumerate processes for Grain OS integration.

const std = @import("std");
const testing = std.testing;
const harbor_kernel = @import("harbor_kernel");
const handle_syscall = harbor_kernel.handle_syscall;
const Syscall = harbor_kernel.Syscall;
const RawIO = harbor_kernel.RawIO;

// Helper: Create kernel on heap to avoid stack overflow.
fn create_test_kernel() !*harbor_kernel.HarborKernel {
    const kernel = try testing.allocator.create(harbor_kernel.HarborKernel);
    harbor_kernel.HarborKernel.init_in_place(kernel);
    return kernel;
}

test "process enumeration syscall" {
    RawIO.disable(); // Disable hardware access in tests
    defer RawIO.enable();
    
    const kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);
    
    // Create a test process by spawning (simplified - just test the syscall interface).
    // Note: Actual process spawning requires ELF loading, so we'll test the enumeration
    // interface with empty process table for now.
    
    // Test enumerate_processes with empty process table.
    const buffer_ptr: u64 = 0x1000; // Valid VM memory address
    const buffer_len: u64 = 1024; // Enough for multiple ProcessInfo structures
    const max_processes: u64 = 16;
    
    const enum_num = @intFromEnum(Syscall.enumerate_processes);
    const result = try handle_syscall(kernel, enum_num, buffer_ptr, buffer_len, max_processes, 0);
    
    // Should succeed even with empty process table.
    try testing.expect(result == .success);
    try testing.expect(result.success == 0); // No processes found
}

test "process enumeration with invalid buffer" {
    RawIO.disable(); // Disable hardware access in tests
    defer RawIO.enable();
    
    const kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);
    
    // Test with null buffer pointer.
    const enum_num = @intFromEnum(Syscall.enumerate_processes);
    const result1 = handle_syscall(kernel, enum_num, 0, 1024, 16, 0) catch |err| {
        try testing.expect(err == harbor_kernel.HarborError.invalid_argument);
        // Test with buffer too small.
        const buffer_ptr: u64 = 0x1000;
        const PROCESS_INFO_SIZE: u64 = 32;
        const enum_num2 = @intFromEnum(Syscall.enumerate_processes);
        const result2 = handle_syscall(kernel, enum_num2, buffer_ptr, PROCESS_INFO_SIZE - 1, 16, 0) catch |err2| {
            try testing.expect(err2 == harbor_kernel.HarborError.invalid_argument);
            return;
        };
        try testing.expect(result2 == .err);
        try testing.expect(result2.err == harbor_kernel.HarborError.invalid_argument);
        return;
    };
    try testing.expect(result1 == .err);
    try testing.expect(result1.err == harbor_kernel.HarborError.invalid_argument);
    
    // Test with buffer too small.
    const buffer_ptr: u64 = 0x1000;
    const PROCESS_INFO_SIZE: u64 = 32;
    const enum_num2 = @intFromEnum(Syscall.enumerate_processes);
    const result2 = handle_syscall(kernel, enum_num2, buffer_ptr, PROCESS_INFO_SIZE - 1, 16, 0) catch |err| {
        try testing.expect(err == harbor_kernel.HarborError.invalid_argument);
        return;
    };
    try testing.expect(result2 == .err);
    try testing.expect(result2.err == harbor_kernel.HarborError.invalid_argument);
}

test "get process info syscall" {
    RawIO.disable(); // Disable hardware access in tests
    defer RawIO.enable();
    
    const kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);
    
    // Test with invalid process ID.
    const info_ptr: u64 = 0x1000;
    const get_info_num = @intFromEnum(Syscall.get_process_info);
    const result1 = handle_syscall(kernel, get_info_num, 0, info_ptr, 0, 0) catch |err| {
        try testing.expect(err == harbor_kernel.HarborError.invalid_argument);
        // Test with non-existent process.
        const get_info_num2 = @intFromEnum(Syscall.get_process_info);
        const result2 = handle_syscall(kernel, get_info_num2, 999, info_ptr, 0, 0) catch |err2| {
            try testing.expect(err2 == harbor_kernel.HarborError.not_found);
            // Test with null info pointer.
            const get_info_num3 = @intFromEnum(Syscall.get_process_info);
            const result3 = handle_syscall(kernel, get_info_num3, 1, 0, 0, 0) catch |err3| {
                try testing.expect(err3 == harbor_kernel.HarborError.invalid_argument);
                return;
            };
            try testing.expect(result3 == .err);
            try testing.expect(result3.err == harbor_kernel.HarborError.invalid_argument);
            return;
        };
        try testing.expect(result2 == .err);
        try testing.expect(result2.err == harbor_kernel.HarborError.not_found);
        return;
    };
    try testing.expect(result1 == .err);
    try testing.expect(result1.err == harbor_kernel.HarborError.invalid_argument);
    
    // Test with non-existent process.
    const get_info_num2 = @intFromEnum(Syscall.get_process_info);
    const result2 = handle_syscall(kernel, get_info_num2, 999, info_ptr, 0, 0) catch |err| {
        try testing.expect(err == harbor_kernel.HarborError.not_found);
        // Test with null info pointer.
        const get_info_num3 = @intFromEnum(Syscall.get_process_info);
        const result3 = handle_syscall(kernel, get_info_num3, 1, 0, 0, 0) catch |err3| {
            try testing.expect(err3 == harbor_kernel.HarborError.invalid_argument);
            return;
        };
        try testing.expect(result3 == .err);
        try testing.expect(result3.err == harbor_kernel.HarborError.invalid_argument);
        return;
    };
    try testing.expect(result2 == .err);
    try testing.expect(result2.err == harbor_kernel.HarborError.not_found);
    
    // Test with null info pointer.
    const get_info_num3 = @intFromEnum(Syscall.get_process_info);
    const result3 = handle_syscall(kernel, get_info_num3, 1, 0, 0, 0) catch |err| {
        try testing.expect(err == harbor_kernel.HarborError.invalid_argument);
        return;
    };
    try testing.expect(result3 == .err);
    try testing.expect(result3.err == harbor_kernel.HarborError.invalid_argument);
}

test "process info structure layout" {
    // Disable RawIO to avoid SIGILL in tests.
    RawIO.disable();
    defer RawIO.enable();
    
    // Verify ProcessInfo structure size and layout.
    const info = harbor_kernel.ProcessInfo.init();
    
    // Structure should be 32 bytes:
    // pid: u32 (4) + parent_pid: u32 (4) + state: u8 (1) + padding (3) = 12
    // cpu_time_ns: u64 (8) = 20 (but u64 alignment means offset 16)
    // memory_used: u64 (8) = 28 (but u64 alignment means offset 24)
    // Total: 32 bytes with padding
    
    try testing.expect(@sizeOf(harbor_kernel.ProcessInfo) == 32);
    try testing.expect(info.pid == 0);
    try testing.expect(info.parent_pid == 0);
    try testing.expect(info.state == 0);
    try testing.expect(info.cpu_time_ns == 0);
    try testing.expect(info.memory_used == 0);
}

