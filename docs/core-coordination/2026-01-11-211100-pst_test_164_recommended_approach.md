# Test 164: Recommended Approach

**Date**: 2026-01-11-211100-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Clear, actionable recommendation for solving the crash  
**Status**: ✅ **RECOMMENDATION READY**

---

## The Problem

Test 164 crashes with signal 11 even after fixing:
- ✅ VM.init() stack temporary
- ✅ BasinKernel.init() stack temporary  
- ✅ FullStackTestEnv heap allocation
- ✅ Smaller test environments

**We don't know WHERE it's crashing.**

---

## The Solution: Isolate First, Then Fix

### Step 1: Create Minimal Test (5 minutes)

Add this to `tests/164_end_to_end_integration_test.zig`:

```zig
// Minimal test: Just initialization, no syscall
test "minimal: initialization only" {
    var env = try VMKernelIntegrationTestEnv.init();
    defer env.destroy();
    const integration = env.get_integration();
    const vm = env.get_vm();
    
    // Just verify initialization worked
    try testing.expect(integration.initialized);
    try testing.expect(vm.state == .halted);
    try testing.expect(vm.syscall_handler != null);
}
```

**Run it**: `zig build test 2>&1 | grep "minimal"`

**If it passes**: Crash is in syscall execution  
**If it crashes**: Crash is in initialization

### Step 2: Based on Result

#### If Minimal Test Passes (Crash is in syscall)
- Check `call_syscall_via_vm()` helper
- Check `VM.execute_ecall()`
- Check syscall handler

#### If Minimal Test Crashes (Crash is in initialization)
- Check `Integration.finish_init()`
- Check `VM.init_framebuffer()`
- Check test function frame size

### Step 3: Fix the Issue

Once we know where it crashes, fix that specific issue.

---

## Why This Approach Works

1. **Fast**: Minimal test takes 5 minutes to write
2. **Clear**: Tells us exactly where the problem is
3. **Systematic**: No guessing, just test and fix
4. **Efficient**: Don't waste time on wrong fixes

---

## Alternative: If Minimal Test Doesn't Help

Get GDB trace:
```bash
TEST_EXE=$(find .zig-cache -name "test" -type f -executable | head -1)
gdb -batch -ex "run" -ex "bt 20" -ex "quit" "$TEST_EXE"
```

This will show exact crash location.

---

## Recommendation

**Do Step 1 first** (create minimal test). It's the fastest way to isolate the problem.
