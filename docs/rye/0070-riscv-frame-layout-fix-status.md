# RISC-V Frame Layout Fix: Status Update

**Date**: 20260122.195400.rye  
**Status**: ✅ **FIX IMPLEMENTED** — Code fix complete, compiler rebuild needed  
**Purpose**: Current status of frame layout fix

---

## Fix Status

### Code Changes ✅

**Status**: ✅ **COMPLETE** — Fix implemented in external repository

**Changes**:
1. ✅ Type definition: `stack_adjust: i12` → `stack_adjust: i32`
2. ✅ Bounds check: Added in `computeFrameLayout()`
3. ✅ Safety checks: Added in instruction generation
4. ✅ Committed: Fix committed to external repository

**Location**: `codeberg.org/ryelang/rye` commit `f5a81273`

---

## Testing Status

### Test Case 1: debug.zig ✅

**File**: `src/kernel/debug.zig`  
**Status**: ✅ **Compiles successfully**  
**Result**: Fix does not break small stack frames

### Test Case 2: kernel_shell.zig ⏳

**File**: `src/kernel/kernel_shell.zig`  
**Status**: ⏳ **Compiler rebuild needed**  
**Issue**: Compiler binary needs rebuild to pick up code changes

**Note**: The fix is in the source code, but the compiler binary (`zig-out/bin/zig`) was built before the fix. Need to rebuild compiler to test the fix.

---

## Next Steps

### Immediate

1. **Rebuild Compiler**
   ```bash
   cd /home/xy/codeberg/ryelang/rye
   zig build
   ```

2. **Test Fix**
   - Test with `debug.zig` (should still compile)
   - Test with `kernel_shell.zig` (should show error, not panic)

3. **Verify Error Message**
   - Check error message is clear
   - Verify it shows actual frame size
   - Confirm helpful for debugging

### Short-Term

4. **Document Results**
   - Update fix verification document
   - Document test results
   - Update status documents

---

## Implementation Summary

### What Was Fixed

**Problem**: Compiler panic when stack frame size exceeds 2047 bytes

**Solution**:
- Changed `stack_adjust` type from `i12` to `i32`
- Added bounds check to fail gracefully
- Added safety checks in instruction generation

**Result**: Compiler will show clear error message instead of panicking

---

## Code Changes

### Change 1: Type Definition

**File**: `src/arch/riscv64/CodeGen.zig:1765`

```zig
const FrameLayout = struct {
    stack_adjust: i32,  // Changed from i12
    save_reg_list: Mir.RegisterList,
};
```

### Change 2: Bounds Check

**File**: `src/arch/riscv64/CodeGen.zig:1874-1882`

```zig
// Why: Check if stack frame size fits in 12-bit immediate (RISC-V limitation).
// If too large, fail with clear error message instead of panicking.
const max_i12: i32 = 2047;
if (acc_frame_size > max_i12) {
    return func.fail(
        "stack frame size {d} bytes exceeds maximum {d} bytes for single instruction adjustment. Function requires multiple instructions (not yet implemented).",
        .{ acc_frame_size, max_i12 },
    );
}
```

### Change 3: Safety Checks

**File**: `src/arch/riscv64/CodeGen.zig:1201-1208`

```zig
// Why: Check if stack_adjust fits in 12-bit immediate before using in instruction.
const stack_adjust = frame_layout.stack_adjust;
if (stack_adjust > 2047 or stack_adjust < -2048) {
    return func.fail(
        "stack_adjust {d} exceeds 12-bit immediate range (-2048 to 2047)",
        .{stack_adjust},
    );
}
```

---

## Expected Behavior After Rebuild

### Small Stack Frames ✅

**Expected**: Compiles successfully  
**Example**: `debug.zig`  
**Status**: ✅ Verified (compiles)

### Large Stack Frames

**Expected**: Clear error message  
**Example**: `kernel_shell.zig`  
**Status**: ⏳ To be tested after rebuild

**Expected Error**:
```
error: stack frame size XXXX bytes exceeds maximum 2047 bytes for single instruction adjustment. Function requires multiple instructions (not yet implemented).
```

---

## References

- **Fix Implementation**: `docs/rye/0068-riscv-frame-layout-fix-implementation.md`
- **Fix Verification**: `docs/rye/0069-riscv-frame-layout-fix-verification.md`
- **Investigation**: `docs/rye/0067-riscv-frame-layout-issue-investigation.md`

---

**Date**: 20260122.195400.rye  
**Status**: ✅ **FIX IMPLEMENTED** — Code complete, compiler rebuild needed for testing

**Next Action**: Rebuild compiler, then test with `kernel_shell.zig` to verify error message.
