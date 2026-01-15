# Aurora 2 Subcore: IDE/Browser Architecture

**Date**: 2026-01-02-090305-pst  
**Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Status**: ✅ **ARCHITECTURE DOCUMENTED** — Comprehensive architecture overview complete

---

## Executive Summary

This document describes the overall IDE/Browser architecture for Aurora 2 Subcore, including sub-agent responsibilities, boundaries, component interaction patterns, and data flow.

**Purpose**: Provide comprehensive architecture documentation for IDE/Browser domain, enabling clear understanding of system design, sub-agent boundaries, and integration patterns.

**Audience**: L2 sub-agents, Core 1 Subcore, other L1 agents, and future developers

---

## Architecture Overview

### System Structure

**L1 Subcore Coordinator**: Aurora 2 Subcore Agent
- **Role**: IDE/Browser architecture coordination, cross-sub-agent decision making, integration testing
- **Scope**: IDE/Browser domain (Editor, Browser, Component Library)
- **Coordination**: Weekly/bi-weekly with L2 sub-agents, as-needed with Core 1 Subcore and other L1 agents

**L2 Sub-Agents**:
- **2a. Dream Editor Agent**: IDE features (LSP, Tree-sitter, AI integration, editor core)
- **2b. Dream Browser Agent**: Browser features (Nostr, WebSocket, HTML/CSS rendering)
- **2c. Component Library Agent**: UI components (Component API, basic UI components, JG Project UI)

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                    Aurora 2 Subcore (L1)                        │
│              IDE/Browser Architecture Coordination              │
└─────────────────────────────────────────────────────────────────┘
                            │
                ┌───────────┴───────────┐
                │                       │
                ▼                       ▼
    ┌──────────────────────┐   ┌──────────────────────┐
    │  Dream Editor (2a)   │   │ Dream Browser (2b)   │
    │                      │   │                      │
    │  - LSP Integration   │   │  - Nostr Protocol    │
    │  - Tree-sitter       │   │  - WebSocket         │
    │  - AI Integration    │   │  - HTML/CSS Render   │
    │  - Editor Core       │   │  - Viewport Mgmt     │
    │  - Multi-pane Layout │   │  - Performance       │
    └──────────┬───────────┘   └──────────┬───────────┘
               │                          │
               │                          │
               └──────────┬───────────────┘
                          │
                          ▼
            ┌─────────────────────────────┐
            │ Component Library (2c)      │
            │                             │
            │  - Component API            │
            │  - Basic UI Components      │
            │  - Layout Components        │
            │  - Rendering Integration    │
            └──────────┬──────────────────┘
                       │
                       ▼
            ┌─────────────────────────────┐
            │   Rendering Layer           │
            │   (GrainAurora)             │
            │                             │
            │  - Component Rendering      │
            │  - RenderContext            │
            │  - RenderResult             │
            │  - Node Types               │
            └─────────────────────────────┘
```

---

## Sub-Agent Responsibilities and Boundaries

### 2a. Dream Editor Agent (L2 Sub-Agent)

**Domain**: IDE Editor Features

**Responsibilities**:
- LSP (Language Server Protocol) integration
- Tree-sitter parsing and syntax highlighting
- AI provider integration (GLM-4.6)
- Editor core features (text buffer, cursor, selection, undo/redo)
- Method folding and code structure
- Magit-style VCS integration
- Multi-pane layout (using Component API)
- Editor UI components (panes, tabs, status bar, toolbar)

**Code Ownership**:
- `src/dream_editor/` (Editor-specific code)
- `src/aurora_editor.zig` (Editor core)
- `src/aurora_lsp.zig` (LSP integration)
- `src/aurora_tree_sitter.zig` (Tree-sitter)
- `src/aurora_ai_provider.zig` (AI integration)
- `src/aurora_folding.zig` (Method folding)
- `src/aurora_vcs.zig` (VCS integration)
- `src/dream_editor_components.zig` (Editor UI components - after Component API Phase 1)

**Boundaries**:
- Uses Component Library Agent (2c) Component API for UI components
- Uses GrainBuffer (`src/grain_buffer.zig`) for text buffer (shared with Component Library)
- Uses DAG Core (`src/dag_core.zig`) for event recording (shared with all)
- Coordinates with Aurora 2 Subcore for shared module changes
- Coordinates with Browser Agent (2b) for shared foundation

**Integration Points**:
- Component API: Editor UI components (panes, tabs, status bar) via Component Library Agent
- GrainBuffer: Text buffer for editor content
- DAG Core: Editor events (file edits, LSP interactions, AI completions)

---

### 2b. Dream Browser Agent (L2 Sub-Agent)

**Domain**: Browser Features

**Responsibilities**:
- Nostr protocol integration
- WebSocket transport and real-time communication
- HTML/CSS parsing and rendering
- Viewport management and scrolling
- Performance monitoring and profiling
- Bookmarks and navigation
- Browser UI components (navigation, address bar, tabs, browser view)

**Code Ownership**:
- `src/dream_browser/` (Browser-specific code)
- `src/dream_browser_nostr.zig` (Nostr integration)
- `src/dream_protocol.zig` (Dream Protocol - Nostr + WebSocket + State machine)
- `src/dream_websocket.zig` (WebSocket client)
- `src/dream_browser_parser.zig` (HTML/CSS parsing)
- `src/dream_browser_renderer.zig` (HTML/CSS rendering)
- `src/dream_browser_viewport.zig` (Viewport management)
- `src/dream_browser_performance.zig` (Performance monitoring)
- `src/dream_browser_components.zig` (Browser UI components - existing, uses Component API)

**Boundaries**:
- Uses Component Library Agent (2c) Component API for UI components
- Uses DAG Core (`src/dag_core.zig`) for event recording (shared with all)
- Coordinates with Aurora 2 Subcore for shared module changes
- Coordinates with Editor Agent (2a) for shared foundation

**Integration Points**:
- Component API: Browser UI components (navigation, address bar, tabs, browser view) via Component Library Agent
- DAG Core: Browser events (navigation, Nostr events, WebSocket messages)
- Content Area: `browser_view.content_area` component for Bubble Agent SLC components

---

### 2c. Component Library Agent (L2 Sub-Agent)

**Domain**: UI Components

**Responsibilities**:
- Component API design and implementation (Phase 1)
- Component lifecycle management (init, update, render, cleanup)
- Component state management (state/size/theme variants)
- Component rendering integration (GrainAurora)
- Basic UI components (Phase 2: buttons, inputs, labels)
- Layout components (Phase 2: columns, rows, containers)
- Component styling and theming
- JG Project UI components (Phase 4, Months 7-12: 3D visualization, dashboards, mobile)

**Code Ownership**:
- `src/dream_browser_components.zig` (Browser Component API - existing, Phase 1 updates)
- `src/dream_editor_components.zig` (Editor Component API - Phase 1 implementation)
- `src/grain_component_library/` (Phase 2: basic UI components)
- Component API core (Phase 1: unified Component API)

**Boundaries**:
- Provides Component API to Editor Agent (2a) and Browser Agent (2b)
- Uses Workspace Agent's base Component types (`src/grain_workspace/components.zig`)
- Uses GrainAurora rendering system (`src/grain_aurora.zig`)
- Uses GrainBuffer (`src/grain_buffer.zig`) for text buffer (shared with Editor)
- Coordinates with Aurora 2 Subcore for Component API design decisions
- Coordinates with Bubble Agent for JG Project UI component integration

**Integration Points**:
- Component API: Provides unified Component API to Editor and Browser agents
- GrainBuffer: Text buffer for component rendering
- GrainAurora: Component rendering system
- Workspace Agent: Base Component types (reused)

---

## Component Interaction Patterns

### Component API Flow

**Pattern**: Component Library Agent (2c) provides Component API, Editor and Browser agents consume it.

```
Editor Agent (2a)              Browser Agent (2b)
     │                                │
     │                                │
     └────────────┬───────────────────┘
                  │
                  ▼
        Component Library Agent (2c)
                  │
                  │ Component API
                  ▼
        ┌─────────────────────┐
        │  Component Base     │
        │  Types (Workspace)  │
        └─────────────────────┘
                  │
                  ▼
        ┌─────────────────────┐
        │   GrainAurora       │
        │   Rendering         │
        └─────────────────────┘
```

**Component ID Allocation**:
- Workspace Agent: IDs 1-29 (base Component types)
- Browser Agent: IDs 30-69 (Browser UI components)
- Editor Agent: IDs 70-99 (Editor UI components)
- Component Library: IDs 1000-9999 (Phase 2: basic UI components, future)

### Shared Module Flow

**Pattern**: Shared modules (GrainBuffer, DAG Core) are coordinated by Aurora 2 Subcore.

```
Editor Agent (2a)              Browser Agent (2b)
     │                                │
     │                                │
     └────────────┬───────────────────┘
                  │
                  ▼
        Aurora 2 Subcore (L1)
        (Coordinates shared modules)
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
  GrainBuffer          DAG Core
  (Editor +            (All sub-agents)
   Component)
```

---

## Data Flow

### Editor Workflow

```
User Input → Editor Agent (2a)
                │
                ├─→ LSP Integration (code intelligence)
                ├─→ Tree-sitter (syntax highlighting)
                ├─→ AI Integration (code completion)
                ├─→ Editor Core (text buffer, cursor)
                └─→ Component API (UI rendering)
                     │
                     └─→ Component Library Agent (2c)
                          │
                          └─→ GrainAurora (rendering)
```

### Browser Workflow

```
User Navigation → Browser Agent (2b)
                    │
                    ├─→ Nostr Protocol (event handling)
                    ├─→ WebSocket (real-time communication)
                    ├─→ HTML/CSS Parser (content parsing)
                    ├─→ Renderer (content rendering)
                    └─→ Component API (UI rendering)
                         │
                         └─→ Component Library Agent (2c)
                              │
                              └─→ GrainAurora (rendering)
```

### Component Rendering Flow

```
Component State Change
        │
        ▼
Component Library Agent (2c)
        │
        ├─→ Component Lifecycle (update)
        ├─→ Component State Management
        └─→ Component Rendering
             │
             └─→ GrainAurora
                  │
                  └─→ RenderResult (Node tree)
```

---

## Integration Patterns

### Component API Integration

**Pattern**: Unified Component API for Editor, Browser, and future JG Project components.

**Components**:
1. **Base Component Types**: From Workspace Agent (`src/grain_workspace/components.zig`)
2. **Component API**: Component Library Agent provides unified API
3. **Component Groups**: Editor and Browser define component groups (EditorPaneComponents, NavigationComponents, etc.)
4. **Rendering**: Components render via GrainAurora

**Integration Steps**:
1. Component Library Agent (2c) implements Component API (Phase 1)
2. Editor Agent (2a) uses Component API for UI components (multi-pane layout)
3. Browser Agent (2b) uses Component API for UI components (existing structure, enhanced)
4. Component Library Agent (2c) provides basic UI components (Phase 2)

### Shared Module Integration

**Pattern**: Shared modules (GrainBuffer, DAG Core) are coordinated by Aurora 2 Subcore.

**GrainBuffer**:
- **Used By**: Editor Agent (2a), Component Library Agent (2c)
- **Purpose**: Text buffer for editor content and component rendering
- **Coordination**: Aurora 2 Subcore coordinates changes

**DAG Core**:
- **Used By**: All sub-agents (Editor, Browser, Component Library)
- **Purpose**: Event recording, version management, state synchronization
- **Coordination**: Aurora 2 Subcore coordinates usage patterns

### Cross-Application Integration

**Pattern**: Editor and Browser can share Component rendering and theme synchronization.

**Shared Components**:
- Components can be shared between Editor and Browser
- Theme synchronization across applications
- State management consistency

**Integration**:
- Component Library Agent provides unified Component API
- Editor and Browser use Component API for consistent UI
- Aurora 2 Subcore coordinates cross-application patterns

---

## API Contracts

### Component API Contract

**Provider**: Component Library Agent (2c)

**Consumers**: Editor Agent (2a), Browser Agent (2b), future JG Project components

**Contract**:
- Component lifecycle: init, update, render, cleanup
- Component state management: state/size/theme variants
- Component rendering: GrainAurora integration
- Component ID allocation: non-overlapping ranges per agent

**Versioning**: Component API is versioned, breaking changes require coordination

### Shared Module Contracts

**GrainBuffer Contract**:
- **Provider**: Shared module (coordinated by Aurora 2 Subcore)
- **Consumers**: Editor Agent (2a), Component Library Agent (2c)
- **Contract**: Text buffer operations, state management, readonly spans

**DAG Core Contract**:
- **Provider**: Shared module (coordinated by Aurora 2 Subcore)
- **Consumers**: All sub-agents (Editor, Browser, Component Library)
- **Contract**: Event recording, history retrieval, version management

---

## Security Boundaries

### Component Isolation

**Boundary**: Each sub-agent owns its domain code and components.

**Isolation**:
- Editor Agent: Owns editor-specific code and Editor UI components
- Browser Agent: Owns browser-specific code and Browser UI components
- Component Library Agent: Owns Component API and basic UI components

**Shared Resources**:
- Shared modules (GrainBuffer, DAG Core) are coordinated by Aurora 2 Subcore
- Component API provides unified interface, but components are isolated per agent

### Error Handling

**Pattern**: Errors are handled at sub-agent level, propagated through Component API.

**Error Propagation**:
- Sub-agent errors: Handled within sub-agent domain
- Component API errors: Propagated to consuming agents
- Shared module errors: Coordinated by Aurora 2 Subcore

---

## Performance Characteristics

### Component Rendering Performance

**Performance Requirements**:
- Component initialization: < 1ms per component
- Component rendering: < 10ms per component tree
- Component state updates: < 1ms per update

**Optimization**:
- Component rendering is batched where possible
- Component state updates are minimal and focused
- GrainAurora rendering is optimized for component rendering

### Shared Module Performance

**GrainBuffer Performance**:
- Text buffer operations: < 1ms per operation
- Readonly spans: Zero-copy where possible
- State management: O(1) operations

**DAG Core Performance**:
- Event recording: < 1ms per event
- History retrieval: O(n) where n is history length
- Version management: O(1) operations

---

## Future Architecture Considerations

### JG Project Integration (Months 7-12)

**Phase 4**: Component Library Agent (2c) implements JG Project UI components

**Components**:
- 3D visualization components
- Dashboard components
- Mobile UI components

**Integration**:
- Uses Component API (same as Editor and Browser)
- Component IDs: TBD (separate range or reuse existing)
- Integration with Bubble Agent for design patterns

### Cross-Agent Integration

**Future Integration Points**:
- Workspace Agent: Desktop dashboards (Component API base types)
- Bubble Agent: JG UI components (design patterns, SLC components)
- Carry Agent: Mobile UI components (Component API for mobile)

---

## Summary

**Architecture**: ✅ **DOCUMENTED**

**Key Components**:
- L1 Subcore Coordinator (Aurora 2 Subcore) for architecture coordination
- L2 Sub-Agents (Editor, Browser, Component Library) for domain-specific implementation
- Component API for unified UI component system
- Shared modules (GrainBuffer, DAG Core) coordinated by Aurora 2 Subcore

**Integration Patterns**:
- Component API integration (Editor and Browser use Component Library)
- Shared module integration (coordinated by Aurora 2 Subcore)
- Cross-application integration (Component sharing, theme synchronization)

**Next Steps**:
- Document integration patterns in detail
- Create Architecture Decision Records (ADRs)
- Update architecture as implementation progresses

---

**Date**: 2026-01-02-090305-pst  
**Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Status**: ✅ **ARCHITECTURE DOCUMENTED** — Comprehensive architecture overview complete

