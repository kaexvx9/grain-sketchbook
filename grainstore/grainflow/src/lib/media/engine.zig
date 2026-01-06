//! Grainflow Media Engine: Core media processing API.
//! Why: Native Zig rewrite of ffmpeg functionality in Grain Style.
//! Architecture: Bounded allocations, explicit types, deterministic execution.
//!
//! GrainStyle compliance:
//! - grain_case function names
//! - u32/u64 types (not usize/isize)
//! - MAX_ constants for bounded allocations
//! - Assertions for preconditions/postconditions
//! - No recursion (iterative algorithms, stack-based)

const std = @import("std");
// TODO: Add zigimg when available
// const zigimg = @import("zigimg");

/// Grainflow Media Engine: Main API for media processing.
pub const GrainflowEngine = struct {
    allocator: std.mem.Allocator,

    // Bounded: Max image width (explicit limit)
    pub const MAX_IMAGE_WIDTH: u32 = 32768;

    // Bounded: Max image height (explicit limit)
    pub const MAX_IMAGE_HEIGHT: u32 = 32768;

    // Bounded: Max image size in bytes (explicit limit)
    pub const MAX_IMAGE_SIZE: u32 = 100 * 1024 * 1024; // 100 MB

    // Bounded: Max filter count per image (explicit limit)
    pub const MAX_FILTER_COUNT: u32 = 64;

    // Bounded: Max path length (explicit limit)
    pub const MAX_PATH_LEN: u32 = 4096;

    /// Image format enumeration.
    pub const ImageFormat = enum(u8) {
        png,
        jpeg,
        webp,
        avif,
        bmp,
        tiff,
        unknown,
    };

    /// Image structure: Represents a decoded image.
    pub const Image = struct {
        width: u32,
        height: u32,
        format: ImageFormat,
        pixels: []u8, // RGBA pixel data (width * height * 4 bytes)
        allocator: std.mem.Allocator,

        /// Deinitialize image and free pixel data.
        pub fn deinit(self: *Image) void {
            // Assert: Image must be valid
            std.debug.assert(self.pixels.len > 0);
            std.debug.assert(self.allocator.ptr != null);

            self.allocator.free(self.pixels);
        }
    };

    /// Initialize Grainflow engine.
    pub fn init(allocator: std.mem.Allocator) GrainflowEngine {
        // Assert: Allocator must be valid
        std.debug.assert(allocator.ptr != null);

        return GrainflowEngine{
            .allocator = allocator,
        };
    }

    /// Load image from file path.
    pub fn load_image(
        self: *GrainflowEngine,
        path: []const u8,
    ) !Image {
        // Assert: Path must be non-empty and within bounds
        std.debug.assert(path.len > 0);
        std.debug.assert(path.len <= MAX_PATH_LEN);

        // Read file into memory
        const file = try std.fs.cwd().openFile(path, .{});
        defer file.close();

        const file_size = try file.getEndPos();
        std.debug.assert(file_size <= MAX_IMAGE_SIZE);

        const file_data = try self.allocator.alloc(u8, file_size);
        defer self.allocator.free(file_data);

        const bytes_read = try file.readAll(file_data);
        std.debug.assert(bytes_read == file_size);

        // Load from memory
        return self.load_image_from_memory(file_data);
    }

    /// Load image from memory buffer.
    pub fn load_image_from_memory(
        self: *GrainflowEngine,
        data: []const u8,
    ) !Image {
        // Assert: Data must be non-empty and within bounds
        std.debug.assert(data.len > 0);
        std.debug.assert(data.len <= MAX_IMAGE_SIZE);

        // Detect format
        const format = detect_format(data);
        if (format == .unknown) {
            return error.UnknownImageFormat;
        }

        // TODO: Load using zigimg when available
        // For now, return error (zigimg not available)
        // const zigimg_image = try zigimg.Image.fromMemory(
        //     self.allocator,
        //     data,
        // );
        // defer zigimg_image.deinit(self.allocator);
        //
        // const width: u32 = @intCast(zigimg_image.width);
        // const height: u32 = @intCast(zigimg_image.height);
        //
        // std.debug.assert(width > 0);
        // std.debug.assert(height > 0);
        // std.debug.assert(width <= MAX_IMAGE_WIDTH);
        // std.debug.assert(height <= MAX_IMAGE_HEIGHT);
        //
        // const pixel_count: u32 = width * height;
        // const pixel_buffer_size: u32 = pixel_count * 4;
        // const pixels = try self.allocator.alloc(u8, pixel_buffer_size);
        //
        // try convert_to_rgba(zigimg_image, pixels, width, height);
        
        return error.ZigimgNotAvailable;

        return Image{
            .width = width,
            .height = height,
            .format = format,
            .pixels = pixels,
            .allocator = self.allocator,
        };
    }

    /// Save image to file path.
    pub fn save_image(
        self: *GrainflowEngine,
        image: *Image,
        format: ImageFormat,
        path: []const u8,
    ) !void {
        // Assert: Image and path must be valid
        std.debug.assert(image.width > 0);
        std.debug.assert(image.height > 0);
        std.debug.assert(image.width <= MAX_IMAGE_WIDTH);
        std.debug.assert(image.height <= MAX_IMAGE_HEIGHT);
        std.debug.assert(path.len > 0);
        std.debug.assert(path.len <= MAX_PATH_LEN);

        // TODO: Implement image saving
        // For now, return error (placeholder)
        _ = self;
        _ = format;
        return error.NotImplemented;
    }

    /// Crop image to specified rectangle.
    pub fn crop_image(
        self: *GrainflowEngine,
        image: *Image,
        x: u32,
        y: u32,
        width: u32,
        height: u32,
    ) !Image {
        // Assert: Crop bounds must be valid
        std.debug.assert(x + width <= image.width);
        std.debug.assert(y + height <= image.height);
        std.debug.assert(width > 0);
        std.debug.assert(height > 0);
        std.debug.assert(width <= MAX_IMAGE_WIDTH);
        std.debug.assert(height <= MAX_IMAGE_HEIGHT);

        // Allocate cropped pixel buffer
        const pixel_count: u32 = width * height;
        const pixel_buffer_size: u32 = pixel_count * 4; // RGBA = 4 bytes
        const pixels = try self.allocator.alloc(u8, pixel_buffer_size);

        // Copy cropped region
        var dest_y: u32 = 0;
        while (dest_y < height) : (dest_y += 1) {
            const src_y: u32 = y + dest_y;
            var dest_x: u32 = 0;
            while (dest_x < width) : (dest_x += 1) {
                const src_x: u32 = x + dest_x;

                // Source pixel index
                const src_idx: u32 = (src_y * image.width + src_x) * 4;

                // Destination pixel index
                const dest_idx: u32 = (dest_y * width + dest_x) * 4;

                // Copy RGBA pixel
                pixels[dest_idx + 0] = image.pixels[src_idx + 0]; // R
                pixels[dest_idx + 1] = image.pixels[src_idx + 1]; // G
                pixels[dest_idx + 2] = image.pixels[src_idx + 2]; // B
                pixels[dest_idx + 3] = image.pixels[src_idx + 3]; // A
            }
        }

        return Image{
            .width = width,
            .height = height,
            .format = image.format,
            .pixels = pixels,
            .allocator = self.allocator,
        };
    }

    /// Resize image to specified dimensions.
    pub fn resize_image(
        self: *GrainflowEngine,
        image: *Image,
        width: u32,
        height: u32,
    ) !Image {
        // Assert: Dimensions must be valid
        std.debug.assert(width > 0);
        std.debug.assert(height > 0);
        std.debug.assert(width <= MAX_IMAGE_WIDTH);
        std.debug.assert(height <= MAX_IMAGE_HEIGHT);

        // TODO: Implement image resizing
        // For now, return error (placeholder)
        _ = self;
        return error.NotImplemented;
    }
};

/// Detect image format from magic bytes.
pub fn detect_format(data: []const u8) ImageFormat {
    // Assert: Data must be non-empty
    std.debug.assert(data.len > 0);

    // PNG: 89 50 4E 47 0D 0A 1A 0A
    if (data.len >= 8 and
        data[0] == 0x89 and
        data[1] == 0x50 and
        data[2] == 0x4E and
        data[3] == 0x47)
    {
        return .png;
    }

    // JPEG: FF D8 FF
    if (data.len >= 3 and
        data[0] == 0xFF and
        data[1] == 0xD8 and
        data[2] == 0xFF)
    {
        return .jpeg;
    }

    // WebP: RIFF ... WEBP
    if (data.len >= 12 and
        std.mem.eql(u8, data[0..4], "RIFF") and
        std.mem.eql(u8, data[8..12], "WEBP"))
    {
        return .webp;
    }

    // BMP: BM
    if (data.len >= 2 and data[0] == 0x42 and data[1] == 0x4D) {
        return .bmp;
    }

    // TIFF: II* or MM*
    if (data.len >= 4 and
        ((data[0] == 0x49 and data[1] == 0x49 and data[2] == 0x2A and data[3] == 0x00) or
         (data[0] == 0x4D and data[1] == 0x4D and data[2] == 0x00 and data[3] == 0x2A)))
    {
        return .tiff;
    }

    // TODO: Add AVIF detection
    return .unknown;
}

// TODO: Convert zigimg image to RGBA pixel buffer (when zigimg available)
// fn convert_to_rgba(
//     img: zigimg.Image,
//     pixels: []u8,
//     width: u32,
//     height: u32,
// ) !void {
//     // Implementation will be added when zigimg is available
// }

