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
│  │  - RV64I + RVC + M extension                        │    │
│  │  - SBI console I/O (putchar/getchar)                │    │
│  │  - Input buffer (256-byte ring)                     │    │
│  │  - Memory read/write                                │    │
│  │  - 12/12 unit tests passing                         │    │
│  └─────────────────────────────────────────────────────┘    │
├─────────────────────────────────────────────────────────────┤
│                Basin Kernel (RISC-V64)                       │
│  ┌─────────────────────────────────────────────────────┐    │
│  │ src/basin/hello_riscv.zig (REPL kernel)             │    │
│  │  - Entry at 0x80000000                              │    │
│  │  - Interactive command shell                        │    │
│  │  - Commands: h=help, f=fib, q=quit                  │    │
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
   - RVC compressed instructions (16-bit)
   - M extension (multiply/divide)
   - SBI console I/O (putchar/getchar)
   - SBI system reset
   - Input buffer (256-byte ring buffer)
   - 12/12 unit tests passing

3. **Basin REPL Kernel** (`src/basin/hello_riscv.zig`)
   - Entry point at 0x80000000
   - Interactive command shell
   - Commands: h=help, f=fib, e=expr (calculator with variables), q=quit
   - Expression evaluator with variable support:
     - Arithmetic: +, -, *, /, parentheses, negative numbers
     - Variable assignment: `x = 5`
     - Variable usage: `x * 2`, `x + 10`
     - Up to 32 variables with 16-char names
   - SBI console I/O
   - Linker script for RISC-V kernel
   - Version: v0.4

4. **Integration Test** (`src/vantage/basin_integration_test.zig`)
   - Loads Basin ELF binary
   - Sends keyboard input to VM
   - Captures console output
   - Verifies REPL functionality

5. **Build System**
   - `zig build vantage-x86_64` - Vantage VM
   - `zig build basin-rv64` - Basin REPL kernel
   - `./scripts/create_iso.sh` - Bootable ISO

### In Progress

1. **Grainscript Integration**
   - Port interpreter to freestanding RISC-V
   - Connect UI built-ins to Vantage framebuffer

### Pending

1. **Full Basin Kernel for RISC-V**
   - Port `basin_kernel.zig` to freestanding RISC-V
   - Implement MMIO for Vantage devices

2. **Direct Framebuffer Access**
   - Map framebuffer to Basin via MMIO
   - Enable graphical UI from Basin

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

1. **Phase 1: Test in QEMU** (current)
   - Test Vantage ISO in QEMU with display
   - Verify Basin REPL works on real framebuffer
   - Test expression evaluator (`e` command)

2. **Phase 2: Grainscript Interpreter**
   - Port interpreter to freestanding RISC-V
   - Replace std.mem.Allocator with static allocation
   - Add REPL command to launch Grainscript

3. **Phase 3: Framebuffer Access**
   - Map framebuffer to Basin via MMIO
   - Implement pixel drawing from Basin

4. **Phase 4: Full Basin Kernel**
   - Port process/memory management
   - Implement syscall interface

## File Structure

```
src/
├── basin/                      # Basin Kernel (RISC-V64)
│   ├── hello_riscv.zig         # REPL kernel
│   ├── hello_riscv.ry          # Rye version
│   └── linker_riscv64.ld       # Linker script
├── vantage/                    # Vantage VM (x86_64)
│   ├── main_x86_64.zig         # Entry point
│   ├── main_x86_64.ry          # Rye version
│   ├── riscv_core.zig          # RISC-V emulator
│   ├── riscv_core.ry           # Rye version
│   ├── riscv_core_test.zig     # Unit tests
│   ├── riscv_core_test.ry      # Rye version
│   ├── basin_integration_test.zig  # Integration test
│   └── basin_integration_test.ry   # Rye version
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

- **78 Rye modules** (20,745 lines)
- **333/333 project tests** passing
- **12/12 RISC-V core tests** passing
- **1/1 integration test** passing
- **Basin REPL v0.4** with expression evaluator and variable support
