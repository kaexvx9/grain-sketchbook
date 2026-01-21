//! Vantage RISC-V64 Core - Minimal Freestanding RISC-V Emulator
//! Why: Emulate RISC-V64 on x86_64 host without std dependencies.
//! Grain Style: Explicit types, static allocation, comprehensive assertions.
//!
//! Architecture:
//!   This is a minimal RISC-V64 interpreter for freestanding environments.
//!   It does not depend on std library (except for comptime features).
//!   Memory is provided externally (from Limine memory map).

/// RISC-V64 Register file (32 GP registers + PC).
/// Why: Explicit register representation for RISC-V64 ISA.
pub const RegisterFile = struct {
    /// General-purpose registers (x0-x31).
    /// x0 is hardwired to 0 in RISC-V.
    x: [32]u64 = [_]u64{0} ** 32,
    /// Program counter.
    pc: u64 = 0,
};

/// VM execution state.
pub const VMState = enum(u8) {
    halted = 0,
    running = 1,
    ecall = 2, // Waiting for environment call handling
    ebreak = 3, // Debug breakpoint
    errored = 4,
};

/// VM error codes.
pub const VMError = enum(u8) {
    none = 0,
    invalid_instruction = 1,
    memory_fault = 2,
    misaligned_access = 3,
    illegal_instruction = 4,
};

/// SBI (Supervisor Binary Interface) call results.
/// Why: Handle RISC-V SBI calls for console I/O and system control.
pub const SbiResult = struct {
    error_code: i64 = 0,
    value: u64 = 0,
};

/// Vantage RISC-V64 Core.
/// Why: Minimal emulator for freestanding environments.
/// Note: Memory is provided externally, not embedded in struct.
pub const RiscvCore = struct {
    /// Register file.
    regs: RegisterFile = .{},
    /// Execution state.
    state: VMState = .halted,
    /// Last error.
    last_error: VMError = .none,
    /// External memory pointer (set by host).
    memory: [*]u8 = undefined,
    /// Memory size in bytes.
    memory_size: u64 = 0,
    /// Instruction count (for statistics).
    instructions_executed: u64 = 0,

    /// Framebuffer info (for SBI console output).
    /// Set by host after initialization.
    framebuffer: ?*Framebuffer = null,

    /// Initialize core with external memory.
    /// Why: Memory comes from Limine, not statically allocated.
    pub fn init(self: *RiscvCore, mem: [*]u8, mem_size: u64) void {
        self.regs = .{};
        self.state = .halted;
        self.last_error = .none;
        self.memory = mem;
        self.memory_size = mem_size;
        self.instructions_executed = 0;
        self.framebuffer = null;
    }

    /// Set program counter.
    pub fn set_pc(self: *RiscvCore, pc: u64) void {
        self.regs.pc = pc;
    }

    /// Get register value.
    pub fn get_reg(self: *const RiscvCore, reg: u5) u64 {
        if (reg == 0) return 0; // x0 is always 0
        return self.regs.x[reg];
    }

    /// Set register value.
    pub fn set_reg(self: *RiscvCore, reg: u5, value: u64) void {
        if (reg == 0) return; // x0 is hardwired to 0
        self.regs.x[reg] = value;
    }

    /// Read byte from memory.
    pub fn read_byte(self: *const RiscvCore, addr: u64) ?u8 {
        const phys = translate_address(addr, self.memory_size) orelse return null;
        if (phys >= self.memory_size) return null;
        return self.memory[phys];
    }

    /// Read halfword (16-bit) from memory.
    pub fn read_half(self: *const RiscvCore, addr: u64) ?u16 {
        const phys = translate_address(addr, self.memory_size) orelse return null;
        if (phys + 1 >= self.memory_size) return null;
        const lo: u16 = self.memory[phys];
        const hi: u16 = self.memory[phys + 1];
        return lo | (hi << 8);
    }

    /// Read word (32-bit) from memory.
    pub fn read_word(self: *const RiscvCore, addr: u64) ?u32 {
        const phys = translate_address(addr, self.memory_size) orelse return null;
        if (phys + 3 >= self.memory_size) return null;
        var result: u32 = 0;
        var i: u6 = 0;
        while (i < 4) : (i += 1) {
            result |= @as(u32, self.memory[phys + i]) << @intCast(i * 8);
        }
        return result;
    }

    /// Read doubleword (64-bit) from memory.
    pub fn read_dword(self: *const RiscvCore, addr: u64) ?u64 {
        const phys = translate_address(addr, self.memory_size) orelse return null;
        if (phys + 7 >= self.memory_size) return null;
        var result: u64 = 0;
        var i: u6 = 0;
        while (i < 8) : (i += 1) {
            result |= @as(u64, self.memory[phys + i]) << @intCast(i * 8);
        }
        return result;
    }

    /// Write byte to memory.
    pub fn write_byte(self: *RiscvCore, addr: u64, value: u8) bool {
        const phys = translate_address(addr, self.memory_size) orelse return false;
        if (phys >= self.memory_size) return false;
        self.memory[phys] = value;
        return true;
    }

    /// Write halfword to memory.
    pub fn write_half(self: *RiscvCore, addr: u64, value: u16) bool {
        const phys = translate_address(addr, self.memory_size) orelse return false;
        if (phys + 1 >= self.memory_size) return false;
        self.memory[phys] = @truncate(value);
        self.memory[phys + 1] = @truncate(value >> 8);
        return true;
    }

    /// Write word to memory.
    pub fn write_word(self: *RiscvCore, addr: u64, value: u32) bool {
        const phys = translate_address(addr, self.memory_size) orelse return false;
        if (phys + 3 >= self.memory_size) return false;
        var i: u6 = 0;
        while (i < 4) : (i += 1) {
            self.memory[phys + i] = @truncate(value >> @intCast(i * 8));
        }
        return true;
    }

    /// Write doubleword to memory.
    pub fn write_dword(self: *RiscvCore, addr: u64, value: u64) bool {
        const phys = translate_address(addr, self.memory_size) orelse return false;
        if (phys + 7 >= self.memory_size) return false;
        var i: u6 = 0;
        while (i < 8) : (i += 1) {
            self.memory[phys + i] = @truncate(value >> @intCast(i * 8));
        }
        return true;
    }

    /// Execute one instruction.
    /// Returns: true if execution should continue, false if halted or error.
    pub fn step(self: *RiscvCore) bool {
        if (self.state != .running) return false;

        // Fetch instruction (4 bytes at PC).
        const inst = self.read_word(self.regs.pc) orelse {
            self.state = .errored;
            self.last_error = .memory_fault;
            return false;
        };

        // Decode and execute.
        const opcode: u7 = @truncate(inst);
        var next_pc = self.regs.pc + 4;

        switch (opcode) {
            // LUI (Load Upper Immediate)
            0b0110111 => {
                const rd = extract_rd(inst);
                const imm = @as(i64, @bitCast(@as(u64, inst & 0xFFFFF000)));
                self.set_reg(rd, @bitCast(imm));
            },

            // AUIPC (Add Upper Immediate to PC)
            0b0010111 => {
                const rd = extract_rd(inst);
                const imm = @as(i64, @bitCast(@as(u64, inst & 0xFFFFF000)));
                const result = @as(i64, @bitCast(self.regs.pc)) +% imm;
                self.set_reg(rd, @bitCast(result));
            },

            // JAL (Jump and Link)
            0b1101111 => {
                const rd = extract_rd(inst);
                const imm = decode_j_imm(inst);
                self.set_reg(rd, self.regs.pc + 4);
                next_pc = @bitCast(@as(i64, @bitCast(self.regs.pc)) +% imm);
            },

            // JALR (Jump and Link Register)
            0b1100111 => {
                const rd = extract_rd(inst);
                const rs1 = extract_rs1(inst);
                const imm = decode_i_imm(inst);
                const target = (@as(i64, @bitCast(self.get_reg(rs1))) +% imm) & ~@as(i64, 1);
                self.set_reg(rd, self.regs.pc + 4);
                next_pc = @bitCast(target);
            },

            // Branch instructions
            0b1100011 => {
                const rs1 = extract_rs1(inst);
                const rs2 = extract_rs2(inst);
                const imm = decode_b_imm(inst);
                const funct3: u3 = @truncate(inst >> 12);

                const val1 = self.get_reg(rs1);
                const val2 = self.get_reg(rs2);
                const signed1: i64 = @bitCast(val1);
                const signed2: i64 = @bitCast(val2);

                const take_branch = switch (funct3) {
                    0b000 => val1 == val2, // BEQ
                    0b001 => val1 != val2, // BNE
                    0b100 => signed1 < signed2, // BLT
                    0b101 => signed1 >= signed2, // BGE
                    0b110 => val1 < val2, // BLTU
                    0b111 => val1 >= val2, // BGEU
                    else => false,
                };

                if (take_branch) {
                    next_pc = @bitCast(@as(i64, @bitCast(self.regs.pc)) +% imm);
                }
            },

            // Load instructions
            0b0000011 => {
                const rd = extract_rd(inst);
                const rs1 = extract_rs1(inst);
                const imm = decode_i_imm(inst);
                const funct3: u3 = @truncate(inst >> 12);
                const addr: u64 = @bitCast(@as(i64, @bitCast(self.get_reg(rs1))) +% imm);

                const value: ?u64 = switch (funct3) {
                    0b000 => if (self.read_byte(addr)) |v| @as(u64, @bitCast(@as(i64, @as(i8, @bitCast(v))))) else null, // LB
                    0b001 => if (self.read_half(addr)) |v| @as(u64, @bitCast(@as(i64, @as(i16, @bitCast(v))))) else null, // LH
                    0b010 => if (self.read_word(addr)) |v| @as(u64, @bitCast(@as(i64, @as(i32, @bitCast(v))))) else null, // LW
                    0b011 => self.read_dword(addr), // LD
                    0b100 => if (self.read_byte(addr)) |v| @as(u64, v) else null, // LBU
                    0b101 => if (self.read_half(addr)) |v| @as(u64, v) else null, // LHU
                    0b110 => if (self.read_word(addr)) |v| @as(u64, v) else null, // LWU
                    else => null,
                };

                if (value) |v| {
                    self.set_reg(rd, v);
                } else {
                    self.state = .errored;
                    self.last_error = .memory_fault;
                    return false;
                }
            },

            // Store instructions
            0b0100011 => {
                const rs1 = extract_rs1(inst);
                const rs2 = extract_rs2(inst);
                const imm = decode_s_imm(inst);
                const funct3: u3 = @truncate(inst >> 12);
                const addr: u64 = @bitCast(@as(i64, @bitCast(self.get_reg(rs1))) +% imm);
                const val = self.get_reg(rs2);

                const success = switch (funct3) {
                    0b000 => self.write_byte(addr, @truncate(val)), // SB
                    0b001 => self.write_half(addr, @truncate(val)), // SH
                    0b010 => self.write_word(addr, @truncate(val)), // SW
                    0b011 => self.write_dword(addr, val), // SD
                    else => false,
                };

                if (!success) {
                    self.state = .errored;
                    self.last_error = .memory_fault;
                    return false;
                }
            },

            // Integer Register-Immediate operations
            0b0010011 => {
                const rd = extract_rd(inst);
                const rs1 = extract_rs1(inst);
                const imm = decode_i_imm(inst);
                const funct3: u3 = @truncate(inst >> 12);
                const val = self.get_reg(rs1);
                const sval: i64 = @bitCast(val);

                const result: u64 = switch (funct3) {
                    0b000 => @bitCast(sval +% imm), // ADDI
                    0b010 => if (sval < imm) 1 else 0, // SLTI
                    0b011 => if (val < @as(u64, @bitCast(imm))) 1 else 0, // SLTIU
                    0b100 => val ^ @as(u64, @bitCast(imm)), // XORI
                    0b110 => val | @as(u64, @bitCast(imm)), // ORI
                    0b111 => val & @as(u64, @bitCast(imm)), // ANDI
                    0b001 => val << @truncate(@as(u64, @bitCast(imm)) & 0x3F), // SLLI
                    0b101 => blk: {
                        const shamt: u6 = @truncate(@as(u64, @bitCast(imm)) & 0x3F);
                        const arith = (inst >> 30) & 1 != 0;
                        if (arith) {
                            break :blk @bitCast(sval >> shamt); // SRAI
                        } else {
                            break :blk val >> shamt; // SRLI
                        }
                    },
                };
                self.set_reg(rd, result);
            },

            // Integer Register-Register operations
            0b0110011 => {
                const rd = extract_rd(inst);
                const rs1 = extract_rs1(inst);
                const rs2 = extract_rs2(inst);
                const funct3: u3 = @truncate(inst >> 12);
                const funct7: u7 = @truncate(inst >> 25);
                const val1 = self.get_reg(rs1);
                const val2 = self.get_reg(rs2);
                const sval1: i64 = @bitCast(val1);
                const sval2: i64 = @bitCast(val2);

                const result: u64 = switch (funct7) {
                    0b0000000 => switch (funct3) {
                        0b000 => @bitCast(sval1 +% sval2), // ADD
                        0b001 => val1 << @truncate(val2 & 0x3F), // SLL
                        0b010 => if (sval1 < sval2) 1 else 0, // SLT
                        0b011 => if (val1 < val2) 1 else 0, // SLTU
                        0b100 => val1 ^ val2, // XOR
                        0b101 => val1 >> @truncate(val2 & 0x3F), // SRL
                        0b110 => val1 | val2, // OR
                        0b111 => val1 & val2, // AND
                    },
                    0b0100000 => switch (funct3) {
                        0b000 => @bitCast(sval1 -% sval2), // SUB
                        0b101 => @bitCast(sval1 >> @truncate(val2 & 0x3F)), // SRA
                        else => blk: {
                            self.state = .errored;
                            self.last_error = .invalid_instruction;
                            break :blk 0;
                        },
                    },
                    0b0000001 => blk: { // M extension (multiply/divide)
                        break :blk switch (funct3) {
                            0b000 => @bitCast(sval1 *% sval2), // MUL
                            0b100 => if (sval2 != 0) @bitCast(@divTrunc(sval1, sval2)) else 0xFFFFFFFFFFFFFFFF, // DIV
                            0b101 => if (val2 != 0) val1 / val2 else 0xFFFFFFFFFFFFFFFF, // DIVU
                            0b110 => if (sval2 != 0) @bitCast(@rem(sval1, sval2)) else @bitCast(sval1), // REM
                            0b111 => if (val2 != 0) val1 % val2 else val1, // REMU
                            else => 0,
                        };
                    },
                    else => blk: {
                        self.state = .errored;
                        self.last_error = .invalid_instruction;
                        break :blk 0;
                    },
                };

                if (self.state == .running) {
                    self.set_reg(rd, result);
                }
            },

            // 32-bit Integer Register-Immediate operations (RV64I)
            0b0011011 => {
                const rd = extract_rd(inst);
                const rs1 = extract_rs1(inst);
                const imm = decode_i_imm(inst);
                const funct3: u3 = @truncate(inst >> 12);
                const val: i32 = @truncate(@as(i64, @bitCast(self.get_reg(rs1))));

                const result: i32 = switch (funct3) {
                    0b000 => val +% @as(i32, @truncate(imm)), // ADDIW
                    0b001 => blk: {
                        const shamt: u5 = @truncate(@as(u64, @bitCast(imm)) & 0x1F);
                        const uval: u32 = @bitCast(val);
                        break :blk @as(i32, @bitCast(uval << shamt));
                    }, // SLLIW
                    0b101 => blk: {
                        const shamt: u5 = @truncate(@as(u64, @bitCast(imm)) & 0x1F);
                        const arith = (inst >> 30) & 1 != 0;
                        if (arith) {
                            break :blk val >> shamt; // SRAIW
                        } else {
                            break :blk @as(i32, @bitCast(@as(u32, @bitCast(val)) >> shamt)); // SRLIW
                        }
                    },
                    else => blk: {
                        self.state = .errored;
                        self.last_error = .invalid_instruction;
                        break :blk 0;
                    },
                };

                if (self.state == .running) {
                    self.set_reg(rd, @bitCast(@as(i64, result)));
                }
            },

            // 32-bit Integer Register-Register operations (RV64I)
            0b0111011 => {
                const rd = extract_rd(inst);
                const rs1 = extract_rs1(inst);
                const rs2 = extract_rs2(inst);
                const funct3: u3 = @truncate(inst >> 12);
                const funct7: u7 = @truncate(inst >> 25);
                const val1: i32 = @truncate(@as(i64, @bitCast(self.get_reg(rs1))));
                const val2: i32 = @truncate(@as(i64, @bitCast(self.get_reg(rs2))));
                const uval1: u32 = @bitCast(val1);
                const uval2: u32 = @bitCast(val2);

                const result: i32 = switch (funct7) {
                    0b0000000 => switch (funct3) {
                        0b000 => val1 +% val2, // ADDW
                        0b001 => @bitCast(uval1 << @truncate(uval2 & 0x1F)), // SLLW
                        0b101 => @bitCast(uval1 >> @truncate(uval2 & 0x1F)), // SRLW
                        else => blk: {
                            self.state = .errored;
                            self.last_error = .invalid_instruction;
                            break :blk 0;
                        },
                    },
                    0b0100000 => switch (funct3) {
                        0b000 => val1 -% val2, // SUBW
                        0b101 => val1 >> @truncate(uval2 & 0x1F), // SRAW
                        else => blk: {
                            self.state = .errored;
                            self.last_error = .invalid_instruction;
                            break :blk 0;
                        },
                    },
                    0b0000001 => switch (funct3) { // M extension 32-bit
                        0b000 => val1 *% val2, // MULW
                        0b100 => if (val2 != 0) @divTrunc(val1, val2) else -1, // DIVW
                        0b101 => if (uval2 != 0) @bitCast(uval1 / uval2) else @bitCast(@as(u32, 0xFFFFFFFF)), // DIVUW
                        0b110 => if (val2 != 0) @rem(val1, val2) else val1, // REMW
                        0b111 => if (uval2 != 0) @bitCast(uval1 % uval2) else @bitCast(uval1), // REMUW
                        else => blk: {
                            self.state = .errored;
                            self.last_error = .invalid_instruction;
                            break :blk 0;
                        },
                    },
                    else => blk: {
                        self.state = .errored;
                        self.last_error = .invalid_instruction;
                        break :blk 0;
                    },
                };

                if (self.state == .running) {
                    self.set_reg(rd, @bitCast(@as(i64, result)));
                }
            },

            // SYSTEM (ECALL, EBREAK, CSR)
            0b1110011 => {
                const funct3: u3 = @truncate(inst >> 12);
                if (funct3 == 0) {
                    // ECALL or EBREAK
                    if (inst == 0x00000073) {
                        // ECALL - environment call
                        self.state = .ecall;
                        return true; // Let host handle ecall
                    } else if (inst == 0x00100073) {
                        // EBREAK - breakpoint
                        self.state = .ebreak;
                        return false;
                    }
                }
                // CSR instructions - treat as NOP for now
                // (We don't emulate privileged mode fully)
            },

            // FENCE instructions - treat as NOP
            0b0001111 => {},

            else => {
            self.state = .errored;
            self.last_error = .invalid_instruction;
            return false;
            },
        }

        self.regs.pc = next_pc;
        self.instructions_executed += 1;
        return true;
    }

    /// Handle SBI ecall.
    /// Why: Process RISC-V SBI calls (console, system control).
    /// Returns: true if handled and execution should continue.
    pub fn handle_sbi(self: *RiscvCore) bool {
        if (self.state != .ecall) return false;

        // SBI uses a7 for extension ID, a6 for function ID
        const ext_id = self.get_reg(17); // a7
        const func_id = self.get_reg(16); // a6
        const arg0 = self.get_reg(10); // a0
        _ = func_id;

        var result = SbiResult{};

        switch (ext_id) {
            // Legacy console putchar (extension 0x01)
            0x01 => {
                // Output character to framebuffer
                if (self.framebuffer) |fb| {
                    fb.putchar(@truncate(arg0));
                }
                result.value = 0;
            },

            // Legacy console getchar (extension 0x02)
            0x02 => {
                // No input support yet
                result.value = @bitCast(@as(i64, -1));
            },

            // System reset (extension 0x53525354 = "SRST")
            0x53525354 => {
                self.state = .halted;
                return false;
            },

            // Base extension (extension 0x10)
            0x10 => {
                // Return success for probe, version queries
                result.value = 0;
            },

            else => {
                // Unknown SBI call - return error
                result.error_code = -2; // SBI_ERR_NOT_SUPPORTED
            },
        }

        // Set return values (a0 = error, a1 = value)
        self.set_reg(10, @bitCast(result.error_code));
        self.set_reg(11, result.value);

        // Continue execution
        self.state = .running;
        self.regs.pc += 4;
        return true;
    }

    /// Run until halted or ecall.
    /// Returns: number of instructions executed.
    pub fn run(self: *RiscvCore, max_instructions: u64) u64 {
        self.state = .running;
        var count: u64 = 0;

        while (count < max_instructions) {
            if (!self.step()) break;

            // Handle ecall (SBI)
            if (self.state == .ecall) {
                if (!self.handle_sbi()) break;
            }

            count += 1;
        }

        return count;
    }
};

/// Framebuffer for console output.
/// Why: Simple text console using graphical framebuffer.
pub const Framebuffer = struct {
    /// Pixel buffer (32-bit BGRA).
    pixels: [*]volatile u32,
    /// Width in pixels.
    width: u32,
    /// Height in pixels.
    height: u32,
    /// Pitch (bytes per row).
    pitch: u32,
    /// Current cursor X position (in characters).
    cursor_x: u32 = 0,
    /// Current cursor Y position (in characters).
    cursor_y: u32 = 0,
    /// Character width in pixels.
    char_width: u32 = 8,
    /// Character height in pixels.
    char_height: u32 = 16,

    /// Initialize framebuffer.
    pub fn init(pixels: [*]volatile u32, width: u32, height: u32, pitch: u32) Framebuffer {
        return .{
            .pixels = pixels,
            .width = width,
            .height = height,
            .pitch = pitch,
        };
    }

    /// Put a character at cursor position.
    pub fn putchar(self: *Framebuffer, c: u8) void {
        if (c == '\n') {
            self.cursor_x = 0;
            self.cursor_y += 1;
            if (self.cursor_y >= self.height / self.char_height) {
                self.scroll();
            }
            return;
        }

        if (c == '\r') {
            self.cursor_x = 0;
            return;
        }

        // Draw character (simplified: just a filled rectangle for printable chars)
        if (c >= 32 and c < 127) {
            const x = self.cursor_x * self.char_width;
            const y = self.cursor_y * self.char_height;
            self.draw_char(x, y, c, 0x00e0e0e0);
        }

        self.cursor_x += 1;
        if (self.cursor_x >= self.width / self.char_width) {
            self.cursor_x = 0;
            self.cursor_y += 1;
            if (self.cursor_y >= self.height / self.char_height) {
                self.scroll();
            }
        }
    }

    /// Draw a character at pixel position.
    fn draw_char(self: *Framebuffer, x: u32, y: u32, _: u8, color: u32) void {
        // Simplified: draw a small block for each character
        // A real implementation would use a font bitmap
        var py: u32 = 0;
        while (py < self.char_height - 2) : (py += 1) {
            var px: u32 = 0;
            while (px < self.char_width - 1) : (px += 1) {
                self.put_pixel(x + px, y + py, color);
            }
        }
    }

    /// Put a pixel.
    fn put_pixel(self: *Framebuffer, x: u32, y: u32, color: u32) void {
        if (x >= self.width or y >= self.height) return;
        const offset = y * (self.pitch / 4) + x;
        self.pixels[offset] = color;
    }

    /// Scroll the screen up by one line.
    fn scroll(self: *Framebuffer) void {
        // Move all lines up
        const line_pixels = self.char_height * (self.pitch / 4);
        const total_lines = self.height / self.char_height;
        const pixels_per_line = self.pitch / 4;

        var line: u32 = 0;
        while (line < total_lines - 1) : (line += 1) {
            const dst_y = line * self.char_height;
            const src_y = (line + 1) * self.char_height;

            var row: u32 = 0;
            while (row < self.char_height) : (row += 1) {
                const dst_offset = (dst_y + row) * pixels_per_line;
                const src_offset = (src_y + row) * pixels_per_line;

                var col: u32 = 0;
                while (col < self.width) : (col += 1) {
                    self.pixels[dst_offset + col] = self.pixels[src_offset + col];
                }
            }
        }

        // Clear last line
        const last_y = (total_lines - 1) * self.char_height;
        var row: u32 = 0;
        while (row < self.char_height) : (row += 1) {
            const offset = (last_y + row) * pixels_per_line;
            var col: u32 = 0;
            while (col < self.width) : (col += 1) {
                self.pixels[offset + col] = 0x001a1a2e; // Background color
            }
        }

        self.cursor_y = total_lines - 1;
        _ = line_pixels;
    }
};

// Helper functions for instruction decoding

fn extract_rd(inst: u32) u5 {
    return @truncate(inst >> 7);
}

fn extract_rs1(inst: u32) u5 {
    return @truncate(inst >> 15);
}

fn extract_rs2(inst: u32) u5 {
    return @truncate(inst >> 20);
}

fn decode_i_imm(inst: u32) i64 {
    const imm: i32 = @bitCast(inst & 0xFFF00000);
    return @as(i64, imm >> 20);
}

fn decode_s_imm(inst: u32) i64 {
    const imm11_5: u32 = inst & 0xFE000000;
    const imm4_0: u32 = (inst >> 7) & 0x1F;
    const combined: i32 = @bitCast(imm11_5 | (imm4_0 << 20));
    return @as(i64, combined >> 20);
}

fn decode_b_imm(inst: u32) i64 {
    const imm12: u32 = (inst >> 31) << 12;
    const imm11: u32 = ((inst >> 7) & 1) << 11;
    const imm10_5: u32 = ((inst >> 25) & 0x3F) << 5;
    const imm4_1: u32 = ((inst >> 8) & 0xF) << 1;
    const raw: u32 = imm12 | imm11 | imm10_5 | imm4_1;
    // Sign-extend from bit 12
    const extended: i32 = @bitCast(raw);
    const shifted: i32 = (extended << 19) >> 19;
    return @as(i64, shifted);
}

fn decode_j_imm(inst: u32) i64 {
    const imm20: u32 = (inst >> 31) << 20;
    const imm19_12: u32 = inst & 0x000FF000;
    const imm11: u32 = ((inst >> 20) & 1) << 11;
    const imm10_1: u32 = ((inst >> 21) & 0x3FF) << 1;
    const raw: u32 = imm20 | imm19_12 | imm11 | imm10_1;
    // Sign-extend from bit 20
    const extended: i32 = @bitCast(raw);
    const shifted: i32 = (extended << 11) >> 11;
    return @as(i64, shifted);
}

/// Translate virtual address to physical.
/// Why: RISC-V kernels typically load at 0x80000000.
fn translate_address(addr: u64, mem_size: u64) ?u64 {
    const KERNEL_BASE: u64 = 0x80000000;

    if (addr >= KERNEL_BASE and addr < KERNEL_BASE + mem_size) {
        return addr - KERNEL_BASE;
    }

    if (addr < mem_size) {
        return addr;
    }

    return null;
}
