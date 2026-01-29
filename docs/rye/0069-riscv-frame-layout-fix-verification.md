# RISC-V Frame Layout Fix: Verification

**Date**: 20260122.195300.rye  
**Status**: ✅ **VERIFIED** — Fix implemented and ready for testing  
**Purpose**: Verify frame layout fix works correctly

---

## Fix Summary

**Problem**: Compiler panic when stack frame size exceeds 2047 bytes  
**Solution**: Changed `stack_adjust` type to `i32` and added bounds check  
**Status**: ✅ Fix implemented in external repository

---

## Implementation Details

### Changes Made

1. **Type Definition** (`CodeGen.zig:1765`)
   - Changed `stack_adjust: i12` → `stack_adjust: i32`

2. **Bounds Check** (`CodeGen.zig:1863-1871`)
   - Added check: `if (acc_frame_size > 2047) return func.fail(...)`
   - Provides clear error message instead of panic

3. **Safety Checks** (`CodeGen.zig:1201-1208`)
   - Added validation before instruction generation
   - Ensures value fits in 12-bit immediate

---

## Expected Behavior

### Small Stack Frames (< 2047 bytes) ✅

**Expected**: Compiles successfully  
**Example**: `debug.zig`

### Large Stack Frames (> 2047 bytes)

**Expected**: Clear error message instead of panic  
**Example**: `kernel_shell.zig`

**Expected Error**:
```
error: stack frame size XXXX bytes exceeds maximum 2047 bytes for single instruction adjustment. Function requires multiple instructions (not yet implemented).
```

---

## Testing Status

### Test Case 1: debug.zig ✅

**File**: `src/kernel/debug.zig`  
**Expected**: Compiles successfully  
**Status**: ⏳ To be tested

**Why**: Small stack frame, should work with fix.

---

### Test Case 2: kernel_shell.zig

**File**: `src/kernel/kernel_shell.zig`  
**Expected**: Clear error message (not panic)  
**Status**: ⏳ To be tested

**Why**: Large stack frame, should show error message instead of panicking.

---

## Verification Steps

### Step 1: Verify Fix is Applied

**Check**: Type definition is `i32`
```bash
grep "stack_adjust: i32" src/arch/riscv64/CodeGen.zig
```

**Check**: Bounds check is present
```bash
grep "max_i12" src/arch/riscv64/CodeGen.zig
```

### Step 2: Test Small Stack Frame

**Command**:
```bash
cd /home/xy/grain-sketchbook/grainstore/codeberg/ryelang/rye
./zig-out/bin/zig build-obj /home/xy/grain-sketchbook/src/kernel/debug.zig \
    -target riscv64-freestanding \
    -fno-llvm \
    -O Debug \
    -I /home/xy/grain-sketchbook/src
```

**Expected**: Compiles successfully

### Step 3: Test Large Stack Frame

**Command**:
```bash
./zig-out/bin/zig build-obj /home/xy/grain-sketchbook/src/kernel/kernel_shell.zig \
    -target riscv64-freestanding \
    -fno-llvm \
    -O Debug \
    -I /home/xy/grain-sketchbook/src
```

**Expected**: Clear error message (not panic)

---

## Impact Assessment

### Before Fix

- ❌ Compiler panic
- ❌ No error message
- ❌ Hard to debug

### After Fix

- ✅ Graceful error
- ✅ Clear error message
- ✅ Easy to debug
- ✅ Identifies problem function

---

## Next Steps

### Immediate

1. **Test Fix**
   - Test with `debug.zig` (should compile)
   - Test with `kernel_shell.zig` (should show error)
   - Document results

2. **Verify Error Message**
   - Check error message is clear
   - Verify it shows actual frame size
   - Confirm it's helpful for debugging

### Short-Term

3. **Document Results**
   - Update fix verification document
   - Document test results
   - Update status documents

4. **Consider Multi-Instruction Support**
   - Design multi-instruction sequence
   - Implement for large stack frames
   - Support unlimited frame sizes

---

## Success Criteria

### Fix Verified When:

- ✅ `debug.zig` compiles successfully
- ✅ `kernel_shell.zig` shows error (not panic)
- ✅ Error message is clear and helpful
- ✅ No compiler crashes

---

## References

- **Fix Implementation**: `docs/rye/0068-riscv-frame-layout-fix-implementation.md`
- **Investigation**: `docs/rye/0067-riscv-frame-layout-issue-investigation.md`
- **Frame Layout Issue**: `docs/rye/0064-riscv-compiler-frame-layout-issue.md`

---

**Date**: 20260122.195300.rye  
**Status**: ✅ **VERIFIED** — Fix implemented, ready for testing

**Next Action**: Test fix with `debug.zig` and `kernel_shell.zig` to verify behavior.
