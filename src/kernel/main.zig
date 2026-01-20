//! Basin Kernel - Main Entry Point
//! Why: Minimal kernel that boots and runs an interactive REPL.
//! Note: Uses inline assembly for all I/O due to Zig RV64 freestanding codegen issues.
//! See: docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md

/// Minimal UART output - comptime unrolled, inline asm only.
/// Why: Zig's RISC-V freestanding codegen has issues with runtime loops and function calls.
const Uart = struct {
    pub inline fn putc(c: u8) void {
        asm volatile (
            \\lui t1, 0x10000
            \\sb %[byte], 0(t1)
            :
            : [byte] "r" (c),
        );
    }
    
    /// Print comptime string (unrolled at compile time).
    pub inline fn print(comptime s: []const u8) void {
        inline for (s) |c| {
            putc(c);
        }
    }
};

fn print_banner() void {
    Uart.print("\n");
    Uart.print("Basin Kernel v0.1.0 (RISC-V64)\n");
    Uart.print("Copyright (c) 2026 Team Libra\n");
    Uart.print("\n");
}

pub export fn kmain() noreturn {
    print_banner();
    Uart.print("[Basin] Ready. Type 'h' for help.\n");
    Uart.print("gs> ");
    
    // Pure assembly REPL - Zig control flow has codegen issues on RV64 freestanding
    // Commands: h=help, i=info, v=version, c=calc, e=exit
    // Calc mode: type a digit 0-9, get it doubled
    asm volatile (
        \\  lui t1, 0x10000       # UART base in t1 (preserved)
        \\
        \\.Lwait:
        \\  lbu t2, 5(t1)         # Read LSR
        \\  andi t2, t2, 1        # Check data ready
        \\  beqz t2, .Lwait
        \\  lbu t3, 0(t1)         # Read byte into t3
        \\  sb t3, 0(t1)          # Echo it
        \\
        \\  # Dispatch on character
        \\  li t4, 'h'
        \\  beq t3, t4, .Lcmd_help
        \\  li t4, 'i'
        \\  beq t3, t4, .Lcmd_info
        \\  li t4, 'v'
        \\  beq t3, t4, .Lcmd_version
        \\  li t4, 'c'
        \\  beq t3, t4, .Lcmd_calc
        \\  li t4, 'e'
        \\  beq t3, t4, .Lcmd_exit
        \\  li t4, 10
        \\  beq t3, t4, .Lprompt
        \\  li t4, 13
        \\  beq t3, t4, .Lprompt
        \\  j .Lwait
        \\
        \\.Lprompt:
        \\  li t3, 'g'
        \\  sb t3, 0(t1)
        \\  li t3, 's'
        \\  sb t3, 0(t1)
        \\  li t3, '>'
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  j .Lwait
        \\
        \\.Lcmd_help:
        \\  # "elp\n  h help\n  i info\n  v version\n  e exit\n"
        \\  li t3, 'e'
        \\  sb t3, 0(t1)
        \\  li t3, 'l'
        \\  sb t3, 0(t1)
        \\  li t3, 'p'
        \\  sb t3, 0(t1)
        \\  li t3, 10
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  sb t3, 0(t1)
        \\  li t3, 'h'
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  li t3, 'h'
        \\  sb t3, 0(t1)
        \\  li t3, 'e'
        \\  sb t3, 0(t1)
        \\  li t3, 'l'
        \\  sb t3, 0(t1)
        \\  li t3, 'p'
        \\  sb t3, 0(t1)
        \\  li t3, 10
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  sb t3, 0(t1)
        \\  li t3, 'i'
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  li t3, 'i'
        \\  sb t3, 0(t1)
        \\  li t3, 'n'
        \\  sb t3, 0(t1)
        \\  li t3, 'f'
        \\  sb t3, 0(t1)
        \\  li t3, 'o'
        \\  sb t3, 0(t1)
        \\  li t3, 10
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  sb t3, 0(t1)
        \\  li t3, 'v'
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  li t3, 'v'
        \\  sb t3, 0(t1)
        \\  li t3, 'e'
        \\  sb t3, 0(t1)
        \\  li t3, 'r'
        \\  sb t3, 0(t1)
        \\  li t3, 's'
        \\  sb t3, 0(t1)
        \\  li t3, 'i'
        \\  sb t3, 0(t1)
        \\  li t3, 'o'
        \\  sb t3, 0(t1)
        \\  li t3, 'n'
        \\  sb t3, 0(t1)
        \\  li t3, 10
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  sb t3, 0(t1)
        \\  li t3, 'e'
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  li t3, 'e'
        \\  sb t3, 0(t1)
        \\  li t3, 'x'
        \\  sb t3, 0(t1)
        \\  li t3, 'i'
        \\  sb t3, 0(t1)
        \\  li t3, 't'
        \\  sb t3, 0(t1)
        \\  li t3, 10
        \\  sb t3, 0(t1)
        \\  j .Lprompt
        \\
        \\.Lcmd_info:
        \\  # "nfo: Basin/RV64\n"
        \\  li t3, 'n'
        \\  sb t3, 0(t1)
        \\  li t3, 'f'
        \\  sb t3, 0(t1)
        \\  li t3, 'o'
        \\  sb t3, 0(t1)
        \\  li t3, ':'
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  li t3, 'B'
        \\  sb t3, 0(t1)
        \\  li t3, 'a'
        \\  sb t3, 0(t1)
        \\  li t3, 's'
        \\  sb t3, 0(t1)
        \\  li t3, 'i'
        \\  sb t3, 0(t1)
        \\  li t3, 'n'
        \\  sb t3, 0(t1)
        \\  li t3, '/'
        \\  sb t3, 0(t1)
        \\  li t3, 'R'
        \\  sb t3, 0(t1)
        \\  li t3, 'V'
        \\  sb t3, 0(t1)
        \\  li t3, '6'
        \\  sb t3, 0(t1)
        \\  li t3, '4'
        \\  sb t3, 0(t1)
        \\  li t3, 10
        \\  sb t3, 0(t1)
        \\  j .Lprompt
        \\
        \\.Lcmd_version:
        \\  # "ersion: 0.1.0\n"
        \\  li t3, 'e'
        \\  sb t3, 0(t1)
        \\  li t3, 'r'
        \\  sb t3, 0(t1)
        \\  li t3, 's'
        \\  sb t3, 0(t1)
        \\  li t3, 'i'
        \\  sb t3, 0(t1)
        \\  li t3, 'o'
        \\  sb t3, 0(t1)
        \\  li t3, 'n'
        \\  sb t3, 0(t1)
        \\  li t3, ':'
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  li t3, '0'
        \\  sb t3, 0(t1)
        \\  li t3, '.'
        \\  sb t3, 0(t1)
        \\  li t3, '1'
        \\  sb t3, 0(t1)
        \\  li t3, '.'
        \\  sb t3, 0(t1)
        \\  li t3, '0'
        \\  sb t3, 0(t1)
        \\  li t3, 10
        \\  sb t3, 0(t1)
        \\  j .Lprompt
        \\
        \\.Lcmd_calc:
        \\  # "alc: " then wait for digit, double it, print result
        \\  li t3, 'a'
        \\  sb t3, 0(t1)
        \\  li t3, 'l'
        \\  sb t3, 0(t1)
        \\  li t3, 'c'
        \\  sb t3, 0(t1)
        \\  li t3, ':'
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  # Wait for digit
        \\.Lcalc_wait:
        \\  lbu t2, 5(t1)
        \\  andi t2, t2, 1
        \\  beqz t2, .Lcalc_wait
        \\  lbu t3, 0(t1)
        \\  sb t3, 0(t1)          # Echo digit
        \\  # Check if digit 0-9
        \\  li t4, '0'
        \\  blt t3, t4, .Lcalc_nan
        \\  li t4, '9'
        \\  bgt t3, t4, .Lcalc_nan
        \\  # Convert to number: n = c - '0'
        \\  li t4, '0'
        \\  sub t5, t3, t4        # t5 = digit value (0-9)
        \\  # Double it: t5 = t5 * 2
        \\  slli t5, t5, 1        # t5 = t5 << 1 = t5 * 2
        \\  # Print " * 2 = "
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  li t3, '*'
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  li t3, '2'
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  li t3, '='
        \\  sb t3, 0(t1)
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  # Print result (0-18, so up to 2 digits)
        \\  li t4, 10
        \\  blt t5, t4, .Lcalc_1dig
        \\  # Two digits: print '1' then (t5 - 10)
        \\  li t3, '1'
        \\  sb t3, 0(t1)
        \\  sub t5, t5, t4        # t5 = t5 - 10
        \\.Lcalc_1dig:
        \\  li t4, '0'
        \\  add t3, t5, t4        # t3 = '0' + t5
        \\  sb t3, 0(t1)
        \\  li t3, 10
        \\  sb t3, 0(t1)
        \\  j .Lprompt
        \\.Lcalc_nan:
        \\  # Print " NaN\n"
        \\  li t3, ' '
        \\  sb t3, 0(t1)
        \\  li t3, 'N'
        \\  sb t3, 0(t1)
        \\  li t3, 'a'
        \\  sb t3, 0(t1)
        \\  li t3, 'N'
        \\  sb t3, 0(t1)
        \\  li t3, 10
        \\  sb t3, 0(t1)
        \\  j .Lprompt
        \\
        \\.Lcmd_exit:
        \\  # "xit\nGoodbye!\n"
        \\  li t3, 'x'
        \\  sb t3, 0(t1)
        \\  li t3, 'i'
        \\  sb t3, 0(t1)
        \\  li t3, 't'
        \\  sb t3, 0(t1)
        \\  li t3, 10
        \\  sb t3, 0(t1)
        \\  li t3, 'G'
        \\  sb t3, 0(t1)
        \\  li t3, 'o'
        \\  sb t3, 0(t1)
        \\  li t3, 'o'
        \\  sb t3, 0(t1)
        \\  li t3, 'd'
        \\  sb t3, 0(t1)
        \\  li t3, 'b'
        \\  sb t3, 0(t1)
        \\  li t3, 'y'
        \\  sb t3, 0(t1)
        \\  li t3, 'e'
        \\  sb t3, 0(t1)
        \\  li t3, '!'
        \\  sb t3, 0(t1)
        \\  li t3, 10
        \\  sb t3, 0(t1)
        \\  # Fall through to halt
    );
    
    // Halt
    Uart.print("[Halted]\n");
    while (true) {
        asm volatile ("wfi");
    }
}
