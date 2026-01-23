# RISC-V Issue 2: Investigation Plan

**Date**: 20260122.190400.rye  
**Status**: 🔍 **INVESTIGATION** — Issue 2: Function Calls with anytype/comptime  
**Progress**: Test cases created, investigation plan outlined

---

## Problem Statement

Functions with `anytype` parameters or comptime string formatting crash or hang.  
Affects: `Debug.kassert()`, `Debug.kprint()`, functions using `inline for` over runtime slices.

**Symptoms**:
- `Debug.kassert(condition, "message", .{})` - hangs even when condition is true
- `Debug.kprint("text", .{})` - generates invalid instructions
- Any function using `inline for` over runtime slices - generates invalid loop code

**Error Evidence**:
```
[kernel_vm_test] Error at PC 0x80019644 ... error.invalid_instruction
[kernel_vm_test] Error at PC 0x800a8208 ... error.unaligned_instruction
```

---

## Investigation Findings

### 1. Anytype Resolution (Sema.zig lines 7317-7364)

**Current Behavior**:
- Anytype parameters are resolved at comptime by evaluating the generic parameter type
- Resolution happens before codegen
- Code looks correct: `param_ty = try sema.analyzeAsType(&generic_block, param_src, ty_ref)`

**Hypothesis**: 
- Resolution works correctly
- Problem may be in codegen handling of resolved types for freestanding
- Or problem may be in how resolved types interact with calling convention

### 2. Comptime Format Strings

**Current Behavior**:
- Format strings with `comptime` keyword should be fully evaluated at comptime
- Standard library `std.fmt` functions use comptime format strings

**Hypothesis**:
- Format string parsing may generate runtime code for freestanding
- Or format string evaluation may not be fully comptime for freestanding targets

### 3. Inline For Unrolling

**Current Behavior**:
- `inline for` should unroll at comptime when iterating over comptime slices
- Runtime slices should not use `inline for`

**Hypothesis**:
- `inline for` may not be properly unrolling for freestanding
- Or runtime slices may be incorrectly using `inline for`

---

## Test Cases Created

### 1. `comptime_format_string.zig`

**Purpose**: Test comptime format string evaluation

**Tests**:
- Comptime format string function
- Anytype parameter resolution
- Inline for with comptime slice

**Expected**: All should compile and work correctly

### 2. `anytype_resolution.zig`

**Purpose**: Test anytype parameter resolution

**Tests**:
- Generic function with anytype parameters
- Multiple calls with different types (u32, u64, i32)
- Type resolution before codegen

**Expected**: All types resolved correctly, correct codegen

---

## Investigation Plan

### Phase 1: Compilation Testing

**Goal**: Verify test cases compile and identify compilation errors

**Steps**:
1. Build Rye compiler
2. Compile test cases for `riscv64-freestanding`
3. Check for compilation errors
4. Analyze error messages

**Expected Outcomes**:
- If compilation fails: Identify specific error
- If compilation succeeds: Check generated code

### Phase 2: Codegen Analysis

**Goal**: Analyze generated code for issues

**Steps**:
1. Generate assembly for test cases
2. Check for invalid instructions
3. Verify calling conventions
4. Check for runtime format parsing

**Expected Outcomes**:
- Identify specific codegen issues
- Locate problematic instruction sequences
- Understand root cause

### Phase 3: Root Cause Identification

**Goal**: Identify exact root cause

**Steps**:
1. Trace format string evaluation through compiler
2. Verify anytype resolution flow
3. Check inline for unrolling behavior
4. Compare with working targets (e.g., x86_64)

**Expected Outcomes**:
- Identify exact location of issue
- Understand why it fails for freestanding
- Document root cause

### Phase 4: Fix Implementation

**Goal**: Implement fix

**Steps**:
1. Design fix based on root cause
2. Implement fix in appropriate location
3. Test fix with test cases
4. Verify with Basin kernel

**Expected Outcomes**:
- Fix implemented
- Test cases pass
- Basin kernel works

---

## Key Code Locations

### Anytype Resolution
- **Location**: `src/Sema.zig` lines 7317-7364
- **Function**: `analyzeCall` - Generic parameter resolution
- **Key Code**: `param_ty = try sema.analyzeAsType(&generic_block, param_src, ty_ref)`

### Comptime Evaluation
- **Location**: `src/Zcu/PerThread.zig` lines 853-927
- **Function**: `analyzeComptimeUnit` - Comptime unit analysis
- **Key Code**: Comptime block evaluation

### Function Call Codegen
- **Location**: `src/arch/riscv64/CodeGen.zig` lines 4826-4950
- **Function**: `genCall` - Function call codegen
- **Key Code**: Calling convention handling

### Format String Parsing
- **Location**: Standard library (not in compiler)
- **Function**: `std.fmt` functions
- **Key Code**: Format string evaluation

---

## Workaround (Current)

Use comptime-unrolled inline assembly:

```zig
const Uart = struct {
    inline fn putc(c: u8) void {
        asm volatile (
            \\lui t1, 0x10000
            \\sb %[byte], 0(t1)
            :
            : [byte] "r" (c),
        );
    }
    
    pub inline fn print(comptime s: []const u8) void {
        inline for (s) |c| {
            putc(c);
        }
    }
};
```

**Key Requirements**:
- `inline fn` to avoid function call overhead
- `comptime s: []const u8` to force compile-time unrolling
- `inline for` to unroll at compile time (no runtime loop)
- Direct inline assembly for the actual store

---

## Next Steps

### Immediate (This Week)

1. **Build and Test**:
   - Build Rye compiler
   - Compile test cases
   - Identify compilation errors

2. **Codegen Analysis**:
   - Generate assembly
   - Analyze generated code
   - Identify problematic sequences

### Short-Term (Next Week)

1. **Root Cause**:
   - Trace through compiler
   - Identify exact issue
   - Document findings

2. **Fix Design**:
   - Design fix
   - Implement fix
   - Test fix

---

## Success Criteria

### Issue 2 Complete When:

- ✅ Test cases compile successfully
- ✅ Generated code is correct
- ✅ No invalid instructions
- ✅ Correct calling conventions
- ✅ Format strings fully comptime
- ✅ Anytype parameters resolved correctly
- ✅ Inline for unrolls correctly
- ✅ Basin kernel works with format strings

---

## References

- **Issue 2 Analysis**: `docs/rye/0027-riscv-anytype-comptime-fix-analysis.md`
- **Test Cases**: `test/cases/riscv64_freestanding/comptime_format_string.zig`
- **Test Cases**: `test/cases/riscv64_freestanding/anytype_resolution.zig`
- **Original Issues**: `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md`
- **Workaround**: Inline assembly with comptime unrolling

---

**Date**: 20260122.190400.rye  
**Status**: 🔍 **INVESTIGATION** — Test cases created, investigation plan outlined

**Next Action**: Build compiler and test cases to identify root cause
