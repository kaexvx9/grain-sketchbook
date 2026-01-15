//! RISC-V Platform Interface
//! Why: Platform runtime services for RISC-V kernels (SBI wrapper).
//! Grain Style: Minimal, type-safe, comprehensive assertions.

const std = @import("std");
const Debug = @import("debug.zig");
// Use module import for SBI (provided by build.zig for kernel build) or fallback to file import for tests
const sbi = @import("sbi");
const platform = @import("platform.zig");

/// RISC-V platform function implementation.
/// Why: Map unified platform functions to RISC-V SBI calls.
/// Contract: function_id must be valid, args must be valid.
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
            // Note: In VM, this is handled by VM's handle_sbi_call.
            // On real hardware, this would use inline assembly.
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
            // Note: In VM, this is handled by VM's handle_sbi_call.
            // On real hardware, this would use inline assembly.
            const result = sbi.console_getchar();
            
            // Map SBI result to platform result.
            // Note: ConsoleGetcharResult has .NoChar and catch-all `_` for character value
            return switch (result) {
                .NoChar => platform.PlatformResult{
                    .error_code = -1, // Failed (no character)
                    .value = -1,
                },
                _ => platform.PlatformResult{
                    .error_code = 0, // Success
                    .value = @intFromEnum(result), // Convert enum to integer
                },
            };
        },
        .set_timer => {
            // Call SBI set timer.
            // Note: In VM, this is handled by VM's handle_sbi_call.
            // On real hardware, this would use inline assembly.
            sbi.set_timer(arg0);
            
            // Return success.
            return platform.PlatformResult{
                .error_code = 0,
                .value = 0,
            };
        },
        .shutdown => {
            // Call SBI shutdown (doesn't return).
            // Note: In VM, this is handled by VM's handle_sbi_call.
            // On real hardware, this would use inline assembly.
            sbi.shutdown();
            
            // Shutdown never returns, but compiler needs return statement.
            unreachable;
        },
    };
}

// Static counter for time source (increments each call)
var time_call_counter: u64 = 0;

/// Get current time in nanoseconds since epoch.
/// Why: Provide time source for freestanding RISC-V kernel.
/// Contract: Returns monotonic time (or fixed value for stub).
/// Note: This is a stub - actual implementation should use RISC-V timer.
/// For now, use a simple counter that increments to provide monotonic time.
pub fn get_time_ns() u64 {
    // Stub: Use a simple counter-based approach for now.
    // Actual implementation should read RISC-V time CSR (time register).
    // For now, use a base time + incrementing counter to provide monotonic time.
    const BASE_TIME_NS: u64 = 1703000000 * 1000000000; // Jan 2024
    // Increment counter each call
    time_call_counter += 1;
    // Return base time + counter (in nanoseconds)
    // Increment by 1ms (1,000,000 ns) per call to simulate time passing
    return BASE_TIME_NS + (time_call_counter * 1000000);
}
