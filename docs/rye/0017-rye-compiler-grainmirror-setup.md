# Rye Compiler Grainmirror Setup

**Date**: 2026-01-22-065200-pst  
**Status**: 🆕 **SETUP GUIDE** — Grainmirror configuration for Rye compiler fork  
**Repository**: `codeberg.org/ryelang/rye`

---

## Overview

This document describes how to set up grainmirror for the Rye compiler fork, enabling development outside the monorepo with continuous syncing into grainstore.

---

## Directory Structure

### External Development Location

**Host Machine**: `~/codeberg/ryelang/rye`  
**Purpose**: Primary development location (outside monorepo)  
**Remote**: `origin` → `codeberg.org/ryelang/rye`  
**Upstream**: `upstream` → `codeberg.org/ziglang/zig`

### Grainstore Mirror Location

**Monorepo**: `grainstore/codeberg/ryelang/rye`  
**Purpose**: Mirrored copy for integration and reference  
**Sync**: Continuous grainmirror sync from `codeberg.org/ryelang/rye`

---

## Setup Steps

### Step 1: Create External Repository

```bash
# Create directory structure
mkdir -p ~/codeberg/ryelang

# Clone Zig 0.15.2
cd ~/codeberg/ryelang
git clone https://codeberg.org/ziglang/zig.git rye
cd rye

# Checkout Zig 0.15.2 tag
git checkout 0.15.2

# Create base branch
git checkout -b rye-0.15.2-base

# Set up remotes
git remote rename origin upstream
git remote add origin https://codeberg.org/ryelang/rye.git

# Verify remotes
git remote -v
# Should show:
# origin    https://codeberg.org/ryelang/rye.git (fetch)
# origin    https://codeberg.org/ryelang/rye.git (push)
# upstream  https://codeberg.org/ziglang/zig.git (fetch)
# upstream  https://codeberg.org/ziglang/zig.git (push)
```

### Step 2: Create Initial Attribution Commit

```bash
# Create THIRD_PARTY_LICENSES.md (see template in 0012-rye-repository-setup-guide.md)
# Get Zig 0.15.2 commit hash
ZIG_COMMIT=$(git rev-parse HEAD)

# Create attribution commit
git add THIRD_PARTY_LICENSES.md
git commit -m "rye: fork from zig 0.15.2 with attribution

2026-01-22-065200-pst

forked from:
- ziglang/zig tag 0.15.2
- https://codeberg.org/ziglang/zig/src/tag/0.15.2
- commit: $ZIG_COMMIT

rye adaptations planned:
- fix risc-v freestanding codegen bugs
- add toroidal/garden types as first-class language features
- enforce rye style constraints (64 lines, 128 chars, why comments)
- chronological versioning (non-semantic: YYYYMMDD.HHMMSS.variant)
- garden-allocation model (not linux heap model)

see THIRD_PARTY_LICENSES.md for zig license and attribution

rye style: explicit attribution, chronological versioning, toroidal bounded model"
```

### Step 3: Push to Codeberg

```bash
# Push base branch
git push -u origin rye-0.15.2-base

# Create main branch
git checkout -b main
git push -u origin main
```

### Step 4: Configure Grainmirror

**Location**: `grainstore/codeberg/ryelang/rye` (in monorepo)

**Pattern**: `grainstore/{platform}/{org}/{repo}`

**Sync Strategy**:
- **Source**: `codeberg.org/ryelang/rye` (external repository)
- **Target**: `grainstore/codeberg/ryelang/rye` (monorepo mirror)
- **Method**: Continuous sync (not symlinked, for Cursor filetree compatibility)

**Grainmirror Manifest Entry** (to be added to `grainstore-manifest`):

```toml
[mirrors.rye_compiler]
platform = "codeberg"
org = "ryelang"
repo = "rye"
path = "grainstore/codeberg/ryelang/rye"
url = "https://codeberg.org/ryelang/rye.git"
strategy = "pull"  # Pull from external repo into monorepo
```

---

## Development Workflow

### External Development (Primary)

**Location**: `~/codeberg/ryelang/rye`

1. **Edit** files in `~/codeberg/ryelang/rye`
2. **Commit** changes locally
3. **Push** to `codeberg.org/ryelang/rye`
4. **Grainmirror** syncs into monorepo automatically

### Monorepo Integration (Reference)

**Location**: `grainstore/codeberg/ryelang/rye` (in monorepo)

- **Read-only** reference copy
- **Synced** from external repository
- **Used** for integration testing and documentation
- **Not edited** directly (edits happen in external location)

---

## Grainmirror Sync Commands

### Manual Sync

```bash
# From monorepo root
cd /home/xy/ry

# Sync Rye compiler
grainmirror sync ryelang/rye

# Or sync all mirrors
grainmirror sync
```

### Automatic Sync (Future)

When grainmirror is rewritten in Rye, it can:
- Watch for changes in `~/codeberg/ryelang/rye`
- Automatically sync to `grainstore/codeberg/ryelang/rye`
- Provide real-time updates

---

## Why Not Symlinks?

**Problem**: Cursor's filetree doesn't track symlinks well

**Solution**: Grainmirror copies files (not symlinks) into grainstore

**Benefits**:
- ✅ Cursor filetree works correctly
- ✅ Monorepo has complete reference copy
- ✅ No nested `.git` folders in monorepo
- ✅ Clean separation between external dev and monorepo

**Trade-offs**:
- ⚠️ Requires sync step (manual or automatic)
- ⚠️ Monorepo copy may lag behind external edits

---

## Integration with Basin Kernel

### Build System Integration

**Current** (Phase 1 - Transpiler):
```bash
# Basin uses Rye transpiler from monorepo
cd /home/xy/ry
rye build src/basin/hello_riscv.ry  # Transpiles to Zig
zig build basin-rv64                # Compiles with Zig
```

**Future** (Phase 2 - Native Compiler):
```bash
# Basin uses Rye compiler from grainstore
cd /home/xy/ry
grainstore/codeberg/ryelang/rye/build/bin/rye build src/basin/hello_riscv.ry
# Or if Rye is in PATH:
rye build src/basin/hello_riscv.ry
```

### Version Alignment

**Rye Compiler Version**: Chronological (e.g., `20260122.065200.rye`)  
**Basin Kernel Version**: Chronological (e.g., `20260122.065200.basin`)  
**Alignment**: Both use same timestamp format, can track compatibility

---

## File Structure

```
~/codeberg/ryelang/rye/          # External development (editable)
├── .git/                        # Git repository
├── src/                         # Rye compiler source
├── build.zig                    # Build configuration
├── THIRD_PARTY_LICENSES.md     # Zig attribution
└── README.md                    # Rye compiler docs

/home/xy/ry/                     # Monorepo
├── grainstore/
│   └── codeberg/
│       └── ryelang/
│           └── rye/             # Mirrored copy (read-only reference)
│               ├── src/         # Synced from external
│               ├── build.zig    # Synced from external
│               └── ...          # All files synced
└── src/
    └── basin/                   # Basin kernel (uses Rye compiler)
```

---

## Verification

### Check External Repository

```bash
cd ~/codeberg/ryelang/rye
git remote -v
git log --oneline -5
```

### Check Grainstore Mirror

```bash
cd /home/xy/ry
ls -la grainstore/codeberg/ryelang/rye/
# Should show synced files
```

### Check Sync Status

```bash
cd /home/xy/ry
grainmirror status ryelang/rye
```

---

## Troubleshooting

### Sync Not Working

**Problem**: Changes in `~/codeberg/ryelang/rye` not appearing in grainstore

**Solution**:
1. Ensure changes are pushed to `codeberg.org/ryelang/rye`
2. Run `grainmirror sync ryelang/rye` manually
3. Check grainmirror logs for errors

### Cursor Filetree Issues

**Problem**: Files not showing in Cursor filetree

**Solution**: Ensure grainmirror uses file copies (not symlinks)

### Build System Issues

**Problem**: Basin can't find Rye compiler

**Solution**: 
1. Ensure Rye is built: `cd ~/codeberg/ryelang/rye && rye build`
2. Add to PATH or use full path in build.zig
3. Verify grainstore mirror is synced

---

## References

- **Repository Setup**: `docs/rye/0012-rye-repository-setup-guide.md`
- **Fork Plan**: `docs/rye/0011-rye-compiler-fork-plan.md`
- **Grainmirror Strategy**: `docs/rye/0006-multi-repo-grainmirror-strategy.md`
- **Grainmirror Rewrite Plan**: `docs/rye/0018-grainmirror-rye-rewrite-plan.md`

---

**Date**: 2026-01-22-065200-pst  
**Status**: 🆕 **SETUP GUIDE** — Grainmirror configuration for Rye compiler fork
