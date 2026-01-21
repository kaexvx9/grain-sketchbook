//! UI Event Loop Test
//! Why: Verify kernel event loop integration for UI applications.

const std = @import("std");
const testing = std.testing;
const event_loop = @import("ui_event_loop");
const ui_bindings = @import("grainscript_ui_bindings");

const EventLoop = event_loop.EventLoop;
const InputEvent = event_loop.InputEvent;
const InputEventType = event_loop.InputEventType;
const RenderCommand = event_loop.RenderCommand;
const AppSlot = event_loop.AppSlot;
const UiApp = ui_bindings.UiApp;

// === Constants Tests ===

test "event loop constants" {
    try testing.expectEqual(@as(u32, 256), event_loop.MAX_INPUT_EVENTS);
    try testing.expectEqual(@as(u32, 128), event_loop.MAX_RENDER_COMMANDS);
    try testing.expectEqual(@as(u32, 16), event_loop.MAX_APPS);
    try testing.expectEqual(@as(u32, 60), event_loop.TICK_RATE_HZ);
}

// === InputEvent Tests ===

test "input event key creation" {
    const key_event = InputEvent.key(.key_down, 65, 0, 1000);
    try testing.expectEqual(InputEventType.key_down, key_event.event_type);
    try testing.expectEqual(@as(u16, 65), key_event.code);
    try testing.expectEqual(@as(u64, 1000), key_event.timestamp);
}

test "input event mouse creation" {
    const mouse_event = InputEvent.mouse(.mouse_down, 100, 200, 1, 2000);
    try testing.expectEqual(InputEventType.mouse_down, mouse_event.event_type);
    try testing.expectEqual(@as(i16, 100), mouse_event.x);
    try testing.expectEqual(@as(i16, 200), mouse_event.y);
    try testing.expectEqual(@as(u16, 1), mouse_event.code);
}

// === RenderCommand Tests ===

test "render command clear" {
    const cmd = RenderCommand.clear(0xFF0000FF);
    try testing.expectEqual(event_loop.RenderCommandType.clear, cmd.command_type);
    try testing.expectEqual(@as(u32, 0xFF0000FF), cmd.color);
}

test "render command draw_rect" {
    const cmd = RenderCommand.draw_rect(10, 20, 100, 50, 0x00FF00FF);
    try testing.expectEqual(event_loop.RenderCommandType.draw_rect, cmd.command_type);
    try testing.expectEqual(@as(i16, 10), cmd.x);
    try testing.expectEqual(@as(i16, 20), cmd.y);
    try testing.expectEqual(@as(u16, 100), cmd.width);
    try testing.expectEqual(@as(u16, 50), cmd.height);
}

test "render command commit" {
    const cmd = RenderCommand.commit();
    try testing.expectEqual(event_loop.RenderCommandType.commit, cmd.command_type);
}

// === AppSlot Tests ===

test "app slot initialization" {
    const slot = AppSlot.init();
    try testing.expect(!slot.is_active());
    try testing.expect(!slot.focused);
    try testing.expect(!slot.visible);
}

// === EventLoop Tests ===

test "event loop initialization" {
    var loop = EventLoop.init();
    try testing.expect(!loop.is_running());
    try testing.expectEqual(@as(u32, 0), loop.count());
    try testing.expectEqual(@as(u32, 0), loop.input_pending());
    try testing.expectEqual(@as(u32, 0), loop.render_pending());
}

test "event loop start and stop" {
    var loop = EventLoop.init();

    loop.start();
    try testing.expect(loop.is_running());

    loop.stop();
    try testing.expect(!loop.is_running());
}

test "event loop push input" {
    var loop = EventLoop.init();

    const event1 = InputEvent.key(.key_down, 65, 0, 1000);
    const event2 = InputEvent.key(.key_up, 65, 0, 1100);

    loop.push_input(event1);
    loop.push_input(event2);

    try testing.expectEqual(@as(u32, 2), loop.input_pending());
}

test "event loop push render" {
    var loop = EventLoop.init();

    loop.push_render(RenderCommand.clear(0));
    loop.push_render(RenderCommand.draw_rect(0, 0, 100, 100, 0xFFFFFFFF));
    loop.push_render(RenderCommand.commit());

    try testing.expectEqual(@as(u32, 3), loop.render_pending());
}

test "event loop pop render" {
    var loop = EventLoop.init();

    loop.push_render(RenderCommand.clear(0xFF0000FF));

    const cmd = loop.pop_render();
    try testing.expect(cmd != null);
    try testing.expectEqual(event_loop.RenderCommandType.clear, cmd.?.command_type);
    try testing.expectEqual(@as(u32, 0), loop.render_pending());
}

test "event loop register app" {
    var loop = EventLoop.init();
    var app = UiApp.init();

    const handle = loop.register_app(&app, 100);
    try testing.expect(handle != null);
    try testing.expectEqual(@as(u32, 1), loop.count());
}

test "event loop register multiple apps" {
    var loop = EventLoop.init();
    var app1 = UiApp.init();
    var app2 = UiApp.init();
    var app3 = UiApp.init();

    const h1 = loop.register_app(&app1, 100);
    const h2 = loop.register_app(&app2, 101);
    const h3 = loop.register_app(&app3, 102);

    try testing.expect(h1 != null);
    try testing.expect(h2 != null);
    try testing.expect(h3 != null);
    try testing.expectEqual(@as(u32, 3), loop.count());
}

test "event loop unregister app" {
    var loop = EventLoop.init();
    var app = UiApp.init();

    const handle = loop.register_app(&app, 100).?;
    try testing.expectEqual(@as(u32, 1), loop.count());

    try testing.expect(loop.unregister_app(handle));
    try testing.expectEqual(@as(u32, 0), loop.count());
}

test "event loop tick" {
    var loop = EventLoop.init();
    loop.start();

    // Push some events.
    loop.push_input(InputEvent.key(.key_down, 65, 0, 1000));
    loop.push_input(InputEvent.key(.key_up, 65, 0, 1100));

    // Tick processes events.
    const processed = loop.tick(2000);

    // Events were processed (but no app registered, so 0 delivered).
    try testing.expectEqual(@as(u32, 0), processed);
    try testing.expectEqual(@as(u32, 0), loop.input_pending());
    try testing.expectEqual(@as(u64, 1), loop.tick_count);
}

test "event loop first app gets focus" {
    var loop = EventLoop.init();
    var app = UiApp.init();

    const handle = loop.register_app(&app, 100).?;

    // First app should be focused.
    try testing.expect(loop.apps[handle].focused);
    try testing.expectEqual(handle, loop.focused_app);
}

// === Input Conversion Tests ===

test "input to ui event conversion" {
    const key_input = InputEvent.key(.key_down, 65, 0, 1000);
    const ui_event = event_loop.input_to_ui_event(key_input);
    try testing.expectEqual(ui_bindings.UiEventType.key_press, ui_event.event_type);
}

test "mouse input to ui event conversion" {
    const mouse_input = InputEvent.mouse(.mouse_down, 100, 200, 1, 1000);
    const ui_event = event_loop.input_to_ui_event(mouse_input);
    try testing.expectEqual(ui_bindings.UiEventType.click, ui_event.event_type);
}

// === Global Event Loop Tests ===

test "global event loop" {
    event_loop.init_event_loop();
    const loop = event_loop.get_event_loop();
    try testing.expect(!loop.is_running());
    try testing.expectEqual(@as(u32, 0), loop.count());
}
