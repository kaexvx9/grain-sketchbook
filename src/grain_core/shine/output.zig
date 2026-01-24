//! Grain Shine Output Interface
//!
//! Why: Implements output (monitor/display) management for Shine protocol.
//! Handles display information, modes, and geometry with proper bounds checking.

const std = @import("std");
const protocol = @import("protocol.zig");
const ObjectId = protocol.ObjectId;
const ArgumentParser = protocol.ArgumentParser;

/// Why: Output interface for display/monitor information.
/// Provides display geometry, modes, and scale information to clients.
pub const OutputInterface = struct {
    pub const RELEASE_OPCODE: u16 = 0;
    
    /// Why: Release request - client releases output object.
    pub const ReleaseRequest = struct {
        /// Why: Parse release request (no arguments).
        pub fn parse(_: *ArgumentParser) !ReleaseRequest {
            return ReleaseRequest{};
        }
    };
    
    /// Why: Geometry event - advertise output geometry to clients.
    pub const GeometryEvent = struct {
        x: i32,
        y: i32,
        physical_width: i32,   // mm
        physical_height: i32,  // mm
        subpixel: u32,
        make: []const u8,
        model: []const u8,
        transform: u32,
        
        /// Why: Serialize geometry event to wire format with bounds checking.
        pub fn serialize(self: GeometryEvent, buffer: []u8) !u32 {
            // Why: Calculate required size with alignment.
            const make_len = self.make.len;
            const model_len = self.model.len;
            const make_aligned = (make_len + 3) & ~@as(u32, 3);
            const model_aligned = (model_len + 3) & ~@as(u32, 3);
            const total_size = 32 + 4 + make_aligned + 4 + model_aligned + 4; // Fixed fields + strings
            
            if (buffer.len < total_size) return error.BufferTooSmall;
            
            var offset: u32 = 0;
            
            // Position
            std.mem.writeInt(i32, buffer[offset..offset + 4], self.x, .little);
            offset += 4;
            std.mem.writeInt(i32, buffer[offset..offset + 4], self.y, .little);
            offset += 4;
            
            // Physical dimensions
            std.mem.writeInt(i32, buffer[offset..offset + 4], self.physical_width, .little);
            offset += 4;
            std.mem.writeInt(i32, buffer[offset..offset + 4], self.physical_height, .little);
            offset += 4;
            
            // Subpixel
            std.mem.writeInt(u32, buffer[offset..offset + 4], self.subpixel, .little);
            offset += 4;
            
            // Make string
            std.mem.writeInt(u32, buffer[offset..offset + 4], @intCast(make_len), .little);
            offset += 4;
            @memcpy(buffer[offset..offset + make_len], self.make);
            offset += @intCast(make_len);
            while (offset & 3 != 0) {
                buffer[offset] = 0;
                offset += 1;
            }
            
            // Model string
            std.mem.writeInt(u32, buffer[offset..offset + 4], @intCast(model_len), .little);
            offset += 4;
            @memcpy(buffer[offset..offset + model_len], self.model);
            offset += @intCast(model_len);
            while (offset & 3 != 0) {
                buffer[offset] = 0;
                offset += 1;
            }
            
            // Transform
            std.mem.writeInt(u32, buffer[offset..offset + 4], self.transform, .little);
            offset += 4;
            
            return offset;
        }
    };
    
    /// Why: Mode event - advertise output mode to clients.
    pub const ModeEvent = struct {
        flags: u32,
        width: i32,
        height: i32,
        refresh: i32,  // mHz (millihertz)
        
        /// Why: Serialize mode event to wire format.
        pub fn serialize(self: ModeEvent, buffer: []u8) !u32 {
            if (buffer.len < 16) return error.BufferTooSmall;
            
            std.mem.writeInt(u32, buffer[0..4], self.flags, .little);
            std.mem.writeInt(i32, buffer[4..8], self.width, .little);
            std.mem.writeInt(i32, buffer[8..12], self.height, .little);
            std.mem.writeInt(i32, buffer[12..16], self.refresh, .little);
            
            return 16;
        }
    };
    
    /// Why: Done event - output configuration complete.
    pub const DoneEvent = struct {
        /// Why: Serialize done event (no arguments).
        pub fn serialize(buffer: []u8) !u32 {
            _ = buffer; // No data needed
            return 0;
        }
    };
    
    /// Why: Scale event - advertise output scale factor.
    pub const ScaleEvent = struct {
        factor: i32,
        
        /// Why: Serialize scale event to wire format.
        pub fn serialize(self: ScaleEvent, buffer: []u8) !u32 {
            if (buffer.len < 4) return error.BufferTooSmall;
            
            std.mem.writeInt(i32, buffer[0..4], self.factor, .little);
            return 4;
        }
    };
    
    /// Why: Name event - advertise output name/description.
    pub const NameEvent = struct {
        name: []const u8,
        
        /// Why: Serialize name event with bounds checking.
        pub fn serialize(self: NameEvent, buffer: []u8) !u32 {
            const name_len = self.name.len;
            const aligned_len = (name_len + 3) & ~@as(u32, 3);
            const total_size = 4 + aligned_len;
            
            if (buffer.len < total_size) return error.BufferTooSmall;
            
            std.mem.writeInt(u32, buffer[0..4], @intCast(name_len), .little);
            @memcpy(buffer[4..4 + name_len], self.name);
            
            var offset = 4 + name_len;
            while (offset & 3 != 0) {
                buffer[offset] = 0;
                offset += 1;
            }
            
            return @intCast(offset);
        }
    };
    
    /// Why: Description event - advertise output description.
    pub const DescriptionEvent = struct {
        description: []const u8,
        
        /// Why: Serialize description event with bounds checking.
        pub fn serialize(self: DescriptionEvent, buffer: []u8) !u32 {
            const desc_len = self.description.len;
            const aligned_len = (desc_len + 3) & ~@as(u32, 3);
            const total_size = 4 + aligned_len;
            
            if (buffer.len < total_size) return error.BufferTooSmall;
            
            std.mem.writeInt(u32, buffer[0..4], @intCast(desc_len), .little);
            @memcpy(buffer[4..4 + desc_len], self.description);
            
            var offset = 4 + desc_len;
            while (offset & 3 != 0) {
                buffer[offset] = 0;
                offset += 1;
            }
            
            return @intCast(offset);
        }
    };
};

/// Way: Output implementation for managing display information.
/// Tracks output state, modes, and provides event serialization.
pub const Output = struct {
    const Self = @This();
    
    /// Why: Maximum supported display modes per output.
    const MAX_MODES: u32 = 32;
    
    id: ObjectId,
    x: i32,
    y: i32,
    physical_width: i32,
    physical_height: i32,
    subpixel: u32,
    make: []const u8,
    model: []const u8,
    transform: u32,
    scale_factor: i32,
    modes: std.ArrayList(Mode),
    current_mode_index: ?u32,
    
    /// Why: Display mode information.
    pub const Mode = struct {
        flags: u32,
        width: i32,
        height: i32,
        refresh: i32,  // mHz
    };
    
    /// Why: Initialize output with proper allocator and validation.
    pub fn init(
        allocator: std.mem.Allocator,
        id: ObjectId,
        x: i32,
        y: i32,
        physical_width: i32,
        physical_height: i32,
        make: []const u8,
        model: []const u8,
    ) !Self {
        if (physical_width <= 0 or physical_height <= 0) {
            return error.InvalidPhysicalSize;
        }
        
        if (make.len == 0 or model.len == 0) {
            return error.EmptyMakeModel;
        }
        
        if (make.len > 128 or model.len > 128) {
            return error.MakeModelTooLong;
        }
        
        return Self{
            .id = id,
            .x = x,
            .y = y,
            .physical_width = physical_width,
            .physical_height = physical_height,
            .subpixel = 0,  // Unknown subpixel
            .make = make,
            .model = model,
            .transform = 0, // Normal transform
            .scale_factor = 1,
            .modes = std.ArrayList(Mode).init(allocator),
            .current_mode_index = null,
        };
    }
    
    /// Why: Cleanup output resources.
    pub fn deinit(self: *Self) void {
        self.modes.deinit();
    }
    
    /// Why: Add display mode with bounds checking.
    pub fn addMode(self: *Self, flags: u32, width: i32, height: i32, refresh: i32) !void {
        if (self.modes.items.len >= MAX_MODES) {
            return error.TooManyModes;
        }
        
        if (width <= 0 or height <= 0 or refresh <= 0) {
            return error.InvalidModeParameters;
        }
        
        try self.modes.append(Mode{
            .flags = flags,
            .width = width,
            .height = height,
            .refresh = refresh,
        });
    }
    
    /// Why: Set current display mode by index.
    pub fn setCurrentMode(self: *Self, mode_index: u32) !void {
        if (mode_index >= self.modes.items.len) {
            return error.InvalidModeIndex;
        }
        
        self.current_mode_index = mode_index;
    }
    
    /// Why: Set output scale factor with validation.
    pub fn setScaleFactor(self: *Self, factor: i32) !void {
        if (factor <= 0 or factor > 8) {
            return error.InvalidScaleFactor;
        }
        
        self.scale_factor = factor;
    }
};