//! Hello World for Basin Kernel on Vantage VM
//! Why: Minimal RISC-V64 kernel to test Vantage emulation.
//! Grain Style: Explicit types, static allocation.
//!
//! This is a standalone RISC-V64 program that prints "Hello from Basin!"
//! using SBI console output, then halts.

/// SBI console putchar (legacy extension 0x01).
fn sbi_putchar(c: u8) void {
    // SBI call: a7 = extension ID (0x01), a0 = character
    asm volatile ("ecall"
        :
        : [ext] "{a7}" (@as(u64, 0x01)),
          [arg0] "{a0}" (@as(u64, c)),
        : .{ .memory = true }
    );
}

/// Print a string via SBI.
fn print(s: []const u8) void {
    for (s) |c| {
        sbi_putchar(c);
    }
}

/// SBI system reset (extension 0x53525354 = "SRST").
fn sbi_shutdown() noreturn {
    asm volatile ("ecall"
        :
        : [ext] "{a7}" (@as(u64, 0x53525354)),
          [func] "{a6}" (@as(u64, 0)),
          [arg0] "{a0}" (@as(u64, 0)),
          [arg1] "{a1}" (@as(u64, 0)),
        : .{ .memory = true }
    );
    unreachable;
}

/// Entry point.
export fn _start() callconv(.naked) noreturn {
    // Set up a minimal stack (use some high address in memory).
    // Then call basin_main.
    asm volatile (
        \\lui sp, 0x80100
        \\call basin_main
    );
    unreachable;
}

/// Main function (called from _start after stack setup).
export fn basin_main() callconv(.c) noreturn {
    print("Hello from Basin!\n");
    print("Vantage VM is running RISC-V64 emulation.\n");
    print("Grainscript shell coming soon...\n");
    print("\n");
    print("Shutting down...\n");

    sbi_shutdown();
}
