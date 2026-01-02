#!/bin/bash
# Fix mount issue and continue NixOS installation
# Run this if install_nixos.sh failed at the mounting step

set -e

echo "=========================================="
echo "  Fix Mount and Continue Installation"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "ERROR: Please run as root"
    echo "Usage: sudo bash fix_mount_and_install.sh"
    exit 1
fi

DISK="/dev/sda"

# Step 1: Refresh device links
echo "Step 1: Refreshing device links..."
partprobe $DISK 2>/dev/null || true
udevadm trigger
sleep 2

# Step 2: Mount using partition devices directly
echo ""
echo "Step 2: Mounting filesystems..."
if mountpoint -q /mnt; then
    echo "  /mnt is already mounted, unmounting..."
    umount /mnt 2>/dev/null || true
fi

if mountpoint -q /mnt/boot; then
    echo "  /mnt/boot is already mounted, unmounting..."
    umount /mnt/boot 2>/dev/null || true
fi

# Mount root partition (sda2)
echo "  Mounting root partition (/dev/sda2)..."
mount /dev/sda2 /mnt || {
    echo "ERROR: Failed to mount /dev/sda2"
    echo "Trying by-label method..."
    sleep 1
    mount /dev/disk/by-label/nixos /mnt || {
        echo "ERROR: Both mount methods failed"
        echo "Check partitions: lsblk"
        exit 1
    }
}

# Mount boot partition (sda1)
echo "  Mounting boot partition (/dev/sda1)..."
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot || {
    echo "ERROR: Failed to mount /dev/sda1"
    echo "Trying by-label method..."
    sleep 1
    mount /dev/disk/by-label/boot /mnt/boot || {
        echo "ERROR: Both mount methods failed"
        exit 1
    }
}

# Verify mounts
echo ""
echo "Step 3: Verifying mounts..."
mount | grep -E "/mnt|/boot" || echo "WARNING: Mount verification unclear"
echo "  ✓ Filesystems mounted"

# Step 4: Generate NixOS configuration
echo ""
echo "Step 4: Generating NixOS configuration..."
if [ ! -f /mnt/etc/nixos/configuration.nix ]; then
    nixos-generate-config --root /mnt
    echo "  ✓ Configuration generated"
else
    echo "  ℹ Configuration already exists"
fi

# Step 5: Copy custom configuration if available
echo ""
echo "Step 5: Installing custom configuration..."
if [ -f /tmp/configuration.nix ]; then
    cp /tmp/configuration.nix /mnt/etc/nixos/configuration.nix
    echo "  ✓ Custom configuration installed"
else
    echo "  ℹ Custom configuration not found at /tmp/configuration.nix"
    echo "  Using generated configuration at /mnt/etc/nixos/configuration.nix"
fi

# Step 6: Show configuration location
echo ""
echo "Step 6: Configuration ready"
echo "  Configuration: /mnt/etc/nixos/configuration.nix"
echo "  Hardware config: /mnt/etc/nixos/hardware-configuration.nix"
echo ""
read -p "Edit configuration now? (yes/no): " EDIT_CONFIG
if [ "$EDIT_CONFIG" = "yes" ]; then
    nano /mnt/etc/nixos/configuration.nix
fi

# Step 7: Install NixOS
echo ""
echo "Step 7: Installing NixOS..."
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

# Step 8: Installation complete
echo ""
echo "=========================================="
echo "  Installation Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "  1. Reboot: reboot"
echo "  2. Use launch_nixos_vm_post.sh instead of launch_nixos_vm_install.sh"
echo "  3. SSH access: ssh -p 2222 xy@localhost (from host)"
echo ""
echo "Your system is ready to reboot!"

