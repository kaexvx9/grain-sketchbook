# ADR 003: Component ID Allocation Strategy

**Date**: 2026-01-02-090305-pst  
**Status**: ✅ **ACCEPTED**  
**Deciders**: Aurora 2 Subcore Agent, Component Library Agent (2c), Editor Agent (2a), Browser Agent (2b), Workspace Agent  
**Context**: Need non-overlapping Component ID ranges for all agents using Component API

---

## Context

Multiple agents need Component IDs for their UI components. Need to allocate non-overlapping ID ranges to prevent conflicts.

**Problem**:
- Workspace Agent uses Component IDs 1-29 (base Component types)
- Browser Agent needs Component IDs for Browser UI components
- Editor Agent needs Component IDs for Editor UI components
- Component Library needs Component IDs for basic UI components
- Need non-overlapping allocation strategy

---

## Decision

Allocate Component ID ranges as follows:

**Component ID Allocation**:
- **Workspace Agent**: IDs 1-29 (existing, base Component types)
- **Browser Agent**: IDs 30-69 (40 components)
  - 30-34: NavigationComponents
  - 40-42: AddressBarComponents
  - 50-53: TabComponents
  - 60-62: BrowserViewComponents
  - 35-39, 43-49, 54-59, 63-69: Reserved for future browser components
- **Editor Agent**: IDs 70-99 (30 components)
  - 70-79: EditorPaneComponents
  - 80-89: EditorTabComponents
  - 90-95: EditorStatusBarComponents
  - 96-99: EditorToolbarComponents
- **Component Library**: IDs 1000-9999 (Phase 2: basic UI components, future)

**Allocation Principles**:
1. Non-overlapping ranges (no conflicts)
2. Sufficient capacity for each agent
3. Clear boundaries between agents
4. Room for future expansion

---

## Consequences

### Positive

- ✅ Non-overlapping Component ID ranges
- ✅ Clear boundaries between agents
- ✅ Sufficient capacity for each agent
- ✅ Room for future expansion
- ✅ No Component ID conflicts

### Negative

- Non-consecutive IDs for Browser Agent (30-34, 40-42, 50-53, 60-62 with gaps)
- Gaps in allocation (intentional for future expansion)

### Neutral

- Component ID allocation is documented and confirmed
- Allocation strategy supports future growth

---

## Alternatives Considered

1. **Sequential Allocation**: Rejected — doesn't provide room for expansion
2. **Dynamic Allocation**: Rejected — adds complexity, harder to manage
3. **Fixed Ranges with Gaps**: **ACCEPTED** — provides room for expansion, clear boundaries

---

## Implementation

**Date**: 2026-01-01 (requirements confirmed)  
**Status**: ✅ **CONFIRMED**

**Confirmed**:
- ✅ Workspace Agent: IDs 1-29 (existing)
- ✅ Browser Agent: IDs 30-69 (confirmed 2026-01-01-085600-pst)
- ✅ Editor Agent: IDs 70-99 (confirmed 2026-01-01-084922-pst)
- ✅ Component Library: IDs 1000-9999 (design document)

---

**References**:
- `docs/component_api_design.md`
- `docs/core-coordination/aurora_2a_editor_component_requirements_2026-01-01-084922-pst.md`
- `docs/core-coordination/aurora_2b_browser_component_requirements_2026-01-01-085600-pst.md`

