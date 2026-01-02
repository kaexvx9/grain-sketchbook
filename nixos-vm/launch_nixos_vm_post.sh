#!/bin/bash
# Launch NixOS VM in QEMU/KVM (Post-Installation)
# This script boots from installed disk for normal operation
# Use launch_nixos_vm_install.sh for initial installation
# Framework 16: x86_64 AMD, 64GB RAM

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISO_DIR="$SCRIPT_DIR/iso"
DISK_DIR="$SCRIPT_DIR/disk"
ISO_FILE="$ISO_DIR/nixos-minimal-25.11.iso"
DISK_FILE="$DISK_DIR/nixos-vm.qcow2"

# Check if disk exists
if [ ! -f "$DISK_FILE" ]; then
    echo "Error: Disk file not found at $DISK_FILE"
    exit 1
fi

# VM Configuration
MEMORY="8G"  # 8GB RAM for NixOS VM (plenty available on Framework 16)
CORES="4"    # 4 CPU cores
DISPLAY=":0" # Use host display

# QEMU/KVM launch command
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
    -display gtk,zoom-to-fit=on,grab-on-hover=on,show-menubar=off \
    -name "NixOS 25.11 VM"

