//! Basin Kernel Core
//! Why: Core BasinKernel struct definition, initialization, and common helper functions.

const std = @import("std");
const Debug = @import("debug.zig");
const Timer = @import("timer.zig").Timer;
const InterruptController = @import("interrupt.zig").InterruptController;
const Scheduler = @import("scheduler.zig").Scheduler;
const ChannelTable = @import("channel.zig").ChannelTable;
const Storage = @import("storage.zig").Storage;
const Keyboard = @import("keyboard.zig").Keyboard;
const Mouse = @import("mouse.zig").Mouse;
const MemoryPool = @import("memory.zig").MemoryPool;
const page_table = @import("page_table.zig");
const PageTable = page_table.PageTable;
const page_fault_stats = @import("page_fault_stats.zig");
const PageFaultStats = page_fault_stats.PageFaultStats;
const memory_stats = @import("memory_stats.zig");
const MemoryStats = memory_stats.MemoryStats;
const cow = @import("cow.zig");
const CowTable = cow.CowTable;
const KernelLogBuffer = @import("kernel_log_buffer.zig").KernelLogBuffer;
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
const syscall_performance_profiler = @import("syscall_performance_profiler.zig");
const SyscallPerformanceProfiler = syscall_performance_profiler.SyscallPerformanceProfiler;

const types = @import("basin_kernel_types.zig");
const MemoryMapping = types.MemoryMapping;
const FileHandle = types.FileHandle;
const DirectoryHandle = types.DirectoryHandle;
const Process = types.Process;
const User = types.User;
const UserContext = types.UserContext;
const UserId = types.UserId;
const MapFlags = types.MapFlags;
const BasinError = types.BasinError;
const SyscallResult = types.SyscallResult;
const Syscall = types.Syscall;
const MAX_MAPPINGS = types.MAX_MAPPINGS;
const MAX_HANDLES = types.MAX_HANDLES;
const MAX_DIR_HANDLES = types.MAX_DIR_HANDLES;
const MAX_PROCESSES = types.MAX_PROCESSES;
const MAX_USERS = types.MAX_USERS;

/// Why: Central kernel state, all subsystems, resource tables.
pub const BasinKernel = struct {
    mappings: [MAX_MAPPINGS]MemoryMapping = [_]MemoryMapping{MemoryMapping.init()} ** MAX_MAPPINGS,
    next_alloc_addr: u64 = 0x100000,
    handles: [MAX_HANDLES]FileHandle = [_]FileHandle{FileHandle.init()} ** MAX_HANDLES,
    next_handle_id: u64 = 1,
    mru_handle_index: u32 = MAX_HANDLES,
    mru_handle_id: u64 = 0,
    handle_id_to_index: [MAX_HANDLES]u32 = [_]u32{MAX_HANDLES} ** MAX_HANDLES,
    mapping_addr_to_index: [MAX_MAPPINGS]u32 = [_]u32{MAX_MAPPINGS} ** MAX_MAPPINGS,
    dir_handles: [MAX_DIR_HANDLES]DirectoryHandle = [_]DirectoryHandle{DirectoryHandle.init()} ** MAX_DIR_HANDLES,
    next_dir_handle_id: u64 = 1,
    processes: [MAX_PROCESSES]Process = [_]Process{Process.init()} ** MAX_PROCESSES,
    next_process_id: u64 = 1,
    current_process_index: u32 = MAX_PROCESSES,
    users: [MAX_USERS]User = [_]User{User.init()} ** MAX_USERS,
    user_count: u32 = 0,
    current_user: UserContext = UserContext{ .uid = 0, .gid = 0, .euid = 0, .egid = 0 },
    timer: Timer,
    interrupt_controller: InterruptController,
    scheduler: Scheduler,
    process_group_manager: ProcessGroupManager,
    process_group_stats: ProcessGroupStatsManager,
    process_group_limits: ProcessGroupLimitsManager,
    network_interfaces: NetworkInterfaceManager,
    tcp_sockets: TcpSocketManager,
    udp_sockets: UdpSocketManager,
    audio_devices: AudioDeviceManager,
    channels: ChannelTable,
    storage: Storage,
    keyboard: Keyboard,
    mouse: Mouse,
    log_buffer: KernelLogBuffer,
    memory_pool: MemoryPool,
    page_table: PageTable,
    page_fault_stats: PageFaultStats,
    memory_stats: MemoryStats,
    cow_table: CowTable,
    syscall_profiler: SyscallPerformanceProfiler,
    vm_memory_reader: ?*const fn (addr: u64, len: u32, buffer: []u8) ?u32 = null,
    vm_memory_reader_user_data: ?*anyopaque = null,
    vm_memory_writer: ?*const fn (addr: u64, len: u32, data: []const u8) ?u32 = null,
    vm_memory_writer_user_data: ?*anyopaque = null,

    /// Why: Create and return initialized kernel.
    pub fn init() BasinKernel {
        var kernel = BasinKernel{
            .timer = Timer.init(),
            .interrupt_controller = InterruptController.init(),
            .scheduler = Scheduler.init(),
            .process_group_manager = ProcessGroupManager.init(),
            .process_group_stats = ProcessGroupStatsManager.init(),
            .process_group_limits = ProcessGroupLimitsManager.init(),
            .network_interfaces = NetworkInterfaceManager.init(),
            .tcp_sockets = TcpSocketManager.init(),
            .udp_sockets = UdpSocketManager.init(),
            .audio_devices = AudioDeviceManager.init(),
            .channels = ChannelTable.init(),
            .storage = Storage.init(),
            .keyboard = Keyboard.init(),
            .mouse = Mouse.init(),
            .log_buffer = undefined,
            .memory_pool = MemoryPool.init(),
            .page_table = PageTable.init(),
            .page_fault_stats = PageFaultStats.init(),
            .memory_stats = MemoryStats.init(),
            .cow_table = CowTable.init(),
            .syscall_profiler = SyscallPerformanceProfiler.init(),
        };
        kernel.log_buffer = KernelLogBuffer.init(&kernel.timer);
        kernel.init_users();
        kernel.assert_initial_state();
        return kernel;
    }

    fn assert_initial_state(kernel: *BasinKernel) void {
        for (kernel.mappings, 0..) |mapping, i| {
            Debug.kassert(!mapping.allocated, "Mapping {d} should be unallocated", .{i});
        }
        Debug.kassert(kernel.next_alloc_addr % 4096 == 0, "Next alloc addr not aligned", .{});
        for (kernel.handles, 0..) |handle, i| {
            Debug.kassert(!handle.allocated, "Handle {d} should be unallocated", .{i});
            Debug.kassert(handle.id == 0, "Handle {d} ID should be 0", .{i});
        }
        Debug.kassert(kernel.next_handle_id != 0, "Next handle ID is 0", .{});
        Debug.kassert(kernel.mru_handle_index == MAX_HANDLES, "MRU index not invalid", .{});
        Debug.kassert(kernel.mru_handle_id == 0, "MRU ID not 0", .{});
        for (kernel.handle_id_to_index) |idx| {
            Debug.kassert(idx == MAX_HANDLES, "Hash table entry not invalid", .{});
        }
        Debug.kassert(kernel.current_process_index == MAX_PROCESSES, "Current process not invalid", .{});
        Debug.kassert(kernel.user_count >= 1, "User count < 1", .{});
        Debug.kassert(kernel.users[0].uid == 0, "First user UID != 0", .{});
        Debug.kassert(kernel.timer.initialized, "Timer not initialized", .{});
        Debug.kassert(kernel.interrupt_controller.initialized, "Interrupt controller not init", .{});
        Debug.kassert(kernel.scheduler.initialized, "Scheduler not initialized", .{});
    }

    fn init_core_subsystems(target: *BasinKernel) void {
        Debug.vprint("Initializing timer...", .{});
        target.timer = Timer.init();
        Debug.vprint("Initializing interrupt controller...", .{});
        target.interrupt_controller = InterruptController.init();
        Debug.vprint("Initializing scheduler...", .{});
        target.scheduler = Scheduler.init();
    }

    fn init_process_groups_inline(target: *BasinKernel) void {
        const ProcessGroup = process_group.ProcessGroup;
        const Session = process_group.Session;
        var i: u32 = 0;
        while (i < 64) : (i += 1) target.process_group_manager.groups[i] = ProcessGroup.init();
        i = 0;
        while (i < 32) : (i += 1) target.process_group_manager.sessions[i] = Session.init();
        target.process_group_manager.next_pgid = 1;
        target.process_group_manager.next_sid = 1;
        target.process_group_manager.initialized = true;
    }

    fn init_process_group_stats_inline(target: *BasinKernel) void {
        const PGStats = @import("process_group_stats.zig").ProcessGroupStats;
        var i: u32 = 0;
        while (i < 64) : (i += 1) target.process_group_stats.stats[i] = PGStats.init();
        target.process_group_stats.initialized = true;
    }

    fn init_process_group_limits_inline(target: *BasinKernel) void {
        const PGLimits = @import("process_group_limits.zig").ProcessGroupLimits;
        var i: u32 = 0;
        while (i < 64) : (i += 1) target.process_group_limits.limits[i] = PGLimits.init();
        target.process_group_limits.initialized = true;
    }

    fn init_process_group_managers(target: *BasinKernel) void {
        Debug.vprint("Initializing process group managers...", .{});
        init_process_groups_inline(target);
        init_process_group_stats_inline(target);
        init_process_group_limits_inline(target);
        Debug.vprint("Process group managers initialized", .{});
    }

    fn init_network_interfaces_inline(target: *BasinKernel) void {
        const NetworkInterface = @import("network.zig").NetworkInterface;
        var i: u32 = 0;
        while (i < 8) : (i += 1) target.network_interfaces.interfaces[i] = NetworkInterface.init();
        target.network_interfaces.initialized = true;
        target.network_interfaces.stats = @import("network_interface_stats.zig").NetworkInterfaceStats.init();
    }

    fn init_tcp_sockets_inline(target: *BasinKernel) void {
        var i: u32 = 0;
        while (i < 64) : (i += 1) {
            target.tcp_sockets.sockets[i].socket_id = 0;
            target.tcp_sockets.sockets[i].state = @import("tcp_socket.zig").TcpSocketState.closed;
            target.tcp_sockets.sockets[i].local_addr = 0;
            target.tcp_sockets.sockets[i].local_port = 0;
            target.tcp_sockets.sockets[i].remote_addr = 0;
            target.tcp_sockets.sockets[i].remote_port = 0;
            @memset(&target.tcp_sockets.sockets[i].recv_buffer, 0);
            target.tcp_sockets.sockets[i].recv_buffer_size = 0;
            @memset(&target.tcp_sockets.sockets[i].send_buffer, 0);
            target.tcp_sockets.sockets[i].send_buffer_size = 0;
            target.tcp_sockets.sockets[i].allocated = false;
            target.tcp_sockets.sockets[i].owner_process_id = 0;
        }
        target.tcp_sockets.next_socket_id = 1;
        target.tcp_sockets.initialized = true;
        target.tcp_sockets.stats = @import("tcp_socket_stats.zig").TcpSocketStats.init();
    }

    fn init_udp_sockets_inline(target: *BasinKernel) void {
        var i: u32 = 0;
        while (i < 64) : (i += 1) {
            target.udp_sockets.sockets[i].socket_id = 0;
            target.udp_sockets.sockets[i].state = @import("udp_socket.zig").UdpSocketState.closed;
            target.udp_sockets.sockets[i].local_addr = 0;
            target.udp_sockets.sockets[i].local_port = 0;
            @memset(&target.udp_sockets.sockets[i].recv_buffer, 0);
            target.udp_sockets.sockets[i].recv_buffer_size = 0;
            @memset(&target.udp_sockets.sockets[i].send_buffer, 0);
            target.udp_sockets.sockets[i].send_buffer_size = 0;
            target.udp_sockets.sockets[i].allocated = false;
            target.udp_sockets.sockets[i].owner_process_id = 0;
        }
        target.udp_sockets.next_socket_id = 1;
        target.udp_sockets.initialized = true;
        target.udp_sockets.stats = @import("udp_socket_stats.zig").UdpSocketStats.init();
    }

    fn init_network_managers(target: *BasinKernel) void {
        Debug.vprint("Initializing network managers...", .{});
        init_network_interfaces_inline(target);
        init_tcp_sockets_inline(target);
        init_udp_sockets_inline(target);
        Debug.vprint("Network managers initialized", .{});
    }

    fn init_audio_manager(target: *BasinKernel) void {
        Debug.vprint("Initializing audio device manager...", .{});
        var i: u32 = 0;
        while (i < 16) : (i += 1) {
            target.audio_devices.devices[i].device_id = 0;
            @memset(&target.audio_devices.devices[i].name, 0);
            target.audio_devices.devices[i].device_type = @import("audio.zig").AudioDeviceType.unknown;
            target.audio_devices.devices[i].state = @import("audio.zig").AudioDeviceState.disconnected;
            target.audio_devices.devices[i].volume = 50;
            target.audio_devices.devices[i].muted = false;
            target.audio_devices.devices[i].allocated = false;
            target.audio_devices.devices[i].owner_process_id = 0;
            target.audio_devices.devices[i].format = @import("audio.zig").AudioFormat.init();
            @memset(&target.audio_devices.devices[i].input_buffer, 0);
            target.audio_devices.devices[i].input_buffer_len = 0;
            @memset(&target.audio_devices.devices[i].output_buffer, 0);
            target.audio_devices.devices[i].output_buffer_len = 0;
        }
        target.audio_devices.next_device_id = 1;
        target.audio_devices.master_volume = 50;
        target.audio_devices.master_muted = false;
        target.audio_devices.active_output_device_id = 0;
        target.audio_devices.active_input_device_id = 0;
        target.audio_devices.initialized = true;
        target.audio_devices.stats = @import("audio_device_stats.zig").AudioDeviceStats.init();
        Debug.vprint("Audio device manager initialized", .{});
    }

    fn init_managers(target: *BasinKernel) void {
        init_process_group_managers(target);
        init_network_managers(target);
        init_audio_manager(target);
    }

    fn init_channels(target: *BasinKernel) void {
        Debug.vprint("Initializing channels...", .{});
        var i: u32 = 0;
        while (i < 64) : (i += 1) {
            target.channels.channels[i].id = 0;
            target.channels.channels[i].message_count = 0;
            target.channels.channels[i].read_pos = 0;
            target.channels.channels[i].write_pos = 0;
            target.channels.channels[i].allocated = false;
            target.channels.channels[i].owner_process_id = 0;
            var j: u32 = 0;
            while (j < 32) : (j += 1) {
                @memset(&target.channels.channels[i].messages[j].data, 0);
                target.channels.channels[i].messages[j].length = 0;
                target.channels.channels[i].messages[j].valid = false;
            }
        }
        target.channels.channel_count = 0;
        target.channels.next_channel_id = 1;
        Debug.vprint("Channels initialized", .{});
    }

    fn init_storage_inline(target: *BasinKernel) void {
        Debug.vprint("Initializing storage...", .{});
        var i: u32 = 0;
        while (i < 128) : (i += 1) {
            @memset(&target.storage.files[i].name, 0);
            target.storage.files[i].name_len = 0;
            @memset(&target.storage.files[i].data, 0);
            target.storage.files[i].data_len = 0;
            target.storage.files[i].allocated = false;
        }
        i = 0;
        while (i < 32) : (i += 1) {
            @memset(&target.storage.directories[i].name, 0);
            target.storage.directories[i].name_len = 0;
            @memset(&target.storage.directories[i].file_indices, 0);
            target.storage.directories[i].file_count = 0;
            target.storage.directories[i].allocated = false;
        }
        target.storage.file_count = 0;
        target.storage.next_file_index = 1;
        target.storage.directory_count = 0;
        target.storage.next_directory_index = 1;
        Debug.vprint("Storage initialized", .{});
    }

    fn init_storage_keyboard_mouse(target: *BasinKernel) void {
        init_storage_inline(target);
        Debug.vprint("Initializing keyboard...", .{});
        target.keyboard = Keyboard.init();
        Debug.vprint("Initializing mouse...", .{});
        target.mouse = Mouse.init();
    }

    fn init_io_subsystems(target: *BasinKernel) void {
        init_channels(target);
        init_storage_keyboard_mouse(target);
    }

    fn init_memory_subsystems(target: *BasinKernel) void {
        Debug.vprint("Initializing memory subsystems...", .{});
        @memset(&target.memory_pool.buffer, 0);
        var i: u32 = 0;
        while (i < 1024) : (i += 1) target.memory_pool.page_states[i] = @import("memory.zig").PageState.free;
        target.memory_pool.allocated_pages = 0;
        target.memory_pool.next_free_page = 0;
        target.page_table = PageTable.init();
        target.page_fault_stats = PageFaultStats.init();
        target.memory_stats = MemoryStats.init();
        target.cow_table = CowTable.init();
        target.syscall_profiler = SyscallPerformanceProfiler.init();
        Debug.vprint("Memory subsystems initialized", .{});
    }

    fn init_io_and_memory(target: *BasinKernel) void {
        init_io_subsystems(target);
        init_memory_subsystems(target);
    }

    /// Why: For heap-allocated kernels, initialize directly.
    pub fn init_in_place(target: *BasinKernel) void {
        target.timer.boot_time_ns = 0;
        target.timer.last_timer_ns = 0;
        target.timer.initialized = true;
        target.interrupt_controller.initialized = true;
        target.scheduler.initialized = true;
        target.scheduler.current_pid = 0;
        target.scheduler.next_index = 0;
        target.log_buffer.write_index = 0;
        target.log_buffer.entry_count = 0;
        target.log_buffer.timer = &target.timer;
        target.user_count = 0;
        target.memory_pool.allocated_pages = 0;
        target.memory_pool.next_free_page = 0;
        target.channels.next_channel_id = 1;
        target.channels.channel_count = 0;
        for (&target.channels.channels) |*ch| {
            ch.allocated = false;
            ch.id = 0;
        }
        target.user_count = 1;
    }

    fn init_users(self: *BasinKernel) void {
        Debug.vprint("Creating root user...", .{});
        var root = User.init();
        root.uid = 0;
        root.gid = 0;
        @memcpy(root.name[0..4], "root");
        @memcpy(root.home[0..5], "/root");
        root.capabilities = 0xFFFFFFFFFFFFFFFF;
        root.validate();
        self.users[0] = root;
        Debug.vprint("Creating xy user...", .{});
        var xy = User.init();
        xy.uid = 1000;
        xy.gid = 1000;
        @memcpy(xy.name[0..2], "xy");
        @memcpy(xy.home[0..8], "/home/xy");
        xy.capabilities = 0x0000000000000001;
        xy.validate();
        self.users[1] = xy;
        self.user_count = 2;
        Debug.kassert(self.users[0].uid == 0, "Root UID check failed", .{});
        Debug.kassert(self.users[1].uid == 1000, "XY UID check failed", .{});
    }

    /// Why: Look up user record for permission checks.
    pub fn find_user_by_uid(self: *const BasinKernel, uid: UserId) ?u32 {
        for (0..self.user_count) |i| {
            if (self.users[i].uid == uid) return @as(u32, @intCast(i));
        }
        return null;
    }

    /// Why: Look up user record by username.
    pub fn find_user_by_name(self: *const BasinKernel, name: []const u8) ?u32 {
        for (0..self.user_count) |i| {
            const arr = self.users[i].name;
            var len: u32 = 0;
            for (arr, 0..) |b, idx| {
                if (b == 0) { len = @as(u32, @intCast(idx)); break; }
            }
            if (len == 0) continue;
            if (std.mem.eql(u8, arr[0..len], name)) return @as(u32, @intCast(i));
        }
        return null;
    }

    /// Why: Change current user for permission checks.
    pub fn set_current_user(self: *BasinKernel, uid: UserId) !void {
        const idx = self.find_user_by_uid(uid) orelse return BasinError.user_not_found;
        const user = self.users[idx];
        self.user_context = UserContext.init(user.uid, user.gid);
        Debug.kassert(self.user_context.uid == uid, "Set current user failed", .{});
    }

    /// Why: Provide comprehensive system statistics.
    pub fn get_kernel_stats_snapshot(self: *const BasinKernel) KernelStatsSnapshot {
        return KernelStatsSnapshot.create(
            self.tcp_sockets.get_stats(),
            self.udp_sockets.get_stats(),
            self.network_interfaces.get_stats(),
            self.audio_devices.get_stats(),
            self.scheduler.get_stats(),
            &self.memory_stats,
            &self.page_fault_stats,
        );
    }

    /// Why: Provide profiling summary for performance analysis.
    pub fn get_profiler_summary(self: *const BasinKernel) struct {
        total_syscall_count: u64,
        total_execution_time_ns: u64,
        enabled: bool,
    } {
        return .{
            .total_syscall_count = self.syscall_profiler.get_total_syscall_count(),
            .total_execution_time_ns = self.syscall_profiler.get_total_execution_time_ns(),
            .enabled = self.syscall_profiler.enabled,
        };
    }

    /// Why: Identify syscall with highest call count.
    pub fn find_profiler_hot_path(self: *const BasinKernel) ?struct { syscall_num: u32, call_count: u64 } {
        return self.syscall_profiler.find_hot_path();
    }

    /// Why: Identify slowest syscall for optimization.
    pub fn find_profiler_slow_path(self: *const BasinKernel) ?struct { syscall_num: u32, avg_time_ns: u64 } {
        return self.syscall_profiler.find_slow_path();
    }

    /// Why: Identify multiple hot paths for optimization.
    pub fn get_profiler_top_syscalls_by_count(self: *const BasinKernel, max: u32) struct {
        entries: [150]struct { syscall_num: u32, call_count: u64 },
        count: u32,
    } {
        return self.syscall_profiler.get_top_syscalls_by_count(max);
    }

    /// Why: Identify multiple slow paths for optimization.
    pub fn get_profiler_top_syscalls_by_time(self: *const BasinKernel, max: u32) struct {
        entries: [150]struct { syscall_num: u32, avg_time_ns: u64 },
        count: u32,
    } {
        return self.syscall_profiler.get_top_syscalls_by_time(max);
    }

    fn calculate_process_memory_usage(self: *const BasinKernel, pid: u64) u64 {
        Debug.kassert(pid != 0, "Process ID is 0", .{});
        const pid32 = @as(u32, @truncate(pid));
        var total: u64 = 0;
        for (0..MAX_MAPPINGS) |i| {
            const m = &self.mappings[i];
            if (m.allocated and m.owner_process_id == pid32) total +%= m.size;
        }
        return total;
    }

    /// Why: Keep process memory_used field current.
    pub fn update_process_memory_usage(self: *BasinKernel, pid: u64) void {
        Debug.kassert(pid != 0, "Process ID is 0", .{});
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == pid) {
                self.processes[i].memory_used = self.calculate_process_memory_usage(pid);
                return;
            }
        }
    }

    /// Why: Allocate new mapping entry.
    pub fn find_free_mapping(self: *BasinKernel) ?u32 {
        for (self.mappings, 0..) |mapping, i| {
            if (!mapping.allocated) return @as(u32, @intCast(i));
        }
        return null;
    }

    /// Why: Look up mapping for unmap/protect operations.
    pub fn find_mapping_by_address(self: *BasinKernel, addr: u64) ?u32 {
        Debug.kassert(addr % 4096 == 0, "Address {x} not aligned", .{addr});
        const hash_idx = @as(u32, @truncate((addr / 4096) % MAX_MAPPINGS));
        const cached = self.mapping_addr_to_index[hash_idx];
        if (cached < MAX_MAPPINGS) {
            const m = &self.mappings[cached];
            if (m.allocated and m.address == addr) return cached;
        }
        for (self.mappings, 0..) |m, i| {
            if (m.allocated and m.address == addr) {
                const idx = @as(u32, @intCast(i));
                self.mapping_addr_to_index[hash_idx] = idx;
                return idx;
            }
        }
        return null;
    }

    /// Why: Maintain hash table when new mappings are allocated.
    pub fn add_mapping_to_hash_table(self: *BasinKernel, addr: u64, idx: u32) void {
        Debug.kassert(addr % 4096 == 0, "Address {x} not aligned", .{addr});
        Debug.kassert(idx < MAX_MAPPINGS, "Mapping index out of bounds", .{});
        const hash_idx = @as(u32, @truncate((addr / 4096) % MAX_MAPPINGS));
        self.mapping_addr_to_index[hash_idx] = idx;
    }

    /// Why: Maintain hash table when mappings are deallocated.
    pub fn remove_mapping_from_hash_table(self: *BasinKernel, addr: u64) void {
        Debug.kassert(addr % 4096 == 0, "Address {x} not aligned", .{addr});
        const hash_idx = @as(u32, @truncate((addr / 4096) % MAX_MAPPINGS));
        self.mapping_addr_to_index[hash_idx] = MAX_MAPPINGS;
    }

    /// Why: Enforce memory protection by checking permissions.
    pub fn check_memory_permission(self: *const BasinKernel, addr: u64) ?MapFlags {
        const pf = self.page_table.check_permission(addr) orelse return null;
        return MapFlags{ .read = pf.read, .write = pf.write, .execute = pf.execute, .shared = pf.shared, ._padding = 0 };
    }

    /// Why: Validate no overlapping mappings.
    pub fn check_overlap(self: *BasinKernel, addr: u64, size: u64) bool {
        for (self.mappings) |m| {
            if (m.overlaps(addr, size)) return true;
        }
        return false;
    }

    /// Why: Validate mapping table state consistency.
    pub fn count_allocated_mappings(self: *BasinKernel) u32 {
        var count: u32 = 0;
        for (self.mappings) |m| {
            if (m.allocated) count += 1;
        }
        return count;
    }

    /// Why: Allocate new handle entry.
    pub fn find_free_handle(self: *BasinKernel) ?u32 {
        for (self.handles, 0..) |h, i| {
            if (!h.allocated) return @as(u32, @intCast(i));
        }
        return null;
    }

    /// Why: Look up handle for read/write/close operations.
    pub fn find_handle_by_id(self: *BasinKernel, hid: u64) ?u32 {
        Debug.kassert(hid != 0, "Handle ID is 0", .{});
        if (self.mru_handle_index < MAX_HANDLES and self.mru_handle_id == hid) {
            const mru = &self.handles[self.mru_handle_index];
            if (mru.allocated and mru.id == hid) return self.mru_handle_index;
        }
        const hash_idx = @as(u32, @truncate(hid % MAX_HANDLES));
        const cached = self.handle_id_to_index[hash_idx];
        if (cached < MAX_HANDLES) {
            const h = &self.handles[cached];
            if (h.allocated and h.id == hid) {
                self.mru_handle_index = cached;
                self.mru_handle_id = hid;
                return cached;
            }
        }
        for (self.handles, 0..) |h, i| {
            if (h.allocated and h.id == hid) {
                const idx = @as(u32, @intCast(i));
                self.handle_id_to_index[hash_idx] = idx;
                self.mru_handle_index = idx;
                self.mru_handle_id = hid;
                return idx;
            }
        }
        return null;
    }

    /// Why: Clear MRU cache when handle is closed.
    pub fn invalidate_mru_handle_cache(self: *BasinKernel) void {
        self.mru_handle_index = MAX_HANDLES;
        self.mru_handle_id = 0;
    }

    /// Why: Maintain O(1) handle lookup performance.
    pub fn update_handle_hash_table(self: *BasinKernel, hid: u64, idx: u32) void {
        Debug.kassert(hid != 0, "Handle ID is 0", .{});
        Debug.kassert(idx < MAX_HANDLES, "Handle index >= MAX_HANDLES", .{});
        const hash_idx = @as(u32, @truncate(hid % MAX_HANDLES));
        self.handle_id_to_index[hash_idx] = idx;
    }

    /// Why: Maintain hash table consistency when handles are deallocated.
    pub fn invalidate_handle_hash_table(self: *BasinKernel, hid: u64) void {
        Debug.kassert(hid != 0, "Handle ID is 0", .{});
        const hash_idx = @as(u32, @truncate(hid % MAX_HANDLES));
        self.handle_id_to_index[hash_idx] = MAX_HANDLES;
    }

    /// Why: Look up current process index for resource tracking.
    pub fn find_current_process_index(self: *BasinKernel) ?u32 {
        const pid = self.scheduler.get_current();
        if (pid == 0) { self.current_process_index = MAX_PROCESSES; return null; }
        if (self.current_process_index < MAX_PROCESSES) {
            const cached = &self.processes[self.current_process_index];
            if (cached.allocated and cached.id == pid) return self.current_process_index;
        }
        for (0..MAX_PROCESSES) |i| {
            if (self.processes[i].allocated and self.processes[i].id == pid) {
                const idx = @as(u32, @intCast(i));
                self.current_process_index = idx;
                return idx;
            }
        }
        self.current_process_index = MAX_PROCESSES;
        return null;
    }

    /// Why: Clear cache when process state changes.
    pub fn invalidate_current_process_cache(self: *BasinKernel) void {
        self.current_process_index = MAX_PROCESSES;
    }

    /// Why: Validate handle table state consistency.
    pub fn count_allocated_handles(self: *BasinKernel) u32 {
        var count: u32 = 0;
        for (self.handles) |h| {
            if (h.allocated) count += 1;
        }
        return count;
    }

    /// Why: Helper function to check timeout expiration for syscalls.
    pub fn check_timeout(self: *const BasinKernel, start: u64, timeout: u64) bool {
        if (timeout == 0) return false;
        const now = self.timer.get_monotonic_ns();
        Debug.kassert(now >= start, "Current time < start time", .{});
        return (now - start) >= timeout;
    }

    fn check_cpu_time_limit(_: *const BasinKernel, p: *const Process) bool {
        if (p.max_cpu_time_ns == 0) return false;
        return p.cpu_time_ns > p.max_cpu_time_ns;
    }

    fn can_allocate_memory(_: *const BasinKernel, p: *const Process, bytes: u64) bool {
        if (p.max_memory_bytes == 0) return true;
        return (p.memory_used +% bytes) <= p.max_memory_bytes;
    }

    /// Why: Enforce file descriptor limits before opening files.
    pub fn can_open_file_descriptor(_: *const BasinKernel, p: *const Process) bool {
        if (p.max_file_descriptors == 0) return true;
        return (p.open_file_descriptors + 1) <= p.max_file_descriptors;
    }

    /// Why: Enforce connection limits before opening connections.
    pub fn can_open_connection(_: *const BasinKernel, p: *const Process) bool {
        if (p.max_connections == 0) return true;
        return (p.open_connections + 1) <= p.max_connections;
    }
};
