#!/bin/bash
# QEMU RISC-V Setup Script for Grain OS Testing
#
# Why: Configure QEMU RISC-V environment for Grain OS validation and testing.
# Sets up framebuffer, memory, and display for complete system testing.
#
# Agent: Vantage 3 (Systems Implementation)

set -e

QEMU_BIN="${QEMU_BIN:-qemu-system-riscv64}"
KERNEL_IMAGE="${KERNEL_IMAGE:-build/grain_os_kernel}"
MEMORY_SIZE="512M"
FRAMEBUFFER_ADDR="0x10000000"

echo "=== QEMU RISC-V Setup for Grain OS ==="
echo ""

# Why: Check if QEMU is available.
if ! command -v "$QEMU_BIN" &> /dev/null; then
    echo "ERROR: QEMU not found. Please install qemu-system-riscv64"
    exit 1
fi

echo "QEMU binary: $QEMU_BIN"
echo "Kernel image: $KERNEL_IMAGE"
echo "Memory: $MEMORY_SIZE"
echo "Framebuffer: $FRAMEBUFFER_ADDR"
echo ""

# Why: Build QEMU command with proper configuration.
QEMU_CMD=(
    "$QEMU_BIN"
    -machine virt
    -cpu rv64
    -m "$MEMORY_SIZE"
    -kernel "$KERNEL_IMAGE"
    -device virtio-gpu-pci
    -device ramfb,addr="$FRAMEBUFFER_ADDR"
    -nographic
    -serial stdio
)

echo "QEMU command:"
echo "${QEMU_CMD[@]}"
echo ""
echo "=== Starting QEMU ==="
echo ""

# Why: Execute QEMU with configured parameters.
exec "${QEMU_CMD[@]}"