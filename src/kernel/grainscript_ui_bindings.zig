//! Grainscript UI Bindings: User-Space API for Toroidal DAG UI
//! Why: Bridge Grainscript applications to Basin kernel UI DAG syscalls.
//! See: docs/rye/0005-toroidal-dag-ui-architecture.md

const std = @import("std");
const dag_adapter = @import("dag_toroidal_adapter.zig");
const UnifiedNodeType = dag_adapter.UnifiedNodeType;
const UnifiedEventType = dag_adapter.UnifiedEventType;
const NodeHandle = dag_adapter.NodeHandle;

// === Constants ===

/// Why: Maximum elements per UI component.
pub const MAX_UI_ELEMENTS: u32 = 256;

/// Why: Maximum text length for UI labels.
pub const MAX_TEXT_LEN: u32 = 128;

/// Why: Maximum children per container.
pub const MAX_CHILDREN: u32 = 16;

// === UI Component Types ===

/// Why: High-level UI component types for Grainscript.
pub const UiComponentType = enum(u8) {
    /// Text label (read-only).
    label,
    /// Text input field.
    input,
    /// Clickable button.
    button,
    /// Container for other elements.
    container,
    /// Scrollable list.
    list,
    /// Canvas for drawing.
    canvas,
    /// Menu bar.
    menu,
    /// Status bar.
    status_bar,
};

/// Why: UI event types for Grainscript callbacks.
pub const UiEventType = enum(u8) {
    /// Button clicked.
    click,
    /// Text changed in input.
    text_change,
    /// Focus gained.
    focus,
    /// Focus lost.
    blur,
    /// Key pressed.
    key_press,
    /// Mouse entered.
    hover_enter,
    /// Mouse left.
    hover_leave,
    /// Scroll event.
    scroll,
};

/// Why: Invalid handle sentinel value.
pub const INVALID_HANDLE_ID: u32 = dag_adapter.MAX_NODES - 1;

/// Why: UI component handle (wraps DAG NodeHandle).
pub const UiHandle = struct {
    dag_handle: NodeHandle,
    component_type: UiComponentType,

    /// Why: Create handle from raw values.
    pub fn from_raw(raw_id: u32, comp_type: UiComponentType) UiHandle {
        return UiHandle{
            .dag_handle = NodeHandle.from_raw(raw_id),
            .component_type = comp_type,
        };
    }

    /// Why: Get raw ID for syscall.
    pub fn raw(self: UiHandle) u32 {
        return self.dag_handle.raw();
    }

    /// Why: Check if handle is valid.
    pub fn is_valid(self: UiHandle) bool {
        return self.dag_handle.raw() != INVALID_HANDLE_ID;
    }

    /// Why: Create invalid handle.
    pub fn invalid() UiHandle {
        return UiHandle{
            .dag_handle = NodeHandle.invalid(),
            .component_type = .label,
        };
    }
};

// === UI Component State ===

/// Why: Text content for labels and inputs.
pub const TextContent = struct {
    data: [MAX_TEXT_LEN]u8,
    len: u32,

    /// Why: Initialize empty text.
    pub fn init() TextContent {
        return TextContent{
            .data = [_]u8{0} ** MAX_TEXT_LEN,
            .len = 0,
        };
    }

    /// Why: Set text from slice.
    pub fn set(self: *TextContent, text: []const u8) void {
        const copy_len = @min(text.len, MAX_TEXT_LEN);
        @memcpy(self.data[0..copy_len], text[0..copy_len]);
        self.len = @intCast(copy_len);
    }

    /// Why: Get text as slice.
    pub fn get(self: *const TextContent) []const u8 {
        return self.data[0..self.len];
    }
};

/// Why: UI component with state.
pub const UiComponent = struct {
    handle: UiHandle,
    text: TextContent,
    children: [MAX_CHILDREN]UiHandle,
    child_count: u32,
    enabled: bool,
    visible: bool,
    focused: bool,

    /// Why: Initialize empty component.
    pub fn init(handle: UiHandle) UiComponent {
        var comp = UiComponent{
            .handle = handle,
            .text = TextContent.init(),
            .children = undefined,
            .child_count = 0,
            .enabled = true,
            .visible = true,
            .focused = false,
        };
        for (&comp.children) |*child| {
            child.* = UiHandle.invalid();
        }
        return comp;
    }

    /// Why: Add child component.
    pub fn add_child(self: *UiComponent, child: UiHandle) bool {
        if (self.child_count >= MAX_CHILDREN) return false;
        self.children[self.child_count] = child;
        self.child_count += 1;
        return true;
    }

    /// Why: Set text content.
    pub fn set_text(self: *UiComponent, text: []const u8) void {
        self.text.set(text);
    }

    /// Why: Get text content.
    pub fn get_text(self: *const UiComponent) []const u8 {
        return self.text.get();
    }
};

// === UI Builder API ===

/// Why: Grainscript UI builder for creating component hierarchies.
pub const UiBuilder = struct {
    components: [MAX_UI_ELEMENTS]UiComponent,
    count: u32,
    root: UiHandle,

    /// Why: Initialize empty builder.
    pub fn init() UiBuilder {
        var builder = UiBuilder{
            .components = undefined,
            .count = 0,
            .root = UiHandle.invalid(),
        };
        for (&builder.components) |*comp| {
            comp.* = UiComponent.init(UiHandle.invalid());
        }
        return builder;
    }

    /// Why: Create root container.
    pub fn create_root(self: *UiBuilder) ?UiHandle {
        if (self.count >= MAX_UI_ELEMENTS) return null;
        const handle = UiHandle.from_raw(self.count, .container);
        self.components[self.count] = UiComponent.init(handle);
        self.count += 1;
        self.root = handle;
        return handle;
    }

    /// Why: Create label component.
    pub fn create_label(self: *UiBuilder, parent: UiHandle, text: []const u8) ?UiHandle {
        return self.create_component_with_text(parent, .label, text);
    }

    /// Why: Create button component.
    pub fn create_button(self: *UiBuilder, parent: UiHandle, text: []const u8) ?UiHandle {
        return self.create_component_with_text(parent, .button, text);
    }

    /// Why: Create input field.
    pub fn create_input(self: *UiBuilder, parent: UiHandle, placeholder: []const u8) ?UiHandle {
        return self.create_component_with_text(parent, .input, placeholder);
    }

    /// Why: Create container.
    pub fn create_container(self: *UiBuilder, parent: UiHandle) ?UiHandle {
        return self.create_component(parent, .container);
    }

    /// Why: Create list component.
    pub fn create_list(self: *UiBuilder, parent: UiHandle) ?UiHandle {
        return self.create_component(parent, .list);
    }

    /// Why: Internal - create component with text.
    fn create_component_with_text(
        self: *UiBuilder,
        parent: UiHandle,
        comp_type: UiComponentType,
        text: []const u8,
    ) ?UiHandle {
        const handle = self.create_component(parent, comp_type) orelse return null;
        const idx = handle.raw();
        if (idx < MAX_UI_ELEMENTS) {
            self.components[idx].set_text(text);
        }
        return handle;
    }

    /// Why: Internal - create component without text.
    fn create_component(self: *UiBuilder, parent: UiHandle, comp_type: UiComponentType) ?UiHandle {
        if (self.count >= MAX_UI_ELEMENTS) return null;
        const handle = UiHandle.from_raw(self.count, comp_type);
        self.components[self.count] = UiComponent.init(handle);
        self.count += 1;

        // Add to parent if valid.
        if (parent.is_valid()) {
            const parent_idx = parent.raw();
            if (parent_idx < MAX_UI_ELEMENTS) {
                _ = self.components[parent_idx].add_child(handle);
            }
        }
        return handle;
    }

    /// Why: Get component by handle.
    pub fn get_component(self: *UiBuilder, handle: UiHandle) ?*UiComponent {
        if (!handle.is_valid()) return null;
        const idx = handle.raw();
        if (idx >= MAX_UI_ELEMENTS) return null;
        if (idx >= self.count) return null;
        return &self.components[idx];
    }

    /// Why: Set component text.
    pub fn set_text(self: *UiBuilder, handle: UiHandle, text: []const u8) bool {
        const comp = self.get_component(handle) orelse return false;
        comp.set_text(text);
        return true;
    }

    /// Why: Get component text.
    pub fn get_text(self: *UiBuilder, handle: UiHandle) ?[]const u8 {
        const comp = self.get_component(handle) orelse return null;
        return comp.get_text();
    }

    /// Why: Enable/disable component.
    pub fn set_enabled(self: *UiBuilder, handle: UiHandle, enabled: bool) bool {
        const comp = self.get_component(handle) orelse return false;
        comp.enabled = enabled;
        return true;
    }

    /// Why: Show/hide component.
    pub fn set_visible(self: *UiBuilder, handle: UiHandle, visible: bool) bool {
        const comp = self.get_component(handle) orelse return false;
        comp.visible = visible;
        return true;
    }

    /// Why: Get component count.
    pub fn component_count(self: *const UiBuilder) u32 {
        return self.count;
    }
};

// === Event Handling ===

/// Why: UI event from kernel.
pub const UiEvent = struct {
    target: UiHandle,
    event_type: UiEventType,
    data: u32,

    /// Why: Create event.
    pub fn init(target: UiHandle, event_type: UiEventType, data: u32) UiEvent {
        return UiEvent{
            .target = target,
            .event_type = event_type,
            .data = data,
        };
    }
};

/// Why: Event callback signature.
pub const EventCallback = *const fn (event: UiEvent, user_data: ?*anyopaque) void;

/// Why: Event handler registration.
pub const EventHandler = struct {
    target: UiHandle,
    event_type: UiEventType,
    callback: EventCallback,
    user_data: ?*anyopaque,
};

/// Why: Maximum event handlers.
pub const MAX_HANDLERS: u32 = 64;

/// Why: Event dispatcher for Grainscript.
pub const EventDispatcher = struct {
    handlers: [MAX_HANDLERS]EventHandler,
    handler_count: u32,

    /// Why: Initialize empty dispatcher.
    pub fn init() EventDispatcher {
        var dispatcher = EventDispatcher{
            .handlers = undefined,
            .handler_count = 0,
        };
        for (&dispatcher.handlers) |*h| {
            h.* = EventHandler{
                .target = UiHandle.invalid(),
                .event_type = .click,
                .callback = undefined,
                .user_data = null,
            };
        }
        return dispatcher;
    }

    /// Why: Register event handler.
    pub fn on(
        self: *EventDispatcher,
        target: UiHandle,
        event_type: UiEventType,
        callback: EventCallback,
        user_data: ?*anyopaque,
    ) bool {
        if (self.handler_count >= MAX_HANDLERS) return false;
        self.handlers[self.handler_count] = EventHandler{
            .target = target,
            .event_type = event_type,
            .callback = callback,
            .user_data = user_data,
        };
        self.handler_count += 1;
        return true;
    }

    /// Why: Dispatch event to registered handlers.
    pub fn dispatch(self: *EventDispatcher, event: UiEvent) u32 {
        var dispatched: u32 = 0;
        for (self.handlers[0..self.handler_count]) |handler| {
            const target_match = handler.target.raw() == event.target.raw();
            const type_match = handler.event_type == event.event_type;
            if (target_match and type_match) {
                handler.callback(event, handler.user_data);
                dispatched += 1;
            }
        }
        return dispatched;
    }

    /// Why: Get handler count.
    pub fn count(self: *const EventDispatcher) u32 {
        return self.handler_count;
    }
};

// === Grainscript UI Application ===

/// Why: Complete UI application state for Grainscript.
pub const UiApp = struct {
    builder: UiBuilder,
    dispatcher: EventDispatcher,
    running: bool,

    /// Why: Initialize application.
    pub fn init() UiApp {
        return UiApp{
            .builder = UiBuilder.init(),
            .dispatcher = EventDispatcher.init(),
            .running = false,
        };
    }

    /// Why: Create root window.
    pub fn create_window(self: *UiApp) ?UiHandle {
        return self.builder.create_root();
    }

    /// Why: Add label to parent.
    pub fn add_label(self: *UiApp, parent: UiHandle, text: []const u8) ?UiHandle {
        return self.builder.create_label(parent, text);
    }

    /// Why: Add button to parent.
    pub fn add_button(self: *UiApp, parent: UiHandle, text: []const u8) ?UiHandle {
        return self.builder.create_button(parent, text);
    }

    /// Why: Add input to parent.
    pub fn add_input(self: *UiApp, parent: UiHandle, placeholder: []const u8) ?UiHandle {
        return self.builder.create_input(parent, placeholder);
    }

    /// Why: Register click handler.
    pub fn on_click(
        self: *UiApp,
        target: UiHandle,
        callback: EventCallback,
        user_data: ?*anyopaque,
    ) bool {
        return self.dispatcher.on(target, .click, callback, user_data);
    }

    /// Why: Register text change handler.
    pub fn on_text_change(
        self: *UiApp,
        target: UiHandle,
        callback: EventCallback,
        user_data: ?*anyopaque,
    ) bool {
        return self.dispatcher.on(target, .text_change, callback, user_data);
    }

    /// Why: Process incoming event.
    pub fn process_event(self: *UiApp, event: UiEvent) u32 {
        return self.dispatcher.dispatch(event);
    }

    /// Why: Start application (would call kernel event loop).
    pub fn run(self: *UiApp) void {
        self.running = true;
        // In real implementation, this would:
        // 1. Call UI DAG syscall to register UI
        // 2. Enter kernel event loop
        // 3. Dispatch events to handlers
    }

    /// Why: Stop application.
    pub fn stop(self: *UiApp) void {
        self.running = false;
    }

    /// Why: Check if running.
    pub fn is_running(self: *const UiApp) bool {
        return self.running;
    }

    /// Why: Get component count.
    pub fn component_count(self: *const UiApp) u32 {
        return self.builder.component_count();
    }
};
