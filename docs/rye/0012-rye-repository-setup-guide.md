# Rye Repository Setup Guide

**Date**: 2026-01-22-062923-pst  
**Status**: 🆕 **SETUP GUIDE** — Instructions for creating `codeberg.org/rye/rye` repository  
**Base**: Zig 0.15.2 (https://codeberg.org/ziglang/zig/src/tag/0.15.2)

---

## Repository Creation

### Step 1: Create Repository on Codeberg

1. **Go to**: https://codeberg.org/rye
2. **Create new repository**: `rye`
3. **Description**: "Rye compiler - Fork of Zig 0.15.2, adapted for RISC-V freestanding, toroidal types, and Rye Style enforcement"
4. **Visibility**: Public
5. **Initialize**: Don't initialize with README (we'll clone Zig first)

---

## Step 2: Clone and Fork Zig 0.15.2

```bash
# Clone Zig repository
git clone https://codeberg.org/ziglang/zig.git rye
cd rye

# Checkout Zig 0.15.2 tag
git checkout 0.15.2

# Create base branch for Rye
git checkout -b rye-0.15.2-base

# Rename remote to upstream
git remote rename origin upstream

# Add Rye repository as origin
git remote add origin https://codeberg.org/rye/rye.git

# Verify remotes
git remote -v
# Should show:
# origin    https://codeberg.org/rye/rye.git (fetch)
# origin    https://codeberg.org/rye/rye.git (push)
# upstream  https://codeberg.org/ziglang/zig.git (fetch)
# upstream  https://codeberg.org/ziglang/zig.git (push)
```

---

## Step 3: Create Initial Attribution Commit

```bash
# Create THIRD_PARTY_LICENSES.md (see template below)
# Create initial commit with attribution

git add THIRD_PARTY_LICENSES.md
git commit -m "rye: fork from zig 0.15.2 with attribution

2026-01-22-062923-pst

forked from:
- ziglang/zig tag 0.15.2
- https://codeberg.org/ziglang/zig/src/tag/0.15.2
- commit: [ZIG_0.15.2_COMMIT_HASH]

rye adaptations planned:
- fix risc-v freestanding codegen bugs (see docs/zig/2025-06-30-riscv64-freestanding-codegen-issues.md)
- add toroidal/garden types as first-class language features
- enforce rye style constraints (64 lines, 128 chars, why comments)
- chronological versioning (non-semantic: YYYYMMDD.HHMMSS.variant)
- garden-allocation model (not linux heap model)

see THIRD_PARTY_LICENSES.md for zig license and attribution

rye style: explicit attribution, chronological versioning, toroidal bounded model"
```

---

## Step 4: Update Versioning

```bash
# Update version strings to chronological
# Find and replace semantic versioning with chronological

# Example locations to update:
# - src/main.zig (version string)
# - README.md (version references)
# - build.zig (version constants)
# - CHANGELOG.md (format)

# Use chronological format: 20260122.062923.rye
```

---

## Step 5: Rename Compiler Binary

```bash
# Rename 'zig' to 'rye' throughout codebase
# Update:
# - Binary name: zig → rye
# - Command names: zig build → rye build, zig test → rye test
# - Documentation references
# - Error messages
```

---

## Step 6: Push to Rye Repository

```bash
# Push base branch
git push -u origin rye-0.15.2-base

# Create main branch from base
git checkout -b main
git push -u origin main
```

---

## THIRD_PARTY_LICENSES.md Template

```markdown
# Third-Party License Attributions

This file contains license attributions for third-party software used in the Rye compiler.

---

## Zig Compiler

**Repository**: https://codeberg.org/ziglang/zig  
**Tag**: 0.15.2  
**Commit**: [ZIG_0.15.2_COMMIT_HASH]  
**License**: MIT License  
**Copyright**: Copyright (c) 2015-2025 Zig contributors

Rye is a fork of Zig 0.15.2, adapted for:
- RISC-V freestanding codegen fixes
- Toroidal/garden type system
- Rye Style enforcement
- Chronological versioning
- Garden-allocation model

### MIT License

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

---

## LLVM

**Repository**: https://github.com/llvm/llvm-project  
**License**: Apache License 2.0 with LLVM Exceptions  
**Copyright**: LLVM Project contributors

Rye uses LLVM as its code generation backend (inherited from Zig).

[Full LLVM license text with exceptions]

---

## Other Dependencies

[Add other dependencies as needed]
```

---

## Verification Checklist

After setup, verify:

- [ ] Repository created at `codeberg.org/rye/rye`
- [ ] Zig 0.15.2 tag checked out
- [ ] Upstream remote points to `ziglang/zig`
- [ ] Origin remote points to `rye/rye`
- [ ] THIRD_PARTY_LICENSES.md created with Zig attribution
- [ ] Initial attribution commit created
- [ ] Version strings updated to chronological format
- [ ] Compiler binary renamed (zig → rye)
- [ ] Base branch pushed to repository
- [ ] Main branch created and pushed

---

## Next Steps After Setup

1. **Document RISC-V Fixes**: Create detailed fix strategy document
2. **Add Toroidal Types**: Design standard library types
3. **Integrate Rye Style**: Plan compiler enforcement
4. **Test with Basin**: Verify fixes work with Basin kernel

---

**Date**: 2026-01-22-062923-pst  
**Status**: 🆕 **SETUP GUIDE** — Instructions for creating `codeberg.org/rye/rye` repository
