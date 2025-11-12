const std = @import("std");
const Platform = @import("platform.zig").Platform;
const GrainAurora = @import("grain_aurora.zig").GrainAurora;
const AuroraFilter = @import("aurora_filter.zig");
const TextRenderer = @import("aurora_text_renderer.zig").TextRenderer;

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

        // Render initial component tree: welcome message.
        const welcome_component = struct {
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
        }.view;

        try aurora.render(welcome_component, "/");

        return TahoeSandbox{
            .allocator = allocator,
            .platform = platform,
            .aurora = aurora,
            .filter_state = .{},
        };
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
        // Assert buffer: must be RGBA-aligned and match dimensions.
        std.debug.assert(buffer.len > 0);
        std.debug.assert(buffer.len % 4 == 0);
        const window_width = self.platform.width();
        const window_height = self.platform.height();
        // Assert dimensions: must match buffer size.
        std.debug.assert(window_width > 0);
        std.debug.assert(window_height > 0);
        std.debug.assert(buffer.len == window_width * window_height * 4);
        
        // Tiger Style: Draw something visible to the buffer!
        // Fill with a nice dark blue-gray background (Tahoe aesthetic).
        const bg_color: u32 = 0xFF1E1E2E; // Dark blue-gray (RGBA)
        @memset(buffer, @as(u8, @truncate(bg_color)));
        @memset(buffer[1..], @as(u8, @truncate(bg_color >> 8)));
        @memset(buffer[2..], @as(u8, @truncate(bg_color >> 16)));
        @memset(buffer[3..], @as(u8, @truncate(bg_color >> 24)));
        
        // Actually, let's do it pixel by pixel for clarity.
        var y: u32 = 0;
        while (y < window_height) : (y += 1) {
            var x: u32 = 0;
            while (x < window_width) : (x += 1) {
                const pixel_offset = (y * window_width + x) * 4;
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
        const center_x = window_width / 2;
        const center_y = window_height / 2;
        const rect_width = @min(400, window_width - 100);
        const rect_height = @min(200, window_height - 100);
        const rect_x = center_x - rect_width / 2;
        const rect_y = center_y - rect_height / 2;
        
        var rect_y_idx: u32 = rect_y;
        while (rect_y_idx < rect_y + rect_height and rect_y_idx < window_height) : (rect_y_idx += 1) {
            var rect_x_idx: u32 = rect_x;
            while (rect_x_idx < rect_x + rect_width and rect_x_idx < window_width) : (rect_x_idx += 1) {
                const pixel_offset = (rect_y_idx * window_width + rect_x_idx) * 4;
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
