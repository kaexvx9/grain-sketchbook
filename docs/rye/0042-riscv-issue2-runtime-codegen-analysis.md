# RISC-V Issue 2: Runtime Codegen Analysis

**Date**: 20260122.192200.rye  
**Status**: 🔍 **ANALYSIS** — Runtime codegen investigation  
**Focus**: Function calls, Writer operations, vtable dispatch

---

## Writer.writeAll Analysis

### Implementation

**Location**: `lib/std/Io/Writer.zig` lines 530-533

**Code**:
```zig
pub fn writeAll(w: *Writer, bytes: []const u8) Error!void {
    var index: usize = 0;
    while (index < bytes.len) index += try w.write(bytes[index..]);
}
```

**Observations**:
1. ✅ Simple loop with `w.write()`
2. ✅ No allocations
3. ✅ No syscalls directly
4. ⚠️ Calls `w.write()` which may call `vtable.drain`

### Writer.write Implementation

**Location**: `lib/std/Io/Writer.zig` lines 518-526

**Code**:
```zig
pub fn write(w: *Writer, bytes: []const u8) Error!usize {
    if (w.end + bytes.len <= w.buffer.len) {
        @branchHint(.likely);
        @memcpy(w.buffer[w.end..][0..bytes.len], bytes);
        w.end += bytes.len;
        return bytes.len;
    }
    return w.vtable.drain(w, &.{bytes}, 1);
}
```

**Observations**:
1. ✅ Uses `@memcpy` (comptime-known, should work)
2. ✅ Buffer management (simple pointer arithmetic)
3. ⚠️ Calls `vtable.drain` (function pointer) when buffer full

**Potential Issue**: Function pointer calls via vtable might not work correctly in freestanding.

---

## Function Call Codegen

### genCall Implementation

**Location**: `src/arch/riscv64/CodeGen.zig` lines 4842-5013

**Key Code**:
```zig
fn genCall(
    func: *Func,
    info: union(enum) {
        air: Air.Inst.Ref,
        lib: struct { ... },
    },
    arg_tys: []const Type,
    arg_vals: []const MCValue,
) !MCValue {
    // ...
    const arg_tys = try allocator.alloc(Type, arg_refs.len);
    for (arg_tys, arg_refs) |*arg_ty, arg_ref| arg_ty.* = func.typeOf(arg_ref);
    
    const call_ret = try func.genCall(.{ .air = callee }, arg_tys, arg_vals);
    // ...
}
```

**Observations**:
1. ✅ Types are resolved before codegen (`func.typeOf(arg_ref)`)
2. ✅ Uses stack allocator (no heap allocation)
3. ✅ Passes resolved types to `genCall`

**Key Insight**: Types are already resolved when reaching codegen. The issue might be in how function pointers are called.

---

## VTable Dispatch Analysis

### Writer VTable Structure

**Location**: `lib/std/Io/Writer.zig` lines 18-87

**Key Code**:
```zig
pub const VTable = struct {
    drain: *const fn (w: *Writer, data: []const []const u8, splat: usize) Error!usize,
    sendFile: *const fn (...) FileError!usize = unimplementedSendFile,
    flush: *const fn (w: *Writer) Error!void = defaultFlush,
    rebase: *const fn (w: *Writer, preserve: usize, capacity: usize) Error!void = defaultRebase,
};
```

**Observations**:
1. ⚠️ Function pointers in vtable
2. ⚠️ VTable dispatch requires indirect calls
3. ⚠️ Indirect calls might not work correctly in freestanding

**Potential Issue**: Indirect function calls (via function pointers) might generate incorrect code for freestanding.

---

## Hypothesis: Indirect Function Calls

### Primary Hypothesis

**Problem**: Indirect function calls (function pointers, vtable dispatch) generate incorrect code for freestanding targets.

**Evidence**:
1. Format strings are comptime (correct)
2. Anytype resolution is comptime (correct)
3. But runtime operations use vtable dispatch (function pointers)
4. Function pointer calls might not work correctly

**Symptoms Match**:
- `Debug.kprint()` uses `Writer.print()` → `writeAll()` → `vtable.drain()`
- `Debug.kassert()` might use similar patterns
- Invalid instructions could be from incorrect function pointer calls

### Secondary Hypothesis

**Problem**: Function call codegen for resolved anytype parameters might be incorrect.

**Evidence**:
1. Types are resolved before codegen
2. But calling convention might not handle resolved generics correctly
3. Parameter passing might be incorrect

---

## Investigation Areas

### 1. Indirect Function Call Codegen

**Location**: `src/arch/riscv64/CodeGen.zig` function call handling

**Questions**:
- How are function pointers called?
- Is calling convention correct for indirect calls?
- Are function pointer loads correct?

**Action**: Trace function pointer call codegen.

### 2. VTable Dispatch Codegen

**Questions**:
- How is vtable.drain called?
- Is the function pointer correctly loaded?
- Is the call correctly generated?

**Action**: Trace vtable dispatch codegen.

### 3. Resolved Type Parameter Passing

**Questions**:
- Are resolved anytype parameters passed correctly?
- Is calling convention correct?
- Are parameter types correctly handled?

**Action**: Trace parameter passing for resolved types.

---

## Test Strategy

### Minimal Test Case

**Goal**: Test indirect function calls in freestanding

**Test Structure**:
```zig
// Test indirect function call
fn indirect_call(fn_ptr: *const fn (u32) u32, val: u32) u32 {
    return fn_ptr(val);
}

fn add_one(x: u32) u32 {
    return x + 1;
}

pub fn test_indirect() void {
    const result = indirect_call(add_one, 42);
    _ = result;
}
```

**Verification**:
- Compiles successfully
- Generates correct indirect call code
- No invalid instructions

### VTable Test Case

**Goal**: Test vtable dispatch in freestanding

**Test Structure**:
```zig
// Minimal vtable-like structure
const VTable = struct {
    call: *const fn (*const u8) void,
};

fn test_vtable(vtable: *const VTable, data: *const u8) void {
    vtable.call(data);
}
```

**Verification**:
- Compiles successfully
- Generates correct vtable dispatch
- No invalid instructions

---

## Next Steps

### Immediate

1. **Create Indirect Call Test**
   - Test function pointer calls
   - Verify codegen
   - Check for issues

2. **Create VTable Test**
   - Test vtable dispatch
   - Verify codegen
   - Check for issues

3. **Trace Function Pointer Codegen**
   - Find where function pointers are called
   - Verify calling convention
   - Check for freestanding-specific issues

### Short-Term

4. **Compare with Working Targets**
   - Compare function pointer codegen
   - Identify differences
   - Find freestanding-specific issues

5. **Fix Function Pointer Codegen**
   - Implement fix
   - Verify with tests
   - Test with Basin kernel

---

## Key Insights

### What We Know

1. ✅ Format strings are fully comptime
2. ✅ Anytype resolution is fully comptime
3. ✅ Types are resolved before codegen
4. ⚠️ Runtime operations use function pointers (vtable)
5. ⚠️ Indirect calls might be the issue

### What We Need to Verify

1. 🔍 Function pointer call codegen
2. 🔍 VTable dispatch codegen
3. 🔍 Calling convention for indirect calls
4. 🔍 Parameter passing for resolved types

---

## References

- **Writer.writeAll**: `lib/std/Io/Writer.zig` lines 530-533
- **Writer.write**: `lib/std/Io/Writer.zig` lines 518-526
- **Writer VTable**: `lib/std/Io/Writer.zig` lines 18-87
- **genCall**: `src/arch/riscv64/CodeGen.zig` lines 4842-5013

---

**Date**: 20260122.192200.rye  
**Status**: 🔍 **ANALYSIS** — Focus on indirect function calls and vtable dispatch

**Next Action**: Create test cases for indirect calls and vtable dispatch, trace codegen.
