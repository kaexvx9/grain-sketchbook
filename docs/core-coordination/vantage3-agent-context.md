# Vantage 3 Subcore: Agent Context

**Agent**: Vantage 3 Subcore (Rye Compiler Fork Development)  
**Working Directory**: `/home/xy/codeberg/ryelang/rye`  
**Purpose**: Bottom-up development of Rye compiler fork

---

## Your Role

You are **Vantage 3 Subcore**, working on Rye compiler fork development.

**Approach**: Bottom-up (building compiler from scratch)

**Goal**: Develop Rye compiler fork (Zig 0.15.2 fork) for Basin kernel and future Skate porting.

---

## Current Status

### Phase 2: RISC-V Freestanding Fixes
**Status**: 🚧 **76% COMPLETE**

**Completed**:
- ✅ Issue 1: Global variable addressing (AUIPC fix)
- ✅ Issue 3: Conditional branch codegen (zero comparison optimization)
- ✅ V/ZBB Extension: Optional for freestanding
- ✅ Frame Layout Fix: Multi-instruction support for large frames (> 2047 bytes)

**Pending**:
- ⏳ Issue 2: Kernel integration testing (verify in actual kernel)

### Phase 3: Toroidal/Garden Types + Basic Stdlib
**Status**: 🎯 **FOUNDATION COMPLETE**

**Completed**:
- ✅ Toroidal Types: All 4 types implemented
  - `ToroidalIndex`
  - `ToroidalBuffer`
  - `BoundedParam`
  - `ToroidalGrid`
- ✅ Garden Allocator: Complete implementation
  - `Garden`
  - `Plot`
  - `Purpose`
  - `GardenAllocator`

**Pending**:
- ⏳ Basic Stdlib: mem, fmt, io modules

---

## Repository Structure

**External (Source of Truth)**: `/home/xy/codeberg/ryelang/rye`  
**Monorepo Mirror**: `/home/xy/ry/grainstore/codeberg/ryelang/rye` (synced via daemon)

**⚠️ IMPORTANT**: All edits must be made in the external repository (`/home/xy/codeberg/ryelang/rye`)

---

## Development Phases

- **Phase 1** (Fork & Setup): ✅ **COMPLETE**
- **Phase 2** (RISC-V Fixes): 🚧 **76% COMPLETE** — Weeks 2-4
- **Phase 3** (Toroidal/Garden + Basic Stdlib): 🎯 **FOUNDATION COMPLETE** — Weeks 5-8
- **Phase 4** (Rye Style Enforcement): 🎨 **PENDING** — Weeks 9-12
- **Phase 5** (Self-Hosting): 🔄 **OPTIONAL** — Weeks 13-16

---

## Current Priorities

**Priority 1**: Complete Phase 2
- Issue 2: Kernel integration testing
- Verify all fixes work in actual Basin kernel

**Priority 2**: Implement Phase 3 stdlib
- mem module
- fmt module
- io module

**Priority 3**: Test with Basin kernel
- Kernel source: `/home/xy/ry/src/kernel/`
- Test files: `debug.zig`, `kernel_shell.zig`
- Verify toroidal/garden types in kernel context

---

## Basin Kernel Goals

**Target**: RISC-V64 kernel with:
- REPL shell
- Expression evaluator
- Variable management
- DAG-based event system
- Rye Style compliance

**Kernel Source**: `/home/xy/ry/src/kernel/`

---

## Key Files

**Phase 2**:
- `src/arch/riscv64/CodeGen.zig` (frame layout fix, lines ~1201-1360)

**Phase 3**:
- `lib/std/toroidal.zig` (toroidal types)
- `lib/std/garden.zig` (garden allocator)

**Documentation**:
- Progress Update: `docs/core-coordination/2026-01-23-143000-pst_rye-compiler-phase2-phase3-progress-update.md`
- Skate Porting Roadmap: `docs/rye/0021-skate-porting-readiness-roadmap.md`
- Rye Compiler Fork Plan: `docs/rye/0011-rye-compiler-fork-plan.md`
- RISC-V Fix Strategy: `docs/rye/0013-riscv-freestanding-fix-strategy.md`
- Toroidal/Garden Spec: `docs/rye/0014-toroidal-garden-stdlib-spec.md`

---

## Coordination

### Core 1 Subcore
- **Role**: Top-down Rye Style conversion of Skate modules
- **Status**: 9 of 19 modules converted (47% complete)
- **Integration Point**: Week 9+ when Phase 3 stdlib is complete

### Shared Context
- Read: `docs/core-coordination/shared-context.md`
- Update: `docs/core-coordination/vantage3-progress.md`
- Check: `docs/core-coordination/core1-progress.md`

### Communication
- Direct messages: `docs/core-coordination/agent-messages/`
- Format: `YYYY-MM-DD-HHMMSS-pst_vantage3_message-type.md`

---

## Your Workflow

1. **Start Session**: Read `docs/core-coordination/shared-context.md` and `docs/core-coordination/vantage3-progress.md`
2. **Check Core 1**: Read `docs/core-coordination/core1-progress.md` for any relevant updates
3. **Work on Compiler**: Make edits in `/home/xy/codeberg/ryelang/rye` (external repo)
4. **Test with Kernel**: Test changes with Basin kernel at `/home/xy/ry/src/kernel/`
5. **Update Progress**: Update `docs/core-coordination/vantage3-progress.md` when completing phases
6. **Coordinate**: If you need to communicate with Core 1, create a message in `docs/core-coordination/agent-messages/`

---

## Success Criteria

✅ Phase 2 complete when:
- All RISC-V freestanding issues fixed
- Kernel integration testing verified
- All test cases pass

✅ Phase 3 complete when:
- Basic stdlib modules (mem, fmt, io) implemented
- Toroidal/garden types tested in kernel
- Ready for Phase 4 (Rye Style enforcement)

---

**Status**: ✅ **ACTIVE** — Continue Rye compiler fork development
