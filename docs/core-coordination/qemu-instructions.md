# QEMU RISC-V Setup Instructions for Grain OS

**Date**: 2026-01-23-190900-pst  
**Environment**: Ubuntu 24.04 LTS GNOME Wayland  
**Purpose**: Grain OS testing and validation

---

## Prerequisites

### Install QEMU
```bash
sudo apt update
sudo apt install qemu-system-riscv64
```

### Verify Installation
```bash
qemu-system-riscv64 --version
```

---

## SSH Key Setup (First Time)

### Generate SSH Keys
```bash
cd /home/xy/grain-sketchbook
./tools/qemu-ssh-setup.sh
```

**What This Does**:
- Generates `~/.ssh/id_ed25519_qemu` (ed25519 key pair)
- Creates SSH config entry: `ssh qemu-grain`
- Displays public key for guest configuration

**If Key Already Exists**:
- Script detects existing key
- Displays connection instructions
- No new key generated

---

## Running QEMU

### Terminal Mode (Recommended for Development)

**Command**:
```bash
cd /home/xy/grain-sketchbook
./tools/qemu-riscv-setup.sh
```

**Features**:
- Serial console output (stdout/stderr)
- No GUI window (runs in terminal)
- Exit: `Ctrl+A` then `X`

**Best For**:
- Development and debugging
- Automated testing
- CI/CD pipelines
- Wezterm terminal sessions

### GUI Mode (For Visual Testing)

**Command**:
```bash
cd /home/xy/grain-sketchbook
./tools/qemu-riscv-setup.sh --gui
```

**Features**:
- SDL or GTK display window
- Visual framebuffer output
- Mouse/keyboard input
- Exit: Close window or `Ctrl+Alt+G` to release mouse

**Best For**:
- Visual validation
- Display testing
- User experience testing
- GNOME desktop environment

---

## SSH Access

### Setup (One Time)

1. **Generate Keys** (if not done):
   ```bash
   ./tools/qemu-ssh-setup.sh
   ```

2. **Add Public Key to QEMU Guest**:
   - Copy public key from `~/.ssh/id_ed25519_qemu.pub`
   - Add to guest: `~/.ssh/authorized_keys`
   - Or configure during guest OS setup

### Connect to QEMU Guest

**Using SSH Config** (recommended):
```bash
ssh qemu-grain
```

**Direct Connection**:
```bash
ssh -i ~/.ssh/id_ed25519_qemu -p 2222 root@localhost
```

**Connection Details**:
- Host: `localhost`
- Port: `2222` (default, configurable via `SSH_PORT` env var)
- User: `root` (or as configured in guest)
- Key: `~/.ssh/id_ed25519_qemu`

---

## File Transfer

### Copy File to QEMU Guest

**Using SSH Config**:
```bash
scp -P 2222 file.txt qemu-grain:/path/to/destination/
```

**Direct Command**:
```bash
scp -i ~/.ssh/id_ed25519_qemu -P 2222 file.txt root@localhost:/path/to/destination/
```

### Copy Directory to QEMU Guest

**Using SSH Config**:
```bash
scp -P 2222 -r directory/ qemu-grain:/path/to/destination/
```

**Direct Command**:
```bash
scp -i ~/.ssh/id_ed25519_qemu -P 2222 -r directory/ root@localhost:/path/to/destination/
```

### Copy from QEMU Guest

**Using SSH Config**:
```bash
scp -P 2222 qemu-grain:/path/to/file.txt ./
```

**Direct Command**:
```bash
scp -i ~/.ssh/id_ed25519_qemu -P 2222 root@localhost:/path/to/file.txt ./
```

---

## Environment Variables

### Customize QEMU Configuration

```bash
# QEMU binary path
export QEMU_BIN=qemu-system-riscv64

# Kernel image path
export KERNEL_IMAGE=build/grain_os_kernel

# SSH port
export SSH_PORT=2222

# SSH key path
export SSH_KEY=~/.ssh/id_ed25519_qemu

# Run QEMU
./tools/qemu-riscv-setup.sh
```

---

## Troubleshooting

### QEMU Not Found
```bash
# Install QEMU
sudo apt install qemu-system-riscv64

# Verify installation
which qemu-system-riscv64
```

### SSH Connection Failed
```bash
# Check if QEMU is running
ps aux | grep qemu

# Verify SSH port forwarding
netstat -tlnp | grep 2222

# Check SSH key permissions
chmod 600 ~/.ssh/id_ed25519_qemu
chmod 644 ~/.ssh/id_ed25519_qemu.pub
```

### GUI Mode Not Working
```bash
# Try SDL display
QEMU_DISPLAY=sdl ./tools/qemu-riscv-setup.sh --gui

# Or GTK display
QEMU_DISPLAY=gtk ./tools/qemu-riscv-setup.sh --gui
```

### Permission Denied (SSH)
```bash
# Fix SSH key permissions
chmod 600 ~/.ssh/id_ed25519_qemu
chmod 644 ~/.ssh/id_ed25519_qemu.pub
chmod 700 ~/.ssh
```

---

## Quick Reference

### Terminal Mode
```bash
./tools/qemu-riscv-setup.sh
# Exit: Ctrl+A then X
```

### GUI Mode
```bash
./tools/qemu-riscv-setup.sh --gui
# Exit: Close window or Ctrl+Alt+G
```

### SSH Setup
```bash
./tools/qemu-ssh-setup.sh
```

### SSH Connect
```bash
ssh qemu-grain
# Or: ssh -i ~/.ssh/id_ed25519_qemu -p 2222 root@localhost
```

### Copy Files
```bash
scp -P 2222 file.txt qemu-grain:/path/
scp -P 2222 -r directory/ qemu-grain:/path/
```

---

**Status**: ✅ **READY** — All tools configured and tested  
**Date**: 2026-01-23-190900-pst