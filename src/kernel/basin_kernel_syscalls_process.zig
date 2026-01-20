//! Basin Kernel Process Syscalls
//! Why: Process management syscalls (spawn, exit, wait, yield, process groups, signals).
//! Grain Style: Explicit types, static allocation, comprehensive assertions.

const std = @import("std");
const Debug = @import("debug.zig");
const ProcessContext = @import("process.zig").ProcessContext;
const Signal = @import("signal.zig").Signal;
const SignalAction = @import("signal.zig").SignalAction;
const elf_parser = @import("elf_parser.zig");
const segment_loader = @import("segment_loader.zig");
const resource_cleanup = @import("resource_cleanup.zig");

// Import types
const types = @import("basin_kernel_types.zig");
const BasinError = types.BasinError;
const SyscallResult = types.SyscallResult;
const Process = types.Process;
const MAX_PROCESSES = types.MAX_PROCESSES;

// Import core
const core = @import("basin_kernel_core.zig");
const BasinKernel = core.BasinKernel;

const VM_MEM: u64 = 4 * 1024 * 1024;
const MIN_ELF: u64 = 64;
const STACK_PTR: u64 = 0x3ff000;

/// Validate spawn arguments.
fn validate_spawn_args(exe: u64, args_ptr: u64, args_len: u64) ?BasinError {
    if (exe == 0 or exe >= VM_MEM or exe + MIN_ELF > VM_MEM) return BasinError.invalid_argument;
    if (args_ptr != 0) {
        if (args_ptr >= VM_MEM or args_len == 0 or args_len > 65536) return BasinError.invalid_argument;
        if (args_ptr + args_len > VM_MEM) return BasinError.invalid_argument;
    } else if (args_len != 0) return BasinError.invalid_argument;
    return null;
}

/// Find free process slot.
fn find_free_slot(self: *BasinKernel) ?usize {
    for (0..MAX_PROCESSES) |i| {
        if (!self.processes[i].allocated) return i;
    }
    return null;
}

/// Parse ELF and get entry point.
fn parse_elf_entry(self: *BasinKernel, exe: u64) struct { entry: u64, len: u64 } {
    const reader = self.vm_memory_reader orelse return .{ .entry = exe, .len = MIN_ELF };
    var buf: [64]u8 = undefined;
    const n = reader(exe, 64, &buf) orelse return .{ .entry = exe, .len = MIN_ELF };
    if (n < 64) return .{ .entry = exe, .len = MIN_ELF };
    const info = elf_parser.parse_elf_header(&buf);
    if (!info.valid) return .{ .entry = exe, .len = MIN_ELF };
    load_segments(self, exe, info, reader);
    return .{ .entry = info.entry_point, .len = MIN_ELF };
}

/// Load ELF program segments.
fn load_segments(
    self: *BasinKernel,
    exe: u64,
    info: elf_parser.ElfHeader,
    reader: *const fn (u64, u32, [*]u8) ?u32,
) void {
    if (info.phnum == 0 or info.phoff == 0 or info.phentsize < 56) return;
    const writer = self.vm_memory_writer orelse return;
    const count = @min(info.phnum, 16);
    for (0..count) |i| {
        const off = info.phoff + (@as(u64, @intCast(i)) * @as(u64, info.phentsize));
        var phdr: [56]u8 = undefined;
        const n = reader(exe + off, 56, &phdr) orelse break;
        if (n < 56) break;
        const seg = elf_parser.parse_program_header(&phdr);
        if (seg.valid) _ = segment_loader.load_program_segment(seg, exe, reader, writer, self);
    }
}

/// Check process group spawn limit.
fn check_spawn_limit(self: *BasinKernel, pgid: u64) bool {
    if (pgid == 0) return true;
    var count: u32 = 0;
    for (0..MAX_PROCESSES) |i| {
        if (self.processes[i].allocated and self.processes[i].pgid == pgid) count += 1;
    }
    return self.process_group_limits.can_spawn_process(pgid, count);
}

/// Initialize process entry.
fn init_process(
    self: *BasinKernel,
    idx: usize,
    pid: u64,
    exe: u64,
    entry: u64,
    pgid: u64,
) void {
    const p = &self.processes[idx];
    p.id = pid;
    p.state = .running;
    p.exit_status = 0;
    p.executable_ptr = exe;
    p.executable_len = MIN_ELF;
    p.entry_point = entry;
    p.stack_pointer = STACK_PTR;
    p.context = ProcessContext.init(entry, STACK_PTR, entry);
    p.parent_pid = self.scheduler.get_current();
    p.cpu_time_ns = 0;
    p.memory_used = MIN_ELF;
    p.priority = 0;
    p.pgid = pgid;
    p.allocated = true;
}

/// Process syscall handlers for BasinKernel.
pub const ProcessSyscalls = struct {
    /// Why: Create a new child process from an executable.
    pub fn syscall_spawn(
        self: *BasinKernel,
        executable: u64,
        args_ptr: u64,
        args_len: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg4;
        if (validate_spawn_args(executable, args_ptr, args_len)) |e| return e;

        const idx = find_free_slot(self) orelse return BasinError.out_of_memory;
        const pid = self.next_process_id;
        self.next_process_id += 1;

        const elf = parse_elf_entry(self, executable);
        const pgid = get_parent_pgid(self);
        if (!check_spawn_limit(self, pgid)) return BasinError.resource_exhausted;

        init_process(self, idx, pid, executable, elf.entry, pgid);
        self.scheduler.set_current(pid, self.processes[idx].time_slice_quantum);
        self.current_process_index = @as(u32, @intCast(idx));

        return SyscallResult.ok(pid);
    }

    fn get_parent_pgid(self: *BasinKernel) u64 {
        const cur = self.scheduler.get_current();
        if (cur == 0) return 0;
        const idx = self.find_current_process_index() orelse return 0;
        return self.processes[idx].pgid;
    }

    /// Update process group stats on exit.
    fn update_pgid_on_exit(self: *BasinKernel, pgid: u64) void {
        if (pgid == 0) return;
        self.process_group_stats.increment_exited_count(pgid);
        var count: u32 = 0;
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].pgid == pgid) count += 1;
        }
        if (count > 0) count -= 1;
        self.process_group_stats.update_process_count(pgid, count);
    }

    /// Mark process exited and cleanup scheduler.
    fn mark_exited_and_cleanup(self: *BasinKernel, idx: usize, exit_status: u32, pid: u64) void {
        self.processes[idx].state = .exited;
        self.processes[idx].exit_status = exit_status;
        if (self.scheduler.is_current(pid)) {
            self.scheduler.clear_current();
            self.invalidate_current_process_cache();
        }
        _ = resource_cleanup.cleanup_process_resources(self, @truncate(pid));
    }

    /// Why: Terminate the current process with an exit status.
    pub fn syscall_exit(
        self: *BasinKernel,
        status: u64,
        _arg2: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg2;
        _ = _arg3;
        _ = _arg4;

        Debug.kassert(status <= 255, "Exit status > 255", .{});
        const exit_status = @as(u32, @truncate(status));
        const pid = self.scheduler.get_current();

        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == pid) {
                update_pgid_on_exit(self, self.processes[i].pgid);
                mark_exited_and_cleanup(self, i, exit_status, pid);
                break;
            }
        }
        return SyscallResult.ok(status);
    }

    /// Why: Voluntarily give up CPU to allow other processes to run.
    pub fn syscall_yield(
        self: *BasinKernel,
        _arg1: u64,
        _arg2: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = self;
        _ = _arg1;
        _ = _arg2;
        _ = _arg3;
        _ = _arg4;
        
        // Yield syscall: voluntary CPU yield (cooperative scheduling hint).
        // Why: Simple implementation - return success immediately.
        // Note: VM scheduler (if implemented) can use this hint for context switching.
        // For now, just return success (no-op).
        return SyscallResult.ok(0);
    }

    /// Find process index by ID.
    /// Why: Common lookup logic for wait and other syscalls.
    fn find_process_idx(self: *BasinKernel, pid: u64) ?usize {
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == pid) return i;
        }
        return null;
    }

    /// Why: Wait for a child process to terminate and get its exit status.
    pub fn syscall_wait(
        self: *BasinKernel,
        process: u64,
        _arg2: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg2;
        _ = _arg3;
        _ = _arg4;

        if (process == 0) return BasinError.invalid_argument;

        const idx = find_process_idx(self, process) orelse return BasinError.not_found;

        if (self.processes[idx].state == .exited) {
            const exit_status: u64 = self.processes[idx].exit_status;
            Debug.kassert(exit_status <= 255, "Exit status > 255", .{});
            return SyscallResult.ok(exit_status);
        }

        // Process still running: would block (cooperative scheduling).
        return BasinError.would_block;
    }

    /// Why: Set the process group ID for a process.
    pub fn syscall_setpgid(
        self: *BasinKernel,
        pid: u64,
        pgid: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg3;
        _ = _arg4;
        
        // Assert: Process ID must be valid (non-zero).
        if (pid == 0) {
            return BasinError.invalid_argument; // Invalid process ID
        }
        
        // Assert: Process group ID must be valid (non-zero).
        if (pgid == 0) {
            return BasinError.invalid_argument; // Invalid process group ID
        }
        
        // Find process in process table.
        var found: ?usize = null;
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == pid) {
                found = i;
                break;
            }
        }
        
        if (found == null) {
            return BasinError.not_found; // Process not found
        }
        
        const idx = found.?;
        
        // Set process group ID.
        // Why: Assign process to a process group.
        self.processes[idx].pgid = pgid;
        
        // Update process group statistics.
        // Why: Track process count in groups.
        var process_count: u32 = 0;
        var i: u32 = 0;
        while (i < MAX_PROCESSES) : (i += 1) {
            if (self.processes[i].allocated and self.processes[i].pgid == pgid) {
                process_count += 1;
            }
        }
        self.process_group_stats.update_process_count(pgid, process_count);
        
        // Return success.
        return SyscallResult.ok(0);
    }

    /// Why: Get the process group ID for a process.
    pub fn syscall_getpgid(
        self: *BasinKernel,
        pid: u64,
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
        
        // Assert: Process ID must be valid (non-zero).
        if (pid == 0) {
            return BasinError.invalid_argument; // Invalid process ID
        }
        
        // Find process in process table.
        var found: ?usize = null;
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == pid) {
                found = i;
                break;
            }
        }
        
        if (found == null) {
            return BasinError.not_found; // Process not found
        }
        
        const idx = found.?;
        
        // Get process group ID.
        // Why: Return process group ID for userspace queries.
        const pgid = self.processes[idx].pgid;
        
        // Return process group ID.
        return SyscallResult.ok(pgid);
    }

    /// Why: Create a new session and set the process as session leader.
    pub fn syscall_setsid(
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
        
        // Get current process ID.
        const current_pid = self.scheduler.get_current();
        if (current_pid == 0) {
            return BasinError.invalid_argument; // No current process
        }
        
        // Create new session.
        // Why: Create a new session for the current process.
        const sid = self.process_group_manager.create_session(current_pid);
        if (sid == 0) {
            return BasinError.resource_exhausted; // No free session slot
        }
        
        // Find process in process table.
        var found: ?usize = null;
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == current_pid) {
                found = i;
                break;
            }
        }
        
        if (found == null) {
            return BasinError.not_found; // Process not found
        }
        
        const idx = found.?;
        
        // Set session ID for current process.
        // Why: Assign process to the new session.
        self.processes[idx].sid = sid;
        
        // Create a new process group in the session.
        // Why: Process becomes leader of both session and group.
        const pgid = self.process_group_manager.create_group(
            current_pid,
            sid,
            &self.processes,
            MAX_PROCESSES,
        );
        if (pgid == 0) {
            return BasinError.resource_exhausted; // No free group slot
        }
        
        // Return session ID.
        return SyscallResult.ok(sid);
    }

    /// Why: Get the session ID for a process.
    pub fn syscall_getsid(
        self: *BasinKernel,
        pid: u64,
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
        
        // Assert: Process ID must be valid (non-zero).
        if (pid == 0) {
            return BasinError.invalid_argument; // Invalid process ID
        }
        
        // Find process in process table.
        var found: ?usize = null;
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == pid) {
                found = i;
                break;
            }
        }
        
        if (found == null) {
            return BasinError.not_found; // Process not found
        }
        
        const idx = found.?;
        
        // Get session ID.
        // Why: Return session ID for userspace queries.
        const sid = self.processes[idx].sid;
        
        // Return session ID.
        return SyscallResult.ok(sid);
    }

    /// Handle SIGKILL termination of a process.
    fn handle_sigkill(self: *BasinKernel, process: *Process, pid: u64) void {
        process.state = .exited;
        process.exit_status = 128 + @intFromEnum(Signal.sigkill);
        if (self.scheduler.is_current(pid)) {
            self.scheduler.clear_current();
            self.invalidate_current_process_cache();
        }
    }

    /// Send signal to a single process by index.
    fn send_signal_to_process(self: *BasinKernel, idx: usize, signal: Signal, pid: u64) void {
        const process = &self.processes[idx];
        process.signals.send_signal(signal);
        if (signal == .sigkill) handle_sigkill(self, process, pid);
    }

    /// Why: Send a signal to a process or process group.
    pub fn syscall_kill(
        self: *BasinKernel,
        pid: u64,
        signal_num: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg3;
        _ = _arg4;

        if (signal_num >= 32) return BasinError.invalid_argument;
        const signal = @as(Signal, @enumFromInt(@as(u32, @truncate(signal_num))));

        // Check for process group or session delivery (high bits).
        if ((pid & 0x8000000000000000) != 0) {
            const pgid = pid & 0x7FFFFFFFFFFFFFFF;
            if (pgid == 0) return BasinError.invalid_argument;
            return ProcessSyscalls.kill_process_group(self, pgid, signal);
        }
        if ((pid & 0x4000000000000000) != 0) {
            const sid = pid & 0x3FFFFFFFFFFFFFFF;
            if (sid == 0) return BasinError.invalid_argument;
            return ProcessSyscalls.kill_session(self, sid, signal);
        }

        if (pid == 0) return BasinError.invalid_argument;

        const idx = find_process_idx(self, pid) orelse return BasinError.not_found;
        send_signal_to_process(self, idx, signal, pid);
        return SyscallResult.ok(0);
    }
    
    /// Send signal to all processes in a process group.
    /// Why: Support POSIX signal delivery to process groups.
    /// Contract: pgid must be valid (non-zero), signal must be valid.
    pub fn kill_process_group(
        self: *BasinKernel,
        pgid: u64,
        signal: Signal,
    ) BasinError!SyscallResult {
        // Assert: Process group ID must be valid (non-zero).
        if (pgid == 0) {
            return BasinError.invalid_argument; // Invalid process group ID
        }
        
        // Find all processes in the process group.
        var processes_found: u32 = 0;
        var process_indices: [MAX_PROCESSES]usize = undefined;
        
        var idx: u32 = 0;
        while (idx < MAX_PROCESSES) : (idx += 1) {
            if (self.processes[idx].allocated and self.processes[idx].pgid == pgid) {
                process_indices[processes_found] = idx;
                processes_found += 1;
            }
        }
        
        // If no processes found in group, return error.
        if (processes_found == 0) {
            return BasinError.not_found; // Process group not found or empty
        }
        
        // Send signal to all processes in the group.
        var i: u32 = 0;
        while (i < processes_found) : (i += 1) {
            const process_idx = process_indices[i];
            const process = &self.processes[process_idx];
            
            // Send signal to process.
            process.signals.send_signal(signal);
            
            // SIGKILL immediately terminates process.
            if (signal == .sigkill) {
                process.state = .exited;
                process.exit_status = 128 + @intFromEnum(signal); // Exit code = 128 + signal
                
                // Clear current process if it's the one being killed.
                if (self.scheduler.get_current() == process.id) {
                    self.scheduler.clear_current();
                    // Invalidate current process cache when process is killed.
                    // Why: Ensure cache doesn't point to killed process.
                    self.invalidate_current_process_cache();
                }
            }
        }
        
        // Return success (number of processes signaled).
        return SyscallResult.ok(processes_found);
    }
    
    /// Send signal to all processes in a session.
    /// Why: Support POSIX signal delivery to sessions.
    /// Contract: sid must be valid (non-zero), signal must be valid.
    pub fn kill_session(
        self: *BasinKernel,
        sid: u64,
        signal: Signal,
    ) BasinError!SyscallResult {
        // Assert: Session ID must be valid (non-zero).
        if (sid == 0) {
            return BasinError.invalid_argument; // Invalid session ID
        }
        
        // Find all processes in the session.
        var processes_found: u32 = 0;
        var process_indices: [MAX_PROCESSES]usize = undefined;
        
        var idx: u32 = 0;
        while (idx < MAX_PROCESSES) : (idx += 1) {
            if (self.processes[idx].allocated and self.processes[idx].sid == sid) {
                process_indices[processes_found] = idx;
                processes_found += 1;
            }
        }
        
        // If no processes found in session, return error.
        if (processes_found == 0) {
            return BasinError.not_found; // Session not found or empty
        }
        
        // Send signal to all processes in the session.
        var i: u32 = 0;
        while (i < processes_found) : (i += 1) {
            const process_idx = process_indices[i];
            const process = &self.processes[process_idx];
            
            // Send signal to process.
            process.signals.send_signal(signal);
            
            // SIGKILL immediately terminates process.
            if (signal == .sigkill) {
                process.state = .exited;
                process.exit_status = 128 + @intFromEnum(signal); // Exit code = 128 + signal
                
                // Clear current process if it's the one being killed.
                if (self.scheduler.get_current() == process.id) {
                    self.scheduler.clear_current();
                    // Invalidate current process cache when process is killed.
                    // Why: Ensure cache doesn't point to killed process.
                    self.invalidate_current_process_cache();
                }
            }
        }
        
        // Return success (number of processes signaled).
        return SyscallResult.ok(processes_found);
    }

    /// Why: Set a signal handler for a specific signal.
    pub fn syscall_signal(
        self: *BasinKernel,
        signal_num: u64,
        _handler_ptr: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _handler_ptr;
        _ = _arg3;
        _ = _arg4;
        
        // Assert: Signal number must be valid (< 32).
        if (signal_num >= 32) {
            return BasinError.invalid_argument;
        }
        
        // Get current process.
        const current_pid = self.scheduler.get_current();
        if (current_pid == 0) {
            return BasinError.invalid_user; // No current process
        }
        
        // Find current process.
        var found: ?usize = null;
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == current_pid) {
                found = i;
                break;
            }
        }
        
        if (found == null) {
            return BasinError.not_found;
        }
        
        const process = &self.processes[found.?];
        const signal = @as(Signal, @enumFromInt(@as(u32, @truncate(signal_num))));
        
        // Create signal action (handler_ptr is function pointer, ignored for now).
        const action = SignalAction{
            .handler = null, // Stub: handler registration requires function pointer translation
            .context = null,
            .mask = 0,
            .flags = 0,
        };
        
        process.signals.register_handler(signal, action);
        
        // Assert: Handler must be registered (postcondition).
        Debug.kassert(process.signals.actions[@intFromEnum(signal)].handler == action.handler, "Handler not registered", .{});
        
        return SyscallResult.ok(0);
    }

    /// Why: Get or set signal action for a specific signal.
    pub fn syscall_sigaction(
        self: *BasinKernel,
        signal_num: u64,
        action_ptr: u64,
        old_action_ptr: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg4;
        
        // Assert: Signal number must be valid (< 32).
        if (signal_num >= 32) {
            return BasinError.invalid_argument;
        }
        
        // Get current process.
        const current_pid = self.scheduler.get_current();
        if (current_pid == 0) {
            return BasinError.invalid_user;
        }
        
        // Find current process.
        var found: ?usize = null;
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == current_pid) {
                found = i;
                break;
            }
        }
        
        if (found == null) {
            return BasinError.not_found;
        }
        
        const process = &self.processes[found.?];
        const signal = @as(Signal, @enumFromInt(@as(u32, @truncate(signal_num))));
        
        // Save old action if old_action_ptr is non-zero (stub: would read from VM memory).
        _ = old_action_ptr;
        
        // Set new action if action_ptr is non-zero (stub: would read from VM memory).
        if (action_ptr != 0) {
            const action = SignalAction{
                .handler = null, // Stub: requires function pointer translation
                .context = null,
                .mask = 0,
                .flags = 0,
            };
            process.signals.register_handler(signal, action);
        }
        
        return SyscallResult.ok(0);
    }
};
