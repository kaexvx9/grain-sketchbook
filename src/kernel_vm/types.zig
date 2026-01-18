//! Vantage VM Type Definitions
//! Why: Shared types for VM components (execute, decode, memory).
//! Grain Style: Explicit types (u32/u64), no usize.

const std = @import("std");

/// VM execution state.
/// Why: Track VM lifecycle (halted, running, errored).
pub const VMState = enum {
    halted,
    running,
    errored,
};

/// VM error types.
/// Why: Explicit error enumeration for all VM failure modes.
pub const VMError = error{
    invalid_instruction,
    invalid_memory_access,
    invalid_register,
    stack_overflow,
    stack_underflow,
    division_by_zero,
    halted,
    breakpoint,
    unimplemented,
    page_fault,
    access_fault,
    misaligned_access,
};

/// Decoded instruction fields.
/// Why: Pre-decoded instruction for efficient execution.
/// Grain Style: Explicit field sizes matching RISC-V spec.
pub const DecodedInst = struct {
    opcode: u7,
    rd: u5,
    rs1: u5,
    rs2: u5,
    funct3: u3,
    funct7: u7,
    imm: i32,
    
    /// Decode R-type instruction.
    pub fn decode_r(inst: u32) DecodedInst {
        return .{
            .opcode = @truncate(inst),
            .rd = @truncate(inst >> 7),
            .rs1 = @truncate(inst >> 15),
            .rs2 = @truncate(inst >> 20),
            .funct3 = @truncate(inst >> 12),
            .funct7 = @truncate(inst >> 25),
            .imm = 0,
        };
    }
    
    /// Decode I-type instruction.
    pub fn decode_i(inst: u32) DecodedInst {
        const imm12 = @as(i32, @bitCast(inst)) >> 20;
        return .{
            .opcode = @truncate(inst),
            .rd = @truncate(inst >> 7),
            .rs1 = @truncate(inst >> 15),
            .rs2 = 0,
            .funct3 = @truncate(inst >> 12),
            .funct7 = 0,
            .imm = imm12,
        };
    }
    
    /// Decode S-type instruction.
    pub fn decode_s(inst: u32) DecodedInst {
        const imm_11_5 = @as(u7, @truncate(inst >> 25));
        const imm_4_0 = @as(u5, @truncate(inst >> 7));
        const imm12_raw = (@as(u12, imm_11_5) << 5) | imm_4_0;
        const imm = @as(i32, @as(i12, @bitCast(imm12_raw)));
        return .{
            .opcode = @truncate(inst),
            .rd = 0,
            .rs1 = @truncate(inst >> 15),
            .rs2 = @truncate(inst >> 20),
            .funct3 = @truncate(inst >> 12),
            .funct7 = 0,
            .imm = imm,
        };
    }
    
    /// Decode B-type instruction.
    pub fn decode_b(inst: u32) DecodedInst {
        const imm_12 = @as(u1, @truncate(inst >> 31));
        const imm_10_5 = @as(u6, @truncate(inst >> 25));
        const imm_4_1 = @as(u4, @truncate(inst >> 8));
        const imm_11 = @as(u1, @truncate(inst >> 7));
        const imm13_raw = (@as(u13, imm_12) << 12) | (@as(u13, imm_11) << 11) |
            (@as(u13, imm_10_5) << 5) | (@as(u13, imm_4_1) << 1);
        const imm = @as(i32, @as(i13, @bitCast(imm13_raw)));
        return .{
            .opcode = @truncate(inst),
            .rd = 0,
            .rs1 = @truncate(inst >> 15),
            .rs2 = @truncate(inst >> 20),
            .funct3 = @truncate(inst >> 12),
            .funct7 = 0,
            .imm = imm,
        };
    }
    
    /// Decode U-type instruction (LUI, AUIPC).
    pub fn decode_u(inst: u32) DecodedInst {
        const imm20 = @as(i32, @bitCast(inst & 0xFFFFF000));
        return .{
            .opcode = @truncate(inst),
            .rd = @truncate(inst >> 7),
            .rs1 = 0,
            .rs2 = 0,
            .funct3 = 0,
            .funct7 = 0,
            .imm = imm20,
        };
    }
    
    /// Decode J-type instruction (JAL).
    pub fn decode_j(inst: u32) DecodedInst {
        const imm_20 = @as(u1, @truncate(inst >> 31));
        const imm_10_1 = @as(u10, @truncate(inst >> 21));
        const imm_11 = @as(u1, @truncate(inst >> 20));
        const imm_19_12 = @as(u8, @truncate(inst >> 12));
        const imm21_raw = (@as(u21, imm_20) << 20) | (@as(u21, imm_19_12) << 12) |
            (@as(u21, imm_11) << 11) | (@as(u21, imm_10_1) << 1);
        const imm = @as(i32, @as(i21, @bitCast(imm21_raw)));
        return .{
            .opcode = @truncate(inst),
            .rd = @truncate(inst >> 7),
            .rs1 = 0,
            .rs2 = 0,
            .funct3 = 0,
            .funct7 = 0,
            .imm = imm,
        };
    }
};

/// RISC-V opcodes.
/// Why: Named constants for instruction dispatch.
pub const Opcode = struct {
    pub const LUI: u7 = 0b0110111;
    pub const AUIPC: u7 = 0b0010111;
    pub const JAL: u7 = 0b1101111;
    pub const JALR: u7 = 0b1100111;
    pub const BRANCH: u7 = 0b1100011;
    pub const LOAD: u7 = 0b0000011;
    pub const STORE: u7 = 0b0100011;
    pub const OP_IMM: u7 = 0b0010011;
    pub const OP: u7 = 0b0110011;
    pub const OP_IMM_32: u7 = 0b0011011;
    pub const OP_32: u7 = 0b0111011;
    pub const SYSTEM: u7 = 0b1110011;
    pub const FENCE: u7 = 0b0001111;
};

/// Check if instruction is compressed (16-bit RVC).
/// Why: RVC instructions have low 2 bits != 0b11.
pub fn is_compressed(inst: u32) bool {
    return (inst & 0b11) != 0b11;
}

/// Get instruction size in bytes.
/// Why: RVC = 2 bytes, standard = 4 bytes.
pub fn instruction_size(inst: u32) u64 {
    return if (is_compressed(inst)) 2 else 4;
}
