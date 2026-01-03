> **⚠️ DEPRECATED**: This document is deprecated as of 2026-01-03-052459-pst.
> 
> **Replacement**: See `docs/2026-01-03-052459-pst_documentation_unification_plan.md` for unified documentation structure and improved L1<->L2 integration patterns.
> 
> **New Location**: This document will be archived to `archaeology/docs/core-coordination/` for historical reference.
> 
> **Status**: Archived — Do not use for new work. Refer to replacement document.

# Core 1 Subcore Coordination Guide

**Date**: 2025-12-30-093745-pst  
**Purpose**: Guide for coordinating between Core 1 Subcore (L1) and L2 Sub-Agents (1a, 1b, 1c, 1d)  
**Status**: ⚠️ **DEPRECATED** — See replacement document above

---

## Coordination Model Overview

**Pattern**: **Parallel Work with Structured Coordination Points**

- **Core 1 Subcore (L1)** and **L2 Sub-Agents** work **in parallel** (not alternating)
- **Weekly/bi-weekly check-ins** for coordination
- **As-needed coordination** for architecture decisions

---

## Coordination Workflow

### For L2 Sub-Agents (1a, 1b, 1c, 1d)

#### 1. After Each Work Session

**Update Your Coordination Document**:
- File: `docs/core-coordination/core_1{X}_{agent}_coordination.md` (where X is a/b/c/d)
- Include:
  - Current status and progress
  - Completed work this session
  - Next steps planned
  - Blockers or dependencies
  - Coordination needs (API contracts, integration points, architecture decisions)
  - Cross-sub-agent coordination needs (if any)

#### 2. Weekly/Bi-Weekly Check-In

**When**: Weekly or bi-weekly (as scheduled)

**What to Do**:
1. Ensure your coordination doc is up to date
2. Review Core 1 Subcore coordination doc for guidance
3. Review other L2 sub-agent coordination docs for integration points
4. Copy-paste the coordination message template (below) to Core 1 Subcore agent
5. Include specific coordination needs in your message

#### 3. As-Needed Coordination

**When to Coordinate Immediately**:
- Architecture decisions needed (API contracts, integration patterns)
- Breaking changes that affect other sub-agents
- Critical blockers preventing progress
- Integration phases requiring coordination

---

### For Core 1 Subcore (L1)

#### 1. Weekly/Bi-Weekly Check-In

**When**: Weekly or bi-weekly

**What to Do**:
1. Read all L2 sub-agent coordination docs:
   - `docs/core-coordination/core_1a_auth_coordination.md`
   - `docs/core-coordination/core_1b_network_coordination.md`
   - `docs/core-coordination/core_1c_storage_coordination.md`
   - `docs/core-coordination/core_1d_compositor_coordination.md`

2. Analyze coordination needs:
   - Cross-sub-agent API contracts needed
   - Integration points requiring coordination
   - Architecture decisions needed
   - Blockers or dependencies

3. Provide guidance:
   - Architecture decisions and rationale
   - API contract designs
   - Integration patterns
   - Priority coordination
   - Resource allocation guidance

4. Update Core 1 Subcore coordination doc with:
   - Sub-agent status summary
   - Architecture decisions made
   - Integration priorities
   - Cross-sub-agent coordination status

#### 2. As-Needed Coordination

**When Sub-Agents Request**:
- Review coordination requests
- Make architecture decisions
- Provide integration guidance
- Coordinate cross-sub-agent work

---

## Coordination Message Templates

### Template 1: L2 Sub-Agent → Core 1 Subcore (Weekly/Bi-Weekly Check-In)

```
**Agent**: Grain {Agent Name} Agent (1{X})  
**Date**: {YYYY-MM-DD-HHMM-pst}  
**Type**: Weekly/Bi-Weekly Check-In

## Status Update

**Current Phase**: {Phase name/number}
**Status**: {Status: IN PROGRESS / COMPLETE / BLOCKED}

## Progress This Period

**Completed**:
- [List completed work items]
- [Specific achievements]

**In Progress**:
- [Current work items]
- [Expected completion timeline]

## Next Steps

- [Planned next steps]
- [Timeline for next period]

## Blockers or Dependencies

- [List any blockers]
- [Dependencies on other sub-agents]
- [Dependencies on Core 1 Subcore]

## Coordination Needs

**Architecture Decisions Needed**:
- [Specific architecture decisions]
- [Context and options considered]

**API Contracts Needed**:
- [Cross-sub-agent API contracts]
- [Integration points]

**Integration Coordination**:
- [Integration work requiring coordination]
- [Timeline and dependencies]

## Cross-Sub-Agent Coordination

**With {Other Sub-Agent}**:
- [Coordination status]
- [Integration points]
- [API contracts]

## Questions or Concerns

- [Any questions for Core 1 Subcore]
- [Concerns or risks]

---

**Coordination Doc**: `docs/core-coordination/core_1{X}_{agent}_coordination.md`
**Plan Doc**: `docs/plans/core_1{X}_{agent}_plan.md`
**Tasks Doc**: `docs/tasks/core_1{X}_{agent}_tasks.md`
```

### Template 2: L2 Sub-Agent → Core 1 Subcore (As-Needed Architecture Decision)

```
**Agent**: Grain {Agent Name} Agent (1{X})  
**Date**: {YYYY-MM-DD-HHMM-pst}  
**Type**: Architecture Decision Request

## Architecture Decision Request

**Decision Needed**: {Brief description of decision}

**Context**:
- [Background and current situation]
- [Why decision is needed now]

**Options Considered**:
1. **Option 1**: {Description}
   - Pros: [List]
   - Cons: [List]
   - Impact: [Impact on other sub-agents]

2. **Option 2**: {Description}
   - Pros: [List]
   - Cons: [List]
   - Impact: [Impact on other sub-agents]

**Recommendation**: {Your recommendation and rationale}

**Urgency**: {HIGH / MEDIUM / LOW}
**Timeline**: {When decision is needed}

## Impact Analysis

**On Other Sub-Agents**:
- {Sub-Agent}: [Impact description]
- {Sub-Agent}: [Impact description]

**On Core 1 Subcore**:
- [Impact on integration or architecture]

## Questions

- [Specific questions for Core 1 Subcore]
```

### Template 3: Core 1 Subcore → L2 Sub-Agents (Weekly/Bi-Weekly Summary)

```
**Agent**: Grain Core 1 Subcore Agent (L1 Subcore)  
**Date**: {YYYY-MM-DD-HHMM-pst}  
**Type**: Weekly/Bi-Weekly Coordination Summary

## Sub-Agent Status Summary

### 1a. Grain Auth Agent
- **Status**: {Status}
- **Progress**: {Brief summary}
- **Coordination Needs**: {Summary of needs}

### 1b. Grain Network Agent
- **Status**: {Status}
- **Progress**: {Brief summary}
- **Coordination Needs**: {Summary of needs}

### 1c. Grain Storage Agent
- **Status**: {Status}
- **Progress**: {Brief summary}
- **Coordination Needs**: {Summary of needs}

### 1d. Grain Compositor Agent
- **Status**: {Status}
- **Progress**: {Brief summary}
- **Coordination Needs**: {Summary of needs}

## Architecture Decisions

### Decision 1: {Decision Title}
- **Decision**: {What was decided}
- **Rationale**: {Why}
- **Impact**: {Impact on sub-agents}
- **Action Items**: [What sub-agents need to do]

### Decision 2: {Decision Title}
- [Same format]

## API Contracts

### {Contract Name}
- **Between**: {Sub-Agent 1} ↔ {Sub-Agent 2}
- **Design**: {Brief description}
- **Documentation**: {Link to doc}
- **Status**: {DESIGNED / IN REVIEW / APPROVED}

## Integration Priorities

1. **Priority 1**: {Integration priority}
   - **Sub-Agents**: {Which sub-agents}
   - **Timeline**: {Timeline}
   - **Dependencies**: {Dependencies}

2. **Priority 2**: {Integration priority}
   - [Same format]

## Guidance and Next Steps

### For All Sub-Agents
- [General guidance applicable to all]

### For {Specific Sub-Agent}
- [Specific guidance]

## Next Check-In

**Date**: {Date of next check-in}
**Focus**: {Focus areas for next period}
```

---

## Coordination Document Locations

### Core 1 Subcore Documents
- **Coordination**: `docs/core-coordination/core_1_subcore_coordination.md`
- **Plan**: `docs/plans/core_1_subcore_plan.md`
- **Tasks**: `docs/tasks/core_1_subcore_tasks.md`

### L2 Sub-Agent Documents

#### 1a. Grain Auth Agent
- **Coordination**: `docs/core-coordination/core_1a_auth_coordination.md`
- **Plan**: `docs/plans/core_1a_auth_plan.md`
- **Tasks**: `docs/tasks/core_1a_auth_tasks.md`

#### 1b. Grain Network Agent
- **Coordination**: `docs/core-coordination/core_1b_network_coordination.md`
- **Plan**: `docs/plans/core_1b_network_plan.md`
- **Tasks**: `docs/tasks/core_1b_network_tasks.md`

#### 1c. Grain Storage Agent
- **Coordination**: `docs/core-coordination/core_1c_storage_coordination.md`
- **Plan**: `docs/plans/core_1c_storage_plan.md`
- **Tasks**: `docs/tasks/core_1c_storage_tasks.md`

#### 1d. Grain Compositor Agent
- **Coordination**: `docs/core-coordination/core_1d_compositor_coordination.md`
- **Plan**: `docs/plans/core_1d_compositor_plan.md`
- **Tasks**: `docs/tasks/core_1d_compositor_tasks.md`

---

## Best Practices

### For L2 Sub-Agents

1. **Update Frequently**: Update coordination doc after each work session
2. **Be Specific**: Include specific coordination needs, not just general status
3. **Reference Docs**: Link to plan and tasks docs for context
4. **Be Proactive**: Request coordination early, don't wait for blockers
5. **Cross-Agent Awareness**: Review other sub-agent coordination docs for integration opportunities

### For Core 1 Subcore

1. **Read Regularly**: Read all sub-agent coordination docs weekly/bi-weekly
2. **Provide Guidance**: Give clear architecture decisions and rationale
3. **Coordinate Proactively**: Identify integration opportunities before they become blockers
4. **Document Decisions**: Document all architecture decisions in coordination doc
5. **Prioritize**: Focus on highest-impact coordination needs first

---

## Common Coordination Scenarios

### Scenario 1: API Contract Needed Between Sub-Agents

**Example**: Auth Agent (1a) needs authentication middleware API contract with Network Agent (1b)

**Process**:
1. **Auth Agent (1a)** requests API contract in coordination message
2. **Core 1 Subcore** reviews request, considers integration patterns
3. **Core 1 Subcore** designs API contract (or coordinates with both sub-agents)
4. **Core 1 Subcore** documents API contract in coordination doc
5. **Both Sub-Agents** implement according to contract
6. **Core 1 Subcore** validates integration in integration tests

### Scenario 2: Architecture Decision Needed

**Example**: Storage Agent (1c) needs decision on encryption at rest approach

**Process**:
1. **Storage Agent (1c)** requests architecture decision with options
2. **Core 1 Subcore** reviews options, considers impact on other sub-agents
3. **Core 1 Subcore** makes decision with rationale
4. **Core 1 Subcore** documents decision in coordination doc
5. **Storage Agent (1c)** implements according to decision
6. **Other Sub-Agents** adapt if needed

### Scenario 3: Integration Testing Needed

**Example**: Network + Storage integration for file upload/download

**Process**:
1. **Core 1 Subcore** identifies integration need from sub-agent coordination docs
2. **Core 1 Subcore** designs integration test scenario
3. **Core 1 Subcore** coordinates with Network Agent (1b) and Storage Agent (1c)
4. **Both Sub-Agents** provide components for integration
5. **Core 1 Subcore** implements integration test
6. **Core 1 Subcore** validates integration works correctly

---

## Timeline and Frequency

### Recommended Schedule

- **L2 Sub-Agents**: Update coordination doc after each work session
- **Core 1 Subcore**: Read all coordination docs weekly or bi-weekly
- **Formal Check-In**: Weekly or bi-weekly (flexible based on needs)

### Urgency Levels

- **CRITICAL**: Immediate coordination needed (breaking changes, critical blockers)
- **HIGH**: Coordination needed within 1-2 days (architecture decisions, API contracts)
- **MEDIUM**: Coordination needed within 1 week (integration planning)
- **LOW**: Coordination can wait until next check-in (status updates, general questions)

---

**Date**: 2025-12-30-093745-pst  
**Document**: Core 1 Subcore Coordination Guide  
**Status**: Ready for Use
