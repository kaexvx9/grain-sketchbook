const std = @import("std");
const c = @import("objc_runtime.zig").c;
const cg = @import("objc_runtime.zig").cg;
const cocoa = @import("cocoa_bridge.zig");

// C helper function to create NSImage from CGImage.
extern fn createNSImageFromCGImage(cgImage: *anyopaque, width: f64, height: f64) ?*c.objc_object;

/// Thin Cocoa bridge: Aurora owns the RGBA buffer; Cocoa just hosts the view.
/// ~<~ Glow Airbend: explicit allocations prevent dynamic Cocoa leaks into Zig runtime.
/// 
/// Pointer design (TigerStyle single-level only):
/// - `ns_window: ?*c.objc_object`: Single pointer to NSWindow (nullable for cleanup).
/// - `ns_view: ?*c.objc_object`: Single pointer to NSView (nullable for cleanup).
/// - `ns_app: ?*c.objc_object`: Single pointer to NSApplication shared instance (nullable for cleanup).
/// - `rgba_buffer`: Static array, no pointers needed.
pub const Window = struct {
    title: []const u8,
    width: u32 = 1024,
    height: u32 = 768,
    /// Static buffer for RGBA pixels: avoids dynamic allocation.
    /// Size: 1024 * 768 * 4 = 3,145,728 bytes (3MB).
    /// Why: Static allocation eliminates allocator dependency and reduces runtime overhead.
    rgba_buffer: [1024 * 768 * 4]u8 = [_]u8{0} ** (1024 * 768 * 4),
    allocator: std.mem.Allocator,
    /// Single pointer to NSWindow: nullable for cleanup safety.
    ns_window: ?*c.objc_object = null,
    /// Single pointer to NSView: nullable for cleanup safety.
    ns_view: ?*c.objc_object = null,
    /// Single pointer to NSApplication shared instance: nullable for cleanup safety.
    ns_app: ?*c.objc_object = null,

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, title: []const u8) Self {
        // Assert: title must be valid (non-empty, reasonable length).
        std.debug.assert(title.len > 0);
        std.debug.assert(title.len <= 1024);
        
        // Assert: allocator must be valid (non-null pointer).
        const allocator_ptr = @intFromPtr(allocator.ptr);
        std.debug.assert(allocator_ptr != 0);
        
        const self = Self{
            .title = title,
            .allocator = allocator,
            .width = 1024,
            .height = 768,
            .rgba_buffer = [_]u8{0} ** (1024 * 768 * 4),
            .ns_window = null,
            .ns_view = null,
            .ns_app = null,
        };
        
        // Assert postcondition: dimensions must be valid.
        std.debug.assert(self.width > 0);
        std.debug.assert(self.height > 0);
        std.debug.assert(self.width <= 1024);
        std.debug.assert(self.height <= 768);
        
        // Assert: buffer size matches dimensions.
        const expected_buffer_size = @as(usize, self.width) * @as(usize, self.height) * 4;
        std.debug.assert(self.rgba_buffer.len == expected_buffer_size);
        std.debug.assert(self.rgba_buffer.len % 4 == 0);
        
        return self;
    }

    pub fn deinit(self: *Self) void {
        // Assert precondition: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        std.debug.assert(self_ptr != 0);
        
        // Assert precondition: buffer must be valid.
        std.debug.assert(self.rgba_buffer.len > 0);
        std.debug.assert(self.rgba_buffer.len % 4 == 0);
        const expected_buffer_size = @as(usize, self.width) * @as(usize, self.height) * 4;
        std.debug.assert(self.rgba_buffer.len == expected_buffer_size);

        // Release Cocoa objects: single pointers, explicit cleanup.
        if (self.ns_view) |view| {
            const viewPtrValue = @intFromPtr(view);
            std.debug.assert(viewPtrValue != 0);
            const releaseSel = c.sel_getUid("release");
            std.debug.assert(releaseSel != null);
            cocoa.objc_msgSendVoid0(@ptrCast(view), releaseSel);
        }
        if (self.ns_window) |window| {
            const windowPtrValue = @intFromPtr(window);
            std.debug.assert(windowPtrValue != 0);
            const closeSel = c.sel_getUid("close");
            const releaseSel = c.sel_getUid("release");
            std.debug.assert(closeSel != null);
            std.debug.assert(releaseSel != null);
            cocoa.objc_msgSendVoid0(@ptrCast(window), closeSel);
            cocoa.objc_msgSendVoid0(@ptrCast(window), releaseSel);
        }

        self.* = undefined;
    }

    pub fn show(self: *Self) void {
        // Assert precondition: title must be valid.
        std.debug.assert(self.title.len > 0);
        std.debug.assert(self.width > 0);
        std.debug.assert(self.height > 0);
        std.debug.assert(self.rgba_buffer.len > 0);
        std.debug.assert(self.rgba_buffer.len == self.width * self.height * 4);

        // Initialize NSApplication: get shared instance.
        const NSApplicationClass = c.objc_getClass("NSApplication");
        std.debug.assert(NSApplicationClass != null);
        const sharedAppSel = c.sel_getUid("sharedApplication");
        std.debug.assert(sharedAppSel != null);
        const sharedApp_opt = cocoa.objc_msgSend0(@ptrCast(NSApplicationClass), sharedAppSel);
        std.debug.assert(sharedApp_opt != null);
        const sharedApp: *c.objc_object = @ptrCast(@alignCast(sharedApp_opt.?));
        std.debug.assert(@intFromPtr(sharedApp) != 0);

        // Create NSWindow.
        const NSWindowClass = c.objc_getClass("NSWindow");
        std.debug.assert(NSWindowClass != null);
        const allocSel = c.sel_getUid("alloc");
        std.debug.assert(allocSel != null);
        const window_opt = cocoa.objc_msgSend0(@ptrCast(NSWindowClass), allocSel);
        std.debug.assert(window_opt != null);
        const window: *c.objc_object = @ptrCast(@alignCast(window_opt.?));
        std.debug.assert(@intFromPtr(window) != 0);

        // Create content rect.
        const contentRect = cocoa.NSRect{
            .origin = .{
                .x = 100.0,
                .y = 100.0,
            },
            .size = .{
                .width = @as(f64, @floatFromInt(self.width)),
                .height = @as(f64, @floatFromInt(self.height)),
            },
        };

        // Initialize window.
        const initSel = c.sel_getUid("initWithContentRect:styleMask:backing:defer:");
        std.debug.assert(initSel != null);
        const styleMask: usize = 15;
        const backing: usize = 2;
        const deferFlag: bool = false;
        const nsWindow_opt = cocoa.objc_msgSend4(@ptrCast(window), initSel, contentRect, styleMask, backing, deferFlag);
        std.debug.assert(nsWindow_opt != null);
        const nsWindow: *c.objc_object = @ptrCast(@alignCast(nsWindow_opt.?));
        std.debug.assert(@intFromPtr(nsWindow) != 0);

        // Set window title.
        const setTitleSel = c.sel_getUid("setTitle:");
        std.debug.assert(setTitleSel != null);
        const title_cstr = std.fmt.allocPrint(self.allocator, "{s}\x00", .{self.title}) catch |err| {
            std.debug.panic("Failed to allocate title string: {s}", .{@errorName(err)});
        };
        defer self.allocator.free(title_cstr);
        const NSStringClass = c.objc_getClass("NSString");
        std.debug.assert(NSStringClass != null);
        const stringWithUTF8StringSel = c.sel_getUid("stringWithUTF8String:");
        std.debug.assert(stringWithUTF8StringSel != null);
        const title_nsstring_opt = cocoa.objc_msgSendNSString(@ptrCast(NSStringClass), stringWithUTF8StringSel, title_cstr.ptr);
        std.debug.assert(title_nsstring_opt != null);
        const title_nsstring: *c.objc_object = @ptrCast(@alignCast(title_nsstring_opt.?));
        cocoa.objc_msgSendVoid1(@ptrCast(nsWindow), setTitleSel, title_nsstring);

        // Create NSImageView (specialized view for displaying images).
        const NSImageViewClass = c.objc_getClass("NSImageView");
        std.debug.assert(NSImageViewClass != null);
        const imageView_opt = cocoa.objc_msgSend0(@ptrCast(NSImageViewClass), allocSel);
        std.debug.assert(imageView_opt != null);
        const imageView: *c.objc_object = @ptrCast(@alignCast(imageView_opt.?));
        std.debug.assert(@intFromPtr(imageView) != 0);
        const imageViewInitSel = c.sel_getUid("initWithFrame:");
        std.debug.assert(imageViewInitSel != null);
        const nsImageView_opt = cocoa.objc_msgSend1(@ptrCast(imageView), imageViewInitSel, contentRect);
        std.debug.assert(nsImageView_opt != null);
        const nsImageView: *c.objc_object = @ptrCast(@alignCast(nsImageView_opt.?));
        std.debug.assert(@intFromPtr(nsImageView) != 0);
        
        // Note: NSImageView will use default scaling (proportional scaling).
        // We can configure this later if needed.
        
        // Set image view as content view.
        const setContentViewSel = c.sel_getUid("setContentView:");
        std.debug.assert(setContentViewSel != null);
        cocoa.objc_msgSendVoid1(@ptrCast(nsWindow), setContentViewSel, nsImageView);
        
        // Store pointers (store imageView as ns_view since it's still an NSView).
        self.ns_window = nsWindow;
        self.ns_view = nsImageView;
        self.ns_app = sharedApp;
        
        // Show window.
        const makeKeySel = c.sel_getUid("makeKeyAndOrderFront:");
        std.debug.assert(makeKeySel != null);
        cocoa.objc_msgSendVoid0(@ptrCast(nsWindow), makeKeySel);
        
        // Activate application.
        const activateSel = c.sel_getUid("activateIgnoringOtherApps:");
        std.debug.assert(activateSel != null);
        cocoa.objc_msgSendVoidBool(@ptrCast(sharedApp), activateSel, true);
    }

    pub fn getBuffer(self: *Self) []u8 {
        // Assert precondition: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        std.debug.assert(self_ptr != 0);
        std.debug.assert(self.rgba_buffer.len > 0);
        std.debug.assert(self.rgba_buffer.len % 4 == 0);
        const expected_size = @as(usize, self.width) * @as(usize, self.height) * 4;
        std.debug.assert(self.rgba_buffer.len == expected_size);
        return &self.rgba_buffer;
    }

    pub fn present(self: *Self) !void {
        // Assert precondition: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        std.debug.assert(self_ptr != 0);
        if (self_ptr < 0x1000) {
            std.debug.panic("Window.present: self pointer is suspiciously small: 0x{x}", .{self_ptr});
        }
        
        // Assert precondition: view must be initialized.
        std.debug.assert(self.ns_view != null);
        const view = self.ns_view.?;
        const view_ptr = @intFromPtr(view);
        std.debug.assert(view_ptr != 0);
        if (view_ptr < 0x1000) {
            std.debug.panic("Window.present: view pointer is suspiciously small: 0x{x}", .{view_ptr});
        }
        if (view_ptr % 8 != 0) {
            std.debug.panic("Window.present: view pointer is not aligned: 0x{x}", .{view_ptr});
        }
        
        // Assert precondition: buffer must be valid.
        std.debug.assert(self.rgba_buffer.len > 0);
        std.debug.assert(self.rgba_buffer.len % 4 == 0);
        const expected_buffer_size = @as(usize, self.width) * @as(usize, self.height) * 4;
        std.debug.assert(self.rgba_buffer.len == expected_buffer_size);
        std.debug.assert(self.width > 0);
        std.debug.assert(self.height > 0);
        
        std.debug.print("[window] Presenting buffer to view at: 0x{x}, buffer size: {d} bytes\n", .{ view_ptr, self.rgba_buffer.len });
        
        // Create CGImage from RGBA buffer.
        const cg_image = try createCGImageFromBuffer(&self.rgba_buffer, self.width, self.height);
        defer releaseCGImage(cg_image);
        
        // Assert: CGImage must be valid.
        const cg_image_ptr = @intFromPtr(cg_image);
        std.debug.assert(cg_image_ptr != 0);
        if (cg_image_ptr < 0x1000) {
            std.debug.panic("Window.present: cg_image pointer is suspiciously small: 0x{x}", .{cg_image_ptr});
        }
        
        // Create NSImage from CGImage.
        std.debug.print("[window] Creating NSImage from CGImage (using C wrapper)...\n", .{});
        const width_f64 = @as(f64, @floatFromInt(self.width));
        const height_f64 = @as(f64, @floatFromInt(self.height));
        std.debug.assert(width_f64 > 0.0);
        std.debug.assert(height_f64 > 0.0);
        
        // Use extern function declared at top level.
        const nsImage_opt = createNSImageFromCGImage(cg_image, width_f64, height_f64);
        std.debug.assert(nsImage_opt != null);
        const nsImage: *c.objc_object = @ptrCast(@alignCast(nsImage_opt.?));
        
        // Assert: NSImage pointer must be valid.
        const nsImage_ptr = @intFromPtr(nsImage);
        std.debug.assert(nsImage_ptr != 0);
        if (nsImage_ptr < 0x1000) {
            std.debug.panic("Window.present: nsImage pointer is suspiciously small: 0x{x}", .{nsImage_ptr});
        }
        if (nsImage_ptr % 8 != 0) {
            std.debug.panic("Window.present: nsImage pointer is not aligned: 0x{x}", .{nsImage_ptr});
        }
        std.debug.print("[window] Created NSImage at: 0x{x}\n", .{nsImage_ptr});
        
        // Set image on NSImageView (much simpler than drawing manually).
        const setImageSel = c.sel_getUid("setImage:");
        std.debug.assert(setImageSel != null);
        cocoa.objc_msgSendVoid1(@ptrCast(view), setImageSel, nsImage);
        
        // Mark view as needing display.
        const setNeedsDisplaySel = c.sel_getUid("setNeedsDisplay:");
        std.debug.assert(setNeedsDisplaySel != null);
        cocoa.objc_msgSendVoidBool(@ptrCast(view), setNeedsDisplaySel, true);
        
        std.debug.print("[window] Set NSImage on NSImageView.\n", .{});
    }
    
    fn createCGImageFromBuffer(buffer: []const u8, width: u32, height: u32) !*anyopaque {
        // Assert: parameters must be valid.
        std.debug.assert(buffer.len > 0);
        std.debug.assert(width > 0);
        std.debug.assert(height > 0);
        const expected_size = @as(usize, width) * @as(usize, height) * 4;
        std.debug.assert(buffer.len == expected_size);
        std.debug.assert(buffer.len % 4 == 0);
        
        std.debug.print("[window] Creating CGImage: {d}x{d}, buffer: {d} bytes\n", .{ width, height, buffer.len });
        
        // Create CGColorSpace for RGB.
        const rgb_color_space = cg.CGColorSpaceCreateDeviceRGB();
        std.debug.assert(rgb_color_space != null);
        defer cg.CGColorSpaceRelease(rgb_color_space);
        
        // Create CGDataProvider from buffer.
        const data_provider = cg.CGDataProviderCreateWithData(
            null,
            buffer.ptr,
            buffer.len,
            null,
        );
        std.debug.assert(data_provider != null);
        defer cg.CGDataProviderRelease(data_provider);
        
        // Create CGImage.
        const cg_image = cg.CGImageCreate(
            width,
            height,
            8,
            32,
            width * 4,
            rgb_color_space,
            cg.kCGImageAlphaPremultipliedLast | cg.kCGBitmapByteOrder32Big,
            data_provider,
            null,
            false,
            cg.kCGRenderingIntentDefault,
        );
        
        std.debug.assert(cg_image != null);
        
        const cg_image_ptr = @intFromPtr(cg_image);
        std.debug.assert(cg_image_ptr != 0);
        if (cg_image_ptr < 0x1000) {
            std.debug.panic("createCGImageFromBuffer: cg_image pointer is suspiciously small: 0x{x}", .{cg_image_ptr});
        }
        
        std.debug.print("[window] Created CGImage at: 0x{x}\n", .{cg_image_ptr});
        return @ptrCast(cg_image);
    }
    
    fn releaseCGImage(cg_image: *anyopaque) void {
        const cg_image_ptr = @intFromPtr(cg_image);
        std.debug.assert(cg_image_ptr != 0);
        if (cg_image_ptr < 0x1000) {
            std.debug.panic("releaseCGImage: cg_image pointer is suspiciously small: 0x{x}", .{cg_image_ptr});
        }
        std.debug.print("[window] Releasing CGImage at: 0x{x}\n", .{cg_image_ptr});
        cg.CGImageRelease(@ptrCast(cg_image));
    }
    
    pub fn runEventLoop(self: *Self) void {
        // Assert precondition: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        std.debug.assert(self_ptr != 0);
        if (self_ptr < 0x1000) {
            std.debug.panic("Window.runEventLoop: self pointer is suspiciously small: 0x{x}", .{self_ptr});
        }
        
        // Assert precondition: app must be initialized.
        std.debug.assert(self.ns_app != null);
        const app = self.ns_app.?;
        
        // Assert: app pointer must be valid.
        const app_ptr = @intFromPtr(app);
        std.debug.assert(app_ptr != 0);
        if (app_ptr < 0x1000) {
            std.debug.panic("Window.runEventLoop: app pointer is suspiciously small: 0x{x}", .{app_ptr});
        }
        if (app_ptr % 8 != 0) {
            std.debug.panic("Window.runEventLoop: app pointer is not aligned: 0x{x}", .{app_ptr});
        }
        
        std.debug.print("[window] Running NSApplication event loop...\n", .{});
        
        // Run event loop.
        const runSel = c.sel_getUid("run");
        std.debug.assert(runSel != null);
        
        // Assert: selector pointer must be valid.
        const runSel_ptr = @intFromPtr(runSel);
        std.debug.assert(runSel_ptr != 0);
        
        cocoa.objc_msgSendVoid0(@ptrCast(app), runSel);
        
        std.debug.print("[window] NSApplication event loop exited.\n", .{});
    }
};
