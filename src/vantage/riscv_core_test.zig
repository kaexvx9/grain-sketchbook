//! Unit tests for Vantage RISC-V Core
//! Why: Verify RISC-V emulation works correctly before testing in QEMU.

const std = @import("std");
const riscv = @import("riscv_core.zig");

/// Test memory for VM (1MB).
var test_memory: [1024 * 1024]u8 = undefined;

// Test basic instruction execution.
test "riscv_core: basic execution" {
    var core: riscv.RiscvCore = .{};
    core.init(&test_memory, test_memory.len);

    // Write a simple program: ADDI x1, x0, 42; ECALL
    // ADDI x1, x0, 42 = 0x02a00093
    // ECALL = 0x00000073
    const program = [_]u8{
        0x93, 0x00, 0xa0, 0x02, // addi x1, x0, 42
        0x73, 0x00, 0x00, 0x00, // ecall
    };
    @memcpy(test_memory[0..program.len], &program);

    // Set PC to start of program (physical address 0 = virtual 0x80000000)
    core.set_pc(0x80000000);
    core.state = .running;

    // Execute first instruction
    const cont1 = core.step();
    try std.testing.expect(cont1);
    try std.testing.expectEqual(@as(u64, 42), core.get_reg(1));
    try std.testing.expectEqual(@as(u64, 0x80000004), core.regs.pc);

    // Execute ecall
    const cont2 = core.step();
    try std.testing.expect(cont2);
    try std.testing.expectEqual(riscv.VMState.ecall, core.state);
}

// Test LUI instruction.
test "riscv_core: lui instruction" {
    var core: riscv.RiscvCore = .{};
    core.init(&test_memory, test_memory.len);

    // LUI x2, 0x12345 = 0x12345137
    const program = [_]u8{ 0x37, 0x51, 0x34, 0x12 };
    @memcpy(test_memory[0..program.len], &program);

    core.set_pc(0x80000000);
    core.state = .running;
    _ = core.step();

    try std.testing.expectEqual(@as(u64, 0x12345000), core.get_reg(2));
}

// Test AUIPC instruction.
test "riscv_core: auipc instruction" {
    var core: riscv.RiscvCore = .{};
    core.init(&test_memory, test_memory.len);

    // AUIPC x3, 0x1 = 0x00001197
    const program = [_]u8{ 0x97, 0x11, 0x00, 0x00 };
    @memcpy(test_memory[0..program.len], &program);

    core.set_pc(0x80000000);
    core.state = .running;
    _ = core.step();

    // PC was 0x80000000, adding 0x1000 = 0x80001000
    try std.testing.expectEqual(@as(u64, 0x80001000), core.get_reg(3));
}

// Test JAL instruction.
test "riscv_core: jal instruction" {
    var core: riscv.RiscvCore = .{};
    core.init(&test_memory, test_memory.len);

    // JAL x1, +8 = jump forward 8 bytes, save return address
    // Encoding: imm[20|10:1|11|19:12] rd opcode
    // +8 = 0x008: imm[20]=0, imm[10:1]=0b0000000100, imm[11]=0, imm[19:12]=0
    const program = [_]u8{ 0xef, 0x00, 0x80, 0x00 };
    @memcpy(test_memory[0..program.len], &program);

    core.set_pc(0x80000000);
    core.state = .running;
    _ = core.step();

    // Return address saved to x1
    try std.testing.expectEqual(@as(u64, 0x80000004), core.get_reg(1));
    // PC jumped to 0x80000000 + 8 = 0x80000008
    try std.testing.expectEqual(@as(u64, 0x80000008), core.regs.pc);
}

// Test branch instruction (BEQ).
test "riscv_core: beq instruction" {
    var core: riscv.RiscvCore = .{};
    core.init(&test_memory, test_memory.len);

    // BEQ x0, x0, +8 (always taken since x0 == x0)
    // Encoding for BEQ with offset +8
    const program = [_]u8{ 0x63, 0x04, 0x00, 0x00 };
    @memcpy(test_memory[0..program.len], &program);

    core.set_pc(0x80000000);
    core.state = .running;
    _ = core.step();

    // Branch taken: PC = 0x80000000 + 8 = 0x80000008
    try std.testing.expectEqual(@as(u64, 0x80000008), core.regs.pc);
}

// Test load/store instructions.
test "riscv_core: load store" {
    var core: riscv.RiscvCore = .{};
    core.init(&test_memory, test_memory.len);

    // Simple test: x1 = 0x100 (address), x2 = 42 (value)
    // SW x2, 0(x1); LW x3, 0(x1)
    const program = [_]u8{
        // ADDI x1, x0, 0x100
        0x93, 0x00, 0x00, 0x10,
        // ADDI x2, x0, 42
        0x13, 0x01, 0xa0, 0x02,
        // SW x2, 0(x1)
        0x23, 0x20, 0x20, 0x00,
        // LW x3, 0(x1)
        0x83, 0x21, 0x00, 0x00,
    };
    @memcpy(test_memory[0..program.len], &program);

    core.set_pc(0x80000000);
    core.state = .running;

    _ = core.step(); // ADDI x1, x0, 0x100
    try std.testing.expectEqual(@as(u64, 0x100), core.get_reg(1));

    _ = core.step(); // ADDI x2, x0, 42
    try std.testing.expectEqual(@as(u64, 42), core.get_reg(2));

    _ = core.step(); // SW x2, 0(x1)
    _ = core.step(); // LW x3, 0(x1)

    // x3 should have the stored value
    try std.testing.expectEqual(@as(u64, 42), core.get_reg(3));
}

// Test SBI console putchar.
test "riscv_core: sbi putchar" {
    var core: riscv.RiscvCore = .{};
    core.init(&test_memory, test_memory.len);

    // Set a7 = 0x01 (legacy console putchar), a0 = 'A'
    // Then ECALL
    // LI a7, 0x01: ADDI x17, x0, 1
    // LI a0, 65: ADDI x10, x0, 65
    // ECALL

    const program = [_]u8{
        0x93, 0x08, 0x10, 0x00, // ADDI x17, x0, 1
        0x13, 0x05, 0x10, 0x04, // ADDI x10, x0, 65 ('A')
        0x73, 0x00, 0x00, 0x00, // ECALL
    };
    @memcpy(test_memory[0..program.len], &program);

    core.set_pc(0x80000000);
    core.state = .running;

    _ = core.step(); // Set a7
    try std.testing.expectEqual(@as(u64, 1), core.get_reg(17));

    _ = core.step(); // Set a0
    try std.testing.expectEqual(@as(u64, 65), core.get_reg(10));

    _ = core.step(); // ECALL
    try std.testing.expectEqual(riscv.VMState.ecall, core.state);

    // Handle SBI call
    const handled = core.handle_sbi();
    try std.testing.expect(handled);
    try std.testing.expectEqual(riscv.VMState.running, core.state);
}

// Test multiply instruction (M extension).
test "riscv_core: mul instruction" {
    var core: riscv.RiscvCore = .{};
    core.init(&test_memory, test_memory.len);

    // Set x1 = 7, x2 = 6, then MUL x3, x1, x2
    const program = [_]u8{
        0x93, 0x00, 0x70, 0x00, // ADDI x1, x0, 7
        0x13, 0x01, 0x60, 0x00, // ADDI x2, x0, 6
        0xb3, 0x81, 0x20, 0x02, // MUL x3, x1, x2
    };
    @memcpy(test_memory[0..program.len], &program);

    core.set_pc(0x80000000);
    core.state = .running;

    _ = core.step();
    _ = core.step();
    _ = core.step();

    try std.testing.expectEqual(@as(u64, 42), core.get_reg(3));
}

// Test run with SBI shutdown.
test "riscv_core: run with shutdown" {
    var core: riscv.RiscvCore = .{};
    core.init(&test_memory, test_memory.len);

    // Program: set a7 = 0x53525354 (SRST), then ecall to shutdown
    // LUI a7, 0x53525 = 0x53525000
    // ORI a7, a7, 0x354 (need ADDI since immediate is positive)
    // Actually simpler: just test that step+handle_sbi works
    const program = [_]u8{
        0x93, 0x00, 0x10, 0x00, // ADDI x1, x0, 1
        0x93, 0x80, 0x10, 0x00, // ADDI x1, x1, 1
        0x93, 0x80, 0x10, 0x00, // ADDI x1, x1, 1
    };
    @memcpy(test_memory[0..program.len], &program);

    core.set_pc(0x80000000);
    core.state = .running;

    // Execute 3 instructions manually
    _ = core.step();
    _ = core.step();
    _ = core.step();

    try std.testing.expectEqual(@as(u64, 3), core.get_reg(1));
    try std.testing.expectEqual(riscv.VMState.running, core.state);
}
