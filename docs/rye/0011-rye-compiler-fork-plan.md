# Rye Compiler Fork Plan: From Transpiler to Native Compiler

**Date**: 2026-01-22-062923-pst  
**Status**: 🆕 **PLANNING** — Fork Zig 0.15.2 to create Rye compiler  
**Repository**: `codeberg.org/ryelang/rye` (new repository)  
**Base**: Zig 0.15.2 tag (https://codeberg.org/ziglang/zig/src/tag/0.15.2)

---

## Executive Summary

**Current State**: Rye is a Phase 1 transpiler (validates `.ry` → emits `.zig`)  
**Target State**: Rye is a Phase 2 native compiler (compiles `.ry` → machine code)  
**Strategy**: Fork Zig 0.15.2, adapt for RISC-V freestanding, add toroidal/garden types, enforce Rye Style

**Why Fork Zig**:
- Fix RISC-V freestanding codegen bugs (see `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md`)
- Add toroidal/garden types as first-class language features
- Enforce Rye Style at compiler level (64 lines, 128 chars, "why" comments)
- Use chronological versioning (non-semantic)
- Design for Basin kernel's garden-allocation model

---

## Repository Setup

### New Repository: `codeberg.org/ryelang/rye`

**Organization**: `ryelang` (follows `ziglang/zig` pattern)  
**Repository**: `rye`  
**Base**: Fork from `codeberg.org/ziglang/zig` at tag `0.15.2`

**Initial Setup**:
```bash
# Clone Zig 0.15.2
git clone https://codeberg.org/ziglang/zig.git rye
cd rye
git checkout 0.15.2
git checkout -b rye-0.15.2-base

# Rename remote
git remote rename origin upstream
git remote add origin https://codeberg.org/ryelang/rye.git

# Initial commit with attribution
git commit --allow-empty -m "rye: fork from zig 0.15.2

2026-01-22-062923-pst

forked from:
- ziglang/zig tag 0.15.2
- https://codeberg.org/ziglang/zig/src/tag/0.15.2

rye adaptations:
- fix risc-v freestanding codegen bugs
- add toroidal/garden types
- enforce rye style constraints
- chronological versioning
- garden-allocation model

see THIRD_PARTY_LICENSES.md for zig attribution"
```

---

## Versioning Strategy

### Rye Uses Chronological Versioning

**Format**: `YYYYMMDD.HHMMSS.variant`  
**Example**: `20260122.062923.rye`

**Why**: Per Rye Style (`docs/rye_style.md`), chronological versioning conveys:
- **When** it was released (absolute, not relative)
- **Causality** (later timestamps came after earlier ones)
- **No false promises** about compatibility

**Implementation**:
- Remove all semantic versioning (v0.x.x)
- Use chronological timestamps for releases
- Version string in compiler: `rye version` → `20260122.062923.rye`

---

## Core Adaptations from Zig

### 1. Fix RISC-V Freestanding Codegen Bugs

**Issues to Fix** (from `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md`):

1. **Incorrect Global Variable Address Calculation**
   - Fix `AUIPC + ADDI` sequence for global variable access
   - Ensure correct address calculation for RISC-V64

2. **Function Calls Causing Crashes**
   - Fix `anytype` parameter codegen for freestanding
   - Fix comptime string formatting for freestanding
   - Ensure `inline for` works correctly

3. **Conditional Branch Codegen**
   - Fix bitwise operation conditionals
   - Ensure correct branch codegen for RISC-V

4. **Inline Assembly Reliability**
   - Ensure inline assembly works reliably
   - Fix register constraints

**Priority**: HIGH - These are existential bugs for Basin kernel

---

### 2. Add Toroidal/Garden Types as First-Class Features

**Toroidal Types** (from `docs/rye/0003-toroidal-garden-architecture.md`):

```rye
// Built-in toroidal types
pub const ToroidalIndex = struct { ... };  // Built into compiler
pub const ToroidalBuffer = struct { ... }; // Built into compiler
pub const BoundedParam = struct { ... };   // Built into compiler
pub const ToroidalGrid = struct { ... };   // Built into compiler
```

**Garden Allocation** (from `docs/rye/0003-toroidal-garden-architecture.md`):

```rye
// Built-in garden allocator
pub const Garden = struct { ... };  // Built into compiler/stdlib
```

**Implementation**:
- Add toroidal types to Rye standard library
- Add garden allocator to Rye standard library
- Compiler optimizations for toroidal access (modular arithmetic)
- Compiler-enforced bounded capacity (MAX_ constants)

---

### 3. Enforce Rye Style at Compiler Level

**Constraints to Enforce**:

1. **Function Length**: ≤ 64 lines (compiler error if exceeded)
2. **Line Length**: ≤ 128 characters (compiler error if exceeded)
3. **Why Comments**: Required for all `pub fn` (compiler error if missing)
4. **Explicit Types**: No `usize`/`isize` inference (compiler error)
5. **Assertions**: Minimum 2 per function (compiler warning, can be error)
6. **No Recursion**: Compiler error on recursive functions

**Implementation**:
- Add Rye Style validator to compiler frontend
- Integrate with existing Phase 1 validator logic
- Make violations compiler errors (not just warnings)

---

### 4. Chronological Versioning

**Remove Semantic Versioning**:
- Remove all `v0.x.x` version strings
- Use chronological timestamps: `YYYYMMDD.HHMMSS.variant`
- Update version command: `rye version` → `20260122.062923.rye`

**Implementation**:
- Update version strings in compiler
- Update changelog format
- Update release process

---

### 5. Garden-Allocation Model (Not Linux Model)

**Philosophy** (from `docs/rye/0002-tend-supervisor-vision.md`):
- **Garden allocation** instead of heap/arena
- **Bounded capacity** (MAX_ constants)
- **Tend pattern** (receive/release, not allocate/free)
- **Explicit presence** (`allocated: bool` flags)

**Implementation**:
- Default allocator is garden-based (not heap-based)
- Compiler enforces bounded capacity
- Standard library uses garden allocation
- Kernel uses garden allocation (Basin kernel model)

---

## Build System Adaptations

### Rye Binary Built from Source

**Build Command**:
```bash
# Build Rye compiler (self-hosted)
cd rye
zig build  # Bootstrap with Zig
./zig-out/bin/rye build  # Build Rye with Rye (self-hosted)
```

**Versioning**:
- Rye compiler version: chronological (`20260122.062923.rye`)
- Built from Rye source (self-hosted)
- Uses Rye Style constraints

### Test Commands Become Rye Commands

**Current** (Phase 1):
```bash
zig test src/vantage/basin_integration_test.zig
```

**Future** (Phase 2):
```bash
rye test src/vantage/basin_integration_test.ry
```

**Implementation**:
- Add `rye test` command (mirrors `zig test`)
- Compile test files with Rye compiler
- Run tests with RISC-V freestanding target

---

## Third-Party License Attribution

### THIRD_PARTY_LICENSES.md

**Required Attribution**:
- Zig (MIT License) - Base compiler
- LLVM (Apache 2.0 with LLVM exceptions) - Backend
- Other dependencies as needed

**Format** (similar to `keatonlivermore/grain-sketchbook/THIRD_PARTY_LICENSES.md`):
```markdown
# Third-Party Licenses

## Zig Compiler

Rye is forked from Zig 0.15.2:
- Source: https://codeberg.org/ziglang/zig
- Tag: 0.15.2
- License: MIT
- Copyright: Andrew Kelley and contributors

Rye adaptations:
- RISC-V freestanding codegen fixes
- Toroidal/garden type system
- Rye Style enforcement
- Chronological versioning
- Garden-allocation model

[Full Zig license text]
```

---

## Development Phases

### Phase 1: Fork and Setup (Week 1)

**Tasks**:
1. Fork Zig 0.15.2 to `codeberg.org/ryelang/rye`
2. Create THIRD_PARTY_LICENSES.md with Zig attribution
3. Update versioning to chronological
4. Rename compiler binary: `zig` → `rye`
5. Update all version strings

**Deliverable**: Rye compiler repository with proper attribution

---

### Phase 2: RISC-V Freestanding Fixes (Weeks 2-4)

**Tasks**:
1. Fix global variable address calculation
2. Fix function call codegen for freestanding
3. Fix conditional branch codegen
4. Fix inline assembly reliability
5. Test with Basin kernel

**Deliverable**: RISC-V freestanding codegen works correctly

---

### Phase 3: Toroidal/Garden Types (Weeks 5-8)

**Tasks**:
1. Add ToroidalIndex to standard library
2. Add ToroidalBuffer to standard library
3. Add BoundedParam to standard library
4. Add Garden allocator to standard library
5. Add compiler optimizations for toroidal access

**Deliverable**: Toroidal/garden types available in Rye

---

### Phase 4: Rye Style Enforcement (Weeks 9-12)

**Tasks**:
1. Integrate Rye Style validator into compiler
2. Enforce 64-line function limit
3. Enforce 128-character line limit
4. Enforce "why" comment requirement
5. Enforce explicit types (no usize/isize)
6. Enforce no recursion

**Deliverable**: Rye Style constraints enforced at compiler level

---

### Phase 5: Self-Hosting (Weeks 13-16)

**Tasks**:
1. Port Rye compiler to Rye (self-hosted)
2. Build Rye with Rye
3. Test self-hosted compiler
4. Update build system

**Deliverable**: Rye compiler written in Rye, built with Rye

---

## Architecture: Toroidal Basin Kernel Vision

### Design Principles

**From Toroidal Garden Architecture** (`docs/rye/0003-toroidal-garden-architecture.md`):

1. **Toroidal Topology**: No edges, no boundary conditions
2. **Garden Allocation**: Bounded plots, not unbounded heaps
3. **Tend Philosophy**: Stewardship over ownership
4. **Bounded Capacity**: MAX_ constants, explicit finitude
5. **Safety by Construction**: Topology guarantees safety

### Language Features for Basin Kernel

**Toroidal Types**:
```rye
// Built-in toroidal index
var scheduler_idx: ToroidalIndex(MAX_PROCESSES) = .{ .value = 0 };

// Built-in toroidal buffer
var log_buffer: ToroidalBuffer(LogEntry, MAX_LOG_ENTRIES) = .{};

// Built-in bounded parameter
var timeout: BoundedParam(0, 1000) = .{ .value = 100 };
```

**Garden Allocation**:
```rye
// Built-in garden allocator
var process_garden: Garden(Process, MAX_PROCESSES) = .{};

// Receive plot (not allocate)
const process = process_garden.receive(.system) orelse return error.NoCapacity;

// Release plot (not free)
process_garden.release(process);
```

**Rye Style Enforcement**:
```rye
/// Why: Schedule next runnable process (toroidal round-robin).
pub fn schedule_next(self: *Scheduler) ?u32 {
    // Function must be ≤ 64 lines
    // Lines must be ≤ 128 characters
    // Must have "why" comment
    // Must have 2+ assertions
    // Must use explicit types (u32, not usize)
}
```

---

## Departure from Zig/C/Linux Model

### Substantial Departures

**Allocation Model**:
- **Zig/C/Linux**: Heap allocation, unbounded growth
- **Rye/Basin**: Garden allocation, bounded capacity

**Memory Safety**:
- **Zig/C/Linux**: Bounds checking, error handling
- **Rye/Basin**: Toroidal topology, no bounds checks needed

**Resource Management**:
- **Zig/C/Linux**: Ownership, RAII, reference counting
- **Rye/Basin**: Tend pattern, stewardship, explicit presence

**Kernel Architecture**:
- **Linux**: 30+ million lines, unbounded complexity
- **Basin**: ~15,000 lines, bounded capacity, toroidal structures

**Language Constraints**:
- **Zig/C**: No function length limits, no line length limits
- **Rye**: 64-line functions, 128-char lines (compiler-enforced)

### Similarities Retained

**From Zig**:
- No hidden control flow
- No hidden memory allocations
- Compile-time evaluation (comptime)
- No garbage collector
- Cross-compilation
- C interop

**From C**:
- Systems programming focus
- Low-level control
- Direct hardware access
- Minimal runtime

---

## Repository Structure

### `codeberg.org/ryelang/rye`

```
rye/
├── README.md                    # Rye compiler overview
├── THIRD_PARTY_LICENSES.md      # Zig and other attributions
├── CHANGELOG.md                 # Chronological versioning
├── build.zig                    # Build system (Rye)
├── lib/                         # Rye standard library
│   ├── std/
│   │   ├── toroidal.ry          # Toroidal types
│   │   ├── garden.ry            # Garden allocator
│   │   ├── bounded.ry           # Bounded parameters
│   │   └── ...
├── src/                         # Compiler source (Rye)
│   ├── main.ry                  # Compiler entry point
│   ├── frontend/                # Parser, validator
│   ├── backend/                 # Code generation
│   └── ...
└── test/                        # Compiler tests
```

---

## Migration Path

### From Phase 1 (Transpiler) to Phase 2 (Compiler)

**Current Workflow**:
```bash
# Phase 1: Transpile to Zig
rye check src/*.ry
rye build src/main.ry  # Emits src/main.zig
zig build basin-rv64  # Compile with Zig
```

**Future Workflow**:
```bash
# Phase 2: Compile directly
rye check src/*.ry
rye build basin-rv64  # Compile directly to RISC-V64
rye test src/vantage/basin_integration_test.ry  # Test with Rye
```

**Migration Steps**:
1. Fork Zig 0.15.2 → `codeberg.org/ryelang/rye`
2. Fix RISC-V freestanding bugs
3. Add toroidal/garden types
4. Enforce Rye Style
5. Self-host compiler
6. Update Basin kernel build to use Rye compiler
7. Update test commands to use `rye test`

---

## Success Criteria

### Phase 2 Complete When:

- ✅ Rye compiler forks Zig 0.15.2 with proper attribution
- ✅ RISC-V freestanding codegen bugs fixed
- ✅ Toroidal/garden types available in standard library
- ✅ Rye Style constraints enforced at compiler level
- ✅ Chronological versioning implemented
- ✅ Self-hosted (Rye compiler written in Rye)
- ✅ Basin kernel builds with Rye compiler
- ✅ Test commands use `rye test`

---

## Next Steps

### Immediate (This Week)

1. **Create Repository**: Fork Zig 0.15.2 to `codeberg.org/ryelang/rye`
2. **Attribution**: Create THIRD_PARTY_LICENSES.md with Zig credit
3. **Versioning**: Update to chronological versioning
4. **Planning**: Document RISC-V fix strategy

### Short-Term (This Month)

1. **RISC-V Fixes**: Fix codegen bugs from issue document
2. **Toroidal Types**: Add to standard library
3. **Garden Allocator**: Add to standard library
4. **Testing**: Test with Basin kernel

### Medium-Term (Months 2-3)

1. **Rye Style Enforcement**: Integrate validator into compiler
2. **Self-Hosting**: Port compiler to Rye
3. **Basin Integration**: Update Basin build to use Rye
4. **Documentation**: Complete compiler documentation

---

## References

- **Zig RISC-V Issues**: `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md`
- **Rye Vision**: `docs/rye/0001-rye-language-vision.md`
- **Toroidal Architecture**: `docs/rye/0003-toroidal-garden-architecture.md`
- **Tend Philosophy**: `docs/rye/0002-tend-supervisor-vision.md`
- **Rye Style**: `docs/rye_style.md`
- **Zig 0.15.2 Tag**: https://codeberg.org/ziglang/zig/src/tag/0.15.2

---

**Date**: 2026-01-22-062923-pst  
**Status**: 🆕 **PLANNING** — Fork Zig 0.15.2 to create Rye compiler  
**Repository**: `codeberg.org/ryelang/rye` (new repository)

**Fork Zig. Fix RISC-V. Add Toroidal. Enforce Style. Build Basin.**
