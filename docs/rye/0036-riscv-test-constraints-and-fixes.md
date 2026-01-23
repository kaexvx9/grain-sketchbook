# RISC-V Test Constraints & Required Fixes

**Date**: 20260122.191000.rye  
**Status**: ✅ **DOCUMENTATION** — Test constraints and required compiler fixes  
**Purpose**: Document why tests are minimal and what fixes are needed

---

## Test Constraints for Naked Functions

### Problem

Naked functions (`callconv(.naked)`) have strict limitations:
- ❌ **No runtime calls** (e.g., `std.debug.assert`)
- ❌ **No local variables** (`var` declarations)
- ✅ **Only**: Direct operations, global variable access, inline assembly

### Why Tests Are Minimal

Our RISC-V freestanding tests must:
1. **Compile successfully** (verify codegen fixes)
2. **Avoid runtime calls** (can't use `std.debug.assert`)
3. **Use globals only** (no locals in naked functions)

**Test Strategy**: 
- Tests verify **compilation** (codegen correctness)
- Not runtime execution (would require QEMU/hardware)
- Success = correct instruction generation

---

## Required Compiler Fix: V Extension for Freestanding

### Problem

RISC-V codegen requires `.v` (vector) extension by default, but freestanding targets (e.g., Basin kernel) typically don't have it.

**Error**: `error: target missing required feature v`

### Fix

**Location**: `src/arch/riscv64/CodeGen.zig` lines 1107-1125

**Change**: Make `.v` optional for freestanding targets:

```zig
const required_features = [_]Target.riscv.Feature{
    .d,
    .m,
    .a,
    .zicsr,
    .v,
    .zbb,
};

fn gen(func: *Func) !void {
    const pt = func.pt;
    const zcu = pt.zcu;
    const fn_info = zcu.typeToFunc(func.fn_type).?;
    const freestanding = func.target.os.tag == .freestanding;

    inline for (required_features) |feature| {
        // Why: Freestanding (e.g. Basin kernel) typically lacks V extension.
        if (freestanding and feature == .v) continue;
        if (!func.hasFeature(feature)) {
            return func.fail(
                "target missing required feature {s}",
                .{@tagName(feature)},
            );
        }
    }
    // ... rest of gen function
}
```

**Why**: Basin kernel and most freestanding RISC-V targets don't include vector extensions. Making `.v` optional allows compilation for freestanding while still requiring it for other targets.

---

## Test File Format

### Minimal Test Pattern

```zig
//! Why: Test description.

const builtin = @import("builtin");
const std = @import("std");

// Use globals (no locals in naked)
var test_var: u32 = 0;

pub fn _start() callconv(.naked) noreturn {
    // Direct operations only
    _ = test_var;  // Read
    test_var = 42; // Write
    // No asserts, no function calls, no locals
    
    while (true) {}
}

comptime {
    @export(&_start, .{ .name = "_start" });
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Exe
```

---

## Verification Strategy

### Compile-Only Verification

Since tests can't run (no runtime), we verify fixes by:

1. **Compilation Success**: Tests compile without errors
2. **Assembly Inspection**: Check generated `.s` files for correct instructions
3. **Integration**: Test with Basin kernel (full system test)

### Assembly Verification

```bash
# Generate assembly
zig build-exe test.zig -target riscv64-freestanding -fno-llvm -femit-asm

# Check for correct instructions
# Issue 1: Should see AUIPC (not LUI) for globals
# Issue 3: Should see optimized zero comparisons
```

---

## Current Status

### ✅ Fixes Applied

1. **Issue 1**: Global variable fix (AUIPC) - ✅ Committed
2. **Issue 3**: Bitwise branch fix (zero optimization) - ✅ Committed
3. **V Extension**: Optional for freestanding - ⚠️ Needs re-application

### ⚠️ Pending

1. **V Extension Fix**: Re-apply to `CodeGen.zig`
2. **Test Simplification**: Update tests to minimal format
3. **Verification**: Compile tests and inspect assembly

---

## Next Steps

1. **Re-apply V fix** to `CodeGen.zig`
2. **Update tests** to minimal format (no asserts/calls)
3. **Commit to external repo** (`~/codeberg/ryelang/rye`)
4. **Wait for sync** (daemon copies to grainstore)
5. **Build and test** compilation

---

**Date**: 20260122.191000.rye  
**Status**: ✅ **DOCUMENTATION** — Constraints and fixes documented
