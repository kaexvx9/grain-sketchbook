# x86_64 JIT Backend Design

**Date**: 2026-01-01-235500-pst  
**Agent**: Vantage 3b VM Runtime (L2 Sub-Agent)  
**Status**: 🆕 **DESIGN PHASE** — x86_64 JIT Backend Architecture  
**Priority**: HIGH (Framework Ubuntu x86 development)

---

## Executive Summary

This document outlines the design for the RISC-V → x86_64 JIT compilation backend, prioritized for Framework Ubuntu x86 development. The x86_64 backend will enable Basin Kernel to run natively on Framework 16 (x86_64 AMD) and legacy Intel x86_64 hardware.

**Key Goals**:
- Enable RISC-V → x86_64 JIT translation
- Support Framework 16 AMD hardware (x86_64 AMD)
- Support legacy Intel x86_64 hardware
- Maintain compatibility with existing ARM64 JIT architecture
- Follow Grain Style principles (safety, performance, joy)

---

## Architecture Overview

### Current ARM64 JIT Architecture

The existing JIT compiler uses:
1. **Instruction Translation**: RISC-V instructions → ARM64 instructions
2. **Emit Functions**: ARM64-specific code generation (`emit_add`, `emit_mov`, etc.)
3. **Architecture Detection**: `builtin.cpu.arch == .aarch64`
4. **Code Buffer**: Executable memory for compiled blocks

### x86_64 JIT Architecture (New)

The x86_64 backend will mirror the ARM64 architecture:
1. **Instruction Translation**: RISC-V instructions → x86_64 instructions
2. **Emit Functions**: x86_64-specific code generation (`emit_add_x86_64`, `emit_mov_x86_64`, etc.)
3. **Architecture Detection**: `builtin.cpu.arch == .x86_64`
4. **Code Buffer**: Same executable memory mechanism (platform-agnostic)

---

## Design Decisions

### 1. Backend Selection Strategy

**Approach**: Architecture-specific backend selection at runtime

**Implementation**:
- Detect host architecture at JIT context initialization
- Select appropriate backend (ARM64 or x86_64)
- Use backend-specific emit functions based on architecture

**Why**: This approach maintains compatibility with existing ARM64 JIT while adding x86_64 support. The architecture detection is straightforward and allows both backends to coexist.

### 2. Register Mapping

**RISC-V → x86_64 Register Mapping**:
- RISC-V x0 (zero) → x86_64 r15 (reserved for zero)
- RISC-V x1-x31 → x86_64 r14, r13, r12, r11, r10, r9, r8, rdi, rsi, rdx, rcx, rbx, rax, rbp, rsp (callee-saved + caller-saved)
- RISC-V PC → x86_64 r15 (separate register for program counter)

**Why**: x86_64 has fewer general-purpose registers than RISC-V (16 vs 32), so we need careful register allocation. We'll use a register allocator to map RISC-V registers to x86_64 registers efficiently.

### 3. Instruction Translation Patterns

**Common Patterns**:
- **ADD**: RISC-V `add rd, rs1, rs2` → x86_64 `add %rsi, %rdi` (with register mapping)
- **LOAD**: RISC-V `lw rd, offset(rs1)` → x86_64 `mov offset(%rdi), %rsi` (with address translation)
- **STORE**: RISC-V `sw rs2, offset(rs1)` → x86_64 `mov %rsi, offset(%rdi)` (with address translation)
- **BRANCH**: RISC-V `beq rs1, rs2, offset` → x86_64 `cmp %rdi, %rsi; je offset` (with offset calculation)

**Why**: These patterns mirror the ARM64 translation approach but use x86_64 instruction encodings. We'll need to handle x86_64's variable-length instructions and addressing modes.

### 4. Memory Model

**Guest Memory Access**:
- RISC-V memory addresses → x86_64 memory addresses (via VM memory buffer)
- Use base pointer + offset addressing for guest memory access
- Maintain memory protection (read-only code, read-write data)

**Why**: The VM memory model is already abstracted, so x86_64 JIT can use the same memory access patterns as ARM64 JIT.

---

## Implementation Plan

### Phase 1: Architecture Detection and Backend Selection

**Tasks**:
1. Add architecture detection to `JitContext` initialization
2. Create backend enum (`Backend.arm64`, `Backend.x86_64`)
3. Select backend based on host architecture
4. Store backend selection in `JitContext`

**Files**:
- `src/kernel_vm/jit.zig` - Add backend selection logic

**Estimated Time**: 1-2 hours

---

### Phase 2: x86_64 Emit Functions

**Tasks**:
1. Create x86_64 emit functions (mirror ARM64 emit functions)
2. Implement x86_64 instruction encoding
3. Add x86_64 register mapping utilities
4. Create x86_64-specific code generation helpers

**Functions to Implement**:
- `emit_add_x86_64()` - ADD instruction
- `emit_mov_x86_64()` - MOV instruction
- `emit_cmp_x86_64()` - CMP instruction
- `emit_jcc_x86_64()` - Conditional jump (JE, JNE, etc.)
- `emit_ldr_x86_64()` - Load from memory
- `emit_str_x86_64()` - Store to memory
- `emit_ret_x86_64()` - Return instruction
- Plus additional x86_64-specific emit functions

**Files**:
- `src/kernel_vm/jit.zig` - Add x86_64 emit functions (conditional compilation)

**Estimated Time**: 1-2 days

---

### Phase 3: x86_64 Instruction Translation

**Tasks**:
1. Create x86_64 translation functions (mirror ARM64 translation)
2. Implement RISC-V → x86_64 instruction mapping
3. Handle x86_64-specific instruction patterns
4. Add x86_64 register allocation

**Translation Functions**:
- `translate_r_type_x86_64()` - R-type instructions (ADD, SUB, etc.)
- `translate_i_type_x86_64()` - I-type instructions (ADDI, etc.)
- `translate_load_x86_64()` - Load instructions
- `translate_store_x86_64()` - Store instructions
- `translate_branch_x86_64()` - Branch instructions
- `translate_jal_x86_64()` - Jump and link
- `translate_jalr_x86_64()` - Jump and link register

**Files**:
- `src/kernel_vm/jit.zig` - Add x86_64 translation functions

**Estimated Time**: 2-3 days

---

### Phase 4: Integration and Testing

**Tasks**:
1. Integrate x86_64 backend into `compile_block()`
2. Add x86_64 architecture detection to backend selection
3. Test x86_64 JIT compilation on Framework x86_64
4. Test x86_64 JIT execution correctness
5. Performance benchmarking on x86_64

**Files**:
- `src/kernel_vm/jit.zig` - Integrate x86_64 backend
- `tests/` - Add x86_64 JIT tests

**Estimated Time**: 2-3 days

---

## Technical Considerations

### x86_64 Instruction Encoding

**Challenge**: x86_64 uses variable-length instructions (1-15 bytes), unlike ARM64's fixed 4-byte instructions.

**Solution**: Use Zig's inline assembly or manual instruction encoding. We'll need to:
- Encode x86_64 instructions byte-by-byte
- Handle instruction prefixes (REX, ModR/M, SIB)
- Calculate instruction lengths for code buffer management

**Why**: This approach gives us full control over instruction encoding and allows us to optimize for code size and performance.

### Register Allocation

**Challenge**: x86_64 has fewer registers than RISC-V (16 vs 32).

**Solution**: Implement a simple register allocator:
- Map frequently used RISC-V registers to x86_64 registers
- Spill less frequently used registers to memory
- Use x86_64's callee-saved registers for RISC-V callee-saved registers

**Why**: A simple allocator is sufficient for initial implementation. We can optimize later if needed.

### Calling Convention

**Challenge**: x86_64 System V ABI differs from ARM64 calling convention.

**Solution**: Maintain compatibility with existing `GuestState` structure:
- Use x86_64 calling convention for JIT function calls
- Map `GuestState` fields to x86_64 registers/stack
- Handle register preservation across JIT function calls

**Why**: The `GuestState` structure is already abstracted, so we can adapt it to x86_64 calling convention.

---

## Testing Strategy

### Unit Tests

**Test Coverage**:
- x86_64 emit functions (instruction encoding correctness)
- x86_64 translation functions (instruction mapping correctness)
- Register mapping (RISC-V → x86_64 register allocation)
- Memory access (guest memory → x86_64 memory access)

**Test Files**:
- `tests/154_x86_64_jit_emit_test.zig` - Emit function tests
- `tests/155_x86_64_jit_translation_test.zig` - Translation function tests
- `tests/156_x86_64_jit_integration_test.zig` - End-to-end JIT tests

### Integration Tests

**Test Coverage**:
- x86_64 JIT compilation on Framework x86_64
- x86_64 JIT execution correctness
- Performance benchmarking (x86_64 vs interpreter)
- Multi-architecture testing (ARM64, x86_64 AMD, x86_64 Intel)

**Test Files**:
- `tests/157_x86_64_jit_framework_test.zig` - Framework x86_64 tests
- `tests/158_x86_64_jit_performance_test.zig` - Performance benchmarks

---

## Coordination Needs

### With Basin Kernel Agent (3a)

**When**: After x86_64 JIT backend implementation
**Need**: Syscall interface documentation
**Purpose**: Ensure JIT can correctly call kernel syscalls on x86_64

### With System Integration Agent (3c)

**When**: After x86_64 JIT backend implementation
**Need**: Multi-architecture testing framework
**Purpose**: Test JIT on Framework x86_64 AMD and legacy Intel x86_64 hardware

### With Vantage 3 Subcore (L1 Parent)

**When**: Before starting implementation
**Need**: Approval for x86_64 JIT backend design
**Purpose**: Confirm architecture and implementation approach

---

## Success Criteria

### Week 1 Success
- ✅ Architecture detection and backend selection implemented
- ✅ x86_64 emit functions implemented (basic set)
- ✅ x86_64 instruction translation started

### Week 2 Success
- ✅ x86_64 instruction translation complete
- ✅ x86_64 JIT compilation working on Framework x86_64
- ✅ Basic correctness tests passing

### Week 3 Success
- ✅ x86_64 JIT execution correctness verified
- ✅ Performance benchmarks completed
- ✅ Integration tests passing on Framework x86_64

### Week 4 Success
- ✅ Legacy Intel x86_64 hardware compatibility verified
- ✅ Multi-architecture testing framework integrated
- ✅ Documentation complete

---

## Risks and Mitigations

### Risk 1: x86_64 Instruction Encoding Complexity

**Mitigation**: Start with simple instructions (ADD, MOV, CMP), then expand to complex instructions. Use existing x86_64 instruction encoding libraries if needed.

### Risk 2: Register Allocation Complexity

**Mitigation**: Start with simple register mapping (1:1 for common registers), then optimize with register allocator if needed.

### Risk 3: Performance on Legacy Hardware

**Mitigation**: Test on legacy Intel x86_64 hardware early. Optimize for older hardware if performance is insufficient.

---

## Next Steps

1. **Get Vantage 3 Subcore approval** for x86_64 JIT backend design
2. **Start Phase 1**: Architecture detection and backend selection
3. **Coordinate with Agent 3a**: Get syscall interface documentation
4. **Coordinate with Agent 3c**: Plan multi-architecture testing

---

**Date**: 2026-01-01-235500-pst  
**Agent**: Vantage 3b VM Runtime (L2 Sub-Agent)  
**Status**: 🆕 **DESIGN PHASE** — x86_64 JIT Backend Architecture Ready for Review

