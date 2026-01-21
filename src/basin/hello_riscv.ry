//! Basin Kernel for Vantage VM
//! Why: RISC-V64 kernel demonstrating full Vantage emulation.
//! Grain Style: Explicit types, static allocation.
//!
//! Simplified version that avoids complex string operations
//! to work around potential relocation issues.

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

/// Print a simple message character by character.
fn print_hello() void {
    sbi_putchar('H');
    sbi_putchar('e');
    sbi_putchar('l');
    sbi_putchar('l');
    sbi_putchar('o');
    sbi_putchar(' ');
    sbi_putchar('f');
    sbi_putchar('r');
    sbi_putchar('o');
    sbi_putchar('m');
    sbi_putchar(' ');
    sbi_putchar('B');
    sbi_putchar('a');
    sbi_putchar('s');
    sbi_putchar('i');
    sbi_putchar('n');
    sbi_putchar('!');
    sbi_putchar('\n');
}

/// Print a digit.
fn print_digit(d: u8) void {
    sbi_putchar('0' + d);
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
    // Print hello
    print_hello();

    // Print fib(10) = 55
    sbi_putchar('f');
    sbi_putchar('i');
    sbi_putchar('b');
    sbi_putchar('(');
    sbi_putchar('1');
    sbi_putchar('0');
    sbi_putchar(')');
    sbi_putchar('=');

    const f10 = fib(10);
    print_digit(@truncate(f10 / 10));
    print_digit(@truncate(f10 % 10));
    sbi_putchar('\n');

    // Print OK
    sbi_putchar('O');
    sbi_putchar('K');
    sbi_putchar('\n');

    sbi_shutdown();
}
