//! Grain GUI Toolkit: Base Widget Foundation
//!
//! Why: Core widget system for Grain Shine applications with memory safety.
//! Provides foundation for Skate GUI and all future Grain applications.
//!
//! Agents: Core 1 (Implementation) + Glow (Design)

const std = @import("std");

/// Why: Base widget with memory-safe hierarchy and bounds checking.
pub const Widget = struct {
    const Self = @This();
    
    id: u32,
    x: i32,
    y: i32,
    width: u32,
    height: u32,
    visible: bool,
    enabled: bool,
    widget_type: WidgetType,
    parent: ?*Widget,
    children: std.ArrayList(*Widget),
    allocator: std.mem.Allocator,
    
    /// Why: Maximum children per widget to prevent unbounded growth.
    pub const MAX_CHILDREN: u32 = 256;
    
    /// Why: Maximum widget dimensions for safety.
    pub const MAX_DIMENSION: u32 = 8192;
    
    /// Why: Initialize widget with dimension validation.
    pub fn init(
        allocator: std.mem.Allocator,
        id: u32,
        x: i32,
        y: i32,
        width: u32,
        height: u32,
        widget_type: WidgetType,
    ) !Self {
        if (width == 0 or height == 0) return error.InvalidDimensions;
        if (width > MAX_DIMENSION or height > MAX_DIMENSION) return error.DimensionsTooLarge;
        
        return Self{
            .id = id,
            .x = x,
            .y = y,
            .width = width,
            .height = height,
            .visible = true,
            .enabled = true,
            .widget_type = widget_type,
            .parent = null,
            .children = std.ArrayList(*Widget).init(allocator),
            .allocator = allocator,
        };
    }
    
    /// Why: Cleanup widget and all children recursively.
    pub fn deinit(self: *Self) void {
        for (self.children.items) |child| {
            child.deinit();
        }
        self.children.deinit();
    }
    
    /// Why: Add child widget with bounds checking.
    pub fn addChild(self: *Self, child: *Widget) !void {
        if (self.children.items.len >= MAX_CHILDREN) {
            return error.TooManyChildren;
        }
        
        child.parent = self;
        try self.children.append(child);
    }
    
    /// Why: Check if point is within widget bounds.
    pub fn containsPoint(self: *const Self, px: i32, py: i32) bool {
        return px >= self.x and 
               px < self.x + @as(i32, @intCast(self.width)) and
               py >= self.y and 
               py < self.y + @as(i32, @intCast(self.height));
    }
    
    /// Why: Move widget to new position.
    pub fn moveTo(self: *Self, new_x: i32, new_y: i32) void {
        self.x = new_x;
        self.y = new_y;
    }
    
    /// Why: Resize widget with bounds checking.
    pub fn resize(self: *Self, new_width: u32, new_height: u32) !void {
        if (new_width == 0 or new_height == 0) return error.InvalidDimensions;
        if (new_width > MAX_DIMENSION or new_height > MAX_DIMENSION) {
            return error.DimensionsTooLarge;
        }
        
        self.width = new_width;
        self.height = new_height;
    }
};

/// Why: Widget types for rendering dispatch and event handling.
pub const WidgetType = enum {
    container,
    button,
    label,
    text_input,
    text_area,
    scroll_view,
    menu,
    dialog,
    editor_panel,  // For Skate editor
    file_tree,      // For Skate file browser
};

/// Why: Event types for widget interaction.
pub const EventType = enum {
    mouse_click,
    mouse_move,
    mouse_enter,
    mouse_leave,
    key_press,
    key_release,
    focus_gained,
    focus_lost,
    resize,
    paint,
};

/// Why: Widget event structure with bounds checking.
pub const WidgetEvent = struct {
    event_type: EventType,
    widget_id: u32,
    x: i32,
    y: i32,
    key_code: u32,
    modifiers: u32,
    
    /// Why: Create mouse click event.
    pub fn mouseClick(widget_id: u32, x: i32, y: i32) WidgetEvent {
        return WidgetEvent{
            .event_type = .mouse_click,
            .widget_id = widget_id,
            .x = x,
            .y = y,
            .key_code = 0,
            .modifiers = 0,
        };
    }
    
    /// Why: Create key press event.
    pub fn keyPress(widget_id: u32, key_code: u32, modifiers: u32) WidgetEvent {
        return WidgetEvent{
            .event_type = .key_press,
            .widget_id = widget_id,
            .x = 0,
            .y = 0,
            .key_code = key_code,
            .modifiers = modifiers,
        };
    }
};