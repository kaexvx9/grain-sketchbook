# Toroidal/Garden Standard Library Specification

**Date**: 2026-01-22-062923-pst  
**Status**: 🆕 **SPECIFICATION** — Toroidal and garden types for Rye standard library  
**Reference**: `docs/rye/0003-toroidal-garden-architecture.md`

---

## Overview

Rye standard library will include toroidal and garden types as first-class language features. These types enable the toroidal Basin kernel architecture with garden-allocation model.

---

## Toroidal Types

### ToroidalIndex(N)

**Purpose**: Index that wraps automatically (toroidal topology, no edge cases)

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

**Compiler Optimization**: Modular arithmetic (`% N`) should compile to single instruction on modern CPUs.

---

### ToroidalBuffer(T, N)

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
        
        /// Why: Push with wrap-around (overwrites oldest if full).
        pub fn push(self: *@This(), item: T) void { ... }
        
        /// Why: Pop with wrap-around.
        pub fn pop(self: *@This()) ?T { ... }
        
        /// Why: Access any index (wraps automatically).
        pub fn get(self: *const @This(), idx: u32) T { ... }
    };
}
```

**Use Cases**: Log buffers, message queues, scheduler round-robin

---

### BoundedParam(min, max)

**Purpose**: Parameter that cannot exceed range (clamping or wrapping)

**Location**: `lib/std/toroidal.ry`

**API**:
```rye
/// Why: Bounded parameter that cannot exceed range.
pub fn BoundedParam(comptime min: i64, comptime max: i64) type {
    return struct {
        value: i64,
        
        const MIN: i64 = min;
        const MAX: i64 = max;
        
        /// Why: Create parameter with clamping to valid range.
        pub fn init(v: i64) @This() { ... }
        
        /// Why: Create with toroidal wrap (periodic boundary).
        pub fn init_wrap(v: i64) @This() { ... }
        
        /// Why: Set value with clamping.
        pub fn set(self: *@This(), v: i64) void { ... }
        
        /// Why: Set value with wrap-around.
        pub fn set_wrap(self: *@This(), v: i64) void { ... }
    };
}
```

---

### ToroidalGrid(T, W, H)

**Purpose**: 2D grid with toroidal access (no edge cases in 2D traversal)

**Location**: `lib/std/toroidal.ry`

**API**:
```rye
/// Why: 2D toroidal grid - no edge cases in 2D traversal.
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

## Garden Allocation

### Garden(T, N)

**Purpose**: Bounded memory region for related resources (garden-allocation model)

**Location**: `lib/std/garden.ry`

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

## Integration with Basin Kernel

### Basin Kernel Usage

```rye
// Basin kernel uses garden allocation
pub const BasinKernel = struct {
    /// Process garden: MAX_PROCESSES plots
    process_garden: Garden(Process, MAX_PROCESSES),
    
    /// Channel garden: MAX_CHANNELS plots
    channel_garden: Garden(Channel, MAX_CHANNELS),
    
    /// Scheduler uses toroidal round-robin
    scheduler: struct {
        current: ToroidalIndex(MAX_PROCESSES),
        // ...
    },
    
    /// Log buffer uses toroidal write
    log_buffer: ToroidalBuffer(LogEntry, MAX_LOG_ENTRIES),
};
```

---

## Compiler Optimizations

### Toroidal Access Optimization

**Current** (manual):
```rye
return array[idx % N];  // Modular arithmetic
```

**Optimized** (compiler):
- If `N` is power of 2: Use bitwise AND (`idx & (N-1)`)
- If `N` is small: Use conditional (faster than division)
- Otherwise: Use optimized modular arithmetic

### Garden Allocation Optimization

**Current** (manual):
```rye
for (&self.plots) |*plot| {
    if (!plot.allocated) { ... }
}
```

**Optimized** (compiler):
- Track free list at compile time if possible
- Optimize common patterns (first-fit, best-fit)
- Generate efficient allocation code

---

## Standard Library Structure

```
lib/std/
├── toroidal.ry          # ToroidalIndex, ToroidalBuffer, BoundedParam, ToroidalGrid
├── garden.ry            # Garden allocator
├── bounded.ry           # Bounded types and constants
├── tend.ry              # Tend pattern helpers
└── ...
```

---

## Migration from Current Implementation

**Current**: Toroidal types in `src/kernel/toroidal.ry` (Basin kernel)  
**Future**: Toroidal types in `lib/std/toroidal.ry` (Rye standard library)

**Migration Steps**:
1. Move toroidal types to Rye standard library
2. Update Basin kernel to import from `std.toroidal`
3. Remove duplicate implementations
4. Add compiler optimizations

---

## References

- **Toroidal Architecture**: `docs/rye/0003-toroidal-garden-architecture.md`
- **Tend Philosophy**: `docs/rye/0002-tend-supervisor-vision.md`
- **Current Implementation**: `src/kernel/toroidal.ry`

---

**Date**: 2026-01-22-062923-pst  
**Status**: 🆕 **SPECIFICATION** — Toroidal and garden types for Rye standard library
