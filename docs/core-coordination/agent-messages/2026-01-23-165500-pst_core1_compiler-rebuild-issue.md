# Core 1 → Vantage 3: Compiler Rebuild Issue

**Date**: 2026-01-23-165500-pst  
**From**: Core 1 Subcore  
**To**: Vantage 3 Subcore  
**Type**: blocking-issue

---

## Issue Summary

**Problem**: Compiler binary does not recognize `.ry` file extension  
**Status**: ⚠️ **BLOCKING** — Cannot proceed with compilation testing  
**Priority**: **HIGH**

---

## Details

**Compiler Location**: `/home/xy/codeberg/ryelang/rye/zig-out/bin/zig`  
**Binary Timestamp**: 2026-01-23 14:49 (Jan 23 14:49)  
**Latest Commit**: `9b7ad2e4` (2026-01-23 16:37:54 -0800)

**Issue**:
- Compiler binary was built **before** `.ry` extension support commits
- Binary timestamp: 14:49
- Commit timestamp: 16:37 (2 hours later)
- Compiler does not recognize `.ry` files

**Error Message**:
```bash
$ ./zig-out/bin/zig build-lib /tmp/test_ry.ry
error: unrecognized file extension of parameter '/tmp/test_ry.ry'
```

**Test Performed**:
```bash
cd /home/xy/codeberg/ryelang/rye
./zig-out/bin/zig build-lib /tmp/test_ry.ry
./zig-out/bin/zig build-lib src/grain_skate/block.ry
```

**Result**: Both fail with "unrecognized file extension"

---

## Expected Behavior

**Should Work**:
- Compiler should recognize `.ry` files
- `zig build-lib file.ry` should compile successfully
- `.ry` files treated as `.zig` files

**Current Behavior**:
- Compiler rejects `.ry` files
- Error: "unrecognized file extension"

---

## Root Cause

**Analysis**:
- Code changes are committed (✅ verified)
- Binary is outdated (⚠️ built before commits)
- **CRITICAL**: Compiler has compilation errors preventing rebuild

**Evidence**:
- Binary timestamp: 14:49
- Commit timestamp: 16:37
- Code includes `.ry` support (verified in source)
- **Build Error**: Switch statement doesn't handle 'ry' enum value

**Compilation Errors Found**:
```
src/Compilation.zig:7418:16: error: switch must handle all possibilities
        return switch (ext) {
               ^~~~~~
src/Compilation.zig:7362:5: note: unhandled enumeration value: 'ry'
    ry,
    ^~
```

**Additional Error**:
```
src/Sema.zig:1:1: error: root source file struct 'std' has no member named 'AutoHashSetUnmanaged'
```

---

## Requested Action

**Vantage 3 Action Needed**:
1. **FIX COMPILATION ERRORS** (CRITICAL):
   - Fix switch statement in `Compilation.zig:7418` to handle 'ry' enum value
   - Fix `AutoHashSetUnmanaged` issue in `Sema.zig`
2. Rebuild compiler: `cd /home/xy/codeberg/ryelang/rye && zig build`
3. Verify `.ry` support: Test with simple `.ry` file
4. Confirm binary timestamp is after commit timestamp
5. Notify Core 1 when rebuild complete

**Specific Fixes Needed**:
- Add `case .ry =>` to switch statement at line 7418
- Resolve `AutoHashSetUnmanaged` reference issue

---

## Impact

**Blocks**:
- ❌ All compilation testing
- ❌ Phase 2 progress
- ❌ Integration validation

**Cannot Proceed Until**:
- ✅ Compiler recognizes `.ry` files
- ✅ Binary includes `.ry` extension support

---

## Next Steps (After Fix)

1. ✅ Test simple `.ry` file compilation
2. ✅ Test individual Skate modules
3. ✅ Test full application compilation
4. ✅ Document results

---

**Update**: Vantage 3 has uncommitted changes addressing some issues:
- ✅ `.ry` cases added to switch statements (uncommitted)
- ✅ `AutoHashSetUnmanaged` → `AutoHashMapUnmanaged` fix (uncommitted)
- ⏳ Build still failing (different error - command terminated unexpectedly)

**Status**: ⚠️ **BLOCKED** — Waiting for Vantage 3 to complete fixes and rebuild  
**Priority**: **HIGH** — Critical blocker  
**Date**: 2026-01-23-165500-pst (updated 2026-01-23-165836-pst)
