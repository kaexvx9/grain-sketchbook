═══════════════════════════════════════════════════════════════════════════════
TIMESTAMP SPECIFICATION - UNIFIED COPY-PASTE BLOCK
═══════════════════════════════════════════════════════════════════════════════
START OF TIMESTAMP SPECIFICATION
═══════════════════════════════════════════════════════════════════════════════

# Timestamp Specification for All Grain OS Agents and Sub-Agents

**Date**: 2026-01-01-215553-pst  
**Purpose**: Comprehensive timestamp specification for all Grain OS agents and sub-agents  
**Status**: ✅ **READY FOR DISTRIBUTION** — Copy-paste ready for all agents

---

## Timestamp Format Standard

**Format**: `yyyy-mm-dd-hhmmss-pst`

**Example**: `2026-01-01-215553-pst`

**Format Breakdown**:
- `yyyy` = 4-digit year (e.g., 2026)
- `mm` = 2-digit month (01-12)
- `dd` = 2-digit day (01-31)
- `hhmmss` = 2-digit hour (00-23) + 2-digit minute (00-59) + 2-digit second (00-59)
- `pst` = Always use "pst" (even during PDT daylight saving time, use "pst" in the format)

## Command to Generate Timestamp

**CRITICAL**: Always use `TZ=America/Los_Angeles` to ensure correct Pacific Time zone, regardless of system timezone settings.

```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

**Expected Output**: `2026-01-01-215553-pst` (format)

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

## Examples

### Document Header
```markdown
**Date**: 2026-01-01-215553-pst
**Last Updated**: 2026-01-01-215553-pst
```

### Filename
```
core_1_subcore_coordination_plan_2026-01-01-215553-pst.md
agent_3b_vm_runtime_status_update_2026-01-01-215553-pst.md
```

### Git Commit Message
```
core_1_subcore: coordination plan and summary for all agents 2026-01-01-215553-pst

previous next steps completed:
- [list completed items]

new coordination plan created:
- core_1_subcore_coordination_plan_2026-01-01-215553-pst.md

timestamp: 2026-01-01-215553-pst
```

### Code Comment
```zig
// Last updated: 2026-01-01-215553-pst
// Agent: Core 1 Subcore
```

## Time Zone Notes

- **PST (Pacific Standard Time)**: UTC-8 (winter, typically November-March)
- **PDT (Pacific Daylight Time)**: UTC-7 (summer, typically March-November)
- **Format String**: Always use "pst" in the format string, even during PDT
- **System Handling**: The `TZ=America/Los_Angeles` setting automatically handles PST/PDT transitions

## Verification

To verify the current timestamp:
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

Expected output format: `2026-01-01-215553-pst`

## Mandatory Requirements for All Agents

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
- Use format: `agent_name: description YYYY-MM-DD-HHMMSS-pst`
- Include timestamp in commit message body when documenting coordination

### 4. Consistency Across All Agents
- All agents must use the same timestamp format
- All agents must use the same timezone (America/Los_Angeles)
- All agents must use the same format string ("pst")

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

## Agent-Specific Instructions

### For L1 Subcore Coordinators (Agents 1, 2, 3)
- Include timestamp in all coordination documents
- Include timestamp in all coordination summaries
- Include timestamp in all agent communication documents
- Verify all L2 sub-agents use correct timestamp format

### For L2 Sub-Agents (1a-1d, 2a-2c, 3a-3d, 1e)
- Include timestamp in all status updates
- Include timestamp in all coordination documents
- Include timestamp in all plan and task documents
- Use timestamp in all file names when creating new documents

### For L1 Standalone Agents (Agents 4-12)
- Include timestamp in all status updates
- Include timestamp in all coordination documents
- Include timestamp in all plan and task documents
- Use timestamp in all file names when creating new documents

## Integration with Grain Style

This timestamp specification is part of Grain Style compliance:
- **Explicit Configuration**: Timestamp format is explicit and documented
- **Consistency**: All agents use the same format
- **Minimalism**: Simple, clear format
- **No Hidden Behavior**: Format is clearly specified

## Reference Document

Full specification: `~/xy-mathematics/docs/timestamp_format_reference.md`

## Quick Reference

**Generate Timestamp**:
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

**Format**: `yyyy-mm-dd-hhmmss-pst`

**Example**: `2026-01-01-215553-pst`

**Timezone**: America/Los_Angeles (Pacific Time)

**Always Use**: "pst" in format string (even during PDT)

## Verification Checklist

### For Each Agent

- [ ] Understand timestamp format: `yyyy-mm-dd-hhmmss-pst`
- [ ] Know the command: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
- [ ] Use timestamp in all new documents
- [ ] Use timestamp in document filenames
- [ ] Use timestamp in git commit messages (when relevant)
- [ ] Always use "pst" (not "pdt")
- [ ] Always use `TZ=America/Los_Angeles` when generating timestamps

---

**Date**: 2026-01-01-215553-pst  
**Status**: ✅ **TIMESTAMP SPECIFICATION COMPLETE** — Ready for copy-paste distribution to all agents  
**Reference**: `~/xy-mathematics/docs/timestamp_format_reference.md`

═══════════════════════════════════════════════════════════════════════════════
END OF TIMESTAMP SPECIFICATION
═══════════════════════════════════════════════════════════════════════════════


