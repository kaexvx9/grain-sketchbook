//! Basin Kernel Process Syscalls
//! Why: Process management syscalls (spawn, exit, wait, yield, process groups, signals).

const std = @import("std");
const Debug = @import("debug.zig");
const ProcessContext = @import("process.zig").ProcessContext;
const Signal = @import("signal.zig").Signal;
const SignalAction = @import("signal.zig").SignalAction;
const elf_parser = @import("elf_parser.zig");
const segment_loader = @import("segment_loader.zig");
const resource_cleanup = @import("resource_cleanup.zig");

const types = @import("basin_kernel_types.zig");
const BasinError = types.BasinError;
const SyscallResult = types.SyscallResult;
const Process = types.Process;
const MAX_PROCESSES = types.MAX_PROCESSES;

const core = @import("basin_kernel_core.zig");
const BasinKernel = core.BasinKernel;

const VM_MEM: u64 = 4 * 1024 * 1024;
const MIN_ELF: u64 = 64;
const STACK_PTR: u64 = 0x3ff000;

fn validate_spawn_args(exe: u64, args_ptr: u64, args_len: u64) ?BasinError {
    if (exe == 0 or exe >= VM_MEM or exe + MIN_ELF > VM_MEM) return BasinError.invalid_argument;
    if (args_ptr != 0) {
        if (args_ptr >= VM_MEM or args_len == 0 or args_len > 65536) return BasinError.invalid_argument;
        if (args_ptr + args_len > VM_MEM) return BasinError.invalid_argument;
    } else if (args_len != 0) return BasinError.invalid_argument;
    return null;
}

fn find_free_slot(self: *BasinKernel) ?usize {
    for (0..MAX_PROCESSES) |i| {
        if (!self.processes[i].allocated) return i;
    }
    return null;
}

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

fn load_segments(self: *BasinKernel, exe: u64, info: elf_parser.ElfInfo, reader: *const fn (u64, u32, []u8) ?u32) void {
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

fn check_spawn_limit(self: *BasinKernel, pgid: u64) bool {
    if (pgid == 0) return true;
    var count: u32 = 0;
    for (0..MAX_PROCESSES) |i| {
        if (self.processes[i].allocated and self.processes[i].pgid == pgid) count += 1;
    }
    return self.process_group_limits.can_spawn_process(pgid, count);
}

fn init_process(self: *BasinKernel, idx: usize, pid: u64, exe: u64, entry: u64, pgid: u64) void {
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

fn find_process_idx(self: *BasinKernel, pid: u64) ?usize {
    for (0..MAX_PROCESSES) |i| {
        if (self.processes[i].allocated and self.processes[i].id == pid) return i;
    }
    return null;
}

fn get_parent_pgid(self: *BasinKernel) u64 {
    const cur = self.scheduler.get_current();
    if (cur == 0) return 0;
    const idx = self.find_current_process_index() orelse return 0;
    return self.processes[idx].pgid;
}

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

fn mark_exited(self: *BasinKernel, idx: usize, status: u32, pid: u64) void {
    self.processes[idx].state = .exited;
    self.processes[idx].exit_status = status;
    if (self.scheduler.is_current(pid)) {
        self.scheduler.clear_current();
        self.invalidate_current_process_cache();
    }
    _ = resource_cleanup.cleanup_process_resources(self, @truncate(pid));
}

fn handle_sigkill(self: *BasinKernel, p: *Process, pid: u64) void {
    p.state = .exited;
    p.exit_status = 128 + @intFromEnum(Signal.sigkill);
    if (self.scheduler.is_current(pid)) {
        self.scheduler.clear_current();
        self.invalidate_current_process_cache();
    }
}

fn send_signal_to_idx(self: *BasinKernel, idx: usize, sig: Signal, pid: u64) void {
    const p = &self.processes[idx];
    p.signals.send_signal(sig);
    if (sig == .sigkill) handle_sigkill(self, p, pid);
}

fn count_pgid(self: *BasinKernel, pgid: u64) u32 {
    var c: u32 = 0;
    for (0..MAX_PROCESSES) |i| {
        if (self.processes[i].allocated and self.processes[i].pgid == pgid) c += 1;
    }
    return c;
}

fn find_group_members(self: *BasinKernel, pgid: u64, out: *[MAX_PROCESSES]usize) u32 {
    var n: u32 = 0;
    for (0..MAX_PROCESSES) |i| {
        if (self.processes[i].allocated and self.processes[i].pgid == pgid) {
            out[n] = i;
            n += 1;
        }
    }
    return n;
}

fn find_session_members(self: *BasinKernel, sid: u64, out: *[MAX_PROCESSES]usize) u32 {
    var n: u32 = 0;
    for (0..MAX_PROCESSES) |i| {
        if (self.processes[i].allocated and self.processes[i].sid == sid) {
            out[n] = i;
            n += 1;
        }
    }
    return n;
}

fn signal_members(self: *BasinKernel, idxs: []usize, count: u32, sig: Signal) void {
    for (0..count) |i| {
        const p = &self.processes[idxs[i]];
        p.signals.send_signal(sig);
        if (sig == .sigkill) handle_sigkill(self, p, p.id);
    }
}

/// Process syscall handlers for BasinKernel.
/// Why: Extract process syscalls to separate module.
pub const ProcessSyscalls = struct {
    /// Why: Create a new child process from an executable.
    pub fn syscall_spawn(self: *BasinKernel, exe: u64, args_ptr: u64, args_len: u64, _: u64) BasinError!SyscallResult {
        if (validate_spawn_args(exe, args_ptr, args_len)) |e| return e;
        const idx = find_free_slot(self) orelse return BasinError.out_of_memory;
        const pid = self.next_process_id;
        self.next_process_id += 1;
        const elf = parse_elf_entry(self, exe);
        const pgid = get_parent_pgid(self);
        if (!check_spawn_limit(self, pgid)) return BasinError.resource_exhausted;
        init_process(self, idx, pid, exe, elf.entry, pgid);
        self.scheduler.set_current(pid, self.processes[idx].time_slice_quantum);
        self.current_process_index = @as(u32, @intCast(idx));
        return SyscallResult.ok(pid);
    }

    /// Why: Terminate the current process with an exit status.
    pub fn syscall_exit(self: *BasinKernel, status: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
        Debug.kassert(status <= 255, "Exit status > 255", .{});
        const pid = self.scheduler.get_current();
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == pid) {
                update_pgid_on_exit(self, self.processes[i].pgid);
                mark_exited(self, i, @as(u32, @truncate(status)), pid);
                break;
            }
        }
        return SyscallResult.ok(status);
    }

    /// Why: Voluntarily give up CPU.
    pub fn syscall_yield(_: *BasinKernel, _: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
        return SyscallResult.ok(0);
    }

    /// Why: Wait for a child process to terminate.
    pub fn syscall_wait(self: *BasinKernel, pid: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
        if (pid == 0) return BasinError.invalid_argument;
        const idx = find_process_idx(self, pid) orelse return BasinError.not_found;
        if (self.processes[idx].state == .exited) return SyscallResult.ok(self.processes[idx].exit_status);
        return BasinError.would_block;
    }

    /// Why: Set the process group ID for a process.
    pub fn syscall_setpgid(self: *BasinKernel, pid: u64, pgid: u64, _: u64, _: u64) BasinError!SyscallResult {
        if (pid == 0 or pgid == 0) return BasinError.invalid_argument;
        const idx = find_process_idx(self, pid) orelse return BasinError.not_found;
        self.processes[idx].pgid = pgid;
        self.process_group_stats.update_process_count(pgid, count_pgid(self, pgid));
        return SyscallResult.ok(0);
    }

    /// Why: Get the process group ID for a process.
    pub fn syscall_getpgid(self: *BasinKernel, pid: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
        if (pid == 0) return BasinError.invalid_argument;
        const idx = find_process_idx(self, pid) orelse return BasinError.not_found;
        return SyscallResult.ok(self.processes[idx].pgid);
    }

    /// Why: Create a new session.
    pub fn syscall_setsid(self: *BasinKernel, _: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
        const pid = self.scheduler.get_current();
        if (pid == 0) return BasinError.invalid_argument;
        const sid = self.process_group_manager.create_session(pid);
        if (sid == 0) return BasinError.resource_exhausted;
        const idx = find_process_idx(self, pid) orelse return BasinError.not_found;
        self.processes[idx].sid = sid;
        const pgid = self.process_group_manager.create_group(pid, sid, &self.processes, MAX_PROCESSES);
        if (pgid == 0) return BasinError.resource_exhausted;
        return SyscallResult.ok(sid);
    }

    /// Why: Get the session ID for a process.
    pub fn syscall_getsid(self: *BasinKernel, pid: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
        if (pid == 0) return BasinError.invalid_argument;
        const idx = find_process_idx(self, pid) orelse return BasinError.not_found;
        return SyscallResult.ok(self.processes[idx].sid);
    }

    /// Why: Send a signal to a process or process group.
    pub fn syscall_kill(self: *BasinKernel, pid: u64, sig_num: u64, _: u64, _: u64) BasinError!SyscallResult {
        if (sig_num >= 32) return BasinError.invalid_argument;
        const sig = @as(Signal, @enumFromInt(@as(u32, @truncate(sig_num))));
        if ((pid & 0x8000000000000000) != 0) {
            const pgid = pid & 0x7FFFFFFFFFFFFFFF;
            if (pgid == 0) return BasinError.invalid_argument;
            return kill_process_group(self, pgid, sig);
        }
        if ((pid & 0x4000000000000000) != 0) {
            const sid = pid & 0x3FFFFFFFFFFFFFFF;
            if (sid == 0) return BasinError.invalid_argument;
            return kill_session(self, sid, sig);
        }
        if (pid == 0) return BasinError.invalid_argument;
        const idx = find_process_idx(self, pid) orelse return BasinError.not_found;
        send_signal_to_idx(self, idx, sig, pid);
        return SyscallResult.ok(0);
    }

    /// Why: Send signal to all processes in a process group.
    pub fn kill_process_group(self: *BasinKernel, pgid: u64, sig: Signal) BasinError!SyscallResult {
        if (pgid == 0) return BasinError.invalid_argument;
        var idxs: [MAX_PROCESSES]usize = undefined;
        const n = find_group_members(self, pgid, &idxs);
        if (n == 0) return BasinError.not_found;
        signal_members(self, idxs[0..n], n, sig);
        return SyscallResult.ok(n);
    }

    /// Why: Send signal to all processes in a session.
    pub fn kill_session(self: *BasinKernel, sid: u64, sig: Signal) BasinError!SyscallResult {
        if (sid == 0) return BasinError.invalid_argument;
        var idxs: [MAX_PROCESSES]usize = undefined;
        const n = find_session_members(self, sid, &idxs);
        if (n == 0) return BasinError.not_found;
        signal_members(self, idxs[0..n], n, sig);
        return SyscallResult.ok(n);
    }

    /// Why: Set a signal handler for a specific signal.
    pub fn syscall_signal(self: *BasinKernel, sig_num: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
        if (sig_num >= 32) return BasinError.invalid_argument;
        const pid = self.scheduler.get_current();
        if (pid == 0) return BasinError.invalid_user;
        const idx = find_process_idx(self, pid) orelse return BasinError.not_found;
        const sig = @as(Signal, @enumFromInt(@as(u32, @truncate(sig_num))));
        const action = SignalAction{ .handler = null, .context = null, .mask = 0, .flags = 0 };
        self.processes[idx].signals.register_handler(sig, action);
        return SyscallResult.ok(0);
    }

    /// Why: Get or set signal action for a specific signal.
    pub fn syscall_sigaction(self: *BasinKernel, sig_num: u64, act_ptr: u64, _: u64, _: u64) BasinError!SyscallResult {
        if (sig_num >= 32) return BasinError.invalid_argument;
        const pid = self.scheduler.get_current();
        if (pid == 0) return BasinError.invalid_user;
        const idx = find_process_idx(self, pid) orelse return BasinError.not_found;
        if (act_ptr != 0) {
            const sig = @as(Signal, @enumFromInt(@as(u32, @truncate(sig_num))));
            const action = SignalAction{ .handler = null, .context = null, .mask = 0, .flags = 0 };
            self.processes[idx].signals.register_handler(sig, action);
        }
        return SyscallResult.ok(0);
    }
};
