# Critical Path Quick Reference: Single-Threaded Dependency Chain

**Date**: 2026-01-02-084259-pst  
**Agent**: Free 12 (Coordination and Documentation Support, Core 1 Subcore)  
**Status**: ✅ **QUICK REFERENCE READY** — Critical path visualization for all agents

---

## Goal

**Vantage application running Basin Kernel for Framework Grain OS sevenos x86_64 with Grainscript shell usable for basic commands** (Zig, Grain Style, recursion prompt strict guidelines)

---

## Critical Path (Strict Dependency Order)

### Step 1: Basin Kernel Syscall Interface Distribution ⚠️ BLOCKING

**Agent**: 3a (Basin Kernel)  
**Status**: ✅ Documentation ready  
**Action**: Distribute syscall docs to 3b and 3d  
**Timeline**: THIS WEEK  
**Blocks**: Steps 2 and 3

**What 3a Must Do**:
- [ ] Distribute syscall interface documentation to Agent 3b (VM Runtime)
- [ ] Distribute syscall interface documentation to Agent 3d (Init System)
- [ ] Verify documentation completeness
- [ ] Check in with Vantage 3 Subcore when complete

**What 3b and 3d Are Waiting For**:
- Syscall interface documentation to proceed with integration

---

### Step 2: VM Runtime Grain Style Compliance + JIT Pipeline ⚠️ BLOCKING

**Agent**: 3b (VM Runtime)  
**Status**: Phase 2 compliance in progress  
**Action**: Verify compliance + implement x86_64 JIT  
**Timeline**: WEEK 1-2  
**Blocks**: Vantage application running

**What 3b Must Do**:
- [ ] Verify Phase 2 Grain Style compliance (validate-70, grainwrap-100) — THIS WEEK
- [ ] Design RISC-V → x86_64 JIT pipeline using Basin syscall docs — WEEK 1
- [ ] Implement x86_64 JIT backend for Framework x86_64 — WEEK 1-2
- [ ] Integrate with Basin Kernel syscall interface
- [ ] Check in with Vantage 3 Subcore before integration

**Dependencies**:
- ✅ Basin Kernel syscall docs (from Step 1)

**What Vantage Application Is Waiting For**:
- x86_64 JIT compilation to run Basin Kernel

---

### Step 3: sevenos Init System Completion ⚠️ BLOCKING

**Agent**: 3d (Init System)  
**Status**: Supervision library complete, phases 3-4 in progress  
**Action**: Fix compilation + complete phases + Basin syscall integration  
**Timeline**: WEEK 1-2  
**Blocks**: Step 4 (Shell integration)

**What 3d Must Do**:
- [ ] Fix dependency manager compilation issue (Zig 0.15.2) — THIS WEEK
- [ ] Complete Phase 3 (dependency manager) — THIS WEEK
- [ ] Implement Phase 4 (main init loop) — WEEK 1-2
- [ ] Integrate with Basin Kernel syscall interface (spawn, wait, exit, setpgid, setsid) — WEEK 1-2
- [ ] Check in with Vantage 3 Subcore before integration

**Dependencies**:
- ✅ Basin Kernel syscall docs (from Step 1)

**What Shell Is Waiting For**:
- Complete Init System to integrate

---

### Step 4: Grainscript Shell Integration 🎯 END GOAL

**Agent**: 1e (Grainscript Shell)  
**Status**: Phase 1 complete, basic functionality in progress  
**Action**: Complete testing + integrate with Init System  
**Timeline**: WEEK 1-2  
**End Goal**: Usable shell on Framework x86_64

**What 1e Must Do**:
- [ ] Complete basic shell functionality testing — THIS WEEK
- [ ] Integrate with sevenos Init System (3d) — WEEK 1-2 (BLOCKED ON STEP 3)
- [ ] Verify shell works for basic Grainscript commands on Framework x86_64 — WEEK 1-2
- [ ] Check in with Core 1 Subcore before integration

**Dependencies**:
- ✅ Complete Init System (from Step 3)

**End Goal**:
- Usable Grainscript shell running on Vantage/Basin Kernel Framework x86_64

---

### Step 5: System Integration Testing Framework 🔧 SUPPORTING

**Agent**: 3c (System Integration)  
**Status**: Integration complete, multi-arch testing in progress  
**Action**: Multi-arch testing framework  
**Timeline**: WEEK 1-2  
**Role**: Supporting verification

**What 3c Must Do**:
- [ ] Implement multi-architecture testing framework — WEEK 1-2
- [ ] Create Framework x86_64 test runner — WEEK 1-2
- [ ] Verify all components work together
- [ ] Check in with Vantage 3 Subcore before integration

**Role**: Enables verification of all components

---

## Dependency Chain Visualization

```
Goal: Vantage running Basin Kernel with working Grainscript shell
│
├─ Step 1: 3a (Basin Kernel) → Distribute syscall docs
│   └─ Blocks: Steps 2 and 3
│
├─ Step 2: 3b (VM Runtime) → Verify compliance + x86_64 JIT
│   ├─ Depends on: Step 1 (syscall docs)
│   └─ Blocks: Vantage application running
│
├─ Step 3: 3d (Init System) → Fix compilation + complete phases
│   ├─ Depends on: Step 1 (syscall docs)
│   └─ Blocks: Step 4 (Shell integration)
│
├─ Step 4: 1e (Grainscript Shell) → Complete testing + integrate
│   ├─ Depends on: Step 3 (Complete Init System)
│   └─ End Goal: Usable shell
│
└─ Step 5: 3c (System Integration) → Multi-arch testing
    └─ Role: Supporting verification
```

---

## Critical Blockers Summary

### Blocker 1: 3a Must Distribute Syscall Docs
- **Agent**: 3a (Basin Kernel)
- **Action**: Distribute documentation to 3b and 3d
- **Timeline**: THIS WEEK
- **Impact**: Blocks Steps 2 and 3

### Blocker 2: 3b Must Verify Compliance and Implement JIT
- **Agent**: 3b (VM Runtime)
- **Action**: Verify Grain Style compliance + implement x86_64 JIT
- **Timeline**: WEEK 1-2
- **Impact**: Blocks Vantage application running

### Blocker 3: 3d Must Fix Compilation and Complete Phases
- **Agent**: 3d (Init System)
- **Action**: Fix compilation + complete Phase 3/4 + Basin syscall integration
- **Timeline**: WEEK 1-2
- **Impact**: Blocks Step 4 (Shell integration)

### Blocker 4: 1e Must Integrate with 3d
- **Agent**: 1e (Grainscript Shell)
- **Action**: Complete testing + integrate with Init System
- **Timeline**: WEEK 1-2
- **Impact**: Blocks end goal

---

## Requirements for All Steps

**All agents in the critical path must**:
- ✅ Follow Grain Style strictly (grain_case, u32/u64, grainwrap-100, validate-70)
- ✅ Follow recursion prompt strict guidelines
- ✅ Update documentation (coordination, plan, tasks)
- ✅ Check in before integration steps
- ✅ Ensure all tests pass
- ✅ Use Glow G2 voice in all communications

---

## Timeline Summary

**THIS WEEK**:
- Step 1: 3a distributes syscall docs
- Step 2: 3b verifies Grain Style compliance
- Step 3: 3d fixes compilation + completes Phase 3
- Step 4: 1e completes basic shell testing

**WEEK 1-2**:
- Step 2: 3b implements x86_64 JIT backend
- Step 3: 3d implements Phase 4 + Basin syscall integration
- Step 4: 1e integrates with Init System
- Step 5: 3c implements multi-arch testing framework

**END GOAL**: Usable Grainscript shell running on Vantage/Basin Kernel Framework x86_64

---

## Quick Status Check

**For Agents in Critical Path**:
1. What step are you on?
2. Are your dependencies met?
3. What's blocking you?
4. When will you complete your step?
5. Have you checked in with your parent Subcore?

**For Other Agents**:
- Continue your work independently
- Avoid conflicts with critical path agents
- Check in before integration with critical path agents
- Support critical path agents as needed

---

## Reference Documents

- **Latest Coordination Summary**: `docs/agent-communications/core_1_subcore_coordination_summary_2026-01-02-083246-pst.md`
- **Latest Coordination Plan**: `docs/core-coordination/core_1_subcore_coordination_plan_2026-01-01-235944-pst.md`
- **Grain Style**: `docs/grain_style.md`
- **Recursion Prompt Guidelines**: `docs/framework_16_recursion_prompt_strict_guidelines_2026-01-01-202549-pst.md`

---

**Date**: 2026-01-02-084259-pst  
**Agent**: Free 12 (Coordination and Documentation Support, Core 1 Subcore)  
**Status**: ✅ **QUICK REFERENCE COMPLETE** — Ready for agent use

