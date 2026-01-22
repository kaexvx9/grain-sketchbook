# Build, Run, and Test Guide

**Date**: 2026-01-21-194401-pst  
**Status**: ✅ **READY** — Complete instructions for building, running, and testing Grain OS  
**Version**: Basin 20260121.194401.basin, Vantage 20260121.194401.vantage

---

## Quick Start

**Fastest way to verify everything works:**

```bash
cd /home/xy/ry

# Build Basin kernel (RISC-V64)
zig build basin-rv64

# Run integration test (no QEMU needed)
zig test src/vantage/basin_integration_test.zig --mod riscv_core:src/vantage/riscv_core.zig
```

**Expected**: Test passes, showing Basin REPL is functional.

---

## Prerequisites

### Required Software

**Zig Compiler** (0.15.2 or later):
```bash
# Download from https://ziglang.org/download/
# Or use package manager:
# Ubuntu/Debian: Download .tar.xz and extract to /usr/local
# macOS: brew install zig
```

**QEMU** (for full boot testing):
```bash
# Ubuntu/Debian
sudo apt install qemu-system-x86_64

# macOS
brew install qemu

# Verify
qemu-system-x86_64 --version
```

**Optional: UEFI Firmware** (for UEFI boot):
```bash
# Ubuntu/Debian
sudo apt install ovmf

# macOS (via Homebrew)
brew install qemu
# OVMF usually included with QEMU
```

**ISO Creation Tools**:
```bash
# Ubuntu/Debian
sudo apt install xorriso

# macOS
brew install xorriso
```

### Environment Setup

```bash
# Clone repository (if not already done)
git clone https://codeberg.org/teamlibra/ry.git
cd ry

# Verify Zig is in PATH
zig version  # Should show 0.15.2 or later
```

---

## Architecture Overview

**Grain OS uses a two-layer architecture with bottom-up development:**

```
Framework x86_64 Host (Development Machine)
  └─> Vantage VM (x86_64, boots via Limine) [Bottom-Up: Foundation]
      └─> Basin Kernel (RISC-V64, emulated) [Bottom-Up: Foundation]
          └─> REPL Shell / Grainscript
          
Future Integration:
  └─> Skate Desktop (x86_64 Linux userspace) [Top-Down: Applications]
      └─> Uses Basin/Vantage foundation indirectly
```

**Development Strategy**:
- **Bottom-Up (Vantage 3 Subcore)**: Basin kernel, Vantage VM, foundation layers
- **Top-Down (Core 1 Subcore)**: Skate desktop, Skate mobile, application layers
- **Integration**: Applications initially run as userspace on Linux (indirect foundation use)
- **Future**: Applications can run inside Basin kernel (direct integration)

**Key Principle**: 
- **Basin** targets **RISC-V only** (`src/basin/`, `src/kernel/`)
- **Vantage** handles **x86_64 only** (`src/vantage/`, `src/kernel_vm/`)
- See `docs/architecture/basin_vantage_architecture_constraints.md` for details
- See `docs/agent-communications/l1-subcores/vantage_3_subcore/prompts/2026-01-22-062000-pst_vantage_3_subcore_bottom_up_coordination_prompt.md` for coordination strategy

---

## Building

### Build Targets

**Basin Kernel (RISC-V64)**:
```bash
zig build basin-rv64
```
- **Output**: `zig-out/bin/basin-rv64` (RISC-V64 ELF)
- **Target**: `riscv64-freestanding-none`
- **Purpose**: RISC-V kernel that runs in Vantage VM

**Vantage VM (x86_64)**:
```bash
zig build vantage-x86_64
```
- **Output**: `zig-out/bin/vantage` (x86_64 ELF)
- **Target**: `x86_64-freestanding` (Limine boot protocol)
- **Purpose**: VM host that emulates RISC-V64 to run Basin

**Build Both**:
```bash
zig build basin-rv64 vantage-x86_64
```

### Build Options

**Debug Build** (default):
```bash
zig build basin-rv64 -Doptimize=Debug
```

**Release Build** (smaller, faster):
```bash
zig build basin-rv64 -Doptimize=ReleaseSmall
```

**All Build Steps**:
```bash
# List all available build steps
zig build --help

# Common steps:
zig build basin-rv64          # Basin kernel (RISC-V64)
zig build vantage-x86_64       # Vantage VM (x86_64)
zig build test                # Run all tests
```

---

## Running

### Option 1: Integration Test (Fastest - No QEMU)

**Best for**: Quick verification, CI/CD, development

```bash
cd /home/xy/ry

# 1. Build Basin kernel
zig build basin-rv64

# 2. Run integration test
zig test src/vantage/basin_integration_test.zig --mod riscv_core:src/vantage/riscv_core.zig
```

**What it does**:
- Loads Basin ELF into RISC-V VM memory
- Sends test commands (`h`, `f`, `e`, `q`)
- Captures console output
- Verifies REPL functionality

**Expected output**: Test passes with REPL command verification.

---

### Option 2: Full Boot in QEMU (Interactive)

**Best for**: Interactive testing, debugging, development

#### Step 1: Build Components

```bash
cd /home/xy/ry

# Build both components
zig build basin-rv64      # Basin kernel (RISC-V64)
zig build vantage-x86_64  # Vantage VM (x86_64)
```

#### Step 2: Create Bootable ISO

```bash
# Create ISO with Limine bootloader
./scripts/create_iso.sh
```

**What this does**:
- Builds Vantage VM and Basin kernel (if not already built)
- Downloads/clones Limine bootloader (if needed)
- Creates `vantage.iso` with both binaries
- Configures Limine boot protocol

**Output**: `vantage.iso` in project root

#### Step 3: Boot in QEMU

**BIOS Boot** (simpler):
```bash
qemu-system-x86_64 -cdrom vantage.iso -serial stdio
```

**UEFI Boot** (more modern):
```bash
qemu-system-x86_64 \
  -bios /usr/share/ovmf/OVMF.fd \
  -cdrom vantage.iso \
  -serial stdio
```

**QEMU Options**:
- `-cdrom vantage.iso` - Boot from ISO
- `-serial stdio` - **Critical**: Redirects serial console to terminal (for Basin REPL)
- `-bios /usr/share/ovmf/OVMF.fd` - UEFI firmware (optional, for UEFI boot)
- `-m 512M` - Memory size (optional, default is usually fine)
- `-smp 2` - CPU cores (optional)

#### Step 4: Use Basin REPL

Once booted, you'll see:
```
Basin Kernel 20260121.194401.basin
Commands: h=help f=fib e=expr v=vars c=clear q=quit
  expr supports: +, -, *, /, (), variables (x=5, x*2)
> 
```

**Available Commands**:
- `h` - Show help
- `f` - Compute Fibonacci numbers
- `e` - Expression evaluator with variables
  - Examples: `2+3*4`, `x=5`, `x*2`, `(x+y)*2`
- `v` - List all defined variables
- `c` - Clear all variables
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
> v
Variables:
  x = 10
  y = 5
> f
fib(0)=0
> q
Goodbye!
```

---

### Option 3: Run on Real Hardware

**For Framework x86_64 or other x86_64 machines:**

1. **Create ISO** (as above):
   ```bash
   ./scripts/create_iso.sh
   ```

2. **Write to USB**:
   ```bash
   # Find USB device (e.g., /dev/sdb)
   lsblk
   
   # Write ISO to USB (WARNING: This will erase the USB!)
   sudo dd if=vantage.iso of=/dev/sdb bs=4M status=progress oflag=sync
   ```

3. **Boot from USB**:
   - Boot machine from USB
   - Vantage VM will boot and run Basin kernel
   - Serial console output depends on hardware configuration

---

## Testing

### Run All Tests

```bash
# Run all tests
zig build test

# Run with summary
zig build test --summary all

# Run specific test
zig build test --test-filter test_name
```

### Test Categories

**Unit Tests**:
- RISC-V core tests: `src/vantage/riscv_core_test.zig`
- Basin integration: `src/vantage/basin_integration_test.zig`

**Integration Tests**:
- End-to-end: `tests/164_end_to_end_integration_test.zig`
- Framework x86: `tests/169_framework_x86_full_stack_test.zig`
- Basin/Grainscript: `tests/165_basin_grainscript_integration_test.zig`

**Kernel Tests**:
- Kernel integration: `tests/014_kernel_integration_test.zig`
- Process scheduler: `tests/022_process_scheduler_test.zig`
- Memory allocator: `tests/027_memory_allocator_test.zig`

### Run Specific Test Files

```bash
# Run Basin integration test
zig test src/vantage/basin_integration_test.zig --mod riscv_core:src/vantage/riscv_core.zig

# Run RISC-V core tests
zig test src/vantage/riscv_core_test.zig --mod riscv_core:src/vantage/riscv_core.zig

# Run specific test file
zig test tests/164_end_to_end_integration_test.zig
```

### Test Framework x86_64

**For Framework 16 (x86_64 AMD) testing**:

```bash
# Run Framework x86_64 test suite
./scripts/run_framework_x86_64_tests.sh

# Or manually
zig build test --test-filter framework_x86
```

---

## Rye Style Compliance Testing

**Important**: All Basin/Vantage code must follow Rye Style. This is a mandatory requirement for foundation work.

### Rye Style Requirements

**Core Constraints**:
1. **Function Length**: ≤ 64 lines (compiler-enforced)
2. **Line Length**: ≤ 128 characters (compiler-enforced)
3. **Why Comments**: Required for all `pub fn` functions
4. **Explicit Types**: Use `u32`/`u64` instead of `usize`/`isize`
5. **Assertions**: Minimum 2 assertions per function
6. **No Recursion**: Convert all recursive functions to iterative

### Validate Rye Style Compliance

**For Rye Files (.ry)**:
```bash
# Build Rye compiler (if not already built)
cd rye && zig build

# Check Rye files for compliance
./zig-out/bin/rye check src/basin/*.ry
./zig-out/bin/rye check src/vantage/*.ry
./zig-out/bin/rye check src/kernel/*.ry
```

**For Zig Files (.zig)**:
```bash
# Validate kernel code (Grain Style: 64 lines, 128 chars)
zig run tools/validate_kernel.zig

# Validate source code
zig run tools/validate_src.zig

# Validate VM code
zig run tools/validate_vm.zig
```

**Manual Review Checklist**:
- [ ] All functions ≤ 64 lines
- [ ] All lines ≤ 128 characters
- [ ] All `pub fn` have "why" comments
- [ ] All types are explicit (u32/u64, not usize/isize)
- [ ] All functions have 2+ assertions
- [ ] No recursive functions (iterative only)

### Rye Style Testing Workflow

**Before Committing**:
```bash
# 1. Build and test functionality
zig build basin-rv64
zig test src/vantage/basin_integration_test.zig --mod riscv_core:src/vantage/riscv_core.zig

# 2. Validate Rye Style compliance
./rye/zig-out/bin/rye check src/basin/*.ry src/vantage/*.ry 2>/dev/null || echo "No .ry files to check"
zig run tools/validate_kernel.zig

# 3. Run all tests
zig build test

# 4. Commit only if all checks pass
```

**Continuous Validation**:
- Run Rye Style validation as part of your development workflow
- Fix violations immediately (don't accumulate technical debt)
- Use validation tools before committing

### Rye Style Violations

**Common Issues**:
- Functions over 64 lines → Extract helper functions
- Lines over 128 characters → Break into multiple lines
- Missing "why" comments → Add documentation
- Using `usize`/`isize` → Use explicit `u32`/`u64`
- Recursive functions → Convert to iterative with stack

**Fixing Violations**:
1. Identify violation (function length, line length, etc.)
2. Refactor to meet constraints
3. Re-run validation
4. Verify tests still pass
5. Commit with Rye Style compliance verified

---

## Troubleshooting

### Build Issues

**Error**: `zig: command not found`
- **Fix**: Install Zig 0.15.2+ and ensure it's in PATH

**Error**: `target riscv64-freestanding-none not found`
- **Fix**: Update Zig to 0.15.2 or later (RISC-V64 support required)

**Error**: Build fails with compilation errors
- **Fix**: Check Zig version, ensure all dependencies are available

### Runtime Issues

**Integration Test Fails**:
- **Error**: `Failed to open basin-rv64: FileNotFound`
- **Fix**: Build Basin first: `zig build basin-rv64`

**QEMU Boot Issues**:
- **Error**: `qemu-system-x86_64: command not found`
- **Fix**: Install QEMU: `sudo apt install qemu-system-x86_64`

- **Error**: ISO not found
- **Fix**: Create ISO: `./scripts/create_iso.sh`

- **No output in terminal**
- **Fix**: Use `-serial stdio` flag:
  ```bash
  qemu-system-x86_64 -cdrom vantage.iso -serial stdio
  ```

**Basin REPL Not Responding**:
- Check that serial console is redirected (`-serial stdio`)
- Try typing `h` and pressing Enter
- Verify Basin kernel loaded (check boot messages)
- Check QEMU output for errors

### ISO Creation Issues

**Error**: `xorriso: command not found`
- **Fix**: Install xorriso: `sudo apt install xorriso` or `brew install xorriso`

**Error**: Limine not found
- **Fix**: Script will auto-clone Limine, but ensure git is installed

**Error**: ISO creation fails
- **Fix**: Check disk space, ensure write permissions

---

## File Locations

### Source Code

- **Basin Kernel**: `src/basin/hello_riscv.zig`
- **Vantage VM**: `src/vantage/main_x86_64.zig`
- **RISC-V Core**: `src/vantage/riscv_core.zig`
- **Kernel Code**: `src/kernel/` (RISC-V only)
- **VM Runtime**: `src/kernel_vm/` (x86_64 host)

### Build Outputs

- **Basin Binary**: `zig-out/bin/basin-rv64` (RISC-V64 ELF)
- **Vantage Binary**: `zig-out/bin/vantage` (x86_64 ELF)
- **ISO**: `vantage.iso` (bootable ISO)

### Scripts

- **Create ISO**: `scripts/create_iso.sh`
- **QEMU Run**: `scripts/run_qemu.sh`
- **UEFI QEMU**: `scripts/run_uefi_qemu.sh`
- **Framework Tests**: `scripts/run_framework_x86_64_tests.sh`

### Documentation

- **This Guide**: `docs/BUILD_RUN_TEST.md`
- **Running Instructions**: `docs/rye/0010-basin-running-instructions.md`
- **Architecture Constraints**: `docs/architecture/basin_vantage_architecture_constraints.md`
- **Vantage Summary**: `docs/rye/VANTAGE_3_SUBCORE_SUMMARY.md`

---

## Quick Reference

### Build Commands

```bash
# Build Basin kernel (RISC-V64)
zig build basin-rv64

# Build Vantage VM (x86_64)
zig build vantage-x86_64

# Build both
zig build basin-rv64 vantage-x86_64

# Build with optimizations
zig build basin-rv64 -Doptimize=ReleaseSmall
```

### Run Commands

```bash
# Integration test (fastest)
zig build basin-rv64
zig test src/vantage/basin_integration_test.zig --mod riscv_core:src/vantage/riscv_core.zig

# Full boot in QEMU
zig build basin-rv64 vantage-x86_64
./scripts/create_iso.sh
qemu-system-x86_64 -cdrom vantage.iso -serial stdio
```

### Test Commands

```bash
# Run all tests
zig build test

# Run specific test
zig build test --test-filter test_name

# Run Basin integration test
zig test src/vantage/basin_integration_test.zig --mod riscv_core:src/vantage/riscv_core.zig
```

### Rye Style Validation Commands

```bash
# Validate Rye files (.ry)
cd rye && zig build
./zig-out/bin/rye check src/basin/*.ry src/vantage/*.ry

# Validate Zig files (.zig)
zig run tools/validate_kernel.zig
zig run tools/validate_src.zig
zig run tools/validate_vm.zig

# Complete validation workflow
zig build basin-rv64 && \
zig test src/vantage/basin_integration_test.zig --mod riscv_core:src/vantage/riscv_core.zig && \
zig run tools/validate_kernel.zig && \
zig build test
```

---

## Next Steps

### Current Status (Bottom-Up Foundation Work)

✅ **Basin REPL v0.4+** - Interactive shell with:
- Expression evaluator (arithmetic, variables)
- Variable management (`v`, `c` commands)
- Fibonacci calculator (`f` command)
- Help system (`h` command)

✅ **Foundation Layer** (Vantage 3 Subcore):
- Basin kernel (RISC-V64) running on Vantage VM
- Vantage VM (x86_64) with JIT backend
- Framework x86_64 compatibility
- Rye Style compliance (ongoing)

### Planned Enhancements

**Foundation Work (Bottom-Up)**:
- **Phase 2: Grainscript Integration**
  - Port Grainscript interpreter to freestanding RISC-V
  - Add `g` command to launch Grainscript
  - Full scripting capabilities

- **Phase 3: Framebuffer Access**
  - Map framebuffer to Basin via MMIO
  - Enable pixel drawing from Basin
  - Graphical UI support

- **Phase 4: Full Basin Kernel**
  - Process management
  - Memory management
  - Complete syscall interface

**Application Work (Top-Down - Core 1 Subcore)**:
- **Skate Desktop**: Knowledge graph application (x86_64 Linux userspace)
- **Skate Mobile/Carry**: Mobile framework and Android applications
- **Integration**: Applications use Basin/Vantage foundation (initially indirect, future direct)

### Integration Points

**Initial Integration** (Month 1-2):
- Skate desktop runs as userspace application on Framework x86_64 Linux
- Uses Basin/Vantage foundation indirectly (through Linux kernel)
- No direct integration needed initially

**Future Integration** (Later Phase):
- Skate can run inside Basin kernel (in-kernel application)
- Direct integration with Basin syscalls
- Requires coordination on syscall interface

**Coordination**:
- Vantage 3 Subcore: Build foundation (bottom-up)
- Core 1 Subcore: Build applications (top-down)
- Coordinate at integration points
- Ensure Rye Style compliance throughout

---

## Architecture Notes

**Important**: Basin targets RISC-V only. Vantage handles x86_64 only.

- **Basin** (`src/basin/`, `src/kernel/`): RISC-V64 only
- **Vantage** (`src/vantage/`, `src/kernel_vm/`): x86_64 host, RISC-V emulation
- **Boot** (`src/boot/`): Architecture-specific bootloaders

See `docs/architecture/basin_vantage_architecture_constraints.md` for full details.

---

**Date**: 2026-01-22-062000-pst (Updated with Rye Style compliance and bottom-up strategy)  
**Status**: ✅ **READY** — Complete instructions for building, running, and testing Grain OS  
**Context**: Bottom-up foundation work (Vantage 3 Subcore) preparing for top-down application work (Core 1 Subcore)
