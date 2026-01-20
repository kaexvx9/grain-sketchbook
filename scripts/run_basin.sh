#!/bin/bash
# Run Basin kernel on QEMU RISC-V64
# Usage: ./scripts/run_basin.sh

set -e

KERNEL="${1:-zig-out/bin/grain-rv64}"

if [ ! -f "$KERNEL" ]; then
    echo "Kernel not found: $KERNEL"
    echo "Build with: zig build kernel-rv64"
    exit 1
fi

echo "Starting Basin Kernel on QEMU..."
echo "Press Ctrl+A X to exit QEMU"
echo ""

qemu-system-riscv64 \
    -machine virt \
    -bios none \
    -kernel "$KERNEL" \
    -nographic \
    -m 128M
