# RISC-V Issue 2: Investigation Next Steps

**Date**: 20260122.191800.rye  
**Status**: 🔍 **READY** — Test cases created, investigation ready  
**Next**: Compile tests, trace format string evaluation, analyze anytype resolution

---

## Current Status

### ✅ Completed

1. **Revised Test Cases Created**
   - `comptime_format_string_regular.zig` - Tests format strings in regular functions
   - `anytype_resolution_regular.zig` - Tests anytype resolution in regular functions
   - Committed to external repo

2. **Test Strategy Defined**
   - Use regular functions (not `_start`) to avoid naked function constraints
   - Compile to object files (`output_mode=Obj`)
   - Verify compilation and codegen

### 🔍 Next Steps

1. **Compile Test Cases**
   - Wait for sync daemon to copy files to grainstore
   - Compile both test cases
   - Document compilation results

2. **Investigate Format String Evaluation**
   - Trace `std.fmt` format string parsing
   - Verify comptime evaluation
   - Check for runtime format parsing

3. **Investigate Anytype Resolution**
   - Verify resolution happens before codegen
   - Check calling convention for resolved types
   - Trace through codegen phases

---

## Investigation Plan

### Phase 1: Compilation Testing

**Goal**: Verify Issue 2 test cases compile successfully

**Steps**:
1. Wait for sync daemon (files in external repo → grainstore)
2. Compile `comptime_format_string_regular.zig`
3. Compile `anytype_resolution_regular.zig`
4. Document compilation results

**Success Criteria**:
- ✅ Tests compile without errors
- ✅ No codegen errors
- ✅ Object files generated successfully

### Phase 2: Format String Analysis

**Goal**: Understand how format strings are evaluated

**Investigation Areas**:

#### 2.1 Standard Library Format Functions

**Location**: `lib/std/fmt.zig` (in Zig stdlib)

**Questions**:
- How does `std.fmt.format()` handle comptime format strings?
- Is format string parsing fully evaluated at comptime?
- Are format arguments evaluated at comptime?

**Action**: 
- Review `std.fmt` implementation
- Trace format string parsing through compiler
- Verify comptime evaluation

#### 2.2 Comptime Format String Parsing

**Location**: Compiler format string handling

**Questions**:
- Where is format string parsing implemented?
- Is parsing done at comptime or runtime?
- Are format specifiers resolved at comptime?

**Action**:
- Search for format string parsing code
- Verify comptime evaluation
- Check for runtime parsing code

#### 2.3 Freestanding Target Handling

**Questions**:
- Does freestanding have special format string handling?
- Are format strings fully evaluated for freestanding?
- Is there runtime format parsing for freestanding?

**Action**:
- Check target-specific format handling
- Verify no runtime format parsing
- Ensure full comptime evaluation

### Phase 3: Anytype Resolution Analysis

**Goal**: Verify anytype parameters are correctly resolved

**Investigation Areas**:

#### 3.1 Resolution Flow

**Location**: `src/Sema.zig` lines 7317-7364

**Questions**:
- Are all `anytype` parameters resolved before codegen?
- Is resolution happening in comptime blocks?
- Are resolved types correctly passed to codegen?

**Action**:
- Review anytype resolution code
- Trace resolution through compiler phases
- Verify resolution happens at comptime

#### 3.2 Codegen for Resolved Types

**Location**: `src/arch/riscv64/CodeGen.zig`

**Questions**:
- Are resolved types correctly handled in codegen?
- Is calling convention correct for resolved generics?
- Are function calls generated correctly?

**Action**:
- Review function call codegen
- Check calling convention handling
- Verify resolved type codegen

#### 3.3 Generic Function Instantiations

**Questions**:
- How are generic functions instantiated?
- Are instantiations correct for freestanding?
- Is codegen correct for instantiated functions?

**Action**:
- Review generic instantiation code
- Check freestanding-specific handling
- Verify codegen for instantiations

### Phase 4: Root Cause Identification

**Goal**: Identify exact cause of Issue 2

**Steps**:
1. Compare working vs. failing code paths
2. Identify freestanding-specific issues
3. Determine if fix is in sema or codegen
4. Document root cause

**Hypotheses to Test**:
1. **Format String Runtime Parsing**: Format strings not fully evaluated at comptime
2. **Anytype Codegen Issue**: Resolved types not correctly handled in codegen
3. **Calling Convention**: Incorrect calling convention for resolved generics
4. **Freestanding Restrictions**: Missing comptime validation for freestanding

### Phase 5: Fix Implementation

**Goal**: Implement fix and verify

**Steps**:
1. Implement fix based on root cause
2. Update test cases
3. Verify fix works
4. Document fix

---

## Key Code Locations

### Format String Parsing

- **Standard Library**: `lib/std/fmt.zig` (Zig stdlib)
- **Compiler**: `src/fmt.zig` (compiler format utilities)
- **Comptime Evaluation**: `src/Sema.zig` (comptime evaluation)

### Anytype Resolution

- **Resolution**: `src/Sema.zig` lines 7317-7364
- **Generic Blocks**: `src/Sema.zig` (generic parameter resolution)
- **Codegen**: `src/arch/riscv64/CodeGen.zig` (function call codegen)

### Comptime Evaluation

- **Comptime Blocks**: `src/Sema.zig` (comptime block handling)
- **Comptime Units**: `src/Zcu/PerThread.zig` lines 853-927
- **Comptime Reasons**: `src/Sema.zig` lines 884-925

---

## Test Case Compilation

### Expected Behavior

**If Issue 2 is Fixed**:
- ✅ Tests compile successfully
- ✅ Format strings fully evaluated at comptime
- ✅ Anytype parameters correctly resolved
- ✅ No runtime format parsing
- ✅ Correct codegen for resolved types

**If Issue 2 Still Exists**:
- ⚠️ Tests may compile but generate incorrect code
- ⚠️ Format strings may have runtime parsing
- ⚠️ Anytype resolution may be incomplete
- ⚠️ Codegen may be incorrect

---

## Success Criteria

### Issue 2 Fix Complete When:

1. ✅ Test cases compile successfully
2. ✅ Format strings fully evaluated at comptime
3. ✅ Anytype parameters correctly resolved and codegen'd
4. ✅ No runtime format parsing for freestanding
5. ✅ Correct calling convention for resolved generics
6. ✅ No runtime crashes or hangs
7. ✅ Documentation updated

---

## References

- **Test Constraints**: `docs/rye/0039-riscv-issue2-test-constraints.md`
- **Current State**: `docs/rye/0038-riscv-phase2-current-state-and-next-steps.md`
- **Code Analysis**: `docs/rye/0035-riscv-issue2-code-analysis.md`
- **Investigation Plan**: `docs/rye/0033-riscv-issue2-investigation-plan.md`

---

**Date**: 20260122.191800.rye  
**Status**: 🔍 **READY** — Investigation plan ready, test cases created

**Next Action**: Compile test cases and begin format string analysis.
