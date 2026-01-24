//! Basin Kernel: RISC-V Framebuffer Driver
//!
//! Why: Low-level framebuffer management for RISC-V hardware.
//! Provides direct memory-mapped display access with bounds checking and safety.
//!
//! Agent: Vantage 3 (Systems Implementation)

const std = @import("std");

/// Why: Framebuffer configuration for RISC-V display hardware.
pub const FramebufferConfig = struct {
    width: u32,
    height: u32,
    bpp: u32,  // Bits per pixel (typically 32)
    pitch: u32, // Bytes per scanline
    address: [*]u8, // Physical memory address
    
    /// Why: Validate framebuffer configuration parameters.
    pub fn validate(self: *const FramebufferConfig) !void {
        if (self.width == 0 or self.height == 0) return error.InvalidDimensions;
        if (self.width > 8192 or self.height > 8192) return error.DimensionsTooLarge;
        if (self.bpp != 32) return error.UnsupportedBPP; // Only 32-bit RGBA supported
        if (self.address == null) return error.InvalidAddress;
        
        // Why: Validate pitch calculation.
        const expected_pitch = self.width * (self.bpp / 8);
        if (self.pitch < expected_pitch) return error.InvalidPitch;
    }
    
    /// Why: Calculate total framebuffer size with bounds checking.
    pub fn getSize(self: *const FramebufferConfig) u64 {
        return @as(u64, self.pitch) * @as(u64, self.height);
    }
};

/// Why: RISC-V framebuffer driver with memory safety.
pub const Framebuffer = struct {
    const Self = @This();
    
    config: FramebufferConfig,
    is_initialized: bool,
    
    /// Why: Maximum framebuffer size to prevent memory exhaustion.
    pub const MAX_FRAMEBUFFER_SIZE: u64 = 32 * 1024 * 1024; // 32MB
    
    /// Why: Initialize framebuffer with validation.
    pub fn init(config: FramebufferConfig) !Self {
        try config.validate();
        
        const size = config.getSize();
        if (size > MAX_FRAMEBUFFER_SIZE) {
            return error.FramebufferTooLarge;
        }
        
        return Self{
            .config = config,
            .is_initialized = true,
        };
    }
    
    /// Why: Write pixel to framebuffer with bounds checking.
    pub fn writePixel(self: *const Self, x: u32, y: u32, color: u32) !void {
        if (!self.is_initialized) return error.NotInitialized;
        if (x >= self.config.width or y >= self.config.height) {
            return error.OutOfBounds;
        }
        
        const offset = (@as(u64, y) * @as(u64, self.config.pitch)) + 
                       (@as(u64, x) * 4); // 4 bytes per pixel (32-bit)
        
        if (offset + 4 > self.config.getSize()) {
            return error.OutOfBounds;
        }
        
        // Why: Write pixel color (RGBA format).
        const pixel_ptr = self.config.address + offset;
        @as(*u32, @ptrCast(pixel_ptr)).* = color;
    }
    
    /// Why: Clear entire framebuffer to specified color.
    pub fn clear(self: *const Self, color: u32) !void {
        if (!self.is_initialized) return error.NotInitialized;
        
        const size = self.config.getSize();
        var offset: u64 = 0;
        
        while (offset < size) {
            if (offset + 4 > size) break;
            @as(*u32, @ptrCast(self.config.address + offset)).* = color;
            offset += 4;
        }
    }
    
    /// Why: Get framebuffer dimensions for display configuration.
    pub fn getDimensions(self: *const Self) struct { width: u32, height: u32 } {
        return .{
            .width = self.config.width,
            .height = self.config.height,
        };
    }
    
    /// Why: Check if framebuffer is ready for use.
    pub fn isReady(self: *const Self) bool {
        return self.is_initialized;
    }
};

/// Why: QEMU RISC-V framebuffer initialization.
/// Sets up display for QEMU virt machine with VGA/display device.
pub fn initializeQEMUFramebuffer() !Framebuffer {
    // Why: QEMU virt machine default framebuffer configuration.
    // In real implementation, this would query hardware or use device tree.
    const qemu_config = FramebufferConfig{
        .width = 1920,
        .height = 1080,
        .bpp = 32,
        .pitch = 1920 * 4, // 4 bytes per pixel
        .address = @ptrFromInt(0x10000000), // QEMU virt framebuffer address
    };
    
    return Framebuffer.init(qemu_config);
}