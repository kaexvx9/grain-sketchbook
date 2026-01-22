# Rye Compiler Setup Status

**Date**: 2026-01-22-065209-pst  
**Status**: ✅ **EXTERNAL REPO READY** — Setup complete, push pending authentication  
**Repository**: `codeberg.org/ryelang/rye`

---

## Setup Complete

### External Repository

**Location**: `~/codeberg/ryelang/rye`  
**Status**: ✅ Ready

**Completed Steps**:
1. ✅ Cloned Zig 0.15.2 from `codeberg.org/ziglang/zig`
2. ✅ Checked out tag `0.15.2` (commit: `e4cbd752c8c05f131051f8c873cff7823177d7d3`)
3. ✅ Created branch `rye-0.15.2-base`
4. ✅ Set up remotes:
   - `origin` → `https://codeberg.org/ryelang/rye.git`
   - `upstream` → `https://codeberg.org/ziglang/zig.git`
5. ✅ Created `THIRD_PARTY_LICENSES.md` with Zig attribution
6. ✅ Created initial attribution commit
7. ✅ Created `main` branch from base

**Pending Steps** (require authentication):
- ⏳ Push `rye-0.15.2-base` branch to Codeberg
- ⏳ Push `main` branch to Codeberg

**To Complete**:
```bash
cd ~/codeberg/ryelang/rye
git push -u origin rye-0.15.2-base
git push -u origin main
```

---

## Grainstore Mirror Setup

**Location**: `grainstore/codeberg/ryelang/rye`  
**Status**: ⏳ Pending (after push to Codeberg)

**Next Steps**:
1. Push external repository to Codeberg (requires authentication)
2. Clone into grainstore:
   ```bash
   cd /home/xy/ry/grainstore/codeberg/ryelang
   git clone https://codeberg.org/ryelang/rye.git
   ```
3. Add to `.gitignore` (if not already):
   ```
   grainstore/codeberg/ryelang/rye/
   ```
4. Update `src/grain_manifest.zig` (optional, for future grainmirror integration)

---

## Manifest Entry (Future)

When grainmirror is fully functional, add to manifest:

**Location**: `src/grain_manifest.zig`

**Entry**:
```zig
.{ .platform = "codeberg", .org = "ryelang", .repo = "rye" },
```

**Or TOML format** (if grainmirror uses TOML):
```toml
[mirrors.rye_compiler]
platform = "codeberg"
org = "ryelang"
repo = "rye"
path = "grainstore/codeberg/ryelang/rye"
url = "https://codeberg.org/ryelang/rye.git"
```

---

## Development Workflow

### External Development (Primary)

**Location**: `~/codeberg/ryelang/rye`

1. **Edit** files in `~/codeberg/ryelang/rye`
2. **Commit** changes locally
3. **Push** to `codeberg.org/ryelang/rye` (after authentication setup)
4. **Grainmirror** syncs into monorepo (when functional)

### Monorepo Integration (Reference)

**Location**: `grainstore/codeberg/ryelang/rye` (in monorepo)

- **Read-only** reference copy
- **Synced** from external repository
- **Used** for integration testing and documentation
- **Not edited** directly (edits happen in external location)

---

## Authentication Setup

### Option 1: SSH Keys (Recommended)

```bash
# Generate SSH key if needed
ssh-keygen -t ed25519 -C "your_email@example.com"

# Add to Codeberg: https://codeberg.org/user/settings/keys

# Update remote to use SSH
cd ~/codeberg/ryelang/rye
git remote set-url origin git@codeberg.org:ryelang/rye.git
```

### Option 2: Personal Access Token

```bash
# Create token: https://codeberg.org/user/settings/applications
# Use token as password when pushing

cd ~/codeberg/ryelang/rye
git push -u origin rye-0.15.2-base
# Enter username and token when prompted
```

---

## Verification Checklist

### External Repository

- [x] Repository cloned from Zig 0.15.2
- [x] Tag 0.15.2 checked out
- [x] Remotes configured correctly
- [x] THIRD_PARTY_LICENSES.md created
- [x] Initial commit created
- [ ] Pushed to Codeberg (pending authentication)

### Grainstore Mirror

- [ ] Directory structure created
- [ ] Repository cloned into grainstore
- [ ] .gitignore updated
- [ ] Manifest entry added (optional)

---

## Next Steps

1. **Set up authentication** for Codeberg (SSH keys or token)
2. **Push** external repository to Codeberg
3. **Clone** into grainstore for monorepo reference
4. **Update** manifest when grainmirror is functional
5. **Begin** RISC-V freestanding bug fixes (see `docs/rye/0013-riscv-freestanding-fix-strategy.md`)

---

## References

- **Repository Setup Guide**: `docs/rye/0012-rye-repository-setup-guide.md`
- **Grainmirror Setup**: `docs/rye/0017-rye-compiler-grainmirror-setup.md`
- **Fork Plan**: `docs/rye/0011-rye-compiler-fork-plan.md`
- **RISC-V Fix Strategy**: `docs/rye/0013-riscv-freestanding-fix-strategy.md`

---

**Date**: 2026-01-22-065209-pst  
**Status**: ✅ **EXTERNAL REPO READY** — Setup complete, push pending authentication
