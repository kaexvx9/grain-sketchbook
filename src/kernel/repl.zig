//! Simple REPL for Kernel Interactive Mode
//! Why: Provide interactive command interface for development and testing.
//! Grain Style: Explicit types, bounded allocations, comprehensive assertions.
//!
//! NOTE: This is a minimal REPL using inline assembly for UART output.
//! The full REPL with Grainscript evaluation is disabled due to Zig codegen issues
//! on RISC-V64 freestanding targets. See docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md

const RawIO = @import("raw_io.zig");
const BasinKernel = @import("basin_kernel.zig").BasinKernel;

/// Minimal UART output - comptime unrolled, inline asm only.
/// Why: Zig's RISC-V freestanding codegen has issues with runtime loops and function calls.
const Uart = struct {
    inline fn putc(c: u8) void {
        asm volatile (
            \\lui t1, 0x10000
            \\sb %[byte], 0(t1)
            :
            : [byte] "r" (c),
        );
    }
    
    pub inline fn print(comptime s: []const u8) void {
        inline for (s) |c| {
            putc(c);
        }
    }
};

/// Simple REPL for kernel interactive mode.
pub const Repl = struct {
    kernel: *BasinKernel,
    running: bool,

    const Self = @This();
    const MAX_LINE_LEN: u32 = 256;

    /// Initialize REPL.
    pub fn init(kernel: *BasinKernel) Self {
        return Self{
            .kernel = kernel,
            .running = true,
        };
    }

    /// Run REPL loop.
    pub fn run(self: *Self) void {
        Uart.print("\n");
        Uart.print("Grainscript REPL v0.1.0\n");
        Uart.print("Type 'help' for commands, 'exit' to quit.\n");
        Uart.print("\n");

        var line_buf: [MAX_LINE_LEN]u8 = undefined;
        var line_len: u32 = 0;

        while (self.running) {
            // Print prompt
            Uart.print("grainscript> ");

            // Read line from UART (blocking wait for input)
            line_len = 0;
            while (line_len < MAX_LINE_LEN) {
                const c = RawIO.read_byte_blocking();
                
                // Handle newline
                if (c == '\n' or c == '\r') {
                    break;
                }
                
                // Handle backspace
                if (c == '\x08' or c == '\x7f') {
                    if (line_len > 0) {
                        line_len -= 1;
                        Uart.print("\x08 \x08");
                    }
                    continue;
                }
                
                // Add printable character
                if (c >= 0x20 and c < 0x7f) {
                    line_buf[line_len] = c;
                    line_len += 1;
                    RawIO.write_byte(c);
                }
            }
            
            Uart.print("\n");

            // Process command
            if (line_len > 0) {
                self.process_line(line_buf[0..line_len]);
            }
        }
    }
    
    /// Process a line of input.
    fn process_line(self: *Self, line: []const u8) void {
        // Check for exit
        if (line.len >= 4 and line[0] == 'e' and line[1] == 'x' and line[2] == 'i' and line[3] == 't') {
            Uart.print("Goodbye!\n");
            self.running = false;
            return;
        }
        
        // Check for help
        if (line.len >= 4 and line[0] == 'h' and line[1] == 'e' and line[2] == 'l' and line[3] == 'p') {
            Uart.print("Commands: help, exit, sysinfo\n");
            return;
        }
        
        // Check for sysinfo
        if (line.len >= 7 and line[0] == 's' and line[1] == 'y' and line[2] == 's') {
            Uart.print("Basin Kernel v0.1.0 (RISC-V64)\n");
            Uart.print("Users: ");
            // Print user count as digit (0-9)
            const count = self.kernel.user_count;
            if (count < 10) {
                Uart.putc('0' + @as(u8, @intCast(count)));
            } else {
                Uart.print("10+");
            }
            Uart.print("\n");
            return;
        }
        
        // Echo back unknown commands
        Uart.print("Unknown: ");
        for (line) |c| {
            RawIO.write_byte(c);
        }
        Uart.print("\n");
    }
};
