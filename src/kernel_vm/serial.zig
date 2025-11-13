const std = @import("std");

/// Serial output buffer for kernel printf/debug output.
/// Tiger Style: Static allocation, deterministic output.
/// ~<~ Glow Waterbend: Serial output flows deterministically.

/// Serial output buffer (64KB static allocation).
/// Why: Static allocation eliminates allocator dependency.
const SERIAL_BUFFER_SIZE: usize = 64 * 1024;

/// Serial output handler.
/// Why: Capture kernel serial output for display in VM pane.
pub const SerialOutput = struct {
    /// Output buffer (circular buffer).
    buffer: [SERIAL_BUFFER_SIZE]u8 = [_]u8{0} ** SERIAL_BUFFER_SIZE,
    /// Write position (circular buffer head).
    write_pos: usize = 0,
    /// Read position (circular buffer tail, for display).
    read_pos: usize = 0,
    /// Total bytes written (for overflow detection).
    total_written: usize = 0,

    const Self = @This();

    /// Write byte to serial output.
    /// Why: Handle kernel serial writes (e.g., printf output).
    pub fn writeByte(self: *Self, byte: u8) void {
        // Assert: write position must be within buffer bounds.
        std.debug.assert(self.write_pos < SERIAL_BUFFER_SIZE);
        
        // Write byte to buffer (circular buffer).
        self.buffer[self.write_pos] = byte;
        self.write_pos = (self.write_pos + 1) % SERIAL_BUFFER_SIZE;
        self.total_written += 1;
        
        // Assert: write position must wrap correctly.
        std.debug.assert(self.write_pos < SERIAL_BUFFER_SIZE);
    }

    /// Write string to serial output.
    /// Why: Handle kernel string output (e.g., printf format strings).
    pub fn writeString(self: *Self, str: []const u8) void {
        // Assert: string must be non-empty.
        std.debug.assert(str.len > 0);
        
        for (str) |byte| {
            self.writeByte(byte);
        }
    }

    /// Get serial output as string (for display).
    /// Why: Return serial output for rendering in VM pane.
    pub fn get_output(self: *const Self) []const u8 {
        // Return entire buffer (circular buffer, may contain old data).
        // Future: Implement proper circular buffer reading.
        return &self.buffer;
    }

    /// Clear serial output buffer.
    /// Why: Reset output for clean display.
    pub fn clear(self: *Self) void {
        @memset(&self.buffer, 0);
        self.write_pos = 0;
        self.read_pos = 0;
        self.total_written = 0;
        
        // Assert: buffer must be cleared.
        std.debug.assert(self.buffer[0] == 0);
        std.debug.assert(self.write_pos == 0);
        std.debug.assert(self.read_pos == 0);
    }
};

