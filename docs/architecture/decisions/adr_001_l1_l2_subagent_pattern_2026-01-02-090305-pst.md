# ADR 001: L1 Subcore/L2 Sub-Agent Pattern for Aurora 2 Subcore

**Date**: 2026-01-02-090305-pst  
**Status**: ✅ **ACCEPTED**  
**Deciders**: Aurora 2 Subcore Agent, Core 1 Subcore Agent  
**Context**: Aurora Agent needed to enable parallelization of IDE/Browser work

---

## Context

Aurora Agent (2nd Agent) was handling all IDE/Browser services (Editor, Browser, Component Library) as a single agent, limiting parallelization and development velocity.

**Problem**:
- Single agent handling three distinct domains
- Limited parallelization
- Slower development velocity
- Less specialization

---

## Decision

Evolve **Grain Aurora Agent** into **Aurora 2 Subcore (L1 Subcore Coordinator)** with 3 L2 sub-agents, following the proven Core 1 Subcore and Vantage 3 Subcore pattern.

**Structure**:
- **Aurora 2 Subcore (L1)**: IDE/Browser architecture coordination
- **2a. Dream Editor Agent (L2)**: IDE features (LSP, Tree-sitter, AI integration, editor core)
- **2b. Dream Browser Agent (L2)**: Browser features (Nostr, WebSocket, HTML/CSS rendering)
- **2c. Component Library Agent (L2)**: UI components (Component API, basic UI components, JG Project UI)

---

## Consequences

### Positive

- ✅ Enables parallelization of IDE/Browser work
- ✅ Clear separation of concerns (Editor, Browser, Component Library)
- ✅ Better coordination model (L1 Subcore coordinates, L2 sub-agents implement)
- ✅ Matches proven L1/L2 pattern from Core 1 Subcore and Vantage 3 Subcore
- ✅ Better specialization per domain
- ✅ Faster development velocity

### Negative

- Additional coordination overhead (weekly/bi-weekly check-ins)
- More coordination documents to maintain

### Neutral

- Architecture evolution required (documentation, coordination structure)
- L2 sub-agents need to be created and initialized

---

## Alternatives Considered

1. **Keep Single Aurora Agent**: Rejected — limits parallelization
2. **Separate Agents (No Subcore)**: Rejected — no coordination model, harder to manage
3. **L1 Subcore/L2 Sub-Agent Pattern**: **ACCEPTED** — proven pattern, enables parallelization

---

## Implementation

**Date**: 2025-12-31-192740-pst  
**Status**: ✅ **COMPLETE**

**Completed**:
- ✅ L1 Subcore/L2 Sub-Agent pattern implemented
- ✅ L2 sub-agent prompts created
- ✅ Coordination documents created
- ✅ All documentation structure complete

---

**References**:
- `docs/aurora_2_subcore_sub_agent_proposal_2025-12-31.md`
- `docs/core-coordination/aurora_2_subcore_coordination.md`

