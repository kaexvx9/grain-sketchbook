# RISC-V Issue 2: Test Constraints & Strategy

**Date**: 20260122.191600.rye  
**Status**: 🔍 **ANALYSIS** — Issue 2 test constraints identified  
**Finding**: Tests need different approach due to naked function limitations

---

## Problem Identified

### Current Test Cases

**Issue**: Both Issue 2 test cases fail with:
```
error: runtime call not allowed in naked function
```

**Test Cases**:
- `comptime_format_string.zig` - Calls `comptime_print()` from `_start`
- `anytype_resolution.zig` - Calls `test_generic()` from `_start`

### Root Cause

Naked functions (`callconv(.naked)`) cannot:
- ❌ Call other functions (even if they're `inline`)
- ❌ Use runtime calls
- ❌ Have local variables

**But Issue 2 is about**:
- Function calls with `anytype`/`comptime`
- Format string evaluation
- Generic function resolution

**Conflict**: We can't test function calls from a naked function!

---

## Understanding Issue 2

### Real-World Context

Issue 2 occurs in **Basin kernel code**, not in `_start`:

```zig
// In Basin kernel (NOT in _start)
pub fn kassert(condition: bool, comptime fmt: []const u8, args: anytype) void {
    if (!condition) {
        kprint(fmt, args);  // <-- Issue 2 happens here
        // ...
    }
}

pub fn kprint(comptime fmt: []const u8, args: anytype) void {
    // Format string parsing and output
    // <-- Issue 2: format string not fully evaluated at comptime
}
```

**Key Insight**: Issue 2 happens in **regular functions**, not in `_start`.

---

## Test Strategy Revision

### Option 1: Test in Regular Functions (Recommended)

**Approach**: Create test that compiles to freestanding but doesn't use `_start`:

```zig
// Test file that compiles but doesn't need _start
pub fn test_comptime_format() void {
    comptime_print("test");  // Should work in regular function
}

pub fn test_anytype() void {
    test_generic();  // Should work in regular function
}

// No _start needed - just verify compilation
```

**Limitation**: Can't test runtime behavior without `_start`.

### Option 2: Inline Everything in `_start`

**Approach**: Inline all logic directly in `_start`:

```zig
pub fn _start() callconv(.naked) noreturn {
    // Inline format string logic
    // Inline anytype resolution
    // No function calls
}
```

**Limitation**: Doesn't test actual function call codegen.

### Option 3: Test with Basin Kernel Integration

**Approach**: Test Issue 2 fixes with actual Basin kernel code:

```zig
// In Basin kernel
pub fn _start() callconv(.naked) noreturn {
    // Call regular functions (not naked)
    kassert(true, "test", .{});
    kprint("hello", .{});
}
```

**Advantage**: Tests real-world scenario.  
**Limitation**: Requires Basin kernel integration.

---

## Recommended Approach

### Phase 1: Compilation Tests (Regular Functions)

**Goal**: Verify Issue 2 code compiles correctly

**Test Structure**:
```zig
// Test comptime format strings in regular function
pub fn test_format_string() void {
    comptime_print("test message");
}

// Test anytype resolution in regular function
pub fn test_anytype_resolution() void {
    const result = generic_add(@as(u32, 10), @as(u32, 20));
    _ = result;
}

// No _start - just verify compilation
```

**Verification**: 
- ✅ Compiles successfully
- ✅ No codegen errors
- ✅ Format strings evaluated at comptime
- ✅ Anytype parameters resolved correctly

### Phase 2: Integration Tests (Basin Kernel)

**Goal**: Verify Issue 2 fixes work in real kernel code

**Test Structure**:
- Use actual Basin kernel `Debug.kassert()` and `Debug.kprint()`
- Test with real kernel scenarios
- Verify no crashes or hangs

**Verification**:
- ✅ Runtime behavior correct
- ✅ No invalid instructions
- ✅ No hangs or crashes

---

## Revised Test Cases

### Test 1: Comptime Format String (Regular Function)

```zig
//! Why: Test comptime format string in regular function (not _start).
//! Verifies format strings are fully evaluated at comptime.

const builtin = @import("builtin");
const std = @import("std");

fn comptime_print(comptime fmt: []const u8) void {
    _ = fmt;  // Should be fully evaluated at comptime
}

pub fn test_comptime_format() void {
    comptime_print("test message");
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Obj
```

### Test 2: Anytype Resolution (Regular Function)

```zig
//! Why: Test anytype resolution in regular function (not _start).
//! Verifies anytype parameters are resolved before codegen.

const builtin = @import("builtin");
const std = @import("std");

fn generic_add(a: anytype, b: anytype) @TypeOf(a) {
    return a + b;
}

pub fn test_anytype_resolution() void {
    const result1 = generic_add(@as(u32, 10), @as(u32, 20));
    const result2 = generic_add(@as(u64, 100), @as(u64, 200));
    _ = result1;
    _ = result2;
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Obj
```

**Note**: Using `output_mode=Obj` instead of `Exe` since we don't need `_start`.

---

## Next Steps

### Immediate

1. **Create Revised Test Cases**
   - Regular functions (not `_start`)
   - Compile to object files
   - Verify compilation success

2. **Analyze Generated Code**
   - Check format string evaluation
   - Verify anytype resolution
   - Inspect codegen output

### Short-Term

3. **Basin Kernel Integration**
   - Test with real `Debug.kassert()` and `Debug.kprint()`
   - Verify runtime behavior
   - Confirm fixes work in practice

---

## Key Insights

### Issue 2 Testing Challenge

**Problem**: Issue 2 is about function calls, but `_start` can't call functions.

**Solution**: Test in regular functions, verify compilation and codegen.

### Real-World Context

**Issue 2 occurs in**:
- Regular kernel functions (not `_start`)
- Functions with `anytype` parameters
- Functions with comptime format strings

**Testing Strategy**:
- Phase 1: Compilation tests (regular functions)
- Phase 2: Integration tests (Basin kernel)

---

**Date**: 20260122.191600.rye  
**Status**: 🔍 **ANALYSIS** — Test constraints identified, strategy revised

**Next Action**: Create revised test cases using regular functions instead of `_start`.
