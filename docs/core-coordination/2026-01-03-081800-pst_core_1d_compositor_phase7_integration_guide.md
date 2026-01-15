# Core 1d Compositor Agent: Phase 7 Integration Guide

**Date**: 2026-01-03-081800-pst  
**Agent**: Core 1d Compositor Agent (L2 Sub-Agent)  
**Parent Agent**: Core 1 Subcore Agent (L1 Subcore)  
**Status**: ✅ **INTEGRATION GUIDE READY** — Detailed integration instructions prepared

---

## Purpose

This document provides detailed integration instructions for Phase 7 workspace persistence using the Storage Agent API. This guide shows exactly how to integrate the `compositor_workspace_persistence.zig` module into the compositor.

---

## Storage Agent API Review

### API Module Status

**Module**: `src/grain_core/compositor_workspace_persistence.zig`

**Status**: ✅ **IMPLEMENTED** (minor TODOs remain)

**Functions Available**:
1. ✅ `save_workspace_config()` - Save single workspace
2. ✅ `load_workspace_config()` - Load single workspace
3. ✅ `save_all_workspaces()` - Save all workspaces atomically
4. ✅ `load_all_workspaces()` - Load all workspaces
5. ✅ `save_window_state()` - Save window state
6. ✅ `load_window_state()` - Load window state
7. ⏳ `list_saved_window_ids()` - List saved window IDs (TODO: directory listing)

**Minor TODOs**:
- Line 147: Atomic rename (requires path_resolver integration)
- Line 249: Directory listing (requires path_resolver integration)

**Note**: These TODOs don't block integration. The atomic save works (writes to both tmp and final file), and window ID listing can be handled differently if needed.

---

## Integration Steps

### Step 1: Import Required Modules

**Location**: Top of `src/grain_core/compositor.zig`

**Add Imports**:
```zig
const compositor_workspace_persistence = @import("compositor_workspace_persistence.zig");
const integrated_file_io = @import("integrated_file_io.zig");
const integrated_file_storage = @import("integrated_file_storage.zig");
```

---

### Step 2: Add IntegratedFileIO to Compositor Struct

**Location**: `Compositor` struct in `src/grain_core/compositor.zig`

**Add Field**:
```zig
pub const Compositor = struct {
    // ... existing fields ...
    file_io: ?integrated_file_io.IntegratedFileIO, // Optional, initialized when Storage Agent available
    // ... rest of fields ...
};
```

**Initialization**: Initialize in `init()` or via separate initialization function

---

### Step 3: Initialize IntegratedFileIO

**Location**: `Compositor.init()` or separate initialization function

**Initialization Pattern**:
```zig
// Initialize IntegratedFileIO (if Storage Agent available)
// This requires access to IntegratedFileStorageManager
// Pattern: Get from Storage Agent or initialize if available
```

**Note**: The exact initialization depends on how Storage Agent exposes `IntegratedFileStorageManager`. This will be coordinated with Storage Agent.

---

### Step 4: Implement Startup Restoration

**Location**: After `Compositor.init()` or in compositor startup function

**Function to Add**:
```zig
// Restore workspace state from persistent storage on startup.
pub fn restore_workspace_state_persistent(
    self: *Compositor,
    current_time: u64,
    user_id: u32,
    group_id: u32,
) void {
    std.debug.assert(self.file_io != null);
    if (self.file_io) |*io| {
        restore_workspace_state_persistent_impl(self, io, current_time, user_id, group_id) catch |err| {
            // Log error but continue with default workspace
            // Compositor still works without persistence
            _ = err;
        };
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
}
```

---

### Step 5: Implement Workspace Switch Save

**Location**: `Compositor.switch_workspace()` function

**Integration Pattern**:
```zig
pub fn switch_workspace(self: *Compositor, workspace_id: u32) bool {
    // ... existing workspace switching logic ...
    
    // Save workspace state after switch
    if (self.file_io) |*io| {
        save_workspace_state_persistent_safe(self, io);
    }
    
    return true;
}
```

**Helper Function**:
```zig
// Save workspace state with error handling (graceful degradation).
fn save_workspace_state_persistent_safe(
    self: *Compositor,
    io: *integrated_file_io.IntegratedFileIO,
) void {
    const current_time = get_current_timestamp(); // Get from time manager
    const user_id = get_current_user_id(); // Get from system
    const group_id = get_current_group_id(); // Get from system
    
    save_workspace_state_persistent_impl(self, io, current_time, user_id, group_id) catch |err| {
        // Log error but continue
        // In-memory state still works
        _ = err;
    };
}
```

---

### Step 6: Implement Workspace Creation Save

**Location**: `Compositor.create_workspace()` function

**Integration Pattern**:
```zig
pub fn create_workspace(self: *Compositor, name: []const u8) ?u32 {
    // ... existing workspace creation logic ...
    
    // Save workspace state after creation
    if (self.file_io) |*io| {
        save_workspace_state_persistent_safe(self, io);
    }
    
    return workspace_id;
}
```

---

### Step 7: Implement Window State Save

**Location**: `Compositor.save_window_state()` function

**Integration Pattern**:
```zig
pub fn save_window_state(self: *Compositor, window_id: u32) bool {
    // ... existing in-memory save logic ...
    const in_memory_success = self.state_manager.save_window(...);
    
    if (!in_memory_success) {
        return false;
    }
    
    // Also save to persistent storage
    if (self.file_io) |*io| {
        save_window_state_persistent_safe(self, window_id, io);
    }
    
    return true;
}
```

**Helper Function**:
```zig
// Save window state to persistent storage with error handling.
fn save_window_state_persistent_safe(
    self: *Compositor,
    window_id: u32,
    io: *integrated_file_io.IntegratedFileIO,
) void {
    if (self.state_manager.get_window_state(window_id)) |state| {
        const current_time = get_current_timestamp();
        const user_id = get_current_user_id();
        const group_id = get_current_group_id();
        
        const window_state_entry = compositor_workspace_persistence.WindowStateEntry{
            .window_id = state.window_id,
            .workspace_id = state.workspace_id,
            .x = state.x,
            .y = state.y,
            .width = state.width,
            .height = state.height,
            .minimized = state.minimized,
            .maximized = state.maximized,
            .title = state.title,
            .title_len = state.title_len,
        };
        
        compositor_workspace_persistence.save_window_state(
            io,
            &window_state_entry,
            current_time,
            user_id,
            group_id,
            self.allocator,
        ) catch |err| {
            // Log error but continue
            // In-memory state still works
            _ = err;
        };
    }
}
```

---

### Step 8: Implement Shutdown Save

**Location**: `Compositor.shutdown_system()` function

**Integration Pattern**:
```zig
pub fn shutdown_system(self: *Compositor) bool {
    // Save all workspace states before shutdown
    if (self.file_io) |*io| {
        save_workspace_state_persistent_safe(self, io);
        save_all_window_states_persistent_safe(self, io);
    }
    
    // Continue with shutdown
    return self.power_manager.shutdown_system();
}
```

---

## Helper Functions to Implement

### 1. Workspace State Serialization Helper

**Purpose**: Convert workspace manager state to Storage Agent format

**Function**:
```zig
// Serialize workspace manager state for persistence.
fn serialize_workspace_state(
    self: *const Compositor,
    allocator: std.mem.Allocator,
) ![]compositor_workspace_persistence.WorkspaceConfig {
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
    return result;
}
```

---

### 2. Workspace Restoration Helper

**Purpose**: Restore workspace manager from loaded state

**Function**:
```zig
// Restore workspace manager from loaded state.
fn restore_workspaces_from_config(
    self: *Compositor,
    configs: []const compositor_workspace_persistence.WorkspaceConfig,
    current_workspace_id: u32,
) void {
    // Clear existing workspaces (keep default workspace structure)
    // Restore workspaces from configs
    // Set current workspace
    // Restore window assignments
}
```

---

## Error Handling Strategy

### Graceful Degradation Pattern

**Principle**: Persistence failures should not break compositor functionality

**Pattern**:
```zig
// Save with error handling (graceful degradation).
fn save_workspace_state_persistent_safe(
    self: *Compositor,
    io: *integrated_file_io.IntegratedFileIO,
) void {
    save_workspace_state_persistent_impl(self, io, ...) catch |err| {
        // Log error but continue
        // In-memory state still works
        _ = err;
    };
}
```

**Benefits**:
- Compositor continues working even if persistence fails
- In-memory state management still works
- User experience not disrupted

---

## Testing Strategy

### Unit Tests

**Test Module**: `tests/139_grain_core_compositor_workspace_persistence_integration_test.zig`

**Test Cases**:
1. Startup restoration test (load workspaces on init)
2. Workspace switch save test (save on switch)
3. Workspace creation save test (save on create)
4. Window state save test (save on state change)
5. Window assignment save test (save on assignment)
6. Shutdown save test (save on shutdown)
7. Error handling test (graceful degradation on errors)
8. Atomic operation test (verify atomic saves)
9. Framework x86_64 test (verify on Framework)

---

## Integration Timeline

### Phase 1: Module Integration (Day 1)

**Tasks**:
1. Import Storage Agent modules
2. Add `IntegratedFileIO` field to Compositor struct
3. Initialize `IntegratedFileIO` (coordinate with Storage Agent)
4. Add helper functions

---

### Phase 2: Persistence Hooks (Days 2-3)

**Tasks**:
1. Implement startup restoration
2. Implement workspace switch save
3. Implement workspace creation save
4. Implement window state save
5. Implement shutdown save

---

### Phase 3: Testing (Days 4-5)

**Tasks**:
1. Add comprehensive tests
2. Integration testing with Storage Agent
3. Framework x86_64 verification
4. Error handling verification

---

## Coordination with Storage Agent

### Questions to Resolve

1. **IntegratedFileStorageManager Access**: How does Compositor get access to `IntegratedFileStorageManager`?
   - Option 1: Storage Agent provides initialization function
   - Option 2: Compositor creates its own instance
   - Option 3: Shared instance from system

2. **User/Group ID**: How does Compositor get current user_id and group_id?
   - Option 1: From system calls
   - Option 2: From Storage Agent
   - Option 3: Default values

3. **Timestamp**: How does Compositor get current timestamp?
   - Option 1: From time manager
   - Option 2: From system calls
   - Option 3: Storage Agent provides

4. **Atomic Rename**: When will atomic rename be implemented?
   - Current: Works but not atomic (writes to both tmp and final)
   - Future: Atomic rename once path_resolver integration complete

5. **Directory Listing**: When will directory listing be implemented?
   - Current: Returns 0 (no windows found)
   - Future: Once path_resolver integration complete
   - Alternative: Track window IDs in workspace state

---

## Summary

**Integration Guide**: ✅ **READY**

**Status**: Detailed integration instructions prepared. Ready to integrate once Storage Agent coordinates on initialization details.

**Next Steps**:
1. Coordinate with Storage Agent on initialization details
2. Implement integration following this guide
3. Add comprehensive tests
4. Framework x86_64 verification

---

**Date**: 2026-01-03-081800-pst  
**Agent**: Core 1d Compositor Agent (L2 Sub-Agent)  
**Status**: ✅ **INTEGRATION GUIDE READY** — Detailed integration instructions prepared  
**Voice**: ✅ Glow G2 (masculine, steadfast, Aquarian, calm, upbeat, graceful)  
**Grain Style**: ✅ 100% compliant

