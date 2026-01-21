//! Grainscript UI Bindings Test
//! Why: Verify user-space UI API for Grainscript applications.

const std = @import("std");
const testing = std.testing;
const ui = @import("grainscript_ui_bindings");

const UiHandle = ui.UiHandle;
const UiComponentType = ui.UiComponentType;
const UiEventType = ui.UiEventType;
const UiEvent = ui.UiEvent;
const TextContent = ui.TextContent;
const UiComponent = ui.UiComponent;
const UiBuilder = ui.UiBuilder;
const EventDispatcher = ui.EventDispatcher;
const UiApp = ui.UiApp;

// === Handle Tests ===

test "ui handle creation and validation" {
    const handle = UiHandle.from_raw(42, .button);
    try testing.expect(handle.is_valid());
    try testing.expectEqual(@as(u32, 42), handle.raw());
    try testing.expectEqual(UiComponentType.button, handle.component_type);
}

test "invalid handle" {
    const invalid = UiHandle.invalid();
    try testing.expect(!invalid.is_valid());
}

// === TextContent Tests ===

test "text content set and get" {
    var text = TextContent.init();
    try testing.expectEqual(@as(u32, 0), text.len);

    text.set("Hello, Grainscript!");
    try testing.expectEqualStrings("Hello, Grainscript!", text.get());
}

test "text content truncation" {
    var text = TextContent.init();

    // Create string longer than MAX_TEXT_LEN
    var long_text: [200]u8 = undefined;
    for (&long_text) |*c| {
        c.* = 'x';
    }

    text.set(&long_text);
    try testing.expectEqual(ui.MAX_TEXT_LEN, text.len);
}

// === UiComponent Tests ===

test "ui component initialization" {
    const handle = UiHandle.from_raw(0, .label);
    const comp = UiComponent.init(handle);

    try testing.expect(comp.enabled);
    try testing.expect(comp.visible);
    try testing.expect(!comp.focused);
    try testing.expectEqual(@as(u32, 0), comp.child_count);
}

test "ui component add children" {
    const parent_handle = UiHandle.from_raw(0, .container);
    var parent = UiComponent.init(parent_handle);

    const child1 = UiHandle.from_raw(1, .label);
    const child2 = UiHandle.from_raw(2, .button);

    try testing.expect(parent.add_child(child1));
    try testing.expect(parent.add_child(child2));
    try testing.expectEqual(@as(u32, 2), parent.child_count);
}

test "ui component text" {
    const handle = UiHandle.from_raw(0, .label);
    var comp = UiComponent.init(handle);

    comp.set_text("Test Label");
    try testing.expectEqualStrings("Test Label", comp.get_text());
}

// === UiBuilder Tests ===

test "ui builder create root" {
    var builder = UiBuilder.init();
    const root = builder.create_root();

    try testing.expect(root != null);
    try testing.expect(root.?.is_valid());
    try testing.expectEqual(@as(u32, 1), builder.component_count());
}

test "ui builder create label" {
    var builder = UiBuilder.init();
    const root = builder.create_root().?;
    const label = builder.create_label(root, "Hello");

    try testing.expect(label != null);
    try testing.expectEqual(@as(u32, 2), builder.component_count());

    const text = builder.get_text(label.?);
    try testing.expect(text != null);
    try testing.expectEqualStrings("Hello", text.?);
}

test "ui builder create button" {
    var builder = UiBuilder.init();
    const root = builder.create_root().?;
    const button = builder.create_button(root, "Click Me");

    try testing.expect(button != null);
    try testing.expectEqual(UiComponentType.button, button.?.component_type);
}

test "ui builder create input" {
    var builder = UiBuilder.init();
    const root = builder.create_root().?;
    const input = builder.create_input(root, "Enter text...");

    try testing.expect(input != null);
    try testing.expectEqual(UiComponentType.input, input.?.component_type);
}

test "ui builder set and get text" {
    var builder = UiBuilder.init();
    const root = builder.create_root().?;
    const label = builder.create_label(root, "Initial").?;

    try testing.expect(builder.set_text(label, "Updated"));
    try testing.expectEqualStrings("Updated", builder.get_text(label).?);
}

test "ui builder enable/disable" {
    var builder = UiBuilder.init();
    const root = builder.create_root().?;
    const button = builder.create_button(root, "Button").?;

    try testing.expect(builder.set_enabled(button, false));
    const comp = builder.get_component(button).?;
    try testing.expect(!comp.enabled);
}

test "ui builder show/hide" {
    var builder = UiBuilder.init();
    const root = builder.create_root().?;
    const label = builder.create_label(root, "Label").?;

    try testing.expect(builder.set_visible(label, false));
    const comp = builder.get_component(label).?;
    try testing.expect(!comp.visible);
}

// === EventDispatcher Tests ===

var test_callback_count: u32 = 0;

fn test_callback(_: UiEvent, _: ?*anyopaque) void {
    test_callback_count += 1;
}

test "event dispatcher register handler" {
    var dispatcher = EventDispatcher.init();
    const target = UiHandle.from_raw(1, .button);

    try testing.expect(dispatcher.on(target, .click, test_callback, null));
    try testing.expectEqual(@as(u32, 1), dispatcher.count());
}

test "event dispatcher dispatch" {
    test_callback_count = 0;
    var dispatcher = EventDispatcher.init();
    const target = UiHandle.from_raw(1, .button);

    _ = dispatcher.on(target, .click, test_callback, null);

    const event = UiEvent.init(target, .click, 0);
    const dispatched = dispatcher.dispatch(event);

    try testing.expectEqual(@as(u32, 1), dispatched);
    try testing.expectEqual(@as(u32, 1), test_callback_count);
}

test "event dispatcher no match" {
    test_callback_count = 0;
    var dispatcher = EventDispatcher.init();
    const button = UiHandle.from_raw(1, .button);
    const label = UiHandle.from_raw(2, .label);

    _ = dispatcher.on(button, .click, test_callback, null);

    // Event for different target
    const event = UiEvent.init(label, .click, 0);
    const dispatched = dispatcher.dispatch(event);

    try testing.expectEqual(@as(u32, 0), dispatched);
    try testing.expectEqual(@as(u32, 0), test_callback_count);
}

// === UiApp Tests ===

test "ui app initialization" {
    var app = UiApp.init();
    try testing.expect(!app.is_running());
    try testing.expectEqual(@as(u32, 0), app.component_count());
}

test "ui app create window" {
    var app = UiApp.init();
    const window = app.create_window();

    try testing.expect(window != null);
    try testing.expectEqual(@as(u32, 1), app.component_count());
}

test "ui app add components" {
    var app = UiApp.init();
    const window = app.create_window().?;

    const label = app.add_label(window, "Welcome");
    const button = app.add_button(window, "OK");
    const input = app.add_input(window, "Type here");

    try testing.expect(label != null);
    try testing.expect(button != null);
    try testing.expect(input != null);
    try testing.expectEqual(@as(u32, 4), app.component_count());
}

test "ui app register click handler" {
    var app = UiApp.init();
    const window = app.create_window().?;
    const button = app.add_button(window, "Click").?;

    try testing.expect(app.on_click(button, test_callback, null));
}

test "ui app run and stop" {
    var app = UiApp.init();
    _ = app.create_window();

    app.run();
    try testing.expect(app.is_running());

    app.stop();
    try testing.expect(!app.is_running());
}

test "ui app process event" {
    test_callback_count = 0;
    var app = UiApp.init();
    const window = app.create_window().?;
    const button = app.add_button(window, "Test").?;

    _ = app.on_click(button, test_callback, null);

    const event = UiEvent.init(button, .click, 0);
    const processed = app.process_event(event);

    try testing.expectEqual(@as(u32, 1), processed);
    try testing.expectEqual(@as(u32, 1), test_callback_count);
}
