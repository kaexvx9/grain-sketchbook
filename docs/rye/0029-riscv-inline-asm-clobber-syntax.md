# RISC-V Inline Assembly Clobber Syntax: Documentation

**Date**: 20260122.185500.rye  
**Status**: ✅ **DOCUMENTATION** — Issue 4: Inline Assembly Clobber Syntax  
**Issue**: Zig 0.15 changed inline assembly clobber syntax (breaking change)

---

## Problem Summary

Zig 0.15 changed inline assembly clobber syntax (breaking change).  
**Old syntax**: `: "t0"` (string)  
**New syntax**: `: .t0` (enum-style)

This is a documentation and error message issue - the syntax change is correct, but needs to be clearly documented.

---

## Syntax Change

### Old Syntax (Zig 0.14 and earlier) - ❌ **ERROR in Rye/Zig 0.15**

```zig
asm volatile (
    "instruction"
    : [output] "=r" (output)
    : [input] "r" (input)
    : "t0", "t1"  // ❌ String clobbers - ERROR
);
```

**Error**: Compiler will reject string clobbers with an error message.

### New Syntax (Rye/Zig 0.15+) - ✅ **CORRECT**

```rye
asm volatile (
    "instruction"
    : [output] "=r" (output)
    : [input] "r" (input)
    : .t0, .t1  // ✅ Enum-style clobbers
);
```

**Correct**: Enum-style clobbers using register names as enum values.

---

## RISC-V Register Names

**Available Clobber Registers** (enum-style):
- `.zero` - Zero register (x0)
- `.ra` - Return address (x1)
- `.sp` - Stack pointer (x2)
- `.gp` - Global pointer (x3)
- `.tp` - Thread pointer (x4)
- `.t0` through `.t6` - Temporary registers (x5-x7, x28-x31)
- `.s0` through `.s11` - Saved registers (x8-x9, x18-x27)
- `.a0` through `.a7` - Argument registers (x10-x17)

**Common Usage**:
```rye
// Clobber temporary registers
: .t0, .t1

// Clobber argument registers
: .a0, .a1

// Clobber memory (all registers)
: .memory
```

---

## Examples

### Example 1: UART Output (RISC-V)

```rye
/// Why: Output byte to UART using inline assembly.
pub fn uart_putc(byte: u8) void {
    asm volatile (
        \\lui t1, 0x10000
        \\sb %[byte], 0(t1)
        :
        : [byte] "r" (byte)
        : .t1  // ✅ Enum-style clobber
    );
}
```

### Example 2: Memory Barrier

```rye
/// Why: Memory barrier using inline assembly.
pub fn memory_barrier() void {
    asm volatile (
        "fence iorw, iorw"
        :
        :
        : .memory  // ✅ Clobber memory
    );
}
```

### Example 3: System Call

```rye
/// Why: Make system call using inline assembly.
pub fn syscall(num: u64, arg1: u64, arg2: u64, arg3: u64) u64 {
    var result: u64 = undefined;
    asm volatile (
        \\ecall
        : [result] "={a0}" (result)
        : [num] "{a7}" (num),
          [arg1] "{a0}" (arg1),
          [arg2] "{a1}" (arg2),
          [arg3] "{a2}" (arg3)
        : .a0, .a1, .a2, .a7  // ✅ Clobber argument registers
    );
    return result;
}
```

---

## Migration Guide

### Step 1: Identify Old Syntax

**Look for**:
```zig
: "t0", "t1"  // String clobbers
```

### Step 2: Convert to New Syntax

**Change to**:
```rye
: .t0, .t1  // Enum-style clobbers
```

### Step 3: Verify

**Check**:
- Compiler accepts new syntax
- No compilation errors
- Functionality preserved

---

## Error Messages

**Current Error** (if using old syntax):
```
error: expected enum-style clobber, found string
```

**Recommended Error Message** (for Rye):
```
error: inline assembly clobber syntax changed in Zig 0.15
  old syntax: : "t0", "t1"  (string clobbers)
  new syntax:  : .t0, .t1   (enum-style clobbers)
  
  help: change string clobbers to enum-style clobbers
```

---

## Implementation Notes

**Location**: `src/Sema.zig` - Clobber resolution (lines 16387-16391)

**Current Behavior**:
- Clobbers are resolved as struct values
- Enum-style clobbers are already supported
- String clobbers should be rejected with helpful error

**Future Enhancement**:
- Add helpful error message for old syntax
- Provide migration suggestions
- Document in Rye language reference

---

## References

- **Issue Document**: `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md`
- **Fix Strategy**: `docs/rye/0013-riscv-freestanding-fix-strategy.md`
- **Zig 0.15 Release Notes**: Inline assembly clobber syntax change

---

## Status

**Current**: ✅ Syntax change is correct and working  
**Action Needed**: 
- Document new syntax clearly
- Add helpful error messages for old syntax
- Create migration guide

---

**Date**: 20260122.185500.rye  
**Status**: ✅ **DOCUMENTATION** — Syntax is correct, documentation needed
