# RISC-V Phase 3: Planning Document

**Date**: 20260122.194200.rye  
**Status**: 📋 **PLANNING** — Phase 3 preparation while Phase 2 completes  
**Focus**: Toroidal/Garden Types + Basic Stdlib

---

## Executive Summary

**Phase 2 Status**: 75% complete (Issues 1 & 3 fixed, Issue 2 investigation complete)  
**Phase 3 Goal**: Add toroidal/garden types and basic stdlib to Rye compiler  
**Timeline**: Weeks 5-8 (recommended start after Phase 2 completion)  
**Dependencies**: Phase 2 completion (RISC-V freestanding fixes)

---

## Phase 3 Overview

### What is Phase 3?

**Phase 3: Toroidal/Garden Types + Basic Stdlib** adds:
1. **Toroidal Types** - Bounded, wrap-around data structures (no edge cases)
2. **Garden Allocator** - Bounded memory regions (garden-allocation model)
3. **Basic Stdlib** - Essential standard library for Basin kernel

**Why Phase 3 Matters**:
- Enables Basin kernel's toroidal architecture
- Provides garden-allocation model (bounded, explicit capacity)
- Eliminates edge cases through toroidal topology
- Foundation for Phase 4 (Rye Style enforcement)

---

## Toroidal Types Implementation

### Core Toroidal Types

**Reference**: `docs/rye/0014-toroidal-garden-stdlib-spec.md`

#### 1. ToroidalIndex(N)

**Purpose**: Index that wraps automatically (no overflow, no bounds errors)

**Location**: `lib/std/toroidal.ry`

**API**:
```rye
/// Why: Toroidal index with automatic wrap-around (no overflow, no bounds errors).
pub fn ToroidalIndex(comptime N: u32) type {
    return struct {
        value: u32,
        const MAX: u32 = N;
        
        /// Why: Create index with automatic wrap-around.
        pub fn init(v: u32) @This() { ... }
        
        /// Why: Increment with periodic boundary (wraps at N).
        pub fn inc(self: *@This()) void { ... }
        
        /// Why: Decrement with periodic boundary (wraps at 0).
        pub fn dec(self: *@This()) void { ... }
        
        /// Why: Add offset with wrap-around.
        pub fn add(self: @This(), offset: u32) @This() { ... }
        
        /// Why: Get raw value for array access.
        pub fn get(self: @This()) u32 { ... }
    };
}
```

**Compiler Optimization**: Modular arithmetic (`% N`) should compile to single instruction.

---

#### 2. ToroidalBuffer(T, N)

**Purpose**: Circular buffer with toroidal access (no bounds checks needed)

**Location**: `lib/std/toroidal.ry`

**API**:
```rye
/// Why: Toroidal buffer - circular buffer with no edge cases.
pub fn ToroidalBuffer(comptime T: type, comptime N: u32) type {
    return struct {
        data: [N]T,
        head: ToroidalIndex(N),
        tail: ToroidalIndex(N),
        count: u32,
        
        /// Why: Push element with automatic wrap-around.
        pub fn push(self: *@This(), value: T) void { ... }
        
        /// Why: Pop element with automatic wrap-around.
        pub fn pop(self: *@This()) ?T { ... }
        
        /// Why: Access element at index with wrap-around.
        pub fn get(self: *const @This(), idx: ToroidalIndex(N)) T { ... }
    };
}
```

---

#### 3. BoundedParam(T, MAX)

**Purpose**: Parameter with explicit maximum (compiler-enforced bounds)

**Location**: `lib/std/toroidal.ry`

**API**:
```rye
/// Why: Parameter with explicit maximum (compiler-enforced bounds).
pub fn BoundedParam(comptime T: type, comptime MAX: u32) type {
    return struct {
        value: T,
        const MAX_VALUE: u32 = MAX;
        
        /// Why: Create bounded parameter (compiler checks bounds).
        pub fn init(v: T) @This() { ... }
    };
}
```

---

#### 4. ToroidalGrid(T, W, H)

**Purpose**: 2D grid with wrap-around boundaries (no edge cases)

**Location**: `lib/std/toroidal.ry`

**API**:
```rye
/// Why: 2D grid with wrap-around boundaries (no edge cases).
pub fn ToroidalGrid(comptime T: type, comptime W: u32, comptime H: u32) type {
    return struct {
        data: [W * H]T,
        
        /// Why: Access cell at (x, y) with wrap-around.
        pub fn get(self: *const @This(), x: u32, y: u32) T { ... }
        
        /// Why: Set cell at (x, y) with wrap-around.
        pub fn set(self: *@This(), x: u32, y: u32, value: T) void { ... }
    };
}
```

---

## Garden Allocator Implementation

### Garden(T, N)

**Purpose**: Bounded memory region for related resources (garden-allocation model)

**Location**: `lib/std/garden.ry`

**Reference**: `docs/rye/0003-toroidal-garden-architecture.md`

**API**:
```rye
/// Why: Bounded memory region for related resources (garden-allocation model).
pub fn Garden(comptime T: type, comptime N: u32) type {
    return struct {
        plots: [N]Plot,
        plot_count: u32,
        
        pub const Plot = struct {
            allocated: bool,
            purpose: Purpose,
            data: T,
        };
        
        /// Why: Receive a plot for cultivation (not allocate).
        pub fn receive(self: *@This(), purpose: Purpose) ?*Plot { ... }
        
        /// Why: Release a plot back to fallow (not free).
        pub fn release(self: *@This(), plot: *Plot) void { ... }
        
        /// Why: Find plot by purpose.
        pub fn find(self: *@This(), purpose: Purpose) ?*Plot { ... }
        
        /// Why: Enumerate all allocated plots.
        pub fn enumerate(self: *const @This(), plots: []*Plot) u32 { ... }
    };
}
```

**Philosophy**:
- `receive` not `allocate` - we receive into care, not create from nothing
- `release` not `free` - we release back to availability, not destroy
- `purpose` - each plot has explicit purpose (not anonymous memory)

---

## Basic Stdlib Implementation

### Essential Modules

**Location**: `lib/std/`

**Modules**:
1. **`toroidal.ry`** - Toroidal types (ToroidalIndex, ToroidalBuffer, etc.)
2. **`garden.ry`** - Garden allocator (Garden, Plot, Purpose)
3. **`mem.ry`** - Memory operations (copy, set, compare)
4. **`fmt.ry`** - Formatting (print, format strings)
5. **`io.ry`** - I/O operations (read, write, streams)

**Priority**: Toroidal and garden types first, then basic stdlib.

---

## Implementation Tasks

### Task 1: Toroidal Types (Week 5-6)

**Subtasks**:
1. Create `lib/std/toroidal.ry`
2. Implement `ToroidalIndex(N)`
3. Implement `ToroidalBuffer(T, N)`
4. Implement `BoundedParam(T, MAX)`
5. Implement `ToroidalGrid(T, W, H)`
6. Add compiler optimizations for modular arithmetic
7. Create test cases

**Deliverable**: All toroidal types available in stdlib

---

### Task 2: Garden Allocator (Week 6-7)

**Subtasks**:
1. Create `lib/std/garden.ry`
2. Implement `Garden(T, N)` type
3. Implement `Plot` structure
4. Implement `Purpose` enum
5. Implement `receive()` and `release()` methods
6. Implement `find()` and `enumerate()` methods
7. Create test cases

**Deliverable**: Garden allocator available in stdlib

---

### Task 3: Basic Stdlib (Week 7-8)

**Subtasks**:
1. Create `lib/std/mem.ry` (memory operations)
2. Create `lib/std/fmt.ry` (formatting)
3. Create `lib/std/io.ry` (I/O operations)
4. Integrate with Basin kernel
5. Create test cases

**Deliverable**: Basic stdlib functional

---

## Integration with Basin Kernel

### Basin Kernel Usage

**Reference**: `docs/rye/0014-toroidal-garden-stdlib-spec.md`

```rye
// Basin kernel uses garden allocation
pub const BasinKernel = struct {
    /// Process garden: MAX_PROCESSES plots
    process_garden: Garden(Process, MAX_PROCESSES),
    
    /// Handle garden: MAX_HANDLES plots
    handle_garden: Garden(Handle, MAX_HANDLES),
    
    /// Memory mapping garden: MAX_MAPPINGS plots
    mapping_garden: Garden(Mapping, MAX_MAPPINGS),
};
```

**Benefits**:
- Bounded capacity (no unbounded growth)
- Explicit purpose (each plot has purpose)
- No fragmentation (fixed-size plots)
- Tend pattern (receive/release, not allocate/free)

---

## Compiler Optimizations

### Modular Arithmetic Optimization

**Goal**: Compile `% N` to single instruction on modern CPUs

**Implementation**:
- Detect `value % N` where `N` is power of 2
- Use bitwise AND (`& (N-1)`) instead of modulo
- For non-power-of-2, use optimized modulo instruction

**Example**:
```rye
// Before optimization
idx.value = (idx.value + 1) % N;

// After optimization (if N is power of 2)
idx.value = (idx.value + 1) & (N - 1);
```

---

## Testing Strategy

### Unit Tests

**For Each Type**:
1. Create test file: `test/toroidal/test_toroidal_index.ry`
2. Test wrap-around behavior
3. Test edge cases (0, MAX-1, MAX)
4. Test compiler optimizations

### Integration Tests

**Basin Kernel Integration**:
1. Test garden allocation in kernel
2. Test toroidal buffer in kernel
3. Verify bounded capacity works
4. Verify no edge cases

---

## Dependencies

### Phase 2 Completion

**Required Before Phase 3**:
- ✅ Issue 1: Global variable addressing (fixed)
- ✅ Issue 3: Conditional branch codegen (fixed)
- ⏳ Issue 2: Kernel integration testing (pending)
- ✅ V/ZBB Extension: Optional for freestanding (fixed)

**Status**: Phase 2 at 75%, can start Phase 3 planning

---

## Timeline

### Recommended Schedule

**Week 5-6**: Toroidal Types
- Implement all toroidal types
- Add compiler optimizations
- Create test cases

**Week 6-7**: Garden Allocator
- Implement garden allocator
- Integrate with Basin kernel
- Create test cases

**Week 7-8**: Basic Stdlib
- Implement basic stdlib modules
- Integrate with Basin kernel
- Final testing

**Total**: 4 weeks (Weeks 5-8)

---

## Success Criteria

### Phase 3 Complete When:

1. ✅ All toroidal types available in `lib/std/toroidal.ry`
2. ✅ Garden allocator available in `lib/std/garden.ry`
3. ✅ Basic stdlib functional (`mem`, `fmt`, `io`)
4. ✅ Compiler optimizations for modular arithmetic
5. ✅ Basin kernel can use toroidal/garden types
6. ✅ All test cases pass
7. ✅ Documentation complete

---

## Next Steps

### Immediate (While Phase 2 Completes)

1. **Review Specifications**
   - Review `docs/rye/0014-toroidal-garden-stdlib-spec.md`
   - Review `docs/rye/0003-toroidal-garden-architecture.md`
   - Understand requirements

2. **Design Implementation**
   - Design API for each type
   - Plan compiler optimizations
   - Plan integration with Basin kernel

3. **Prepare Test Cases**
   - Design test cases for each type
   - Plan integration tests
   - Plan performance tests

### When Phase 2 Completes

4. **Start Implementation**
   - Begin with ToroidalIndex
   - Implement incrementally
   - Test as you go

---

## References

- **Toroidal/Garden Architecture**: `docs/rye/0003-toroidal-garden-architecture.md`
- **Stdlib Specification**: `docs/rye/0014-toroidal-garden-stdlib-spec.md`
- **Compiler Fork Plan**: `docs/rye/0011-rye-compiler-fork-plan.md`
- **Phase 2 Status**: `docs/rye/0052-riscv-phase2-final-status-and-roadmap.md`

---

**Date**: 20260122.194200.rye  
**Status**: 📋 **PLANNING** — Phase 3 preparation document

**Next Action**: Review specifications, design implementation, prepare for Phase 3 start after Phase 2 completion.
