const Panic = @import("panic.zig");
const Trap = @import("trap.zig");
const BasinKernel = @import("basin_kernel.zig").BasinKernel;
const BasinKernelCore = @import("basin_kernel_core.zig").BasinKernel;
const Debug = @import("debug.zig");
const Framebuffer = @import("framebuffer.zig").Framebuffer;
const boot = @import("boot.zig");
const platform = @import("platform.zig");
const platform_riscv = @import("platform_riscv.zig");
const TimeSource = @import("time_source.zig").TimeSource;

// Global kernel instance
var kernel: BasinKernel = undefined;

// Global framebuffer (initialized in kmain)
// Why: Static allocation for framebuffer state.
var framebuffer: ?Framebuffer = null;

/// Print boot banner.
fn print_banner() void {
    Debug.kprint("\n   ______           _          ____  _____\n", .{});
    Debug.kprint("  / ____/________ _(_)___     / __ \\/ ___/\n", .{});
    Debug.kprint(" / / __/ ___/ __ `/ / __ \\   / / / /\\__ \\ \n", .{});
    Debug.kprint("/ /_/ / /  / /_/ / / / / /  / /_/ /___/ / \n", .{});
    Debug.kprint("\\____/_/   \\__,_/_/_/ /_/   \\____//____/  \n", .{});
    Debug.kprint("\nBasin Kernel v0.1.0 (RISC-V64)\n", .{});
    Debug.kprint("Copyright (c) 2026 Team Carry\n\n", .{});
}

pub export fn kmain() noreturn {
    TimeSource.set_implementation(platform_riscv.get_time_ns);
    const riscv_platform = platform.Platform.init(
        .riscv64,
        platform_riscv.platform_call_riscv,
        platform_riscv.get_time_ns,
    );
    platform.set_platform(riscv_platform);
    print_banner();

    // 2. Initialize Kernel
    Debug.log(.info, "Initializing Basin...", .{});
    // Note: Use init_in_place() to avoid stack overflow (BasinKernel is ~76KB, stack is only 16KB)
    // Verbose mode can be enabled via CLI flag (future: kernel parameter)
    // For now, verbose mode is disabled by default (set to true for detailed debugging)
    Debug.set_verbose(false);
    
    Debug.vprint("Starting kernel initialization...", .{});
    const kernel_ptr = &kernel;
    @call(.auto, BasinKernelCore.init_in_place, .{kernel_ptr});
    Debug.vprint("Kernel initialization complete", .{});
    
    // 3. Execute boot sequence (validate all subsystems initialized).
    // Why: Ensure all subsystems are initialized in correct order.
    boot.boot_kernel(&kernel);
    
    Debug.log(.info, "Users initialized: {d}", .{kernel.user_count});

    // 4. Initialize framebuffer (access at 0x90000000)
    // Why: Display boot messages and kernel output on screen.
    // Note: Framebuffer memory is mapped by VM at 0x90000000.
    // The kernel accesses it via store instructions, which the VM translates.
    // For now, framebuffer is initialized host-side by VM.init_framebuffer().
    // Kernel can write to it via store instructions to 0x90000000+ addresses.
    // Note: Direct pointer access in kernel requires unsafe code.
    // We'll use a syscall-based approach for kernel framebuffer access in the future.
    
    Debug.log(.info, "Framebuffer available at 0x90000000 (initialized by VM).", .{});
    Debug.log(.info, "System ready.", .{});

    // 5. Start REPL (interactive mode for development)
    // Why: Provide interactive command interface for development and testing.
    // Note: In production, this would spawn init process instead.
    const repl_mod = @import("repl.zig");
    var repl = repl_mod.Repl.init(&kernel);
    repl.run();

    // 6. Enter trap loop (handles interrupts and exceptions)
    // Why: Process pending interrupts and handle exceptions in main loop.
    // Note: This is reached if REPL exits.
    Trap.loop_with_kernel(&kernel);
}
