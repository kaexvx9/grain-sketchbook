//! Tests for x86_64 JIT instruction translation.
//! Why: Verify RISC-V → x86_64 instruction translation correctness.

const std = @import("std");
const testing = std.testing;
const vm_mod = @import("src/kernel_vm/vm.zig");
const VM = vm_mod.VM;
const builtin = @import("builtin");

test "x86_64 JIT R-type instruction translation" {
    // x86_64 JIT only available on x86_64 hosts.
    if (builtin.cpu.arch != .x86_64) {
        return;
    }
    
    const allocator = testing.allocator;
    
    // Simple R-type program: ADD x1, x2, x3
    const program = [_]u8{
        0x33, 0x81, 0x31, 0x00, // ADD x1, x2, x3 (R-type)
    };
    
    var vm: VM = undefined;
    try vm.init_with_jit(allocator, &program, 0x80000000);
    defer vm.deinit_jit(allocator);
    
    vm.state = .running;
    
    // Set up registers: x2 = 10, x3 = 20
    vm.regs.set(2, 10);
    vm.regs.set(3, 20);
    
    // Execute with JIT.
    try vm.step_jit();
    
    // Verify result: x1 should be 30 (10 + 20).
    try testing.expect(vm.regs.get(1) == 30);
}

test "x86_64 JIT I-type instruction translation" {
    // x86_64 JIT only available on x86_64 hosts.
    if (builtin.cpu.arch != .x86_64) {
        return;
    }
    
    const allocator = testing.allocator;
    
    // Simple I-type program: ADDI x1, x0, 42
    const program = [_]u8{
        0x93, 0x00, 0xA0, 0x02, // ADDI x1, x0, 42
    };
    
    var vm: VM = undefined;
    try vm.init_with_jit(allocator, &program, 0x80000000);
    defer vm.deinit_jit(allocator);
    
    vm.state = .running;
    
    // Execute with JIT.
    try vm.step_jit();
    
    // Verify result: x1 should be 42.
    try testing.expect(vm.regs.get(1) == 42);
}

test "x86_64 JIT branch instruction translation" {
    // x86_64 JIT only available on x86_64 hosts.
    if (builtin.cpu.arch != .x86_64) {
        return;
    }
    
    const allocator = testing.allocator;
    
    // Branch program: BEQ x1, x2, target (if equal, jump forward)
    // x1 = 10, x2 = 10 (equal, should branch)
    const program = [_]u8{
        0x63, 0x02, 0x10, 0x00, // BEQ x1, x2, +8 (forward branch)
        0x93, 0x00, 0x10, 0x00, // ADDI x1, x0, 1 (should be skipped)
        0x93, 0x00, 0x20, 0x00, // ADDI x2, x0, 2 (target)
    };
    
    var vm: VM = undefined;
    try vm.init_with_jit(allocator, &program, 0x80000000);
    defer vm.deinit_jit(allocator);
    
    vm.state = .running;
    
    // Set up registers: x1 = 10, x2 = 10 (equal).
    vm.regs.set(1, 10);
    vm.regs.set(2, 10);
    
    // Execute with JIT.
    try vm.step_jit();
    
    // Verify PC jumped to target (skipped ADDI x1, x0, 1).
    // PC should be at target instruction (0x80000008).
    try testing.expect(vm.regs.pc == 0x80000008);
}

test "x86_64 JIT ECALL fallback to interpreter" {
    // x86_64 JIT only available on x86_64 hosts.
    if (builtin.cpu.arch != .x86_64) {
        return;
    }
    
    const allocator = testing.allocator;
    
    // Program with ECALL: should fall back to interpreter.
    const program = [_]u8{
        0x73, 0x00, 0x00, 0x00, // ECALL
    };
    
    var vm: VM = undefined;
    try vm.init_with_jit(allocator, &program, 0x80000000);
    defer vm.deinit_jit(allocator);
    
    vm.state = .running;
    
    // Execute with JIT (ECALL should fall back to interpreter).
    try vm.step_jit();
    
    // Verify interpreter fallback was tracked.
    if (vm.jit) |jit_ctx| {
        // Should have at least one interpreter fallback.
        try testing.expect(jit_ctx.perf_counters.interpreter_fallbacks > 0);
    }
}

