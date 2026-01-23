# RISC-V Issue 2: Format String Analysis

**Date**: 20260122.192000.rye  
**Status**: ✅ **ANALYSIS** — Format string parsing is fully comptime  
**Finding**: Format strings are correctly evaluated at comptime, issue likely elsewhere

---

## Key Finding: Format Strings Are Fully Comptime

### Writer.print Implementation

**Location**: `lib/std/Io/Writer.zig` lines 593-710

**Key Code**:
```zig
pub fn print(w: *Writer, comptime fmt: []const u8, args: anytype) Error!void {
    // ...
    @setEvalBranchQuota(fmt.len * 1000);
    comptime var arg_state: std.fmt.ArgState = .{ .args_len = fields_info.len };
    comptime var i = 0;
    comptime var literal: []const u8 = "";
    inline while (true) {
        // ...
        inline while (i < fmt.len) : (i += 1) {
            switch (fmt[i]) {
                '{', '}' => break,
                else => {},
            }
        }
        // ...
        const placeholder = comptime std.fmt.Placeholder.parse(&placeholder_array);
        const arg_pos = comptime switch (placeholder.arg) {
            // ...
        };
        // ...
    }
}
```

**Observations**:
1. ✅ Format string is `comptime` parameter
2. ✅ Uses `inline while` loops (comptime unrolling)
3. ✅ Uses `comptime var` for state
4. ✅ Placeholder parsing is `comptime`
5. ✅ Argument position resolution is `comptime`

**Conclusion**: Format string parsing is **fully evaluated at comptime**. No runtime parsing occurs.

---

## Placeholder.parse Implementation

**Location**: `lib/std/fmt.zig` lines 97-150

**Key Code**:
```zig
pub fn parse(comptime bytes: []const u8) Placeholder {
    var parser: Parser = .{ .bytes = bytes, .i = 0 };
    const arg = parser.specifier() catch |err| @compileError(@errorName(err));
    // ... all parsing happens at comptime
}
```

**Observations**:
1. ✅ Takes `comptime` bytes parameter
2. ✅ Uses `@compileError` for errors (comptime-only)
3. ✅ All parsing logic is comptime-evaluated

**Conclusion**: Placeholder parsing is **fully comptime**.

---

## Runtime Code Generation

### What Happens at Runtime

**Location**: `lib/std/Io/Writer.zig` lines 638-710

**Runtime Operations**:
1. `try w.writeAll(literal)` - Writes literal strings
2. `try w.printValue(...)` - Prints formatted values
3. Width/precision calculations (if not comptime)

**Key Insight**: The format string is parsed at comptime, but the actual **printing** happens at runtime. This is correct behavior.

---

## Issue 2 Hypothesis Revision

### Original Hypothesis (REJECTED)

**Hypothesis**: Format strings are not fully evaluated at comptime, causing runtime parsing.

**Status**: ❌ **REJECTED** - Format strings ARE fully evaluated at comptime.

### Revised Hypothesis

**Hypothesis 1**: Runtime printing operations (`w.writeAll`, `w.printValue`) may generate incorrect code for freestanding.

**Evidence**:
- Format parsing is comptime (correct)
- But printing happens at runtime
- Runtime printing might use unsupported operations for freestanding

**Hypothesis 2**: `anytype` resolution works, but codegen for resolved types is incorrect.

**Evidence**:
- Anytype resolution happens at comptime (correct)
- But codegen might not handle resolved types correctly

**Hypothesis 3**: Format string arguments (`args: anytype`) might not be correctly resolved.

**Evidence**:
- Format string itself is comptime
- But arguments are `anytype` and need resolution
- Resolution might be incomplete or incorrect

---

## Anytype Resolution Analysis

### Resolution Flow

**Location**: `src/Sema.zig` lines 7317-7364

**Key Code**:
```zig
// Evaluate the generic parameter type
const ty_ref = try sema.resolveInlineBody(&generic_block, body, param_inst_idx);
const param_ty = try sema.analyzeAsType(&generic_block, param_src, ty_ref);
```

**Observations**:
1. ✅ Resolution happens in `generic_block` (comptime block)
2. ✅ Uses `resolveInlineBody` (comptime evaluation)
3. ✅ Uses `analyzeAsType` (type analysis)
4. ✅ Happens before codegen

**Conclusion**: Anytype resolution is **fully comptime** and happens before codegen.

---

## Revised Investigation Focus

### Priority 1: Runtime Printing Operations

**Question**: Do runtime printing operations (`w.writeAll`, `w.printValue`) generate correct code for freestanding?

**Check**:
- `Writer.writeAll` implementation
- `Writer.printValue` implementation
- Check for unsupported operations (allocations, syscalls, etc.)

**Action**: Trace runtime printing codegen for freestanding.

### Priority 2: Codegen for Resolved Types

**Question**: Does codegen correctly handle resolved `anytype` parameters?

**Check**:
- Function call codegen with resolved types
- Calling convention for resolved generics
- Parameter passing for resolved types

**Action**: Trace anytype resolution through to codegen.

### Priority 3: Format Argument Resolution

**Question**: Are format string arguments (`args: anytype`) correctly resolved?

**Check**:
- Argument type resolution in `Writer.print`
- Argument passing to `printValue`
- Type handling for format arguments

**Action**: Verify argument resolution and passing.

---

## Key Insights

### What Works (Comptime)

1. ✅ Format string parsing - Fully comptime
2. ✅ Placeholder parsing - Fully comptime
3. ✅ Anytype parameter resolution - Fully comptime
4. ✅ Argument position resolution - Fully comptime

### What Might Be Wrong (Runtime)

1. ⚠️ Runtime printing operations (`writeAll`, `printValue`)
2. ⚠️ Codegen for resolved types
3. ⚠️ Argument passing to printing functions

---

## Next Steps

### Immediate

1. **Trace Runtime Printing**
   - Check `Writer.writeAll` codegen
   - Check `Writer.printValue` codegen
   - Verify no unsupported operations

2. **Trace Codegen for Resolved Types**
   - Check function call codegen
   - Verify calling convention
   - Check parameter passing

3. **Test with Minimal Example**
   - Create minimal format string test
   - Verify compilation and codegen
   - Check generated code

---

## References

- **Writer.print**: `lib/std/Io/Writer.zig` lines 593-710
- **Placeholder.parse**: `lib/std/fmt.zig` lines 97-150
- **Anytype Resolution**: `src/Sema.zig` lines 7317-7364

---

**Date**: 20260122.192000.rye  
**Status**: ✅ **ANALYSIS** — Format strings are comptime, issue likely in runtime codegen

**Next Action**: Trace runtime printing operations and codegen for resolved types.
