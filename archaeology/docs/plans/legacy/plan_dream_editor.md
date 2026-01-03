# Grain Dream Editor Agent: Development Plan

**Agent**: Grain Dream Editor Agent (2a)  
**Parent Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Last Updated**: 2026-01-01-092253-pst  
**Status**: ✅ **PHASE 1 COMPLETE** — Phase 2 In Progress ⏳ (Blocked on Component API)

---

## Overview

Grain Dream Editor Agent is responsible for building the **Dream Editor (IDE features)**, a Matklad-inspired editor with GLM-4.6 integration. The editor provides a native Zig IDE experience with advanced code intelligence, AI-powered completions, and seamless VCS integration.

**Key Goals**:
- Matklad-inspired editor with readonly spans (text-as-UI)
- Complete LSP integration (JSON-RPC 2.0, snapshot model)
- Tree-sitter syntax highlighting and structural editing
- GLM-4.6 AI integration (1,000 tokens/second)
- Method folding (fold bodies by default, show signatures)
- Magit-style VCS integration (virtual files with readonly metadata)
- Multi-pane layout support (blocked on Component API)
- Virtual file system (VFS) abstraction

**Philosophy**: Build a native IDE that feels like part of Grain OS, with safety-first design (GrainStyle compliance), bounded allocations, and comprehensive assertions.

---

## Completed Phases

### Phase 1: Core Editor Features ✅ **COMPLETE**

**Status**: ✅ **COMPLETE**  
**Priority**: HIGHEST  
**Estimated Time**: 8-10 weeks ✅ **COMPLETE**  
**Started**: 2025-12-01  
**Completed**: 2025-12-31

**Objective**: Build Matklad-inspired editor with GLM-4.6 integration, LSP support, tree-sitter syntax highlighting, method folding, and Magit-style VCS integration.

#### 1.1: Readonly Spans Integration ✅ **COMPLETE**
- ✅ Integrated enhanced GrainBuffer into editor
- ✅ Edit protection (prevents modifications to readonly spans)
- ✅ Visual rendering (readonly spans returned in render result)
- ✅ Cursor handling (insert checks for readonly violations)
- **Files**: `src/aurora_editor.zig`, `src/grain_buffer.zig`

#### 1.2: Method Folding ✅ **COMPLETE**
- ✅ Parse code structure (regex-based for Zig functions/structs)
- ✅ Identify method/function boundaries
- ✅ Fold bodies by default, show signatures
- ✅ Toggle folding (keyboard shortcut ready)
- ✅ Visual indicators (fold state tracking)
- **Files**: `src/aurora_folding.zig`, `src/aurora_editor.zig`

#### 1.3: GLM-4.6 Integration ✅ **COMPLETE**
- ✅ Code completion (ghost text at 1,000 tps integrated)
- ✅ Editor integration (GLM-4.6 client optional, falls back to LSP)
- ✅ Code transformation (refactor, extract, inline)
- ✅ AI Provider Abstraction (`aurora_ai_provider.zig`)
- ✅ Tool calling (run `zig build`, `jj status`)
- ✅ Multi-file edits (context-aware)
- **Files**: `src/aurora_glm46.zig`, `src/aurora_ai_provider.zig`, `src/aurora_glm46_provider.zig`, `src/aurora_ai_transforms.zig`

#### 1.4: Complete LSP Implementation ✅ **COMPLETE**
- ✅ JSON-RPC 2.0 serialization/deserialization
- ✅ Snapshot model (incremental updates, Matklad-style)
- ✅ Cancellation support for pending requests
- ✅ Server communication (stdin/stdout with Content-Length headers)
- ✅ Document lifecycle (didOpen, didChange with incremental edits)
- ✅ Code intelligence (autocomplete, hover, go-to-definition, diagnostics)
- ✅ GrainStyle compliance (u32 types, assertions, bounded allocations)
- **Files**: `src/aurora_lsp.zig`, `src/aurora_editor.zig`

#### 1.5: Tree-sitter Integration ✅ **COMPLETE**
- ✅ Syntax parsing and highlighting
- ✅ Structural editing support
- ✅ Code structure understanding
- ✅ Bounded parsing (max 10,000 nodes, max depth 100)
- **Files**: `src/aurora_tree_sitter.zig`, `src/aurora_editor.zig`

#### 1.6: Magit-Style VCS Integration ✅ **COMPLETE**
- ✅ Virtual file system (`.jj/status.jj`, `.jj/commit/*.diff`)
- ✅ Readonly spans for commit hashes, parent info, file paths, diff headers
- ✅ Editable hunks (diff content can be edited)
- ✅ Watch for edits, invoke `jj` commands
- ✅ Bounded allocations (max 1000 virtual files, max 100 pending commands)
- **Files**: `src/aurora_vcs.zig`

#### 1.7: Editor Core Features ✅ **COMPLETE**
- ✅ Text buffer integration (uses `grain_buffer.zig` shared module)
- ✅ Cursor and selection management
- ✅ Editing operations (insert, delete, replace)
- ✅ Undo/redo functionality (bounded history: max 1024 entries)
- ✅ File save/load functionality
- ✅ Ghost text rendering (AI completion preview)
- **Files**: `src/aurora_editor.zig`

#### 1.8: Text Rendering ✅ **COMPLETE**
- ✅ Text rendering integration
- ✅ Visual rendering features (diagnostics, inlay hints, code lens)
- ✅ 8x8 bitmap font rendering
- **Files**: `src/aurora_text_renderer.zig`, `src/aurora_editor.zig`

**Tests**: Comprehensive test coverage across all modules

**Coordination**:
- ✅ Component API requirements provided to Component Library Agent (2c) (2026-01-01-084922-pst)
- ✅ Coordination alignment with Dream Browser Agent (2b) (2026-01-01-085414-pst)

---

## Current Phase

### Phase 2: Enhancements and Integration ⏳ **IN PROGRESS** (Blocked on Component API)

**Status**: ⏳ **IN PROGRESS** (Blocked on Component API)  
**Priority**: HIGH  
**Estimated Time**: 4-6 weeks  
**Started**: 2025-12-31

**Objective**: Enhance editor with multi-pane layout, VFS abstraction, and advanced editor features.

**Current Blocker**: Multi-pane layout implementation blocked until Component Library Agent (2c) finalizes Component API design (Phase 0.5) and implements Component API (Phase 1).

#### 2.1: Multi-Pane Layout ⏳ **BLOCKED** (Waiting for Component API)

**Status**: ⏳ **BLOCKED** — Waiting for Component Library Agent (2c) Component API  
**Priority**: HIGH  
**Blocked On**: Component Library Agent (2c) Component API design (Phase 0.5) and implementation (Phase 1)

**Requirements Provided**:
- ✅ Editor UI component requirements provided (2026-01-01-084922-pst)
- ✅ Component structure and ID allocation (70-99) confirmed
- ✅ Integration requirements documented

**Waiting For**:
- ⏳ Component Library Agent (2c) to finalize Component API design (Phase 0.5)
- ⏳ Component Library Agent (2c) to implement Component API (Phase 1)
- ⏳ `DreamEditorComponentAPI` structure with EditorPaneComponents, EditorTabComponents, EditorStatusBarComponents

**Features** (when unblocked):
- ⏳ Layout management (split panes, resize, focus)
- ⏳ Component API integration for editor UI components
- ⏳ River compositor integration (when available)
- **Files**: `src/aurora_layout.zig`

#### 2.2: Virtual File System (VFS) ⏳ **PLANNED**

**Status**: ⏳ **PLANNED**  
**Priority**: MEDIUM  
**Dependencies**: Can proceed independently (not blocked)

**Features**:
- ⏳ File system abstraction
- ⏳ Virtual file handling
- ⏳ Integration with editor for virtual file support
- **Files**: `src/aurora_vfs.zig` (if needed, may be integrated into existing modules)

#### 2.3: Advanced Editor Features ⏳ **PLANNED**

**Status**: ⏳ **PLANNED**  
**Priority**: MEDIUM  
**Dependencies**: Can proceed independently (not blocked)

**Features**:
- ⏳ Enhanced code lens (more LSP features)
- ⏳ Inlay hints (type hints, parameter names)
- ⏳ Symbol navigation (workspace symbols, document symbols)
- ⏳ Code actions (quick fixes, refactorings)
- ⏳ Format on save
- ⏳ Find references
- ⏳ Rename symbol

---

## Planned Phases

### Phase 3: Advanced Features 📋 **PLANNED**

**Objective**: Multi-cursor editing, code snippets, custom keybindings, plugin system

**Estimated Time**: 2-3 weeks

**Features**:
- 📋 Multi-cursor editing
- 📋 Code snippets/templates
- 📋 Custom keybindings
- 📋 Plugin system (if needed)
- 📋 Theme customization
- 📋 Performance profiling tools

**Dependencies**: Phase 2 complete, Component Library Agent coordination

---

## Coordination

**With Aurora 2 Subcore (L1)**:
- Weekly/bi-weekly check-ins for status updates and architecture decisions
- As-needed coordination for breaking changes, cross-sub-agent dependencies
- Shared module coordination (GrainBuffer, DAG Core)
- **Current Priority**: Component API coordination (blocking multi-pane layout)

**With Component Library Agent (2c)**:
- ✅ Component API requirements provided (2026-01-01-084922-pst)
- ⏳ Waiting for Component API design finalization (Phase 0.5)
- ⏳ Waiting for Component API implementation (Phase 1)
- **Current Blocker**: Component API blocks multi-pane layout implementation

**With Dream Browser Agent (2b)**:
- ✅ Coordination alignment (2026-01-01-085414-pst)
- ✅ Shared Component API coordination needs identified
- Via Aurora 2 Subcore for shared foundation coordination

---

## Dependencies

### Shared Modules (Coordinated via Aurora 2 Subcore)
- **`src/grain_buffer.zig`** - Text buffer (shared with Component Library Agent)
- **`src/dag_core.zig`** - DAG (shared with all agents)
- **`src/shared/`** - Shared modules (coordinated by Aurora 2 Subcore)

### External Dependencies
- **LSP servers** (language-specific, e.g., ZLS for Zig)
- **GLM-4.6 API** (Cerebras) - OpenAI-compatible endpoint
- **Tree-sitter** (C library via `@cImport` or bindings)
- **Zig grammar** (tree-sitter-zig)

### Blocking Dependencies
- **Component Library Agent (2c) Component API** - **BLOCKING**: Multi-pane layout implementation
  - Component API design (Phase 0.5) - **BLOCKING**
  - Component API implementation (Phase 1) - **BLOCKING**

---

## Grain Style Compliance

- ✅ Function length: ≤ 70 lines
- ✅ Line length: ≤ 100 characters
- ✅ Explicit types: `u32`/`u64` (not `usize`/`isize`)
- ✅ Bounded allocations
- ✅ Comprehensive assertions
- ✅ All compiler warnings enabled

---

## Key Files (Domain)

### Core Editor Files
- `src/aurora_editor.zig` - Editor core ✅
- `src/aurora_lsp.zig` - LSP client ✅
- `src/aurora_tree_sitter.zig` - Tree-sitter integration ✅
- `src/aurora_folding.zig` - Method folding ✅
- `src/aurora_vcs.zig` - Magit-style VCS ✅
- `src/aurora_vfs.zig` - Virtual file system (if exists)
- `src/aurora_layout.zig` - Multi-pane layout ⏳ (blocked)
- `src/aurora_text_renderer.zig` - Text rendering ✅

### AI Integration Files
- `src/aurora_glm46.zig` - GLM-4.6 client ✅
- `src/aurora_glm46_provider.zig` - GLM-4.6 provider ✅
- `src/aurora_ai_provider.zig` - AI provider abstraction ✅
- `src/aurora_ai_transforms.zig` - AI code transformations ✅

### Shared Files (Coordinated via Aurora 2 Subcore)
- `src/grain_buffer.zig` - Text buffer (shared with Component Library Agent)
- `src/dag_core.zig` - DAG (shared with all)
- `src/shared/` - Shared modules (coordinated by Aurora 2 Subcore)

---

**Last Updated**: 2026-01-01-092253-pst  
**Agent**: Grain Dream Editor Agent (2a)  
**Parent Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Status**: ✅ Phase 1 Complete — Phase 2 In Progress (Blocked on Component API)
