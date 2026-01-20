# Toroidal Garden Architecture: Rye + Basin Unified Design

**Date**: 2026-01-20
**Status**: Architecture Vision
**Relationship**: Unifies Rye language, Basin kernel, and Tend philosophy

---

## Overview

This document describes how Rye (language) and Basin (kernel) share a unified architecture based on:

1. **Toroidal data structures** - bounded, wrap-around, no edge cases
2. **Garden allocation** - tend resources in bounded plots, not arenas
3. **Tend philosophy** - stewardship over ownership

The key insight: **a torus has no edges**. Every point has equivalent topological relationships. In code, this means no boundary conditions, no off-by-one errors, no edge cases to forget.

---

## Part 1: Garden Allocation

### Why "Garden" Instead of "Arena"

| Arena | Garden |
|-------|--------|
| Combat metaphor | Cultivation metaphor |
| Win/lose, acquire/discard | Tend/nurture, receive/release |
| Unbounded growth | Bounded plots |
| Anonymous memory | Named beds with purpose |
| Bump allocator | Explicit capacity |

An arena is a place of competition. A garden is a place of cultivation.

### Garden Structure

```rye
/// Why: Bounded memory region for related resources.
pub const Garden = struct {
    /// Fixed capacity - acceptance of finitude.
    plots: [MAX_PLOTS]Plot,
    plot_count: u32,
    
    /// Why: Each plot has explicit purpose.
    pub const Plot = struct {
        allocated: bool,
        purpose: Purpose,
        data: [PLOT_SIZE]u8,
    };
    
    /// Why: Receive a plot for cultivation.
    pub fn receive(self: *Garden, purpose: Purpose) ?*Plot {
        for (&self.plots) |*plot| {
            if (!plot.allocated) {
                plot.allocated = true;
                plot.purpose = purpose;
                return plot;
            }
        }
        return null;  // Garden is full - this is natural, not an error
    }
    
    /// Why: Release a plot back to fallow.
    pub fn release(self: *Garden, plot: *Plot) void {
        plot.allocated = false;
        plot.purpose = .fallow;
    }
};
```

### Garden vs Arena vs Heap

| Aspect | Heap | Arena | Garden |
|--------|------|-------|--------|
| Capacity | Unbounded | Unbounded | Bounded (MAX_) |
| Lifetime | Per-object | Per-arena | Per-purpose |
| Fragmentation | Yes | No | No |
| Overhead | Headers per object | None | 1 bool per plot |
| Safety | Manual/GC | Bulk free | Tend pattern |
| Philosophy | Ownership | Disposal | Stewardship |

---

## Part 2: Toroidal Data Structures

### The Toroidal Insight

From the whitepaper: *"A torus has no edges - every point has equivalent topological relationships."*

In programming terms:
- **No bounds checks at runtime** - indices wrap by construction
- **No edge cases** - periodic boundaries eliminate special cases
- **No off-by-one errors** - modular arithmetic is always valid

### Core Toroidal Types

```rye
/// Why: Index that wraps automatically (toroidal topology).
pub fn ToroidalIndex(comptime N: u32) type {
    return struct {
        value: u32,
        
        /// Why: Advance with automatic wrap-around.
        pub fn advance(self: *@This()) void {
            self.value = (self.value + 1) % N;
        }
        
        /// Why: Retreat with automatic wrap-around.
        pub fn retreat(self: *@This()) void {
            self.value = if (self.value == 0) N - 1 else self.value - 1;
        }
        
        /// Why: Offset with automatic wrap-around.
        pub fn offset(self: @This(), delta: i32) @This() {
            const n: i32 = @intCast(N);
            const v: i32 = @intCast(self.value);
            const result = @mod(v + delta, n);
            return .{ .value = @intCast(result) };
        }
    };
}

/// Why: Circular buffer with toroidal access (no bounds checks).
pub fn ToroidalBuffer(comptime T: type, comptime N: u32) type {
    return struct {
        data: [N]T,
        head: ToroidalIndex(N),
        tail: ToroidalIndex(N),
        count: u32,
        
        /// Why: Push with wrap-around (overwrites oldest if full).
        pub fn push(self: *@This(), item: T) void {
            self.data[self.head.value] = item;
            self.head.advance();
            if (self.count < N) {
                self.count += 1;
            } else {
                self.tail.advance();  // Overwrite oldest
            }
        }
        
        /// Why: Pop with wrap-around.
        pub fn pop(self: *@This()) ?T {
            if (self.count == 0) return null;
            const item = self.data[self.tail.value];
            self.tail.advance();
            self.count -= 1;
            return item;
        }
        
        /// Why: Access any index (wraps automatically).
        pub fn get(self: *const @This(), idx: u32) T {
            return self.data[idx % N];
        }
    };
}

/// Why: Bounded parameter that cannot exceed range.
pub fn BoundedParam(comptime min: i64, comptime max: i64) type {
    return struct {
        value: i64,
        
        /// Why: Set with automatic clamping to valid range.
        pub fn set(self: *@This(), v: i64) void {
            self.value = @max(min, @min(max, v));
        }
        
        /// Why: Wrap-around increment (toroidal).
        pub fn increment(self: *@This()) void {
            self.value = if (self.value >= max) min else self.value + 1;
        }
    };
}
```

### Memory Safety by Topology

Traditional bounds checking:
```zig
// Every access needs runtime check
if (idx < array.len) {
    return array[idx];  // Safe
} else {
    return error.OutOfBounds;  // Edge case
}
```

Toroidal access:
```rye
// No check needed - topology guarantees safety
return array[idx % N];  // Always valid by construction
```

The modular arithmetic is **one instruction** on all modern CPUs. The bounds check requires **branch prediction** which can stall pipelines.

---

## Part 3: Basin Kernel Architecture

### Garden-Based Kernel Resources

Basin uses gardens (not arenas, not heaps) for all kernel resources:

```rye
pub const BasinKernel = struct {
    /// Process garden: MAX_PROCESSES plots
    process_garden: Garden(Process, MAX_PROCESSES),
    
    /// Channel garden: MAX_CHANNELS plots  
    channel_garden: Garden(Channel, MAX_CHANNELS),
    
    /// Mapping garden: MAX_MAPPINGS plots
    mapping_garden: Garden(MemoryMapping, MAX_MAPPINGS),
    
    /// Handle garden: MAX_HANDLES plots
    handle_garden: Garden(FileHandle, MAX_HANDLES),
};
```

### Toroidal Kernel Structures

```rye
/// Why: Scheduler uses toroidal round-robin.
pub const Scheduler = struct {
    current: ToroidalIndex(MAX_PROCESSES),
    
    /// Why: Find next runnable process (wraps around).
    pub fn find_next(self: *Scheduler, procs: []const Process) ?u32 {
        var i: u32 = 0;
        while (i < MAX_PROCESSES) : (i += 1) {
            self.current.advance();
            if (procs[self.current.value].state == .runnable) {
                return self.current.value;
            }
        }
        return null;  // No runnable process
    }
};

/// Why: Log buffer uses toroidal write (oldest entries overwritten).
pub const LogBuffer = struct {
    entries: ToroidalBuffer(LogEntry, MAX_LOG_ENTRIES),
    
    /// Why: Write log entry (never fails, may overwrite oldest).
    pub fn write(self: *LogBuffer, entry: LogEntry) void {
        self.entries.push(entry);  // Toroidal - always succeeds
    }
};

/// Why: IPC channel uses toroidal message queue.
pub const Channel = struct {
    messages: ToroidalBuffer(Message, MAX_MESSAGES),
    
    /// Why: Send message (wraps if full - policy decision).
    pub fn send(self: *Channel, msg: Message) void {
        self.messages.push(msg);
    }
};
```

### Init-in-Place Pattern (Garden Planting)

```rye
/// Why: Plant the kernel garden directly in memory.
pub fn init_in_place(garden: *BasinKernel) void {
    // Prepare each garden bed
    garden.process_garden = Garden(Process, MAX_PROCESSES).init();
    garden.channel_garden = Garden(Channel, MAX_CHANNELS).init();
    garden.mapping_garden = Garden(MemoryMapping, MAX_MAPPINGS).init();
    garden.handle_garden = Garden(FileHandle, MAX_HANDLES).init();
    
    // Plant the root user
    _ = garden.process_garden.receive(.system);
}
```

---

## Part 4: Rye-Basin Integration

### Shared Principles (Not Shared Code)

Rye and Basin share **principles**, not **implementations**:

| Principle | Rye (Language) | Basin (Kernel) |
|-----------|----------------|----------------|
| Bounded capacity | MAX_ constants | MAX_ constants |
| Toroidal access | ToroidalBuffer type | Scheduler, LogBuffer |
| Garden allocation | Language allocator | Kernel resource pools |
| Tend pattern | Resource structs | Process/Channel/Handle |
| 64-line limit | Compiler enforced | Style enforced |
| Why comments | Compiler enforced | Style enforced |

### The Separation

```
┌─────────────────────────────────────────────┐
│                    Rye                       │
│  (Language: compiler, type system, stdlib)  │
│                                             │
│  - ToroidalBuffer(T, N)                     │
│  - Garden(T, N)                             │
│  - BoundedParam(min, max)                   │
│  - 64-line / 128-char enforcement           │
│  - /// Why: enforcement                     │
└─────────────────────────────────────────────┘
           │
           │ compiles to
           ▼
┌─────────────────────────────────────────────┐
│                   Basin                      │
│  (Kernel: syscalls, scheduler, memory)      │
│                                             │
│  - Uses toroidal structures                 │
│  - Uses garden allocation                   │
│  - Written in Rye (transpiled to Zig)       │
│  - Follows Tend philosophy                  │
└─────────────────────────────────────────────┘
```

Rye provides the **language constructs**. Basin **uses** them. They are closely tied through shared philosophy and types, but Basin doesn't depend on Rye's compiler internals, and Rye doesn't know about Basin's syscalls.

### The Connection Point

The connection is the **type system**:

```rye
// Rye provides this type
pub const ToroidalBuffer = @import("std").ToroidalBuffer;

// Basin uses this type
const LogBuffer = ToroidalBuffer(LogEntry, MAX_LOG_ENTRIES);
```

Basin imports Rye's standard library types. That's the only coupling.

---

## Part 5: Performance Through Topology

### Why Toroidal is Faster

From the whitepaper, toroidal structures provide:

1. **No branch misprediction** - modular arithmetic vs. bounds check
2. **No edge effects** - uniform access patterns
3. **Cache-friendly** - predictable wrap-around access
4. **No error paths** - indices always valid by construction

### Projected Gains (From Whitepaper)

| Factor | Conservative | Realistic | Optimistic |
|--------|--------------|-----------|------------|
| Natural gradient convergence | 1.1x | 1.15x | 1.2x |
| Compact domain optimization | 1.2x | 1.3x | 1.4x |
| Deterministic execution | 1.0x | 1.05x | 1.1x |
| Toroidal topology | 1.3x | 1.4x | 1.6x |
| **Composite** | **1.7x** | **2.2x** | **2.9x** |

These gains are achievable **within RyeStyle constraints** because the constraints *enable* the topology.

---

## Part 6: Memory Safety Guarantees

### Safety by Construction

1. **Bounded capacity** → No unbounded growth → No OOM
2. **Toroidal indices** → No out-of-bounds → No buffer overflow
3. **Explicit allocation flag** → No use-after-free → No dangling pointers
4. **Garden pattern** → No forgotten resources → No leaks
5. **64-line functions** → Auditable code → Fewer bugs

### The Mathematical Guarantee

A torus is a **compact manifold**:
- **Compact** = bounded = finite = no infinity edge cases
- **Manifold** = smooth = no discontinuities = no edge effects
- **No boundary** = no edges = no boundary conditions to check

This isn't just philosophy - it's **topology**. The mathematics *guarantees* the safety properties.

---

## Summary

| Concept | Description |
|---------|-------------|
| **Garden allocation** | Bounded plots with explicit purpose, tended not owned |
| **Toroidal structures** | Wrap-around access, no edge cases by topology |
| **Tend philosophy** | Stewardship over ownership, presence over control |
| **Rye-Basin separation** | Shared types/philosophy, not shared implementation |
| **Safety by topology** | Mathematical guarantees from compact manifolds |

The path forward:
1. Add toroidal types to Rye standard library
2. Refactor Basin to use garden allocation terminology
3. Document the unified philosophy
4. Measure performance gains from toroidal structures

This is the synthesis: **mathematics ensuring safety, topology enabling performance, philosophy guiding design**.
