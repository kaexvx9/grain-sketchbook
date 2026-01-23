# RISC-V Issue 2: Code Analysis & Insights

**Date**: 20260122.190600.rye  
**Status**: 🔍 **ANALYSIS** — Deep code analysis for Issue 2  
**Findings**: Key insights from codebase analysis

---

## Code Analysis Findings

### 1. Comptime Evaluation Flow

**Location**: `src/Sema.zig` lines 7237-7261

**Key Insight**: The compiler does enter comptime scope for:
- `.compile_time` modifier calls
- Functions with comptime-only return types
- Generic function calls (when function value is known)

**Code Pattern**:
```zig
if (!block.isComptime()) {
    if (modifier == .compile_time) {
        block.comptime_reason = .{ .reason = .{
            .src = call_src,
            .r = .{ .simple = .comptime_call_modifier },
        } };
    } else if (!inline_requested and try Type.fromInterned(func_ty_info.return_type).comptimeOnlySema(pt)) {
        block.comptime_reason = .{ /* comptime-only return type */ };
    }
}
```

**Observation**: No special handling for freestanding targets. Comptime evaluation should work the same regardless of target.

---

### 2. Anytype Resolution

**Location**: `src/Sema.zig` lines 7317-7364

**Key Insight**: Anytype parameters ARE resolved at comptime before codegen:

```zig
// Evaluate the generic parameter type
const ty_ref = try sema.resolveInlineBody(&generic_block, body, param_inst_idx);
const param_ty = try sema.analyzeAsType(&generic_block, param_src, ty_ref);
```

**Observation**: Resolution happens in a comptime block (`generic_block`), so types should be fully resolved.

**Hypothesis**: The issue might be in how resolved types are passed to codegen, not in resolution itself.

---

### 3. Freestanding Target Handling

**Location**: `src/target.zig`, `src/Compilation.zig`

**Key Insight**: Freestanding targets are recognized but have minimal special handling:
- `target.os.tag == .freestanding` checks exist
- Used for linking decisions (no libc, etc.)
- No special comptime validation

**Observation**: No compiler-enforced restrictions on comptime evaluation for freestanding.

**Hypothesis**: The problem might be that format strings in standard library functions aren't being fully evaluated at comptime, or codegen is generating runtime format parsing.

---

### 4. Function Call Codegen

**Location**: `src/arch/riscv64/CodeGen.zig` lines 4794-4823

**Key Insight**: Codegen receives already-resolved types:

```zig
const arg_tys = try allocator.alloc(Type, arg_refs.len);
for (arg_tys, arg_refs) |*arg_ty, arg_ref| arg_ty.* = func.typeOf(arg_ref);
```

**Observation**: Types are resolved before reaching codegen. The issue might be in calling convention handling for resolved generic types.

---

## Root Cause Hypothesis

### Primary Hypothesis: Format String Runtime Parsing

**Problem**: Standard library format functions (`std.fmt.print`, etc.) may be generating runtime format parsing code for freestanding targets, even when format strings are comptime.

**Evidence**:
- Format strings are parsed in standard library (not compiler)
- Standard library might not fully unroll format parsing at comptime
- Freestanding targets lack runtime support for format parsing

**Fix Strategy**: Ensure format strings are fully evaluated and unrolled at comptime for freestanding targets.

---

### Secondary Hypothesis: Calling Convention for Resolved Generics

**Problem**: When anytype is resolved to a concrete type, the calling convention codegen might not handle it correctly for freestanding.

**Evidence**:
- Anytype resolution works (happens at comptime)
- Codegen receives resolved types
- But calling convention might assume runtime type information

**Fix Strategy**: Verify calling convention codegen handles resolved generic types correctly.

---

### Tertiary Hypothesis: Inline For with Runtime Slices

**Problem**: `inline for` might be incorrectly used with runtime slices, generating invalid loop code.

**Evidence**:
- `inline for` should only work with comptime slices
- But compiler might not enforce this for freestanding
- Runtime loops would fail in freestanding

**Fix Strategy**: Ensure `inline for` only works with comptime slices, error otherwise.

---

## Investigation Priority

### Priority 1: Format String Parsing

**Why**: Most likely cause based on symptoms (crashes in `Debug.kprint`)

**Action**:
1. Check standard library format string parsing
2. Verify comptime evaluation for freestanding
3. Test with minimal format string example

### Priority 2: Calling Convention

**Why**: Could explain anytype parameter issues

**Action**:
1. Trace anytype resolution through to codegen
2. Check calling convention codegen for resolved types
3. Compare with working targets

### Priority 3: Inline For Validation

**Why**: Less likely but still possible

**Action**:
1. Check inline for validation in Sema
2. Verify comptime slice requirement
3. Test with runtime slice (should error)

---

## Recommended Fix Approach

### Option 1: Compiler-Level Validation (Recommended)

**Strategy**: Add compiler checks to ensure format strings are fully comptime for freestanding.

**Implementation**:
```zig
// In Sema.zig, when analyzing function calls
if (target.os.tag == .freestanding) {
    // Check if format string is comptime
    // Error if runtime format parsing is attempted
}
```

**Pros**:
- Catches issues at compile time
- Clear error messages
- Prevents invalid codegen

**Cons**:
- Requires understanding format string evaluation
- Might need standard library changes

---

### Option 2: Standard Library Changes

**Strategy**: Modify standard library format functions to ensure full comptime evaluation for freestanding.

**Implementation**:
- Add `comptime` requirements for format strings
- Use `inline for` to unroll format parsing
- Ensure no runtime format parsing

**Pros**:
- Fixes root cause
- Works for all users
- No compiler changes needed

**Cons**:
- Requires standard library modifications
- Might break existing code

---

### Option 3: Codegen Fixes

**Strategy**: Fix codegen to handle resolved generic types correctly.

**Implementation**:
- Verify calling convention for resolved types
- Ensure no runtime type information needed
- Fix any codegen bugs

**Pros**:
- Fixes anytype issues
- Improves codegen quality

**Cons**:
- Might not fix format string issues
- Requires deep codegen understanding

---

## Next Steps

### Immediate (This Week)

1. **Test Compilation**:
   - Build Rye compiler
   - Compile test cases
   - Identify specific errors

2. **Format String Analysis**:
   - Check standard library format parsing
   - Verify comptime evaluation
   - Create minimal reproduction

### Short-Term (Next Week)

1. **Root Cause Confirmation**:
   - Identify exact issue location
   - Confirm hypothesis
   - Document findings

2. **Fix Design**:
   - Choose fix approach
   - Design implementation
   - Create fix plan

### Medium-Term (Week 3-4)

1. **Fix Implementation**:
   - Implement fix
   - Test fix
   - Verify with Basin kernel

---

## Key Code Locations Summary

| Component | Location | Purpose |
|-----------|----------|---------|
| **Comptime Evaluation** | `src/Sema.zig:7237-7261` | Enters comptime scope for calls |
| **Anytype Resolution** | `src/Sema.zig:7317-7364` | Resolves generic parameters |
| **Function Call Codegen** | `src/arch/riscv64/CodeGen.zig:4794-4823` | Generates call instructions |
| **Freestanding Checks** | `src/target.zig:12-17` | Freestanding target detection |
| **Format String Parsing** | Standard library | Format string evaluation |

---

## Success Criteria

### Issue 2 Complete When:

- ✅ Format strings fully evaluated at comptime for freestanding
- ✅ Anytype parameters resolved correctly before codegen
- ✅ Inline for only works with comptime slices
- ✅ No runtime format parsing for freestanding
- ✅ Test cases compile and run correctly
- ✅ Basin kernel works with format strings

---

## References

- **Investigation Plan**: `docs/rye/0033-riscv-issue2-investigation-plan.md`
- **Issue 2 Analysis**: `docs/rye/0027-riscv-anytype-comptime-fix-analysis.md`
- **Test Cases**: `test/cases/riscv64_freestanding/comptime_format_string.zig`
- **Test Cases**: `test/cases/riscv64_freestanding/anytype_resolution.zig`

---

**Date**: 20260122.190600.rye  
**Status**: 🔍 **ANALYSIS** — Code analysis complete, hypotheses formed

**Next Action**: Test compilation to confirm hypotheses
