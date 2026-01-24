//! Skate: Main Application Window
//!
//! Why: Primary Skate application window integrating all components.
//! Coordinates editor, file browser, and UI elements with Grain Shine protocol.
//!
//! Agents: Core 1 (Implementation) + Glow (Design) + Reya (Architecture)

const std = @import("std");
const widget_base = @import("../../grain_core/gui_toolkit/widget_base.zig");
const skate_editor = @import("skate_editor_widget.zig");
const shine = @import("../../grain_core/shine/compositor_core.zig");

const Widget = widget_base.Widget;
const SkateEditorWidget = skate_editor.SkateEditorWidget;
const CompositorCore = shine.CompositorCore;

/// Why: Main Skate application window with editor and UI.
/// Integrates all Skate components into cohesive application interface.
pub const SkateMainWindow = struct {
    const Self = @This();
    
    allocator: std.mem.Allocator,
    compositor: *CompositorCore,
    root_widget: Widget,
    editor_widget: ?SkateEditorWidget,
    surface_id: u32,
    client_id: u32,
    
    /// Why: Initialize main Skate window with Grain Shine connection.
    pub fn init(allocator: std.mem.Allocator, compositor: *CompositorCore) !Self {
        // Why: Connect to compositor as client.
        const client_id = try compositor.addClient();
        
        // Why: Create surface for window.
        const surface_id: u32 = 100; // Simplified - real implementation would get from compositor
        
        // Why: Create root widget container.
        const root_widget = try Widget.init(allocator, 1, 0, 0, 1920, 1080, .container);
        
        return Self{
            .allocator = allocator,
            .compositor = compositor,
            .root_widget = root_widget,
            .editor_widget = null,
            .surface_id = surface_id,
            .client_id = client_id,
        };
    }
    
    /// Why: Cleanup window resources.
    pub fn deinit(self: *Self) void {
        if (self.editor_widget) |*editor| {
            editor.deinit();
        }
        self.root_widget.deinit();
    }
    
    /// Why: Initialize editor panel in window with proper surface connection.
    pub fn createEditor(self: *Self) !void {
        // Why: Create surface for editor widget through compositor.
        // In real implementation, this would send create_surface message to compositor.
        const editor_surface_id: u32 = self.surface_id + 1;
        
        // Why: Create editor widget covering most of window.
        var editor = try SkateEditorWidget.init(
            self.allocator,
            2, // widget ID
            0, // x
            0, // y
            1920, // width
            1080, // height
        );
        
        // Why: Add editor to root widget hierarchy.
        try self.root_widget.addChild(&editor.widget);
        
        self.editor_widget = editor;
    }
    
    /// Why: Handle application events from Grain Shine.
    pub fn handleEvent(self: *Self, event: widget_base.WidgetEvent) !void {
        switch (event.event_type) {
            .key_press => {
                if (self.editor_widget) |*editor| {
                    try editor.handleKeyEvent(event.key_code, event.modifiers);
                }
            },
            .mouse_click => {
                if (self.editor_widget) |*editor| {
                    try editor.handleMouseClick(event.x, event.y);
                }
            },
            else => {},
        }
    }
    
    /// Why: Render complete window to display through Grain Shine protocol.
    pub fn render(self: *Self) !void {
        if (self.editor_widget) |*editor| {
            // Why: Render editor content to Grain Shine surface.
            try editor.render(self.surface_id);
            
            // Why: Request compositor to refresh display.
            // In full implementation, this would send damage/commit messages.
        }
    }
    
    /// Why: Load file into editor.
    pub fn openFile(self: *Self, file_path: []const u8) !void {
        if (self.editor_widget) |*editor| {
            try editor.loadFile(file_path);
        } else {
            return error.EditorNotInitialized;
        }
    }
    
    /// Why: Save current file from editor.
    pub fn saveFile(self: *Self, file_path: []const u8) !void {
        if (self.editor_widget) |*editor| {
            try editor.saveFile(file_path);
        } else {
            return error.EditorNotInitialized;
        }
    }
};

/// Why: Initialize and run complete Skate application.
/// Creates window, sets up editor, and starts main loop.
pub fn runSkateApplication(allocator: std.mem.Allocator, compositor: *CompositorCore) !void {
    std.debug.print("Starting Skate application...\n", .{});
    
    // Why: Create main window.
    var window = try SkateMainWindow.init(allocator, compositor);
    defer window.deinit();
    
    // Why: Initialize editor.
    try window.createEditor();
    std.debug.print("Skate editor initialized\n", .{});
    
    // Why: Example - load a test file if it exists.
    // In real implementation, this would be triggered by user action.
    
    std.debug.print("Skate application ready\n", .{});
    
    // Why: Main event loop would go here.
    // For now, this demonstrates the initialization sequence.
}