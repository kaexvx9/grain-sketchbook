//! Grain Shine Compositor Interface
//!
//! Why: Implements compositor and surface management for Shine protocol.
//! Handles surface creation, buffer management, and frame callbacks
//! with proper bounds checking and Rye Style compliance.

const std = @import("std");
const protocol = @import("protocol.zig");
const ObjectId = protocol.ObjectId;
const ArgumentParser = protocol.ArgumentParser;
const MessageResult = protocol.MessageResult;

/// Why: Compositor interface for creating surfaces and regions.
/// Manages surface lifecycle and provides bounded resource allocation.
pub const CompositorInterface = struct {
    pub const CREATE_SURFACE_OPCODE: u16 = 0;
    pub const CREATE_REGION_OPCODE: u16 = 1;
    
    /// Why: Create surface request - allocates a new surface object.
    pub const CreateSurfaceRequest = struct {
        id: ObjectId,
        
        /// Why: Parse create surface request from message data.
        pub fn parse(parser: *ArgumentParser) !CreateSurfaceRequest {
            return CreateSurfaceRequest{
                .id = try parser.parseObjectId(),
            };
        }
    };
    
    /// Why: Create region request - allocates a new region object for clipping.
    pub const CreateRegionRequest = struct {
        id: ObjectId,
        
        /// Why: Parse create region request from message data.
        pub fn parse(parser: *ArgumentParser) !CreateRegionRequest {
            return CreateRegionRequest{
                .id = try parser.parseObjectId(),
            };
        }
    };
};

/// Why: Surface interface for content display and input handling.
/// Manages buffer attachment, damage tracking, and frame callbacks.
pub const SurfaceInterface = struct {
    pub const DESTROY_OPCODE: u16 = 0;
    pub const ATTACH_OPCODE: u16 = 1;
    pub const DAMAGE_OPCODE: u16 = 2;
    pub const FRAME_OPCODE: u16 = 3;
    pub const SET_OPAQUE_REGION_OPCODE: u16 = 4;
    pub const SET_INPUT_REGION_OPCODE: u16 = 5;
    pub const COMMIT_OPCODE: u16 = 6;
    pub const SET_BUFFER_TRANSFORM_OPCODE: u16 = 7;
    pub const SET_BUFFER_SCALE_OPCODE: u16 = 8;
    pub const DAMAGE_BUFFER_OPCODE: u16 = 9;
    
    /// Why: Attach buffer request - attach a buffer to the surface.
    pub const AttachRequest = struct {
        buffer: ?ObjectId,  // null means detach buffer
        x: i32,             // Buffer x offset
        y: i32,             // Buffer y offset
        
        /// Why: Parse attach request from message data with validation.
        pub fn parse(parser: *ArgumentParser) !AttachRequest {
            const buffer = try parser.parseObjectId();
            const x = try parser.parseInt();
            const y = try parser.parseInt();
            
            return AttachRequest{
                .buffer = if (buffer == 0) null else buffer,
                .x = x,
                .y = y,
            };
        }
    };
    
    /// Why: Damage request - mark surface area as damaged and needing redraw.
    pub const DamageRequest = struct {
        x: i32,
        y: i32,
        width: i32,
        height: i32,
        
        /// Why: Parse damage request with bounds validation.
        pub fn parse(parser: *ArgumentParser) !DamageRequest {
            const x = try parser.parseInt();
            const y = try parser.parseInt(); 
            const width = try parser.parseInt();
            const height = try parser.parseInt();
            
            // Why: Validate damage rectangle bounds.
            if (width < 0 or height < 0) return error.InvalidDamageSize;
            if (width > 8192 or height > 8192) return error.DamageTooLarge; // Reasonable surface size limit
            
            return DamageRequest{
                .x = x,
                .y = y,
                .width = width,
                .height = height,
            };
        }
    };
    
    /// Why: Frame callback request - client requests notification when frame is displayed.
    pub const FrameRequest = struct {
        callback: ObjectId,
        
        /// Why: Parse frame callback request.
        pub fn parse(parser: *ArgumentParser) !FrameRequest {
            return FrameRequest{
                .callback = try parser.parseObjectId(),
            };
        }
    };
    
    /// Why: Set buffer transform request - set buffer transformation.
    pub const SetBufferTransformRequest = struct {
        transform: u32,  // Transformation type
        
        /// Why: Parse buffer transform request with validation.
        pub fn parse(parser: *ArgumentParser) !SetBufferTransformRequest {
            const transform = try parser.parseUint();
            
            // Why: Validate transform value (0-7 are valid transforms).
            if (transform > 7) return error.InvalidTransform;
            
            return SetBufferTransformRequest{
                .transform = transform,
            };
        }
    };
    
    /// Why: Set buffer scale request - set buffer scaling factor.
    pub const SetBufferScaleRequest = struct {
        scale: i32,
        
        /// Why: Parse buffer scale request with validation.
        pub fn parse(parser: *ArgumentParser) !SetBufferScaleRequest {
            const scale = try parser.parseInt();
            
            // Why: Validate scale factor (must be positive and reasonable).
            if (scale <= 0) return error.InvalidScale;
            if (scale > 8) return error.ScaleTooLarge; // Reasonable limit
            
            return SetBufferScaleRequest{
                .scale = scale,
            };
        }
    };
};

/// Why: Surface implementation with bounded resource management.
/// Tracks surface state, buffers, and damage regions with proper cleanup.
pub const Surface = struct {
    const Self = @This();
    
    /// Why: Maximum number of pending frame callbacks per surface.
    const MAX_FRAME_CALLBACKS: u32 = 64;
    
    /// Why: Maximum damage regions per surface to prevent unbounded growth.
    const MAX_DAMAGE_REGIONS: u32 = 32;
    
    id: ObjectId,
    current_buffer: ?ObjectId,
    pending_buffer: ?ObjectId,
    buffer_x: i32,
    buffer_y: i32,
    buffer_transform: u32,
    buffer_scale: i32,
    frame_callbacks: std.ArrayList(ObjectId),
    damage_regions: std.ArrayList(DamageRegion),
    committed: bool,
    
    /// Why: Damage region for tracking surface changes.
    pub const DamageRegion = struct {
        x: i32,
        y: i32,
        width: i32,
        height: i32,
    };
    
    /// Why: Initialize surface with proper allocator and bounds.
    pub fn init(allocator: std.mem.Allocator, id: ObjectId) Self {
        return Self{
            .id = id,
            .current_buffer = null,
            .pending_buffer = null,
            .buffer_x = 0,
            .buffer_y = 0,
            .buffer_transform = 0,
            .buffer_scale = 1,
            .frame_callbacks = std.ArrayList(ObjectId).init(allocator),
            .damage_regions = std.ArrayList(DamageRegion).init(allocator),
            .committed = false,
        };
    }
    
    /// Why: Cleanup surface resources and free memory.
    pub fn deinit(self: *Self) void {
        self.frame_callbacks.deinit();
        self.damage_regions.deinit();
    }
    
    /// Why: Attach buffer to surface with validation.
    pub fn attach(self: *Self, buffer: ?ObjectId, x: i32, y: i32) !void {
        self.pending_buffer = buffer;
        self.buffer_x = x;
        self.buffer_y = y;
    }
    
    /// Why: Add damage region with bounds checking.
    pub fn addDamage(self: *Self, x: i32, y: i32, width: i32, height: i32) !void {
        if (self.damage_regions.items.len >= MAX_DAMAGE_REGIONS) {
            // Why: Remove oldest damage region to maintain bounds.
            _ = self.damage_regions.orderedRemove(0);
        }
        
        try self.damage_regions.append(DamageRegion{
            .x = x,
            .y = y,
            .width = width,
            .height = height,
        });
    }
    
    /// Why: Add frame callback with bounds checking.
    pub fn addFrameCallback(self: *Self, callback: ObjectId) !void {
        if (self.frame_callbacks.items.len >= MAX_FRAME_CALLBACKS) {
            return error.TooManyFrameCallbacks;
        }
        
        try self.frame_callbacks.append(callback);
    }
    
    /// Why: Commit pending surface state to current state.
    pub fn commit(self: *Self) void {
        self.current_buffer = self.pending_buffer;
        self.committed = true;
        
        // Why: Clear damage regions after commit.
        self.damage_regions.clearRetainingCapacity();
    }
    
    /// Why: Set buffer transformation with validation.
    pub fn setBufferTransform(self: *Self, transform: u32) !void {
        if (transform > 7) return error.InvalidTransform;
        self.buffer_transform = transform;
    }
    
    /// Why: Set buffer scale with validation.
    pub fn setBufferScale(self: *Self, scale: i32) !void {
        if (scale <= 0 or scale > 8) return error.InvalidScale;
        self.buffer_scale = scale;
    }
};