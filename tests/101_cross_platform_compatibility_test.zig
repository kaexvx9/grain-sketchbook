//! RISC-V Platform Compatibility Test
//! Why: Verify platform abstraction works for RISC-V (RISC-V-only architecture).
//! Grain Style: Explicit types (u32/u64 not usize), comprehensive assertions.

const std = @import("std");
const testing = std.testing;
const basin_kernel = @import("basin_kernel");
const Debug = basin_kernel.Debug;
const kernel_platform = @import("kernel_platform");
const platform_riscv = kernel_platform.platform_riscv;
const platform = kernel_platform.platform;

test "platform_riscv_init" {
    // Initialize RISC-V platform.
    const riscv_platform = platform.Platform.init(
        .riscv64,
        platform_riscv.platform_call_riscv,
        platform_riscv.get_time_ns,
    );
    
    // Assert: Platform must be initialized.
    Debug.kassert(riscv_platform.initialized, "RISC-V platform not initialized", .{});
    
    // Assert: Architecture must be RISC-V64.
    Debug.kassert(
        riscv_platform.arch == .riscv64,
        "Platform architecture mismatch",
        .{},
    );
    
    // Assert: Platform call function must be set.
    Debug.kassert(
        riscv_platform.platform_call_fn != null,
        "Platform call function not set",
        .{},
    );
    
    // Assert: Time source function must be set.
    Debug.kassert(
        riscv_platform.time_source_fn != null,
        "Time source function not set",
        .{},
    );
}

test "platform_riscv_console_putchar" {
    // Initialize RISC-V platform.
    const riscv_platform = platform.Platform.init(
        .riscv64,
        platform_riscv.platform_call_riscv,
        platform_riscv.get_time_ns,
    );
    
    // Test console putchar (should not crash).
    riscv_platform.console_putchar('A');
    
    // Assert: Platform must remain initialized.
    Debug.kassert(riscv_platform.initialized, "Platform not initialized", .{});
}

test "platform_riscv_get_time_ns" {
    // Initialize RISC-V platform.
    const riscv_platform = platform.Platform.init(
        .riscv64,
        platform_riscv.platform_call_riscv,
        platform_riscv.get_time_ns,
    );
    
    // Get time from platform.
    const time_ns = riscv_platform.get_time_ns();
    
    // Assert: Time must be reasonable (not zero, not before year 2000).
    const YEAR_2000_NS: u64 = 946684800 * 1000000000; // Jan 1, 2000
    Debug.kassert(time_ns >= YEAR_2000_NS, "Time before year 2000", .{});
    
    // Assert: Platform must remain initialized.
    Debug.kassert(riscv_platform.initialized, "Platform not initialized", .{});
}

test "platform_global_instance" {
    // Initialize RISC-V platform.
    const riscv_platform = platform.Platform.init(
        .riscv64,
        platform_riscv.platform_call_riscv,
        platform_riscv.get_time_ns,
    );
    
    // Set global platform instance.
    platform.set_platform(riscv_platform);
    
    // Get global platform instance.
    const global_platform = platform.get_platform();
    
    // Assert: Global platform must be initialized.
    Debug.kassert(global_platform.initialized, "Global platform not initialized", .{});
    
    // Assert: Architecture must match.
    Debug.kassert(
        global_platform.arch == .riscv64,
        "Global platform architecture mismatch",
        .{},
    );
}
