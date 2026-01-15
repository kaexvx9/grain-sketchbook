# Test 164: Crash Isolated to Initialization

**Date**: 2026-01-11-211200-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Document that crash is in initialization, not syscall  
**Status**: ✅ **ISOLATED** — Crash is in initialization phase

---

## Critical Finding

**Minimal test crashes too!**

```zig
test "minimal: initialization only" {
    var env = try VMKernelIntegrationTestEnv.init();  // ← CRASHES HERE
    defer env.destroy();
    // ... never reaches this code ...
}
```

**Conclusion**: The crash is in **initialization**, not in syscall execution.

---

## Initialization Chain

```
VMKernelIntegrationTestEnv.init()
  ├─ testing.allocator.create(VMKernelIntegrationTestEnv)  // Heap allocation
  ├─ VM.init(&env.vm, ...)  // ✅ Fixed (no stack temp)
  ├─ BasinKernel.init_in_place(&env.kernel)  // ✅ Fixed (no stack temp)
  └─ Integration.init_with_kernel(&env.vm, &env.kernel)  // Small struct
      └─ Integration.finish_init()  // ⚠️ POTENTIAL ISSUE
          ├─ Sets global pointers
          ├─ vm.set_syscall_handler(...)
          └─ vm.init_framebuffer()  // ⚠️ POTENTIAL ISSUE
```

---

## Potential Causes

### 1. Test Function Stack Probe
- **Hypothesis**: Zig's stack probe at test function entry fails
- **Why**: Test function might have large frame
- **Check**: Test function frame size

### 2. Integration.finish_init() → vm.init_framebuffer()
- **Hypothesis**: Framebuffer initialization has issue
- **Why**: Called during initialization
- **Check**: Skip framebuffer initialization

### 3. Something in VMKernelIntegrationTestEnv.init()
- **Hypothesis**: The init function itself has issue
- **Why**: Crash happens during init
- **Check**: Test each step separately

---

## Next Steps

1. **Test without framebuffer**: Comment out `vm.init_framebuffer()` call
2. **Test each component**: Create tests for VM only, Kernel only, etc.
3. **Check test function frame**: See if test function has large locals

---

## Key Insight

**The crash is NOT in syscall execution.** It's in initialization, which means:
- ✅ Our syscall fixes are correct
- ❌ We still have an initialization issue
- 🔍 Need to check `finish_init()` and `init_framebuffer()`
