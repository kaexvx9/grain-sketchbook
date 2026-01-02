# ADR 005: RISC-V → x86_64 JIT Compilation Strategy

**Date**: 2026-01-02-100345-pst  
**Status**: ✅ **ACCEPTED**  
**Deciders**: Vantage 3 Subcore Agent, VM Runtime Agent (3b)  
**Context**: Need to enable Basin Kernel execution on Framework x86_64 (x86_64 AMD) and legacy Intel x86_64 hardware

---

## Context

**Problem**:
- Basin Kernel targets RISC-V only (Grain OS principle)
- Framework 16 development environment is x86_64 AMD (Ubuntu 24.04 LTS)
- Need to run RISC-V kernel code on x86_64 hardware
- Existing ARM64 JIT backend exists, but x86_64 backend needed

**Requirements**:
- Support Framework 16 (x86_64 AMD) for development
- Support legacy Intel x86_64 hardware for Dispatch software deployment
- Maintain compatibility with existing ARM64 JIT architecture
- Follow Grain Style principles (safety, performance, joy)

---

## Decision

Implement **RISC-V → x86_64 JIT compilation backend** using architecture-specific backend selection at runtime, mirroring the existing ARM64 JIT architecture.

**Strategy**:
1. **Architecture Detection**: Detect host architecture at JIT context initialization
2. **Backend Selection**: Select appropriate backend (ARM64 or x86_64) based on host architecture
3. **Instruction Translation**: RISC-V instructions → x86_64 instructions (mirror ARM64 approach)
4. **Emit Functions**: x86_64-specific code generation (`emit_add_x86_64`, `emit_mov_x86_64`, etc.)
5. **Code Buffer**: Same executable memory mechanism (platform-agnostic)

**Implementation Approach**:
- **Phase 1**: Architecture detection and backend selection
- **Phase 2**: x86_64 emit functions (basic set)
- **Phase 3**: x86_64 instruction translation (all basic instructions)
- **Phase 4**: Integration and testing on Framework x86_64

**ECALL Handling**:
- **Phase 1 (Initial)**: ECALL instructions fall back to interpreter (simpler, matches ARM64 behavior)
- **Phase 2 (Future)**: ECALL instructions generate syscall stubs (optimization, if needed)

---

## Consequences

### Positive

- ✅ Enables native x86_64 execution on Framework 16
- ✅ Supports legacy Intel x86_64 hardware
- ✅ Maintains compatibility with existing ARM64 JIT
- ✅ Both backends can coexist
- ✅ Architecture detection is straightforward
- ✅ Matches proven ARM64 JIT architecture

### Negative

- x86_64 has fewer registers than RISC-V (16 vs 32) — requires careful register allocation
- x86_64 uses variable-length instructions (1-15 bytes) — more complex encoding than ARM64's fixed 4-byte instructions
- Additional code complexity (architecture-specific backend selection)

### Neutral

- Implementation requires x86_64 instruction encoding knowledge
- Register allocator needed for efficient register mapping
- Performance optimization can be done incrementally

---

## Alternatives Considered

1. **Pure Interpreter (No JIT)**: Rejected — too slow for production use
2. **Separate x86_64 Kernel**: Rejected — violates "RISC-V only" Grain OS principle
3. **QEMU Emulation**: Rejected — too slow, not native performance
4. **Architecture-Specific Backend Selection**: **ACCEPTED** — maintains compatibility, enables native performance

---

## Implementation Status

**Date**: 2026-01-02-090817-pst  
**Status**: ✅ **PHASE 3 COMPLETE**

**Completed**:
- ✅ Phase 3.1: Architecture detection and backend selection complete
- ✅ Phase 3.2: x86_64 emit functions implemented (15+ functions)
- ✅ Phase 3.3: x86_64 instruction translation implemented (all basic instructions)
- ✅ Phase 3.4: Critical fixes and backend-aware fixup system complete
- ✅ SLT/SLTU optimizations complete (SETcc instructions)
- ✅ ECALL fallback to interpreter implemented

**Remaining**:
- ⏳ ECALL integration (after syscall interface docs received from Agent 3a)
- ⏳ Testing on Framework x86_64
- ⏳ Performance optimizations (JALR indirect jump, address translation enhancement)

---

## References

- `docs/kernel_vm/x86_64_jit_backend_design.md` — x86_64 JIT backend design
- `docs/plans/jit_integration_planning.md` — JIT integration planning
- `docs/core-coordination/vantage_3b_vm_runtime_coordination.md` — VM Runtime coordination

---

**Date**: 2026-01-02-100345-pst  
**Status**: ✅ **ACCEPTED** — Phase 3 complete, ready for testing

