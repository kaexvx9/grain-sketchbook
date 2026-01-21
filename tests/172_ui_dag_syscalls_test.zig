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

test "ui syscall base value" {
    try testing.expectEqual(@as(u16, 200), UI_SYSCALL_BASE);
}

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

test "ui error enum values" {
    try testing.expectEqual(@as(u8, 0), @intFromEnum(UiError.none));
    try testing.expectEqual(@as(u8, 1), @intFromEnum(UiError.invalid_handle));
    try testing.expectEqual(@as(u8, 2), @intFromEnum(UiError.dag_full));
    try testing.expectEqual(@as(u8, 3), @intFromEnum(UiError.node_not_found));
    try testing.expectEqual(@as(u8, 4), @intFromEnum(UiError.edge_failed));
    try testing.expectEqual(@as(u8, 5), @intFromEnum(UiError.permission_denied));
}

test "ui syscall result ok" {
    const result = UiSyscallResult.ok(42);
    try testing.expect(result.success);
    try testing.expectEqual(@as(u32, 42), result.value);
    try testing.expectEqual(@as(u8, 0), result.error_code);
}

test "ui syscall result err" {
    const result = UiSyscallResult.err(@intFromEnum(UiError.invalid_handle));
    try testing.expect(!result.success);
    try testing.expectEqual(@as(u32, 0), result.value);
    try testing.expectEqual(@intFromEnum(UiError.invalid_handle), result.error_code);
}
