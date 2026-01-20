# Grain OS Quickstart

Boot the kernel in under 5 minutes.

## Prerequisites

- Zig 0.15+ (`zig version`)
- QEMU with RISC-V support (`qemu-system-riscv64 --version`)

## Build and Run

```bash
# Clone
git clone https://codeberg.org/xy/ry.git
cd ry

# Build kernel
zig build kernel

# Run in QEMU
qemu-system-riscv64 -M virt -nographic -bios none -kernel zig-out/bin/kernel

# Or use the VM test (auto-exits)
zig build kernel-vm-test
```

## Expected Output

```
Basin Kernel v0.1.0
Grainscript> 
```

Type `help` at the prompt for available commands.

## Rye Compiler

The kernel includes modules written in Rye, our systems language:

```bash
# Build Rye compiler
cd rye && zig build

# Check a .ry file
./zig-out/bin/rye check ../src/kernel/uart.ry

# Compile .ry to .zig
./zig-out/bin/rye build ../src/kernel/uart.ry
```

## Project Structure

```
ry/
├── src/kernel/     # Basin kernel (Zig + Rye)
│   ├── main.zig    # Kernel entry point
│   ├── uart.ry     # UART driver (first Rye module)
│   └── ...
├── rye/            # Rye compiler
│   └── src/main.zig
├── docs/           # Documentation
└── build.zig       # Build system
```

## Next Steps

- Read `docs/rye_style.md` for coding guidelines
- Read `docs/rye/0001-rye-language-vision.md` for language vision
- Explore syscalls in `src/kernel/basin_kernel.zig`
