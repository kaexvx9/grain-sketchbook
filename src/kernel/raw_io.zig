// QEMU RISC-V virt machine UART0 address
const UART0_BASE: usize = 0x10000000;

// Global flag to disable RawIO in test mode.
// Why: In tests, hardware addresses don't exist, so we need to avoid writing to them.
// Grain Style: Explicit flag, no magic numbers.
var raw_io_enabled: bool = true;

/// Disable RawIO (for testing).
/// Why: Allow tests to disable hardware access to avoid SIGILL.
pub fn disable() void {
    raw_io_enabled = false;
}

/// Enable RawIO (for production).
/// Why: Allow re-enabling hardware access after tests.
pub fn enable() void {
    raw_io_enabled = true;
}

/// Check if RawIO is enabled.
/// Why: Allow Debug.kassert to detect test mode and fail gracefully.
pub fn is_enabled() bool {
    return raw_io_enabled;
}

pub fn write(msg: []const u8) void {
    // Why: In test mode, skip hardware access to avoid SIGILL.
    if (!raw_io_enabled) {
        return; // No-op when disabled
    }
    
    const uart = @as(*volatile u8, @ptrFromInt(UART0_BASE));
    for (msg) |c| {
        // Wait for THR (Transmitter Holding Register) to be empty?
        // For QEMU/Simple UART we can usually just write.
        // In a real driver we'd check LSR (Line Status Register) bit 5.
        // const lsr = @as(*volatile u8, @ptrFromInt(UART0_BASE + 5));
        // while ((lsr.* & 0x20) == 0) {}
        
        uart.* = c;
    }
}

pub fn write_byte(c: u8) void {
    // Why: In test mode, skip hardware access to avoid SIGILL.
    if (!raw_io_enabled) {
        return; // No-op when disabled
    }
    
    const uart = @as(*volatile u8, @ptrFromInt(UART0_BASE));
    uart.* = c;
}

/// Read byte from UART (non-blocking).
/// Why: Read character from serial input for REPL.
/// Returns: Character if available, null if no character ready.
/// Note: For QEMU virt machine, UART LSR (Line Status Register) is at offset 5.
///       Bit 0 indicates data ready.
pub fn read_byte() ?u8 {
    // Why: In test mode, skip hardware access to avoid SIGILL.
    if (!raw_io_enabled) {
        return null; // No-op when disabled
    }
    
    // Check LSR (Line Status Register) bit 0 (Data Ready)
    const lsr = @as(*volatile u8, @ptrFromInt(UART0_BASE + 5));
    if ((lsr.* & 0x01) == 0) {
        return null; // No data available
    }
    
    // Read from RBR (Receiver Buffer Register)
    const rbr = @as(*volatile u8, @ptrFromInt(UART0_BASE));
    return rbr.*;
}

/// Read byte from UART (blocking).
/// Why: Wait for character input in REPL.
/// Returns: Character when available (blocks until data ready).
/// Note: Polls LSR until data is available.
pub fn read_byte_blocking() u8 {
    // Why: In test mode, skip hardware access to avoid SIGILL.
    if (!raw_io_enabled) {
        // In test mode, return a dummy value (shouldn't be called in tests)
        return 0;
    }
    
    // Poll LSR (Line Status Register) until data is ready
    const lsr = @as(*volatile u8, @ptrFromInt(UART0_BASE + 5));
    while ((lsr.* & 0x01) == 0) {
        // Wait for data (busy wait)
        // Note: In a real system, we might yield CPU here
    }
    
    // Read from RBR (Receiver Buffer Register)
    const rbr = @as(*volatile u8, @ptrFromInt(UART0_BASE));
    return rbr.*;
}
