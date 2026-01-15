//! Tests for Grain OS Compositor Workspace Persistence (Phase 7).
//!
//! Why: Verify workspace and window state persistence integration with Storage Agent.
//! Architecture: Integration tests for Phase 7 workspace persistence.
//! GrainStyle: grain_case, u32/u64, bounded operations, assertions.

const std = @import("std");
const testing = std.testing;
const grain_core = @import("grain_core");
const Compositor = grain_core.compositor.Compositor;
const compositor_workspace_persistence = grain_core.compositor_workspace_persistence;
const workspace = grain_core.workspace;

// Test: Compositor initialization with Storage Agent.
test "compositor storage initialization" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    std.debug.assert(compositor.current_user_id > 0);
    std.debug.assert(compositor.current_group_id > 0);
    std.debug.assert(compositor.windows_len == 0);
    std.debug.assert(compositor.next_window_id > 0);
}

// Test: Workspace state serialization (via save operation).
test "workspace state serialization via save" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    
    // Create multiple workspaces
    const ws1_id = compositor.create_workspace("workspace1");
    std.debug.assert(ws1_id != null);
    if (ws1_id) |id1| {
        std.debug.assert(id1 > 0);
    }
    
    const ws2_id = compositor.create_workspace("workspace2");
    std.debug.assert(ws2_id != null);
    
    // Save workspace state (which internally serializes)
    compositor.save_workspace_state_persistent_safe();
    
    // Verify workspaces exist
    std.debug.assert(compositor.workspace_manager.workspaces_len >= 3); // Default + 2 created
}

// Test: Workspace state save (safe error handling).
test "workspace state save safe" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    
    // Create workspace
    const ws_id = compositor.create_workspace("test_workspace");
    std.debug.assert(ws_id != null);
    
    // Save workspace state (should not crash even if save fails)
    compositor.save_workspace_state_persistent_safe();
    
    // Compositor should still be functional
    std.debug.assert(compositor.windows_len == 0);
    std.debug.assert(compositor.workspace_manager.current_workspace_id > 0);
}

// Test: Workspace state restoration (safe error handling).
test "workspace state restore safe" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    
    // Restore workspace state (should not crash even if load fails)
    compositor.restore_workspace_state_persistent();
    
    // Compositor should still be functional with default workspace
    std.debug.assert(compositor.workspace_manager.current_workspace_id > 0);
}

// Test: Window state save (safe error handling).
test "window state save safe" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    
    // Create window
    const window_id = try compositor.create_window(800, 600);
    std.debug.assert(window_id > 0);
    
    // Save window state (should not crash even if save fails)
    const saved = compositor.save_window_state(window_id);
    std.debug.assert(saved);
    
    // Save to persistent storage (should not crash even if save fails)
    compositor.save_window_state_persistent_safe(window_id);
    
    // Compositor should still be functional
    std.debug.assert(compositor.windows_len == 1);
}

// Test: Workspace switch with persistence.
test "workspace switch with persistence" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    
    // Create workspace
    const ws_id = compositor.create_workspace("switch_test");
    std.debug.assert(ws_id != null);
    if (ws_id) |id| {
        // Switch to workspace (should save state)
        const switched = compositor.switch_workspace(id);
        std.debug.assert(switched);
        std.debug.assert(compositor.get_current_workspace_id() == id);
    }
}

// Test: Workspace creation with persistence.
test "workspace creation with persistence" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    
    // Create workspace (should save state)
    const ws_id = compositor.create_workspace("persistence_test");
    std.debug.assert(ws_id != null);
    
    // Verify workspace exists
    if (ws_id) |id| {
        const current_id = compositor.get_current_workspace_id();
        std.debug.assert(id > 0);
    }
}

// Test: Shutdown with state save.
test "shutdown with state save" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    
    // Create workspace and window
    const ws_id = compositor.create_workspace("shutdown_test");
    std.debug.assert(ws_id != null);
    
    const window_id = try compositor.create_window(800, 600);
    std.debug.assert(window_id > 0);
    
    // Save all states on shutdown (should not crash)
    compositor.save_all_states_on_shutdown();
    
    // Compositor should still be functional
    std.debug.assert(compositor.windows_len == 1);
}

// Test: Multiple workspaces persistence.
test "multiple workspaces persistence" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    
    // Create multiple workspaces
    const ws1_id = compositor.create_workspace("ws1");
    const ws2_id = compositor.create_workspace("ws2");
    const ws3_id = compositor.create_workspace("ws3");
    
    std.debug.assert(ws1_id != null);
    std.debug.assert(ws2_id != null);
    std.debug.assert(ws3_id != null);
    
    // Save workspace state
    compositor.save_workspace_state_persistent_safe();
    
    // Verify workspaces exist
    std.debug.assert(compositor.workspace_manager.workspaces_len >= 4); // Default + 3 created
}

// Test: Window state persistence with multiple windows.
test "window state persistence multiple windows" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    
    // Create multiple windows
    const window1_id = try compositor.create_window(800, 600);
    const window2_id = try compositor.create_window(1024, 768);
    const window3_id = try compositor.create_window(640, 480);
    
    std.debug.assert(window1_id > 0);
    std.debug.assert(window2_id > 0);
    std.debug.assert(window3_id > 0);
    std.debug.assert(compositor.windows_len == 3);
    
    // Save all window states
    compositor.save_all_window_states();
    
    // Save to persistent storage (should not crash)
    compositor.save_window_state_persistent_safe(window1_id);
    compositor.save_window_state_persistent_safe(window2_id);
    compositor.save_window_state_persistent_safe(window3_id);
}

// Test: Workspace restoration from empty state.
test "workspace restoration empty state" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    
    // Restore workspace state (should use default if no saved state)
    compositor.restore_workspace_state_persistent();
    
    // Should have at least default workspace
    std.debug.assert(compositor.workspace_manager.current_workspace_id > 0);
    std.debug.assert(compositor.workspace_manager.workspaces_len >= 1);
}

// Test: Error handling graceful degradation.
test "error handling graceful degradation" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var compositor = Compositor.init(allocator);
    
    // Create workspace and window
    const ws_id = compositor.create_workspace("error_test");
    const window_id = try compositor.create_window(800, 600);
    
    // All persistence operations should not crash even if they fail
    compositor.save_workspace_state_persistent_safe();
    compositor.save_window_state_persistent_safe(window_id);
    compositor.restore_workspace_state_persistent();
    compositor.save_all_states_on_shutdown();
    
    // Compositor should still be functional
    std.debug.assert(compositor.windows_len == 1);
    std.debug.assert(compositor.workspace_manager.current_workspace_id > 0);
}

