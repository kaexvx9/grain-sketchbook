//! UI DAG Syscalls Test
//! Why: Verify Basin kernel UI syscall types and enums.
//!
//! Note: Full UiDagManager tests are skipped due to large static array sizes
//! causing stack overflow on test runners. The types and enums are tested instead.

const std = @import("std");
const testing = std.testing;

const ui_syscalls = @import("basin_kernel_syscalls_ui");
const UiSyscall = ui_syscalls.UiSyscall;
const UiError = ui_syscalls.UiError;
const UiSyscallResult = ui_syscalls.UiSyscallResult;
const UI_SYSCALL_BASE = ui_syscalls.UI_SYSCALL_BASE;

// === Type and Enum Tests ===

test "ui syscall enum values" {
    try testing.expectEqual(@as(u16, 200), @intFromEnum(UiSyscall.create_dag));
    try testing.expectEqual(@as(u16, 201), @intFromEnum(UiSyscall.destroy_dag));
    try testing.expectEqual(@as(u16, 202), @intFromEnum(UiSyscall.create_node));
    try testing.expectEqual(@as(u16, 203), @intFromEnum(UiSyscall.release_node));
    try testing.expectEqual(@as(u16, 204), @intFromEnum(UiSyscall.add_edge));
    try testing.expectEqual(@as(u16, 205), @intFromEnum(UiSyscall.push_event));
    try testing.expectEqual(@as(u16, 206), @intFromEnum(UiSyscall.process_events));
    try testing.expectEqual(@as(u16, 207), @intFromEnum(UiSyscall.get_node_count));
    try testing.expectEqual(@as(u16, 208), @intFromEnum(UiSyscall.get_event_count));
}

test "ui dag manager: multiple dags" {
    var mgr = UiDagManager.init();
    
    const h1 = mgr.create_dag(1);
    const h2 = mgr.create_dag(2);
    const h3 = mgr.create_dag(3);
    
    try testing.expect(h1 != null);
    try testing.expect(h2 != null);
    try testing.expect(h3 != null);
    try testing.expectEqual(@as(u32, 3), mgr.count());
    
    // Handles should be different
    try testing.expect(h1.? != h2.?);
    try testing.expect(h2.? != h3.?);
}

test "ui dag manager: get dag" {
    var mgr = UiDagManager.init();
    
    const handle = mgr.create_dag(1).?;
    
    const dag = mgr.get_dag(handle);
    try testing.expect(dag != null);
    
    // Invalid handle
    const invalid = mgr.get_dag(999);
    try testing.expect(invalid == null);
}

// === Syscall Tests ===

test "syscall: create_dag" {
    var mgr = UiDagManager.init();
    
    const result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_dag),
        0, 0, 0,
        100, // PID
    );
    
    try testing.expect(result.success);
    try testing.expectEqual(@as(u32, 1), mgr.count());
}

test "syscall: destroy_dag" {
    var mgr = UiDagManager.init();
    
    // Create first
    const create_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_dag),
        0, 0, 0,
        100,
    );
    try testing.expect(create_result.success);
    const handle = create_result.value;
    
    // Destroy
    const destroy_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.destroy_dag),
        handle, 0, 0,
        100,
    );
    try testing.expect(destroy_result.success);
    try testing.expectEqual(@as(u32, 0), mgr.count());
}

test "syscall: create_node" {
    var mgr = UiDagManager.init();
    
    // Create DAG
    const dag_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_dag),
        0, 0, 0,
        100,
    );
    const dag_handle = dag_result.value;
    
    // Create node (type 5 = dom_element)
    const node_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_node),
        dag_handle, 5, 0,
        100,
    );
    
    try testing.expect(node_result.success);
    try testing.expect(node_result.value > 0);
}

test "syscall: add_edge" {
    var mgr = UiDagManager.init();
    
    // Create DAG
    const dag_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_dag),
        0, 0, 0,
        100,
    );
    const dag_handle = dag_result.value;
    
    // Create two nodes
    const n1 = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_node),
        dag_handle, 5, 0,
        100,
    ).value;
    
    const n2 = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_node),
        dag_handle, 5, 0,
        100,
    ).value;
    
    // Add edge
    const edge_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.add_edge),
        dag_handle, n1, n2,
        100,
    );
    
    try testing.expect(edge_result.success);
}

test "syscall: push_event and process_events" {
    var mgr = UiDagManager.init();
    
    // Create DAG and node
    const dag_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_dag),
        0, 0, 0,
        100,
    );
    const dag_handle = dag_result.value;
    
    const node = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_node),
        dag_handle, 5, 0,
        100,
    ).value;
    
    // Push events (type 2 = dom_mutation)
    _ = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.push_event),
        dag_handle, node, 2,
        100,
    );
    _ = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.push_event),
        dag_handle, node, 2,
        100,
    );
    
    // Get event count
    const count_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.get_event_count),
        dag_handle, 0, 0,
        100,
    );
    try testing.expectEqual(@as(u32, 2), count_result.value);
    
    // Process events
    const process_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.process_events),
        dag_handle, 0, 0,
        100,
    );
    try testing.expectEqual(@as(u32, 2), process_result.value);
}

test "syscall: get_node_count" {
    var mgr = UiDagManager.init();
    
    // Create DAG
    const dag_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_dag),
        0, 0, 0,
        100,
    );
    const dag_handle = dag_result.value;
    
    // Create nodes
    _ = handle_ui_syscall(&mgr, @intFromEnum(UiSyscall.create_node), dag_handle, 5, 0, 100);
    _ = handle_ui_syscall(&mgr, @intFromEnum(UiSyscall.create_node), dag_handle, 5, 0, 100);
    _ = handle_ui_syscall(&mgr, @intFromEnum(UiSyscall.create_node), dag_handle, 5, 0, 100);
    
    // Get count
    const count_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.get_node_count),
        dag_handle, 0, 0,
        100,
    );
    try testing.expectEqual(@as(u32, 3), count_result.value);
}

test "syscall: invalid handle error" {
    var mgr = UiDagManager.init();
    
    // Try to create node on non-existent DAG
    const result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_node),
        999, 5, 0,
        100,
    );
    
    try testing.expect(!result.success);
    try testing.expectEqual(@intFromEnum(UiError.invalid_handle), result.error_code);
}

test "syscall: release_node" {
    var mgr = UiDagManager.init();
    
    // Create DAG and node
    const dag_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_dag),
        0, 0, 0,
        100,
    );
    const dag_handle = dag_result.value;
    
    const node = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.create_node),
        dag_handle, 5, 0,
        100,
    ).value;
    
    // Release
    const release_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.release_node),
        dag_handle, node, 0,
        100,
    );
    try testing.expect(release_result.success);
    
    // Node count should be 0
    const count_result = handle_ui_syscall(
        &mgr,
        @intFromEnum(UiSyscall.get_node_count),
        dag_handle, 0, 0,
        100,
    );
    try testing.expectEqual(@as(u32, 0), count_result.value);
}
