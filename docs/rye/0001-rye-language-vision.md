# Rye Language Vision

**Date**: 2025-06-30  
**Status**: Vision / Long-term  
**Relationship**: Zig-inspired, Grain OS native language

## Overview

Rye is a systems programming language designed for the Grain OS ecosystem. It draws heavily from Zig's philosophy while addressing specific needs discovered during Basin kernel development.

## Name

**Rye** - a hardy grain that grows in harsh conditions.

- One syllable
- File extension: `.ry`
- Fits the Grain family (Basin, Grain OS, Grainscript)

## Core Principles

### From Zig (Keep)
- No hidden control flow
- No hidden memory allocations  
- Compile-time evaluation (comptime)
- No garbage collector, no runtime
- Cross-compilation as first-class feature
- C interop

### From Grain Style (Add)
- 64-line function limit (enforced by compiler)
- 128-character line limit (enforced)
- Mandatory "why" comments for public functions
- 2+ assertions per function (optional lint)
- Explicit types always (no type inference for locals)

### From Our Experience (Fix)
- Rock-solid freestanding codegen (our primary target)
- Global variable addresses must be correct
- Inline assembly must work reliably with all register constraints
- Conditional branches must work with bitwise operations
- No UBSan/debug overhead for freestanding targets by default

## Target Platforms (Priority Order)

1. RISC-V 64-bit freestanding (Basin kernel)
2. x86_64 freestanding (Vantage VM, future ports)
3. AArch64 freestanding (ARM servers, phones)
4. Linux userspace (tooling)

## Relationship to Zig

**Phase 1 (Now)**: Use Zig, document bugs, contribute fixes upstream  
**Phase 2 (Future)**: Fork Zig frontend, customize for Grain Style  
**Phase 3 (Long-term)**: Native Rye compiler (self-hosting)

## Why Not Just Use Zig?

Zig is excellent. We will continue using it. But:

1. **Freestanding is not their priority** - Most Zig users target Linux/Windows/macOS
2. **Our constraints are unusual** - 64-line functions, mandatory comments
3. **Full control** - Compiler bugs in kernel code are existential risks
4. **Aesthetic alignment** - Rye can embody Grain philosophy at the syntax level

## Non-Goals (For Now)

- Competing with Zig in the general market
- Building a community around Rye (it's for us)
- Novel language features (we want boring and reliable)

## Syntax Sketch

```rye
// file: kernel/main.ry

/// Kernel entry point.
/// Why: Called by bootloader after hardware init.
pub fn kmain() noreturn {
    uart.print("Basin Kernel v0.1.0\n");
    repl.run();
    halt();
}

/// Print a character to UART.
/// Why: Direct hardware access for early boot.
fn uart_putc(c: u8) void {
    asm volatile {
        lui t1, 0x10000
        sb {c}, 0(t1)
    } : : [c] "r" (c);
}
```

Syntax is intentionally close to Zig. Differences TBD based on experience.

## Timeline

No timeline. Rye is a vision document, not a project plan. We build it when:
1. Zig bugs block us repeatedly
2. Grain Style enforcement needs compiler support
3. We have bandwidth after Basin kernel is stable

## See Also

- `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md` - Bugs that motivated this
- `docs/grain_style.md` - Coding philosophy Rye would enforce
