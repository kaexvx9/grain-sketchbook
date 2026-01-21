//! Basin Kernel Lite: Test-friendly minimal kernel
//! Why: Smaller footprint for unit testing without stack overflow.
//!
//! The full BasinKernel has a 4MB memory pool that causes stack overflow
//! in tests. This lite version uses minimal allocations for testing.

const std = @import("std");
const Debug = @import("debug.zig");
const Timer = @import("timer.zig").Timer;
const InterruptController = @import("interrupt.zig").InterruptController;
const Scheduler = @import("scheduler.zig").Scheduler;

const types = @import("basin_kernel_types.zig");
pub const Syscall = types.Syscall;
pub const BasinError = types.BasinError;
pub const SyscallResult = types.SyscallResult;

// === Lite Constants (smaller than full kernel) ===

/// Why: Smaller limits for testing.
pub const LITE_MAX_PROCESSES: u32 = 4;
pub const LITE_MAX_HANDLES: u32 = 4;
pub const LITE_MAX_MAPPINGS: u32 = 4;

// === Lite Process State ===

/// Why: Lite process states (matches subset of full kernel).
pub const LiteProcessState = enum(u8) {
    free = 0,
    running = 1,
    ready = 2,
    exited = 3,
};

// === Lite Process ===

/// Why: Minimal process for testing.
pub const LiteProcess = struct {
    pid: u64,
    state: LiteProcessState,
    priority: u8,

    /// Why: Initialize empty process.
    pub fn init() LiteProcess {
        return LiteProcess{
            .pid = 0,
            .state = .free,
            .priority = 0,
        };
    }

    /// Why: Check if slot is used.
    pub fn is_active(self: *const LiteProcess) bool {
        return self.pid != 0 and self.state != .free;
    }
};

// === Lite Memory ===

/// Why: Minimal memory pool for testing (64KB instead of 4MB).
pub const LITE_POOL_SIZE: u32 = 64 * 1024;
pub const LITE_PAGE_SIZE: u32 = 4096;
pub const LITE_MAX_PAGES: u32 = LITE_POOL_SIZE / LITE_PAGE_SIZE;

/// Why: Page state tracking.
pub const PageState = enum(u8) { free = 0, allocated = 1 };

/// Why: Minimal memory pool.
pub const LiteMemoryPool = struct {
    page_states: [LITE_MAX_PAGES]PageState,
    allocated_pages: u32,

    /// Why: Initialize pool.
    pub fn init() LiteMemoryPool {
        return LiteMemoryPool{
            .page_states = [_]PageState{.free} ** LITE_MAX_PAGES,
            .allocated_pages = 0,
        };
    }

    /// Why: Get free page count.
    pub fn get_free_pages(self: *const LiteMemoryPool) u32 {
        return LITE_MAX_PAGES - self.allocated_pages;
    }
};

// === Lite Kernel ===

/// Why: Minimal kernel for testing core functionality.
pub const BasinKernelLite = struct {
    // Core subsystems (small).
    timer: Timer,
    interrupt_controller: InterruptController,
    scheduler: Scheduler,

    // Minimal process table.
    processes: [LITE_MAX_PROCESSES]LiteProcess,
    next_process_id: u64,
    current_process_index: u32,

    // Minimal memory.
    memory_pool: LiteMemoryPool,

    // State.
    initialized: bool,
    boot_time_ns: u64,

    /// Why: Initialize lite kernel.
    pub fn init() BasinKernelLite {
        return BasinKernelLite{
            .timer = Timer.init(),
            .interrupt_controller = InterruptController.init(),
            .scheduler = Scheduler.init(),
            .processes = [_]LiteProcess{LiteProcess.init()} ** LITE_MAX_PROCESSES,
            .next_process_id = 1,
            .current_process_index = LITE_MAX_PROCESSES,
            .memory_pool = LiteMemoryPool.init(),
            .initialized = true,
            .boot_time_ns = 0,
        };
    }

    /// Why: Spawn a minimal process.
    pub fn spawn_process(self: *BasinKernelLite, priority: u8) ?u64 {
        // Find free slot.
        for (&self.processes, 0..) |*proc, idx| {
            if (!proc.is_active()) {
                const pid = self.next_process_id;
                self.next_process_id += 1;
                proc.pid = pid;
                proc.state = .running;
                proc.priority = priority;

                // Set as current if first process.
                if (self.current_process_index >= LITE_MAX_PROCESSES) {
                    self.current_process_index = @intCast(idx);
                }
                return pid;
            }
        }
        return null;
    }

    /// Why: Get current process.
    pub fn get_current_process(self: *BasinKernelLite) ?*LiteProcess {
        if (self.current_process_index >= LITE_MAX_PROCESSES) return null;
        return &self.processes[self.current_process_index];
    }

    /// Why: Exit current process.
    pub fn exit_process(self: *BasinKernelLite, exit_code: u32) bool {
        _ = exit_code;
        if (self.current_process_index >= LITE_MAX_PROCESSES) return false;
        self.processes[self.current_process_index] = LiteProcess.init();
        self.current_process_index = LITE_MAX_PROCESSES;
        return true;
    }

    /// Why: Yield to next process.
    pub fn yield_process(self: *BasinKernelLite) void {
        // Find next running process.
        var checked: u32 = 0;
        var idx = (self.current_process_index + 1) % LITE_MAX_PROCESSES;
        while (checked < LITE_MAX_PROCESSES) {
            if (self.processes[idx].is_active() and self.processes[idx].state == .running) {
                self.current_process_index = idx;
                return;
            }
            idx = (idx + 1) % LITE_MAX_PROCESSES;
            checked += 1;
        }
    }

    /// Why: Handle syscall dispatch.
    pub fn syscall(self: *BasinKernelLite, num: u32, a0: u64, a1: u64, a2: u64) SyscallResult {
        _ = a1;
        _ = a2;
        const syscall_enum = std.meta.intToEnum(Syscall, num) catch {
            return SyscallResult.fail(BasinError.invalid_syscall);
        };

        return switch (syscall_enum) {
            .spawn => blk: {
                const pid = self.spawn_process(@intCast(a0)) orelse {
                    break :blk SyscallResult.fail(BasinError.out_of_memory);
                };
                break :blk SyscallResult.ok(pid);
            },
            .exit => blk: {
                _ = self.exit_process(@intCast(a0));
                break :blk SyscallResult.ok(0);
            },
            .yield => blk: {
                self.yield_process();
                break :blk SyscallResult.ok(0);
            },
            else => SyscallResult.fail(BasinError.invalid_syscall),
        };
    }

    /// Why: Get process count.
    pub fn process_count(self: *const BasinKernelLite) u32 {
        var count: u32 = 0;
        for (&self.processes) |*proc| {
            if (proc.is_active()) count += 1;
        }
        return count;
    }

    /// Why: Check if initialized.
    pub fn is_initialized(self: *const BasinKernelLite) bool {
        return self.initialized;
    }
};

// === Tests ===

test "lite kernel initialization" {
    var kernel = BasinKernelLite.init();
    try std.testing.expect(kernel.is_initialized());
    try std.testing.expect(kernel.interrupt_controller.initialized);
    try std.testing.expectEqual(@as(u32, 0), kernel.process_count());
}

test "lite kernel spawn process" {
    var kernel = BasinKernelLite.init();
    const pid = kernel.spawn_process(5);
    try std.testing.expect(pid != null);
    try std.testing.expectEqual(@as(u64, 1), pid.?);
    try std.testing.expectEqual(@as(u32, 1), kernel.process_count());
}

test "lite kernel multiple processes" {
    var kernel = BasinKernelLite.init();

    const p1 = kernel.spawn_process(1);
    const p2 = kernel.spawn_process(2);
    const p3 = kernel.spawn_process(3);

    try std.testing.expect(p1 != null);
    try std.testing.expect(p2 != null);
    try std.testing.expect(p3 != null);
    try std.testing.expectEqual(@as(u32, 3), kernel.process_count());
}

test "lite kernel exit process" {
    var kernel = BasinKernelLite.init();
    _ = kernel.spawn_process(5);
    try std.testing.expectEqual(@as(u32, 1), kernel.process_count());

    try std.testing.expect(kernel.exit_process(0));
    try std.testing.expectEqual(@as(u32, 0), kernel.process_count());
}

test "lite kernel yield" {
    var kernel = BasinKernelLite.init();
    _ = kernel.spawn_process(1);
    _ = kernel.spawn_process(2);

    const initial_idx = kernel.current_process_index;
    kernel.yield_process();
    try std.testing.expect(kernel.current_process_index != initial_idx);
}

test "lite kernel syscall spawn" {
    var kernel = BasinKernelLite.init();
    const result = kernel.syscall(@intFromEnum(Syscall.spawn), 5, 0, 0);
    switch (result) {
        .success => |pid| try std.testing.expectEqual(@as(u64, 1), pid),
        .err => return error.UnexpectedError,
    }
}

test "lite kernel syscall yield" {
    var kernel = BasinKernelLite.init();
    _ = kernel.spawn_process(1);
    const result = kernel.syscall(@intFromEnum(Syscall.yield), 0, 0, 0);
    switch (result) {
        .success => {},
        .err => return error.UnexpectedError,
    }
}

test "lite kernel memory pool" {
    const kernel = BasinKernelLite.init();
    try std.testing.expectEqual(LITE_MAX_PAGES, kernel.memory_pool.get_free_pages());
}

test "lite kernel interrupt controller" {
    const kernel = BasinKernelLite.init();
    try std.testing.expect(kernel.interrupt_controller.initialized);
    try std.testing.expectEqual(@as(u64, 0), kernel.interrupt_controller.pending);
}
