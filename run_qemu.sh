#!/bin/bash
# Run Grain OS Kernel in QEMU
#
# This script builds the RISC-V64 kernel and runs it in QEMU.
# The kernel boots and enters the Grainscript REPL.
#
# Requirements:
#   - QEMU installed (qemu-system-riscv64)
#   - Zig compiler (0.12.0 or later)
#
# Usage:
#   ./run_qemu.sh
#
# For networking and file sharing, use:
#   ./scripts/run_qemu_with_networking.sh
#
# Exit:
#   - Press Ctrl+A then X to exit QEMU
#   - Or close the terminal window

set -e  # Exit on error

echo "Building kernel..."
zig build kernel-rv64

if [ ! -f "zig-out/bin/grain-rv64" ]; then
    echo "Error: Kernel build failed (zig-out/bin/grain-rv64 not found)"
    exit 1
fi

echo "Starting QEMU..."
echo "Kernel will boot and enter Grainscript REPL"
echo "Type 'help' in the REPL for available commands"
echo "Press Ctrl+A then X to exit QEMU"
echo ""

# Run QEMU with RISC-V64 virt machine
qemu-system-riscv64 \
    -machine virt \
    -bios none \
    -kernel zig-out/bin/grain-rv64 \
    -m 128M \
    -smp 1 \
    -nographic \
    -serial mon:stdio
