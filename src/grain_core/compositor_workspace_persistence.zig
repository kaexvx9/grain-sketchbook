//! Grain Core Compositor Workspace Persistence: Save/load workspace and window state.
//!
//! Why: Persist compositor workspace and window state across sessions.
//! Architecture: JSON serialization with IntegratedFileIO for storage.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const integrated_file_io = @import("integrated_file_io.zig");

// Bounded: Max number of workspaces.
pub const MAX_WORKSPACES: u32 = 10;

// Bounded: Max number of windows.
pub const MAX_WINDOWS: u32 = 256;

// Bounded: Max workspace name length.
pub const MAX_WORKSPACE_NAME_LEN: u32 = 32;

// Bounded: Max window title length.
pub const MAX_WINDOW_TITLE_LEN: u32 = 256;

// Workspace configuration structure.
pub const WorkspaceConfig = struct {
    id: u32,
    name: [MAX_WORKSPACE_NAME_LEN]u8,
    name_len: u32,
    window_ids: [MAX_WINDOWS]u32,
    window_ids_len: u32,
    focused_window_id: u32,
    visible: bool,
};

// Window state entry structure.
pub const WindowStateEntry = struct {
    window_id: u32,
    workspace_id: u32,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    minimized: bool,
    maximized: bool,
    title: [MAX_WINDOW_TITLE_LEN]u8,
    title_len: u32,
};

// Workspace state structure (for atomic save/load).
pub const WorkspaceState = struct {
    current_workspace_id: u32,
    workspaces: [MAX_WORKSPACES]WorkspaceConfig,
    workspaces_len: u32,
};

// Base path for compositor persistence.
const COMPOSITOR_BASE_PATH: []const u8 = "~/.grain/compositor";

// Workspaces file path.
const WORKSPACES_FILE: []const u8 = "~/.grain/compositor/workspaces.json";

// Windows directory path.
const WINDOWS_DIR: []const u8 = "~/.grain/compositor/windows";

// Save workspace configuration to persistent storage.
pub fn save_workspace_config(
    io: *integrated_file_io.IntegratedFileIO,
    workspace_id: u32,
    workspace: *const WorkspaceConfig,
    current_time: u64,
    user_id: u32,
    group_id: u32,
    allocator: std.mem.Allocator,
) !void {
    std.debug.assert(io != null);
    std.debug.assert(workspace != null);
    std.debug.assert(workspace_id > 0);
    std.debug.assert(workspace_id <= MAX_WORKSPACES);
    std.debug.assert(user_id > 0);
    const file_path = try std.fmt.allocPrint(
        allocator,
        "{s}/workspaces/workspace_{d}.json",
        .{ COMPOSITOR_BASE_PATH, workspace_id },
    );
    defer allocator.free(file_path);
    const json_data = try serialize_workspace_config(workspace, allocator);
    defer allocator.free(json_data);
    try io.write_file(allocator, file_path, json_data, current_time, user_id, group_id);
}

// Load workspace configuration from persistent storage.
pub fn load_workspace_config(
    io: *integrated_file_io.IntegratedFileIO,
    workspace_id: u32,
    workspace: *WorkspaceConfig,
    current_time: u64,
    user_id: u32,
    group_id: u32,
    allocator: std.mem.Allocator,
) !bool {
    std.debug.assert(io != null);
    std.debug.assert(workspace != null);
    std.debug.assert(workspace_id > 0);
    std.debug.assert(workspace_id <= MAX_WORKSPACES);
    std.debug.assert(user_id > 0);
    const file_path = try std.fmt.allocPrint(
        allocator,
        "{s}/workspaces/workspace_{d}.json",
        .{ COMPOSITOR_BASE_PATH, workspace_id },
    );
    defer allocator.free(file_path);
    const json_data = io.read_file(allocator, file_path, current_time, user_id, group_id) catch |err| {
        if (err == error.FileNotFound) {
            return false;
        }
        return err;
    };
    defer allocator.free(json_data);
    try deserialize_workspace_config(json_data, workspace);
    return true;
}

// Save all workspaces atomically.
pub fn save_all_workspaces(
    io: *integrated_file_io.IntegratedFileIO,
    workspaces: []const WorkspaceConfig,
    current_workspace_id: u32,
    current_time: u64,
    user_id: u32,
    group_id: u32,
    allocator: std.mem.Allocator,
) !void {
    std.debug.assert(io != null);
    std.debug.assert(workspaces.len <= MAX_WORKSPACES);
    std.debug.assert(current_workspace_id > 0);
    std.debug.assert(current_workspace_id <= MAX_WORKSPACES);
    std.debug.assert(user_id > 0);
    const state = WorkspaceState{
        .current_workspace_id = current_workspace_id,
        .workspaces = undefined,
        .workspaces_len = @intCast(workspaces.len),
    };
    @memcpy(state.workspaces[0..workspaces.len], workspaces);
    const json_data = try serialize_workspace_state(&state, allocator);
    defer allocator.free(json_data);
    const tmp_path = try std.fmt.allocPrint(allocator, "{s}.tmp", .{WORKSPACES_FILE});
    defer allocator.free(tmp_path);
    try io.write_file(allocator, tmp_path, json_data, current_time, user_id, group_id);
    // TODO: Atomic rename (requires path_resolver integration)
    try io.write_file(allocator, WORKSPACES_FILE, json_data, current_time, user_id, group_id);
}

// Load all workspaces from persistent storage.
pub fn load_all_workspaces(
    io: *integrated_file_io.IntegratedFileIO,
    workspaces: *[MAX_WORKSPACES]WorkspaceConfig,
    current_workspace_id: *u32,
    current_time: u64,
    user_id: u32,
    group_id: u32,
    allocator: std.mem.Allocator,
) !u32 {
    std.debug.assert(io != null);
    std.debug.assert(workspaces != null);
    std.debug.assert(current_workspace_id != null);
    std.debug.assert(user_id > 0);
    const json_data = io.read_file(allocator, WORKSPACES_FILE, current_time, user_id, group_id) catch |err| {
        if (err == error.FileNotFound) {
            return 0;
        }
        return err;
    };
    defer allocator.free(json_data);
    var state = WorkspaceState{
        .current_workspace_id = 0,
        .workspaces = undefined,
        .workspaces_len = 0,
    };
    try deserialize_workspace_state(json_data, &state);
    current_workspace_id.* = state.current_workspace_id;
    @memcpy(workspaces[0..state.workspaces_len], state.workspaces[0..state.workspaces_len]);
    return state.workspaces_len;
}

// Save window state to persistent storage.
pub fn save_window_state(
    io: *integrated_file_io.IntegratedFileIO,
    window_state: *const WindowStateEntry,
    current_time: u64,
    user_id: u32,
    group_id: u32,
    allocator: std.mem.Allocator,
) !void {
    std.debug.assert(io != null);
    std.debug.assert(window_state != null);
    std.debug.assert(window_state.window_id > 0);
    std.debug.assert(user_id > 0);
    const file_path = try std.fmt.allocPrint(
        allocator,
        "{s}/window_{d}.json",
        .{ WINDOWS_DIR, window_state.window_id },
    );
    defer allocator.free(file_path);
    const json_data = try serialize_window_state(window_state, allocator);
    defer allocator.free(json_data);
    try io.write_file(allocator, file_path, json_data, current_time, user_id, group_id);
}

// Load window state from persistent storage.
pub fn load_window_state(
    io: *integrated_file_io.IntegratedFileIO,
    window_state: *WindowStateEntry,
    current_time: u64,
    user_id: u32,
    group_id: u32,
    allocator: std.mem.Allocator,
) !bool {
    std.debug.assert(io != null);
    std.debug.assert(window_state != null);
    std.debug.assert(window_state.window_id > 0);
    std.debug.assert(user_id > 0);
    const file_path = try std.fmt.allocPrint(
        allocator,
        "{s}/window_{d}.json",
        .{ WINDOWS_DIR, window_state.window_id },
    );
    defer allocator.free(file_path);
    const json_data = io.read_file(allocator, file_path, current_time, user_id, group_id) catch |err| {
        if (err == error.FileNotFound) {
            return false;
        }
        return err;
    };
    defer allocator.free(json_data);
    try deserialize_window_state(json_data, window_state);
    return true;
}

// List all saved window IDs.
pub fn list_saved_window_ids(
    io: *integrated_file_io.IntegratedFileIO,
    window_ids: *[MAX_WINDOWS]u32,
    current_time: u64,
    user_id: u32,
    group_id: u32,
    allocator: std.mem.Allocator,
) !u32 {
    std.debug.assert(io != null);
    std.debug.assert(window_ids != null);
    std.debug.assert(user_id > 0);
    // TODO: Implement directory listing (requires path_resolver integration)
    // For now, return 0 (no windows found)
    _ = current_time;
    _ = group_id;
    _ = allocator;
    return 0;
}

// Serialize workspace configuration to JSON.
fn serialize_workspace_config(
    workspace: *const WorkspaceConfig,
    allocator: std.mem.Allocator,
) ![]u8 {
    std.debug.assert(workspace != null);
    var json = std.ArrayList(u8).init(allocator);
    defer json.deinit();
    const writer = json.writer();
    try writer.print(
        \\{{"id":{d},"name":"{s}","window_ids":[
    ,
        .{ workspace.id, workspace.name[0..workspace.name_len] },
    );
    var i: u32 = 0;
    while (i < workspace.window_ids_len) : (i += 1) {
        if (i > 0) try writer.writeAll(",");
        try writer.print("{d}", .{workspace.window_ids[i]});
    }
    try writer.print(
        \\],"focused_window_id":{d},"visible":{s}}}
    ,
        .{ workspace.focused_window_id, if (workspace.visible) "true" else "false" },
    );
    return json.toOwnedSlice();
}

// Deserialize workspace configuration from JSON.
fn deserialize_workspace_config(
    json_data: []const u8,
    workspace: *WorkspaceConfig,
) !void {
    std.debug.assert(json_data.len > 0);
    std.debug.assert(workspace != null);
    var parsed = try std.json.parseFromSlice(
        std.json.Value,
        std.heap.page_allocator,
        json_data,
        .{},
    );
    defer parsed.deinit();
    if (parsed.value != .object) return error.InvalidFormat;
    const obj = parsed.value.object;
    workspace.id = if (obj.get("id")) |v| @intCast(v.integer) else return error.InvalidFormat;
    if (obj.get("name")) |v| {
        if (v != .string) return error.InvalidFormat;
        const name_len = @min(v.string.len, MAX_WORKSPACE_NAME_LEN);
        @memset(workspace.name[0..], 0);
        @memcpy(workspace.name[0..name_len], v.string[0..name_len]);
        workspace.name_len = @intCast(name_len);
    }
    workspace.window_ids_len = 0;
    if (obj.get("window_ids")) |v| {
        if (v != .array) return error.InvalidFormat;
        const arr_len = @min(v.array.items.len, MAX_WINDOWS);
        var i: u32 = 0;
        while (i < arr_len) : (i += 1) {
            workspace.window_ids[i] = @intCast(v.array.items[i].integer);
        }
        workspace.window_ids_len = @intCast(arr_len);
    }
    workspace.focused_window_id = if (obj.get("focused_window_id")) |v| @intCast(v.integer) else 0;
    workspace.visible = if (obj.get("visible")) |v| (v == .bool and v.bool) else false;
}

// Serialize workspace state to JSON.
fn serialize_workspace_state(
    state: *const WorkspaceState,
    allocator: std.mem.Allocator,
) ![]u8 {
    std.debug.assert(state != null);
    var json = std.ArrayList(u8).init(allocator);
    defer json.deinit();
    const writer = json.writer();
    try writer.print(
        \\{{"current_workspace_id":{d},"workspaces":[
    ,
        .{state.current_workspace_id},
    );
    var i: u32 = 0;
    while (i < state.workspaces_len) : (i += 1) {
        if (i > 0) try writer.writeAll(",");
        const ws_json = try serialize_workspace_config(&state.workspaces[i], allocator);
        defer allocator.free(ws_json);
        try writer.writeAll(ws_json);
    }
    try writer.writeAll("]}");
    return json.toOwnedSlice();
}

// Deserialize workspace state from JSON.
fn deserialize_workspace_state(
    json_data: []const u8,
    state: *WorkspaceState,
) !void {
    std.debug.assert(json_data.len > 0);
    std.debug.assert(state != null);
    var parsed = try std.json.parseFromSlice(
        std.json.Value,
        std.heap.page_allocator,
        json_data,
        .{},
    );
    defer parsed.deinit();
    if (parsed.value != .object) return error.InvalidFormat;
    const obj = parsed.value.object;
    state.current_workspace_id = if (obj.get("current_workspace_id")) |v| @intCast(v.integer) else 0;
    state.workspaces_len = 0;
    if (obj.get("workspaces")) |v| {
        if (v != .array) return error.InvalidFormat;
        const arr_len = @min(v.array.items.len, MAX_WORKSPACES);
        var i: u32 = 0;
        while (i < arr_len) : (i += 1) {
            if (v.array.items[i] != .object) continue;
            const ws_obj = v.array.items[i].object;
            state.workspaces[i].id = if (ws_obj.get("id")) |id| @intCast(id.integer) else 0;
            if (ws_obj.get("name")) |name_val| {
                if (name_val != .string) continue;
                const name_len = @min(name_val.string.len, MAX_WORKSPACE_NAME_LEN);
                @memset(state.workspaces[i].name[0..], 0);
                @memcpy(state.workspaces[i].name[0..name_len], name_val.string[0..name_len]);
                state.workspaces[i].name_len = @intCast(name_len);
            }
            state.workspaces[i].window_ids_len = 0;
            if (ws_obj.get("window_ids")) |ids_val| {
                if (ids_val != .array) continue;
                const ids_len = @min(ids_val.array.items.len, MAX_WINDOWS);
                var j: u32 = 0;
                while (j < ids_len) : (j += 1) {
                    state.workspaces[i].window_ids[j] = @intCast(ids_val.array.items[j].integer);
                }
                state.workspaces[i].window_ids_len = @intCast(ids_len);
            }
            state.workspaces[i].focused_window_id = if (ws_obj.get("focused_window_id")) |fid| @intCast(fid.integer) else 0;
            state.workspaces[i].visible = if (ws_obj.get("visible")) |vis| (vis == .bool and vis.bool) else false;
        }
        state.workspaces_len = @intCast(arr_len);
    }
}

// Serialize window state to JSON.
fn serialize_window_state(
    window_state: *const WindowStateEntry,
    allocator: std.mem.Allocator,
) ![]u8 {
    std.debug.assert(window_state != null);
    var json = std.ArrayList(u8).init(allocator);
    defer json.deinit();
    const writer = json.writer();
    try writer.print(
        \\{{"window_id":{d},"workspace_id":{d},"x":{d},"y":{d},"width":{d},"height":{d},"minimized":{s},"maximized":{s},"title":"{s}"}}
    ,
        .{
            window_state.window_id,
            window_state.workspace_id,
            window_state.x,
            window_state.y,
            window_state.width,
            window_state.height,
            if (window_state.minimized) "true" else "false",
            if (window_state.maximized) "true" else "false",
            window_state.title[0..window_state.title_len],
        },
    );
    return json.toOwnedSlice();
}

// Deserialize window state from JSON.
fn deserialize_window_state(
    json_data: []const u8,
    window_state: *WindowStateEntry,
) !void {
    std.debug.assert(json_data.len > 0);
    std.debug.assert(window_state != null);
    var parsed = try std.json.parseFromSlice(
        std.json.Value,
        std.heap.page_allocator,
        json_data,
        .{},
    );
    defer parsed.deinit();
    if (parsed.value != .object) return error.InvalidFormat;
    const obj = parsed.value.object;
    window_state.window_id = if (obj.get("window_id")) |v| @intCast(v.integer) else return error.InvalidFormat;
    window_state.workspace_id = if (obj.get("workspace_id")) |v| @intCast(v.integer) else 0;
    window_state.x = if (obj.get("x")) |v| @intCast(v.integer) else 0;
    window_state.y = if (obj.get("y")) |v| @intCast(v.integer) else 0;
    window_state.width = if (obj.get("width")) |v| @intCast(v.integer) else 0;
    window_state.height = if (obj.get("height")) |v| @intCast(v.integer) else 0;
    window_state.minimized = if (obj.get("minimized")) |v| (v == .bool and v.bool) else false;
    window_state.maximized = if (obj.get("maximized")) |v| (v == .bool and v.bool) else false;
    if (obj.get("title")) |v| {
        if (v != .string) return error.InvalidFormat;
        const title_len = @min(v.string.len, MAX_WINDOW_TITLE_LEN);
        @memset(window_state.title[0..], 0);
        @memcpy(window_state.title[0..title_len], v.string[0..title_len]);
        window_state.title_len = @intCast(title_len);
    }
}

