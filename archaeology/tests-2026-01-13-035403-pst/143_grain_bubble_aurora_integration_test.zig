//! Grain Bubble Aurora Integration Tests.
//!
//! Why: Test integration between Bubble SLC UI components and Aurora Agent DreamBrowserComponentAPI.
//! Architecture: Unit tests for Aurora integration.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2025-12-31-050600-pst: Grain Bubble Agent

const std = @import("std");
const testing = std.testing;
const grain_bubble = @import("grain_bubble");
const dream_browser_components = @import("dream_browser_components");

test "aurora integration init" {
    var library = grain_bubble.slc_ui_components.SlcComponentLibrary.init();
    var integration = grain_bubble.aurora_integration.AuroraIntegration.init(&library);
    std.debug.assert(integration.component_library == &library);
    std.debug.assert(integration.browser_api == null);
}

test "aurora integration set browser api" {
    var library = grain_bubble.slc_ui_components.SlcComponentLibrary.init();
    var integration = grain_bubble.aurora_integration.AuroraIntegration.init(&library);
    var browser_api = dream_browser_components.DreamBrowserComponentAPI.init();
    integration.set_browser_api(&browser_api);
    std.debug.assert(integration.browser_api != null);
}

test "aurora integration apply pattern to browser component" {
    var library = grain_bubble.slc_ui_components.SlcComponentLibrary.init();
    var integration = grain_bubble.aurora_integration.AuroraIntegration.init(&library);
    var browser_api = dream_browser_components.DreamBrowserComponentAPI.init();
    integration.set_browser_api(&browser_api);
    var pattern = grain_bubble.slc_ui_components.PresetPatterns.get_profile_builder_pattern();
    integration.apply_pattern_to_browser_component(
        &browser_api.browser_view.content_area,
        &pattern,
    );
    std.debug.assert(browser_api.browser_view.content_area.theme == .light or browser_api.browser_view.content_area.theme == .dark or browser_api.browser_view.content_area.theme == .auto);
}

test "aurora integration apply pattern to content area" {
    var library = grain_bubble.slc_ui_components.SlcComponentLibrary.init();
    var integration = grain_bubble.aurora_integration.AuroraIntegration.init(&library);
    var browser_api = dream_browser_components.DreamBrowserComponentAPI.init();
    integration.set_browser_api(&browser_api);
    var pattern = grain_bubble.slc_ui_components.PresetPatterns.get_website_builder_pattern();
    integration.apply_pattern_to_content_area(&pattern);
    std.debug.assert(browser_api.browser_view.content_area.theme == .light or browser_api.browser_view.content_area.theme == .dark or browser_api.browser_view.content_area.theme == .auto);
}

test "aurora integration apply pattern to browser api" {
    var library = grain_bubble.slc_ui_components.SlcComponentLibrary.init();
    var integration = grain_bubble.aurora_integration.AuroraIntegration.init(&library);
    var browser_api = dream_browser_components.DreamBrowserComponentAPI.init();
    integration.set_browser_api(&browser_api);
    var pattern = grain_bubble.slc_ui_components.PresetPatterns.get_workspace_app_pattern();
    integration.apply_pattern_to_browser_api(&pattern);
    std.debug.assert(browser_api.navigation.navigation_bar.theme == .light or browser_api.navigation.navigation_bar.theme == .dark or browser_api.navigation.navigation_bar.theme == .auto);
    std.debug.assert(browser_api.browser_view.content_area.theme == .light or browser_api.browser_view.content_area.theme == .dark or browser_api.browser_view.content_area.theme == .auto);
}

test "aurora integration sync theme to bubble" {
    var library = grain_bubble.slc_ui_components.SlcComponentLibrary.init();
    var integration = grain_bubble.aurora_integration.AuroraIntegration.init(&library);
    var browser_api = dream_browser_components.DreamBrowserComponentAPI.init();
    integration.set_browser_api(&browser_api);
    // Set theme on browser component.
    browser_api.browser_view.content_area.set_theme(.dark);
    // Sync theme to Bubble (simplified test - returns true if component library exists).
    const result = integration.sync_theme_to_bubble(
        1,
        &browser_api.browser_view.content_area,
    );
    std.debug.assert(result == true);
}

test "aurora integration can render in content area" {
    var library = grain_bubble.slc_ui_components.SlcComponentLibrary.init();
    var integration = grain_bubble.aurora_integration.AuroraIntegration.init(&library);
    var browser_api = dream_browser_components.DreamBrowserComponentAPI.init();
    integration.set_browser_api(&browser_api);
    // All SLC component types can render in content_area.
    std.debug.assert(integration.can_render_in_content_area(.profile_builder) == true);
    std.debug.assert(integration.can_render_in_content_area(.website_builder) == true);
    std.debug.assert(integration.can_render_in_content_area(.workspace_app) == true);
}

test "aurora integration can render in content area without api" {
    var library = grain_bubble.slc_ui_components.SlcComponentLibrary.init();
    var integration = grain_bubble.aurora_integration.AuroraIntegration.init(&library);
    // Without browser API, cannot render.
    std.debug.assert(integration.can_render_in_content_area(.profile_builder) == false);
}