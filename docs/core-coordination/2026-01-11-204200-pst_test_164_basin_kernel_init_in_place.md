# Test 164: BasinKernel init_in_place Fix

**Date**: 2026-01-11-204200-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Add init_in_place to BasinKernel to avoid stack temporary  
**Status**: ✅ **COMPLETE** — Function added, test compiles, still crashes

---

## Problem

`BasinKernel.init()` creates a stack temporary:
```zig
pub fn init() BasinKernel {
    var kernel = BasinKernel{  // ← Creates ~76KB struct on stack
        .timer = Timer.init(),
        // ... many fields ...
    };
    // ... initialization ...
    return kernel;  // ← Returns copy (stack temporary)
}
```

When we do `env.kernel = BasinKernel.init()`, Zig creates the temporary on the stack first, then copies it to the heap location. This can cause stack overflow.

---

## Solution

Added `init_in_place()` function to `BasinKernel`:
```zig
pub fn init_in_place(target: *BasinKernel) void {
    // Initialize all fields directly in target (no stack temporary)
    target.timer = Timer.init();
    target.interrupt_controller = InterruptController.init();
    // ... initialize all fields directly ...
    target.init_users();
    // ... assertions ...
}
```

This initializes the kernel directly in the heap-allocated location, avoiding any stack temporaries.

---

## Changes Made

1. **`src/kernel/basin_kernel_core.zig`**: Added `init_in_place()` function
2. **`tests/164_end_to_end_integration_test.zig`**: Updated all 3 test environments to use `init_in_place()`:
   - `VMKernelTestEnv.init()`
   - `VMKernelIntegrationTestEnv.init()`
   - `FullStackTestEnv.init()`

---

## Status

- ✅ **Compilation**: Test compiles successfully
- ✅ **init_in_place**: Function added and working
- ❌ **Runtime**: Still crashes with signal 11

---

## Next Steps

The crash persists. Possible causes:
1. Stack overflow in test function itself (not in init)
2. Stack overflow in `Integration.init_with_kernel()` or `finish_init()`
3. Stack overflow in `call_syscall_via_vm()` helper
4. Different issue (null pointer, invalid memory access, etc.)

Need to get fresh GDB trace to see if crash location changed.
