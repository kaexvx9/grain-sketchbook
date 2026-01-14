# Test 164 Fix: VM.init() Stack Temporary

**Date**: 2026-01-11-201600-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Fix stack overflow in VM.init() caused by 8MB array literal  
**Status**: ✅ **FIX APPLIED** — Testing in progress

---

## Issue

In `src/kernel_vm/vm.zig`, the `VM.init()` function was creating an 8MB array literal on the stack:

```zig
target.* = .{
    .memory = [_]u8{0} ** VM_MEMORY_SIZE,  // 8MB stack temporary!
    ...
};
```

Even though `target` points to heap memory, the array literal `[_]u8{0} ** VM_MEMORY_SIZE` is created on the stack first, then copied to the heap. This causes a stack overflow.

---

## Fix Applied

Changed to initialize memory directly in heap location:

```zig
target.regs = .{};
@memset(&target.memory, 0); // Initialize 8MB memory array directly (avoid stack temporary)
target.memory_size = VM_MEMORY_SIZE;
target.state = .halted;
target.last_error = null;
target.exception_stats = exception_stats_mod.ExceptionStats.init();
target.memory_stats = memory_stats_mod.VMMemoryStats.init(VM_MEMORY_SIZE);
```

This avoids creating the 8MB stack temporary.

---

## Files Modified

- `src/kernel_vm/vm.zig`: Changed VM.init() to use @memset instead of array literal

---

## Status

✅ **Fix applied**  
⏳ **Testing**: Verifying if this resolves the stack overflow crash
