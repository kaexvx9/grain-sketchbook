//! Trap Handler Loop
//! Why: Main kernel loop for handling interrupts and syscalls.
//! Grain Style: Explicit state tracking, bounded execution.

const Panic = @import("panic.zig");
const InterruptController = @import("interrupt.zig").InterruptController;
const BasinKernel = @import("basin_kernel.zig").BasinKernel;
const Debug = @import("debug.zig");
const page_fault_stats = @import("page_fault_stats.zig");
const exception_types = @import("exception_types.zig");

/// Exception type (unified for RISC-V and AArch64).
/// Why: Explicit exception types for type safety, architecture-agnostic.
/// Note: Re-exports unified ExceptionType from exception_types.zig.
pub const ExceptionType = exception_types.ExceptionType;

/// Trap loop (main kernel loop).
/// Why: Process interrupts and handle syscalls in main loop.
/// Contract: Must be called from kernel main, runs indefinitely.
/// Note: In VM, syscalls are handled by VM's syscall handler.
///       This loop processes pending interrupts and exceptions.
/// GrainStyle: Bounded loops, explicit state tracking, no recursion.
pub fn loop_with_kernel(kernel: *BasinKernel) noreturn {
    // Assert: Kernel pointer must be valid (precondition).
    const kernel_ptr = @intFromPtr(kernel);
    Debug.kassert(kernel_ptr != 0, "Kernel ptr is null", .{});
    Debug.kassert(kernel_ptr % @alignOf(BasinKernel) == 0, "Kernel ptr unaligned", .{});
    
    Panic.write("grain kernel: entering trap loop\n");
    
    // Main trap loop (bounded iterations per cycle).
    // Why: Process interrupts and exceptions in main loop.
    // GrainStyle: Bounded execution, no infinite loops without bounds.
    var iteration_count: u32 = 0;
    const MAX_ITERATIONS_PER_CYCLE: u32 = 1000; // Prevent infinite loops.
    
    while (true) {
        // Assert: Iteration count must be bounded (invariant).
        Debug.kassert(iteration_count < MAX_ITERATIONS_PER_CYCLE, "Iteration count overflow", .{});
        
        // Process pending interrupts.
        // Why: Handle deferred interrupts (timer, external, software).
        kernel.interrupt_controller.process_pending();
        
        // Assert: Interrupt controller must be initialized (postcondition).
        Debug.kassert(kernel.interrupt_controller.initialized, "Interrupt controller not initialized", .{});
        
        // Yield CPU if no work (cooperative scheduling).
        // Why: Allow other processes to run if current process yields.
        // Note: In VM, scheduling is handled by VM's step loop.
        // This is a placeholder for future cooperative scheduling.
        
        // Reset iteration count periodically (prevent overflow).
        iteration_count += 1;
        if (iteration_count >= MAX_ITERATIONS_PER_CYCLE) {
            iteration_count = 0;
        }
    }
}

/// Legacy trap loop (backward compatibility).
/// Why: Maintain compatibility with existing code that calls loop().
/// Contract: Must be called from kernel main, runs indefinitely.
/// Note: This version doesn't process interrupts (requires kernel reference).
///       Use loop_with_kernel() for full functionality.
pub fn loop() noreturn {
    Panic.write("grain kernel: entering trap loop (legacy mode)\n");
    
    // Legacy loop (no interrupt processing).
    // Why: Backward compatibility with code that doesn't pass kernel reference.
    // Note: In VM environment, interrupts are processed via VM's interrupt handling.
    while (true) {
        // Empty loop (interrupts handled by VM).
    }
}

/// Log exception and record page fault stats if applicable.
fn log_and_record_exception(
    kernel: *BasinKernel,
    exc: ExceptionType,
    pc: u64,
    val: u64,
) void {
    switch (exc) {
        .illegal_instruction => Debug.kprint("kernel: illegal instr PC=0x{x}\n", .{pc}),
        .load_address_misaligned, .store_address_misaligned => {
            Debug.kprint("kernel: misaligned PC=0x{x} addr=0x{x}\n", .{ pc, val });
        },
        .load_access_fault, .store_access_fault => {
            Debug.kprint("kernel: access fault PC=0x{x} addr=0x{x}\n", .{ pc, val });
        },
        .instruction_access_fault => Debug.kprint("kernel: instr fault PC=0x{x}\n", .{pc}),
        .instruction_page_fault => {
            Debug.kprint("kernel: instr page fault PC=0x{x}\n", .{pc});
            kernel.page_fault_stats.record_page_fault(.instruction, val);
        },
        .load_page_fault, .store_page_fault => {
            Debug.kprint("kernel: page fault PC=0x{x} addr=0x{x}\n", .{ pc, val });
            const ft = if (exc == .load_page_fault) page_fault_stats.PageFaultType.load else .store;
            kernel.page_fault_stats.record_page_fault(ft, val);
        },
        .breakpoint => Debug.kprint("kernel: breakpoint PC=0x{x}\n", .{pc}),
        .environment_call_from_u_mode, .environment_call_from_s_mode => {
            Debug.kprint("kernel: ecall PC=0x{x}\n", .{pc});
        },
        else => Debug.kprint("kernel: exc {d} PC=0x{x}\n", .{ @intFromEnum(exc), pc }),
    }
}

/// Why: Process exceptions (illegal instruction, misaligned access, etc.).
pub fn handle_exception(
    kernel: *BasinKernel,
    exception_type: ExceptionType,
    exception_pc: u64,
    exception_value: u64,
) void {
    log_and_record_exception(kernel, exception_type, exception_pc, exception_value);

    if (is_fatal_exception(exception_type)) {
        terminate_process_on_exception(kernel, exception_type, exception_pc);
    }
}

/// Check if exception is fatal (should terminate process).
/// Why: Determine which exceptions should terminate the process.
/// Contract: Exception type must be valid.
/// Returns: true if exception is fatal, false otherwise.
fn is_fatal_exception(exception_type: ExceptionType) bool {
    return switch (exception_type) {
        .illegal_instruction,
        .load_address_misaligned,
        .store_address_misaligned,
        .load_access_fault,
        .store_access_fault,
        .instruction_access_fault,
        .instruction_page_fault,
        .load_page_fault,
        .store_page_fault,
        => true,
        .breakpoint,
        .environment_call_from_u_mode,
        .environment_call_from_s_mode,
        .instruction_address_misaligned,
        => false,
    };
}

/// Terminate current process on fatal exception.
/// Why: Cleanly terminate process when fatal exception occurs.
/// Contract: Kernel must be initialized, current process must exist.
/// GrainStyle: Explicit error handling, bounded execution.
/// Find process index, using cache or fallback search.
fn find_process_for_termination(kernel: *BasinKernel, pid: u64) ?u32 {
    if (kernel.find_current_process_index()) |idx| return idx;
    var i: u32 = 0;
    while (i < 16) : (i += 1) {
        if (kernel.processes[i].allocated and kernel.processes[i].id == pid) return i;
    }
    return null;
}

/// Mark process as terminated and cleanup.
fn do_terminate_process(kernel: *BasinKernel, idx: u32, exit_status: u32, pid: u64) void {
    const process = &kernel.processes[idx];
    process.state = .exited;
    process.exit_status = exit_status;

    if (kernel.scheduler.is_current(pid)) {
        kernel.scheduler.clear_current();
        kernel.invalidate_current_process_cache();
    }

    const resource_cleanup = @import("resource_cleanup.zig");
    _ = resource_cleanup.cleanup_process_resources(kernel, @truncate(pid));
}

fn terminate_process_on_exception(
    kernel: *BasinKernel,
    exception_type: ExceptionType,
    exception_pc: u64,
) void {
    const pid = kernel.scheduler.get_current();
    if (pid == 0) {
        Debug.kprint("kernel: no process to terminate\n", .{});
        return;
    }

    const idx = find_process_for_termination(kernel, pid) orelse {
        Debug.kprint("kernel: pid {d} not found\n", .{pid});
        return;
    };

    const exc_code = @intFromEnum(exception_type);
    const exit_status: u32 = 128 + @as(u32, @truncate(exc_code));

    do_terminate_process(kernel, idx, exit_status, pid);
    Debug.kprint("kernel: pid {d} exc {d} PC=0x{x}\n", .{ pid, exc_code, exception_pc });
}
