# Shared Context: Core 1 & Vantage 3 Coordination

**Last Updated**: 2026-01-23-161235-pst  
**Purpose**: Shared context file for Core 1 Subcore and Vantage 3 Subcore coordination

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
- See: `docs/rye_style.md`

### Validation
- Use `rye check <file>` or compile with Rye compiler to validate
- Rye Style enforcement is now active in the compiler (Phase 4 complete)
- All core checks active: function length (64 lines), line length (128 chars), why comments, explicit types
- Must pass with zero violations before renaming `.zig` → `.ry`

---

## Basin Kernel Goals

**Target**: RISC-V64 kernel with:
- REPL shell
- Expression evaluator
- Variable management
- DAG-based event system
- Rye Style compliance

**Kernel Source**: `/home/xy/grain-sketchbook/src/kernel/`

---

## Repository Structure

**Workspace**: `/home/xy/grain-sketchbook` (monorepo)  
**Rye Compiler Fork**: `/home/xy/codeberg/ryelang/rye` (external, source of truth)  
**Rye Compiler Mirror**: `/home/xy/grain-sketchbook/grainstore/codeberg/ryelang/rye` (synced via daemon)  
**Skate Application**: `/home/xy/grain-sketchbook/src/grain_skate/`  
**Basin Kernel**: `/home/xy/grain-sketchbook/src/kernel/`  
**Rye Documentation**: `/home/xy/grain-sketchbook/docs/rye/`  
**Coordination Docs**: `/home/xy/grain-sketchbook/docs/core-coordination/`

---

## Coordination Pattern

### Two Complementary Approaches

**Core 1 Subcore (Top-Down)**:
- Converting Skate modules to Rye Style (`.zig` → `.ry`)
- Using Phase 1 transpiler (`rye check`) for validation
- Preparing code for Rye compiler fork
- Works with current Zig compiler

**Vantage 3 Subcore (Bottom-Up)**:
- ✅ RISC-V freestanding fixes complete (Phase 2)
- ✅ Toroidal/garden types complete (Phase 3)
- ✅ Rye Style enforcement complete (Phase 4 core checks)
- ✅ Basic stdlib available (mem, fmt, io)
- Testing with Basin kernel

**Integration Point**: ✅ **COMPLETE**
- Core 1 has converted all 19 Skate modules to Rye Style (100% complete)
- Vantage 3 has stable Rye compiler with Rye Style enforcement active
- Compiler now enforces all core Rye Style constraints automatically
- All modules validated and ready for compiler validation testing

---

## Timeline

- ✅ **Phase 2**: RISC-V freestanding fixes — COMPLETE
- ✅ **Phase 3**: Toroidal/garden types + stdlib — COMPLETE
- ✅ **Phase 4**: Rye Style enforcement — COMPLETE (core checks)
- ✅ **Complete**: Core 1 converted all Skate modules (19/19 complete, 100%)
- ✅ **Ready**: Rye compiler with style enforcement available for use
- ✅ **Integration**: All modules validated, ready for compiler validation testing
- ✅ **Phase 5**: GUI Foundation — `.ry` file extension support **COMPLETE** (compiler rebuild needed)

---

## Key Documentation

### Rye Style
- **Rye Style Guide**: `docs/rye_style.md`
- **Top-Down Guide**: `docs/rye/0023-rye-style-top-down-application-guide.md`
- **Implementation Roadmap**: `docs/rye/0024-rye-style-implementation-roadmap.md`

### Rye Compiler
- **Rye Compiler Fork Plan**: `docs/rye/0011-rye-compiler-fork-plan.md`
- **RISC-V Fix Strategy**: `docs/rye/0013-riscv-freestanding-fix-strategy.md`
- **Toroidal/Garden Spec**: `docs/rye/0014-toroidal-garden-stdlib-spec.md`
- **Skate Porting Roadmap**: `docs/rye/0021-skate-porting-readiness-roadmap.md`

### Coordination
- **Full Coordination Prompt**: `docs/core-coordination/2026-01-23-160000-pst_cursor-cli-two-agent-coordination-prompt.md`
- **Quick Reference**: `docs/core-coordination/cursor-cli-setup-quick-reference.md`
- **Progress Updates**: `docs/core-coordination/core1-progress.md` and `docs/core-coordination/vantage3-progress.md`

---

## Communication Protocol

### Progress Updates
- Each agent updates their respective progress file:
  - Core 1: `docs/core-coordination/core1-progress.md`
  - Vantage 3: `docs/core-coordination/vantage3-progress.md`
- Both agents read this shared context file
- Both agents read each other's progress files

### Conflict Prevention
- Core 1 works in `/home/xy/grain-sketchbook/src/grain_skate/` (monorepo)
- Vantage 3 works in `/home/xy/codeberg/ryelang/rye` (external repo)
- Shared documentation in `/home/xy/grain-sketchbook/docs/` (monorepo)
- When updating shared docs, check the other agent's progress file first

### Coordination Messages
- Use `docs/core-coordination/agent-messages/` for direct communication
- Format: `YYYY-MM-DD-HHMMSS-pst_agent-name_message-type.md`
- Types: `status-update`, `question`, `coordination-request`, `blocking-issue`

---

**Status**: ✅ **ACTIVE** — Both agents should reference this file regularly
