//! Raw UART I/O for QEMU RISC-V virt machine.
//! Why: Inline assembly bypasses Zig's volatile pointer codegen issues.

var disabled: bool = false;

/// Why: Disable UART output for tests (avoid SIGILL on x86_64).
pub fn disable() void {
    disabled = true;
}

/// Why: Re-enable UART output after tests.
pub fn enable() void {
    disabled = false;
}

/// Write a string to UART.
/// Why: Output text to console for kernel messages.
pub fn write(msg: []const u8) void {
    if (disabled) return;
    for (msg) |c| write_byte_raw(c);
}

/// Write a single byte to UART.
/// Why: Direct hardware output for early boot before interrupts.
pub fn write_byte(c: u8) void {
    if (disabled) return;
    write_byte_raw(c);
}

fn write_byte_raw(c: u8) void {
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
    if (disabled) return null;
    var lsr_val: u8 = undefined;
    asm volatile (
        \\lui t1, 0x10000
        \\lbu %[out], 5(t1)
        : [out] "=r" (lsr_val),
    );
    if ((lsr_val & 0x01) == 0) return null;
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
    if (disabled) return 0;
    while (true) {
        if (read_byte()) |b| return b;
    }
}
