//! Tests for Grain Aurora Dream Editor Component API.
//!
//! Tests component API structure per approved design (Core Agent coordination
//! decision 2025-12-28-125036-pst, Phase 1 approval 2026-01-06-093037-pst).
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2026-01-06-095653-pst: Dream Editor Component API Tests (Phase 1)

const std = @import("std");
const testing = std.testing;
const dream_editor_components = @import("dream_editor_components");

test "Component init" {
    const comp = dream_editor_components.Component.init(70, "test_component");
    try testing.expect(comp.id == 70);
    try testing.expect(comp.name_len == 14);
    try testing.expect(comp.state == .normal);
    try testing.expect(comp.size == .medium);
    try testing.expect(comp.theme == .light);
    try testing.expect(comp.visible == true);
    try testing.expect(comp.enabled == true);
}

test "Component set_state" {
    var comp = dream_editor_components.Component.init(70, "test");
    comp.set_state(.hover);
    try testing.expect(comp.state == .hover);
    comp.set_state(.active);
    try testing.expect(comp.state == .active);
    comp.set_state(.disabled);
    try testing.expect(comp.state == .disabled);
    comp.set_state(.focused);
    try testing.expect(comp.state == .focused);
    comp.set_state(.normal);
    try testing.expect(comp.state == .normal);
}

test "Component set_size" {
    var comp = dream_editor_components.Component.init(70, "test");
    comp.set_size(.small);
    try testing.expect(comp.size == .small);
    comp.set_size(.large);
    try testing.expect(comp.size == .large);
    comp.set_size(.medium);
    try testing.expect(comp.size == .medium);
}

test "Component set_theme" {
    var comp = dream_editor_components.Component.init(70, "test");
    comp.set_theme(.dark);
    try testing.expect(comp.theme == .dark);
    comp.set_theme(.high_contrast);
    try testing.expect(comp.theme == .high_contrast);
    comp.set_theme(.light);
    try testing.expect(comp.theme == .light);
}

test "EditorPaneComponents init" {
    const pane_components = dream_editor_components.EditorPaneComponents.init();
    try testing.expect(pane_components.left_pane.id == 70);
    try testing.expect(pane_components.center_pane.id == 71);
    try testing.expect(pane_components.right_pane.id == 72);
    try testing.expect(pane_components.split_pane_vertical.id == 73);
    try testing.expect(pane_components.split_pane_horizontal.id == 74);
    try testing.expect(pane_components.left_pane.name_len > 0);
    try testing.expect(pane_components.center_pane.name_len > 0);
    try testing.expect(pane_components.right_pane.name_len > 0);
}

test "EditorPaneComponents set_state_all" {
    var pane_components = dream_editor_components.EditorPaneComponents.init();
    pane_components.set_state_all(.hover);
    try testing.expect(pane_components.left_pane.state == .hover);
    try testing.expect(pane_components.center_pane.state == .hover);
    try testing.expect(pane_components.right_pane.state == .hover);
    try testing.expect(pane_components.split_pane_vertical.state == .hover);
    try testing.expect(pane_components.split_pane_horizontal.state == .hover);
    pane_components.set_state_all(.active);
    try testing.expect(pane_components.left_pane.state == .active);
}

test "EditorPaneComponents set_size_all" {
    var pane_components = dream_editor_components.EditorPaneComponents.init();
    pane_components.set_size_all(.small);
    try testing.expect(pane_components.left_pane.size == .small);
    try testing.expect(pane_components.center_pane.size == .small);
    try testing.expect(pane_components.right_pane.size == .small);
    try testing.expect(pane_components.split_pane_vertical.size == .small);
    try testing.expect(pane_components.split_pane_horizontal.size == .small);
    pane_components.set_size_all(.large);
    try testing.expect(pane_components.left_pane.size == .large);
}

test "EditorPaneComponents set_theme_all" {
    var pane_components = dream_editor_components.EditorPaneComponents.init();
    pane_components.set_theme_all(.dark);
    try testing.expect(pane_components.left_pane.theme == .dark);
    try testing.expect(pane_components.center_pane.theme == .dark);
    try testing.expect(pane_components.right_pane.theme == .dark);
    try testing.expect(pane_components.split_pane_vertical.theme == .dark);
    try testing.expect(pane_components.split_pane_horizontal.theme == .dark);
    pane_components.set_theme_all(.high_contrast);
    try testing.expect(pane_components.left_pane.theme == .high_contrast);
}

test "EditorTabComponents init" {
    const tab_components = dream_editor_components.EditorTabComponents.init();
    try testing.expect(tab_components.tab_bar.id == 80);
    try testing.expect(tab_components.tab_view.id == 81);
    try testing.expect(tab_components.new_tab_button.id == 82);
    try testing.expect(tab_components.close_tab_button.id == 83);
    try testing.expect(tab_components.tab_bar.name_len > 0);
    try testing.expect(tab_components.tab_view.name_len > 0);
}

test "EditorTabComponents set_state_all" {
    var tab_components = dream_editor_components.EditorTabComponents.init();
    tab_components.set_state_all(.hover);
    try testing.expect(tab_components.tab_bar.state == .hover);
    try testing.expect(tab_components.tab_view.state == .hover);
    try testing.expect(tab_components.new_tab_button.state == .hover);
    try testing.expect(tab_components.close_tab_button.state == .hover);
    tab_components.set_state_all(.active);
    try testing.expect(tab_components.tab_bar.state == .active);
}

test "EditorTabComponents set_size_all" {
    var tab_components = dream_editor_components.EditorTabComponents.init();
    tab_components.set_size_all(.small);
    try testing.expect(tab_components.tab_bar.size == .small);
    try testing.expect(tab_components.tab_view.size == .small);
    try testing.expect(tab_components.new_tab_button.size == .small);
    try testing.expect(tab_components.close_tab_button.size == .small);
    tab_components.set_size_all(.large);
    try testing.expect(tab_components.tab_bar.size == .large);
}

test "EditorTabComponents set_theme_all" {
    var tab_components = dream_editor_components.EditorTabComponents.init();
    tab_components.set_theme_all(.dark);
    try testing.expect(tab_components.tab_bar.theme == .dark);
    try testing.expect(tab_components.tab_view.theme == .dark);
    try testing.expect(tab_components.new_tab_button.theme == .dark);
    try testing.expect(tab_components.close_tab_button.theme == .dark);
    tab_components.set_theme_all(.high_contrast);
    try testing.expect(tab_components.tab_bar.theme == .high_contrast);
}

test "EditorStatusBarComponents init" {
    const status_components = dream_editor_components.EditorStatusBarComponents.init();
    try testing.expect(status_components.status_bar.id == 90);
    try testing.expect(status_components.line_number.id == 91);
    try testing.expect(status_components.column_number.id == 92);
    try testing.expect(status_components.mode_indicator.id == 93);
    try testing.expect(status_components.file_path.id == 94);
    try testing.expect(status_components.diagnostics_count.id == 95);
    try testing.expect(status_components.status_bar.name_len > 0);
    try testing.expect(status_components.line_number.name_len > 0);
}

test "EditorStatusBarComponents set_state_all" {
    var status_components = dream_editor_components.EditorStatusBarComponents.init();
    status_components.set_state_all(.hover);
    try testing.expect(status_components.status_bar.state == .hover);
    try testing.expect(status_components.line_number.state == .hover);
    try testing.expect(status_components.column_number.state == .hover);
    try testing.expect(status_components.mode_indicator.state == .hover);
    try testing.expect(status_components.file_path.state == .hover);
    try testing.expect(status_components.diagnostics_count.state == .hover);
    status_components.set_state_all(.active);
    try testing.expect(status_components.status_bar.state == .active);
}

test "EditorStatusBarComponents set_size_all" {
    var status_components = dream_editor_components.EditorStatusBarComponents.init();
    status_components.set_size_all(.small);
    try testing.expect(status_components.status_bar.size == .small);
    try testing.expect(status_components.line_number.size == .small);
    try testing.expect(status_components.column_number.size == .small);
    try testing.expect(status_components.mode_indicator.size == .small);
    try testing.expect(status_components.file_path.size == .small);
    try testing.expect(status_components.diagnostics_count.size == .small);
    status_components.set_size_all(.large);
    try testing.expect(status_components.status_bar.size == .large);
}

test "EditorStatusBarComponents set_theme_all" {
    var status_components = dream_editor_components.EditorStatusBarComponents.init();
    status_components.set_theme_all(.dark);
    try testing.expect(status_components.status_bar.theme == .dark);
    try testing.expect(status_components.line_number.theme == .dark);
    try testing.expect(status_components.column_number.theme == .dark);
    try testing.expect(status_components.mode_indicator.theme == .dark);
    try testing.expect(status_components.file_path.theme == .dark);
    try testing.expect(status_components.diagnostics_count.theme == .dark);
    status_components.set_theme_all(.high_contrast);
    try testing.expect(status_components.status_bar.theme == .high_contrast);
}

test "EditorToolbarComponents init" {
    const toolbar_components = dream_editor_components.EditorToolbarComponents.init();
    try testing.expect(toolbar_components.toolbar.id == 96);
    try testing.expect(toolbar_components.save_button.id == 97);
    try testing.expect(toolbar_components.open_button.id == 98);
    try testing.expect(toolbar_components.toolbar.name_len > 0);
    try testing.expect(toolbar_components.save_button.name_len > 0);
}

test "EditorToolbarComponents set_state_all" {
    var toolbar_components = dream_editor_components.EditorToolbarComponents.init();
    toolbar_components.set_state_all(.hover);
    try testing.expect(toolbar_components.toolbar.state == .hover);
    try testing.expect(toolbar_components.save_button.state == .hover);
    try testing.expect(toolbar_components.open_button.state == .hover);
    toolbar_components.set_state_all(.active);
    try testing.expect(toolbar_components.toolbar.state == .active);
}

test "EditorToolbarComponents set_size_all" {
    var toolbar_components = dream_editor_components.EditorToolbarComponents.init();
    toolbar_components.set_size_all(.small);
    try testing.expect(toolbar_components.toolbar.size == .small);
    try testing.expect(toolbar_components.save_button.size == .small);
    try testing.expect(toolbar_components.open_button.size == .small);
    toolbar_components.set_size_all(.large);
    try testing.expect(toolbar_components.toolbar.size == .large);
}

test "EditorToolbarComponents set_theme_all" {
    var toolbar_components = dream_editor_components.EditorToolbarComponents.init();
    toolbar_components.set_theme_all(.dark);
    try testing.expect(toolbar_components.toolbar.theme == .dark);
    try testing.expect(toolbar_components.save_button.theme == .dark);
    try testing.expect(toolbar_components.open_button.theme == .dark);
    toolbar_components.set_theme_all(.high_contrast);
    try testing.expect(toolbar_components.toolbar.theme == .high_contrast);
}

test "DreamEditorComponentAPI init" {
    const api = dream_editor_components.DreamEditorComponentAPI.init();
    try testing.expect(api.panes.left_pane.id == 70);
    try testing.expect(api.tabs.tab_bar.id == 80);
    try testing.expect(api.status_bar.status_bar.id == 90);
    try testing.expect(api.toolbar.toolbar.id == 96);
}

test "DreamEditorComponentAPI set_theme_all" {
    var api = dream_editor_components.DreamEditorComponentAPI.init();
    api.set_theme_all(.dark);
    try testing.expect(api.panes.left_pane.theme == .dark);
    try testing.expect(api.tabs.tab_bar.theme == .dark);
    try testing.expect(api.status_bar.status_bar.theme == .dark);
    try testing.expect(api.toolbar.toolbar.theme == .dark);
    api.set_theme_all(.high_contrast);
    try testing.expect(api.panes.left_pane.theme == .high_contrast);
    try testing.expect(api.tabs.tab_bar.theme == .high_contrast);
    try testing.expect(api.status_bar.status_bar.theme == .high_contrast);
    try testing.expect(api.toolbar.toolbar.theme == .high_contrast);
}

test "DreamEditorComponentAPI set_size_all" {
    var api = dream_editor_components.DreamEditorComponentAPI.init();
    api.set_size_all(.large);
    try testing.expect(api.panes.left_pane.size == .large);
    try testing.expect(api.tabs.tab_bar.size == .large);
    try testing.expect(api.status_bar.status_bar.size == .large);
    try testing.expect(api.toolbar.toolbar.size == .large);
    api.set_size_all(.small);
    try testing.expect(api.panes.left_pane.size == .small);
    try testing.expect(api.tabs.tab_bar.size == .small);
    try testing.expect(api.status_bar.status_bar.size == .small);
    try testing.expect(api.toolbar.toolbar.size == .small);
}

test "Component name truncation" {
    const long_name = "a" ** 100;
    const comp = dream_editor_components.Component.init(70, long_name);
    try testing.expect(comp.name_len == dream_editor_components.MAX_COMPONENT_NAME_LEN);
    try testing.expect(comp.name_len <= dream_editor_components.MAX_COMPONENT_NAME_LEN);
}

test "Component variant combinations" {
    var comp = dream_editor_components.Component.init(70, "test");
    comp.set_state(.hover);
    comp.set_size(.large);
    comp.set_theme(.dark);
    try testing.expect(comp.state == .hover);
    try testing.expect(comp.size == .large);
    try testing.expect(comp.theme == .dark);
    comp.set_state(.active);
    comp.set_size(.small);
    comp.set_theme(.high_contrast);
    try testing.expect(comp.state == .active);
    try testing.expect(comp.size == .small);
    try testing.expect(comp.theme == .high_contrast);
}


