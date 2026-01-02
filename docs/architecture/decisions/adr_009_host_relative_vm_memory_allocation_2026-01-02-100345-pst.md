# ADR 009: Host-Relative VM Memory Allocation

**Date**: 2026-01-02-100345-pst  
**Status**: ⚠️ **PROPOSED** — Under consideration  
**Deciders**: Vantage 3 Subcore Agent, VM Runtime Agent (3b)  
**Context**: Need to support large VM memory allocations (e.g., 48GB on 64GB host) for production use

---

## Context

**Problem**:
- Current VM memory is statically allocated (compile-time constant: 8MB)
- No concept of host-relative memory allocation or dynamic VM memory sizing
- Production use cases may require larger VM memory allocations
- Need to respect host machine memory constraints

**Current State**:
- `VM_MEMORY_SIZE: u64 = 8 * 1024 * 1024` (8MB, compile-time constant)
- VM memory allocated as static array: `memory: [VM_MEMORY_SIZE]u8`
- No host memory detection or limits
- Designed for small allocations (4MB-64MB recommended)

**Proposed Use Case**:
- Allocate 48GB to Vantage VM on 64GB Framework Ubuntu x86_64 laptop
- VM memory should be configurable relative to host machine RAM
- Support production workloads requiring large memory

---

## Decision

**Status**: ⚠️ **UNDER CONSIDERATION** — Need to evaluate use case and implementation approach

**Key Questions**:
1. **Is 48GB allocation necessary?** What production workload requires 48GB VM memory?
2. **Should VM memory be dynamic or static?** Current static allocation won't work for 48GB
3. **How should host memory be detected?** Need to detect available RAM and set limits
4. **What's the memory allocation strategy?** Static vs. dynamic, heap vs. mmap

**Recommendation**: **Evaluate use case first** before implementing large memory allocation.

---

## Analysis

### Current Architecture (Static Allocation)

**Pros**:
- ✅ Simple implementation (no allocator dependency)
- ✅ Predictable memory usage
- ✅ Bounded execution guarantees
- ✅ Fast initialization
- ✅ Stack-friendly (small allocations)

**Cons**:
- ❌ Cannot allocate 48GB (stack overflow, compile-time issues)
- ❌ Not configurable at runtime
- ❌ No host memory awareness
- ❌ Limited to small allocations (8MB default, 64MB max recommended)

### Proposed Architecture (Dynamic Allocation)

**Pros**:
- ✅ Can allocate large memory (48GB+)
- ✅ Configurable at runtime
- ✅ Host memory aware
- ✅ Supports production workloads

**Cons**:
- ⚠️ More complex implementation (allocator dependency)
- ⚠️ Less predictable memory usage
- ⚠️ Potential for memory exhaustion
- ⚠️ Slower initialization (large allocations)
- ⚠️ May require mmap for large allocations

---

## Use Case Evaluation

### Question 1: Is 48GB Allocation Necessary?

**Current VM Use Cases**:
- Kernel development (4MB-64MB sufficient)
- Kernel testing (4MB-64MB sufficient)
- Basic userspace programs (4MB-64MB sufficient)

**Potential Production Use Cases**:
- Large database workloads (may need 48GB+)
- Memory-intensive applications (may need 48GB+)
- Multi-process systems (may need 48GB+)

**Recommendation**: **Clarify use case** before implementing 48GB allocation.

### Question 2: What's the Actual Requirement?

**Framework x86_64 (64GB RAM)**:
- **48GB to VM**: 75% of host RAM
- **16GB remaining**: For host OS, applications, overhead
- **Question**: Is this the right split? What's the actual workload?

**Alternative Approaches**:
- **Smaller allocation**: 8GB-16GB VM memory (more reasonable for most workloads)
- **Dynamic sizing**: Start small, grow as needed
- **Memory limits**: Set max VM memory based on host RAM (e.g., 50% of available RAM)

---

## Proposed Implementation (If Approved)

### Option 1: Dynamic Allocation with Host Memory Detection

**Architecture**:
```zig
pub const VM = struct {
    /// Physical memory (dynamically allocated).
    /// Why: Support large memory allocations (48GB+).
    memory: []u8,
    /// Memory size in bytes (configurable at runtime).
    memory_size: u64,
    /// Allocator for memory management.
    allocator: std.mem.Allocator,
    
    /// Initialize VM with configurable memory size.
    pub fn init(
        self: *VM,
        allocator: std.mem.Allocator,
        memory_size: u64,
    ) !void {
        // Detect host memory
        const host_memory = try detect_host_memory();
        
        // Validate memory size
        if (memory_size > host_memory.available) {
            return error.MemorySizeTooLarge;
        }
        
        // Allocate VM memory
        self.memory = try allocator.alloc(u8, memory_size);
        self.memory_size = memory_size;
        self.allocator = allocator;
    }
    
    /// Deinitialize VM (free memory).
    pub fn deinit(self: *VM) void {
        self.allocator.free(self.memory);
    }
};
```

**Host Memory Detection**:
```zig
pub const HostMemory = struct {
    total: u64,
    available: u64,
    used: u64,
};

pub fn detect_host_memory() !HostMemory {
    // Platform-specific detection
    // Linux: /proc/meminfo
    // macOS: sysctl hw.memsize
    // Windows: GlobalMemoryStatusEx
}
```

### Option 2: Static Allocation with Configurable Size

**Architecture**:
```zig
// Compile-time configuration
pub const VM_MEMORY_SIZE: u64 = if (builtin.mode == .Debug)
    8 * 1024 * 1024  // 8MB for development
else
    48 * 1024 * 1024 * 1024;  // 48GB for production

pub const VM = struct {
    memory: [VM_MEMORY_SIZE]u8 = [_]u8{0} ** VM_MEMORY_SIZE,
    memory_size: u64 = VM_MEMORY_SIZE,
};
```

**Pros**: Simple, no allocator dependency  
**Cons**: Still compile-time constant, cannot adjust at runtime

### Option 3: Hybrid Approach (Recommended)

**Architecture**:
- **Small allocations (< 64MB)**: Static allocation (current approach)
- **Large allocations (>= 64MB)**: Dynamic allocation (heap or mmap)
- **Host memory detection**: Detect available RAM and set limits
- **Configurable at runtime**: Allow VM memory size configuration

**Implementation**:
```zig
pub const VM = struct {
    /// Physical memory (static for small, dynamic for large).
    memory_small: [64 * 1024 * 1024]u8 = undefined,  // 64MB static buffer
    memory_large: ?[]u8 = null,  // Dynamic allocation for large memory
    memory: []u8,  // Points to either static or dynamic memory
    memory_size: u64,
    allocator: ?std.mem.Allocator = null,
    
    /// Initialize VM with configurable memory size.
    pub fn init(
        self: *VM,
        allocator: ?std.mem.Allocator,
        memory_size: u64,
    ) !void {
        const SMALL_MEMORY_THRESHOLD: u64 = 64 * 1024 * 1024;  // 64MB
        
        if (memory_size <= SMALL_MEMORY_THRESHOLD) {
            // Use static allocation
            self.memory = &self.memory_small;
            self.memory_size = memory_size;
            self.allocator = null;
        } else {
            // Use dynamic allocation
            if (allocator == null) {
                return error.AllocatorRequired;
            }
            
            // Detect host memory
            const host_memory = try detect_host_memory();
            if (memory_size > host_memory.available) {
                return error.MemorySizeTooLarge;
            }
            
            // Allocate large memory
            self.memory_large = try allocator.?.alloc(u8, memory_size);
            self.memory = self.memory_large.?;
            self.memory_size = memory_size;
            self.allocator = allocator;
        }
    }
    
    /// Deinitialize VM (free dynamic memory if allocated).
    pub fn deinit(self: *VM) void {
        if (self.allocator) |alloc| {
            alloc.free(self.memory_large.?);
        }
    }
};
```

---

## Recommendations

### Immediate Recommendation

**Before implementing 48GB allocation**:
1. **Clarify use case**: What production workload requires 48GB VM memory?
2. **Evaluate alternatives**: Can the workload work with smaller allocations (8GB-16GB)?
3. **Consider memory limits**: Set max VM memory based on host RAM (e.g., 50% of available RAM)

### If 48GB Allocation Is Necessary

**Recommended Approach**: **Hybrid approach (Option 3)**
- Small allocations (< 64MB): Static allocation (current approach)
- Large allocations (>= 64MB): Dynamic allocation with host memory detection
- Configurable at runtime: Allow VM memory size configuration
- Memory limits: Respect host machine constraints

**Implementation Steps**:
1. Add host memory detection (platform-specific)
2. Add dynamic allocation support for large memory
3. Add VM memory size configuration API
4. Add memory limit validation
5. Update documentation

---

## Consequences

### Positive (If Implemented)

- ✅ Supports large memory allocations (48GB+)
- ✅ Configurable at runtime
- ✅ Host memory aware
- ✅ Supports production workloads

### Negative (If Implemented)

- ⚠️ More complex implementation
- ⚠️ Allocator dependency for large allocations
- ⚠️ Potential for memory exhaustion
- ⚠️ Slower initialization for large allocations
- ⚠️ May require mmap for very large allocations

### Neutral

- Implementation can be done incrementally
- Small allocations can remain static (backward compatible)

---

## Alternatives Considered

1. **Keep Static Allocation (Current)**: Rejected — cannot support 48GB
2. **Full Dynamic Allocation**: Rejected — loses benefits of static allocation for small cases
3. **Hybrid Approach**: **RECOMMENDED** — best of both worlds

---

## Implementation Status

**Date**: 2026-01-02-100345-pst  
**Status**: ⚠️ **PROPOSED** — Under consideration

**Next Steps**:
1. **Clarify use case**: What production workload requires 48GB VM memory?
2. **Evaluate alternatives**: Can workload work with smaller allocations?
3. **If approved**: Implement hybrid approach (Option 3)

---

## References

- `docs/zyx/vm_memory_config.md` — Current VM memory configuration
- `src/kernel_vm/vm.zig` — Current VM implementation
- `docs/architecture/decisions/adr_009_host_relative_vm_memory_allocation_2026-01-02-100345-pst.md` — This ADR

---

**Date**: 2026-01-02-100345-pst  
**Status**: ⚠️ **PROPOSED** — Under consideration, awaiting use case clarification

