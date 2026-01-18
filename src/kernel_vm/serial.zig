const std = @import("std");

/// Serial I/O buffers for kernel console.
/// Grain Style: Static allocation, deterministic I/O.
/// ~<~ Glow Waterbend: Serial I/O flows deterministically.

/// Serial buffer size (64KB static allocation).
/// Why: Static allocation eliminates allocator dependency.
const SERIAL_BUFFER_SIZE: usize = 64 * 1024;

/// Serial input buffer size (4KB for keyboard input).
/// Why: Keyboard input is typically much smaller than output.
const SERIAL_INPUT_BUFFER_SIZE: usize = 4 * 1024;

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
    /// Why: Handle kernel serial writes (e.g., printf output via SBI_CONSOLE_PUTCHAR).
    /// Grain Style: Comprehensive assertions for buffer management and circular buffer wrapping.
    pub fn writeByte(self: *Self, byte: u8) void {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        std.debug.assert(self_ptr != 0);
        std.debug.assert(self_ptr % @alignOf(Self) == 0);
        
        // Assert: buffer must be initialized (non-empty).
        std.debug.assert(self.buffer.len == SERIAL_BUFFER_SIZE);
        std.debug.assert(self.buffer.len > 0);
        
        // Assert: write position must be within buffer bounds.
        std.debug.assert(self.write_pos < SERIAL_BUFFER_SIZE);
        
        // Assert: total_written must be valid (non-negative, can wrap).
        // Note: total_written can wrap (usize overflow), but that's OK for counting.
        
        // Store old write position for validation.
        const old_write_pos = self.write_pos;
        const old_total_written = self.total_written;
        
        // Write byte to buffer (circular buffer).
        self.buffer[self.write_pos] = byte;
        self.write_pos = (self.write_pos + 1) % SERIAL_BUFFER_SIZE;
        self.total_written += 1;
        
        // Assert: byte must be written correctly.
        std.debug.assert(self.buffer[old_write_pos] == byte);
        
        // Assert: write position must wrap correctly.
        std.debug.assert(self.write_pos < SERIAL_BUFFER_SIZE);
        
        // Assert: write position must advance (or wrap).
        if (old_write_pos < SERIAL_BUFFER_SIZE - 1) {
            std.debug.assert(self.write_pos == old_write_pos + 1);
        } else {
            // Wrapped: write_pos should be 0.
            std.debug.assert(self.write_pos == 0);
        }
        
        // Assert: total_written must increment.
        std.debug.assert(self.total_written == old_total_written + 1);
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

/// Serial input handler.
/// Why: Buffer keyboard input for kernel console (SBI_CONSOLE_GETCHAR).
pub const SerialInput = struct {
    /// Input buffer (circular buffer).
    buffer: [SERIAL_INPUT_BUFFER_SIZE]u8 = [_]u8{0} ** SERIAL_INPUT_BUFFER_SIZE,
    /// Write position (producer side - host input).
    write_pos: usize = 0,
    /// Read position (consumer side - kernel getchar).
    read_pos: usize = 0,
    /// Number of bytes available to read.
    available: usize = 0,

    const Self = @This();

    /// Add byte to input buffer (from host keyboard).
    /// Why: Host pushes keyboard input for kernel to read via getchar.
    /// Returns: true if byte was added, false if buffer full.
    pub fn push(self: *Self, byte: u8) bool {
        // Assert: positions must be valid.
        std.debug.assert(self.write_pos < SERIAL_INPUT_BUFFER_SIZE);
        std.debug.assert(self.read_pos < SERIAL_INPUT_BUFFER_SIZE);
        std.debug.assert(self.available <= SERIAL_INPUT_BUFFER_SIZE);

        // Check if buffer is full.
        if (self.available >= SERIAL_INPUT_BUFFER_SIZE) {
            return false;
        }

        // Write byte to buffer.
        self.buffer[self.write_pos] = byte;
        self.write_pos = (self.write_pos + 1) % SERIAL_INPUT_BUFFER_SIZE;
        self.available += 1;

        // Assert: available count must be valid.
        std.debug.assert(self.available <= SERIAL_INPUT_BUFFER_SIZE);
        return true;
    }

    /// Read byte from input buffer (kernel getchar).
    /// Why: Kernel reads keyboard input via SBI_CONSOLE_GETCHAR.
    /// Returns: byte if available, null if buffer empty.
    pub fn pop(self: *Self) ?u8 {
        // Assert: positions must be valid.
        std.debug.assert(self.write_pos < SERIAL_INPUT_BUFFER_SIZE);
        std.debug.assert(self.read_pos < SERIAL_INPUT_BUFFER_SIZE);
        std.debug.assert(self.available <= SERIAL_INPUT_BUFFER_SIZE);

        // Check if buffer is empty.
        if (self.available == 0) {
            return null;
        }

        // Read byte from buffer.
        const byte = self.buffer[self.read_pos];
        self.read_pos = (self.read_pos + 1) % SERIAL_INPUT_BUFFER_SIZE;
        self.available -= 1;

        // Assert: available count must be valid.
        std.debug.assert(self.available < SERIAL_INPUT_BUFFER_SIZE);
        return byte;
    }

    /// Push string to input buffer.
    /// Why: Convenience for pushing command strings.
    /// Returns: number of bytes pushed.
    pub fn pushString(self: *Self, str: []const u8) usize {
        var pushed: usize = 0;
        for (str) |byte| {
            if (self.push(byte)) {
                pushed += 1;
            } else {
                break;
            }
        }
        return pushed;
    }

    /// Check if input is available.
    pub fn hasInput(self: *const Self) bool {
        return self.available > 0;
    }

    /// Clear input buffer.
    pub fn clear(self: *Self) void {
        @memset(&self.buffer, 0);
        self.write_pos = 0;
        self.read_pos = 0;
        self.available = 0;
    }
};

