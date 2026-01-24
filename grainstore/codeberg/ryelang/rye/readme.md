# Rye

A systems programming language designed for RISC-V freestanding and the Basin kernel.

**Version**: 20260122.181925.rye

## Overview

Rye is a fork of Zig 0.15.2, adapted for:
- **RISC-V freestanding first**: Every codegen path tested against bare metal
- **Toroidal/garden types**: Bounded data structures with no edge cases
- **Rye Style enforcement**: 64-line functions, 128-char lines, mandatory "why" comments
- **Chronological versioning**: Non-semantic versioning (YYYYMMDD.HHMMSS.variant)
- **Garden allocation**: Bounded plots, not unbounded heaps

Rye is designed for the Basin kernel. The language and the kernel evolve together.

## Why Rye?

We created Rye because we need complete control over our systems language:

- **Freestanding is primary**: RISC-V64 freestanding is our target, not an afterthought
- **Compiler-enforced style**: Constraints enforced by the compiler, not lint
- **No surprises**: Global variable addresses are correct. Conditionals work. Inline assembly is reliable
- **Explicit over implicit**: No hidden control flow, no hidden memory allocations
- **Simple over easy**: Rye is simple (not intertwined) even when it's not easy (familiar)

See `THIRD_PARTY_LICENSES.md` for Zig attribution and license.

## Core Principles

### From Zig (Keep)
- No hidden control flow
- No hidden memory allocations
- Compile-time evaluation (comptime)
- No garbage collector, no runtime
- Cross-compilation as first-class feature
- C interop

### Rye Style (Add)
- 64-line function limit (enforced by compiler)
- 128-character line limit (enforced)
- Mandatory "why" comments for public functions
- 2+ assertions per function
- Explicit types always (no `usize`/`isize` inference)
- No recursion (iterative only)

### From Our Experience (Fix)
- Rock-solid freestanding codegen (our primary target)
- Global variable addresses must be correct
- Inline assembly must work reliably
- Conditional branches must work with bitwise operations
- No UBSan/debug overhead for freestanding targets by default

## Target Platforms

1. **RISC-V 64-bit freestanding** (Basin kernel) - Primary target
2. **x86_64 freestanding** (future ports)
3. **AArch64 freestanding** (ARM servers)
4. **Linux userspace** (tooling)

## Toroidal Garden Architecture

Rye and Basin share a unified architecture:

- **Toroidal data structures**: Bounded, wrap-around, no edge cases
- **Garden allocation**: Tend resources in bounded plots, not arenas
- **Tend philosophy**: Stewardship over ownership

A torus has no edges. Every point has equivalent topological relationships. In code, this means no boundary conditions, no off-by-one errors, no edge cases to forget.

## Building from Source

Ensure you have the required dependencies:

- CMake >= 3.15
- System C/C++ Toolchain
- LLVM, Clang, LLD development libraries == 20.x

Then it is the standard CMake build process:

```
mkdir build
cd build
cmake ..
make install
```

## Building from Source without LLVM

In this case, the only system dependency is a C compiler:

```
cc -o bootstrap bootstrap.c
./bootstrap
```

This produces a `rye` executable in the current working directory.

## Chronological Versioning

Rye uses **chronological versioning** instead of semantic versioning:

```
YYYYMMDD.HHMMSS.variant
20260122.181925.rye
```

This conveys:
- **When** it was released (absolute, not relative)
- **Causality** (later timestamps came after earlier ones)
- **No false promises** about compatibility

## Relationship to Zig

Rye is a fork of Zig 0.15.2. We fix RISC-V freestanding codegen bugs, add toroidal/garden types, and enforce Rye Style at the compiler level.

**We are not competing with Zig.** Rye is for the Basin kernel. Zig remains excellent for general-purpose systems programming.

## Contributing

Rye is Free and Open Source Software. We welcome bug reports and patches.

However, Rye is designed specifically for the Basin kernel. If you're building something else, Zig might be a better fit.

## License

See `LICENSE` and `THIRD_PARTY_LICENSES.md` for license information.

Rye is a fork of Zig 0.15.2 (MIT License). See `THIRD_PARTY_LICENSES.md` for full attribution.

## See Also

- `docs/rye_style.md` - RyeStyle: the coding philosophy Rye enforces
- `docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md` - Bugs that motivated Rye
- `docs/rye/0003-toroidal-garden-architecture.md` - Toroidal/garden architecture vision

---

**Rye**: A hardy grain that grows in harsh conditions.
