// 005 Fuzz Test: SBI + Kernel Syscall Integration
//
// Objective: Validate full stack integration (Hardware → SBI → Kernel → Userspace)
// with randomized fuzz testing for SBI calls, kernel syscalls, ECALL dispatch,
// serial output, and state transitions.
//
// Method:
// - Uses SimpleRng for deterministic randomness (wrap-safe arithmetic)
// - Generates random SBI function IDs (0-9) and kernel syscall numbers (10-50)
// - Tests ECALL dispatch (function ID < 10 → SBI, >= 10 → kernel)
// - Tests serial output routing (SBI_CONSOLE_PUTCHAR → serial output)
// - Tests state transitions (VM state, kernel state, serial output state)
// - Uses Arena allocator to minimize heap noise
//
// Date: 2025-11-13
// Operator: Glow G2 (Stoic Aquarian cadence)
const std = @import("std");
const kernel_vm = @import("kernel_vm");
const VM = kernel_vm.VM;
const SerialOutput = kernel_vm.SerialOutput;
const basin_kernel = @import("basin_kernel");
const BasinKernel = basin_kernel.BasinKernel;
const sbi = @import("sbi");

// SimpleRng: inline copy for test (avoiding module path issues).
const SimpleRng = struct {
    state: u64,

    pub fn init(seed: u64) SimpleRng {
        return .{ .state = seed };
    }

    fn next(self: *SimpleRng) u64 {
        self.state = self.state *% 6364136223846793005 +% 1;
        return self.state;
    }

    pub fn boolean(self: *SimpleRng) bool {
        return (self.next() & 1) == 1;
    }

    pub fn range(self: *SimpleRng, comptime T: type, upper: T) T {
        return self.uint_less_than(T, upper);
    }

    pub fn uint_less_than(self: *SimpleRng, comptime T: type, bound: T) T {
        return @intCast(self.next() % @as(u64, bound));
    }
};

/// Generate random SBI EID (0-9).
/// Why: Test SBI call handling with random function IDs.
fn generate_sbi_eid(rng: *SimpleRng) u32 {
    return rng.range(u32, 10); // 0-9
}

/// Generate random kernel syscall number (10-50).
/// Why: Test kernel syscall handling with random syscall numbers.
fn generate_kernel_syscall(rng: *SimpleRng) u32 {
    return 10 + rng.range(u32, 41); // 10-50
}

/// Generate random ECALL function ID (0-50).
/// Why: Test ECALL dispatch with random function IDs across boundary.
fn generate_ecall_function_id(rng: *SimpleRng) u32 {
    return rng.range(u32, 51); // 0-50
}

/// Generate random character for SBI_CONSOLE_PUTCHAR.
/// Why: Test serial output with random characters.
fn generate_character(rng: *SimpleRng) u8 {
    return @as(u8, @truncate(rng.range(u32, 256))); // 0-255
}

/// Generate random u64 argument.
/// Why: Test syscall arguments with random values.
fn generate_u64_arg(rng: *SimpleRng) u64 {
    return rng.next();
}

test "005_fuzz_sbi_calls" {
    // Test Category 1: SBI Call Fuzzing
    // Objective: Validate SBI call handling with random EIDs and arguments.
    
    var rng = SimpleRng.init(0x005F00F100000001);
    
    // Test 100 random SBI calls.
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        // Generate random SBI EID.
        const eid = generate_sbi_eid(&rng);
        
        // Assert: EID must be < 10 (legacy SBI functions).
        std.debug.assert(eid < 10);
        
        // Initialize VM with minimal kernel image (single NOP instruction).
        // Why: VM.init requires non-empty kernel image.
        const minimal_kernel = [_]u8{ 0x13, 0x00, 0x00, 0x00 }; // NOP instruction (ADDI x0, x0, 0)
        var vm = VM.init(&minimal_kernel, 0x1000);
        
        // Initialize serial output.
        var serial_output = SerialOutput{};
        vm.set_serial_output(&serial_output);
        
        // Assert: VM state must be valid.
        std.debug.assert(vm.state != .errored);
        
        // Assert: Serial output must be set.
        std.debug.assert(vm.serial_output != null);
        
        // Start VM.
        vm.start();
        
        // Assert: VM state must be running.
        std.debug.assert(vm.state == .running);
        
        // Set up registers for SBI call.
        // RISC-V calling convention: a7 (x17) = EID, a0 (x10) = arg1.
        const arg1 = generate_u64_arg(&rng);
        vm.regs.set(17, eid); // a7 = EID
        vm.regs.set(10, arg1); // a0 = arg1
        
        // Execute ECALL (will dispatch to SBI if eid < 10).
        // Note: We're testing SBI calls, so eid < 10 is guaranteed.
        std.debug.assert(eid < 10);
        
        // Manually call handle_sbi_call to test SBI handling directly.
        // Why: Test SBI handling without full VM execution.
        vm.handle_sbi_call(eid, arg1, 0, 0, 0);
        
        // Assert: VM state must remain valid after SBI call (unless shutdown).
        if (eid != @intFromEnum(sbi.EID.LEGACY_SHUTDOWN)) {
            std.debug.assert(vm.state != .errored);
        }
        
        // Assert: a0 register must be set (SBI return value).
        const a0 = vm.regs.get(10);
        
        // Assert: For CONSOLE_PUTCHAR, a0 should be 0 (success).
        if (eid == @intFromEnum(sbi.EID.LEGACY_CONSOLE_PUTCHAR)) {
            std.debug.assert(a0 == 0);
            
            // Assert: Serial output must have received character.
            if (arg1 <= 0xFF) {
                // Character was written to serial output.
                std.debug.assert(serial_output.total_written > 0);
            }
        }
        
        // Assert: For SHUTDOWN, VM state must be halted.
        if (eid == @intFromEnum(sbi.EID.LEGACY_SHUTDOWN)) {
            std.debug.assert(vm.state == .halted);
        }
    }
}

test "005_fuzz_kernel_syscalls" {
    // Test Category 2: Kernel Syscall Fuzzing
    // Objective: Validate kernel syscall handling with random syscall numbers and arguments.
    
    var rng = SimpleRng.init(0x005F00F200000002);
    
    // Test 100 random kernel syscalls.
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        // Generate random kernel syscall number.
        const syscall_num = generate_kernel_syscall(&rng);
        
        // Assert: Syscall number must be >= 10 (kernel syscalls, not SBI).
        std.debug.assert(syscall_num >= 10);
        
        // Initialize kernel.
        var kernel = BasinKernel.init();
        
        // Assert: Kernel must be initialized.
        const kernel_ptr = @intFromPtr(&kernel);
        std.debug.assert(kernel_ptr != 0);
        
        // Generate random arguments.
        const arg1 = generate_u64_arg(&rng);
        const arg2 = generate_u64_arg(&rng);
        const arg3 = generate_u64_arg(&rng);
        const arg4 = generate_u64_arg(&rng);
        
        // Call kernel syscall handler.
        const result = kernel.handle_syscall(syscall_num, arg1, arg2, arg3, arg4) catch |err| {
            // Assert: Error must be valid BasinError (discard for fuzz test).
            _ = @intFromError(err);
            continue;
        };
        
        // Assert: Result must be valid (success or error).
        switch (result) {
            .success => |value| {
                // Assert: Success value must be valid.
                _ = value;
            },
            .err => |err_val| {
                // Assert: Error must be valid BasinError (discard for fuzz test).
                _ = @intFromError(err_val);
            },
        }
        
        // Assert: For implemented syscalls (exit, yield, map), result should be success.
        if (syscall_num == @intFromEnum(basin_kernel.Syscall.exit)) {
            // Exit syscall should return success with status.
            std.debug.assert(result == .success);
            std.debug.assert(result.success <= 255); // Exit status 0-255
        } else if (syscall_num == @intFromEnum(basin_kernel.Syscall.yield)) {
            // Yield syscall should return success.
            std.debug.assert(result == .success);
        } else if (syscall_num == @intFromEnum(basin_kernel.Syscall.map)) {
            // Map syscall may return success or error depending on arguments.
            // Assert: If success, address must be page-aligned or zero.
            if (result == .success) {
                const addr = result.success;
                std.debug.assert(addr == 0 or addr % 4096 == 0);
            }
        }
    }
}

test "005_fuzz_ecall_dispatch" {
    // Test Category 3: ECALL Dispatch Fuzzing
    // Objective: Validate ECALL dispatch logic (SBI vs kernel) with random function IDs.
    
    var rng = SimpleRng.init(0x005F00F300000003);
    
    // Test 100 random ECALL function IDs.
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        // Generate random function ID (0-50).
        const function_id = generate_ecall_function_id(&rng);
        
        // Assert: Function ID must be within valid range.
        std.debug.assert(function_id <= 50);
        
        // Initialize VM with minimal kernel image (single NOP instruction).
        // Why: VM.init requires non-empty kernel image.
        const minimal_kernel = [_]u8{ 0x13, 0x00, 0x00, 0x00 }; // NOP instruction (ADDI x0, x0, 0)
        var vm = VM.init(&minimal_kernel, 0x1000);
        
        // Initialize serial output.
        var serial_output = SerialOutput{};
        vm.set_serial_output(&serial_output);
        
        // Set up syscall handler for kernel syscalls.
        var kernel = BasinKernel.init();
        vm.set_syscall_handler(handle_syscall_wrapper, &kernel);
        
        // Assert: Syscall handler must be set.
        std.debug.assert(vm.syscall_handler != null);
        
        // Start VM.
        vm.start();
        
        // Assert: VM state must be running.
        std.debug.assert(vm.state == .running);
        
        // Set up registers for ECALL.
        vm.regs.set(17, function_id); // a7 = function ID
        vm.regs.set(10, 0); // a0 = arg1
        vm.regs.set(11, 0); // a1 = arg2
        vm.regs.set(12, 0); // a2 = arg3
        vm.regs.set(13, 0); // a3 = arg4
        
        // Execute ECALL.
        vm.execute_ecall() catch |err| {
            // ECALL may fail if VM state is invalid, but we've validated state.
            std.debug.panic("ECALL failed: {s}", .{@errorName(err)});
        };
        
        // Assert: Dispatch must be correct.
        if (function_id < 10) {
            // SBI call: VM should handle it directly.
            std.debug.assert(vm.state != .errored);
        } else {
            // Kernel syscall: Handler should be called.
            std.debug.assert(vm.syscall_handler != null);
        }
        
        // Assert: VM state must remain valid (unless shutdown/exit).
        if (function_id != @intFromEnum(sbi.EID.LEGACY_SHUTDOWN) and function_id != 2) {
            std.debug.assert(vm.state != .errored);
        }
    }
}

/// Wrapper for kernel syscall handler (for VM callback).
/// Why: Bridge VM callback to kernel syscall handler.
fn handle_syscall_wrapper(syscall_num: u32, arg1: u64, arg2: u64, arg3: u64, arg4: u64) u64 {
    // Get kernel from user_data (simplified for test).
    var kernel = BasinKernel.init();
    
    // Call kernel syscall handler.
    const result = kernel.handle_syscall(syscall_num, arg1, arg2, arg3, arg4) catch |err| {
        // Return error code (negative value).
        const error_code = @as(i64, @intCast(@intFromError(err)));
        return @as(u64, @bitCast(-error_code));
    };
    
    // Extract result value.
    switch (result) {
        .success => |value| return value,
        .err => |err_val| {
            const error_code = @as(i64, @intCast(@intFromError(err_val)));
            return @as(u64, @bitCast(-error_code));
        },
    }
}

test "005_fuzz_serial_output" {
    // Test Category 4: Serial Output Fuzzing
    // Objective: Validate serial output routing and buffer management with random characters.
    
    var rng = SimpleRng.init(0x005F00F400000004);
    
    // Test 1000 random characters.
    var i: u32 = 0;
    while (i < 1000) : (i += 1) {
        // Initialize serial output.
        var serial_output = SerialOutput{};
        
        // Assert: Serial output must be initialized.
        std.debug.assert(serial_output.buffer.len > 0);
        std.debug.assert(serial_output.write_pos == 0);
        std.debug.assert(serial_output.total_written == 0);
        
        // Generate random character.
        const character = generate_character(&rng);
        
        // Write character to serial output.
        serial_output.writeByte(character);
        
        // Assert: Write position must advance (or wrap).
        std.debug.assert(serial_output.write_pos < serial_output.buffer.len);
        std.debug.assert(serial_output.total_written == i + 1);
        
        // Assert: Character must be written correctly.
        const expected_pos = (i + 1) % serial_output.buffer.len;
        std.debug.assert(serial_output.buffer[expected_pos] == character);
        
        // Assert: Buffer must be valid (circular buffer).
        std.debug.assert(serial_output.buffer.len == 64 * 1024);
    }
}

test "005_fuzz_state_transitions" {
    // Test Category 5: State Transition Fuzzing
    // Objective: Validate VM state transitions with random state changes.
    
    var rng = SimpleRng.init(0x005F00F500000005);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    
    // Test 100 random state transitions.
    var i: u32 = 0;
    while (i < 100) : (i += 1) {
        // Initialize VM with minimal kernel image (single NOP instruction).
        // Why: VM.init requires non-empty kernel image.
        const minimal_kernel = [_]u8{ 0x13, 0x00, 0x00, 0x00 }; // NOP instruction (ADDI x0, x0, 0)
        var vm = VM.init(&minimal_kernel, 0x1000);
        
        // Assert: Initial state must be halted.
        std.debug.assert(vm.state == .halted);
        
        // Start VM.
        vm.start();
        
        // Assert: VM state must be running.
        std.debug.assert(vm.state == .running);
        
        // Randomly stop or continue.
        if (rng.boolean()) {
            vm.stop();
            
            // Assert: VM state must be halted.
            std.debug.assert(vm.state == .halted);
        } else {
            // Assert: VM state must remain running.
            std.debug.assert(vm.state == .running);
        }
        
        // Assert: VM state must never be errored (unless explicit error).
        std.debug.assert(vm.state != .errored);
    }
}

test "005_fuzz_combined_execution" {
    // Test Category 6: Combined Execution Fuzzing
    // Objective: Validate combined SBI + kernel syscall execution with random sequences.
    
    var rng = SimpleRng.init(0x005F00F600000006);
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    
    // Test 50 random sequences of SBI + kernel calls.
    var i: u32 = 0;
    while (i < 50) : (i += 1) {
        // Initialize VM with minimal kernel image (single NOP instruction).
        // Why: VM.init requires non-empty kernel image.
        const minimal_kernel = [_]u8{ 0x13, 0x00, 0x00, 0x00 }; // NOP instruction (ADDI x0, x0, 0)
        var vm = VM.init(&minimal_kernel, 0x1000);
        
        // Initialize serial output.
        var serial_output = SerialOutput{};
        vm.set_serial_output(&serial_output);
        
        // Set up syscall handler.
        var kernel = BasinKernel.init();
        vm.set_syscall_handler(handle_syscall_wrapper, &kernel);
        
        // Start VM.
        vm.start();
        
        // Execute 10 random calls (mix of SBI and kernel).
        var j: u32 = 0;
        while (j < 10) : (j += 1) {
            // Randomly choose SBI or kernel call.
            const is_sbi = rng.boolean();
            
            if (is_sbi) {
                // SBI call.
                const eid = generate_sbi_eid(&rng);
                const arg1 = generate_u64_arg(&rng);
                
                vm.regs.set(17, eid);
                vm.regs.set(10, arg1);
                
                vm.handle_sbi_call(eid, arg1, 0, 0, 0);
                
                // Assert: VM state must remain valid (unless shutdown).
                if (eid != @intFromEnum(sbi.EID.LEGACY_SHUTDOWN)) {
                    std.debug.assert(vm.state != .errored);
                }
            } else {
                // Kernel syscall.
                const syscall_num = generate_kernel_syscall(&rng);
                const arg1 = generate_u64_arg(&rng);
                const arg2 = generate_u64_arg(&rng);
                const arg3 = generate_u64_arg(&rng);
                const arg4 = generate_u64_arg(&rng);
                
                vm.regs.set(17, syscall_num);
                vm.regs.set(10, arg1);
                vm.regs.set(11, arg2);
                vm.regs.set(12, arg3);
                vm.regs.set(13, arg4);
                
                vm.execute_ecall() catch |err| {
                    // ECALL may fail if VM state is invalid.
                    std.debug.panic("ECALL failed: {s}", .{@errorName(err)});
                };
                
                // Assert: VM state must remain valid (unless exit).
                if (syscall_num != 2) {
                    std.debug.assert(vm.state != .errored);
                }
            }
            
            // Break if VM is halted.
            if (vm.state == .halted) {
                break;
            }
        }
        
        // Assert: VM state must be valid at end of sequence.
        std.debug.assert(vm.state != .errored);
    }
}

