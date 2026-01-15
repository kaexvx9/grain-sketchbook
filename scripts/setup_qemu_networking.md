# QEMU Networking Setup Guide

## Overview

This guide explains how to use networking and file sharing with QEMU for Grain OS development.

## Quick Start

### 1. Run QEMU with Networking

```bash
./scripts/run_qemu_with_networking.sh
```

This script:
- Starts QEMU with user mode networking (NAT)
- Sets up port forwarding (SSH on 2222, HTTP on 8080)
- Mounts a shared directory (`qemu_shared/`) as 9p filesystem

### 2. Transfer Files

**Option A: Shared Directory (Recommended for now)**
```bash
# Copy file to shared directory
cp my_script.sh qemu_shared/

# In QEMU guest, access via:
# /mnt/shared/my_script.sh
```

**Option B: Using SCP Script**
```bash
./scripts/scp_to_qemu.sh my_script.sh /tmp/my_script.sh
```

**Option C: Direct SCP (when SSH server is available)**
```bash
scp -P 2222 my_script.sh root@localhost:/tmp/my_script.sh
```

## Network Configuration

### Port Forwarding

- **SSH**: Host port 2222 → Guest port 22
- **HTTP**: Host port 8080 → Guest port 80

### Access from Host

```bash
# SSH (when SSH server is running in guest)
ssh -p 2222 root@localhost

# HTTP (when HTTP server is running in guest)
curl http://localhost:8080
```

## File Sharing

### Shared Directory

- **Host path**: `qemu_shared/` (in project root)
- **Guest mount**: `/mnt/shared` (9p filesystem)
- **Access**: Read/write from both host and guest

### Using the Shared Directory

**From Host:**
```bash
# Copy files to shared directory
cp my_script.sh qemu_shared/
cp my_data.txt qemu_shared/
```

**From Guest (in kernel/scripts):**
```bash
# Access files from shared directory
# Note: Requires 9p filesystem driver in kernel
cat /mnt/shared/my_script.sh
```

## Current Limitations

### Networking

- **User mode networking**: NAT-based, guest can access host network
- **SSH server**: Not yet implemented in kernel (requires networking stack)
- **TCP/UDP**: Kernel has socket managers but needs networking driver integration

### File Sharing

- **9p filesystem**: Requires 9p driver in kernel
- **Current status**: QEMU configured, driver implementation pending

## Future Enhancements

1. **9p Filesystem Driver**: Implement 9p driver in kernel to access shared directory
2. **SSH Server**: Add SSH server to kernel for remote access
3. **Network Stack**: Complete networking stack integration
4. **Virtio Drivers**: Complete virtio-net and virtio-9p driver implementations

## Troubleshooting

### Port Already in Use

If you see "port already in use" errors:
```bash
# Check what's using the port
sudo lsof -i :2222
sudo lsof -i :8080

# Kill the process or use different ports
```

### Shared Directory Not Accessible

- Ensure `qemu_shared/` directory exists
- Check QEMU logs for 9p mount errors
- Verify kernel has 9p filesystem support

### Network Not Working

- Verify QEMU started with `-netdev` and `-device virtio-net-device`
- Check QEMU monitor: `telnet localhost 5555`
- Verify kernel has networking drivers loaded

## QEMU Monitor

Access QEMU monitor for debugging:
```bash
telnet localhost 5555
```

Monitor commands:
- `info network`: Show network configuration
- `info block`: Show block devices
- `info qtree`: Show device tree
- `quit`: Exit QEMU
