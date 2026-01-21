# Basin Kernel Running Instructions

**Date**: 2026-01-21  
**Status**: Ready to Run  
**Version**: Basin REPL v0.4

---

## Overview

Basin is a **RISC-V64 kernel** that runs on **Vantage VM** (x86_64 host). Currently, Basin provides a **text-based CLI REPL** via SBI console I/O.

**Architecture**:
```
Framework x86_64 Host
  └─> Vantage VM (x86_64, boots via Limine)
      └─> Basin Kernel (RISC-V64, emulated)
          └─> REPL Shell (text-based CLI)
```

---

## Quick Start: Test Basin in Integration Test (Easiest)

**This is the fastest way to verify Basin works without booting:**

```bash
# 1. Build Basin kernel
cd /home/xy/ry
zig build basin-rv64

# 2. Run integration test (tests Basin REPL)
zig test src/vantage/basin_integration_test.zig --mod riscv_core:src/vantage/riscv_core.zig
```

**What this does**:
- Loads Basin ELF into RISC-V VM memory
- Sends test commands (`h`, `f`, `f`, `f`, `q`)
- Captures console output
- Verifies REPL functionality

**Expected output**: Test passes, showing Basin REPL commands work.

---

## Full Boot: Run Basin in QEMU (CLI/Text Mode)

**This boots Vantage VM in QEMU and runs Basin with a text console:**

### Prerequisites

1. **QEMU** installed:
   ```bash
   # Ubuntu/Debian
   sudo apt install qemu-system-x86_64
   
   # Verify
   qemu-system-x86_64 --version
   ```

2. **OVMF (UEFI firmware)** - Optional, for UEFI boot:
   ```bash
   # Ubuntu/Debian
   sudo apt install ovmf
   ```

### Build Steps

```bash
# Navigate to project root
cd /home/xy/ry

# 1. Build Basin kernel (RISC-V64)
zig build basin-rv64

# 2. Build Vantage VM (x86_64 bootloader)
zig build vantage-x86_64

# 3. Create bootable ISO
./scripts/create_iso.sh
```

**Build outputs**:
- `zig-out/bin/basin-rv64` - Basin kernel ELF (RISC-V64)
- `zig-out/bin/vantage` - Vantage VM bootloader (x86_64)
- `vantage.iso` - Bootable ISO (created by script)

### Run in QEMU

**Option 1: BIOS Boot (Simpler)**
```bash
qemu-system-x86_64 -cdrom vantage.iso -serial stdio
```

**Option 2: UEFI Boot (More modern)**
```bash
qemu-system-x86_64 \
  -bios /usr/share/ovmf/OVMF.fd \
  -cdrom vantage.iso \
  -serial stdio
```

**QEMU Options Explained**:
- `-cdrom vantage.iso` - Boot from ISO
- `-serial stdio` - **Important**: Redirects serial console to terminal (for Basin REPL)
- `-bios /usr/share/ovmf/OVMF.fd` - UEFI firmware (optional)

### Using Basin REPL

Once booted, you'll see:
```
Basin Kernel v0.4
Commands: h=help f=fib e=expr q=quit
  expr supports: +, -, *, /, (), variables (x=5, x*2)
> 
```

**Available Commands**:
- `h` - Show help
- `f` - Compute Fibonacci numbers
- `e` - Expression evaluator with variables
  - Examples: `2+3*4`, `x=5`, `x*2`, `(x+y)*2`
- `q` - Quit (shuts down kernel)

**Example Session**:
```
> e
Enter expression or assignment (e.g., 2+3*4 or x=5): x = 10
x = 10
> e
Enter expression or assignment (e.g., 2+3*4 or x=5): y = 5
y = 5
> e
Enter expression or assignment (e.g., 2+3*4 or x=5): x * y
= 50
> f
fib(0)=0
> q
Goodbye!
```

---

## Current Status: CLI/Text Mode

**Yes, we're booting in CLI form first.**

Basin currently uses:
- **SBI console I/O** (`putchar`/`getchar`) for text input/output
- **Serial console** (via QEMU `-serial stdio`) for terminal interaction
- **No graphics yet** - framebuffer access is planned for Phase 3

**Why CLI first?**
1. ✅ Simpler to implement and test
2. ✅ Works via integration tests (no QEMU needed)
3. ✅ Foundation for future graphics support
4. ✅ REPL is fully functional for scripting

---

## Troubleshooting

### Integration Test Fails

**Error**: `Failed to open basin-rv64: FileNotFound`

**Fix**: Build Basin first:
```bash
zig build basin-rv64
```

### QEMU Boot Issues

**Error**: `qemu-system-x86_64: command not found`

**Fix**: Install QEMU:
```bash
sudo apt install qemu-system-x86_64
```

**Error**: ISO not found

**Fix**: Create ISO:
```bash
./scripts/create_iso.sh
```

**No output in terminal**:

**Fix**: Make sure you use `-serial stdio`:
```bash
qemu-system-x86_64 -cdrom vantage.iso -serial stdio
```

### Basin REPL Not Responding

- Check that serial console is redirected (`-serial stdio`)
- Try typing `h` and pressing Enter
- Verify Basin kernel loaded (check boot messages)

---

## Next Steps

### Phase 1: Current (CLI/Text) ✅
- Basin REPL with text console
- Expression evaluator with variables
- Integration tests

### Phase 2: Grainscript Interpreter
- Port Grainscript to freestanding RISC-V
- Add `g` command to launch Grainscript

### Phase 3: Framebuffer Access
- Map framebuffer to Basin via MMIO
- Enable pixel drawing from Basin
- Graphical UI support

### Phase 4: Full Basin Kernel
- Process management
- Memory management
- Syscall interface

---

## File Locations

- **Basin Kernel**: `/home/xy/ry/src/basin/hello_riscv.zig`
- **Vantage VM**: `/home/xy/ry/src/vantage/main_x86_64.zig`
- **RISC-V Core**: `/home/xy/ry/src/vantage/riscv_core.zig`
- **Integration Test**: `/home/xy/ry/src/vantage/basin_integration_test.zig`
- **Build Output**: `/home/xy/ry/zig-out/bin/`
- **ISO Script**: `/home/xy/ry/scripts/create_iso.sh`

---

## Quick Reference

```bash
# Test Basin (fastest)
cd /home/xy/ry
zig build basin-rv64
zig test src/vantage/basin_integration_test.zig --mod riscv_core:src/vantage/riscv_core.zig

# Full boot in QEMU
cd /home/xy/ry
zig build basin-rv64
zig build vantage-x86_64
./scripts/create_iso.sh
qemu-system-x86_64 -cdrom vantage.iso -serial stdio
```

---

**Ready to run!** Start with the integration test, then try full boot in QEMU. 🚀
