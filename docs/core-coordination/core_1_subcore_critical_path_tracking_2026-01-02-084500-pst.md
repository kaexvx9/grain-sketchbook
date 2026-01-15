# Core 1 Subcore: Critical Path Tracking Document

**Date**: 2026-01-02-084500-pst  
**Agent**: Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator) — Carry 6  
**Status**: ✅ **TRACKING ACTIVE** — Monitoring single-threaded dependency chain toward Vantage running Basin Kernel on Framework sevenos x86_64 with working Grainscript shell

**Goal**: Vantage application running Basin Kernel for Framework Grain OS sevenos x86_64 with Grainscript shell usable successfully for basic Grainscript commands implemented in Zig following Grain Style with recursion prompt strict guidelines.

---

## Critical Path Status Overview

**Single-threaded computation priority chain** — All steps must execute in strict dependency order.

### Step 1: Basin Kernel Syscall Interface Distribution (BLOCKING) ⏳
**Agent**: 3a (Basin Kernel) → **Recipients**: 3b (VM Runtime), 3d (Init System)  
**Status**: ✅ Documentation complete, ✅ Approved, ⏳ **DISTRIBUTION IN PROGRESS**  
**Timeline**: THIS WEEK (immediate)

**What's Complete**:
- ✅ Complete syscall interface reference (`docs/kernel/syscall_interface_reference.md`)
- ✅ JIT-specific interface guide (`docs/kernel/syscall_interface_for_jit.md`)
- ✅ Init System interface guide (`docs/kernel/syscall_interface_for_init.md`)
- ✅ Vantage 3 Subcore approval received (2026-01-02-083246-pst)

**What's Needed**:
- ⏳ **IMMEDIATE**: Distribute documentation to Agent 3b (VM Runtime)
- ⏳ **IMMEDIATE**: Distribute documentation to Agent 3d (Init System)
- ⏳ Verify receipt and acknowledgment from both agents
- ⏳ Update coordination documents with distribution completion

**Blocking**: Steps 2 and 3 cannot proceed without this documentation.

**Core 1 Subcore Action**: Monitor distribution progress, facilitate if needed.

---

### Step 2: VM Runtime Grain Style Compliance + JIT Pipeline (BLOCKING) ⏳
**Agent**: 3b (VM Runtime) → **Output**: Vantage Application with x86_64 JIT  
**Status**: ⏳ **BLOCKED ON STEP 1** — Waiting for syscall interface documentation  
**Timeline**: WEEK 1-2 (after Step 1 complete)

**What's Needed** (after Step 1):
- ⏳ Verify Phase 2 Grain Style compliance (validate-70, grainwrap-100) — THIS WEEK
- ⏳ Design RISC-V → x86_64 JIT pipeline using Basin syscall docs — WEEK 1
- ⏳ Implement x86_64 JIT backend for Framework x86_64 — WEEK 1-2

**Current Status**:
- ⚠️ Phase 2 Grain Style compliance: 2 functions 1-5 lines over limit
  - `vm.zig::step()` (71 lines → 70 lines needed)
  - `jit.zig::compile_block()` (75 lines → 70 lines needed)

**Blocking**: Vantage cannot run without x86_64 JIT compilation.

**Core 1 Subcore Action**: Monitor compliance verification, coordinate with Vantage 3 Subcore on progress.

---

### Step 3: sevenos Init System Completion (BLOCKING) ⏳
**Agent**: 3d (Init System) → **Output**: Complete Init System ready for Shell integration  
**Status**: ⏳ **BLOCKED ON STEP 1** — Waiting for syscall interface documentation  
**Timeline**: WEEK 1-2 (after Step 1 complete)

**What's Needed** (after Step 1):
- ⏳ Fix dependency manager compilation issue (Zig 0.15.2) — THIS WEEK
- ⏳ Complete Phase 3 (dependency manager) — THIS WEEK
- ⏳ Implement Phase 4 (main init loop) — WEEK 1-2
- ⏳ Integrate with Basin Kernel syscall interface (spawn, wait, exit, setpgid, setsid) — WEEK 1-2

**Current Status**:
- ✅ Supervision library foundation complete
- ⏳ Service configuration loader (needs completion)
- ⏳ Dependency manager (compilation issue to fix)
- ⏳ Main init loop (needs implementation)

**Blocking**: Shell cannot integrate without Init System.

**Core 1 Subcore Action**: Prepare for cross-subcore coordination (1e ↔ 3d), monitor Init System progress.

---

### Step 4: Grainscript Shell Integration (END GOAL) ⏳
**Agent**: 1e (Grainscript Shell) → **Output**: Usable Shell  
**Status**: ✅ Phase 1 complete, ⏳ **BLOCKED ON STEP 3** — Waiting for Init System  
**Timeline**: WEEK 1-2 (after Step 3 complete)

**What's Complete**:
- ✅ Zig 0.15.2 API compatibility fixed
- ✅ Basic shell functionality working (built-in commands, external programs, pipes)

**What's Needed** (after Step 3):
- ⏳ Complete basic shell functionality testing — THIS WEEK
- ⏳ Integrate with sevenos Init System (3d) — WEEK 1-2 (BLOCKED ON STEP 3)
- ⏳ Verify shell works for basic Grainscript commands on Framework x86_64 — WEEK 1-2

**Blocking**: End goal cannot be achieved without shell integration.

**Core 1 Subcore Action**: Coordinate cross-subcore integration (1e ↔ 3d), prepare integration architecture.

---

### Step 5: System Integration Testing Framework (SUPPORTING) ⏳
**Agent**: 3c (System Integration) → **Output**: Multi-architecture testing framework  
**Status**: ⏳ **IN PROGRESS** — Can proceed independently  
**Timeline**: WEEK 1-2 (parallel with Steps 2-4)

**What's Needed**:
- ⏳ Implement multi-architecture testing framework — WEEK 1-2
- ⏳ Create Framework x86_64 test runner — WEEK 1-2
- ⏳ Adapt existing 44 integration tests for multi-arch — WEEK 2-3

**Current Status**:
- ✅ All integration test expansion phases complete (44 tests)
- ⏳ Multi-architecture testing framework design in progress

**Supporting**: Enables verification of all components.

**Core 1 Subcore Action**: Coordinate on Core 1 services integration testing, share test results.

---

## Core 1 Subcore: Independent Work (Non-Conflicting)

### 1. Critical Path Monitoring and Facilitation (ONGOING)

**Tasks**:
- [ ] Monitor Step 1: Verify syscall documentation distribution to 3b and 3d
- [ ] Monitor Step 2: Track VM Runtime compliance and JIT progress
- [ ] Monitor Step 3: Track Init System completion progress
- [ ] Monitor Step 4: Prepare for Shell ↔ Init System integration
- [ ] Monitor Step 5: Coordinate with System Integration (3c) on testing

**Why This Matters**:
- Ensures critical path stays on track
- Identifies blockers early
- Facilitates coordination when needed

**Deliverables**:
- Weekly critical path status updates
- Blocker identification and escalation
- Coordination facilitation summaries

**Timeline**: Ongoing

---

### 2. Cross-Subcore Integration Architecture Planning (HIGH PRIORITY)

**Context**: Step 4 requires cross-subcore coordination between Core 1 Subcore (1e) and Vantage 3 Subcore (3d). We should prepare the integration architecture now, even though Step 4 is blocked on Step 3.

**Tasks**:
- [ ] Design Shell ↔ Init System integration architecture
- [ ] Define API contracts for shell-init system communication
- [ ] Plan service lifecycle integration (shell as a service)
- [ ] Design command execution flow (shell → init system → kernel)
- [ ] Document integration patterns and best practices

**Why This Matters**:
- Prepares for Step 4 integration work
- Reduces integration time when Step 3 completes
- Ensures clean architecture from the start

**Deliverables**:
- Integration architecture document
- API contract specifications
- Integration patterns guide

**Timeline**: Week 1-2 (can proceed in parallel with Steps 2-3)

---

### 3. Core 1 Services Integration Testing Framework (MEDIUM PRIORITY)

**Context**: While waiting for critical path steps, we can develop integration testing framework for Core 1 services that will be needed when shell integrates with Core services.

**Tasks**:
- [ ] Design Core 1 services integration test framework
- [ ] Plan integration tests for Auth + Network (middleware)
- [ ] Plan integration tests for Network + Storage (file transfer)
- [ ] Plan integration tests for Storage + Auth (credential storage)
- [ ] Plan integration tests for Shell + Core services (1a-1d)
- [ ] Coordinate with System Integration (3c) on test infrastructure

**Why This Matters**:
- Prepares for Step 4 shell integration with Core services
- Ensures Core services work correctly together
- Enables comprehensive testing when integration happens

**Deliverables**:
- Integration test framework design
- Test plan for Core services integration
- Coordination plan with System Integration (3c)

**Timeline**: Week 1-2 (can proceed in parallel)

---

### 4. Documentation Enhancement: Dependency Tracking (LOW PRIORITY)

**Context**: The single-threaded dependency chain needs clear tracking. We can enhance coordination documents to make dependencies more visible.

**Tasks**:
- [ ] Add dependency chain visualization to coordination documents
- [ ] Create blocker tracking section in coordination plan
- [ ] Update agent-specific instructions with dependency context
- [ ] Enhance troubleshooting section with dependency-related issues

**Why This Matters**:
- Makes critical path more visible to all agents
- Helps agents understand why their work is blocked
- Facilitates better coordination

**Deliverables**:
- Enhanced coordination documents
- Dependency tracking visualization
- Blocker tracking section

**Timeline**: Week 1 (can proceed anytime)

---

## Coordination Needs

### With Vantage 3 Subcore

**Immediate**:
- Monitor Step 1 distribution progress (3a → 3b, 3d)
- Coordinate on Step 2 compliance verification (3b)
- Coordinate on Step 3 Init System progress (3d)
- Prepare for Step 4 cross-subcore integration (1e ↔ 3d)

**Weekly Coordination**:
- **Time**: Every Tuesday, 2:00 PM PST (1 hour)
- **Focus**: Critical path progress, blockers, cross-subcore integration planning

---

### With System Integration (3c)

**Immediate**:
- Coordinate on multi-architecture testing framework design
- Plan Core 1 services integration testing
- Share test infrastructure requirements

**Weekly Coordination**:
- **Time**: Every Monday, 11:00 AM PST (30 minutes)
- **Focus**: Integration testing coordination, test results sharing

---

### With L2 Sub-Agents (1a-1e)

**Immediate**:
- Monitor Agent 1e (Shell) progress on testing and integration preparation
- Coordinate Agents 1a-1d on Framework x86 adaptation
- Prepare for Shell ↔ Core services integration (Step 4)

**Weekly Check-Ins**:
- **Time**: Every Monday, 10:00 AM PST (30 minutes)
- **Focus**: Progress updates, blockers, integration planning

---

## Blocker Tracking

### Current Blockers

1. **Step 1 Blocker**: ⏳ **IN PROGRESS** — Syscall documentation distribution to 3b and 3d
   - **Owner**: Agent 3a (Basin Kernel)
   - **Status**: Documentation complete, approved, distribution in progress
   - **Expected Resolution**: This week
   - **Impact**: Blocks Steps 2 and 3

2. **Step 2 Blocker**: ⏳ **WAITING** — VM Runtime Grain Style compliance + JIT implementation
   - **Owner**: Agent 3b (VM Runtime)
   - **Status**: Blocked on Step 1, compliance issues identified
   - **Expected Resolution**: Week 1-2 (after Step 1)
   - **Impact**: Blocks Vantage running

3. **Step 3 Blocker**: ⏳ **WAITING** — Init System compilation fix + completion
   - **Owner**: Agent 3d (Init System)
   - **Status**: Blocked on Step 1, compilation issue identified
   - **Expected Resolution**: Week 1-2 (after Step 1)
   - **Impact**: Blocks Step 4 (Shell integration)

4. **Step 4 Blocker**: ⏳ **WAITING** — Shell integration with Init System
   - **Owner**: Agent 1e (Grainscript Shell)
   - **Status**: Blocked on Step 3, Phase 1 complete
   - **Expected Resolution**: Week 1-2 (after Step 3)
   - **Impact**: Blocks end goal

---

## Success Criteria

### Week 1 Success
- ✅ Step 1: Syscall documentation distributed to 3b and 3d
- ✅ Step 2: VM Runtime compliance verified
- ✅ Step 3: Init System compilation fixed
- ✅ Step 4: Shell testing complete
- ✅ Step 5: Multi-arch testing framework design complete

### Week 2 Success
- ✅ Step 2: x86_64 JIT backend implemented
- ✅ Step 3: Init System Phase 3 and 4 complete
- ✅ Step 4: Shell integrated with Init System
- ✅ Step 5: Multi-arch testing framework implemented

### End Goal Success
- ✅ Vantage running Basin Kernel on Framework x86_64
- ✅ Grainscript shell usable for basic commands
- ✅ All components integrated and tested

---

## Notes

- All work must follow Grain Style strictly
- All implementations target RISC-V only (kernel runs in VM)
- Use Glow G2 voice in all communications (calm, steadfast, forward-looking)
- Zero technical debt policy (no TODOs or FIXMEs)
- Parallel work model maximizes development velocity where possible

---

**Date**: 2026-01-02-084500-pst  
**Agent**: Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator) — Carry 6  
**Status**: ✅ **TRACKING ACTIVE** — Monitoring critical path progress

