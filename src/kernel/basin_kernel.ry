//! Basin kernel — The container where everything flows
//! Why: Central syscall dispatch and memory/channel/timing syscalls.

const std = @import("std");
pub const Debug = @import("debug.zig");
pub const Timer = @import("timer.zig").Timer;
const InterruptController = @import("interrupt.zig").InterruptController;
pub const Scheduler = @import("scheduler.zig").Scheduler;
pub const ChannelTable = @import("channel.zig").ChannelTable;
const ProcessContext = @import("process.zig").ProcessContext;
const Storage = @import("storage.zig").Storage;
const Keyboard = @import("keyboard.zig").Keyboard;
const Mouse = @import("mouse.zig").Mouse;
pub const MemoryPool = @import("memory.zig").MemoryPool;
const SignalTable = @import("signal.zig").SignalTable;
const Signal = @import("signal.zig").Signal;
const SignalAction = @import("signal.zig").SignalAction;
const elf_parser = @import("elf_parser.zig");
const segment_loader = @import("segment_loader.zig");
const page_table = @import("page_table.zig");
const PageTable = page_table.PageTable;
const page_fault_stats = @import("page_fault_stats.zig");
const PageFaultStats = page_fault_stats.PageFaultStats;
const memory_stats = @import("memory_stats.zig");
const MemoryStats = memory_stats.MemoryStats;
const cow = @import("cow.zig");
const CowTable = cow.CowTable;
const resource_cleanup = @import("resource_cleanup.zig");
const KernelLogBuffer = @import("kernel_log_buffer.zig").KernelLogBuffer;
const KernelLogEntry = @import("kernel_log_buffer.zig").KernelLogEntry;
const KernelLogLevel = @import("kernel_log_buffer.zig").KernelLogLevel;
const scheduler_stats = @import("scheduler_stats.zig");
const process_group = @import("process_group.zig");
const ProcessGroupManager = process_group.ProcessGroupManager;
const process_group_stats = @import("process_group_stats.zig");
const ProcessGroupStatsManager = process_group_stats.ProcessGroupStatsManager;
const process_group_limits = @import("process_group_limits.zig");
const ProcessGroupLimitsManager = process_group_limits.ProcessGroupLimitsManager;
const network = @import("network.zig");
const NetworkInterfaceManager = network.NetworkInterfaceManager;
const tcp_socket = @import("tcp_socket.zig");
const TcpSocketManager = tcp_socket.TcpSocketManager;
const udp_socket = @import("udp_socket.zig");
const UdpSocketManager = udp_socket.UdpSocketManager;
const audio = @import("audio.zig");
const AudioDeviceManager = audio.AudioDeviceManager;
const kernel_stats_aggregator = @import("kernel_stats_aggregator.zig");
const KernelStatsSnapshot = kernel_stats_aggregator.KernelStatsSnapshot;

const types = @import("basin_kernel_types.zig");
const core = @import("basin_kernel_core.zig");
const process_syscalls = @import("basin_kernel_syscalls_process.zig");
const ProcessSyscalls = process_syscalls.ProcessSyscalls;
const file_syscalls = @import("basin_kernel_syscalls_file.zig");
const FileSyscalls = file_syscalls.FileSyscalls;
const network_syscalls = @import("basin_kernel_syscalls_network.zig");
const NetworkSyscalls = network_syscalls.NetworkSyscalls;
const audio_syscalls = @import("basin_kernel_syscalls_audio.zig");
const AudioSyscalls = audio_syscalls.AudioSyscalls;
const stats_syscalls = @import("basin_kernel_syscalls_stats.zig");
const StatsSyscalls = stats_syscalls.StatsSyscalls;

pub const Syscall = types.Syscall;
pub const MapFlags = types.MapFlags;
pub const OpenFlags = types.OpenFlags;
pub const ClockId = types.ClockId;
pub const Handle = types.Handle;
pub const SysInfo = types.SysInfo;
pub const ProcessInfo = types.ProcessInfo;
pub const ResourceUsage = types.ResourceUsage;
pub const UserId = types.UserId;
pub const GroupId = types.GroupId;
pub const User = types.User;
pub const UserContext = types.UserContext;
pub const BasinError = types.BasinError;
pub const SyscallResult = types.SyscallResult;
pub const ProcessState = types.ProcessState;
pub const Process = types.Process;

const MemoryMapping = types.MemoryMapping;
const FileHandle = types.FileHandle;
const DirectoryHandle = types.DirectoryHandle;
const MAX_MAPPINGS = types.MAX_MAPPINGS;
const MAX_HANDLES = types.MAX_HANDLES;
const MAX_DIR_HANDLES = types.MAX_DIR_HANDLES;
const MAX_PROCESSES = types.MAX_PROCESSES;
const MAX_USERS = types.MAX_USERS;

pub const resource_cleanup_module = resource_cleanup;
pub const RawIO = @import("uart.zig");
pub const syscall_performance_profiler = @import("syscall_performance_profiler.zig");
pub const PAGE_SIZE = @import("memory.zig").PAGE_SIZE;
pub const MAX_PAGES = @import("memory.zig").MAX_PAGES;
pub const Channel = @import("channel.zig").Channel;
pub const MAX_MESSAGE_SIZE = @import("channel.zig").MAX_MESSAGE_SIZE;
pub const MAX_MESSAGES = @import("channel.zig").MAX_MESSAGES;

comptime {
    std.debug.assert(MAX_HANDLES > 0);
    std.debug.assert(MAX_HANDLES <= 0xFFFFFFFF);
    std.debug.assert(MAX_HANDLES < 0xFFFFFFFF);
}

pub const BasinKernel = core.BasinKernel;

const VM_MEM: u64 = 4 * 1024 * 1024;
const USER_START: u64 = 0x100000;

fn decode_syscall(num: u32) ?Syscall {
    if (num < 1 or num > @intFromEnum(Syscall.set_resource_limit)) return null;
    return std.meta.intToEnum(Syscall, num) catch return null;
}

fn record_profile(self: *BasinKernel, num: u32, start: u64) void {
    if (!self.syscall_profiler.enabled or start == 0) return;
    const end = self.timer.get_monotonic_ns();
    const elapsed = if (end >= start) end - start else 1;
    self.syscall_profiler.record_syscall(num, elapsed);
}

/// Why: Central syscall entry point, validate and dispatch.
pub fn handle_syscall(self: *BasinKernel, num: u32, a1: u64, a2: u64, a3: u64, a4: u64) BasinError!SyscallResult {
    const syscall = decode_syscall(num) orelse return BasinError.invalid_syscall;
    const start = if (self.syscall_profiler.enabled) self.timer.get_monotonic_ns() else 0;
    const result = dispatch_syscall(self, syscall, a1, a2, a3, a4);
    record_profile(self, num, start);
    return result;
}

fn dispatch_core(self: *BasinKernel, s: Syscall, a1: u64, a2: u64, a3: u64, a4: u64) ?BasinError!SyscallResult {
    return switch (s) {
        .spawn => ProcessSyscalls.syscall_spawn(self, a1, a2, a3, a4),
        .exit => ProcessSyscalls.syscall_exit(self, a1, a2, a3, a4),
        .yield => ProcessSyscalls.syscall_yield(self, a1, a2, a3, a4),
        .wait => ProcessSyscalls.syscall_wait(self, a1, a2, a3, a4),
        .map => syscall_map(self, a1, a2, a3, a4),
        .unmap => syscall_unmap(self, a1, a2, a3, a4),
        .protect => syscall_protect(self, a1, a2, a3, a4),
        .channel_create => syscall_channel_create(self, a1, a2, a3, a4),
        .channel_send => syscall_channel_send(self, a1, a2, a3, a4),
        .channel_recv => syscall_channel_recv(self, a1, a2, a3, a4),
        .open => FileSyscalls.syscall_open(self, a1, a2, a3, a4),
        .read => FileSyscalls.syscall_read(self, a1, a2, a3, a4),
        .write => FileSyscalls.syscall_write(self, a1, a2, a3, a4),
        .close => FileSyscalls.syscall_close(self, a1, a2, a3, a4),
        .unlink => FileSyscalls.syscall_unlink(self, a1, a2, a3, a4),
        .rename => FileSyscalls.syscall_rename(self, a1, a2, a3, a4),
        .mkdir => FileSyscalls.syscall_mkdir(self, a1, a2, a3, a4),
        .opendir => FileSyscalls.syscall_opendir(self, a1, a2, a3, a4),
        .readdir => FileSyscalls.syscall_readdir(self, a1, a2, a3, a4),
        .closedir => FileSyscalls.syscall_closedir(self, a1, a2, a3, a4),
        .clock_gettime => syscall_clock_gettime(self, a1, a2, a3, a4),
        .sleep_until => syscall_sleep_until(self, a1, a2, a3, a4),
        .sysinfo => syscall_sysinfo(self, a1, a2, a3, a4),
        .enumerate_processes => syscall_enumerate_processes(self, a1, a2, a3, a4),
        .get_process_info => syscall_get_process_info(self, a1, a2, a3, a4),
        .read_kernel_log => syscall_read_kernel_log(self, a1, a2, a3, a4),
        .set_priority => syscall_set_priority(self, a1, a2, a3, a4),
        .get_priority => syscall_get_priority(self, a1, a2, a3, a4),
        .setpgid => ProcessSyscalls.syscall_setpgid(self, a1, a2, a3, a4),
        .getpgid => ProcessSyscalls.syscall_getpgid(self, a1, a2, a3, a4),
        .setsid => ProcessSyscalls.syscall_setsid(self, a1, a2, a3, a4),
        .getsid => ProcessSyscalls.syscall_getsid(self, a1, a2, a3, a4),
        .read_input_event => syscall_read_input_event(self, a1, a2, a3, a4),
        .fb_clear => syscall_fb_clear(self, a1, a2, a3, a4),
        .fb_draw_pixel => syscall_fb_draw_pixel(self, a1, a2, a3, a4),
        .fb_draw_text => syscall_fb_draw_text(self, a1, a2, a3, a4),
        .kill => ProcessSyscalls.syscall_kill(self, a1, a2, a3, a4),
        .signal => ProcessSyscalls.syscall_signal(self, a1, a2, a3, a4),
        .sigaction => ProcessSyscalls.syscall_sigaction(self, a1, a2, a3, a4),
        else => null,
    };
}

fn dispatch_net(self: *BasinKernel, s: Syscall, a1: u64, a2: u64, a3: u64, a4: u64) ?BasinError!SyscallResult {
    return switch (s) {
        .network_create_interface => NetworkSyscalls.syscall_network_create_interface(self, a1, a2, a3, a4),
        .network_set_state => NetworkSyscalls.syscall_network_set_state(self, a1, a2, a3, a4),
        .network_set_ipv4 => NetworkSyscalls.syscall_network_set_ipv4(self, a1, a2, a3, a4),
        .network_set_ipv6 => NetworkSyscalls.syscall_network_set_ipv6(self, a1, a2, a3, a4),
        .network_get_interface => NetworkSyscalls.syscall_network_get_interface(self, a1, a2, a3, a4),
        .network_delete_interface => NetworkSyscalls.syscall_network_delete_interface(self, a1, a2, a3, a4),
        .network_enumerate_interfaces => NetworkSyscalls.syscall_network_enumerate_interfaces(self, a1, a2, a3, a4),
        .network_get_stats => NetworkSyscalls.syscall_network_get_stats(self, a1, a2, a3, a4),
        .tcp_socket => NetworkSyscalls.syscall_tcp_socket(self, a1, a2, a3, a4),
        .tcp_bind => NetworkSyscalls.syscall_tcp_bind(self, a1, a2, a3, a4),
        .tcp_listen => NetworkSyscalls.syscall_tcp_listen(self, a1, a2, a3, a4),
        .tcp_accept => NetworkSyscalls.syscall_tcp_accept(self, a1, a2, a3, a4),
        .tcp_connect => NetworkSyscalls.syscall_tcp_connect(self, a1, a2, a3, a4),
        .tcp_send => NetworkSyscalls.syscall_tcp_send(self, a1, a2, a3, a4),
        .tcp_recv => NetworkSyscalls.syscall_tcp_recv(self, a1, a2, a3, a4),
        .tcp_close => NetworkSyscalls.syscall_tcp_close(self, a1, a2, a3, a4),
        .tcp_enumerate_sockets => NetworkSyscalls.syscall_tcp_enumerate_sockets(self, a1, a2, a3, a4),
        .tcp_get_stats => NetworkSyscalls.syscall_tcp_get_stats(self, a1, a2, a3, a4),
        .udp_socket => NetworkSyscalls.syscall_udp_socket(self, a1, a2, a3, a4),
        .udp_bind => NetworkSyscalls.syscall_udp_bind(self, a1, a2, a3, a4),
        .udp_sendto => NetworkSyscalls.syscall_udp_sendto(self, a1, a2, a3, a4),
        .udp_recvfrom => NetworkSyscalls.syscall_udp_recvfrom(self, a1, a2, a3, a4),
        .udp_close => NetworkSyscalls.syscall_udp_close(self, a1, a2, a3, a4),
        .udp_enumerate_sockets => NetworkSyscalls.syscall_udp_enumerate_sockets(self, a1, a2, a3, a4),
        .udp_get_stats => NetworkSyscalls.syscall_udp_get_stats(self, a1, a2, a3, a4),
        .udp_sendto_with_timeout => NetworkSyscalls.syscall_udp_sendto_with_timeout(self, a1, a2, a3, a4),
        .udp_recvfrom_with_timeout => NetworkSyscalls.syscall_udp_recvfrom_with_timeout(self, a1, a2, a3, a4),
        else => null,
    };
}

fn dispatch_audio(self: *BasinKernel, s: Syscall, a1: u64, a2: u64, a3: u64, a4: u64) ?BasinError!SyscallResult {
    return switch (s) {
        .audio_create_device => AudioSyscalls.syscall_audio_create_device(self, a1, a2, a3, a4),
        .audio_set_volume => AudioSyscalls.syscall_audio_set_volume(self, a1, a2, a3, a4),
        .audio_set_mute => AudioSyscalls.syscall_audio_set_mute(self, a1, a2, a3, a4),
        .audio_set_state => AudioSyscalls.syscall_audio_set_state(self, a1, a2, a3, a4),
        .audio_set_active_output => AudioSyscalls.syscall_audio_set_active_output(self, a1, a2, a3, a4),
        .audio_set_active_input => AudioSyscalls.syscall_audio_set_active_input(self, a1, a2, a3, a4),
        .audio_set_master_volume => AudioSyscalls.syscall_audio_set_master_volume(self, a1, a2, a3, a4),
        .audio_set_master_mute => AudioSyscalls.syscall_audio_set_master_mute(self, a1, a2, a3, a4),
        .audio_get_device => AudioSyscalls.syscall_audio_get_device(self, a1, a2, a3, a4),
        .audio_set_format => AudioSyscalls.syscall_audio_set_format(self, a1, a2, a3, a4),
        .audio_read => AudioSyscalls.syscall_audio_read(self, a1, a2, a3, a4),
        .audio_write => AudioSyscalls.syscall_audio_write(self, a1, a2, a3, a4),
        .audio_enumerate_devices => AudioSyscalls.syscall_audio_enumerate_devices(self, a1, a2, a3, a4),
        .audio_delete_device => AudioSyscalls.syscall_audio_delete_device(self, a1, a2, a3, a4),
        .audio_get_stats => AudioSyscalls.syscall_audio_get_stats(self, a1, a2, a3, a4),
        .kernel_get_stats => StatsSyscalls.syscall_kernel_get_stats(self, a1, a2, a3, a4),
        .health_check => StatsSyscalls.syscall_health_check(self, a1, a2, a3, a4),
        .get_resource_usage => StatsSyscalls.syscall_get_resource_usage(self, a1, a2, a3, a4),
        .set_resource_limit => StatsSyscalls.syscall_set_resource_limit(self, a1, a2, a3, a4),
        else => null,
    };
}

fn dispatch_syscall(self: *BasinKernel, s: Syscall, a1: u64, a2: u64, a3: u64, a4: u64) BasinError!SyscallResult {
    if (dispatch_core(self, s, a1, a2, a3, a4)) |r| return r;
    if (dispatch_net(self, s, a1, a2, a3, a4)) |r| return r;
    if (dispatch_audio(self, s, a1, a2, a3, a4)) |r| return r;
    return BasinError.invalid_syscall;
}

fn validate_map_args(size: u64, flags: u64) BasinError!MapFlags {
    if (size == 0 or size % 4096 != 0) return BasinError.invalid_argument;
    if (size > VM_MEM) return BasinError.out_of_memory;
    const mf = @as(MapFlags, @bitCast(@as(u32, @truncate(flags))));
    if (!mf.read and !mf.write and !mf.execute) return BasinError.invalid_argument;
    if (mf._padding != 0) return BasinError.invalid_argument;
    return mf;
}

fn resolve_map_addr(self: *BasinKernel, addr: u64, size: u64) BasinError!u64 {
    if (addr == 0) {
        const a = self.next_alloc_addr;
        if (a + size > VM_MEM) return BasinError.out_of_memory;
        return a;
    }
    if (addr % 4096 != 0) return BasinError.unaligned_access;
    if (addr < USER_START) return BasinError.permission_denied;
    if (addr + size > VM_MEM) return BasinError.out_of_memory;
    return addr;
}

fn get_process_pgid(self: *BasinKernel, pid: u64) ?u64 {
    for (0..MAX_PROCESSES) |i| {
        if (self.processes[i].allocated and self.processes[i].id == pid) return self.processes[i].pgid;
    }
    return null;
}

fn sum_group_memory(self: *BasinKernel, pgid: u64) u64 {
    var total: u64 = 0;
    for (0..MAX_PROCESSES) |i| {
        if (self.processes[i].allocated and self.processes[i].pgid == pgid) total +%= self.processes[i].memory_used;
    }
    return total;
}

fn check_group_memory_limit(self: *BasinKernel, size: u64) BasinError!bool {
    const pid = self.scheduler.get_current();
    if (pid == 0) return false;
    const pgid = get_process_pgid(self, pid) orelse return false;
    const usage = sum_group_memory(self, pgid);
    return !self.process_group_limits.can_allocate_memory(pgid, usage, size);
}

fn commit_mapping(self: *BasinKernel, idx: usize, addr: u64, size: u64, flags: MapFlags, owner: u32) void {
    var m = &self.mappings[idx];
    m.address = addr;
    m.size = size;
    m.flags = flags;
    m.allocated = true;
    m.owner_process_id = owner;
    self.add_mapping_to_hash_table(addr, @as(u32, @intCast(idx)));
    const pf = page_table.PageFlags{
        .read = flags.read, .write = flags.write, .execute = flags.execute, .shared = flags.shared, ._padding = 0,
    };
    self.page_table.map_pages(addr, size, pf);
    self.memory_stats.update_from_page_table(@ptrCast(&self.page_table), VM_MEM);
    self.memory_stats.update_mapping_count(self.count_allocated_mappings());
    if (owner > 0) self.update_process_memory_usage(@as(u64, owner));
}

/// Why: Map memory region for process address space.
pub fn syscall_map(self: *BasinKernel, addr: u64, size: u64, flags: u64, _: u64) BasinError!SyscallResult {
    const mf = try validate_map_args(size, flags);
    const mapping_addr = try resolve_map_addr(self, addr, size);
    if (self.check_overlap(mapping_addr, size)) return BasinError.invalid_argument;
    if (try check_group_memory_limit(self, size)) return BasinError.resource_exhausted;
    const idx = self.find_free_mapping() orelse return BasinError.out_of_memory;
    const owner = @as(u32, @truncate(self.scheduler.get_current()));
    commit_mapping(self, idx, mapping_addr, size, mf, owner);
    if (addr == 0) self.next_alloc_addr = mapping_addr + size;
    return SyscallResult.ok(mapping_addr);
}

fn validate_unmap_region(region: u64) ?BasinError {
    if (region % 4096 != 0) return BasinError.unaligned_access;
    if (region < USER_START) return BasinError.permission_denied;
    if (region >= VM_MEM) return BasinError.invalid_argument;
    return null;
}

fn clear_mapping(mapping: *MemoryMapping) void {
    mapping.allocated = false;
    mapping.address = 0;
    mapping.size = 0;
    mapping.owner_process_id = 0;
    mapping.flags = MapFlags.init(.{});
}

fn syscall_unmap(self: *BasinKernel, region: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
    if (validate_unmap_region(region)) |err| return err;
    const idx = self.find_mapping_by_address(region) orelse return BasinError.invalid_argument;
    Debug.kassert(self.mappings[idx].allocated, "Mapping not allocated", .{});
    const mapping = &self.mappings[idx];
    const size = mapping.size;
    const owner = mapping.owner_process_id;
    self.remove_mapping_from_hash_table(region);
    clear_mapping(mapping);
    self.page_table.unmap_pages(region, size);
    self.memory_stats.update_from_page_table(@ptrCast(&self.page_table), VM_MEM);
    self.memory_stats.update_mapping_count(self.count_allocated_mappings());
    if (owner > 0) self.update_process_memory_usage(@as(u64, owner));
    return SyscallResult.ok(0);
}

fn validate_protect_flags(flags: u64) ?MapFlags {
    const mf = @as(MapFlags, @bitCast(@as(u32, @truncate(flags))));
    if (!mf.read and !mf.write and !mf.execute) return null;
    if (mf._padding != 0) return null;
    return mf;
}

fn map_to_page_flags(mf: MapFlags) page_table.PageFlags {
    return .{ .read = mf.read, .write = mf.write, .execute = mf.execute, .shared = mf.shared, ._padding = 0 };
}

fn syscall_protect(self: *BasinKernel, region: u64, flags: u64, _: u64, _: u64) BasinError!SyscallResult {
    if (validate_unmap_region(region)) |err| return err;
    const mf = validate_protect_flags(flags) orelse return BasinError.invalid_argument;
    const idx = self.find_mapping_by_address(region) orelse return BasinError.invalid_argument;
    Debug.kassert(self.mappings[idx].allocated, "Mapping not allocated", .{});
    const mapping = &self.mappings[idx];
    const size = mapping.size;
    mapping.flags = mf;
    self.page_table.protect_pages(region, size, map_to_page_flags(mf));
    self.memory_stats.update_from_page_table(@ptrCast(&self.page_table), VM_MEM);
    return SyscallResult.ok(0);
}

fn syscall_channel_create(self: *BasinKernel, _: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
    const owner = @as(u32, @truncate(self.scheduler.get_current()));
    const id = self.channels.create();
    if (id == 0) return BasinError.out_of_memory;
    if (self.channels.find(id)) |ch| ch.owner_process_id = owner;
    return SyscallResult.ok(id);
}

fn validate_channel_buffer(ch_id: u64, ptr: u64, len: u64) ?BasinError {
    const MAX_MSG: u64 = 4096;
    if (ch_id == 0) return BasinError.invalid_argument;
    if (ptr == 0 or ptr >= VM_MEM) return BasinError.invalid_argument;
    if (len == 0 or len > MAX_MSG) return BasinError.invalid_argument;
    if (ptr + len > VM_MEM) return BasinError.invalid_argument;
    return null;
}

fn syscall_channel_send(self: *BasinKernel, ch: u64, ptr: u64, len: u64, timeout: u64) BasinError!SyscallResult {
    if (validate_channel_buffer(ch, ptr, len)) |err| return err;
    const start = self.timer.get_monotonic_ns();
    const channel = self.channels.find(ch) orelse return BasinError.not_found;
    if (self.check_timeout(start, timeout)) return BasinError.ipc_timeout;
    const reader = self.vm_memory_reader orelse return BasinError.invalid_syscall;
    const len32 = @as(u32, @truncate(len));
    var buf: [4096]u8 = undefined;
    const slice = buf[0..len32];
    const read = reader(ptr, len32, slice) orelse return BasinError.invalid_argument;
    if (read != len32) return BasinError.invalid_argument;
    if (!channel.send(slice)) {
        if (self.check_timeout(start, timeout)) return BasinError.ipc_timeout;
        return BasinError.would_block;
    }
    if (self.check_timeout(start, timeout)) return BasinError.ipc_timeout;
    return SyscallResult.ok(0);
}

fn syscall_channel_recv(self: *BasinKernel, ch: u64, ptr: u64, len: u64, timeout: u64) BasinError!SyscallResult {
    if (validate_channel_buffer(ch, ptr, len)) |err| return err;
    const start = self.timer.get_monotonic_ns();
    const channel = self.channels.find(ch) orelse return BasinError.not_found;
    if (self.check_timeout(start, timeout)) return BasinError.ipc_timeout;
    var msg_buf: [4096]u8 = undefined;
    const recv_len = channel.receive(&msg_buf);
    if (recv_len == 0) {
        if (self.check_timeout(start, timeout)) return BasinError.ipc_timeout;
        return BasinError.would_block;
    }
    if (self.check_timeout(start, timeout)) return BasinError.ipc_timeout;
    const writer = self.vm_memory_writer orelse return BasinError.invalid_syscall;
    const to_write = @min(recv_len, @as(u32, @truncate(len)));
    const written = writer(ptr, to_write, msg_buf[0..to_write]) orelse return BasinError.invalid_argument;
    if (written != to_write) return BasinError.invalid_argument;
    return SyscallResult.ok(@as(u64, written));
}

fn validate_vm_ptr(ptr: u64, size: u64) ?BasinError {
    if (ptr == 0 or ptr >= VM_MEM) return BasinError.invalid_argument;
    if (ptr + size > VM_MEM) return BasinError.invalid_argument;
    return null;
}

fn syscall_clock_gettime(self: *BasinKernel, clock_id: u64, ptr: u64, _: u64, _: u64) BasinError!SyscallResult {
    _ = self;
    const clock = @as(?ClockId, @enumFromInt(@as(u32, @truncate(clock_id)))) orelse return BasinError.invalid_argument;
    Debug.kassert(clock == .monotonic or clock == .realtime, "Invalid clock", .{});
    if (validate_vm_ptr(ptr, 16)) |err| return err;
    return BasinError.invalid_syscall;
}

fn syscall_sleep_until(self: *BasinKernel, ts: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
    if (ts == 0) return BasinError.invalid_argument;
    const now = self.timer.get_monotonic_ns();
    if (ts < now) return BasinError.invalid_argument;
    return SyscallResult.ok(0);
}

fn get_memory_stats(self: *BasinKernel) struct { total: u64, available: u64 } {
    const total: u64 = VM_MEM;
    const alloc = self.memory_pool.allocated_pages;
    const avail_pages: u32 = if (alloc > 1024) 0 else 1024 - alloc;
    return .{ .total = total, .available = @as(u64, avail_pages) * 4096 };
}

fn count_processes(self: *BasinKernel) struct { total: u32, running: u32 } {
    var total: u32 = 0;
    var running: u32 = 0;
    for (0..MAX_PROCESSES) |i| {
        if (self.processes[i].allocated) {
            total += 1;
            if (self.processes[i].state == .running) running += 1;
        }
    }
    return .{ .total = total, .running = running };
}

fn syscall_sysinfo(self: *BasinKernel, info_ptr: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
    if (validate_vm_ptr(info_ptr, 56)) |err| return err;
    _ = get_memory_stats(self);
    _ = count_processes(self);
    _ = self.timer.get_uptime_ns();
    return SyscallResult.ok(0);
}

fn find_proc_idx(self: *BasinKernel, pid: u64) ?usize {
    for (0..MAX_PROCESSES) |i| {
        if (self.processes[i].allocated and self.processes[i].id == pid) return i;
    }
    return null;
}

fn syscall_enumerate_processes(self: *BasinKernel, buf_ptr: u64, buf_len: u64, max: u64, _: u64) BasinError!SyscallResult {
    if (validate_vm_ptr(buf_ptr, 32)) |err| return err;
    if (buf_len < 32) return BasinError.invalid_argument;
    const limit = if (max > 0 and max < MAX_PROCESSES) max else MAX_PROCESSES;
    const max_fit = buf_len / 32;
    const count = @min(limit, max_fit);
    var written: u32 = 0;
    for (0..MAX_PROCESSES) |i| {
        if (written >= count) break;
        if (self.processes[i].allocated) written += 1;
    }
    return SyscallResult.ok(@intCast(written));
}

fn syscall_get_process_info(self: *BasinKernel, pid: u64, ptr: u64, _: u64, _: u64) BasinError!SyscallResult {
    if (pid == 0) return BasinError.invalid_argument;
    if (validate_vm_ptr(ptr, 32)) |err| return err;
    if (find_proc_idx(self, pid) == null) return BasinError.not_found;
    self.update_process_memory_usage(pid);
    return SyscallResult.ok(0);
}

fn syscall_read_kernel_log(self: *BasinKernel, buf_ptr: u64, buf_len: u64, max: u64, _: u64) BasinError!SyscallResult {
    const entry_size: u64 = @sizeOf(KernelLogEntry);
    if (validate_vm_ptr(buf_ptr, entry_size)) |err| return err;
    if (buf_len < entry_size) return BasinError.invalid_argument;
    const entry_count = self.log_buffer.get_entry_count();
    const limit = if (max > 0 and max < 256) max else 256;
    const max_fit = buf_len / entry_size;
    const count = @min(limit, max_fit);
    const actual = @min(count, entry_count);
    var written: u32 = 0;
    for (0..actual) |i| {
        if (self.log_buffer.get_entry(@intCast(i))) |_| written += 1;
    }
    return SyscallResult.ok(@intCast(written));
}

fn syscall_set_priority(self: *BasinKernel, pid: u64, priority: u64, _: u64, _: u64) BasinError!SyscallResult {
    if (pid == 0) return BasinError.invalid_argument;
    if (priority < 20 or priority > 59) return BasinError.invalid_argument;
    const idx = find_proc_idx(self, pid) orelse return BasinError.not_found;
    const priority_i8 = @as(i8, @intCast(@as(i64, @intCast(priority)) - 20));
    self.processes[idx].priority = priority_i8;
    return SyscallResult.ok(0);
}

fn syscall_get_priority(self: *BasinKernel, pid: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
    if (pid == 0) return BasinError.invalid_argument;
    const idx = find_proc_idx(self, pid) orelse return BasinError.not_found;
    const priority_u64 = @as(u64, @intCast(@as(i32, self.processes[idx].priority) + 20));
    return SyscallResult.ok(priority_u64);
}

fn syscall_read_input_event(_: *BasinKernel, event_buf: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
    if (event_buf == 0) return BasinError.invalid_argument;
    return BasinError.invalid_syscall;
}

fn syscall_fb_clear(_: *BasinKernel, color: u64, _: u64, _: u64, _: u64) BasinError!SyscallResult {
    if (color > 0xFFFFFFFF) return BasinError.invalid_argument;
    return BasinError.invalid_syscall;
}

fn syscall_fb_draw_pixel(_: *BasinKernel, x: u64, y: u64, color: u64, _: u64) BasinError!SyscallResult {
    if (x > 0xFFFFFFFF or y > 0xFFFFFFFF or color > 0xFFFFFFFF) return BasinError.invalid_argument;
    return BasinError.invalid_syscall;
}

fn syscall_fb_draw_text(_: *BasinKernel, text_ptr: u64, x: u64, y: u64, color: u64) BasinError!SyscallResult {
    if (text_ptr == 0) return BasinError.invalid_argument;
    if (x > 0xFFFFFFFF or y > 0xFFFFFFFF or color > 0xFFFFFFFF) return BasinError.invalid_argument;
    return BasinError.invalid_syscall;
}

/// Why: Explicit exports for backward compatibility.
pub const harbor_kernel = struct {
    pub const Syscall = @import("basin_kernel.zig").Syscall;
    pub const handle_syscall = @import("basin_kernel.zig").handle_syscall;
    pub const MapFlags = @import("basin_kernel.zig").MapFlags;
    pub const OpenFlags = @import("basin_kernel.zig").OpenFlags;
    pub const ClockId = @import("basin_kernel.zig").ClockId;
    pub const Handle = @import("basin_kernel.zig").Handle;
    pub const Signal = @import("signal.zig").Signal;
    pub const SysInfo = @import("basin_kernel.zig").SysInfo;
    pub const BasinError = @import("basin_kernel.zig").BasinError;
    pub const SyscallResult = @import("basin_kernel.zig").SyscallResult;
    pub const BasinKernel = @import("basin_kernel.zig").BasinKernel;
    pub const ProcessContext = @import("process.zig").ProcessContext;
    pub const KernelLogBuffer = @import("kernel_log_buffer.zig").KernelLogBuffer;
    pub const KernelLogEntry = @import("kernel_log_buffer.zig").KernelLogEntry;
    pub const KernelLogLevel = @import("kernel_log_buffer.zig").KernelLogLevel;
    pub const Process = @import("basin_kernel.zig").Process;
    pub const Storage = @import("storage.zig").Storage;
    pub const FileEntry = @import("storage.zig").FileEntry;
    pub const DirectoryEntry = @import("storage.zig").DirectoryEntry;
    pub const MAX_FILE_SIZE = @import("storage.zig").MAX_FILE_SIZE;
    pub const InterruptController = @import("interrupt.zig").InterruptController;
    pub const InterruptType = @import("interrupt.zig").InterruptType;
    pub const InterruptHandler = @import("interrupt.zig").InterruptHandler;
    pub const Timer = @import("timer.zig").Timer;
    pub const Keyboard = @import("keyboard.zig").Keyboard;
    pub const Mouse = @import("mouse.zig").Mouse;
    pub const KeyCode = @import("keyboard.zig").KeyCode;
    pub const ChannelTable = @import("channel.zig").ChannelTable;
    pub const Channel = @import("channel.zig").Channel;
    pub const MemoryPool = @import("memory.zig").MemoryPool;
    pub const MAX_PAGES = @import("memory.zig").MAX_PAGES;
    pub const PAGE_SIZE = @import("memory.zig").PAGE_SIZE;
    pub const MAX_MESSAGE_SIZE = @import("channel.zig").MAX_MESSAGE_SIZE;
    pub const BootSequence = @import("boot.zig").BootSequence;
    pub const BootPhase = @import("boot.zig").BootPhase;
    pub const boot_kernel = @import("boot.zig").boot_kernel;
    pub const ExceptionType = @import("trap.zig").ExceptionType;
    pub const handle_exception = @import("trap.zig").handle_exception;
    pub const Debug = @import("debug.zig");
    pub const platform = @import("platform.zig");
};
