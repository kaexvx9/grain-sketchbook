# Rye Compiler Fork: Executive Summary

**Date**: 2026-01-22-064042-pst  
**Status**: ✅ **PLANNING COMPLETE** — Ready to proceed with fork  
**Repository**: `codeberg.org/ryelang/rye` (to be created)

---

## Quick Reference

**All Planning Documents**:
1. **Fork Plan**: `docs/rye/0011-rye-compiler-fork-plan.md` — Comprehensive strategy
2. **Setup Guide**: `docs/rye/0012-rye-repository-setup-guide.md` — Repository creation steps
3. **RISC-V Fixes**: `docs/rye/0013-riscv-freestanding-fix-strategy.md` — Bug fix strategy
4. **Stdlib Spec**: `docs/rye/0014-toroidal-garden-stdlib-spec.md` — Toroidal/garden types
5. **Style Enforcement**: `docs/rye/0015-rye-style-compiler-enforcement.md` — Compiler constraints

---

## What We're Building

**Rye Compiler** — Fork of Zig 0.15.2, adapted for:
- ✅ RISC-V freestanding codegen fixes (4 critical bugs)
- ✅ Toroidal/garden types as first-class features
- ✅ Rye Style enforcement at compiler level
- ✅ Chronological versioning (non-semantic)
- ✅ Garden-allocation model (not Linux heap model)

**Target**: Native Rye compiler that compiles `.ry` → machine code (Phase 2)

---

## Key Decisions

### 1. Fork Zig 0.15.2

**Base**: https://codeberg.org/ziglang/zig/src/tag/0.15.2  
**Repository**: `codeberg.org/ryelang/rye`  
**Attribution**: THIRD_PARTY_LICENSES.md with full Zig MIT license

### 2. Fix RISC-V Freestanding Bugs

**Issues** (from `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md`):
1. Incorrect global variable address calculation (64KB offset)
2. Function calls with anytype/comptime crashing
3. Conditional branch codegen with bitwise operations
4. Inline assembly clobber syntax (documentation)

### 3. Add Toroidal/Garden Types

**Types**:
- `ToroidalIndex(N)` — Wrap-around index
- `ToroidalBuffer(T, N)` — Circular buffer
- `BoundedParam(min, max)` — Clamped parameter
- `ToroidalGrid(T, W, H)` — 2D grid
- `Garden(T, N)` — Garden allocator

**Location**: `lib/std/toroidal.ry`, `lib/std/garden.ry`

### 4. Enforce Rye Style

**Constraints** (compiler errors):
- Function length ≤ 64 lines
- Line length ≤ 128 characters
- "Why" comments required for `pub fn`
- No `usize`/`isize` (explicit types only)
- No recursion (iterative only)

**Constraints** (compiler warnings):
- Minimum 2 assertions per function

### 5. Chronological Versioning

**Format**: `YYYYMMDD.HHMMSS.variant`  
**Example**: `20260122.064042.rye`  
**Why**: Per Rye Style, conveys when released, causality, no false compatibility promises

---

## Migration Path

### Current (Phase 1 - Transpiler)

```bash
rye check src/*.ry          # Validate constraints
rye build src/main.ry       # Transpile to Zig
zig build basin-rv64        # Compile with Zig
zig test src/vantage/basin_integration_test.zig  # Test with Zig
```

### Future (Phase 2 - Native Compiler)

```bash
rye check src/*.ry          # Validate constraints (still available)
rye build basin-rv64        # Compile directly to RISC-V64
rye test src/vantage/basin_integration_test.ry  # Test with Rye
```

---

## Development Phases

**Phase 1**: Fork and Setup (Week 1)
- Create repository, attribution, versioning

**Phase 2**: RISC-V Fixes (Weeks 2-4)
- Fix 4 codegen bugs
- Test with Basin kernel

**Phase 3**: Toroidal/Garden Types (Weeks 5-8)
- Add to standard library
- Compiler optimizations

**Phase 4**: Rye Style Enforcement (Weeks 9-12)
- Integrate validator into compiler
- Make constraints compiler errors

**Phase 5**: Self-Hosting (Weeks 13-16)
- Port compiler to Rye
- Build Rye with Rye

---

## Toroidal Basin Kernel Vision

**Design Principles**:
- **Toroidal Topology**: No edges, no boundary conditions
- **Garden Allocation**: Bounded plots, not unbounded heaps
- **Tend Philosophy**: Stewardship over ownership
- **Bounded Capacity**: MAX_ constants, explicit finitude
- **Safety by Construction**: Topology guarantees safety

**Departures from Zig/C/Linux**:
- Garden allocation vs heap
- Toroidal topology vs bounds checking
- Tend pattern vs ownership/RAII
- Bounded capacity vs unbounded growth
- Compiler-enforced constraints vs conventions

---

## Next Steps

### Immediate (This Week)

1. **Create Repository**: Fork Zig 0.15.2 to `codeberg.org/ryelang/rye`
2. **Attribution**: Create THIRD_PARTY_LICENSES.md
3. **Versioning**: Update to chronological format
4. **Documentation**: Set up repository structure

### Short-Term (This Month)

1. **RISC-V Fixes**: Implement bug fixes
2. **Toroidal Types**: Add to standard library
3. **Testing**: Test with Basin kernel

### Medium-Term (Months 2-3)

1. **Style Enforcement**: Integrate into compiler
2. **Self-Hosting**: Port compiler to Rye
3. **Basin Integration**: Update Basin build to use Rye

---

## Success Criteria

**Phase 2 Complete When**:
- ✅ Rye compiler forks Zig 0.15.2 with proper attribution
- ✅ RISC-V freestanding codegen bugs fixed
- ✅ Toroidal/garden types available in standard library
- ✅ Rye Style constraints enforced at compiler level
- ✅ Chronological versioning implemented
- ✅ Self-hosted (Rye compiler written in Rye)
- ✅ Basin kernel builds with Rye compiler
- ✅ Test commands use `rye test`

---

## References

- **Fork Plan**: `docs/rye/0011-rye-compiler-fork-plan.md`
- **Setup Guide**: `docs/rye/0012-rye-repository-setup-guide.md`
- **RISC-V Fixes**: `docs/rye/0013-riscv-freestanding-fix-strategy.md`
- **Stdlib Spec**: `docs/rye/0014-toroidal-garden-stdlib-spec.md`
- **Style Enforcement**: `docs/rye/0015-rye-style-compiler-enforcement.md`
- **Zig Issues**: `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md`
- **Toroidal Architecture**: `docs/rye/0003-toroidal-garden-architecture.md`
- **Tend Philosophy**: `docs/rye/0002-tend-supervisor-vision.md`
- **Rye Style**: `docs/rye_style.md`

---

**Date**: 2026-01-22-064042-pst  
**Status**: ✅ **PLANNING COMPLETE** — Ready to proceed with fork

**Fork Zig. Fix RISC-V. Add Toroidal. Enforce Style. Build Basin.**
