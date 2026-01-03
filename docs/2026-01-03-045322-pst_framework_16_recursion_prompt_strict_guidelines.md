# Framework 16: Recursion Prompt Strict Guidelines for Core 1 Subcore

**Date**: 2026-01-03-045322-pst  
**Filename**: `2026-01-03-045322-pst_framework_16_recursion_prompt_strict_guidelines.md` (timestamp prefix format)  
**Context**: Framework 16 (x86_64 AMD, 64GB RAM) running Ubuntu 24.04 LTS host  
**Purpose**: Strict guidelines for Core 1 Subcore recursion prompt execution in Framework Cursor workspace

---

## Executive Summary

This document defines the **strict guidelines** for executing the Core 1 Subcore recursion prompt in the Framework 16 Cursor workspace. These guidelines ensure consistent, comprehensive coordination across all Grain OS agents and sub-agents.

**Key Requirements**:
1. ✅ Check all agent and subagent statuses and system-integration docs
2. ✅ Check git diff and git status
3. ✅ Create new coordination plan with timestamp
4. ✅ Create comprehensive printout summary with timestamp
5. ✅ Commit with Grain Style commit message
6. ✅ Push to main
7. ✅ Include Grain Style compliance instructions
8. ✅ Include documentation update instructions
9. ✅ Include integration check-in instructions

---

## Recursion Prompt Template

**Copy-paste this exact prompt to Core 1 Subcore Agent in Framework Cursor workspace:**

```
check all agent and subagent statuses and system-integration docs and plans and tasks, and check our git diff and git push add all to main with Grain Style commit message when done with new terminal date now yyyy-mm-dd-hhmmss-pst- timestamp, create and print a new Core 1 subcore agent coordination plan for all Grain OS agents and subagents with the same timestamp in the filename. have our Grain Style commit message verify that our previous next steps from the previous coordination doc have been completed and give hints as to the new next current steps just written in the new coordination plan, with the now timestamp

create a printout summary with same timestamp in the summary header, with your agent name being Core 1 Subcore Agent, and structure the whole printout summary to be comprehensive with maximal context used for me to copy and paste for each agent, communicating thorough intentions

in your instructions to each agent, tell them to continue as you and they best recommend, given the context, and tell them remember to follow Grain Style (~/xy-mathematics/docs/grain_style.md ) with grain_case function names and all the strict rules with all compiler warnings turned on, and specifically enforce grainwrap-100 and grain validate-70 and tell them to use explicitly bound u32/u64 not usize/isize, so our code is consistent across all compile target platforms

tell them to continue the next phase of implementation and when they're done update their subagent systems-integration docs and plans and tasks informing you Core 1 Subcore Agent and/or their other respective Subcore Agent parents about how to update the general Grain OS summary ~/xy-mathematics/docs/plan.md and ~/xy-mathematics/docs/tasks.md in thinking. tell them to let us and/or their parent Subcore agents know when they need to check in with me about upcoming integration steps via Core 1 Subcore and/or their parent subcore agents and core-coordination generally with the other agents and subagents so that we prevent accidental conflicts. also tell them to make sure that all their agent-specific and integration new tests as well as existing tests pass that implement their API contracts
```

---

## Step-by-Step Execution Guidelines

### Step 1: Check All Agent and Subagent Statuses

**Required Actions**:
1. **Read all coordination documents**:
   - Core 1 Subcore: `docs/core-coordination/core_1_subcore_coordination.md`
   - Core 1 Subcore L2 sub-agents:
     - `docs/core-coordination/core_1a_auth_coordination.md`
     - `docs/core-coordination/core_1b_network_coordination.md`
     - `docs/core-coordination/core_1c_storage_coordination.md`
     - `docs/core-coordination/core_1d_compositor_coordination.md`
   - Vantage 3 Subcore: `docs/core-coordination/vantage_3_subcore_coordination.md`
   - Vantage 3 Subcore L2 sub-agents:
     - `docs/core-coordination/vantage_3a_basin_kernel_coordination.md`
     - `docs/core-coordination/vantage_3b_vm_runtime_coordination.md`
     - `docs/core-coordination/vantage_3c_system_integration_coordination.md`
   - Aurora 2 Subcore: `docs/core-coordination/aurora_2_subcore_coordination.md`
   - Aurora 2 Subcore L2 sub-agents:
     - `docs/core-coordination/aurora_2a_dream_editor_coordination.md`
     - `docs/core-coordination/aurora_2b_dream_browser_coordination.md`
     - `docs/core-coordination/aurora_2c_component_library_coordination.md`

2. **Read all system-integration documents**:
   - Core 1 Subcore: `docs/core-coordination/core_1_subcore_system_integration.md`
   - Core 1 Subcore L2 sub-agents:
     - `docs/core-coordination/core_1a_auth_system_integration.md`
     - `docs/core-coordination/core_1b_network_system_integration.md`
     - `docs/core-coordination/core_1c_storage_system_integration.md`
     - `docs/core-coordination/core_1d_compositor_system_integration.md`
   - Vantage 3 Subcore: `docs/core-coordination/vantage_3_subcore_system_integration.md`
   - Vantage 3 Subcore L2 sub-agents:
     - `docs/core-coordination/vantage_3a_basin_kernel_system_integration.md`
     - `docs/core-coordination/vantage_3b_vm_runtime_system_integration.md`
     - `docs/core-coordination/vantage_3c_system_integration_coordination.md` (already includes system-integration)
   - Aurora 2 Subcore: `docs/core-coordination/aurora_2_subcore_system_integration.md`
   - Aurora 2 Subcore L2 sub-agents:
     - `docs/core-coordination/aurora_2a_dream_editor_system_integration.md`
     - `docs/core-coordination/aurora_2b_dream_browser_system_integration.md`
     - `docs/core-coordination/aurora_2c_component_library_system_integration.md`
   - (Note: Some agents may not have system-integration docs yet — this is expected during migration)

3. **Read all plan documents**:
   - `docs/plans/core_1_subcore_plan.md`
   - `docs/plans/core_1a_auth_plan.md`
   - `docs/plans/core_1b_network_plan.md`
   - `docs/plans/core_1c_storage_plan.md`
   - `docs/plans/core_1d_compositor_plan.md`
   - (And other relevant plan documents)

4. **Read all tasks documents**:
   - `docs/tasks/core_1_subcore_tasks.md`
   - `docs/tasks/core_1a_auth_tasks.md`
   - `docs/tasks/core_1b_network_tasks.md`
   - `docs/tasks/core_1c_storage_tasks.md`
   - `docs/tasks/core_1d_compositor_tasks.md`
   - (And other relevant tasks documents)

5. **Read general summaries**:
   - `docs/plan.md`
   - `docs/tasks.md`

**Output**: Comprehensive understanding of all agent statuses, progress, blockers, next steps, and system-integration status

---

### Step 2: Check Git Diff and Git Status

**Required Actions**:
1. **Check git status**:
   ```bash
   git status
   ```

2. **Check git diff** (if there are uncommitted changes):
   ```bash
   git diff
   ```

3. **Stage all changes** (if needed):
   ```bash
   git add -A
   ```

**Output**: Understanding of current git state, uncommitted changes, and what needs to be committed

---

### Step 3: Get Current Timestamp

**Required Actions**:
1. **Get timestamp in correct format**:
   ```bash
   TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
   ```

2. **Use this timestamp for**:
   - Coordination plan filename
   - Summary document filename
   - Commit message
   - Document headers

**Format**: `yyyy-mm-dd-hhmmss-pst` (e.g., `2026-01-01-202549-pst`)

**Timezone**: America/Los_Angeles (Pacific Time)

---

### Step 4: Create New Coordination Plan

**Required Actions**:
1. **Create coordination plan document**:
   - Filename: `docs/core-coordination/core_1_subcore_coordination_plan_YYYY-MM-DD-HHMMSS-pst.md`
   - Include comprehensive status of all agents and sub-agents
   - Include previous next steps verification
   - Include new immediate next steps
   - Include integration priorities
   - Include critical blockers

2. **Structure**:
   - Executive Summary
   - Previous Next Steps Status (verify completion)
   - Current Status (all agents)
   - Immediate Next Steps (all agents)
   - Integration Priorities
   - Critical Blockers
   - Grain Style Compliance Requirements
   - Documentation Requirements
   - Test Requirements

3. **Content Requirements**:
   - Verify previous next steps from previous coordination doc
   - Document current status of all agents
   - Provide new immediate next steps
   - Include hints about new next steps in commit message

**Output**: Comprehensive coordination plan document with timestamp

---

### Step 5: Create Comprehensive Printout Summary

**Required Actions**:
1. **Create summary document**:
   - Filename: `docs/agent-communications/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_summary.md` (timestamp prefix format)
   - Agent name: "Core 1 Subcore Agent"
   - Timestamp in header

2. **Structure for Copy-Paste**:
   - Comprehensive context for each agent
   - Agent-specific instructions
   - Grain Style compliance requirements
   - Documentation update instructions
   - Integration check-in instructions
   - Test requirements

3. **Content Requirements**:
   - **For each agent**: Comprehensive section with:
     - Current status
     - Immediate next steps
     - Instructions: "Continue as you and [other agents] best recommend, given the context"
     - Grain Style compliance reminder
     - Documentation update instructions
     - Integration check-in instructions
     - Test requirements

4. **Agent Instructions Must Include**:
   - "Continue as you and [other agents] best recommend, given the context"
   - "Remember to follow Grain Style (`~/xy-mathematics/docs/grain_style.md`) with `grain_case` function names and all the strict rules with all compiler warnings turned on"
   - "Specifically enforce `grainwrap-100` and `grain validate-70`"
   - "Use explicitly bound `u32`/`u64` not `usize`/`isize`, so our code is consistent across all compile target platforms"
   - "When you're done, update your subagent systems-integration docs and plans and tasks, informing Core 1 Subcore Agent and/or their other respective Subcore Agent parents about how to update the general Grain OS summary `~/xy-mathematics/docs/plan.md` and `~/xy-mathematics/docs/tasks.md` in thinking"
   - "Let us and/or their parent Subcore agents know when you need to check in about upcoming integration steps via Core 1 Subcore and/or their parent subcore agents and core-coordination generally with the other agents and subagents so that we prevent accidental conflicts"
   - "Make sure that all your agent-specific and integration new tests as well as existing tests pass that implement your API contracts"

**Output**: Comprehensive printout summary ready for copy-paste to each agent

---

### Step 6: Commit with Grain Style Commit Message

**Required Actions**:
1. **Stage all changes**:
   ```bash
   git add -A
   ```

2. **Create Grain Style commit message**:
   - Format: `agent_name: brief_description_YYYY-MM-DD-HHMMSS-pst`
   - Verify previous next steps completion
   - Document new coordination plan and summary
   - Include hints about new next steps
   - Include current status summary

3. **Commit**:
   ```bash
   git commit -m "core_1_subcore: coordination plan and summary for all agents YYYY-MM-DD-HHMMSS-pst

   previous next steps completed:
   - [list completed items from previous coordination doc]
   
   new coordination plan created:
   - core_1_subcore_coordination_plan_YYYY-MM-DD-HHMMSS-pst.md
   - [brief description of plan contents]
   
   new coordination summary created:
   - core_1_subcore_coordination_summary_YYYY-MM-DD-HHMMSS-pst.md
   - [brief description of summary contents]
   
   current status:
   - [key status items]
   
   immediate priorities:
   - [list immediate priorities]
   
   all agents instructed to:
   - continue as best recommended given context
   - follow grain style strictly (grain_case, u32/u64, grainwrap-100, grain validate-70)
   - update systems-integration docs and plans and tasks
   - inform core 1 subcore about plan.md and tasks.md updates
   - check in before integration steps to prevent conflicts
   - ensure all tests pass"
   ```

**Output**: Committed changes with comprehensive Grain Style commit message

---

### Step 7: Push to Main

**Required Actions**:
1. **Push to main**:
   ```bash
   git push origin main
   ```

2. **Verify push success**:
   - Check git output for success confirmation
   - Verify no errors

**Output**: Changes pushed to main branch

---

## Grain Style Compliance Requirements

### Mandatory Instructions for All Agents

**Include in every agent instruction section**:

1. **Grain Style Compliance**:
   - "Remember to follow Grain Style (`~/xy-mathematics/docs/grain_style.md`) with `grain_case` function names and all the strict rules with all compiler warnings turned on"
   - "Specifically enforce `grainwrap-100` and `grain validate-70`"
   - "Use explicitly bound `u32`/`u64` not `usize`/`isize`, so our code is consistent across all compile target platforms"

2. **Function Naming**: `grain_case` (snake_case)
3. **Type Usage**: Explicit `u32`/`u64`, no `usize`/`isize`
4. **Line Length**: ≤100 characters (`grainwrap-100`)
5. **Function Length**: ≤70 lines (`grain validate-70`)
6. **Assertions**: Minimum 2 assertions per function
7. **Bounded Allocations**: All MAX_ constants defined
8. **Compiler Warnings**: All warnings addressed

---

## Documentation Update Requirements

### Mandatory Instructions for All Agents

**Include in every agent instruction section**:

1. **Update System-Integration Docs**:
   - "When you're done, update your agent system-integration docs and plans and tasks"
   - "System-integration doc location: `docs/core-coordination/{agent}_system_integration.md`"
   - "Informing Core 1 Subcore Agent and/or their other respective Subcore Agent parents about how to update the general Grain OS summary `~/xy-mathematics/docs/plan.md` and `~/xy-mathematics/docs/tasks.md` in thinking"

2. **Required Updates**:
   - Coordination documents (after each work session)
   - Plan documents (as implementation evolves)
   - Tasks documents (as tasks are completed)
   - General summaries (`docs/plan.md`, `docs/tasks.md`) — inform Core 1 Subcore

---

## Integration Check-In Requirements

### Mandatory Instructions for All Agents

**Include in every agent instruction section**:

1. **Check-In Before Integration**:
   - "Let us and/or their parent Subcore agents know when you need to check in about upcoming integration steps via Core 1 Subcore and/or their parent subcore agents and core-coordination generally with the other agents and subagents so that we prevent accidental conflicts"

2. **When to Check In**:
   - Before starting integration work with other agents
   - When API contracts need coordination
   - When breaking changes affect other agents
   - When critical blockers arise

3. **How to Check In**:
   - Through Core 1 Subcore for Core 1 sub-agents
   - Through parent Subcore Agent for L2 sub-agents
   - Through Core 1 Subcore for cross-subcore coordination

---

## Test Requirements

### Mandatory Instructions for All Agents

**Include in every agent instruction section**:

1. **Test Requirements**:
   - "Make sure that all your agent-specific and integration new tests as well as existing tests pass that implement your API contracts"

2. **Required Tests**:
   - All agent-specific tests pass
   - All integration tests pass
   - All API contract tests pass
   - All existing tests pass

---

## Timestamp Format Requirements

### Strict Format

**Format**: `yyyy-mm-dd-hhmmss-pst`

**Example**: `2026-01-01-202549-pst`

**Timezone**: America/Los_Angeles (Pacific Time)

**Usage**:
- Coordination plan filename
- Summary document filename
- Commit message
- Document headers

**Command**:
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

---

## File Naming Conventions

**CRITICAL**: All documents with timestamps must use **timestamp prefix format** for automatic alphanumeric sorting on Codeberg.

### Timestamp Prefix Format (REQUIRED)

**Format**: `YYYY-MM-DD-HHMMSS-pst_document_name.md`

**Example**: `2026-01-01-202549-pst_core_1_subcore_coordination_plan.md`

**Why**: Timestamp prefix ensures automatic chronological sorting in file listings (Codeberg, file browsers, etc.)

**Rule**: **ALWAYS** put timestamp at the beginning of the filename, separated by underscore.

---

### Coordination Plan

**Format**: `docs/core-coordination/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_plan.md`

**Example**: `docs/core-coordination/2026-01-01-202549-pst_core_1_subcore_coordination_plan.md`

---

### Coordination Summary

**Format**: `docs/agent-communications/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_summary.md`

**Example**: `docs/agent-communications/2026-01-01-202549-pst_core_1_subcore_coordination_summary.md`

---

### All Agent Communication Documents

**Format**: `docs/agent-communications/YYYY-MM-DD-HHMMSS-pst_document_name.md`

**Example**: `docs/agent-communications/2026-01-02-100345-pst_vantage_3_subcore_to_3b_guest_ram_pointer_architecture.md`

**Rule**: **ALWAYS** use timestamp prefix format for all new documents.

---

## Commit Message Format

### Grain Style Commit Message

**Format**:
```
agent_name: brief_description

YYYY-MM-DD-HHMMSS-pst (timestamp in commit message body, not filename)

previous next steps completed:
- [list completed items]

new coordination plan created:
- [plan filename and description]

new coordination summary created:
- [summary filename and description]

current status:
- [key status items]

immediate priorities:
- [list immediate priorities]

all agents instructed to:
- [list instructions]
```

**Example**:
```
core_1_subcore: coordination plan and summary for all agents

2026-01-01-202549-pst (timestamp in commit message body)

previous next steps completed:
- core 1 subcore plan and tasks documents created
- all l2 sub-agents have coordination, plan, and tasks documents
- weekly/bi-weekly check-in schedule established
- cross-sub-agent api design and integration planning in progress

new coordination plan created:
- core_1_subcore_coordination_plan_2026-01-01-202549-pst.md
- comprehensive coordination plan for all grain os agents and sub-agents
- immediate next steps for core 1 subcore l2 sub-agents
- immediate next steps for vantage 3 subcore and l2 sub-agents
- immediate next steps for aurora 2 subcore and l2 sub-agents
- immediate next steps for non-core, non-aurora agents
- critical blockers resolution status
- integration priorities and coordination needs

new coordination summary created:
- core_1_subcore_coordination_summary_2026-01-01-202549-pst.md
- comprehensive printout summary for copy-paste distribution to all agents
- agent-specific instructions with immediate next steps
- grain style compliance requirements
- documentation requirements
- integration check-in requirements
- test requirements

current status:
- payment/vault/bank storage schema: approved (2026-01-01-083955-pst)
- storage ↔ network integration: 100% complete, ready for testing
- network agent phases 1-4: complete, ready for auth agent coordination
- auth agent phases 1-6.2: complete, middleware integration ready
- compositor agent phases 1-6, 8 preview: complete, phase 7 ready
- vantage 3 subcore: all kernel features complete, l2 sub-agents active
- aurora 2 subcore: architecture evolution complete, l2 sub-agents active
- compilation errors: build.zig fixed, remaining errors to be resolved
- non-core, non-aurora agents: parallel development prompt distributed

immediate priorities:
- auth ↔ network middleware integration: api contract design session
- network integration testing: execute file transfer integration tests
- compilation errors: resolve remaining compilation errors
- component api design: aurora 2 subcore coordinates with bubble agent
- silo agent passwordstorage: begin implementation (~1 day)

all agents instructed to:
- continue as best recommended given context
- follow grain style strictly (grain_case, u32/u64, grainwrap-100, grain validate-70)
- update systems-integration docs and plans and tasks
- inform core 1 subcore about plan.md and tasks.md updates
- check in before integration steps to prevent conflicts
- ensure all tests pass
```

---

## Verification Checklist

### Before Committing

- [ ] All agent statuses checked
- [ ] All coordination documents read
- [ ] All plan documents read
- [ ] All tasks documents read
- [ ] Git status checked
- [ ] Git diff reviewed (if applicable)
- [ ] Timestamp generated correctly
- [ ] Coordination plan created with timestamp
- [ ] Summary document created with timestamp
- [ ] All agent instructions include Grain Style compliance
- [ ] All agent instructions include documentation updates
- [ ] All agent instructions include integration check-ins
- [ ] All agent instructions include test requirements
- [ ] Commit message verifies previous next steps
- [ ] Commit message includes hints about new next steps
- [ ] Commit message follows Grain Style format

### Before Pushing

- [ ] All changes committed
- [ ] Commit message is comprehensive
- [ ] No uncommitted changes
- [ ] Ready to push to main

---

## Framework 16 Specific Considerations

### Environment

- **Host OS**: Ubuntu 24.04 LTS
- **VM**: NixOS 25.11 minimal Linux kernel 6.18.2 VM (via QEMU/KVM)
- **Workspace**: Framework 16 Cursor workspace
- **Repository**: `xy-mathematics` (cloned in Framework workspace)

### Paths

- **Grain Style**: `~/xy-mathematics/docs/grain_style.md`
- **Plan**: `~/xy-mathematics/docs/plan.md`
- **Tasks**: `~/xy-mathematics/docs/tasks.md`
- **Coordination Docs**: `~/xy-mathematics/docs/core-coordination/`
- **Agent Communications**: `~/xy-mathematics/docs/agent-communications/`

### Timestamp Generation

**Command** (run in Framework workspace):
```bash
cd ~/xy-mathematics
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

---

## Common Mistakes to Avoid

### ❌ Don't Do This

1. **Missing Timestamp**: Forgetting to generate timestamp or using wrong format
2. **Incomplete Status Check**: Not reading all coordination/plan/tasks documents
3. **Missing Instructions**: Not including all required instructions for agents
4. **Incomplete Commit Message**: Not verifying previous next steps or including hints
5. **Wrong File Paths**: Using incorrect paths (should be `~/xy-mathematics/...`)
6. **Missing Grain Style**: Not including Grain Style compliance instructions
7. **Missing Documentation Updates**: Not including documentation update instructions
8. **Missing Integration Check-Ins**: Not including integration check-in instructions
9. **Missing Test Requirements**: Not including test requirements
10. **Wrong Timezone**: Using wrong timezone (must be America/Los_Angeles)

### ✅ Do This Instead

1. **Always Generate Timestamp**: Use `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
2. **Read All Documents**: Check all coordination, plan, and tasks documents
3. **Include All Instructions**: Include Grain Style, documentation, integration, tests
4. **Comprehensive Commit Message**: Verify previous steps, include hints, document new work
5. **Use Correct Paths**: Use `~/xy-mathematics/...` paths
6. **Follow Format**: Use exact format for filenames and commit messages
7. **Verify Before Push**: Check all requirements before pushing

---

## Summary

**Recursion Prompt Execution**:
1. ✅ Check all agent statuses and docs
2. ✅ Check git diff and status
3. ✅ Generate timestamp
4. ✅ Create coordination plan
5. ✅ Create comprehensive summary
6. ✅ Commit with Grain Style message
7. ✅ Push to main

**Required Instructions for All Agents**:
- Grain Style compliance (grain_case, u32/u64, grainwrap-100, grain validate-70)
- Documentation updates (coordination, plan, tasks, plan.md, tasks.md)
- Integration check-ins (before integration steps)
- Test requirements (all tests must pass)

**Timestamp Format**: `yyyy-mm-dd-hhmmss-pst` (America/Los_Angeles)

**File Naming**: Include timestamp in all new documents

---

**Date**: 2026-01-03-045322-pst  
**Filename**: `2026-01-03-045322-pst_framework_16_recursion_prompt_strict_guidelines.md` (timestamp prefix format)  
**Status**: ✅ **RECURSION PROMPT GUIDELINES COMPLETE** — Ready for Framework 16 Cursor workspace  
**Next Steps**: Use this document as reference when executing recursion prompt in Framework workspace
