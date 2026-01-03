# Grain OS: L1<->L2 Integration Patterns

**Date**: 2026-01-03-053134-pst  
**Purpose**: Unified L1 Subcore Coordinator ↔ L2 Sub-Agent integration patterns for all Grain OS agents  
**Status**: ✅ **UNIFIED PATTERNS DOCUMENT CREATED**

---

## Executive Summary

This document defines the **unified integration patterns** for communication and coordination between L1 Subcore Coordinators and their L2 Sub-Agents across all Grain OS subcores (Core 1, Aurora 2, Vantage 3).

**Key Principles**:
1. **Parallel Work Model**: L1 and L2 work in parallel, not alternating
2. **Structured Coordination Points**: Weekly/bi-weekly check-ins, as-needed for architecture decisions
3. **Documentation-Driven**: All coordination documented in standard format
4. **Clear Communication Flows**: L2 → L1, L1 → L2, L1 ↔ L1, L2 ↔ L2 (minimal)
5. **System-Integration Focus**: All agents maintain system-integration docs

---

## L1 Subcore Coordinator Responsibilities

### Primary Role: Subcore Coordination

**L1 Subcore Coordinators** (Core 1, Aurora 2, Vantage 3) must:

1. **Maintain Unified System-Integration Document**:
   - Primary doc: `docs/core-coordination/{subcore}_subcore_system_integration.md`
   - Updated after each coordination cycle
   - Includes cross-subcore integration points
   - Aggregates L2 sub-agent integration status

2. **Coordinate L2 Sub-Agent System-Integration**:
   - Review L2 system-integration docs: `docs/core-coordination/{subcore}_{id}_{name}_system_integration.md`
   - Aggregate L2 integration status into L1 system-integration doc
   - Coordinate cross-L2 integration points
   - Plan integration milestones

3. **Facilitate Cross-Subcore Integration**:
   - Coordinate with other L1 Subcore Coordinators on cross-subcore integration
   - Document cross-subcore integration points in system-integration docs
   - Plan cross-subcore integration milestones
   - Coordinate with Grain Core Agent for system-wide decisions

4. **Provide to L2 Sub-Agents** (while working in parallel):
   - Overall subcore architecture coordination
   - Cross-sub-agent decision making
   - Integration testing and validation
   - Coordination with other full agents (Vantage, Silo, etc.)
   - High-level planning and roadmap
   - API contract definitions
   - Shared resource management

5. **Read L2 Sub-Agent Documentation**:
   - Weekly/bi-weekly review of all L2 coordination, plan, tasks, and system-integration docs
   - Make coordination decisions based on L2 status
   - Identify blockers and integration needs
   - Plan next coordination cycle

---

## L2 Sub-Agent Responsibilities

### Primary Role: Domain-Specific Implementation

**L2 Sub-Agents** must:

1. **Maintain System-Integration Document**:
   - Primary doc: `docs/core-coordination/{subcore}_{id}_{name}_system_integration.md`
   - Updated after each work session
   - Includes integration status with other agents/sub-agents
   - Documents integration decisions and API contracts

2. **Maintain Standard Documentation**:
   - Coordination: `docs/core-coordination/{subcore}_{id}_{name}_coordination.md`
   - Plan: `docs/plans/{subcore}_{id}_{name}_plan.md`
   - Tasks: `docs/tasks/{subcore}_{id}_{name}_tasks.md`
   - System-Integration: `docs/core-coordination/{subcore}_{id}_{name}_system_integration.md`

3. **Provide to L1 Parent** (while working in parallel):
   - Domain-specific implementation progress
   - Technical decisions within their domain
   - Testing and validation results
   - Documentation updates
   - Integration needs and blockers
   - API contract requirements

4. **Coordinate Through L1 Parent**:
   - Update L1 parent on integration needs
   - Request L1 parent coordination for cross-subcore integration
   - Document integration decisions in system-integration doc
   - Escalate blockers to L1 for resolution

5. **Direct L2<->L2 Coordination** (Minimal, Documented):
   - Direct coordination only for immediate technical needs
   - Document all direct L2<->L2 coordination in system-integration docs
   - Inform L1 parent of direct coordination
   - Most coordination should go through L1 parent

---

## Communication Flow Patterns

### L2 → L1 Communication

**Frequency**: Continuous (documentation updates), Weekly/bi-weekly (coordination check-ins)

**Communication Channels**:
1. **Documentation Updates**:
   - L2 updates coordination, plan, tasks, and system-integration docs after each work session
   - L1 reads all L2 docs weekly/bi-weekly

2. **Integration Requests**:
   - L2 requests L1 coordination for cross-subcore integration
   - L2 documents integration needs in system-integration doc
   - L1 reviews and coordinates with other L1 Subcore Coordinators

3. **Blocker Escalation**:
   - L2 escalates blockers to L1 for resolution
   - L2 documents blockers in coordination doc
   - L1 reviews and coordinates resolution

**Documentation Requirements**:
- All L2 → L1 communication must be documented in L2's coordination or system-integration doc
- L2 must update docs after each work session
- L2 must inform L1 of integration needs before starting integration work

---

### L1 → L2 Communication

**Frequency**: Weekly/bi-weekly (coordination cycles), As-needed (architecture decisions)

**Communication Channels**:
1. **Coordination Plans**:
   - L1 provides coordination plans via recursion cycle
   - L1 creates comprehensive coordination summaries for distribution
   - L1 updates coordination plan with L2 status and next steps

2. **Integration Guidance**:
   - L1 provides integration guidance and API contracts
   - L1 coordinates cross-L2 integration points
   - L1 plans integration milestones

3. **Priority Coordination**:
   - L1 coordinates priorities across L2 sub-agents
   - L1 aligns L2 work with critical path and system-wide priorities
   - L1 provides context for L2 decision-making

**Documentation Requirements**:
- All L1 → L2 communication must be documented in L1's coordination plan and system-integration doc
- L1 must create coordination summaries for copy-paste distribution
- L1 must update system-integration doc with cross-L2 integration status

---

### L1 ↔ L1 Communication (Cross-Subcore)

**Frequency**: As-needed (cross-subcore integration), Weekly (system-wide coordination)

**Communication Channels**:
1. **Direct Coordination**:
   - L1 Subcore Coordinators coordinate directly on cross-subcore integration
   - L1 updates system-integration docs with cross-subcore integration points
   - L1 plans cross-subcore integration milestones

2. **Grain Core Agent Coordination**:
   - L1 coordinates with Grain Core Agent for system-wide decisions
   - L1 escalates system-wide blockers to Grain Core Agent
   - L1 aligns subcore priorities with system-wide priorities

**Documentation Requirements**:
- All L1 ↔ L1 communication must be documented in L1's system-integration doc
- L1 must update system-integration doc with cross-subcore integration status
- L1 must coordinate with Grain Core Agent for system-wide decisions

---

### L2 ↔ L2 Communication (Minimal, Documented)

**Frequency**: Minimal, as-needed only (immediate technical needs)

**Communication Pattern**:
- Direct L2<->L2 coordination only for immediate technical needs
- Most coordination should go through L1 parent
- All direct L2<->L2 coordination must be documented in both L2's system-integration docs
- L2 must inform L1 parent of direct coordination

**Examples**:
- Auth (1a) ↔ Network (1b): Authentication middleware (documented in both system-integration docs)
- Storage (1c) ↔ Network (1b): File upload/download (documented in both system-integration docs)
- Storage (1c) ↔ Compositor (1d): Workspace state persistence (documented in both system-integration docs)

**Documentation Requirements**:
- All L2 ↔ L2 communication must be documented in both L2's system-integration docs
- L2 must inform L1 parent of direct coordination
- L2 must coordinate through L1 for cross-subcore L2 coordination

---

## Parallel Work Model

### Primary Mode: Parallel Work (Not Alternating)

**L1 Subcore Coordinators and L2 Sub-Agents work in parallel** to maximize parallelization and development velocity.

### L1 Can Work On (While L2 Works):

1. **Integration Testing and Validation**:
   - Integration testing across L2 sub-agents
   - End-to-end system testing
   - Performance analysis across sub-agents
   - Cross-sub-agent validation

2. **Architecture Planning and Documentation**:
   - Overall subcore architecture
   - Cross-sub-agent API design
   - Integration patterns and best practices
   - Architecture decision records

3. **Coordination with Other Full Agents**:
   - Coordinate with other L1 Subcore Coordinators
   - Coordinate with Grain Core Agent
   - System-wide architecture decisions

4. **Cross-Sub-Agent Decision Making**:
   - API contracts between sub-agents
   - Shared resource management
   - Integration patterns
   - Performance optimization across domains

5. **System-Wide Planning**:
   - Roadmap planning
   - Priority coordination
   - Resource allocation
   - Timeline management

### L2 Can Work On (While L1 Works):

1. **Domain-Specific Implementation**:
   - Feature development within their domain
   - Performance optimization
   - Security hardening
   - Testing and validation

2. **Documentation Updates**:
   - Domain-specific documentation
   - Technical decision documentation
   - Integration status updates
   - System-integration doc updates

3. **Independent Work**:
   - Work that doesn't require L1 coordination
   - Work that doesn't affect other L2 sub-agents
   - Work that doesn't require cross-subcore coordination

---

## Coordination Schedule

### Weekly/Bi-Weekly Check-Ins

**Format**: Async coordination document updates + sync check-in if needed

**Agenda**:
1. Review L2 sub-agent progress (coordination, plan, tasks, system-integration docs)
2. Review critical path progress (if applicable)
3. Review integration progress (cross-L2, cross-subcore)
4. Discuss blockers and coordination needs
5. Plan next week's priorities
6. Update coordination documents

### As-Needed Coordination

**Triggers**:
- Architecture decisions affecting multiple L2 sub-agents
- Breaking changes requiring coordination
- Critical blockers requiring immediate attention
- Integration phases requiring coordination
- Cross-subcore integration needs

---

## Documentation Requirements

### L1 Subcore Coordinator Documentation

**Required Documents**:
1. **Coordination**: `docs/core-coordination/{subcore}_subcore_coordination.md`
2. **Plan**: `docs/plans/{subcore}_subcore_plan.md`
3. **Tasks**: `docs/tasks/{subcore}_subcore_tasks.md`
4. **System-Integration**: `docs/core-coordination/{subcore}_subcore_system_integration.md` ⭐ **NEW REQUIREMENT**

### L2 Sub-Agent Documentation

**Required Documents**:
1. **Coordination**: `docs/core-coordination/{subcore}_{id}_{name}_coordination.md`
2. **Plan**: `docs/plans/{subcore}_{id}_{name}_plan.md`
3. **Tasks**: `docs/tasks/{subcore}_{id}_{name}_tasks.md`
4. **System-Integration**: `docs/core-coordination/{subcore}_{id}_{name}_system_integration.md` ⭐ **NEW REQUIREMENT**

### Documentation Update Frequency

- **Coordination Docs**: Updated after each work session
- **Plan Docs**: Updated as implementation evolves
- **Tasks Docs**: Updated as tasks are completed
- **System-Integration Docs**: Updated after each work session or integration milestone ⭐ **NEW REQUIREMENT**

---

## Integration Check-In Requirements

### When to Check In

**L2 Sub-Agents must check in with L1 parent**:
- Before starting integration work with other agents/sub-agents
- When API contracts need coordination
- When breaking changes affect other agents
- When critical blockers arise
- When cross-subcore integration is needed

**L1 Subcore Coordinators must check in with Grain Core Agent**:
- When system-wide architecture decisions are needed
- When cross-domain integration is needed
- When system-wide blockers arise
- When system-wide priorities need coordination

### How to Check In

**L2 → L1**:
- Update system-integration doc with integration needs
- Document in coordination doc
- Request L1 coordination in system-integration doc

**L1 → Grain Core Agent**:
- Update system-integration doc with system-wide needs
- Document in coordination doc
- Coordinate directly with Grain Core Agent

---

## Examples

### Example 1: L2 → L1 Integration Request

**Scenario**: Auth Agent (1a) needs to integrate with Network Agent (1b) for authentication middleware.

**Process**:
1. Auth Agent (1a) documents integration need in `core_1a_auth_system_integration.md`
2. Auth Agent (1a) updates coordination doc with integration request
3. Core 1 Subcore reviews both Auth and Network system-integration docs
4. Core 1 Subcore facilitates API contract design session
5. Core 1 Subcore documents integration plan in `core_1_subcore_system_integration.md`
6. Both agents proceed with integration implementation

### Example 2: L1 → L2 Priority Coordination

**Scenario**: Core 1 Subcore needs to align L2 priorities with critical path.

**Process**:
1. Core 1 Subcore reviews critical path status
2. Core 1 Subcore updates coordination plan with priority alignment
3. Core 1 Subcore creates coordination summary for distribution
4. Core 1 Subcore distributes coordination summary to all L2 sub-agents
5. L2 sub-agents update their plans and tasks based on priorities
6. L2 sub-agents update system-integration docs with priority changes

### Example 3: L1 ↔ L1 Cross-Subcore Integration

**Scenario**: Core 1 Subcore needs to integrate Grainscript Shell (1e) with Vantage 3 Subcore's Init System (3d).

**Process**:
1. Core 1 Subcore documents integration need in `core_1_subcore_system_integration.md`
2. Core 1 Subcore coordinates with Vantage 3 Subcore
3. Both L1 Subcore Coordinators update their system-integration docs
4. Both L1 Subcore Coordinators create integration plan
5. L2 sub-agents (1e and 3d) receive integration guidance from their L1 parents
6. L2 sub-agents proceed with integration implementation

---

## Reference Documents

**Unified Documentation Structure**:
- `docs/2026-01-03-052459-pst_documentation_unification_plan.md`
- `docs/2026-01-03-052745-pst_system_integration_doc_migration_log.md`
- `docs/2026-01-03-052745-pst_plan_tasks_migration_mapping.md`

**Recursion Guidelines**:
- `docs/2026-01-03-045322-pst_framework_16_recursion_prompt_strict_guidelines.md`

**Agent List**:
- `docs/2026-01-03-044511-pst_framework_16_agent_list_with_subagents.md`

---

**Date**: 2026-01-03-053134-pst  
**Status**: ✅ **UNIFIED INTEGRATION PATTERNS COMPLETE** — Ready for adoption by all L1 and L2 agents  
**Next Steps**: Update agent prompt templates to reference this document

