//! Grain Shine: Core structures for display protocol.
//!
//! Why: Implement Grain Shine display protocol for window management and compositing.
//! Wayland wire-format compatible with Rye Style bounds and safety constraints.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");

// Bounded: Max number of Shine objects per client.
pub const MAX_OBJECTS_PER_CLIENT: u32 = 1024;

// Bounded: Max number of clients connected.
pub const MAX_CLIENTS: u32 = 64;

// Bounded: Max surface width/height (in pixels).
pub const MAX_SURFACE_WIDTH: u32 = 8192;
pub const MAX_SURFACE_HEIGHT: u32 = 8192;

// Bounded: Max message size in bytes (wire format limit: 16-bit size field).
pub const MAX_MESSAGE_SIZE: u32 = 65535;

// Bounded: Max string length in bytes (64KB, reasonable for protocol strings).
pub const MAX_STRING_LENGTH: u32 = 65536;

// Bounded: Max array size in bytes (64KB, matches message size limit).
pub const MAX_ARRAY_SIZE: u32 = 65536;

// Bounded: Max file descriptors per message (reasonable limit).
pub const MAX_FDS_PER_MESSAGE: u32 = 8;

// Shine object ID type (32-bit unsigned integer).
pub const ObjectId = u32;

// Shine message header structure (wire format).
pub const MessageHeader = struct {
    object_id: ObjectId,
    opcode: u16,
    size: u16,
    
    /// Why: Parse message header from raw bytes with bounds checking.
    /// Validates header format and size constraints.
    pub fn parse(data: []const u8) !MessageHeader {
        std.debug.assert(data.len >= 8); // Header is 8 bytes minimum
        if (data.len < 8) return error.InvalidMessage;
        
        const object_id = std.mem.readInt(u32, data[0..4], .little);
        const size_and_opcode = std.mem.readInt(u32, data[4..8], .little);
        
        const size: u16 = @intCast((size_and_opcode >> 16) & 0xFFFF);
        const opcode: u16 = @intCast(size_and_opcode & 0xFFFF);
        
        // Why: Validate message size against bounds.
        if (size > MAX_MESSAGE_SIZE) return error.MessageTooLarge;
        if (size < 8) return error.MessageTooSmall;
        
        return MessageHeader{
            .object_id = object_id,
            .opcode = opcode,
            .size = size,
        };
    }
    
    /// Why: Validate message header constraints.
    pub fn validate(self: MessageHeader) !void {
        std.debug.assert(self.size >= 8);
        std.debug.assert(self.size <= MAX_MESSAGE_SIZE);
        if (self.size < 8) return error.MessageTooSmall;
        if (self.size > MAX_MESSAGE_SIZE) return error.MessageTooLarge;
        if (self.object_id == 0) return error.InvalidObjectId;
    }
};

// Shine interface name (bounded string).
pub const InterfaceName = struct {
    data: [64]u8,
    len: u32,

    pub fn init(name: []const u8) InterfaceName {
        std.debug.assert(name.len > 0);
        std.debug.assert(name.len <= 64);
        var result = InterfaceName{
            .data = undefined,
            .len = @intCast(name.len),
        };
        var i: u32 = 0;
        while (i < 64) : (i += 1) {
            result.data[i] = 0;
        }
        i = 0;
        while (i < name.len) : (i += 1) {
            result.data[i] = name[i];
        }
        std.debug.assert(result.len <= 64);
        return result;
    }

    pub fn as_slice(self: *const InterfaceName) []const u8 {
        return self.data[0..self.len];
    }
};

// Shine object: base structure for all Shine objects.
pub const Object = struct {
    id: ObjectId,
    interface: InterfaceName,
    version: u32,

    pub fn init(id: ObjectId, interface: InterfaceName, version: u32) Object {
        std.debug.assert(id > 0);
        std.debug.assert(version > 0);
        std.debug.assert(version <= 10);
        const obj = Object{
            .id = id,
            .interface = interface,
            .version = version,
        };
        std.debug.assert(obj.id > 0);
        return obj;
    }
};

// Surface: represents a drawable area (window content).
pub const Surface = struct {
    object: Object,
    width: u32,
    height: u32,
    buffer: ?[]u8,

    pub fn init(id: ObjectId, width: u32, height: u32) Surface {
        std.debug.assert(id > 0);
        std.debug.assert(width > 0);
        std.debug.assert(width <= MAX_SURFACE_WIDTH);
        std.debug.assert(height > 0);
        std.debug.assert(height <= MAX_SURFACE_HEIGHT);
        const surface = Surface{
            .object = Object.init(id, InterfaceName.init("shine_surface"), 4),
            .width = width,
            .height = height,
            .buffer = null,
        };
        std.debug.assert(surface.width > 0);
        std.debug.assert(surface.height > 0);
        return surface;
    }
};

// Output: represents a display/monitor.
pub const Output = struct {
    object: Object,
    width: u32,
    height: u32,
    physical_width: u32,
    physical_height: u32,

    pub fn init(
        id: ObjectId,
        width: u32,
        height: u32,
        physical_width: u32,
        physical_height: u32,
    ) Output {
        std.debug.assert(id > 0);
        std.debug.assert(width > 0);
        std.debug.assert(height > 0);
        const output = Output{
            .object = Object.init(id, InterfaceName.init("shine_output"), 4),
            .width = width,
            .height = height,
            .physical_width = physical_width,
            .physical_height = physical_height,
        };
        std.debug.assert(output.width > 0);
        std.debug.assert(output.height > 0);
        return output;
    }
};

// Seat: represents input devices (keyboard, mouse, touch).
pub const Seat = struct {
    object: Object,
    has_keyboard: bool,
    has_pointer: bool,
    has_touch: bool,

    pub fn init(id: ObjectId) Seat {
        std.debug.assert(id > 0);
        const seat = Seat{
            .object = Object.init(id, InterfaceName.init("shine_seat"), 7),
            .has_keyboard = true,
            .has_pointer = true,
            .has_touch = false,
        };
        std.debug.assert(seat.object.id > 0);
        return seat;
    }
};

// Registry: global object registry for Shine protocol.
pub const Registry = struct {
    object: Object,
    objects: [MAX_OBJECTS_PER_CLIENT]Object,
    objects_len: u32,

    pub fn init(id: ObjectId) Registry {
        std.debug.assert(id > 0);
        var registry = Registry{
            .object = Object.init(id, InterfaceName.init("shine_registry"), 1),
            .objects = undefined,
            .objects_len = 0,
        };
        var i: u32 = 0;
        while (i < MAX_OBJECTS_PER_CLIENT) : (i += 1) {
            registry.objects[i] = Object.init(0, InterfaceName.init(""), 0);
        }
        std.debug.assert(registry.object.id > 0);
        return registry;
    }

    pub fn bind(
        self: *Registry,
        name: u32,
        interface: InterfaceName,
        version: u32,
    ) !ObjectId {
        std.debug.assert(name > 0);
        std.debug.assert(version > 0);
        std.debug.assert(self.objects_len < MAX_OBJECTS_PER_CLIENT);
        const new_id: ObjectId = self.objects_len + 1;
        self.objects[self.objects_len] = Object.init(new_id, interface, version);
        self.objects_len += 1;
        std.debug.assert(self.objects_len <= MAX_OBJECTS_PER_CLIENT);
        return new_id;
    }
};

