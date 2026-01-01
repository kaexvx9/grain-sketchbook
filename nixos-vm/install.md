# NixOS VM Installation Guide

Complete installation guide for NixOS in QEMU/KVM on Framework 16.

---

## Quick Start (3 Steps)

### Step 1: Copy Configuration to VM

**Option A: Copy-paste (easiest for first time)**

1. In the VM terminal, create the config file:
   ```bash
   sudo nano /tmp/configuration.nix
   ```
2. Copy the contents from `configuration.nix` on your host and paste
3. Save (Ctrl+O, Enter, Ctrl+X)

**Option B: Download (if VM has internet)**
```bash
# In VM, download the configuration
curl -o /tmp/configuration.nix https://raw.githubusercontent.com/YOUR_REPO/xy-mathematics/main/nixos-vm/configuration.nix
```

**Option C: SCP from host (after setting password)**
```bash
# In VM, set password first:
passwd

# Then from host:
scp -P 2222 ~/xy-mathematics/nixos-vm/configuration.nix nixos@localhost:/tmp/
```

### Step 2: Run Installation Script

**Copy the installation script to the VM:**

1. In VM, create the script:
   ```bash
   sudo nano /tmp/install_nixos.sh
   ```
2. Copy the contents from `install_nixos.sh` on your host
3. Save and run:
   ```bash
   sudo bash /tmp/install_nixos.sh
   ```

The script will:
- ✅ Partition the disk automatically
- ✅ Format partitions
- ✅ Mount filesystems
- ✅ Generate and install configuration
- ✅ Install NixOS

**Time: ~10-30 minutes**

### Step 3: Reboot

```bash
reboot
```

After reboot, **remove the ISO** from the launch script:
- Edit `launch_nixos_vm.sh`
- Comment out or remove the `-cdrom $ISO_FILE \` line
- Or change `-boot order=d` to `-boot order=c`

---

## Post-Installation

After first boot, run:

```bash
# Copy post_install.sh to VM (same methods as Step 1)
# Then run:
bash ~/post_install.sh
```

This will:
- ✅ Update the system
- ✅ Clone xy-mathematics repository
- ✅ Configure Git
- ✅ Verify development tools
- ✅ Test build system

## Access from Host

```bash
ssh -p 2222 xy@localhost
```

---

## Detailed Installation Guide

This guide provides detailed, scripted instructions for installing NixOS in the QEMU VM with maximum automation.

### Prerequisites

- NixOS VM booted from ISO
- You should be logged in as `nixos` user (automatic login)

### Step 1: Download Configuration to VM

See "Quick Start" section above for methods to get `configuration.nix` into the VM.

### Step 2: Automated Installation Script

The `install_nixos.sh` script automates the entire installation process:

- Detects and partitions the disk automatically
- Formats partitions (FAT32 for boot, ext4 for root)
- Mounts filesystems
- Generates initial NixOS configuration
- Copies custom configuration if available
- Installs NixOS with interactive prompts

The script includes error handling and will prompt you before making destructive changes.

### Step 3: Manual Installation Steps (if scripts don't work)

#### Partitioning Manually

```bash
sudo -i
DISK="/dev/vda"
parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 esp on
parted $DISK -- mkpart primary 512MiB 100%
mkfs.fat -F 32 -n boot ${DISK}1
mkfs.ext4 -L nixos ${DISK}2
```

#### Mounting

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```

#### Generate Config

```bash
nixos-generate-config --root /mnt
```

#### Edit Configuration

```bash
nano /mnt/etc/nixos/configuration.nix
# Copy your configuration.nix content here
```

#### Install

```bash
nixos-install
```

#### Reboot

```bash
reboot
```

---

## Complete Automated Installation (All-in-One)

Here's a complete script that does everything in one go:

```bash
#!/bin/bash
# Complete NixOS Installation Script
# Run this in the NixOS VM ISO environment as root

set -e

DISK="/dev/vda"
CONFIG_URL="https://raw.githubusercontent.com/YOUR_REPO/xy-mathematics/main/nixos-vm/configuration.nix"

echo "=== Complete NixOS Installation ==="

# Download configuration if possible
if command -v curl &> /dev/null; then
    echo "Downloading configuration..."
    curl -o /tmp/configuration.nix "$CONFIG_URL" || echo "Download failed, will use generated config"
fi

# Partition
echo "Partitioning $DISK..."
parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 esp on
parted $DISK -- mkpart primary 512MiB 100%

# Format
echo "Formatting..."
mkfs.fat -F 32 -n boot ${DISK}1
mkfs.ext4 -L nixos ${DISK}2

# Mount
echo "Mounting..."
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot

# Generate and copy config
echo "Generating configuration..."
nixos-generate-config --root /mnt

if [ -f /tmp/configuration.nix ]; then
    cp /tmp/configuration.nix /mnt/etc/nixos/configuration.nix
fi

# Install
echo "Installing NixOS (this takes a while)..."
nixos-install --no-root-passwd

echo "=== Installation Complete! Run 'reboot' to restart. ==="
```

---

## Troubleshooting

### Installation script fails
- Check disk: `lsblk` (might be `/dev/sda` instead of `/dev/vda`)
- Check mounts: `mount | grep /mnt`
- See manual steps above

### Disk Not Found

If `/dev/vda` doesn't exist:
```bash
lsblk  # List available disks
# Use the appropriate disk (might be /dev/sda, /dev/nvme0n1, etc.)
```

### Network Issues

If you need internet in the VM:
```bash
# Check network
ip addr
# Configure if needed
nmtui
```

### Configuration Errors

Test your configuration:
```bash
nixos-install --dry-run
# Or after mounting:
nixos-rebuild --dry-run
```

### Can't SSH after install
- Check SSH is running: `sudo systemctl status sshd`
- Check firewall: `sudo nixos-rebuild switch` (rebuild config)

### Build system errors
- Update: `sudo nixos-rebuild switch --upgrade`
- Check Zig: `zig version`

---

## Next Steps After Installation

1. **Reboot the VM**
2. **Remove ISO from launch script** (change boot order or remove `-cdrom` line)
3. **SSH access**: `ssh -p 2222 xy@localhost` (from host)
4. **Set up development environment** using the post-installation script

---

## Helper Scripts

### Copy Files to VM

Use `copy_to_vm.sh` from the host to copy files to the VM:

```bash
./copy_to_vm.sh
```

This will copy `configuration.nix` and `install_nixos.sh` to the VM.

### Post-Installation Script

After first boot, run `post_install.sh` to:
- Update the system
- Clone xy-mathematics repository
- Configure Git
- Verify development tools
- Test build system

