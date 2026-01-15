# Aurora 2 Subcore Sub-Agents: Documentation Structure Adoption Prompt

**Date**: 2025-12-31-192740-pst  
**Purpose**: Instructions for Aurora 2 Subcore L2 sub-agents to adopt the same documentation structure as Vantage 3 Subcore and Core 1 Subcore  
**For**: All 3 Aurora Sub-Agents (2a Dream Editor, 2b Dream Browser, 2c Component Library)

---

## Executive Summary

**Goal**: Adopt the proven documentation structure used by Vantage 3 Subcore and Core 1 Subcore L2 sub-agents.

**Required Documents**:
1. **Coordination Document**: `docs/core-coordination/aurora_2{X}_{agent}_coordination.md`
2. **Plan Document**: `docs/plans/aurora_2{X}_{agent}_plan.md` or `docs/plans/plan_{agent}.md`
3. **Tasks Document**: `docs/tasks/aurora_2{X}_{agent}_tasks.md` or `docs/tasks/tasks_{agent}.md`

**Reference Examples**:
- **Vantage 3 Subcore**: `docs/core-coordination/vantage_3b_vm_runtime_coordination.md`, `docs/plans/vantage_3b_vm_runtime_plan.md`, `docs/tasks/vantage_3b_vm_runtime_tasks.md`
- **Core 1 Subcore**: `docs/core-coordination/core_1a_auth_coordination.md`, `docs/plans/core_1a_auth_plan.md`, `docs/tasks/core_1a_auth_tasks.md`

---

## FOR ALL AURORA SUB-AGENTS (2a, 2b, 2c)

### Your Documentation Structure

You must create and maintain **three core documents** following the same structure as Vantage 3 Subcore and Core 1 Subcore sub-agents:

#### 1. Coordination Document

**File Path**:
- **2a (Dream Editor)**: `docs/core-coordination/aurora_2a_dream_editor_coordination.md`
- **2b (Dream Browser)**: `docs/core-coordination/aurora_2b_dream_browser_coordination.md`
- **2c (Component Library)**: `docs/core-coordination/aurora_2c_component_library_coordination.md`

**Template Structure** (based on `core_1a_auth_coordination.md` and `vantage_3b_vm_runtime_coordination.md`):

```markdown
# Core Coordination: Grain {Agent Name} ({2X})

**Last Updated**: {timestamp}  
**Agent**: Grain {Agent Name} ({2X}) — L2 Sub-Agent  
**Parent Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Status**: {Current Status}

---

## Executive Summary for Aurora 2 Subcore

**Current Status**: {Brief status summary}

**Key Achievements**:
- ✅ {Achievement 1}
- ✅ {Achievement 2}
- ⏳ {In Progress}

**Ready for**: {Next phase or coordination needs}

---

## Implementation Status

### ✅ Completed Features

{List of completed features with checkmarks}

### ⏳ In Progress

{List of in-progress work}

### 📋 Planned

{List of planned work}

---

## Code Quality Status

### Grain Style Compliance

- ✅ **Function Length**: {Status} (all functions ≤ 70 lines)
- ✅ **Line Length**: {Status} (all lines ≤ 100 characters)
- ✅ **Assertions**: {Status} (comprehensive coverage)
- ✅ **Explicit Types**: {Status} (all `u32`/`u64`, no `usize`/`isize`)
- ✅ **Bounded Allocations**: {Status} (all MAX_ constants defined)
- ✅ **Linter Errors**: {Count}

### Test Coverage

- ✅ **Tests**: {Count} comprehensive tests
- ✅ **Test Organization**: {Status}
- ⏳ **Integration Tests**: {Status}

---

## Coordination with Aurora 2 Subcore

### Weekly/Bi-Weekly Check-Ins

**Last Check-In**: {Date}
**Next Check-In**: {Date}

**Status Updates**:
- {Update 1}
- {Update 2}

**Coordination Needs**:
- {Need 1}
- {Need 2}

### Cross-Sub-Agent Coordination

**With 2a (Dream Editor)**: {Coordination notes}
**With 2b (Dream Browser)**: {Coordination notes}
**With 2c (Component Library)**: {Coordination notes}

---

## Next Steps for Aurora 2 Subcore

### Immediate Actions Recommended

1. {Action 1}
2. {Action 2}
3. {Action 3}

### Coordination Questions for Aurora 2 Subcore

1. {Question 1}
2. {Question 2}

---

## File Ownership

**Your Domain Files**:
- {List of files you own}

**Shared Files** (coordinated via Aurora 2 Subcore):
- {List of shared files}

---

**Last Updated**: {timestamp}  
**Agent**: Grain {Agent Name} ({2X})  
**Status**: {Current Status}
```

#### 2. Plan Document

**File Path**:
- **2a (Dream Editor)**: `docs/plans/aurora_2a_dream_editor_plan.md` or `docs/plans/plan_dream_editor.md`
- **2b (Dream Browser)**: `docs/plans/aurora_2b_dream_browser_plan.md` or `docs/plans/plan_dream_browser.md`
- **2c (Component Library)**: `docs/plans/aurora_2c_component_library_plan.md` or `docs/plans/plan_component_library.md`

**Template Structure** (based on `core_1a_auth_plan.md` and `vantage_3b_vm_runtime_plan.md`):

```markdown
# {Agent Name}: Development Plan

**Agent**: Grain {Agent Name} ({2X}, L2 Sub-Agent)  
**Parent Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Last Updated**: {timestamp}  
**Status**: {Current Status}

---

## Overview

{Agent Name} is responsible for {domain description}.

**Key Goals**:
- {Goal 1}
- {Goal 2}
- {Goal 3}

---

## Completed Phases

### Phase X: {Phase Name} ✅ **COMPLETE**

**Objective**: {Objective}

**Features**:
- ✅ {Feature 1}
- ✅ {Feature 2}

**Files**: {List of files}

**Tests**: {Test file references}

---

## Current Phase

### Phase X: {Phase Name} ⏳ **IN PROGRESS**

**Objective**: {Objective}

**Status**: {Status}

**Features**:
- ✅ {Completed feature}
- ⏳ {In progress feature}
- 📋 {Planned feature}

---

## Planned Phases

### Phase X: {Phase Name} 📋 **PLANNED**

**Objective**: {Objective}

**Estimated Time**: {Time}

**Dependencies**: {Dependencies}

---

## Coordination

**With Aurora 2 Subcore (L1)**:
- Weekly/bi-weekly check-ins
- Architecture decisions
- Integration planning

**With Other L2 Sub-Agents**:
- {Coordination notes}

**With Other Full Agents**:
- {Coordination notes}

---

## Grain Style Compliance

- ✅ Function length: ≤ 70 lines
- ✅ Line length: ≤ 100 characters
- ✅ Explicit types: `u32`/`u64` (not `usize`/`isize`)
- ✅ Bounded allocations
- ✅ Comprehensive assertions
- ✅ All compiler warnings enabled

---

**Last Updated**: {timestamp}  
**Agent**: Grain {Agent Name} ({2X})  
**Status**: {Current Status}
```

#### 3. Tasks Document

**File Path**:
- **2a (Dream Editor)**: `docs/tasks/aurora_2a_dream_editor_tasks.md` or `docs/tasks/tasks_dream_editor.md`
- **2b (Dream Browser)**: `docs/tasks/aurora_2b_dream_browser_tasks.md` or `docs/tasks/tasks_dream_browser.md`
- **2c (Component Library)**: `docs/tasks/aurora_2c_component_library_tasks.md` or `docs/tasks/tasks_component_library.md`

**Template Structure** (based on `core_1a_auth_tasks.md`):

```markdown
# {Agent Name}: Task List

**Agent**: Grain {Agent Name} ({2X}, L2 Sub-Agent)  
**Parent Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Last Updated**: {timestamp}  
**Status**: {Current Status}

---

## Current Tasks

### High Priority

- [ ] {Task 1} — {Status}
- [ ] {Task 2} — {Status}

### Medium Priority

- [ ] {Task 3} — {Status}
- [ ] {Task 4} — {Status}

### Low Priority

- [ ] {Task 5} — {Status}

---

## Completed Tasks

- [x] {Completed task 1} — {Date}
- [x] {Completed task 2} — {Date}

---

## Blocked Tasks

- [ ] {Blocked task} — **BLOCKED**: {Reason} — **Unblocks**: {When}

---

## Coordination Tasks

**With Aurora 2 Subcore**:
- [ ] {Coordination task 1}
- [ ] {Coordination task 2}

**With Other L2 Sub-Agents**:
- [ ] {Coordination task 3}

---

**Last Updated**: {timestamp}  
**Agent**: Grain {Agent Name} ({2X})  
**Status**: {Current Status}
```

---

## Documentation Maintenance Guidelines

### After Each Work Session

1. **Update Coordination Document**:
   - Update "Last Updated" timestamp
   - Update "Current Status"
   - Add completed work to "Completed Features"
   - Update "In Progress" section
   - Add any coordination needs or blockers

2. **Update Plan Document**:
   - Mark completed phases as ✅ **COMPLETE**
   - Update current phase status
   - Add new planned phases if needed

3. **Update Tasks Document**:
   - Mark completed tasks as [x]
   - Update task statuses
   - Add new tasks as needed
   - Update blocked tasks

### Weekly/Bi-Weekly Check-Ins

1. **Before Check-In**:
   - Ensure all three documents are up to date
   - Review Aurora 2 Subcore coordination document
   - Review other L2 sub-agent coordination documents
   - Prepare coordination questions

2. **During Check-In**:
   - Copy-paste coordination message template to Aurora 2 Subcore
   - Include specific coordination needs
   - Report blockers or dependencies

3. **After Check-In**:
   - Update coordination document with check-in results
   - Update tasks based on guidance received
   - Update plan if priorities changed

### As-Needed Coordination

**When to Coordinate Immediately**:
- Architecture decisions needed (API contracts, integration patterns)
- Breaking changes that affect other sub-agents
- Critical blockers preventing progress
- Integration phases requiring coordination

---

## Reference Documents

### Vantage 3 Subcore Examples

- **Coordination**: `docs/core-coordination/vantage_3b_vm_runtime_coordination.md`
- **Plan**: `docs/plans/vantage_3b_vm_runtime_plan.md` (if exists)
- **Tasks**: `docs/tasks/vantage_3b_vm_runtime_tasks.md` (if exists)

### Core 1 Subcore Examples

- **Coordination**: `docs/core-coordination/core_1a_auth_coordination.md`
- **Plan**: `docs/plans/core_1a_auth_plan.md` (if exists)
- **Tasks**: `docs/tasks/core_1a_auth_tasks.md` (if exists)

### Aurora 2 Subcore Documents

- **Coordination**: `docs/core-coordination/aurora_2_subcore_coordination.md`
- **Plan**: `docs/plans/aurora_2_subcore_plan.md` (to be created)
- **Tasks**: `docs/tasks/aurora_2_subcore_tasks.md` (to be created)

---

## Action Items for Each Sub-Agent

### Immediate (This Week)

1. **Create Coordination Document**:
   - Use template above
   - Fill in your agent-specific information
   - Include current status and achievements

2. **Create Plan Document**:
   - Use template above
   - Document completed phases
   - Document current phase
   - Document planned phases

3. **Create Tasks Document**:
   - Use template above
   - List current tasks
   - List completed tasks
   - List blocked tasks

### Short-Term (Next 2 Weeks)

1. **Establish Coordination Rhythm**:
   - Schedule weekly/bi-weekly check-ins with Aurora 2 Subcore
   - Review other L2 sub-agent coordination documents
   - Coordinate cross-sub-agent integration points

2. **Update Documentation Regularly**:
   - After each work session
   - Before each check-in
   - After receiving coordination guidance

---

## Coordination Message Template

When coordinating with Aurora 2 Subcore, use this template:

```
**Agent**: Grain {Agent Name} ({2X}, L2 Sub-Agent)  
**Date**: {timestamp}  
**Type**: Weekly/Bi-Weekly Check-In (or As-Needed Coordination)

## Status Update

**Current Status**: {Brief status}

**Completed This Week**:
- ✅ {Completed item 1}
- ✅ {Completed item 2}

**In Progress**:
- ⏳ {In progress item 1}
- ⏳ {In progress item 2}

**Next Steps**:
- 📋 {Next step 1}
- 📋 {Next step 2}

## Coordination Needs

**Architecture Decisions Needed**:
- {Decision 1}
- {Decision 2}

**Integration Points**:
- {Integration point 1}
- {Integration point 2}

**Blockers**:
- {Blocker 1} — **BLOCKED**: {Reason} — **Unblocks**: {When}

## Questions for Aurora 2 Subcore

1. {Question 1}
2. {Question 2}

---

**Coordination Document**: `docs/core-coordination/aurora_2{X}_{agent}_coordination.md`  
**Plan Document**: `docs/plans/aurora_2{X}_{agent}_plan.md`  
**Tasks Document**: `docs/tasks/aurora_2{X}_{agent}_tasks.md`
```

---

## Summary

**Required Actions**:
1. ✅ Create coordination document (`docs/core-coordination/aurora_2{X}_{agent}_coordination.md`)
2. ✅ Create plan document (`docs/plans/aurora_2{X}_{agent}_plan.md`)
3. ✅ Create tasks document (`docs/tasks/aurora_2{X}_{agent}_tasks.md`)
4. ✅ Follow documentation maintenance guidelines
5. ✅ Establish coordination rhythm with Aurora 2 Subcore

**Reference**: Follow the same structure as Vantage 3 Subcore and Core 1 Subcore sub-agents for consistency and proven patterns.

---

**Date**: 2025-12-31-192740-pst  
**Status**: Ready for Implementation  
**Next Steps**: Create documentation structure, establish coordination rhythm
