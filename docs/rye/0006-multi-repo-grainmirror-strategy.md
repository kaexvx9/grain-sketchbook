# Multi-Repository Strategy: Grainmirror Federation

**Date**: 2026-01-20
**Status**: Planning
**Monorepo**: codeberg.org/keatonlivermore/grain-sketchbook

---

## Overview

This document outlines the strategy for managing multiple component repositories that federate into the main monorepo via grainmirror.

---

## Repository Map

| Repo | URL | Purpose | Status |
|------|-----|---------|--------|
| **ry** | codeberg.org/keatonlivermore/grain-sketchbook | Monorepo (current home) | Active |
| **grain** | codeberg.org/grain | Grain OS core | Acquired |
| **basin** | codeberg.org/basin | Basin kernel | Acquired |
| **tend** | codeberg.org/tend | Tend philosophy/allocator | Acquired |
| **skate** | codeberg.org/skate | Visual programming | Acquired |
| **realidream** | codeberg.org/realidream | Browser engine | Acquired |
| **reya** | codeberg.org/reya | Virtual assistant | Acquired |
| **court** | codeberg.org/court | Governance/consensus | Acquired |
| **rye** | codeberg.org/ryelang (?) | Rye language compiler | Unavailable |
| **aurora** | codeberg.org/grain-aurora (?) | IDE/editor | Unavailable |

---

## Grainmirror Pattern

### Directory Structure

```
keatonlivermore/grain-sketchbook/
├── src/                    # Main source (owned by ry)
├── vendor/
│   ├── grain/              # Mirror of grain/grain
│   ├── basin/              # Mirror of basin/basin
│   ├── tend/               # Mirror of tend/tend
│   ├── skate/              # Mirror of skate/skate
│   ├── realidream/         # Mirror of realidream/realidream
│   ├── reya/               # Mirror of reya/reya
│   └── court/              # Mirror of court/court
└── grainmirror.toml        # Mirror configuration
```

### Mirror Configuration

```toml
# grainmirror.toml

[mirrors]
grain = { url = "codeberg.org/grain/grain", path = "vendor/grain" }
basin = { url = "codeberg.org/basin/basin", path = "vendor/basin" }
tend = { url = "codeberg.org/tend/tend", path = "vendor/tend" }
skate = { url = "codeberg.org/skate/skate", path = "vendor/skate" }
realidream = { url = "codeberg.org/realidream/realidream", path = "vendor/realidream" }
reya = { url = "codeberg.org/reya/reya", path = "vendor/reya" }
court = { url = "codeberg.org/court/court", path = "vendor/court" }

[sync]
strategy = "pull"           # Pull from component repos into monorepo
frequency = "on-demand"     # Manual sync via grainmirror sync
```

---

## Development Workflow

### Option A: Monorepo-First (Current)

1. All development happens in `keatonlivermore/grain-sketchbook`
2. Periodically extract components to their repos
3. Component repos are read-only mirrors

**Pros**: Simple, single source of truth
**Cons**: Components not independently usable

### Option B: Component-First

1. Develop components in their own repos
2. Grainmirror syncs into monorepo
3. Monorepo integrates and tests

**Pros**: Components are standalone, easier collaboration
**Cons**: More complex sync, potential conflicts

### Option C: Hybrid (Recommended)

1. **Core development** in monorepo (`ry`)
2. **Stable releases** pushed to component repos
3. **External contributions** via component repos, merged into monorepo
4. Grainmirror handles bidirectional sync

```
External contributor
        │
        ▼
   skate/skate ───────────────┐
        │                     │
        │ PR                  │ grainmirror sync
        ▼                     ▼
   Issue/Review          keatonlivermore/grain-sketchbook
        │                     │
        │                     │ grainmirror push
        ▼                     ▼
   Merge to skate ◄───── Release tag
```

---

## Issue Management

### Per-Repo Issues

Each component repo has its own issue tracker:

| Repo | Issue Focus |
|------|-------------|
| grain/grain | OS-level issues, distribution |
| basin/basin | Kernel bugs, syscalls |
| skate/skate | Visual programming UX |
| realidream/realidream | Browser rendering, web compat |
| reya/reya | AI assistant behavior |
| court/court | Governance, voting |

### Monorepo Issues

`keatonlivermore/grain-sketchbook` tracks:
- Cross-component integration
- Build system issues
- Release coordination
- Architecture decisions

### Issue Labels (Shared)

```
component:grain
component:basin
component:skate
component:realidream
component:reya
component:court
priority:high
priority:medium
priority:low
type:bug
type:feature
type:docs
```

---

## Collaboration Model

### Maintainers

| Repo | Primary | Backup |
|------|---------|--------|
| ry | Keaton | AI agents |
| grain | TBD | - |
| basin | TBD | - |
| skate | TBD | - |
| realidream | TBD | - |
| reya | TBD | - |
| court | TBD | - |

### Contribution Flow

1. **Fork** component repo (e.g., `skate/skate`)
2. **Branch** for feature/fix
3. **PR** to component repo
4. **Review** by maintainer
5. **Merge** to component repo
6. **Sync** to monorepo via grainmirror
7. **Integration test** in monorepo
8. **Release** propagates back to component repos

---

## Future: Monorepo Migration

Eventually the monorepo may move:

| Current | Future Option |
|---------|---------------|
| keatonlivermore/grain-sketchbook | grain/grain (OS is primary) |
| keatonlivermore/grain-sketchbook | basin/basin (kernel is primary) |
| keatonlivermore/grain-sketchbook | ryelang/rye (language is primary) |

Decision criteria:
- Which component becomes the primary identity?
- Where do users expect to find the project?
- Which community grows largest?

**For now**: Keep `keatonlivermore/grain-sketchbook` as monorepo home.

---

## Action Items

### Immediate (This Week)
- [ ] Reserve remaining repo names on Codeberg
- [ ] Set up placeholder READMEs

### Short-term (This Month)
- [ ] Create grainmirror.toml structure
- [ ] Test bidirectional sync
- [ ] Document contribution guide per repo

### Long-term
- [ ] Populate component repos with extracted code
- [ ] Enable issue tracking per component
- [ ] Establish maintainer roles

---

## Acquired Repos

- [x] codeberg.org/grain - Grain OS core
- [x] codeberg.org/skate - Visual programming
- [x] codeberg.org/basin - Basin kernel
- [x] codeberg.org/court - Governance/consensus
- [x] codeberg.org/reya - Virtual assistant
- [x] codeberg.org/tend - Tend philosophy/allocator
- [x] codeberg.org/realidream - Browser engine
- [ ] codeberg.org/rye - **Unavailable** (alternative: `ryelang`?)
- [ ] codeberg.org/aurora - **Unavailable** (alternative: `grain-aurora`?)
