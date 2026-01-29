# RISC-V Freestanding Codegen Fix Strategy

**Date**: 2026-01-22-062923-pst  
**Status**: 🆕 **FIX STRATEGY** — Detailed plan for fixing Zig 0.15.2 RISC-V freestanding bugs  
**Base**: Issues documented in `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md`

---

## Overview

This document provides a detailed strategy for fixing the four critical RISC-V freestanding codegen bugs discovered during Basin kernel development. These fixes will be implemented in the Rye compiler fork.

---

## Issue 1: Incorrect Global Variable Address Calculation

### Problem

Global variable at `0x800ddf28` accessed at `0x800def28` (off by 64KB).  
The `AUIPC + ADDI` instruction sequence calculates wrong address.

### Root Cause Analysis

**Location in Zig Compiler**: `src/codegen/riscv64.zig` (or equivalent)  
**Issue**: Address calculation for global variables uses incorrect offset in `AUIPC` instruction.

**AUIPC Instruction Format**:
```
AUIPC rd, imm20
# Computes: rd = PC + (imm20 << 12)
```

**ADDI Instruction Format**:
```
ADDI rd, rs1, imm12
# Computes: rd = rs1 + sign_extend(imm12)
```

**Correct Sequence**:
```
AUIPC t1, imm20_high    # t1 = PC + (imm20_high << 12)
ADDI  t1, t1, imm12_low  # t1 = t1 + sign_extend(imm12_low)
# Result: t1 = global_variable_address
```

**Bug**: `imm20_high` calculation is off by 1, causing 64KB offset error.

### Fix Strategy

1. **Locate Codegen Function**: Find `genGlobalVariableAccess` or equivalent in RISC-V codegen
2. **Fix Address Calculation**: Correct `AUIPC` immediate calculation
3. **Add Test**: Create test case that verifies correct global variable access
4. **Verify**: Test with Basin kernel global variables

### Implementation

```zig
// In src/codegen/riscv64.zig (or equivalent)

// BEFORE (buggy):
const high_20 = (addr >> 12) & 0xFFFFF;  // Wrong calculation
const low_12 = addr & 0xFFF;

// AFTER (fixed):
const high_20 = ((addr - pc) >> 12) & 0xFFFFF;  // Account for PC-relative
const low_12 = (addr & 0xFFF) | ((addr < 0) ? 0x800 : 0);  // Sign extension
```

### Test Case

```rye
// test/riscv64_global_var.ry
var test_global: bool = true;

pub fn test_global_access() bool {
    return test_global;  // Should access correct address
}
```

---

## Issue 2: Function Calls Causing Crashes

### Problem

Functions with `anytype` parameters or comptime string formatting crash or hang.  
Affects: `Debug.kassert()`, `Debug.kprint()`, functions using `inline for` over runtime slices.

### Root Cause Analysis

**Location**: `src/codegen/riscv64.zig` - Function call codegen  
**Issue**: Comptime codegen for `anytype` and format strings generates invalid RISC-V instructions for freestanding target.

**Specific Problems**:
1. Comptime format parsing generates code that assumes runtime support
2. `anytype` parameter handling generates incorrect calling convention code
3. `inline for` over runtime slices generates invalid loop code

### Fix Strategy

1. **Comptime Format Strings**: Ensure format parsing is fully comptime for freestanding
2. **Anytype Handling**: Fix codegen for `anytype` in freestanding context
3. **Inline For**: Ensure `inline for` generates correct unrolled code

### Implementation

```zig
// In src/codegen/riscv64.zig

// Fix comptime format string codegen for freestanding
fn genComptimeFormatString(comptime fmt: []const u8) void {
    // Ensure all format parsing is comptime
    // Generate direct string output, not runtime format calls
}

// Fix anytype parameter codegen
fn genAnytypeParam(param: AnytypeParam) void {
    // Generate correct calling convention for freestanding
    // Don't assume runtime type information
}
```

### Test Cases

```rye
// test/riscv64_comptime_format.ry
pub fn test_comptime_print(comptime msg: []const u8) void {
    // Should work in freestanding
    print_comptime(msg);
}

// test/riscv64_anytype.ry
pub fn test_anytype(val: anytype) void {
    // Should generate correct code for freestanding
    _ = val;
}
```

---

## Issue 3: Conditional Branch Codegen

### Problem

Conditionals like `if ((lsr_val & 0x01) != 0)` don't work correctly.  
Bitwise operations with conditionals generate incorrect branch code.

### Root Cause Analysis

**Location**: `src/codegen/riscv64.zig` - Conditional branch codegen  
**Issue**: Bitwise operations in conditionals generate incorrect comparison and branch instructions.

**Expected Codegen**:
```riscv
ANDI t1, t0, 1      # t1 = lsr_val & 0x01
BNEZ t1, .Lbranch   # if t1 != 0, branch
```

**Buggy Codegen**: May generate incorrect comparison or branch instruction.

### Fix Strategy

1. **Locate Branch Codegen**: Find conditional branch generation
2. **Fix Bitwise Comparison**: Ensure bitwise ops generate correct comparison
3. **Test Bitwise Branches**: Verify all bitwise conditional patterns

### Implementation

```zig
// In src/codegen/riscv64.zig

// Fix conditional branch with bitwise operations
fn genConditionalBranch(cond: Condition, bitwise_op: ?BitwiseOp) void {
    if (bitwise_op) |op| {
        // Generate correct bitwise comparison
        genBitwiseOp(op);
        genBranch(cond, .Ltarget);
    } else {
        genBranch(cond, .Ltarget);
    }
}
```

### Test Case

```rye
// test/riscv64_bitwise_branch.ry
pub fn test_bitwise_conditional(val: u32) bool {
    if ((val & 0x01) != 0) {
        return true;
    }
    return false;
}
```

---

## Issue 4: Inline Assembly Clobber Syntax

### Problem

Zig 0.15 changed inline assembly clobber syntax (breaking change).  
Old syntax: `: "t0"` (string)  
New syntax: `: .t0` (enum-style)

### Root Cause Analysis

**Location**: `src/parse/asm.zig` - Inline assembly parser  
**Issue**: Syntax change is correct, but needs to be documented and consistent.

### Fix Strategy

1. **Document Syntax**: Ensure Rye documentation clearly shows new syntax
2. **Error Messages**: Provide clear error messages for old syntax
3. **Migration Guide**: Document migration from old to new syntax

### Implementation

```zig
// In src/parse/asm.zig

// Accept new syntax: .t0, .t1, etc.
// Reject old syntax: "t0", "t1", etc. with helpful error message
```

### Documentation

```markdown
## Inline Assembly Clobber Syntax

**New Syntax** (Rye/Zig 0.15+):
```rye
asm volatile (
    "instruction"
    : [output] "=r" (output)
    : [input] "r" (input)
    : .t0, .t1  // Enum-style clobbers
);
```

**Old Syntax** (deprecated):
```rye
: "t0", "t1"  // String clobbers - ERROR in Rye
```
```

---

## Testing Strategy

### Test Suite Structure

```
rye/test/
├── riscv64_freestanding/
│   ├── global_var.ry          # Issue 1: Global variable access
│   ├── comptime_format.ry      # Issue 2: Comptime format strings
│   ├── anytype_params.ry       # Issue 2: Anytype parameters
│   ├── bitwise_branch.ry        # Issue 3: Bitwise conditionals
│   └── inline_asm.ry            # Issue 4: Inline assembly
└── integration/
    └── basin_kernel.ry          # Full Basin kernel test
```

### Test Execution

```bash
# Run RISC-V freestanding tests
rye test test/riscv64_freestanding/*.ry --target riscv64-freestanding-none

# Run Basin kernel integration test
rye test test/integration/basin_kernel.ry --target riscv64-freestanding-none
```

---

## Implementation Priority

### Phase 1: Critical Fixes (Week 1-2)

1. **Issue 1**: Global variable address calculation (HIGH - blocks kernel)
2. **Issue 3**: Conditional branch codegen (HIGH - blocks kernel)

### Phase 2: Function Call Fixes (Week 3-4)

3. **Issue 2**: Function calls with anytype/comptime (MEDIUM - affects debugging)

### Phase 3: Documentation (Week 5)

4. **Issue 4**: Inline assembly syntax (LOW - documentation/error messages)

---

## Verification

### Success Criteria

- ✅ All test cases pass
- ✅ Basin kernel builds and runs correctly
- ✅ No workarounds needed (no inline assembly for simple operations)
- ✅ Global variables accessed at correct addresses
- ✅ Conditionals work with bitwise operations
- ✅ Comptime functions work in freestanding context

### Basin Kernel Integration

```bash
# Build Basin kernel with Rye compiler
cd /home/xy/grain-sketchbook
rye build basin-rv64

# Run integration test
rye test src/vantage/basin_integration_test.ry

# Boot in QEMU
rye build basin-rv64 vantage-x86_64
./scripts/create_iso.sh
qemu-system-x86_64 -cdrom vantage.iso -serial stdio
```

---

## References

- **Original Issues**: `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md`
- **Zig 0.15.2 Source**: https://codeberg.org/ziglang/zig/src/tag/0.15.2
- **RISC-V Specification**: RISC-V Instruction Set Manual

---

**Date**: 2026-01-22-062923-pst  
**Status**: 🆕 **FIX STRATEGY** — Detailed plan for fixing Zig 0.15.2 RISC-V freestanding bugs
