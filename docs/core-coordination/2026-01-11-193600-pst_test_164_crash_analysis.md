# Test 164 Crash Analysis - Stack Overflow

**Date**: 2026-01-11-193600-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Analyze GDB stack trace to identify root cause of crash  
**Status**: ✅ **ROOT CAUSE IDENTIFIED** — Stack overflow in test initialization

---

## Executive Summary

**Root Cause**: **Stack overflow** during `FullStackTestEnv.init()` allocation.

The crash occurs at the very beginning of the test function when Zig's stack probe tries to verify stack space. The `FullStackTestEnv` struct is too large to fit on the stack.

---

## GDB Stack Trace Analysis

### Crash Location
```
#0  0x0000000001059f7d in 164_end_to_end_integration_test.test.process lifecycle: spawn integration ()
```

### Instruction at Crash Point
```asm
=> 0x1059f7d <164_end_to_end_integration_test.test.process lifecycle: spawn integration+13>:
   test   %esp,-0x1000(%rsp,%r10,1)
```

**What this means**: This is a **stack probe instruction**. Zig inserts these to check if there's enough stack space before allocating large stack frames. The crash happens because the stack doesn't have enough space.

### Call Stack
```
#0  164_end_to_end_integration_test.test.process lifecycle: spawn integration ()
#1  test_runner.mainTerminal ()
#2  test_runner.main ()
#3  start.main ()
```

The crash occurs **immediately** when entering the test function, before any actual test code runs.

---

## Root Cause

### Problem: Stack Overflow

The `FullStackTestEnv` struct contains:
- `VM` (8MB memory array)
- `BasinKernel` (large struct with many subsystems)
- `Integration`
- `Supervisor`
- `ServiceManager`
- `Executor`
- `ShellEnvironment`
- `JobManager`
- `std.heap.ArenaAllocator`

**Total size**: Likely > 8MB (mostly from `VM.memory: [8MB]u8`)

**Stack limit**: Typically 8MB on Linux, but the test is trying to allocate this on the stack.

### Why It Crashes

1. Test function starts: `test "process lifecycle: spawn integration"`
2. Zig compiler inserts stack probe to check for space
3. Stack probe instruction: `test %esp,-0x1000(%rsp,%r10,1)`
4. **CRASH**: Stack doesn't have enough space → segmentation fault

---

## Solution

### Option 1: Allocate on Heap (Recommended)

Change `FullStackTestEnv.init()` to return a heap-allocated pointer:

```zig
pub fn init() !*FullStackTestEnv {
    const env = try testing.allocator.create(FullStackTestEnv);
    env.* = .{
        // ... initialization ...
    };
    return env;
}

// In test:
var env = try FullStackTestEnv.init();
defer testing.allocator.destroy(env);
```

### Option 2: Use Smaller Test Environment

Create a minimal test environment that doesn't include the full VM:

```zig
pub const MinimalTestEnv = struct {
    kernel: BasinKernel,
    integration: Integration,
    // ... minimal fields only ...
};
```

### Option 3: Increase Stack Size

Set larger stack size (not recommended, just a workaround):

```bash
ulimit -s 16384  # 16MB stack
```

---

## Recommended Fix

**Use Option 1**: Allocate `FullStackTestEnv` on the heap.

**Why**: 
- Cleanest solution
- Follows Zig best practices for large structs
- Doesn't require changing test structure
- Works on all systems

**Implementation**:
1. Change `init()` to return `!*FullStackTestEnv`
2. Use `testing.allocator.create()` to allocate
3. Update all tests to use `try` and `defer destroy()`

---

## Files to Modify

- `tests/164_end_to_end_integration_test.zig`:
  - Change `FullStackTestEnv.init()` signature
  - Update all test functions to use heap allocation
  - Add proper cleanup with `defer`

---

## Status

✅ **Root cause identified**: Stack overflow  
✅ **Solution identified**: Heap allocation  
⏳ **Fix pending**: Implementation needed

---

## Next Steps

1. Modify `FullStackTestEnv.init()` to use heap allocation
2. Update all 61 test functions in test 164
3. Verify fix with GDB (should no longer crash)
4. Run full test suite to ensure no regressions
