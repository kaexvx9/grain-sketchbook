//! Grain Aurora Dream Editor Component API: Component structures for editor.
//!
//! Why: Provide component API structure for Dream Editor per Workspace Agent
//! Component API pattern (Core Agent coordination decision 2025-12-28-125036-pst).
//! Architecture: Component API with variant support (state/size/theme), adapted
//! for editor context (panes, tabs, status bar, toolbar, etc.).
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2026-01-06-095653-pst: Dream Editor Component API Implementation (Phase 1)

const std = @import("std");
const workspace_components = @import("grain_workspace").components;

// Re-export component base types from Workspace Agent for consistency.
pub const Component = workspace_components.Component;
pub const ComponentState = workspace_components.ComponentState;
pub const ComponentSize = workspace_components.ComponentSize;
pub const ComponentTheme = workspace_components.ComponentTheme;
pub const MAX_COMPONENT_NAME_LEN = workspace_components.MAX_COMPONENT_NAME_LEN;
pub const MAX_COMPONENT_ID = workspace_components.MAX_COMPONENT_ID;

// Editor pane components: left_pane, center_pane, right_pane, split panes.
pub const EditorPaneComponents = struct {
    left_pane: Component,
    center_pane: Component,
    right_pane: Component,
    split_pane_vertical: Component,
    split_pane_horizontal: Component,

    pub fn init() EditorPaneComponents {
        const components = EditorPaneComponents{
            .left_pane = Component.init(70, "left_pane"),
            .center_pane = Component.init(71, "center_pane"),
            .right_pane = Component.init(72, "right_pane"),
            .split_pane_vertical = Component.init(73, "split_pane_vertical"),
            .split_pane_horizontal = Component.init(74, "split_pane_horizontal"),
        };
        std.debug.assert(components.left_pane.id == 70);
        std.debug.assert(components.center_pane.id == 71);
        std.debug.assert(components.right_pane.id == 72);
        std.debug.assert(components.split_pane_vertical.id == 73);
        std.debug.assert(components.split_pane_horizontal.id == 74);
        return components;
    }

    pub fn set_state_all(self: *EditorPaneComponents, state: ComponentState) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.left_pane.set_state(state);
        self.center_pane.set_state(state);
        self.right_pane.set_state(state);
        self.split_pane_vertical.set_state(state);
        self.split_pane_horizontal.set_state(state);
        std.debug.assert(self.left_pane.state == state);
    }

    pub fn set_size_all(self: *EditorPaneComponents, size: ComponentSize) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.left_pane.set_size(size);
        self.center_pane.set_size(size);
        self.right_pane.set_size(size);
        self.split_pane_vertical.set_size(size);
        self.split_pane_horizontal.set_size(size);
        std.debug.assert(self.left_pane.size == size);
    }

    pub fn set_theme_all(self: *EditorPaneComponents, theme: ComponentTheme) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.left_pane.set_theme(theme);
        self.center_pane.set_theme(theme);
        self.right_pane.set_theme(theme);
        self.split_pane_vertical.set_theme(theme);
        self.split_pane_horizontal.set_theme(theme);
        std.debug.assert(self.left_pane.theme == theme);
    }
};

// Editor tab components: tab_bar, tab_view, new_tab_button, close_tab_button.
pub const EditorTabComponents = struct {
    tab_bar: Component,
    tab_view: Component,
    new_tab_button: Component,
    close_tab_button: Component,

    pub fn init() EditorTabComponents {
        const components = EditorTabComponents{
            .tab_bar = Component.init(80, "tab_bar"),
            .tab_view = Component.init(81, "tab_view"),
            .new_tab_button = Component.init(82, "new_tab_button"),
            .close_tab_button = Component.init(83, "close_tab_button"),
        };
        std.debug.assert(components.tab_bar.id == 80);
        std.debug.assert(components.tab_view.id == 81);
        std.debug.assert(components.new_tab_button.id == 82);
        std.debug.assert(components.close_tab_button.id == 83);
        return components;
    }

    pub fn set_state_all(self: *EditorTabComponents, state: ComponentState) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.tab_bar.set_state(state);
        self.tab_view.set_state(state);
        self.new_tab_button.set_state(state);
        self.close_tab_button.set_state(state);
        std.debug.assert(self.tab_bar.state == state);
    }

    pub fn set_size_all(self: *EditorTabComponents, size: ComponentSize) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.tab_bar.set_size(size);
        self.tab_view.set_size(size);
        self.new_tab_button.set_size(size);
        self.close_tab_button.set_size(size);
        std.debug.assert(self.tab_bar.size == size);
    }

    pub fn set_theme_all(self: *EditorTabComponents, theme: ComponentTheme) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.tab_bar.set_theme(theme);
        self.tab_view.set_theme(theme);
        self.new_tab_button.set_theme(theme);
        self.close_tab_button.set_theme(theme);
        std.debug.assert(self.tab_bar.theme == theme);
    }
};

// Editor status bar components: status_bar, line_number, column_number, etc.
pub const EditorStatusBarComponents = struct {
    status_bar: Component,
    line_number: Component,
    column_number: Component,
    mode_indicator: Component,
    file_path: Component,
    diagnostics_count: Component,

    pub fn init() EditorStatusBarComponents {
        const components = EditorStatusBarComponents{
            .status_bar = Component.init(90, "status_bar"),
            .line_number = Component.init(91, "line_number"),
            .column_number = Component.init(92, "column_number"),
            .mode_indicator = Component.init(93, "mode_indicator"),
            .file_path = Component.init(94, "file_path"),
            .diagnostics_count = Component.init(95, "diagnostics_count"),
        };
        std.debug.assert(components.status_bar.id == 90);
        std.debug.assert(components.line_number.id == 91);
        std.debug.assert(components.column_number.id == 92);
        std.debug.assert(components.mode_indicator.id == 93);
        std.debug.assert(components.file_path.id == 94);
        std.debug.assert(components.diagnostics_count.id == 95);
        return components;
    }

    pub fn set_state_all(self: *EditorStatusBarComponents, state: ComponentState) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.status_bar.set_state(state);
        self.line_number.set_state(state);
        self.column_number.set_state(state);
        self.mode_indicator.set_state(state);
        self.file_path.set_state(state);
        self.diagnostics_count.set_state(state);
        std.debug.assert(self.status_bar.state == state);
    }

    pub fn set_size_all(self: *EditorStatusBarComponents, size: ComponentSize) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.status_bar.set_size(size);
        self.line_number.set_size(size);
        self.column_number.set_size(size);
        self.mode_indicator.set_size(size);
        self.file_path.set_size(size);
        self.diagnostics_count.set_size(size);
        std.debug.assert(self.status_bar.size == size);
    }

    pub fn set_theme_all(self: *EditorStatusBarComponents, theme: ComponentTheme) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.status_bar.set_theme(theme);
        self.line_number.set_theme(theme);
        self.column_number.set_theme(theme);
        self.mode_indicator.set_theme(theme);
        self.file_path.set_theme(theme);
        self.diagnostics_count.set_theme(theme);
        std.debug.assert(self.status_bar.theme == theme);
    }
};

// Editor toolbar components: toolbar, save_button, open_button.
pub const EditorToolbarComponents = struct {
    toolbar: Component,
    save_button: Component,
    open_button: Component,

    pub fn init() EditorToolbarComponents {
        const components = EditorToolbarComponents{
            .toolbar = Component.init(96, "toolbar"),
            .save_button = Component.init(97, "save_button"),
            .open_button = Component.init(98, "open_button"),
        };
        std.debug.assert(components.toolbar.id == 96);
        std.debug.assert(components.save_button.id == 97);
        std.debug.assert(components.open_button.id == 98);
        return components;
    }

    pub fn set_state_all(self: *EditorToolbarComponents, state: ComponentState) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.toolbar.set_state(state);
        self.save_button.set_state(state);
        self.open_button.set_state(state);
        std.debug.assert(self.toolbar.state == state);
    }

    pub fn set_size_all(self: *EditorToolbarComponents, size: ComponentSize) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.toolbar.set_size(size);
        self.save_button.set_size(size);
        self.open_button.set_size(size);
        std.debug.assert(self.toolbar.size == size);
    }

    pub fn set_theme_all(self: *EditorToolbarComponents, theme: ComponentTheme) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.toolbar.set_theme(theme);
        self.save_button.set_theme(theme);
        self.open_button.set_theme(theme);
        std.debug.assert(self.toolbar.theme == theme);
    }
};

// Dream Editor Component API: unified API for all editor components.
pub const RealidreamEditorComponentAPI = struct {
    panes: EditorPaneComponents,
    tabs: EditorTabComponents,
    status_bar: EditorStatusBarComponents,
    toolbar: EditorToolbarComponents,

    pub fn init() RealidreamEditorComponentAPI {
        const api = RealidreamEditorComponentAPI{
            .panes = EditorPaneComponents.init(),
            .tabs = EditorTabComponents.init(),
            .status_bar = EditorStatusBarComponents.init(),
            .toolbar = EditorToolbarComponents.init(),
        };
        std.debug.assert(api.panes.left_pane.id == 70);
        std.debug.assert(api.tabs.tab_bar.id == 80);
        std.debug.assert(api.status_bar.status_bar.id == 90);
        std.debug.assert(api.toolbar.toolbar.id == 96);
        return api;
    }

    pub fn set_theme_all(self: *RealidreamEditorComponentAPI, theme: ComponentTheme) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.panes.set_theme_all(theme);
        self.tabs.set_theme_all(theme);
        self.status_bar.set_theme_all(theme);
        self.toolbar.set_theme_all(theme);
        std.debug.assert(self.panes.left_pane.theme == theme);
    }

    pub fn set_size_all(self: *RealidreamEditorComponentAPI, size: ComponentSize) void {
        std.debug.assert(@intFromPtr(self) != 0);
        self.panes.set_size_all(size);
        self.tabs.set_size_all(size);
        self.status_bar.set_size_all(size);
        self.toolbar.set_size_all(size);
        std.debug.assert(self.panes.left_pane.size == size);
    }
};


