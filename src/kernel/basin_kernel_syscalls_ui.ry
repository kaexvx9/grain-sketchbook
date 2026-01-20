//! Basin Kernel UI DAG Syscalls
//! Why: Provide syscalls for Grainscript UI applications using toroidal DAG.

const std = @import("std");
const adapter = @import("dag_toroidal_adapter.zig");
const UnifiedDag = adapter.UnifiedDag;
const UnifiedNodeType = adapter.UnifiedNodeType;
const UnifiedEventType = adapter.UnifiedEventType;
const NodeHandle = adapter.NodeHandle;

/// Why: Maximum UI DAGs per kernel (one per application).
pub const MAX_UI_DAGS: u32 = 16;

/// Why: UI DAG slot for per-application state.
pub const UiDagSlot = struct {
    dag: UnifiedDag,
    allocated: bool,
    owner_pid: u32,

    /// Why: Initialize empty slot.
    pub fn init() UiDagSlot {
        return UiDagSlot{
            .dag = UnifiedDag.init(),
            .allocated = false,
            .owner_pid = 0,
        };
    }
};

/// Why: UI DAG manager for all applications.
pub const UiDagManager = struct {
    slots: [MAX_UI_DAGS]UiDagSlot,
    slot_count: u32,

    /// Why: Initialize UI DAG manager.
    pub fn init() UiDagManager {
        var mgr = UiDagManager{
            .slots = undefined,
            .slot_count = 0,
        };
        for (&mgr.slots) |*s| s.* = UiDagSlot.init();
        return mgr;
    }

    /// Why: Create UI DAG for process.
    pub fn create_dag(self: *UiDagManager, pid: u32) ?u32 {
        if (self.slot_count >= MAX_UI_DAGS) return null;
        const slot_idx = self.find_free_slot() orelse return null;
        self.slots[slot_idx].allocated = true;
        self.slots[slot_idx].owner_pid = pid;
        self.slots[slot_idx].dag = UnifiedDag.init();
        self.slot_count += 1;
        return @intCast(slot_idx);
    }

    fn find_free_slot(self: *UiDagManager) ?usize {
        for (&self.slots, 0..) |*s, i| {
            if (!s.allocated) return i;
        }
        return null;
    }

    /// Why: Get DAG by handle.
    pub fn get_dag(self: *UiDagManager, handle: u32) ?*UnifiedDag {
        if (handle >= MAX_UI_DAGS) return null;
        if (!self.slots[handle].allocated) return null;
        return &self.slots[handle].dag;
    }

    /// Why: Destroy UI DAG.
    pub fn destroy_dag(self: *UiDagManager, handle: u32) bool {
        if (handle >= MAX_UI_DAGS) return false;
        if (!self.slots[handle].allocated) return false;
        self.slots[handle] = UiDagSlot.init();
        self.slot_count -= 1;
        return true;
    }

    /// Why: Get slot count.
    pub fn count(self: *const UiDagManager) u32 {
        return self.slot_count;
    }
};

/// Why: UI syscall numbers (starting at 200 to avoid conflicts).
pub const UI_SYSCALL_BASE: u16 = 200;

pub const UiSyscall = enum(u16) {
    create_dag = UI_SYSCALL_BASE + 0,
    destroy_dag = UI_SYSCALL_BASE + 1,
    create_node = UI_SYSCALL_BASE + 2,
    release_node = UI_SYSCALL_BASE + 3,
    add_edge = UI_SYSCALL_BASE + 4,
    push_event = UI_SYSCALL_BASE + 5,
    process_events = UI_SYSCALL_BASE + 6,
    get_node_count = UI_SYSCALL_BASE + 7,
    get_event_count = UI_SYSCALL_BASE + 8,
};

/// Why: UI syscall result.
pub const UiSyscallResult = struct {
    success: bool,
    value: u32,
    error_code: u8,

    /// Why: Success result.
    pub fn ok(value: u32) UiSyscallResult {
        return UiSyscallResult{ .success = true, .value = value, .error_code = 0 };
    }

    /// Why: Error result.
    pub fn err(code: u8) UiSyscallResult {
        return UiSyscallResult{ .success = false, .value = 0, .error_code = code };
    }
};

/// Why: Error codes for UI syscalls.
pub const UiError = enum(u8) {
    none = 0,
    invalid_handle = 1,
    dag_full = 2,
    node_not_found = 3,
    edge_failed = 4,
    permission_denied = 5,
};

/// Why: Handle UI syscall dispatch.
pub fn handle_ui_syscall(
    mgr: *UiDagManager,
    syscall_num: u16,
    arg0: u32,
    arg1: u32,
    arg2: u32,
    pid: u32,
) UiSyscallResult {
    const err_code = @intFromEnum(UiError.invalid_handle);
    const syscall = std.meta.intToEnum(UiSyscall, syscall_num) catch {
        return UiSyscallResult.err(err_code);
    };
    return dispatch_syscall(mgr, syscall, arg0, arg1, arg2, pid);
}

fn dispatch_syscall(
    mgr: *UiDagManager,
    syscall: UiSyscall,
    arg0: u32,
    arg1: u32,
    arg2: u32,
    pid: u32,
) UiSyscallResult {
    switch (syscall) {
        .create_dag => return syscall_create_dag(mgr, pid),
        .destroy_dag => return syscall_destroy_dag(mgr, arg0),
        .create_node => return syscall_create_node(mgr, arg0, arg1),
        .release_node => return syscall_release_node(mgr, arg0, arg1),
        .add_edge => return syscall_add_edge(mgr, arg0, arg1, arg2),
        .push_event => return syscall_push_event(mgr, arg0, arg1, arg2),
        .process_events => return syscall_process_events(mgr, arg0),
        .get_node_count => return syscall_get_node_count(mgr, arg0),
        .get_event_count => return syscall_get_event_count(mgr, arg0),
    }
}

/// Why: Create new UI DAG for calling process.
fn syscall_create_dag(mgr: *UiDagManager, pid: u32) UiSyscallResult {
    const handle = mgr.create_dag(pid) orelse return UiSyscallResult.err(@intFromEnum(UiError.dag_full));
    return UiSyscallResult.ok(handle);
}

/// Why: Destroy UI DAG.
fn syscall_destroy_dag(mgr: *UiDagManager, handle: u32) UiSyscallResult {
    if (mgr.destroy_dag(handle)) return UiSyscallResult.ok(0);
    return UiSyscallResult.err(@intFromEnum(UiError.invalid_handle));
}

/// Why: Create node in DAG.
fn syscall_create_node(mgr: *UiDagManager, handle: u32, node_type: u32) UiSyscallResult {
    const err_inv = @intFromEnum(UiError.invalid_handle);
    const err_full = @intFromEnum(UiError.dag_full);
    const dag = mgr.get_dag(handle) orelse return UiSyscallResult.err(err_inv);
    const nt_u8: u8 = @truncate(node_type);
    const nt = std.meta.intToEnum(UnifiedNodeType, nt_u8) catch {
        return UiSyscallResult.err(err_inv);
    };
    const node = dag.create_node(nt) orelse return UiSyscallResult.err(err_full);
    return UiSyscallResult.ok(node.raw());
}

/// Why: Release node from DAG.
fn syscall_release_node(mgr: *UiDagManager, handle: u32, node_id: u32) UiSyscallResult {
    const dag = mgr.get_dag(handle) orelse return UiSyscallResult.err(@intFromEnum(UiError.invalid_handle));
    if (dag.release_node(NodeHandle.from_raw(node_id))) return UiSyscallResult.ok(0);
    return UiSyscallResult.err(@intFromEnum(UiError.node_not_found));
}

/// Why: Add edge between nodes.
fn syscall_add_edge(mgr: *UiDagManager, handle: u32, from: u32, to: u32) UiSyscallResult {
    const dag = mgr.get_dag(handle) orelse return UiSyscallResult.err(@intFromEnum(UiError.invalid_handle));
    if (dag.add_edge(NodeHandle.from_raw(from), NodeHandle.from_raw(to))) return UiSyscallResult.ok(0);
    return UiSyscallResult.err(@intFromEnum(UiError.edge_failed));
}

/// Why: Push event to node.
fn syscall_push_event(mgr: *UiDagManager, handle: u32, node_id: u32, event_type: u32) UiSyscallResult {
    const err_inv = @intFromEnum(UiError.invalid_handle);
    const dag = mgr.get_dag(handle) orelse return UiSyscallResult.err(err_inv);
    const et_u8: u8 = @truncate(event_type);
    const et = std.meta.intToEnum(UnifiedEventType, et_u8) catch {
        return UiSyscallResult.err(err_inv);
    };
    dag.push_event(NodeHandle.from_raw(node_id), et);
    return UiSyscallResult.ok(0);
}

/// Why: Process pending events.
fn syscall_process_events(mgr: *UiDagManager, handle: u32) UiSyscallResult {
    const dag = mgr.get_dag(handle) orelse return UiSyscallResult.err(@intFromEnum(UiError.invalid_handle));
    const processed = dag.process_events();
    return UiSyscallResult.ok(processed);
}

/// Why: Get node count.
fn syscall_get_node_count(mgr: *UiDagManager, handle: u32) UiSyscallResult {
    const dag = mgr.get_dag(handle) orelse return UiSyscallResult.err(@intFromEnum(UiError.invalid_handle));
    return UiSyscallResult.ok(dag.count());
}

/// Why: Get pending event count.
fn syscall_get_event_count(mgr: *UiDagManager, handle: u32) UiSyscallResult {
    const dag = mgr.get_dag(handle) orelse return UiSyscallResult.err(@intFromEnum(UiError.invalid_handle));
    return UiSyscallResult.ok(dag.pending_events());
}
