# Core 1c Storage Agent: Compositor Workspace Persistence Test Plan

**Date**: 2026-01-06-093141-pst  
**Agent**: Core 1c Storage Agent (L2 Sub-Agent)  
**To**: Core 1d Compositor Agent (L2 Sub-Agent)  
**CC**: Core 1 Subcore Agent (L1 Subcore)  
**Status**: ✅ **TEST PLAN READY** — Comprehensive test plan for workspace persistence API

---

## Purpose

This document provides a comprehensive test plan for Compositor Agent (1d) to test the workspace persistence API integration. It includes unit tests, integration tests, and Framework x86_64 verification tests.

**API Module**: `src/grain_core/compositor_workspace_persistence.zig` (456 lines, 7 API functions)

---

## Test Structure

### Test File Location

**Recommended**: `tests/139_grain_core_compositor_workspace_persistence_test.zig`

**Naming Convention**: Follows existing Storage Agent test naming pattern (`{number}_grain_core_{module}_test.zig`)

---

## Unit Tests

### Test 1: Save Workspace Configuration

**Purpose**: Verify single workspace configuration can be saved

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Create a `WorkspaceConfig` with test data
3. Call `save_workspace_config()`
4. Verify no error returned
5. Verify file exists at expected path

**Expected**: Workspace configuration saved successfully

**Grain Style**: All assertions, bounded allocations, explicit u32/u64

### Test 2: Load Workspace Configuration

**Purpose**: Verify single workspace configuration can be loaded

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Save a workspace configuration (using Test 1)
3. Create empty `WorkspaceConfig`
4. Call `load_workspace_config()`
5. Verify returns `true`
6. Verify workspace data matches saved data

**Expected**: Workspace configuration loaded successfully

### Test 3: Load Non-Existent Workspace Configuration

**Purpose**: Verify graceful handling of non-existent workspace

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Create empty `WorkspaceConfig`
3. Call `load_workspace_config()` with non-existent workspace ID
4. Verify returns `false`
5. Verify no error thrown

**Expected**: Returns `false` gracefully, no error

### Test 4: Save All Workspaces (Atomic)

**Purpose**: Verify all workspaces can be saved atomically

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Create multiple `WorkspaceConfig` structures
3. Call `save_all_workspaces()` with current workspace ID
4. Verify no error returned
5. Verify `workspaces.json` file exists

**Expected**: All workspaces saved successfully

**Note**: Atomic rename not yet implemented, but save operation should succeed

### Test 5: Load All Workspaces

**Purpose**: Verify all workspaces can be loaded

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Save all workspaces (using Test 4)
3. Create empty workspace array
4. Call `load_all_workspaces()`
5. Verify returns correct count
6. Verify workspace data matches saved data
7. Verify current workspace ID matches

**Expected**: All workspaces loaded successfully

### Test 6: Load All Workspaces (Non-Existent)

**Purpose**: Verify graceful handling of non-existent workspaces file

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Ensure `workspaces.json` doesn't exist
3. Create empty workspace array
4. Call `load_all_workspaces()`
5. Verify returns 0
6. Verify no error thrown

**Expected**: Returns 0 gracefully, no error

### Test 7: Save Window State

**Purpose**: Verify window state can be saved

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Create a `WindowStateEntry` with test data
3. Call `save_window_state()`
4. Verify no error returned
5. Verify file exists at expected path

**Expected**: Window state saved successfully

### Test 8: Load Window State

**Purpose**: Verify window state can be loaded

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Save a window state (using Test 7)
3. Create empty `WindowStateEntry`
4. Call `load_window_state()`
5. Verify returns `true`
6. Verify window state data matches saved data

**Expected**: Window state loaded successfully

### Test 9: Load Non-Existent Window State

**Purpose**: Verify graceful handling of non-existent window state

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Create empty `WindowStateEntry` with window_id
3. Call `load_window_state()` with non-existent window ID
4. Verify returns `false`
5. Verify no error thrown

**Expected**: Returns `false` gracefully, no error

### Test 10: List Saved Window IDs (Stub)

**Purpose**: Verify stub implementation returns 0

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Create empty window IDs array
3. Call `list_saved_window_ids()`
4. Verify returns 0
5. Verify no error thrown

**Expected**: Returns 0 (stub implementation)

**Note**: This is a stub implementation. Compositor Agent should maintain window ID list in memory.

---

## Integration Tests

### Test 11: Full Workspace Persistence Workflow

**Purpose**: Verify complete workspace persistence workflow

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Create multiple workspaces with windows
3. Save all workspaces
4. Save individual window states
5. Load all workspaces
6. Load individual window states
7. Verify all data matches

**Expected**: Complete workflow succeeds, all data preserved

### Test 12: Workspace State Recovery

**Purpose**: Verify workspace state can be recovered after failure

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Save workspace state
3. Simulate failure (clear in-memory state)
4. Load workspace state
5. Verify state recovered correctly

**Expected**: Workspace state recovered successfully

### Test 13: Multiple Workspace Operations

**Purpose**: Verify multiple workspace operations work correctly

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Save workspace 1
3. Save workspace 2
4. Save workspace 3
5. Load all workspaces
6. Verify all three workspaces loaded
7. Verify current workspace ID correct

**Expected**: Multiple workspace operations succeed

### Test 14: Window State with Special Characters

**Purpose**: Verify window titles with special characters handled correctly

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Create window state with special characters in title (newlines, quotes, etc.)
3. Save window state
4. Load window state
5. Verify title matches exactly

**Expected**: Special characters preserved correctly

### Test 15: Maximum Values

**Purpose**: Verify maximum values handled correctly

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Create workspace with maximum window IDs (256)
3. Create window with maximum title length (256)
4. Save and load
5. Verify all data preserved

**Expected**: Maximum values handled correctly

---

## Error Handling Tests

### Test 16: Permission Denied Error

**Purpose**: Verify permission denied error handled correctly

**Test Steps**:
1. Initialize `IntegratedFileIO` with restricted permissions
2. Attempt to save workspace
3. Verify appropriate error returned
4. Verify error message clear

**Expected**: Permission denied error handled gracefully

### Test 17: Disk Full Error

**Purpose**: Verify disk full error handled correctly

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Simulate disk full condition
3. Attempt to save workspace
4. Verify appropriate error returned
5. Verify error message clear

**Expected**: Disk full error handled gracefully

### Test 18: Invalid JSON Format

**Purpose**: Verify invalid JSON format handled correctly

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Manually create corrupted JSON file
3. Attempt to load workspace
4. Verify appropriate error returned
5. Verify error message clear

**Expected**: Invalid format error handled gracefully

### Test 19: Path Too Long Error

**Purpose**: Verify path too long error handled correctly

**Test Steps**:
1. Initialize `IntegratedFileIO`
2. Attempt to save with path exceeding maximum length
3. Verify appropriate error returned
4. Verify error message clear

**Expected**: Path too long error handled gracefully

---

## Framework x86_64 Tests

### Test 20: Framework x86_64 Compilation

**Purpose**: Verify all code compiles for x86_64-linux-gnu target

**Test Steps**:
1. Compile workspace persistence module for x86_64-linux-gnu
2. Verify no compilation errors
3. Verify no warnings
4. Verify Grain Style compliance

**Expected**: Compiles successfully for Framework x86_64

### Test 21: Framework x86_64 Execution

**Purpose**: Verify all tests pass on Framework x86_64

**Test Steps**:
1. Run all unit tests on Framework x86_64
2. Run all integration tests on Framework x86_64
3. Verify all tests pass
4. Verify no runtime errors

**Expected**: All tests pass on Framework x86_64

---

## Test Implementation Guidelines

### Grain Style Compliance

**All tests must**:
- Use `grain_case` naming
- Use explicit `u32`/`u64` types
- Have minimum 2 assertions per test
- Use bounded allocations
- Follow max 70 lines per function (if applicable)

### Test Structure

**Recommended Structure**:
```zig
test "save workspace configuration" {
    // Setup
    var io = integrated_file_io.IntegratedFileIO.init(storage_manager);
    var workspace = compositor_workspace_persistence.WorkspaceConfig{
        // ... initialize
    };
    
    // Execute
    try compositor_workspace_persistence.save_workspace_config(
        &io,
        1,
        &workspace,
        current_time,
        user_id,
        group_id,
        allocator,
    );
    
    // Verify
    std.debug.assert(workspace.id == 1);
    // ... more assertions
}
```

### Test Data

**Use Realistic Test Data**:
- Workspace names: "Main", "Work", "Personal"
- Window titles: "Terminal", "Editor", "Browser"
- Window positions: Various x, y coordinates
- Window sizes: Various width, height values

---

## Test Execution

### Running Tests

**Command**:
```bash
zig build test -Dtarget=x86_64-linux-gnu
```

**Or specific test**:
```bash
zig test tests/139_grain_core_compositor_workspace_persistence_test.zig -target x86_64-linux-gnu
```

### Test Coverage Goals

**Target**: 100% function coverage, 90%+ branch coverage

**Priority Tests**:
1. All 7 API functions (Tests 1-10)
2. Error handling (Tests 16-19)
3. Integration workflow (Tests 11-15)
4. Framework x86_64 (Tests 20-21)

---

## Known Limitations in Tests

### 1. Atomic Rename Test

**Status**: Cannot fully test atomic rename (not yet implemented)

**Workaround**: Test that save operation succeeds, note that atomic rename will be added later

### 2. Directory Listing Test

**Status**: Cannot test directory listing (stub implementation)

**Workaround**: Test that stub returns 0, note that Compositor Agent should maintain window ID list in memory

---

## Test Dependencies

### Required Modules

- `grain_core/compositor_workspace_persistence.zig`
- `grain_core/integrated_file_io.zig`
- `grain_core/integrated_file_storage.zig`
- `std.testing`

### Test Infrastructure

- Test allocator (use `std.testing.allocator`)
- Mock time function (for `current_time` parameter)
- Mock user/group IDs (for `user_id`, `group_id` parameters)

---

## Success Criteria

### Unit Tests

- ✅ All 10 unit tests pass
- ✅ All error handling tests pass
- ✅ All tests follow Grain Style

### Integration Tests

- ✅ All 5 integration tests pass
- ✅ Full workflow test passes
- ✅ State recovery test passes

### Framework x86_64 Tests

- ✅ Compilation test passes
- ✅ Execution test passes
- ✅ All tests pass on Framework x86_64

---

## Glow G2 Voice Note

The test plan is ready for your implementation. It covers all 7 API functions, error handling scenarios, integration workflows, and Framework x86_64 verification. The tests follow Grain Style guidelines and use realistic test data. There are two known limitations (atomic rename and directory listing), but they don't block testing. Once you implement these tests, we can verify the workspace persistence API works correctly and is ready for production use.

---

**Date**: 2026-01-06-093141-pst  
**From**: Core 1c Storage Agent (L2 Sub-Agent)  
**Status**: ✅ **TEST PLAN READY** — Comprehensive test plan for workspace persistence API  
**Next**: Compositor Agent test implementation, test execution, Framework x86_64 verification

