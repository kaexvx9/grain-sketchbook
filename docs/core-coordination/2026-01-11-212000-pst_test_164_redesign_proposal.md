# Test 164: Bottom-Up Redesign Proposal

**Date**: 2026-01-11-212000-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Propose clean-slate redesign to avoid stack overflow from the start  
**Status**: 📋 **PROPOSAL READY**

---

## Problem with Current Design

1. **Large structs on stack**: VM (8MB), BasinKernel (76KB) allocated on stack
2. **Stack overflow**: Zig's stack probe fails at test function entry
3. **Fighting symptoms**: Fixing stack temporaries one by one
4. **Root cause**: Design assumes stack allocation is safe

---

## Proposed Solution: Bottom-Up Redesign

### Core Principle: **Heap-First Architecture**

**Rule**: Any struct > 1KB must be heap-allocated by default.

### Design Changes

#### 1. VM: Always Heap-Allocated
```zig
// OLD: VM allocated on stack
var vm: VM = undefined;
VM.init(&vm, ...);

// NEW: VM always heap-allocated
pub fn create() !*VM {
    const vm = try allocator.create(VM);
    vm.init(...);
    return vm;
}
```

#### 2. BasinKernel: Always Heap-Allocated
```zig
// OLD: Kernel allocated on stack
var kernel: BasinKernel = undefined;
BasinKernel.init_in_place(&kernel);

// NEW: Kernel always heap-allocated
pub fn create() !*BasinKernel {
    const kernel = try allocator.create(BasinKernel);
    kernel.init_in_place();
    return kernel;
}
```

#### 3. Integration: Pointer-Based
```zig
// NEW: Integration stores pointers, never values
pub const Integration = struct {
    vm: *VM,           // Always pointer
    kernel: *BasinKernel,  // Always pointer
    // ... no large values
};
```

#### 4. Test Framework: Stack-Safe
```zig
// NEW: Test helpers return pointers
pub fn create_test_vm() !*VM { ... }
pub fn create_test_kernel() !*BasinKernel { ... }
pub fn create_test_integration(vm: *VM, kernel: *BasinKernel) !*Integration { ... }

// Tests use pointers only
test "example" {
    const vm = try create_test_vm();
    defer vm.destroy();
    // ... test code
}
```

---

## Implementation Plan

### Phase 1: Create New Stack-Safe Modules
1. Create `src/kernel_vm/vm_heap.zig` - Heap-allocated VM
2. Create `src/kernel/kernel_heap.zig` - Heap-allocated Kernel
3. Create `src/kernel_vm/integration_heap.zig` - Pointer-based Integration
4. Create `tests/test_helpers.zig` - Stack-safe test utilities

### Phase 2: Update Tests
1. Rewrite test 164 using new stack-safe helpers
2. Verify no stack overflow
3. Test all functionality

### Phase 3: Migrate or Archive
1. **Option A**: Migrate existing code to new pattern
2. **Option B**: Archive old code to `archaeology/`, keep new code
3. **Option C**: Keep both, mark old as deprecated

---

## Benefits

1. **No stack overflow**: Design prevents it from the start
2. **Clear ownership**: Heap allocation makes ownership explicit
3. **Easier testing**: Test helpers handle allocation
4. **Better performance**: Heap allocation is actually fine for large structs
5. **Future-proof**: New code follows safe patterns

---

## Migration Strategy

### Option 1: Parallel Implementation
- Create new stack-safe modules alongside old ones
- Gradually migrate tests
- Eventually remove old modules

### Option 2: Clean Slate
- Archive current code to `archaeology/`
- Start fresh with stack-safe design
- Rebuild from bottom up

### Option 3: Hybrid
- Keep core functionality (VM, Kernel)
- Redesign only test framework and Integration layer
- Minimal changes to existing code

---

## Recommendation

**Option 3 (Hybrid)** - Redesign test framework and Integration layer, keep core VM/Kernel but make them heap-safe by default.

**Why**: 
- Minimal disruption
- Fixes the immediate problem (test 164)
- Sets good patterns for future code
- Can migrate core later if needed

---

## Next Steps

1. Create `tests/test_helpers.zig` with stack-safe helpers
2. Rewrite test 164 using new helpers
3. Verify it works
4. Document the pattern for future tests
