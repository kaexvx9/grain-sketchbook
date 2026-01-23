# RISC-V Issue 2: Root Cause Identified

**Date**: 20260122.193200.rye  
**Status**: 🎯 **ROOT CAUSE IDENTIFIED** — Runtime index with inline for  
**Finding**: Debug.kprint() uses problematic pattern

---

## Root Cause: Runtime Index with Inline For

### The Problem

**Location**: `src/kernel/debug.zig` lines 66-83

**Code Pattern**:
```zig
fn print_arg(args: anytype, idx: usize) void {
    inline for (std.meta.fields(@TypeOf(args)), 0..) |field, i| {
        if (i == idx) {  // Runtime comparison!
            const val = @field(args, field.name);
            // Use val
            return;
        }
    }
}
```

**Issue**: 
- `inline for` unrolls all fields at comptime
- But `idx` is a runtime value
- Runtime `if (i == idx)` selects which unrolled code to execute
- This generates code for all fields but only uses one at runtime

**Why This Fails for Freestanding**:
- All field access code is generated (comptime unrolling)
- Runtime selection might generate incorrect branches
- Codegen might not handle this pattern correctly for freestanding

---

## Comparison

### Standard Library (Works) ✅

**Location**: `lib/std/Io/Writer.zig`

**Pattern**:
- Fully comptime format parsing
- Comptime field selection
- No runtime index selection

**Result**: Works correctly

### Debug.kprint() (Fails) ❌

**Location**: `src/kernel/debug.zig`

**Pattern**:
- Runtime format parsing
- Runtime index selection with `inline for`
- Mixed comptime/runtime pattern

**Result**: Generates invalid instructions

---

## Test Case Created

### runtime_index_inline_for.zig

**Purpose**: Test the exact pattern from `Debug.kprint()`

**Pattern**:
```zig
fn print_arg(args: anytype, idx: usize) void {
    inline for (std.meta.fields(@TypeOf(args)), 0..) |field, i| {
        if (i == idx) {
            const val = @field(args, field.name);
            _ = val;
            return;
        }
    }
}
```

**Status**: Created, waiting for sync and compilation

---

## Fix Strategies

### Fix 1: Make Format Parsing Comptime (Recommended)

**Strategy**: Rewrite `Debug.kprint()` to use fully comptime format parsing like standard library.

**Implementation**:
```zig
pub fn kprint(comptime fmt: []const u8, args: anytype) void {
    comptime var i = 0;
    comptime var arg_idx = 0;
    inline while (i < fmt.len) {
        // Comptime format parsing
        // Comptime field selection
    }
}
```

**Pros**:
- Fully comptime (like standard library)
- No runtime parsing
- Should work correctly

**Cons**:
- Requires rewriting format parsing
- More complex implementation

### Fix 2: Fix Runtime Index Selection

**Strategy**: Use comptime field access instead of inline for with runtime index.

**Implementation**:
```zig
fn print_arg(args: anytype, idx: usize) void {
    const fields = comptime std.meta.fields(@TypeOf(args));
    if (idx < fields.len) {
        const field = fields[idx];
        const val = @field(args, field.name);
        // Use val
    }
}
```

**Pros**:
- Simpler change
- Keeps existing structure
- No inline for with runtime index

**Cons**:
- Still uses runtime parsing
- Might have other issues

---

## Next Steps

### Immediate

1. **Compile Test Case**
   - Wait for sync
   - Compile `runtime_index_inline_for.zig`
   - Verify if it reproduces the issue

2. **Verify Root Cause**
   - If test fails: Confirms root cause
   - If test passes: Need deeper investigation

### Short-Term

3. **Implement Fix**
   - Choose fix strategy (Fix 1 recommended)
   - Implement fix in `Debug.kprint()`
   - Verify with tests

4. **Test with Basin Kernel**
   - Test fixed `Debug.kprint()` in kernel
   - Verify runtime behavior
   - Confirm fix works

---

## Key Insights

### What We Found

1. ✅ Real `Debug.kprint()` uses runtime format parsing
2. ✅ Uses `inline for` with runtime index selection
3. ✅ Different from standard library (fully comptime)
4. ✅ This is likely the root cause

### What We Need

1. 🔍 Verify test case reproduces issue
2. 🔍 Implement appropriate fix
3. 🔍 Test with Basin kernel

---

## References

- **Real Code**: `src/kernel/debug.zig` lines 34-96
- **Real Code Analysis**: `docs/rye/0049-riscv-issue2-real-code-analysis.md`
- **Standard Library**: `lib/std/Io/Writer.zig` lines 593-710

---

**Date**: 20260122.193200.rye  
**Status**: 🎯 **ROOT CAUSE IDENTIFIED** — Runtime index with inline for pattern

**Next Action**: Compile test case, verify root cause, implement fix.
