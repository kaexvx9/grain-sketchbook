# Cursor CLI: Two-Agent Setup Quick Reference

**Date**: 2026-01-23-160000-pst  
**Purpose**: Quick reference for setting up two Cursor CLI agents

---

## Terminal 1: Core 1 Subcore (Rye Style Conversion)

**Working Directory**: `/home/xy/ry`

**Prompt**:
```
You are Core 1 Subcore, converting Skate desktop modules to Rye Style.

Status: 9 modules converted (block.ry, bracket_matching.ry, etc.)
Current: ai_insights.zig → ai_insights.ry (3 functions exceed 64-line limit)

Goal: Convert remaining Skate modules to Rye Style
- Use: ./rye/zig-out/bin/rye check <file>
- Constraints: 64 lines, 128 chars, "why" comments
- Docs: docs/rye/0023-rye-style-top-down-application-guide.md

Coordination: Vantage 3 working on Rye compiler fork (bottom-up)
Integration: Week 9+ when Phase 3 stdlib complete

Continue Rye Style conversion.
```

**Key Files**:
- `src/grain_skate/ai_insights.zig` (current work)
- `docs/rye/0024-rye-style-implementation-roadmap.md`
- `docs/rye/0072-vantage-3-phase2-phase3-progress-acknowledgment.md`

---

## Terminal 2: Vantage 3 Subcore (Rye Compiler Fork)

**Working Directory**: `/home/xy/codeberg/ryelang/rye`

**Prompt**:
```
You are Vantage 3 Subcore, developing Rye compiler fork (bottom-up).

Status: Phase 2 (76% complete), Phase 3 foundation (complete)
Current: Issue 2 kernel testing, Phase 3 stdlib (mem, fmt, io)

Goal: Complete Phase 2/3, test with Basin kernel
- Repository: /home/xy/codeberg/ryelang/rye (source of truth)
- Basin kernel: /home/xy/ry/src/kernel/
- Docs: docs/rye/0011-rye-compiler-fork-plan.md

Coordination: Core 1 converting Skate to Rye Style (top-down)
Integration: Week 9+ when Phase 3 stdlib complete

Continue Rye compiler fork development.
```

**Key Files**:
- `src/arch/riscv64/CodeGen.zig` (frame layout fix)
- `lib/std/toroidal.zig` (toroidal types)
- `lib/std/garden.zig` (garden allocator)
- `docs/core-coordination/2026-01-23-143000-pst_rye-compiler-phase2-phase3-progress-update.md`

---

## Shared Context

**Rye Style Constraints**:
- 64-line function limit (2^6)
- 128-character line limit (2^7)
- "why" comments required for public functions
- No recursion
- Minimum 2 assertions per function

**Basin Kernel Goals**:
- RISC-V64 kernel
- REPL shell
- Expression evaluator
- Variable management
- DAG-based events

**Coordination Documents**:
- `docs/core-coordination/shared-context.md` (shared context)
- `docs/core-coordination/core1-agent-context.md` (Core 1 full context)
- `docs/core-coordination/vantage3-agent-context.md` (Vantage 3 full context)
- `docs/core-coordination/COORDINATION_GUIDE.md` (complete guide)
- `docs/core-coordination/2026-01-23-160000-pst_cursor-cli-two-agent-coordination-prompt.md` (original prompt)
- `docs/rye/0072-vantage-3-phase2-phase3-progress-acknowledgment.md`

---

## Setup Commands

**Terminal 1 (Core 1)**:
```bash
cd /home/xy/ry
./docs/core-coordination/setup-core1-agent.sh
# Script will display prompt and context
```

**Terminal 2 (Vantage 3)**:
```bash
cd /home/xy/codeberg/ryelang/rye
/home/xy/ry/docs/core-coordination/setup-vantage3-agent.sh
# Script will display prompt and context
```

## Coordination Files

**Shared Context**: `docs/core-coordination/shared-context.md`  
**Core 1 Progress**: `docs/core-coordination/core1-progress.md`  
**Vantage 3 Progress**: `docs/core-coordination/vantage3-progress.md`  
**Agent Messages**: `docs/core-coordination/agent-messages/`  
**Full Guide**: `docs/core-coordination/COORDINATION_GUIDE.md`

---

**Date**: 2026-01-23-160000-pst  
**Status**: 📋 **QUICK REFERENCE** — Use with Cursor CLI setup
