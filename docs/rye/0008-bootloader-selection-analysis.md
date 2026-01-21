# Bootloader Selection Analysis for Vantage VM

**Date**: 2026-01-21
**Status**: Decision Document
**Author**: AI Agent (research-assisted)

---

## Architecture Clarification

**Basin Kernel** targets **RISC-V only**. No Basin/Grain code targets x86_64 directly.

**Vantage VM** is the virtualization layer that:
1. Boots on x86_64 host (Framework laptop) via Limine
2. Loads Basin kernel (RISC-V ELF)
3. Emulates RISC-V64 to run Basin
4. Provides hardware abstraction (framebuffer, input, etc.)

This document analyzes bootloaders for **Vantage VM on x86_64**, not Basin directly.

---

## Executive Summary

After analyzing available bootloaders for x86_64, we recommend **Limine** as the bootloader for Vantage VM on Framework x86_64. This document explains the rationale based on Rye Style compatibility, toroidal architecture alignment, and practical considerations.

---

## Bootloader Landscape

### Available Options

| Bootloader | License | Architectures | Protocol | Zig Ecosystem |
|------------|---------|---------------|----------|---------------|
| **Limine** | BSD-2-Clause | x86, x86_64, aarch64, riscv64 | Native + Multiboot | Used by Zig OSes |
| **BOOTBOOT** | MIT | x86_64, aarch64, riscv64 | Native | Zig example kernel |
| **GRUB** | GPL | x86, x86_64, others | Multiboot 1/2 | Common but complex |
| **Custom UEFI** | N/A | x86_64 | UEFI | Our src/boot/*.zig |

### Zig-Based OS Projects

Several successful Zig operating systems have been built:

1. **Zen** (github.com/AndreaOrru/zen) - 515 stars
   - Experimental OS in Zig
   - Uses custom bootloader approach
   - x86_64 focused

2. **Pluto/ZystemOS** (github.com/ZystemOS/pluto) - 701 stars
   - x86 kernel in Zig
   - Uses GRUB with Multiboot
   - Most mature Zig OS project

3. **UEFI Examples** (github.com/nrdmn/uefi-examples) - 77 stars
   - Pure Zig UEFI applications
   - Demonstrates Zig's native UEFI support

---

## Why Limine for Basin Kernel

### 1. Rye Style Compatibility

Limine's design philosophy aligns with Rye Style principles:

| Rye Style Principle | Limine Alignment |
|---------------------|------------------|
| **Explicit types** | Request-based protocol with explicit structures |
| **Static allocation** | All boot info in fixed-size structures |
| **No hidden allocations** | Kernel receives pre-allocated memory map |
| **Comprehensive assertions** | Protocol version checking built-in |
| **Deterministic behavior** | Same boot sequence every time |

The Limine protocol uses a **request-response model**:

```c
// Request structure (explicit, statically allocated)
__attribute__((used, section(".limine_requests")))
static volatile struct limine_framebuffer_request framebuffer_request = {
    .id = LIMINE_FRAMEBUFFER_REQUEST_ID,
    .revision = 0
};

// Response is a pointer to bootloader-filled struct
struct limine_framebuffer *fb = framebuffer_request.response->framebuffers[0];
```

This maps directly to Zig/Rye's explicit typing:

```zig
// Rye Style: Explicit request structure
const framebuffer_request = limine.FramebufferRequest{
    .id = limine.FRAMEBUFFER_REQUEST_ID,
    .revision = 0,
};

// Response with explicit types
const fb: *limine.Framebuffer = framebuffer_request.response.?.framebuffers[0];
```

### 2. Toroidal Architecture Alignment

Basin kernel uses a **toroidal DAG** for UI and syscall routing. Limine's boot protocol supports this:

| Toroidal Feature | Limine Support |
|------------------|----------------|
| **Framebuffer access** | Direct linear framebuffer with pitch/format info |
| **Memory mapping** | Higher-half kernel with identity-mapped physmem |
| **Multi-core boot** | All cores start executing kernel simultaneously |
| **Module loading** | Initial ramdisk with Grainscript shell |

The higher-half mapping (kernel at 0xffffffff80000000+) is ideal for Basin's memory model:
- User space: 0x0 - 0x00007fffffffffff (lower half)
- Kernel space: 0xffff800000000000+ (higher half)
- Toroidal buffers can use identity-mapped physical memory

### 3. Syscall Interface Compatibility

Limine provides everything needed for Basin's syscall table:

```
Basin Syscall Categories → Limine Boot Info
─────────────────────────────────────────────
Process (spawn/exit)    → Memory map for page allocation
File I/O                → Initial ramdisk (initrd) module
Network                 → (kernel responsibility after boot)
UI (framebuffer)        → Framebuffer request/response
Audio                   → (kernel responsibility after boot)
```

### 4. Multi-Architecture Support

Limine supports all architectures Basin targets:

| Architecture | Limine | Basin Status |
|--------------|--------|--------------|
| x86_64 | ✅ UEFI + BIOS | Primary target (Framework) |
| riscv64 | ✅ UEFI | Current VM target |
| aarch64 | ✅ UEFI | Future (Apple Silicon) |

### 5. Practical Advantages

- **No assembly required**: Kernel entry is a C/Zig function
- **Prebuilt binaries**: `git clone --branch=v10.x-binary`
- **ISO and disk image support**: Works with QEMU and real hardware
- **Active maintenance**: Regular releases, responsive community
- **Simple configuration**: Single `limine.conf` file

---

## Comparison: Limine vs BOOTBOOT vs Custom UEFI

### BOOTBOOT

**Pros:**
- MIT license (same as Basin)
- Zig example kernel included
- Simpler than Limine (single protocol)

**Cons:**
- Less flexible memory model
- Fixed kernel load address
- Smaller community
- Author has interpersonal conflicts with OSDev community

### Custom UEFI (our src/boot/x86_64_uefi.zig)

**Pros:**
- Full control
- Pure Rye Style implementation
- No external dependencies

**Cons:**
- Significant development effort for production quality
- Need to handle ACPI, memory map, etc.
- Testing burden on multiple hardware configurations
- Bootloader is infrastructure, not the novel part of Basin

### Decision: Limine

Limine provides the best balance of:
1. Rye Style compatibility (explicit, static, deterministic)
2. Toroidal architecture support (framebuffer, memory map)
3. Development velocity (focus on kernel, not bootloader)
4. Multi-architecture path (x86_64 now, riscv64/aarch64 later)

---

## Implementation Plan

### Phase 1: Limine Integration for Vantage

1. Create `limine.zig` header (translate limine.h) ✅
2. Create `src/vantage/main_x86_64.zig` with Limine entry
3. Create `linker_x86_64.ld` for higher-half Vantage ✅
4. Add `limine.conf` for boot configuration ✅
5. Add build target `zig build vantage-x86_64`

### Phase 2: Vantage VM Integration

1. Initialize RISC-V emulator from Vantage entry
2. Load Basin kernel (RISC-V ELF) from initrd module
3. Map host framebuffer to Basin's MMIO region
4. Start RISC-V execution loop

### Phase 3: Bootable Image

1. Create `scripts/create_iso.sh` using Limine tools ✅
2. Include Basin kernel as Limine module
3. Test in QEMU with UEFI and BIOS
4. Document boot process

### Phase 4: Hardware Testing

1. Create bootable USB image
2. Test on Framework laptop
3. Document any hardware-specific issues

---

## Limine Protocol Quick Reference

### Required Requests

```zig
// Base revision (required for all kernels)
const base_revision = limine.BaseRevision{ .revision = 3 };

// Framebuffer (for Basin UI)
const framebuffer_request = limine.FramebufferRequest{};

// Memory map (for page allocator)
const memmap_request = limine.MemmapRequest{};

// HHDM (higher-half direct map) for physmem access
const hhdm_request = limine.HhdmRequest{};

// Kernel address (for self-reference)
const kernel_address_request = limine.KernelAddressRequest{};
```

### Kernel Entry

```zig
export fn _start() callconv(.C) noreturn {
    // Verify base revision
    if (!base_revision.is_supported()) {
        halt();
    }

    // Access framebuffer
    if (framebuffer_request.response) |response| {
        const fb = response.framebuffers()[0];
        // fb.address, fb.width, fb.height, fb.pitch available
    }

    // Initialize Basin kernel
    basin_kernel.init();

    halt();
}
```

---

## Preserving Custom UEFI Work

The code in `src/boot/x86_64_uefi.zig` and `src/boot/x86_64_drivers.zig` is not wasted:

1. **Documentation value**: Shows understanding of UEFI boot process
2. **Driver reference**: Serial, keyboard, timer drivers work post-boot
3. **Future option**: Could become standalone bootloader if needed
4. **Test infrastructure**: QEMU script works for any x86_64 kernel

---

## Conclusion

**Recommendation**: Use Limine as the bootloader for Basin kernel on x86_64.

**Rationale**:
1. Request-based protocol matches Rye Style's explicit typing
2. Higher-half kernel support aligns with toroidal memory model
3. Multi-architecture support matches Basin's RISC-V/x86_64/ARM64 goals
4. Active community and prebuilt binaries accelerate development
5. Proven in Zig ecosystem (multiple Zig OSes use it successfully)

The focus should be on proving Basin kernel works, not reinventing bootloaders. Limine is production-quality infrastructure that lets us concentrate on the novel parts of the system.

---

## References

1. Limine Protocol Specification: https://github.com/limine-bootloader/limine/blob/trunk/PROTOCOL.md
2. OSDev Wiki - Limine: https://wiki.osdev.org/Limine
3. OSDev Wiki - Limine Bare Bones: https://wiki.osdev.org/Limine_Bare_Bones
4. ZystemOS/Pluto (Zig kernel): https://github.com/ZystemOS/pluto
5. Zen (Zig OS): https://github.com/AndreaOrru/zen
6. UEFI Examples in Zig: https://github.com/nrdmn/uefi-examples
