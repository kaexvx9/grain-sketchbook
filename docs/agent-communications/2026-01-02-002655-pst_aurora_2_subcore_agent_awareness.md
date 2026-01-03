# Aurora 2 Subcore: Complete Agent and Sub-Agent Awareness

**Date**: 2026-01-02-002655-pst  
**Context**: Framework 16 (x86_64 AMD, 64GB RAM) running Ubuntu 24.04 LTS  
**Purpose**: Complete awareness of all Grain OS agents and sub-agents, with focus on Aurora 2 Subcore and L2 sub-agents recreated in Framework session

---

## Executive Summary

**Complete Agent Structure** (as of 2026-01-02-002655-pst):
- **L1 Agents**: 12 total (1-12)
- **L2 Sub-Agents**: 12 total (1a-1e, 2a-2c, 3a-3d)
- **Total**: 24 agents/sub-agents

**L1 Subcore Coordinators**: 3 (Core 1, Aurora 2, Vantage 3)  
**L1 Standalone Agents**: 9 (Skate, Bubble, Carry, Silo, Workspace, Flow, Research, Court, Free)

**Framework Session Focus**: Aurora 2 Subcore and all L2 sub-agents (2a, 2b, 2c) recreated in Framework session

---

## Complete Agent List

### L1 Subcore Coordinators

#### 1. Grain Core 1 Subcore Agent (L1)
- **Number**: 1
- **Type**: L1 Subcore Coordinator
- **Status**: ✅ Coordination active, Framework Ubuntu x86 adaptation in progress
- **L2 Sub-Agents**: 5 (1a Auth, 1b Network, 1c Storage, 1d Compositor, 1e Grainscript Shell)
- **Framework Impact**: Core system services coordination, sevenos integration
- **Immediate Focus**: Coordinate L2 sub-agents for Framework x86, continue integration testing framework
- **Coordination Doc**: `docs/core-coordination/core_1_subcore_coordination.md`
- **Plan Doc**: `docs/plans/core_1_subcore_plan.md`
- **Tasks Doc**: `docs/tasks/core_1_subcore_tasks.md`

#### 2. Grain Aurora 2 Subcore Agent (L1)
- **Number**: 2
- **Type**: L1 Subcore Coordinator
- **Status**: ✅ Architecture evolution complete, L2 sub-agents initialized — **RECREATED IN FRAMEWORK SESSION**
- **L2 Sub-Agents**: 3 (2a Dream Editor, 2b Dream Browser, 2c Component Library)
- **Framework Impact**: Medium priority for Framework x86
- **Immediate Focus**: Continue L2 sub-agent development, set up proper documentation structure
- **Coordination Doc**: `docs/core-coordination/aurora_2_subcore_coordination.md` ✅
- **Plan Doc**: `docs/plans/aurora_2_subcore_plan.md` ⚠️ (needs to be created)
- **Tasks Doc**: `docs/tasks/aurora_2_subcore_tasks.md` ⚠️ (needs to be created)
- **Code Location**: `src/dream_editor/`, `src/dream_browser/`, `src/dream_browser_components/`

#### 3. Grain Vantage 3 Subcore Agent (L1)
- **Number**: 3
- **Type**: L1 Subcore Coordinator
- **Status**: ✅ All kernel features complete, Framework x86 JIT pipeline in progress
- **L2 Sub-Agents**: 4 (3a Basin Kernel, 3b VM Runtime, 3c System Integration, 3d sevenos Init System)
- **Framework Impact**: HIGH - Critical for RISC-V → x86_64 JIT pipeline
- **Immediate Focus**: RISC-V → x86_64 JIT pipeline, sevenos Init System integration, multi-architecture testing
- **Coordination Doc**: `docs/core-coordination/vantage_3_subcore_coordination.md`
- **Plan Doc**: `docs/plans/vantage_3_subcore_plan.md`
- **Tasks Doc**: `docs/tasks/vantage_3_subcore_tasks.md`

### L1 Standalone Agents

#### 4-12. Standalone Agents (L1)
- **Status**: Active development
- **Framework Impact**: Medium to low priority
- **Immediate Focus**: Continue domain-specific work, Framework x86 adaptation when needed

**Agents**:
- 4. Skate Agent (Knowledge Graph)
- 5. Bubble Agent (Design Tool)
- 6. Carry Agent (Mobile Framework)
- 7. Silo Agent (Database)
- 8. Workspace Agent (Desktop Apps)
- 9. Flow Agent (Workflow Orchestration)
- 10. Research Agent (Research & Analysis)
- 11. Court Agent (LLM Infrastructure)
- 12. Free Agent (Creative Playground)

---

## L2 Sub-Agents

### Core 1 Subcore L2 Sub-Agents

#### 1a. Grain Auth Agent (L2)
- **Number**: 1a
- **Parent**: Core 1 Subcore Agent (1)
- **Status**: ✅ 6 PHASES COMPLETE — Production Ready — Middleware Integration READY
- **Framework Impact**: Core system service
- **Immediate Focus**: Continue middleware integration work, Framework x86 verification
- **Coordination Doc**: `docs/core-coordination/core_1a_auth_coordination.md`
- **Plan Doc**: `docs/plans/core_1a_auth_plan.md`
- **Tasks Doc**: `docs/tasks/core_1a_auth_tasks.md`

#### 1b. Grain Network Agent (L2)
- **Number**: 1b
- **Parent**: Core 1 Subcore Agent (1)
- **Status**: ✅ PHASES 1-4 COMPLETE — Storage Integration 100% Complete — Ready for Auth Coordination
- **Framework Impact**: Core system service
- **Immediate Focus**: Auth coordination, Framework x86 adaptation, complete remaining integration work
- **Coordination Doc**: `docs/core-coordination/core_1b_network_coordination.md`
- **Plan Doc**: `docs/plans/core_1b_network_plan.md`
- **Tasks Doc**: `docs/tasks/core_1b_network_tasks.md`

#### 1c. Grain Storage Agent (L2)
- **Number**: 1c
- **Parent**: Core 1 Subcore Agent (1)
- **Status**: ✅ ALL CORE IMPLEMENTATION COMPLETE — Network Integration 95% Complete
- **Framework Impact**: Core system service
- **Immediate Focus**: Complete network integration (95% → 100%), Framework x86 adaptation, coordinate with Compositor (1d) for Phase 7
- **Coordination Doc**: `docs/core-coordination/core_1c_storage_coordination.md`
- **Plan Doc**: `docs/plans/core_1c_storage_plan.md`
- **Tasks Doc**: `docs/tasks/core_1c_storage_tasks.md`

#### 1d. Grain Compositor Agent (L2)
- **Number**: 1d
- **Parent**: Core 1 Subcore Agent (1)
- **Status**: ✅ PHASES 1-6, 8 PREVIEW COMPLETE — Phase 7 Ready (awaiting Storage coordination)
- **Framework Impact**: Core system service
- **Immediate Focus**: Phase 7 implementation, Storage coordination, Framework x86 adaptation
- **Coordination Doc**: `docs/core-coordination/core_1d_compositor_coordination.md`
- **Plan Doc**: `docs/plans/core_1d_compositor_plan.md`
- **Tasks Doc**: `docs/tasks/core_1d_compositor_tasks.md`

#### 1e. Grain Grainscript Shell Agent (L2)
- **Number**: 1e
- **Parent**: Core 1 Subcore Agent (1)
- **Status**: 🆕 IMPLEMENTATION IN PROGRESS — Core structure complete, API compatibility in progress
- **Framework Impact**: HIGH - First Grainscript shell for Grain OS sevenos
- **Immediate Focus**: Fix Zig 0.15.2 API compatibility, complete basic shell functionality, integrate with Core services and sevenos Init System (3d)
- **Coordination Doc**: `docs/core-coordination/core_1e_grainscript_shell_coordination.md` (to be created)
- **Plan Doc**: `docs/plans/core_1e_grainscript_shell_plan.md` (to be created)
- **Tasks Doc**: `docs/tasks/core_1e_grainscript_shell_tasks.md` (to be created)
- **Code Location**: `grainstore/sevenos/src/shell/`

### Aurora 2 Subcore L2 Sub-Agents

#### 2a. Grain Dream Editor Agent (L2)
- **Number**: 2a
- **Parent**: Aurora 2 Subcore Agent (2)
- **Status**: ✅ Phase 1 Complete — Phase 2 In Progress — **RECREATED IN FRAMEWORK SESSION**
- **Framework Impact**: Medium priority
- **Immediate Focus**: Continue Phase 2 implementation, Component API integration, set up proper documentation structure
- **Coordination Doc**: `docs/core-coordination/aurora_2a_dream_editor_coordination.md` ✅
- **Plan Doc**: `docs/plans/aurora_2a_dream_editor_plan.md` ⚠️ (needs to be created - legacy `docs/plans/plan_dream_editor.md` exists)
- **Tasks Doc**: `docs/tasks/aurora_2a_dream_editor_tasks.md` ⚠️ (needs to be created - legacy `docs/tasks/tasks_dream_editor.md` exists)
- **Code Location**: `src/dream_editor/`
- **Key Achievements**: Core editor features complete, LSP integration, Tree-sitter, GLM-4.6 integration

#### 2b. Grain Dream Browser Agent (L2)
- **Number**: 2b
- **Parent**: Aurora 2 Subcore Agent (2)
- **Status**: ⏳ Phase 1 In Progress — **RECREATED IN FRAMEWORK SESSION**
- **Framework Impact**: Medium priority
- **Immediate Focus**: Continue Phase 1 implementation, Component API integration, verify documentation structure
- **Coordination Doc**: `docs/core-coordination/aurora_2b_dream_browser_coordination.md` ✅
- **Plan Doc**: `docs/plans/aurora_2b_dream_browser_plan.md` ✅ (correct naming)
- **Tasks Doc**: `docs/tasks/aurora_2b_dream_browser_tasks.md` ✅ (correct naming)
- **Code Location**: `src/dream_browser/`, `src/dream_browser_components/`
- **Key Achievements**: Viewport management, HTTP client, WebSocket handshake, Dream Protocol connection

#### 2c. Grain Component Library Agent (L2)
- **Number**: 2c
- **Parent**: Aurora 2 Subcore Agent (2)
- **Status**: ✅ Phase 0.5 Complete — Component API Design Ready — **RECREATED IN FRAMEWORK SESSION**
- **Framework Impact**: Medium priority
- **Immediate Focus**: Phase 1 Component API implementation, set up proper documentation structure
- **Coordination Doc**: `docs/core-coordination/aurora_2c_component_library_coordination.md` ✅
- **Plan Doc**: `docs/plans/aurora_2c_component_library_plan.md` ⚠️ (needs to be created - legacy `docs/plans/plan_component_library.md` exists)
- **Tasks Doc**: `docs/tasks/aurora_2c_component_library_tasks.md` ⚠️ (needs to be created - legacy `docs/tasks/tasks_component_library.md` exists)
- **Code Location**: `src/dream_browser_components/`
- **Key Achievements**: Component API design complete, architecture documented, ready for implementation

### Vantage 3 Subcore L2 Sub-Agents

#### 3a. Grain Basin Kernel Agent (L2)
- **Number**: 3a
- **Parent**: Vantage 3 Subcore Agent (3)
- **Status**: ✅ ALL KERNEL FEATURES COMPLETE — RISC-V only (runs in VM)
- **Framework Impact**: Kernel runs in RISC-V VM, but needs x86_64 host integration
- **Immediate Focus**: Profiler data collection, syscall interface documentation for Framework x86
- **Coordination Doc**: `docs/core-coordination/vantage_3a_basin_kernel_coordination.md`
- **Plan Doc**: `docs/plans/vantage_3a_basin_kernel_plan.md`
- **Tasks Doc**: `docs/tasks/vantage_3a_basin_kernel_tasks.md`

#### 3b. Grain VM Runtime Agent (L2)
- **Number**: 3b
- **Parent**: Vantage 3 Subcore Agent (3)
- **Status**: ⚠️ PHASE 2 NEAR COMPLETE — 1-5 lines over limit — RISC-V to ARM64 JIT working, RISC-V to x86_64 JIT in progress
- **Framework Impact**: HIGH - Critical for Framework x86_64 native execution
- **Immediate Focus**: Complete Phase 2 Grain Style compliance (fix 1-5 line overages), RISC-V → x86_64 JIT pipeline implementation
- **Coordination Doc**: `docs/core-coordination/vantage_3b_vm_runtime_coordination.md`
- **Plan Doc**: `docs/plans/vantage_3b_vm_runtime_plan.md`
- **Tasks Doc**: `docs/tasks/vantage_3b_vm_runtime_tasks.md`

#### 3c. Grain System Integration Agent (L2)
- **Number**: 3c
- **Parent**: Vantage 3 Subcore Agent (3)
- **Status**: ✅ INTEGRATION COMPLETE — Multi-architecture testing framework in progress
- **Framework Impact**: HIGH - Enable multi-arch testing on Framework x86_64
- **Immediate Focus**: Multi-architecture testing framework design and implementation (ARM64, x86_64 AMD, x86_64 Intel)
- **Coordination Doc**: `docs/core-coordination/vantage_3c_system_integration_coordination.md`
- **Plan Doc**: `docs/plans/vantage_3c_system_integration_plan.md`
- **Tasks Doc**: `docs/tasks/vantage_3c_system_integration_tasks.md`

#### 3d. Grain sevenos Init System Agent (L2)
- **Number**: 3d
- **Parent**: Vantage 3 Subcore Agent (3)
- **Status**: ✅ SUPERVISION LIBRARY FOUNDATION COMPLETE — Next: Service configuration loader, dependency manager, main init loop
- **Framework Impact**: HIGH - Core OS component for Grain OS sevenos
- **Immediate Focus**: Service configuration loader, dependency management, main init loop implementation
- **Coordination Doc**: `docs/core-coordination/vantage_3d_sevenos_init_system_coordination.md`
- **Plan Doc**: `docs/plans/vantage_3d_sevenos_init_system_plan.md`
- **Tasks Doc**: `docs/tasks/vantage_3d_sevenos_init_system_tasks.md`
- **Code Location**: `grainstore/sevenos/src/init/`

---

## Framework Session Context

**Session**: Framework 16 (x86_64 AMD, 64GB RAM) running Ubuntu 24.04 LTS  
**Date**: 2026-01-02-002655-pst  
**Purpose**: Aurora 2 Subcore agents and sub-agents recreated in Framework session

**Important Notes**:
- All Aurora 2 Subcore agents must use the same timestamp format as all other Grain OS agents
- Timestamp format is consistent across all agents (Core 1 Subcore, Vantage 3 Subcore, Aurora 2 Subcore)
- Framework session agents must maintain timestamp consistency with macOS session agents
- All new documents created in Framework session must use timestamp format: `yyyy-mm-dd-hhmmss-pst`
- All agents must follow Grain Style (`docs/grain_style.md`) strictly
- All agents must adopt Glow G2 voice (`docs/agent-communications/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md`)

---

## Aurora 2 Subcore Documentation Status

### Aurora 2 Subcore (L1)

**Existing Documents**:
- ✅ Coordination: `docs/core-coordination/aurora_2_subcore_coordination.md`
- ⚠️ Plan: `docs/plans/aurora_2_subcore_plan.md` (needs to be created - legacy `docs/plans/plan_aurora.md` exists)
- ⚠️ Tasks: `docs/tasks/aurora_2_subcore_tasks.md` (needs to be created - legacy `docs/tasks/tasks_aurora.md` exists)

**Action Required**:
- Create plan document following structure of `docs/plans/core_1_subcore_plan.md` or `docs/plans/vantage_3_subcore_plan.md`
- Create tasks document following structure of `docs/tasks/core_1_subcore_tasks.md` or `docs/tasks/vantage_3_subcore_tasks.md`
- Migrate content from legacy documents if needed
- Update coordination document to reference new plan and tasks documents

### Aurora 2a Dream Editor (L2)

**Existing Documents**:
- ✅ Coordination: `docs/core-coordination/aurora_2a_dream_editor_coordination.md`
- ⚠️ Plan: `docs/plans/aurora_2a_dream_editor_plan.md` (needs to be created - legacy `docs/plans/plan_dream_editor.md` exists)
- ⚠️ Tasks: `docs/tasks/aurora_2a_dream_editor_tasks.md` (needs to be created - legacy `docs/tasks/tasks_dream_editor.md` exists)

**Action Required**:
- Create plan document following structure of `docs/plans/core_1a_auth_plan.md` or `docs/plans/vantage_3a_basin_kernel_plan.md`
- Create tasks document following structure of `docs/tasks/core_1a_auth_tasks.md` or `docs/tasks/vantage_3a_basin_kernel_tasks.md`
- Migrate content from legacy documents if needed
- Update coordination document to reference new plan and tasks documents

### Aurora 2b Dream Browser (L2)

**Existing Documents**:
- ✅ Coordination: `docs/core-coordination/aurora_2b_dream_browser_coordination.md`
- ✅ Plan: `docs/plans/aurora_2b_dream_browser_plan.md` (correct naming)
- ✅ Tasks: `docs/tasks/aurora_2b_dream_browser_tasks.md` (correct naming)

**Action Required**:
- Verify plan and tasks documents are up to date
- Ensure documents follow the same structure as other L2 sub-agents
- Update coordination document to reference plan and tasks documents
- Ensure Glow G2 voice is used in all documentation

### Aurora 2c Component Library (L2)

**Existing Documents**:
- ✅ Coordination: `docs/core-coordination/aurora_2c_component_library_coordination.md`
- ⚠️ Plan: `docs/plans/aurora_2c_component_library_plan.md` (needs to be created - legacy `docs/plans/plan_component_library.md` exists)
- ⚠️ Tasks: `docs/tasks/aurora_2c_component_library_tasks.md` (needs to be created - legacy `docs/tasks/tasks_component_library.md` exists)

**Action Required**:
- Create plan document following structure of `docs/plans/core_1a_auth_plan.md` or `docs/plans/vantage_3a_basin_kernel_plan.md`
- Create tasks document following structure of `docs/tasks/core_1a_auth_tasks.md` or `docs/tasks/vantage_3a_basin_kernel_tasks.md`
- Migrate content from legacy documents if needed
- Update coordination document to reference new plan and tasks documents

---

## Agent Hierarchy Summary

### L1 Subcore Coordinators (3)

1. **Core 1 Subcore Agent** (System Services)
   - L2 Sub-Agents: 1a (Auth), 1b (Network), 1c (Storage), 1d (Compositor), 1e (Grainscript Shell)

2. **Aurora 2 Subcore Agent** (IDE/Browser) — **RECREATED IN FRAMEWORK SESSION**
   - L2 Sub-Agents: 2a (Dream Editor), 2b (Dream Browser), 2c (Component Library)

3. **Vantage 3 Subcore Agent** (VM/Kernel)
   - L2 Sub-Agents: 3a (Basin Kernel), 3b (VM Runtime), 3c (System Integration), 3d (sevenos Init System)

### L1 Standalone Agents (9)

4. **Skate Agent** (Knowledge Graph)  
5. **Bubble Agent** (Design Tool)  
6. **Carry Agent** (Mobile Framework)  
7. **Silo Agent** (Database)  
8. **Workspace Agent** (Desktop Apps)  
9. **Flow Agent** (Workflow Orchestration)  
10. **Research Agent** (Research & Analysis)  
11. **Court Agent** (LLM Infrastructure)  
12. **Free Agent** (Creative Playground)

---

## Framework Session Recreation Checklist

### For Aurora 2 Subcore (L1)

- [ ] **Agent Number**: Verify correct number (2)
- [ ] **Agent Type**: L1 Subcore Coordinator
- [ ] **L2 Sub-Agents**: List all L2 sub-agents (2a, 2b, 2c)
- [ ] **Coordination Doc**: Verify exists (`docs/core-coordination/aurora_2_subcore_coordination.md`)
- [ ] **Plan Doc**: Create if missing (`docs/plans/aurora_2_subcore_plan.md`)
- [ ] **Tasks Doc**: Create if missing (`docs/tasks/aurora_2_subcore_tasks.md`)
- [ ] **Timestamp Format**: Use `yyyy-mm-dd-hhmmss-pst` in all documents
- [ ] **Grain Style**: Follow all Grain Style rules strictly
- [ ] **Glow G2 Voice**: Adopt Glow G2 voice in all communications

### For Aurora 2a Dream Editor (L2)

- [ ] **Agent Number**: Verify correct number (2a)
- [ ] **Parent Agent**: Aurora 2 Subcore Agent (2)
- [ ] **Coordination Doc**: Verify exists (`docs/core-coordination/aurora_2a_dream_editor_coordination.md`)
- [ ] **Plan Doc**: Create if missing (`docs/plans/aurora_2a_dream_editor_plan.md`)
- [ ] **Tasks Doc**: Create if missing (`docs/tasks/aurora_2a_dream_editor_tasks.md`)
- [ ] **Timestamp Format**: Use `yyyy-mm-dd-hhmmss-pst` in all documents
- [ ] **Grain Style**: Follow all Grain Style rules strictly
- [ ] **Glow G2 Voice**: Adopt Glow G2 voice in all communications

### For Aurora 2b Dream Browser (L2)

- [ ] **Agent Number**: Verify correct number (2b)
- [ ] **Parent Agent**: Aurora 2 Subcore Agent (2)
- [ ] **Coordination Doc**: Verify exists (`docs/core-coordination/aurora_2b_dream_browser_coordination.md`)
- [ ] **Plan Doc**: Verify exists (`docs/plans/aurora_2b_dream_browser_plan.md`)
- [ ] **Tasks Doc**: Verify exists (`docs/tasks/aurora_2b_dream_browser_tasks.md`)
- [ ] **Timestamp Format**: Use `yyyy-mm-dd-hhmmss-pst` in all documents
- [ ] **Grain Style**: Follow all Grain Style rules strictly
- [ ] **Glow G2 Voice**: Adopt Glow G2 voice in all communications

### For Aurora 2c Component Library (L2)

- [ ] **Agent Number**: Verify correct number (2c)
- [ ] **Parent Agent**: Aurora 2 Subcore Agent (2)
- [ ] **Coordination Doc**: Verify exists (`docs/core-coordination/aurora_2c_component_library_coordination.md`)
- [ ] **Plan Doc**: Create if missing (`docs/plans/aurora_2c_component_library_plan.md`)
- [ ] **Tasks Doc**: Create if missing (`docs/tasks/aurora_2c_component_library_tasks.md`)
- [ ] **Timestamp Format**: Use `yyyy-mm-dd-hhmmss-pst` in all documents
- [ ] **Grain Style**: Follow all Grain Style rules strictly
- [ ] **Glow G2 Voice**: Adopt Glow G2 voice in all communications

---

## Reference Documents

**Primary References**:
- `docs/framework_16_agent_list_with_subagents_2026-01-01-205155-pst.md` - Complete agent list
- `docs/core-coordination/core_1_subcore_coordination_plan_2026-01-01-233240-pst.md` - Latest coordination plan
- `docs/agent-communications/aurora_2_subcore_documentation_setup_prompt_2026-01-02-000032-pst.md` - Documentation setup
- `docs/agent-communications/aurora_2_subcore_timestamp_specification_2026-01-02-001956-pst.md` - Timestamp specification

**Supporting Documents**:
- `docs/agent-communications/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md` - Glow G2 voice
- `docs/grain_style.md` - Grain Style guidelines
- `docs/core-coordination/aurora_2_subcore_coordination.md` - Aurora 2 Subcore coordination

---

## Summary

**Total Agents**: 12 L1 agents + 12 L2 sub-agents = **24 total agents/sub-agents**

**L1 Subcore Coordinators**: 3 (Core 1, Aurora 2, Vantage 3)  
**L1 Standalone Agents**: 9 (Skate, Bubble, Carry, Silo, Workspace, Flow, Research, Court, Free)

**L2 Sub-Agents**:
- **Core 1 Subcore**: 5 (1a Auth, 1b Network, 1c Storage, 1d Compositor, 1e Grainscript Shell)
- **Aurora 2 Subcore**: 3 (2a Dream Editor, 2b Dream Browser, 2c Component Library) — **RECREATED IN FRAMEWORK SESSION**
- **Vantage 3 Subcore**: 4 (3a Basin Kernel, 3b VM Runtime, 3c System Integration, 3d sevenos Init System)

**Framework Session Focus**: Aurora 2 Subcore and all L2 sub-agents (2a, 2b, 2c) recreated in Framework session must:
- Use correct timestamp format (`yyyy-mm-dd-hhmmss-pst`)
- Follow Grain Style strictly
- Adopt Glow G2 voice
- Set up proper documentation structure (plan and tasks documents)

---

**Date**: 2026-01-02-002655-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Status**: ✅ **AGENT AWARENESS COMPLETE** — Ready for copy-paste distribution to Aurora 2 Subcore and all L2 sub-agents  
**Reference**: `docs/framework_16_agent_list_with_subagents_2026-01-01-205155-pst.md`

