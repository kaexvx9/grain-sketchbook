# Timestamp Specification: Aurora 2 Subcore Agents and Sub-Agents

**Date**: 2026-01-02-001956-pst  
**Purpose**: Timestamp specification awareness for Aurora 2 Subcore and all L2 sub-agents in Framework session  
**Status**: ✅ **READY FOR DISTRIBUTION** — Copy-paste ready for Aurora 2 Subcore and all L2 sub-agents

---

## Instructions for Aurora 2 Subcore and All L2 Sub-Agents

**This document provides comprehensive timestamp specification awareness for Aurora 2 Subcore and all L2 sub-agents (2a, 2b, 2c) recreated in the Framework session. Each agent should:**

1. **Read this document completely** to understand the timestamp specification
2. **Use the correct timestamp format** in all documents and communications
3. **Follow the timestamp command** exactly as specified
4. **Verify timestamps** before committing or pushing changes
5. **Maintain consistency** with all other Grain OS agents

---

## Timestamp Format Standard

**Format**: `yyyy-mm-dd-hhmmss-pst`

**Example**: `2026-01-02-001956-pst`

**Format Breakdown**:
- `yyyy` = 4-digit year (e.g., 2026)
- `mm` = 2-digit month (01-12)
- `dd` = 2-digit day (01-31)
- `hhmmss` = 2-digit hour (00-23) + 2-digit minute (00-59) + 2-digit second (00-59)
- `pst` = Always use "pst" (even during PDT daylight saving time, use "pst" in the format)

---

## Command to Generate Timestamp

**CRITICAL**: Always use `TZ=America/Los_Angeles` to ensure correct Pacific Time zone, regardless of system timezone settings.

```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

**Expected Output**: `2026-01-02-001956-pst` (format)

---

## When to Use This Timestamp Format

Use this timestamp format for:
- ✅ Creating new documents (coordination docs, plans, tasks, proposals, etc.)
- ✅ Code edits that include timestamps
- ✅ Git commit messages with timestamps
- ✅ Filenames that include timestamps
- ✅ Document headers with "Date" or "Last Updated" fields
- ✅ Agent communication documents
- ✅ Coordination summaries
- ✅ Status updates

---

## Examples for Aurora 2 Subcore Agents

### Document Header

```markdown
**Date**: 2026-01-02-001956-pst
**Last Updated**: 2026-01-02-001956-pst
**Agent**: Grain Aurora 2 Subcore Agent (2nd Agent, L1 Subcore)
```

### Filename

```
aurora_2_subcore_coordination_plan_2026-01-02-001956-pst.md
aurora_2a_dream_editor_status_update_2026-01-02-001956-pst.md
aurora_2b_dream_browser_coordination_2026-01-02-001956-pst.md
aurora_2c_component_library_tasks_2026-01-02-001956-pst.md
```

### Git Commit Message

```
aurora_2_subcore: coordination plan and summary for all agents 2026-01-02-001956-pst

previous next steps completed:
- [list completed items]

new coordination plan created:
- aurora_2_subcore_coordination_plan_2026-01-02-001956-pst.md

timestamp: 2026-01-02-001956-pst
```

### Code Comment

```zig
// Last updated: 2026-01-02-001956-pst
// Agent: Aurora 2 Subcore (L1 Subcore Coordinator)
```

---

## Time Zone Notes

- **PST (Pacific Standard Time)**: UTC-8 (winter, typically November-March)
- **PDT (Pacific Daylight Time)**: UTC-7 (summer, typically March-November)
- **Format String**: Always use "pst" in the format string, even during PDT
- **System Handling**: The `TZ=America/Los_Angeles` setting automatically handles PST/PDT transitions

---

## Verification

To verify the current timestamp:
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

Expected output format: `2026-01-02-001956-pst`

---

## Mandatory Requirements for Aurora 2 Subcore Agents

### 1. Always Use Correct Format
- Use exact format: `yyyy-mm-dd-hhmmss-pst`
- Always use "pst" (not "pdt" or other timezone codes)
- Always use `TZ=America/Los_Angeles` when generating timestamps

### 2. Use in All Documents
- All new documents must include timestamp in filename
- All document headers must include timestamp
- All coordination documents must include timestamp
- All status updates must include timestamp

### 3. Use in Git Commits
- Include timestamp in commit message when relevant
- Use format: `aurora_2{X}: description YYYY-MM-DD-HHMMSS-pst`
- Include timestamp in commit message body when documenting coordination

### 4. Consistency Across All Aurora Agents
- All Aurora 2 Subcore agents must use the same timestamp format
- All Aurora 2 Subcore agents must use the same timezone (America/Los_Angeles)
- All Aurora 2 Subcore agents must use the same format string ("pst")

---

## Common Mistakes to Avoid

### ❌ Don't Do This
1. Using system timezone instead of `TZ=America/Los_Angeles`
2. Using "pdt" in format string (even during daylight saving time)
3. Using different timestamp formats (e.g., ISO 8601, Unix timestamp)
4. Forgetting to include timestamp in document filename
5. Using wrong date format (e.g., MM/DD/YYYY, DD-MM-YYYY)

### ✅ Do This Instead
1. Always use `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
2. Always use "pst" in format string
3. Always use `yyyy-mm-dd-hhmmss-pst` format
4. Always include timestamp in document filename
5. Always use YYYY-MM-DD format

---

## Agent-Specific Instructions

### For Aurora 2 Subcore (L1 Subcore Coordinator)

**Agent**: Grain Aurora 2 Subcore Agent (2nd Agent, L1 Subcore)

**Timestamp Requirements**:
- Include timestamp in all coordination documents
- Include timestamp in all coordination summaries
- Include timestamp in all agent communication documents
- Verify all L2 sub-agents (2a, 2b, 2c) use correct timestamp format
- Use timestamp in all new document filenames

**Example Coordination Document**:
```markdown
# Core Coordination: Grain Aurora 2 Subcore Agent

**Last Updated**: 2026-01-02-001956-pst
**Agent**: Grain Aurora 2 Subcore Agent (2nd Agent, L1 Subcore)
**Status**: {Current Status}
```

---

### For Aurora 2a: Dream Editor Agent (L2 Sub-Agent)

**Agent**: Grain Dream Editor Agent (2a, L2 Sub-Agent)

**Timestamp Requirements**:
- Include timestamp in all status updates
- Include timestamp in all coordination documents
- Include timestamp in all plan and task documents
- Use timestamp in all file names when creating new documents
- Update "Last Updated" timestamp in coordination document after each work session

**Example Coordination Document**:
```markdown
# Core Coordination: Grain Dream Editor Agent (2a)

**Last Updated**: 2026-01-02-001956-pst
**Agent**: Grain Dream Editor Agent (2a) — L2 Sub-Agent
**Parent Agent**: Grain Aurora 2 Subcore Agent (2nd Agent, L1 Subcore)
**Status**: {Current Status}
```

---

### For Aurora 2b: Dream Browser Agent (L2 Sub-Agent)

**Agent**: Grain Dream Browser Agent (2b, L2 Sub-Agent)

**Timestamp Requirements**:
- Include timestamp in all status updates
- Include timestamp in all coordination documents
- Include timestamp in all plan and task documents
- Use timestamp in all file names when creating new documents
- Update "Last Updated" timestamp in coordination document after each work session

**Example Coordination Document**:
```markdown
# Core Coordination: Grain Dream Browser Agent (2b)

**Last Updated**: 2026-01-02-001956-pst
**Agent**: Grain Dream Browser Agent (2b) — L2 Sub-Agent
**Parent Agent**: Grain Aurora 2 Subcore Agent (2nd Agent, L1 Subcore)
**Status**: {Current Status}
```

---

### For Aurora 2c: Component Library Agent (L2 Sub-Agent)

**Agent**: Grain Component Library Agent (2c, L2 Sub-Agent)

**Timestamp Requirements**:
- Include timestamp in all status updates
- Include timestamp in all coordination documents
- Include timestamp in all plan and task documents
- Use timestamp in all file names when creating new documents
- Update "Last Updated" timestamp in coordination document after each work session

**Example Coordination Document**:
```markdown
# Core Coordination: Grain Component Library Agent (2c)

**Last Updated**: 2026-01-02-001956-pst
**Agent**: Grain Component Library Agent (2c) — L2 Sub-Agent
**Parent Agent**: Grain Aurora 2 Subcore Agent (2nd Agent, L1 Subcore)
**Status**: {Current Status}
```

---

## Framework Session Context

**Session**: Framework 16 (x86_64 AMD, 64GB RAM) running Ubuntu 24.04 LTS  
**Date**: 2026-01-02-001956-pst  
**Purpose**: Aurora 2 Subcore agents and sub-agents recreated in Framework session

**Important Notes**:
- All Aurora 2 Subcore agents must use the same timestamp format as all other Grain OS agents
- Timestamp format is consistent across all agents (Core 1 Subcore, Vantage 3 Subcore, Aurora 2 Subcore)
- Framework session agents must maintain timestamp consistency with macOS session agents
- All new documents created in Framework session must use timestamp format

---

## Integration with Grain Style

This timestamp specification is part of Grain Style compliance:
- **Explicit Configuration**: Timestamp format is explicit and documented
- **Consistency**: All agents use the same format
- **Minimalism**: Simple, clear format
- **No Hidden Behavior**: Format is clearly specified

---

## Reference Documents

**Primary Reference**:
- `docs/agent-communications/timestamp_specification_multi_agent_prompt_2026-01-01-215553-pst.md` - Full timestamp specification

**Supporting Documents**:
- `docs/agent-communications/aurora_2_subcore_documentation_setup_prompt_2026-01-02-000032-pst.md` - Documentation setup
- `docs/core-coordination/aurora_2_subcore_coordination.md` - Aurora 2 Subcore coordination

---

## Quick Reference

**Generate Timestamp**:
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

**Format**: `yyyy-mm-dd-hhmmss-pst`

**Example**: `2026-01-02-001956-pst`

**Timezone**: America/Los_Angeles (Pacific Time)

**Always Use**: "pst" in format string (even during PDT)

---

## Verification Checklist

### For Aurora 2 Subcore (L1)

- [ ] Understand timestamp format: `yyyy-mm-dd-hhmmss-pst`
- [ ] Know the command: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
- [ ] Use timestamp in all new documents
- [ ] Use timestamp in document filenames
- [ ] Use timestamp in git commit messages (when relevant)
- [ ] Always use "pst" (not "pdt")
- [ ] Always use `TZ=America/Los_Angeles` when generating timestamps
- [ ] Verify all L2 sub-agents (2a, 2b, 2c) use correct timestamp format

### For Aurora 2a, 2b, 2c (L2 Sub-Agents)

- [ ] Understand timestamp format: `yyyy-mm-dd-hhmmss-pst`
- [ ] Know the command: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
- [ ] Use timestamp in all new documents
- [ ] Use timestamp in document filenames
- [ ] Use timestamp in git commit messages (when relevant)
- [ ] Always use "pst" (not "pdt")
- [ ] Always use `TZ=America/Los_Angeles` when generating timestamps
- [ ] Update "Last Updated" timestamp in coordination document after each work session

---

## Summary

**Timestamp Format**: `yyyy-mm-dd-hhmmss-pst`

**Command**: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`

**Usage**: All documents, filenames, git commits, status updates

**Consistency**: All Aurora 2 Subcore agents must use the same format as all other Grain OS agents

**Framework Session**: Aurora 2 Subcore agents recreated in Framework session must maintain timestamp consistency

---

**Date**: 2026-01-02-001956-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Status**: ✅ **TIMESTAMP SPECIFICATION COMPLETE** — Ready for copy-paste distribution to Aurora 2 Subcore and all L2 sub-agents  
**Reference**: `docs/agent-communications/timestamp_specification_multi_agent_prompt_2026-01-01-215553-pst.md`

