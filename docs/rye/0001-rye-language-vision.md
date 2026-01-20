# Rye Language Vision

**Date**: 2025-06-30  
**Status**: Phase 1 Implemented  
**Relationship**: Zig-inspired, Grain OS native language  
**Implementation**: `rye/` - Transpiler to Zig with RyeStyle validation

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

**Phase 1 (Complete)**: Rye transpiler validates `.ry` files and emits `.zig`  
**Phase 2 (Future)**: Fork Zig frontend, customize for Grain Style  
**Phase 3 (Long-term)**: Native Rye compiler (self-hosting)

### Phase 1 Implementation

The `rye/` directory contains the Phase 1 transpiler:

```bash
# Build
cd rye && zig build

# Validate RyeStyle constraints
./zig-out/bin/rye check src/*.ry

# Compile to Zig
./zig-out/bin/rye build src/main.ry
```

Features implemented (v0.4.0):
- 128-character line length enforcement
- 64-line function length enforcement
- `/// Why:` comment requirement for public functions
- Lexer with Zig-compatible tokens
- Parser for function detection with doc comment tracking
- Validator with full RyeStyle constraint checking
- Emitter (identity transform for Phase 1)
- `--json` output for CI integration
- `--summary` for aggregated reports
- **First production module**: `src/kernel/uart.ry` (UART driver)

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

- `docs/rye_style.md` - RyeStyle: the coding philosophy Rye enforces
- `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md` - Bugs that motivated Rye
- `docs/grain_style.md` - Original GrainStyle (historical, for Zig development)
