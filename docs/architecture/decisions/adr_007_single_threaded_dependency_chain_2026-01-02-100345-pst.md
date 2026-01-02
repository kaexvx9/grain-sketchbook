# ADR 007: Single-Threaded Dependency Chain for Critical Path

**Date**: 2026-01-02-100345-pst  
**Status**: ✅ **ACCEPTED**  
**Deciders**: Core 1 Subcore Agent, Vantage 3 Subcore Agent  
**Context**: Need to coordinate multiple agents toward end goal with clear dependencies

---

## Context

**Problem**:
- Multiple agents working on different components (Basin Kernel, VM Runtime, Init System, Grainscript Shell)
- Complex dependencies between components
- Need clear coordination model to prevent blocking and conflicts
- Goal: Vantage running Basin Kernel on Framework sevenos x86_64 with working Grainscript shell

**Requirements**:
- Clear dependency chain
- Prevent blocking work
- Enable parallel work where possible
- Support critical path execution

---

## Decision

Implement **single-threaded dependency chain** with strict dependency order for critical path, while allowing supporting work to proceed in parallel.

**Critical Path** (executed in strict dependency order):
1. **Step 1 (BLOCKING)**: Basin Kernel (3a) → Distribute syscall docs to 3b and 3d
2. **Step 2 (BLOCKING)**: VM Runtime (3b) → Verify Grain Style compliance + implement x86_64 JIT
3. **Step 3 (BLOCKING)**: Init System (3d) → Fix compilation + complete Phase 3/4 + Basin syscall integration
4. **Step 4 (END GOAL)**: Grainscript Shell (1e) → Complete testing + integrate with Init System
5. **Step 5 (SUPPORTING)**: System Integration (3c) → Multi-arch testing framework (can proceed in parallel)

**Coordination Model**:
- **Blocking Steps**: Must complete in strict order (Steps 1-4)
- **Supporting Steps**: Can proceed in parallel (Step 5)
- **Parallel Work**: Independent work that doesn't block critical path (integration planning, documentation, optimizations)

---

## Consequences

### Positive

- ✅ Clear dependency chain prevents blocking
- ✅ Enables parallel work where possible
- ✅ Supports critical path execution
- ✅ Prevents conflicts and coordination issues
- ✅ Clear priorities for all agents

### Negative

- Sequential execution for blocking steps (slower than parallel)
- Requires careful coordination to prevent blocking

### Neutral

- Supporting work can proceed in parallel
- Independent work doesn't block critical path

---

## Alternatives Considered

1. **Fully Parallel**: Rejected — would cause blocking and conflicts
2. **Fully Sequential**: Rejected — too slow, prevents parallel work
3. **Single-Threaded Dependency Chain with Parallel Supporting Work**: **ACCEPTED** — balances dependency management with parallelization

---

## Implementation Status

**Date**: 2026-01-02-083246-pst  
**Status**: ✅ **ACTIVE**

**Current Status**:
- ✅ Step 1: APPROVED (Agent 3a syscall docs distribution)
- ✅ Step 2: Phase 3 COMPLETE (Agent 3b x86_64 JIT backend)
- ⏳ Step 3: BLOCKED ON STEP 1 (Agent 3d Init System)
- ⏳ Step 4: BLOCKED ON STEP 3 (Agent 1e Grainscript Shell)
- ✅ Step 5: DESIGN APPROVED (Agent 3c multi-arch testing framework)

**Coordination**:
- Vantage 3 Subcore monitoring Step 1 completion
- Core 1 Subcore monitoring critical path progress
- All agents aware of dependency chain

---

## References

- `docs/agent-communications/core_1_subcore_coordination_summary_2026-01-02-083246-pst.md` — Single-threaded priority chain
- `docs/core-coordination/vantage_3_subcore_coordination.md` — Vantage 3 Subcore coordination

---

**Date**: 2026-01-02-100345-pst  
**Status**: ✅ **ACCEPTED** — Active, critical path monitoring in progress

