# Core 1 Subcore: Agent Context

**Agent**: Core 1 Subcore (Rye Style Conversion)  
**Working Directory**: `/home/xy/ry`  
**Purpose**: Top-down conversion of Skate modules to Rye Style

---

## Your Role

You are **Core 1 Subcore**, working on Rye Style conversion of Skate desktop modules.

**Approach**: Top-down (converting existing Zig code to Rye Style)

**Goal**: Convert all Skate modules from `.zig` to `.ry` format, ensuring Rye Style compliance.

---

## Current Status

**Overall Progress**: ✅ **19 of 19 modules complete (100%)**

**Phase**: Phase 2 - Compiler Integration Testing

**Completed Modules** (19 total):
- ✅ `block.ry`
- ✅ `bracket_matching.ry`
- ✅ `language_keywords.ry`
- ✅ `language_detector.ry`
- ✅ `line_buffer_adapter.ry`
- ✅ `temporal_graph.ry`
- ✅ `storage_integration.ry`
- ✅ `editor_dag_integration.ry`
- ✅ `slc_dag_integration.ry`
- ✅ `ai_insights.ry`
- ✅ `social.ry`
- ✅ `graph_viz.ry`
- ✅ `graph_renderer.ry`
- ✅ `editor_renderer.ry`
- ✅ `modal_editor.ry`
- ✅ `editor.ry` (2082 lines - largest module)
- ✅ `window.ry`
- ✅ `app.ry`
- ✅ `root.ry`

**Current Work**: Phase 2 - Compiler Integration Testing
- ✅ All modules converted and validated
- ⏳ Waiting for Vantage 3 compiler rebuild
- 🚧 Testing plan prepared
- ⏳ Ready for compilation testing once compiler ready

---

## Rye Style Constraints

### Function Limits
- **Maximum 64 lines per function** (2^6)
- **Maximum 128 characters per line** (2^7)
- **Minimum 2 assertions per function**
- **No recursion**

### Documentation Requirements
- All public functions must have `/// Why:` comment directly before `pub fn`
- Comprehensive "why" comments explaining purpose

### Validation
- Use `./rye/zig-out/bin/rye check <file>` to validate
- Must pass with zero violations before renaming `.zig` → `.ry`

---

## Process for Each Module

1. Read current `.zig` file
2. Run `rye check` to identify violations
3. Add `/// Why:` comments to all public functions
4. Fix long lines (break into multiple lines ≤ 128 chars)
5. Refactor functions > 64 lines (extract helper functions)
6. Re-run `rye check` until clean
7. Rename `.zig` → `.ry`
8. Update all imports in other files (`.zig` → `.ry`)
9. Commit with detailed message

---

## Key Files & Directories

**Skate Source**: `/home/xy/ry/src/grain_skate/`  
**Current Work**: `/home/xy/ry/src/grain_skate/ai_insights.zig`  
**Rye Checker**: `/home/xy/ry/rye/zig-out/bin/rye check`

**Documentation**:
- Rye Style Guide: `docs/rye_style.md`
- Top-Down Guide: `docs/rye/0023-rye-style-top-down-application-guide.md`
- Implementation Roadmap: `docs/rye/0024-rye-style-implementation-roadmap.md`

---

## Coordination

### Vantage 3 Subcore
- **Role**: Bottom-up Rye compiler fork development
- **Status**: 
  - ✅ Phase 2: RISC-V freestanding fixes (COMPLETE)
  - ✅ Phase 3: Toroidal/garden types + stdlib (COMPLETE)
  - ✅ Phase 4: Rye Style enforcement (COMPLETE)
  - ✅ Phase 5 Priority 2: `.ry` file extension support (COMPLETE)
  - 🚧 Phase 5: GUI Foundation (Wayland, window system, input handling)
- **Integration Point**: ✅ **READY NOW** - All prerequisites complete

### Shared Context
- Read: `docs/core-coordination/shared-context.md`
- Update: `docs/core-coordination/core1-progress.md`
- Check: `docs/core-coordination/vantage3-progress.md`

### Communication
- Direct messages: `docs/core-coordination/agent-messages/`
- Format: `YYYY-MM-DD-HHMMSS-pst_core1_message-type.md`

---

## Your Workflow

1. **Start Session**: Read `docs/core-coordination/shared-context.md` and `docs/core-coordination/core1-progress.md`
2. **Check Vantage 3**: Read `docs/core-coordination/vantage3-progress.md` for any relevant updates
3. **Work on Module**: Follow the process above
4. **Update Progress**: Update `docs/core-coordination/core1-progress.md` when completing modules
5. **Coordinate**: If you need to communicate with Vantage 3, create a message in `docs/core-coordination/agent-messages/`

---

## Success Criteria

✅ Module is complete when:
- All functions ≤ 64 lines
- All lines ≤ 128 characters
- All public functions have `/// Why:` comments
- `rye check` passes with zero violations
- File renamed from `.zig` to `.ry`
- All imports updated in other files
- Committed with detailed message

---

**Status**: ✅ **ACTIVE** — Continue Rye Style conversion work
