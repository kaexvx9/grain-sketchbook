# Grain OS: Documentation Unification Plan

**Date**: 2026-01-03-052459-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Purpose**: Unify documentation locations for all agents/sub-agents, include system-integration docs, improve recursion cycle and L1<->L2 integration patterns  
**Status**: ✅ **UNIFICATION PLAN CREATED** — Ready for implementation

---

## Executive Summary

This document provides a comprehensive plan to:
1. **Unify documentation locations** for all agents and sub-agents
2. **Consolidate system-integration documentation** into a clear structure
3. **Improve recursion cycle patterns** for Core 1 Subcore coordination
4. **Enhance L1<->L2 integration patterns** for better coordination
5. **Mark deprecated documents** for archaeological preservation

**Key Changes**:
- Standardize all agent documentation to three core documents per agent/sub-agent
- Consolidate system-integration docs into unified structure
- Improve recursion prompt to include system-integration doc checks
- Enhance L1<->L2 coordination patterns with clearer communication flows
- Archive old-format documents to `archaeology/` directory

---

## Current Documentation Structure Analysis

### Current State

**Agent Documentation Locations**:
- ✅ **New Format** (Standardized):
  - Coordination: `docs/core-coordination/{agent}_coordination.md`
  - Plan: `docs/plans/{agent}_plan.md`
  - Tasks: `docs/tasks/{agent}_tasks.md`
- ⚠️ **Old Format** (Legacy, needs migration):
  - Plan: `docs/plans/plan_{agent}.md` (e.g., `plan_aurora.md`, `plan_core.md`)
  - Tasks: `docs/tasks/tasks_{agent}.md` (e.g., `tasks_aurora.md`, `tasks_core.md`)

**System-Integration Documentation**:
- ⚠️ **Scattered** across `docs/core-coordination/` with various naming patterns:
  - `core_1_subcore_system_integration_*.md` (multiple versions with timestamps)
  - `core_1_subcore_system_integration_coordination_*.md` (multiple versions)
  - `vantage_3c_system_integration_coordination.md`
  - `core_1a_auth_system_integration_*.md`
  - `core_1c_storage_system_integration.md`
  - Various other system-integration related docs

**Recursion and Coordination Patterns**:
- ✅ **Recursion Guidelines**: `docs/2026-01-03-045322-pst_framework_16_recursion_prompt_strict_guidelines.md`
- ⚠️ **L1<->L2 Patterns**: Documented in multiple places:
  - `docs/core-coordination/core_1_subcore_coordination.md`
  - `docs/grain_*_agent_prompt.md` files
  - Various coordination documents

---

## Unified Documentation Structure

### Standard Agent Documentation Structure

**Every agent/sub-agent must have exactly three core documents**:

1. **Coordination Document**: `docs/core-coordination/{agent}_coordination.md`
   - Status, progress, blockers
   - Coordination decisions
   - Next steps for other agents
   - Updated after each work session

2. **Plan Document**: `docs/plans/{agent}_plan.md`
   - Implementation plan
   - Phase descriptions
   - Architecture decisions
   - Updated as plan evolves

3. **Tasks Document**: `docs/tasks/{agent}_tasks.md`
   - Detailed task list
   - Task completion status
   - Task dependencies
   - Updated as tasks are completed

**Naming Convention**:
- **L1 Subcore Coordinators**: `{subcore_name}_subcore_coordination.md` (e.g., `core_1_subcore_coordination.md`)
- **L2 Sub-Agents**: `{subcore_name}_{agent_id}_{agent_name}_coordination.md` (e.g., `core_1a_auth_coordination.md`)
- **Standalone L1 Agents**: `{agent_name}_agent_coordination.md` (e.g., `skate_agent_coordination.md`)

### System-Integration Documentation Structure

**Unified System-Integration Document Location**:

**Primary System-Integration Document** (per agent/sub-agent):
- `docs/core-coordination/{agent}_system_integration.md`
- **Purpose**: Comprehensive system-integration status, cross-agent integration points, integration testing status
- **Updated**: After each integration milestone or coordination session

**System-Integration Coordination Documents** (cross-agent):
- `docs/core-coordination/{agent1}_{agent2}_integration_coordination.md`
- **Purpose**: Cross-agent integration planning and coordination
- **Example**: `docs/core-coordination/core_1e_grainscript_shell_vantage_3d_init_system_integration_coordination.md`

**System-Integration Status Documents** (timestamped, for historical tracking):
- `docs/core-coordination/YYYY-MM-DD-HHMMSS-pst_{agent}_system_integration_status.md`
- **Purpose**: Snapshot of system-integration status at specific points in time
- **Updated**: As needed for historical tracking

**Consolidation Strategy**:
1. **Identify primary system-integration doc** for each agent (most recent, comprehensive version)
2. **Rename to standard format**: `{agent}_system_integration.md`
3. **Archive timestamped versions** to `archaeology/docs/core-coordination/system-integration-archive/`
4. **Create cross-agent integration docs** for major integration points

---

## Improved Recursion Cycle Pattern

### Enhanced Recursion Prompt

**Updated recursion prompt template** (to be integrated into recursion guidelines):

```
check all agent and subagent statuses and system-integration docs and plans and tasks, and check our git diff and git push add all to main with Grain Style commit message when done with new terminal date now yyyy-mm-dd-hhmmss-pst- timestamp, create and print a new Core 1 subcore agent coordination plan for all Grain OS agents and subagents with the same timestamp in the filename. have our Grain Style commit message verify that our previous next steps from the previous coordination doc have been completed and give hints as to the new next current steps just written in the new coordination plan, with the now timestamp

create a printout summary with same timestamp in the summary header, with your agent name being Core 1 Subcore Agent, and structure the whole printout summary to be comprehensive with maximal context used for me to copy and paste for each agent, communicating thorough intentions

in your instructions to each agent, tell them to continue as you and they best recommend, given the context, and tell them remember to follow Grain Style (~/xy-mathematics/docs/grain_style.md ) with grain_case function names and all the strict rules with all compiler warnings turned on, and specifically enforce grainwrap-100 and grain validate-70 and tell them to use explicitly bound u32/u64 not usize/isize, so our code is consistent across all compile target platforms

tell them to continue the next phase of implementation and when they're done update their agent system-integration docs and plans and tasks informing you Core 1 Subcore Agent and/or their other respective Subcore Agent parents about how to update the general Grain OS summary ~/xy-mathematics/docs/plan.md and ~/xy-mathematics/docs/tasks.md in thinking. tell them to let us and/or their parent Subcore agents know when they need to check in with me about upcoming integration steps via Core 1 Subcore and/or their parent subcore agents and core-coordination generally with the other agents and subagents so that we prevent accidental conflicts. also tell them to make sure that all their agent-specific and integration new tests as well as existing tests pass that implement their API contracts
```

**Key Changes**:
- ✅ Explicitly includes "system-integration docs" in status check
- ✅ Instructs agents to update "system-integration docs" (not just "systems-integration docs")
- ✅ Maintains all existing requirements (Grain Style, documentation, integration, tests)

### Recursion Cycle Steps (Enhanced)

**Step 1: Check All Agent and Subagent Statuses** (Enhanced):
1. **Read all coordination documents**: `docs/core-coordination/{agent}_coordination.md`
2. **Read all system-integration documents**: `docs/core-coordination/{agent}_system_integration.md`
3. **Read all plan documents**: `docs/plans/{agent}_plan.md`
4. **Read all tasks documents**: `docs/tasks/{agent}_tasks.md`
5. **Read general summaries**: `docs/plan.md`, `docs/tasks.md`

**Step 2-7**: (Unchanged from current recursion guidelines)

---

## Improved L1<->L2 Integration Patterns

### Enhanced L1 Subcore Coordinator Responsibilities

**L1 Subcore Coordinators** (Core 1, Aurora 2, Vantage 3) must:

1. **Maintain Unified System-Integration Document**:
   - Primary doc: `docs/core-coordination/{subcore}_subcore_system_integration.md`
   - Updated after each coordination cycle
   - Includes cross-subcore integration points

2. **Coordinate L2 Sub-Agent System-Integration**:
   - Review L2 system-integration docs: `docs/core-coordination/{subcore}_{id}_{name}_system_integration.md`
   - Aggregate L2 integration status into L1 system-integration doc
   - Coordinate cross-L2 integration points

3. **Facilitate Cross-Subcore Integration**:
   - Coordinate with other L1 Subcore Coordinators on cross-subcore integration
   - Document cross-subcore integration points in system-integration docs
   - Plan cross-subcore integration milestones

### Enhanced L2 Sub-Agent Responsibilities

**L2 Sub-Agents** must:

1. **Maintain System-Integration Document**:
   - Primary doc: `docs/core-coordination/{subcore}_{id}_{name}_system_integration.md`
   - Updated after each work session
   - Includes integration status with other agents/sub-agents

2. **Coordinate Through L1 Parent**:
   - Update L1 parent on integration needs
   - Request L1 parent coordination for cross-subcore integration
   - Document integration decisions in system-integration doc

3. **Direct L2<->L2 Coordination** (Minimal, Documented):
   - Direct coordination only for immediate technical needs
   - Document all direct L2<->L2 coordination in system-integration docs
   - Inform L1 parent of direct coordination

### Communication Flow Patterns

**L2 → L1 Communication**:
1. **Regular Updates**: L2 updates coordination, plan, tasks, and system-integration docs
2. **Integration Requests**: L2 requests L1 coordination for cross-subcore integration
3. **Blocker Escalation**: L2 escalates blockers to L1 for resolution

**L1 → L2 Communication**:
1. **Coordination Plans**: L1 provides coordination plans via recursion cycle
2. **Integration Guidance**: L1 provides integration guidance and API contracts
3. **Priority Coordination**: L1 coordinates priorities across L2 sub-agents

**L1 ↔ L1 Communication** (Cross-Subcore):
1. **Direct Coordination**: L1 Subcore Coordinators coordinate directly on cross-subcore integration
2. **System-Integration Docs**: L1 updates system-integration docs with cross-subcore integration points
3. **Grain Core Agent**: L1 coordinates with Grain Core Agent for system-wide decisions

---

## Migration Plan

### Phase 1: Identify and Consolidate System-Integration Docs (This Week)

**Tasks**:
1. **Identify all system-integration docs**:
   - Search `docs/core-coordination/` for `*system_integration*.md`
   - List all system-integration related documents

2. **Identify primary system-integration doc per agent**:
   - For each agent, identify most recent, comprehensive system-integration doc
   - Mark as primary doc

3. **Rename primary docs to standard format**:
   - `{agent}_system_integration.md` (no timestamp in filename)
   - Update internal timestamps to "Last Updated" format

4. **Archive timestamped versions**:
   - Move to `archaeology/docs/core-coordination/system-integration-archive/`
   - Preserve for historical reference

**Deliverables**:
- Unified system-integration doc per agent/sub-agent
- Archived timestamped versions
- Migration log document

### Phase 2: Migrate Old-Format Plan/Tasks Docs (Week 1-2)

**Tasks**:
1. **Identify old-format docs**:
   - `docs/plans/plan_*.md` (except `plan.md` main doc)
   - `docs/tasks/tasks_*.md` (except `tasks.md` main doc)

2. **Check for new-format equivalents**:
   - Verify new-format doc exists for each old-format doc
   - If new-format exists, mark old-format as deprecated
   - If new-format missing, create from old-format

3. **Archive old-format docs**:
   - Move to `archaeology/docs/plans/legacy/`
   - Move to `archaeology/docs/tasks/legacy/`
   - Add deprecation notice to archived docs

**Deliverables**:
- All agents have new-format plan/tasks docs
- Old-format docs archived
- Migration log updated

### Phase 3: Update Recursion Guidelines (Week 1)

**Tasks**:
1. **Update recursion guidelines**:
   - Add system-integration doc checks to Step 1
   - Update recursion prompt template
   - Add system-integration doc update instructions

2. **Update coordination summary template**:
   - Include system-integration doc update instructions
   - Add system-integration status section

**Deliverables**:
- Updated recursion guidelines
- Updated coordination summary template

### Phase 4: Update L1<->L2 Integration Patterns (Week 1-2)

**Tasks**:
1. **Create unified L1<->L2 integration pattern doc**:
   - `docs/2026-01-03-052459-pst_l1_l2_integration_patterns.md`
   - Document enhanced communication flows
   - Document system-integration doc responsibilities

2. **Update agent prompt templates**:
   - Include system-integration doc requirements
   - Update L1<->L2 coordination patterns

3. **Mark old pattern docs as deprecated**:
   - Add deprecation notices to old pattern docs
   - Archive to `archaeology/docs/agent-communications/patterns/`

**Deliverables**:
- Unified L1<->L2 integration pattern doc
- Updated agent prompt templates
- Deprecated old pattern docs

---

## Deprecated Documents

### Documents to Mark as Deprecated

**Old-Format Plan/Tasks Docs** (to be archived):
- `docs/plans/plan_aurora.md` → Use `docs/plans/aurora_2_subcore_plan.md`
- `docs/plans/plan_core.md` → Use `docs/plans/core_1_subcore_plan.md`
- `docs/plans/plan_skate.md` → Use `docs/plans/skate_agent_plan.md`
- `docs/plans/plan_bubble.md` → Use `docs/plans/bubble_agent_plan.md`
- `docs/plans/plan_carry.md` → Use `docs/plans/carry_agent_plan.md`
- `docs/plans/plan_database.md` → Use `docs/plans/silo_agent_plan.md`
- `docs/plans/plan_workspace.md` → Use `docs/plans/workspace_agent_plan.md`
- `docs/plans/plan_flow.md` → Use `docs/plans/flow_agent_plan.md`
- `docs/plans/plan_research.md` → Use `docs/plans/research_agent_plan.md`
- `docs/plans/plan_court.md` → Use `docs/plans/court_agent_plan.md`
- `docs/plans/plan_dream_editor.md` → Use `docs/plans/aurora_2a_dream_editor_plan.md`
- `docs/plans/plan_dream_browser.md` → Use `docs/plans/aurora_2b_dream_browser_plan.md`
- `docs/plans/plan_component_library.md` → Use `docs/plans/aurora_2c_component_library_plan.md`
- (And corresponding `tasks_*.md` files)

**Old Pattern Documentation** (to be archived):
- `docs/core-coordination/core_1_subcore_coordination_guide.md` → Use unified integration patterns doc
- Various old coordination pattern docs in `docs/agent-communications/`

**Timestamped System-Integration Docs** (to be archived after consolidation):
- All `*_system_integration_YYYY-MM-DD-HHMMSS-pst.md` files (after primary doc identified)

### Deprecation Notice Format

**Add to top of deprecated documents**:

```markdown
> **⚠️ DEPRECATED**: This document is deprecated as of 2026-01-03-052459-pst.
> 
> **Replacement**: See `docs/2026-01-03-052459-pst_documentation_unification_plan.md` for unified documentation structure.
> 
> **New Location**: This document will be archived to `archaeology/docs/` for historical reference.
> 
> **Status**: Archived — Do not use for new work. Refer to replacement document.
```

---

## Implementation Checklist

### Immediate Actions (This Week)

- [ ] **Phase 1**: Identify and consolidate system-integration docs
  - [ ] Search and list all system-integration docs
  - [ ] Identify primary doc per agent
  - [ ] Rename primary docs to standard format
  - [ ] Archive timestamped versions

- [ ] **Phase 3**: Update recursion guidelines
  - [ ] Add system-integration doc checks
  - [ ] Update recursion prompt template
  - [ ] Update coordination summary template

### Week 1-2 Actions

- [ ] **Phase 2**: Migrate old-format plan/tasks docs
  - [ ] Identify old-format docs
  - [ ] Verify new-format equivalents
  - [ ] Create missing new-format docs
  - [ ] Archive old-format docs

- [ ] **Phase 4**: Update L1<->L2 integration patterns
  - [ ] Create unified integration pattern doc
  - [ ] Update agent prompt templates
  - [ ] Mark old pattern docs as deprecated

### Ongoing

- [ ] **Monitor**: Ensure all agents follow unified structure
- [ ] **Enforce**: Require system-integration doc updates in recursion cycle
- [ ] **Archive**: Move deprecated docs to archaeology as needed

---

## Success Criteria

### Phase 1 Success
- ✅ All agents have unified system-integration doc
- ✅ Timestamped versions archived
- ✅ Migration log created

### Phase 2 Success
- ✅ All agents have new-format plan/tasks docs
- ✅ Old-format docs archived
- ✅ No duplicate plan/tasks docs

### Phase 3 Success
- ✅ Recursion guidelines updated
- ✅ Recursion prompt includes system-integration checks
- ✅ Coordination summary includes system-integration instructions

### Phase 4 Success
- ✅ Unified L1<->L2 integration pattern doc created
- ✅ Agent prompt templates updated
- ✅ Old pattern docs deprecated and archived

### Overall Success
- ✅ All agents follow unified documentation structure
- ✅ System-integration docs consolidated and maintained
- ✅ Recursion cycle includes system-integration doc checks
- ✅ L1<->L2 integration patterns improved and documented
- ✅ Deprecated docs marked and archived

---

## Reference Documents

**Unified Documentation Structure**:
- This document: `docs/2026-01-03-052459-pst_documentation_unification_plan.md`
- Recursion Guidelines: `docs/2026-01-03-045322-pst_framework_16_recursion_prompt_strict_guidelines.md`
- Agent List: `docs/2026-01-03-044511-pst_framework_16_agent_list_with_subagents.md`
- Documentation Navigation: `docs/2026-01-03-044110-pst_documentation_navigation_guide.md`

**System-Integration Docs** (Examples):
- Core 1 Subcore: `docs/core-coordination/core_1_subcore_system_integration.md` (to be created/consolidated)
- System Integration Agent: `docs/core-coordination/vantage_3c_system_integration_coordination.md`

**Agent Documentation** (Examples):
- Core 1 Subcore: `docs/core-coordination/core_1_subcore_coordination.md`
- Auth Agent: `docs/core-coordination/core_1a_auth_coordination.md`

---

**Date**: 2026-01-03-052459-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **UNIFICATION PLAN COMPLETE** — Ready for implementation  
**Next Steps**: Begin Phase 1 (System-Integration Doc Consolidation)

