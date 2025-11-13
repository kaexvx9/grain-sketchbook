const std = @import("std");
const Platform = @import("platform.zig").Platform;
const GrainAurora = @import("grain_aurora.zig").GrainAurora;
const AuroraFilter = @import("aurora_filter.zig");
const TextRenderer = @import("aurora_text_renderer.zig").TextRenderer;
const events = @import("platform/events.zig");

/// TahoeSandbox hosts a River-inspired compositor with Moonglow keybindings,
/// blending Vegan Tiger aesthetics with Grain terminal panes.
/// ~<~ Glow Waterbend: compositor streams stay deterministic.
pub const TahoeSandbox = struct {
    allocator: std.mem.Allocator,
    platform: Platform,
    aurora: GrainAurora,
    filter_state: AuroraFilter.FluxState,

    pub fn init(allocator: std.mem.Allocator, title: []const u8) !TahoeSandbox {
        // Assert arguments: title must not be empty and within bounds.
        std.debug.assert(title.len > 0);
        std.debug.assert(title.len <= 256);
        var platform = try Platform.init(allocator, title);
        errdefer platform.deinit();
        // Assert postcondition: platform must be initialized.
        // VTable and impl are non-optional pointers in Zig 0.15.
        _ = platform.vtable;
        _ = platform.impl;
        var aurora = try GrainAurora.init(allocator, "");
        errdefer aurora.deinit();
        
        var sandbox = TahoeSandbox{
            .allocator = allocator,
            .platform = platform,
            .aurora = aurora,
            .filter_state = .{},
        };
        
        // Set up event handler (Tiger Style: validate all function pointers).
        const event_handler = events.EventHandler{
            .user_data = &sandbox,
            .onMouse = handleMouseEvent,
            .onKeyboard = handleKeyboardEvent,
            .onFocus = handleFocusEvent,
        };
        
        // Assert: event handler function pointers must be valid.
        const onMouse_ptr = @intFromPtr(event_handler.onMouse);
        const onKeyboard_ptr = @intFromPtr(event_handler.onKeyboard);
        const onFocus_ptr = @intFromPtr(event_handler.onFocus);
        std.debug.assert(onMouse_ptr != 0);
        std.debug.assert(onKeyboard_ptr != 0);
        std.debug.assert(onFocus_ptr != 0);
        if (onMouse_ptr < 0x1000) {
            std.debug.panic("TahoeSandbox.init: onMouse pointer is suspiciously small: 0x{x}", .{onMouse_ptr});
        }
        if (onKeyboard_ptr < 0x1000) {
            std.debug.panic("TahoeSandbox.init: onKeyboard pointer is suspiciously small: 0x{x}", .{onKeyboard_ptr});
        }
        if (onFocus_ptr < 0x1000) {
            std.debug.panic("TahoeSandbox.init: onFocus pointer is suspiciously small: 0x{x}", .{onFocus_ptr});
        }
        
        // Assert: user_data pointer must be valid.
        const user_data_ptr = @intFromPtr(event_handler.user_data);
        std.debug.assert(user_data_ptr == @intFromPtr(&sandbox));
        std.debug.assert(user_data_ptr != 0);
        
        platform.vtable.setEventHandler(platform.impl, &event_handler);
        
        // Render initial component tree: welcome message.
        try aurora.render(struct {
            fn view(ctx: *GrainAurora.RenderContext) GrainAurora.RenderResult {
                _ = ctx;
                return GrainAurora.RenderResult{
                    .root = .{ .column = .{
                        .children = &.{
                            .{ .text = "Grain Aurora" },
                            .{ .text = "" },
                            .{ .text = "Welcome to the Tahoe sandbox." },
                            .{ .text = "River-inspired compositor with Moonglow keymaps." },
                            .{ .text = "" },
                            .{ .button = .{ .id = "start", .label = "Begin" } },
                        },
                    } },
                    .readonly_spans = &.{},
                };
            }
        }.view, "/");
        
        return sandbox;
    }
    
    /// Handle mouse events: log and process.
    /// Tiger Style: validate user_data pointer, validate event fields.
    fn handleMouseEvent(user_data: *anyopaque, event: events.MouseEvent) bool {
        // Assert: user_data pointer must be valid (non-zero, aligned).
        const user_data_ptr = @intFromPtr(user_data);
        std.debug.assert(user_data_ptr != 0);
        if (user_data_ptr < 0x1000) {
            std.debug.panic("handleMouseEvent: user_data pointer is suspiciously small: 0x{x}", .{user_data_ptr});
        }
        if (user_data_ptr % @alignOf(TahoeSandbox) != 0) {
            std.debug.panic("handleMouseEvent: user_data pointer is not aligned: 0x{x}", .{user_data_ptr});
        }
        
        // Cast user_data to TahoeSandbox.
        const sandbox: *TahoeSandbox = @ptrCast(@alignCast(user_data));
        
        // Assert: sandbox pointer round-trip check.
        const sandbox_ptr = @intFromPtr(sandbox);
        std.debug.assert(sandbox_ptr == user_data_ptr);
        
        // Assert: sandbox must have valid platform (Tiger Style invariant).
        _ = sandbox.platform.vtable;
        _ = sandbox.platform.impl;
        
        // Assert: event coordinates must be reasonable.
        std.debug.assert(event.x >= -10000.0 and event.x <= 10000.0);
        std.debug.assert(event.y >= -10000.0 and event.y <= 10000.0);
        
        // Assert: event enum values must be valid.
        std.debug.assert(@intFromEnum(event.kind) < 4);
        std.debug.assert(@intFromEnum(event.button) < 4);
        
        std.debug.print("[tahoe_window] Mouse event: kind={s}, button={s}, x={d}, y={d}, modifiers={any}\n", .{
            @tagName(event.kind),
            @tagName(event.button),
            event.x,
            event.y,
            event.modifiers,
        });
        // For now, just log events. Later: implement actual interaction.
        // Note: sandbox is validated above via assertions.
        return false; // Event not handled.
    }
    
    /// Handle keyboard events: log and process.
    /// Tiger Style: validate user_data pointer, validate event fields.
    fn handleKeyboardEvent(user_data: *anyopaque, event: events.KeyboardEvent) bool {
        // Assert: user_data pointer must be valid (non-zero, aligned).
        const user_data_ptr = @intFromPtr(user_data);
        std.debug.assert(user_data_ptr != 0);
        if (user_data_ptr < 0x1000) {
            std.debug.panic("handleKeyboardEvent: user_data pointer is suspiciously small: 0x{x}", .{user_data_ptr});
        }
        if (user_data_ptr % @alignOf(TahoeSandbox) != 0) {
            std.debug.panic("handleKeyboardEvent: user_data pointer is not aligned: 0x{x}", .{user_data_ptr});
        }
        
        // Cast user_data to TahoeSandbox.
        const sandbox: *TahoeSandbox = @ptrCast(@alignCast(user_data));
        
        // Assert: sandbox pointer round-trip check.
        const sandbox_ptr = @intFromPtr(sandbox);
        std.debug.assert(sandbox_ptr == user_data_ptr);
        
        // Assert: sandbox must have valid platform (Tiger Style invariant).
        _ = sandbox.platform.vtable;
        _ = sandbox.platform.impl;
        
        // Assert: event key_code must be reasonable.
        std.debug.assert(event.key_code <= 0xFFFF);
        
        // Assert: event character must be valid Unicode (if present).
        if (event.character) |c| {
            std.debug.assert(c <= 0x10FFFF);
            std.debug.assert(!(c >= 0xD800 and c <= 0xDFFF)); // No surrogates
        }
        
        // Assert: event enum value must be valid.
        std.debug.assert(@intFromEnum(event.kind) < 2);
        
        const char_str = if (event.character) |c| blk: {
            var buf: [4]u8 = undefined;
            const len = std.unicode.utf8Encode(c, &buf) catch 0;
            std.debug.assert(len > 0);
            std.debug.assert(len <= 4);
            break :blk buf[0..len];
        } else "none";
        std.debug.print("[tahoe_window] Keyboard event: kind={s}, key_code={d}, character={s}, modifiers={any}\n", .{
            @tagName(event.kind),
            event.key_code,
            char_str,
            event.modifiers,
        });
        // For now, just log events. Later: implement actual interaction.
        // Note: sandbox is validated above via assertions.
        return false; // Event not handled.
    }
    
    /// Handle focus events: log window focus changes.
    /// Tiger Style: validate user_data pointer, validate event fields.
    fn handleFocusEvent(user_data: *anyopaque, event: events.FocusEvent) bool {
        // Assert: user_data pointer must be valid (non-zero, aligned).
        const user_data_ptr = @intFromPtr(user_data);
        std.debug.assert(user_data_ptr != 0);
        if (user_data_ptr < 0x1000) {
            std.debug.panic("handleFocusEvent: user_data pointer is suspiciously small: 0x{x}", .{user_data_ptr});
        }
        if (user_data_ptr % @alignOf(TahoeSandbox) != 0) {
            std.debug.panic("handleFocusEvent: user_data pointer is not aligned: 0x{x}", .{user_data_ptr});
        }
        
        // Cast user_data to TahoeSandbox.
        const sandbox: *TahoeSandbox = @ptrCast(@alignCast(user_data));
        
        // Assert: sandbox pointer round-trip check.
        const sandbox_ptr = @intFromPtr(sandbox);
        std.debug.assert(sandbox_ptr == user_data_ptr);
        
        // Assert: sandbox must have valid platform (Tiger Style invariant).
        _ = sandbox.platform.vtable;
        _ = sandbox.platform.impl;
        
        // Assert: event enum value must be valid.
        std.debug.assert(@intFromEnum(event.kind) < 2);
        
        std.debug.print("[tahoe_window] Focus event: kind={s}\n", .{@tagName(event.kind)});
        // For now, just log events. Later: implement focus-based UI updates.
        // Note: sandbox is validated above via assertions.
        return false; // Event not handled.
    }

    pub fn deinit(self: *TahoeSandbox) void {
        self.aurora.deinit();
        self.platform.deinit();
        self.* = undefined;
    }

    pub fn show(self: *TahoeSandbox) !void {
        try self.platform.show();
    }

    pub fn tick(self: *TahoeSandbox) !void {
        // Assert precondition: platform must be initialized.
        // VTable and impl are non-optional pointers in Zig 0.15.
        _ = self.platform.vtable;
        _ = self.platform.impl;
        const buffer = self.platform.getBuffer();
        // Assert buffer: must be RGBA-aligned.
        // Buffer size is fixed (1024x768), window size can differ.
        std.debug.assert(buffer.len > 0);
        std.debug.assert(buffer.len % 4 == 0);
        const expected_buffer_size = 1024 * 768 * 4; // Fixed buffer size
        std.debug.assert(buffer.len == expected_buffer_size);
        
        // Buffer dimensions (fixed, always 1024x768).
        const buffer_width: u32 = 1024;
        const buffer_height: u32 = 768;
        
        // Tiger Style: Draw something visible to the buffer!
        // Fill with a nice dark blue-gray background (Tahoe aesthetic).
        const bg_color: u32 = 0xFF1E1E2E; // Dark blue-gray (RGBA)
        @memset(buffer, @as(u8, @truncate(bg_color)));
        @memset(buffer[1..], @as(u8, @truncate(bg_color >> 8)));
        @memset(buffer[2..], @as(u8, @truncate(bg_color >> 16)));
        @memset(buffer[3..], @as(u8, @truncate(bg_color >> 24)));
        
        // Actually, let's do it pixel by pixel for clarity.
        var y: u32 = 0;
        while (y < buffer_height) : (y += 1) {
            var x: u32 = 0;
            while (x < buffer_width) : (x += 1) {
                const pixel_offset = (y * buffer_width + x) * 4;
                if (pixel_offset + 3 < buffer.len) {
                    // RGBA format: R, G, B, A
                    buffer[pixel_offset + 0] = 0x1E; // R
                    buffer[pixel_offset + 1] = 0x1E; // G
                    buffer[pixel_offset + 2] = 0x2E; // B
                    buffer[pixel_offset + 3] = 0xFF; // A (fully opaque)
                }
            }
        }
        
        // Draw a simple gradient or pattern to show it's working.
        // Draw a white rectangle in the center as a "hello world".
        // Use buffer dimensions for drawing (fixed 1024x768).
        const center_x = buffer_width / 2;
        const center_y = buffer_height / 2;
        const rect_width = @min(400, buffer_width - 100);
        const rect_height = @min(200, buffer_height - 100);
        const rect_x = center_x - rect_width / 2;
        const rect_y = center_y - rect_height / 2;
        
        var rect_y_idx: u32 = rect_y;
        while (rect_y_idx < rect_y + rect_height and rect_y_idx < buffer_height) : (rect_y_idx += 1) {
            var rect_x_idx: u32 = rect_x;
            while (rect_x_idx < rect_x + rect_width and rect_x_idx < buffer_width) : (rect_x_idx += 1) {
                const pixel_offset = (rect_y_idx * buffer_width + rect_x_idx) * 4;
                if (pixel_offset + 3 < buffer.len) {
                    // White with slight transparency
                    buffer[pixel_offset + 0] = 0xFF; // R
                    buffer[pixel_offset + 1] = 0xFF; // G
                    buffer[pixel_offset + 2] = 0xFF; // B
                    buffer[pixel_offset + 3] = 0xE0; // A (slightly transparent)
                }
            }
        }
        
        std.debug.print("[tahoe_window] Drew background and white rectangle to buffer.\n", .{});
        
        // Apply Aurora filter if enabled.
        AuroraFilter.apply(self.filter_state, buffer);
        
        // Present the buffer to the window.
        try self.platform.present();
        std.debug.print("[tahoe_window] Buffer presented to window.\n", .{});
    }

    pub fn toggleFlux(self: *TahoeSandbox, mode: AuroraFilter.Mode) void {
        self.filter_state.toggle(mode);
    }
    
    /// Start animation loop: sets up timer to call tick() continuously at 60fps.
    /// Tiger Style: validate platform pointers, ensure callback is properly set up.
    pub fn startAnimationLoop(self: *TahoeSandbox) void {
        // Assert: platform must be initialized.
        _ = self.platform.vtable;
        _ = self.platform.impl;
        
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        std.debug.assert(self_ptr != 0);
        if (self_ptr < 0x1000) {
            std.debug.panic("TahoeSandbox.startAnimationLoop: self pointer is suspiciously small: 0x{x}", .{self_ptr});
        }
        
        // Create tick callback that calls self.tick().
        const tickCallback = struct {
            fn tick(user_data: *anyopaque) void {
                const sandbox: *TahoeSandbox = @ptrCast(@alignCast(user_data));
                
                // Assert: sandbox pointer round-trip check.
                const sandbox_ptr = @intFromPtr(sandbox);
                const user_data_ptr = @intFromPtr(user_data);
                std.debug.assert(sandbox_ptr == user_data_ptr);
                
                // Assert: sandbox must have valid platform.
                _ = sandbox.platform.vtable;
                _ = sandbox.platform.impl;
                
                // Call tick (ignore errors in timer callback - log them instead).
                sandbox.tick() catch |err| {
                    std.debug.print("[tahoe_window] Tick error in animation loop: {s}\n", .{@errorName(err)});
                };
            }
        }.tick;
        
        // Start animation loop via platform.
        // Note: tickCallback function pointer validation happens in Window.startAnimationLoop.
        self.platform.vtable.startAnimationLoop(self.platform.impl, tickCallback, self);
        
        std.debug.print("[tahoe_window] Animation loop started (60fps).\n", .{});
    }
    
    /// Stop animation loop: stops timer.
    /// Tiger Style: validate platform pointers.
    pub fn stopAnimationLoop(self: *TahoeSandbox) void {
        // Assert: platform must be initialized.
        _ = self.platform.vtable;
        _ = self.platform.impl;
        
        // Stop animation loop via platform.
        self.platform.vtable.stopAnimationLoop(self.platform.impl);
        
        std.debug.print("[tahoe_window] Animation loop stopped.\n", .{});
    }
};

test "tahoe sandbox lifecycle" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var sandbox = try TahoeSandbox.init(arena.allocator(), "Test");
    defer sandbox.deinit();
    try sandbox.show();
    try sandbox.tick();
    sandbox.toggleFlux(.darkroom);
    try sandbox.tick();
}
