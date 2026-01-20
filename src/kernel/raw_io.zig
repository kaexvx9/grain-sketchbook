// QEMU RISC-V virt machine UART0 address
// Why inline assembly: Zig's volatile pointer codegen for RISC-V freestanding
// has address calculation issues. Direct assembly bypasses this.

/// Write a string to UART.
pub fn write(msg: []const u8) void {
    for (msg) |c| {
        write_byte(c);
    }
}

/// Write a single byte to UART using inline assembly.
/// Use a0 explicitly for byte (first arg), t1 for UART address.
pub fn write_byte(c: u8) void {
    asm volatile (
        \\lui t1, 0x10000
        \\sb a0, 0(t1)
        :
        : [byte] "{a0}" (c),
    );
}

/// Read byte from UART (non-blocking).
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
pub fn read_byte_blocking() u8 {
    while (true) {
        if (read_byte()) |b| return b;
    }
}
