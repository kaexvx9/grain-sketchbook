# Framework 16: Complete Agent List with Number Indices and Subagents

**Date**: 2026-01-01-205155-pst  
**Context**: Framework 16 (x86_64 AMD, 64GB RAM) running Ubuntu 24.04 LTS host  
**Purpose**: Complete reference for all 12 Grain OS agents with their number indices and L2 sub-agents for Framework Cursor workspace recreation

---

## Executive Summary

This document provides a complete, authoritative list of all 12 Grain OS agents with their number indices and L2 sub-agents. Use this document when recreating agents in the Framework 16 Cursor workspace.

**Total Agents**: 12 L1 agents + 10 L2 sub-agents = **22 total agents/sub-agents**

**L1 Subcore Coordinators**: 3 (Core 1, Aurora 2, Vantage 3)  
**L1 Standalone Agents**: 9 (Skate, Bubble, Carry, Silo, Workspace, Flow, Research, Court, Free)

---

## Complete Agent List

### L1 Agents (Full Agents)

#### 1. Grain Core 1 Subcore Agent
- **Number**: 1
- **Type**: L1 Subcore Coordinator
- **Responsibilities**: System services coordination, integration testing, architecture planning, coordination with other L1 agents
- **Code Location**: `src/grain_core/`
- **Coordination Doc**: `docs/core-coordination/core_1_subcore_coordination.md`
- **Plan Doc**: `docs/plans/core_1_subcore_plan.md`
- **Tasks Doc**: `docs/tasks/core_1_subcore_tasks.md`
- **L2 Sub-Agents**: 4 (1a, 1b, 1c, 1d)

#### 2. Grain Aurora 2 Subcore Agent
- **Number**: 2
- **Type**: L1 Subcore Coordinator
- **Responsibilities**: IDE/Browser architecture coordination, Dream Editor/Browser/Component Library integration
- **Code Location**: `src/dream_editor/`, `src/dream_browser/`, `src/dream_browser_components/`
- **Coordination Doc**: `docs/core-coordination/aurora_2_subcore_coordination.md`
- **Plan Doc**: `docs/plans/aurora_2_subcore_plan.md`
- **Tasks Doc**: `docs/tasks/aurora_2_subcore_tasks.md`
- **L2 Sub-Agents**: 3 (2a, 2b, 2c)

#### 3. Grain Vantage 3 Subcore Agent
- **Number**: 3
- **Type**: L1 Subcore Coordinator
- **Responsibilities**: VM/Kernel architecture coordination, Basin kernel/Vantage VM/System integration coordination
- **Code Location**: `src/kernel/`, `src/kernel_vm/`
- **Coordination Doc**: `docs/core-coordination/vantage_3_subcore_coordination.md`
- **Plan Doc**: `docs/plans/vantage_3_subcore_plan.md`
- **Tasks Doc**: `docs/tasks/vantage_3_subcore_tasks.md`
- **L2 Sub-Agents**: 3 (3a, 3b, 3c)

#### 4. Grain Skate Agent
- **Number**: 4
- **Type**: L1 Standalone Agent
- **Responsibilities**: Knowledge graph, graph operations, AI-powered insights
- **Code Location**: `src/grain_skate/`
- **Coordination Doc**: `docs/core-coordination/skate_agent_coordination.md`
- **Plan Doc**: `docs/plans/skate_agent_plan.md`
- **Tasks Doc**: `docs/tasks/skate_agent_tasks.md`
- **L2 Sub-Agents**: None

#### 5. Grain Bubble Agent
- **Number**: 5
- **Type**: L1 Standalone Agent
- **Responsibilities**: Design tool, UI components, visual design, JG Project UI integration
- **Code Location**: `src/grain_bubble/`
- **Coordination Doc**: `docs/core-coordination/bubble_agent_coordination.md`
- **Plan Doc**: `docs/plans/bubble_agent_plan.md`
- **Tasks Doc**: `docs/tasks/bubble_agent_tasks.md`
- **L2 Sub-Agents**: None

#### 6. Grain Carry Agent
- **Number**: 6
- **Type**: L1 Standalone Agent
- **Responsibilities**: Mobile framework, iOS/Android support, mobile apps
- **Code Location**: `src/grain_carry/`
- **Coordination Doc**: `docs/core-coordination/carry_agent_coordination.md`
- **Plan Doc**: `docs/plans/carry_agent_plan.md`
- **Tasks Doc**: `docs/tasks/carry_agent_tasks.md`
- **L2 Sub-Agents**: None

#### 7. Grain Silo Agent
- **Number**: 7
- **Type**: L1 Standalone Agent
- **Responsibilities**: Database, storage, SLC product integration, PasswordStorage helper implementation
- **Code Location**: `src/grain_silo/`
- **Coordination Doc**: `docs/core-coordination/silo_agent_coordination.md`
- **Plan Doc**: `docs/plans/silo_agent_plan.md`
- **Tasks Doc**: `docs/tasks/silo_agent_tasks.md`
- **L2 Sub-Agents**: None
- **Note**: Renamed from Agent 2 to Agent 7 (2025-12-31-192740-pst)

#### 8. Grain Workspace Agent
- **Number**: 8
- **Type**: L1 Standalone Agent
- **Responsibilities**: Desktop apps, application management
- **Code Location**: `src/grain_workspace/`
- **Coordination Doc**: `docs/core-coordination/workspace_agent_coordination.md`
- **Plan Doc**: `docs/plans/workspace_agent_plan.md`
- **Tasks Doc**: `docs/tasks/workspace_agent_tasks.md`
- **L2 Sub-Agents**: None

#### 9. Grain Flow Agent
- **Number**: 9
- **Type**: L1 Standalone Agent
- **Responsibilities**: Workflow orchestration, process management
- **Code Location**: `src/grain_flow/`
- **Coordination Doc**: `docs/core-coordination/flow_agent_coordination.md`
- **Plan Doc**: `docs/plans/flow_agent_plan.md`
- **Tasks Doc**: `docs/tasks/flow_agent_tasks.md`
- **L2 Sub-Agents**: None

#### 10. Grain Research Agent
- **Number**: 10
- **Type**: L1 Standalone Agent
- **Responsibilities**: Research & analysis, validation testing, code quality
- **Code Location**: `src/grain_research/`
- **Coordination Doc**: `docs/core-coordination/research_agent_coordination.md`
- **Plan Doc**: `docs/plans/research_agent_plan.md`
- **Tasks Doc**: `docs/tasks/research_agent_tasks.md`
- **L2 Sub-Agents**: None

#### 11. Grain Court Agent
- **Number**: 11
- **Type**: L1 Standalone Agent
- **Responsibilities**: LLM infrastructure, payment integration, legal/compliance
- **Code Location**: `src/grain_court/`
- **Coordination Doc**: `docs/core-coordination/court_agent_coordination.md`
- **Plan Doc**: `docs/plans/court_agent_plan.md`
- **Tasks Doc**: `docs/tasks/court_agent_tasks.md`
- **L2 Sub-Agents**: None

#### 12. Grain Free Agent
- **Number**: 12
- **Type**: L1 Standalone Agent
- **Responsibilities**: Creative playground, experimental features, optional coordination
- **Code Location**: `src/grain_free/`
- **Coordination Doc**: `docs/core-coordination/free_agent_coordination.md`
- **Plan Doc**: `docs/plans/free_agent_plan.md`
- **Tasks Doc**: `docs/tasks/free_agent_tasks.md`
- **L2 Sub-Agents**: None

---

## L2 Sub-Agents

### Core 1 Subcore L2 Sub-Agents

#### 1a. Grain Auth Agent
- **Number**: 1a
- **Parent**: Core 1 Subcore Agent (1)
- **Type**: L2 Sub-Agent
- **Responsibilities**: Authentication and authorization services, RBAC, middleware integration
- **Code Location**: `src/grain_core/auth_service.zig`, `src/grain_core/lock_screen.zig`
- **Coordination Doc**: `docs/core-coordination/core_1a_auth_coordination.md`
- **Plan Doc**: `docs/plans/core_1a_auth_plan.md`
- **Tasks Doc**: `docs/tasks/core_1a_auth_tasks.md`
- **Status**: ✅ 6 PHASES COMPLETE — Production Ready — Middleware Integration READY

#### 1b. Grain Network Agent
- **Number**: 1b
- **Parent**: Core 1 Subcore Agent (1)
- **Type**: L2 Sub-Agent
- **Responsibilities**: Network services (HTTP, WebSocket, DNS, TCP/UDP), file transfer integration
- **Code Location**: `src/grain_core/network/`
- **Coordination Doc**: `docs/core-coordination/core_1b_network_coordination.md`
- **Plan Doc**: `docs/plans/core_1b_network_plan.md`
- **Tasks Doc**: `docs/tasks/core_1b_network_tasks.md`
- **Status**: ✅ PHASES 1-4 COMPLETE — Storage Integration 100% Complete — Ready for Auth Coordination

#### 1c. Grain Storage Agent
- **Number**: 1c
- **Parent**: Core 1 Subcore Agent (1)
- **Type**: L2 Sub-Agent
- **Responsibilities**: File system and storage services, file transfer management
- **Code Location**: `src/grain_core/storage/`
- **Coordination Doc**: `docs/core-coordination/core_1c_storage_coordination.md`
- **Plan Doc**: `docs/plans/core_1c_storage_plan.md`
- **Tasks Doc**: `docs/tasks/core_1c_storage_tasks.md`
- **Status**: ✅ ALL CORE IMPLEMENTATION COMPLETE — Network Integration 95% Complete

#### 1d. Grain Compositor Agent
- **Number**: 1d
- **Parent**: Core 1 Subcore Agent (1)
- **Type**: L2 Sub-Agent
- **Responsibilities**: Window management and compositing, Wayland protocol, tiling
- **Code Location**: `src/grain_core/compositor/`
- **Coordination Doc**: `docs/core-coordination/core_1d_compositor_coordination.md`
- **Plan Doc**: `docs/plans/core_1d_compositor_plan.md`
- **Tasks Doc**: `docs/tasks/core_1d_compositor_tasks.md`
- **Status**: ✅ PHASES 1-6, 8 PREVIEW COMPLETE — Phase 7 Ready (awaiting Storage coordination)

---

### Aurora 2 Subcore L2 Sub-Agents

#### 2a. Grain Dream Editor Agent
- **Number**: 2a
- **Parent**: Aurora 2 Subcore Agent (2)
- **Type**: L2 Sub-Agent
- **Responsibilities**: Dream Editor (IDE features, LSP, Tree-sitter, AI integration)
- **Code Location**: `src/dream_editor/`
- **Coordination Doc**: `docs/core-coordination/aurora_2a_dream_editor_coordination.md`
- **Plan Doc**: `docs/plans/aurora_2a_dream_editor_plan.md`
- **Tasks Doc**: `docs/tasks/aurora_2a_dream_editor_tasks.md`
- **Status**: 🆕 INITIALIZED — Architecture evolution complete

#### 2b. Grain Dream Browser Agent
- **Number**: 2b
- **Parent**: Aurora 2 Subcore Agent (2)
- **Type**: L2 Sub-Agent
- **Responsibilities**: Dream Browser (Web browser features, Nostr, WebSocket, HTML/CSS)
- **Code Location**: `src/dream_browser/`, `src/dream_browser_components/`
- **Coordination Doc**: `docs/core-coordination/aurora_2b_dream_browser_coordination.md`
- **Plan Doc**: `docs/plans/aurora_2b_dream_browser_plan.md`
- **Tasks Doc**: `docs/tasks/aurora_2b_dream_browser_tasks.md`
- **Status**: 🆕 INITIALIZED — Architecture evolution complete

#### 2c. Grain Component Library Agent
- **Number**: 2c
- **Parent**: Aurora 2 Subcore Agent (2)
- **Type**: L2 Sub-Agent
- **Responsibilities**: Component Library (Rich UI components, design system)
- **Code Location**: `src/dream_browser_components/`
- **Coordination Doc**: `docs/core-coordination/aurora_2c_component_library_coordination.md`
- **Plan Doc**: `docs/plans/aurora_2c_component_library_plan.md`
- **Tasks Doc**: `docs/tasks/aurora_2c_component_library_tasks.md`
- **Status**: 🆕 INITIALIZED — Architecture evolution complete

---

### Vantage 3 Subcore L2 Sub-Agents

#### 3a. Grain Basin Kernel Agent
- **Number**: 3a
- **Parent**: Vantage 3 Subcore Agent (3)
- **Type**: L2 Sub-Agent
- **Responsibilities**: RISC-V kernel development, Basin kernel syscalls, kernel features
- **Code Location**: `src/kernel/`
- **Coordination Doc**: `docs/core-coordination/vantage_3a_basin_kernel_coordination.md`
- **Plan Doc**: `docs/plans/vantage_3a_basin_kernel_plan.md`
- **Tasks Doc**: `docs/tasks/vantage_3a_basin_kernel_tasks.md`
- **Status**: ✅ ALL KERNEL FEATURES COMPLETE — RISC-V only (runs in VM)

#### 3b. Grain VM Runtime Agent
- **Number**: 3b
- **Parent**: Vantage 3 Subcore Agent (3)
- **Type**: L2 Sub-Agent
- **Responsibilities**: Vantage VM development tool, RISC-V to ARM64 JIT, RISC-V to x86_64 JIT (Framework AMD, Intel x86_64, NixOS)
- **Code Location**: `src/kernel_vm/`
- **Coordination Doc**: `docs/core-coordination/vantage_3b_vm_runtime_coordination.md`
- **Plan Doc**: `docs/plans/vantage_3b_vm_runtime_plan.md`
- **Tasks Doc**: `docs/tasks/vantage_3b_vm_runtime_tasks.md`
- **Status**: ✅ VM RUNTIME COMPLETE — RISC-V to ARM64 JIT working, RISC-V to x86_64 JIT in progress

#### 3c. Grain System Integration Agent
- **Number**: 3c
- **Parent**: Vantage 3 Subcore Agent (3)
- **Type**: L2 Sub-Agent
- **Responsibilities**: Kernel/VM integration, RISC-V compliance, multi-architecture testing
- **Code Location**: `src/kernel_vm/integration.zig`
- **Coordination Doc**: `docs/core-coordination/vantage_3c_system_integration_coordination.md`
- **Plan Doc**: `docs/plans/vantage_3c_system_integration_plan.md`
- **Tasks Doc**: `docs/tasks/vantage_3c_system_integration_tasks.md`
- **Status**: ✅ INTEGRATION COMPLETE — Multi-architecture testing framework in progress

---

## Agent Hierarchy Summary

### L1 Subcore Coordinators (3)

1. **Core 1 Subcore Agent** (System Services)
   - L2 Sub-Agents: 1a (Auth), 1b (Network), 1c (Storage), 1d (Compositor)

2. **Aurora 2 Subcore Agent** (IDE/Browser)
   - L2 Sub-Agents: 2a (Dream Editor), 2b (Dream Browser), 2c (Component Library)

3. **Vantage 3 Subcore Agent** (VM/Kernel)
   - L2 Sub-Agents: 3a (Basin Kernel), 3b (VM Runtime), 3c (System Integration)

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

## Framework 16 Recreation Checklist

### For Each Agent

- [ ] **Agent Number**: Verify correct number (1-12)
- [ ] **Agent Type**: L1 Subcore Coordinator, L1 Standalone, or L2 Sub-Agent
- [ ] **Parent Agent**: If L2, identify parent L1 agent
- [ ] **Code Location**: Verify code directory exists
- [ ] **Coordination Doc**: Create/verify coordination document
- [ ] **Plan Doc**: Create/verify plan document
- [ ] **Tasks Doc**: Create/verify tasks document
- [ ] **Prompt File**: Create/verify agent prompt file (if exists)

### For L1 Subcore Coordinators

- [ ] **L2 Sub-Agents**: List all L2 sub-agents
- [ ] **Coordination Model**: Establish L1/L2 coordination pattern
- [ ] **Integration Testing**: Plan integration testing for L2 sub-agents

### For L2 Sub-Agents

- [ ] **Parent Agent**: Identify parent L1 Subcore Coordinator
- [ ] **Coordination Pattern**: Understand L1/L2 coordination model
- [ ] **Domain Isolation**: Verify domain-specific work isolation

---

## Agent Numbering Reference

### Quick Reference Table

| Number | Agent Name | Type | L2 Sub-Agents |
|--------|------------|------|---------------|
| 1 | Core 1 Subcore | L1 Subcore | 1a, 1b, 1c, 1d |
| 2 | Aurora 2 Subcore | L1 Subcore | 2a, 2b, 2c |
| 3 | Vantage 3 Subcore | L1 Subcore | 3a, 3b, 3c |
| 4 | Skate | L1 Standalone | None |
| 5 | Bubble | L1 Standalone | None |
| 6 | Carry | L1 Standalone | None |
| 7 | Silo | L1 Standalone | None |
| 8 | Workspace | L1 Standalone | None |
| 9 | Flow | L1 Standalone | None |
| 10 | Research | L1 Standalone | None |
| 11 | Court | L1 Standalone | None |
| 12 | Free | L1 Standalone | None |

---

## Documentation Structure

### Standard Documentation Files

Each agent should have:
- **Coordination Doc**: `docs/core-coordination/{agent}_coordination.md`
- **Plan Doc**: `docs/plans/{agent}_plan.md`
- **Tasks Doc**: `docs/tasks/{agent}_tasks.md`
- **Prompt File**: `docs/grain_{agent}_prompt.md` (if exists)

### L2 Sub-Agent Documentation

L2 sub-agents follow the same structure with parent prefix:
- **Coordination Doc**: `docs/core-coordination/{parent}_{subagent}_coordination.md`
- **Plan Doc**: `docs/plans/{parent}_{subagent}_plan.md`
- **Tasks Doc**: `docs/tasks/{parent}_{subagent}_tasks.md`

---

## Coordination Patterns

### L1 ↔ L2 Coordination (Subcore ↔ Sub-Agents)

**Pattern**: Parallel work with structured coordination points

- **L1 Subcore** coordinates L2 sub-agents
- **L2 Sub-Agents** work in parallel on isolated domains
- **Weekly/bi-weekly check-ins** for coordination
- **As-needed coordination** for architecture decisions

### L1 ↔ L1 Coordination (Full Agents)

**Pattern**: Standard coordination through Core 1 Subcore

- **Core 1 Subcore** coordinates with other L1 agents
- **L1 Standalone Agents** coordinate through Core 1 Subcore
- **L1 Subcore Coordinators** coordinate with each other through Core 1 Subcore

### L2 ↔ L2 Coordination (Sub-Agent ↔ Sub-Agent)

**Pattern**: Minimal, as-needed only

- **Same Parent**: Coordinate through parent L1 Subcore
- **Different Parents**: Coordinate through Core 1 Subcore
- **Direct Coordination**: Document in coordination docs

---

## Framework 16 Specific Considerations

### Environment

- **Host OS**: Ubuntu 24.04 LTS
- **VM**: NixOS 25.11 minimal Linux kernel 6.18.2 VM (via QEMU/KVM)
- **Workspace**: Framework 16 Cursor workspace
- **Repository**: `xy-mathematics` (cloned in Framework workspace)

### Paths

- **Code**: `~/xy-mathematics/src/{agent}/`
- **Coordination**: `~/xy-mathematics/docs/core-coordination/`
- **Plans**: `~/xy-mathematics/docs/plans/`
- **Tasks**: `~/xy-mathematics/docs/tasks/`
- **Prompts**: `~/xy-mathematics/docs/grain_{agent}_prompt.md`

### Timestamp Format

**Format**: `yyyy-mm-dd-hhmmss-pst` (America/Los_Angeles)

**Command**:
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

---

## Summary

**Total Agents**: 12 L1 agents + 10 L2 sub-agents = **22 total agents/sub-agents**

**L1 Subcore Coordinators**: 3 (Core 1, Aurora 2, Vantage 3)  
**L1 Standalone Agents**: 9 (Skate, Bubble, Carry, Silo, Workspace, Flow, Research, Court, Free)

**L2 Sub-Agents**:
- **Core 1 Subcore**: 4 (1a Auth, 1b Network, 1c Storage, 1d Compositor)
- **Aurora 2 Subcore**: 3 (2a Dream Editor, 2b Dream Browser, 2c Component Library)
- **Vantage 3 Subcore**: 3 (3a Basin Kernel, 3b VM Runtime, 3c System Integration)

**Use this document** when recreating agents in the Framework 16 Cursor workspace to ensure correct numbering, hierarchy, and documentation structure.

---

**Date**: 2026-01-01-205155-pst  
**Status**: ✅ **COMPLETE** — Ready for Framework 16 Cursor workspace recreation  
**Next Steps**: Use this document as reference when setting up agents in Framework workspace
