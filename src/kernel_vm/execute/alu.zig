//! RISC-V ALU Instructions
//! Why: Arithmetic and logic operations (ADD, SUB, AND, OR, XOR, shifts).
//! Grain Style: 64-line function limit, explicit types.

const std = @import("std");
const types = @import("../types.zig");
const DecodedInst = types.DecodedInst;

/// Execute ADD: rd = rs1 + rs2
/// Why: Register-register addition with wrapping semantics.
pub fn execute_add(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_r(inst);
    const rs1_val = regs.get(d.rs1);
    const rs2_val = regs.get(d.rs2);
    const result = rs1_val +% rs2_val;
    regs.set(d.rd, result);
}

/// Execute SUB: rd = rs1 - rs2
/// Why: Register-register subtraction with wrapping semantics.
pub fn execute_sub(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_r(inst);
    const rs1_val = regs.get(d.rs1);
    const rs2_val = regs.get(d.rs2);
    const result = rs1_val -% rs2_val;
    regs.set(d.rd, result);
}

/// Execute AND: rd = rs1 & rs2
/// Why: Bitwise AND for masking and flags.
pub fn execute_and(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_r(inst);
    const rs1_val = regs.get(d.rs1);
    const rs2_val = regs.get(d.rs2);
    const result = rs1_val & rs2_val;
    regs.set(d.rd, result);
}

/// Execute OR: rd = rs1 | rs2
/// Why: Bitwise OR for combining flags.
pub fn execute_or(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_r(inst);
    const rs1_val = regs.get(d.rs1);
    const rs2_val = regs.get(d.rs2);
    const result = rs1_val | rs2_val;
    regs.set(d.rd, result);
}

/// Execute XOR: rd = rs1 ^ rs2
/// Why: Bitwise XOR for toggle and comparison.
pub fn execute_xor(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_r(inst);
    const rs1_val = regs.get(d.rs1);
    const rs2_val = regs.get(d.rs2);
    const result = rs1_val ^ rs2_val;
    regs.set(d.rd, result);
}

/// Execute SLT: rd = (rs1 < rs2) ? 1 : 0 (signed)
/// Why: Signed comparison for conditionals.
pub fn execute_slt(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_r(inst);
    const rs1_signed = @as(i64, @bitCast(regs.get(d.rs1)));
    const rs2_signed = @as(i64, @bitCast(regs.get(d.rs2)));
    const result: u64 = if (rs1_signed < rs2_signed) 1 else 0;
    regs.set(d.rd, result);
}

/// Execute SLTU: rd = (rs1 < rs2) ? 1 : 0 (unsigned)
/// Why: Unsigned comparison for addresses and sizes.
pub fn execute_sltu(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_r(inst);
    const rs1_val = regs.get(d.rs1);
    const rs2_val = regs.get(d.rs2);
    const result: u64 = if (rs1_val < rs2_val) 1 else 0;
    regs.set(d.rd, result);
}

/// Execute SLL: rd = rs1 << (rs2 & 0x3f)
/// Why: Logical left shift (64-bit, mask shift amount).
pub fn execute_sll(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_r(inst);
    const rs1_val = regs.get(d.rs1);
    const shamt = @as(u6, @truncate(regs.get(d.rs2)));
    const result = rs1_val << shamt;
    regs.set(d.rd, result);
}

/// Execute SRL: rd = rs1 >> (rs2 & 0x3f) (logical)
/// Why: Logical right shift (zero-fill).
pub fn execute_srl(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_r(inst);
    const rs1_val = regs.get(d.rs1);
    const shamt = @as(u6, @truncate(regs.get(d.rs2)));
    const result = rs1_val >> shamt;
    regs.set(d.rd, result);
}

/// Execute SRA: rd = rs1 >> (rs2 & 0x3f) (arithmetic)
/// Why: Arithmetic right shift (sign-extend).
pub fn execute_sra(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_r(inst);
    const rs1_signed = @as(i64, @bitCast(regs.get(d.rs1)));
    const shamt = @as(u6, @truncate(regs.get(d.rs2)));
    const result = @as(u64, @bitCast(rs1_signed >> shamt));
    regs.set(d.rd, result);
}

// === Immediate variants ===

/// Execute ADDI: rd = rs1 + imm
/// Why: Add immediate for constant arithmetic.
pub fn execute_addi(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_i(inst);
    const rs1_val = regs.get(d.rs1);
    const imm64 = @as(u64, @bitCast(@as(i64, d.imm)));
    const result = rs1_val +% imm64;
    regs.set(d.rd, result);
}

/// Execute ANDI: rd = rs1 & imm
/// Why: And immediate for masking.
pub fn execute_andi(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_i(inst);
    const rs1_val = regs.get(d.rs1);
    const imm64 = @as(u64, @bitCast(@as(i64, d.imm)));
    const result = rs1_val & imm64;
    regs.set(d.rd, result);
}

/// Execute ORI: rd = rs1 | imm
/// Why: Or immediate for setting bits.
pub fn execute_ori(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_i(inst);
    const rs1_val = regs.get(d.rs1);
    const imm64 = @as(u64, @bitCast(@as(i64, d.imm)));
    const result = rs1_val | imm64;
    regs.set(d.rd, result);
}

/// Execute XORI: rd = rs1 ^ imm
/// Why: Xor immediate for toggling bits.
pub fn execute_xori(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_i(inst);
    const rs1_val = regs.get(d.rs1);
    const imm64 = @as(u64, @bitCast(@as(i64, d.imm)));
    const result = rs1_val ^ imm64;
    regs.set(d.rd, result);
}

/// Execute SLTI: rd = (rs1 < imm) ? 1 : 0 (signed)
/// Why: Signed immediate comparison.
pub fn execute_slti(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_i(inst);
    const rs1_signed = @as(i64, @bitCast(regs.get(d.rs1)));
    const result: u64 = if (rs1_signed < d.imm) 1 else 0;
    regs.set(d.rd, result);
}

/// Execute SLTIU: rd = (rs1 < imm) ? 1 : 0 (unsigned)
/// Why: Unsigned immediate comparison.
pub fn execute_sltiu(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_i(inst);
    const rs1_val = regs.get(d.rs1);
    const imm64 = @as(u64, @bitCast(@as(i64, d.imm)));
    const result: u64 = if (rs1_val < imm64) 1 else 0;
    regs.set(d.rd, result);
}

/// Execute SLLI: rd = rs1 << shamt
/// Why: Shift left immediate.
pub fn execute_slli(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_i(inst);
    const rs1_val = regs.get(d.rs1);
    const shamt = @as(u6, @truncate(@as(u32, @bitCast(d.imm))));
    const result = rs1_val << shamt;
    regs.set(d.rd, result);
}

/// Execute SRLI: rd = rs1 >> shamt (logical)
/// Why: Shift right logical immediate.
pub fn execute_srli(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_i(inst);
    const rs1_val = regs.get(d.rs1);
    const shamt = @as(u6, @truncate(@as(u32, @bitCast(d.imm))));
    const result = rs1_val >> shamt;
    regs.set(d.rd, result);
}

/// Execute SRAI: rd = rs1 >> shamt (arithmetic)
/// Why: Shift right arithmetic immediate.
pub fn execute_srai(regs: anytype, inst: u32) void {
    const d = DecodedInst.decode_i(inst);
    const rs1_signed = @as(i64, @bitCast(regs.get(d.rs1)));
    const shamt = @as(u6, @truncate(@as(u32, @bitCast(d.imm))));
    const result = @as(u64, @bitCast(rs1_signed >> shamt));
    regs.set(d.rd, result);
}
