# Test 164 Stack Overflow Fix Status

**Date**: 2026-01-11-200916-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Document stack overflow fix progress  
**Status**: 🔧 **FIX IN PROGRESS** — Heap allocation implemented, test still crashes

---

## Summary

**Root Cause Identified**: Stack overflow due to `FullStackTestEnv` containing 8MB `VM` memory array.

**Fix Applied**: 
- Changed `FullStackTestEnv.init()` to return `!*FullStackTestEnv` (heap-allocated pointer)
- Initialize all fields directly in heap-allocated struct
- Updated all 61 test functions to use `try` and `defer env.destroy()`

**Current Status**: Test still crashes with signal 11, but crash location may have changed.

---

## Changes Made

1. **Heap Allocation**: `FullStackTestEnv.init()` now allocates on heap
2. **Direct Initialization**: VM, Kernel, Integration initialized directly in heap struct
3. **Proper Cleanup**: Added `destroy()` method to free heap-allocated struct
4. **All Tests Updated**: All 61 test functions updated to use heap allocation

---

## Next Steps

1. Verify crash location with GDB to confirm fix is working
2. Check if crash is now in a different location (syscall execution vs initialization)
3. If still in initialization, investigate other potential stack allocations

---

## Files Modified

- `tests/164_end_to_end_integration_test.zig`: Heap allocation for `FullStackTestEnv`
