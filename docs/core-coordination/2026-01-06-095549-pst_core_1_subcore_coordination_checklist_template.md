# Core 1 Subcore: Coordination Checklist Template

**Date**: 2026-01-06-095549-pst  
**Agent**: Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **TEMPLATE READY** — Coordination checklist for all agents/sub-agents

---

## Executive Summary

This document provides a coordination checklist template for all Grain OS agents and sub-agents to use during coordination check-ins. The checklist ensures comprehensive status updates, blocker identification, and integration planning.

**Purpose**: Standardize coordination check-ins and ensure all critical information is captured.

---

## Pre-Check-In Preparation

### Before Coordination Check-In

**Required Actions**:
- [ ] Review your coordination document (`docs/core-coordination/{agent}_coordination.md`)
- [ ] Review your plan document (`docs/plans/{agent}_plan.md`)
- [ ] Review your tasks document (`docs/tasks/{agent}_tasks.md`)
- [ ] Review recent git commits and changes
- [ ] Identify completed work since last check-in
- [ ] Identify blockers or coordination needs
- [ ] Prepare status update summary

**Time Required**: 15-30 minutes

---

## Coordination Check-In Checklist

### Section 1: Status Update

**Current Status**:
- [ ] **Phase/Status**: Current implementation phase or status
- [ ] **Progress**: Percentage complete or milestone reached
- [ ] **Timeline**: On track, ahead, or behind schedule

**Completed Work Since Last Check-In**:
- [ ] List all completed tasks with timestamps
- [ ] List all completed features or modules
- [ ] List all completed documentation updates
- [ ] List all completed tests or validations

**In Progress Work**:
- [ ] List all work currently in progress
- [ ] Estimate completion time for each item
- [ ] Identify any dependencies or blockers

---

### Section 2: Critical Path Awareness

**Critical Path Status** (if applicable):
- [ ] **Step 1**: Basin Kernel (3a) — Status: ✅ COMPLETE / ⏳ IN PROGRESS / ⏳ BLOCKED
- [ ] **Step 2**: VM Runtime (3b) — Status: ✅ COMPLETE / ⏳ IN PROGRESS / ⏳ BLOCKED
- [ ] **Step 3**: Init System (3d) — Status: ✅ COMPLETE / ⏳ IN PROGRESS / ⏳ BLOCKED
- [ ] **Step 4**: Grainscript Shell (1e) — Status: ✅ COMPLETE / ⏳ IN PROGRESS / ⏳ BLOCKED

**Critical Path Impact**:
- [ ] Are you blocking any critical path steps?
- [ ] Are you blocked by any critical path steps?
- [ ] What is your role in the critical path (if any)?

**Critical Path Coordination**:
- [ ] Coordinate with blocking/blocked agents as needed
- [ ] Update critical path status monitor
- [ ] Resolve blockers immediately if blocking critical path

---

### Section 3: Blockers and Dependencies

**Current Blockers**:
- [ ] List all current blockers
- [ ] For each blocker:
  - [ ] Blocker description
  - [ ] Blocker priority (HIGHEST, HIGH, MEDIUM, LOW)
  - [ ] Blocker impact (blocks critical path, blocks other agents, blocks own work)
  - [ ] Blocker resolution plan
  - [ ] Blocker resolution timeline
  - [ ] Coordination needed (which agents?)

**Dependencies**:
- [ ] List all dependencies on other agents
- [ ] For each dependency:
  - [ ] Dependency description
  - [ ] Dependent agent(s)
  - [ ] Dependency status (ready, in progress, blocked)
  - [ ] Dependency timeline
  - [ ] Coordination needed

**Blocking Others**:
- [ ] List all agents blocked by your work
- [ ] For each blocked agent:
  - [ ] What are they waiting for?
  - [ ] When will it be ready?
  - [ ] Can they work around it?

---

### Section 4: Integration Points

**Integration with Other Agents**:
- [ ] List all integration points with other agents
- [ ] For each integration point:
  - [ ] Integration agent(s)
  - [ ] Integration status (planned, in progress, complete)
  - [ ] Integration API contracts (defined, in progress, undefined)
  - [ ] Integration timeline
  - [ ] Integration blockers (if any)

**Cross-Subcore Integration** (if applicable):
- [ ] List all cross-subcore integration points
- [ ] For each integration point:
  - [ ] Integration subcore(s)
  - [ ] Integration status
  - [ ] Coordination needed
  - [ ] Integration timeline

**Integration Testing**:
- [ ] Integration tests planned?
- [ ] Integration tests implemented?
- [ ] Integration tests passing?
- [ ] Integration test coverage?

---

### Section 5: Parallel Work Opportunities

**Independent Work Available**:
- [ ] List all independent work that can proceed in parallel
- [ ] For each independent work item:
  - [ ] Work description
  - [ ] Dependencies (if any)
  - [ ] Estimated time
  - [ ] Priority

**Parallel Work Stream Assignment** (from parallelization plan):
- [ ] Which parallel work stream are you in?
- [ ] What parallel work can you do?
- [ ] Are you coordinating with other agents in your stream?

**Parallel Work Coordination**:
- [ ] Coordinate with agents in same stream
- [ ] Avoid conflicts with other streams
- [ ] Maximize parallelization efficiency

---

### Section 6: Grain Style Compliance

**Grain Style Status**:
- [ ] All code follows `grain_case` naming
- [ ] All types use explicit `u32`/`u64` (no `usize`/`isize`)
- [ ] All functions ≤ 70 lines (`grain validate-70`)
- [ ] All lines ≤ 100 characters (`grainwrap-100`)
- [ ] All functions have ≥ 2 assertions
- [ ] All allocations are bounded (MAX_ constants)
- [ ] All compiler warnings addressed

**Grain Style Issues**:
- [ ] List any Grain Style compliance issues
- [ ] For each issue:
  - [ ] Issue description
  - [ ] Fix plan
  - [ ] Fix timeline

---

### Section 7: Documentation Updates

**Documentation Status**:
- [ ] Coordination document updated
- [ ] Plan document updated
- [ ] Tasks document updated
- [ ] System integration document updated (if applicable)
- [ ] API documentation updated (if applicable)
- [ ] User documentation updated (if applicable)

**Documentation Needs**:
- [ ] List any documentation needs
- [ ] For each need:
  - [ ] Documentation type
  - [ ] Documentation priority
  - [ ] Documentation timeline

---

### Section 8: Testing Status

**Test Coverage**:
- [ ] Unit tests: Coverage percentage
- [ ] Integration tests: Coverage percentage
- [ ] Test execution: All tests passing?

**Test Results**:
- [ ] All tests passing?
- [ ] Any test failures?
- [ ] Test performance acceptable?

**Test Needs**:
- [ ] List any test needs
- [ ] For each need:
  - [ ] Test type
  - [ ] Test priority
  - [ ] Test timeline

---

### Section 9: Next Steps

**Immediate Next Steps** (This Week):
- [ ] List immediate next steps
- [ ] For each step:
  - [ ] Step description
  - [ ] Step priority
  - [ ] Step timeline
  - [ ] Dependencies

**Short-Term Next Steps** (Next 2 Weeks):
- [ ] List short-term next steps
- [ ] For each step:
  - [ ] Step description
  - [ ] Step priority
  - [ ] Step timeline
  - [ ] Dependencies

**Medium-Term Next Steps** (Next Month):
- [ ] List medium-term next steps
- [ ] For each step:
  - [ ] Step description
  - [ ] Step priority
  - [ ] Step timeline
  - [ ] Dependencies

---

### Section 10: Coordination Needs

**Coordination Requests**:
- [ ] List all coordination requests
- [ ] For each request:
  - [ ] Coordination agent(s)
  - [ ] Coordination topic
  - [ ] Coordination priority
  - [ ] Coordination timeline
  - [ ] Coordination format (meeting, async, document)

**Integration Check-Ins Needed**:
- [ ] List all integration check-ins needed
- [ ] For each check-in:
  - [ ] Integration agent(s)
  - [ ] Integration topic
  - [ ] Check-in priority
  - [ ] Check-in timeline

**Architecture Decisions Needed**:
- [ ] List all architecture decisions needed
- [ ] For each decision:
  - [ ] Decision topic
  - [ ] Decision stakeholders
  - [ ] Decision priority
  - [ ] Decision timeline

---

## Post-Check-In Actions

### After Coordination Check-In

**Required Actions**:
- [ ] Update coordination document with check-in results
- [ ] Update plan document with progress
- [ ] Update tasks document with completed tasks
- [ ] Update system integration document (if applicable)
- [ ] Notify Core 1 Subcore (or parent Subcore) of significant updates
- [ ] Follow up on coordination requests
- [ ] Resolve blockers identified during check-in

**Time Required**: 15-30 minutes

---

## Coordination Frequency

### Weekly Check-Ins

**Standard Frequency**: Weekly (every Monday or Tuesday)

**Agents**: All L2 sub-agents, L1 Subcore Coordinators

**Duration**: 15-30 minutes per agent

**Format**: Async (document updates) or sync (meeting)

### Bi-Weekly Check-Ins

**Standard Frequency**: Bi-weekly (every other week)

**Agents**: L1 Standalone Agents, L1 Subcore Coordinators

**Duration**: 15-30 minutes per agent

**Format**: Async (document updates) or sync (meeting)

### As-Needed Check-Ins

**Triggers**:
- Critical path blockers
- Integration milestones
- Architecture decisions
- Breaking changes
- Significant progress

**Format**: Immediate coordination (meeting or async)

---

## Checklist Usage Guidelines

### For L2 Sub-Agents

**Weekly Check-Ins**:
1. Complete pre-check-in preparation
2. Fill out coordination checklist
3. Update coordination documents
4. Submit to Core 1 Subcore (or parent Subcore)
5. Follow up on coordination requests

**Coordination Document**: `docs/core-coordination/{parent}_{agent}_coordination.md`

### For L1 Subcore Coordinators

**Weekly Check-Ins**:
1. Review all L2 sub-agent check-ins
2. Integrate updates into coordination plan
3. Identify cross-sub-agent coordination needs
4. Update system integration document
5. Create coordination summary

**Coordination Document**: `docs/core-coordination/{agent}_coordination.md`

### For L1 Standalone Agents

**Bi-Weekly Check-Ins**:
1. Complete pre-check-in preparation
2. Fill out coordination checklist
3. Update coordination documents
4. Submit to Core 1 Subcore (or Grain Core Agent)
5. Follow up on coordination requests

**Coordination Document**: `docs/core-coordination/{agent}_coordination.md`

---

## Example Check-In

### Agent: 1a (Grain Auth Agent)

**Date**: 2026-01-06-100000-pst

**Section 1: Status Update**
- **Current Status**: ✅ Production Ready — 6 phases complete
- **Completed Work**: Middleware integration design complete
- **In Progress**: Middleware implementation (50% complete)

**Section 2: Critical Path Awareness**
- **Critical Path Impact**: Not in critical path
- **Critical Path Coordination**: None needed

**Section 3: Blockers and Dependencies**
- **Current Blockers**: None
- **Dependencies**: None blocking
- **Blocking Others**: None

**Section 4: Integration Points**
- **Integration with Network (1b)**: Middleware API contract defined, implementation in progress
- **Integration with Storage (1c)**: Credential storage API contract defined, ready to implement

**Section 5: Parallel Work Opportunities**
- **Stream Assignment**: Stream 1 (Core Services)
- **Parallel Work**: Middleware implementation, production hardening

**Section 6: Grain Style Compliance**
- **Grain Style Status**: ✅ All code compliant
- **Grain Style Issues**: None

**Section 7: Documentation Updates**
- **Documentation Status**: ✅ All documents updated
- **Documentation Needs**: None

**Section 8: Testing Status**
- **Test Coverage**: Unit tests 95%, integration tests 80%
- **Test Results**: ✅ All tests passing

**Section 9: Next Steps**
- **Immediate**: Complete middleware implementation (this week)
- **Short-Term**: Credential storage integration (next 2 weeks)

**Section 10: Coordination Needs**
- **Coordination Requests**: None
- **Integration Check-Ins**: Network Agent (1b) for middleware testing

---

## Notes

- **Frequency**: Use this checklist for every coordination check-in
- **Completeness**: Fill out all applicable sections
- **Timeliness**: Complete check-ins on schedule
- **Follow-Up**: Follow up on coordination requests promptly

---

**Date**: 2026-01-06-095549-pst  
**Agent**: Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **TEMPLATE READY** — Coordination checklist ready for all agents

