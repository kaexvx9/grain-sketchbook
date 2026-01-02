# NixOS VM Installation Guide

Complete installation guide for NixOS in QEMU/KVM on Framework 16.

---

## Quick Start (3 Steps)

**Launch Scripts:**
- `launch_nixos_vm_install.sh` - Boot from ISO for installation (use this first)
- `launch_nixos_vm_post.sh` - Boot from installed disk (use after installation)

### Step 1: Launch VM for Installation

From your host machine:
```bash
cd ~/xy-mathematics/nixos-vm
./launch_nixos_vm_install.sh
```

This boots the NixOS installer ISO.

### Step 2: Copy Files to VM

**Option A: SCP from Host (Recommended - Easiest)**

From your **host machine** (Ubuntu), copy the files to the VM:

```bash
# First, set a password in the VM (in VM terminal):
passwd

# Then from host, copy all files at once:
cd ~/xy-mathematics/nixos-vm
scp -P 2222 configuration.nix install_nixos.sh nixos@localhost:/tmp/
scp -P 2222 post_install.sh nixos@localhost:~/
```

Or use the helper script from the host:
```bash
cd ~/xy-mathematics/nixos-vm
./copy_to_vm.sh
```

**Option B: Download from Git (if VM has internet)**

```bash
# In the VM, download files directly:
cd /tmp
curl -O https://codeberg.org/teamcarry11/xy-mathematics/raw/branch/main/nixos-vm/configuration.nix
curl -O https://codeberg.org/teamcarry11/xy-mathematics/raw/branch/main/nixos-vm/install_nixos.sh
curl -O https://codeberg.org/teamcarry11/xy-mathematics/raw/branch/main/nixos-vm/post_install.sh
mv post_install.sh ~/
chmod +x install_nixos.sh ~/post_install.sh
```

### Step 2: Run Installation Script

In the VM terminal, run:

```bash
sudo bash /tmp/install_nixos.sh
```

The script will:
- ✅ Detect and partition the disk automatically
- ✅ Format partitions
- ✅ Mount filesystems
- ✅ Generate hardware-configuration.nix
- ✅ Copy your configuration
- ✅ Install NixOS

**Important:** Use `configuration.nix` (complete version) which includes:
- Hardware configuration imports (fileSystems from hardware-configuration.nix)
- Bootloader configuration for QEMU VM (GRUB with EFI)

The `configuration-base.nix` is a template without these additions - use `configuration.nix` for installation.

**Note:** If the script fails at the mounting step (error about `/dev/disk/by-label/nixos`), see "Troubleshooting: Mount Issue" below.

**Time: ~10-30 minutes**

### Step 4: Reboot and Use Post-Install Script

After installation completes:
```bash
reboot
```

**Close the VM**, then from your host machine, use the post-installation launch script:
```bash
cd ~/xy-mathematics/nixos-vm
./launch_nixos_vm_post.sh
```

This boots from the installed disk (no ISO). The install script is only needed for initial installation.

---

## Post-Installation

After first boot into installed NixOS, run:

```bash
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

### Prerequisites

- NixOS VM booted from ISO
- You should be logged in as `nixos` user (automatic login)
- Host machine with the nixos-vm files accessible

### Step 1: Transfer Files to VM

Choose one of these methods to get the files into the VM:

#### Method 1: SCP (Recommended)

**From host machine:**
```bash
cd ~/xy-mathematics/nixos-vm

# Set password in VM first (in VM: passwd)
# Then copy files:
scp -P 2222 configuration.nix install_nixos.sh nixos@localhost:/tmp/
scp -P 2222 post_install.sh nixos@localhost:~/

# In VM, make scripts executable:
ssh -p 2222 nixos@localhost "chmod +x /tmp/install_nixos.sh ~/post_install.sh"
```

Or use the helper script:
```bash
./copy_to_vm.sh
```

#### Method 2: Download from Repository

**In the VM:**
```bash
cd /tmp

# Download configuration
curl -L -o configuration.nix https://codeberg.org/teamcarry11/xy-mathematics/raw/branch/main/nixos-vm/configuration.nix

# Download installation script
curl -L -o install_nixos.sh https://codeberg.org/teamcarry11/xy-mathematics/raw/branch/main/nixos-vm/install_nixos.sh
chmod +x install_nixos.sh

# Download post-installation script
curl -L -o ~/post_install.sh https://codeberg.org/teamcarry11/xy-mathematics/raw/branch/main/nixos-vm/post_install.sh
chmod +x ~/post_install.sh
```

#### Method 3: QEMU Monitor (Advanced)

If you have access to QEMU monitor, you can use a shared directory or virtio-fs.

### Step 2: Run Installation

**In the VM terminal:**
```bash
sudo bash /tmp/install_nixos.sh
```

The script will:
1. Detect the disk (usually `/dev/vda` for QEMU virtio)
2. Prompt for confirmation before partitioning
3. Create GPT partition table
4. Create EFI boot partition (512MB, FAT32)
5. Create root partition (ext4, rest of disk)
6. Format partitions
7. Mount filesystems
8. Generate NixOS configuration
9. Copy your custom configuration if found
10. Install NixOS

### Step 3: Verify Installation

After the script completes:
- Check that it says "Installation Complete!"
- Run `reboot` to restart
- After reboot, login and verify system works

---

## Manual Installation (Fallback)

If the automated script doesn't work, here are the manual steps:

### Partitioning

```bash
sudo -i
DISK="/dev/vda"  # Adjust if different
parted $DISK -- mklabel gpt
parted $DISK -- mkpart ESP fat32 1MiB 512MiB
parted $DISK -- set 1 esp on
parted $DISK -- mkpart primary 512MiB 100%
mkfs.fat -F 32 -n boot ${DISK}1
mkfs.ext4 -L nixos ${DISK}2
```

### Mounting

```bash
mount /dev/disk/by-label/nixos /mnt
mkdir -p /mnt/boot
mount /dev/disk/by-label/boot /mnt/boot
```

### Configuration

```bash
nixos-generate-config --root /mnt

# Copy your configuration
cp /tmp/configuration.nix /mnt/etc/nixos/configuration.nix
```

### Install

```bash
nixos-install --no-root-passwd
reboot
```

---

## Troubleshooting

### Mount Issue (Can't lookup blockdev)

**Symptom:** Script fails with error:
```
mount: /mnt: fsconfig() failed: /dev/disk/by-label/nixos: Can't lookup blockdev.
```

**Solution:** Use the fix script:

1. **Copy fix script to VM:**
   ```bash
   # From host:
   cd ~/xy-mathematics/nixos-vm
   scp -P 2222 fix_mount_and_install.sh nixos@localhost:/tmp/
   ```

2. **Run fix script in VM:**
   ```bash
   sudo bash /tmp/fix_mount_and_install.sh
   ```

   The fix script will:
   - Refresh device links
   - Mount filesystems using partition devices directly (`/dev/sda1`, `/dev/sda2`)
   - Generate NixOS configuration
   - Copy your custom configuration
   - Continue with installation

3. **If script is cancelled or you need to continue manually:**
   ```bash
   # Filesystems should already be mounted, just run:
   sudo nixos-install --no-root-passwd
   ```

### Configuration Errors (Missing filesystems/bootloader)

**Symptom:** Installation fails with errors:
```
Failed assertions:
- The 'fileSystems' option does not specify your root file system.
- You must set the option 'boot.loader.grub.devices' or 'boot.loader.grub.mirroredBoots'
```

**Solution:** Make sure you're using `configuration.nix` (complete version) which includes:
- Import of `hardware-configuration.nix` (contains fileSystems)
- Bootloader configuration for QEMU VM

The `configuration.nix` file already has both of these configured. If you're using `configuration-base.nix`, you need to add them manually.

**File differences:**
- `configuration.nix` - Complete working version (USE THIS for installation)
  - Includes hardware-configuration.nix import
  - Includes bootloader config (GRUB with EFI for QEMU)
  - Ready to use
- `configuration-base.nix` - Base template (reference only)
  - User settings, packages, kernel 6.18.2
  - Missing hardware imports and bootloader config
  - Would need manual additions to work

### Installation script fails

**Disk not found:**
- Check available disks: `lsblk`
- The script will prompt you to enter the correct disk path
- For QEMU virtio, it's usually `/dev/vda`
- For IDE/SATA, it might be `/dev/sda`

**Permission denied:**
- Make sure you're running with `sudo bash /tmp/install_nixos.sh`
- Check script is executable: `chmod +x /tmp/install_nixos.sh`

**Configuration not found:**
- Verify file exists: `ls -la /tmp/configuration.nix`
- The script will use generated config if custom one isn't found

### Network Issues

**Can't download files:**
- Check network: `ip addr`
- Configure network: `nmtui`
- Use SCP method instead (from host)

**Can't SSH from host:**
- Set password in VM: `passwd`
- Check SSH is running (in installed NixOS): `sudo systemctl status sshd`

### After Installation

**Can't SSH after install:**
- Check SSH service: `sudo systemctl status sshd`
- Rebuild config: `sudo nixos-rebuild switch`
- Check firewall settings in configuration.nix

**Build system errors:**
- Update system: `sudo nixos-rebuild switch --upgrade`
- Check Zig: `zig version`
- Verify packages in configuration.nix

### Disk Issues

**Wrong disk detected:**
- List disks: `lsblk`
- The script prompts for disk path if `/dev/vda` doesn't exist
- Enter the correct path when prompted

**Partition errors:**
- Unmount if mounted: `umount /mnt/boot && umount /mnt`
- Check disk isn't in use: `lsof | grep /dev/vda`
- Start fresh: The script will handle cleanup

---

## File Locations

**In VM during installation:**
- Configuration: `/tmp/configuration.nix`
- Installation script: `/tmp/install_nixos.sh`
- Post-install script: `~/post_install.sh`

**After installation:**
- Configuration: `/etc/nixos/configuration.nix`
- Post-install script: `~/post_install.sh`
- Repository: `~/xy-mathematics/`

---

## Next Steps After Installation

1. **Reboot the VM**
2. **Use post-installation launch script** (on host, use `launch_nixos_vm_post.sh`)
3. **SSH access**: `ssh -p 2222 xy@localhost` (from host)
4. **Run post-installation**: `bash ~/post_install.sh`
5. **Set up development environment** and continue with Grain OS development

---

## Helper Scripts

### copy_to_vm.sh

Helper script to copy files from host to VM via SCP:

```bash
# From host machine
cd ~/xy-mathematics/nixos-vm
./copy_to_vm.sh
```

This script:
- Checks VM connectivity
- Copies `configuration.nix` to `/tmp/`
- Copies `install_nixos.sh` to `/tmp/`
- Copies `post_install.sh` to `~/`
- Makes scripts executable

### install_nixos.sh

Main installation script that:
- Detects disk automatically
- Partitions and formats
- Mounts filesystems
- Generates NixOS config
- Installs system
- Includes error handling and prompts

**Note:** If this script fails at mounting, use `fix_mount_and_install.sh` instead.

### fix_mount_and_install.sh

Recovery script for mount issues:
- Refreshes device links (fixes mount lookup errors)
- Mounts filesystems using partition devices directly
- Continues installation from where install_nixos.sh left off
- Can be run if install_nixos.sh fails or is cancelled

### post_install.sh

Post-installation setup that:
- Updates system packages
- Clones xy-mathematics repository
- Configures Git
- Verifies development tools
- Tests build system

---

## Summary

**Quick Installation Flow:**

1. **Copy files to VM** (SCP or download)
2. **Run**: `sudo bash /tmp/install_nixos.sh`
   - If mount error occurs, use: `sudo bash /tmp/fix_mount_and_install.sh`
   - If script is cancelled, continue with: `sudo nixos-install --no-root-passwd`
3. **Reboot**
4. **Run**: `bash ~/post_install.sh`
5. **Start developing!**

All scripts are self-contained and can be run directly from the file system - no copy-paste needed!

**Common Issue:** If `install_nixos.sh` fails at mounting, the `fix_mount_and_install.sh` script handles this by using partition devices directly instead of labels.
