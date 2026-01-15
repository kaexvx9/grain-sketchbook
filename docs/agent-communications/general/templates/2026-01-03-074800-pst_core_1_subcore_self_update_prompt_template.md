# Core 1 Subcore Self-Update Prompt Template

**Date**: 2026-01-03-074800-pst  
**Purpose**: Template for Core 1 Subcore to update its own documentation following the sub-agent recursion pattern  
**Status**: ✅ **TEMPLATE READY** — Copy-paste ready for Core 1 Subcore self-updates

---

## Usage Instructions

**Copy this entire prompt and paste it to Core 1 Subcore Agent to execute a self-documentation update cycle for independent parallel work.**

**When to Use**:
- After completing independent parallel work sessions
- When updating Core 1 Subcore's own coordination, plans, tasks, system-integration docs
- Before coordination check-ins
- When integrating new changes from git diff/commits

---

## Self-Update Recursion Prompt Template

```
check all my Core 1 Subcore agent statuses and system-integration docs and plans and tasks, and check our git diff and git status, and update all my Core 1 Subcore coordination documents and plans and tasks with any new changes, commits, and diffs from this session.

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

### Step 1: Check Core 1 Subcore Status

**Required Actions**:
1. **Read Core 1 Subcore coordination document**:
   - `docs/core-coordination/core_1_subcore_coordination.md`
   - Review current status, completed work, blockers
   - Review independent parallel work status

2. **Read Core 1 Subcore system-integration document**:
   - `docs/core-coordination/core_1_subcore_system_integration.md`
   - Review integration points, dependencies
   - Review parallel work integration status

3. **Read Core 1 Subcore plan document**:
   - `docs/plans/core_1_subcore_plan.md`
   - Review planned work, priorities
   - Review independent parallel work plans

4. **Read Core 1 Subcore tasks document**:
   - `docs/tasks/core_1_subcore_tasks.md`
   - Review task status, completed items
   - Review independent parallel work tasks

### Step 2: Check Git Status and Diff

**Required Actions**:
1. **Check git status**: `git status`
   - Identify new files, modified files
   - Note any Core 1 Subcore independent work changes
   - Note any documentation changes

2. **Check git diff**: `git diff`
   - Review code changes from independent parallel work
   - Review documentation changes
   - Note any new features, bug fixes, refactoring

3. **Review recent commits**: `git log --oneline -10`
   - Understand what independent work was completed
   - Note any integration points or dependencies
   - Verify documentation was updated

### Step 3: Update Core 1 Subcore Documentation

**Required Actions**:

1. **Update Coordination Document** (`docs/core-coordination/core_1_subcore_coordination.md`):
   - Add completed independent parallel work from this session
   - Update current status
   - Update blockers (if any resolved or new ones)
   - Update integration points
   - Update parallel work status
   - Use timestamp prefix format for any new sections

2. **Update Plan Document** (`docs/plans/core_1_subcore_plan.md`):
   - Reflect actual implementation vs. planned work
   - Update priorities based on current state
   - Add new planned work if needed
   - Update independent parallel work plans

3. **Update Tasks Document** (`docs/tasks/core_1_subcore_tasks.md`):
   - Mark completed tasks with timestamps
   - Add new tasks if needed
   - Update task priorities
   - Update independent parallel work tasks

4. **Update System-Integration Document** (`docs/core-coordination/core_1_subcore_system_integration.md`):
   - Update integration points
   - Note any new dependencies
   - Update coordination status with other agents
   - Update parallel work integration status

### Step 4: Update Directory Structure References

**Required Actions**:

1. **Find Old Paths in Core 1 Subcore Documents**:
   - Search for references to `docs/agent-communications/` with old flat structure
   - Common patterns:
     - `docs/agent-communications/glow_g2_voice_*.md`
     - `docs/agent-communications/timestamp_specification_*.md`
     - `docs/agent-communications/core_1_subcore_coordination_summary_*.md`
     - `docs/agent-communications/critical_path_*.md`
     - `docs/agent-communications/core_1_subcore_*.md`

2. **Update to New Paths**:
   - **General prompts**: `docs/agent-communications/general/prompts/`
   - **General coordination**: `docs/agent-communications/general/coordination/`
   - **General templates**: `docs/agent-communications/general/templates/`
   - **Core 1 Subcore prompts**: `docs/agent-communications/l1-subcores/core_1_subcore/prompts/`
   - **Core 1 Subcore acknowledgments**: `docs/agent-communications/l1-subcores/core_1_subcore/acknowledgments/`
   - **Core 1 Subcore coordination**: `docs/agent-communications/l1-subcores/core_1_subcore/coordination/`

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
   git commit -m "update: Core 1 Subcore coordination docs with independent parallel work - {timestamp}"
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

**Core 1 Subcore Specific**:
- `docs/agent-communications/core_1_subcore_*.md`
  → `docs/agent-communications/l1-subcores/core_1_subcore/prompts/` (for prompts)
  → `docs/agent-communications/l1-subcores/core_1_subcore/acknowledgments/` (for acknowledgments)
  → `docs/agent-communications/l1-subcores/core_1_subcore/coordination/` (for coordination)

---

## Independent Parallel Work Focus

### What This Prompt Updates

**Core 1 Subcore Independent Work**:
- Documentation migration tasks
- Reference updates (coordination, plans, tasks)
- General migration announcements
- Navigation testing
- Cross-subcore coordination
- Any other independent parallel work

**Not Included**:
- Sub-agent status integration (use full recursion prompt for that)
- New coordination plan creation (use full recursion prompt for that)
- Comprehensive printout summary (use full recursion prompt for that)

**This Prompt Is For**:
- Updating Core 1 Subcore's own documentation
- Reflecting independent parallel work completed
- Maintaining Core 1 Subcore's own status
- Keeping Core 1 Subcore docs current

---

## Example Execution

**Scenario**: Core 1 Subcore completed documentation migration work

**Prompt to Copy-Paste**:
```
check all my Core 1 Subcore agent statuses and system-integration docs and plans and tasks, and check our git diff and git status, and update all my Core 1 Subcore coordination documents and plans and tasks with any new changes, commits, and diffs from this session.

update any references to old agent-communications paths to use the new hierarchical directory structure. see docs/agent-communications/README.md and docs/agent-communications/general/templates/2026-01-03-055549-pst_directory_structure_pattern.md for complete directory structure guidance.

when done with all updates, commit with Grain Style commit message using terminal date now yyyy-mm-dd-hhmmss-pst timestamp, and push to main.

verify that all my documentation follows timestamp prefix format for new documents, Grain Style compliance, Glow G2 voice, and new directory structure paths for agent-communications references.
```

---

## Notes

- **Frequency**: Use this prompt after completing independent parallel work sessions
- **Scope**: Update Core 1 Subcore's own documentation only (not sub-agent integration)
- **Standards**: Always verify timestamp prefix format, Grain Style, Glow G2 voice, and directory structure compliance
- **Relationship to Full Recursion**: Use this for self-updates; use full recursion prompt (`2026-01-03-074700-pst_core_1_subcore_recursion_prompt_template.md`) for integrating sub-agent updates and creating coordination plans

---

**Date**: 2026-01-03-074800-pst  
**Status**: ✅ **TEMPLATE READY** — Copy-paste ready for Core 1 Subcore self-updates

