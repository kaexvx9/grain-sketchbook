const std = @import("std");
const Platform = @import("../../platform.zig").Platform;
const Window = @import("window.zig").Window;

/// macOS platform implementation: wraps Cocoa window in platform abstraction.
pub const vtable = Platform.VTable{
    .init = init,
    .deinit = deinit,
    .show = show,
    .getBuffer = getBuffer,
    .present = present,
    .width = width,
    .height = height,
    .runEventLoop = runEventLoop,
};

/// Initialize macOS platform window: returns single pointer to type-erased window.
/// 
/// Pointer design (TigerStyle single-level only):
/// - `allocator.create(Window)` returns `*Window`: single pointer.
/// - Return type `*anyopaque`: single pointer to type-erased window.
/// - Cast from `*Window` to `*anyopaque` is single-level; no double indirection.
fn init(allocator: std.mem.Allocator, title: []const u8) !*anyopaque {
    // Assert arguments: title must not be empty and within bounds.
    std.debug.assert(title.len > 0);
    std.debug.assert(title.len <= 256);
    // Single pointer to Window: allocated on heap, returned as single pointer.
    const window = try allocator.create(Window);
    window.* = Window.init(allocator, title);
    // Assert postcondition: window must be initialized.
    std.debug.assert(window.rgba_buffer.len > 0);
    std.debug.assert(window.width > 0);
    std.debug.assert(window.height > 0);
    // Cast single pointer from concrete type to type-erased: single-level only.
    return window;
}

/// Deinitialize macOS platform window: single pointer to type-erased window.
/// 
/// Pointer design (TigerStyle single-level only):
/// - `impl: *anyopaque`: single pointer to type-erased window.
/// - `@ptrCast(@alignCast(impl))`: casts single pointer to `*Window`.
/// - Cast is single-level; no double indirection. Both pointers are same level.
fn deinit(impl: *anyopaque) void {
    // Cast single pointer from type-erased to concrete type: single-level only.
    const window: *Window = @ptrCast(@alignCast(impl));
    // Assert invariant: window must have valid buffer before deinit.
    std.debug.assert(window.rgba_buffer.len > 0);
    // Save allocator before deinit clears the struct.
    const allocator = window.allocator;
    window.deinit();
    allocator.destroy(window);
}

/// Show macOS platform window: single pointer to type-erased window.
/// 
/// Pointer flow: `impl: *anyopaque` (single pointer) → cast to `*Window`
/// (single pointer). Both are same level; no double indirection.
fn show(impl: *anyopaque) !void {
    // Cast single pointer from type-erased to concrete type: single-level only.
    const window: *Window = @ptrCast(@alignCast(impl));
    // Assert invariant: window must have valid buffer.
    std.debug.assert(window.rgba_buffer.len > 0);
    std.debug.assert(window.width > 0);
    std.debug.assert(window.height > 0);
    window.show();
}

/// Get macOS platform buffer: single pointer to type-erased window, returns slice.
/// 
/// Pointer flow: `impl: *anyopaque` (single pointer) → cast to `*Window`
/// (single pointer) → returns slice (not pointer). No double indirection.
fn getBuffer(impl: *anyopaque) []u8 {
    // Cast single pointer from type-erased to concrete type: single-level only.
    const window: *Window = @ptrCast(@alignCast(impl));
    const buffer = window.getBuffer();
    // Assert return value: buffer must be RGBA-aligned and match dimensions.
    std.debug.assert(buffer.len > 0);
    std.debug.assert(buffer.len % 4 == 0);
    std.debug.assert(buffer.len == window.width * window.height * 4);
    return buffer;
}

/// Present macOS platform window: single pointer to type-erased window.
/// 
/// Pointer flow: `impl: *anyopaque` (single pointer) → cast to `*Window`
/// (single pointer). Both are same level; no double indirection.
fn present(impl: *anyopaque) !void {
    // Cast single pointer from type-erased to concrete type: single-level only.
    const window: *Window = @ptrCast(@alignCast(impl));
    // Assert invariant: window must have valid buffer.
    std.debug.assert(window.rgba_buffer.len > 0);
    try window.present();
}

/// Get macOS platform width: single pointer to type-erased window, returns u32.
/// 
/// Pointer flow: `impl: *anyopaque` (single pointer) → cast to `*Window`
/// (single pointer) → returns u32 (not pointer). No double indirection.
fn width(impl: *anyopaque) u32 {
    // Cast single pointer from type-erased to concrete type: single-level only.
    const window: *Window = @ptrCast(@alignCast(impl));
    const w = window.width;
    // Assert return value: width must be positive and reasonable.
    std.debug.assert(w > 0);
    std.debug.assert(w <= 16384);
    return w;
}

/// Get macOS platform height: single pointer to type-erased window, returns u32.
/// 
/// Pointer flow: `impl: *anyopaque` (single pointer) → cast to `*Window`
/// (single pointer) → returns u32 (not pointer). No double indirection.
fn height(impl: *anyopaque) u32 {
    // Cast single pointer from type-erased to concrete type: single-level only.
    const window: *Window = @ptrCast(@alignCast(impl));
    const h = window.height;
    // Assert return value: height must be positive and reasonable.
    std.debug.assert(h > 0);
    std.debug.assert(h <= 16384);
    return h;
}

/// Run macOS event loop: delegates to Window.runEventLoop.
/// Why: Platform abstraction requires vtable dispatch for event loop.
fn runEventLoop(impl: *anyopaque) void {
    const window: *Window = @ptrCast(@alignCast(impl));
    window.runEventLoop();
}

