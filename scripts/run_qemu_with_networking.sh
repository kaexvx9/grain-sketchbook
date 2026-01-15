#!/usr/bin/env bash
# Run Grain OS in QEMU with networking and file sharing support
# Why: Enable SSH/SCP file transfer and network access for development

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL="$ROOT/zig-out/bin/grain-rv64"
SHARED_DIR="$ROOT/qemu_shared"

# Ensure kernel is built
if [ ! -f "$KERNEL" ]; then
  echo "Kernel image not found at $KERNEL" >&2
  echo "Run 'zig build kernel-rv64' first." >&2
  exit 1
fi

# Create shared directory if it doesn't exist
mkdir -p "$SHARED_DIR"

echo "Starting QEMU with networking..."
echo "Kernel: $KERNEL"
echo "Shared directory: $SHARED_DIR"
echo ""
echo "Network configuration:"
echo "  - User mode networking (NAT)"
echo "  - Host port 2222 -> Guest port 22 (SSH)"
echo "  - Host port 8080 -> Guest port 80 (HTTP)"
echo ""
echo "File sharing:"
echo "  - Host directory: $SHARED_DIR"
echo "  - Guest mount: /mnt/shared (9p filesystem)"
echo ""
echo "To exit QEMU: Press Ctrl+A then X"
echo ""

# Run QEMU with networking and file sharing
qemu-system-riscv64 \
    -machine virt \
    -cpu rv64 \
    -m 512M \
    -smp 1 \
    -nographic \
    -bios none \
    -kernel "$KERNEL" \
    -serial mon:stdio \
    \
    -netdev user,id=net0,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80 \
    -device virtio-net-device,netdev=net0 \
    \
    -fsdev local,id=fs0,path="$SHARED_DIR",security_model=mapped \
    -device virtio-9p-pci,fsdev=fs0,mount_tag=shared \
    \
    -monitor telnet:127.0.0.1:5555,server,nowait
