# Core Coordination: Grain Aurora 2 Subcore Agent

**Last Updated**: 2025-12-31-220825-pst  
**Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Status**: 🆕 **ARCHITECTURE EVOLUTION IN PROGRESS** — Aurora 2 Subcore (L1 Subcore) with 3 L2 Sub-Agents

---

## Executive Summary

**Agent Status**: 🆕 **ARCHITECTURE EVOLUTION IN PROGRESS** — Aurora 2 Subcore (L1 Subcore) with 3 L2 Sub-Agents

**Architecture Evolution**: 🆕 **L1 Subcore/L2 Sub-Agent Pattern** (2025-12-31-192740-pst)
- **Aurora 2 Subcore (L1 Subcore Coordinator)**: Overall IDE/Browser architecture coordination
- **2a. Grain Dream Editor Agent (L2)**: IDE features (LSP, Tree-sitter, AI integration, editor core)
- **2b. Grain Dream Browser Agent (L2)**: Browser features (Nostr, WebSocket, HTML/CSS rendering)
- **2c. Grain Component Library Agent (L2)**: UI components (Component API, JG Project UI components)

**Coordination Model**: **Parallel Work with Structured Coordination Points**
- Aurora 2 Subcore and L2 sub-agents work **in parallel** (not alternating)
- Weekly/bi-weekly check-ins for coordination
- As-needed coordination for architecture decisions

---

## Coordination Model: Subcore vs. Main Core Coordination

**Aurora 2 Subcore Agent** serves as the **L1 Subcore Coordinator** for IDE/Browser architecture coordination, distinct from the main outer primary L1 core coordination handled by the **Grain Core Agent** (which coordinates all L1 agents).

### Subcore Coordination / IDE/Browser Architecture (Aurora 2 Subcore)
- **Scope**: IDE/Browser architecture coordination, Editor/Browser/Component integration
- **Responsibility**: Coordinate L2 sub-agents (2a Dream Editor, 2b Dream Browser, 2c Component Library)
- **Focus**: Architecture-level integration within the IDE/Browser domain (editor, browser, components)
- **Coordination Pattern**: Aurora 2 Subcore ↔ L2 Sub-Agents (weekly/bi-weekly check-ins, architecture decisions)

### Main Outer Primary L1 Core Coordination (Grain Core Agent)
- **Scope**: Overall Grain OS architecture, cross-agent coordination, high-level system decisions
- **Responsibility**: Coordinate all L1 agents (Aurora 2 Subcore, Skate, Workspace, Bubble, Carry, Silo, Vantage 3 Subcore, Core 1 Subcore, etc.)
- **Focus**: Cross-domain integration, system-wide architecture, project-level coordination
- **Coordination Pattern**: Grain Core Agent ↔ Aurora 2 Subcore (as needed for IDE/Browser services, architecture decisions)

**Key Distinction**: Aurora 2 Subcore handles **subcore coordination** (internal to IDE/Browser domain), while Grain Core Agent handles **main outer primary L1 core coordination** (across all domains). Aurora 2 Subcore coordinates with Grain Core Agent when IDE/Browser decisions affect other agents or require system-wide coordination.

---

## Parallel Work Model: Aurora 2 Subcore + L2 Sub-Agents

### Primary Mode: Parallel Work (Not Alternating)

**Aurora 2 Subcore (L1) and L2 sub-agents work in parallel** to maximize parallelization and development velocity.

### Aurora 2 Subcore Can Work On (While Sub-Agents Work):

1. **Integration Testing and Validation**:
   - Integration testing across Editor + Browser + Components
   - End-to-end IDE/Browser testing
   - Performance analysis across sub-agents
   - Cross-sub-agent validation

2. **Architecture Planning and Documentation**:
   - Overall IDE/Browser architecture
   - Cross-sub-agent API design
   - Integration patterns and best practices
   - Architecture decision records

3. **Coordination with Other Full Agents**:
   - Coordinate with Core Agent on HTTP/WebSocket clients, authentication
   - Coordinate with Bubble Agent on design patterns
   - Coordinate with Workspace Agent on desktop dashboards
   - Coordinate with Carry Agent on mobile UI components
   - System-wide architecture decisions

4. **Cross-Sub-Agent Decision Making**:
   - Component API contracts (2c → 2a, 2b)
   - Shared resource management (DAG, text buffer)
   - Integration patterns
   - Performance optimization across domains

5. **Shared Foundation Coordination**:
   - DAG integration (`src/dag_core.zig`)
   - Text buffer (`src/grain_buffer.zig`)
   - Shared modules (`src/shared/`)
   - Ensure consistency across sub-agents

6. **System-Wide Planning**:
   - Roadmap planning
   - Priority coordination
   - Resource allocation
   - Timeline management

### L2 Sub-Agents Can Work On (While Aurora 2 Subcore Works):

1. **Domain-Specific Implementation**:
   - Dream Editor Agent (2a): LSP, Tree-sitter, AI integration, editor core
   - Dream Browser Agent (2b): Nostr, WebSocket, HTML/CSS rendering
   - Component Library Agent (2c): Component API, UI components, JG Project UI

2. **Feature Development**:
   - New features within their domain
   - Performance optimization
   - Security hardening
   - Testing and validation

3. **Documentation Updates**:
   - Domain-specific documentation
   - API documentation
   - Usage examples
   - Test documentation

---

## L2 Sub-Agent Status

### 2a. Grain Dream Editor Agent (L2 Sub-Agent)

**Status**: 🆕 **TO BE CREATED**  
**Domain**: IDE Editor Features  
**Key Files**: `src/aurora_editor.zig`, `src/aurora_lsp.zig`, `src/aurora_tree_sitter.zig`, etc.  
**Coordination**: Weekly/bi-weekly with Aurora 2 Subcore

**Responsibilities**:
- LSP (Language Server Protocol) integration
- Tree-sitter parsing and syntax highlighting
- AI provider integration (GLM-4.6)
- Editor core features (text buffer, cursor, selection)
- Method folding and code structure
- Magit-style VCS integration

### 2b. Grain Dream Browser Agent (L2 Sub-Agent)

**Status**: 🆕 **TO BE CREATED**  
**Domain**: Browser Features  
**Key Files**: `src/dream_browser_*.zig`, `src/dream_protocol.zig`, `src/dream_websocket.zig`, etc.  
**Coordination**: Weekly/bi-weekly with Aurora 2 Subcore

**Responsibilities**:
- Nostr protocol integration
- WebSocket transport and real-time communication
- HTML/CSS parsing and rendering
- Viewport management and scrolling
- Performance monitoring and profiling
- Bookmarks and navigation

### 2c. Grain Component Library Agent (L2 Sub-Agent)

**Status**: 🆕 **TO BE CREATED** — **IMMEDIATE PRIORITY**  
**Domain**: UI Components  
**Key Files**: `src/dream_browser_components.zig`, `src/grain_aurora.zig`  
**Coordination**: Weekly/bi-weekly with Aurora 2 Subcore

**Responsibilities**:
- Component API design and implementation (Phase 0.5) — **IMMEDIATE**
- UI component library (buttons, forms, layouts, etc.)
- JG Project UI components (3D visualization, dashboards, mobile UI) — Months 7-12
- UI rendering system
- Component lifecycle and state management
- Integration with Editor (2a) and Browser (2b)

**Current Priority**: Component API design (Phase 0.5) — **BLOCKS Bubble Agent**

---

## Coordination Frequency

### L1 ↔ L2 Coordination

**Aurora 2 Subcore ↔ L2 Sub-Agents**:
- **Weekly/Bi-weekly**: Status updates, architecture decisions, integration checkpoints
- **As-needed**: Breaking changes, cross-sub-agent dependencies, critical bugs

**Example Coordination Points**:
- Component API changes (2c) affecting Editor UI (2a) or Browser UI (2b)
- Shared DAG integration decisions
- Shared module refactoring (text buffer, font renderer)
- Integration testing across Editor + Browser + Components

### L2 ↔ L2 Coordination

**L2 Sub-Agent ↔ L2 Sub-Agent**:
- **Minimal**: Sub-agents coordinate directly only when necessary
- **Via L1**: Most coordination goes through Aurora 2 Subcore to reduce overhead

**Example Direct Coordination**:
- Component Library Agent (2c) provides Component API to Editor Agent (2a) and Browser Agent (2b)
- Editor Agent (2a) and Browser Agent (2b) use Component API from Component Library Agent (2c)

### L1 ↔ Other Agents

**Aurora 2 Subcore ↔ Other Full Agents**:
- **Standard**: Aurora 2 Subcore coordinates with other full agents using existing coordination patterns
- **Frequency**: As defined in current coordination plans

**Example Coordination**:
- Component Library Agent (2c) coordinates with Bubble Agent (for design patterns)
- Component Library Agent (2c) coordinates with Workspace Agent (for desktop dashboards)
- Component Library Agent (2c) coordinates with Carry Agent (for mobile UI components)
- Aurora 2 Subcore coordinates with Core Agent (for HTTP/WebSocket clients, authentication)

---

## Shared Foundation Coordination

### Shared Files (Coordinated by Aurora 2 Subcore)

1. **DAG Integration** (`src/dag_core.zig`):
   - Shared across all L2 sub-agents
   - Aurora 2 Subcore coordinates DAG integration decisions
   - L2 sub-agents use DAG via Aurora 2 Subcore coordination

2. **Text Buffer** (`src/grain_buffer.zig`):
   - Shared between Dream Editor Agent (2a) and Component Library Agent (2c)
   - Aurora 2 Subcore coordinates text buffer changes
   - L2 sub-agents coordinate via Aurora 2 Subcore

3. **Shared Modules** (`src/shared/`):
   - Font renderer, shared utilities
   - Aurora 2 Subcore coordinates shared module changes
   - L2 sub-agents use shared modules via Aurora 2 Subcore coordination

### Coordination Protocol

**For Shared Files**:
1. L2 sub-agent identifies need for shared file change
2. L2 sub-agent coordinates with Aurora 2 Subcore
3. Aurora 2 Subcore coordinates with affected L2 sub-agents
4. Aurora 2 Subcore approves and implements change
5. All L2 sub-agents update to use new shared file version

---

## Current Status

### Architecture Evolution

**Status**: 🆕 **IN PROGRESS** (2025-12-31-192740-pst)
- ✅ Architecture evolution proposal reviewed
- ✅ Coordination document created
- ⏳ L2 sub-agents to be created
- ⏳ Coordination structure to be established

### Completed Work

- ✅ All Core Agent coordination decisions integrated
- ✅ Component API implemented and tested
- ✅ Error types refined
- ✅ JG requirements summary complete
- ✅ Phase 0.5 (Component API design) complete — unblocks Bubble Agent

### Immediate Priorities

1. **Create L2 Sub-Agents** (This Week):
   - 2a. Dream Editor Agent
   - 2b. Dream Browser Agent
   - 2c. Component Library Agent (IMMEDIATE PRIORITY — Phase 0.5)

2. **Establish Coordination** (This Week):
   - Weekly/bi-weekly check-in schedule
   - Clear ownership boundaries
   - Shared foundation coordination protocol

3. **Update Documentation** (This Week):
   - Update plans and tasks documents
   - Create L2 sub-agent coordination documents
   - Update coordination references

---

## Next Steps

### Immediate (This Week)

1. **Create L2 Sub-Agents**:
   - Use ready-to-use prompts from `docs/aurora_2_subcore_sub_agent_prompts_ready_to_use_2025-12-31.md`
   - Create coordination documents for each L2 sub-agent
   - Establish weekly/bi-weekly check-in schedule

2. **Establish Coordination Structure**:
   - Define coordination protocols
   - Create shared foundation coordination process
   - Set up integration testing framework

3. **Update Documentation**:
   - Update `docs/plans/plan_aurora.md` → `docs/plans/plan_aurora_2_subcore.md`
   - Update `docs/tasks/tasks_aurora.md` → `docs/tasks/tasks_aurora_2_subcore.md`
   - Create L2 sub-agent plan and tasks documents

### Short-Term (Next 2 Weeks)

1. **Begin Parallel Work**:
   - L2 sub-agents begin domain-specific work
   - Aurora 2 Subcore begins integration testing and architecture planning
   - Establish regular coordination rhythm

2. **Component Library Agent Priority**:
   - Component Library Agent (2c) completes Component API design (Phase 0.5)
   - Unblocks Bubble Agent for Phase 5 work

---

## Coordination Documents

- **Aurora 2 Subcore Coordination**: `docs/core-coordination/aurora_2_subcore_coordination.md` (this document)
- **Aurora 2 Subcore Plan**: `docs/plans/plan_aurora_2_subcore.md` (to be created)
- **Aurora 2 Subcore Tasks**: `docs/tasks/tasks_aurora_2_subcore.md` (to be created)
- **L2 Sub-Agent Prompts**: `docs/aurora_2_subcore_sub_agent_prompts_ready_to_use_2025-12-31.md`
- **Architecture Proposal**: `docs/aurora_2_subcore_sub_agent_proposal_2025-12-31.md`

---

**Date**: 2025-12-31-220825-pst  
**Status**: Architecture Evolution In Progress — Ready for L2 Sub-Agent Creation  
**Next Steps**: Create L2 sub-agents, establish coordination structure, update documentation
