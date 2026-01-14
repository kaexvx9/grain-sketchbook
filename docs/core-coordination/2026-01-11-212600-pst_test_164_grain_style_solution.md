# Test 164: Grain Style Solution

**Date**: 2026-01-11-212600-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Redesign test 164 using Grain Style arena allocators  
**Status**: 📋 **SOLUTION READY**

---

## The Grain Style Way: Arena Allocators

### Current Problem
- Stack allocation of large structs (8MB VM, 76KB Kernel)
- Unbounded, unpredictable
- Violates Grain Style principle of bounded allocation

### Grain Style Solution
- **Arena allocators** (pre-allocated at startup)
- **Bounded** (explicit size)
- **Predictable** (all at test start)
- **Explicit** (visible allocation)

---

## Proposed Design

### Test Helper Functions (Grain Style)

```zig
// Grain Style: Arena-based test helpers
pub const TestHelpers = struct {
    /// Create VM via arena (Grain Style: bounded, explicit)
    pub fn create_vm(arena: std.mem.Allocator) !*VM {
        const vm = try arena.create(VM);
        VM.init(vm, &[_]u8{}, 0x80000000);
        return vm;
    }
    
    /// Create Kernel via arena (Grain Style: bounded, explicit)
    pub fn create_kernel(arena: std.mem.Allocator) !*BasinKernel {
        const kernel = try arena.create(BasinKernel);
        BasinKernel.init_in_place(kernel);
        return kernel;
    }
    
    /// Create Integration via arena (Grain Style: bounded, explicit)
    pub fn create_integration(arena: std.mem.Allocator, vm: *VM, kernel: *BasinKernel) !*Integration {
        const integration = try arena.create(Integration);
        integration.* = Integration.init_with_kernel(vm, kernel);
        integration.finish_init();
        return integration;
    }
};
```

### Test Pattern (Grain Style)

```zig
test "process lifecycle: spawn integration" {
    // Grain Style: Arena allocator (bounded, explicit)
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    // Allocate large structs via arena (Grain Style: bounded)
    const vm = try TestHelpers.create_vm(allocator);
    const kernel = try TestHelpers.create_kernel(allocator);
    const integration = try TestHelpers.create_integration(allocator, vm, kernel);
    
    // Test code...
}
```

---

## Why This is Grain Style

1. ✅ **Bounded**: Arena has explicit bounds
2. ✅ **Predictable**: All allocation at test start
3. ✅ **Explicit**: Arena is visible
4. ✅ **No stack overflow**: Large structs on heap
5. ✅ **Startup-time allocation**: Matches Grain Style principle

---

## Implementation Plan

1. Create `tests/test_helpers.zig` with arena-based helpers
2. Rewrite test 164 using helpers
3. Verify no stack overflow
4. Document pattern for future tests

---

## Benefits

- ✅ Grain Style compliant
- ✅ No stack overflow
- ✅ Clear ownership (arena)
- ✅ Easy to test
- ✅ Future-proof pattern
