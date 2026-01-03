# Grain Dream Editor Agent: Task List

**Agent**: Grain Dream Editor Agent (2a)  
**Parent Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Last Updated**: 2026-01-01-092253-pst  
**Status**: ✅ **PHASE 1 COMPLETE** — Phase 2 In Progress ⏳ (Blocked on Component API)

---

## Current Tasks

### High Priority

- [ ] Multi-pane layout management (split panes, resize, focus) — **BLOCKED**: Waiting for Component Library Agent (2c) Component API
- [ ] Component API integration coordination with Component Library Agent (2c) — **BLOCKED**: Waiting for Component Library Agent (2c) Component API design (Phase 0.5) and implementation (Phase 1)
- [ ] River compositor integration (when available) — **BLOCKED**: Depends on River compositor availability

### Medium Priority

- [ ] Virtual File System (VFS) implementation — **PLANNED** (can proceed independently)
- [ ] Enhanced code lens (more LSP features) — **PLANNED** (can proceed independently)
- [ ] Inlay hints (type hints, parameter names) — **PLANNED** (can proceed independently)
- [ ] Symbol navigation (workspace symbols, document symbols) — **PLANNED** (can proceed independently)

### Low Priority

- [ ] Code actions (quick fixes, refactorings) — **PLANNED**
- [ ] Format on save — **PLANNED**
- [ ] Find references — **PLANNED**
- [ ] Rename symbol — **PLANNED**

---

## Completed Tasks

### Phase 1: Core Editor Features ✅ **COMPLETE**

**Status**: ✅ **COMPLETE**  
**Date Started**: 2025-12-01  
**Date Completed**: 2025-12-31  
**Priority**: HIGHEST

#### 1.1: Readonly Spans Integration ✅ **COMPLETE**

- [x] Integrate enhanced GrainBuffer into editor ✅
- [x] Edit protection (prevents modifications to readonly spans) ✅
- [x] Visual rendering (readonly spans returned in render result) ✅
- [x] Cursor handling (insert checks for readonly violations) ✅
- [x] Bounded allocations (max 1000 readonly spans per buffer) ✅
- [x] Comprehensive assertions (GrainStyle compliance) ✅
- **Files**: `src/aurora_editor.zig`, `src/grain_buffer.zig`

#### 1.2: Method Folding ✅ **COMPLETE**

- [x] Create `src/aurora_folding.zig` module structure ✅
- [x] Parse code structure (regex-based for Zig functions/structs) ✅
- [x] Identify method/function boundaries ✅
- [x] Fold bodies by default, show signatures ✅
- [x] Toggle folding (keyboard shortcut ready) ✅
- [x] Visual indicators (fold state tracking) ✅
- [x] Bounded allocations (max 1000 foldable regions) ✅
- [x] Comprehensive assertions (GrainStyle compliance) ✅
- [x] Integrate folding into editor ✅
- **Files**: `src/aurora_folding.zig`, `src/aurora_editor.zig`

#### 1.3: GLM-4.6 Integration ✅ **COMPLETE**

- [x] Create `src/aurora_glm46.zig` module structure ✅
- [x] Implement GLM-4.6 client (Cerebras API integration) ✅
- [x] Code completion (ghost text at 1,000 tps) ✅
- [x] Editor integration (GLM-4.6 client optional, falls back to LSP) ✅
- [x] Create AI provider abstraction (`src/aurora_ai_provider.zig`) ✅
- [x] Create GLM-4.6 provider (`src/aurora_glm46_provider.zig`) ✅
- [x] Code transformation (refactor, extract, inline) ✅
- [x] Create AI transforms module (`src/aurora_ai_transforms.zig`) ✅
- [x] Tool calling (run `zig build`, `jj status`) ✅
- [x] Multi-file edits (context-aware) ✅
- [x] Bounded allocations (max 200K token context window) ✅
- [x] Comprehensive assertions (GrainStyle compliance) ✅
- [x] HTTP client timeout/error handling integration ✅
- **Files**: `src/aurora_glm46.zig`, `src/aurora_ai_provider.zig`, `src/aurora_glm46_provider.zig`, `src/aurora_ai_transforms.zig`, `src/aurora_editor.zig`

#### 1.4: Complete LSP Implementation ✅ **COMPLETE**

- [x] JSON-RPC 2.0 serialization/deserialization ✅
- [x] Snapshot model (incremental updates, Matklad-style) ✅
- [x] Cancellation support for pending requests ✅
- [x] Server communication (stdin/stdout with Content-Length headers) ✅
- [x] Document lifecycle (didOpen, didChange with incremental edits) ✅
- [x] Code intelligence (autocomplete, hover, go-to-definition, diagnostics) ✅
- [x] Bounded allocations (max 1000 snapshots, max 100 pending requests) ✅
- [x] Comprehensive assertions (GrainStyle compliance) ✅
- [x] GrainStyle compliance (u32 types, assertions, bounded allocations) ✅
- **Files**: `src/aurora_lsp.zig`, `src/aurora_editor.zig`

#### 1.5: Tree-sitter Integration ✅ **COMPLETE**

- [x] Create `src/aurora_tree_sitter.zig` module structure ✅
- [x] Syntax parsing and highlighting ✅
- [x] Structural editing support ✅
- [x] Code structure understanding ✅
- [x] Bounded parsing (max 10,000 nodes, max depth 100) ✅
- [x] Comprehensive assertions (GrainStyle compliance) ✅
- [x] Integrate tree-sitter into editor ✅
- **Files**: `src/aurora_tree_sitter.zig`, `src/aurora_editor.zig`

#### 1.6: Magit-Style VCS Integration ✅ **COMPLETE**

- [x] Create `src/aurora_vcs.zig` module structure ✅
- [x] Generate `.jj/status.jj` (readonly metadata, editable hunks) ✅
- [x] Generate `.jj/commit/*.diff` (readonly commit info, editable diff) ✅
- [x] Watch for edits, invoke `jj` commands ✅
- [x] Readonly spans for commit hashes, parent info, file paths, diff headers ✅
- [x] Bounded allocations (max 1000 virtual files, max 100 pending commands) ✅
- [x] Comprehensive assertions (GrainStyle compliance) ✅
- **Files**: `src/aurora_vcs.zig`

#### 1.7: Editor Core Features ✅ **COMPLETE**

- [x] Text buffer integration (uses `grain_buffer.zig` shared module) ✅
- [x] Cursor and selection management ✅
- [x] Editing operations (insert, delete, replace) ✅
- [x] Undo/redo functionality (bounded history: max 1024 entries) ✅
- [x] File save/load functionality ✅
- [x] Ghost text rendering (AI completion preview) ✅
- [x] Comprehensive assertions (GrainStyle compliance) ✅
- **Files**: `src/aurora_editor.zig`

#### 1.8: Text Rendering ✅ **COMPLETE**

- [x] Text rendering integration ✅
- [x] Visual rendering features (diagnostics, inlay hints, code lens) ✅
- [x] 8x8 bitmap font rendering ✅
- [x] Comprehensive assertions (GrainStyle compliance) ✅
- **Files**: `src/aurora_text_renderer.zig`, `src/aurora_editor.zig`

#### Coordination Tasks ✅ **COMPLETE**

- [x] Component API requirements provided to Component Library Agent (2c) (2026-01-01-084922-pst) ✅
- [x] Coordination alignment with Dream Browser Agent (2b) (2026-01-01-085414-pst) ✅

---

## Blocked Tasks

- [ ] Multi-pane layout management — **BLOCKED**: Waiting for Component Library Agent (2c) Component API design (Phase 0.5) and implementation (Phase 1) — **Unblocks**: When Component Library Agent (2c) provides Component API
- [ ] Component API integration for editor UI components — **BLOCKED**: Waiting for Component Library Agent (2c) Component API structure — **Unblocks**: When Component Library Agent (2c) finalizes Component API design and implements Component API
- [ ] River compositor integration — **BLOCKED**: Depends on River compositor availability — **Unblocks**: When River compositor is available

---

## Coordination Tasks

**With Aurora 2 Subcore**:
- [x] Initial coordination complete ✅
- [x] Component API requirements provided ✅
- [x] Coordination alignment with Dream Browser Agent (2b) ✅
- [ ] Weekly/bi-weekly check-ins (ongoing)
- [ ] Component API integration coordination (HIGH PRIORITY — waiting for Component Library Agent)
- [ ] River compositor integration coordination (when available)
- [ ] Shared module coordination (GrainBuffer, DAG Core) ✅

**With Component Library Agent (2c)**:
- [x] Component API requirements provided (2026-01-01-084922-pst) ✅
- [ ] Component API design finalization (Phase 0.5) — **BLOCKED**: Waiting for Component Library Agent
- [ ] Component API implementation (Phase 1) — **BLOCKED**: Waiting for Component Library Agent
- [ ] Component API integration for editor UI components — **BLOCKED**: Waiting for Component Library Agent
- [ ] UI component requirements coordination ✅
- [ ] Theme synchronization (if applicable)

**With Dream Browser Agent (2b)**:
- [x] Coordination alignment (2026-01-01-085414-pst) ✅
- [x] Shared Component API coordination needs identified ✅
- [ ] Via Aurora 2 Subcore for shared foundation coordination

---

## Phase 2: Enhancements and Integration ⏳ **IN PROGRESS** (Blocked on Component API)

**Date Started**: 2025-12-31  
**Priority**: HIGH  
**Status**: ⏳ **IN PROGRESS** (Blocked on Component API)

### 2.1: Multi-Pane Layout ⏳ **BLOCKED** (Waiting for Component API)

- [x] Create `src/aurora_layout.zig` module structure ✅
- [ ] Layout management (split panes, resize, focus) — **BLOCKED**: Waiting for Component API
- [ ] Component API integration for editor UI components — **BLOCKED**: Waiting for Component API
- [ ] River compositor integration (when available) — **BLOCKED**: Depends on River compositor
- [ ] Bounded allocations (max panes, max layout configurations)
- [ ] Comprehensive assertions (GrainStyle compliance)
- **Files**: `src/aurora_layout.zig`

### 2.2: Virtual File System (VFS) ⏳ **PLANNED**

- [ ] Create `src/aurora_vfs.zig` module structure (if needed)
- [ ] File system abstraction
- [ ] Virtual file handling
- [ ] Integration with editor for virtual file support
- [ ] Bounded allocations (max virtual files, max file handles)
- [ ] Comprehensive assertions (GrainStyle compliance)
- **Files**: `src/aurora_vfs.zig` (may be integrated into existing modules)

### 2.3: Advanced Editor Features ⏳ **PLANNED**

- [ ] Enhanced code lens (more LSP features)
- [ ] Inlay hints (type hints, parameter names)
- [ ] Symbol navigation (workspace symbols, document symbols)
- [ ] Code actions (quick fixes, refactorings)
- [ ] Format on save
- [ ] Find references
- [ ] Rename symbol
- [ ] Bounded allocations (max hints, max symbols)
- [ ] Comprehensive assertions (GrainStyle compliance)
- **Files**: `src/aurora_editor.zig`, `src/aurora_lsp.zig`

### 2.4: Testing and Documentation ⏳ **PLANNED**

- [ ] Comprehensive test coverage for all modules
- [ ] Integration tests for editor workflows
- [ ] Performance tests (large file handling, many folds)
- [ ] Documentation updates (API docs, usage examples)
- [ ] GrainStyle validation (all functions < 70 lines, max 2 assertions)
- **Files**: `tests/`, `docs/`

---

## Future Enhancements (Not Yet Planned)

### Phase 3: Advanced Features (Future)

- [ ] Multi-cursor editing
- [ ] Code snippets/templates
- [ ] Custom keybindings
- [ ] Plugin system (if needed)
- [ ] Theme customization
- [ ] Performance profiling tools

---

## Dependencies

### Shared Modules (Coordinated via Aurora 2 Subcore)
- ✅ `src/grain_buffer.zig` - Text buffer (shared with Component Library Agent)
- ✅ `src/dag_core.zig` - DAG (shared with all agents)
- ⏳ `src/shared/` - Shared modules (coordinated by Aurora 2 Subcore)

### External Dependencies
- ✅ LSP servers (language-specific, e.g., ZLS for Zig)
- ✅ GLM-4.6 API (Cerebras) - OpenAI-compatible endpoint
- ✅ Tree-sitter (C library via `@cImport` or bindings)
- ✅ Zig grammar (tree-sitter-zig)

### Blocking Dependencies
- ⏳ **Component Library Agent (2c) Component API** — **BLOCKING**: Multi-pane layout implementation
  - Component API design (Phase 0.5) — **BLOCKING**
  - Component API implementation (Phase 1) — **BLOCKING**

---

## Grain Style Compliance

All tasks must ensure **Grain Style** compliance:

- [x] `grain_case` function names ✅
- [x] Explicit `u32`/`u64` types (not `usize`/`isize`) ✅
- [x] `grainwrap-100` (max 100 characters per line) ✅
- [x] `grain validate-70` (max 70 lines per function) ✅
- [x] Minimum 2 assertions per function ✅
- [x] Bounded allocations ✅
- [x] All compiler warnings enabled ✅
- [ ] Zero technical debt policy (ongoing)

---

**Last Updated**: 2026-01-01-092253-pst  
**Agent**: Grain Dream Editor Agent (2a)  
**Parent Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Status**: ✅ Phase 1 Complete — Phase 2 In Progress (Blocked on Component API)
