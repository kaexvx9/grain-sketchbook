//! Grain Shine Client Management
//!
//! Why: Manages connected clients and their objects for Shine compositor.
//! Provides bounded client tracking, object lifecycle, and connection management
//! with proper cleanup and resource limits.

const std = @import("std");
const protocol = @import("protocol.zig");
const registry = @import("registry.zig");
const compositor = @import("compositor.zig");
const output = @import("output.zig");

const ObjectId = protocol.ObjectId;
const MAX_CLIENTS = protocol.MAX_CLIENTS;
const MAX_OBJECTS_PER_CLIENT = protocol.MAX_OBJECTS_PER_CLIENT;
const Registry = registry.Registry;
const Surface = compositor.Surface;
const Output = output.Output;

/// Why: Client connection state for tracking lifecycle.
pub const ClientState = enum {
    connecting,    // Initial connection phase
    connected,     // Fully connected and operational
    disconnecting, // Graceful disconnection in progress
    disconnected,  // Connection terminated
};

/// Why: Object types managed by client for proper cleanup.
pub const ObjectType = enum {
    display,
    registry,
    compositor,
    surface,
    output,
    seat,
    callback,
    region,
    unknown,
};

/// Why: Object entry for client object tracking.
pub const Object = struct {
    id: ObjectId,
    object_type: ObjectType,
    interface_name: []const u8,
    version: u32,
    active: bool,
    
    /// Why: Initialize object with validation.
    pub fn init(id: ObjectId, object_type: ObjectType, interface_name: []const u8, version: u32) Object {
        return Object{
            .id = id,
            .object_type = object_type,
            .interface_name = interface_name,
            .version = version,
            .active = true,
        };
    }
};

/// Why: Client implementation for managing connection and objects.
/// Provides bounded resource tracking and proper lifecycle management.
pub const Client = struct {
    const Self = @This();
    
    id: u32,
    state: ClientState,
    allocator: std.mem.Allocator,
    objects: std.ArrayList(Object),
    surfaces: std.ArrayList(Surface),
    next_object_id: ObjectId,
    
    /// Why: Initialize client with proper allocator and bounds.
    pub fn init(allocator: std.mem.Allocator, id: u32) Self {
        return Self{
            .id = id,
            .state = .connecting,
            .allocator = allocator,
            .objects = std.ArrayList(Object).init(allocator),
            .surfaces = std.ArrayList(Surface).init(allocator),
            .next_object_id = 2, // 1 is reserved for display
        };
    }
    
    /// Why: Cleanup client resources and free all memory.
    pub fn deinit(self: *Self) void {
        // Why: Clean up all surfaces first.
        for (self.surfaces.items) |*surface| {
            surface.deinit();
        }
        self.surfaces.deinit();
        self.objects.deinit();
    }
    
    /// Why: Add object to client with bounds checking.
    pub fn addObject(self: *Self, object_type: ObjectType, interface_name: []const u8, version: u32) !ObjectId {
        if (self.objects.items.len >= MAX_OBJECTS_PER_CLIENT) {
            return error.TooManyObjects;
        }
        
        const id = self.next_object_id;
        self.next_object_id += 1;
        
        try self.objects.append(Object.init(id, object_type, interface_name, version));
        return id;
    }
    
    /// Why: Remove object from client by ID.
    /// Returns true if found and removed, false otherwise.
    pub fn removeObject(self: *Self, object_id: ObjectId) bool {
        for (self.objects.items, 0..) |*obj, i| {
            if (obj.id == object_id and obj.active) {
                obj.active = false;
                
                // Why: If it's a surface, also remove from surfaces list.
                if (obj.object_type == .surface) {
                    self.removeSurface(object_id);
                }
                
                return true;
            }
        }
        return false;
    }
    
    /// Why: Find object by ID for request processing.
    pub fn findObject(self: *const Self, object_id: ObjectId) ?Object {
        for (self.objects.items) |obj| {
            if (obj.id == object_id and obj.active) {
                return obj;
            }
        }
        return null;
    }
    
    /// Why: Add surface with bounds checking.
    pub fn addSurface(self: *Self, surface_id: ObjectId) !void {
        if (self.surfaces.items.len >= 128) { // Reasonable surface limit per client
            return error.TooManySurfaces;
        }
        
        const surface = Surface.init(self.allocator, surface_id);
        try self.surfaces.append(surface);
    }
    
    /// Why: Remove surface by ID.
    fn removeSurface(self: *Self, surface_id: ObjectId) void {
        for (self.surfaces.items, 0..) |*surface, i| {
            if (surface.id == surface_id) {
                surface.deinit();
                _ = self.surfaces.swapRemove(i);
                break;
            }
        }
    }
    
    /// Why: Find surface by ID for request processing.
    pub fn findSurface(self: *Self, surface_id: ObjectId) ?*Surface {
        for (self.surfaces.items) |*surface| {
            if (surface.id == surface_id) {
                return surface;
            }
        }
        return null;
    }
    
    /// Why: Mark client as connected and ready for requests.
    pub fn setConnected(self: *Self) void {
        self.state = .connected;
    }
    
    /// Why: Begin graceful disconnection process.
    pub fn disconnect(self: *Self) void {
        self.state = .disconnecting;
        
        // Why: Mark all objects as inactive.
        for (self.objects.items) |*obj| {
            obj.active = false;
        }
    }
    
    /// Why: Check if client is in active state for request processing.
    pub fn isActive(self: *const Self) bool {
        return self.state == .connected;
    }
    
    /// Why: Get count of active objects for debugging and monitoring.
    pub fn getObjectCount(self: *const Self) u32 {
        var count: u32 = 0;
        for (self.objects.items) |obj| {
            if (obj.active) count += 1;
        }
        return count;
    }
    
    /// Why: Get count of active surfaces for debugging and monitoring.
    pub fn getSurfaceCount(self: *const Self) u32 {
        return @intCast(self.surfaces.items.len);
    }
};