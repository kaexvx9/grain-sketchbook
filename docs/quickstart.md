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

# Build kernel (with Grainscript interpreter)
zig build kernel-rv64

# Run in QEMU
./scripts/qemu_rv64.sh

# Or use the VM test (auto-exits)
zig build kernel-vm-test
```

## Expected Output

```
Basin Kernel v0.2.0 (RISC-V64 + Grainscript)
Copyright (c) 2026 Team Libra

Type 'help' for commands, 'exit' to halt.

grainscript> help
Commands: help, exit, or Grainscript code
Example: 42 + 8;
grainscript> 
```

Type `help` at the prompt, or enter Grainscript expressions directly.

## Rye Compiler

The kernel includes 60 modules written in Rye (14,000+ lines), our systems language:

```bash
# Build Rye compiler
cd rye && zig build

# Check all Rye modules
./zig-out/bin/rye check ../src/kernel/*.ry

# Get project statistics
./zig-out/bin/rye stats ../src/kernel/*.ry ../src/grainscript/*.ry

# Compile .ry to .zig
./zig-out/bin/rye build ../src/kernel/uart.ry
```

## Project Structure

```
ry/
├── src/kernel/           # Basin kernel (57 Rye modules)
│   ├── main_grainscript.ry  # Kernel entry (Grainscript REPL)
│   ├── main.zig          # Minimal kernel (inline asm, backup)
│   ├── entry.zig         # Entry point re-export
│   └── *.ry              # Rye modules (uart, scheduler, syscalls, etc.)
├── src/grainscript/      # Grainscript interpreter (3 Rye modules)
│   ├── lexer.ry          # Tokenizer
│   ├── parser.ry         # AST builder
│   └── interpreter.ry    # Runtime
├── rye/                  # Rye compiler
│   └── src/main.zig
├── docs/rye/             # Rye language docs
└── build.zig             # Build system
```

## Next Steps

- Read `docs/rye_style.md` for coding guidelines
- Read `docs/rye/0001-rye-language-vision.md` for language vision
- Explore syscalls in `src/kernel/basin_kernel.zig`
