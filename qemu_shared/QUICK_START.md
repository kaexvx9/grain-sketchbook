# QEMU File Transfer Quick Start

## Transfer Files to QEMU Guest

### Method 1: Shared Directory (Easiest)

```bash
# Copy file to shared directory
cp my_script.sh qemu_shared/

# In QEMU guest (when 9p driver is implemented):
# Access at: /mnt/shared/my_script.sh
```

### Method 2: Using SCP Script

```bash
# Transfer file using helper script
./scripts/scp_to_qemu.sh my_script.sh

# Or specify destination path
./scripts/scp_to_qemu.sh my_script.sh /tmp/my_script.sh
```

### Method 3: Direct SCP (Future - when SSH server is available)

```bash
# Direct SCP via port forwarding
scp -P 2222 my_script.sh root@localhost:/tmp/my_script.sh
```

## Start QEMU with Networking

```bash
# Start QEMU with networking and file sharing
./scripts/run_qemu_with_networking.sh
```

## Network Access

- **SSH**: `ssh -p 2222 root@localhost` (when SSH server is available)
- **HTTP**: `http://localhost:8080` (when HTTP server is available)
- **QEMU Monitor**: `telnet localhost 5555`

## Current Status

- ✅ **Shared directory**: Ready (`qemu_shared/`)
- ⏳ **9p filesystem driver**: Pending (needed to access `/mnt/shared/` in guest)
- ⏳ **SSH server**: Pending (needed for direct SCP)

## Notes

- Files in `qemu_shared/` are accessible from both host and guest
- Guest access requires 9p filesystem driver implementation
- For now, use shared directory method for file transfer
