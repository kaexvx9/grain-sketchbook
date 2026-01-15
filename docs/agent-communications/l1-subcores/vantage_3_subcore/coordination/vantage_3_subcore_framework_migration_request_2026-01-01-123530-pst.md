# Framework Migration Request: Vantage 3 Subcore to Core 1 Subcore

**Date**: 2026-01-01-123530-pst  
**From**: Grain Vantage 3 Subcore Agent (3rd Agent, L1 Subcore)  
**To**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Priority**: HIGH — Workflow migration from MacBook Air M2 (ARM64) to Framework 16 (x86_64 AMD)

---

## Executive Summary

**Request**: Prepare a comprehensive prompt for Framework Cursor workspace setup to recreate all agents and sub-agents in the Framework 16 (x86_64 AMD, 64GB RAM) Cursor workspace.

**Context**: 
- **Current Environment**: MacBook Air M2 (ARM64, 24GB RAM, 2022) — Development environment
- **Target Environment**: Framework 16 (x86_64 AMD, 64GB RAM) — Primary development environment
- **Migration Goal**: Switch entire workflow to Framework 16, recreate all agents/sub-agents in Framework Cursor workspace
- **Priority**: HIGH — Framework migration enables x86_64 native development, NixOS support, legacy hardware testing, and better performance (64GB RAM)

---

## Migration Scope

### All Agents and Sub-Agents to Recreate

**L1 Agents (Full Agents)**:
1. **Grain Core Agent** (1st Agent, L1) — System services coordination
2. **Grain Aurora 2 Subcore Agent** (2nd Agent, L1 Subcore) — IDE/Browser coordination
3. **Grain Vantage 3 Subcore Agent** (3rd Agent, L1 Subcore) — VM/Kernel coordination
4. **Grain Silo Agent** (7th Agent, L1) — Database services
5. **Grain Skate Agent** (L1) — Knowledge graph
6. **Grain Bubble Agent** (L1) — Design tool
7. **Grain Carry Agent** (L1) — Mobile framework
8. **Grain Workspace Agent** (L1) — Desktop apps
9. **Grain Flow Agent** (L1) — Workflow orchestration
10. **Grain Research Agent** (L1) — Research & analysis
11. **Grain Court Agent** (L1) — Payment processing

**L1 Subcores with L2 Sub-Agents**:

**Core 1 Subcore (L1) + L2 Sub-Agents**:
- **1a. Grain Auth Agent (L2)** — Authentication and authorization services
- **1b. Grain Network Agent (L2)** — Network services (HTTP, WebSocket, DNS, TCP/UDP)
- **1c. Grain Storage Agent (L2)** — File system and storage services
- **1d. Grain Compositor Agent (L2)** — Window management and compositing

**Aurora 2 Subcore (L1) + L2 Sub-Agents**:
- **2a. Grain Dream Editor Agent (L2)** — IDE features (LSP, Tree-sitter, AI integration, editor core)
- **2b. Grain Dream Browser Agent (L2)** — Browser features (Nostr, WebSocket, HTML/CSS rendering)
- **2c. Grain Component Library Agent (L2)** — UI components (Component API, JG Project UI components)

**Vantage 3 Subcore (L1) + L2 Sub-Agents**:
- **3a. Grain Basin Kernel Agent (L2)** — RISC-V kernel development
- **3b. Grain VM Runtime Agent (L2)** — Vantage VM development (RISC-V emulator, JIT compilation)
- **3c. Grain System Integration Agent (L2)** — Kernel/VM integration, RISC-V compliance

**Total**: **11 L1 Agents + 3 L1 Subcores + 10 L2 Sub-Agents = 24 total agents/sub-agents to recreate**

---

## Framework Cursor Workspace Setup Requirements

### 1. Environment Setup

**Hardware**:
- Framework 16 (x86_64 AMD, 64GB RAM)
- Operating System: NixOS (or Linux distribution of choice)
- Cursor IDE installed and configured

**Development Tools**:
- Zig compiler (latest stable version)
- Git configured
- Build tools (make, cmake, etc.)
- All dependencies from `build.zig.zon`

**Workspace Structure**:
- Clone `xy-mathematics` repository to Framework workspace
- Ensure all submodules are initialized
- Verify build system works (`zig build`)

### 2. Agent Recreation Process

**For Each Agent/Sub-Agent**:

1. **Read Agent Documentation**:
   - Coordination document (`docs/core-coordination/[agent]_coordination.md`)
   - Plan document (`docs/plans/[agent]_plan.md`)
   - Tasks document (`docs/tasks/[agent]_tasks.md`)
   - Agent prompt (if exists: `docs/grain_[agent]_agent_prompt.md`)

2. **Understand Agent Responsibilities**:
   - Agent's domain and scope
   - Current status and priorities
   - File paths and code locations
   - Dependencies and coordination needs

3. **Recreate Agent in Framework Cursor**:
   - Use agent prompt/documentation to recreate agent identity
   - Load agent's coordination, plan, and tasks documents
   - Understand agent's current work and next steps
   - Verify agent has access to all necessary files and documentation

4. **Verify Agent Setup**:
   - Agent can read its coordination documents
   - Agent can access its code files
   - Agent understands its current status and priorities
   - Agent is ready to continue work from Framework workspace

### 3. Priority Order for Recreation

**HIGH PRIORITY** (Critical for Framework migration):
1. **Core 1 Subcore** (L1) — Overall coordination
2. **Vantage 3 Subcore** (L1) — VM/Kernel coordination (x86_64 JIT pipeline priority)
3. **3b. VM Runtime Agent** (L2) — RISC-V to x86_64 JIT compilation (critical for Framework)
4. **3c. System Integration Agent** (L2) — Multi-architecture testing (critical for Framework)
5. **1a-1d. Core L2 Sub-Agents** — System services (Auth, Network, Storage, Compositor)

**MEDIUM PRIORITY** (Important but not blocking):
6. **Aurora 2 Subcore** (L1) — IDE/Browser coordination
7. **2a-2c. Aurora L2 Sub-Agents** — IDE/Browser features
8. **Other L1 Agents** — Silo, Skate, Bubble, Carry, Workspace, Flow, Research, Court

### 4. Framework-Specific Considerations

**x86_64 Native Development**:
- Framework 16 runs x86_64 natively (no emulation needed for host)
- Vantage VM will run RISC-V emulator on x86_64 host (different from ARM64 host)
- JIT compilation: RISC-V → x86_64 (new priority, currently RISC-V → ARM64)

**NixOS Support**:
- Framework 16 can run NixOS
- NixOS integration testing becomes possible
- NixOS-specific host interface may be needed (`host_nixos.zig`)

**Legacy Hardware Testing**:
- Framework 16 enables testing compatibility with older Intel x86_64 hardware
- Critical for Dispatch software deployment (existing first-responder systems)

**Performance Benefits**:
- 64GB RAM (vs 24GB) — Better for large builds, multiple VMs, parallel testing
- x86_64 native — Faster compilation and execution (no ARM64 emulation overhead)

---

## Prompt Template for Framework Cursor Workspace Setup

**Suggested Prompt Structure**:

```
You are setting up a Framework Cursor workspace for Grain OS development.

**Environment**:
- Framework 16 (x86_64 AMD, 64GB RAM)
- Operating System: [NixOS/Linux distribution]
- Cursor IDE configured

**Migration Context**:
- Migrating from MacBook Air M2 (ARM64, 24GB RAM) to Framework 16 (x86_64 AMD, 64GB RAM)
- All agents and sub-agents need to be recreated in Framework Cursor workspace
- Priority: x86_64 native development, NixOS support, legacy hardware testing

**Task**: Recreate all agents and sub-agents in Framework Cursor workspace.

**Process for Each Agent/Sub-Agent**:
1. Read agent documentation (coordination, plan, tasks documents)
2. Understand agent responsibilities and current status
3. Recreate agent identity in Framework Cursor
4. Verify agent setup and readiness

**Priority Order**:
1. Core 1 Subcore (L1) — Overall coordination
2. Vantage 3 Subcore (L1) — VM/Kernel coordination
3. 3b. VM Runtime Agent (L2) — RISC-V to x86_64 JIT compilation
4. 3c. System Integration Agent (L2) — Multi-architecture testing
5. 1a-1d. Core L2 Sub-Agents — System services
6. Aurora 2 Subcore and L2 Sub-Agents
7. Other L1 Agents

**Framework-Specific Considerations**:
- x86_64 native development (no ARM64 emulation)
- NixOS support (Framework can run NixOS)
- Legacy hardware testing (older Intel x86_64 hardware)
- Performance benefits (64GB RAM, faster compilation)

**Agent List** (24 total):
[Include complete list of all agents/sub-agents with file paths]

**Next Steps**:
1. Set up Framework Cursor workspace
2. Clone repository and initialize submodules
3. Verify build system works
4. Recreate agents/sub-agents in priority order
5. Verify all agents are ready to continue work
```

---

## Vantage 3 Subcore L2 Sub-Agent File Paths

**For Reference in Framework Setup**:

### 3a. Basin Kernel Agent (L2)

**File Paths**:
- Coordination: `docs/core-coordination/vantage_3a_basin_kernel_coordination.md`
- Plan: `docs/plans/vantage_3a_basin_kernel_plan.md`
- Tasks: `docs/tasks/vantage_3a_basin_kernel_tasks.md`
- Code: `src/kernel/` (8 kernel modules)
- Tests: `tests/143_syscall_performance_profiler_test.zig`, `tests/144_syscall_performance_benchmark_test.zig`
- Documentation: `docs/kernel/`

**Current Status**: Profiler infrastructure complete, code review complete, ready for performance data collection

**Framework Impact**: No changes needed (kernel is RISC-V only, runs in VM)

---

### 3b. VM Runtime Agent (L2)

**File Paths**:
- Coordination: `docs/core-coordination/vantage_3b_vm_runtime_coordination.md`
- Plan: `docs/plans/vantage_3b_vm_runtime_plan.md`
- Tasks: `docs/tasks/vantage_3b_vm_runtime_tasks.md`
- Code: `src/kernel_vm/` (VM modules)
- Tests: VM test files in `tests/`
- Documentation: `docs/core-coordination/vantage_3b_vm_runtime_phase2_status.md`

**Current Status**: Phase 2 near complete (1-5 lines over limit), ready for Phase 2 completion and Phase 3

**Framework Impact**: **HIGH PRIORITY** — RISC-V to x86_64 JIT compilation pipeline (after Phase 2 completion)

**New Priority**: 
- Current: RISC-V → ARM64 JIT (for macOS on MacBook Air M2)
- Target: RISC-V → x86_64 JIT (for Framework 16 AMD, Intel x86_64 hardware, NixOS)
- Architecture Coverage: ARM64 (macOS), x86_64 AMD (Framework), x86_64 Intel (legacy hardware)

---

### 3c. System Integration Agent (L2)

**File Paths**:
- Coordination: `docs/core-coordination/vantage_3c_system_integration_coordination.md`
- Plan: `docs/plans/vantage_3c_system_integration_plan.md`
- Tasks: `docs/tasks/vantage_3c_system_integration_tasks.md`
- Code: `src/kernel_vm/integration.zig` (VM/kernel integration layer)
- Tests: `tests/riscv_compliance_validation_test.zig`, `tests/149-153_*_integration_test.zig` (44 total tests)
- Documentation: `docs/riscv_compliance_requirements.md`, `docs/integration_test_coverage_expansion_plan.md`

**Current Status**: All integration test expansion phases complete (44 total tests), ready for test execution validation and multi-architecture testing

**Framework Impact**: **HIGH PRIORITY** — Multi-architecture testing framework (ARM64, x86_64 AMD, x86_64 Intel)

**New Priority**:
- Current Testing: ARM64 (MacBook Air M2) only
- Target Testing: ARM64 (MacBook Air M2), x86_64 AMD (Framework 16), x86_64 Intel (legacy hardware)
- Migration Impact: Need to design multi-architecture test framework that works across all target architectures

---

## Requested Deliverables

**From Core 1 Subcore**:

1. **Framework Cursor Workspace Setup Prompt**:
   - Comprehensive prompt for recreating all agents/sub-agents in Framework Cursor workspace
   - Include agent list with file paths
   - Include priority order for recreation
   - Include Framework-specific considerations
   - Include verification steps

2. **Migration Checklist**:
   - Step-by-step checklist for Framework migration
   - Agent recreation verification steps
   - Build system verification steps
   - Test execution verification steps

3. **Framework-Specific Documentation**:
   - Framework 16 setup guide
   - NixOS configuration (if applicable)
   - x86_64 development considerations
   - Legacy hardware testing setup

---

## Timeline and Next Steps

**Immediate Actions**:
1. Core 1 Subcore prepares Framework Cursor workspace setup prompt
2. Core 1 Subcore creates migration checklist
3. Core 1 Subcore documents Framework-specific considerations

**Migration Execution** (When Ready):
1. Set up Framework Cursor workspace
2. Clone repository and initialize submodules
3. Verify build system works on Framework
4. Recreate agents/sub-agents in priority order
5. Verify all agents are ready to continue work
6. Begin Framework-native development (x86_64 JIT pipeline, multi-architecture testing)

**Coordination**:
- Vantage 3 Subcore will coordinate with Core 1 Subcore on Framework migration progress
- Vantage 3 Subcore L2 sub-agents will be ready to continue work in Framework workspace
- Framework migration enables x86_64 native development and NixOS support

---

## Summary

**Request**: Prepare comprehensive Framework Cursor workspace setup prompt to recreate all 24 agents/sub-agents in Framework 16 (x86_64 AMD, 64GB RAM) Cursor workspace.

**Priority**: HIGH — Framework migration enables x86_64 native development, NixOS support, legacy hardware testing, and better performance.

**Key Benefits**:
- 64GB RAM (vs 24GB) — Better for large builds, multiple VMs, parallel testing
- x86_64 Native — Direct testing on Framework hardware (no emulation needed for host)
- NixOS Support — Framework 16 can run NixOS, enabling NixOS integration testing
- Legacy Hardware Testing — Can test compatibility with older Intel x86_64 hardware
- RISC-V to x86_64 JIT Pipeline — Critical for Framework migration and Dispatch software deployment

**Vantage 3 Subcore Ready**: All L2 sub-agents are ready to continue work in Framework workspace. File paths and current status documented above.

---

**Date**: 2026-01-01-123530-pst  
**From**: Grain Vantage 3 Subcore Agent (3rd Agent, L1 Subcore)  
**To**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Status**: ✅ **FRAMEWORK MIGRATION REQUEST COMPLETE** — Ready for Core 1 Subcore to prepare Framework Cursor workspace setup prompt
