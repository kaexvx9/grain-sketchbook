#!/bin/bash
# Launch NixOS VM with verbose boot output (for debugging)
# This shows kernel messages and boot output

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DISK_DIR="$SCRIPT_DIR/disk"
DISK_FILE="$DISK_DIR/nixos-vm.qcow2"

# Check if disk exists
if [ ! -f "$DISK_FILE" ]; then
    echo "Error: Disk file not found at $DISK_FILE"
    exit 1
fi

# VM Configuration
MEMORY="8G"
CORES="4"

# QEMU/KVM launch with serial console for debugging
qemu-system-x86_64 \
    -enable-kvm \
    -cpu host \
    -smp cores=$CORES,threads=1,sockets=1 \
    -m $MEMORY \
    -drive file=$DISK_FILE,format=qcow2 \
    -boot order=c \
    -netdev user,id=net0,hostfwd=tcp::2222-:22 \
    -device virtio-net,netdev=net0 \
    -vga virtio \
    -serial stdio \
    -display gtk,zoom-to-fit=on \
    -name "NixOS 25.11 VM (Debug)"

