# Core 1 Subcore Recursion Prompt Template

**Date**: 2026-01-03-074700-pst  
**Purpose**: Template for Core 1 Subcore to integrate sub-agent updates and maintain coordination documents  
**Status**: ✅ **TEMPLATE READY** — Copy-paste ready for Core 1 Subcore

---

## Usage Instructions

**Copy this entire prompt and paste it to Core 1 Subcore Agent to execute a coordination update cycle after sub-agents have completed their recursion prompts.**

**When to Use**:
- After sub-agents complete their recursion prompts
- Before coordination check-ins
- When integrating updates from multiple sub-agents
- When updating general coordination summaries

---

## Recursion Prompt Template

```
check all agent and subagent statuses and system-integration docs and plans and tasks, and check our git diff and git status, and integrate all sub-agent updates including their new directory structure path updates into my Core 1 Subcore coordination documents.

update any references to old agent-communications paths to use the new hierarchical directory structure:
- old: docs/agent-communications/glow_g2_voice_multi_agent_prompt_*.md
- new: docs/agent-communications/general/prompts/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md

- old: docs/agent-communications/core_1_subcore_coordination_summary_*.md
- new: docs/agent-communications/general/coordination/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_summary.md

- old: docs/agent-communications/critical_path_*.md
- new: docs/agent-communications/general/templates/2026-01-02-084259-pst_critical_path_quick_reference_2026-01-02-084259-pst.md

see docs/agent-communications/README.md and docs/agent-communications/general/templates/2026-01-03-055549-pst_directory_structure_pattern.md for complete directory structure guidance.

when done with all updates, create and print a new Core 1 subcore agent coordination plan for all Grain OS agents and subagents with the same timestamp in the filename using terminal date now yyyy-mm-dd-hhmmss-pst timestamp.

create a printout summary with same timestamp in the summary header, with your agent name being Core 1 Subcore Agent, and structure the whole printout summary to be comprehensive with maximal context used for me to copy and paste for each agent, communicating thorough intentions.

in your instructions to each agent, tell them to continue as you and they best recommend, given the context, and tell them remember to follow Grain Style (~/xy-mathematics/docs/grain_style.md) with grain_case function names and all the strict rules with all compiler warnings turned on, and specifically enforce grainwrap-100 and grain validate-70 and tell them to use explicitly bound u32/u64 not usize/isize, so our code is consistent across all compile target platforms.

tell them to continue the next phase of implementation and when they're done update their subagent systems-integration docs and plans and tasks informing you Core 1 Subcore Agent and/or their other respective Subcore Agent parents about how to update the general Grain OS summary ~/xy-mathematics/docs/plan.md and ~/xy-mathematics/docs/tasks.md in thinking. tell them to let us and/or their parent Subcore agents know when they need to check in with me about upcoming integration steps via Core 1 Subcore and/or their parent subcore agents and core-coordination generally with the other agents and subagents so that we prevent accidental conflicts. also tell them to make sure that all their agent-specific and integration new tests as well as existing tests pass that implement their API contracts.

commit with Grain Style commit message using the same timestamp, and push to main.

verify that all my documentation follows timestamp prefix format for new documents, Grain Style compliance, Glow G2 voice, and new directory structure paths for agent-communications references.
```

---

## Detailed Instructions

### Step 1: Check All Agent and Subagent Statuses

**Required Actions**:
1. **Read all Core 1 Subcore L2 sub-agent coordination documents**:
   - `docs/core-coordination/core_1a_auth_coordination.md`
   - `docs/core-coordination/core_1b_network_coordination.md`
   - `docs/core-coordination/core_1c_storage_coordination.md`
   - `docs/core-coordination/core_1d_compositor_coordination.md`
   - `docs/core-coordination/core_1e_grainscript_shell_coordination.md`

2. **Read all Core 1 Subcore L2 sub-agent system-integration documents**:
   - `docs/core-coordination/core_1a_auth_system_integration.md`
   - `docs/core-coordination/core_1b_network_system_integration.md`
   - `docs/core-coordination/core_1c_storage_system_integration.md`
   - `docs/core-coordination/core_1d_compositor_system_integration.md`
   - `docs/core-coordination/core_1e_grainscript_shell_system_integration.md` (if exists)

3. **Read all Core 1 Subcore L2 sub-agent plan documents**:
   - `docs/plans/core_1a_auth_plan.md`
   - `docs/plans/core_1b_network_plan.md`
   - `docs/plans/core_1c_storage_plan.md`
   - `docs/plans/core_1d_compositor_plan.md`
   - `docs/plans/core_1e_grainscript_shell_plan.md` (if exists)

4. **Read all Core 1 Subcore L2 sub-agent tasks documents**:
   - `docs/tasks/core_1a_auth_tasks.md`
   - `docs/tasks/core_1b_network_tasks.md`
   - `docs/tasks/core_1c_storage_tasks.md`
   - `docs/tasks/core_1d_compositor_tasks.md`
   - `docs/tasks/core_1e_grainscript_shell_tasks.md` (if exists)

5. **Read other L1 Subcore coordination documents** (for cross-subcore awareness):
   - `docs/core-coordination/aurora_2_subcore_coordination.md`
   - `docs/core-coordination/vantage_3_subcore_coordination.md`

6. **Read Core 1 Subcore coordination documents**:
   - `docs/core-coordination/core_1_subcore_coordination.md`
   - `docs/core-coordination/core_1_subcore_system_integration.md`

### Step 2: Check Git Status and Diff

**Required Actions**:
1. **Check git status**: `git status`
   - Identify new files, modified files from sub-agents
   - Note any new agent-communications documents in new directory structure

2. **Check git diff**: `git diff`
   - Review sub-agent documentation updates
   - Review sub-agent code changes
   - Note any directory structure path updates

3. **Review recent commits**: `git log --oneline -20`
   - Understand what work sub-agents completed
   - Note any integration points or dependencies
   - Verify sub-agents updated their documentation

### Step 3: Integrate Sub-Agent Updates

**Required Actions**:

1. **Review Sub-Agent Directory Structure Updates**:
   - Check if sub-agents updated their references to new directory structure
   - Verify sub-agents are using new paths in their documentation
   - Note any remaining old path references that need updating

2. **Update Core 1 Subcore Coordination Document**:
   - Integrate completed work from all sub-agents
   - Update current status for each sub-agent
   - Update blockers (if any resolved or new ones)
   - Update integration points between sub-agents
   - Update cross-subcore coordination status
   - Use timestamp prefix format for any new sections

3. **Update Core 1 Subcore System-Integration Document**:
   - Update integration points with sub-agents
   - Note any new dependencies
   - Update coordination status with other L1 Subcores
   - Update sevenos integration status

4. **Update Core 1 Subcore Plan Document**:
   - Reflect actual implementation vs. planned work
   - Update priorities based on current state
   - Add new planned work if needed
   - Update critical path status

5. **Update Core 1 Subcore Tasks Document**:
   - Mark completed tasks with timestamps
   - Add new tasks if needed
   - Update task priorities

### Step 4: Update Directory Structure References

**Required Actions**:

1. **Find Old Paths in Core 1 Subcore Documents**:
   - Search for references to `docs/agent-communications/` with old flat structure
   - Common patterns:
     - `docs/agent-communications/glow_g2_voice_*.md`
     - `docs/agent-communications/timestamp_specification_*.md`
     - `docs/agent-communications/core_1_subcore_coordination_summary_*.md`
     - `docs/agent-communications/critical_path_*.md`
     - `docs/agent-communications/core_1{X}_*.md` (for sub-agent specific)

2. **Update to New Paths**:
   - **General prompts**: `docs/agent-communications/general/prompts/`
   - **General coordination**: `docs/agent-communications/general/coordination/`
   - **General templates**: `docs/agent-communications/general/templates/`
   - **Sub-agent prompts**: `docs/agent-communications/l2-subagents/core_1/{agent_id}_{agent_name}/prompts/`
   - **Sub-agent acknowledgments**: `docs/agent-communications/l2-subagents/core_1/{agent_id}_{agent_name}/acknowledgments/`
   - **Cross-agent communications**: `docs/agent-communications/cross-agent/`

3. **Reference Documents**:
   - `docs/agent-communications/README.md` — Quick navigation guide
   - `docs/agent-communications/general/templates/2026-01-03-055549-pst_directory_structure_pattern.md` — Complete pattern documentation

### Step 5: Create New Coordination Plan

**Required Actions**:

1. **Generate Timestamp**:
   ```bash
   TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
   ```

2. **Create New Coordination Plan**:
   - **Filename**: `docs/core-coordination/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_plan.md`
   - Include comprehensive status for all agents/sub-agents
   - Include current priorities and next steps
   - Include critical path status
   - Include integration priorities
   - Include coordination needs

3. **Structure the Plan**:
   - Executive summary
   - Critical path status (Steps 1-4)
   - Agent status (all L1 agents and L2 sub-agents)
   - Integration priorities
   - Coordination needs
   - Next steps for each agent

### Step 6: Create Comprehensive Printout Summary

**Required Actions**:

1. **Generate Timestamp** (same as coordination plan):
   ```bash
   TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
   ```

2. **Create Printout Summary**:
   - **Filename**: `docs/agent-communications/general/coordination/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_summary.md`
   - **Agent Name**: "Core 1 Subcore Agent"
   - **Structure**: Comprehensive with maximal context
   - **Purpose**: Copy-paste ready for each agent

3. **Structure the Summary**:
   - Header with timestamp and agent name
   - Executive summary
   - Critical path status
   - Agent-specific sections (one per agent/sub-agent):
     - Current status
     - Completed work
     - Immediate next steps
     - Current blockers
     - Integration priorities
     - Coordination needs
   - Single-threaded computation priority chain
   - Cross-subcore coordination status
   - General instructions (Grain Style, timestamp format, Glow G2 voice, directory structure)

4. **Include Instructions for Each Agent**:
   - Continue as best recommended given context
   - Follow Grain Style (`docs/grain_style.md`)
   - Enforce `grainwrap-100` and `grain validate-70`
   - Use explicit `u32`/`u64`, not `usize`/`isize`
   - Update system-integration docs, plans, and tasks when done
   - Inform Core 1 Subcore and/or parent Subcore about updates
   - Check in before integration steps
   - Ensure all tests pass

### Step 7: Verify Standards Compliance

**Required Checks**:

1. **Timestamp Prefix Format**:
   - All new documents use: `YYYY-MM-DD-HHMMSS-pst_document_name.md`
   - Generate timestamp: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`

2. **Grain Style Compliance**:
   - All code follows `docs/grain_style.md`
   - `grainwrap-100`, `grain validate-70`
   - Explicit `u32`/`u64`, not `usize`/`isize`

3. **Glow G2 Voice**:
   - All communications use Glow G2 voice
   - Reference: `docs/agent-communications/general/prompts/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md`

4. **Directory Structure**:
   - All agent-communications references use new hierarchical paths
   - No references to old flat structure

### Step 8: Commit and Push

**Required Actions**:

1. **Generate Timestamp** (same as coordination plan and summary):
   ```bash
   TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
   ```

2. **Stage All Changes**:
   ```bash
   git add -A
   ```

3. **Commit with Grain Style Message**:
   ```bash
   git commit -m "update: Core 1 Subcore coordination plan and summary with sub-agent updates - {timestamp}"
   ```
   
   **Grain Style Commit Message Format**:
   - Direct, first-principles, positive
   - Action verb: `update`, `add`, `fix`, `complete`
   - Agent name and summary
   - Timestamp included
   - Verify previous next steps completed
   - Give hints about new next steps

4. **Push to Main**:
   ```bash
   git push origin main
   ```

---

## Common Path Updates

### Old Path → New Path Mapping

**General Prompts**:
- `docs/agent-communications/glow_g2_voice_multi_agent_prompt_*.md`
  → `docs/agent-communications/general/prompts/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md`

- `docs/agent-communications/timestamp_specification_multi_agent_prompt_*.md`
  → `docs/agent-communications/general/prompts/timestamp_specification_multi_agent_prompt_2026-01-01-215553-pst.md`

- `docs/agent-communications/complete_agent_awareness_all_agents_*.md`
  → `docs/agent-communications/general/prompts/2026-01-02-002948-pst_complete_agent_awareness_all_agents_2026-01-02-002948-pst.md`

**General Coordination**:
- `docs/agent-communications/core_1_subcore_coordination_summary_*.md`
  → `docs/agent-communications/general/coordination/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_summary.md`

**General Templates**:
- `docs/agent-communications/critical_path_quick_reference_*.md`
  → `docs/agent-communications/general/templates/2026-01-02-084259-pst_critical_path_quick_reference_2026-01-02-084259-pst.md`

- `docs/agent-communications/critical_path_blocker_tracking_*.md`
  → `docs/agent-communications/general/templates/2026-01-02-084613-pst_critical_path_blocker_tracking_2026-01-02-084613-pst.md`

**Sub-Agent Specific** (Example for Agent 1e):
- `docs/agent-communications/core_1e_*.md`
  → `docs/agent-communications/l2-subagents/core_1/1e_grainscript_shell/prompts/` (for prompts)
  → `docs/agent-communications/l2-subagents/core_1/1e_grainscript_shell/acknowledgments/` (for acknowledgments)
  → `docs/agent-communications/l2-subagents/core_1/1e_grainscript_shell/communications/` (for communications)

---

## Notes

- **Frequency**: Use this prompt after sub-agents complete their recursion prompts or before coordination check-ins
- **Scope**: Integrate all Core 1 Subcore L2 sub-agent updates, plus awareness of other L1 Subcores
- **Standards**: Always verify timestamp prefix format, Grain Style, Glow G2 voice, and directory structure compliance
- **Coordination**: Create comprehensive coordination plan and summary for distribution to all agents

---

**Date**: 2026-01-03-074700-pst  
**Status**: ✅ **TEMPLATE READY** — Copy-paste ready for Core 1 Subcore

