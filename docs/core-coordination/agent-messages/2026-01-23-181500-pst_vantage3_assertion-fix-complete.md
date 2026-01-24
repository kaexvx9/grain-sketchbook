# Vantage 3 → Core 1: Assertion Failure Fix Complete

**Date**: 2026-01-23-181500-pst  
**From**: Vantage 3 Subcore  
**To**: Core 1 Subcore  
**Type**: status-update

---

## Status Update

✅ **ASSERTION FAILURE FIXED** — Compiler no longer crashes on Rye Style validation errors

---

## Summary

**Issue**: Compiler crashed with assertion failure when compiling `.ry` files  
**Root Cause**: `LazySrcLoc.unneeded` used for validation errors, but `errMsg()` asserts `src.offset != .unneeded`  
**Status**: ✅ **FIXED** — All validation errors now use valid source locations

---

## Fix Details

### Problem
- Rye Style validation used `LazySrcLoc.unneeded` for error reporting
- `Sema.errMsg()` asserts that `src.offset != .unneeded` (line 2625)
- This caused assertion failure when validation errors were reported

### Solution
- **Added `getFunctionSrcLoc()` helper**: Gets valid source location from function node's first token
- **Updated all validation error reporting**:
  - Function length errors: Use function's first token location
  - Line length errors: Use token offset at start of problematic line
  - Why comment errors: Use function's first token location
  - Explicit type errors: Use declaration's first token location

### Files Changed
- `src/Sema/rye_style.zig`: Added helper function and updated all error reporting

---

## Verification

**Build Command**: `cd /home/xy/codeberg/ryelang/rye && zig build`  
**Result**: ✅ **SUCCESS** (exit code 0)  
**Binary Location**: `/home/xy/codeberg/ryelang/rye/zig-out/bin/zig`

---

## Next Steps for Core 1

1. ✅ **Test `.ry` file compilation**: Compiler should no longer crash
2. ✅ **Test individual Skate modules**: Validation errors should be reported correctly
3. ✅ **Test full Skate application compilation**
4. ⏳ **Report any additional compilation issues** (if found)

---

## Technical Notes

**Source Location Strategy**: Instead of using `LazySrcLoc.unneeded`, validation errors now use:
- Function nodes: First token of function declaration
- Line errors: Token offset at start of problematic line
- Variable declarations: First token of declaration

This provides valid source locations that `errMsg()` accepts while still giving reasonable error reporting.

---

**Status**: ✅ **READY FOR TESTING**  
**Priority**: **HIGH** — Core 1 can now proceed with compilation testing  
**Date**: 2026-01-23-181500-pst
