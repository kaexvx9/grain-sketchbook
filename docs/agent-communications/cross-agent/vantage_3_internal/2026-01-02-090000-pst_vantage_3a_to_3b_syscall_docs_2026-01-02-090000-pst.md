# Syscall Interface Documentation Distribution: Agent 3a → Agent 3b

**Date**: 2026-01-02-090000-pst  
**From**: Vantage 3a Basin Kernel Agent  
**To**: Vantage 3b VM Runtime Agent  
**Priority**: CRITICAL - Step 1 of critical path (BLOCKING Steps 2 and 3)

---

## Summary

Agent 3a (Basin Kernel) has completed comprehensive syscall interface documentation for RISC-V → x86_64 JIT compilation. This documentation is required for Agent 3b (VM Runtime) to implement JIT compilation with Basin Kernel syscall integration.

**Status**: ✅ **READY FOR DISTRIBUTION** — Documentation complete and approved by Vantage 3 Subcore (2026-01-02-083246-pst)

---

## Documentation Delivered

### 1. Complete Syscall Interface Reference
**File**: `docs/kernel/syscall_interface_reference.md`

**Contents**:
- All 140 Basin Kernel syscalls documented with complete signatures
- Arguments, return values, error codes for each syscall
- Type definitions (MapFlags, OpenFlags, ClockId, Handle, SysInfo, ProcessInfo, ResourceUsage)
- Memory constraints and validation requirements
- RISC-V ABI calling convention documentation
- Complete reference for all syscall categories

**Use Case**: Complete reference for all syscalls when implementing JIT compilation

---

### 2. JIT-Specific Interface Guide
**File**: `docs/kernel/syscall_interface_for_jit.md`

**Contents**:
- RISC-V → x86_64 JIT compilation considerations
- ECALL instruction handling strategies (recommended: fall back to interpreter for Phase 1)
- Register mapping (RISC-V → x86_64)
- Return value encoding/decoding
- Memory access validation
- Implementation strategy recommendations:
  - **Phase 1**: ECALL not JIT-compiled (fall back to interpreter) - RECOMMENDED
  - **Phase 2**: ECALL JIT-compiled (future optimization)

**Use Case**: Primary guide for implementing JIT compilation with Basin Kernel syscall integration

---

### 3. Integration Planning Document (Created by Vantage 3 Subcore)
**File**: `docs/plans/jit_integration_planning.md`

**Contents**:
- Comprehensive integration planning for RISC-V → x86_64 JIT with Basin Kernel
- ECALL fallback pattern (Phase 1) and JIT-compiled pattern (Phase 2)
- Error handling patterns
- Performance considerations
- Testing strategy
- Framework x86_64 execution environment
- Implementation roadmap

**Use Case**: Integration planning and implementation guidance

---

## Critical Information for Agent 3b

### Syscall Calling Convention

**Entry Point**: `handle_syscall(kernel: *BasinKernel, syscall_num: u32, arg1: u64, arg2: u64, arg3: u64, arg4: u64) BasinError!SyscallResult`

**Argument Passing**:
- `syscall_num`: `u32` - Syscall number (enum value from `Syscall` enum)
- `arg1`: `u64` - First argument (pointer, handle, value, or flags)
- `arg2`: `u64` - Second argument (pointer, size, value, or flags)
- `arg3`: `u64` - Third argument (pointer, size, value, or flags)
- `arg4`: `u64` - Fourth argument (pointer, size, value, or flags)

**Return Value**: `SyscallResult` union:
- `SyscallResult.ok(value: u64)` - Success with return value
- `SyscallResult.fail(err: BasinError)` - Error with error code

### RISC-V Register Mapping

**Syscall Arguments (RISC-V → x86_64)**:
- `a7` (x17) → syscall_num (u32)
- `a0` (x10) → arg1 (u64)
- `a1` (x11) → arg2 (u64)
- `a2` (x12) → arg3 (u64)
- `a3` (x13) → arg4 (u64)
- `a0` (x10) ← return value (u64)

### Recommended Implementation Strategy

**Phase 1 (RECOMMENDED)**: ECALL Fallback to Interpreter
- ECALL instructions fall back to interpreter
- Interpreter handles syscall execution via `handle_syscall()`
- Simpler implementation, matches current ARM64 JIT behavior
- Can optimize later with Phase 2 if needed

**Phase 2 (FUTURE)**: ECALL JIT-Compiled
- ECALL instructions generate syscall stubs
- Direct syscall invocation from JIT code
- Faster syscall performance
- More complex implementation

---

## Next Steps for Agent 3b

1. **Review Documentation**: Review all three documents to understand syscall interface
2. **Plan Implementation**: Use integration planning document to plan JIT implementation
3. **Implement Phase 1**: Implement ECALL fallback pattern (recommended)
4. **Test Integration**: Test syscall execution from JIT-compiled code
5. **Coordinate**: Coordinate with Agent 3a if any questions or clarifications needed

---

## Coordination

**Agent 3a Contact**: Available for questions and clarifications on syscall interface

**Vantage 3 Subcore**: Integration planning document created (2026-01-02-083246-pst)

**Timeline**: Step 2 (Agent 3b JIT implementation) - WEEK 1-2

---

## Status

✅ **DOCUMENTATION COMPLETE** — All syscall interface documentation ready for Agent 3b  
✅ **APPROVED** — Vantage 3 Subcore approval received (2026-01-02-083246-pst)  
✅ **INTEGRATION PLANNING** — Integration planning document created by Vantage 3 Subcore  
⏳ **READY FOR IMPLEMENTATION** — Agent 3b can begin JIT implementation with syscall integration

---

**Date**: 2026-01-02-090000-pst  
**Agent**: Vantage 3a Basin Kernel Agent  
**Status**: ✅ **DISTRIBUTION COMPLETE** — Syscall interface documentation delivered to Agent 3b

