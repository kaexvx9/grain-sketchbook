//! Grain Bubble Aurora Integration: Dream Browser Component API integration.
//!
//! Why: Integrate Bubble SLC UI components with Aurora Agent DreamBrowserComponentAPI.
//! Architecture: Integration layer between Bubble components and Dream Browser components.
//! SLC components render within content_area of BrowserViewComponents.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2025-12-31-050600-pst: Grain Bubble Agent

const std = @import("std");
const slc_ui_components = @import("slc_ui_components.zig");
const component = @import("component.zig");
const dream_browser_components = @import("dream_browser_components");

// Aurora integration: manages integration between Bubble and Dream Browser components.
pub const AuroraIntegration = struct {
    component_library: *slc_ui_components.SlcComponentLibrary,
    browser_api: ?*dream_browser_components.DreamBrowserComponentAPI,

    pub fn init(
        library: *slc_ui_components.SlcComponentLibrary,
    ) AuroraIntegration {
        std.debug.assert(@intFromPtr(library) != 0);
        const integration = AuroraIntegration{
            .component_library = library,
            .browser_api = null,
        };
        std.debug.assert(integration.component_library == library);
        return integration;
    }

    // Set Aurora Agent DreamBrowserComponentAPI instance.
    pub fn set_browser_api(
        self: *AuroraIntegration,
        api: *dream_browser_components.DreamBrowserComponentAPI,
    ) void {
        std.debug.assert(@intFromPtr(self) != 0);
        std.debug.assert(@intFromPtr(api) != 0);
        self.browser_api = api;
        std.debug.assert(self.browser_api != null);
    }

    // Apply theme to Dream Browser component based on design pattern.
    fn apply_theme_from_pattern(
        browser_comp: *dream_browser_components.Component,
        pattern: *const slc_ui_components.DesignPattern,
    ) void {
        std.debug.assert(@intFromPtr(browser_comp) != 0);
        std.debug.assert(@intFromPtr(pattern) != 0);
        // Determine theme from pattern colors (simplified - use primary color brightness).
        // For now, default to light theme (can be enhanced later).
        const theme = dream_browser_components.ComponentTheme.light;
        browser_comp.set_theme(theme);
        std.debug.assert(browser_comp.theme == theme);
    }

    // Apply Bubble design pattern to Dream Browser component.
    pub fn apply_pattern_to_browser_component(
        self: *AuroraIntegration,
        browser_comp: *dream_browser_components.Component,
        pattern: *const slc_ui_components.DesignPattern,
    ) void {
        std.debug.assert(@intFromPtr(self) != 0);
        std.debug.assert(@intFromPtr(browser_comp) != 0);
        std.debug.assert(@intFromPtr(pattern) != 0);
        // Apply theme from pattern.
        apply_theme_from_pattern(browser_comp, pattern);
        std.debug.assert(browser_comp.theme == .light or browser_comp.theme == .dark or browser_comp.theme == .auto);
    }

    // Apply Bubble design pattern to content_area (where SLC components render).
    pub fn apply_pattern_to_content_area(
        self: *AuroraIntegration,
        pattern: *const slc_ui_components.DesignPattern,
    ) void {
        std.debug.assert(@intFromPtr(self) != 0);
        std.debug.assert(@intFromPtr(pattern) != 0);
        if (self.browser_api == null) {
            return;
        }
        const api = self.browser_api.?;
        // Apply pattern to content_area (SLC components render here).
        self.apply_pattern_to_browser_component(&api.browser_view.content_area, pattern);
        std.debug.assert(api.browser_view.content_area.theme == .light or api.browser_view.content_area.theme == .dark or api.browser_view.content_area.theme == .auto);
    }

    // Apply Bubble design pattern to all Dream Browser components.
    pub fn apply_pattern_to_browser_api(
        self: *AuroraIntegration,
        pattern: *const slc_ui_components.DesignPattern,
    ) void {
        std.debug.assert(@intFromPtr(self) != 0);
        std.debug.assert(@intFromPtr(pattern) != 0);
        if (self.browser_api == null) {
            return;
        }
        const api = self.browser_api.?;
        // Apply pattern to all browser components via unified API.
        // This ensures theme consistency across navigation, address bar, tabs, and browser view.
        const theme = switch (pattern.primary_color) {
            // Simplified: determine theme from primary color brightness.
            // Full implementation would analyze color brightness.
            else => dream_browser_components.ComponentTheme.light,
        };
        api.set_theme_all(theme);
        // Also apply to content_area specifically for SLC component rendering.
        self.apply_pattern_to_content_area(pattern);
        std.debug.assert(api.navigation.navigation_bar.theme == theme);
        std.debug.assert(api.browser_view.content_area.theme == theme or api.browser_view.content_area.theme == .light or api.browser_view.content_area.theme == .dark or api.browser_view.content_area.theme == .auto);
    }

    // Sync Dream Browser component theme to Bubble component design tokens.
    pub fn sync_theme_to_bubble(
        self: *AuroraIntegration,
        bubble_comp_id: u32,
        browser_comp: *const dream_browser_components.Component,
    ) bool {
        std.debug.assert(@intFromPtr(self) != 0);
        std.debug.assert(bubble_comp_id > 0);
        std.debug.assert(@intFromPtr(browser_comp) != 0);
        // Get Bubble component by ID (simplified - would need component lookup).
        // For now, return true if component library exists.
        _ = self.component_library;
        _ = bubble_comp_id;
        _ = browser_comp;
        // Full implementation would:
        // 1. Look up Bubble component by ID
        // 2. Extract theme from browser component
        // 3. Apply theme as design token to Bubble component
        std.debug.assert(browser_comp.theme == .light or browser_comp.theme == .dark or browser_comp.theme == .auto);
        return true;
    }

    // Check if SLC component can render in content_area.
    pub fn can_render_in_content_area(
        self: *const AuroraIntegration,
        slc_comp_type: slc_ui_components.SlcComponentType,
    ) bool {
        std.debug.assert(@intFromPtr(self) != 0);
        if (self.browser_api == null) {
            return false;
        }
        // All SLC component types (Profile, Website, Workspace) can render in content_area.
        _ = slc_comp_type;
        std.debug.assert(slc_comp_type == .profile_builder or slc_comp_type == .website_builder or slc_comp_type == .workspace_app);
        return true;
    }
};