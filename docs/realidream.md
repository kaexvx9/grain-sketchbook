# Realidream

**Repository**: [codeberg.org/realidream](https://codeberg.org/realidream)

---

## What is Realidream?

Realidream is the unified browser component of Grain OS, combining:

- **Reality** - Grounded in toroidal topology, garden allocation, deterministic execution
- **Dream** - Visionary UI architecture, streaming DAG updates, boundless creativity within bounds

Inspired by Noah B.'s EP "Realidream" and the Sanskrit concepts of:
- **Prakriti** (manifest reality) and **Purusha** (pure consciousness)
- **Maya** (creative illusion) and **Vishnu** (the preserver)

---

## Architecture

Realidream uses the Toroidal DAG UI backend shared with Aurora (editor) and Skate (visual programming):

```
┌─────────────────────────────────────────────────────────────┐
│                      Realidream Browser                      │
│                                                             │
│  DOM Elements → ToroidalDag → Streaming Updates             │
│  Garden-allocated · Bounded · Deterministic                 │
└─────────────────────────────────────────────────────────────┘
```

### Key Components

| File | Purpose |
|------|---------|
| `src/realidream_toroidal_integration.ry` | DOM integration with toroidal DAG |
| `src/realidream_browser_renderer.zig` | HTML/CSS rendering |
| `src/realidream_browser_parser.zig` | HTML parsing |
| `src/realidream_protocol.zig` | Network protocols |
| `src/realidream_browser_nostr.zig` | Nostr integration |

### Toroidal Benefits

1. **No OOM** - Garden allocation with bounded MAX_DOM_NODES
2. **No edge cases** - Toroidal indexing wraps naturally
3. **Deterministic** - Same input always produces same output
4. **Fast** - No bounds checks, no dynamic allocation

---

## Integration with Aurora and Skate

All three UI backends share the same underlying infrastructure:

```rye
const adapter = @import("kernel/dag_toroidal_adapter.zig");

// Each backend uses the same UnifiedDag
pub const RealidreamIntegration = struct {
    dag: adapter.UnifiedDag,
    // DOM-specific fields...
};

pub const AuroraIntegration = struct {
    dag: adapter.UnifiedDag,
    // AST-specific fields...
};

pub const SkateIntegration = struct {
    dag: adapter.UnifiedDag,
    // Visual-specific fields...
};
```

This enables:
- **Shared event propagation** - Changes in one backend can flow to others
- **Unified state model** - AST, DOM, and visual nodes in the same graph
- **Cross-backend linking** - Editor code linked to browser preview

---

## Naming

The name "Realidream" was chosen to replace "Dream Browser" because:

1. **Unique** - Available on Codeberg as `codeberg.org/realidream`
2. **Meaningful** - Captures the synthesis of grounded reality and creative vision
3. **One-syllable roots** - "Real" + "i" + "dream" flows naturally
4. **Philosophical depth** - Connects to Vedic concepts of manifest/unmanifest

---

## Status

| Metric | Value |
|--------|-------|
| Rye modules | 63 |
| Tests | 276/276 |
| Integration | Full toroidal DAG |
| Versioning | Chronological (20260120.0952) |

See [Toroidal DAG UI Architecture](rye/0005-toroidal-dag-ui-architecture.md) for technical details.
