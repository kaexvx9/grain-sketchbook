//! Grainscript UI Built-in Functions
//! Why: Expose kernel UI API to Grainscript applications.
//! See: docs/rye/0007-basin-kernel-boot-roadmap.md Phase 5.3

const std = @import("std");
const Interpreter = @import("interpreter.zig").Interpreter;
const Value = Interpreter.Value;
const Error = Interpreter.Error;

// === UI Built-in Functions ===

/// Why: Create a new window.
/// Usage: window = ui_create_window()
/// Returns: Window handle (integer) or null on failure.
pub fn builtin_ui_create_window(_: *Interpreter, _: []const Value) Error!Value {
    // TODO: Connect to kernel UI event loop when available.
    // For now, return a placeholder handle.
    return Value{ .integer = 1 };
}

/// Why: Add a label to a container.
/// Usage: label = ui_add_label(parent, "text")
/// Args: parent handle, text string.
/// Returns: Label handle (integer) or null on failure.
pub fn builtin_ui_add_label(_: *Interpreter, args: []const Value) Error!Value {
    if (args.len < 2) return Error.TypeMismatch;
    if (args[0] != .integer) return Error.TypeMismatch;
    if (args[1] != .string) return Error.TypeMismatch;

    // TODO: Connect to kernel UI event loop.
    // For now, return a placeholder handle.
    return Value{ .integer = 2 };
}

/// Why: Add a button to a container.
/// Usage: button = ui_add_button(parent, "text")
/// Args: parent handle, text string.
/// Returns: Button handle (integer) or null on failure.
pub fn builtin_ui_add_button(_: *Interpreter, args: []const Value) Error!Value {
    if (args.len < 2) return Error.TypeMismatch;
    if (args[0] != .integer) return Error.TypeMismatch;
    if (args[1] != .string) return Error.TypeMismatch;

    // TODO: Connect to kernel UI event loop.
    return Value{ .integer = 3 };
}

/// Why: Add a text input field to a container.
/// Usage: input = ui_add_input(parent, "placeholder")
/// Args: parent handle, placeholder text.
/// Returns: Input handle (integer) or null on failure.
pub fn builtin_ui_add_input(_: *Interpreter, args: []const Value) Error!Value {
    if (args.len < 2) return Error.TypeMismatch;
    if (args[0] != .integer) return Error.TypeMismatch;
    if (args[1] != .string) return Error.TypeMismatch;

    // TODO: Connect to kernel UI event loop.
    return Value{ .integer = 4 };
}

/// Why: Add a list/output area to a container.
/// Usage: list = ui_add_list(parent)
/// Args: parent handle.
/// Returns: List handle (integer) or null on failure.
pub fn builtin_ui_add_list(_: *Interpreter, args: []const Value) Error!Value {
    if (args.len < 1) return Error.TypeMismatch;
    if (args[0] != .integer) return Error.TypeMismatch;

    // TODO: Connect to kernel UI event loop.
    return Value{ .integer = 5 };
}

/// Why: Set text content of a UI element.
/// Usage: ui_set_text(handle, "new text")
/// Args: element handle, new text.
/// Returns: true on success, false on failure.
pub fn builtin_ui_set_text(_: *Interpreter, args: []const Value) Error!Value {
    if (args.len < 2) return Error.TypeMismatch;
    if (args[0] != .integer) return Error.TypeMismatch;
    if (args[1] != .string) return Error.TypeMismatch;

    // TODO: Connect to kernel UI event loop.
    return Value{ .boolean = true };
}

/// Why: Get text content of a UI element.
/// Usage: text = ui_get_text(handle)
/// Args: element handle.
/// Returns: Text string or empty string on failure.
pub fn builtin_ui_get_text(_: *Interpreter, args: []const Value) Error!Value {
    if (args.len < 1) return Error.TypeMismatch;
    if (args[0] != .integer) return Error.TypeMismatch;

    // TODO: Connect to kernel UI event loop.
    return Value{ .string = "" };
}

/// Why: Poll for UI events.
/// Usage: event = ui_poll_event()
/// Returns: Event data (integer code) or null if no event.
pub fn builtin_ui_poll_event(_: *Interpreter, _: []const Value) Error!Value {
    // TODO: Connect to kernel UI event loop.
    // For now, return null (no events).
    return Value{ .null = {} };
}

/// Why: Check if UI system is available.
/// Usage: available = ui_available()
/// Returns: true if UI is available, false otherwise.
pub fn builtin_ui_available(_: *Interpreter, _: []const Value) Error!Value {
    // TODO: Check kernel UI event loop status.
    return Value{ .boolean = true };
}

// === Registration ===

/// Why: Register all UI built-in functions with the interpreter.
pub fn register_ui_builtins(interpreter: *Interpreter) !void {
    const BuiltinFn = *const fn (*Interpreter, []const Value) Error!Value;

    const builtins = [_]struct { name: []const u8, params: u32, handler: BuiltinFn }{
        .{ .name = "ui_create_window", .params = 0, .handler = builtin_ui_create_window },
        .{ .name = "ui_add_label", .params = 2, .handler = builtin_ui_add_label },
        .{ .name = "ui_add_button", .params = 2, .handler = builtin_ui_add_button },
        .{ .name = "ui_add_input", .params = 2, .handler = builtin_ui_add_input },
        .{ .name = "ui_add_list", .params = 1, .handler = builtin_ui_add_list },
        .{ .name = "ui_set_text", .params = 2, .handler = builtin_ui_set_text },
        .{ .name = "ui_get_text", .params = 1, .handler = builtin_ui_get_text },
        .{ .name = "ui_poll_event", .params = 0, .handler = builtin_ui_poll_event },
        .{ .name = "ui_available", .params = 0, .handler = builtin_ui_available },
    };

    for (builtins) |b| {
        try interpreter.add_builtin(b.name, b.params, b.handler);
    }
}
