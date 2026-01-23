# RISC-V Issue 2: Investigation Summary

**Date**: 20260122.192300.rye  
**Status**: 🔍 **INVESTIGATION** — Hypothesis identified, test cases created  
**Progress**: Format/anytype confirmed comptime, indirect calls hypothesis

---

## Investigation Overview

### Problem Statement

Functions with `anytype` parameters or comptime string formatting crash or hang.  
Affects: `Debug.kassert()`, `Debug.kprint()`, functions using `inline for` over runtime slices.

**Symptoms**:
- `Debug.kassert(condition, "message", .{})` - hangs even when condition is true
- `Debug.kprint("text", .{})` - generates invalid instructions
- Invalid instruction errors at runtime

---

## Investigation Phases

### Phase 1: Format String Analysis ✅

**Question**: Are format strings fully evaluated at comptime?

**Finding**: ✅ **YES** - Format strings are fully comptime
- `Writer.print` uses `inline while` loops (comptime unrolling)
- Placeholder parsing is `comptime`
- No runtime format parsing occurs

**Conclusion**: Format string parsing is NOT the issue.

**Documentation**: `docs/rye/0041-riscv-issue2-format-string-analysis.md`

---

### Phase 2: Anytype Resolution Analysis ✅

**Question**: Are anytype parameters correctly resolved before codegen?

**Finding**: ✅ **YES** - Anytype resolution is fully comptime
- Resolution happens in `generic_block` (comptime block)
- Uses `resolveInlineBody` and `analyzeAsType`
- Types are resolved before reaching codegen

**Conclusion**: Anytype resolution is NOT the issue.

**Documentation**: `docs/rye/0041-riscv-issue2-format-string-analysis.md`

---

### Phase 3: Runtime Codegen Analysis ✅

**Question**: What happens at runtime that might cause issues?

**Finding**: ⚠️ **INDIRECT FUNCTION CALLS** - Potential issue identified
- `Writer.write()` calls `vtable.drain` (function pointer)
- VTable dispatch uses indirect calls
- Indirect calls might generate incorrect code for freestanding

**Conclusion**: Indirect function calls (vtable dispatch) are the likely issue.

**Documentation**: `docs/rye/0042-riscv-issue2-runtime-codegen-analysis.md`

---

## Current Hypothesis

### Primary Hypothesis: Indirect Function Call Codegen

**Problem**: Indirect function calls (function pointers, vtable dispatch) generate incorrect code for freestanding targets.

**Evidence**:
1. ✅ Format strings are comptime (not the issue)
2. ✅ Anytype resolution is comptime (not the issue)
3. ⚠️ Runtime operations use vtable dispatch (function pointers)
4. ⚠️ Function pointer calls might not work correctly

**Flow**:
```
Debug.kprint() 
  → Writer.print() [comptime format parsing ✅]
  → Writer.writeAll() 
  → Writer.write() 
  → vtable.drain() [indirect call ⚠️]
  → Invalid instructions ❌
```

**Test Cases Created**:
- `indirect_function_call.zig` - Tests function pointer calls
- `vtable_dispatch.zig` - Tests vtable dispatch

---

## Test Cases

### Created Test Cases

1. **`comptime_format_string_regular.zig`**
   - Tests format strings in regular functions
   - Verifies comptime evaluation

2. **`anytype_resolution_regular.zig`**
   - Tests anytype resolution in regular functions
   - Verifies resolution before codegen

3. **`indirect_function_call.zig`** ⭐ NEW
   - Tests function pointer calls
   - Verifies indirect call codegen

4. **`vtable_dispatch.zig`** ⭐ NEW
   - Tests vtable dispatch
   - Verifies function pointer calls via vtable

### Test Strategy

**Approach**: Use regular functions (not `_start`) to avoid naked function constraints.

**Verification**:
- Compile tests successfully
- Check generated code for correct instructions
- Verify no invalid instructions

---

## Next Steps

### Immediate

1. **Wait for Sync**
   - Test files in external repo → grainstore
   - Sync daemon copies files

2. **Compile Test Cases**
   ```bash
   zig build-obj test/cases/riscv64_freestanding/indirect_function_call.zig \
       -target riscv64-freestanding -fno-llvm -O Debug
   
   zig build-obj test/cases/riscv64_freestanding/vtable_dispatch.zig \
       -target riscv64-freestanding -fno-llvm -O Debug
   ```

3. **Analyze Results**
   - If tests compile: Check generated code
   - If tests fail: Analyze error messages
   - Verify indirect call codegen

### Short-Term

4. **Trace Function Pointer Codegen**
   - Find where function pointers are called
   - Verify calling convention
   - Check for freestanding-specific issues

5. **Compare with Working Targets**
   - Compare function pointer codegen
   - Identify differences
   - Find freestanding-specific issues

6. **Implement Fix**
   - Fix function pointer call codegen
   - Verify with tests
   - Test with Basin kernel

---

## Key Insights

### What Works (Comptime)

1. ✅ Format string parsing - Fully comptime
2. ✅ Placeholder parsing - Fully comptime
3. ✅ Anytype parameter resolution - Fully comptime
4. ✅ Argument position resolution - Fully comptime

### What Might Be Wrong (Runtime)

1. ⚠️ Indirect function calls (function pointers)
2. ⚠️ VTable dispatch
3. ⚠️ Calling convention for indirect calls
4. ⚠️ Function pointer loads

---

## Investigation Timeline

### Completed

- ✅ Format string analysis (comptime confirmed)
- ✅ Anytype resolution analysis (comptime confirmed)
- ✅ Runtime codegen analysis (indirect calls hypothesis)
- ✅ Test case creation (indirect calls, vtable)

### In Progress

- 🔍 Test compilation (waiting for sync)
- 🔍 Function pointer codegen tracing

### Pending

- ⏳ Root cause identification
- ⏳ Fix implementation
- ⏳ Verification with Basin kernel

---

## Success Criteria

### Issue 2 Fix Complete When:

1. ✅ Test cases compile successfully
2. ✅ Indirect function calls work correctly
3. ✅ VTable dispatch works correctly
4. ✅ No invalid instructions generated
5. ✅ No runtime crashes or hangs
6. ✅ Documentation updated

---

## References

- **Format String Analysis**: `docs/rye/0041-riscv-issue2-format-string-analysis.md`
- **Runtime Codegen Analysis**: `docs/rye/0042-riscv-issue2-runtime-codegen-analysis.md`
- **Test Constraints**: `docs/rye/0039-riscv-issue2-test-constraints.md`
- **Investigation Plan**: `docs/rye/0040-riscv-issue2-investigation-next-steps.md`

---

## Commits Made

### External Repo (`codeberg.org/ryelang/rye`)

- `82b4a7f`: Add revised issue 2 test cases using regular functions
- `[pending]`: Add indirect call and vtable dispatch test cases

### Monorepo (`teamlibra/ry`)

- `5af62f1`: Document format string analysis findings
- `e832481`: Document runtime codegen analysis
- `[pending]`: Document investigation summary

---

**Date**: 20260122.192300.rye  
**Status**: 🔍 **INVESTIGATION** — Hypothesis identified, test cases created

**Next Action**: Wait for sync, compile test cases, verify indirect call codegen.
