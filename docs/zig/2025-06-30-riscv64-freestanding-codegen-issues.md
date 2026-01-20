# Zig RISC-V64 Freestanding Code Generation Issues

**Date**: 2025-06-30  
**Zig Version**: 0.15.2  
**Target**: `riscv64-freestanding-none`  
**Project**: Basin Kernel (Grain OS)

## Summary

During development of a RISC-V64 kernel, we encountered several code generation issues with Zig 0.15.2 targeting `riscv64-freestanding-none`. These issues caused the kernel to silently fail or crash, producing incorrect machine code for seemingly correct Zig source.

## Issue 1: Incorrect Global Variable Address Calculation

### Symptom
A global `bool` variable declared as:
```zig
var raw_io_enabled: bool = true;
```

Was being read from an incorrect memory address, causing conditional checks to always take the wrong branch.

### Details
- Variable was correctly placed in `.data` section at virtual address `0x800ddf28`
- The `AUIPC + ADDI` instruction sequence generated to compute this address was calculating `0x800def28` instead (off by `0x10000` / 64KB)
- This caused reads to return `0x00` (false) instead of `0x01` (true)
- Result: UART output functions silently returned early without writing

### Evidence
```
# readelf showed correct symbol address:
800ddf28  raw_io_enabled

# But disassembly of write_byte showed:
AUIPC + ADDI computing 0x800def28 (wrong by 0x10000)
```

### Workaround
Eliminated the global variable entirely. Replaced runtime checks with comptime checks:
```zig
// Before (broken):
if (!raw_io_enabled) return;

// After (working):
const builtin = @import("builtin");
if (builtin.os.tag != .freestanding) return;
```

## Issue 2: Function Calls Causing Crashes

### Symptom
Calling any function that uses `anytype` parameters or comptime string formatting would cause the kernel to crash or hang.

### Affected Patterns
- `Debug.kassert(condition, "message", .{})` - hangs even when condition is true
- `Debug.kprint("text", .{})` - generates invalid instructions
- Any function using `inline for` over runtime slices

### Evidence
```
[kernel_vm_test] Error at PC 0x80019644 ... error.invalid_instruction
[kernel_vm_test] Error at PC 0x800a8208 ... error.unaligned_instruction
```

The crash addresses were within:
- `debug.kprint` (comptime format parsing)
- `memcpy` (slice operations)
- `__atomic_compare_*` (standard library atomics)

### Workaround
Use only comptime-unrolled inline assembly for critical output:

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
    
    /// Print comptime string (unrolled at compile time).
    pub inline fn print(comptime s: []const u8) void {
        inline for (s) |c| {
            putc(c);
        }
    }
};
```

Key requirements:
- `inline fn` to avoid function call overhead
- `comptime s: []const u8` to force compile-time unrolling
- `inline for` to unroll at compile time (no runtime loop)
- Direct inline assembly for the actual store

## Issue 3: Inline Assembly Clobber Syntax

### Symptom
Zig 0.15 uses new inline assembly clobber syntax. Old syntax caused compilation errors.

### Details
```zig
// Old syntax (Zig 0.14 and earlier) - ERROR in 0.15:
asm volatile (
    \\...
    : : [byte] "r" (c),
    : "t0"  // <-- string clobber syntax rejected
);

// New syntax (Zig 0.15):
asm volatile (
    \\...
    : : [byte] "r" (c),
    : .t0,  // <-- enum-style clobber
);
```

However, omitting clobbers entirely also works if using caller-saved registers (t0-t6, a0-a7).

## Issue 4: Conditional Branch Codegen

### Symptom
Zig conditionals like `if ((lsr_val & 0x01) != 0)` were not working correctly. The LSR register was returning 0x21 (data ready), but the kernel never entered the conditional block.

### Workaround
Move the entire polling loop into inline assembly:

```zig
asm volatile (
    \\.Lwait:
    \\lui t1, 0x10000
    \\lbu t2, 5(t1)
    \\andi t2, t2, 1
    \\beqz t2, .Lwait
    \\lbu %[out], 0(t1)
    : [out] "=r" (byte),
);
```

## Working Boot Sequence

After applying all workarounds, the kernel successfully boots and runs an interactive REPL:

```
Basin Kernel v0.1.0 (RISC-V64)
Copyright (c) 2026 Team Libra

[Basin] Ready.
gs> help: h=help e=exit
gs> exit
Bye!
[Halted]
```

The REPL is implemented entirely in inline assembly to avoid all the codegen issues.
It successfully:
- Polls UART for input
- Echoes characters
- Recognizes 'h' for help and 'e' for exit
- Prints responses
- Halts cleanly on exit

## Recommendations for RISC-V Freestanding Kernels

1. **Avoid global mutable variables** in critical paths - use comptime checks instead
2. **Use inline assembly** for all early boot I/O before standard library is validated
3. **Use `comptime` parameters** with `inline for` instead of runtime loops
4. **Avoid `anytype`** in boot-critical functions
5. **Test with instruction-level tracing** in your VM/emulator to catch silent failures

## Files Modified

- `src/kernel/raw_io.zig` - Replaced volatile pointer stores with inline asm
- `src/kernel/main.zig` - Created `Uart` struct with comptime print
- `src/kernel/platform.zig` - Removed kassert calls that were hanging
- `src/kernel/debug.zig` - Updated kassert to use builtin.os.tag

## Environment

- Host: Linux x86_64
- Zig: 0.15.2
- Target: riscv64-freestanding-none
- VM: Custom RISC-V64 interpreter (Vantage)
- UART: QEMU virt machine compatible (0x10000000)

## Contact

This document was created to share with experienced Zig/RISC-V developers who may have insights into these issues or can confirm if they are known bugs.

Project: https://github.com/[your-repo]/grain-os (Basin Kernel)
