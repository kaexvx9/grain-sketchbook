# Rye Sync Daemon Usage

**Date**: 20260122.183000.rye  
**Status**: ✅ **READY** — Daemon compiles and is ready for use  
**Tool**: `rye_sync_daemon`

---

## Overview

The Rye Sync Daemon keeps `~/codeberg/ryelang/rye` in sync with `grainstore/codeberg/ryelang/rye` in the monorepo.

**How it works**:
- Polls every 2 seconds
- Copies files directly from external repo to grainstore
- Excludes `.git` folder from copy
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
- Uses `std.fs.Dir.copyFile` for file copying
- Uses `std.fs.Dir.iterate` for directory traversal

---

## How It Works

1. **Daemon starts**: Initializes with paths
2. **Loop begins**: Every 2 seconds:
   - Opens external repository directory (`~/codeberg/ryelang/rye`)
   - Recursively copies all files and directories to grainstore
   - Excludes `.git` folder from copy
   - Uses `std.fs.Dir.copyFile` for efficient file copying
   - Sleeps 2 seconds
3. **On failure**: Retries up to 3 times with 500ms delay
4. **On success**: Continues loop

**Important**: The daemon copies files directly, so the grainstore location does not need to be a git repository. The `.git` folder is explicitly excluded from the copy.

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
3. Daemon is running: Check process with `ps aux | grep rye_sync_daemon`
4. Files match: `diff -r ~/codeberg/ryelang/rye /home/xy/ry/grainstore/codeberg/ryelang/rye --exclude=".git"`

**Fix**:
- Ensure external repo has files to sync
- Verify daemon has read permissions to external directory
- Verify daemon has write permissions to grainstore directory
- Check that `.git` folder is not blocking (should be excluded automatically)
- Restart daemon if code was updated

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

**Date**: 20260122.183000.rye  
**Status**: ✅ **READY** — Daemon compiles and is ready for use

---

## Important Notes

- **Rebuild required**: If daemon code changes, rebuild and restart the daemon
- **No git required**: Grainstore location does not need to be a git repository
- **`.git` excluded**: The `.git` folder is automatically excluded from sync
- **File copying**: Uses direct file copy, not git operations
