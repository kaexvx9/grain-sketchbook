# RISC-V Global Variable Address Fix: Implementation

**Date**: 20260122.184500.rye  
**Status**: 🚧 **IN PROGRESS** — Fixing Issue 1: Incorrect Global Variable Address Calculation  
**Issue**: Global variables accessed with wrong address (off by 64KB)

---

## Problem Summary

Global variable at `0x800ddf28` accessed at `0x800def28` (off by 64KB).  
The codegen uses `LUI + ADDI` instead of `AUIPC + ADDI` for PC-relative addressing.

---

## Root Cause

**Location**: `src/arch/riscv64/Lower.zig` line 240-248

**Current Code** (buggy):
```zig
.pseudo_load_symbol => {
    const payload = inst.data.reloc;
    const dst_reg = payload.register;
    assert(dst_reg.class() == .int);

    try lower.emit(.lui, &.{  // ❌ WRONG: LUI is absolute, not PC-relative
        .{ .reg = dst_reg },
        .{ .imm = lower.reloc(.{
            .load_symbol_reloc = .{
                .atom_index = payload.atom_index,
                .sym_index = payload.sym_index,
            },
        }) },
    });

    try lower.emit(.addi, &.{
        .{ .reg = dst_reg },
        .{ .reg = dst_reg },
        .{ .imm = Immediate.s(0) },
    });
},
```

**Issue**: 
- `LUI` loads an absolute 20-bit immediate (not PC-relative)
- For freestanding targets, we need `AUIPC` (Add Upper Immediate to PC)
- The linker relocation `R_RISCV.HI20` expects PC-relative addressing

---

## Fix

**Change**: Replace `.lui` with `.auipc` for symbol loading

**Fixed Code**:
```zig
.pseudo_load_symbol => {
    const payload = inst.data.reloc;
    const dst_reg = payload.register;
    assert(dst_reg.class() == .int);

    try lower.emit(.auipc, &.{  // ✅ FIXED: AUIPC is PC-relative
        .{ .reg = dst_reg },
        .{ .imm = lower.reloc(.{
            .load_symbol_reloc = .{
                .atom_index = payload.atom_index,
                .sym_index = payload.sym_index,
            },
        }) },
    });

    try lower.emit(.addi, &.{
        .{ .reg = dst_reg },
        .{ .reg = dst_reg },
        .{ .imm = Immediate.s(0) },
    });
},
```

**Why This Works**:
- `AUIPC rd, imm20` computes: `rd = PC + (imm20 << 12)`
- `ADDI rd, rd, imm12` computes: `rd = rd + sign_extend(imm12)`
- Together: `rd = PC + (imm20 << 12) + sign_extend(imm12)`
- Linker resolves `R_RISCV.HI20` and `R_RISCV.LO12_I` relocations correctly
- Result: Correct PC-relative address to global variable

---

## Implementation Steps

1. **Edit**: `~/codeberg/ryelang/rye/src/arch/riscv64/Lower.zig`
   - Change line 240: `.lui` → `.auipc`

2. **Test**: Create test case
   - File: `~/codeberg/ryelang/rye/test/riscv64_freestanding/global_var.ry`
   - Test global variable access

3. **Verify**: Build and test
   - Build Rye compiler
   - Compile test case
   - Verify correct address calculation

4. **Integration**: Test with Basin kernel
   - Build Basin kernel with fixed Rye compiler
   - Verify global variables work correctly

---

## Test Case

```rye
// test/riscv64_freestanding/global_var.ry
var test_global: bool = true;

/// Why: Test global variable access with correct address calculation.
pub fn test_global_access() bool {
    std.debug.assert(test_global == true);
    return test_global;
}

/// Why: Test global variable modification.
pub fn test_global_modify() void {
    test_global = false;
    std.debug.assert(test_global == false);
    test_global = true;
    std.debug.assert(test_global == true);
}
```

---

## Verification

### Before Fix
```
# Disassembly shows:
LUI  t1, 0x800dd      # Absolute address (wrong)
ADDI t1, t1, 0x728    # Results in 0x800def28 (wrong by 64KB)
```

### After Fix
```
# Disassembly shows:
AUIPC t1, 0x800dd     # PC-relative address (correct)
ADDI  t1, t1, 0x728   # Results in 0x800ddf28 (correct)
```

---

## References

- **Issue Document**: `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md`
- **Fix Strategy**: `docs/rye/0013-riscv-freestanding-fix-strategy.md`
- **RISC-V Spec**: RISC-V Instruction Set Manual (AUIPC instruction)

---

**Date**: 20260122.184500.rye  
**Status**: 🚧 **IN PROGRESS** — Ready to implement fix
