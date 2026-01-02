# Core 1 Subcore: Architecture Decision Records (ADRs)

**Date**: 2026-01-02-010000-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: 🆕 **TEMPLATE CREATED** — ADR template and initial decisions documented

---

## Executive Summary

This document contains Architecture Decision Records (ADRs) for Core 1 Subcore system services. ADRs document major architecture decisions, trade-offs, rationale, alternatives considered, and impact analysis.

**Purpose**: Provide clear documentation of architecture decisions for future reference and coordination.

---

## ADR Template

### ADR Format

```markdown
## ADR-XXX: [Decision Title]

**Date**: YYYY-MM-DD-HHMMSS-pst  
**Status**: [Proposed | Accepted | Rejected | Deprecated | Superseded]  
**Context**: [What is the issue we're addressing?]  
**Decision**: [What is the decision we're making?]  
**Consequences**: [What are the consequences of this decision?]  
**Alternatives Considered**: [What alternatives did we consider?]  
**Trade-offs**: [What are the trade-offs?]  
**Impact**: [What is the impact on other components?]  
**References**: [Links to related documents]
```

---

## ADR-001: L1 Subcore/L2 Sub-Agent Pattern

**Date**: 2025-12-30-093745-pst  
**Status**: ✅ **ACCEPTED**  
**Context**: Core Agent (1st Agent) was handling all Core system services (Auth, Network, Storage, Compositor) as a single agent, limiting parallelization.

**Decision**: Implement L1 Subcore/L2 Sub-Agent pattern — Core Agent becomes Core 1 Subcore (L1 Subcore Coordinator) with 4 L2 sub-agents (1a Auth, 1b Network, 1c Storage, 1d Compositor).

**Consequences**:
- ✅ Enables parallelization of Core system services work
- ✅ Clear separation of concerns (Auth, Network, Storage, Compositor)
- ✅ Better coordination model (L1 Subcore coordinates, L2 sub-agents implement)
- ✅ Matches proven Vantage 3 Subcore pattern
- ⚠️ Requires coordination overhead (weekly/bi-weekly check-ins)

**Alternatives Considered**:
1. **Single Agent**: Keep all services in one agent (rejected — limits parallelization)
2. **Separate L1 Agents**: Make each service a separate L1 agent (rejected — too much coordination overhead)
3. **L1 Subcore/L2 Sub-Agent**: Current decision (accepted)

**Trade-offs**:
- **Pros**: Parallelization, clear boundaries, proven pattern
- **Cons**: Coordination overhead, additional documentation

**Impact**:
- Core 1 Subcore becomes coordinator
- L2 sub-agents work independently
- Coordination documents required
- Plan and tasks documents split

**References**:
- `docs/plans/core_1_subcore_plan.md`
- `docs/tasks/core_1_subcore_tasks.md`

---

## ADR-002: Grainscript Shell as Core 1 Subcore L2 Sub-Agent (1e)

**Date**: 2026-01-01-210806-pst  
**Status**: ✅ **ACCEPTED**  
**Context**: Grainscript Shell needed for Grain OS sevenos, required coordination with Core services and sevenos Init System.

**Decision**: Assign Grainscript Shell as Core 1 Subcore L2 sub-agent (1e), coordinate with sevenos Init System (3d) via cross-subcore coordination.

**Consequences**:
- ✅ Shell integrates with Core services (1a-1d)
- ✅ Shell coordinates with Init System (3d) via Core 1 ↔ Vantage 3 coordination
- ✅ Clear ownership and coordination model
- ⚠️ Requires cross-subcore coordination

**Alternatives Considered**:
1. **Separate L1 Agent**: Make Shell a separate L1 agent (rejected — too much coordination overhead)
2. **Vantage 3 Subcore**: Assign to Vantage 3 Subcore (rejected — Shell needs Core services integration)
3. **Core 1 Subcore L2**: Current decision (accepted)

**Trade-offs**:
- **Pros**: Clear integration with Core services, manageable coordination
- **Cons**: Cross-subcore coordination required for Init System

**Impact**:
- Core 1 Subcore coordinates Shell (1e)
- Cross-subcore coordination with Vantage 3 Subcore for Init System (3d)
- Shell integration tests require cross-subcore coordination

**References**:
- `docs/core-coordination/core_1_subcore_coordination_plan_2026-01-01-233240-pst.md`
- `docs/core-coordination/vantage_3d_sevenos_init_coordination.md`

---

## ADR-003: Integration Test Framework Design

**Date**: 2026-01-02-004000-pst  
**Status**: ✅ **ACCEPTED**  
**Context**: Need integration testing framework for cross-sub-agent integration testing.

**Decision**: Create integration test framework (`tests/integration/core_1_subcore/runner.zig`) with test runner, isolation helpers, and result reporting.

**Consequences**:
- ✅ Standardized integration test structure
- ✅ Test isolation and cleanup
- ✅ Result tracking and reporting
- ✅ Ready for L2 sub-agent integration tests

**Alternatives Considered**:
1. **No Framework**: Write tests without framework (rejected — inconsistent structure)
2. **External Framework**: Use external testing framework (rejected — not Grain Style compliant)
3. **Custom Framework**: Current decision (accepted)

**Trade-offs**:
- **Pros**: Grain Style compliant, tailored to our needs, consistent structure
- **Cons**: Custom implementation, maintenance overhead

**Impact**:
- All integration tests use framework
- Consistent test structure
- Easier test maintenance

**References**:
- `tests/integration/core_1_subcore/runner.zig`
- `docs/core-coordination/core_1_subcore_integration_test_framework_2026-01-02-004000-pst.md`

---

## ADR-004: API Contract Pattern Design

**Date**: 2026-01-02-004500-pst  
**Status**: ✅ **ACCEPTED**  
**Context**: Need standardized API contract patterns for cross-sub-agent integration.

**Decision**: Define 5 core API contract patterns (Auth↔Network, Network↔Storage, Storage↔Auth, Compositor↔Storage, Shell↔Core Services) with explicit function signatures, error handling, and resource management.

**Consequences**:
- ✅ Consistent API contract design
- ✅ Clear integration patterns
- ✅ Standardized error handling
- ✅ Standardized resource management

**Alternatives Considered**:
1. **Ad-Hoc Contracts**: Design contracts as needed (rejected — inconsistent)
2. **External Patterns**: Use external API patterns (rejected — not Grain Style compliant)
3. **Custom Patterns**: Current decision (accepted)

**Trade-offs**:
- **Pros**: Consistent, Grain Style compliant, tailored to our needs
- **Cons**: Custom patterns, documentation overhead

**Impact**:
- All L2 sub-agents follow patterns
- Consistent integration design
- Easier integration implementation

**References**:
- `docs/core-coordination/core_1_subcore_api_contract_patterns_2026-01-02-004500-pst.md`

---

## ADR-005: Explicit u32/u64 Types (No usize/isize)

**Date**: 2026-01-02-004000-pst  
**Status**: ✅ **ACCEPTED**  
**Context**: Platform-dependent types (`usize`/`isize`) cause cross-platform compatibility issues.

**Decision**: All Core 1 Subcore code must use explicit `u32`/`u64` types, never `usize`/`isize`.

**Consequences**:
- ✅ Cross-platform consistency
- ✅ Predictable behavior across architectures
- ✅ Framework Ubuntu x86_64 compatibility
- ⚠️ Requires explicit type conversions

**Alternatives Considered**:
1. **Use usize/isize**: Allow platform-dependent types (rejected — cross-platform issues)
2. **Explicit Types**: Current decision (accepted)

**Trade-offs**:
- **Pros**: Cross-platform consistency, predictable behavior
- **Cons**: Requires explicit conversions, more verbose

**Impact**:
- All L2 sub-agents must use explicit types
- All integration code must use explicit types
- Framework x86_64 compatibility ensured

**References**:
- `~/xy-mathematics/docs/grain_style.md`
- `docs/core-coordination/core_1_subcore_integration_best_practices_2026-01-02-005500-pst.md`

---

## ADR-006: Bounded Allocations (MAX_ Constants)

**Date**: 2026-01-02-004000-pst  
**Status**: ✅ **ACCEPTED**  
**Context**: Unbounded allocations can cause memory exhaustion and security issues.

**Decision**: All Core 1 Subcore code must use bounded allocations with MAX_ constants, never unbounded allocations.

**Consequences**:
- ✅ Memory safety
- ✅ Predictable resource usage
- ✅ Security (prevents DoS attacks)
- ⚠️ Requires careful sizing

**Alternatives Considered**:
1. **Unbounded Allocations**: Allow unbounded allocations (rejected — security risk)
2. **Bounded Allocations**: Current decision (accepted)

**Trade-offs**:
- **Pros**: Memory safety, security, predictable behavior
- **Cons**: Requires careful sizing, may need to reject large inputs

**Impact**:
- All L2 sub-agents must use bounded allocations
- All integration code must use bounded allocations
- API contracts must define MAX_ constants

**References**:
- `~/xy-mathematics/docs/grain_style.md`
- `docs/core-coordination/core_1_subcore_integration_best_practices_2026-01-02-005500-pst.md`

---

## ADR-007: Integration Test Framework Location

**Date**: 2026-01-02-004000-pst  
**Status**: ✅ **ACCEPTED**  
**Context**: Need to decide where integration tests live in the codebase.

**Decision**: Place Core 1 Subcore integration tests in `tests/integration/core_1_subcore/` directory.

**Consequences**:
- ✅ Clear organization
- ✅ Easy to find integration tests
- ✅ Separated from unit tests
- ✅ Supports future expansion

**Alternatives Considered**:
1. **tests/ Directory**: Mix with unit tests (rejected — hard to find)
2. **src/ Directory**: Place in source directory (rejected — not standard)
3. **tests/integration/**: Current decision (accepted)

**Trade-offs**:
- **Pros**: Clear organization, standard location
- **Cons**: Additional directory structure

**Impact**:
- All Core 1 Subcore integration tests in `tests/integration/core_1_subcore/`
- Consistent with other integration test locations

**References**:
- `tests/integration/core_1_subcore/runner.zig`

---

## ADR-008: Cross-Subcore Coordination Model

**Date**: 2026-01-02-003000-pst  
**Status**: ✅ **ACCEPTED**  
**Context**: Shell (1e) needs to integrate with Init System (3d), requiring cross-subcore coordination.

**Decision**: Use Core 1 Subcore ↔ Vantage 3 Subcore coordination for cross-subcore integration (1e ↔ 3d).

**Consequences**:
- ✅ Clear coordination model
- ✅ L1 Subcore coordinators handle cross-subcore coordination
- ✅ L2 sub-agents don't coordinate directly across subcores
- ⚠️ Requires L1 Subcore coordination overhead

**Alternatives Considered**:
1. **Direct L2 Coordination**: L2 sub-agents coordinate directly (rejected — too complex)
2. **L1 Subcore Coordination**: Current decision (accepted)

**Trade-offs**:
- **Pros**: Clear model, manageable coordination
- **Cons**: L1 Subcore coordination overhead

**Impact**:
- Core 1 Subcore coordinates with Vantage 3 Subcore
- Shell (1e) and Init System (3d) integration via L1 Subcores
- Cross-subcore integration tests require L1 Subcore coordination

**References**:
- `docs/core-coordination/core_1_subcore_system_integration_2026-01-02-003000-pst.md`

---

## ADR-009: Framework Ubuntu x86_64 Adaptation Strategy

**Date**: 2026-01-02-003000-pst  
**Status**: ✅ **ACCEPTED**  
**Context**: Need to adapt Core 1 Subcore services for Framework Ubuntu x86_64.

**Decision**: Adapt Core 1 Subcore services for Framework x86_64 while maintaining RISC-V kernel target (kernel runs in VM, JIT compiles to x86_64).

**Consequences**:
- ✅ Framework x86_64 native development
- ✅ RISC-V kernel in VM
- ✅ x86_64 JIT compilation
- ✅ Multi-architecture testing required

**Alternatives Considered**:
1. **RISC-V Only**: Keep RISC-V only (rejected — Framework x86_64 needed)
2. **x86_64 Native**: Make x86_64 native (rejected — RISC-V kernel needed)
3. **Hybrid Approach**: Current decision (accepted)

**Trade-offs**:
- **Pros**: Framework x86_64 development, RISC-V kernel maintained
- **Cons**: Multi-architecture complexity, JIT compilation required

**Impact**:
- All Core 1 Subcore services must work on Framework x86_64
- Multi-architecture testing required
- JIT compilation pipeline needed

**References**:
- `docs/core-coordination/core_1_subcore_system_integration_2026-01-02-003000-pst.md`

---

## ADR-010: Parallel Work Model

**Date**: 2025-12-30-093745-pst  
**Status**: ✅ **ACCEPTED**  
**Context**: Need to maximize development velocity while maintaining coordination.

**Decision**: Use parallel work model — Core 1 Subcore and L2 sub-agents work in parallel, with weekly/bi-weekly check-ins.

**Consequences**:
- ✅ Maximum development velocity
- ✅ Parallel work on different domains
- ✅ Coordination at check-in points
- ⚠️ Requires discipline to maintain coordination

**Alternatives Considered**:
1. **Sequential Work**: Work sequentially (rejected — too slow)
2. **Parallel Work**: Current decision (accepted)

**Trade-offs**:
- **Pros**: Maximum velocity, parallel development
- **Cons**: Requires coordination discipline

**Impact**:
- Core 1 Subcore works on coordination/integration
- L2 sub-agents work on domain-specific implementation
- Weekly/bi-weekly check-ins maintain coordination

**References**:
- `docs/plans/core_1_subcore_plan.md`

---

## Future ADRs

### Planned ADRs

1. **ADR-011**: Shared Resource Interface Design (pending)
2. **ADR-012**: Error Propagation Pattern Design (pending)
3. **ADR-013**: Security Boundary Design (pending)
4. **ADR-014**: Performance Optimization Strategy (pending)
5. **ADR-015**: sevenos Integration Architecture (pending)

---

## ADR Maintenance

### When to Create an ADR

Create an ADR when:
- Making a significant architecture decision
- Choosing between alternatives
- Defining patterns or standards
- Making decisions that affect multiple components

### ADR Lifecycle

1. **Proposed**: Decision is proposed
2. **Accepted**: Decision is accepted and implemented
3. **Rejected**: Decision is rejected
4. **Deprecated**: Decision is deprecated (superseded or no longer relevant)
5. **Superseded**: Decision is superseded by a new ADR

### ADR Review

- Review ADRs during architecture discussions
- Update ADRs when decisions change
- Deprecate ADRs when superseded
- Document rationale for changes

---

## Notes

- All ADRs follow Grain Style principles
- All ADRs document trade-offs and alternatives
- All ADRs include impact analysis
- ADRs are living documents (updated as needed)

---

**Date**: 2026-01-02-010000-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: Template and Initial ADRs Complete — Ready for Future Decisions

