# ADR 004: Shared Module Coordination Strategy

**Date**: 2026-01-02-090305-pst  
**Status**: ✅ **ACCEPTED**  
**Deciders**: Aurora 2 Subcore Agent, Editor Agent (2a), Browser Agent (2b), Component Library Agent (2c)  
**Context**: Multiple sub-agents need to share modules (GrainBuffer, DAG Core, font renderer)

---

## Context

Editor Agent, Browser Agent, and Component Library Agent need to share modules (GrainBuffer for text buffer, DAG Core for event recording, font renderer for rendering). Need coordination strategy to prevent conflicts and ensure consistency.

**Problem**:
- Multiple sub-agents use shared modules
- Need to prevent conflicts in shared module usage
- Need coordination for shared module changes
- Need consistency across sub-agents

---

## Decision

Aurora 2 Subcore (L1) coordinates shared module usage and changes, following this protocol:

**Coordination Protocol**:
1. **Change Notification**: Sub-agent identifies need for shared module change
2. **Coordination**: Sub-agent coordinates with Aurora 2 Subcore
3. **Review**: Aurora 2 Subcore coordinates with affected sub-agents
4. **Approval**: Aurora 2 Subcore approves and implements change
5. **Update**: All sub-agents update to use new shared module version

**Shared Modules**:
- **GrainBuffer** (`src/grain_buffer.zig`): Shared between Editor Agent (2a) and Component Library Agent (2c)
- **DAG Core** (`src/dag_core.zig`): Shared between all sub-agents (Editor, Browser, Component Library)
- **Shared Font Renderer** (`src/shared/`): Shared between all sub-agents

**Coordination Model**:
- Aurora 2 Subcore coordinates shared module changes
- Sub-agents coordinate via Aurora 2 Subcore (not directly)
- Changes require Aurora 2 Subcore approval

---

## Consequences

### Positive

- ✅ Consistent shared module usage
- ✅ No conflicts in shared module changes
- ✅ Clear coordination process
- ✅ Centralized change management

### Negative

- Additional coordination overhead (changes require Aurora 2 Subcore approval)
- Slightly slower change process (coordination required)

### Neutral

- Coordination protocol established
- Shared module usage documented

---

## Alternatives Considered

1. **No Coordination**: Rejected — risks conflicts, inconsistency
2. **Direct Coordination**: Rejected — complex, harder to manage
3. **L1 Subcore Coordination**: **ACCEPTED** — clear process, centralized management

---

## Implementation

**Date**: 2025-12-31 (architecture evolution)  
**Status**: ✅ **ACTIVE**

**Active**:
- ✅ Aurora 2 Subcore coordinates shared module changes
- ✅ Coordination protocol documented
- ✅ Shared module usage patterns documented

---

**References**:
- `docs/core-coordination/aurora_2_subcore_coordination.md`
- `docs/architecture/aurora_2_integration_patterns_2026-01-02-090305-pst.md`

