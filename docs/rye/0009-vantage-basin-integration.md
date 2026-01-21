# Vantage VM and Basin Kernel Integration

**Date**: 2025-01-21
**Status**: Implementation in Progress

---

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Framework x86_64 Host                     │
├─────────────────────────────────────────────────────────────┤
│                     Limine Bootloader                        │
├─────────────────────────────────────────────────────────────┤
│                    Vantage VM (x86_64)                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ src/vantage/main_x86_64.zig                         │    │
│  │  - Limine protocol handler                          │    │
│  │  - Framebuffer initialization                       │    │
│  │  - Memory map processing                            │    │
│  │  - Basin ELF loader                                 │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ src/vantage/riscv_core.zig                          │    │
│  │  - RV64I base instruction set                       │    │
│  │  - M extension (multiply/divide)                    │    │
│  │  - SBI console output                               │    │
│  │  - Memory read/write                                │    │
│  │  - 9/9 unit tests passing                           │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                Basin Kernel (RISC-V64)                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ src/basin/hello_riscv.zig (test kernel)             │    │
│  │  - Entry at 0x80000000                              │    │
│  │  - SBI console output                               │    │
│  │  - SBI shutdown                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ src/kernel/basin_kernel.zig (full kernel)           │    │
│  │  - Process management                               │    │
│  │  - Memory management                                │    │
│  │  - Syscall handling                                 │    │
│  │  - Scheduler                                        │    │
│  │  - Network stack                                    │    │
│  │  - Audio subsystem                                  │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ src/grainscript/interpreter.zig                     │    │
│  │  - Grainscript language runtime                     │    │
│  │  - UI built-in functions                            │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

## Current Status

### Completed

1. **Vantage VM x86_64 Entry** (`src/vantage/main_x86_64.zig`)
   - Limine boot protocol integration
   - Framebuffer initialization
   - Memory map processing
   - Basin ELF loader

2. **RISC-V64 Core** (`src/vantage/riscv_core.zig`)
   - Full RV64I instruction set
   - M extension (multiply/divide)
   - SBI console output (legacy putchar)
   - SBI system reset
   - 9/9 unit tests passing

3. **Basin Test Kernel** (`src/basin/hello_riscv.zig`)
   - Entry point at 0x80000000
   - SBI console output
   - Linker script for RISC-V kernel

4. **Build System**
   - `zig build vantage-x86_64` - Vantage VM
   - `zig build basin-rv64` - Basin test kernel
   - `./scripts/create_iso.sh` - Bootable ISO

### In Progress

1. **Vantage <-> Basin Interface**
   - Need to define syscall interface
   - Need to map framebuffer to Basin
   - Need to handle keyboard input

### Pending

1. **Full Basin Kernel for RISC-V**
   - Port `basin_kernel.zig` to freestanding RISC-V
   - Implement MMIO for Vantage devices

2. **Grainscript Integration**
   - Port interpreter to freestanding RISC-V
   - Connect UI built-ins to Vantage framebuffer

## Build Commands

```bash
# Build Vantage VM for x86_64
zig build vantage-x86_64

# Build Basin test kernel for RISC-V64
zig build basin-rv64

# Create bootable ISO
./scripts/create_iso.sh

# Test in QEMU (UEFI)
qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -cdrom vantage.iso

# Test in QEMU (BIOS)
qemu-system-x86_64 -cdrom vantage.iso
```

## SBI Interface

Basin communicates with Vantage via SBI (Supervisor Binary Interface):

| Extension ID | Function | Description |
|--------------|----------|-------------|
| 0x01 | putchar | Console output (legacy) |
| 0x02 | getchar | Console input (legacy) |
| 0x10 | base | SBI version info |
| 0x53525354 | reset | System reset/shutdown |

## Memory Map

Vantage provides Basin with:
- **RAM**: Allocated from Limine memory map (8-64MB)
- **Framebuffer**: Mapped at 0x90000000 (MMIO)
- **Keyboard**: Mapped at 0x91000000 (MMIO)

## Next Steps

1. **Phase 1: Verify Hello World**
   - Test Vantage ISO in QEMU with display
   - Verify Basin prints to framebuffer

2. **Phase 2: Add Input**
   - Implement SBI getchar
   - Map keyboard input to Basin

3. **Phase 3: Port Basin Kernel**
   - Create `src/basin/main.zig` (full kernel)
   - Implement MMIO handlers

4. **Phase 4: Grainscript Shell**
   - Port interpreter to freestanding
   - Create shell UI

## File Structure

```
src/
├── basin/                      # Basin Kernel (RISC-V64)
│   ├── hello_riscv.zig         # Test kernel
│   ├── hello_riscv.ry          # Rye version
│   └── linker_riscv64.ld       # Linker script
├── vantage/                    # Vantage VM (x86_64)
│   ├── main_x86_64.zig         # Entry point
│   ├── main_x86_64.ry          # Rye version
│   ├── riscv_core.zig          # RISC-V emulator
│   ├── riscv_core.ry           # Rye version
│   ├── riscv_core_test.zig     # Unit tests
│   └── riscv_core_test.ry      # Rye version
├── boot/                       # Boot infrastructure
│   ├── limine.zig              # Limine protocol
│   ├── limine.ry               # Rye version
│   ├── x86_64_uefi.zig         # UEFI bootloader
│   └── x86_64_drivers.zig      # Hardware drivers
└── kernel/                     # Kernel components
    ├── basin_kernel.zig        # Full kernel
    ├── grainscript_ui_bindings.zig
    └── ...
```

## Statistics

- **77 Rye modules** (19,892 lines)
- **333/333 project tests** passing
- **9/9 RISC-V core tests** passing
