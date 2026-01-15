//! Kernel Platform Module
//! Why: Export platform abstraction for testing.
//! Grain Style: Minimal wrapper for module exports.

// Import sbi module (provided by build.zig imports)
const sbi = @import("sbi");
// Import Debug and platform through harbor_kernel to avoid module conflicts
const harbor_kernel = @import("harbor_kernel");
const Debug = harbor_kernel.Debug;
pub const platform = harbor_kernel.platform;

// Re-implement platform_riscv functions using module imports instead of file imports
// Why: platform_riscv.zig uses @import("../kernel_vm/sbi.zig") which doesn't work in module context
pub const platform_riscv = struct {
    /// RISC-V platform function implementation.
    /// Why: Map unified platform functions to RISC-V SBI calls.
    pub fn platform_call_riscv(
        function_id: platform.PlatformFunction,
        arg0: u64,
        arg1: u64,
        arg2: u64,
        arg3: u64,
    ) platform.PlatformResult {
        // Assert: function_id must be valid.
        Debug.kassert(
            @intFromEnum(function_id) >= 1 and @intFromEnum(function_id) <= 4,
            "Invalid platform function ID",
            .{},
        );
        
        // Assert: Unused args must be zero (for now).
        _ = arg1;
        _ = arg2;
        _ = arg3;
        
        // Map unified platform functions to RISC-V SBI calls.
        return switch (function_id) {
            .console_putchar => {
                // Assert: character must fit in u8.
                Debug.kassert(arg0 <= 0xFF, "Character out of range", .{});
                
                // Call SBI console putchar.
                const char = @as(u8, @truncate(arg0));
                _ = sbi.console_putchar(char);
                
                // Return success.
                return platform.PlatformResult{
                    .error_code = 0,
                    .value = 0,
                };
            },
            .console_getchar => {
                // Call SBI console getchar.
                const result = sbi.console_getchar();
                
                // Map SBI result to platform result.
                return switch (result) {
                    .NoChar => platform.PlatformResult{
                        .error_code = -1, // Failed (no character)
                        .value = -1,
                    },
                    .Char => |char| platform.PlatformResult{
                        .error_code = 0, // Success
                        .value = @as(i64, @intCast(char)),
                    },
                };
            },
            .set_timer => {
                // Call SBI set timer.
                sbi.set_timer(arg0);
                
                // Return success.
                return platform.PlatformResult{
                    .error_code = 0,
                    .value = 0,
                };
            },
            .shutdown => {
                // Call SBI shutdown (doesn't return).
                sbi.shutdown();
                
                // Shutdown never returns, but compiler needs return statement.
                unreachable;
            },
        };
    }
    
    /// Get current time in nanoseconds since epoch.
    /// Why: Provide time source for freestanding RISC-V kernel.
    pub fn get_time_ns() u64 {
        // Stub: Return a fixed time value for now.
        // Actual implementation should read RISC-V time CSR (time register).
        const FIXED_TIME_NS: u64 = 1703000000 * 1000000000; // Jan 2024
        return FIXED_TIME_NS;
    }
};
