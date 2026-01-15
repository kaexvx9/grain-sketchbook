//! Tests for kernel log reading syscall.
//! Why: Verify kernel can provide log entries to userspace for Grain OS integration.

const std = @import("std");
const testing = std.testing;
const harbor_kernel = @import("harbor_kernel");
const KernelLogLevel = @import("kernel_log_buffer.zig").KernelLogLevel;
const KernelLogEntry = @import("kernel_log_buffer.zig").KernelLogEntry;

test "kernel log reading syscall" {
    var kernel = harbor_kernel.HarborKernel.init();
    
    // Add some test log entries to the buffer.
    kernel.log_buffer.add_entry(
        KernelLogLevel.info,
        "test",
        "Test message 1",
    );
    kernel.log_buffer.add_entry(
        KernelLogLevel.warn,
        "test",
        "Test message 2",
    );
    
    // Test read_kernel_log with valid buffer.
    const buffer_ptr: u64 = 0x1000; // Valid VM memory address
    const buffer_len: u64 = 1024; // Enough for multiple KernelLogEntry structures
    const max_entries: u64 = 16;
    
    const read_log_num = @intFromEnum(harbor_kernel.Syscall.read_kernel_log);
    const handle_syscall = harbor_kernel.handle_syscall;
    const result = try handle_syscall(&kernel, read_log_num, buffer_ptr, buffer_len, max_entries, 0);
    
    // Should succeed and return number of entries.
    try testing.expect(result == .success);
    try testing.expect(result.success >= 2); // At least 2 entries
}

test "kernel log reading with invalid buffer" {
    var kernel = harbor_kernel.HarborKernel.init();
    
    // Test with null buffer pointer.
    const read_log_num = @intFromEnum(harbor_kernel.Syscall.read_kernel_log);
    const handle_syscall = harbor_kernel.handle_syscall;
    const result1 = try handle_syscall(&kernel, read_log_num, 0, 1024, 16, 0);
    try testing.expect(result1 == .err);
    try testing.expect(result1.err == harbor_kernel.HarborError.invalid_argument);
    
    // Test with buffer too small.
    const buffer_ptr: u64 = 0x1000;
    const KERNEL_LOG_ENTRY_SIZE: u64 = @sizeOf(KernelLogEntry);
    const result2 = try handle_syscall(&kernel, read_log_num, buffer_ptr, KERNEL_LOG_ENTRY_SIZE - 1, 16, 0);
    try testing.expect(result2 == .err);
    try testing.expect(result2.err == harbor_kernel.HarborError.invalid_argument);
}

test "kernel log entry structure layout" {
    // Verify KernelLogEntry structure size and layout.
    const entry = KernelLogEntry.init();
    
    // Structure should be: timestamp(8) + level(1) + padding(7) + source(32) + message(256) = 304 bytes
    // With alignment: timestamp(8) + level(1) + padding(7) = 16, source(32) = 32, message(256) = 256
    // Total: 304 bytes
    
    try testing.expect(@sizeOf(KernelLogEntry) == 304);
    try testing.expect(entry.timestamp == 0);
    try testing.expect(entry.level == 0);
    try testing.expect(entry.source[0] == 0);
    try testing.expect(entry.message[0] == 0);
}

