# Rye Sync Daemon Usage

**Date**: 20260122.182600.rye  
**Status**: ✅ **READY** — Daemon compiles and is ready for use  
**Tool**: `rye_sync_daemon`

---

## Overview

The Rye Sync Daemon keeps `~/codeberg/ryelang/rye` in sync with `grainstore/codeberg/ryelang/rye` in the monorepo.

**How it works**:
- Polls every 2 seconds
- Runs `git pull origin main` in grainstore location
- Retries up to 3 times on failure
- Runs continuously in background

---

## Building

```bash
# Build daemon directly (avoids other build dependencies)
cd /home/xy/ry
zig build-exe tools/rye_sync_daemon.zig

# Binary created at: rye_sync_daemon (in current directory)
# Or move to: zig-out/bin/rye_sync_daemon

# Alternative: Use build step (if other deps are available)
zig build rye-sync
```

---

## Running

### Background Terminal

```bash
# Run daemon in background terminal
cd /home/xy/ry

# If built directly:
./rye_sync_daemon

# If installed to zig-out/bin:
./zig-out/bin/rye_sync_daemon

# Or use build step (builds and runs):
zig build rye-sync
```

**Note**: The daemon runs continuously. Press `Ctrl+C` to stop.

### Systemd Service (Optional)

Create `/etc/systemd/user/rye-sync.service`:

```ini
[Unit]
Description=Rye Sync Daemon
After=network.target

[Service]
Type=simple
ExecStart=/home/xy/ry/zig-out/bin/rye_sync_daemon
Restart=always
RestartSec=5

[Install]
WantedBy=default.target
```

Enable and start:
```bash
systemctl --user enable rye-sync.service
systemctl --user start rye-sync.service
```

---

## Configuration

**Paths** (hardcoded, can be made configurable):
- **External**: `~/codeberg/ryelang/rye`
- **Grainstore**: `/home/xy/ry/grainstore/codeberg/ryelang/rye`

**Settings** (in `tools/rye_sync_daemon.zig`):
- `SYNC_INTERVAL_MS = 2000` (2 seconds)
- `MAX_RETRIES = 3`
- `MAX_PATH_LEN = 512` (maximum path length)

**API Notes**:
- Uses `std.Thread.sleep` for delays (Zig 0.15.2)
- Uses `std.process.getEnvVarOwned` for environment variables
- Uses `std.process.Child` for git commands

---

## How It Works

1. **Daemon starts**: Initializes with paths
2. **Loop begins**: Every 2 seconds:
   - Changes to grainstore directory
   - Runs `git pull origin main`
   - Waits for completion
   - Sleeps 2 seconds
3. **On failure**: Retries up to 3 times with 500ms delay
4. **On success**: Continues loop

---

## Rye Style Compliance

✅ **Function length**: All functions ≤ 64 lines  
✅ **Line length**: All lines ≤ 128 characters  
✅ **Why comments**: All `pub fn` have "why" comments  
✅ **Explicit types**: No `usize`/`isize` inference  
✅ **Assertions**: Minimum 2 per function  
✅ **No recursion**: Iterative only

---

## Troubleshooting

### Daemon Not Syncing

**Check**:
1. External repository exists: `ls ~/codeberg/ryelang/rye`
2. Grainstore directory exists: `ls /home/xy/ry/grainstore/codeberg/ryelang/rye`
3. Git remote configured: `cd grainstore/codeberg/ryelang/rye && git remote -v`
4. Daemon is running: Check process with `ps aux | grep rye_sync_daemon`

**Fix**:
- Ensure external repo is pushed to Codeberg
- Ensure grainstore directory is cloned from Codeberg
- Check git authentication (SSH keys)
- Verify daemon has write permissions to grainstore directory

### High CPU Usage

**Cause**: Polling every 2 seconds may be too frequent

**Fix**: Increase `SYNC_INTERVAL_MS` in `tools/rye_sync_daemon.zig`

---

## Future Enhancements

- **File watching**: Use inotify instead of polling
- **Config file**: Make paths and intervals configurable
- **Logging**: Add log file for sync operations
- **Status endpoint**: HTTP endpoint for daemon status

---

## References

- **Source**: `tools/rye_sync_daemon.zig`
- **Build**: `zig build rye-sync`
- **Grainmirror Setup**: `docs/rye/0017-rye-compiler-grainmirror-setup.md`

---

**Date**: 20260122.182600.rye  
**Status**: ✅ **READY** — Daemon compiles and is ready for use
