//! Raw UART I/O for QEMU RISC-V virt machine.
//! Why: Inline assembly bypasses Zig's volatile pointer codegen issues.

/// Write a string to UART.
/// Why: Output text to console for kernel messages.
pub fn write(msg: []const u8) void {
    for (msg) |c| {
        write_byte(c);
    }
}

/// Write a single byte to UART.
/// Why: Direct hardware output for early boot before interrupts.
pub fn write_byte(c: u8) void {
    asm volatile (
        \\lui t1, 0x10000
        \\sb a0, 0(t1)
        :
        : [byte] "{a0}" (c),
    );
}

/// Read byte from UART (non-blocking).
/// Why: Poll UART for input without blocking kernel.
pub fn read_byte() ?u8 {
    var lsr_val: u8 = undefined;
    asm volatile (
        \\lui t1, 0x10000
        \\lbu %[out], 5(t1)
        : [out] "=r" (lsr_val),
    );
    if ((lsr_val & 0x01) == 0) {
        return null;
    }
    var byte: u8 = undefined;
    asm volatile (
        \\lui t1, 0x10000
        \\lbu %[out], 0(t1)
        : [out] "=r" (byte),
    );
    return byte;
}

/// Read byte from UART (blocking).
/// Why: Wait for user input in REPL loop.
pub fn read_byte_blocking() u8 {
    while (true) {
        if (read_byte()) |b| return b;
    }
}
