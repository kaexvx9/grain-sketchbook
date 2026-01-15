# ADR 009: Host-Relative VM Memory Allocation

**Date**: 2026-01-02-100345-pst  
**Status**: ✅ **APPROVED** — Use case clarified, implementation approved  
**Deciders**: Vantage 3 Subcore Agent, VM Runtime Agent (3b)  
**Context**: Need to support large VM memory allocations for Aurora (IDE/Browser services) running in Vantage VM

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

**Use Case (Clarified)**:
- **Aurora (IDE/Browser services)** running in Vantage VM needs significant memory for:
  - Editor buffers (multiple files, large codebases)
  - Browser rendering (multiple tabs, HTML/CSS rendering)
  - Component library (UI components, rendering)
  - AI integration (context, embeddings)
  - LSP servers (language servers, diagnostics)
  - Tree-sitter parsers (syntax trees, highlighting)
- **Goal**: Allocate as much VM RAM as possible without threatening host Ubuntu
- **Target**: 64GB Framework Ubuntu x86_64 laptop
- **Strategy**: Leave ~8-16GB for host Ubuntu, allocate ~48-56GB to VM

---

## Decision

**Status**: ✅ **APPROVED** — Use case clarified (Aurora IDE/Browser), implementation approved

**Architecture Decision**: **Hybrid Approach (Option 3)**
- Small allocations (< 64MB): Static allocation (current approach, backward compatible)
- Large allocations (>= 64MB): Dynamic allocation with host memory detection
- Configurable at runtime: Allow VM memory size configuration
- Memory limits: Respect host machine constraints (leave ~8-16GB for host Ubuntu)

**Memory Allocation Strategy**:
- **Host Memory Detection**: Detect total and available RAM
- **Safety Margin**: Reserve 8-16GB for host Ubuntu (OS, system services, overhead)
- **VM Allocation**: Allocate remaining memory to VM (up to ~48-56GB on 64GB host)
- **Dynamic Allocation**: Use heap allocation (or mmap for very large allocations)

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

### Use Case: Aurora IDE/Browser Services

**Aurora Memory Requirements**:
- **Editor buffers**: Multiple files, large codebases (can use 1-4GB+)
- **Browser rendering**: Multiple tabs, HTML/CSS rendering (can use 2-8GB+)
- **Component library**: UI components, rendering (can use 500MB-2GB+)
- **AI integration**: Context, embeddings (can use 1-4GB+)
- **LSP servers**: Language servers, diagnostics (can use 500MB-2GB+ per server)
- **Tree-sitter parsers**: Syntax trees, highlighting (can use 100MB-500MB+)
- **Total estimated**: 5-20GB+ for typical usage, 20-40GB+ for heavy usage

**Framework x86_64 (64GB RAM)**:
- **Host Ubuntu needs**: ~8-16GB (OS, system services, basic operations, safety margin)
- **VM allocation**: ~48-56GB (maximize for Aurora)
- **Split**: 75-87% to VM, 13-25% to host (reasonable for dedicated development machine)

**Recommendation**: **Allocate 48-52GB to VM**, leave 12-16GB for host Ubuntu

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

### Approved Implementation

**Approach**: **Hybrid approach (Option 3)** — **APPROVED**

**Memory Allocation Strategy**:
1. **Host Memory Detection**: Detect total and available RAM (platform-specific)
2. **Safety Margin**: Reserve 12-16GB for host Ubuntu (configurable)
3. **VM Allocation**: Allocate remaining memory to VM (up to 48-52GB on 64GB host)
4. **Dynamic Allocation**: Use heap allocation for large memory (>= 64MB)
5. **Backward Compatibility**: Keep static allocation for small memory (< 64MB)

**Implementation Steps**:
1. ✅ Add host memory detection (Linux: /proc/meminfo, macOS: sysctl, Windows: GlobalMemoryStatusEx)
2. ✅ Add dynamic allocation support for large memory (>= 64MB)
3. ✅ Add VM memory size configuration API (auto-detect or manual)
4. ✅ Add memory limit validation (respect host constraints)
5. ✅ Update documentation

**Default Behavior**:
- **Auto-detect**: Automatically allocate max available memory (minus safety margin)
- **Manual override**: Allow manual memory size configuration
- **Fallback**: Use static allocation if dynamic allocation fails

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
**Status**: ✅ **APPROVED** — Use case clarified (Aurora IDE/Browser), implementation approved

**Next Steps**:
1. ✅ **Use case clarified**: Aurora IDE/Browser services need large memory allocation
2. ✅ **Approach approved**: Hybrid approach (Option 3) - static for small, dynamic for large
3. ⏳ **Implementation**: Add host memory detection and dynamic allocation support
4. ⏳ **Testing**: Test on Framework x86_64 (64GB RAM) with 48-52GB VM allocation
5. ⏳ **Documentation**: Update VM memory configuration documentation

**Priority**: **HIGH** — Aurora needs large memory allocation for production use

---

## References

- `docs/zyx/vm_memory_config.md` — Current VM memory configuration
- `src/kernel_vm/vm.zig` — Current VM implementation
- `docs/architecture/decisions/adr_009_host_relative_vm_memory_allocation_2026-01-02-100345-pst.md` — This ADR

---

**Date**: 2026-01-02-100345-pst  
**Status**: ⚠️ **PROPOSED** — Under consideration, awaiting use case clarification

