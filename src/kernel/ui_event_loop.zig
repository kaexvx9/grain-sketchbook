//! UI Event Loop: Basin Kernel Event Integration
//! Why: Connect Grainscript UI applications to kernel event processing.
//! See: docs/rye/0005-toroidal-dag-ui-architecture.md

const std = @import("std");
const dag_adapter = @import("dag_toroidal_adapter.zig");
const ui_bindings = @import("grainscript_ui_bindings.zig");
const ToroidalBuffer = dag_adapter.toroidal_types.ToroidalBuffer;

const UiHandle = ui_bindings.UiHandle;
const UiEvent = ui_bindings.UiEvent;
const UiEventType = ui_bindings.UiEventType;
const UiApp = ui_bindings.UiApp;

// === Constants ===

/// Why: Maximum pending input events.
pub const MAX_INPUT_EVENTS: u32 = 256;

/// Why: Maximum pending render commands.
pub const MAX_RENDER_COMMANDS: u32 = 128;

/// Why: Maximum registered applications.
pub const MAX_APPS: u32 = 16;

/// Why: Event loop tick rate (60 Hz).
pub const TICK_RATE_HZ: u32 = 60;

/// Why: Nanoseconds per tick.
pub const NS_PER_TICK: u64 = 1_000_000_000 / TICK_RATE_HZ;

// === Input Events ===

/// Why: Raw input event from kernel.
pub const InputEventType = enum(u8) {
    /// Keyboard key pressed.
    key_down,
    /// Keyboard key released.
    key_up,
    /// Mouse button pressed.
    mouse_down,
    /// Mouse button released.
    mouse_up,
    /// Mouse moved.
    mouse_move,
    /// Mouse wheel scrolled.
    mouse_scroll,
    /// Touch start.
    touch_start,
    /// Touch move.
    touch_move,
    /// Touch end.
    touch_end,
    /// Window focus gained.
    focus_in,
    /// Window focus lost.
    focus_out,
    /// Window resize.
    resize,
};

/// Why: Raw input event data.
pub const InputEvent = struct {
    event_type: InputEventType,
    /// Target app handle (0 = broadcast).
    target_app: u32,
    /// Key code or button.
    code: u16,
    /// Modifier keys (shift, ctrl, alt, meta).
    modifiers: u8,
    /// X coordinate (mouse/touch).
    x: i16,
    /// Y coordinate (mouse/touch).
    y: i16,
    /// Delta (scroll or pressure).
    delta: i16,
    /// Timestamp in nanoseconds.
    timestamp: u64,

    /// Why: Create key event.
    pub fn key(event_type: InputEventType, code: u16, mods: u8, ts: u64) InputEvent {
        return InputEvent{
            .event_type = event_type,
            .target_app = 0,
            .code = code,
            .modifiers = mods,
            .x = 0,
            .y = 0,
            .delta = 0,
            .timestamp = ts,
        };
    }

    /// Why: Create mouse event.
    pub fn mouse(event_type: InputEventType, x: i16, y: i16, btn: u16, ts: u64) InputEvent {
        return InputEvent{
            .event_type = event_type,
            .target_app = 0,
            .code = btn,
            .modifiers = 0,
            .x = x,
            .y = y,
            .delta = 0,
            .timestamp = ts,
        };
    }
};

// === Render Commands ===

/// Why: Render command type.
pub const RenderCommandType = enum(u8) {
    /// Clear screen.
    clear,
    /// Draw rectangle.
    draw_rect,
    /// Draw text.
    draw_text,
    /// Draw line.
    draw_line,
    /// Set clip region.
    set_clip,
    /// Reset clip.
    reset_clip,
    /// Commit frame.
    commit,
};

/// Why: Render command data.
pub const RenderCommand = struct {
    command_type: RenderCommandType,
    /// Target component.
    target: UiHandle,
    /// Position X.
    x: i16,
    /// Position Y.
    y: i16,
    /// Width.
    width: u16,
    /// Height.
    height: u16,
    /// Color (RGBA packed).
    color: u32,
    /// Text data offset (for draw_text).
    text_offset: u16,
    /// Text length.
    text_len: u16,

    /// Why: Create clear command.
    pub fn clear(color: u32) RenderCommand {
        return RenderCommand{
            .command_type = .clear,
            .target = UiHandle.invalid(),
            .x = 0,
            .y = 0,
            .width = 0,
            .height = 0,
            .color = color,
            .text_offset = 0,
            .text_len = 0,
        };
    }

    /// Why: Create draw_rect command.
    pub fn draw_rect(x: i16, y: i16, w: u16, h: u16, color: u32) RenderCommand {
        return RenderCommand{
            .command_type = .draw_rect,
            .target = UiHandle.invalid(),
            .x = x,
            .y = y,
            .width = w,
            .height = h,
            .color = color,
            .text_offset = 0,
            .text_len = 0,
        };
    }

    /// Why: Create commit command.
    pub fn commit() RenderCommand {
        return RenderCommand{
            .command_type = .commit,
            .target = UiHandle.invalid(),
            .x = 0,
            .y = 0,
            .width = 0,
            .height = 0,
            .color = 0,
            .text_offset = 0,
            .text_len = 0,
        };
    }
};

// === Application Slot ===

/// Why: Registered application slot.
pub const AppSlot = struct {
    app: ?*UiApp,
    process_id: u32,
    focused: bool,
    visible: bool,
    z_order: u8,

    /// Why: Initialize empty slot.
    pub fn init() AppSlot {
        return AppSlot{
            .app = null,
            .process_id = 0,
            .focused = false,
            .visible = false,
            .z_order = 0,
        };
    }

    /// Why: Check if slot is used.
    pub fn is_active(self: *const AppSlot) bool {
        return self.app != null;
    }
};

// === Event Loop ===

/// Why: Kernel UI event loop.
pub const EventLoop = struct {
    /// Pending input events (toroidal buffer).
    input_queue: ToroidalBuffer(InputEvent, MAX_INPUT_EVENTS),
    /// Pending render commands (toroidal buffer).
    render_queue: ToroidalBuffer(RenderCommand, MAX_RENDER_COMMANDS),
    /// Registered applications.
    apps: [MAX_APPS]AppSlot,
    /// Number of registered apps.
    app_count: u32,
    /// Currently focused app index.
    focused_app: u32,
    /// Running state.
    running: bool,
    /// Current tick count.
    tick_count: u64,
    /// Last tick timestamp (ns).
    last_tick_ns: u64,

    /// Why: Initialize event loop.
    pub fn init() EventLoop {
        var loop = EventLoop{
            .input_queue = ToroidalBuffer(InputEvent, MAX_INPUT_EVENTS).init(),
            .render_queue = ToroidalBuffer(RenderCommand, MAX_RENDER_COMMANDS).init(),
            .apps = undefined,
            .app_count = 0,
            .focused_app = 0,
            .running = false,
            .tick_count = 0,
            .last_tick_ns = 0,
        };
        for (&loop.apps) |*slot| {
            slot.* = AppSlot.init();
        }
        return loop;
    }

    /// Why: Register application with event loop.
    pub fn register_app(self: *EventLoop, app: *UiApp, pid: u32) ?u32 {
        if (self.app_count >= MAX_APPS) return null;

        // Find free slot.
        for (&self.apps, 0..) |*slot, i| {
            if (!slot.is_active()) {
                slot.app = app;
                slot.process_id = pid;
                slot.visible = true;
                slot.z_order = @intCast(self.app_count);
                self.app_count += 1;

                // First app gets focus.
                if (self.app_count == 1) {
                    slot.focused = true;
                    self.focused_app = @intCast(i);
                }
                return @intCast(i);
            }
        }
        return null;
    }

    /// Why: Unregister application.
    pub fn unregister_app(self: *EventLoop, handle: u32) bool {
        if (handle >= MAX_APPS) return false;
        if (!self.apps[handle].is_active()) return false;

        self.apps[handle] = AppSlot.init();
        if (self.app_count > 0) {
            self.app_count -= 1;
        }

        // Move focus if needed.
        if (self.focused_app == handle) {
            self.focus_next_app();
        }
        return true;
    }

    /// Why: Focus next available app.
    fn focus_next_app(self: *EventLoop) void {
        for (&self.apps, 0..) |*slot, i| {
            if (slot.is_active() and slot.visible) {
                slot.focused = true;
                self.focused_app = @intCast(i);
                return;
            }
        }
        self.focused_app = 0;
    }

    /// Why: Push input event to queue.
    pub fn push_input(self: *EventLoop, event: InputEvent) void {
        self.input_queue.push(event);
    }

    /// Why: Push render command to queue.
    pub fn push_render(self: *EventLoop, cmd: RenderCommand) void {
        self.render_queue.push(cmd);
    }

    /// Why: Process one tick of the event loop.
    pub fn tick(self: *EventLoop, current_ns: u64) u32 {
        var processed: u32 = 0;

        // Process input events.
        while (self.input_queue.len() > 0) {
            if (self.input_queue.pop()) |input| {
                processed += self.dispatch_input(input);
            }
        }

        // Update tick state.
        self.tick_count += 1;
        self.last_tick_ns = current_ns;

        return processed;
    }

    /// Why: Dispatch input event to appropriate app.
    fn dispatch_input(self: *EventLoop, input: InputEvent) u32 {
        // Targeted event.
        if (input.target_app > 0 and input.target_app <= MAX_APPS) {
            const slot = &self.apps[input.target_app - 1];
            if (slot.is_active()) {
                return self.deliver_to_app(slot, input);
            }
        }

        // Broadcast to focused app.
        if (self.focused_app < MAX_APPS) {
            const slot = &self.apps[self.focused_app];
            if (slot.is_active()) {
                return self.deliver_to_app(slot, input);
            }
        }

        return 0;
    }

    /// Why: Deliver input event to specific app.
    fn deliver_to_app(self: *EventLoop, slot: *AppSlot, input: InputEvent) u32 {
        _ = self;
        const app = slot.app orelse return 0;

        // Convert input to UI event.
        const ui_event = input_to_ui_event(input);
        return app.process_event(ui_event);
    }

    /// Why: Get pending render commands.
    pub fn pop_render(self: *EventLoop) ?RenderCommand {
        return self.render_queue.pop();
    }

    /// Why: Get registered app count.
    pub fn count(self: *const EventLoop) u32 {
        return self.app_count;
    }

    /// Why: Get input queue length.
    pub fn input_pending(self: *const EventLoop) u32 {
        return self.input_queue.len();
    }

    /// Why: Get render queue length.
    pub fn render_pending(self: *const EventLoop) u32 {
        return self.render_queue.len();
    }

    /// Why: Start event loop.
    pub fn start(self: *EventLoop) void {
        self.running = true;
    }

    /// Why: Stop event loop.
    pub fn stop(self: *EventLoop) void {
        self.running = false;
    }

    /// Why: Check if running.
    pub fn is_running(self: *const EventLoop) bool {
        return self.running;
    }
};

// === Conversion Functions ===

/// Why: Convert kernel input event to UI event.
pub fn input_to_ui_event(input: InputEvent) UiEvent {
    const event_type: UiEventType = switch (input.event_type) {
        .key_down, .key_up => .key_press,
        .mouse_down => .click,
        .mouse_up => .click,
        .mouse_move => .hover_enter,
        .mouse_scroll => .scroll,
        .focus_in => .focus,
        .focus_out => .blur,
        else => .click,
    };

    return UiEvent.init(
        UiHandle.invalid(), // Will be set by hit testing.
        event_type,
        input.code,
    );
}

// === Global Event Loop ===

/// Why: Single global event loop instance for kernel.
var global_event_loop: EventLoop = EventLoop.init();

/// Why: Get global event loop.
pub fn get_event_loop() *EventLoop {
    return &global_event_loop;
}

/// Why: Initialize global event loop (called at kernel boot).
pub fn init_event_loop() void {
    global_event_loop = EventLoop.init();
}
