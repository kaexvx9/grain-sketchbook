# ADR 006: ECALL Instruction Fallback Strategy

**Date**: 2026-01-02-100345-pst  
**Status**: ✅ **ACCEPTED**  
**Deciders**: Vantage 3 Subcore Agent, VM Runtime Agent (3b), Basin Kernel Agent (3a)  
**Context**: Need to handle RISC-V ECALL instructions (syscall invocation) in JIT-compiled code

---

## Context

**Problem**:
- ECALL instructions invoke kernel syscalls
- JIT-compiled code needs to handle ECALL instructions
- Two approaches: fall back to interpreter vs. JIT-compile ECALL
- Need to balance implementation complexity vs. performance

**Requirements**:
- Support syscall invocation from JIT-compiled code
- Maintain compatibility with existing ARM64 JIT behavior
- Follow Grain Style principles (simplicity, safety)
- Enable future optimization if needed

---

## Decision

**Phase 1 (Initial)**: ECALL instructions **fall back to interpreter** (matches current ARM64 JIT behavior).

**Phase 2 (Future Optimization)**: ECALL instructions can be **JIT-compiled** with syscall stub generation (if performance requires it).

**Rationale**:
- **Phase 1**: Simpler implementation, matches existing behavior, no syscall-specific JIT code needed
- **Phase 2**: Faster syscall invocation, reduced interpreter overhead, better performance for syscall-heavy workloads

**Implementation** (Phase 1):
1. JIT compiler detects ECALL instruction
2. JIT compiler emits interpreter fallback
3. Interpreter handles ECALL and calls kernel `handle_syscall()`
4. Interpreter receives `SyscallResult` union
5. Interpreter decodes result and updates VM registers
6. JIT code continues execution with updated registers

---

## Consequences

### Positive

- ✅ Simpler implementation (Phase 1)
- ✅ Matches current ARM64 JIT behavior
- ✅ No syscall-specific JIT code needed (Phase 1)
- ✅ Interpreter handles all syscall complexity
- ✅ Can optimize later with Phase 2 if needed
- ✅ Clear upgrade path for performance optimization

### Negative

- ⚠️ Interpreter overhead for syscall-heavy workloads (Phase 1)
- ⚠️ Performance impact for frequent syscalls (Phase 1)
- ⚠️ Phase 2 requires more complex implementation (syscall stub generation, register mapping, return value encoding)

### Neutral

- Phase 2 can be implemented incrementally if performance requires it
- Performance targets: < 1ms syscall latency (Phase 1 should meet this)

---

## Alternatives Considered

1. **ECALL Always JIT-Compiled**: Rejected — too complex for initial implementation
2. **ECALL Always Interpreter**: Rejected — limits future optimization
3. **Two-Phase Approach (Fallback First, JIT Later)**: **ACCEPTED** — balances simplicity and future optimization

---

## Implementation Status

**Date**: 2026-01-02-090817-pst  
**Status**: ✅ **PHASE 1 IMPLEMENTED**

**Completed**:
- ✅ ECALL fallback to interpreter implemented
- ✅ Interpreter handles ECALL and calls kernel `handle_syscall()`
- ✅ Return value handling implemented
- ✅ VM register updates implemented

**Remaining**:
- ⏳ Integration with Basin Kernel syscall interface (after syscall docs received from Agent 3a)
- ⏳ Testing on Framework x86_64
- ⏳ Performance validation (< 1ms syscall latency target)

**Phase 2 (Future)**:
- ⏳ Syscall stub generation
- ⏳ Register mapping (RISC-V → x86_64)
- ⏳ Return value encoding/decoding
- ⏳ Performance optimization

---

## References

- `docs/kernel/syscall_interface_for_jit.md` — JIT-specific syscall interface guide
- `docs/plans/jit_integration_planning.md` — JIT integration planning (ECALL patterns)
- `docs/core-coordination/vantage_3b_vm_runtime_coordination.md` — VM Runtime coordination

---

**Date**: 2026-01-02-100345-pst  
**Status**: ✅ **ACCEPTED** — Phase 1 implemented, Phase 2 available for future optimization

