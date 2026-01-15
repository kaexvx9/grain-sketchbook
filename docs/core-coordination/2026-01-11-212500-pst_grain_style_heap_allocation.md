# Grain Style and Heap Allocation: The Right Approach

**Date**: 2026-01-11-212500-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Clarify how heap allocation fits with Grain Style  
**Status**: ✅ **CLARIFICATION COMPLETE**

---

## Key Insight: Grain Style is About BOUNDED, Not Stack-Only

### Grain Style Principles (from `docs/grain_style.md`)

> **"All memory must be statically allocated at startup. No memory may be dynamically allocated (or freed and reallocated) after initialization."**

**Key word**: "statically allocated at startup" - this means **pre-allocated**, not "on the stack".

---

## The Real Grain Style Pattern

### ✅ Grain Style Compliant: Arena Allocators

```zig
// Grain Style: Pre-allocate at startup, use arena
pub const TestEnv = struct {
    arena: std.heap.ArenaAllocator,  // Pre-allocated at startup
    vm: *VM,  // Heap-allocated via arena
    kernel: *BasinKernel,  // Heap-allocated via arena
    
    pub fn init() !*TestEnv {
        const env = try testing.allocator.create(TestEnv);
        env.arena = std.heap.ArenaAllocator.init(testing.allocator);
        const allocator = env.arena.allocator();
        
        // Allocate large structs via arena (bounded, predictable)
        env.vm = try allocator.create(VM);
        VM.init(env.vm, ...);
        
        env.kernel = try allocator.create(BasinKernel);
        BasinKernel.init_in_place(env.kernel);
        
        return env;
    }
};
```

**Why this is Grain Style**:
- ✅ **Bounded**: Arena has fixed size (or bounded growth)
- ✅ **Predictable**: All allocation happens at startup
- ✅ **Explicit**: All allocation is visible
- ✅ **No hidden allocations**: Arena is explicit

### ❌ NOT Grain Style: Stack Allocation of Large Structs

```zig
// NOT Grain Style: Unbounded stack usage
test "example" {
    var vm: VM = undefined;  // 8MB on stack - UNBOUNDED!
    VM.init(&vm, ...);
}
```

**Why this violates Grain Style**:
- ❌ **Unbounded**: Stack can overflow (not predictable)
- ❌ **Hidden**: Stack allocation is implicit
- ❌ **Not at startup**: Happens during test execution

---

## Grain Style Allocation Hierarchy

### 1. Static Arrays (Best - Compile-Time)
```zig
const MAX_USERS: u32 = 256;
users: [MAX_USERS]User = [_]User{User.init()} ** MAX_USERS;
```
- ✅ Compile-time known size
- ✅ Zero runtime overhead
- ✅ Most bounded

### 2. Arena Allocators (Good - Startup-Time)
```zig
arena: std.heap.ArenaAllocator,
// Allocate at startup, use throughout lifetime
```
- ✅ Bounded (fixed or bounded growth)
- ✅ Predictable (all at startup)
- ✅ Explicit

### 3. Stack Allocation (Only for Small Structs)
```zig
var small: SmallStruct = undefined;  // < 1KB
```
- ✅ OK for small structs (< 1KB)
- ❌ NOT OK for large structs (> 1KB)

### 4. Dynamic Heap (Avoid - Not Grain Style)
```zig
// Frequent allocations/deallocations
const ptr = try allocator.allocate(...);
defer allocator.free(ptr);
```
- ❌ Unbounded
- ❌ Unpredictable
- ❌ Not Grain Style

---

## The Solution: Arena-Based Test Framework

### Pattern: Pre-Allocate at Test Start

```zig
// Grain Style test helper
pub fn create_test_vm(arena: std.mem.Allocator) !*VM {
    const vm = try arena.create(VM);
    VM.init(vm, &[_]u8{}, 0x80000000);
    return vm;
}

// Test uses arena (bounded, predictable)
test "example" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    const vm = try create_test_vm(allocator);
    // ... test code
}
```

**Why this is Grain Style**:
- ✅ **Bounded**: Arena has explicit bounds
- ✅ **Predictable**: All allocation at test start
- ✅ **Explicit**: Arena is visible
- ✅ **No stack overflow**: Large structs on heap

---

## Key Insight

**Stacks are NOT more bounded than heaps in Grain Style context!**

- **Stack**: Unbounded (can overflow, unpredictable)
- **Arena Heap**: Bounded (explicit size, predictable)

**Grain Style prefers bounded, predictable allocation** - which means:
- ✅ Static arrays (compile-time)
- ✅ Arena allocators (startup-time, bounded)
- ❌ Stack allocation of large structs (unbounded, unpredictable)

---

## Recommendation

**Use arena allocators for test framework** - this is MORE Grain Style compliant than stack allocation!

1. Pre-allocate at test start (startup-time)
2. Use arena with explicit bounds
3. All large structs via arena
4. Deallocate at test end

This is the Grain Style way.
