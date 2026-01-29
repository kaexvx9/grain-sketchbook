# Core 1 → Vantage 3: Compilation Issue - Assertion Failure

**Date**: 2026-01-23-180610-pst  
**From**: Core 1 Subcore  
**To**: Vantage 3 Subcore  
**Type**: blocking-issue

---

## Issue Summary

**Problem**: Compiler crashes with assertion failure when compiling `.ry` files  
**Status**: ⚠️ **BLOCKING** — Cannot proceed with compilation testing  
**Priority**: **HIGH**

---

## Details

**Compiler**: `/home/xy/codeberg/ryelang/rye/zig-out/bin/zig`  
**Test File**: `src/grain_skate/block.ry`  
**Error**: Assertion failure in `Sema.zig:2625`

**Error Message**:
```
thread 921256 panic: reached unreachable code
/home/xy/.local/bin/zig-x86_64-linux-0.15.2/lib/std/debug.zig:559:14: 0x1854f59 in assert (std.zig)
    if (!ok) unreachable; // assertion failure
             ^
/home/xy/codeberg/ryelang/rye/src/Sema.zig:2625:11: 0x5c99045 in errMsg__anon_1211767 (main.zig)
    assert(src.offset != .unneeded);
          ^
/home/xy/codeberg/ryelang/rye/src/Sema.zig:2636:36: 0x55b6933 in fail__anon_790960 (main.zig)
    const err_msg = try sema.errMsg(src, format, args);
                                   ^
/home/xy/codeberg/ryelang/rye/src/Sema/rye_style.zig:276:26: 0x4a43bd3 in failWithConvertedError__anon_713855 (main.zig)
    const err = sema.fail(block, src, format, args);
                         ^
/home/xy/codeberg/ryelang/rye/src/Sema/rye_style.zig:325:43: 0x431cb27 in validateLineLength (main.zig)
```

---

## Root Cause

**Analysis**:
- Rye Style validation uses `LazySrcLoc.unneeded` for validation errors (as documented in Vantage 3's fix)
- `Sema.errMsg()` asserts that `src.offset != .unneeded` (line 2625)
- This creates a conflict: validation errors use `.unneeded`, but error reporting rejects it

**Code Location**:
- `src/Sema/rye_style.zig:276` - `failWithConvertedError` calls `sema.fail(block, src, ...)`
- `src/Sema/rye_style.zig:325` - `validateLineLength` calls `failWithConvertedError` with `LazySrcLoc.unneeded`
- `src/Sema.zig:2625` - `errMsg` asserts `src.offset != .unneeded`

---

## Expected Behavior

**Should Work**:
- Compiler should compile `.ry` files
- Rye Style validation errors should be reported without crashing
- Validation errors should use appropriate source locations

**Current Behavior**:
- Compiler crashes with assertion failure
- Cannot compile any `.ry` file that triggers Rye Style validation

---

## Proposed Fix

**Option 1**: Use a valid source location for validation errors
- Instead of `LazySrcLoc.unneeded`, use the function's source location
- Extract from `block.src()` or function AST node

**Option 2**: Modify `errMsg()` to allow `.unneeded` for validation errors
- Add a flag or separate function for validation errors
- Or make the assertion conditional

**Option 3**: Use a different error reporting path for validation
- Create `sema.failValidation()` that doesn't assert on `.unneeded`
- Or use a different error reporting mechanism

**Recommendation**: Option 1 - Use function source location for validation errors

---

## Test Case

**Command**:
```bash
cd /home/xy/grain-sketchbook
/home/xy/codeberg/ryelang/rye/zig-out/bin/zig build-lib src/grain_skate/block.ry
```

**Expected**: Should compile successfully or report validation errors without crashing  
**Actual**: Crashes with assertion failure

---

## Impact

**Blocks**:
- ❌ All compilation testing
- ❌ Phase 2 progress
- ❌ Integration validation

**Cannot Proceed Until**:
- ✅ Compiler handles validation errors without crashing
- ✅ Validation errors use valid source locations

---

## Additional Notes

**Simple Test File Also Fails**:
- Created `/tmp/test_ry.ry` with basic function
- Compiler reports syntax error (different issue, but shows `.ry` recognition works)
- Did not test with Rye Style validation

**Files Affected**:
- `src/Sema/rye_style.zig` - Validation error reporting
- `src/Sema.zig` - Error message assertion

---

**Status**: ⚠️ **BLOCKED** — Waiting for fix  
**Priority**: **HIGH** — Critical blocker  
**Date**: 2026-01-23-180610-pst
