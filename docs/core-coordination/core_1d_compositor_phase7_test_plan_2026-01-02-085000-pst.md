# Core 1d Compositor Agent: Phase 7 Persistence Test Plan

**Date**: 2026-01-02-085000-pst  
**Agent**: Core 1d Compositor Agent (L2 Sub-Agent)  
**Parent Agent**: Core 1 Subcore Agent (L1 Subcore)  
**Status**: ✅ **TEST PLAN READY** — Prepared for Phase 7 persistence testing

---

## Current Test Coverage

### Existing Tests ✅

**Workspace Management Tests** (`tests/057_grain_core_workspace_test.zig`):
- ✅ Workspace initialization
- ✅ Workspace add/remove window
- ✅ Workspace set focused window
- ✅ Workspace manager initialization
- ✅ Workspace manager get workspace
- ✅ Workspace manager switch workspace
- ✅ Workspace manager assign window
- ✅ Compositor workspace integration
- ✅ Compositor window workspace assignment

**Window State Tests** (`tests/067_grain_core_window_state_test.zig`):
- ✅ Window state manager initialization
- ✅ Save window state
- ✅ Get window state
- ✅ Remove window state
- ✅ Update existing window state
- ✅ Clear all states
- ✅ Compositor save window state
- ✅ Compositor restore window state
- ✅ Compositor save all window states
- ✅ Compositor window removed from state on deletion

**Window Session Tests** (`tests/082_grain_core_window_session_test.zig`):
- ✅ Session manager initialization
- ✅ Create session
- ✅ Find session by ID
- ✅ Find session by name
- ✅ Delete session
- ✅ Get session count
- ✅ Clear all sessions
- ✅ Compositor create session
- ✅ Compositor restore session
- ✅ Compositor find session by name
- ✅ Compositor get session count

**Status**: All in-memory state management is well-tested. We need to add persistence integration tests.

---

## Phase 7 Persistence Test Plan

### Test File Structure

**New Test File**: `tests/068_grain_core_workspace_persistence_test.zig`

**Purpose**: Test workspace and window state persistence integration with Storage Agent

---

## Test Categories

### 1. Workspace State Persistence Tests

**Test**: `workspace state save to storage`
- Create multiple workspaces with windows
- Save workspace state using Storage Agent API
- Verify workspace state was saved correctly
- Verify all workspace data is preserved

**Test**: `workspace state load from storage`
- Save workspace state
- Create new compositor instance
- Load workspace state from Storage Agent API
- Verify workspace state was restored correctly
- Verify all workspaces and window assignments restored

**Test**: `workspace state persistence across restart`
- Create workspaces and assign windows
- Save workspace state
- Simulate compositor restart (new instance)
- Load workspace state on startup
- Verify workspace state matches saved state

**Test**: `workspace state save error handling`
- Test save failure scenarios (permissions, disk full, etc.)
- Verify compositor continues operation on save failure
- Verify error is logged but doesn't crash compositor

**Test**: `workspace state load error handling`
- Test load failure scenarios (file not found, corruption, etc.)
- Verify compositor falls back to default workspace on load failure
- Verify error is logged but doesn't crash compositor

---

### 2. Window State Persistence Tests

**Test**: `window state save to storage`
- Create windows with various states
- Save window state using Storage Agent API
- Verify window state was saved correctly
- Verify all window data is preserved (position, size, title, workspace)

**Test**: `window state load from storage`
- Save window state
- Create new compositor instance
- Load window state from Storage Agent API
- Verify window state was restored correctly
- Verify windows are restored to correct workspaces

**Test**: `window state persistence across restart`
- Create windows with various states
- Save window state
- Simulate compositor restart (new instance)
- Load window state on startup
- Verify window state matches saved state

**Test**: `window state save error handling`
- Test save failure scenarios
- Verify compositor continues operation on save failure
- Verify error is logged but doesn't crash compositor

**Test**: `window state load error handling`
- Test load failure scenarios
- Verify compositor falls back gracefully on load failure
- Verify error is logged but doesn't crash compositor

---

### 3. Integration Tests

**Test**: `workspace and window state persistence together`
- Create workspaces with windows
- Save both workspace and window state
- Load both on startup
- Verify complete state restoration

**Test**: `persistence with multiple workspaces and windows`
- Create multiple workspaces (up to MAX_WORKSPACES)
- Create multiple windows (up to MAX_WINDOWS)
- Assign windows to different workspaces
- Save and load complete state
- Verify all workspaces and windows restored correctly

**Test**: `persistence with workspace switching`
- Create multiple workspaces
- Switch between workspaces
- Save workspace state after each switch
- Load and verify current workspace is correct

**Test**: `persistence with window state changes`
- Create windows and modify their state
- Save window state after each change
- Load and verify window states match

---

### 4. Edge Case Tests

**Test**: `persistence with empty workspace`
- Create workspace with no windows
- Save and load workspace state
- Verify empty workspace is preserved

**Test**: `persistence with maximum workspaces`
- Create MAX_WORKSPACES workspaces
- Save and load workspace state
- Verify all workspaces are preserved

**Test**: `persistence with maximum windows`
- Create MAX_WINDOWS windows
- Save and load window state
- Verify all windows are preserved

**Test**: `persistence with long window titles`
- Create windows with MAX_TITLE_LEN titles
- Save and load window state
- Verify long titles are preserved correctly

**Test**: `persistence with special characters in workspace names`
- Create workspaces with special characters in names
- Save and load workspace state
- Verify special characters are preserved

---

### 5. Performance Tests

**Test**: `persistence save performance`
- Measure time to save workspace state
- Measure time to save window state
- Verify performance is acceptable (not blocking compositor)

**Test**: `persistence load performance`
- Measure time to load workspace state
- Measure time to load window state
- Verify performance is acceptable (not blocking compositor startup)

**Test**: `persistence with large state`
- Create large number of workspaces and windows
- Measure save/load performance
- Verify performance scales reasonably

---

### 6. Framework x86_64 Tests

**Test**: `persistence on Framework x86_64`
- Run all persistence tests on Framework x86_64
- Verify no architecture-specific issues
- Verify performance is acceptable

**Test**: `persistence cross-platform compatibility`
- Verify saved state can be loaded on different architectures (if applicable)
- Test data format compatibility

---

## Test Implementation Strategy

### Mock Storage Agent for Testing

**Approach**: Create mock Storage Agent implementation for testing

**Benefits**:
- Test persistence logic without full Storage Agent dependency
- Test error handling scenarios
- Test performance without actual file I/O
- Faster test execution

**Implementation**:
```zig
// Mock Storage Agent for testing.
pub const MockStorageManager = struct {
    saved_workspaces: ?WorkspaceState = null,
    saved_windows: std.HashMap(u32, WindowStateEntry),
    
    pub fn save_workspace_config(self: *MockStorageManager, state: *const WorkspaceState) !void {
        // Mock implementation
    }
    
    pub fn load_workspace_config(self: *MockStorageManager, state: *WorkspaceState) !bool {
        // Mock implementation
    }
    
    // ... other mock methods
};
```

---

### Integration Tests with Real Storage Agent

**Approach**: Integration tests with actual Storage Agent (when available)

**Benefits**:
- Test real integration
- Verify API contract works correctly
- Test end-to-end persistence

**Implementation**:
- Use actual Storage Agent module
- Test with real file I/O
- Verify data format compatibility
- Test error handling with real Storage Agent

---

## Test Data Structures

### Test Helpers

**Helper Functions**:
```zig
// Create test workspace state.
fn create_test_workspace_state() WorkspaceState {
    // Create test data
}

// Create test window state.
fn create_test_window_state() WindowStateEntry {
    // Create test data
}

// Verify workspace state matches.
fn verify_workspace_state(expected: *const WorkspaceState, actual: *const WorkspaceState) bool {
    // Verify all fields match
}

// Verify window state matches.
fn verify_window_state(expected: *const WindowStateEntry, actual: *const WindowStateEntry) bool {
    // Verify all fields match
}
```

---

## Test Execution Plan

### Phase 1: Unit Tests (Mock Storage Agent)

**Timeline**: After Storage Agent API contract agreed

**Tests**:
- All workspace state persistence tests
- All window state persistence tests
- Edge case tests
- Performance tests (with mock)

**Status**: Ready to implement once API contract agreed

---

### Phase 2: Integration Tests (Real Storage Agent)

**Timeline**: After Phase 1 complete

**Tests**:
- Integration tests with real Storage Agent
- End-to-end persistence tests
- Framework x86_64 tests

**Status**: Ready to implement after Phase 1

---

## Test Coverage Goals

**Target Coverage**:
- ✅ 100% coverage of persistence API functions
- ✅ 100% coverage of error handling paths
- ✅ 100% coverage of edge cases
- ✅ Performance tests for all persistence operations
- ✅ Framework x86_64 verification

---

## Test Maintenance

### Regular Updates

**When to Update Tests**:
- When Storage Agent API changes
- When persistence implementation changes
- When new edge cases are discovered
- When performance requirements change

**Test Review**:
- Review test coverage regularly
- Add tests for any bugs found
- Update tests when implementation evolves

---

## Summary

**Current Test Coverage**: In-memory state management is well-tested (workspace, window state, sessions).

**Phase 7 Test Plan**: Comprehensive test plan for persistence integration:
- Workspace state persistence tests
- Window state persistence tests
- Integration tests
- Edge case tests
- Performance tests
- Framework x86_64 tests

**Implementation Strategy**: Mock Storage Agent for unit tests, real Storage Agent for integration tests.

**Status**: Test plan ready, awaiting Storage Agent API contract agreement to begin implementation.

---

**Date**: 2026-01-02-085000-pst  
**Agent**: Core 1d Compositor Agent (L2 Sub-Agent)  
**Status**: ✅ **TEST PLAN READY** — Prepared for Phase 7 persistence testing  
**Voice**: ✅ Glow G2 (masculine, steadfast, Aquarian, calm, upbeat, graceful)

