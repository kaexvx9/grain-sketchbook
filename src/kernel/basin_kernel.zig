//! Basin kernel — The container where everything flows
//!
//! Basin kernel is a Zig monolith kernel for RISC-V64, designed for the next 30 years.
//! Non-POSIX, type-safe, minimal syscall surface, Clutch Style safety.
//!
//! **Homebrew Bundle**: `basin`
//!
//! **Vision**: Modern kernel design inspired by seL4 (minimal), Aero OS (monolithic),
//! and Fuchsia (capability-based), but built in pure Zig for RISC-V.
//!
//! **Note**: Theseus OS uses SAS/SPL architecture (not traditional monolithic).
//! Aero OS proves monolithic kernels work (runs real apps), but targets x86_64 only.
//! Basin kernel fills the gap: RISC-V native, non-POSIX, minimal syscall surface.
//!
//! **Target**: Framework 13 DeepComputing RISC-V Mainboard
//! **Development**: macOS Tahoe IDE with RISC-V VM for testing

const std = @import("std");
pub const Debug = @import("debug.zig");
// Re-export types for tests (also used internally)
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

// Import types from separate module
const types = @import("basin_kernel_types.zig");

// Import core BasinKernel struct and helpers
const core = @import("basin_kernel_core.zig");

// Import process syscalls
const process_syscalls = @import("basin_kernel_syscalls_process.zig");
const ProcessSyscalls = process_syscalls.ProcessSyscalls;

// Import file syscalls
const file_syscalls = @import("basin_kernel_syscalls_file.zig");
const FileSyscalls = file_syscalls.FileSyscalls;

// Import network syscalls
const network_syscalls = @import("basin_kernel_syscalls_network.zig");
const NetworkSyscalls = network_syscalls.NetworkSyscalls;

// Import audio syscalls
const audio_syscalls = @import("basin_kernel_syscalls_audio.zig");
const AudioSyscalls = audio_syscalls.AudioSyscalls;

// Import stats syscalls
const stats_syscalls = @import("basin_kernel_syscalls_stats.zig");
const StatsSyscalls = stats_syscalls.StatsSyscalls;

// Re-export all public types for backward compatibility
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
// Note: ProcessContext is available via basin_kernel.harbor_kernel.ProcessContext

// Re-export internal types used by BasinKernel
const MemoryMapping = types.MemoryMapping;
const FileHandle = types.FileHandle;
const DirectoryHandle = types.DirectoryHandle;

// Re-export constants
const MAX_MAPPINGS = types.MAX_MAPPINGS;
const MAX_HANDLES = types.MAX_HANDLES;
const MAX_DIR_HANDLES = types.MAX_DIR_HANDLES;
const MAX_PROCESSES = types.MAX_PROCESSES;
const MAX_USERS = types.MAX_USERS;

// Export resource_cleanup for tests.
pub const resource_cleanup_module = resource_cleanup;

// Export RawIO for tests to disable hardware access.
pub const RawIO = @import("uart.zig");

// Export syscall_performance_profiler for tests.
pub const syscall_performance_profiler = @import("syscall_performance_profiler.zig");

// Re-export additional types for tests (these are also in harbor_kernel struct for compatibility)
pub const PAGE_SIZE = @import("memory.zig").PAGE_SIZE;
pub const MAX_PAGES = @import("memory.zig").MAX_PAGES;
pub const Channel = @import("channel.zig").Channel;
pub const MAX_MESSAGE_SIZE = @import("channel.zig").MAX_MESSAGE_SIZE;
pub const MAX_MESSAGES = @import("channel.zig").MAX_MESSAGES;
// Note: KernelLogLevel and KernelLogEntry are available via basin_kernel.harbor_kernel struct

// Compile-time assertions for handle table size.
comptime {
    std.debug.assert(MAX_HANDLES > 0);
    std.debug.assert(MAX_HANDLES <= 0xFFFFFFFF);
    std.debug.assert(MAX_HANDLES < 0xFFFFFFFF);
}

// Re-export BasinKernel from core module
pub const BasinKernel = core.BasinKernel;

/// Decode syscall number to enum.
fn decode_syscall(num: u32) ?Syscall {
    if (num < 10 or num > @intFromEnum(Syscall.getsid)) return null;
    return @enumFromInt(num);
}

/// Record syscall profiling data.
fn record_profile(self: *BasinKernel, num: u32, start: u64) void {
    if (!self.syscall_profiler.enabled or start == 0) return;
    const end = self.timer.get_monotonic_ns();
    const elapsed = if (end >= start) end - start else 1;
    self.syscall_profiler.record_syscall(num, elapsed);
}

/// Why: Central syscall entry point, validate and dispatch.
pub fn handle_syscall(
    self: *BasinKernel,
    syscall_num: u32,
    arg1: u64,
    arg2: u64,
    arg3: u64,
    arg4: u64,
) BasinError!SyscallResult {
    const syscall = decode_syscall(syscall_num) orelse return BasinError.invalid_syscall;
    const start = if (self.syscall_profiler.enabled) self.timer.get_monotonic_ns() else 0;

    const result = switch (syscall) {
        .spawn => ProcessSyscalls.syscall_spawn(self, arg1, arg2, arg3, arg4),
        .exit => ProcessSyscalls.syscall_exit(self, arg1, arg2, arg3, arg4),
        .yield => ProcessSyscalls.syscall_yield(self, arg1, arg2, arg3, arg4),
        .wait => ProcessSyscalls.syscall_wait(self, arg1, arg2, arg3, arg4),
        .map => syscall_map(self, arg1, arg2, arg3, arg4),
        .unmap => syscall_unmap(self, arg1, arg2, arg3, arg4),
        .protect => syscall_protect(self, arg1, arg2, arg3, arg4),
        .channel_create => syscall_channel_create(self, arg1, arg2, arg3, arg4),
        .channel_send => syscall_channel_send(self, arg1, arg2, arg3, arg4),
        .channel_recv => syscall_channel_recv(self, arg1, arg2, arg3, arg4),
        .open => FileSyscalls.syscall_open(self, arg1, arg2, arg3, arg4),
        .read => FileSyscalls.syscall_read(self, arg1, arg2, arg3, arg4),
        .write => FileSyscalls.syscall_write(self, arg1, arg2, arg3, arg4),
        .close => FileSyscalls.syscall_close(self, arg1, arg2, arg3, arg4),
        .unlink => FileSyscalls.syscall_unlink(self, arg1, arg2, arg3, arg4),
        .rename => FileSyscalls.syscall_rename(self, arg1, arg2, arg3, arg4),
        .mkdir => FileSyscalls.syscall_mkdir(self, arg1, arg2, arg3, arg4),
        .opendir => FileSyscalls.syscall_opendir(self, arg1, arg2, arg3, arg4),
        .readdir => FileSyscalls.syscall_readdir(self, arg1, arg2, arg3, arg4),
        .closedir => FileSyscalls.syscall_closedir(self, arg1, arg2, arg3, arg4),
        .clock_gettime => syscall_clock_gettime(self, arg1, arg2, arg3, arg4),
        .sleep_until => syscall_sleep_until(self, arg1, arg2, arg3, arg4),
        .sysinfo => syscall_sysinfo(self, arg1, arg2, arg3, arg4),
        .enumerate_processes => syscall_enumerate_processes(self, arg1, arg2, arg3, arg4),
        .get_process_info => syscall_get_process_info(self, arg1, arg2, arg3, arg4),
        .read_kernel_log => syscall_read_kernel_log(self, arg1, arg2, arg3, arg4),
        .set_priority => syscall_set_priority(self, arg1, arg2, arg3, arg4),
        .get_priority => syscall_get_priority(self, arg1, arg2, arg3, arg4),
        .setpgid => ProcessSyscalls.syscall_setpgid(self, arg1, arg2, arg3, arg4),
        .getpgid => ProcessSyscalls.syscall_getpgid(self, arg1, arg2, arg3, arg4),
        .setsid => ProcessSyscalls.syscall_setsid(self, arg1, arg2, arg3, arg4),
        .getsid => ProcessSyscalls.syscall_getsid(self, arg1, arg2, arg3, arg4),
        .read_input_event => syscall_read_input_event(self, arg1, arg2, arg3, arg4),
        .fb_clear => syscall_fb_clear(self, arg1, arg2, arg3, arg4),
        .fb_draw_pixel => syscall_fb_draw_pixel(self, arg1, arg2, arg3, arg4),
        .fb_draw_text => syscall_fb_draw_text(self, arg1, arg2, arg3, arg4),
        .kill => ProcessSyscalls.syscall_kill(self, arg1, arg2, arg3, arg4),
        .signal => ProcessSyscalls.syscall_signal(self, arg1, arg2, arg3, arg4),
        .sigaction => ProcessSyscalls.syscall_sigaction(self, arg1, arg2, arg3, arg4),
        .network_create_interface => NetworkSyscalls.syscall_network_create_interface(self, arg1, arg2, arg3, arg4),
        .network_set_state => NetworkSyscalls.syscall_network_set_state(self, arg1, arg2, arg3, arg4),
        .network_set_ipv4 => NetworkSyscalls.syscall_network_set_ipv4(self, arg1, arg2, arg3, arg4),
        .network_set_ipv6 => NetworkSyscalls.syscall_network_set_ipv6(self, arg1, arg2, arg3, arg4),
        .network_get_interface => NetworkSyscalls.syscall_network_get_interface(self, arg1, arg2, arg3, arg4),
        .network_delete_interface => NetworkSyscalls.syscall_network_delete_interface(self, arg1, arg2, arg3, arg4),
        .network_enumerate_interfaces => NetworkSyscalls.syscall_network_enumerate_interfaces(self, arg1, arg2, arg3, arg4),
        .network_get_stats => NetworkSyscalls.syscall_network_get_stats(self, arg1, arg2, arg3, arg4),
        .tcp_socket => NetworkSyscalls.syscall_tcp_socket(self, arg1, arg2, arg3, arg4),
        .tcp_bind => NetworkSyscalls.syscall_tcp_bind(self, arg1, arg2, arg3, arg4),
        .tcp_listen => NetworkSyscalls.syscall_tcp_listen(self, arg1, arg2, arg3, arg4),
        .tcp_accept => NetworkSyscalls.syscall_tcp_accept(self, arg1, arg2, arg3, arg4),
        .tcp_connect => NetworkSyscalls.syscall_tcp_connect(self, arg1, arg2, arg3, arg4),
        .tcp_send => NetworkSyscalls.syscall_tcp_send(self, arg1, arg2, arg3, arg4),
        .tcp_recv => NetworkSyscalls.syscall_tcp_recv(self, arg1, arg2, arg3, arg4),
        .tcp_close => NetworkSyscalls.syscall_tcp_close(self, arg1, arg2, arg3, arg4),
        .tcp_enumerate_sockets => NetworkSyscalls.syscall_tcp_enumerate_sockets(self, arg1, arg2, arg3, arg4),
        .tcp_get_stats => NetworkSyscalls.syscall_tcp_get_stats(self, arg1, arg2, arg3, arg4),
        .udp_socket => NetworkSyscalls.syscall_udp_socket(self, arg1, arg2, arg3, arg4),
        .udp_bind => NetworkSyscalls.syscall_udp_bind(self, arg1, arg2, arg3, arg4),
        .udp_sendto => NetworkSyscalls.syscall_udp_sendto(self, arg1, arg2, arg3, arg4),
        .udp_recvfrom => NetworkSyscalls.syscall_udp_recvfrom(self, arg1, arg2, arg3, arg4),
        .udp_close => NetworkSyscalls.syscall_udp_close(self, arg1, arg2, arg3, arg4),
        .udp_enumerate_sockets => NetworkSyscalls.syscall_udp_enumerate_sockets(self, arg1, arg2, arg3, arg4),
        .udp_get_stats => NetworkSyscalls.syscall_udp_get_stats(self, arg1, arg2, arg3, arg4),
        .udp_sendto_with_timeout => NetworkSyscalls.syscall_udp_sendto_with_timeout(self, arg1, arg2, arg3, arg4),
        .udp_recvfrom_with_timeout => NetworkSyscalls.syscall_udp_recvfrom_with_timeout(self, arg1, arg2, arg3, arg4),
        .audio_create_device => AudioSyscalls.syscall_audio_create_device(self, arg1, arg2, arg3, arg4),
        .audio_set_volume => AudioSyscalls.syscall_audio_set_volume(self, arg1, arg2, arg3, arg4),
        .audio_set_mute => AudioSyscalls.syscall_audio_set_mute(self, arg1, arg2, arg3, arg4),
        .audio_set_state => AudioSyscalls.syscall_audio_set_state(self, arg1, arg2, arg3, arg4),
        .audio_set_active_output => AudioSyscalls.syscall_audio_set_active_output(self, arg1, arg2, arg3, arg4),
        .audio_set_active_input => AudioSyscalls.syscall_audio_set_active_input(self, arg1, arg2, arg3, arg4),
        .audio_set_master_volume => AudioSyscalls.syscall_audio_set_master_volume(self, arg1, arg2, arg3, arg4),
        .audio_set_master_mute => AudioSyscalls.syscall_audio_set_master_mute(self, arg1, arg2, arg3, arg4),
        .audio_get_device => AudioSyscalls.syscall_audio_get_device(self, arg1, arg2, arg3, arg4),
        .audio_set_format => AudioSyscalls.syscall_audio_set_format(self, arg1, arg2, arg3, arg4),
        .audio_read => AudioSyscalls.syscall_audio_read(self, arg1, arg2, arg3, arg4),
        .audio_write => AudioSyscalls.syscall_audio_write(self, arg1, arg2, arg3, arg4),
        .audio_enumerate_devices => AudioSyscalls.syscall_audio_enumerate_devices(self, arg1, arg2, arg3, arg4),
        .audio_delete_device => AudioSyscalls.syscall_audio_delete_device(self, arg1, arg2, arg3, arg4),
        .audio_get_stats => AudioSyscalls.syscall_audio_get_stats(self, arg1, arg2, arg3, arg4),
        .kernel_get_stats => StatsSyscalls.syscall_kernel_get_stats(self, arg1, arg2, arg3, arg4),
        .health_check => StatsSyscalls.syscall_health_check(self, arg1, arg2, arg3, arg4),
        .get_resource_usage => StatsSyscalls.syscall_get_resource_usage(self, arg1, arg2, arg3, arg4),
        .set_resource_limit => StatsSyscalls.syscall_set_resource_limit(self, arg1, arg2, arg3, arg4),
    };

    record_profile(self, syscall_num, start);
    return result;
}
    
    // Syscall handlers (stubs for future implementation).
    // Why: Separate functions for each syscall, Grain Style function length limit.

    /// Why: Map memory region for process address space.
    pub fn syscall_map(
        self: *BasinKernel,
        addr: u64,
        size: u64,
        flags: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg4;
        const map_flags = try validate_map_args(size, flags);
        const mapping_addr = try resolve_map_addr(self, addr, size);

        if (self.check_overlap(mapping_addr, size)) return BasinError.invalid_argument;
        if (try check_group_memory_limit(self, size)) return BasinError.resource_exhausted;

        const idx = self.find_free_mapping() orelse return BasinError.out_of_memory;
        const owner = @as(u32, @truncate(self.scheduler.get_current()));

        commit_mapping(self, idx, mapping_addr, size, map_flags, owner);
        if (addr == 0) self.next_alloc_addr = mapping_addr + size;

        return SyscallResult.ok(mapping_addr);
    }

    const VM_MEM_SIZE: u64 = 4 * 1024 * 1024;
    const USER_START: u64 = 0x100000;

    /// Validate size and flags for map syscall.
    fn validate_map_args(size: u64, flags: u64) BasinError!MapFlags {
        if (size == 0 or size % 4096 != 0) return BasinError.invalid_argument;
        if (size > VM_MEM_SIZE) return BasinError.out_of_memory;
        const mf = @as(MapFlags, @bitCast(@as(u32, @truncate(flags))));
        if (!mf.read and !mf.write and !mf.execute) return BasinError.invalid_argument;
        if (mf._padding != 0) return BasinError.invalid_argument;
        return mf;
    }

    /// Resolve mapping address (kernel-chosen or user-provided).
    fn resolve_map_addr(self: *BasinKernel, addr: u64, size: u64) BasinError!u64 {
        if (addr == 0) {
            const a = self.next_alloc_addr;
            if (a + size > VM_MEM_SIZE) return BasinError.out_of_memory;
            return a;
        }
        if (addr % 4096 != 0) return BasinError.unaligned_access;
        if (addr < USER_START) return BasinError.permission_denied;
        if (addr + size > VM_MEM_SIZE) return BasinError.out_of_memory;
        return addr;
    }

    /// Check process group memory limit.
    fn check_group_memory_limit(self: *BasinKernel, size: u64) BasinError!bool {
        const pid = self.scheduler.get_current();
        if (pid == 0) return false;
        const pgid = get_process_pgid(self, pid) orelse return false;
        const usage = sum_group_memory(self, pgid);
        return !self.process_group_limits.can_allocate_memory(pgid, usage, size);
    }

    fn get_process_pgid(self: *BasinKernel, pid: u64) ?u64 {
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == pid)
                return self.processes[i].pgid;
        }
        return null;
    }

    fn sum_group_memory(self: *BasinKernel, pgid: u64) u64 {
        var total: u64 = 0;
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].pgid == pgid)
                total +%= self.processes[i].memory_used;
        }
        return total;
    }

    /// Commit mapping entry and update page table/stats.
    fn commit_mapping(
        self: *BasinKernel,
        idx: usize,
        addr: u64,
        size: u64,
        flags: MapFlags,
        owner: u32,
    ) void {
        var m = &self.mappings[idx];
        m.address = addr;
        m.size = size;
        m.flags = flags;
        m.allocated = true;
        m.owner_process_id = owner;
        self.add_mapping_to_hash_table(addr, idx);

        const pf = page_table.PageFlags{
            .read = flags.read,
            .write = flags.write,
            .execute = flags.execute,
            .shared = flags.shared,
            ._padding = 0,
        };
        self.page_table.map_pages(addr, size, pf);
        self.memory_stats.update_from_page_table(@ptrCast(&self.page_table), VM_MEM_SIZE);
        self.memory_stats.update_mapping_count(self.count_allocated_mappings());
        if (owner > 0) self.update_process_memory_usage(@as(u64, owner));
    }
    
    /// Validate unmap region address.
    fn validate_unmap_region(region: u64) ?BasinError {
        if (region % 4096 != 0) return BasinError.unaligned_access;
        if (region < USER_START) return BasinError.permission_denied;
        if (region >= VM_MEM_SIZE) return BasinError.invalid_argument;
        return null;
    }

    /// Clear a mapping entry.
    fn clear_mapping(mapping: *MemoryMapping) void {
        mapping.allocated = false;
        mapping.address = 0;
        mapping.size = 0;
        mapping.owner_process_id = 0;
        mapping.flags = MapFlags.init(.{});
    }

    fn syscall_unmap(
        self: *BasinKernel,
        region: u64,
        _arg2: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg2;
        _ = _arg3;
        _ = _arg4;

        if (validate_unmap_region(region)) |err| return err;

        const idx = self.find_mapping_by_address(region) orelse {
            return BasinError.invalid_argument;
        };

        Debug.kassert(self.mappings[idx].allocated, "Mapping not allocated", .{});
        const mapping = &self.mappings[idx];
        const size = mapping.size;
        const owner = mapping.owner_process_id;

        self.remove_mapping_from_hash_table(region);
        clear_mapping(mapping);
        self.page_table.unmap_pages(region, size);

        const VM_MEM: u64 = 4 * 1024 * 1024;
        self.memory_stats.update_from_page_table(@ptrCast(&self.page_table), VM_MEM);
        self.memory_stats.update_mapping_count(self.count_allocated_mappings());

        if (owner > 0) self.update_process_memory_usage(@as(u64, owner));
        return SyscallResult.ok(0);
    }
    
    /// Validate and decode protection flags.
    fn validate_protect_flags(flags: u64) ?MapFlags {
        const map_flags = @as(MapFlags, @bitCast(@as(u32, @truncate(flags))));
        if (!map_flags.read and !map_flags.write and !map_flags.execute) return null;
        if (map_flags._padding != 0) return null;
        return map_flags;
    }

    /// Convert MapFlags to PageFlags.
    fn map_to_page_flags(mf: MapFlags) page_table.PageFlags {
        return .{ .read = mf.read, .write = mf.write, .execute = mf.execute, .shared = mf.shared, ._padding = 0 };
    }

    fn syscall_protect(
        self: *BasinKernel,
        region: u64,
        flags: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg3;
        _ = _arg4;

        if (validate_unmap_region(region)) |err| return err;

        const map_flags = validate_protect_flags(flags) orelse return BasinError.invalid_argument;

        const idx = self.find_mapping_by_address(region) orelse {
            return BasinError.invalid_argument;
        };

        Debug.kassert(self.mappings[idx].allocated, "Mapping not allocated", .{});
        const mapping = &self.mappings[idx];
        const size = mapping.size;
        mapping.flags = map_flags;

        self.page_table.protect_pages(region, size, map_to_page_flags(map_flags));

        const VM_MEM: u64 = 4 * 1024 * 1024;
        self.memory_stats.update_from_page_table(@ptrCast(&self.page_table), VM_MEM);

        return SyscallResult.ok(0);
    }
    
    fn syscall_channel_create(
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
        
        // Get current process ID from scheduler.
        // Why: Track which process owns this channel for resource cleanup.
        const current_process_id = self.scheduler.get_current();
        const owner_process_id = @as(u32, @truncate(current_process_id));
        
        // Create channel in channel table.
        const channel_id = self.channels.create();
        
        if (channel_id == 0) {
            return BasinError.out_of_memory; // Channel table full
        }
        
        // Assert: Channel ID must be non-zero.
        Debug.kassert(channel_id != 0, "Channel ID is 0", .{});
        
        // Set owner process ID for the channel.
        // Why: Track which process owns this channel for resource cleanup.
        const channel = self.channels.find(channel_id);
        if (channel) |ch| {
            ch.owner_process_id = owner_process_id;
        }
        
        const result = SyscallResult.ok(channel_id);
        
        // Assert: result must be success (not error).
        Debug.kassert(result == .success, "Result not success", .{});
        Debug.kassert(result.success == channel_id, "Result value mismatch", .{});
        
        return result;
    }
    
    /// Validate channel buffer args (4KB max message).
    fn validate_channel_buffer(ch_id: u64, ptr: u64, len: u64) ?BasinError {
        const VM_MEM: u64 = 4 * 1024 * 1024;
        const MAX_MSG: u64 = 4096;
        if (ch_id == 0) return BasinError.invalid_argument;
        if (ptr == 0 or ptr >= VM_MEM) return BasinError.invalid_argument;
        if (len == 0 or len > MAX_MSG) return BasinError.invalid_argument;
        if (ptr + len > VM_MEM) return BasinError.invalid_argument;
        return null;
    }

    fn syscall_channel_send(
        self: *BasinKernel,
        channel: u64,
        data_ptr: u64,
        data_len: u64,
        timeout_ns: u64,
    ) BasinError!SyscallResult {
        if (validate_channel_buffer(channel, data_ptr, data_len)) |err| return err;

        const start_ns = self.timer.get_monotonic_ns();
        const ch = self.channels.find(channel) orelse return BasinError.not_found;

        if (self.check_timeout(start_ns, timeout_ns)) return BasinError.ipc_timeout;
        if (self.vm_memory_reader == null) return BasinError.invalid_syscall;

        const len32 = @as(u32, @truncate(data_len));
        var buf: [4096]u8 = undefined;
        const slice = buf[0..len32];

        const read = self.vm_memory_reader.?(data_ptr, len32, slice) orelse {
            return BasinError.invalid_argument;
        };
        if (read != len32) return BasinError.invalid_argument;

        if (!ch.send(slice)) {
            if (self.check_timeout(start_ns, timeout_ns)) return BasinError.ipc_timeout;
            return BasinError.would_block;
        }

        if (self.check_timeout(start_ns, timeout_ns)) return BasinError.ipc_timeout;
        return SyscallResult.ok(0);
    }
    
    fn syscall_channel_recv(
        self: *BasinKernel,
        channel: u64,
        buffer_ptr: u64,
        buffer_len: u64,
        timeout_ns: u64,
    ) BasinError!SyscallResult {
        if (validate_channel_buffer(channel, buffer_ptr, buffer_len)) |err| return err;

        const start_ns = self.timer.get_monotonic_ns();
        const ch = self.channels.find(channel) orelse return BasinError.not_found;

        if (self.check_timeout(start_ns, timeout_ns)) return BasinError.ipc_timeout;

        var msg_buf: [4096]u8 = undefined;
        const recv_len = ch.receive(&msg_buf);

        if (recv_len == 0) {
            if (self.check_timeout(start_ns, timeout_ns)) return BasinError.ipc_timeout;
            return SyscallResult.ok(0);
        }

        if (self.check_timeout(start_ns, timeout_ns)) return BasinError.ipc_timeout;
        if (self.vm_memory_writer == null) return BasinError.invalid_syscall;

        const to_write = @min(recv_len, @as(u32, @truncate(buffer_len)));
        const written = self.vm_memory_writer.?(buffer_ptr, to_write, msg_buf[0..to_write]) orelse {
            return BasinError.invalid_argument;
        };
        if (written != to_write) return BasinError.invalid_argument;

        return SyscallResult.ok(@as(u64, written));
    }
    
    fn syscall_clock_gettime(
        self: *BasinKernel,
        clock_id: u64,
        timespec_ptr: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg3;
        _ = _arg4;
        
        // Assert: clock_id must be valid (monotonic or realtime).
        const clock = @as(?ClockId, @enumFromInt(@as(u32, @truncate(clock_id)))) orelse {
            return BasinError.invalid_argument; // Invalid clock ID
        };
        
        // Assert: Clock must be valid (monotonic or realtime).
        Debug.kassert(clock == .monotonic or clock == .realtime, "Invalid clock", .{});
        
        // Assert: timespec pointer must be valid (non-zero, within VM memory).
        if (timespec_ptr == 0) {
            return BasinError.invalid_argument; // Null pointer
        }
        
        const VM_MEMORY_SIZE: u64 = 4 * 1024 * 1024; // 4MB default (matches syscall_map)
        if (timespec_ptr >= VM_MEMORY_SIZE) {
            return BasinError.invalid_argument; // Timespec pointer exceeds VM memory
        }
        
        // Assert: timespec must fit within VM memory (16 bytes: seconds + nanoseconds).
        const TIMESPEC_SIZE: u64 = 16; // 8 bytes seconds + 8 bytes nanoseconds
        if (timespec_ptr + TIMESPEC_SIZE > VM_MEMORY_SIZE) {
            return BasinError.invalid_argument; // Timespec exceeds VM memory
        }
        
        // Note: This syscall is handled by integration layer (needs VM access).
        // This stub should never be called, but we include it for completeness.
        // Contract: clock_id and timespec_ptr must be valid (checked by integration layer).
        
        // This should not be reached (integration layer handles this syscall).
        return BasinError.invalid_syscall;
    }
    
    fn syscall_sleep_until(
        self: *BasinKernel,
        timestamp: u64,
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
        
        // Assert: timestamp must be valid (non-zero, reasonable value).
        // Note: Timestamp is nanoseconds since epoch (or boot, depending on clock type).
        // For now, accept any non-zero value (validation depends on clock implementation).
        if (timestamp == 0) {
            return BasinError.invalid_argument; // Zero timestamp (invalid)
        }
        
        // Get current monotonic time (nanoseconds since boot).
        const current_time_ns = self.timer.get_monotonic_ns();
        
        // Assert: Current time must be valid.
        Debug.kassert(current_time_ns >= 0, "Current time negative", .{});
        
        // Check if timestamp is in the past.
        // Note: timestamp is nanoseconds since boot (monotonic clock).
        if (timestamp < current_time_ns) {
            // Timestamp is in the past: return error.
            return BasinError.invalid_argument; // Timestamp in the past
        }
        
        // Calculate sleep duration (nanoseconds to wait).
        const sleep_duration_ns = timestamp - current_time_ns;
        
        // Assert: Sleep duration must be non-negative.
        Debug.kassert(sleep_duration_ns >= 0, "Sleep duration negative", .{});
        
        // TODO: Implement actual blocking sleep (when scheduler is implemented).
        // For now, return success immediately (non-blocking stub).
        // Why: Simple stub - matches current kernel development stage.
        // Note: In full implementation, we would:
        // - Set timer interrupt for timestamp
        // - Block current process until timer interrupt
        // - Wake up when timer interrupt fires
        // - Return success when woken up
        
        // Stub: Return success immediately (non-blocking).
        const result = SyscallResult.ok(0);
        
        // Assert: result must be success (not error).
        Debug.kassert(result == .success, "Result not success", .{});
        Debug.kassert(result.success == 0, "Result not 0", .{}); // Sleep_until returns 0 on success
        
        return result;
    }
    
    /// Get memory statistics for sysinfo.
    fn get_memory_stats(self: *BasinKernel) struct { total: u64, available: u64 } {
        const total: u64 = 4 * 1024 * 1024;
        const alloc = self.memory_pool.allocated_pages;
        const avail_pages: u32 = if (alloc > 1024) 0 else 1024 - alloc;
        return .{ .total = total, .available = @as(u64, avail_pages) * 4096 };
    }

    /// Count processes by state.
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

    fn syscall_sysinfo(
        self: *BasinKernel,
        info_ptr: u64,
        _arg2: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg2;
        _ = _arg3;
        _ = _arg4;

        if (validate_vm_ptr(info_ptr, 56)) |err| return err;

        // Collect stats (integration layer writes to VM memory).
        const mem = get_memory_stats(self);
        const procs = count_processes(self);
        _ = mem;
        _ = procs;
        _ = self.timer.get_uptime_ns();

        return SyscallResult.ok(0);
    }

    fn syscall_enumerate_processes(
        self: *BasinKernel,
        buffer_ptr: u64,
        buffer_len: u64,
        max_processes: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg4;
        
        // Assert: buffer pointer must be valid (non-zero, within VM memory).
        if (buffer_ptr == 0) {
            return BasinError.invalid_argument; // Null pointer
        }
        
        const VM_MEMORY_SIZE: u64 = 4 * 1024 * 1024; // 4MB default
        if (buffer_ptr >= VM_MEMORY_SIZE) {
            return BasinError.invalid_argument; // Buffer pointer exceeds VM memory
        }
        
        // Assert: buffer length must be sufficient for at least one ProcessInfo.
        const PROCESS_INFO_SIZE: u64 = 32; // pid(4) + parent_pid(4) + state(1) + padding(3) + cpu_time_ns(8) + memory_used(8)
        if (buffer_len < PROCESS_INFO_SIZE) {
            return BasinError.invalid_argument; // Buffer too small
        }
        
        // Assert: max_processes must be reasonable.
        const MAX_PROCESSES_U64: u64 = MAX_PROCESSES;
        const limit: u64 = if (max_processes > 0 and max_processes < MAX_PROCESSES_U64) max_processes else MAX_PROCESSES_U64;
        
        // Calculate how many ProcessInfo structures fit in buffer.
        const max_fit: u64 = buffer_len / PROCESS_INFO_SIZE;
        const count: u64 = if (limit < max_fit) limit else max_fit;
        
        // Enumerate processes and write to buffer.
        // Note: Integration layer will write ProcessInfo structures to buffer_ptr.
        var written: u32 = 0;
        var i: u32 = 0;
        while (i < MAX_PROCESSES and written < count) : (i += 1) {
            if (self.processes[i].allocated) {
                written += 1;
            }
        }
        
        // Return number of processes found (integration layer writes data).
        const result = SyscallResult.ok(@intCast(written));
        
        // Assert: result must be success.
        Debug.kassert(result == .success, "Result not success", .{});
        
        return result;
    }

    /// Validate VM memory pointer with required size.
    /// Why: Common validation for syscalls writing to VM memory.
    fn validate_vm_ptr(ptr: u64, size: u64) ?BasinError {
        const VM_MEM: u64 = 4 * 1024 * 1024;
        if (ptr == 0 or ptr >= VM_MEM) return BasinError.invalid_argument;
        if (ptr + size > VM_MEM) return BasinError.invalid_argument;
        return null;
    }

    /// Find process index by ID.
    /// Why: Common lookup logic for process syscalls.
    fn find_proc_idx(self: *BasinKernel, pid: u64) ?usize {
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == pid) return i;
        }
        return null;
    }

    fn syscall_get_process_info(
        self: *BasinKernel,
        pid: u64,
        info_ptr: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg3;
        _ = _arg4;

        if (pid == 0) return BasinError.invalid_argument;
        if (validate_vm_ptr(info_ptr, 32)) |err| return err;
        if (find_proc_idx(self, pid) == null) return BasinError.not_found;

        // Update memory usage before returning info.
        self.update_process_memory_usage(pid);

        // Integration layer writes ProcessInfo (32 bytes) to info_ptr.
        return SyscallResult.ok(0);
    }

    fn syscall_read_kernel_log(
        self: *BasinKernel,
        buffer_ptr: u64,
        buffer_len: u64,
        max_entries: u64,
        flags: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = flags; // Reserved for future use (filter flags)
        
        // Assert: buffer pointer must be valid (non-zero, within VM memory).
        if (buffer_ptr == 0) {
            return BasinError.invalid_argument; // Null pointer
        }
        
        const VM_MEMORY_SIZE: u64 = 4 * 1024 * 1024; // 4MB default
        if (buffer_ptr >= VM_MEMORY_SIZE) {
            return BasinError.invalid_argument; // Buffer pointer exceeds VM memory
        }
        
        // Assert: buffer length must be sufficient for at least one KernelLogEntry.
        // Structure layout: timestamp(8) + level(1) + padding(7) + source(32) + message(256) = 304 bytes
        const KERNEL_LOG_ENTRY_SIZE: u64 = @sizeOf(KernelLogEntry);
        if (buffer_len < KERNEL_LOG_ENTRY_SIZE) {
            return BasinError.invalid_argument; // Buffer too small
        }
        
        // Get entry count from log buffer.
        const entry_count = self.log_buffer.get_entry_count();
        
        // Assert: max_entries must be reasonable.
        const MAX_LOG_ENTRIES_U64: u64 = 256;
        const limit: u64 = if (max_entries > 0 and max_entries < MAX_LOG_ENTRIES_U64) max_entries else MAX_LOG_ENTRIES_U64;
        
        // Calculate how many KernelLogEntry structures fit in buffer.
        const max_fit: u64 = buffer_len / KERNEL_LOG_ENTRY_SIZE;
        const count: u64 = if (limit < max_fit) limit else max_fit;
        const actual_count: u64 = if (count < entry_count) count else entry_count;
        
        // Enumerate log entries and write to buffer.
        // Note: Integration layer will write KernelLogEntry structures to buffer_ptr.
        var written: u32 = 0;
        var i: u32 = 0;
        while (i < actual_count) : (i += 1) {
            if (self.log_buffer.get_entry(i)) |_| {
                written += 1;
            }
        }
        
        // Return number of log entries found (integration layer writes data).
        const result = SyscallResult.ok(@intCast(written));
        
        // Assert: result must be success.
        Debug.kassert(result == .success, "Result not success", .{});
        
        return result;
    }

    fn syscall_set_priority(
        self: *BasinKernel,
        pid: u64,
        priority: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg3;
        _ = _arg4;
        
        // Assert: process ID must be valid (non-zero).
        if (pid == 0) {
            return BasinError.invalid_argument; // Invalid process ID
        }
        
        // Assert: priority must be valid nice value (-20 to 19).
        // Why: POSIX-style nice values: -20 (highest priority) to 19 (lowest priority).
        const MIN_NICE: i8 = -20;
        const MAX_NICE: i8 = 19;
        // Convert u64 to i8 (assuming value is in 0-39 range, subtract 20).
        // Why: Userspace passes nice value as unsigned (0-39), convert to signed (-20 to 19).
        const priority_offset: u64 = 20;
        if (priority < priority_offset or priority > priority_offset + 39) {
            return BasinError.invalid_argument; // Invalid priority value
        }
        const priority_i8 = @as(i8, @intCast(@as(i64, @intCast(priority)) - @as(i64, priority_offset)));
        
        // Assert: Priority must be in valid range after conversion.
        Debug.kassert(priority_i8 >= MIN_NICE and priority_i8 <= MAX_NICE, "Priority out of range", .{});
        
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
        
        // Set process priority.
        // Why: Update process priority for scheduling decisions.
        self.processes[idx].priority = priority_i8;
        
        // Assert: Priority must be set correctly.
        Debug.kassert(self.processes[idx].priority == priority_i8, "Priority not set", .{});
        
        // Return success.
        const result = SyscallResult.ok(0);
        
        // Assert: result must be success.
        Debug.kassert(result == .success, "Result not success", .{});
        
        return result;
    }

    fn syscall_get_priority(
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
        
        // Assert: process ID must be valid (non-zero).
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
        
        // Get process priority.
        // Why: Return process priority for userspace queries.
        const priority = self.processes[idx].priority;
        
        // Convert i8 to u64 for return value (add 20 to make it non-negative).
        // Why: Return nice value as unsigned (0-39 range: -20 becomes 0, 19 becomes 39).
        const priority_u64 = @as(u64, @intCast(@as(i32, priority) + 20));
        
        // Assert: Priority value must be in valid range (0-39).
        Debug.kassert(priority_u64 <= 39, "Priority value > 39", .{});
        
        // Return priority value.
        const result = SyscallResult.ok(priority_u64);
        
        // Assert: result must be success.
        Debug.kassert(result == .success, "Result not success", .{});
        
        return result;
    }
    
    fn syscall_read_input_event(
        self: *BasinKernel,
        event_buf: u64,
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
        
        // Note: This syscall is handled by integration layer (needs VM access).
        // This stub should never be called, but we include it for completeness.
        // Contract: event_buf must be valid pointer (checked by integration layer).
        if (event_buf == 0) {
            return BasinError.invalid_argument;
        }
        
        // This should not be reached (integration layer handles this syscall).
        return BasinError.invalid_syscall;
    }
    
    fn syscall_fb_clear(
        self: *BasinKernel,
        color: u64,
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
        
        // Note: This syscall is handled by integration layer (needs VM access).
        // This stub should never be called, but we include it for completeness.
        // Contract: color must be valid 32-bit RGBA value.
        if (color > 0xFFFFFFFF) {
            return BasinError.invalid_argument;
        }
        
        // This should not be reached (integration layer handles this syscall).
        return BasinError.invalid_syscall;
    }
    
    fn syscall_fb_draw_pixel(
        self: *BasinKernel,
        x: u64,
        y: u64,
        color: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg4;
        
        // Note: This syscall is handled by integration layer (needs VM access).
        // This stub should never be called, but we include it for completeness.
        // Contract: coordinates and color must be valid.
        if (x > 0xFFFFFFFF or y > 0xFFFFFFFF or color > 0xFFFFFFFF) {
            return BasinError.invalid_argument;
        }
        
        // This should not be reached (integration layer handles this syscall).
        return BasinError.invalid_syscall;
    }
    
    fn syscall_fb_draw_text(
        self: *BasinKernel,
        text_ptr: u64,
        x: u64,
        y: u64,
        fg_color: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        // Note: This syscall is handled by integration layer (needs VM access).
        // This stub should never be called, but we include it for completeness.
        // Contract: text_ptr must be valid pointer, coordinates and color must be valid.
        if (text_ptr == 0) {
            return BasinError.invalid_argument;
        }
        if (x > 0xFFFFFFFF or y > 0xFFFFFFFF or fg_color > 0xFFFFFFFF) {
            return BasinError.invalid_argument;
        }
        
        // This should not be reached (integration layer handles this syscall).
        return BasinError.invalid_syscall;
    }

/// Basin Kernel module exports.
/// Why: Explicit exports, clear public API.
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
    // Note: process_execution.zig imports kernel_vm, which creates a circular dependency.
    // It's only used by kernel_vm/integration.zig which can import it directly.
    // pub const process_execution = @import("process_execution.zig");
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
    // Debug and platform modules for testing
    pub const Debug = @import("debug.zig");
    pub const platform = @import("platform.zig");
};

