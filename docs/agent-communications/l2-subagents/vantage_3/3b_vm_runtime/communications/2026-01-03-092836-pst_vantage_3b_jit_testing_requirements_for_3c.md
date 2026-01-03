# Vantage 3b to 3c: JIT Testing Requirements Coordination

**Date**: 2026-01-03-092836-pst  
**From**: Vantage 3b VM Runtime Agent  
**To**: Vantage 3c System Integration Agent  
**Status**: ✅ **READY FOR COORDINATION** — JIT testing requirements documented  
**Priority**: IMMEDIATE — Per Core 1 Subcore coordination (2026-01-03-091238-pst)

---

## Executive Summary

This document outlines JIT testing requirements for the x86_64 JIT backend implementation, providing coordination details for Agent 3c's multi-architecture testing framework integration.

**Status**: ✅ **x86_64 JIT Backend Implementation Complete** — Ready for testing coordination

**Key Accomplishments**:
- ✅ Phase 3 complete — x86_64 JIT backend with SLT/SLTU optimizations
- ✅ Guest RAM integration complete — R13 architecture implemented
- ✅ ECALL fallback implemented — Interpreter fallback for syscalls
- ✅ Test infrastructure created — Emit and translation test files ready

---

## JIT Testing Requirements

### Architecture Support

**Current Implementation**:
- ✅ **x86_64 JIT Backend**: Complete implementation with full instruction translation
- ✅ **ARM64 JIT Backend**: Existing implementation (maintained)
- ✅ **Architecture Detection**: Runtime detection via `builtin.cpu.arch`

**Testing Requirements**:
- ✅ **x86_64 AMD (Framework 16)**: Primary target — HIGH PRIORITY
- ✅ **x86_64 Intel (Legacy)**: Secondary target — HIGH PRIORITY
- ✅ **ARM64 (MacBook Air M2)**: Development/testing — MEDIUM PRIORITY

### Test Infrastructure Status

**Test Files Created**:
- ✅ `tests/154_x86_64_jit_emit_test.zig` — Emit function tests (instruction encoding verification)
- ✅ `tests/155_x86_64_jit_translation_test.zig` — Translation function tests (RISC-V → x86_64)

**Test Coverage**:
- ✅ REX prefix encoding
- ✅ ModR/M byte encoding
- ✅ Register mapping (RISC-V → x86_64)
- ✅ Instruction translation (R-type, I-type, load, store, branch, jump)
- ✅ ECALL fallback to interpreter
- ✅ SLT/SLTU optimization (SETcc instructions)
- ✅ JALR indirect jump
- ✅ Guest RAM pointer integration (R13 base pointer)

**Test Status**: ⚠️ **NEEDS MODULE FIX** — Test files need proper module import setup (independent work, can proceed)

### Multi-Architecture Testing Integration Points

**What Agent 3b Needs from Agent 3c**:

1. **Test Framework Integration**:
   - Architecture detection helpers (ARM64, x86_64 AMD, x86_64 Intel)
   - Test runner support for x86_64 JIT tests
   - Cross-architecture test comparison utilities

2. **Framework x86_64 Test Infrastructure**:
   - Test execution on Framework 16 (x86_64 AMD)
   - Test execution on legacy Intel hardware (x86_64 Intel)
   - Test result aggregation across architectures

3. **JIT-Specific Test Patterns**:
   - JIT compilation correctness tests
   - JIT execution correctness tests
   - JIT performance benchmarks
   - ECALL fallback validation tests
   - Guest RAM access validation tests

4. **Integration Testing**:
   - VM → Kernel integration (JIT-compiled code syscalls)
   - Multi-architecture syscall interface testing
   - Framework x86_64 end-to-end testing

### Testing Priorities

**IMMEDIATE** (Ready Now):
1. ✅ **x86_64 JIT Backend Testing**: Verify instruction translation correctness
2. ✅ **ECALL Fallback Testing**: Verify syscall fallback behavior
3. ✅ **Guest RAM Access Testing**: Verify R13 base pointer integration

**HIGH PRIORITY** (After Framework Infrastructure):
1. ⏳ **Framework x86_64 Test Execution**: Run tests on Framework 16
2. ⏳ **Multi-Architecture Comparison**: Compare ARM64 vs x86_64 JIT behavior
3. ⏳ **Performance Benchmarking**: JIT vs interpreter performance on x86_64

**MEDIUM PRIORITY** (Ongoing):
1. ⏳ **Legacy Intel Hardware Testing**: Test on x86_64 Intel systems
2. ⏳ **Integration Testing**: VM → Kernel integration with JIT
3. ⏳ **Error Handling Testing**: JIT error recovery and fallback

### Coordination Points

**What Agent 3b Can Provide**:
- ✅ JIT test files (emit and translation tests)
- ✅ JIT implementation details and architecture
- ✅ Testing requirements and priorities
- ✅ Integration points for test framework

**What Agent 3b Needs from Agent 3c**:
- ⏳ Multi-architecture test framework integration
- ⏳ Framework x86_64 test runner setup
- ⏳ Test execution coordination
- ⏳ Test result aggregation and reporting

### Next Steps

**For Agent 3c**:
1. **IMMEDIATE**: Review JIT testing requirements (this document)
2. **IMMEDIATE**: Coordinate test framework integration approach
3. **HIGH PRIORITY**: Set up Framework x86_64 test infrastructure
4. **HIGH PRIORITY**: Integrate JIT tests into multi-architecture framework

**For Agent 3b**:
1. ✅ JIT testing requirements documented (this document)
2. ⏳ Fix test module import issues (independent work)
3. ⏳ Prepare for test framework integration
4. ⏳ Ready to coordinate on test execution

### Timeline

**IMMEDIATE** (This Week):
- Coordinate test framework integration approach
- Set up Framework x86_64 test infrastructure
- Integrate JIT tests into multi-architecture framework

**HIGH PRIORITY** (Next 2 Weeks):
- Execute JIT tests on Framework x86_64
- Compare ARM64 vs x86_64 JIT behavior
- Performance benchmarking

**ONGOING**:
- Legacy Intel hardware testing
- Integration testing
- Error handling testing

---

## Technical Details

### JIT Backend Architecture

**x86_64 JIT Backend**:
- **Register Mapping**: RISC-V registers → x86_64 registers (1:1 mapping)
- **Guest RAM Pointer**: R13 (callee-saved register) = `guest_ram` base pointer
- **Guest State Pointer**: RDI (first argument) = `GuestState` pointer
- **Address Translation**: Kernel space, framebuffer, low memory translation
- **ECALL Fallback**: Returns `error.InvalidInstruction` to trigger interpreter fallback

**ARM64 JIT Backend** (Existing):
- **Register Mapping**: RISC-V registers → ARM64 registers (1:1 mapping)
- **Guest RAM Pointer**: x27 = `mem_base` (guest_ram base pointer)
- **Guest State Pointer**: x0 (first argument) = `GuestState` pointer

### Test Infrastructure

**Test Files**:
- `tests/154_x86_64_jit_emit_test.zig`: Tests x86_64 instruction encoding
- `tests/155_x86_64_jit_translation_test.zig`: Tests RISC-V → x86_64 translation

**Test Coverage Areas**:
1. **Emit Functions**: REX prefixes, ModR/M bytes, register mapping
2. **Instruction Translation**: R-type, I-type, load, store, branch, jump
3. **ECALL Fallback**: Interpreter fallback behavior
4. **Guest RAM Access**: R13 base pointer integration
5. **Address Translation**: Kernel, framebuffer, low memory

### Integration Points

**VM → Kernel Integration**:
- JIT-compiled code syscalls (ECALL fallback)
- Guest RAM access validation
- Address translation validation

**Multi-Architecture Testing**:
- ARM64 vs x86_64 JIT comparison
- x86_64 AMD vs Intel comparison
- Cross-architecture test result aggregation

---

## Summary

**Status**: ✅ **READY FOR COORDINATION** — JIT testing requirements documented

**Key Points**:
- ✅ x86_64 JIT backend implementation complete
- ✅ Test infrastructure created (needs module import fix)
- ✅ Ready for multi-architecture testing framework integration
- ⏳ IMMEDIATE: Coordinate test framework integration approach
- ⏳ HIGH PRIORITY: Set up Framework x86_64 test infrastructure

**Next Steps**:
1. Agent 3c reviews this document
2. Coordinate test framework integration approach
3. Set up Framework x86_64 test infrastructure
4. Integrate JIT tests into multi-architecture framework

---

**Date**: 2026-01-03-092836-pst  
**From**: Vantage 3b VM Runtime Agent  
**To**: Vantage 3c System Integration Agent  
**Status**: ✅ **READY FOR COORDINATION**

