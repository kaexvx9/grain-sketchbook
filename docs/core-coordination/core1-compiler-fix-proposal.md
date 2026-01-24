# Core 1: Compiler Fix Proposal

**Date**: 2026-01-23-165603-pst  
**Issue**: Compiler compilation errors preventing rebuild  
**Status**: 🔧 **FIX PROPOSAL**

---

## Problem

Compiler fails to build due to switch statements not handling `.ry` enum value.

**Errors**:
1. `Compilation.zig:7418` - `clangSupportsDepFile()` switch missing `.ry` case
2. `Compilation.zig:7438` - `canonicalName()` switch missing `.ry` case  
3. `Compilation.zig:7370` - `clangNeedsLanguageOverride()` switch missing `.ry` case
4. `Compilation.zig:7399` - `clangSupportsDiagnostics()` switch missing `.ry` case
5. `Sema.zig` - `AutoHashSetUnmanaged` reference issue

---

## Proposed Fixes

### Fix 1: `clangSupportsDepFile()` (line 7418)

**Current**:
```zig
pub fn clangSupportsDepFile(ext: FileExt) bool {
    return switch (ext) {
        .assembly_with_cpp, .c, .cpp, .h, .hpp, .hm, .hmm, .m, .mm => true,
        .ll, .bc, .assembly, .shared_library, .object, .static_library, .zig, .def, .rc, .res, .manifest, .unknown => false,
    };
}
```

**Fix**: Add `.ry` to the false case (same as `.zig`):
```zig
.ll, .bc, .assembly, .shared_library, .object, .static_library, .zig, .ry, .def, .rc, .res, .manifest, .unknown => false,
```

### Fix 2: `canonicalName()` (line 7438)

**Current**: Switch doesn't include `.ry`

**Fix**: Add `.ry => ".ry",` case (same as `.zig => ".zig",`)

### Fix 3: `clangNeedsLanguageOverride()` (line 7370)

**Current**: Switch doesn't include `.ry`

**Fix**: Add `.ry` to the false case (same as `.zig`):
```zig
.zig, .ry, .def, .rc, .res, .manifest, .unknown, => false,
```

### Fix 4: `clangSupportsDiagnostics()` (line 7399)

**Current**: Switch doesn't include `.ry`

**Fix**: Add `.ry` to the false case (same as `.zig`):
```zig
.zig, .ry, .def, .rc, .res, .manifest, .unknown, => false,
```

### Fix 5: `AutoHashSetUnmanaged` (Sema.zig)

**Issue**: Reference to non-existent type  
**Fix**: Check if this is a Zig version compatibility issue or typo

---

## Rationale

Since `.ry` files are treated identically to `.zig` files (same parsing, same semantics), all switch statements should handle `.ry` the same way as `.zig`.

---

## Testing After Fix

1. Rebuild compiler: `cd /home/xy/codeberg/ryelang/rye && zig build`
2. Verify build succeeds
3. Test `.ry` file recognition: `./zig-out/bin/zig build-lib test.ry`
4. Notify Core 1 when ready

---

**Status**: 🔧 **PROPOSAL** — Awaiting Vantage 3 implementation  
**Priority**: **HIGH** — Blocks compilation testing  
**Date**: 2026-01-23-165603-pst
