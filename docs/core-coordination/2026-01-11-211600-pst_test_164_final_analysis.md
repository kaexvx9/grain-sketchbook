# Test 164: Final Analysis and Solution

**Date**: 2026-01-11-211600-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Final analysis and recommended solution  
**Status**: ✅ **ANALYSIS COMPLETE** — Solution identified

---

## Root Cause: Stack Probe at Test Function Entry

**The crash happens at the test function entry**, before any code runs. This is a **stack probe failure**.

Even the simplest test crashes:
```zig
test "minimal: VM only" {
    const vm = try create_vm_on_heap();  // ← Crashes here
    defer testing.allocator.destroy(vm);
}
```

---

## Why This Happens

1. **Zig's stack probe**: Checks if there's enough stack space for the function's frame
2. **Test function frame**: Even with heap allocation, the test function frame might be large
3. **Stack limit**: Default stack size might be too small for test functions with large types

---

## Solutions

### Solution 1: Increase Stack Size (Quick Fix)
```bash
ulimit -s 16384  # Increase to 16MB
zig build test
```

**Pros**: Quick, works immediately  
**Cons**: Doesn't fix root cause, might not work on all systems

### Solution 2: Refactor Tests to Use Only Pointers (Proper Fix)
- Create helper functions that return pointers
- Never put large types in test function frame
- Use heap allocation for everything

**Pros**: Proper fix, works everywhere  
**Cons**: Requires refactoring all tests

### Solution 3: Use Separate Test File (Workaround)
- Create minimal test file with smaller frame
- Test components separately
- Avoid large types in test signatures

**Pros**: Isolates problem  
**Cons**: Doesn't fix main test

---

## Recommended Approach

**Try Solution 1 first** (increase stack size) to verify this is the issue. If it works, then **implement Solution 2** (refactor to use pointers) for a proper fix.

---

## Status

- ✅ Root cause identified: Stack probe failure
- ✅ Solution options identified
- ⏳ Need to test stack size increase
- ⏳ Need to refactor tests if stack size works
