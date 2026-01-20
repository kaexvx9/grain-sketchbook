//! Basin Kernel Stats Syscalls
//! Why: Statistics and resource management syscalls (kernel_get_stats, health_check, get_resource_usage, set_resource_limit).
//! Grain Style: Explicit types, static allocation, comprehensive assertions.

const std = @import("std");
const Debug = @import("debug.zig");

// Import types
const types = @import("basin_kernel_types.zig");
const BasinError = types.BasinError;
const SyscallResult = types.SyscallResult;
const ResourceUsage = types.ResourceUsage;
const MAX_PROCESSES = types.MAX_PROCESSES;
const Process = types.Process;

// Import core
const core = @import("basin_kernel_core.zig");
const BasinKernel = core.BasinKernel;

/// Stats syscall handlers for BasinKernel.
/// Why: Extract stats syscalls to separate module for organization.
pub const StatsSyscalls = struct {
    /// Get unified kernel statistics snapshot.
    /// Why: Provide comprehensive system statistics for monitoring and debugging.
    /// Contract: stats_ptr must be valid pointer (checked by integration layer).
    /// Note: Integration layer will write KernelStatsSnapshot structure to stats_ptr.
    pub fn syscall_kernel_get_stats(
        self: *BasinKernel,
        stats_ptr: u64,
        _arg2: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg2;
        _ = _arg3;
        _ = _arg4;
        
        // Assert: Stats pointer must be valid (non-zero, within VM memory).
        if (stats_ptr == 0) {
            return BasinError.invalid_argument; // Null pointer
        }
        
        const VM_MEMORY_SIZE: u64 = 4 * 1024 * 1024; // 4MB default
        if (stats_ptr >= VM_MEMORY_SIZE) {
            return BasinError.invalid_argument; // Stats pointer exceeds VM memory
        }
        
        // Assert: KernelStatsSnapshot structure must fit within VM memory.
        // KernelStatsSnapshot size: 7 pointers (8 bytes each) + 2 u64 + 1 f64 = 7*8 + 2*8 + 8 = 80 bytes
        const KERNEL_STATS_SIZE: u64 = 80;
        if (stats_ptr + KERNEL_STATS_SIZE > VM_MEMORY_SIZE) {
            return BasinError.invalid_argument; // Stats structure exceeds VM memory
        }
        
        // Note: This syscall is handled by integration layer (needs VM access to write snapshot).
        // This stub validates the pointer but integration layer will write the KernelStatsSnapshot structure.
        // Contract: stats_ptr must be valid (checked above).
        
        // Get snapshot for validation (integration layer will use this).
        _ = self.get_kernel_stats_snapshot();
        
        const result = SyscallResult.ok(0);
        
        // Assert: result must be success (not error).
        Debug.kassert(result == .success, "Result not success", .{});
        
        return result;
    }
    
    /// Health check syscall.
    /// Why: Provide overall system health status for monitoring.
    /// Returns: Health status (0 = healthy, 1 = degraded, 2 = unhealthy).
    pub fn syscall_health_check(
        self: *BasinKernel,
        _arg1: u64,
        _arg2: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg1;
        _ = _arg2;
        _ = _arg3;
        _ = _arg4;
        
        // Get kernel statistics snapshot.
        const snapshot = self.get_kernel_stats_snapshot();
        
        // Calculate health status based on health score.
        // Health score: 0.0 to 100.0 (higher is better).
        // Status: 0 = healthy (>= 80.0), 1 = degraded (50.0-79.9), 2 = unhealthy (< 50.0)
        var health_status: u64 = 0;
        if (snapshot.health_score < 50.0) {
            health_status = 2; // Unhealthy
        } else if (snapshot.health_score < 80.0) {
            health_status = 1; // Degraded
        } else {
            health_status = 0; // Healthy
        }
        
        // Assert: Health status must be valid (0, 1, or 2).
        Debug.kassert(health_status <= 2, "Health status out of range", .{});
        
        const result = SyscallResult.ok(health_status);
        
        // Assert: result must be success (not error).
        Debug.kassert(result == .success, "Result not success", .{});
        
        return result;
    }
    
    /// Validate VM pointer with size check.
    fn validate_usage_ptr(ptr: u64, size: u64) ?BasinError {
        const VM_MEM: u64 = 4 * 1024 * 1024;
        if (ptr == 0 or ptr >= VM_MEM) return BasinError.invalid_argument;
        if (ptr + size > VM_MEM) return BasinError.invalid_argument;
        return null;
    }

    /// Count file descriptors owned by process.
    fn count_fds_for_pid(self: *BasinKernel, pid: u64) u32 {
        var count: u32 = 0;
        const pid32 = @as(u32, @truncate(pid));
        for (self.handles) |h| {
            if (h.allocated and h.owner_process_id == pid32) count += 1;
        }
        return count;
    }

    /// Why: Expose per-process resource usage (CPU, memory, network, file descriptors).
    pub fn syscall_get_resource_usage(
        self: *BasinKernel,
        pid: u64,
        usage_ptr: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg3;
        _ = _arg4;

        if (pid == 0) return BasinError.invalid_argument;
        if (validate_usage_ptr(usage_ptr, 48)) |err| return err;

        const idx = find_proc_by_pid(self, pid) orelse return BasinError.process_not_found;
        const process = &self.processes[idx];

        // Build usage struct (stub: would write to VM memory).
        _ = ResourceUsage{
            .pid = @intCast(pid),
            .cpu_time_ns = process.cpu_time_ns,
            .memory_used = process.memory_used,
            .network_bytes_sent = process.network_bytes_sent,
            .network_bytes_received = process.network_bytes_received,
            .open_file_descriptors = count_fds_for_pid(self, pid),
            .open_connections = process.open_connections,
        };

        return SyscallResult.ok(0);
    }
    
    /// Set resource limit for a process.
    /// Find process index by ID.
    fn find_proc_by_pid(self: *BasinKernel, pid: u64) ?u32 {
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == pid) return @intCast(i);
        }
        return null;
    }

    /// Apply a resource limit to a process.
    fn apply_limit(process: *Process, limit_type: u64, value: u64) ?BasinError {
        switch (limit_type) {
            0 => process.max_cpu_time_ns = value,
            1 => process.max_memory_bytes = value,
            2 => {
                if (value > 0xFFFFFFFF) return BasinError.invalid_argument;
                process.max_file_descriptors = @truncate(value);
            },
            3 => {
                if (value > 0xFFFFFFFF) return BasinError.invalid_argument;
                process.max_connections = @truncate(value);
            },
            else => return BasinError.invalid_argument,
        }
        return null;
    }

    /// Why: Configure per-process resource limits to prevent resource exhaustion.
    pub fn syscall_set_resource_limit(
        self: *BasinKernel,
        pid: u64,
        limit_type: u64,
        limit_value: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg4;

        if (pid == 0 or limit_type > 3) return BasinError.invalid_argument;

        const idx = find_proc_by_pid(self, pid) orelse return BasinError.process_not_found;

        // Permission check: root or self.
        const current = self.scheduler.get_current();
        if (current != pid and !self.current_user.is_root()) {
            return BasinError.permission_denied;
        }

        if (apply_limit(&self.processes[idx], limit_type, limit_value)) |err| return err;
        return SyscallResult.ok(0);
    }
};
