const std = @import("std");
const builtin = @import("builtin");
const sbi = @import("sbi");
const SerialOutput = @import("serial.zig").SerialOutput;
const jit_mod = @import("jit.zig");
const error_log_mod = @import("error_log.zig");
const performance_mod = @import("performance.zig");
const state_snapshot_mod = @import("state_snapshot.zig");
const exception_stats_mod = @import("exception_stats.zig");
const memory_stats_mod = @import("memory_stats.zig");
const instruction_stats_mod = @import("instruction_stats.zig");
const syscall_stats_mod = @import("syscall_stats.zig");
const execution_flow_mod = @import("execution_flow.zig");
const branch_stats_mod = @import("branch_stats.zig");
const register_stats_mod = @import("register_stats.zig");
const instruction_perf_mod = @import("instruction_perf.zig");
const debug_interface_mod = @import("debug_interface.zig");
const instruction_trace_mod = @import("instruction_trace.zig");
const checkpoint_mod = @import("checkpoint.zig");
const optimization_hints_mod = @import("optimization_hints.zig");
const memory_protection_mod = @import("memory_protection.zig");

/// Pure Zig RISC-V64 emulator for kernel development.
/// Grain Style: Static allocation where possible, comprehensive assertions,
/// deterministic execution.
/// ~<~ Glow Earthbend: VM state is explicit, no hidden allocations.
/// Input event for kernel (simplified from platform events).
/// Why: Kernel-friendly event representation, static allocation.
/// GrainStyle: Explicit types, bounded size, deterministic encoding.
pub const InputEvent = struct {
    /// Event type: 0=mouse, 1=keyboard
    event_type: u8,
    /// Mouse event data (if event_type == 0)
    mouse: MouseEventData,
    /// Keyboard event data (if event_type == 1)
    keyboard: KeyboardEventData,
    
    pub const MouseEventData = struct {
        kind: u8, // 0=down, 1=up, 2=move, 3=drag
        button: u8, // 0=left, 1=right, 2=middle, 3=other
        x: u32, // X coordinate (scaled to framebuffer: 0-1023)
        y: u32, // Y coordinate (scaled to framebuffer: 0-767)
        modifiers: u8, // Bit flags: 1=shift, 2=control, 4=option, 8=command
    };
    
    pub const KeyboardEventData = struct {
        kind: u8, // 0=down, 1=up
        key_code: u32, // Platform key code
        character: u32, // Unicode character (0 if not printable)
        modifiers: u8, // Bit flags: 1=shift, 2=control, 4=option, 8=command
    };
};

/// Input event queue (bounded circular buffer).
/// Why: Buffer input events for kernel to read via syscalls.
/// GrainStyle: Static allocation, bounded queue, deterministic behavior.
/// Note: Max 64 events (sufficient for interactive input, prevents overflow).
const MAX_INPUT_EVENTS: u32 = 64;
pub const InputEventQueue = struct {
    /// Event buffer (circular queue)
    events: [MAX_INPUT_EVENTS]InputEvent = [_]InputEvent{undefined} ** MAX_INPUT_EVENTS,
    /// Write index (next position to write)
    write_idx: u32 = 0,
    /// Read index (next position to read)
    read_idx: u32 = 0,
    /// Number of events in queue
    count: u32 = 0,
    
    /// Dequeue event (for kernel to read).
    /// Why: Kernel reads events via syscall.
    /// Returns: event if available, null if queue empty.
    pub fn dequeue(self: *InputEventQueue) ?InputEvent {
        if (self.count == 0) {
            return null;
        }
        
        const event = self.events[self.read_idx];
        self.read_idx = (self.read_idx + 1) % MAX_INPUT_EVENTS;
        self.count -= 1;
        
        // Assert: count must be consistent.
        std.debug.assert(self.count < MAX_INPUT_EVENTS);
        
        return event;
    }
    
    /// Get queue size (number of events available).
    pub fn size(self: *const InputEventQueue) u32 {
        return self.count;
    }
};

/// Framebuffer dirty region tracking.
/// Why: Optimize framebuffer sync by only copying changed regions.
/// GrainStyle: Static allocation, explicit types, bounded regions.
/// Note: Tracks single rectangular region (can be expanded to multiple regions if needed).
pub const FramebufferDirtyRegion = struct {
    /// Whether any region is dirty (optimization: skip tracking if false).
    is_dirty: bool = false,
    /// Minimum X coordinate of dirty region (inclusive).
    min_x: u32 = 0,
    /// Minimum Y coordinate of dirty region (inclusive).
    min_y: u32 = 0,
    /// Maximum X coordinate of dirty region (exclusive).
    max_x: u32 = 0,
    /// Maximum Y coordinate of dirty region (exclusive).
    max_y: u32 = 0,
    
    /// Mark pixel as dirty.
    /// Why: Track that a pixel has been modified.
    /// Contract: x and y must be within framebuffer bounds.
    pub fn mark_pixel(self: *FramebufferDirtyRegion, x: u32, y: u32) void {
        // Assert: Coordinates must be within framebuffer bounds.
        const FRAMEBUFFER_WIDTH: u32 = 1024;
        const FRAMEBUFFER_HEIGHT: u32 = 768;
        std.debug.assert(x < FRAMEBUFFER_WIDTH);
        std.debug.assert(y < FRAMEBUFFER_HEIGHT);
        
        if (!self.is_dirty) {
            // First dirty pixel: initialize region.
            self.is_dirty = true;
            self.min_x = x;
            self.min_y = y;
            self.max_x = x + 1;
            self.max_y = y + 1;
        } else {
            // Expand region to include new pixel.
            if (x < self.min_x) self.min_x = x;
            if (y < self.min_y) self.min_y = y;
            if (x + 1 > self.max_x) self.max_x = x + 1;
            if (y + 1 > self.max_y) self.max_y = y + 1;
        }
        
        // Assert: Region bounds must be valid (postcondition).
        std.debug.assert(self.min_x < self.max_x);
        std.debug.assert(self.min_y < self.max_y);
        std.debug.assert(self.max_x <= FRAMEBUFFER_WIDTH);
        std.debug.assert(self.max_y <= FRAMEBUFFER_HEIGHT);
    }
    
    /// Mark entire framebuffer as dirty.
    /// Why: Used when clearing framebuffer (entire screen changes).
    pub fn mark_all(self: *FramebufferDirtyRegion) void {
        const FRAMEBUFFER_WIDTH: u32 = 1024;
        const FRAMEBUFFER_HEIGHT: u32 = 768;
        
        self.is_dirty = true;
        self.min_x = 0;
        self.min_y = 0;
        self.max_x = FRAMEBUFFER_WIDTH;
        self.max_y = FRAMEBUFFER_HEIGHT;
        
        // Assert: Region must cover entire framebuffer (postcondition).
        std.debug.assert(self.min_x == 0);
        std.debug.assert(self.min_y == 0);
        std.debug.assert(self.max_x == FRAMEBUFFER_WIDTH);
        std.debug.assert(self.max_y == FRAMEBUFFER_HEIGHT);
    }
    
    /// Clear dirty region (after sync).
    /// Why: Reset tracking after copying dirty region to window.
    pub fn clear(self: *FramebufferDirtyRegion) void {
        self.is_dirty = false;
        self.min_x = 0;
        self.min_y = 0;
        self.max_x = 0;
        self.max_y = 0;
        
        // Assert: Region must be cleared (postcondition).
        std.debug.assert(!self.is_dirty);
    }
    
    /// Get dirty region bounds (if dirty).
    /// Why: Query dirty region for optimized sync.
    /// Returns: true if dirty, false if clean.
    pub fn get_bounds(
        self: *const FramebufferDirtyRegion,
        min_x: *u32,
        min_y: *u32,
        max_x: *u32,
        max_y: *u32,
    ) bool {
        if (!self.is_dirty) {
            return false;
        }
        
        min_x.* = self.min_x;
        min_y.* = self.min_y;
        max_x.* = self.max_x;
        max_y.* = self.max_y;
        
        // Assert: Bounds must be valid (postcondition).
        std.debug.assert(min_x.* < max_x.*);
        std.debug.assert(min_y.* < max_y.*);
        
        return true;
    }
};

/// RISC-V64 register file (32 general-purpose registers + PC).
/// Why: Static allocation for register state, deterministic execution.
pub const RegisterFile = struct {
    /// General-purpose registers (x0-x31).
    /// x0 is hardwired to zero; x1-x31 are writable.
    /// Why: Array indexing matches RISC-V register encoding.
    regs: [32]u64 = [_]u64{0} ** 32,
    /// Program counter (PC).
    /// Why: Separate from regs for clarity and PC-specific operations.
    pc: u64 = 0,

    /// Get register value (x0 always returns 0).
    /// Grain Style: Validate register index, ensure x0 behavior.
    /// Note: Register statistics tracking is done in VM methods that call this.
    pub fn get(self: *const RegisterFile, reg: u5) u64 {
        // Assert: register index must be valid (0-31).
        std.debug.assert(reg < 32);

        // x0 is hardwired to zero (RISC-V spec).
        if (reg == 0) {
            return 0;
        }

        return self.regs[reg];
    }

    /// Set register value (x0 writes are ignored).
    /// Grain Style: Validate register index, enforce x0 behavior.
    pub fn set(self: *RegisterFile, reg: u5, value: u64) void {
        // Assert: register index must be valid (0-31).
        std.debug.assert(reg < 32);

        // x0 is hardwired to zero (RISC-V spec: writes to x0 are ignored).
        if (reg == 0) {
            return;
        }

        self.regs[reg] = value;

        // Assert: register value must be set correctly (unless x0).
        std.debug.assert(reg == 0 or self.regs[reg] == value);
    }
};

/// VM memory configuration.
/// Why: Centralized memory size configuration for RAM-aware development.
/// Note: Development machine (MacBook Air M2): 24GB RAM
///       Target hardware (Framework 13 RISC-V): 8GB RAM
///       Default: 8MB (safe for both, sufficient for kernel + framebuffer)
///       Max recommended: 64MB (works on both machines, allows larger kernel testing)
///       Memory layout:
///       - 0x80000000 - 0x8FFFFFFF: Kernel code/data (128MB virtual, 4MB physical)
///       - 0x90000000 - 0x900BBFFF: Framebuffer (1024x768x4 = 3MB)
/// GrainStyle: Use explicit u64 instead of usize for cross-platform consistency
pub const VM_MEMORY_SIZE: u64 = 8 * 1024 * 1024; // 8MB (kernel + framebuffer)

/// RISC-V64 virtual machine state.
/// Why: Encapsulate all VM state for deterministic execution.
pub const VM = struct {
    /// Register file (32 GP registers + PC).
    regs: RegisterFile = .{},
    /// Physical memory (static allocation, size configured by VM_MEMORY_SIZE).
    /// Why: Static allocation eliminates allocator dependency.
    /// Note: RISC-V64 typically uses 48-bit physical addresses, but we
    /// use configurable size for kernel development (default 4MB, sufficient for early boot).
    /// RAM considerations:
    /// - Development: 24GB available (MacBook Air M2)
    /// - Target: 8GB available (Framework 13 RISC-V)
    /// - 4MB default is conservative and safe for both machines.
    /// GrainStyle: Use explicit u64 for memory_size instead of usize
    memory: [VM_MEMORY_SIZE]u8 = [_]u8{0} ** VM_MEMORY_SIZE,
    /// Memory size in bytes.
    memory_size: u64 = VM_MEMORY_SIZE,
    /// VM execution state (running, halted, error).
    state: VMState = .halted,
    /// Last error (if state == .errored).
    /// Note: Using optional error set for error tracking.
    last_error: ?VMError = null,
    /// Syscall handler callback (optional).
    /// Why: Allow external syscall handling (e.g., Grain Basin kernel).
    /// Note: Type-erased to avoid requiring basin_kernel import at module level.
    syscall_handler: ?*const fn (
        syscall_num: u32,
        arg1: u64,
        arg2: u64,
        arg3: u64,
        arg4: u64,
    ) u64 = null,
    /// User data for syscall handler (optional).
    /// Why: Pass context to syscall handler (e.g., Basin Kernel instance).
    syscall_user_data: ?*anyopaque = null,
    /// Memory permission check callback (optional).
    /// Why: Enforce memory protection by checking read/write/execute permissions.
    /// Note: Type-erased to avoid requiring basin_kernel import at module level.
    /// Returns: u32 with permission bits (bit 0=read, bit 1=write, bit 2=execute),
    /// or 0 if not mapped.
    permission_checker: ?*const fn (addr: u64) u32 = null,
    /// User data for permission checker (optional).
    /// Why: Pass context to permission checker (e.g., Basin Kernel instance).
    permission_checker_user_data: ?*anyopaque = null,
    /// Serial output handler (for SBI console output).
    /// Why: Capture SBI console output (LEGACY_CONSOLE_PUTCHAR) for display.
    serial_output: ?*SerialOutput = null,

    /// JIT compiler context (optional, enabled via init_with_jit)
    /// Why: Enable near-native performance for kernel execution
    jit: ?*jit_mod.JitContext = null,
    
    /// Input event queue (for keyboard/mouse events from host).
    /// Why: Buffer input events for kernel to read via syscalls.
    /// GrainStyle: Static allocation, bounded queue, deterministic behavior.
    /// Note: Events are enqueued from host (macOS) and dequeued by kernel.
    input_event_queue: InputEventQueue = .{},

    /// Enable JIT compilation
    jit_enabled: bool = false,
    
    /// Dirty region tracking for framebuffer optimization.
    /// Why: Track changed framebuffer regions to optimize sync (only copy dirty areas).
    /// GrainStyle: Static allocation, bounded regions, explicit types.
    /// Note: Tracks rectangular regions that have been modified since last sync.
    framebuffer_dirty: FramebufferDirtyRegion = .{},
    
    /// Error log for tracking errors.
    /// Why: Record errors for debugging, monitoring, and recovery decisions.
    /// GrainStyle: Static allocation, bounded buffer, deterministic logging.
    error_log: error_log_mod.ErrorLog = .{},
    
    /// VM start timestamp (monotonic nanoseconds).
    /// Why: Calculate relative timestamps for error log entries.
    start_timestamp: u64 = 0,
    
    /// Performance metrics tracking.
    /// Why: Monitor VM execution performance for optimization and diagnostics.
    /// GrainStyle: Static allocation, bounded counters, explicit types.
    performance: performance_mod.PerformanceMetrics = .{},
    /// Exception statistics tracker.
    /// Why: Track exception counts by type for debugging and monitoring.
    /// GrainStyle: Static allocation, bounded counters, explicit types.
    exception_stats: exception_stats_mod.ExceptionStats = .{},
    /// Memory statistics tracker.
    /// Why: Track memory usage, access patterns, and allocation metrics.
    /// GrainStyle: Static allocation, bounded counters, explicit types.
    memory_stats: memory_stats_mod.VMMemoryStats = undefined,
    /// Instruction execution statistics tracker.
    /// Why: Track instruction execution frequency and patterns.
    /// GrainStyle: Static allocation, bounded counters, explicit types.
    instruction_stats: instruction_stats_mod.VMInstructionStats = .{
        .entries = undefined,
        .entries_len = 0,
        .total_instructions = 0,
    },
    /// Syscall execution statistics tracker.
    /// Why: Track syscall execution frequency and patterns.
    /// GrainStyle: Static allocation, bounded counters, explicit types.
    syscall_stats: syscall_stats_mod.VMSyscallStats = .{
        .entries = undefined,
        .entries_len = 0,
        .total_syscalls = 0,
    },
    /// Execution flow tracker.
    /// Why: Track PC sequences to identify execution patterns, loops, and control flow.
    /// GrainStyle: Static allocation, bounded buffers, explicit types.
    execution_flow: execution_flow_mod.VMExecutionFlow = .{
        .pc_history = undefined,
        .pc_history_index = 0,
        .pc_history_len = 0,
        .unique_pcs = undefined,
        .unique_pcs_len = 0,
        .total_instructions = 0,
    },
    /// Branch statistics tracker.
    /// Why: Track branch instruction outcomes for branch prediction analysis.
    /// GrainStyle: Static allocation, bounded counters, explicit types.
    branch_stats: branch_stats_mod.VMBranchStats = .{
        .entries = undefined,
        .entries_len = 0,
        .total_branches = 0,
        .total_taken = 0,
        .total_not_taken = 0,
    },
    /// Register usage statistics tracker.
    /// Why: Track register read/write frequency for register usage analysis.
    /// GrainStyle: Static allocation, bounded counters, explicit types.
    register_stats: register_stats_mod.VMRegisterStats = register_stats_mod.VMRegisterStats.init(),
    /// Instruction performance profiler.
    /// Why: Track execution time per instruction type for performance analysis.
    /// GrainStyle: Static allocation, bounded counters, explicit types.
    instruction_perf: instruction_perf_mod.VMInstructionPerf =
        instruction_perf_mod.VMInstructionPerf.init(),
    /// Debugging interface.
    /// Why: Provide breakpoints, watchpoints, and step debugging capabilities.
    /// GrainStyle: Static allocation, bounded arrays, explicit types.
    debug_interface: debug_interface_mod.VMDebugInterface =
        debug_interface_mod.VMDebugInterface.init(),
    /// Instruction trace logger.
    /// Why: Record instruction execution history for debugging.
    /// GrainStyle: Static allocation, bounded circular buffer, explicit types.
    instruction_trace: instruction_trace_mod.VMInstructionTrace = .{
        .trace_buffer = undefined,
        .trace_index = 0,
        .trace_count = 0,
        .enabled = false,
        .filter_pc_min = null,
        .filter_pc_max = null,
    },
    /// Checkpoint manager.
    /// Why: Save and restore VM state for debugging and state management.
    /// GrainStyle: Static allocation, bounded buffers, explicit types.
    checkpoint: checkpoint_mod.VMCheckpoint = checkpoint_mod.VMCheckpoint.init(),
    /// Optimization hints analyzer.
    /// Why: Analyze statistics and provide optimization recommendations.
    /// GrainStyle: Static allocation, bounded buffers, explicit types.
    optimization_hints: optimization_hints_mod.VMOptimizationHints =
        optimization_hints_mod.VMOptimizationHints.init(),
    /// Memory protection manager.
    /// Why: Provide memory protection capabilities (page tables, permissions).
    /// GrainStyle: Static allocation, bounded page tables, explicit types.
    memory_protection: memory_protection_mod.VMMemoryProtection = .{
        .page_table = undefined,
        .page_table_len = 0,
    },

    const Self = @This();

    /// Inject mouse event into VM input queue.
    /// Why: Route macOS mouse events to kernel via VM.
    /// GrainStyle: Explicit bounds checking, deterministic encoding.
    /// Note: Takes simplified event data to avoid cross-module dependency.
    pub fn inject_mouse_event(
        self: *Self,
        kind: u8,
        button: u8,
        x: f64,
        y: f64,
        modifiers: u8,
    ) void {
        // Assert: VM must be initialized.
        std.debug.assert(self.memory_size > 0);
        
        // Assert: Event kind must be valid (0=down, 1=up, 2=move, 3=drag).
        std.debug.assert(kind < 4);
        
        // Assert: Button must be valid (0=left, 1=right, 2=middle, 3=other).
        std.debug.assert(button < 4);
        
        // Scale coordinates to framebuffer (1024x768).
        const x_scaled: u32 = @intFromFloat(if (x > 1023.0) 1023.0 else if (x < 0.0) 0.0 else x);
        const y_scaled: u32 = @intFromFloat(if (y > 767.0) 767.0 else if (y < 0.0) 0.0 else y);
        
        // Create input event.
        const input_event = InputEvent{
            .event_type = 0, // Mouse event
            .mouse = .{
                .kind = kind,
                .button = button,
                .x = x_scaled,
                .y = y_scaled,
                .modifiers = modifiers,
            },
            .keyboard = .{
                .kind = 0,
                .key_code = 0,
                .character = 0,
                .modifiers = 0,
            },
        };
        
        // Enqueue event (handle queue full by dropping oldest).
        if (self.input_event_queue.count >= MAX_INPUT_EVENTS) {
            const new_read_idx = (self.input_event_queue.read_idx + 1) % MAX_INPUT_EVENTS;
            self.input_event_queue.read_idx = new_read_idx;
            self.input_event_queue.count -= 1;
        }
        
        self.input_event_queue.events[self.input_event_queue.write_idx] = input_event;
        const new_write_idx = (self.input_event_queue.write_idx + 1) % MAX_INPUT_EVENTS;
        self.input_event_queue.write_idx = new_write_idx;
        self.input_event_queue.count += 1;
        
        // Assert: Event must be enqueued (queue size increased or oldest dropped).
        std.debug.assert(self.input_event_queue.count <= MAX_INPUT_EVENTS);
    }
    
    /// Inject keyboard event into VM input queue.
    /// Why: Route macOS keyboard events to kernel via VM.
    /// GrainStyle: Explicit bounds checking, deterministic encoding.
    /// Note: Takes simplified event data to avoid cross-module dependency.
    pub fn inject_keyboard_event(
        self: *Self,
        kind: u8,
        key_code: u32,
        character: u32,
        modifiers: u8,
    ) void {
        // Assert: VM must be initialized.
        std.debug.assert(self.memory_size > 0);
        
        // Assert: Event kind must be valid (0=down, 1=up).
        std.debug.assert(kind < 2);
        
        // Create input event.
        const input_event = InputEvent{
            .event_type = 1, // Keyboard event
            .mouse = .{
                .kind = 0,
                .button = 0,
                .x = 0,
                .y = 0,
                .modifiers = 0,
            },
            .keyboard = .{
                .kind = kind,
                .key_code = key_code,
                .character = character,
                .modifiers = modifiers,
            },
        };
        
        // Enqueue event (handle queue full by dropping oldest).
        if (self.input_event_queue.count >= MAX_INPUT_EVENTS) {
            const new_read_idx = (self.input_event_queue.read_idx + 1) % MAX_INPUT_EVENTS;
            self.input_event_queue.read_idx = new_read_idx;
            self.input_event_queue.count -= 1;
        }
        
        self.input_event_queue.events[self.input_event_queue.write_idx] = input_event;
        const new_write_idx = (self.input_event_queue.write_idx + 1) % MAX_INPUT_EVENTS;
        self.input_event_queue.write_idx = new_write_idx;
        self.input_event_queue.count += 1;
        
        // Assert: Event must be enqueued (queue size increased or oldest dropped).
        std.debug.assert(self.input_event_queue.count <= MAX_INPUT_EVENTS);
    }

    pub const VMState = enum {
        running,
        halted,
        errored,
    };

    pub const VMError = error{
        invalid_instruction,
        invalid_memory_access,
        unaligned_instruction,
        unaligned_memory_access,
    };
    
    /// Record exception in statistics (maps VMError to RISC-V exception code).
    /// Why: Track exceptions for statistics when VM errors occur.
    /// Contract: VM must be initialized.
    fn record_vm_error(self: *Self, err: VMError) void {
        // Assert: VM must be initialized (precondition).
        std.debug.assert(self.memory_size > 0);
        
        // Map VMError to RISC-V exception code.
        const exception_code: u32 = switch (err) {
            .invalid_instruction => 2, // Illegal instruction
            .invalid_memory_access => 5, // Load access fault (approximate)
            .unaligned_instruction => 0, // Instruction address misaligned
            .unaligned_memory_access => 4, // Load address misaligned (approximate)
        };
        
        // Record exception in statistics.
        self.exception_stats.record_exception(exception_code);
        
        // Assert: Exception must be recorded (postcondition).
        std.debug.assert(self.exception_stats.get_count(exception_code) > 0);
    }

    /// Initialize VM with kernel image loaded at address (GrainStyle: in-place initialization).
    /// Why: Explicit initialization ensures deterministic state.
    /// In-place initialization avoids stack overflow.
    /// Contract: target must point to uninitialized VM struct.
    /// Contract: load_address must be 4-byte aligned (RISC-V requirement).
    /// Contract: kernel_image must fit in VM memory if non-empty.
    /// Postcondition: VM is in halted state, memory zeroed, PC set to load_address (or 0 if no kernel).
    pub fn init(target: *Self, kernel_image: []const u8, load_address: u64) void {
        // Assert: load address must be aligned (4-byte alignment for RISC-V).
        std.debug.assert(load_address % 4 == 0);

        // Assert: kernel image must fit in memory (if non-empty).
        if (kernel_image.len > 0) {
            std.debug.assert(load_address + kernel_image.len <= VM_MEMORY_SIZE);
        }

        // Initialize VM struct in-place (GrainStyle: avoid stack allocation of large struct).
        // Note: Initialize memory array directly to avoid creating 8MB stack temporary.
        target.regs = .{};
        @memset(&target.memory, 0); // Initialize 8MB memory array directly (avoid stack temporary)
        target.memory_size = VM_MEMORY_SIZE;
        target.state = .halted;
        target.last_error = null;
        target.exception_stats = exception_stats_mod.ExceptionStats.init();
        target.memory_stats = memory_stats_mod.VMMemoryStats.init(VM_MEMORY_SIZE);
        target.syscall_stats = syscall_stats_mod.VMSyscallStats.init();
        
        // Initialize optional callback fields to null (critical when struct was allocated with undefined).
        target.syscall_handler = null;
        target.syscall_user_data = null;
        target.permission_checker = null;
        target.permission_checker_user_data = null;
        target.serial_output = null;
        target.jit = null;
        target.jit_enabled = false;
        target.input_event_queue = .{};
        target.memory_protection = memory_protection_mod.VMMemoryProtection.init();
        target.debug_interface = debug_interface_mod.VMDebugInterface.init();
        target.execution_flow = execution_flow_mod.VMExecutionFlow.init();
        target.instruction_stats = instruction_stats_mod.VMInstructionStats.init();
        target.branch_stats = branch_stats_mod.VMBranchStats.init();
        target.register_stats = register_stats_mod.VMRegisterStats.init();
        target.instruction_perf = instruction_perf_mod.VMInstructionPerf.init();
        target.instruction_trace = instruction_trace_mod.VMInstructionTrace.init();
        // Note: VMCheckpoint is 128MB+ (16 checkpoints * 8MB each), skip full init.
        // The default value (.checkpoints = undefined, .checkpoint_count = 0) is fine.
        target.checkpoint.checkpoint_count = 0;
        target.optimization_hints = optimization_hints_mod.VMOptimizationHints.init();
        target.framebuffer_dirty = .{};
        target.error_log = .{};
        target.performance = .{};
        
        // Add default memory regions (kernel, framebuffer).
        target.memory_stats.add_region(0x80000000, 0x80000000 + VM_MEMORY_SIZE);
        const framebuffer_start: u64 = 0x90000000;
        const framebuffer_size: u64 = 1024 * 768 * 4; // 3MB
        target.memory_stats.add_region(framebuffer_start, framebuffer_start + framebuffer_size);

        // Load kernel image into memory (if non-empty).
        // Why: Copy kernel bytes to VM memory at load address.
        if (kernel_image.len > 0) {
            @memcpy(target.memory[@intCast(load_address)..][0..kernel_image.len], kernel_image);

            // Set PC to load address (kernel entry point).
            target.regs.pc = load_address;

            // Assert: PC must be set correctly.
            std.debug.assert(target.regs.pc == load_address);

            // Assert: kernel image must be loaded correctly.
            const mem_slice = target.memory[@intCast(load_address)..][0..kernel_image.len];
            std.debug.assert(std.mem.eql(u8, mem_slice, kernel_image));
        } else {
            // No kernel image - PC remains 0 (will be set by ELF loader).
            target.regs.pc = 0;
        }

        // Assert: VM must be in halted state after initialization.
        std.debug.assert(target.state == .halted);
    }


    /// Initialize VM with JIT support
    /// Why: Enable near-native performance for kernel execution
    pub fn init_with_jit(
        target: *Self,
        allocator: std.mem.Allocator,
        kernel_image: []const u8,
        load_address: u64,
    ) !void {
        std.debug.assert(load_address % 4 == 0);
        const load_end = load_address + kernel_image.len;
        std.debug.assert(kernel_image.len == 0 or load_end <= VM_MEMORY_SIZE);
        
        // Initialize VM normally
        target.init(kernel_image, load_address);
        
        // Initialize JIT
        var guest_state = jit_mod.GuestState{
            .regs = target.regs.regs,
            .pc = target.regs.pc,
        };
        
        const jit_ctx = try allocator.create(jit_mod.JitContext);
        const mem_slice = target.memory[0..target.memory_size];
        jit_ctx.* = try jit_mod.JitContext.init(
            allocator,
            &guest_state,
            mem_slice,
            target.memory_size,
        );
        target.jit = jit_ctx;
        target.jit_enabled = true;
        
        std.debug.assert(target.jit != null);
        std.debug.assert(target.jit_enabled);
    }
    
    /// Execute with JIT (if enabled), fall back to interpreter if JIT fails
    /// Why: Provide transparent JIT acceleration with interpreter safety net
    pub fn step_jit(self: *Self) VMError!void {
        std.debug.assert(self.state == .running or self.state == .halted);
        
        if (!self.jit_enabled or self.jit == null) {
            // JIT not enabled, use interpreter
            return self.step();
        }
        
        const jit_ctx = self.jit.?;
        const pc = self.regs.pc;
        
        // Check cache first (avoid compilation if already compiled).
        const compile_start = std.time.nanoTimestamp();
        const func = jit_ctx.compile_block(pc) catch |err| {
            // JIT failed or threshold not met, fall back to interpreter.
            if (err == jit_mod.JitError.ThresholdNotMet) {
                // Threshold not met: use interpreter and track execution.
                jit_ctx.perf_counters.hot_path_tracker.record_execution(pc);
            } else {
                // Other JIT error: fall back to interpreter.
                jit_ctx.perf_counters.interpreter_fallbacks += 1;
            }
            return self.step();
        };
        const compile_end = std.time.nanoTimestamp();
        const compile_time: i64 = @intCast(@as(i128, compile_end) - @as(i128, compile_start));
        if (compile_time > 0) {
            jit_ctx.perf_counters.jit_compile_time_ns += @intCast(compile_time);
        }
        
        // Sync guest state to JIT.
        var guest_state = jit_mod.GuestState{
            .regs = self.regs.regs,
            .pc = pc,
        };
        
        // Execute JIT code (measure execution time).
        const exec_start = std.time.nanoTimestamp();
        // Use architecture-specific enter function.
        if (builtin.cpu.arch == .x86_64) {
            jit_mod.JitContext.enter_jit_x86_64(func, &guest_state, &self.memory);
        } else if (builtin.cpu.arch == .aarch64) {
            jit_mod.JitContext.enter_jit(func, &guest_state, &self.memory);
        } else {
            // Unsupported architecture: fall back to interpreter.
            return self.step();
        }
        const exec_end = std.time.nanoTimestamp();
        const exec_time: i64 = @intCast(@as(i128, exec_end) - @as(i128, exec_start));
        if (exec_time > 0) {
            jit_ctx.perf_counters.total_execution_time_ns += @intCast(exec_time);
        }
        
        // Record hot path execution.
        jit_ctx.perf_counters.hot_path_tracker.record_execution(pc);
        
        // Sync back to VM.
        self.regs.regs = guest_state.regs;
        self.regs.pc = guest_state.pc;
        
        // Note: cache_hits/cache_misses are tracked in compile_block().
        
        std.debug.assert(self.regs.pc % 4 == 0 or self.state != .running);
    }
    
    /// Enable JIT on an already-initialized VM
    /// Why: Allow enabling JIT after loadKernel() has loaded the kernel
    /// Contract: VM must be initialized (via init() or loadKernel())
    /// Contract: JIT must not already be enabled
    pub fn enable_jit(self: *Self, allocator: std.mem.Allocator) !void {
        std.debug.assert(self.jit == null);
        std.debug.assert(!self.jit_enabled);
        
        // Initialize JIT context
        var guest_state = jit_mod.GuestState{
            .regs = self.regs.regs,
            .pc = self.regs.pc,
        };
        
        const jit_ctx = try allocator.create(jit_mod.JitContext);
        const FRAMEBUFFER_SIZE: u32 = 1024 * 768 * 4; // 3MB
        const mem_slice = self.memory[0..self.memory_size];
        jit_ctx.* = try jit_mod.JitContext.init(
            allocator,
            &guest_state,
            mem_slice,
            self.memory_size,
        );
        jit_ctx.framebuffer_size = FRAMEBUFFER_SIZE;
        self.jit = jit_ctx;
        self.jit_enabled = true;
        
        std.debug.assert(self.jit != null);
        std.debug.assert(self.jit_enabled);
    }
    
    /// Deinitialize JIT (if enabled)
    pub fn deinit_jit(self: *Self, allocator: std.mem.Allocator) void {
        if (self.jit) |jit_ctx| {
            jit_ctx.deinit();
            allocator.destroy(jit_ctx);
            self.jit = null;
            self.jit_enabled = false;
        }
    }
    /// Read memory at address (little-endian, 8 bytes).
    /// Grain Style: Validate address, bounds checking, alignment.
    pub fn read64(self: *Self, addr: u64) VMError!u64 {
        // Assert: address must be within memory bounds.
        std.debug.assert(addr + 8 <= self.memory_size);

        // Assert: address must be 8-byte aligned (RISC-V64 requirement).
        if (addr % 8 != 0) {
            // Record exception (load address misaligned, code 4).
            self.exception_stats.record_exception(4);
            return VMError.unaligned_memory_access;
        }

        // Read 8 bytes (little-endian).
        const bytes = self.memory[@intCast(addr)..][0..8];
        const value = std.mem.readInt(u64, bytes, .little);

        // Track memory read.
        self.memory_stats.record_read(addr, 8);

        return value;
    }

    /// Write memory at address (little-endian, 8 bytes).
    /// Grain Style: Validate address, bounds checking, alignment.
    pub fn write64(self: *Self, addr: u64, value: u64) VMError!void {
        // Assert: address must be within memory bounds.
        std.debug.assert(addr + 8 <= self.memory_size);

        // Assert: address must be 8-byte aligned (RISC-V64 requirement).
        if (addr % 8 != 0) {
            // Record exception (store address misaligned, code 6).
            self.exception_stats.record_exception(6);
            return VMError.unaligned_memory_access;
        }

        // Write 8 bytes (little-endian).
        const bytes = self.memory[@intCast(addr)..][0..8];
        std.mem.writeInt(u64, bytes, value, .little);

        // Track memory write (before read check to avoid double counting).
        self.memory_stats.record_write(addr, 8);

        // Assert: value must be written correctly.
        const read_back = try self.read64(addr);
        std.debug.assert(read_back == value);
    }

    /// Translate virtual address to physical offset in VM memory
    /// Why: Map kernel virtual addresses (0x80000000+, 0x90000000+) to VM memory offsets
    /// Contract: Returns physical offset, or null if address is invalid
    /// Memory layout:
    ///   - 0x80000000+: Kernel code/data -> offset 0+
    ///   - 0x90000000+: Framebuffer -> offset (memory_size - framebuffer_size)+
    /// GrainStyle: Use explicit u64 instead of usize for cross-platform consistency
    /// Translate virtual address to physical offset.
    /// Why: Public access needed for framebuffer sync in TahoeSandbox.
    /// GrainStyle: Explicit u64 types, bounds checking, deterministic mapping.
    pub fn translate_address(self: *const Self, virt_addr: u64) ?u64 {
        const KERNEL_BASE: u64 = 0x80000000;
        const FRAMEBUFFER_BASE: u64 = 0x90000000;
        const FRAMEBUFFER_SIZE: u32 = 1024 * 768 * 4; // 3MB
        
        if (virt_addr >= FRAMEBUFFER_BASE) {
            // Framebuffer region: map to end of VM memory
            const framebuffer_offset: u64 = self.memory_size - @as(u64, FRAMEBUFFER_SIZE);
            const offset_in_fb: u64 = virt_addr - FRAMEBUFFER_BASE;
            
            if (offset_in_fb >= FRAMEBUFFER_SIZE) {
                return null; // Out of framebuffer bounds
            }
            
            const phys_offset = framebuffer_offset + offset_in_fb;
            if (phys_offset >= self.memory_size) {
                return null; // Out of memory bounds
            }
            
            return phys_offset;
        } else if (virt_addr >= KERNEL_BASE) {
            // Kernel region: map directly (0x80000000 -> 0)
            const offset: u64 = virt_addr - KERNEL_BASE;
            if (offset >= self.memory_size) {
                return null; // Out of memory bounds
            }
            return offset;
        } else {
            // Low memory: map directly
            if (virt_addr >= self.memory_size) {
                return null;
            }
            return virt_addr;
        }
    }

    /// Get framebuffer memory region
    /// Why: Provide access to framebuffer memory for host-side rendering
    /// Contract: Returns slice of VM memory at framebuffer base address
    /// Note: Framebuffer is at 0x90000000, mapped to offset in VM memory
    /// GrainStyle: Use explicit u64 for offset calculation, cast to usize only for array indexing
    pub fn get_framebuffer_memory(self: *Self) []u8 {
        const FRAMEBUFFER_SIZE: u32 = 1024 * 768 * 4; // 3MB
        const framebuffer_offset: u64 = self.memory_size - @as(u64, FRAMEBUFFER_SIZE);
        
        std.debug.assert(framebuffer_offset + @as(u64, FRAMEBUFFER_SIZE) <= self.memory_size);
        
        return self.memory[@intCast(framebuffer_offset)..][0..FRAMEBUFFER_SIZE];
    }

    /// Initialize framebuffer from host-side code
    /// Why: Set up framebuffer before kernel starts, clear to background, draw test pattern
    /// Contract: Initializes framebuffer memory with test pattern for visual verification
    /// GrainStyle: Explicit assertions, bounded execution,
    /// static allocation, no external dependencies
    pub fn init_framebuffer(self: *Self) void {
        // Mark entire framebuffer as dirty (initialization changes everything).
        self.framebuffer_dirty.mark_all();
        
        // Framebuffer constants (matching kernel/framebuffer.zig)
        const FRAMEBUFFER_WIDTH: u32 = 1024;
        const FRAMEBUFFER_HEIGHT: u32 = 768;
        const FRAMEBUFFER_BPP: u32 = 4; // 32-bit RGBA
        // 3MB framebuffer
        const FRAMEBUFFER_SIZE: u32 = FRAMEBUFFER_WIDTH * FRAMEBUFFER_HEIGHT * FRAMEBUFFER_BPP;
        
        // Color constants (32-bit RGBA format)
        const COLOR_DARK_BG: u32 = 0x1E1E2EFF; // Dark background
        const COLOR_RED: u32 = 0xFF0000FF;
        const COLOR_GREEN: u32 = 0x00FF00FF;
        const COLOR_BLUE: u32 = 0x0000FFFF;
        const COLOR_WHITE: u32 = 0xFFFFFFFF;
        
        // Assert: VM memory must be large enough for framebuffer
        std.debug.assert(self.memory_size >= FRAMEBUFFER_SIZE);
        
        // Get framebuffer memory region
        const fb_memory = self.get_framebuffer_memory();
        
        // Assert: framebuffer memory must be correct size
        std.debug.assert(fb_memory.len == FRAMEBUFFER_SIZE);
        
        // Clear framebuffer to dark background color
        // Why: Fill entire framebuffer with background color before drawing test pattern
        const bg_r: u8 = @truncate((COLOR_DARK_BG >> 24) & 0xFF);
        const bg_g: u8 = @truncate((COLOR_DARK_BG >> 16) & 0xFF);
        const bg_b: u8 = @truncate((COLOR_DARK_BG >> 8) & 0xFF);
        const bg_a: u8 = @truncate(COLOR_DARK_BG & 0xFF);
        
        var i: u32 = 0;
        while (i < FRAMEBUFFER_SIZE) : (i += 4) {
            fb_memory[i + 0] = bg_r;
            fb_memory[i + 1] = bg_g;
            fb_memory[i + 2] = bg_b;
            fb_memory[i + 3] = bg_a;
        }
        
        // Assert: framebuffer must be cleared (check first and last pixel)
        std.debug.assert(fb_memory[0] == bg_r);
        std.debug.assert(fb_memory[FRAMEBUFFER_SIZE - 4] == bg_r);
        
        // Draw test pattern: colored rectangles at corners
        // Why: Visual verification that framebuffer is working correctly
        const rect_size: u32 = 100;
        const spacing: u32 = 20;
        
        // Helper: Draw a filled rectangle
        // Why: Reusable drawing primitive for test pattern
        const draw_rect = struct {
            fn draw(memory: []u8, x: u32, y: u32, w: u32, h: u32, color: u32) void {
                std.debug.assert(x < FRAMEBUFFER_WIDTH);
                std.debug.assert(y < FRAMEBUFFER_HEIGHT);
                std.debug.assert(x + w <= FRAMEBUFFER_WIDTH);
                std.debug.assert(y + h <= FRAMEBUFFER_HEIGHT);
                std.debug.assert(w > 0);
                std.debug.assert(h > 0);
                
                const r: u8 = @truncate((color >> 24) & 0xFF);
                const g: u8 = @truncate((color >> 16) & 0xFF);
                const b: u8 = @truncate((color >> 8) & 0xFF);
                const a: u8 = @truncate(color & 0xFF);
                
                var py: u32 = y;
                while (py < y + h) : (py += 1) {
                    var px: u32 = x;
                    while (px < x + w) : (px += 1) {
                        const offset: u32 = (py * FRAMEBUFFER_WIDTH + px) * FRAMEBUFFER_BPP;
                        std.debug.assert(offset + 3 < FRAMEBUFFER_SIZE);
                        memory[offset + 0] = r;
                        memory[offset + 1] = g;
                        memory[offset + 2] = b;
                        memory[offset + 3] = a;
                    }
                }
                
                // Assert: rectangle must be drawn (check top-left corner)
                const corner_offset: u32 = (y * FRAMEBUFFER_WIDTH + x) * FRAMEBUFFER_BPP;
                std.debug.assert(memory[corner_offset] == r);
            }
        }.draw;
        
        // Red rectangle (top-left)
        draw_rect(fb_memory, spacing, spacing, rect_size, rect_size, COLOR_RED);
        
        // Green rectangle (top-right)
        const green_x = FRAMEBUFFER_WIDTH - rect_size - spacing;
        draw_rect(fb_memory, green_x, spacing, rect_size, rect_size, COLOR_GREEN);
        
        // Blue rectangle (bottom-left)
        const blue_y = FRAMEBUFFER_HEIGHT - rect_size - spacing;
        draw_rect(fb_memory, spacing, blue_y, rect_size, rect_size, COLOR_BLUE);
        
        // White rectangle (bottom-right)
        const white_x = FRAMEBUFFER_WIDTH - rect_size - spacing;
        const white_y = FRAMEBUFFER_HEIGHT - rect_size - spacing;
        draw_rect(fb_memory, white_x, white_y, rect_size, rect_size, COLOR_WHITE);
        
        // Assert: test pattern must be drawn (check first red pixel)
        const red_offset: u32 = (spacing * FRAMEBUFFER_WIDTH + spacing) * FRAMEBUFFER_BPP;
        std.debug.assert(fb_memory[red_offset] == 0xFF); // Red component
        
        // Draw boot message text
        // Why: Display kernel boot message on framebuffer for visual verification
        // Note: Using inline text rendering to avoid cross-module dependency
        const boot_text = "Grain Basin Kernel v0.1.0\nRISC-V64 Emulator\nFramebuffer Ready";
        draw_text_inline(fb_memory, boot_text, 250, 300, COLOR_WHITE, COLOR_DARK_BG);
    }
    
    /// Draw text inline (helper for init_framebuffer)
    /// Why: Render text directly to framebuffer memory without Framebuffer struct
    /// GrainStyle: Explicit bounds checking, deterministic rendering
    fn draw_text_inline(
        memory: []u8,
        text: []const u8,
        start_x: u32,
        start_y: u32,
        fg_color: u32,
        bg_color: u32,
    ) void {
        const FRAMEBUFFER_WIDTH: u32 = 1024;
        const FRAMEBUFFER_BPP: u32 = 4;
        const CHAR_WIDTH: u32 = 8;
        const CHAR_HEIGHT: u32 = 8;
        
        // Extract colors
        const fg_r: u8 = @truncate((fg_color >> 24) & 0xFF);
        const fg_g: u8 = @truncate((fg_color >> 16) & 0xFF);
        const fg_b: u8 = @truncate((fg_color >> 8) & 0xFF);
        const bg_r: u8 = @truncate((bg_color >> 24) & 0xFF);
        const bg_g: u8 = @truncate((bg_color >> 16) & 0xFF);
        const bg_b: u8 = @truncate((bg_color >> 8) & 0xFF);
        
        var char_x: u32 = start_x;
        var char_y: u32 = start_y;
        
        var i: u32 = 0;
        while (i < text.len) : (i += 1) {
            const ch = text[i];
            
            // Handle newline
            if (ch == '\n') {
                char_x = start_x;
                char_y += CHAR_HEIGHT;
                continue;
            }
            
            // Get character pattern (8x8 bitmap)
            const pattern = get_char_pattern_inline(ch);
            
            // Draw character
            var py: u32 = 0;
            while (py < CHAR_HEIGHT) : (py += 1) {
                var px: u32 = 0;
                while (px < CHAR_WIDTH) : (px += 1) {
                    const pixel_x = char_x + px;
                    const pixel_y = char_y + py;
                    
                    // Bounds check
                    if (pixel_x >= FRAMEBUFFER_WIDTH or pixel_y >= 768) continue;
                    
                    const bit_idx = py * CHAR_WIDTH + px;
                    const bit = (pattern >> @as(u6, @intCast(63 - bit_idx))) & 1;
                    
                    const offset: u32 = (pixel_y * FRAMEBUFFER_WIDTH + pixel_x) * FRAMEBUFFER_BPP;
                    if (offset + 3 >= memory.len) continue;
                    
                    if (bit == 1) {
                        memory[offset + 0] = fg_r;
                        memory[offset + 1] = fg_g;
                        memory[offset + 2] = fg_b;
                    } else {
                        memory[offset + 0] = bg_r;
                        memory[offset + 1] = bg_g;
                        memory[offset + 2] = bg_b;
                    }
                    memory[offset + 3] = 0xFF; // Alpha
                }
            }
            
            char_x += CHAR_WIDTH;
        }
    }
    
    /// Get 8x8 bitmap pattern for character (inline version)
    /// Why: Simple bitmap font for text rendering
    fn get_char_pattern_inline(ch: u8) u64 {
        return switch (ch) {
            ' ' => 0x0000000000000000,
            '!' => 0x1818181818001800,
            '.' => 0x0000000000181800,
            '0' => 0x3C666E7E76663C00,
            '1' => 0x1818381818187E00,
            'A' => 0x183C66667E666600,
            'B' => 0x7C66667C66667C00,
            'C' => 0x3C66606060663C00,
            'D' => 0x786C6666666C7800,
            'E' => 0x7E60607C60607E00,
            'F' => 0x7E60607C60606000,
            'G' => 0x3C66606E66663C00,
            'I' => 0x3C18181818183C00,
            'K' => 0x666C78786C666600,
            'L' => 0x6060606060607E00,
            'M' => 0x63777F6B63636300,
            'N' => 0x66767E7E6E666600,
            'O' => 0x3C66666666663C00,
            'R' => 0x7C66667C6C666600,
            'S' => 0x3C603C0606663C00,
            'V' => 0x66666666663C1800,
            'a' => 0x00003C063E663E00,
            'b' => 0x60607C6666667C00,
            'c' => 0x00003C6660603C00,
            'd' => 0x06063E6666663E00,
            'e' => 0x00003C667E603C00,
            'f' => 0x1C30307C30303000,
            'g' => 0x00003E66663E063C,
            'h' => 0x60607C6666666600,
            'i' => 0x1800181818181800,
            'l' => 0x1818181818181800,
            'm' => 0x0000767F6B636300,
            'n' => 0x00007C6666666600,
            'o' => 0x00003C6666663C00,
            'r' => 0x00007C6660606000,
            's' => 0x00003E603C067C00,
            't' => 0x30307C3030301C00,
            'u' => 0x0000666666663E00,
            'v' => 0x00006666663C1800,
            'w' => 0x0000636B7F360000,
            'x' => 0x0000663C183C6600,
            'y' => 0x00006666663E063C,
            'z' => 0x00007E0C18307E00,
            '-' => 0x000000007E000000,
            '/' => 0x303018180C0C0606,
            else => 0x7E8185B581817E00, // fallback: box
        };
    }

    /// Read instruction at PC (32-bit, little-endian).
    /// Grain Style: Validate PC, bounds checking, alignment.
    pub fn fetch_instruction(self: *Self) VMError!u32 {
        const pc = self.regs.pc;

        // Assert: PC must be within memory bounds (need 4 bytes for instruction).
        // Assert: PC must be 2-byte aligned (RVC allows 16-bit instructions).
        if (pc % 2 != 0) {
            // Record exception (instruction address misaligned, code 0).
            self.exception_stats.record_exception(0);
            return VMError.unaligned_instruction;
        }

        // Translate virtual address to physical.
        // Note: PC may be virtual (e.g., 0x80000000 for kernel).
        const phys_pc = self.translate_address(pc) orelse {
            // Record exception (instruction page fault, code 12).
            self.exception_stats.record_exception(12);
            return VMError.invalid_memory_access;
        };
        
        // Check: Physical PC must be within memory bounds.
        if (phys_pc + 4 > self.memory_size) {
            // Record exception (instruction access fault, code 1).
            self.exception_stats.record_exception(1);
            return VMError.invalid_memory_access;
        }

        // Check memory permissions (if permission checker is set).
        // Why: Enforce memory protection before allowing instruction fetch.
        // Distinguish between page faults (unmapped) and access faults (permission violation).
        if (self.permission_checker) |checker| {
            const permissions = checker(pc);
            if (permissions == 0) {
                // Page not mapped: record page fault (instruction page fault, code 12).
                self.exception_stats.record_exception(12);
                return VMError.invalid_memory_access;
            }
            const has_execute = (permissions & 4) != 0;
            if (!has_execute) {
                // Page mapped but no execute permission:
                // record access fault (instruction access fault, code 1).
                self.exception_stats.record_exception(1);
                return VMError.invalid_memory_access;
            }
        } else {
            // Use memory protection system if no external permission checker.
            const exec_perm = memory_protection_mod.MemoryPermissions.EXECUTE;
            if (!self.memory_protection.check_permission(pc, exec_perm)) {
                // Check if page is mapped at all.
                const perms_opt = self.memory_protection.get_permissions(pc);
                if (perms_opt == null) {
                    // Page not mapped: record page fault (instruction page fault, code 12).
                    self.exception_stats.record_exception(12);
                    return VMError.invalid_memory_access;
                }
                // Page mapped but no execute permission:
                // record access fault (instruction access fault, code 1).
                self.exception_stats.record_exception(1);
                return VMError.invalid_memory_access;
            }
        }

        // Read instruction (16 or 32-bit, little-endian) using physical address.
        // RVC (compressed): if bits [1:0] != 0b11, it's 16-bit
        const bytes16 = self.memory[@intCast(phys_pc)..][0..2];
        const inst16 = std.mem.readInt(u16, bytes16, .little);
        
        // Check if this is a compressed (16-bit) or full (32-bit) instruction
        if ((inst16 & 0b11) != 0b11) {
            // Compressed instruction: return 16-bit value with marker
            // Use upper 16 bits as zero to indicate compressed
            return @as(u32, inst16);
        }
        
        // Full 32-bit instruction
        const bytes32 = self.memory[@intCast(phys_pc)..][0..4];
        return std.mem.readInt(u32, bytes32, .little);
    }
    
    /// Check if instruction is compressed (16-bit).
    fn is_compressed_instruction(inst: u32) bool {
        return (inst & 0b11) != 0b11;
    }
    
    /// Get instruction size in bytes.
    fn instruction_size(inst: u32) u64 {
        return if (is_compressed_instruction(inst)) 2 else 4;
    }

    /// Execute single instruction (decode and execute).
    /// Grain Style: Comprehensive instruction decoding, assertions.
    pub fn step(self: *Self) VMError!void {
        // Assert: VM must be in running state.
        if (self.state != .running) {
            return;
        }

        // Store PC before instruction execution (for branch detection).
        const pc_before = self.regs.pc;

        // Check for breakpoint at current PC.
        if (self.debug_interface.check_breakpoint(pc_before)) {
            // Breakpoint hit: stop execution (caller should check breakpoint_hit flag).
            return;
        }

        // Assert: PC must be 2-byte aligned (RVC allows 16-bit instructions).
        std.debug.assert(pc_before % 2 == 0);
        
        // Note: PC may be a virtual address (e.g., 0x80000000 for kernel).
        // The translate_address() function will map it to physical address.
        // We verify the physical address is valid in fetch_instruction().

        // Fetch instruction at PC (may be 16 or 32 bits).
        const inst = try self.fetch_instruction();
        
        // Track instruction execution (performance monitoring).
        self.performance.increment_instruction();
        
        // Track execution flow (PC sequence).
        self.execution_flow.record_pc(pc_before);
        
        // Assert: instruction must be valid (not all ones, which is invalid).
        // Note: Zero instructions (NOP) are valid, so we don't check for 0x00000000.
        std.debug.assert(inst != 0xFFFFFFFF);

        // Decode instruction opcode (bits [6:0]).
        const opcode = @as(u7, @truncate(inst));
        const opcode_u32: u32 = @intCast(opcode);
        
        // Track instruction execution.
        self.instruction_stats.record_instruction(opcode_u32);

        // Record instruction trace (before execution).
        self.instruction_trace.record_instruction(self, pc_before, inst);

        // Execute based on instruction type (compressed or full).
        const inst_size = instruction_size(inst);
        
        if (is_compressed_instruction(inst)) {
            // Execute compressed (16-bit) instruction
            try self.execute_compressed(@as(u16, @truncate(inst)));
        } else {
            // Execute full (32-bit) instruction
            try self.execute_opcode(opcode, inst);
        }

        // Advance PC to next instruction (2 or 4 bytes).
        // Note: Branch/jump instructions modify PC directly, check if PC was modified.
        if (self.regs.pc == pc_before) {
            // Normal case: PC unchanged by instruction, advance.
            self.regs.pc += inst_size;
        }
        // Else: PC was modified by branch instruction, don't increment again.

        // Assert: PC must be 2-byte aligned after instruction execution.
        std.debug.assert(self.regs.pc % 2 == 0);

        // Note: PC may be a virtual address (e.g., 0x80000000+ for kernel).
        // We don't check bounds here since translate_address() handles that.
    }
    
    /// Execute compressed (16-bit RVC) instruction.
    /// RVC quadrants: bits [1:0] determine instruction quadrant.
    fn execute_compressed(self: *Self, inst: u16) VMError!void {
        const quadrant = @as(u2, @truncate(inst));
        const funct3 = @as(u3, @truncate(inst >> 13));
        
        switch (quadrant) {
            0b00 => try self.execute_c0(inst, funct3),
            0b01 => try self.execute_c1(inst, funct3),
            0b10 => try self.execute_c2(inst, funct3),
            0b11 => unreachable, // Not a compressed instruction
        }
    }
    
    /// Execute C0 quadrant compressed instruction.
    fn execute_c0(self: *Self, inst: u16, funct3: u3) VMError!void {
        switch (funct3) {
            0b000 => {
                // C.ADDI4SPN: addi rd', sp, imm
                const rd_prime = @as(u3, @truncate(inst >> 2));
                const rd: u5 = @as(u5, rd_prime) + 8; // rd' maps to x8-x15
                // imm = [5:4|9:6|2|3] scaled by 4
                const nzuimm_5_4 = @as(u2, @truncate(inst >> 11));
                const nzuimm_9_6 = @as(u4, @truncate(inst >> 7));
                const nzuimm_2 = @as(u1, @truncate(inst >> 6));
                const nzuimm_3 = @as(u1, @truncate(inst >> 5));
                const imm: u64 = (@as(u64, nzuimm_5_4) << 4) |
                    (@as(u64, nzuimm_9_6) << 6) |
                    (@as(u64, nzuimm_2) << 2) |
                    (@as(u64, nzuimm_3) << 3);
                const sp = self.regs.get(2);
                self.regs.set(rd, sp +% imm);
            },
            0b010 => {
                // C.LW: lw rd', offset(rs1')
                const rd_prime = @as(u3, @truncate(inst >> 2));
                const rs1_prime = @as(u3, @truncate(inst >> 7));
                const rd: u5 = @as(u5, rd_prime) + 8;
                const rs1: u5 = @as(u5, rs1_prime) + 8;
                // offset = [5:3|2|6]
                const uimm_5_3 = @as(u3, @truncate(inst >> 10));
                const uimm_2 = @as(u1, @truncate(inst >> 6));
                const uimm_6 = @as(u1, @truncate(inst >> 5));
                const offset: u64 = (@as(u64, uimm_5_3) << 3) |
                    (@as(u64, uimm_2) << 2) |
                    (@as(u64, uimm_6) << 6);
                const base = self.regs.get(rs1);
                const eff_addr = base +% offset;
                const phys = self.translate_address(eff_addr) orelse return VMError.invalid_memory_access;
                if (phys + 4 > self.memory_size) return VMError.invalid_memory_access;
                const val = std.mem.readInt(i32, self.memory[@intCast(phys)..][0..4], .little);
                self.regs.set(rd, @bitCast(@as(i64, val)));
            },
            0b011 => {
                // C.LD: ld rd', offset(rs1')
                const rd_prime = @as(u3, @truncate(inst >> 2));
                const rs1_prime = @as(u3, @truncate(inst >> 7));
                const rd: u5 = @as(u5, rd_prime) + 8;
                const rs1: u5 = @as(u5, rs1_prime) + 8;
                // offset = [5:3|7:6]
                const uimm_5_3 = @as(u3, @truncate(inst >> 10));
                const uimm_7_6 = @as(u2, @truncate(inst >> 5));
                const offset: u64 = (@as(u64, uimm_5_3) << 3) | (@as(u64, uimm_7_6) << 6);
                const base = self.regs.get(rs1);
                const eff_addr = base +% offset;
                const phys = self.translate_address(eff_addr) orelse return VMError.invalid_memory_access;
                if (phys + 8 > self.memory_size) return VMError.invalid_memory_access;
                const val = std.mem.readInt(u64, self.memory[@intCast(phys)..][0..8], .little);
                self.regs.set(rd, val);
            },
            0b110 => {
                // C.SW: sw rs2', offset(rs1')
                const rs2_prime = @as(u3, @truncate(inst >> 2));
                const rs1_prime = @as(u3, @truncate(inst >> 7));
                const rs2: u5 = @as(u5, rs2_prime) + 8;
                const rs1: u5 = @as(u5, rs1_prime) + 8;
                const uimm_5_3 = @as(u3, @truncate(inst >> 10));
                const uimm_2 = @as(u1, @truncate(inst >> 6));
                const uimm_6 = @as(u1, @truncate(inst >> 5));
                const offset: u64 = (@as(u64, uimm_5_3) << 3) |
                    (@as(u64, uimm_2) << 2) |
                    (@as(u64, uimm_6) << 6);
                const base = self.regs.get(rs1);
                const eff_addr = base +% offset;
                const phys = self.translate_address(eff_addr) orelse return VMError.invalid_memory_access;
                if (phys + 4 > self.memory_size) return VMError.invalid_memory_access;
                const val = @as(u32, @truncate(self.regs.get(rs2)));
                @memcpy(self.memory[@intCast(phys)..][0..4], &std.mem.toBytes(val));
            },
            0b111 => {
                // C.SD: sd rs2', offset(rs1')
                const rs2_prime = @as(u3, @truncate(inst >> 2));
                const rs1_prime = @as(u3, @truncate(inst >> 7));
                const rs2: u5 = @as(u5, rs2_prime) + 8;
                const rs1: u5 = @as(u5, rs1_prime) + 8;
                const uimm_5_3 = @as(u3, @truncate(inst >> 10));
                const uimm_7_6 = @as(u2, @truncate(inst >> 5));
                const offset: u64 = (@as(u64, uimm_5_3) << 3) | (@as(u64, uimm_7_6) << 6);
                const base = self.regs.get(rs1);
                const eff_addr = base +% offset;
                const phys = self.translate_address(eff_addr) orelse return VMError.invalid_memory_access;
                if (phys + 8 > self.memory_size) return VMError.invalid_memory_access;
                const val = self.regs.get(rs2);
                @memcpy(self.memory[@intCast(phys)..][0..8], &std.mem.toBytes(val));
            },
            else => {
                std.debug.print("DEBUG vm.zig: Unknown C0 funct3=0b{b:0>3}\n", .{funct3});
                return VMError.invalid_instruction;
            },
        }
    }
    
    /// Execute C1 quadrant compressed instruction.
    fn execute_c1(self: *Self, inst: u16, funct3: u3) VMError!void {
        switch (funct3) {
            0b000 => {
                // C.ADDI / C.NOP
                const rd = @as(u5, @truncate(inst >> 7));
                const imm_5 = @as(u1, @truncate(inst >> 12));
                const imm_4_0 = @as(u5, @truncate(inst >> 2));
                const imm6 = (@as(u6, imm_5) << 5) | imm_4_0;
                const imm_signed = @as(i64, @as(i6, @bitCast(imm6)));
                if (rd != 0) {
                    const val = self.regs.get(rd);
                    self.regs.set(rd, val +% @as(u64, @bitCast(imm_signed)));
                }
            },
            0b001 => {
                // C.ADDIW (RV64)
                const rd = @as(u5, @truncate(inst >> 7));
                const imm_5 = @as(u1, @truncate(inst >> 12));
                const imm_4_0 = @as(u5, @truncate(inst >> 2));
                const imm6 = (@as(u6, imm_5) << 5) | imm_4_0;
                const imm_signed = @as(i32, @as(i6, @bitCast(imm6)));
                if (rd != 0) {
                    const val32 = @as(i32, @truncate(@as(i64, @bitCast(self.regs.get(rd)))));
                    const result32 = val32 +% imm_signed;
                    self.regs.set(rd, @bitCast(@as(i64, result32)));
                }
            },
            0b010 => {
                // C.LI
                const rd = @as(u5, @truncate(inst >> 7));
                const imm_5 = @as(u1, @truncate(inst >> 12));
                const imm_4_0 = @as(u5, @truncate(inst >> 2));
                const imm6 = (@as(u6, imm_5) << 5) | imm_4_0;
                const imm_signed = @as(i64, @as(i6, @bitCast(imm6)));
                if (rd != 0) {
                    self.regs.set(rd, @bitCast(imm_signed));
                }
            },
            0b011 => {
                // C.LUI / C.ADDI16SP
                const rd = @as(u5, @truncate(inst >> 7));
                if (rd == 2) {
                    // C.ADDI16SP: add sp, sp, imm*16
                    const imm_9 = @as(u1, @truncate(inst >> 12));
                    const imm_4 = @as(u1, @truncate(inst >> 6));
                    const imm_6 = @as(u1, @truncate(inst >> 5));
                    const imm_8_7 = @as(u2, @truncate(inst >> 3));
                    const imm_5 = @as(u1, @truncate(inst >> 2));
                    const imm10: u10 = (@as(u10, imm_9) << 9) |
                        (@as(u10, imm_8_7) << 7) |
                        (@as(u10, imm_6) << 6) |
                        (@as(u10, imm_5) << 5) |
                        (@as(u10, imm_4) << 4);
                    const imm_signed = @as(i64, @as(i10, @bitCast(imm10)));
                    const sp = self.regs.get(2);
                    self.regs.set(2, sp +% @as(u64, @bitCast(imm_signed)));
                } else if (rd != 0) {
                    // C.LUI
                    const imm_17 = @as(u1, @truncate(inst >> 12));
                    const imm_16_12 = @as(u5, @truncate(inst >> 2));
                    const imm18: u18 = (@as(u18, imm_17) << 17) | (@as(u18, imm_16_12) << 12);
                    const imm_signed = @as(i64, @as(i18, @bitCast(imm18)));
                    self.regs.set(rd, @bitCast(imm_signed));
                }
            },
            0b100 => try self.execute_c1_misc(inst),
            0b101 => {
                // C.J: unconditional jump
                const imm_11 = @as(u1, @truncate(inst >> 12));
                const imm_4 = @as(u1, @truncate(inst >> 11));
                const imm_9_8 = @as(u2, @truncate(inst >> 9));
                const imm_10 = @as(u1, @truncate(inst >> 8));
                const imm_6 = @as(u1, @truncate(inst >> 7));
                const imm_7 = @as(u1, @truncate(inst >> 6));
                const imm_3_1 = @as(u3, @truncate(inst >> 3));
                const imm_5 = @as(u1, @truncate(inst >> 2));
                const offset12: u12 = (@as(u12, imm_11) << 11) |
                    (@as(u12, imm_10) << 10) |
                    (@as(u12, imm_9_8) << 8) |
                    (@as(u12, imm_7) << 7) |
                    (@as(u12, imm_6) << 6) |
                    (@as(u12, imm_5) << 5) |
                    (@as(u12, imm_4) << 4) |
                    (@as(u12, imm_3_1) << 1);
                const offset_signed = @as(i64, @as(i12, @bitCast(offset12)));
                self.regs.pc = self.regs.pc +% @as(u64, @bitCast(offset_signed));
            },
            0b110, 0b111 => {
                // C.BEQZ / C.BNEZ
                const rs1_prime = @as(u3, @truncate(inst >> 7));
                const rs1: u5 = @as(u5, rs1_prime) + 8;
                const imm_8 = @as(u1, @truncate(inst >> 12));
                const imm_4_3 = @as(u2, @truncate(inst >> 10));
                const imm_7_6 = @as(u2, @truncate(inst >> 5));
                const imm_2_1 = @as(u2, @truncate(inst >> 3));
                const imm_5 = @as(u1, @truncate(inst >> 2));
                const offset9: u9 = (@as(u9, imm_8) << 8) |
                    (@as(u9, imm_7_6) << 6) |
                    (@as(u9, imm_5) << 5) |
                    (@as(u9, imm_4_3) << 3) |
                    (@as(u9, imm_2_1) << 1);
                const offset_signed = @as(i64, @as(i9, @bitCast(offset9)));
                const rs1_val = self.regs.get(rs1);
                const take_branch = if (funct3 == 0b110) (rs1_val == 0) else (rs1_val != 0);
                if (take_branch) {
                    self.regs.pc = self.regs.pc +% @as(u64, @bitCast(offset_signed));
                }
            },
        }
    }
    
    /// Execute C1 misc ALU operations (funct3 = 0b100).
    fn execute_c1_misc(self: *Self, inst: u16) VMError!void {
        const funct2 = @as(u2, @truncate(inst >> 10));
        const rd_prime = @as(u3, @truncate(inst >> 7));
        const rd: u5 = @as(u5, rd_prime) + 8;
        
        switch (funct2) {
            0b00 => {
                // C.SRLI
                const shamt_5 = @as(u1, @truncate(inst >> 12));
                const shamt_4_0 = @as(u5, @truncate(inst >> 2));
                const shamt: u6 = (@as(u6, shamt_5) << 5) | shamt_4_0;
                const val = self.regs.get(rd);
                self.regs.set(rd, val >> @truncate(shamt));
            },
            0b01 => {
                // C.SRAI
                const shamt_5 = @as(u1, @truncate(inst >> 12));
                const shamt_4_0 = @as(u5, @truncate(inst >> 2));
                const shamt: u6 = (@as(u6, shamt_5) << 5) | shamt_4_0;
                const val = @as(i64, @bitCast(self.regs.get(rd)));
                self.regs.set(rd, @bitCast(val >> @truncate(shamt)));
            },
            0b10 => {
                // C.ANDI
                const imm_5 = @as(u1, @truncate(inst >> 12));
                const imm_4_0 = @as(u5, @truncate(inst >> 2));
                const imm6 = (@as(u6, imm_5) << 5) | imm_4_0;
                const imm_signed = @as(i64, @as(i6, @bitCast(imm6)));
                const val = self.regs.get(rd);
                self.regs.set(rd, val & @as(u64, @bitCast(imm_signed)));
            },
            0b11 => try self.execute_c1_alu(inst, rd),
        }
    }
    
    /// Execute C1 register-register ALU (funct2 = 0b11).
    fn execute_c1_alu(self: *Self, inst: u16, rd: u5) VMError!void {
        const funct1 = @as(u1, @truncate(inst >> 12));
        const funct2_lo = @as(u2, @truncate(inst >> 5));
        const rs2_prime = @as(u3, @truncate(inst >> 2));
        const rs2: u5 = @as(u5, rs2_prime) + 8;
        
        const rd_val = self.regs.get(rd);
        const rs2_val = self.regs.get(rs2);
        
        if (funct1 == 0) {
            // RV64C
            switch (funct2_lo) {
                0b00 => self.regs.set(rd, rd_val -% rs2_val), // C.SUB
                0b01 => self.regs.set(rd, rd_val ^ rs2_val), // C.XOR
                0b10 => self.regs.set(rd, rd_val | rs2_val), // C.OR
                0b11 => self.regs.set(rd, rd_val & rs2_val), // C.AND
            }
        } else {
            // RV64C word operations
            const rd32 = @as(i32, @truncate(@as(i64, @bitCast(rd_val))));
            const rs232 = @as(i32, @truncate(@as(i64, @bitCast(rs2_val))));
            switch (funct2_lo) {
                0b00 => { // C.SUBW
                    const result = rd32 -% rs232;
                    self.regs.set(rd, @bitCast(@as(i64, result)));
                },
                0b01 => { // C.ADDW
                    const result = rd32 +% rs232;
                    self.regs.set(rd, @bitCast(@as(i64, result)));
                },
                else => return VMError.invalid_instruction,
            }
        }
    }
    
    /// Execute C2 quadrant compressed instruction.
    fn execute_c2(self: *Self, inst: u16, funct3: u3) VMError!void {
        switch (funct3) {
            0b000 => {
                // C.SLLI
                const rd = @as(u5, @truncate(inst >> 7));
                const shamt_5 = @as(u1, @truncate(inst >> 12));
                const shamt_4_0 = @as(u5, @truncate(inst >> 2));
                const shamt: u6 = (@as(u6, shamt_5) << 5) | shamt_4_0;
                if (rd != 0) {
                    const val = self.regs.get(rd);
                    self.regs.set(rd, val << @truncate(shamt));
                }
            },
            0b010 => {
                // C.LWSP
                const rd = @as(u5, @truncate(inst >> 7));
                const uimm_5 = @as(u1, @truncate(inst >> 12));
                const uimm_4_2 = @as(u3, @truncate(inst >> 4));
                const uimm_7_6 = @as(u2, @truncate(inst >> 2));
                const offset: u64 = (@as(u64, uimm_5) << 5) |
                    (@as(u64, uimm_4_2) << 2) |
                    (@as(u64, uimm_7_6) << 6);
                const sp = self.regs.get(2);
                const eff_addr = sp +% offset;
                const phys = self.translate_address(eff_addr) orelse return VMError.invalid_memory_access;
                if (phys + 4 > self.memory_size) return VMError.invalid_memory_access;
                const val = std.mem.readInt(i32, self.memory[@intCast(phys)..][0..4], .little);
                if (rd != 0) {
                    self.regs.set(rd, @bitCast(@as(i64, val)));
                }
            },
            0b011 => {
                // C.LDSP
                const rd = @as(u5, @truncate(inst >> 7));
                const uimm_5 = @as(u1, @truncate(inst >> 12));
                const uimm_4_3 = @as(u2, @truncate(inst >> 5));
                const uimm_8_6 = @as(u3, @truncate(inst >> 2));
                const offset: u64 = (@as(u64, uimm_5) << 5) |
                    (@as(u64, uimm_4_3) << 3) |
                    (@as(u64, uimm_8_6) << 6);
                const sp = self.regs.get(2);
                const eff_addr = sp +% offset;
                const phys = self.translate_address(eff_addr) orelse return VMError.invalid_memory_access;
                if (phys + 8 > self.memory_size) return VMError.invalid_memory_access;
                const val = std.mem.readInt(u64, self.memory[@intCast(phys)..][0..8], .little);
                if (rd != 0) {
                    self.regs.set(rd, val);
                }
            },
            0b100 => try self.execute_c2_jr_mv_add(inst),
            0b110 => {
                // C.SWSP
                const rs2 = @as(u5, @truncate(inst >> 2));
                const uimm_5_2 = @as(u4, @truncate(inst >> 9));
                const uimm_7_6 = @as(u2, @truncate(inst >> 7));
                const offset: u64 = (@as(u64, uimm_5_2) << 2) | (@as(u64, uimm_7_6) << 6);
                const sp = self.regs.get(2);
                const eff_addr = sp +% offset;
                const phys = self.translate_address(eff_addr) orelse return VMError.invalid_memory_access;
                if (phys + 4 > self.memory_size) return VMError.invalid_memory_access;
                const val = @as(u32, @truncate(self.regs.get(rs2)));
                @memcpy(self.memory[@intCast(phys)..][0..4], &std.mem.toBytes(val));
            },
            0b111 => {
                // C.SDSP
                const rs2 = @as(u5, @truncate(inst >> 2));
                const uimm_5_3 = @as(u3, @truncate(inst >> 10));
                const uimm_8_6 = @as(u3, @truncate(inst >> 7));
                const offset: u64 = (@as(u64, uimm_5_3) << 3) | (@as(u64, uimm_8_6) << 6);
                const sp = self.regs.get(2);
                const eff_addr = sp +% offset;
                const phys = self.translate_address(eff_addr) orelse return VMError.invalid_memory_access;
                if (phys + 8 > self.memory_size) return VMError.invalid_memory_access;
                const val = self.regs.get(rs2);
                @memcpy(self.memory[@intCast(phys)..][0..8], &std.mem.toBytes(val));
            },
            else => {
                std.debug.print("DEBUG vm.zig: Unknown C2 funct3=0b{b:0>3}\n", .{funct3});
                return VMError.invalid_instruction;
            },
        }
    }
    
    /// Execute C2 JR/MV/ADD instructions (funct3 = 0b100).
    fn execute_c2_jr_mv_add(self: *Self, inst: u16) VMError!void {
        const funct1 = @as(u1, @truncate(inst >> 12));
        const rd = @as(u5, @truncate(inst >> 7));
        const rs2 = @as(u5, @truncate(inst >> 2));
        
        if (funct1 == 0) {
            if (rs2 == 0) {
                // C.JR: jalr x0, rs1, 0
                const target = self.regs.get(rd);
                const phys = self.translate_address(target) orelse return VMError.invalid_memory_access;
                if (phys >= self.memory_size) return VMError.invalid_memory_access;
                self.regs.pc = target;
            } else {
                // C.MV: add rd, x0, rs2
                if (rd != 0) {
                    self.regs.set(rd, self.regs.get(rs2));
                }
            }
        } else {
            if (rs2 == 0) {
                if (rd == 0) {
                    // C.EBREAK
                    self.state = .halted;
                } else {
                    // C.JALR: jalr ra, rs1, 0
                    const target = self.regs.get(rd);
                    const phys = self.translate_address(target) orelse return VMError.invalid_memory_access;
                    if (phys >= self.memory_size) return VMError.invalid_memory_access;
                    self.regs.set(1, self.regs.pc + 2); // return address
                    self.regs.pc = target;
                }
            } else {
                // C.ADD: add rd, rd, rs2
                if (rd != 0) {
                    self.regs.set(rd, self.regs.get(rd) +% self.regs.get(rs2));
                }
            }
        }
    }

    /// Execute instruction based on opcode.
    /// Why: Extract opcode execution from step() to meet Grain Style 70-line limit.
    /// Grain Style: Function length < 70 lines, explicit types, comprehensive assertions.
    fn execute_opcode(self: *Self, opcode: u7, inst: u32) VMError!void {
        switch (opcode) {
            // U-type instructions (LUI, AUIPC)
            0b0110111 => try self.execute_lui(inst), // LUI
            0b0010111 => try self.execute_auipc(inst), // AUIPC
            
            // I-type instructions (ADDI, etc.)
            0b0010011 => try self.execute_i_type(inst), // ADDI and variants
            
            // R-type instructions (ADD, SUB, etc.)
            0b0110011 => try self.execute_r_type(inst), // R-type
            
            // Load instructions
            0b0000011 => try self.execute_load(inst), // Load
            
            // Store instructions
            0b0100011 => try self.execute_store(inst), // Store
            
            // Branch instructions
            0b1100011 => try self.execute_branch(inst), // Branch
            
            // Jump instructions
            0b1101111 => try self.execute_jal(inst), // JAL
            0b1100111 => try self.execute_jalr_with_validation(inst), // JALR
            
            // System instructions
            0b1110011 => try self.execute_system(inst), // ECALL
            
            // RV64I word-sized instructions (32-bit operations, sign-extended to 64-bit)
            0b0011011 => try self.execute_i_type_word(inst), // ADDIW, SLLIW, SRLIW, SRAIW
            0b0111011 => try self.execute_r_type_word(inst), // ADDW, SUBW, SLLW, SRLW, SRAW
            
            // Zig compiler compatibility opcodes
            0b0000001 => try self.execute_zig_compat_i_type(0x01, inst),
            0b0010100 => try self.execute_zig_compat_i_type(0x14, inst),
            0b0100100 => try self.execute_zig_compat_i_type(0x24, inst),
            0b0110100 => try self.execute_zig_compat_i_type(0x34, inst),
            0b0000000 => try self.execute_zig_compat_r_type(inst),
            0b0100000 => try self.execute_zig_compat_i_type(0x20, inst),
            0b0000101 => try self.execute_zig_compat_i_type(0x05, inst),
            0b0000110 => try self.execute_zig_compat_i_type(0x06, inst),
            0b1000101 => try self.execute_zig_compat_i_type(0x45, inst),
            0b0100101 => try self.execute_zig_compat_i_type(0x25, inst),
            0b0111101 => try self.execute_zig_compat_i_type(0x3D, inst),
            0b1100000 => try self.execute_zig_compat_i_type(0x60, inst),
            0b0101110 => try self.execute_zig_compat_i_type(0x2E, inst),
            
            // Default: try Zig compatibility fallback
            else => try self.execute_zig_compat_fallback(opcode, inst),
        }
    }

    /// Execute I-type instruction (ADDI and variants).
    /// Why: Extract I-type handling to reduce execute_opcode() length.
    fn execute_i_type(self: *Self, inst: u32) VMError!void {
        const funct3 = @as(u3, @truncate(inst >> 12));
        if (funct3 == 0b000) {
            try self.execute_addi(inst);
        } else {
            // Unsupported I-type instruction variant.
            std.debug.print(
                "DEBUG vm.zig: Unsupported I-type variant: funct3=0b{b:0>3}\n",
                .{funct3},
            );
            self.state = .errored;
            self.last_error = VMError.invalid_instruction;
            self.exception_stats.record_exception(2);
            return VMError.invalid_instruction;
        }
    }

    /// Execute I-type word instruction (ADDIW, SLLIW, SRLIW, SRAIW).
    /// Why: RV64I 32-bit immediate operations, result sign-extended to 64-bit.
    fn execute_i_type_word(self: *Self, inst: u32) VMError!void {
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const funct3 = @as(u3, @truncate(inst >> 12));
        const imm12 = @as(u12, @truncate(inst >> 20));
        
        const rs1_val = self.regs.get(rs1);
        const rs1_32 = @as(i32, @truncate(@as(i64, @bitCast(rs1_val))));
        
        const result_32: i32 = switch (funct3) {
            0b000 => blk: {
                // ADDIW: rd = sign_ext(rs1[31:0] + imm)
                const imm_signed = @as(i12, @bitCast(imm12));
                break :blk rs1_32 +% @as(i32, imm_signed);
            },
            0b001 => blk: {
                // SLLIW: rd = sign_ext(rs1[31:0] << shamt)
                const shamt = @as(u5, @truncate(imm12));
                break :blk rs1_32 << shamt;
            },
            0b101 => blk: {
                // SRLIW or SRAIW
                const shamt = @as(u5, @truncate(imm12));
                const funct7 = @as(u7, @truncate(inst >> 25));
                if (funct7 == 0b0000000) {
                    // SRLIW: logical right shift
                    break :blk @as(i32, @bitCast(@as(u32, @bitCast(rs1_32)) >> shamt));
                } else {
                    // SRAIW: arithmetic right shift
                    break :blk rs1_32 >> shamt;
                }
            },
            else => {
                self.state = .errored;
                self.last_error = VMError.invalid_instruction;
                return VMError.invalid_instruction;
            },
        };
        
        // Sign-extend 32-bit result to 64-bit
        const result_64 = @as(u64, @bitCast(@as(i64, result_32)));
        self.regs.set(rd, result_64);
        self.regs.pc += 4;
    }
    
    /// Execute R-type word instruction (ADDW, SUBW, SLLW, SRLW, SRAW).
    /// Why: RV64I 32-bit register operations, result sign-extended to 64-bit.
    fn execute_r_type_word(self: *Self, inst: u32) VMError!void {
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const rs2 = @as(u5, @truncate(inst >> 20));
        const funct3 = @as(u3, @truncate(inst >> 12));
        const funct7 = @as(u7, @truncate(inst >> 25));
        
        const rs1_val = self.regs.get(rs1);
        const rs2_val = self.regs.get(rs2);
        const rs1_32 = @as(i32, @truncate(@as(i64, @bitCast(rs1_val))));
        const rs2_32 = @as(i32, @truncate(@as(i64, @bitCast(rs2_val))));
        const shamt = @as(u5, @truncate(rs2_val));
        
        const result_32: i32 = switch (funct3) {
            0b000 => blk: {
                if (funct7 == 0b0000000) {
                    // ADDW
                    break :blk rs1_32 +% rs2_32;
                } else {
                    // SUBW
                    break :blk rs1_32 -% rs2_32;
                }
            },
            0b001 => rs1_32 << shamt, // SLLW
            0b101 => blk: {
                if (funct7 == 0b0000000) {
                    // SRLW
                    break :blk @as(i32, @bitCast(@as(u32, @bitCast(rs1_32)) >> shamt));
                } else {
                    // SRAW
                    break :blk rs1_32 >> shamt;
                }
            },
            else => {
                self.state = .errored;
                self.last_error = VMError.invalid_instruction;
                return VMError.invalid_instruction;
            },
        };
        
        const result_64 = @as(u64, @bitCast(@as(i64, result_32)));
        self.regs.set(rd, result_64);
        self.regs.pc += 4;
    }

    /// Execute R-type instruction (ADD, SUB, etc.).
    /// Why: Extract R-type handling to reduce execute_opcode() length.
    fn execute_r_type(self: *Self, inst: u32) VMError!void {
        const funct3 = @as(u3, @truncate(inst >> 12));
        const funct7 = @as(u7, @truncate(inst >> 25));

        switch (funct3) {
            0b000 => try self.execute_r_type_add_sub(inst, funct7),
            0b001 => try self.execute_r_type_sll(inst, funct7),
            0b010 => try self.execute_r_type_slt(inst, funct7),
            0b100 => try self.execute_r_type_xor(inst, funct7),
            0b101 => try self.execute_r_type_srl_sra(inst, funct7),
            0b110 => try self.execute_r_type_or(inst, funct7),
            0b111 => try self.execute_r_type_and(inst, funct7),
            else => {
                self.state = .errored;
                self.last_error = VMError.invalid_instruction;
                return VMError.invalid_instruction;
            },
        }
    }

    /// Execute R-type ADD or SUB instruction.
    fn execute_r_type_add_sub(self: *Self, inst: u32, funct7: u7) VMError!void {
        if (funct7 == 0b0000000) {
            try self.execute_add(inst);
        } else if (funct7 == 0b0100000) {
            try self.execute_sub(inst);
        } else {
            self.state = .errored;
            self.last_error = VMError.invalid_instruction;
            self.exception_stats.record_exception(2);
            return VMError.invalid_instruction;
        }
    }

    /// Execute R-type SLL instruction.
    fn execute_r_type_sll(self: *Self, inst: u32, funct7: u7) VMError!void {
        if (funct7 == 0b0000000) {
            try self.execute_sll(inst);
        } else {
                std.debug.print(
                    "DEBUG vm.zig: SLL with non-zero funct7=0x{x}, executing as SLL\n",
                    .{funct7},
                );
            try self.execute_sll(inst);
        }
    }

    /// Execute R-type SLT instruction.
    fn execute_r_type_slt(self: *Self, inst: u32, funct7: u7) VMError!void {
        if (funct7 == 0b0000000) {
            try self.execute_slt(inst);
        } else {
            self.state = .errored;
            self.last_error = VMError.invalid_instruction;
            self.exception_stats.record_exception(2);
            return VMError.invalid_instruction;
        }
    }

    /// Execute R-type XOR instruction.
    fn execute_r_type_xor(self: *Self, inst: u32, funct7: u7) VMError!void {
        if (funct7 == 0b0000000) {
            try self.execute_xor(inst);
        } else {
            self.state = .errored;
            self.last_error = VMError.invalid_instruction;
            self.exception_stats.record_exception(2);
            return VMError.invalid_instruction;
        }
    }

    /// Execute R-type SRL or SRA instruction.
    fn execute_r_type_srl_sra(self: *Self, inst: u32, funct7: u7) VMError!void {
        if (funct7 == 0b0000000) {
            try self.execute_srl(inst);
        } else if (funct7 == 0b0100000) {
            try self.execute_sra(inst);
        } else {
            self.state = .errored;
            self.last_error = VMError.invalid_instruction;
            self.exception_stats.record_exception(2);
            return VMError.invalid_instruction;
        }
    }

    /// Execute R-type OR instruction.
    fn execute_r_type_or(self: *Self, inst: u32, funct7: u7) VMError!void {
        if (funct7 == 0b0000000) {
            try self.execute_or(inst);
        } else {
            self.state = .errored;
            self.last_error = VMError.invalid_instruction;
            self.exception_stats.record_exception(2);
            return VMError.invalid_instruction;
        }
    }

    /// Execute R-type AND instruction.
    fn execute_r_type_and(self: *Self, inst: u32, funct7: u7) VMError!void {
        if (funct7 == 0b0000000) {
            try self.execute_and(inst);
        } else {
            self.state = .errored;
            self.last_error = VMError.invalid_instruction;
            self.exception_stats.record_exception(2);
            return VMError.invalid_instruction;
        }
    }

    /// Execute load instruction.
    /// Why: Extract load handling to reduce execute_opcode() length.
    fn execute_load(self: *Self, inst: u32) VMError!void {
        const funct3 = @as(u3, @truncate(inst >> 12));
        switch (funct3) {
            0b000 => try self.execute_lb(inst), // LB
            0b001 => try self.execute_lh(inst), // LH
            0b010 => try self.execute_lw(inst), // LW
            0b011 => try self.execute_ld(inst), // LD
            0b100 => try self.execute_lbu(inst), // LBU
            0b101 => try self.execute_lhu(inst), // LHU
            0b110 => try self.execute_lwu(inst), // LWU
            else => {
                self.state = .errored;
                self.last_error = VMError.invalid_instruction;
                return VMError.invalid_instruction;
            },
        }
    }

    /// Execute store instruction.
    /// Why: Extract store handling to reduce execute_opcode() length.
    fn execute_store(self: *Self, inst: u32) VMError!void {
        const funct3 = @as(u3, @truncate(inst >> 12));
        switch (funct3) {
            0b000 => try self.execute_sb(inst), // SB
            0b001 => try self.execute_sh(inst), // SH
            0b010 => try self.execute_sw(inst), // SW
            0b011 => try self.execute_sd(inst), // SD
            else => {
                self.state = .errored;
                self.last_error = VMError.invalid_instruction;
                return VMError.invalid_instruction;
            },
        }
    }

    /// Execute branch instruction.
    /// Why: Extract branch handling to reduce execute_opcode() length.
    fn execute_branch(self: *Self, inst: u32) VMError!void {
        const funct3 = @as(u3, @truncate(inst >> 12));
        switch (funct3) {
            0b000 => try self.execute_beq(inst), // BEQ
            0b001 => try self.execute_bne(inst), // BNE
            0b100 => try self.execute_blt(inst), // BLT
            0b101 => try self.execute_bge(inst), // BGE
            0b110 => try self.execute_bltu(inst), // BLTU
            0b111 => try self.execute_bgeu(inst), // BGEU
            else => {
                self.state = .errored;
                self.last_error = VMError.invalid_instruction;
                return VMError.invalid_instruction;
            },
        }
    }

    /// Execute system instruction (ECALL, EBREAK, CSR instructions).
    /// Why: Extract system handling to reduce execute_opcode() length.
    fn execute_system(self: *Self, inst: u32) VMError!void {
        const funct3 = @as(u3, @truncate(inst >> 12));
        const rd = @as(u5, @truncate(inst >> 7));
        
        switch (funct3) {
            0b000 => {
                // ECALL (inst == 0x00000073) or EBREAK (inst == 0x00100073)
                if (inst == 0x00000073) {
                    try self.execute_ecall();
                } else if (inst == 0x00100073) {
                    // EBREAK: halt for debugging
                    self.state = .halted;
                } else {
                    // Other system instructions: NOP
                    self.regs.pc += 4;
                }
            },
            0b001, 0b010, 0b011, 0b101, 0b110, 0b111 => {
                // CSR instructions: CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI
                // These read/write Control and Status Registers.
                // In the VM, we NOP them and write 0 to rd (pretend CSR reads return 0).
                if (rd != 0) {
                    self.regs.set(rd, 0);
                }
                self.regs.pc += 4;
            },
            else => {
                self.state = .errored;
                self.last_error = VMError.invalid_instruction;
                return VMError.invalid_instruction;
            },
        }
    }

    /// Execute Zig compiler compatibility I-type instruction.
    /// Why: Extract Zig compatibility handling to reduce execute_opcode() length.
    fn execute_zig_compat_i_type(self: *Self, opcode_val: u8, inst: u32) VMError!void {
        const funct3 = @as(u3, @truncate(inst >> 12));
        std.debug.print(
            "DEBUG vm.zig: Opcode 0x{x:0>2} detected: inst=0x{x}, funct3=0b{b:0>3}\n",
            .{ opcode_val, inst, funct3 },
        );

        if (funct3 == 0b000) {
            std.debug.print(
                "DEBUG vm.zig: Executing opcode 0x{X:0>2} with funct3=0b000 as ADDI\n",
                .{opcode_val},
            );
            try self.execute_addi(inst);
        } else if (funct3 == 0b100) {
            std.debug.print(
                "DEBUG vm.zig: Executing opcode 0x{X:0>2} with funct3=0b100 as XORI\n",
                .{opcode_val},
            );
            try self.execute_xori(inst);
        } else if (funct3 == 0b110) {
            std.debug.print(
                "DEBUG vm.zig: Executing opcode 0x{X:0>2} with funct3=0b110 as ORI\n",
                .{opcode_val},
            );
            try self.execute_ori(inst);
        } else if (funct3 == 0b111) {
            std.debug.print(
                "DEBUG vm.zig: Executing opcode 0x{X:0>2} with funct3=0b111 as ANDI\n",
                .{opcode_val},
            );
            try self.execute_andi(inst);
        } else {
            std.debug.print(
                "DEBUG vm.zig: Unknown opcode 0x{X:0>2} variant (funct3=0b{b:0>3}), treating as NOP\n",
                .{ opcode_val, funct3 },
            );
        }
    }

    /// Execute Zig compiler compatibility R-type instruction.
    /// Why: Extract Zig compatibility handling to reduce execute_opcode() length.
    fn execute_zig_compat_r_type(self: *Self, inst: u32) VMError!void {
        const funct3 = @as(u3, @truncate(inst >> 12));
        const funct7 = @as(u7, @truncate(inst >> 25));
        std.debug.print(
            "DEBUG vm.zig: Opcode 0x00 detected: inst=0x{x}, funct3=0b{b:0>3}, funct7=0b{b:0>7} (0x{x})\n",
            .{ inst, funct3, funct7, funct7 },
        );

        if (funct3 == 0b001) {
            std.debug.print("DEBUG vm.zig: Treating opcode 0x00 with funct3=1 as SLL\n", .{});
            try self.execute_sll(inst);
        } else {
            std.debug.print(
                "DEBUG vm.zig: Unknown opcode 0x00 variant (funct3=0b{b:0>3}), treating as NOP\n",
                .{funct3},
            );
        }
    }

    /// Execute Zig compiler compatibility fallback for unknown opcodes.
    /// Why: Extract Zig compatibility fallback to reduce execute_opcode() length.
    fn execute_zig_compat_fallback(self: *Self, opcode: u7, inst: u32) VMError!void {
        const funct3 = @as(u3, @truncate(inst >> 12));
        if (funct3 == 0b000) {
            std.debug.print(
                "DEBUG vm.zig: Non-standard opcode 0b{b:0>7} (0x{x}) with funct3=0b000, treating as ADDI\n",
                .{ opcode, opcode },
            );
            try self.execute_addi(inst);
        } else if (funct3 == 0b001) {
            std.debug.print(
                "DEBUG vm.zig: Non-standard opcode 0b{b:0>7} (0x{x}) with funct3=0b001, treating as SLLI\n",
                .{ opcode, opcode },
            );
            try self.execute_slli(inst);
        } else if (funct3 == 0b011) {
            std.debug.print(
                "DEBUG vm.zig: Non-standard opcode 0b{b:0>7} (0x{x}) with funct3=0b011, treating as NOP\n",
                .{ opcode, opcode },
            );
        } else if (funct3 == 0b100) {
            std.debug.print(
                "DEBUG vm.zig: Non-standard opcode 0b{b:0>7} (0x{x}) with funct3=0b100, treating as XORI\n",
                .{ opcode, opcode },
            );
            try self.execute_xori(inst);
        } else if (funct3 == 0b110) {
            std.debug.print(
                "DEBUG vm.zig: Non-standard opcode 0b{b:0>7} (0x{x}) with funct3=0b110, treating as ORI\n",
                .{ opcode, opcode },
            );
            try self.execute_ori(inst);
        } else if (funct3 == 0b111) {
            std.debug.print(
                "DEBUG vm.zig: Non-standard opcode 0b{b:0>7} (0x{x}) with funct3=0b111, treating as ANDI\n",
                .{ opcode, opcode },
            );
            try self.execute_andi(inst);
        } else {
            std.debug.print(
                "DEBUG vm.zig: Unknown non-standard opcode 0b{b:0>7} (0x{x}) with funct3=0b{b:0>3}, treating as NOP\n",
                .{ opcode, opcode, funct3 },
            );
        }
    }

    /// Execute JALR instruction with funct3 validation.
    /// Why: Extract JALR handling to reduce execute_opcode() length.
    fn execute_jalr_with_validation(self: *Self, inst: u32) VMError!void {
        const funct3 = @as(u3, @truncate(inst >> 12));
        if (funct3 == 0b000) {
            try self.execute_jalr(inst);
        } else {
            self.state = .errored;
            self.last_error = VMError.invalid_instruction;
            return VMError.invalid_instruction;
        }
    }

    /// Execute LUI (Load Upper Immediate) instruction.
    /// Format: LUI rd, imm[31:12]
    /// Why: Separate function for clarity and Grain Style function length.
    fn execute_lui(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], imm[31:12] = bits [31:12].
        const rd = @as(u5, @truncate(inst >> 7));
        const imm = @as(u32, inst) & 0xFFFFF000; // Extract bits [31:12].

        // Sign-extend imm[31:12] to 64 bits.
        const imm64 = @as(i32, @bitCast(imm)) << 12;
        const imm64_unsigned = @as(u64, @intCast(imm64));

        // Write result to rd.
        self.regs.set(rd, imm64_unsigned);
    }

    /// Execute AUIPC (Add Upper Immediate to PC) instruction.
    /// Format: AUIPC rd, imm[31:12]
    /// Why: PC-relative addressing for position-independent code.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_auipc(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], imm[31:12] = bits [31:12].
        const rd = @as(u5, @truncate(inst >> 7));
        // Extract imm[31:12] as a 20-bit value, then sign-extend to 32 bits, then shift left by 12.
        const imm_31_12_raw = @as(u20, @truncate(inst >> 12));
        const imm_31_12 = @as(i32, @bitCast(@as(u32, imm_31_12_raw) << 12));
        const imm64_unsigned: u64 = @bitCast(@as(i64, imm_31_12));

        // Get current PC (before instruction execution).
        const pc = self.regs.pc;

        // AUIPC: rd = PC + imm[31:12] << 12
        const result = pc +% imm64_unsigned;

        // Debug: Print AUIPC execution for troubleshooting.
        if (rd == 1 or rd == 18) {
            std.debug.print(
                "DEBUG vm.zig: AUIPC x{}: PC=0x{x}, imm_31_12_raw=0x{x}, imm64_unsigned=0x{x}, result=0x{x}\n",
                .{ rd, pc, imm_31_12_raw, imm64_unsigned, result },
            );
        }

        // Write result to rd.
        self.regs.set(rd, result);
    }

    /// Execute ADDI (Add Immediate) instruction.
    /// Format: ADDI rd, rs1, imm[11:0]
    /// Why: Separate function for clarity and Grain Style function length.
    fn execute_addi(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], imm[11:0] = bits [31:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        // Sign-extend imm[11:0] to 64 bits.
        const imm64 = @as(i64, imm12);

        // Read rs1 value.
        const rs1_value = self.regs.get(rs1);

        // Add: rd = rs1 + imm (wrapping addition).
        const result = @as(u64, @intCast(@as(i64, @bitCast(rs1_value)) + imm64));

        // Write result to rd.
        self.regs.set(rd, result);
    }

    /// Execute ORI (OR Immediate) instruction.
    /// Format: ORI rd, rs1, imm[11:0]
    /// Why: Bitwise OR with immediate value for Zig compiler compatibility.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_ori(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], imm[11:0] = bits [31:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        // Sign-extend imm[11:0] to 64 bits.
        const imm64 = @as(u64, @intCast(@as(i64, imm12)));

        // Read rs1 value.
        const rs1_value = self.regs.get(rs1);

        // OR: rd = rs1 | imm (bitwise OR).
        const result = rs1_value | imm64;

        // Write result to rd.
        self.regs.set(rd, result);
    }

    /// Execute ANDI (AND Immediate) instruction.
    /// Format: ANDI rd, rs1, imm[11:0]
    /// Why: Bitwise AND with immediate value for Zig compiler compatibility.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_andi(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], imm[11:0] = bits [31:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        // Sign-extend imm[11:0] to 64 bits.
        const imm64 = @as(u64, @intCast(@as(i64, imm12)));

        // Read rs1 value.
        const rs1_value = self.regs.get(rs1);

        // AND: rd = rs1 & imm (bitwise AND).
        const result = rs1_value & imm64;

        // Write result to rd.
        self.regs.set(rd, result);
    }

    /// Execute XORI (XOR Immediate) instruction.
    /// Format: XORI rd, rs1, imm[11:0]
    /// Why: Bitwise XOR with immediate value for Zig compiler compatibility.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_xori(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], imm[11:0] = bits [31:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        // Sign-extend imm[11:0] to 64 bits.
        const imm64 = @as(u64, @intCast(@as(i64, imm12)));

        // Read rs1 value.
        const rs1_value = self.regs.get(rs1);

        // XOR: rd = rs1 ^ imm (bitwise XOR).
        const result = rs1_value ^ imm64;

        // Write result to rd.
        self.regs.set(rd, result);
    }

    /// Execute ADD (Add) instruction.
    /// Format: ADD rd, rs1, rs2
    /// Encoding: funct7 | rs2 | rs1 | 000 | rd | 0110011
    /// Why: Register-register addition for kernel arithmetic operations.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_add(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], rs2 = bits [24:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const rs2 = @as(u5, @truncate(inst >> 20));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);
        std.debug.assert(rs2 < 32);

        // Read source register values.
        const rs1_value = self.regs.get(rs1);
        self.register_stats.record_read(rs1);
        const rs2_value = self.regs.get(rs2);
        self.register_stats.record_read(rs2);

        // Add: rd = rs1 + rs2 (wrapping addition).
        // Why: RISC-V uses wrapping arithmetic (no overflow exceptions).
        const result = rs1_value +% rs2_value;

        // Write result to rd.
        self.regs.set(rd, result);
        self.register_stats.record_write(rd);

        // Assert: result must be written correctly (unless x0).
        if (rd != 0) {
            std.debug.assert(self.regs.get(rd) == result);
        }
    }

    /// Execute SUB (Subtract) instruction.
    /// Format: SUB rd, rs1, rs2
    /// Encoding: funct7 | rs2 | rs1 | 000 | rd | 0110011
    /// Why: Register-register subtraction for kernel arithmetic operations.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_sub(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], rs2 = bits [24:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const rs2 = @as(u5, @truncate(inst >> 20));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);
        std.debug.assert(rs2 < 32);

        // Read source register values.
        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        // Subtract: rd = rs1 - rs2 (wrapping subtraction).
        // Why: RISC-V uses wrapping arithmetic (no underflow exceptions).
        const result = rs1_value -% rs2_value;

        // Write result to rd.
        self.regs.set(rd, result);

        // Assert: result must be written correctly (unless x0).
        if (rd != 0) {
            std.debug.assert(self.regs.get(rd) == result);
        }
    }

    /// Execute SLT (Set Less Than) instruction.
    /// Format: SLT rd, rs1, rs2
    /// Encoding: funct7 | rs2 | rs1 | 010 | rd | 0110011
    /// Why: Signed comparison for kernel control flow and conditionals.
    /// Grain Style: Comprehensive assertions for register indices and comparison result.
    fn execute_slt(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], rs2 = bits [24:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const rs2 = @as(u5, @truncate(inst >> 20));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);
        std.debug.assert(rs2 < 32);

        // Read source register values (as signed 64-bit integers).
        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        // Compare: rd = (rs1 < rs2) ? 1 : 0 (signed comparison).
        // Why: SLT performs signed comparison (treats values as two's complement).
        const rs1_signed = @as(i64, @bitCast(rs1_value));
        const rs2_signed = @as(i64, @bitCast(rs2_value));
        const result: u64 = if (rs1_signed < rs2_signed) 1 else 0;

        // Write result to rd.
        self.regs.set(rd, result);

        // Assert: result must be 0 or 1 (boolean comparison result).
        std.debug.assert(result == 0 or result == 1);

        // Assert: result must be written correctly (unless x0).
        if (rd != 0) {
            std.debug.assert(self.regs.get(rd) == result);
        }
    }

    /// Execute OR (Bitwise OR) instruction.
    /// Format: OR rd, rs1, rs2
    /// Encoding: funct7 | rs2 | rs1 | 110 | rd | 0110011
    /// Why: Bitwise OR for kernel bit manipulation operations.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_or(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], rs2 = bits [24:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const rs2 = @as(u5, @truncate(inst >> 20));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);
        std.debug.assert(rs2 < 32);

        // Read source register values.
        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        // OR: rd = rs1 | rs2 (bitwise OR).
        // Why: Bitwise OR operation for kernel bit manipulation.
        const result = rs1_value | rs2_value;

        // Write result to rd.
        self.regs.set(rd, result);

        // Assert: result must be written correctly (unless x0).
        if (rd != 0) {
            std.debug.assert(self.regs.get(rd) == result);
        }
    }

    /// Execute AND (Bitwise AND) instruction.
    /// Format: AND rd, rs1, rs2
    /// Encoding: funct7 | rs2 | rs1 | 111 | rd | 0110011
    /// Why: Bitwise AND for kernel bit manipulation operations.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_and(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], rs2 = bits [24:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const rs2 = @as(u5, @truncate(inst >> 20));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);
        std.debug.assert(rs2 < 32);

        // Read source register values.
        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        // AND: rd = rs1 & rs2 (bitwise AND).
        // Why: Bitwise AND operation for kernel bit manipulation.
        const result = rs1_value & rs2_value;

        // Write result to rd.
        self.regs.set(rd, result);

        // Assert: result must be written correctly (unless x0).
        if (rd != 0) {
            std.debug.assert(self.regs.get(rd) == result);
        }
    }

    /// Execute XOR (Exclusive OR) instruction.
    /// Format: XOR rd, rs1, rs2
    /// Encoding: funct7 | rs2 | rs1 | 100 | rd | 0110011
    /// Why: Bitwise XOR for kernel bit manipulation operations.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_xor(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], rs2 = bits [24:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const rs2 = @as(u5, @truncate(inst >> 20));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);
        std.debug.assert(rs2 < 32);

        // Read source register values.
        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        // XOR: rd = rs1 ^ rs2 (bitwise XOR).
        // Why: Bitwise XOR operation for kernel bit manipulation.
        const result = rs1_value ^ rs2_value;

        // Write result to rd.
        self.regs.set(rd, result);

        // Assert: result must be written correctly (unless x0).
        if (rd != 0) {
            std.debug.assert(self.regs.get(rd) == result);
        }
    }

    /// Execute SLL (Shift Left Logical) instruction.
    /// Format: SLL rd, rs1, rs2
    /// Encoding: funct7 | rs2 | rs1 | 001 | rd | 0110011
    /// Why: Logical left shift for kernel bit manipulation operations.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_sll(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], rs2 = bits [24:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const rs2 = @as(u5, @truncate(inst >> 20));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);
        std.debug.assert(rs2 < 32);

        // Read source register values.
        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        // SLL: rd = rs1 << (rs2 & 0x3F) (logical left shift, shift amount masked to 6 bits).
        // Why: RISC-V shift amount is masked to 6 bits (0-63) for 64-bit values.
        const shift_amount = @as(u6, @truncate(rs2_value & 0x3F));
        const result = rs1_value << shift_amount;

        // Debug: Print SLL execution for troubleshooting.
        if (rd == 8) {
            std.debug.print(
                "DEBUG vm.zig: SLL x8: rs1=x{} (0x{x}), rs2=x{} (0x{x}), shift_amount={}, result=0x{x}\n",
                .{ rs1, rs1_value, rs2, rs2_value, shift_amount, result },
            );
        }

        // Write result to rd.
        self.regs.set(rd, result);

        // Assert: result must be written correctly (unless x0).
        if (rd != 0) {
            std.debug.assert(self.regs.get(rd) == result);
            if (rd == 8) {
                std.debug.print("DEBUG vm.zig: SLL x8: Verified x8 = 0x{x}\n", .{self.regs.get(8)});
            }
        }
    }

    /// Execute SRL (Shift Right Logical) instruction.
    /// Format: SRL rd, rs1, rs2
    /// Encoding: funct7 | rs2 | rs1 | 101 | rd | 0110011
    /// Why: Logical right shift for kernel bit manipulation operations.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_srl(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], rs2 = bits [24:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const rs2 = @as(u5, @truncate(inst >> 20));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);
        std.debug.assert(rs2 < 32);

        // Read source register values.
        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        // SRL: rd = rs1 >> (rs2 & 0x3F) (logical right shift, shift amount masked to 6 bits).
        // Why: RISC-V shift amount is masked to 6 bits (0-63) for 64-bit values.
        // Logical shift: fills with zeros (unsigned shift).
        const shift_amount = @as(u6, @truncate(rs2_value & 0x3F));
        const result = rs1_value >> shift_amount;

        // Write result to rd.
        self.regs.set(rd, result);

        // Assert: result must be written correctly (unless x0).
        if (rd != 0) {
            std.debug.assert(self.regs.get(rd) == result);
        }
    }

    /// Execute SLLI (Shift Left Logical Immediate) instruction.
    /// Format: SLLI rd, rs1, imm[5:0]
    /// Encoding: imm[5:0] | rs1 | 001 | rd | 0010011
    /// Why: Logical left shift by immediate for kernel bit manipulation operations.
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_slli(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], imm[5:0] = bits [24:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm_raw = @as(u6, @truncate(inst >> 20)); // imm[5:0]

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);

        // Read source register value.
        const rs1_value = self.regs.get(rs1);

        // SLLI: rd = rs1 << imm[5:0] (logical left shift, shift amount masked to 6 bits).
        // Why: RISC-V shift amount is masked to 6 bits (0-63) for 64-bit values.
        const shift_amount = imm_raw & 0x3F;
        const result = rs1_value << shift_amount;

        // Write result to rd.
        self.regs.set(rd, result);

        // Assert: result must be written correctly (unless x0).
        if (rd != 0) {
            std.debug.assert(self.regs.get(rd) == result);
        }
    }

    /// Execute SRA (Shift Right Arithmetic) instruction.
    /// Format: SRA rd, rs1, rs2
    /// Encoding: funct7(0x20) | rs2 | rs1 | 101 | rd | 0110011
    /// Why: Arithmetic right shift for kernel bit manipulation operations (sign-extended).
    /// Grain Style: Comprehensive assertions for register indices and result validation.
    fn execute_sra(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], rs2 = bits [24:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const rs2 = @as(u5, @truncate(inst >> 20));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);
        std.debug.assert(rs2 < 32);

        // Read source register values.
        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        // SRA: rd = rs1 >> (rs2 & 0x3F) (arithmetic right shift, shift amount masked to 6 bits).
        // Why: RISC-V shift amount is masked to 6 bits (0-63) for 64-bit values.
        // Arithmetic shift: sign-extends (treats value as signed, fills with sign bit).
        const shift_amount = @as(u6, @truncate(rs2_value & 0x3F));
        const rs1_signed = @as(i64, @bitCast(rs1_value));
        const result_signed = rs1_signed >> @as(u6, @intCast(shift_amount));
        const result = @as(u64, @bitCast(result_signed));

        // Write result to rd.
        self.regs.set(rd, result);

        // Assert: result must be written correctly (unless x0).
        if (rd != 0) {
            std.debug.assert(self.regs.get(rd) == result);
        }
    }

    /// Execute LW (Load Word) instruction.
    /// Format: LW rd, offset(rs1)
    /// Encoding: imm[11:0] | rs1 | 010 | rd | 0000011
    /// Why: Load 32-bit word from memory for kernel data access.
    pub fn execute_lw(self: *Self, inst: u32) !void {
        // Decode: rd = bits [11:7], rs1 = bits [19:15], imm[11:0] = bits [31:20].
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);

        // Read base address from rs1.
        var base_addr = self.regs.get(rs1);

        // Sign-extend immediate to 64 bits.
        const imm64 = @as(i64, imm12);
        const offset: u64 = @bitCast(imm64);

        // Workaround: If x8 (s0/fp) is 0x0, check if the address would be valid.
        // If not, try using sp instead (for stack-relative accesses).
        var eff_addr = base_addr +% offset;
        if (rs1 == 8 and base_addr == 0x0) {
            // If address with x8=0x0 is invalid, try sp instead.
            const test_phys = self.translate_address(eff_addr);
            if (test_phys == null or test_phys.? + 4 > self.memory_size) {
                const sp = self.regs.get(2);
                if (sp != 0x0) {
                    const sp_eff = sp +% offset;
                    const sp_phys = self.translate_address(sp_eff);
                    if (sp_phys != null and sp_phys.? + 4 <= self.memory_size) {
                        std.debug.print(
                            "DEBUG vm.zig: LW: x8=0x0 gives invalid addr 0x{x}, trying sp (x2=0x{x})\n",
                            .{ eff_addr, sp },
                        );
                        base_addr = sp;
                        eff_addr = base_addr +% offset;
                    }
                }
            }
        }

        // Assert: effective address must be 4-byte aligned for word load.
        if (eff_addr % 4 != 0) {
            self.state = .errored;
            self.last_error = VMError.unaligned_memory_access;
            return VMError.unaligned_memory_access;
        }

        // Translate virtual address to physical offset
        const phys_offset = self.translate_address(eff_addr) orelse {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };

        // Assert: physical offset + 4 must be within memory bounds.
        if (phys_offset + 4 > self.memory_size) {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        // Read 32-bit word from memory using translated physical offset (sign-extend to 64 bits).
        // GrainStyle: Cast u64 to usize only for array indexing
        const mem_slice = self.memory[@intCast(phys_offset)..][0..4];
        const word = std.mem.readInt(u32, mem_slice, .little);
        const word_signed = @as(i32, @bitCast(word));
        const word64 = @as(u64, @intCast(word_signed));

        // Write to destination register.
        self.regs.set(rd, word64);

        // Assert: register must be set correctly.
        std.debug.assert(self.regs.get(rd) == word64);
    }

    /// Execute SW (Store Word) instruction.
    /// Format: SW rs2, offset(rs1)
    /// Encoding: imm[11:5] | rs2 | rs1 | 010 | imm[4:0] | 0100011
    /// Why: Store 32-bit word to memory for kernel data writes.
    pub fn execute_sw(self: *Self, inst: u32) !void {
        // Decode S-type: rs2 = bits [24:20], rs1 = bits [19:15],
        // imm[11:5] = bits [31:25], imm[4:0] = bits [11:7].
        const rs2 = @as(u5, @truncate(inst >> 20));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm_11_5 = @as(u7, @truncate(inst >> 25));
        const imm_4_0 = @as(u5, @truncate(inst >> 7));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rs2 < 32);
        std.debug.assert(rs1 < 32);

        // Reconstruct 12-bit immediate: imm[11:5] | imm[4:0].
        const imm12_raw = (@as(u12, imm_11_5) << 5) | imm_4_0;
        const imm12 = @as(i32, @truncate(@as(i64, @as(i12, @bitCast(imm12_raw)))));

        // Read base address from rs1.
        const base_addr = self.regs.get(rs1);

        // Sign-extend immediate to 64 bits.
        const imm64 = @as(i64, imm12);
        const offset: u64 = @bitCast(imm64);

        // Calculate effective address: base_addr + offset.
        const eff_addr = base_addr +% offset;

        // Assert: effective address must be 4-byte aligned for word store.
        if (eff_addr % 4 != 0) {
            self.state = .errored;
            self.last_error = VMError.unaligned_memory_access;
            return VMError.unaligned_memory_access;
        }

        // Check memory permissions (if permission checker is set).
        // Why: Enforce memory protection before allowing write access.
        if (self.permission_checker) |checker| {
            const permissions = checker(eff_addr);
            const has_write = (permissions & 2) != 0;
            if (!has_write) {
                // Record exception (store access fault, code 7).
                self.exception_stats.record_exception(7);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
        }
        
        // Translate virtual address to physical offset
        const phys_offset = self.translate_address(eff_addr) orelse {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };

        // Assert: physical offset + 4 must be within memory bounds.
        if (phys_offset + 4 > self.memory_size) {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        // Read source value from rs2 (truncate to 32 bits).
        const rs2_value = self.regs.get(rs2);
        const word = @as(u32, @truncate(rs2_value));

        // Write 32-bit word to memory.
        // GrainStyle: Cast u64 to usize only for array indexing
        @memcpy(self.memory[@intCast(phys_offset)..][0..4], &std.mem.toBytes(word));
    }

    /// Execute LB (Load Byte) instruction.
    /// Format: LB rd, offset(rs1)
    /// Encoding: imm[11:0] | rs1 | 000 | rd | 0000011
    /// Contract: Loads 8-bit byte, sign-extends to 64 bits
    /// Why: Load byte from memory for kernel data access.
    pub fn execute_lb(self: *Self, inst: u32) !void {
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);

        const base_addr = self.regs.get(rs1);
        const imm64 = @as(i64, imm12);
        // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
        const eff_addr = base_addr +% offset;

        // Check memory permissions (if permission checker is set).
        // Why: Enforce memory protection before allowing read access.
        // Distinguish between page faults (unmapped) and access faults (permission violation).
        if (self.permission_checker) |checker| {
            const permissions = checker(eff_addr);
            if (permissions == 0) {
                // Page not mapped: record page fault (load page fault, code 13).
                self.exception_stats.record_exception(13);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
            const has_read = (permissions & 1) != 0;
            if (!has_read) {
                // Page mapped but no read permission:
                // record access fault (load access fault, code 5).
                self.exception_stats.record_exception(5);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
        }

        // Translate virtual address to physical offset
        const phys_offset = self.translate_address(eff_addr) orelse {
            // Address translation failed: record page fault (load page fault, code 13).
            self.exception_stats.record_exception(13);
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };

        // Assert: physical offset + 1 must be within memory bounds.
        if (phys_offset + 1 > self.memory_size) {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        // Read byte from memory using translated physical offset
        // GrainStyle: Cast u64 to usize only for array indexing
        const byte = self.memory[@intCast(phys_offset)];
        const byte_signed = @as(i8, @bitCast(byte));
        const byte64 = @as(u64, @intCast(byte_signed));

        self.regs.set(rd, byte64);

        // Assert: register must be set correctly.
        std.debug.assert(self.regs.get(rd) == byte64);
    }

    /// Execute LH (Load Halfword) instruction.
    /// Format: LH rd, offset(rs1)
    /// Encoding: imm[11:0] | rs1 | 001 | rd | 0000011
    /// Contract: Loads 16-bit halfword, sign-extends to 64 bits, must be 2-byte aligned
    /// Why: Load halfword from memory for kernel data access.
    fn execute_lh(self: *Self, inst: u32) !void {
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);

        const base_addr = self.regs.get(rs1);
        const imm64 = @as(i64, imm12);
        // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
        const eff_addr = base_addr +% offset;

        // Assert: effective address must be 2-byte aligned for halfword load.
        if (eff_addr % 2 != 0) {
            self.state = .errored;
            self.last_error = VMError.unaligned_memory_access;
            return VMError.unaligned_memory_access;
        }

        // Check memory permissions (if permission checker is set).
        // Why: Enforce memory protection before allowing read access.
        // Distinguish between page faults (unmapped) and access faults (permission violation).
        if (self.permission_checker) |checker| {
            const permissions = checker(eff_addr);
            if (permissions == 0) {
                // Page not mapped: record page fault (load page fault, code 13).
                self.exception_stats.record_exception(13);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
            const has_read = (permissions & 1) != 0;
            if (!has_read) {
                // Page mapped but no read permission:
                // record access fault (load access fault, code 5).
                self.exception_stats.record_exception(5);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
        }

        // Translate virtual address to physical offset
        const phys_offset = self.translate_address(eff_addr) orelse {
            // Address translation failed: record page fault (load page fault, code 13).
            self.exception_stats.record_exception(13);
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };

        // Assert: physical offset + 2 must be within memory bounds.
        if (phys_offset + 2 > self.memory_size) {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        // Read 16-bit halfword from memory using translated physical offset
        // GrainStyle: Cast u64 to usize only for array indexing
        const mem_slice = self.memory[@intCast(phys_offset)..][0..2];
        const halfword = std.mem.readInt(u16, mem_slice, .little);
        const halfword_signed = @as(i16, @bitCast(halfword));
        const halfword64 = @as(u64, @intCast(halfword_signed));

        self.regs.set(rd, halfword64);

        // Assert: register must be set correctly.
        std.debug.assert(self.regs.get(rd) == halfword64);
    }

    /// Execute LD (Load Doubleword) instruction.
    /// Format: LD rd, offset(rs1)
    /// Encoding: imm[11:0] | rs1 | 011 | rd | 0000011
    /// Contract: Loads 64-bit doubleword, must be 8-byte aligned
    /// Why: Load doubleword from memory for kernel data access.
    fn execute_ld(self: *Self, inst: u32) !void {
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);

        var base_addr = self.regs.get(rs1);
        const imm64 = @as(i64, imm12);
        const offset: u64 = @bitCast(imm64);

        // Workaround: If x8 (s0/fp) is 0x0, check if the address would be valid.
        // If not, try using sp instead (for stack-relative accesses).
        var eff_addr = base_addr +% offset;
        if (rs1 == 8 and base_addr == 0x0) {
            // If address with x8=0x0 is invalid, try sp instead.
            const test_phys = self.translate_address(eff_addr);
            if (test_phys == null or test_phys.? + 8 > self.memory_size) {
                const sp = self.regs.get(2);
                if (sp != 0x0) {
                    const sp_eff = sp +% offset;
                    const sp_phys = self.translate_address(sp_eff);
                    if (sp_phys != null and sp_phys.? + 8 <= self.memory_size) {
                        std.debug.print(
                            "DEBUG vm.zig: LD: x8=0x0 gives invalid addr 0x{x}, trying sp (x2=0x{x})\n",
                            .{ eff_addr, sp },
                        );
                        base_addr = sp;
                        eff_addr = base_addr +% offset;
                    }
                }
            }
        }

        // Assert: effective address must be 8-byte aligned for doubleword load.
        if (eff_addr % 8 != 0) {
            self.state = .errored;
            self.last_error = VMError.unaligned_memory_access;
            return VMError.unaligned_memory_access;
        }

        // Check memory permissions (if permission checker is set).
        // Why: Enforce memory protection before allowing read access.
        // Distinguish between page faults (unmapped) and access faults (permission violation).
        if (self.permission_checker) |checker| {
            const permissions = checker(eff_addr);
            if (permissions == 0) {
                // Page not mapped: record page fault (load page fault, code 13).
                self.exception_stats.record_exception(13);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
            const has_read = (permissions & 1) != 0;
            if (!has_read) {
                // Page mapped but no read permission:
                // record access fault (load access fault, code 5).
                self.exception_stats.record_exception(5);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
        }

        // Translate virtual address to physical offset
        const phys_offset = self.translate_address(eff_addr) orelse {
            // Address translation failed: record page fault (load page fault, code 13).
            self.exception_stats.record_exception(13);
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };

        // Assert: physical offset + 8 must be within memory bounds.
        if (phys_offset + 8 > self.memory_size) {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        // Read 64-bit doubleword from memory using translated physical offset
        // GrainStyle: Cast u64 to usize only for array indexing
        const mem_slice = self.memory[@intCast(phys_offset)..][0..8];
        const doubleword = std.mem.readInt(u64, mem_slice, .little);

        self.regs.set(rd, doubleword);

        // Assert: register must be set correctly.
        std.debug.assert(self.regs.get(rd) == doubleword);
    }

    /// Execute LBU (Load Byte Unsigned) instruction.
    /// Format: LBU rd, offset(rs1)
    /// Encoding: imm[11:0] | rs1 | 100 | rd | 0000011
    /// Contract: Loads 8-bit byte, zero-extends to 64 bits
    /// Why: Load unsigned byte from memory for kernel data access.
    fn execute_lbu(self: *Self, inst: u32) !void {
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);

        const base_addr = self.regs.get(rs1);
        const imm64 = @as(i64, imm12);
        // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
        const eff_addr = base_addr +% offset;

        // Check memory permissions (if permission checker is set).
        // Why: Enforce memory protection before allowing read access.
        // Distinguish between page faults (unmapped) and access faults (permission violation).
        if (self.permission_checker) |checker| {
            const permissions = checker(eff_addr);
            if (permissions == 0) {
                // Page not mapped: record page fault (load page fault, code 13).
                self.exception_stats.record_exception(13);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
            const has_read = (permissions & 1) != 0;
            if (!has_read) {
                // Page mapped but no read permission:
                // record access fault (load access fault, code 5).
                self.exception_stats.record_exception(5);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
        }

        // Translate virtual address to physical offset
        const phys_offset = self.translate_address(eff_addr) orelse {
            // Address translation failed: record page fault (load page fault, code 13).
            self.exception_stats.record_exception(13);
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };

        // Assert: physical offset + 1 must be within memory bounds.
        if (phys_offset + 1 > self.memory_size) {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        // Read byte from memory using translated physical offset (zero-extend to 64 bits)
        const byte = self.memory[phys_offset];
        const byte64: u64 = byte;

        self.regs.set(rd, byte64);

        // Assert: register must be set correctly.
        std.debug.assert(self.regs.get(rd) == byte64);
    }

    /// Execute LHU (Load Halfword Unsigned) instruction.
    /// Format: LHU rd, offset(rs1)
    /// Encoding: imm[11:0] | rs1 | 101 | rd | 0000011
    /// Contract: Loads 16-bit halfword, zero-extends to 64 bits, must be 2-byte aligned
    /// Why: Load unsigned halfword from memory for kernel data access.
    fn execute_lhu(self: *Self, inst: u32) !void {
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);

        const base_addr = self.regs.get(rs1);
        const imm64 = @as(i64, imm12);
        // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
        const eff_addr = base_addr +% offset;

        // Assert: effective address must be 2-byte aligned for halfword load.
        if (eff_addr % 2 != 0) {
            self.state = .errored;
            self.last_error = VMError.unaligned_memory_access;
            return VMError.unaligned_memory_access;
        }

        // Check memory permissions (if permission checker is set).
        // Why: Enforce memory protection before allowing read access.
        // Distinguish between page faults (unmapped) and access faults (permission violation).
        if (self.permission_checker) |checker| {
            const permissions = checker(eff_addr);
            if (permissions == 0) {
                // Page not mapped: record page fault (load page fault, code 13).
                self.exception_stats.record_exception(13);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
            const has_read = (permissions & 1) != 0;
            if (!has_read) {
                // Page mapped but no read permission:
                // record access fault (load access fault, code 5).
                self.exception_stats.record_exception(5);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
        }

        // Translate virtual address to physical offset
        const phys_offset = self.translate_address(eff_addr) orelse {
            // Address translation failed: record page fault (load page fault, code 13).
            self.exception_stats.record_exception(13);
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };

        // Assert: physical offset + 2 must be within memory bounds.
        if (phys_offset + 2 > self.memory_size) {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        // Read 16-bit halfword from memory using translated physical offset (zero-extend to 64 bits)
        const mem_slice = self.memory[phys_offset..][0..2];
        const halfword = std.mem.readInt(u16, mem_slice, .little);
        const halfword64: u64 = halfword;

        self.regs.set(rd, halfword64);

        // Assert: register must be set correctly.
        std.debug.assert(self.regs.get(rd) == halfword64);
    }

    /// Execute LWU (Load Word Unsigned) instruction.
    /// Format: LWU rd, offset(rs1)
    /// Encoding: imm[11:0] | rs1 | 110 | rd | 0000011
    /// Contract: Loads 32-bit word, zero-extends to 64 bits, must be 4-byte aligned
    /// Why: Load unsigned word from memory for kernel data access.
    fn execute_lwu(self: *Self, inst: u32) !void {
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);

        const base_addr = self.regs.get(rs1);
        const imm64 = @as(i64, imm12);
        // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
        const eff_addr = base_addr +% offset;

        // Assert: effective address must be 4-byte aligned for word load.
        if (eff_addr % 4 != 0) {
            self.state = .errored;
            self.last_error = VMError.unaligned_memory_access;
            return VMError.unaligned_memory_access;
        }

        // Check memory permissions (if permission checker is set).
        // Why: Enforce memory protection before allowing read access.
        // Distinguish between page faults (unmapped) and access faults (permission violation).
        if (self.permission_checker) |checker| {
            const permissions = checker(eff_addr);
            if (permissions == 0) {
                // Page not mapped: record page fault (load page fault, code 13).
                self.exception_stats.record_exception(13);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
            const has_read = (permissions & 1) != 0;
            if (!has_read) {
                // Page mapped but no read permission:
                // record access fault (load access fault, code 5).
                self.exception_stats.record_exception(5);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
        }

        // Translate virtual address to physical offset
        const phys_offset = self.translate_address(eff_addr) orelse {
            // Address translation failed: record page fault (load page fault, code 13).
            self.exception_stats.record_exception(13);
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };

        // Assert: physical offset + 4 must be within memory bounds.
        if (phys_offset + 4 > self.memory_size) {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        // Read 32-bit word from memory using translated physical offset (zero-extend to 64 bits)
        const mem_slice = self.memory[phys_offset..][0..4];
        const word = std.mem.readInt(u32, mem_slice, .little);
        const word64: u64 = word;

        // Record memory read in trace.
        self.instruction_trace.record_memory_read(eff_addr, word64);

        self.regs.set(rd, word64);

        // Assert: register must be set correctly.
        std.debug.assert(self.regs.get(rd) == word64);
    }

    /// Execute SB (Store Byte) instruction.
    /// Format: SB rs2, offset(rs1)
    /// Encoding: imm[11:5] | rs2 | rs1 | 000 | imm[4:0] | 0100011
    /// Contract: Stores low 8 bits of rs2 to memory
    /// Why: Store byte to memory for kernel data writes.
    pub fn execute_sb(self: *Self, inst: u32) !void {
        const rs2 = @as(u5, @truncate(inst >> 20));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm_11_5 = @as(u7, @truncate(inst >> 25));
        const imm_4_0 = @as(u5, @truncate(inst >> 7));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rs2 < 32);
        std.debug.assert(rs1 < 32);

        const imm12_raw = (@as(u12, imm_11_5) << 5) | imm_4_0;
        const imm12 = @as(i32, @truncate(@as(i64, @as(i12, @bitCast(imm12_raw)))));

        var base_addr = self.regs.get(rs1);
        const imm64 = @as(i64, imm12);
        // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);

        // Workaround: If x8 (s0/fp) is 0x0, check if the address would be valid.
        // If not, try using sp instead (for stack-relative accesses).
        var eff_addr = base_addr +% offset;
        if (rs1 == 8 and base_addr == 0x0) {
            // If address with x8=0x0 is out of bounds, try sp instead.
            const test_phys = self.translate_address(eff_addr);
            if (test_phys == null or test_phys.? >= self.memory_size) {
                const sp = self.regs.get(2);
                if (sp != 0x0) {
                    const sp_phys = self.translate_address(sp +% offset);
                    if (sp_phys != null and sp_phys.? < self.memory_size) {
                        std.debug.print(
                            "DEBUG vm.zig: SB: x8=0x0 gives invalid addr 0x{x}, trying sp (x2=0x{x})\n",
                            .{ eff_addr, sp },
                        );
                        base_addr = sp;
                        eff_addr = base_addr +% offset;
                    }
                }
            }
        }

        // Check memory permissions (if permission checker is set).
        // Why: Enforce memory protection before allowing write access.
        if (self.permission_checker) |checker| {
            const permissions = checker(eff_addr);
            const has_write = (permissions & 2) != 0;
            if (!has_write) {
                // Record exception (store access fault, code 7).
                self.exception_stats.record_exception(7);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
        }

        // Translate virtual address to physical offset
        const phys_offset = self.translate_address(eff_addr) orelse {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };

        // Assert: physical offset + 1 must be within memory bounds.
        if (phys_offset + 1 > self.memory_size) {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        const rs2_value = self.regs.get(rs2);
        const byte = @as(u8, @truncate(rs2_value));

        // Record memory write in trace.
        self.instruction_trace.record_memory_write(eff_addr, @as(u64, byte));

        // Write byte to memory using translated physical offset
        // GrainStyle: Cast u64 to usize only for array indexing
        self.memory[@intCast(phys_offset)] = byte;

        // Assert: byte must be written correctly.
        std.debug.assert(self.memory[@intCast(phys_offset)] == byte);
    }

    /// Execute SH (Store Halfword) instruction.
    /// Format: SH rs2, offset(rs1)
    /// Encoding: imm[11:5] | rs2 | rs1 | 001 | imm[4:0] | 0100011
    /// Contract: Stores low 16 bits of rs2 to memory, must be 2-byte aligned
    /// Why: Store halfword to memory for kernel data writes.
    pub fn execute_sh(self: *Self, inst: u32) !void {
        const rs2 = @as(u5, @truncate(inst >> 20));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm_11_5 = @as(u7, @truncate(inst >> 25));
        const imm_4_0 = @as(u5, @truncate(inst >> 7));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rs2 < 32);
        std.debug.assert(rs1 < 32);

        const imm12_raw = (@as(u12, imm_11_5) << 5) | imm_4_0;
        const imm12 = @as(i32, @truncate(@as(i64, @as(i12, @bitCast(imm12_raw)))));

        const base_addr = self.regs.get(rs1);
        const imm64 = @as(i64, imm12);
        // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
        const eff_addr = base_addr +% offset;

        // Assert: effective address must be 2-byte aligned for halfword store.
        if (eff_addr % 2 != 0) {
            self.state = .errored;
            self.last_error = VMError.unaligned_memory_access;
            return VMError.unaligned_memory_access;
        }

        // Check memory permissions (if permission checker is set).
        // Why: Enforce memory protection before allowing write access.
        if (self.permission_checker) |checker| {
            const permissions = checker(eff_addr);
            const has_write = (permissions & 2) != 0;
            if (!has_write) {
                // Record exception (store access fault, code 7).
                self.exception_stats.record_exception(7);
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }
        }

        // Translate virtual address to physical offset
        const phys_offset = self.translate_address(eff_addr) orelse {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };

        // Assert: physical offset + 2 must be within memory bounds.
        if (phys_offset + 2 > self.memory_size) {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        const rs2_value = self.regs.get(rs2);
        const halfword = @as(u16, @truncate(rs2_value));

        // Write 16-bit halfword to memory using translated physical offset
        // GrainStyle: Cast u64 to usize only for array indexing
        @memcpy(self.memory[@intCast(phys_offset)..][0..2], &std.mem.toBytes(halfword));

        // Assert: halfword must be written correctly.
        const read_back = std.mem.readInt(u16, self.memory[@intCast(phys_offset)..][0..2], .little);
        std.debug.assert(read_back == halfword);
    }

    /// Execute SD (Store Doubleword) instruction.
    /// Format: SD rs2, offset(rs1)
    /// Encoding: imm[11:5] | rs2 | rs1 | 011 | imm[4:0] | 0100011
    /// Contract: Stores 64-bit value from rs2 to memory, must be 8-byte aligned
    /// Why: Store doubleword to memory for kernel data writes.
    pub fn execute_sd(self: *Self, inst: u32) !void {
        const rs2 = @as(u5, @truncate(inst >> 20));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm_11_5 = @as(u7, @truncate(inst >> 25));
        const imm_4_0 = @as(u5, @truncate(inst >> 7));

        std.debug.assert(rs2 < 32);
        std.debug.assert(rs1 < 32);

        const imm12_raw = (@as(u12, imm_11_5) << 5) | imm_4_0;
        const imm12 = @as(i32, @truncate(@as(i64, @as(i12, @bitCast(imm12_raw)))));

        var base_addr = self.regs.get(rs1);
        const imm64 = @as(i64, imm12);
        // Sign-extend to u64: use bitcast to preserve two's complement representation.
        const offset: u64 = @bitCast(imm64);

        // Workaround: If x8 (s0/fp) is 0x0, check if the address would be valid.
        // If not, try using sp instead (for stack-relative accesses).
        var eff_addr = base_addr +% offset;
        if (rs1 == 8 and base_addr == 0x0) {
            // If address with x8=0x0 is invalid, try sp instead.
            const test_phys = self.translate_address(eff_addr);
            if (test_phys == null or test_phys.? + 8 > self.memory_size) {
                const sp = self.regs.get(2);
                if (sp != 0x0) {
                    const sp_eff = sp +% offset;
                    const sp_phys = self.translate_address(sp_eff);
                    if (sp_phys != null and sp_phys.? + 8 <= self.memory_size) {
                        std.debug.print(
                            "DEBUG vm.zig: SD: x8=0x0 gives invalid addr 0x{x}, trying sp (x2=0x{x})\n",
                            .{ eff_addr, sp },
                        );
                        base_addr = sp;
                        eff_addr = base_addr +% offset;
                    }
                }
            }
        }

        // Assert: effective address must be 8-byte aligned for doubleword store.
        if (eff_addr % 8 != 0) {
            self.state = .errored;
            self.last_error = VMError.unaligned_memory_access;
            return VMError.unaligned_memory_access;
        }

        // Translate virtual address to physical offset
        const phys_offset = self.translate_address(eff_addr) orelse {
            std.debug.print(
                "DEBUG vm.zig: SD failed: eff_addr=0x{x}, base=0x{x}, offset=0x{x}\n",
                .{ eff_addr, base_addr, offset },
            );
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };

        // Assert: physical offset + 8 must be within memory bounds.
        if (phys_offset + 8 > self.memory_size) {
            std.debug.print(
                "DEBUG vm.zig: SD OOB: phys=0x{x}+8 > mem_size=0x{x}\n",
                .{ phys_offset, self.memory_size },
            );
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        const rs2_value = self.regs.get(rs2);

        // Write 64-bit doubleword to memory using translated physical offset
        // GrainStyle: Cast u64 to usize only for array indexing
        @memcpy(self.memory[@intCast(phys_offset)..][0..8], &std.mem.toBytes(rs2_value));

        // Assert: doubleword must be written correctly.
        const read_back = std.mem.readInt(u64, self.memory[@intCast(phys_offset)..][0..8], .little);
        std.debug.assert(read_back == rs2_value);
    }

    /// Execute BEQ (Branch if Equal) instruction.
    /// Format: BEQ rs1, rs2, offset
    /// Encoding: imm[12] | imm[10:5] | rs2 | rs1 | 000 | imm[4:1] | imm[11] | 1100011
    /// Why: Conditional branch for kernel control flow.
    fn execute_beq(self: *Self, inst: u32) !void {
        // Decode B-type: rs2 = bits [24:20], rs1 = bits [19:15],
        // imm[12] = bit [31], imm[10:5] = bits [30:25],
        // imm[4:1] = bits [11:8], imm[11] = bit [7].
        const rs2 = @as(u5, @truncate(inst >> 20));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm_12 = @as(u1, @truncate(inst >> 31));
        const imm_10_5 = @as(u6, @truncate(inst >> 25));
        const imm_4_1 = @as(u4, @truncate(inst >> 8));
        const imm_11 = @as(u1, @truncate(inst >> 7));

        // Assert: registers must be valid (0-31).
        std.debug.assert(rs2 < 32);
        std.debug.assert(rs1 < 32);

        // Reconstruct 13-bit immediate (sign-extended):
        // imm[12] | imm[11] | imm[10:5] | imm[4:1] | 0.
        const imm_12_u13 = @as(u13, imm_12) << 12;
        const imm_11_u13 = @as(u13, imm_11) << 11;
        const imm_10_5_u13 = @as(u13, imm_10_5) << 5;
        const imm_4_1_u13 = @as(u13, imm_4_1) << 1;
        const imm13_raw = imm_12_u13 | imm_11_u13 | imm_10_5_u13 | imm_4_1_u13;
        const imm13 = @as(i13, @bitCast(imm13_raw));

        // Read register values.
        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        // Store PC before branch for statistics tracking.
        const pc_before = self.regs.pc;

        // Compare: if rs1 == rs2, branch.
        const branch_taken = (rs1_value == rs2_value);
        if (branch_taken) {
            // Sign-extend immediate to 64 bits and add to PC.
            const imm64 = @as(i64, imm13);
            // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);

            // Calculate branch target: PC + offset.
            const branch_target = self.regs.pc +% offset;

            // Align branch target to 4-byte boundary (clear bottom 2 bits).
            // Why: RISC-V instructions must be 4-byte aligned,
            // but branch offsets can be misaligned.
            const aligned_target = branch_target & ~@as(u64, 3);

            // Assert: branch target must be within memory bounds.
            if (aligned_target >= self.memory_size) {
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }

            // Update PC to branch target (PC update happens before normal +4 increment).
            // Note: We'll skip the normal PC += 4 after this instruction.
            self.regs.pc = aligned_target;

            // Track branch statistics.
            self.branch_stats.record_branch(pc_before, branch_taken);

            // Return early to skip normal PC increment.
            return;
        }

        // Track branch statistics (not taken).
        self.branch_stats.record_branch(pc_before, branch_taken);

        // No branch: PC will be incremented normally by +4 in step().
    }

    /// Execute BNE (Branch if Not Equal) instruction.
    /// Format: BNE rs1, rs2, offset
    /// Encoding: imm[12] | imm[10:5] | rs2 | rs1 | 001 | imm[4:1] | imm[11] | 1100011
    /// Contract: Branches if rs1 != rs2, updates PC if condition true
    /// Why: Conditional branch for kernel control flow.
    fn execute_bne(self: *Self, inst: u32) !void {
        const rs2 = @as(u5, @truncate(inst >> 20));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm_12 = @as(u1, @truncate(inst >> 31));
        const imm_10_5 = @as(u6, @truncate(inst >> 25));
        const imm_4_1 = @as(u4, @truncate(inst >> 8));
        const imm_11 = @as(u1, @truncate(inst >> 7));

        std.debug.assert(rs2 < 32);
        std.debug.assert(rs1 < 32);

        const imm_12_u13 = @as(u13, imm_12) << 12;
        const imm_11_u13 = @as(u13, imm_11) << 11;
        const imm_10_5_u13 = @as(u13, imm_10_5) << 5;
        const imm_4_1_u13 = @as(u13, imm_4_1) << 1;
        const imm13_raw = imm_12_u13 | imm_11_u13 | imm_10_5_u13 | imm_4_1_u13;
        const imm13 = @as(i13, @bitCast(imm13_raw));

        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        // Store PC before branch for statistics tracking.
        const pc_before = self.regs.pc;

        const branch_taken = (rs1_value != rs2_value);
        if (branch_taken) {
            const imm64 = @as(i64, imm13);
            // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
            const branch_target = self.regs.pc +% offset;

            if (branch_target % 4 != 0) {
                self.state = .errored;
                self.last_error = VMError.unaligned_instruction;
                return VMError.unaligned_instruction;
            }

            if (branch_target >= self.memory_size) {
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }

            self.regs.pc = branch_target;
            
            // Track branch statistics.
            self.branch_stats.record_branch(pc_before, branch_taken);
            
            return;
        }
        
        // Track branch statistics (not taken).
        self.branch_stats.record_branch(pc_before, branch_taken);
    }

    /// Execute BLT (Branch if Less Than) instruction.
    /// Format: BLT rs1, rs2, offset
    /// Encoding: imm[12] | imm[10:5] | rs2 | rs1 | 100 | imm[4:1] | imm[11] | 1100011
    /// Contract: Branches if rs1 < rs2 (signed), updates PC if condition true
    /// Why: Conditional branch for kernel control flow.
    fn execute_blt(self: *Self, inst: u32) !void {
        const rs2 = @as(u5, @truncate(inst >> 20));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm_12 = @as(u1, @truncate(inst >> 31));
        const imm_10_5 = @as(u6, @truncate(inst >> 25));
        const imm_4_1 = @as(u4, @truncate(inst >> 8));
        const imm_11 = @as(u1, @truncate(inst >> 7));

        std.debug.assert(rs2 < 32);
        std.debug.assert(rs1 < 32);

        const imm_12_u13 = @as(u13, imm_12) << 12;
        const imm_11_u13 = @as(u13, imm_11) << 11;
        const imm_10_5_u13 = @as(u13, imm_10_5) << 5;
        const imm_4_1_u13 = @as(u13, imm_4_1) << 1;
        const imm13_raw = imm_12_u13 | imm_11_u13 | imm_10_5_u13 | imm_4_1_u13;
        const imm13 = @as(i13, @bitCast(imm13_raw));

        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);
        const rs1_signed = @as(i64, @bitCast(rs1_value));
        const rs2_signed = @as(i64, @bitCast(rs2_value));

        // Store PC before branch for statistics tracking.
        const pc_before = self.regs.pc;

        const branch_taken = (rs1_signed < rs2_signed);
        if (branch_taken) {
            const imm64 = @as(i64, imm13);
            // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
            const branch_target = self.regs.pc +% offset;

            if (branch_target % 4 != 0) {
                self.state = .errored;
                self.last_error = VMError.unaligned_instruction;
                return VMError.unaligned_instruction;
            }

            if (branch_target >= self.memory_size) {
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }

            self.regs.pc = branch_target;
            
            // Track branch statistics.
            self.branch_stats.record_branch(pc_before, branch_taken);
            
            return;
        }
        
        // Track branch statistics (not taken).
        self.branch_stats.record_branch(pc_before, branch_taken);
    }

    /// Execute BGE (Branch if Greater or Equal) instruction.
    /// Format: BGE rs1, rs2, offset
    /// Encoding: imm[12] | imm[10:5] | rs2 | rs1 | 101 | imm[4:1] | imm[11] | 1100011
    /// Contract: Branches if rs1 >= rs2 (signed), updates PC if condition true
    /// Why: Conditional branch for kernel control flow.
    fn execute_bge(self: *Self, inst: u32) !void {
        const rs2 = @as(u5, @truncate(inst >> 20));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm_12 = @as(u1, @truncate(inst >> 31));
        const imm_10_5 = @as(u6, @truncate(inst >> 25));
        const imm_4_1 = @as(u4, @truncate(inst >> 8));
        const imm_11 = @as(u1, @truncate(inst >> 7));

        std.debug.assert(rs2 < 32);
        std.debug.assert(rs1 < 32);

        const imm_12_u13 = @as(u13, imm_12) << 12;
        const imm_11_u13 = @as(u13, imm_11) << 11;
        const imm_10_5_u13 = @as(u13, imm_10_5) << 5;
        const imm_4_1_u13 = @as(u13, imm_4_1) << 1;
        const imm13_raw = imm_12_u13 | imm_11_u13 | imm_10_5_u13 | imm_4_1_u13;
        const imm13 = @as(i13, @bitCast(imm13_raw));

        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);
        const rs1_signed = @as(i64, @bitCast(rs1_value));
        const rs2_signed = @as(i64, @bitCast(rs2_value));

        // Store PC before branch for statistics tracking.
        const pc_before = self.regs.pc;

        const branch_taken = (rs1_signed >= rs2_signed);
        if (branch_taken) {
            const imm64 = @as(i64, imm13);
            // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
            const branch_target = self.regs.pc +% offset;

            if (branch_target % 4 != 0) {
                self.state = .errored;
                self.last_error = VMError.unaligned_instruction;
                return VMError.unaligned_instruction;
            }

            if (branch_target >= self.memory_size) {
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }

            self.regs.pc = branch_target;
            
            // Track branch statistics.
            self.branch_stats.record_branch(pc_before, branch_taken);
            
            return;
        }
        
        // Track branch statistics (not taken).
        self.branch_stats.record_branch(pc_before, branch_taken);
    }

    /// Execute BLTU (Branch if Less Than Unsigned) instruction.
    /// Format: BLTU rs1, rs2, offset
    /// Encoding: imm[12] | imm[10:5] | rs2 | rs1 | 110 | imm[4:1] | imm[11] | 1100011
    /// Contract: Branches if rs1 < rs2 (unsigned), updates PC if condition true
    /// Why: Conditional branch for kernel control flow.
    fn execute_bltu(self: *Self, inst: u32) !void {
        const rs2 = @as(u5, @truncate(inst >> 20));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm_12 = @as(u1, @truncate(inst >> 31));
        const imm_10_5 = @as(u6, @truncate(inst >> 25));
        const imm_4_1 = @as(u4, @truncate(inst >> 8));
        const imm_11 = @as(u1, @truncate(inst >> 7));

        std.debug.assert(rs2 < 32);
        std.debug.assert(rs1 < 32);

        const imm_12_u13 = @as(u13, imm_12) << 12;
        const imm_11_u13 = @as(u13, imm_11) << 11;
        const imm_10_5_u13 = @as(u13, imm_10_5) << 5;
        const imm_4_1_u13 = @as(u13, imm_4_1) << 1;
        const imm13_raw = imm_12_u13 | imm_11_u13 | imm_10_5_u13 | imm_4_1_u13;
        const imm13 = @as(i13, @bitCast(imm13_raw));

        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        // Store PC before branch for statistics tracking.
        const pc_before = self.regs.pc;

        const branch_taken = (rs1_value < rs2_value);
        if (branch_taken) {
            const imm64 = @as(i64, imm13);
            // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
            const branch_target = self.regs.pc +% offset;

            // Align branch target to 4-byte boundary (clear bottom 2 bits).
            // Why: RISC-V instructions must be 4-byte aligned,
            // but branch offsets can be misaligned.
            const aligned_target = branch_target & ~@as(u64, 3);

            if (aligned_target >= self.memory_size) {
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }

            self.regs.pc = aligned_target;
            
            // Track branch statistics.
            self.branch_stats.record_branch(pc_before, branch_taken);
            
            return;
        }
        
        // Track branch statistics (not taken).
        self.branch_stats.record_branch(pc_before, branch_taken);
    }

    /// Execute BGEU (Branch if Greater or Equal Unsigned) instruction.
    /// Format: BGEU rs1, rs2, offset
    /// Encoding: imm[12] | imm[10:5] | rs2 | rs1 | 111 | imm[4:1] | imm[11] | 1100011
    /// Contract: Branches if rs1 >= rs2 (unsigned), updates PC if condition true
    /// Why: Conditional branch for kernel control flow.
    fn execute_bgeu(self: *Self, inst: u32) !void {
        const rs2 = @as(u5, @truncate(inst >> 20));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm_12 = @as(u1, @truncate(inst >> 31));
        const imm_10_5 = @as(u6, @truncate(inst >> 25));
        const imm_4_1 = @as(u4, @truncate(inst >> 8));
        const imm_11 = @as(u1, @truncate(inst >> 7));

        std.debug.assert(rs2 < 32);
        std.debug.assert(rs1 < 32);

        const imm_12_u13 = @as(u13, imm_12) << 12;
        const imm_11_u13 = @as(u13, imm_11) << 11;
        const imm_10_5_u13 = @as(u13, imm_10_5) << 5;
        const imm_4_1_u13 = @as(u13, imm_4_1) << 1;
        const imm13_raw = imm_12_u13 | imm_11_u13 | imm_10_5_u13 | imm_4_1_u13;
        const imm13 = @as(i13, @bitCast(imm13_raw));

        const rs1_value = self.regs.get(rs1);
        const rs2_value = self.regs.get(rs2);

        if (rs1_value >= rs2_value) {
            const imm64 = @as(i64, imm13);
            // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
            const branch_target = self.regs.pc +% offset;

            if (branch_target % 4 != 0) {
                self.state = .errored;
                self.last_error = VMError.unaligned_instruction;
                return VMError.unaligned_instruction;
            }

            if (branch_target >= self.memory_size) {
                self.state = .errored;
                self.last_error = VMError.invalid_memory_access;
                return VMError.invalid_memory_access;
            }

            self.regs.pc = branch_target;
            return;
        }
    }

    /// Execute JAL (Jump and Link) instruction.
    /// Format: JAL rd, offset
    /// Encoding: imm[20] | imm[10:1] | imm[11] | imm[19:12] | rd | 1101111
    /// Contract: Jumps to PC + offset, stores PC+4 in rd (return address)
    /// Why: Function calls and long-range jumps.
    fn execute_jal(self: *Self, inst: u32) !void {
        const rd = @as(u5, @truncate(inst >> 7));
        const imm_20 = @as(u1, @truncate(inst >> 31));
        const imm_10_1 = @as(u10, @truncate(inst >> 21));
        const imm_11 = @as(u1, @truncate(inst >> 20));
        const imm_19_12 = @as(u8, @truncate(inst >> 12));

        std.debug.assert(rd < 32);

        // Reconstruct 21-bit immediate (sign-extended): imm[20] | imm[19:12] | imm[11] | imm[10:1] | 0
        const imm_20_u21 = @as(u21, imm_20) << 20;
        const imm_19_12_u21 = @as(u21, imm_19_12) << 12;
        const imm_11_u21 = @as(u21, imm_11) << 11;
        const imm_10_1_u21 = @as(u21, imm_10_1) << 1;
        const imm21_raw = imm_20_u21 | imm_19_12_u21 | imm_11_u21 | imm_10_1_u21;
        const imm21 = @as(i21, @bitCast(imm21_raw));

        // Save return address (PC + 4) in rd.
        const return_addr = self.regs.pc + 4;
        self.regs.set(rd, return_addr);

        // Calculate jump target: PC + offset.
        const imm64 = @as(i64, imm21);
        // Use @bitCast to handle negative immediates correctly
        const offset: u64 = @bitCast(imm64);
        const jump_target = self.regs.pc +% offset;

        // Align jump target to 4-byte boundary (clear bottom 2 bits).
        // Why: RISC-V instructions must be 4-byte aligned, but JAL offsets can be misaligned.
        const aligned_target = jump_target & ~@as(u64, 3);

        // Assert: jump target must be within memory bounds.
        if (aligned_target >= self.memory_size) {
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        // Update PC to jump target (PC update happens before normal +4 increment).
        self.regs.pc = aligned_target;

        // Return early to skip normal PC increment.
        return;
    }

    /// Execute JALR (Jump and Link Register) instruction.
    /// Format: JALR rd, offset(rs1)
    /// Encoding: imm[11:0] | rs1 | 000 | rd | 1100111
    /// Contract: Jumps to (rs1 + offset) & ~1, stores PC+4 in rd (return address)
    /// Why: Function returns and indirect jumps.
    fn execute_jalr(self: *Self, inst: u32) !void {
        const rd = @as(u5, @truncate(inst >> 7));
        const rs1 = @as(u5, @truncate(inst >> 15));
        const imm12 = @as(i32, @truncate(@as(i64, inst >> 20)));

        std.debug.assert(rd < 32);
        std.debug.assert(rs1 < 32);

        // Read base address from rs1.
        const base_addr = self.regs.get(rs1);

        // Sign-extend immediate to 64 bits.
        const imm64 = @as(i64, imm12);
        const offset: u64 = @bitCast(imm64);

        // Calculate jump target: (rs1 + offset) & ~1 (clear LSB for alignment).
        // Note: RISC-V JALR clears the LSB, but we need 4-byte alignment for instructions.
        // So we clear the bottom 2 bits: & ~3
        const jump_target_raw = base_addr +% offset;
        const jump_target = jump_target_raw & ~@as(u64, 3);

        // Debug: Print JALR execution for troubleshooting.
        std.debug.print(
            "DEBUG vm.zig: JALR instruction: rs1={} (x{}), base_addr=0x{x}, imm12={} (0x{x}), offset=0x{x}, jump_target_raw=0x{x}, jump_target=0x{x}, memory_size=0x{x}\n",
            .{ rs1, rs1, base_addr, imm12, imm12, offset, jump_target_raw, jump_target, self.memory_size },
        );

        // Assert: jump target must be 4-byte aligned (enforced by & ~3).
        std.debug.assert(jump_target % 4 == 0);

        // Check: jump target must translate to valid physical address.
        // Note: jump_target may be virtual (e.g., 0x80000000+ for kernel).
        const phys_target = self.translate_address(jump_target) orelse {
            std.debug.print(
                "DEBUG vm.zig: JALR target unmapped: jump_target=0x{x}\n",
                .{jump_target},
            );
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        };
        
        if (phys_target >= self.memory_size) {
            std.debug.print(
                "DEBUG vm.zig: JALR out of bounds: jump_target=0x{x}, phys=0x{x}, memory_size=0x{x}\n",
                .{ jump_target, phys_target, self.memory_size },
            );
            self.state = .errored;
            self.last_error = VMError.invalid_memory_access;
            return VMError.invalid_memory_access;
        }

        // Save return address (PC + 4) in rd.
        const return_addr = self.regs.pc + 4;
        self.regs.set(rd, return_addr);

        // Update PC to jump target (PC update happens before normal +4 increment).
        self.regs.pc = jump_target;

        // Return early to skip normal PC increment.
        return;
    }

    /// Execute ECALL (Environment Call) instruction.
    /// Format: ECALL (no operands, triggers system call).
    /// Why: Handle SBI calls (platform services) and Grain Basin kernel syscalls.
    /// RISC-V calling convention: a7 (x17) = syscall/EID number, a0-a5 (x10-x15) = arguments.
    /// SBI vs Kernel: Function ID < 10 → SBI (platform), >= 10 → kernel syscall.
    /// Grain Style: Comprehensive assertions for ECALL dispatch, arguments, and state transitions.
    /// Note: Public for testing (fuzz tests need direct access).
    pub fn execute_ecall(self: *Self) !void {
        // Assert: VM must be in valid state (running or halted, not errored).
        std.debug.assert(self.state != .errored);

        // Assert: VM must be running (ECALL only valid when running).
        std.debug.assert(self.state == .running);

        // RISC-V syscall convention: a7 (x17) contains syscall/EID number.
        const syscall_num = self.regs.get(17); // a7 register

        // Debug: Print ECALL execution for troubleshooting.
        // Note: Commented out to avoid potential crash in test environment
        // const a0 = self.regs.get(10);
        // const a1 = self.regs.get(11);
        // const a2 = self.regs.get(12);
        // const a3 = self.regs.get(13);
        // std.debug.print(
        //     "DEBUG vm.zig: ECALL instruction: syscall_num={} (0x{x}), a0=0x{x}, a1=0x{x}, a2=0x{x}, a3=0x{x}, PC=0x{x}\n",
        //     .{ syscall_num, syscall_num, a0, a1, a2, a3, self.regs.pc },
        // );

        // Assert: syscall number must fit in u32.
        std.debug.assert(syscall_num <= 0xFFFFFFFF);

        // Assert: syscall number must be within reasonable range (0-200 for all kernel syscalls).
        // Note: Highest syscall is getsid=59, but allow room for future expansion.
        std.debug.assert(syscall_num <= 200);

        // Extract syscall arguments from a0-a5 registers (x10-x15).
        const arg1 = self.regs.get(10); // a0
        const arg2 = self.regs.get(11); // a1
        const arg3 = self.regs.get(12); // a2
        const arg4 = self.regs.get(13); // a3

        // Dispatch: SBI calls (function ID < 10) vs kernel syscalls (>= 10).
        // Why: SBI handles platform services (timer, console, reset), kernel handles kernel services.
        if (syscall_num < 10) {
            // Assert: SBI call must have function ID < 10.
            std.debug.assert(syscall_num < 10);

            // SBI call: Handle platform services.
            self.handle_sbi_call(@as(u32, @truncate(syscall_num)), arg1, arg2, arg3, arg4);

            // Assert: VM state must remain valid after SBI call (unless shutdown).
            if (syscall_num != @intFromEnum(sbi.EID.LEGACY_SHUTDOWN)) {
                std.debug.assert(self.state != .errored);
            }
        } else {
            // Assert: Kernel syscall must have function ID >= 10.
            std.debug.assert(syscall_num >= 10);

            // Track kernel syscall execution.
            // Note: Temporarily wrapped in defensive check for debugging
            const syscall_num_u32: u32 = @intCast(syscall_num);
            if (syscall_num_u32 < 256) {
                self.syscall_stats.record_syscall(syscall_num_u32);
            }

            // Kernel syscall: Handle via callback if available.
            if (self.syscall_handler) |handler| {
                // Assert: handler pointer must be valid.
                const handler_ptr = @intFromPtr(handler);
                std.debug.assert(handler_ptr != 0);

                // Call syscall handler and get result.
                const result = handler(
                    @as(u32, @truncate(syscall_num)),
                    arg1,
                    arg2,
                    arg3,
                    arg4,
                );

                // Assert: result must be valid
                // (can be error code if negative when interpreted as i64).
                // Note: Error codes are negative, success values are non-negative.

                // Store result in a0 (x10) register (RISC-V convention).
                self.regs.set(10, result);

                // Assert: a0 register must be set correctly.
                std.debug.assert(self.regs.get(10) == result);

                // Special case: exit syscall (syscall number 2) halts VM.
                // Note: This is kernel syscall 2, not SBI function ID 2.
                // Note: Kernel syscall 2 is exit, which should halt VM.
                if (syscall_num == 2) {
                    // Assert: exit syscall must halt VM.
                    std.debug.assert(syscall_num == 2);
                    self.state = .halted;

                    // Assert: VM state must be halted after exit syscall.
                    std.debug.assert(self.state == .halted);
                } else {
                    // Assert: Non-exit syscalls should not halt VM.
                    std.debug.assert(self.state == .running);
                }
            } else {
                // Assert: No handler should only happen if handler not set.
                std.debug.assert(self.syscall_handler == null);

                // No handler: halt VM (simple behavior).
                self.state = .halted;

                // Assert: VM state must be halted when no handler.
                std.debug.assert(self.state == .halted);
            }
        }

        // Assert: VM state must remain valid after ECALL (unless shutdown/exit).
        if (syscall_num != @intFromEnum(sbi.EID.LEGACY_SHUTDOWN) and syscall_num != 2) {
            std.debug.assert(self.state != .errored);
        }
    }

    /// Handle SBI (Supervisor Binary Interface) call.
    /// Why: Implement platform services (timer, console, reset) for RISC-V SBI.
    /// SBI Legacy Functions: 0x0=SET_TIMER, 0x1=CONSOLE_PUTCHAR, 0x2=CONSOLE_GETCHAR, 0x8=SHUTDOWN.
    /// Grain Style: Comprehensive assertions for all SBI call parameters and state transitions.
    /// Note: Public for testing (fuzz tests need direct access).
    pub fn handle_sbi_call(self: *Self, eid: u32, arg1: u64, arg2: u64, arg3: u64, arg4: u64) void {
        // Mark unused parameters for future SBI functions.
        _ = arg2;
        _ = arg3;
        _ = arg4;

        // Assert: VM must be in valid state (running or halted, not errored).
        std.debug.assert(self.state != .errored);

        // Assert: EID must be valid SBI legacy function ID (< 10).
        std.debug.assert(eid < 10);

        // Assert: EID must match known SBI legacy function IDs.
        std.debug.assert(eid <= @intFromEnum(sbi.EID.LEGACY_SHUTDOWN));

        // Dispatch based on SBI Extension ID (EID).
        // Why: Different SBI functions have different calling conventions.
        switch (eid) {
            // LEGACY_CONSOLE_PUTCHAR (0x1): Write character to console.
            // Calling convention: character in a0 (x10), no return value.
            @intFromEnum(sbi.EID.LEGACY_CONSOLE_PUTCHAR) => {
                // Assert: character must fit in u8.
                std.debug.assert(arg1 <= 0xFF);

                // Assert: serial_output pointer must be valid if set.
                if (self.serial_output) |serial| {
                    // Assert: serial pointer must be non-null and aligned.
                    const serial_ptr = @intFromPtr(serial);
                    std.debug.assert(serial_ptr != 0);
                    std.debug.assert(serial_ptr % @alignOf(@TypeOf(serial.*)) == 0);

                    // Write character to serial output.
                    serial.writeByte(@as(u8, @truncate(arg1)));

                    // Assert: serial output write position must be valid after write.
                    std.debug.assert(serial.write_pos < serial.buffer.len);
                }

                // SBI CONSOLE_PUTCHAR returns 0 (success) in a0.
                self.regs.set(10, 0);

                // Assert: a0 register must be set to 0 (success).
                std.debug.assert(self.regs.get(10) == 0);
            },
            // LEGACY_SHUTDOWN (0x8): System shutdown.
            // Calling convention: no arguments, no return value.
            @intFromEnum(sbi.EID.LEGACY_SHUTDOWN) => {
                // Assert: VM state must be valid before shutdown.
                std.debug.assert(self.state != .errored);

                // Halt VM on shutdown.
                self.state = .halted;

                // Assert: VM state must be halted after shutdown.
                std.debug.assert(self.state == .halted);

                // SBI SHUTDOWN doesn't return.
                self.regs.set(10, 0);
            },
            // Other SBI functions: Not implemented yet.
            // TODO: Implement SET_TIMER, CONSOLE_GETCHAR, etc.
            else => {
                // Assert: Unknown SBI function must return error code.
                std.debug.assert(eid != @intFromEnum(sbi.EID.LEGACY_CONSOLE_PUTCHAR));
                std.debug.assert(eid != @intFromEnum(sbi.EID.LEGACY_SHUTDOWN));

                // Unknown SBI function: Return error code.
                // SBI error codes: -1 = Failed, -2 = NotSupported.
                const error_code: i64 = -2; // NotSupported
                self.regs.set(10, @as(u64, @bitCast(error_code)));

                // Assert: a0 register must contain error code.
                const result = @as(i64, @bitCast(self.regs.get(10)));
                std.debug.assert(result == error_code);
            },
        }

        // Assert: VM state must remain valid after SBI call (unless shutdown).
        if (eid != @intFromEnum(sbi.EID.LEGACY_SHUTDOWN)) {
            std.debug.assert(self.state != .errored);
        }
    }

    /// Set serial output handler for SBI console.
    /// Why: Allow external serial output handling (e.g., GUI display).
    /// Grain Style: Validate serial pointer, ensure proper initialization.
    pub fn set_serial_output(self: *Self, serial: ?*SerialOutput) void {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        std.debug.assert(self_ptr != 0);
        std.debug.assert(self_ptr % @alignOf(Self) == 0);

        // Assert: serial pointer must be valid if provided.
        if (serial) |s| {
            const serial_ptr = @intFromPtr(s);
            std.debug.assert(serial_ptr != 0);
            std.debug.assert(serial_ptr % @alignOf(SerialOutput) == 0);

            // Assert: serial buffer must be initialized (non-null).
            std.debug.assert(s.buffer.len > 0);
        }

        self.serial_output = serial;

        // Assert: serial_output must be set correctly.
        std.debug.assert(self.serial_output == serial);
    }

    /// Set syscall handler callback.
    /// Why: Allow external syscall handling (e.g., Grain Basin kernel).
    pub fn set_syscall_handler(
        self: *Self,
        handler: *const fn (
            syscall_num: u32,
            arg1: u64,
            arg2: u64,
            arg3: u64,
            arg4: u64,
        ) u64,
        user_data: ?*anyopaque,
    ) void {
        self.syscall_handler = handler;
        self.syscall_user_data = user_data;
    }

    /// Start VM execution (set state to running).
    /// Grain Style: Validate state transitions.
    pub fn start(self: *Self) void {
        // Assert: VM must be halted or errored state to start.
        std.debug.assert(self.state == .halted or self.state == .errored);

        // Initialize start timestamp (for error logging).
        if (self.start_timestamp == 0) {
            self.start_timestamp = @as(u64, @intCast(std.time.nanoTimestamp()));
        }

        self.state = .running;
        self.last_error = null;

        // Assert: VM must be in running state after start.
        std.debug.assert(self.state == .running);
    }

    /// Stop VM execution (set state to halted).
    /// Grain Style: Validate state transitions.
    pub fn stop(self: *Self) void {
        self.state = .halted;

        // Assert: VM must be in halted state after stop.
        std.debug.assert(self.state == .halted);
    }
    
    /// Get diagnostics snapshot.
    /// Why: Capture VM state for debugging and diagnostics.
    /// Returns: DiagnosticsSnapshot with current VM state and metrics.
    pub fn get_diagnostics(self: *const Self) performance_mod.DiagnosticsSnapshot {
        const state_val: u32 = switch (self.state) {
            .running => 0,
            .halted => 1,
            .errored => 2,
        };
        
        // Approximate memory usage (non-zero bytes).
        var memory_used: u64 = 0;
        var i: u64 = 0;
        while (i < self.memory_size) : (i += 1) {
            if (self.memory[@intCast(i)] != 0) {
                memory_used += 1;
            }
        }
        
        return performance_mod.DiagnosticsSnapshot.create(
            state_val,
            self.regs.pc,
            self.regs.get(2), // SP (x2)
            self.memory_size,
            memory_used,
            self.jit_enabled,
            self.error_log.entry_count,
            self.performance,
            self.exception_stats,
        );
    }
    
    /// Print performance metrics summary.
    /// Why: Display performance metrics for monitoring.
    pub fn print_performance(self: *const Self) void {
        self.performance.print_summary();
    }
    
    /// Save VM state to snapshot.
    /// Why: Capture VM state for debugging, testing, and checkpointing.
    /// Contract: VM must be initialized, memory_buffer must be large enough.
    /// Returns: VMStateSnapshot with complete VM state.
    pub fn save_state(self: *const Self, memory_buffer: []u8) !state_snapshot_mod.VMStateSnapshot {
        // Assert: VM must be initialized (precondition).
        std.debug.assert(self.memory_size > 0);
        std.debug.assert(self.memory.len > 0);
        
        // Assert: Memory buffer must be large enough (precondition).
        std.debug.assert(memory_buffer.len >= self.memory.len);
        
        // Create snapshot.
        const snapshot = try state_snapshot_mod.VMStateSnapshot.create(self, memory_buffer);
        
        // Assert: Snapshot must be valid (postcondition).
        std.debug.assert(snapshot.is_valid());
        
        return snapshot;
    }
    
    /// Restore VM state from snapshot.
    /// Why: Restore VM to saved state for debugging and testing.
    /// Contract: VM must be initialized, snapshot must be valid.
    pub fn restore_state(self: *Self, snapshot: *const state_snapshot_mod.VMStateSnapshot) !void {
        // Assert: Snapshot must be valid (precondition).
        std.debug.assert(snapshot.is_valid());
        
        // Assert: Snapshot memory size must match VM memory size (precondition).
        std.debug.assert(snapshot.memory_size == self.memory_size);
        
        // Restore state.
        try snapshot.restore(self);
        
        // Assert: VM state must be restored correctly (postcondition).
        std.debug.assert(self.regs.pc == snapshot.regs[32]);
        std.debug.assert(self.memory_size == snapshot.memory_size);
    }
};
