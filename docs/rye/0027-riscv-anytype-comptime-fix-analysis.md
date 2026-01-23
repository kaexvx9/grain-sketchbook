# RISC-V Anytype/Comptime Fix: Analysis

**Date**: 20260122.185000.rye  
**Status**: 🔍 **ANALYSIS** — Issue 2: Function Calls with anytype/comptime causing crashes  
**Complexity**: HIGH — Requires comptime evaluation system changes

---

## Problem Summary

Functions with `anytype` parameters or comptime string formatting crash or hang.  
Affects: `Debug.kassert()`, `Debug.kprint()`, functions using `inline for` over runtime slices.

---

## Root Cause Analysis

**Issue**: Comptime codegen for `anytype` and format strings generates invalid RISC-V instructions for freestanding target.

**Specific Problems**:
1. **Comptime Format Strings**: Format parsing generates code that assumes runtime support
2. **Anytype Parameters**: `anytype` parameter handling generates incorrect calling convention code
3. **Inline For**: `inline for` over runtime slices generates invalid loop code

**Location**: This issue spans multiple compiler phases:
- **Semantic Analysis** (`src/Sema.zig`): Comptime evaluation and type resolution
- **Code Generation** (`src/arch/riscv64/CodeGen.zig`): Runtime codegen for comptime operations
- **Format String Parsing** (`src/fmt.zig`): Comptime format string handling

---

## Investigation Needed

### 1. Comptime Format Strings

**Question**: Are format strings being fully evaluated at comptime for freestanding targets?

**Check**:
- `src/fmt.zig` - Format string parsing
- `src/Sema.zig` - Comptime evaluation of format strings
- Ensure all format parsing happens at comptime, not runtime

### 2. Anytype Parameter Handling

**Question**: Are `anytype` parameters being properly resolved before codegen?

**Check**:
- `src/Sema.zig` - Generic parameter resolution (lines 7317-7356)
- `src/arch/riscv64/CodeGen.zig` - Function call codegen (lines 4826-4950)
- Ensure `anytype` is resolved to concrete types before codegen

### 3. Inline For Over Runtime Slices

**Question**: Is `inline for` properly unrolling at comptime?

**Check**:
- `src/Sema.zig` - For loop analysis (lines 4503-4542)
- Ensure `inline for` only works with comptime-known lengths
- Runtime slices should not use `inline for`

---

## Potential Fixes

### Fix 1: Ensure Comptime Evaluation for Freestanding

**Strategy**: Add checks in semantic analysis to ensure format strings are fully comptime for freestanding targets.

**Location**: `src/Sema.zig` - Format string evaluation

**Implementation**:
```zig
// In format string evaluation
if (target.os.tag == .freestanding) {
    // Ensure all format parsing is comptime
    // Error if runtime format parsing is attempted
}
```

### Fix 2: Resolve Anytype Before Codegen

**Strategy**: Ensure all `anytype` parameters are resolved to concrete types before codegen.

**Location**: `src/Sema.zig` - Generic parameter resolution

**Implementation**:
```zig
// In function call analysis
if (target.os.tag == .freestanding) {
    // Ensure all anytype parameters are resolved
    // Error if anytype remains unresolved
}
```

### Fix 3: Restrict Inline For to Comptime

**Strategy**: Ensure `inline for` only works with comptime-known lengths.

**Location**: `src/Sema.zig` - For loop analysis

**Implementation**:
```zig
// In for loop analysis
if (is_inline and target.os.tag == .freestanding) {
    // Ensure loop length is comptime-known
    // Error if runtime length is used with inline for
}
```

---

## Test Cases

```rye
// test/riscv64_comptime_format.ry
/// Why: Test comptime format string evaluation for freestanding.
pub fn test_comptime_print(comptime msg: []const u8) void {
    // Should work in freestanding - fully comptime
    print_comptime(msg);
}

// test/riscv64_anytype.ry
/// Why: Test anytype parameter resolution for freestanding.
pub fn test_anytype(val: anytype) void {
    // Should generate correct code for freestanding
    // anytype should be resolved to concrete type
    _ = val;
}

// test/riscv64_inline_for.ry
/// Why: Test inline for with comptime slices.
pub fn test_inline_for_comptime(comptime slice: []const u8) void {
    // Should unroll at comptime
    inline for (slice) |c| {
        putc(c);
    }
}
```

---

## Implementation Priority

**Status**: 🔍 **NEEDS DEEPER INVESTIGATION**

This issue requires:
1. Understanding comptime evaluation system
2. Tracing format string parsing through compiler phases
3. Verifying anytype resolution before codegen
4. Testing inline for unrolling behavior

**Recommendation**: 
- Document issue thoroughly
- Create test cases to reproduce
- Investigate comptime evaluation system
- Fix after understanding root cause

---

## References

- **Issue Document**: `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md`
- **Fix Strategy**: `docs/rye/0013-riscv-freestanding-fix-strategy.md`
- **Sema.zig**: Generic parameter resolution
- **CodeGen.zig**: Function call codegen

---

**Date**: 20260122.185000.rye  
**Status**: 🔍 **ANALYSIS** — Requires deeper investigation of comptime evaluation system
