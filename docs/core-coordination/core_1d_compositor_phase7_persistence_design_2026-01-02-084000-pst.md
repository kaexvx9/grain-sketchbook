# Core 1d Compositor Agent: Phase 7 Persistence Integration Design

**Date**: 2026-01-02-084000-pst  
**Agent**: Core 1d Compositor Agent (L2 Sub-Agent)  
**Parent Agent**: Core 1 Subcore Agent (L1 Subcore)  
**Status**: ✅ **DESIGN READY** — Prepared for Storage Agent API integration

---

## Current State Analysis

### Existing In-Memory State Management ✅

**Window State Management** (`window_state.zig`):
- ✅ `WindowStateManager` - Manages window state entries in-memory
- ✅ `save_window()` - Saves window state to in-memory manager
- ✅ `get_window_state()` - Retrieves window state from in-memory manager
- ✅ `remove_window()` - Removes window state from in-memory manager
- ✅ All window state data structures defined (`WindowStateEntry`)

**Session Management** (`window_session.zig`):
- ✅ `SessionManager` - Manages window sessions in-memory
- ✅ `create_session()` - Creates named session with window states
- ✅ `find_session()` - Finds session by ID or name
- ✅ `delete_session()` - Deletes session
- ✅ All session data structures defined (`WindowSession`)

**Workspace Management** (`workspace.zig`):
- ✅ `WorkspaceManager` - Manages workspaces in-memory
- ✅ `Workspace` - Workspace data structure with window assignments
- ✅ `switch_workspace()` - Switches between workspaces
- ✅ `create_workspace()` - Creates new workspace
- ✅ `assign_window_to_workspace()` - Assigns window to workspace

**Compositor Integration** (`compositor.zig`):
- ✅ `save_window_state()` - Saves individual window state
- ✅ `restore_window_state()` - Restores individual window state
- ✅ `save_all_window_states()` - Saves all window states
- ✅ `create_window_session()` - Creates session with all window states
- ✅ `restore_window_session()` - Restores session

**Status**: All in-memory state management is complete and working. We need to add persistence layer using Storage Agent API.

---

## Persistence Integration Design

### Architecture Approach

**Strategy**: Add persistence hooks that call Storage Agent API, keeping existing in-memory management intact.

**Pattern**: 
1. In-memory state management continues to work as-is
2. Add persistence hooks that serialize state and call Storage Agent API
3. Add restoration hooks that load from Storage Agent API and populate in-memory state
4. Maintain backward compatibility (works without persistence if Storage Agent unavailable)

---

## Data Structures for Persistence

### Workspace Configuration Structure

```zig
// Workspace configuration for persistence.
pub const WorkspaceConfig = struct {
    id: u32,
    name: [32]u8,
    name_len: u32,
    window_ids: [256]u32,
    window_ids_len: u32,
    focused_window_id: u32,
    visible: bool,
};
```

### Workspace State Structure (All Workspaces)

```zig
// Complete workspace state for persistence.
pub const WorkspaceState = struct {
    current_workspace_id: u32,
    workspaces: [10]WorkspaceConfig,
    workspaces_len: u32,
};
```

### Window State Structure (Already Exists)

```zig
// Window state entry (already defined in window_state.zig).
pub const WindowStateEntry = struct {
    window_id: u32,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    minimized: bool,
    maximized: bool,
    workspace_id: u32,
    title: [256]u8,
    title_len: u32,
};
```

---

## API Integration Points

### 1. Workspace State Persistence

**Save Workspace State**:
```zig
// Save all workspace configurations to persistent storage.
pub fn save_workspace_state_persistent(
    self: *Compositor,
    storage: *StorageManager, // From Storage Agent
) !void {
    // Serialize workspace state
    const state = self.serialize_workspace_state();
    
    // Call Storage Agent API to save
    try storage.save_workspace_config(state);
}
```

**Load Workspace State**:
```zig
// Load all workspace configurations from persistent storage.
pub fn load_workspace_state_persistent(
    self: *Compositor,
    storage: *StorageManager, // From Storage Agent
) !bool {
    // Call Storage Agent API to load
    const state = try storage.load_workspace_config();
    
    // Deserialize and restore workspace state
    return self.deserialize_workspace_state(state);
}
```

### 2. Window State Persistence

**Save Window State**:
```zig
// Save window state to persistent storage.
pub fn save_window_state_persistent(
    self: *Compositor,
    window_id: u32,
    storage: *StorageManager, // From Storage Agent
) !void {
    // Get window state from in-memory manager
    if (self.state_manager.get_window_state(window_id)) |state| {
        // Call Storage Agent API to save
        try storage.save_window_state(window_id, &state);
    }
}
```

**Load Window State**:
```zig
// Load window state from persistent storage.
pub fn load_window_state_persistent(
    self: *Compositor,
    window_id: u32,
    storage: *StorageManager, // From Storage Agent
) !bool {
    // Call Storage Agent API to load
    if (try storage.load_window_state(window_id)) |state| {
        // Restore to in-memory manager
        _ = self.state_manager.save_window(
            state.window_id,
            state.x,
            state.y,
            state.width,
            state.height,
            state.minimized,
            state.maximized,
            state.workspace_id,
            state.title[0..state.title_len],
        );
        return true;
    }
    return false;
}
```

### 3. Startup Restoration

**Restore on Compositor Startup**:
```zig
// Restore workspace and window state on compositor startup.
pub fn restore_persistent_state(
    self: *Compositor,
    storage: *StorageManager, // From Storage Agent
) !void {
    // Load workspace state
    _ = try self.load_workspace_state_persistent(storage);
    
    // Load all window states
    // (Implementation depends on Storage Agent API - may need to iterate)
    // For each window that was saved, load its state
}
```

---

## Serialization Design

### Workspace State Serialization

**Format Options** (to be decided with Storage Agent):
1. **JSON Format** (human-readable, easy to debug)
2. **Binary Format** (compact, fast)
3. **Custom Format** (optimized for compositor needs)

**Serialization Functions** (to be implemented):
```zig
// Serialize workspace state to format (JSON/binary/custom).
pub fn serialize_workspace_state(
    self: *const Compositor,
    allocator: std.mem.Allocator,
) ![]u8 {
    // Serialize workspace state
    // Return serialized data
}

// Deserialize workspace state from format.
pub fn deserialize_workspace_state(
    self: *Compositor,
    data: []const u8,
) !bool {
    // Deserialize workspace state
    // Restore to workspace manager
    // Return success/failure
}
```

---

## Integration Points with Storage Agent

### Storage Agent API Functions Needed

**From Coordination Request**:
1. `save_workspace_config()` - Save workspace configuration
2. `load_workspace_config()` - Load workspace configuration
3. `save_all_workspaces()` - Save all workspaces atomically
4. `load_all_workspaces()` - Load all workspaces
5. `save_window_state()` - Save window state
6. `load_window_state()` - Load window state

**Storage Location**: TBD (to be agreed with Storage Agent)
- Option 1: `~/.grain/compositor/workspaces/`
- Option 2: `/etc/grain/compositor/workspaces/` or `~/.config/grain/compositor/workspaces/`

**Data Format**: TBD (to be agreed with Storage Agent)
- Option 1: JSON
- Option 2: Binary
- Option 3: Custom

---

## Implementation Plan

### Phase 1: API Contract Agreement

**Tasks**:
1. ✅ Coordination request sent to Storage Agent
2. ⏳ Review Storage Agent response
3. ⏳ Agree on API contract
4. ⏳ Agree on data format
5. ⏳ Agree on storage location

**Status**: Awaiting Storage Agent response

---

### Phase 2: Serialization Implementation

**Tasks**:
1. Implement workspace state serialization (format TBD)
2. Implement workspace state deserialization (format TBD)
3. Implement window state serialization (if needed, or use existing structure)
4. Add comprehensive tests for serialization/deserialization

**Dependencies**: Data format decision from Phase 1

---

### Phase 3: Storage Agent Integration

**Tasks**:
1. Import Storage Agent module
2. Implement `save_workspace_state_persistent()`
3. Implement `load_workspace_state_persistent()`
4. Implement `save_window_state_persistent()`
5. Implement `load_window_state_persistent()`
6. Implement `restore_persistent_state()` for startup
7. Add error handling for Storage Agent API calls
8. Add comprehensive tests

**Dependencies**: API contract from Phase 1, serialization from Phase 2

---

### Phase 4: Integration and Testing

**Tasks**:
1. Integrate persistence hooks into compositor lifecycle
2. Add startup restoration
3. Add periodic save triggers (on workspace switch, window state change)
4. Integration testing with Storage Agent
5. End-to-end testing
6. Framework x86_64 testing verification

**Dependencies**: All previous phases

---

## Error Handling

### Storage Agent API Errors

**Error Types** (to be defined with Storage Agent):
- Permission errors
- Disk full errors
- Corruption errors
- Network errors (if applicable)

**Error Handling Strategy**:
- Log errors but don't crash compositor
- Fall back to in-memory state if persistence fails
- Provide user feedback for critical errors
- Retry logic for transient errors

---

## Backward Compatibility

### Graceful Degradation

**Strategy**: Compositor should work even if Storage Agent is unavailable.

**Implementation**:
- Check if Storage Agent is available before calling API
- Fall back to in-memory state if persistence unavailable
- Log warnings but continue operation
- Don't block compositor startup if persistence fails

---

## Testing Strategy

### Unit Tests

1. **Serialization Tests**:
   - Test workspace state serialization
   - Test workspace state deserialization
   - Test window state serialization
   - Test edge cases (empty state, max values, etc.)

2. **Storage Agent Integration Tests**:
   - Test save workspace state
   - Test load workspace state
   - Test save window state
   - Test load window state
   - Test error handling

### Integration Tests

1. **End-to-End Tests**:
   - Test workspace persistence across compositor restarts
   - Test window state persistence across compositor restarts
   - Test workspace restoration on startup
   - Test window restoration on startup

2. **Framework x86_64 Tests**:
   - Verify all tests pass on Framework x86_64
   - Verify persistence works on Framework x86_64
   - Verify performance is acceptable

---

## Performance Considerations

### Save Frequency

**Strategy**: Save on significant state changes, not on every update.

**Save Triggers**:
- Workspace switch
- Window state change (minimize, maximize, position, size)
- Window assignment to workspace
- Workspace creation/deletion
- Periodic save (e.g., every 30 seconds) for safety

**Optimization**:
- Batch multiple changes into single save operation
- Use async saves if Storage Agent supports it
- Don't block compositor operations on save

---

## Summary

**Current State**: In-memory state management is complete and working. We need to add persistence layer.

**Design Approach**: Add persistence hooks that call Storage Agent API, keeping existing in-memory management intact.

**Implementation Plan**: Four phases - API contract agreement, serialization, Storage Agent integration, integration and testing.

**Status**: Design ready, awaiting Storage Agent API contract agreement.

---

**Date**: 2026-01-02-084000-pst  
**Agent**: Core 1d Compositor Agent (L2 Sub-Agent)  
**Status**: ✅ **DESIGN READY** — Prepared for Storage Agent API integration  
**Voice**: ✅ Glow G2 (masculine, steadfast, Aquarian, calm, upbeat, graceful)

