# Cursor CLI: Two-Agent Coordination Pattern Setup Prompt

**Date**: 2026-01-23-160000-pst  
**Purpose**: Prompt for Cursor CLI to set up two-agent coordination pattern for Core 1 and Vantage 3 Subcores  
**Target**: Cursor CLI agents working in parallel terminals

---

## Request for Cursor CLI

**Context**: We need to set up a two-CLI-agent coordination pattern where:
1. **Terminal 1 (Core 1 Subcore)**: Continues existing Rye Style conversion work on Skate modules
2. **Terminal 2 (Vantage 3 Subcore)**: New from-scratch prompt for Rye compiler fork development

Both agents should be aware of:
- Rye Style constraints (64-line functions, 128-char lines, "why" comments)
- Basin kernel goals (RISC-V64 kernel, REPL shell, expression evaluator)
- Coordination between top-down (Core 1) and bottom-up (Vantage 3) approaches

**Question**: Can you provide advice and setup instructions for creating this two-CLI-agent coordination pattern?

---

## Project Context

### Repository Structure

**Workspace**: `/home/xy/ry` (monorepo)  
**Rye Compiler Fork**: `/home/xy/codeberg/ryelang/rye` (external, source of truth)  
**Rye Compiler Mirror**: `/home/xy/ry/grainstore/codeberg/ryelang/rye` (synced via daemon)  
**Skate Application**: `/home/xy/ry/src/grain_skate/`  
**Basin Kernel**: `/home/xy/ry/src/kernel/`  
**Rye Documentation**: `/home/xy/ry/docs/rye/`  
**Coordination Docs**: `/home/xy/ry/docs/core-coordination/`

---

## Core 1 Subcore: Rye Style Conversion (Top-Down)

### Current Status

**Goal**: Convert Skate desktop modules from Zig to Rye Style using Phase 1 transpiler.

**Completed Modules** (9 of 19):
1. ✅ `block.ry`
2. ✅ `bracket_matching.ry`
3. ✅ `language_keywords.ry`
4. ✅ `language_detector.ry`
5. ✅ `line_buffer_adapter.ry`
6. ✅ `temporal_graph.ry`
7. ✅ `storage_integration.ry`
8. ✅ `editor_dag_integration.ry`
9. ✅ `slc_dag_integration.ry`

**Current Work**: Converting `ai_insights.zig` → `ai_insights.ry`
- Status: In progress (some "why" comments added, function length issues remain)
- Issues: 3 functions exceed 64-line limit (`send_llm_request`, `suggest_connections`, `summarize_subgraph`)

**Remaining Modules** (10):
- `ai_insights.ry` (in progress)
- `social.ry`
- `graph_viz.ry`
- `graph_renderer.ry`
- `editor_renderer.ry`
- `modal_editor.ry`
- `editor.ry`
- `window.ry`
- `app.ry`
- `root.ry`

### Rye Style Constraints

**Function Limits**:
- Maximum 64 lines per function (2^6)
- Maximum 128 characters per line (2^7)
- Minimum 2 assertions per function
- No recursion

**Documentation**:
- All public functions must have `/// Why:` comment directly before `pub fn`
- Comprehensive "why" comments explaining purpose

**Validation**:
- Use `./rye/zig-out/bin/rye check <file>` to validate
- Must pass with zero violations before renaming `.zig` → `.ry`

### Process for Each Module

1. Read current `.zig` file
2. Run `rye check` to identify violations
3. Add `/// Why:` comments to all public functions
4. Fix long lines (break into multiple lines ≤ 128 chars)
5. Refactor functions > 64 lines (extract helper functions)
6. Re-run `rye check` until clean
7. Rename `.zig` → `.ry`
8. Update all imports in other files (`.zig` → `.ry`)
9. Commit with detailed message

### Key Documentation

- **Rye Style Guide**: `docs/rye_style.md`
- **Top-Down Guide**: `docs/rye/0023-rye-style-top-down-application-guide.md`
- **Implementation Roadmap**: `docs/rye/0024-rye-style-implementation-roadmap.md`
- **Conversion Clarification**: `docs/rye/0022-rye-style-conversion-vs-compiler-fork.md`
- **Progress Acknowledgment**: `docs/rye/0072-vantage-3-phase2-phase3-progress-acknowledgment.md`

---

## Vantage 3 Subcore: Rye Compiler Fork (Bottom-Up)

### Current Status

**Goal**: Develop Rye compiler fork (Zig 0.15.2 fork) for Basin kernel and future Skate porting.

**Phase 2: RISC-V Freestanding Fixes** — 76% Complete
- ✅ Issue 1: Global variable addressing (AUIPC fix)
- ✅ Issue 3: Conditional branch codegen (zero comparison optimization)
- ✅ V/ZBB Extension: Optional for freestanding
- ✅ Frame Layout Fix: Multi-instruction support for large frames (> 2047 bytes)
- ⏳ Issue 2: Kernel integration testing (verify in actual kernel)

**Phase 3: Toroidal/Garden Types + Basic Stdlib** — Foundation Complete
- ✅ Toroidal Types: All 4 types implemented (`ToroidalIndex`, `ToroidalBuffer`, `BoundedParam`, `ToroidalGrid`)
- ✅ Garden Allocator: Complete implementation (`Garden`, `Plot`, `Purpose`, `GardenAllocator`)
- ⏳ Basic Stdlib: mem, fmt, io modules (pending)

**Repository**:
- External (source of truth): `/home/xy/codeberg/ryelang/rye`
- Monorepo mirror: `/home/xy/ry/grainstore/codeberg/ryelang/rye`
- All edits must be made in external repository

### Rye Compiler Development Phases

- **Phase 1** (Fork & Setup): ✅ **COMPLETE**
- **Phase 2** (RISC-V Fixes): 🚧 **76% COMPLETE** — Weeks 2-4
- **Phase 3** (Toroidal/Garden + Basic Stdlib): 🎯 **FOUNDATION COMPLETE** — Weeks 5-8
- **Phase 4** (Rye Style Enforcement): 🎨 **PENDING** — Weeks 9-12
- **Phase 5** (Self-Hosting): 🔄 **OPTIONAL** — Weeks 13-16

### Basin Kernel Goals

**Target**: RISC-V64 kernel with:
- REPL shell
- Expression evaluator
- Variable management
- DAG-based event system
- Rye Style compliance

**Kernel Source**: `/home/xy/ry/src/kernel/`  
**Test Files**:
- `debug.zig` — Compiles successfully ✅
- `kernel_shell.zig` — Large stack frame (tests multi-instruction support)

### Key Documentation

- **Progress Update**: `docs/core-coordination/2026-01-23-143000-pst_rye-compiler-phase2-phase3-progress-update.md`
- **Skate Porting Roadmap**: `docs/rye/0021-skate-porting-readiness-roadmap.md`
- **Rye Compiler Fork Plan**: `docs/rye/0011-rye-compiler-fork-plan.md`
- **RISC-V Fix Strategy**: `docs/rye/0013-riscv-freestanding-fix-strategy.md`
- **Toroidal/Garden Spec**: `docs/rye/0014-toroidal-garden-stdlib-spec.md`
- **Vantage 3 Summary**: `docs/rye/VANTAGE_3_SUBCORE_SUMMARY.md`

---

## Coordination Pattern

### Two Complementary Approaches

**Core 1 Subcore (Top-Down)**:
- Converting Skate modules to Rye Style (`.zig` → `.ry`)
- Using Phase 1 transpiler (`rye check`) for validation
- Preparing code for Rye compiler fork
- Works with current Zig compiler

**Vantage 3 Subcore (Bottom-Up)**:
- Developing Rye compiler fork
- Fixing RISC-V freestanding bugs
- Implementing toroidal/garden types
- Building Rye stdlib
- Testing with Basin kernel

**Integration Point**: Week 9+ (when Phase 3 stdlib is complete)
- Core 1 will have Rye Style compliant code ready
- Vantage 3 will have stable Rye compiler with basic stdlib
- Smooth transition from Zig compiler to Rye compiler

### Shared Context

**Rye Style**:
- 64-line function limit
- 128-character line limit
- "why" comments required
- No recursion
- Minimum 2 assertions per function

**Basin Kernel Goals**:
- RISC-V64 kernel
- REPL shell
- Expression evaluator
- Variable management
- DAG-based events

**Timeline**:
- **Now - Week 9**: Core 1 converts Skate, Vantage 3 completes Phase 2/3
- **Week 9+**: Integration point, Skate can port to Rye compiler fork

---

## Request for Cursor CLI

### Terminal 1: Core 1 Subcore (Continue Existing Work)

**Context to Load**:
- Current Skate Rye Style conversion status (9 modules complete)
- Current work: `ai_insights.zig` → `ai_insights.ry` (in progress)
- Rye Style constraints and validation process
- Remaining modules to convert
- Coordination with Vantage 3 Subcore

**Prompt**:
```
You are Core 1 Subcore, working on Rye Style conversion of Skate desktop modules.

Current Status:
- 9 modules converted to Rye Style (block.ry, bracket_matching.ry, etc.)
- Current work: Converting ai_insights.zig → ai_insights.ry
- Issues: 3 functions exceed 64-line limit (send_llm_request, suggest_connections, summarize_subgraph)

Your Goal:
- Continue converting remaining Skate modules to Rye Style
- Use `./rye/zig-out/bin/rye check` to validate
- Ensure all code meets Rye Style constraints (64 lines, 128 chars, "why" comments)
- Prepare code for Rye compiler fork (Week 9+ integration point)

Key Documentation:
- Rye Style Guide: docs/rye_style.md
- Top-Down Guide: docs/rye/0023-rye-style-top-down-application-guide.md
- Progress: docs/rye/0072-vantage-3-phase2-phase3-progress-acknowledgment.md

Coordination:
- Vantage 3 Subcore is working on Rye compiler fork (bottom-up)
- Integration point: Week 9+ when Phase 3 stdlib is complete
- Both aware of Rye Style constraints and Basin kernel goals

Continue with the best path forward for Rye Style conversion.
```

### Terminal 2: Vantage 3 Subcore (New From-Scratch Prompt)

**Context to Load**:
- Rye compiler fork development status
- Phase 2 (76% complete) and Phase 3 foundation (complete)
- Basin kernel goals and testing
- Coordination with Core 1 Subcore

**Prompt**:
```
You are Vantage 3 Subcore, working on Rye compiler fork development (bottom-up approach).

Current Status:
- Phase 2: 76% complete (frame layout fix done, Issue 2 kernel testing pending)
- Phase 3 Foundation: Complete (toroidal types + garden allocator available)
- Phase 3 Stdlib: Pending (mem, fmt, io modules needed)

Repository:
- External (source of truth): /home/xy/codeberg/ryelang/rye
- Monorepo mirror: /home/xy/ry/grainstore/codeberg/ryelang/rye
- All edits must be made in external repository

Your Goals:
- Complete Phase 2 (Issue 2 kernel integration testing)
- Implement Phase 3 stdlib (mem, fmt, io modules)
- Test with Basin kernel (/home/xy/ry/src/kernel/)
- Prepare for Phase 4 (Rye Style enforcement)

Basin Kernel Goals:
- RISC-V64 kernel with REPL shell
- Expression evaluator
- Variable management
- DAG-based events
- Rye Style compliance

Coordination:
- Core 1 Subcore is converting Skate to Rye Style (top-down)
- Integration point: Week 9+ when Phase 3 stdlib is complete
- Both aware of Rye Style constraints and Basin kernel goals

Key Documentation:
- Progress Update: docs/core-coordination/2026-01-23-143000-pst_rye-compiler-phase2-phase3-progress-update.md
- Skate Porting Roadmap: docs/rye/0021-skate-porting-readiness-roadmap.md
- Rye Compiler Fork Plan: docs/rye/0011-rye-compiler-fork-plan.md

Continue with the best path forward for Rye compiler fork development.
```

---

## Questions for Cursor CLI

1. **Terminal Setup**: What's the best way to set up two separate Cursor CLI terminals with different contexts?

2. **Context Sharing**: How should the two agents share context about:
   - Rye Style constraints
   - Basin kernel goals
   - Coordination updates
   - Progress synchronization

3. **File Coordination**: How should the agents coordinate when:
   - Core 1 updates Skate modules (`.zig` → `.ry`)
   - Vantage 3 updates Rye compiler (external repo)
   - Both need to be aware of shared documentation

4. **Progress Updates**: What's the best pattern for:
   - Core 1 reporting Skate conversion progress
   - Vantage 3 reporting compiler development progress
   - Cross-referencing coordination documents

5. **Conflict Prevention**: How to prevent conflicts when:
   - Both agents work on related files
   - Documentation updates overlap
   - Build system changes affect both

6. **Validation**: How should both agents:
   - Validate Rye Style compliance
   - Test Basin kernel compilation
   - Ensure coordination documents stay synchronized

---

## Recommended Setup Pattern

### Option 1: Separate Terminal Sessions

**Terminal 1 (Core 1)**:
```bash
cd /home/xy/ry
# Load Core 1 context
cursor-cli --context docs/core-coordination/2026-01-23-160000-pst_cursor-cli-two-agent-coordination-prompt.md
# Use Core 1 prompt from above
```

**Terminal 2 (Vantage 3)**:
```bash
cd /home/xy/codeberg/ryelang/rye
# Load Vantage 3 context
cursor-cli --context /home/xy/ry/docs/core-coordination/2026-01-23-160000-pst_cursor-cli-two-agent-coordination-prompt.md
# Use Vantage 3 prompt from above
```

### Option 2: Shared Context File

Create a shared context file that both agents can reference:
- `docs/core-coordination/shared-context.md` (updated by both agents)
- Contains: Rye Style constraints, Basin kernel goals, coordination status

### Option 3: Coordination Channel

Use coordination documents as communication channel:
- Core 1 updates: `docs/core-coordination/core1-progress.md`
- Vantage 3 updates: `docs/core-coordination/vantage3-progress.md`
- Both read: `docs/core-coordination/shared-context.md`

---

## Success Criteria

**Two-Agent Coordination Pattern Works When**:
- ✅ Both agents can work independently without conflicts
- ✅ Both agents are aware of shared context (Rye Style, Basin goals)
- ✅ Progress updates are synchronized
- ✅ Coordination documents stay current
- ✅ No file conflicts or overwrites
- ✅ Both agents can reference each other's work

---

## Next Steps

1. **Review this prompt** with Cursor CLI
2. **Get advice** on best two-agent coordination pattern
3. **Set up Terminal 1** (Core 1 Subcore) with existing context
4. **Set up Terminal 2** (Vantage 3 Subcore) with new from-scratch prompt
5. **Test coordination** between both agents
6. **Refine pattern** based on results

---

**Date**: 2026-01-23-160000-pst  
**Status**: 📋 **PROMPT** — Ready for Cursor CLI review and advice

**Goal**: Establish robust two-agent coordination pattern for parallel development of Rye Style conversion (Core 1) and Rye compiler fork (Vantage 3).
