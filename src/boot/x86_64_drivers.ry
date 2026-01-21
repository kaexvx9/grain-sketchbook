//! x86_64 Hardware Drivers for Basin Kernel
//! Why: Interface with Framework laptop hardware.
//! Grain Style: Explicit types, static allocation, comprehensive assertions.

const std = @import("std");

/// I/O Port Operations.
/// Why: x86 uses port I/O for legacy hardware.
pub const Port = struct {
    /// Read byte from I/O port.
    pub inline fn inb(port: u16) u8 {
        return asm volatile ("inb %[port], %[ret]"
            : [ret] "={al}" (-> u8),
            : [port] "N{dx}" (port),
        );
    }

    /// Write byte to I/O port.
    pub inline fn outb(port: u16, value: u8) void {
        asm volatile ("outb %[value], %[port]"
            :
            : [value] "{al}" (value),
              [port] "N{dx}" (port),
        );
    }

    /// Read word from I/O port.
    pub inline fn inw(port: u16) u16 {
        return asm volatile ("inw %[port], %[ret]"
            : [ret] "={ax}" (-> u16),
            : [port] "N{dx}" (port),
        );
    }

    /// Write word to I/O port.
    pub inline fn outw(port: u16, value: u16) void {
        asm volatile ("outw %[value], %[port]"
            :
            : [value] "{ax}" (value),
              [port] "N{dx}" (port),
        );
    }

    /// Read dword from I/O port.
    pub inline fn inl(port: u16) u32 {
        return asm volatile ("inl %[port], %[ret]"
            : [ret] "={eax}" (-> u32),
            : [port] "N{dx}" (port),
        );
    }

    /// Write dword to I/O port.
    pub inline fn outl(port: u16, value: u32) void {
        asm volatile ("outl %[value], %[port]"
            :
            : [value] "{eax}" (value),
              [port] "N{dx}" (port),
        );
    }

    /// I/O wait (short delay).
    pub inline fn io_wait() void {
        outb(0x80, 0);
    }
};

/// Serial Port Driver (COM1).
/// Why: Debug output on Framework laptop.
/// GrainStyle: Static allocation, explicit port numbers.
pub const Serial = struct {
    /// COM1 base port.
    pub const COM1: u16 = 0x3F8;
    /// COM2 base port.
    pub const COM2: u16 = 0x2F8;

    /// Port offsets.
    const DATA: u16 = 0; // Data register
    const IER: u16 = 1; // Interrupt Enable Register
    const FCR: u16 = 2; // FIFO Control Register
    const LCR: u16 = 3; // Line Control Register
    const MCR: u16 = 4; // Modem Control Register
    const LSR: u16 = 5; // Line Status Register
    const MSR: u16 = 6; // Modem Status Register

    /// Line Status Register bits.
    const LSR_DATA_READY: u8 = 0x01;
    const LSR_TX_EMPTY: u8 = 0x20;

    /// Current port base.
    port: u16,

    /// Initialize serial port.
    /// Why: Set up serial port for 115200 baud.
    pub fn init(port: u16) Serial {
        // Disable interrupts
        Port.outb(port + IER, 0x00);

        // Enable DLAB (set baud rate divisor)
        Port.outb(port + LCR, 0x80);

        // Set divisor to 1 (115200 baud)
        Port.outb(port + DATA, 0x01); // Low byte
        Port.outb(port + IER, 0x00); // High byte

        // 8 bits, no parity, one stop bit
        Port.outb(port + LCR, 0x03);

        // Enable FIFO, clear, 14-byte threshold
        Port.outb(port + FCR, 0xC7);

        // Enable DTR, RTS, OUT2
        Port.outb(port + MCR, 0x0B);

        // Enable interrupts (optional, for async operation)
        Port.outb(port + IER, 0x01);

        return Serial{ .port = port };
    }

    /// Check if transmit buffer is empty.
    pub fn is_tx_empty(self: *const Serial) bool {
        return (Port.inb(self.port + LSR) & LSR_TX_EMPTY) != 0;
    }

    /// Check if data is available.
    pub fn is_data_ready(self: *const Serial) bool {
        return (Port.inb(self.port + LSR) & LSR_DATA_READY) != 0;
    }

    /// Write a byte.
    pub fn write_byte(self: *const Serial, byte: u8) void {
        // Wait for transmit buffer to be empty
        while (!self.is_tx_empty()) {}
        Port.outb(self.port + DATA, byte);
    }

    /// Read a byte (blocking).
    pub fn read_byte(self: *const Serial) u8 {
        while (!self.is_data_ready()) {}
        return Port.inb(self.port + DATA);
    }

    /// Write a string.
    pub fn write_string(self: *const Serial, str: []const u8) void {
        for (str) |c| {
            if (c == '\n') {
                self.write_byte('\r');
            }
            self.write_byte(c);
        }
    }
};

/// PS/2 Keyboard Driver.
/// Why: Input on Framework laptop (or emulated via USB).
/// GrainStyle: Static allocation, explicit scancodes.
pub const Keyboard = struct {
    /// PS/2 ports.
    const DATA_PORT: u16 = 0x60;
    const STATUS_PORT: u16 = 0x64;
    const COMMAND_PORT: u16 = 0x64;

    /// Status register bits.
    const STATUS_OUTPUT_FULL: u8 = 0x01;
    const STATUS_INPUT_FULL: u8 = 0x02;

    /// Scancode to ASCII table (US layout, partial).
    const scancode_to_ascii: [128]u8 = blk: {
        var table = [_]u8{0} ** 128;
        // Row 1: Escape, 1-9, 0, -, =, Backspace
        table[0x01] = 0x1B; // Escape
        table[0x02] = '1';
        table[0x03] = '2';
        table[0x04] = '3';
        table[0x05] = '4';
        table[0x06] = '5';
        table[0x07] = '6';
        table[0x08] = '7';
        table[0x09] = '8';
        table[0x0A] = '9';
        table[0x0B] = '0';
        table[0x0C] = '-';
        table[0x0D] = '=';
        table[0x0E] = 0x08; // Backspace

        // Row 2: Tab, Q-P, [, ], Enter
        table[0x0F] = '\t';
        table[0x10] = 'q';
        table[0x11] = 'w';
        table[0x12] = 'e';
        table[0x13] = 'r';
        table[0x14] = 't';
        table[0x15] = 'y';
        table[0x16] = 'u';
        table[0x17] = 'i';
        table[0x18] = 'o';
        table[0x19] = 'p';
        table[0x1A] = '[';
        table[0x1B] = ']';
        table[0x1C] = '\n';

        // Row 3: A-L, ;, ', `
        table[0x1E] = 'a';
        table[0x1F] = 's';
        table[0x20] = 'd';
        table[0x21] = 'f';
        table[0x22] = 'g';
        table[0x23] = 'h';
        table[0x24] = 'j';
        table[0x25] = 'k';
        table[0x26] = 'l';
        table[0x27] = ';';
        table[0x28] = '\'';
        table[0x29] = '`';

        // Row 4: \, Z-M, ,, ., /
        table[0x2B] = '\\';
        table[0x2C] = 'z';
        table[0x2D] = 'x';
        table[0x2E] = 'c';
        table[0x2F] = 'v';
        table[0x30] = 'b';
        table[0x31] = 'n';
        table[0x32] = 'm';
        table[0x33] = ',';
        table[0x34] = '.';
        table[0x35] = '/';

        // Space
        table[0x39] = ' ';

        break :blk table;
    };

    /// Check if a key is available.
    pub fn is_key_available() bool {
        return (Port.inb(STATUS_PORT) & STATUS_OUTPUT_FULL) != 0;
    }

    /// Read scancode (non-blocking, returns null if no key).
    pub fn read_scancode() ?u8 {
        if (!is_key_available()) {
            return null;
        }
        return Port.inb(DATA_PORT);
    }

    /// Convert scancode to ASCII.
    /// Why: Translate PS/2 scancode to character.
    /// Returns: ASCII character or 0 if not printable/key release.
    pub fn scancode_to_char(scancode: u8) u8 {
        // Key release (high bit set)
        if ((scancode & 0x80) != 0) {
            return 0;
        }
        if (scancode >= 128) {
            return 0;
        }
        return scancode_to_ascii[scancode];
    }

    /// Read character (blocking).
    pub fn read_char() u8 {
        while (true) {
            const scancode = read_scancode() orelse continue;
            const char = scancode_to_char(scancode);
            if (char != 0) {
                return char;
            }
        }
    }
};

/// PIT Timer Driver.
/// Why: System timer for scheduling.
/// GrainStyle: Static allocation, explicit frequencies.
pub const Timer = struct {
    /// PIT ports.
    const CHANNEL0: u16 = 0x40;
    const CHANNEL1: u16 = 0x41;
    const CHANNEL2: u16 = 0x42;
    const COMMAND: u16 = 0x43;

    /// PIT frequency (1.193182 MHz).
    const PIT_FREQUENCY: u32 = 1193182;

    /// Current tick count.
    var ticks: u64 = 0;

    /// Configure frequency (Hz).
    pub fn init(frequency: u32) void {
        const divisor: u16 = @intCast(PIT_FREQUENCY / frequency);

        // Channel 0, lobyte/hibyte, rate generator
        Port.outb(COMMAND, 0x36);

        // Set divisor
        Port.outb(CHANNEL0, @intCast(divisor & 0xFF));
        Port.outb(CHANNEL0, @intCast((divisor >> 8) & 0xFF));

        ticks = 0;
    }

    /// Handle timer interrupt.
    /// Why: Called from IRQ0 handler.
    pub fn handle_interrupt() void {
        ticks +%= 1;
    }

    /// Get current tick count.
    pub fn get_ticks() u64 {
        return ticks;
    }

    /// Sleep for milliseconds (busy wait).
    pub fn sleep_ms(ms: u32) void {
        const target = ticks + (ms * 1000 / 1000); // Assuming 1000 Hz
        while (ticks < target) {
            asm volatile ("hlt");
        }
    }
};

/// Framebuffer Driver.
/// Why: Graphics output on Framework laptop.
/// GrainStyle: Static allocation, explicit pixel formats.
pub const Framebuffer = struct {
    /// Framebuffer base address.
    base: u64,
    /// Width in pixels.
    width: u32,
    /// Height in pixels.
    height: u32,
    /// Bytes per row.
    stride: u32,
    /// Bits per pixel.
    bpp: u32,

    /// Create framebuffer from boot info.
    pub fn from_boot_info(base: u64, width: u32, height: u32, stride: u32, bpp: u32) Framebuffer {
        return Framebuffer{
            .base = base,
            .width = width,
            .height = height,
            .stride = stride,
            .bpp = bpp,
        };
    }

    /// Set pixel (32-bit color: 0xAARRGGBB).
    pub fn set_pixel(self: *const Framebuffer, x: u32, y: u32, color: u32) void {
        if (x >= self.width or y >= self.height) return;

        const offset = y * self.stride + x * (self.bpp / 8);
        const ptr: [*]volatile u32 = @ptrFromInt(self.base + offset);
        ptr[0] = color;
    }

    /// Fill rectangle.
    pub fn fill_rect(self: *const Framebuffer, x: u32, y: u32, w: u32, h: u32, color: u32) void {
        var py = y;
        while (py < y + h and py < self.height) : (py += 1) {
            var px = x;
            while (px < x + w and px < self.width) : (px += 1) {
                self.set_pixel(px, py, color);
            }
        }
    }

    /// Clear screen.
    pub fn clear(self: *const Framebuffer, color: u32) void {
        self.fill_rect(0, 0, self.width, self.height, color);
    }
};

/// IDT Entry (Interrupt Descriptor Table).
/// Why: Define interrupt handlers for x86_64.
pub const IdtEntry = extern struct {
    offset_low: u16,
    selector: u16,
    ist: u8,
    type_attr: u8,
    offset_mid: u16,
    offset_high: u32,
    reserved: u32,

    /// Create IDT entry.
    pub fn create(handler: u64, selector: u16, ist: u3, gate_type: u4, dpl: u2, present: bool) IdtEntry {
        return IdtEntry{
            .offset_low = @intCast(handler & 0xFFFF),
            .selector = selector,
            .ist = ist,
            .type_attr = (@as(u8, if (present) 0x80 else 0) |
                (@as(u8, dpl) << 5) |
                @as(u8, gate_type)),
            .offset_mid = @intCast((handler >> 16) & 0xFFFF),
            .offset_high = @intCast((handler >> 32) & 0xFFFFFFFF),
            .reserved = 0,
        };
    }
};

/// IDT Pointer (for LIDT instruction).
pub const IdtPointer = extern struct {
    limit: u16,
    base: u64,
};

/// GDT Entry (Global Descriptor Table).
/// Why: Define segments for x86_64 (mostly flat model).
pub const GdtEntry = extern struct {
    limit_low: u16,
    base_low: u16,
    base_mid: u8,
    access: u8,
    flags_limit_high: u8,
    base_high: u8,

    /// Create null segment.
    pub fn null_segment() GdtEntry {
        return GdtEntry{
            .limit_low = 0,
            .base_low = 0,
            .base_mid = 0,
            .access = 0,
            .flags_limit_high = 0,
            .base_high = 0,
        };
    }

    /// Create code segment (64-bit long mode).
    pub fn code64(dpl: u2) GdtEntry {
        return GdtEntry{
            .limit_low = 0xFFFF,
            .base_low = 0,
            .base_mid = 0,
            .access = 0x9A | (@as(u8, dpl) << 5), // Present, Code, Readable, Accessed
            .flags_limit_high = 0xAF, // Long mode, 4KB granularity
            .base_high = 0,
        };
    }

    /// Create data segment (64-bit long mode).
    pub fn data64(dpl: u2) GdtEntry {
        return GdtEntry{
            .limit_low = 0xFFFF,
            .base_low = 0,
            .base_mid = 0,
            .access = 0x92 | (@as(u8, dpl) << 5), // Present, Data, Writable, Accessed
            .flags_limit_high = 0xCF, // 4KB granularity, 32-bit
            .base_high = 0,
        };
    }
};

// Tests (run on host, not target).
test "serial port init" {
    // Can't test actual hardware, just verify struct
    const serial = Serial{ .port = Serial.COM1 };
    try std.testing.expectEqual(@as(u16, 0x3F8), serial.port);
}

test "keyboard scancode table" {
    try std.testing.expectEqual(@as(u8, 'a'), Keyboard.scancode_to_char(0x1E));
    try std.testing.expectEqual(@as(u8, ' '), Keyboard.scancode_to_char(0x39));
    try std.testing.expectEqual(@as(u8, 0), Keyboard.scancode_to_char(0x9E)); // Key release
}

test "IDT entry creation" {
    const entry = IdtEntry.create(0x12345678ABCDEF00, 0x08, 0, 0x0E, 0, true);
    try std.testing.expectEqual(@as(u16, 0xEF00), entry.offset_low);
    try std.testing.expectEqual(@as(u16, 0x08), entry.selector);
    try std.testing.expectEqual(@as(u8, 0x8E), entry.type_attr); // Present + Interrupt Gate
}

test "GDT entry creation" {
    const null_seg = GdtEntry.null_segment();
    try std.testing.expectEqual(@as(u8, 0), null_seg.access);

    const code_seg = GdtEntry.code64(0);
    try std.testing.expectEqual(@as(u8, 0x9A), code_seg.access);
}
