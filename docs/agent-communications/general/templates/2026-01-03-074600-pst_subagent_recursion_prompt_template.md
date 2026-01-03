# Sub-Agent Recursion Prompt Template

**Date**: 2026-01-03-074600-pst  
**Purpose**: Template for L2 sub-agents to update their documentation with new changes and migrate to new directory structure  
**Status**: ✅ **TEMPLATE READY** — Copy-paste ready for all sub-agents

---

## Usage Instructions

**Copy this entire prompt and paste it to yourself (the sub-agent) to execute a documentation update cycle.**

**When to Use**:
- After completing work sessions
- Before coordination check-ins
- When integrating new changes from other agents
- When updating references to new directory structure

---

## Recursion Prompt Template

```
check all my agent statuses and system-integration docs and plans and tasks, and check our git diff and git status, and update all my coordination documents and plans and tasks with any new changes, commits, and diffs from this session.

update any references to old agent-communications paths to use the new hierarchical directory structure:
- old: docs/agent-communications/glow_g2_voice_multi_agent_prompt_*.md
- new: docs/agent-communications/general/prompts/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md

- old: docs/agent-communications/core_1_subcore_coordination_summary_*.md
- new: docs/agent-communications/general/coordination/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_summary.md

- old: docs/agent-communications/critical_path_*.md
- new: docs/agent-communications/general/templates/2026-01-02-084259-pst_critical_path_quick_reference_2026-01-02-084259-pst.md

see docs/agent-communications/README.md and docs/agent-communications/general/templates/2026-01-03-055549-pst_directory_structure_pattern.md for complete directory structure guidance.

when done with all updates, commit with Grain Style commit message using terminal date now yyyy-mm-dd-hhmmss-pst timestamp, and push to main.

verify that all my documentation follows:
- timestamp prefix format for new documents: YYYY-MM-DD-HHMMSS-pst_document_name.md
- Grain Style compliance in all code and documentation
- Glow G2 voice in all communications
- new directory structure paths for agent-communications references
```

---

## Detailed Instructions

### Step 1: Check Agent Status

**Required Actions**:
1. **Read your coordination document**:
   - `docs/core-coordination/{parent}_{agent}_coordination.md`
   - Review current status, completed work, blockers

2. **Read your system-integration document** (if exists):
   - `docs/core-coordination/{parent}_{agent}_system_integration.md`
   - Review integration points, dependencies

3. **Read your plan document**:
   - `docs/plans/{parent}_{agent}_plan.md`
   - Review planned work, priorities

4. **Read your tasks document**:
   - `docs/tasks/{parent}_{agent}_tasks.md`
   - Review task status, completed items

### Step 2: Check Git Status and Diff

**Required Actions**:
1. **Check git status**: `git status`
   - Identify new files, modified files, untracked files

2. **Check git diff**: `git diff`
   - Review code changes, documentation changes
   - Note any new features, bug fixes, refactoring

3. **Review recent commits**: `git log --oneline -10`
   - Understand what work was completed
   - Note any integration points or dependencies

### Step 3: Update Documentation

**Required Actions**:

1. **Update Coordination Document**:
   - Add completed work from this session
   - Update current status
   - Update blockers (if any resolved or new ones)
   - Update integration points
   - Use timestamp prefix format for any new sections

2. **Update Plan Document**:
   - Reflect actual implementation vs. planned work
   - Update priorities based on current state
   - Add new planned work if needed

3. **Update Tasks Document**:
   - Mark completed tasks with timestamps
   - Add new tasks if needed
   - Update task priorities

4. **Update System-Integration Document** (if exists):
   - Update integration points
   - Note any new dependencies
   - Update coordination status with other agents

### Step 4: Update Directory Structure References

**Required Actions**:

1. **Find Old Paths**:
   - Search for references to `docs/agent-communications/` with old flat structure
   - Common patterns:
     - `docs/agent-communications/glow_g2_voice_*.md`
     - `docs/agent-communications/timestamp_specification_*.md`
     - `docs/agent-communications/core_1_subcore_coordination_summary_*.md`
     - `docs/agent-communications/critical_path_*.md`
     - `docs/agent-communications/{agent}_*.md`

2. **Update to New Paths**:
   - **General prompts**: `docs/agent-communications/general/prompts/`
   - **General coordination**: `docs/agent-communications/general/coordination/`
   - **General templates**: `docs/agent-communications/general/templates/`
   - **Agent-specific prompts**: `docs/agent-communications/l2-subagents/{parent}/{agent_id}_{agent_name}/prompts/`
   - **Agent-specific acknowledgments**: `docs/agent-communications/l2-subagents/{parent}/{agent_id}_{agent_name}/acknowledgments/`
   - **Cross-agent communications**: `docs/agent-communications/cross-agent/`

3. **Reference Documents**:
   - `docs/agent-communications/README.md` — Quick navigation guide
   - `docs/agent-communications/general/templates/2026-01-03-055549-pst_directory_structure_pattern.md` — Complete pattern documentation

### Step 5: Verify Standards Compliance

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

### Step 6: Commit and Push

**Required Actions**:

1. **Generate Timestamp**:
   ```bash
   TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
   ```

2. **Stage All Changes**:
   ```bash
   git add -A
   ```

3. **Commit with Grain Style Message**:
   ```bash
   git commit -m "update: {agent_name} coordination docs with {summary} - {timestamp}"
   ```
   
   **Grain Style Commit Message Format**:
   - Direct, first-principles, positive
   - Action verb: `update`, `add`, `fix`, `complete`
   - Agent name and summary
   - Timestamp included

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

**Agent-Specific** (Example for Agent 1e):
- `docs/agent-communications/core_1e_*.md`
  → `docs/agent-communications/l2-subagents/core_1/1e_grainscript_shell/prompts/` (for prompts)
  → `docs/agent-communications/l2-subagents/core_1/1e_grainscript_shell/acknowledgments/` (for acknowledgments)
  → `docs/agent-communications/l2-subagents/core_1/1e_grainscript_shell/communications/` (for communications)

---

## Example Execution

**Agent**: 1e (Grainscript Shell)

**Prompt to Copy-Paste**:
```
check all my agent statuses and system-integration docs and plans and tasks, and check our git diff and git status, and update all my coordination documents and plans and tasks with any new changes, commits, and diffs from this session.

update any references to old agent-communications paths to use the new hierarchical directory structure. see docs/agent-communications/README.md and docs/agent-communications/general/templates/2026-01-03-055549-pst_directory_structure_pattern.md for complete directory structure guidance.

when done with all updates, commit with Grain Style commit message using terminal date now yyyy-mm-dd-hhmmss-pst timestamp, and push to main.

verify that all my documentation follows timestamp prefix format for new documents, Grain Style compliance, Glow G2 voice, and new directory structure paths for agent-communications references.
```

---

## Notes

- **Frequency**: Use this prompt after each work session or before coordination check-ins
- **Scope**: Update your own agent documentation only
- **Standards**: Always verify timestamp prefix format, Grain Style, Glow G2 voice, and directory structure compliance
- **Coordination**: Inform your parent L1 Subcore of any significant updates

---

**Date**: 2026-01-03-074600-pst  
**Status**: ✅ **TEMPLATE READY** — Copy-paste ready for all sub-agents

