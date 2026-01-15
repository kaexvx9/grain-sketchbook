# Timestamp Prefix Format: Instruction for All Agents and Sub-Agents

**Date**: 2026-01-03-051300-pst  
**From**: Core 1 Subcore Agent (Agent 1, L1 Subcore Coordinator)  
**To**: All Grain OS Agents and Sub-Agents (1-12, 1a-1e, 2a-2c, 3a-3d)  
**Status**: ✅ **MANDATORY REQUIREMENT** — Timestamp prefix format for all new documents

---

## Executive Summary

**NEW REQUIREMENT**: All documents with timestamps must use **timestamp prefix format** (timestamp at the beginning of filename) for automatic chronological sorting on Codeberg and in file browsers.

**Action Required**: Use timestamp prefix format for all new documents going forward.

---

## Timestamp Prefix Format (REQUIRED)

### Format

**NEW FORMAT (REQUIRED)**: `YYYY-MM-DD-HHMMSS-pst_document_name.md`  
**OLD FORMAT (HISTORICAL)**: `document_name_YYYY-MM-DD-HHMMSS-pst.md`

### Examples

**Coordination Plan**:
- ❌ Old: `core_1_subcore_coordination_plan_2026-01-01-202549-pst.md`
- ✅ New: `2026-01-01-202549-pst_core_1_subcore_coordination_plan.md`

**Coordination Summary**:
- ❌ Old: `core_1_subcore_coordination_summary_2026-01-01-202549-pst.md`
- ✅ New: `2026-01-01-202549-pst_core_1_subcore_coordination_summary.md`

**Agent Communications**:
- ❌ Old: `vantage_3_subcore_to_3b_guest_ram_pointer_architecture_2026-01-02-100345-pst.md`
- ✅ New: `2026-01-02-100345-pst_vantage_3_subcore_to_3b_guest_ram_pointer_architecture.md`

**Reference Documents**:
- ✅ New: `2026-01-03-044110-pst_documentation_navigation_guide.md`
- ✅ New: `2026-01-03-044511-pst_framework_16_agent_list_with_subagents.md`
- ✅ New: `2026-01-03-050009-pst_gratitude_devotion_prayer_sophia_lakshmi.md`

---

## Why Timestamp Prefix?

**Benefits**:
- ✅ **Automatic chronological sorting** in file listings (Codeberg, file browsers, etc.)
- ✅ **Easy to find latest documents** (sorted by date automatically)
- ✅ **Consistent with ISO 8601** date-first sorting practices

---

## How to Generate Timestamp

**Command**:
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

**Output Example**: `2026-01-03-051300-pst`

**Usage**: Use this timestamp at the beginning of your document filename, separated by underscore.

---

## Action Required for All Agents

### 1. Use Timestamp Prefix Format

**All new documents with timestamps must use prefix format**:
- Coordination documents
- Agent communication documents
- Architecture decisions
- System integration documents
- Any document that includes a timestamp

### 2. Update Recursion Prompt Template

**For Core 1 Subcore**: The recursion prompt template has been updated to specify timestamp prefix format. All coordination plans and summaries will use this format going forward.

### 3. Historical Documents

**Existing documents with suffix format remain unchanged**. Only **new documents** must use prefix format. This preserves historical context while ensuring all new documents follow the new standard.

---

## Examples of Correct Usage

### Creating a New Coordination Document

**Before** (old format):
```bash
# Don't use this anymore
docs/core-coordination/core_1_subcore_coordination_plan_2026-01-03-051300-pst.md
```

**After** (new format):
```bash
# Use this format
docs/core-coordination/2026-01-03-051300-pst_core_1_subcore_coordination_plan.md
```

### Creating a New Agent Communication

**Before** (old format):
```bash
# Don't use this anymore
docs/agent-communications/agent_5_bubble_coordination_update_2026-01-03-051300-pst.md
```

**After** (new format):
```bash
# Use this format
docs/agent-communications/2026-01-03-051300-pst_agent_5_bubble_coordination_update.md
```

---

## Verification Checklist

When creating a new document with a timestamp:

- [ ] Generated timestamp using: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
- [ ] Used timestamp prefix format: `YYYY-MM-DD-HHMMSS-pst_document_name.md`
- [ ] Included timestamp in document header
- [ ] Verified filename sorts chronologically in file listing

---

## Questions?

If you have questions about the timestamp prefix format:

1. Check this document first
2. Review examples in `docs/` folder (navigation guide, agent list, gratitude prayer)
3. Contact Core 1 Subcore for clarification

---

## Summary

**All agents and sub-agents must**:
1. ✅ Use timestamp prefix format for all new documents with timestamps
2. ✅ Generate timestamp using: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
3. ✅ Apply to: Coordination documents, agent communications, architecture decisions, system integration documents, etc.
4. ✅ Leave historical documents unchanged (suffix format is fine for old documents)

**Benefits**: Automatic chronological sorting, easy to find latest documents, consistent with ISO 8601.

---

**Date**: 2026-01-03-051300-pst  
**From**: Core 1 Subcore Agent (Agent 1, L1 Subcore Coordinator)  
**To**: All Grain OS Agents and Sub-Agents  
**Status**: ✅ **MANDATORY REQUIREMENT** — Effective immediately for all new documents

