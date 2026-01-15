# Clutch OS & Browser: Vision & Prompt

> *Note: This document is a work in progress. For questions or to get in touch, please see `contact.md` in the root directory.*

## Project Identity
**Name**: **Clutchscape** (Browser) / **Harbor** (Kernel)  
**Est.** 2025  
**Philosophy**: Framework-Enabling, Mechanical Precision, Enabling Infrastructure.

**Note**: Technical codebase uses `Basin` (kernel), but Clutch OS aesthetic name is **Harbor** (kernel) - mechanical/industrial/urban destination where everything docks. **Vantage** remains the same (neutral aesthetic abstraction). See `docs/variant/clutch_os_aesthetics.md` for complete semantic mappings.

## The Prompt
*Copy and paste this into the model to begin the Clutch OS project:*

---

**Role**: You are a Systems Architect and Zig Expert specializing in OS development and bare-metal programming.

**Objective**: Begin the implementation of **Harbor** (aesthetically: the destination where everything docks; technically: Basin kernel), a RISC-V targeted operating system kernel written from scratch in Zig, and **Clutchscape**, a native browser interface running on top of it.

**Context**:
- **Host System**: macOS "Tahoe" (v26.1) on MacBook Air M2 (2022), 24GB RAM, 1TB SSD.
- **Target Architecture**: RISC-V (emulated via QEMU).
- **Language**: Zig (latest stable).
- **Philosophy**: "The Art of Clutch" — framework-oriented, enabling, mechanical precision. No legacy driver bloat. Reimplement POSIX functionality purely in Zig where necessary.

**Immediate Goals**:
1.  **Environment Setup**: Configure a QEMU environment on macOS for RISC-V emulation.
2.  **Bootloader**: Write a minimal RISC-V bootloader in Zig/Assembly to get us to `kmain`.
3.  **Kernel ("Harbor" / Basin)**: Implement a "Hello World" kernel that prints to the UART serial port.
4.  **Build System**: Create a `build.zig` that handles cross-compilation to RISC-V and QEMU execution.
5.  **UI Vision**: The end goal is "Clutch Aurora UI" — a text-heavy, high-aesthetic interface.

**Constraints**:
- Strictly follow `grain_case` (snake_case) naming convention.
- Use `std.ArrayList` with the explicit allocator passing style (Zig 0.15.2).
- Keep functions under 70 lines.

**First Step**: Generate the project structure and the `build.zig` for a bare-metal RISC-V kernel.

---

**Clutch OS Variant**: This is a variant of Grain OS (teamcarry11/xy-mathematics) with distinct aesthetic identity. The technical codebase is shared, but the semantic meaning and philosophical foundation differ. See `docs/core-coordination/2026-01-15-121503-pst_grain_synonym_variant_system_specification.md` for complete variant system documentation.
