//! x86_64 Architecture Support for Vantage VM
//! Why: Enable Basin kernel to target x86_64 (Framework laptop) natively.
//! Grain Style: Explicit types (u32/u64), static allocation, comprehensive assertions.

const std = @import("std");

/// x86_64 General-Purpose Registers.
/// Why: Define standard x86_64 register set for kernel code generation.
/// GrainStyle: Explicit enum values, matches AMD64 ABI.
pub const Register = enum(u8) {
    // 64-bit general-purpose registers
    rax = 0, // Accumulator, return value
    rcx = 1, // Counter, 4th argument
    rdx = 2, // Data, 3rd argument
    rbx = 3, // Base (callee-saved)
    rsp = 4, // Stack pointer
    rbp = 5, // Base pointer (callee-saved)
    rsi = 6, // Source, 2nd argument
    rdi = 7, // Destination, 1st argument
    r8 = 8, // 5th argument
    r9 = 9, // 6th argument
    r10 = 10, // Caller-saved
    r11 = 11, // Caller-saved
    r12 = 12, // Callee-saved
    r13 = 13, // Callee-saved
    r14 = 14, // Callee-saved
    r15 = 15, // Callee-saved

    /// Get register name for debugging.
    /// Why: Human-readable register names.
    pub fn name(self: Register) []const u8 {
        return switch (self) {
            .rax => "rax",
            .rcx => "rcx",
            .rdx => "rdx",
            .rbx => "rbx",
            .rsp => "rsp",
            .rbp => "rbp",
            .rsi => "rsi",
            .rdi => "rdi",
            .r8 => "r8",
            .r9 => "r9",
            .r10 => "r10",
            .r11 => "r11",
            .r12 => "r12",
            .r13 => "r13",
            .r14 => "r14",
            .r15 => "r15",
        };
    }

    /// Check if register is callee-saved.
    /// Why: Determine if register must be preserved across function calls.
    pub fn is_callee_saved(self: Register) bool {
        return switch (self) {
            .rbx, .rbp, .r12, .r13, .r14, .r15 => true,
            else => false,
        };
    }

    /// Check if register needs REX.B prefix for encoding.
    /// Why: Registers r8-r15 need REX prefix in x86_64 encoding.
    pub fn needs_rex(self: Register) bool {
        return @intFromEnum(self) >= 8;
    }
};

/// x86_64 Syscall Numbers (Linux).
/// Why: Define syscall numbers for Basin kernel on x86_64 Linux.
/// GrainStyle: Explicit values matching Linux x86_64 ABI.
pub const Syscall = enum(u64) {
    read = 0,
    write = 1,
    open = 2,
    close = 3,
    stat = 4,
    fstat = 5,
    lstat = 6,
    poll = 7,
    lseek = 8,
    mmap = 9,
    mprotect = 10,
    munmap = 11,
    brk = 12,
    ioctl = 16,
    access = 21,
    pipe = 22,
    select = 23,
    sched_yield = 24,
    mremap = 25,
    msync = 26,
    mincore = 27,
    madvise = 28,
    dup = 32,
    dup2 = 33,
    nanosleep = 35,
    getitimer = 36,
    alarm = 37,
    setitimer = 38,
    getpid = 39,
    fork = 57,
    vfork = 58,
    execve = 59,
    exit = 60,
    wait4 = 61,
    kill = 62,
    uname = 63,
    fcntl = 72,
    flock = 73,
    fsync = 74,
    fdatasync = 75,
    truncate = 76,
    ftruncate = 77,
    getcwd = 79,
    chdir = 80,
    rename = 82,
    mkdir = 83,
    rmdir = 84,
    creat = 85,
    link = 86,
    unlink = 87,
    symlink = 88,
    readlink = 89,
    chmod = 90,
    fchmod = 91,
    chown = 92,
    fchown = 93,
    lchown = 94,
    getuid = 102,
    getgid = 104,
    geteuid = 107,
    getegid = 108,
    setpgid = 109,
    getppid = 110,
    getpgrp = 111,
    setsid = 112,
    getgroups = 115,
    setgroups = 116,
    getrlimit = 97,
    getrusage = 98,
    sysinfo = 99,
    times = 100,
    clock_gettime = 228,
    clock_nanosleep = 230,
    exit_group = 231,
};

/// x86_64 Instruction Prefixes.
/// Why: Define instruction prefixes for x86_64 encoding.
/// GrainStyle: Explicit byte values.
pub const Prefix = struct {
    // REX prefixes (0x40-0x4F)
    pub const REX: u8 = 0x40; // Base REX prefix
    pub const REX_W: u8 = 0x48; // REX.W (64-bit operand)
    pub const REX_R: u8 = 0x44; // REX.R (ModRM.reg extension)
    pub const REX_X: u8 = 0x42; // REX.X (SIB.index extension)
    pub const REX_B: u8 = 0x41; // REX.B (ModRM.rm/SIB.base extension)

    // Operand size prefixes
    pub const OPERAND_SIZE: u8 = 0x66; // 16-bit operand
    pub const ADDRESS_SIZE: u8 = 0x67; // 32-bit address

    // Segment override prefixes
    pub const CS: u8 = 0x2E;
    pub const SS: u8 = 0x36;
    pub const DS: u8 = 0x3E;
    pub const ES: u8 = 0x26;
    pub const FS: u8 = 0x64;
    pub const GS: u8 = 0x65;
};

/// x86_64 Opcodes (common instructions).
/// Why: Define opcodes for code generation.
/// GrainStyle: Explicit byte values.
pub const Opcode = struct {
    // Data movement
    pub const MOV_R64_IMM64: u8 = 0xB8; // MOV r64, imm64 (+ reg in low 3 bits)
    pub const MOV_R64_RM64: u8 = 0x8B; // MOV r64, r/m64
    pub const MOV_RM64_R64: u8 = 0x89; // MOV r/m64, r64
    pub const MOV_RM64_IMM32: u8 = 0xC7; // MOV r/m64, imm32 (sign-extended)

    // Arithmetic
    pub const ADD_RM64_R64: u8 = 0x01; // ADD r/m64, r64
    pub const ADD_R64_RM64: u8 = 0x03; // ADD r64, r/m64
    pub const SUB_RM64_R64: u8 = 0x29; // SUB r/m64, r64
    pub const SUB_R64_RM64: u8 = 0x2B; // SUB r64, r/m64
    pub const CMP_RM64_R64: u8 = 0x39; // CMP r/m64, r64
    pub const CMP_R64_RM64: u8 = 0x3B; // CMP r64, r/m64
    pub const AND_RM64_R64: u8 = 0x21; // AND r/m64, r64
    pub const OR_RM64_R64: u8 = 0x09; // OR r/m64, r64
    pub const XOR_RM64_R64: u8 = 0x31; // XOR r/m64, r64

    // Multiplication/Division
    pub const IMUL_R64_RM64: u16 = 0x0FAF; // IMUL r64, r/m64 (2-byte opcode)
    pub const IDIV_RM64: u8 = 0xF7; // IDIV r/m64 (with /7 ModRM)

    // Shifts
    pub const SHL_RM64_CL: u8 = 0xD3; // SHL r/m64, CL (with /4 ModRM)
    pub const SHR_RM64_CL: u8 = 0xD3; // SHR r/m64, CL (with /5 ModRM)
    pub const SAR_RM64_CL: u8 = 0xD3; // SAR r/m64, CL (with /7 ModRM)

    // Control flow
    pub const JMP_REL8: u8 = 0xEB; // JMP rel8
    pub const JMP_REL32: u8 = 0xE9; // JMP rel32
    pub const JMP_RM64: u8 = 0xFF; // JMP r/m64 (with /4 ModRM)
    pub const CALL_REL32: u8 = 0xE8; // CALL rel32
    pub const CALL_RM64: u8 = 0xFF; // CALL r/m64 (with /2 ModRM)
    pub const RET: u8 = 0xC3; // RET
    pub const RET_IMM16: u8 = 0xC2; // RET imm16

    // Conditional jumps (short, rel8)
    pub const JO_REL8: u8 = 0x70; // JO rel8 (overflow)
    pub const JNO_REL8: u8 = 0x71; // JNO rel8 (not overflow)
    pub const JB_REL8: u8 = 0x72; // JB/JNAE/JC rel8 (below/carry)
    pub const JAE_REL8: u8 = 0x73; // JAE/JNB/JNC rel8 (above or equal)
    pub const JE_REL8: u8 = 0x74; // JE/JZ rel8 (equal/zero)
    pub const JNE_REL8: u8 = 0x75; // JNE/JNZ rel8 (not equal/not zero)
    pub const JBE_REL8: u8 = 0x76; // JBE/JNA rel8 (below or equal)
    pub const JA_REL8: u8 = 0x77; // JA/JNBE rel8 (above)
    pub const JS_REL8: u8 = 0x78; // JS rel8 (sign)
    pub const JNS_REL8: u8 = 0x79; // JNS rel8 (not sign)
    pub const JL_REL8: u8 = 0x7C; // JL/JNGE rel8 (less)
    pub const JGE_REL8: u8 = 0x7D; // JGE/JNL rel8 (greater or equal)
    pub const JLE_REL8: u8 = 0x7E; // JLE/JNG rel8 (less or equal)
    pub const JG_REL8: u8 = 0x7F; // JG/JNLE rel8 (greater)

    // Stack operations
    pub const PUSH_R64: u8 = 0x50; // PUSH r64 (+ reg in low 3 bits)
    pub const POP_R64: u8 = 0x58; // POP r64 (+ reg in low 3 bits)

    // System
    pub const SYSCALL: u16 = 0x050F; // SYSCALL (2-byte opcode, little-endian: 0F 05)
    pub const NOP: u8 = 0x90; // NOP
    pub const INT3: u8 = 0xCC; // INT 3 (breakpoint)
    pub const HLT: u8 = 0xF4; // HLT
};

/// x86_64 Register File.
/// Why: Store x86_64 register state for VM execution.
/// GrainStyle: Static allocation, explicit types.
pub const RegisterFile = struct {
    /// General-purpose registers (rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi, r8-r15).
    gpr: [16]u64 = [_]u64{0} ** 16,

    /// Instruction pointer.
    rip: u64 = 0,

    /// Flags register (RFLAGS).
    rflags: u64 = 0x202, // Default: IF=1 (interrupts enabled)

    /// Segment registers (for completeness, typically 0 in long mode).
    cs: u16 = 0,
    ds: u16 = 0,
    es: u16 = 0,
    fs: u16 = 0,
    gs: u16 = 0,
    ss: u16 = 0,

    /// Get register value.
    /// Why: Read register by enum.
    pub fn get(self: *const RegisterFile, reg: Register) u64 {
        return self.gpr[@intFromEnum(reg)];
    }

    /// Set register value.
    /// Why: Write register by enum.
    pub fn set(self: *RegisterFile, reg: Register, value: u64) void {
        self.gpr[@intFromEnum(reg)] = value;
    }

    /// Get register by index.
    /// Why: Read register by numeric index.
    /// Contract: index must be < 16.
    pub fn get_by_index(self: *const RegisterFile, index: u8) u64 {
        std.debug.assert(index < 16);
        return self.gpr[index];
    }

    /// Set register by index.
    /// Why: Write register by numeric index.
    /// Contract: index must be < 16.
    pub fn set_by_index(self: *RegisterFile, index: u8, value: u64) void {
        std.debug.assert(index < 16);
        self.gpr[index] = value;
    }

    /// Reset all registers.
    /// Why: Initialize register file to clean state.
    pub fn reset(self: *RegisterFile) void {
        self.gpr = [_]u64{0} ** 16;
        self.rip = 0;
        self.rflags = 0x202;
        self.cs = 0;
        self.ds = 0;
        self.es = 0;
        self.fs = 0;
        self.gs = 0;
        self.ss = 0;
    }
};

/// RFLAGS bit positions.
/// Why: Define flag bit positions for condition testing.
pub const Flags = struct {
    pub const CF: u64 = 1 << 0; // Carry flag
    pub const PF: u64 = 1 << 2; // Parity flag
    pub const AF: u64 = 1 << 4; // Auxiliary carry flag
    pub const ZF: u64 = 1 << 6; // Zero flag
    pub const SF: u64 = 1 << 7; // Sign flag
    pub const TF: u64 = 1 << 8; // Trap flag
    pub const IF: u64 = 1 << 9; // Interrupt enable flag
    pub const DF: u64 = 1 << 10; // Direction flag
    pub const OF: u64 = 1 << 11; // Overflow flag
    pub const IOPL: u64 = 3 << 12; // I/O privilege level (2 bits)
    pub const NT: u64 = 1 << 14; // Nested task flag
    pub const RF: u64 = 1 << 16; // Resume flag
    pub const VM: u64 = 1 << 17; // Virtual 8086 mode flag
    pub const AC: u64 = 1 << 18; // Alignment check flag
    pub const VIF: u64 = 1 << 19; // Virtual interrupt flag
    pub const VIP: u64 = 1 << 20; // Virtual interrupt pending
    pub const ID: u64 = 1 << 21; // ID flag (CPUID available)
};

/// x86_64 Calling Convention (System V AMD64 ABI).
/// Why: Define register usage for function calls.
/// GrainStyle: Explicit documentation of ABI.
pub const CallingConvention = struct {
    /// Argument registers (in order).
    /// Why: First 6 integer/pointer arguments passed in registers.
    pub const arg_regs: [6]Register = .{
        .rdi, // 1st argument
        .rsi, // 2nd argument
        .rdx, // 3rd argument
        .rcx, // 4th argument
        .r8, // 5th argument
        .r9, // 6th argument
    };

    /// Return value register.
    /// Why: Return value in rax (and rdx for 128-bit values).
    pub const return_reg: Register = .rax;
    pub const return_reg_high: Register = .rdx;

    /// Syscall argument registers (different from function calls).
    /// Why: Syscalls use different register convention.
    pub const syscall_regs: [6]Register = .{
        .rdi, // 1st argument
        .rsi, // 2nd argument
        .rdx, // 3rd argument
        .r10, // 4th argument (not rcx, which is clobbered by syscall)
        .r8, // 5th argument
        .r9, // 6th argument
    };

    /// Syscall number register.
    pub const syscall_num_reg: Register = .rax;

    /// Syscall return register.
    pub const syscall_return_reg: Register = .rax;
};

/// Encode ModRM byte.
/// Why: Build ModRM byte for instruction encoding.
/// Contract: mod must be 0-3, reg and rm must be 0-7.
pub fn encode_modrm(mod: u2, reg: u3, rm: u3) u8 {
    return (@as(u8, mod) << 6) | (@as(u8, reg) << 3) | @as(u8, rm);
}

/// Encode SIB byte.
/// Why: Build SIB byte for memory addressing.
/// Contract: scale must be 0-3, index and base must be 0-7.
pub fn encode_sib(scale: u2, index: u3, base: u3) u8 {
    return (@as(u8, scale) << 6) | (@as(u8, index) << 3) | @as(u8, base);
}

/// Build REX prefix.
/// Why: Build REX prefix for 64-bit operations or extended registers.
pub fn build_rex(w: bool, r: bool, x: bool, b: bool) u8 {
    var rex: u8 = 0x40;
    if (w) rex |= 0x08; // REX.W
    if (r) rex |= 0x04; // REX.R
    if (x) rex |= 0x02; // REX.X
    if (b) rex |= 0x01; // REX.B
    return rex;
}

// Tests.
test "x86_64 register names" {
    const testing = std.testing;

    try testing.expectEqualStrings("rax", Register.rax.name());
    try testing.expectEqualStrings("rsp", Register.rsp.name());
    try testing.expectEqualStrings("r15", Register.r15.name());
}

test "x86_64 register properties" {
    const testing = std.testing;

    // Callee-saved registers
    try testing.expect(Register.rbx.is_callee_saved());
    try testing.expect(Register.rbp.is_callee_saved());
    try testing.expect(Register.r12.is_callee_saved());
    try testing.expect(!Register.rax.is_callee_saved());
    try testing.expect(!Register.rdi.is_callee_saved());

    // REX prefix needed
    try testing.expect(Register.r8.needs_rex());
    try testing.expect(Register.r15.needs_rex());
    try testing.expect(!Register.rax.needs_rex());
    try testing.expect(!Register.rdi.needs_rex());
}

test "x86_64 register file" {
    const testing = std.testing;

    var regs = RegisterFile{};
    regs.set(.rax, 0x123456789ABCDEF0);
    try testing.expectEqual(@as(u64, 0x123456789ABCDEF0), regs.get(.rax));

    regs.set_by_index(7, 0xDEADBEEF);
    try testing.expectEqual(@as(u64, 0xDEADBEEF), regs.get(.rdi));

    regs.reset();
    try testing.expectEqual(@as(u64, 0), regs.get(.rax));
    try testing.expectEqual(@as(u64, 0x202), regs.rflags);
}

test "x86_64 ModRM encoding" {
    const testing = std.testing;

    // MOV RAX, RCX (mod=3, reg=0, rm=1) = 0xC1
    try testing.expectEqual(@as(u8, 0xC1), encode_modrm(3, 0, 1));

    // [RBP] addressing (mod=0, rm=5) needs special handling
    try testing.expectEqual(@as(u8, 0x05), encode_modrm(0, 0, 5));
}

test "x86_64 REX encoding" {
    const testing = std.testing;

    // REX.W (64-bit operand)
    try testing.expectEqual(@as(u8, 0x48), build_rex(true, false, false, false));

    // REX.WB (64-bit + extended rm)
    try testing.expectEqual(@as(u8, 0x49), build_rex(true, false, false, true));

    // REX.WR (64-bit + extended reg)
    try testing.expectEqual(@as(u8, 0x4C), build_rex(true, true, false, false));
}
