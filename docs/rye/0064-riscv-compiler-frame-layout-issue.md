# RISC-V Compiler: Frame Layout Issue

**Date**: 20260122.194800.rye  
**Status**: 🔍 **ISSUE FOUND** — Compiler crash when compiling complex kernel files  
**Type**: Compiler internal error (separate from Issue 2)

---

## Issue Summary

**Error**: Compiler panic when compiling `kernel_shell.zig`

```
thread 828704 panic: integer does not fit in destination type
/home/xy/ry/grainstore/codeberg/ryelang/rye/src/arch/riscv64/CodeGen.zig:1864:25
        .stack_adjust = @intCast(acc_frame_size),
```

**Location**: `src/arch/riscv64/CodeGen.zig:1864` in `computeFrameLayout()`

**Cause**: Stack frame size calculation exceeds destination type capacity

---

## Test Results

### ✅ debug.zig: Compiles Successfully

**File**: `src/kernel/debug.zig`  
**Status**: ✅ Compiles without errors  
**Finding**: Our fixes work correctly for this file

### ❌ kernel_shell.zig: Compiler Crash

**File**: `src/kernel/kernel_shell.zig`  
**Status**: ❌ Compiler crashes during codegen  
**Error**: Frame layout calculation overflow  
**Finding**: Separate compiler limitation, not related to Issue 2

---

## Analysis

### Root Cause

**Problem**: The `computeFrameLayout()` function calculates a stack frame size that exceeds the capacity of the destination type in `@intCast()`.

**Location**: `CodeGen.zig:1864`
```zig
.stack_adjust = @intCast(acc_frame_size),
```

**Likely Cause**: `kernel_shell.zig` has a very large stack frame (many local variables, large arrays, etc.) that exceeds the maximum value for the destination integer type.

---

## Impact

### On Issue 2 Investigation

**Status**: Issue 2 investigation is **not blocked** by this

**Reasoning**:
- `debug.zig` compiles successfully (contains `kprint()` implementation)
- This is a separate compiler limitation
- Issue 2 is about function calls with `anytype`/`comptime`, not frame layout

**Conclusion**: We can still verify Issue 2 status with `debug.zig` and simpler test cases.

### On Kernel Compilation

**Status**: **Blocked** for complex kernel files

**Impact**:
- Cannot compile `kernel_shell.zig` with current compiler
- May affect other complex kernel files
- Needs to be fixed for full kernel compilation

---

## Next Steps

### Immediate

1. **Document Issue**
   - ✅ Document frame layout issue (this document)
   - ⏳ Investigate root cause
   - ⏳ Design fix

2. **Continue Issue 2 Investigation**
   - ✅ `debug.zig` compiles (contains `kprint()`)
   - ⏳ Test simpler kernel files
   - ⏳ Verify Issue 2 status independently

### Short-Term

3. **Fix Frame Layout Issue**
   - Investigate `computeFrameLayout()` implementation
   - Fix integer overflow
   - Test with `kernel_shell.zig`

4. **Complete Kernel Compilation Tests**
   - Test all kernel files
   - Document any other issues
   - Verify full kernel compilation

---

## Workaround

### For Issue 2 Testing

**Option 1**: Use `debug.zig` only
- `debug.zig` compiles successfully
- Contains `kprint()` implementation
- Can test Issue 2 patterns

**Option 2**: Create minimal test kernel
- Extract `kprint()` usage to minimal file
- Test with simple kernel code
- Verify Issue 2 status

**Option 3**: Fix frame layout issue first
- Fix compiler crash
- Then test full kernel compilation
- More comprehensive but takes longer

---

## Code Location

### Error Location

**File**: `grainstore/codeberg/ryelang/rye/src/arch/riscv64/CodeGen.zig`  
**Line**: 1864  
**Function**: `computeFrameLayout()`

**Code**:
```zig
.stack_adjust = @intCast(acc_frame_size),
```

### Investigation Needed

1. **Check `acc_frame_size` calculation**
   - What is the maximum value?
   - What type is it?
   - Why does it exceed destination type?

2. **Check destination type**
   - What type is `stack_adjust`?
   - What is its maximum value?
   - Can it be increased?

3. **Check `kernel_shell.zig`**
   - How large is the stack frame?
   - What causes it to be so large?
   - Can it be reduced?

---

## References

- **Kernel Compilation Test**: `docs/rye/0063-riscv-kernel-compilation-test-results.md`
- **Action Plan**: `docs/rye/0062-riscv-immediate-action-plan.md`
- **Issue 2 Investigation**: `docs/rye/0051-riscv-issue2-final-investigation-summary.md`

---

**Date**: 20260122.194800.rye  
**Status**: 🔍 **ISSUE FOUND** — Separate compiler limitation, not blocking Issue 2 investigation

**Next Action**: Continue Issue 2 investigation with `debug.zig`, investigate frame layout issue separately.
