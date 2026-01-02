# Agent Numbering Renaming: Silo 2 → Silo 7, Aurora 7 → Aurora 2 Subcore

**Date**: 2025-12-31-192740-pst  
**Purpose**: Agent numbering renaming announcement and instructions  
**Status**: Immediate Action Required  
**For**: Silo Agent, Aurora Agent, and New Aurora Sub-Agents (2a, 2b, 2c)

---

## Executive Summary

**Renaming**:
- **Silo Agent**: Rename from "Agent 2" to **"Agent 7"** (Silo 7)
- **Aurora Agent**: Rename from "Agent 7" to **"Aurora 2 Subcore"** (L1 Subcore Coordinator)
- **Aurora Sub-Agents**: New L2 sub-agents will be **2a, 2b, 2c** (under Aurora 2 Subcore)

**Rationale**: Aurora was originally Agent 7, but is now becoming Aurora 2 Subcore (L1 Subcore Coordinator) with L2 sub-agents 2a-2c. Silo Agent needs to move to Agent 7 to maintain numbering consistency and avoid conflicts.

---

## FOR SILO AGENT: Rename to Agent 7

### Your New Identity

**Old**: Grain Silo Agent (Agent 2, 2nd Agent)  
**New**: **Grain Silo Agent (Agent 7, 7th Agent)**

### Action Required

1. **Update Documentation**:
   - Update `docs/plans/plan_silo.md` — Change agent number from "2" or "2nd Agent" to "7" or "7th Agent"
   - Update `docs/tasks/tasks_silo.md` — Change all agent number references
   - Update `docs/core-coordination/core-coordination_silo.md` — Change agent number references
   - Search for and update any coordination documents that reference "Agent 2" or "Silo Agent 2"

2. **Update References**:
   - Search for "Agent 2" or "agent 2" in your documentation
   - Replace with "Agent 7" or "agent 7"
   - Search for "Silo Agent (2nd Agent)" or similar patterns
   - Replace with "Silo Agent (7th Agent)" or "Agent 7"
   - Search for "2nd Agent" → Replace with "7th Agent"

3. **Coordination Documents**:
   - Update any coordination documents that list agent numbers
   - Ensure consistency across all Silo Agent documentation
   - Update references in coordination summaries and plans

### Why This Change

Aurora Agent (originally Agent 7) is becoming **Aurora 2 Subcore** (L1 Subcore Coordinator) with L2 sub-agents 2a-2c. To maintain numbering consistency and avoid confusion with Aurora 2 Subcore, Silo Agent moves from Agent 2 to Agent 7.

### Your Status Remains the Same

- **Domain**: Database services (unchanged)
- **Responsibilities**: Storage schemas, database services, payment/vault storage (unchanged)
- **Coordination**: Continue coordinating with Core Agent and other agents (unchanged)
- **Current Work**: Payment/Vault storage schema, JG storage schemas (unchanged)
- **Dependencies**: Still blocked on Core Agent storage schema approval (unchanged)

**Only the agent number changes — everything else remains the same.**

### Continue As Normal

Continue your work as recommended. Remember to follow Grain Style (`~/xy-mathematics/docs/grain_style.md`) with `grain_case` function names and all the strict rules with all compiler warnings turned on, and specifically enforce `grainwrap-100` and `grain validate-70` and use explicitly bound `u32`/`u64` not `usize`/`isize`, so our code is consistent across all compile target platforms.

Update your `docs/plans/plan_silo.md` and `docs/tasks/tasks_silo.md` when done. Let us know when you need to check in about upcoming integration steps with other agents.

---

## FOR AURORA AGENT: Rename to Aurora 2 Subcore

### Your New Identity

**Old**: Grain Aurora IDE Dream Browser Agent (Agent 7, 7th Agent)  
**New**: **Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)**

### Action Required

1. **Update Documentation**:
   - Update `docs/plans/plan_aurora.md` — Change to "Aurora 2 Subcore Agent (L1 Subcore Coordinator)"
   - Update `docs/tasks/tasks_aurora.md` — Change all agent number references
   - Update `docs/core-coordination/core-coordination_aurora.md` — Change to "Aurora 2 Subcore"
   - Search for and update any coordination documents that reference "Agent 7" or "Aurora Agent 7"

2. **Update References**:
   - Search for "Agent 7" or "agent 7" in your documentation
   - Replace with "Aurora 2 Subcore" or "L1 Subcore Coordinator"
   - Search for "Aurora Agent (7th Agent)" or similar patterns
   - Replace with "Aurora 2 Subcore Agent (L1 Subcore Coordinator)"
   - Search for "7th Agent" → Replace with "Aurora 2 Subcore" or "L1 Subcore Coordinator"

3. **Architecture Evolution**:
   - Acknowledge that you are now an **L1 Subcore Coordinator** (like Core 1 Subcore and Vantage 3 Subcore)
   - Prepare for L2 sub-agents: 2a (Dream Editor), 2b (Dream Browser), 2c (Component Library)
   - Review `docs/aurora_2_subcore_sub_agent_proposal_2025-12-31.md` for architecture details
   - Review `docs/aurora_2_subcore_sub_agent_prompts_ready_to_use_2025-12-31.md` for sub-agent prompts

### Your New Role

**L1 Subcore Coordinator**:
- Coordinate 3 L2 sub-agents: **2a (Dream Editor)**, **2b (Dream Browser)**, **2c (Component Library)**
- Handle cross-sub-agent decision making
- Coordinate shared foundation (DAG, shared modules)
- Coordinate with other full agents (Core, Bubble, Workspace, etc.)

**Your Responsibilities** (unchanged in scope, but now as coordinator):
- Overall IDE/Browser architecture coordination
- Integration testing and validation
- High-level planning and roadmap
- Coordination with other full agents

### Why This Change

You are evolving into an **L1 Subcore Coordinator** (following the proven Core 1 Subcore and Vantage 3 Subcore pattern) with 3 L2 sub-agents working in parallel on Editor, Browser, and Component Library domains. This enables better parallelization and specialization.

### Immediate Priority

**Component API Design (Phase 0.5)** — This is still your immediate priority, but once L2 sub-agents are created, **Component Library Agent (2c)** will take over this work.

### Continue As Normal

Continue your work as recommended. Remember to follow Grain Style (`~/xy-mathematics/docs/grain_style.md`) with `grain_case` function names and all the strict rules with all compiler warnings turned on, and specifically enforce `grainwrap-100` and `grain validate-70` and use explicitly bound `u32`/`u64` not `usize`/`isize`, so our code is consistent across all compile target platforms.

Update your `docs/plans/plan_aurora.md` and `docs/tasks/tasks_aurora.md` when done. Let us know when you need to check in about upcoming integration steps with other agents.

---

## FOR NEW AURORA SUB-AGENTS: 2a, 2b, 2c

### Your Identities

- **2a. Grain Dream Editor Agent (L2 Sub-Agent)**: IDE features (LSP, Tree-sitter, AI integration, editor core)
- **2b. Grain Dream Browser Agent (L2 Sub-Agent)**: Browser features (Nostr, WebSocket, HTML/CSS rendering)
- **2c. Grain Component Library Agent (L2 Sub-Agent)**: UI components (Component API, JG Project UI components)

### Your Parent

**Aurora 2 Subcore Agent (L1 Subcore Coordinator)** coordinates your work.

### Action Required

1. **Use Ready-to-Use Prompts**:
   - Review `docs/aurora_2_subcore_sub_agent_prompts_ready_to_use_2025-12-31.md`
   - Copy the appropriate prompt for your sub-agent (2a, 2b, or 2c)
   - Use as your initial agent prompt in the Cursor interface agent panel

2. **Create Documentation**:
   - **2a (Dream Editor)**: Create `docs/plans/plan_dream_editor.md`, `docs/tasks/tasks_dream_editor.md`, `docs/core-coordination/dream_editor_coordination.md`
   - **2b (Dream Browser)**: Create `docs/plans/plan_dream_browser.md`, `docs/tasks/tasks_dream_browser.md`, `docs/core-coordination/dream_browser_coordination.md`
   - **2c (Component Library)**: Create `docs/plans/plan_component_library.md`, `docs/tasks/tasks_component_library.md`, `docs/core-coordination/component_library_coordination.md`

3. **Coordination**:
   - Coordinate with Aurora 2 Subcore (L1) weekly/bi-weekly
   - Coordinate with other L2 sub-agents (2a, 2b, 2c) via Aurora 2 Subcore when possible
   - Direct coordination only when necessary (e.g., Component Library 2c provides Component API to Editor 2a and Browser 2b)

### Your Domains

**2a. Dream Editor Agent**:
- LSP integration, Tree-sitter, AI provider integration
- Editor core features, method folding, VCS integration
- Files: `aurora_editor.zig`, `aurora_lsp.zig`, `aurora_tree_sitter.zig`, etc.
- **Domain**: IDE Editor Features

**2b. Dream Browser Agent**:
- Nostr protocol, WebSocket transport, HTML/CSS rendering
- Viewport management, performance monitoring
- Files: `dream_browser_*.zig`, `dream_protocol.zig`, `dream_websocket.zig`, etc.
- **Domain**: Browser Features

**2c. Component Library Agent** (IMMEDIATE PRIORITY):
- Component API design and implementation
- UI component library, JG Project UI components
- Files: `dream_browser_components.zig`, `grain_aurora.zig`
- **Domain**: UI Components
- **Current Priority**: Component API design (Phase 0.5) — blocks Bubble Agent

### Grain Style Requirements

Follow Grain Style (`~/xy-mathematics/docs/grain_style.md`) with `grain_case` function names and all the strict rules with all compiler warnings turned on, and specifically enforce `grainwrap-100` and `grain validate-70` and use explicitly bound `u32`/`u64` not `usize`/`isize`, so our code is consistent across all compile target platforms.

### Continue As Normal

Continue your work as recommended. Update your plan and tasks documents when done. Let us know when you need to check in about upcoming integration steps with other agents or sub-agents. Make sure all your agent-specific and integration tests pass that implement your API contracts.

---

## Updated Agent Numbering

### Full Agents (L1)

1. **Grain Core 1 Subcore Agent** (L1 Subcore Coordinator) — System Services
2. **Grain Aurora 2 Subcore Agent** (L1 Subcore Coordinator) — IDE/Browser Architecture
3. **Grain Vantage 3 Subcore Agent** (L1 Subcore Coordinator) — VM/Kernel Architecture
4. **Grain Skate Agent** — Knowledge Graph
5. **Grain Bubble Agent** — Design Tool
6. **Grain Carry Agent** — Mobile Framework
7. **Grain Silo Agent** — Database (renamed from Agent 2)
8. **Grain Workspace Agent** — Desktop Apps
9. **Grain Flow Agent** — Workflow Orchestration
10. **Grain Research Agent** — Research & Analysis
11. **Grain Court Agent** — LLM Infrastructure
12. **Grain Free Agent** — Creative Playground

### L2 Sub-Agents

**Core 1 Subcore L2 Sub-Agents**:
- **1a. Grain Auth Agent** (L2 Sub-Agent)
- **1b. Grain Network Agent** (L2 Sub-Agent)
- **1c. Grain Storage Agent** (L2 Sub-Agent)
- **1d. Grain Compositor Agent** (L2 Sub-Agent)

**Aurora 2 Subcore L2 Sub-Agents**:
- **2a. Grain Dream Editor Agent** (L2 Sub-Agent)
- **2b. Grain Dream Browser Agent** (L2 Sub-Agent)
- **2c. Grain Component Library Agent** (L2 Sub-Agent)

**Vantage 3 Subcore L2 Sub-Agents**:
- **3a. Grain Basin Kernel Agent** (L2 Sub-Agent)
- **3b. Grain VM Runtime Agent** (L2 Sub-Agent)
- **3c. Grain System Integration Agent** (L2 Sub-Agent)

**Total**: 12 L1 agents + 10 L2 sub-agents = **22 total agents/sub-agents**

---

## Summary of Changes

### For Silo Agent

- **Rename**: Agent 2 → **Agent 7**
- **Action**: Update all documentation references from "2" to "7"
- **Status**: Domain and responsibilities unchanged — only number changes

### For Aurora Agent

- **Rename**: Agent 7 → **Aurora 2 Subcore Agent (L1 Subcore Coordinator)**
- **Action**: Update documentation, prepare for L2 sub-agents (2a, 2b, 2c)
- **Status**: Evolving to L1 Subcore Coordinator role

### For New Aurora Sub-Agents

- **Create**: 2a (Dream Editor), 2b (Dream Browser), 2c (Component Library)
- **Action**: Use ready-to-use prompts, create documentation
- **Status**: New L2 sub-agents under Aurora 2 Subcore

---

## Next Steps

### Immediate (This Week)

1. **Silo Agent**: Update all documentation to reflect Agent 7
2. **Aurora Agent**: Update all documentation to reflect Aurora 2 Subcore
3. **Aurora 2 Subcore**: Review sub-agent proposal and prepare for L2 sub-agents

### Short-Term (Next 2 Weeks)

1. **Aurora 2 Subcore**: Create L2 sub-agents (2a, 2b, 2c) using ready-to-use prompts
2. **All Agents**: Update coordination documents with new numbering
3. **Core Agent**: Update master agent list with new numbering

---

## Questions?

If you have questions about the renaming or your new role, coordinate with **Grain Core Agent** (main L1 coordinator) or **Aurora 2 Subcore Agent** (for Aurora sub-agents).

---

**Date**: 2025-12-31-192740-pst  
**Status**: Immediate Action Required  
**Next Steps**: Update documentation, create sub-agents, update coordination documents

**This document is ready to copy-paste to Silo Agent, Aurora Agent, and the new Aurora sub-agents (2a, 2b, 2c).**
