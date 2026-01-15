# Core 1d Compositor Agent: Phase 7 Helper Functions Template

**Date**: 2026-01-06-093500-pst  
**Agent**: Core 1d Compositor Agent (L2 Sub-Agent)  
**Parent Agent**: Core 1 Subcore Agent (L1 Subcore)  
**Status**: ✅ **HELPER FUNCTIONS TEMPLATE READY** — Implementation-ready function templates prepared

---

## Purpose

This document provides implementation-ready helper function templates for Phase 7 workspace persistence integration. These functions can be implemented once Storage Agent initialization details are coordinated.

---

## Helper Function Templates

### 1. Workspace State Serialization Helper

**Purpose**: Convert workspace manager state to Storage Agent format

**Location**: `src/grain_core/compositor.zig` (private helper function)

**Template**:
```zig
// Serialize workspace manager state for persistence.
// Why: Convert in-memory workspace state to Storage Agent format.
// Contract: Returns array of WorkspaceConfig, caller must free.
fn serialize_workspace_state(
    self: *const Compositor,
    allocator: std.mem.Allocator,
) ![]compositor_workspace_persistence.WorkspaceConfig {
    std.debug.assert(self != null);
    var configs: [workspace.MAX_WORKSPACES]compositor_workspace_persistence.WorkspaceConfig = undefined;
    var configs_len: u32 = 0;
    
    var i: u32 = 0;
    while (i < self.workspace_manager.workspaces_len) : (i += 1) {
        const ws = &self.workspace_manager.workspaces[i];
        configs[configs_len] = compositor_workspace_persistence.WorkspaceConfig{
            .id = ws.id,
            .name = ws.name,
            .name_len = ws.name_len,
            .window_ids = ws.window_ids,
            .window_ids_len = ws.window_ids_len,
            .focused_window_id = ws.focused_window_id,
            .visible = ws.visible,
        };
        configs_len += 1;
    }
    
    const result = try allocator.alloc(compositor_workspace_persistence.WorkspaceConfig, configs_len);
    @memcpy(result[0..configs_len], configs[0..configs_len]);
    std.debug.assert(result.len == configs_len);
    return result;
}
```

**Usage**:
```zig
const configs = try serialize_workspace_state(self, allocator);
defer allocator.free(configs);
try compositor_workspace_persistence.save_all_workspaces(
    io,
    configs,
    self.workspace_manager.current_workspace_id,
    current_time,
    user_id,
    group_id,
    allocator,
);
```

---

### 2. Workspace Restoration Helper

**Purpose**: Restore workspace manager from loaded state

**Location**: `src/grain_core/compositor.zig` (private helper function)

**Template**:
```zig
// Restore workspace manager from loaded state.
// Why: Restore in-memory workspace state from Storage Agent format.
// Contract: Validates loaded state before restoring.
fn restore_workspaces_from_config(
    self: *Compositor,
    configs: []const compositor_workspace_persistence.WorkspaceConfig,
    current_workspace_id: u32,
) void {
    std.debug.assert(self != null);
    std.debug.assert(configs.len <= workspace.MAX_WORKSPACES);
    std.debug.assert(current_workspace_id > 0);
    std.debug.assert(current_workspace_id <= workspace.MAX_WORKSPACES);
    
    // Clear existing workspaces (keep structure)
    self.workspace_manager.workspaces_len = 0;
    
    // Restore workspaces from configs
    var i: u32 = 0;
    while (i < configs.len) : (i += 1) {
        const config = &configs[i];
        // Validate config
        if (config.id == 0 or config.id > workspace.MAX_WORKSPACES) {
            continue; // Skip invalid workspace
        }
        if (config.window_ids_len > workspace.MAX_WORKSPACE_WINDOWS) {
            continue; // Skip workspace with too many windows
        }
        
        // Create workspace from config
        var ws = workspace.Workspace.init(config.id, config.name[0..config.name_len]);
        ws.focused_window_id = config.focused_window_id;
        ws.visible = config.visible;
        
        // Restore window assignments
        var j: u32 = 0;
        while (j < config.window_ids_len) : (j += 1) {
            const window_id = config.window_ids[j];
            if (window_id > 0 and window_id <= compositor.MAX_WINDOWS) {
                _ = ws.add_window(window_id);
            }
        }
        
        self.workspace_manager.workspaces[self.workspace_manager.workspaces_len] = ws;
        self.workspace_manager.workspaces_len += 1;
    }
    
    // Set current workspace
    if (self.workspace_manager.get_workspace(current_workspace_id)) |current_ws| {
        // Hide all workspaces first
        var k: u32 = 0;
        while (k < self.workspace_manager.workspaces_len) : (k += 1) {
            self.workspace_manager.workspaces[k].visible = false;
        }
        // Show current workspace
        current_ws.visible = true;
        self.workspace_manager.current_workspace_id = current_workspace_id;
    } else {
        // Current workspace not found, use first workspace
        if (self.workspace_manager.workspaces_len > 0) {
            self.workspace_manager.workspaces[0].visible = true;
            self.workspace_manager.current_workspace_id = self.workspace_manager.workspaces[0].id;
        }
    }
    
    std.debug.assert(self.workspace_manager.current_workspace_id > 0);
}
```

**Usage**:
```zig
var loaded_workspaces: [workspace.MAX_WORKSPACES]compositor_workspace_persistence.WorkspaceConfig = undefined;
var current_workspace_id: u32 = 0;
const workspaces_len = try compositor_workspace_persistence.load_all_workspaces(
    io,
    &loaded_workspaces,
    &current_workspace_id,
    current_time,
    user_id,
    group_id,
    allocator,
);

if (workspaces_len > 0) {
    restore_workspaces_from_config(self, loaded_workspaces[0..workspaces_len], current_workspace_id);
}
```

---

### 3. Window State Conversion Helper

**Purpose**: Convert compositor window state to Storage Agent format

**Location**: `src/grain_core/compositor.zig` (private helper function)

**Template**:
```zig
// Convert compositor window state to Storage Agent format.
// Why: Convert in-memory window state to Storage Agent format.
// Contract: Returns WindowStateEntry, caller must validate window exists.
fn convert_window_state_to_entry(
    self: *const Compositor,
    window_id: u32,
    workspace_id: u32,
) ?compositor_workspace_persistence.WindowStateEntry {
    std.debug.assert(self != null);
    std.debug.assert(window_id > 0);
    std.debug.assert(workspace_id > 0);
    
    // Get window from compositor
    const window = self.get_window(window_id) orelse return null;
    
    // Get window state from state manager
    const state = self.state_manager.get_window_state(window_id) orelse {
        // No saved state, use current window state
        return compositor_workspace_persistence.WindowStateEntry{
            .window_id = window_id,
            .workspace_id = workspace_id,
            .x = window.x,
            .y = window.y,
            .width = window.width,
            .height = window.height,
            .minimized = window.minimized,
            .maximized = window.maximized,
            .title = window.title,
            .title_len = window.title_len,
        };
    };
    
    // Use saved state
    return compositor_workspace_persistence.WindowStateEntry{
        .window_id = window_id,
        .workspace_id = workspace_id,
        .x = state.x,
        .y = state.y,
        .width = state.width,
        .height = state.height,
        .minimized = state.minimized,
        .maximized = state.maximized,
        .title = state.title,
        .title_len = state.title_len,
    };
}
```

**Usage**:
```zig
if (convert_window_state_to_entry(self, window_id, workspace_id)) |entry| {
    try compositor_workspace_persistence.save_window_state(
        io,
        &entry,
        current_time,
        user_id,
        group_id,
        allocator,
    );
}
```

---

### 4. Error Handling Helper (Graceful Degradation)

**Purpose**: Wrap persistence operations with error handling

**Location**: `src/grain_core/compositor.zig` (private helper function)

**Template**:
```zig
// Save workspace state with error handling (graceful degradation).
// Why: Persistence failures should not break compositor functionality.
// Contract: Logs errors but continues operation.
fn save_workspace_state_persistent_safe(
    self: *Compositor,
) void {
    std.debug.assert(self != null);
    
    if (self.file_io) |*io| {
        const current_time = get_current_timestamp(); // TODO: Get from time manager
        const user_id = get_current_user_id(); // TODO: Get from system
        const group_id = get_current_group_id(); // TODO: Get from system
        
        save_workspace_state_persistent_impl(self, io, current_time, user_id, group_id) catch |err| {
            // Log error but continue
            // In-memory state still works
            log_error("Failed to save workspace state: {}", .{err});
            // Compositor continues functioning normally
        };
    } else {
        // Storage Agent not available, skip persistence
        // In-memory state still works
    }
}

// Implementation helper (private).
fn save_workspace_state_persistent_impl(
    self: *Compositor,
    io: *integrated_file_io.IntegratedFileIO,
    current_time: u64,
    user_id: u32,
    group_id: u32,
) !void {
    std.debug.assert(self != null);
    std.debug.assert(io != null);
    std.debug.assert(user_id > 0);
    
    // Serialize workspace state
    const configs = try serialize_workspace_state(self, self.allocator);
    defer self.allocator.free(configs);
    
    // Save to persistent storage
    try compositor_workspace_persistence.save_all_workspaces(
        io,
        configs,
        self.workspace_manager.current_workspace_id,
        current_time,
        user_id,
        group_id,
        self.allocator,
    );
}
```

**Usage**:
```zig
// After workspace switch
pub fn switch_workspace(self: *Compositor, workspace_id: u32) bool {
    const success = self.workspace_manager.switch_workspace(workspace_id);
    if (success) {
        // Save workspace state after switch
        save_workspace_state_persistent_safe(self);
    }
    return success;
}
```

---

### 5. Startup Restoration Helper

**Purpose**: Restore workspace state on compositor startup

**Location**: `src/grain_core/compositor.zig` (public function)

**Template**:
```zig
// Restore workspace state from persistent storage on startup.
// Why: Restore workspace state across compositor sessions.
// Contract: Uses default workspace if restoration fails.
pub fn restore_workspace_state_persistent(
    self: *Compositor,
    current_time: u64,
    user_id: u32,
    group_id: u32,
) void {
    std.debug.assert(self != null);
    std.debug.assert(user_id > 0);
    
    if (self.file_io) |*io| {
        restore_workspace_state_persistent_impl(self, io, current_time, user_id, group_id) catch |err| {
            // Log error but continue with default workspace
            // Compositor still works without persistence
            log_warning("Failed to restore workspace state: {}", .{err});
            // Default workspace already initialized in WorkspaceManager.init()
        };
    } else {
        // Storage Agent not available, use default workspace
        // Default workspace already initialized in WorkspaceManager.init()
    }
}

// Implementation helper (private).
fn restore_workspace_state_persistent_impl(
    self: *Compositor,
    io: *integrated_file_io.IntegratedFileIO,
    current_time: u64,
    user_id: u32,
    group_id: u32,
) !void {
    std.debug.assert(self != null);
    std.debug.assert(io != null);
    std.debug.assert(user_id > 0);
    
    // Load all workspaces
    var loaded_workspaces: [workspace.MAX_WORKSPACES]compositor_workspace_persistence.WorkspaceConfig = undefined;
    var current_workspace_id: u32 = 0;
    const workspaces_len = try compositor_workspace_persistence.load_all_workspaces(
        io,
        &loaded_workspaces,
        &current_workspace_id,
        current_time,
        user_id,
        group_id,
        self.allocator,
    );
    
    if (workspaces_len == 0) {
        // No saved state, use default workspace
        return;
    }
    
    // Restore workspaces
    restore_workspaces_from_config(self, loaded_workspaces[0..workspaces_len], current_workspace_id);
    
    // Load window states (if list_saved_window_ids is implemented)
    // For now, window states are loaded on-demand when windows are created
    // TODO: Load all window states if list_saved_window_ids is implemented
}
```

**Usage**:
```zig
// In compositor initialization
var compositor = Compositor.init(allocator);
// Initialize Storage Agent (once coordinated)
// compositor.file_io = ...;
// Restore workspace state
compositor.restore_workspace_state_persistent(
    current_time,
    user_id,
    group_id,
);
```

---

### 6. Window State Save Helper

**Purpose**: Save window state to persistent storage

**Location**: `src/grain_core/compositor.zig` (private helper function)

**Template**:
```zig
// Save window state to persistent storage with error handling.
// Why: Persist window state across sessions.
// Contract: Logs errors but continues operation.
fn save_window_state_persistent_safe(
    self: *Compositor,
    window_id: u32,
) void {
    std.debug.assert(self != null);
    std.debug.assert(window_id > 0);
    
    if (self.file_io) |*io| {
        // Get window workspace
        const workspace_id = self.workspace_manager.get_window_workspace(window_id) orelse {
            return; // Window not in any workspace
        };
        
        // Convert window state to entry
        if (convert_window_state_to_entry(self, window_id, workspace_id)) |entry| {
            const current_time = get_current_timestamp(); // TODO: Get from time manager
            const user_id = get_current_user_id(); // TODO: Get from system
            const group_id = get_current_group_id(); // TODO: Get from system
            
            compositor_workspace_persistence.save_window_state(
                io,
                &entry,
                current_time,
                user_id,
                group_id,
                self.allocator,
            ) catch |err| {
                // Log error but continue
                // In-memory state still works
                log_error("Failed to save window state: {}", .{err});
            };
        }
    } else {
        // Storage Agent not available, skip persistence
        // In-memory state still works
    }
}
```

**Usage**:
```zig
// After window state change
pub fn save_window_state(self: *Compositor, window_id: u32) bool {
    // ... existing in-memory save logic ...
    const in_memory_success = self.state_manager.save_window(...);
    
    if (!in_memory_success) {
        return false;
    }
    
    // Also save to persistent storage
    save_window_state_persistent_safe(self, window_id);
    
    return true;
}
```

---

### 7. Shutdown Save Helper

**Purpose**: Save all workspace and window states on shutdown

**Location**: `src/grain_core/compositor.zig` (public function)

**Template**:
```zig
// Save all workspace and window states before shutdown.
// Why: Persist state across compositor sessions.
// Contract: Logs errors but continues shutdown.
pub fn save_all_states_on_shutdown(
    self: *Compositor,
) void {
    std.debug.assert(self != null);
    
    // Save workspace state
    save_workspace_state_persistent_safe(self);
    
    // Save all window states
    if (self.file_io) |*io| {
        const current_time = get_current_timestamp(); // TODO: Get from time manager
        const user_id = get_current_user_id(); // TODO: Get from system
        const group_id = get_current_group_id(); // TODO: Get from system
        
        var i: u32 = 0;
        while (i < self.windows_len) : (i += 1) {
            const window_id = self.windows[i].id;
            save_window_state_persistent_safe(self, window_id);
        }
    }
}
```

**Usage**:
```zig
// In compositor shutdown
pub fn shutdown_system(self: *Compositor) bool {
    // Save all states before shutdown
    save_all_states_on_shutdown(self);
    
    // Continue with shutdown
    return self.power_manager.shutdown_system();
}
```

---

## TODOs for Implementation

### 1. Time Manager Integration

**Current**: `get_current_timestamp()` - TODO: Get from time manager

**Options**:
- Option 1: Get from time manager (if available)
- Option 2: Use system calls (if time manager not available)
- Option 3: Storage Agent provides timestamp

**Action**: Coordinate with Storage Agent or time manager on timestamp source.

---

### 2. User/Group ID Integration

**Current**: `get_current_user_id()`, `get_current_group_id()` - TODO: Get from system

**Options**:
- Option 1: Get from system calls
- Option 2: Get from Storage Agent
- Option 3: Use default values (if not critical)

**Action**: Coordinate with Storage Agent on user/group ID source.

---

### 3. Storage Agent Initialization

**Current**: `self.file_io` - TODO: Initialize from Storage Agent

**Options**:
- Option 1: Storage Agent provides initialization function
- Option 2: Compositor creates its own instance
- Option 3: Shared instance from system

**Action**: Coordinate with Storage Agent on initialization pattern.

---

### 4. Logging Integration

**Current**: `log_error()`, `log_warning()` - TODO: Integrate with logging system

**Options**:
- Option 1: Use existing logging system
- Option 2: Use std.log
- Option 3: Use Storage Agent audit logger

**Action**: Integrate with existing logging system.

---

## Summary

**Helper Functions Template**: ✅ **READY**

**Functions Prepared**:
- ✅ Workspace state serialization helper
- ✅ Workspace restoration helper
- ✅ Window state conversion helper
- ✅ Error handling helper (graceful degradation)
- ✅ Startup restoration helper
- ✅ Window state save helper
- ✅ Shutdown save helper

**TODOs Identified**:
- ⏳ Time manager integration
- ⏳ User/group ID integration
- ⏳ Storage Agent initialization
- ⏳ Logging integration

**Status**: Ready to implement once Storage Agent coordinates on initialization details.

---

**Date**: 2026-01-06-093500-pst  
**Agent**: Core 1d Compositor Agent (L2 Sub-Agent)  
**Status**: ✅ **HELPER FUNCTIONS TEMPLATE READY** — Implementation-ready function templates prepared  
**Voice**: ✅ Glow G2 (masculine, steadfast, Aquarian, calm, upbeat, graceful)  
**Grain Style**: ✅ 100% compliant


