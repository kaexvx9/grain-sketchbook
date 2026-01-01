#!/bin/bash
# Automated NixOS Installation Script
# Run this in the NixOS VM after booting from ISO as root
# Usage: sudo bash install_nixos.sh

set -e  # Exit on error

echo "=========================================="
echo "  NixOS Automated Installation Script"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root"
    echo "Usage: sudo bash install_nixos.sh"
    exit 1
fi

# Configuration
DISK="/dev/vda"  # QEMU virtio disk (adjust if needed)
BOOT_SIZE="512MiB"

# Step 1: Detect disk
echo "Step 1: Detecting disk..."
if [ ! -b "$DISK" ]; then
    echo "WARNING: $DISK not found. Available disks:"
    lsblk
    echo ""
    read -p "Enter disk path (e.g., /dev/sda, /dev/vda): " DISK
    if [ ! -b "$DISK" ]; then
        echo "ERROR: Invalid disk: $DISK"
        exit 1
    fi
fi

echo "Using disk: $DISK"
echo "WARNING: This will ERASE all data on $DISK"
read -p "Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Installation cancelled."
    exit 1
fi

# Step 2: Partition the disk
echo ""
echo "Step 2: Partitioning disk $DISK..."
echo "  Creating GPT partition table..."
parted $DISK -- mklabel gpt

echo "  Creating boot partition (EFI, ${BOOT_SIZE})..."
parted $DISK -- mkpart ESP fat32 1MiB ${BOOT_SIZE}
parted $DISK -- set 1 esp on

echo "  Creating root partition (rest of disk)..."
parted $DISK -- mkpart primary ${BOOT_SIZE} 100%

# Wait for partitions to be available
sleep 2
partprobe $DISK 2>/dev/null || true
sleep 1

# Step 3: Format partitions
echo ""
echo "Step 3: Formatting partitions..."
echo "  Formatting boot partition (FAT32)..."
mkfs.fat -F 32 -n boot ${DISK}1 || mkfs.vfat -F 32 -n boot ${DISK}1

echo "  Formatting root partition (ext4)..."
mkfs.ext4 -F -L nixos ${DISK}2

# Step 4: Mount filesystems
echo ""
echo "Step 4: Mounting filesystems..."
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Step 5: Generate initial configuration
echo ""
echo "Step 5: Generating NixOS configuration..."
nixos-generate-config --root /mnt

# Step 6: Copy custom configuration if available
echo ""
echo "Step 6: Installing custom configuration..."
CONFIG_SOURCE="/tmp/configuration.nix"
if [ -f "$CONFIG_SOURCE" ]; then
    echo "  Found custom configuration at $CONFIG_SOURCE"
    cp "$CONFIG_SOURCE" /mnt/etc/nixos/configuration.nix
    echo "  ✓ Custom configuration installed"
else
    echo "  ℹ Custom configuration not found at $CONFIG_SOURCE"
    echo "  Using generated configuration at /mnt/etc/nixos/configuration.nix"
    echo "  You can edit it manually with: nano /mnt/etc/nixos/configuration.nix"
fi

# Step 7: Show configuration location
echo ""
echo "Step 7: Configuration files ready"
echo "  Configuration: /mnt/etc/nixos/configuration.nix"
echo "  Hardware config: /mnt/etc/nixos/hardware-configuration.nix"
echo ""
echo "  You can edit the configuration now if needed:"
echo "    nano /mnt/etc/nixos/configuration.nix"
echo ""
read -p "Edit configuration now? (yes/no): " EDIT_CONFIG
if [ "$EDIT_CONFIG" = "yes" ]; then
    nano /mnt/etc/nixos/configuration.nix
fi

# Step 8: Install NixOS
echo ""
echo "Step 8: Installing NixOS..."
echo "  This will download packages and install the system."
echo "  This may take 10-30 minutes depending on your connection."
echo ""
read -p "Continue with installation? (yes/no): " INSTALL_CONFIRM
if [ "$INSTALL_CONFIRM" != "yes" ]; then
    echo "Installation cancelled. Filesystems are mounted at /mnt"
    echo "You can continue later or run: nixos-install --no-root-passwd"
    exit 0
fi

echo ""
echo "Installing NixOS (please be patient)..."
nixos-install --no-root-passwd

# Step 9: Installation complete
echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Reboot: reboot"
echo "  2. Remove -cdrom from launch_nixos_vm.sh (or change boot order)"
echo "  3. SSH access: ssh -p 2222 xy@localhost (from host)"
echo ""
echo "Your system is ready to reboot!"

