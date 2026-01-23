# RISC-V Frame Layout Issue: Investigation & Fix Strategy

**Date**: 20260122.195100.rye  
**Status**: 🔍 **INVESTIGATION** — Root cause identified, fix strategy proposed  
**Type**: Compiler internal error (integer overflow in frame layout)

---

## Issue Summary

**Error**: Compiler panic when compiling `kernel_shell.zig`

```
thread 828704 panic: integer does not fit in destination type
src/arch/riscv64/CodeGen.zig:1864:25
        .stack_adjust = @intCast(acc_frame_size),
```

**Location**: `src/arch/riscv64/CodeGen.zig:1864` in `computeFrameLayout()`

---

## Root Cause Analysis

### Problem

**Type Mismatch**: `acc_frame_size` is `i32`, but `stack_adjust` is `i12`

**Code**:
```zig
const FrameLayout = struct {
    stack_adjust: i12,  // 12-bit signed integer (-2048 to 2047)
    save_reg_list: Mir.RegisterList,
};

// In computeFrameLayout():
const acc_frame_size: i32 = std.mem.alignForward(
    i32,
    total_alloc_size + 64 + args_frame_size + spill_frame_size + call_frame_size,
    @intCast(frame_align[@intFromEnum(FrameIndex.base_ptr)].toByteUnits().?),
);

return .{
    .stack_adjust = @intCast(acc_frame_size),  // ❌ Fails if acc_frame_size > 2047
    .save_reg_list = save_reg_list,
};
```

**Why `i12`?**: RISC-V immediate values in instructions are 12 bits. The `stack_adjust` is used in `addi` instructions:

```zig
.imm12 = Immediate.s(-@as(i32, @intCast(frame_layout.stack_adjust))),
```

**Issue**: When `kernel_shell.zig` has a stack frame larger than 2047 bytes, `acc_frame_size` exceeds the `i12` range, causing the `@intCast` to panic.

---

## Why This Happens

### Large Stack Frames

**`kernel_shell.zig`** likely has:
- Many local variables
- Large arrays on the stack
- Complex function with many allocations
- Total stack frame > 2047 bytes

**RISC-V Limitation**: Single `addi` instruction can only adjust stack by ±2047 bytes in one instruction.

---

## Fix Strategy

### Option 1: Use Multiple Instructions for Large Frames ✅ (Recommended)

**Approach**: When `acc_frame_size > 2047`, use multiple `addi` instructions or load value into register first.

**Implementation**:
```zig
// In computeFrameLayout():
const max_i12: i32 = 2047;
if (acc_frame_size > max_i12) {
    // Use register to hold large value
    // Generate: lui + addi to load value, then add to sp
    // Or: Multiple addi instructions
    return func.fail("stack frame too large: {d} bytes (max {d})", .{ acc_frame_size, max_i12 });
}

return .{
    .stack_adjust = @intCast(acc_frame_size),
    .save_reg_list = save_reg_list,
};
```

**Better**: Actually generate multiple instructions or use register:
```zig
// Generate code like:
// lui  t0, %hi(frame_size)
// addi t0, t0, %lo(frame_size)
// sub  sp, sp, t0
```

### Option 2: Change stack_adjust to i32, Handle in Codegen

**Approach**: Store `i32` value, handle large values in instruction generation.

**Implementation**:
```zig
const FrameLayout = struct {
    stack_adjust: i32,  // Change to i32
    save_reg_list: Mir.RegisterList,
};

// In codegen, check if value fits in 12 bits:
if (frame_layout.stack_adjust <= 2047) {
    // Use single addi
    .imm12 = Immediate.s(-@as(i32, @intCast(frame_layout.stack_adjust))),
} else {
    // Use multiple instructions or register
    // Generate: lui + addi + sub
}
```

### Option 3: Limit Stack Frame Size

**Approach**: Fail compilation if stack frame exceeds 2047 bytes (not ideal, but safe).

**Implementation**:
```zig
const max_stack_adjust: i32 = 2047;
if (acc_frame_size > max_stack_adjust) {
    return func.fail(
        "stack frame size {d} bytes exceeds maximum {d} bytes for single instruction",
        .{ acc_frame_size, max_stack_adjust },
    );
}
```

---

## Recommended Fix: Option 2

**Why**: Most flexible, handles all cases, maintains type safety.

**Steps**:
1. Change `stack_adjust` type from `i12` to `i32` in `FrameLayout`
2. Update instruction generation to handle large values
3. Generate multiple instructions when value > 2047
4. Test with `kernel_shell.zig`

---

## Implementation Plan

### Step 1: Change Type Definition

**File**: `src/arch/riscv64/CodeGen.zig:1765`

```zig
const FrameLayout = struct {
    stack_adjust: i32,  // Changed from i12
    save_reg_list: Mir.RegisterList,
};
```

### Step 2: Update Instruction Generation

**File**: `src/arch/riscv64/CodeGen.zig:1201-1208`

```zig
// Check if value fits in 12 bits
const stack_adjust = frame_layout.stack_adjust;
if (stack_adjust <= 2047 and stack_adjust >= -2048) {
    // Single instruction
    func.mir_instructions.set(backpatch_stack_alloc, .{
        .tag = .addi,
        .data = .{ .i_type = .{
            .rd = .sp,
            .rs1 = .sp,
            .imm12 = Immediate.s(-@as(i32, @intCast(stack_adjust))),
        } },
    });
} else {
    // Multiple instructions: load value into register, then subtract
    // TODO: Implement multi-instruction sequence
    return func.fail("stack frame too large: {d} bytes", .{stack_adjust});
}
```

### Step 3: Test

1. Test with `kernel_shell.zig`
2. Verify compilation succeeds
3. Check generated code is correct

---

## Impact

### On Compilation

**Before Fix**:
- ❌ `kernel_shell.zig` crashes compiler
- ✅ `debug.zig` compiles (smaller stack frame)

**After Fix**:
- ✅ `kernel_shell.zig` compiles successfully
- ✅ All kernel files can compile
- ✅ Large stack frames handled correctly

### On Performance

**Minimal Impact**: Large stack frames will use 2-3 instructions instead of 1, but this is necessary and acceptable.

---

## Testing Strategy

### Test Cases

1. **Small Stack Frame** (< 2047 bytes)
   - Should use single `addi` instruction
   - Verify `debug.zig` still compiles

2. **Large Stack Frame** (> 2047 bytes)
   - Should use multiple instructions
   - Verify `kernel_shell.zig` compiles

3. **Edge Case** (exactly 2047 bytes)
   - Should use single `addi` instruction
   - Verify boundary condition

---

## References

- **Frame Layout Issue**: `docs/rye/0064-riscv-compiler-frame-layout-issue.md`
- **Kernel Test Results**: `docs/rye/0063-riscv-kernel-compilation-test-results.md`
- **Code Location**: `grainstore/codeberg/ryelang/rye/src/arch/riscv64/CodeGen.zig:1765, 1864`

---

**Date**: 20260122.195100.rye  
**Status**: 🔍 **INVESTIGATION** — Root cause identified, fix strategy proposed

**Next Action**: Implement Option 2 fix (change to i32, handle in codegen).
