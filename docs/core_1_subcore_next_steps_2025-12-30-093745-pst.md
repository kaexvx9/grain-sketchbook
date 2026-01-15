# Core 1 Subcore Sub-Agents: Next Steps & Path Links

**Date**: 2025-12-30-093745-pst  
**Purpose**: Summary of next steps for creating Core 1 Subcore sub-agents with all relevant path links

---

## Document Location

**Ready-to-Use Prompts**: `docs/core_1_subcore_sub_agent_prompts_ready_to_use_2025-12-30-093745-pst.md`

This document contains 4 complete, copy-pasteable prompts:
- **1a. Grain Auth Agent** (Authentication & Authorization)
- **1b. Grain Network Agent** (Network Services)
- **1c. Grain Storage Agent** (File System & Storage)
- **1d. Grain Compositor Agent** (Window Management & Compositing)

---

## Path Links

### Template & Reference Documents

- **Vantage Sub-Agent Template**: `docs/grain_vantage_sub_agent_creation_prompt.md`
- **Vantage Sub-Agent Prompts (Ready-to-Use)**: `docs/grain_vantage_sub_agent_prompts_ready_to_use.md`
- **Architecture Evolution Document**: `docs/zyx/grain_agent_architecture_evolution_2025-12-29-130647-pst.md`

### Core Agent Documents

- **Core Agent Plan**: `docs/plans/plan_core.md`
- **Core Agent Tasks**: `docs/tasks/tasks_core.md`
- **Core Agent Coordination**: `docs/core-coordination/core-coordination_core.md`
- **Core Agent Coordination Plan**: `docs/agent-communications/core_agent_coordination_plan_2025-12-30-093745-pst.md`

### Grain Style Reference

- **Grain Style Guide**: `docs/grain_style.md`
- **TigerStyle Reference**: https://github.com/tigerbeetle/tigerbeetle/blob/main/docs/TIGER_STYLE.md

### Code Locations

**Auth Service**:
- `src/grain_core/auth_service.zig`
- `src/grain_core/lock_screen.zig`
- `src/grain_core/middleware.zig` (auth middleware)

**Network Services**:
- `src/grain_core/network_stack.zig` (TCP/UDP sockets)
- `src/grain_core/http_client.zig` (HTTP client)
- `src/grain_core/websocket.zig` (WebSocket)
- `src/grain_core/dns_resolver.zig` (DNS)
- `src/grain_core/api_server.zig` (HTTP server)
- `src/grain_core/api_server_network.zig` (API server network layer)

**File Storage**:
- `src/grain_core/file_storage.zig` (file I/O, database file format)
- `src/grain_core/file_manager.zig` (file operations, directory management)
- `src/grain_core/backup_manager.zig` (backup and restore)
- `src/grain_core/index_manager.zig` (index management)
- `src/grain_core/wal_manager.zig` (transaction log management)

**Compositor**:
- `src/grain_core/compositor.zig` (main compositor)
- `src/grain_core/window_*.zig` (window management modules)
- `src/grain_core/desktop_shell.zig` (desktop shell)
- `src/grain_core/display_management.zig` (display management)
- `src/grain_core/input_handler.zig` (input handling)
- `src/grain_core/framebuffer_renderer.zig` (rendering)

---

## Next Steps

### Step 1: Create Core 1 Subcore Coordination Documents

If not already created, create these documents for Core 1 Subcore (L1 Subcore Coordinator):

1. **Coordination Document**: `docs/core-coordination/core_1_subcore_coordination.md`
   - Status, progress, blockers
   - Coordination with L2 sub-agents
   - Coordination with other full agents

2. **Plan Document**: `docs/plans/core_1_subcore_plan.md`
   - Implementation plan
   - Phase descriptions
   - Architecture decisions

3. **Tasks Document**: `docs/tasks/core_1_subcore_tasks.md`
   - Detailed task list
   - Task completion status
   - Task dependencies

**Note**: Core Agent (1st Agent) will become "Core 1 Subcore" (L1 Subcore Coordinator) when these sub-agents are created, similar to how Vantage Agent became "Vantage 3 Subcore".

### Step 2: Create Sub-Agent Prompts in Cursor Interface

For each of the 4 sub-agents:

1. **Open the ready-to-use prompts document**: `docs/core_1_subcore_sub_agent_prompts_ready_to_use_2025-12-30-093745-pst.md`

2. **Copy the entire prompt** for each agent:
   - **1a. Grain Auth Agent** — Copy from "PROMPT 1: Grain Auth Agent (1a)" section
   - **1b. Grain Network Agent** — Copy from "PROMPT 2: Grain Network Agent (1b)" section
   - **1c. Grain Storage Agent** — Copy from "PROMPT 3: Grain Storage Agent (1c)" section
   - **1d. Grain Compositor Agent** — Copy from "PROMPT 4: Grain Compositor Agent (1d)" section

3. **Create new agents in Cursor interface agent panel**:
   - Create 4 new agents
   - Assign numeric indices: **1a**, **1b**, **1c**, **1d**
   - Paste the corresponding prompt as the initial prompt for each agent

### Step 3: Update General Plan and Tasks

Update the general plan and tasks documents to reflect the new Core 1 Subcore structure:

1. **Update `docs/plan.md`**:
   - Change "Grain Core Agent (1st Agent)" to "Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)"
   - Add sections for the 4 L2 sub-agents:
     - 1a. Grain Auth Agent (L2 Sub-Agent)
     - 1b. Grain Network Agent (L2 Sub-Agent)
     - 1c. Grain Storage Agent (L2 Sub-Agent)
     - 1d. Grain Compositor Agent (L2 Sub-Agent)
   - Update agent status summaries

2. **Update `docs/tasks.md`**:
   - Change "Grain Core Agent" to "Grain Core 1 Subcore Agent"
   - Add task sections for the 4 L2 sub-agents
   - Update task summaries

### Step 4: Run Recursion Cycle

After creating the sub-agents and updating documentation:

1. **Have all agents update their status**:
   - All 12 L1 agents + 3 Vantage L2 sub-agents + 4 Core L2 sub-agents = 19 total agents/sub-agents
   - Each agent updates their coordination document

2. **Core Agent creates new coordination plan**:
   - Check all agent statuses and core-coordination docs, plans, and tasks
   - Create new coordination plan: `docs/agent-communications/core_agent_coordination_plan_{timestamp}.md`
   - Create new coordination summary: `docs/agent-communications/core_agent_coordination_summary_{timestamp}.md`

3. **Git commit and push**:
   - Check `git diff`
   - `git add -A`
   - `git commit -m "Grain Style: Core 1 Subcore + 4 L2 sub-agents created, coordination docs updated {timestamp}"`
   - `git push origin main`

4. **All agents adjust work**:
   - Each agent reads the new coordination plan
   - Each agent updates their plan and tasks documents
   - Each agent continues implementation following Grain Style

---

## Agent Numbering Summary

### L1 Agents (Full Agents)

1. **Grain Core 1 Subcore Agent** (System Services) — **L1 Subcore Coordinator**
2. **Grain Silo Agent** (Database)
3. **Grain Vantage 3 Subcore Agent** (VM/Kernel) — **L1 Subcore Coordinator**
4. **Grain Skate Agent** (Knowledge Graph)
5. **Grain Bubble Agent** (Design Tool)
6. **Grain Carry Agent** (Mobile Framework)
7. **Grain Aurora Agent** (IDE/Browser)
8. **Grain Workspace Agent** (Desktop Apps)
9. **Grain Flow Agent** (Workflow Orchestration)
10. **Grain Research Agent** (Research & Analysis)
11. **Grain Court Agent** (LLM Infrastructure)
12. **Grain Free Agent** (Creative Playground)

### L2 Sub-Agents (Under Core 1 Subcore)

- **1a. Grain Auth Agent** (Authentication & Authorization)
- **1b. Grain Network Agent** (Network Services)
- **1c. Grain Storage Agent** (File System & Storage)
- **1d. Grain Compositor Agent** (Window Management & Compositing)

### L2 Sub-Agents (Under Vantage 3 Subcore)

- **3a. Grain Basin Kernel Agent** (RISC-V kernel development)
- **3b. Grain VM Runtime Agent** (Vantage VM development tool)
- **3c. Grain System Integration Agent** (Kernel/VM integration, RISC-V compliance)

**Total**: 12 L1 agents + 7 L2 sub-agents = **19 total agents/sub-agents**

---

## Coordination Model

### L1 ↔ L2 Coordination (Core 1 Subcore ↔ Sub-Agents)

**Frequency**: Weekly or bi-weekly check-ins, as-needed for architecture decisions

**Coordination Pattern**:
- Core 1 Subcore reads all sub-agent coordination docs weekly/bi-weekly
- Sub-agents update their coordination docs after each work session
- Core 1 Subcore coordinates with other full agents (Vantage, Silo, etc.)
- Sub-agents coordinate with each other only when work intersects

### L2 ↔ L2 Coordination (Sub-Agent ↔ Sub-Agent)

**Frequency**: Minimal, as-needed only

**Coordination Pattern**:
- Auth Agent (1a) ↔ Network Agent (1b): Authentication middleware
- Auth Agent (1a) ↔ Storage Agent (1c): Secure credential storage
- Network Agent (1b) ↔ Storage Agent (1c): File upload/download
- Storage Agent (1c) ↔ Compositor Agent (1d): Workspace state persistence
- Most coordination goes through Core 1 Subcore

### L1 ↔ Other Agents (Core 1 Subcore ↔ Full Agents)

**Frequency**: Standard coordination patterns (as per Core Agent coordination plan)

**Coordination Pattern**:
- Core 1 Subcore ALONE coordinates with other full agents
- Sub-agents DO NOT coordinate directly with other full agents
- All external coordination goes through Core 1 Subcore

---

## Critical Notes

1. **RISC-V Only**: All Grain OS software (including all Core sub-agents) targets RISC-V only. No ARM64-specific code.

2. **Grain Style**: All code must follow Grain Style strictly:
   - `grain_case` function names
   - Explicit `u32`/`u64` types (never `usize`/`isize`)
   - Maximum 70 lines per function (`grain validate-70`)
   - Maximum 100 characters per line (`grainwrap-100`)
   - Minimum 2 assertions per function
   - Bounded allocations with `MAX_` constants
   - All compiler warnings enabled

3. **Documentation**: Each sub-agent maintains three documents:
   - Coordination: `docs/core-coordination/core_1{a,b,c,d}_{name}_coordination.md`
   - Plan: `docs/plans/core_1{a,b,c,d}_{name}_plan.md`
   - Tasks: `docs/tasks/core_1{a,b,c,d}_{name}_tasks.md`

4. **Coordination**: Sub-agents coordinate through Core 1 Subcore, not directly with other full agents.

---

## Summary

**Ready-to-Use Prompts**: `docs/core_1_subcore_sub_agent_prompts_ready_to_use_2025-12-30-093745-pst.md`

**Next Steps**:
1. Create Core 1 Subcore coordination documents (if not already created)
2. Copy-paste prompts from ready-to-use document into Cursor interface
3. Update general plan and tasks documents
4. Run recursion cycle with all agents

**Total Agents**: 12 L1 agents + 7 L2 sub-agents = **19 total agents/sub-agents**

---

**Date**: 2025-12-30-093745-pst  
**Document**: Core 1 Subcore Sub-Agents Next Steps & Path Links  
**Status**: Complete — Ready for Implementation
