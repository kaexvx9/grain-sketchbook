# Test 164 Runtime Crash Investigation

**Date**: 2026-01-11-192500-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Document investigation of runtime crash (signal 11) in test 164  
**Status**: 🔍 **INVESTIGATION IN PROGRESS** — Crash persists after multiple fixes

---

## Executive Summary

Test 164 (`tests/164_end_to_end_integration_test.zig`) compiles successfully but crashes at runtime with signal 11 (segmentation fault) in the "process lifecycle: spawn integration" test. Multiple fixes have been applied, but the crash persists.

**Key Achievement**: Test 164 compiles with 0 errors and begins execution.

**Current Issue**: Runtime crash (signal 11) when calling `sysinfo` syscall through VM integration layer.

---

## Crash Details

**Test**: `"process lifecycle: spawn integration"`  
**Location**: `tests/164_end_to_end_integration_test.zig:288`  
**Error**: Signal 11 (segmentation fault)  
**Call Stack** (inferred):
1. `call_syscall_via_vm()` → sets up VM registers
2. `vm.execute_ecall()` → executes ECALL instruction
3. `syscall_handler_wrapper()` → calls kernel syscall handler
4. `handle_syscall()` → routes to `syscall_sysinfo()`
5. **CRASH** (likely in timer access or kernel field access)

---

## Fixes Applied

### 1. Fixed Test to Use Valid Pointer
- **Issue**: Test was calling `sysinfo` with `arg1 = 0` (null pointer)
- **Fix**: Changed to use valid VM memory address (`0x1000`)
- **Result**: Still crashes (crash happens before null check)

### 2. Increased Syscall Number Range
- **Issue**: Assertion `syscall_num <= 50` was too restrictive
- **Fix**: Increased to `syscall_num <= 200`
- **Result**: Compilation fix, doesn't affect runtime

### 3. Commented Out Debug Print
- **Issue**: Debug print in `execute_ecall` might cause issues
- **Fix**: Commented out debug print statement
- **Result**: Still crashes

### 4. Added Safety Checks
- **Issue**: Potential null pointer or uninitialized memory access
- **Fix**: Added assertions for VM memory, integration state, kernel pointer
- **Result**: Still crashes (assertions pass, crash happens later)

---

## Likely Causes

Based on code analysis, the crash is likely due to one of:

1. **Timer Access Issue**: `syscall_sysinfo` calls `self.timer.get_uptime_ns()` which calls `TimeSource.get_time_ns()`. If `TimeSource` is not properly initialized, this could crash.

2. **Kernel Pointer Invalid**: The kernel pointer passed to `handle_syscall` might be invalid or point to uninitialized memory.

3. **VM Memory Access**: Accessing `vm.memory` or kernel fields might trigger invalid memory access.

4. **Function Pointer Issue**: The syscall handler function pointer might be invalid or corrupted.

5. **Stack Overflow**: Large struct initialization might cause stack overflow (unlikely, but possible).

---

## Code Path Analysis

```
test "process lifecycle: spawn integration"
  → FullStackTestEnv.init()
    → VM.init() ✅
    → BasinKernel.init() ✅
      → Timer.init() ✅
        → TimeSource.get_time_ns() ✅ (default implementation)
    → Integration.init_with_kernel() ✅
    → integration.finish_init() ✅
  → call_syscall_via_vm(integration, Syscall.sysinfo, 0x1000, ...)
    → vm.execute_ecall()
      → syscall_handler_wrapper()
        → syscall_handler_wrapper_impl()
          → handle_syscall(kernel, ...)
            → syscall_sysinfo()
              → self.timer.get_uptime_ns() ⚠️ (possible crash here)
```

---

## Next Steps

### Recommended: Use GDB/lldb for Stack Trace

```bash
# Build test with debug symbols
zig build test -Doptimize=Debug

# Run with GDB
gdb --args .zig-cache/o/.../test

# In GDB:
(gdb) run
(gdb) bt  # Get backtrace when crash occurs
(gdb) info registers  # Check register state
(gdb) x/10i $pc  # Check instruction at crash point
```

### Alternative: Add More Defensive Checks

1. **Add null checks** before timer access:
   ```zig
   if (self.timer.initialized) {
       const uptime_ns = self.timer.get_uptime_ns();
   } else {
       return BasinError.invalid_syscall;
   }
   ```

2. **Add bounds checking** for all memory accesses

3. **Add function pointer validation** before calling syscall handler

4. **Use try-catch** around timer access to catch panics

### Alternative: Simplify Test

1. **Test with simpler syscall** (e.g., `yield`) that doesn't access timer
2. **Test kernel initialization** separately
3. **Test VM initialization** separately
4. **Test integration layer** separately

---

## Files Modified

- `tests/164_end_to_end_integration_test.zig`: Fixed to use valid pointer for sysinfo
- `src/kernel_vm/vm.zig`: Increased syscall number range, commented out debug print
- `build.zig`: Added libc linking for test 164

---

## Status

✅ **Compilation**: Test 164 compiles with 0 errors  
✅ **Execution**: Test begins execution  
❌ **Runtime**: Test crashes with signal 11  
🔍 **Investigation**: Ongoing - need GDB stack trace to identify exact crash location

---

## Conclusion

Test 164 has made significant progress:
- ✅ Compiles successfully
- ✅ Executes (not blocked by compilation)
- ❌ Crashes at runtime (needs debugging)

The crash is likely in the syscall execution path, possibly in timer access or kernel field access. A GDB stack trace would help identify the exact location and cause of the crash.
