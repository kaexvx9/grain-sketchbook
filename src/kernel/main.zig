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
    // Commands: h=help, i=info, v=version, e=exit
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
