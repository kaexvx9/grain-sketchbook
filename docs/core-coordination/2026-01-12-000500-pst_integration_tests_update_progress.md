# Integration Tests Update Progress

**Date**: 2026-01-12-000500-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Document integration tests update progress  
**Status**: 🔧 **IN PROGRESS** — Updating tests to Grain Style pattern

---

## Summary

**Updating integration tests to use Grain Style pattern!** Converting all tests from value-based to pointer-based allocation with arena allocators.

---

## Files Being Updated

### ✅ In Progress
- `tests/150_edge_case_integration_test.zig` - Converting to Grain Style, fixing API calls

### ⏳ Next
- `tests/149_syscall_combination_integration_test.zig`
- `tests/151_stress_integration_test.zig`
- `tests/152_error_handling_integration_test.zig`

---

## Changes Being Made

### 1. Update `create_test_integration()` Helper
**Before** (values on stack):
```zig
fn create_test_integration() struct { vm: VM, kernel: BasinKernel, integration: Integration } {
    var vm: VM = undefined;
    VM.init(&vm, ...);
    var kernel = BasinKernel.init();
    ...
}
```

**After** (pointers + arena):
```zig
fn create_test_integration() !struct { vm: *VM, kernel: *BasinKernel, integration: *Integration, arena: std.heap.ArenaAllocator } {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    const allocator = arena.allocator();
    
    const vm = try allocator.create(VM);
    VM.init(vm, ...);
    
    const kernel = try allocator.create(BasinKernel);
    BasinKernel.init_in_place(kernel);
    ...
}
```

### 2. Fix API Calls
**Before**:
```zig
kernel.handle_syscall(...)
kernel.syscall_spawn(...)
```

**After**:
```zig
basin_kernel.handle_syscall(&kernel, ...)
basin_kernel.handle_syscall(&kernel, @intFromEnum(Syscall.spawn), ...)
```

### 3. Add Cleanup
**After**:
```zig
const test_setup = try create_test_integration();
defer test_setup.arena.deinit();
```

---

## Status

- 🔧 **150_edge_case_integration_test.zig**: Fixing error handling
- ⏳ **Other tests**: Waiting for 150 to complete

---

## Next Steps

1. Finish fixing `tests/150_edge_case_integration_test.zig`
2. Update remaining integration tests
3. Verify all tests compile and pass
4. Document completion

---

## Key Insight

**Systematic updates are working!** Converting tests one by one ensures we maintain correctness while improving the codebase.
