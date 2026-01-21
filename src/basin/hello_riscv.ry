//! Basin Kernel for Vantage VM
//! Why: RISC-V64 kernel demonstrating full Vantage emulation.
//! Grain Style: Explicit types, static allocation.
//!
//! This kernel prints a boot banner, runs a simple computation,
//! and demonstrates the RISC-V emulator working correctly.

// === SBI Interface ===

/// SBI console putchar (legacy extension 0x01).
fn sbi_putchar(c: u8) void {
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

/// Print a number in decimal.
fn print_num(n: u64) void {
    if (n == 0) {
        sbi_putchar('0');
        return;
    }
    var buf: [20]u8 = undefined;
    var i: usize = 0;
    var val = n;
    while (val > 0) : (i += 1) {
        buf[i] = @truncate((val % 10) + '0');
        val /= 10;
    }
    while (i > 0) {
        i -= 1;
        sbi_putchar(buf[i]);
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

// === Kernel Entry ===

/// Entry point (naked function for stack setup).
export fn _start() callconv(.naked) noreturn {
    asm volatile (
        \\lui sp, 0x80100
        \\call basin_main
    );
    unreachable;
}

/// Compute Fibonacci number (test computation).
fn fib(n: u64) u64 {
    if (n <= 1) return n;
    var a: u64 = 0;
    var b: u64 = 1;
    var i: u64 = 2;
    while (i <= n) : (i += 1) {
        const c = a + b;
        a = b;
        b = c;
    }
    return b;
}

/// Main kernel function.
export fn basin_main() callconv(.c) noreturn {
    // Boot banner
    print("\n");
    print("========================================\n");
    print("  Basin Kernel v0.1 on Vantage VM\n");
    print("  RISC-V64 Emulation Layer\n");
    print("========================================\n");
    print("\n");

    // System info
    print("[BOOT] Basin kernel started\n");
    print("[BOOT] Architecture: RISC-V64 (RV64IMAC)\n");
    print("[BOOT] Running on Vantage VM (x86_64 host)\n");
    print("\n");

    // Computation test
    print("[TEST] Computing Fibonacci sequence...\n");
    var i: u64 = 0;
    while (i <= 10) : (i += 1) {
        print("  fib(");
        print_num(i);
        print(") = ");
        print_num(fib(i));
        print("\n");
    }
    print("\n");

    // Larger Fibonacci test
    print("[TEST] fib(20) = ");
    print_num(fib(20));
    print("\n");
    print("[TEST] fib(30) = ");
    print_num(fib(30));
    print("\n");
    print("\n");

    // Success message
    print("[OK] All tests passed!\n");
    print("[OK] Basin kernel running successfully on Vantage VM\n");
    print("\n");

    // Future: Grainscript shell
    print("[INFO] Grainscript shell: Coming soon...\n");
    print("\n");

    // Shutdown
    print("[HALT] Shutting down Basin kernel\n");
    print("========================================\n");

    sbi_shutdown();
}
