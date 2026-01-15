# ADR 002: Component API Design - Unified API for Editor, Browser, and JG Project

**Date**: 2026-01-02-090305-pst  
**Status**: ✅ **ACCEPTED**  
**Deciders**: Aurora 2 Subcore Agent, Component Library Agent (2c), Editor Agent (2a), Browser Agent (2b)  
**Context**: Need unified Component API for Editor, Browser, and future JG Project components

---

## Context

Editor and Browser agents need UI components, but they were using separate approaches. Future JG Project components also need Component API. Need unified approach for consistency and reuse.

**Problem**:
- Editor Agent needs UI components for multi-pane layout
- Browser Agent has existing Component API but needs enhancement
- Future JG Project components need Component API
- Need unified, consistent approach

---

## Decision

Design unified Component API that works for Editor, Browser, and future JG Project components, following these principles:

**Design Principles**:
1. **Reuse Existing**: Use Workspace Agent's base Component types (`src/grain_workspace/components.zig`)
2. **Build on Existing**: Build on existing Browser Component API structure
3. **Unified Interface**: Single Component API for all applications
4. **GrainAurora Integration**: Integrate with GrainAurora rendering system
5. **Grain Style Compliance**: Follow GrainStyle principles (grain_case, u32/u64, bounded allocations)

**Component ID Allocation**:
- Workspace Agent: IDs 1-29 (base Component types)
- Browser Agent: IDs 30-69 (Browser UI components)
- Editor Agent: IDs 70-99 (Editor UI components)
- Component Library: IDs 1000-9999 (Phase 2: basic UI components, future)

---

## Consequences

### Positive

- ✅ Unified Component API for all applications
- ✅ Consistent component lifecycle management
- ✅ Reuse of existing base Component types
- ✅ Clear Component ID allocation
- ✅ GrainAurora rendering integration
- ✅ Type-safe component operations

### Negative

- Component Library Agent must implement Component API (Phase 1)
- Editor and Browser agents must integrate with Component API
- Migration from existing Browser Component API needed

### Neutral

- Component API design complete (Phase 0.5)
- Implementation in progress (Phase 1)

---

## Alternatives Considered

1. **Separate Component APIs**: Rejected — duplication, inconsistency
2. **Editor-Specific Component API**: Rejected — doesn't support Browser or JG Project
3. **Browser-Specific Component API**: Rejected — doesn't support Editor or JG Project
4. **Unified Component API**: **ACCEPTED** — consistent, reusable, supports all applications

---

## Implementation

**Date**: 2025-12-31 (Phase 0.5 design complete)  
**Status**: ⏳ **IN PROGRESS** (Phase 1 implementation pending)

**Completed**:
- ✅ Component API design document (`docs/component_api_design.md`)
- ✅ Editor Agent requirements provided
- ✅ Browser Agent requirements provided
- ✅ Requirements summary created

**Pending**:
- ⏳ Component API Phase 1 implementation
- ⏳ Editor Agent Component API integration
- ⏳ Browser Agent Component API integration

---

**References**:
- `docs/component_api_design.md`
- `docs/agent-communications/aurora_2_subcore_component_api_requirements_summary_2026-01-02-084411-pst.md`

