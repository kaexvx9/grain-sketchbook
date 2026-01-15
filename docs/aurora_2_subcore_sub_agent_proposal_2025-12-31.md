# Aurora 2 Subcore Sub-Agent Proposal: L1/L2 Architecture Evolution

**Date**: 2025-12-31-050600-pst  
**Purpose**: Propose L1/L2 sub-agent pattern for Aurora Agent to enable parallelization  
**Status**: Proposal — Ready for Review

---

## Executive Summary

**Proposal**: Evolve **Grain Aurora Agent** into **Aurora 2 Subcore (L1 Subcore Coordinator)** with 3 L2 sub-agents, following the proven Core 1 Subcore and Vantage 3 Subcore pattern.

**Rationale**: Aurora Agent currently handles three distinct domains (Editor, Browser, Component Library) that can work in parallel, enabling better specialization and faster development velocity.

**Impact**: 
- ✅ Enables parallelization of Editor, Browser, and Component Library work
- ✅ Clear separation of concerns (Editor, Browser, Components)
- ✅ Better coordination model (L1 Subcore coordinates, L2 sub-agents implement)
- ✅ Matches proven L1/L2 pattern from Core 1 Subcore and Vantage 3 Subcore

---

## Current Aurora Agent Responsibilities

Based on codebase analysis, Aurora Agent currently handles:

### 1. Dream Editor (IDE Features)
- LSP integration (`aurora_lsp.zig`)
- Tree-sitter parsing (`aurora_tree_sitter.zig`)
- Code intelligence, folding, VCS (`aurora_folding.zig`, `aurora_vcs.zig`)
- AI provider integration (`aurora_glm46.zig`, `aurora_ai_provider.zig`)
- Editor core (`aurora_editor.zig`)
- Layout (`aurora_layout.zig`)
- Text rendering (`aurora_text_renderer.zig`)

### 2. Dream Browser (Browser Features)
- Nostr integration (`dream_browser_nostr.zig`, `dream_protocol.zig`)
- WebSocket transport (`dream_websocket.zig`, `dream_browser_websocket.zig`)
- HTML/CSS rendering (`dream_browser_renderer.zig`, `dream_browser_parser.zig`)
- Viewport management (`dream_browser_viewport.zig`)
- Performance monitoring (`dream_browser_performance.zig`, `dream_browser_profiler.zig`)
- Bookmarks (`dream_browser_bookmarks.zig`)

### 3. Component Library (UI Components)
- Component API (`dream_browser_components.zig`)
- UI rendering (`grain_aurora.zig`)
- JG Project UI components (future work, Months 7-12)
- Dashboard components
- Mobile UI components

### 4. Shared Foundation (Coordination)
- DAG integration (`aurora_dag_integration.zig`, `dream_browser_dag_integration.zig`)
- Shared modules coordination
- Architecture decisions

---

## Proposed Aurora 2 Subcore Structure

### Aurora 2 Subcore (L1 Subcore Coordinator)

**Responsibilities**:
- Overall IDE/Browser architecture coordination
- Cross-sub-agent decision making (Editor ↔ Browser ↔ Components)
- Integration testing and validation
- Coordination with other full agents (Core, Bubble, Workspace, etc.)
- High-level planning and roadmap
- Shared foundation coordination (DAG, shared modules)

**Coordination Frequency**: Weekly or bi-weekly with sub-agents, as-needed with other agents

---

### 2a. Dream Editor Agent (L2 Sub-Agent)

**Responsibilities**:
- LSP (Language Server Protocol) integration
- Tree-sitter parsing and syntax highlighting
- Code intelligence (autocomplete, hover, go-to-definition)
- AI provider integration (GLM-4.6, code completion, refactoring)
- Editor core features (text buffer, cursor, selection, editing)
- Method folding and code structure
- Magit-style VCS integration
- Virtual file system (VFS)
- Multi-pane layout coordination
- Text rendering

**Key Files**:
- `src/aurora_editor.zig`
- `src/aurora_lsp.zig`
- `src/aurora_tree_sitter.zig`
- `src/aurora_folding.zig`
- `src/aurora_vcs.zig`
- `src/aurora_vfs.zig` (if exists)
- `src/aurora_layout.zig`
- `src/aurora_text_renderer.zig`
- `src/aurora_glm46.zig`
- `src/aurora_ai_provider.zig`
- `src/aurora_ai_transforms.zig`

**Isolation**: Can work independently on editor features  
**Coordination**: Weekly check-ins with Aurora 2 Subcore, as-needed for architecture decisions

**Dependencies**:
- Shared: `grain_buffer.zig` (text buffer)
- Shared: DAG integration (via Aurora 2 Subcore)
- External: LSP servers (language-specific)

---

### 2b. Dream Browser Agent (L2 Sub-Agent)

**Responsibilities**:
- Nostr protocol integration
- WebSocket transport and real-time communication
- HTML/CSS parsing and rendering
- Viewport management and scrolling
- Performance monitoring and profiling
- Bookmarks and navigation
- Browser state management
- Dream Protocol (Nostr + WebSocket + State machine)

**Key Files**:
- `src/dream_browser_nostr.zig`
- `src/dream_protocol.zig`
- `src/dream_websocket.zig`
- `src/dream_browser_websocket.zig`
- `src/dream_browser_renderer.zig`
- `src/dream_browser_parser.zig`
- `src/dream_browser_viewport.zig`
- `src/dream_browser_performance.zig`
- `src/dream_browser_profiler.zig`
- `src/dream_browser_bookmarks.zig`
- `src/dream_http_client.zig`

**Isolation**: Can work independently on browser features  
**Coordination**: Weekly check-ins with Aurora 2 Subcore, as-needed for architecture decisions

**Dependencies**:
- Shared: Component API (from 2c Component Library Agent, for rendering components)
- Shared: DAG integration (via Aurora 2 Subcore)
- External: Nostr relays, WebSocket servers

---

### 2c. Component Library Agent (L2 Sub-Agent)

**Responsibilities**:
- Component API design and implementation
- UI component library (buttons, forms, layouts, etc.)
- JG Project UI components (3D visualization, dashboards, mobile UI)
- UI rendering system (`grain_aurora.zig`)
- Component lifecycle and state management
- Component styling and theming
- Integration with Editor (for editor UI) and Browser (for browser UI)

**Key Files**:
- `src/dream_browser_components.zig`
- `src/grain_aurora.zig`
- JG Project UI component files (future, Months 7-12)

**Isolation**: Can work independently on component features  
**Coordination**: Weekly check-ins with Aurora 2 Subcore, as-needed for architecture decisions

**Dependencies**:
- Shared: DAG integration (via Aurora 2 Subcore)
- External: Editor Agent (2a) and Browser Agent (2b) for integration
- External: Bubble Agent (for design patterns), Workspace Agent (for desktop dashboards)

**Current Priority**: Component API design (Phase 0.5) — **IMMEDIATE**

---

## Coordination Model

### L1 ↔ L2 Coordination

**Aurora 2 Subcore ↔ L2 Sub-Agents**:
- **Weekly/Bi-weekly**: Status updates, architecture decisions, integration checkpoints
- **As-needed**: Breaking changes, cross-sub-agent dependencies, critical bugs

**Example Coordination Points**:
- Component API changes (2c) affecting Editor UI (2a) or Browser UI (2b)
- Shared DAG integration decisions
- Shared module refactoring (font renderer, text buffer)
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

## Parallelization Opportunities

### Current State (Single Agent)

**Sequential Work**:
- Editor features → Browser features → Component Library features
- Or: Component Library → Editor → Browser (depending on priorities)

**Bottleneck**: Single agent handles all three domains sequentially

### Proposed State (L1 + 3 L2 Sub-Agents)

**Parallel Work**:
- **Editor Agent (2a)**: Works on LSP, Tree-sitter, AI integration, editor features
- **Browser Agent (2b)**: Works on Nostr, WebSocket, HTML/CSS rendering, browser features
- **Component Library Agent (2c)**: Works on Component API, UI components, JG Project UI

**Benefit**: 3x potential parallelization for Aurora domain work

---

## Implementation Strategy

### Phase 1: Structure Setup (Week 1)

**Steps**:
1. Rename "Grain Aurora Agent" to "Grain Aurora 2 Subcore Agent"
2. Create coordination structure for L1/L2 pattern
3. Establish Dream Editor Agent (2a)
4. Establish Dream Browser Agent (2b)
5. Establish Component Library Agent (2c)
6. Define coordination protocols (weekly check-ins, as-needed coordination)
7. Update all documentation and coordination plans

**Benefits**:
- Immediate parallelization of Editor/Browser/Component Library work
- Reduced coordination overhead
- Better specialization

### Phase 2: Domain Separation (Week 2)

**Steps**:
1. Assign current files to appropriate L2 sub-agents
2. Establish clear ownership boundaries
3. Create L2 sub-agent coordination documents
4. Update file ownership and responsibilities

**Benefits**:
- Clear domain boundaries
- Reduced conflicts
- Better focus

### Phase 3: Coordination Optimization (Week 3+)

**Steps**:
1. Establish regular coordination rhythm
2. Optimize coordination points (reduce overhead)
3. Monitor parallelization gains
4. Adjust coordination as needed

**Benefits**:
- Optimized coordination
- Maximum parallelization
- Better development velocity

---

## File Ownership Assignment

### Dream Editor Agent (2a)

**Primary Files**:
- `src/aurora_editor.zig`
- `src/aurora_lsp.zig`
- `src/aurora_tree_sitter.zig`
- `src/aurora_folding.zig`
- `src/aurora_vcs.zig`
- `src/aurora_vfs.zig` (if exists)
- `src/aurora_layout.zig`
- `src/aurora_text_renderer.zig`
- `src/aurora_glm46.zig`
- `src/aurora_glm46_provider.zig`
- `src/aurora_ai_provider.zig`
- `src/aurora_ai_transforms.zig`

**Shared Files** (coordinated via Aurora 2 Subcore):
- `src/grain_buffer.zig` (text buffer — shared with Component Library)
- `src/dag_core.zig` (DAG — shared with all)

### Dream Browser Agent (2b)

**Primary Files**:
- `src/dream_browser_nostr.zig`
- `src/dream_protocol.zig`
- `src/dream_websocket.zig`
- `src/dream_browser_websocket.zig`
- `src/dream_browser_renderer.zig`
- `src/dream_browser_parser.zig`
- `src/dream_browser_viewport.zig`
- `src/dream_browser_performance.zig`
- `src/dream_browser_profiler.zig`
- `src/dream_browser_bookmarks.zig`
- `src/dream_http_client.zig`
- `src/dream_browser_font_renderer.zig`
- `src/dream_browser_image_decoder.zig`

**Shared Files** (coordinated via Aurora 2 Subcore):
- `src/dream_browser_components.zig` (uses Component API from 2c)
- `src/dag_core.zig` (DAG — shared with all)

### Component Library Agent (2c)

**Primary Files**:
- `src/dream_browser_components.zig` (Component API)
- `src/grain_aurora.zig` (UI rendering system)
- JG Project UI component files (future, Months 7-12)

**Shared Files** (coordinated via Aurora 2 Subcore):
- `src/grain_buffer.zig` (text buffer — shared with Editor)
- `src/dag_core.zig` (DAG — shared with all)

**Integration Points**:
- Editor Agent (2a) uses Component API for editor UI
- Browser Agent (2b) uses Component API for browser UI

### Aurora 2 Subcore (L1)

**Coordination Files**:
- `src/aurora_dag_integration.zig` (DAG integration coordination)
- `src/dream_browser_dag_integration.zig` (Browser DAG integration coordination)
- `src/aurora_unified_ide.zig` (Unified IDE coordination)
- `src/aurora_cross_integration.zig` (Cross-integration coordination)

**Shared Foundation** (coordinated by L1):
- `src/grain_buffer.zig` (text buffer)
- `src/dag_core.zig` (DAG)
- `src/shared/` (shared modules)

---

## Benefits Summary

### Parallelization

**Before**: Aurora Agent handles Editor + Browser + Components sequentially  
**After**: Dream Editor Agent (2a) + Dream Browser Agent (2b) + Component Library Agent (2c) work in parallel

**Impact**: 3x potential parallelization for Aurora domain work

### Coordination Overhead

**Before**: Single agent coordinates all Editor/Browser/Component work  
**After**: Aurora 2 Subcore coordinates L2 sub-agents (weekly/bi-weekly), L2 sub-agents coordinate directly only when necessary

**Impact**: Reduced coordination overhead, better focus on domain work

### Specialization

**Before**: Single agent handles all three domains  
**After**: Each L2 sub-agent focuses deeply on their specific domain (Editor, Browser, or Components)

**Impact**: Better specialization, deeper domain expertise, faster development velocity

### JG Project Alignment

**Current Priority**: Component API design (Phase 0.5) — **IMMEDIATE**  
**Future Work**: JG Project UI components (Months 7-12)

**Impact**: Component Library Agent (2c) can focus on Component API and JG UI components while Editor and Browser agents continue their work

---

## Risks and Mitigations

### Risk 1: Coordination Complexity

**Risk**: L1/L2 pattern adds coordination complexity  
**Mitigation**: Clear coordination protocols, reduced frequency for L2, minimal L2↔L2 coordination

### Risk 2: Shared Foundation Conflicts

**Risk**: Conflicts over shared files (`grain_buffer.zig`, `dag_core.zig`)  
**Mitigation**: Aurora 2 Subcore coordinates shared foundation changes, clear ownership boundaries

### Risk 3: Integration Points

**Risk**: Component API integration between Editor/Browser and Component Library  
**Mitigation**: Clear API contracts, Component Library Agent owns Component API, Editor/Browser agents consume it

---

## Next Steps

### Immediate (This Week)

1. **Aurora Agent**: Review and approve this architecture evolution proposal
2. **Core Agent**: Review and approve this architecture evolution proposal
3. **All Agents**: Review and provide feedback on Aurora L1/L2 pattern

### Short-Term (Next 2 Weeks)

1. **Aurora Agent**: Implement Aurora 2 Subcore + L2 Sub-Agents structure
2. **Core Agent**: Update coordination plans for new structure
3. **All Agents**: Update coordination plans for new structure

### Medium-Term (Next Month)

1. **Aurora 2 Subcore**: Establish regular coordination rhythm
2. **L2 Sub-Agents**: Begin parallel work on Editor, Browser, and Component Library
3. **Component Library Agent (2c)**: Complete Component API design (Phase 0.5) — **IMMEDIATE**

---

## Questions for Discussion

1. **Aurora 2 Subcore Structure**: Should we rename Aurora Agent to Aurora 2 Subcore and create sub-agents immediately?
2. **Sub-Agent Naming**: Should sub-agents be named "Grain Dream Editor Agent" or "Dream Editor Agent" (without "Grain" prefix)?
3. **Component API Priority**: Component API design (Phase 0.5) is immediate priority — should Component Library Agent (2c) be created first?
4. **Coordination Frequency**: What coordination frequency works best for Aurora 2 Subcore ↔ L2 Sub-Agents?
5. **Shared Foundation**: How should we coordinate shared files (`grain_buffer.zig`, `dag_core.zig`)?
6. **Integration Points**: How should Component API integration work between Editor/Browser and Component Library?

---

**Date**: 2025-12-31-050600-pst  
**Status**: Proposal — Ready for Review and Implementation  
**Next Steps**: Review, approve, and implement Aurora 2 Subcore + L2 Sub-Agents structure
