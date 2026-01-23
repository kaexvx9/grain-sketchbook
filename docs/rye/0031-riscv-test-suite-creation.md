# RISC-V Test Suite Creation

**Date**: 20260122.190100.rye  
**Status**: ✅ **COMPLETE** — Test cases created for Issues 1 and 3  
**Location**: `test/cases/riscv64_freestanding/`

---

## Overview

Created test cases to verify RISC-V freestanding fixes for Issues 1 and 3.  
Tests are located in `test/cases/riscv64_freestanding/` and compile for `riscv64-freestanding` target.

---

## Test Cases Created

### 1. `global_var_address.zig` — Issue 1 Fix Verification

**Purpose**: Verify global variable address calculation uses PC-relative addressing.

**Tests**:
- Reading global variables (32-bit and 64-bit)
- Writing global variables
- Pointer to global variables
- Multiple global accesses

**Expected Behavior**:
- Global variables use `AUIPC + ADDI` (PC-relative)
- No 64KB offset errors
- Correct address calculation for freestanding target

**Test Metadata**:
```zig
// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Exe
```

---

### 2. `bitwise_conditional.zig` — Issue 3 Fix Verification

**Purpose**: Verify bitwise conditional branches work correctly with zero comparisons.

**Tests**:
- `if ((val & 0x01) != 0)` — odd/even check
- `if ((val & mask) != 0)` — general mask check
- `if ((val & 0xFF) == 0)` — equality check
- Multiple bitwise conditionals

**Expected Behavior**:
- Zero comparisons optimized correctly
- `SLTU rd, zero, rs1` for `!= 0` checks
- `SLTIU rd, rs1, 1` for `== 0` checks
- Correct branch codegen

**Test Metadata**:
```zig
// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Exe
```

---

## Test Structure

### Directory Structure

```
test/cases/riscv64_freestanding/
├── global_var_address.zig    # Issue 1 test
└── bitwise_conditional.zig    # Issue 3 test
```

### Test Format

Tests follow Zig test case format:
- Use `// compile` comment for compilation tests
- Specify `backend=stage2` for self-hosted backend
- Specify `target=riscv64-freestanding` for freestanding target
- Use `output_mode=Exe` for executable output

---

## Running Tests

### Manual Compilation

```bash
cd ~/codeberg/ryelang/rye
zig build-exe test/cases/riscv64_freestanding/global_var_address.zig \
    -target riscv64-freestanding \
    -fno-stage1 \
    -fno-LLVM
```

### Using Test Harness

```bash
cd ~/codeberg/ryelang/rye
zig build test -Dtest-filter=riscv64_freestanding
```

---

## Verification Steps

### 1. Compilation Verification

**Check**: Tests compile without errors
```bash
zig build-exe test/cases/riscv64_freestanding/global_var_address.zig \
    -target riscv64-freestanding \
    -fno-stage1 \
    -fno-LLVM
```

**Expected**: Successful compilation

### 2. Codegen Verification

**Check**: Generated assembly uses correct instructions

**For Issue 1** (global variables):
```riscv
# Should see AUIPC (not LUI) for global variable access
auipc t0, %pcrel_hi(global_counter)
addi  t0, t0, %pcrel_lo(global_counter+4)
```

**For Issue 3** (bitwise conditionals):
```riscv
# Should see optimized zero comparison
andi  t1, t0, 1      # val & 0x01
sltu  t2, zero, t1   # (0 < t1) ? 1 : 0 (optimized)
beq   t2, zero, .Lelse
```

### 3. Runtime Verification

**Check**: Tests run correctly in QEMU or hardware

```bash
# Using QEMU
qemu-riscv64 test/cases/riscv64_freestanding/global_var_address
```

**Expected**: No crashes, assertions pass

---

## Future Test Cases

### Issue 2: Comptime/Anytype Tests (Pending)

When Issue 2 is fixed, create:
- `comptime_format.zig` — Test comptime format strings
- `anytype_params.zig` — Test anytype parameter resolution
- `inline_for.zig` — Test inline for unrolling

### Integration Tests

- `basin_kernel_integration.zig` — Full Basin kernel compilation
- `uart_output.zig` — UART output with bitwise conditionals
- `memory_barrier.zig` — Memory barriers with inline assembly

---

## Test Coverage

| Issue | Test Case | Status | Coverage |
|-------|-----------|--------|----------|
| **1. Global Variables** | `global_var_address.zig` | ✅ Created | Read, write, pointers, multiple globals |
| **2. Comptime/Anytype** | (Pending) | ⏳ Waiting | Format strings, anytype, inline for |
| **3. Bitwise Branches** | `bitwise_conditional.zig` | ✅ Created | Zero comparisons, masks, equality |
| **4. Inline ASM** | (Documentation only) | ✅ Documented | N/A (syntax documentation) |

---

## References

- **Issue 1 Fix**: `docs/rye/0026-riscv-global-var-fix-implementation.md`
- **Issue 3 Fix**: `docs/rye/0028-riscv-bitwise-branch-fix-implementation.md`
- **Test Format**: `test/cases/README.md`
- **Phase 2 Summary**: `docs/rye/0030-riscv-phase2-progress-summary.md`

---

## Status

**Current**: ✅ Test cases created for Issues 1 and 3  
**Next Steps**:
- Run tests to verify fixes work
- Create Issue 2 tests when fix is implemented
- Add integration tests with Basin kernel

---

**Date**: 20260122.190100.rye  
**Status**: ✅ **COMPLETE** — Test cases created and committed
