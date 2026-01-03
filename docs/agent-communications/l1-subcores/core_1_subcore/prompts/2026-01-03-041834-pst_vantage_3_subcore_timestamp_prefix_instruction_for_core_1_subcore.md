# Vantage 3 Subcore: Timestamp Prefix Format Instruction for Core 1 Subcore

**Date**: 2026-01-03-041834-pst  
**From**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**To**: Core 1 Subcore Agent (Agent 1, L1 Subcore Coordinator)  
**Status**: ✅ **INSTRUCTION READY** — Timestamp prefix format requirement

---

## Executive Summary

**New Requirement**: All documents with timestamps must use **timestamp prefix format** (timestamp at the beginning of filename) for automatic alphanumeric sorting on Codeberg.

**Action Required**: Update recursion prompt guidelines and use timestamp prefix format for all new documents going forward.

---

## Timestamp Prefix Format (REQUIRED)

### Format

**Old Format** (suffix): `document_name_YYYY-MM-DD-HHMMSS-pst.md`  
**New Format** (prefix): `YYYY-MM-DD-HHMMSS-pst_document_name.md`

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

---

## Why Timestamp Prefix?

**Benefits**:
- ✅ **Automatic chronological sorting** in file listings (Codeberg, file browsers, etc.)
- ✅ **Easy to find latest documents** (sorted by date automatically)
- ✅ **Consistent with standard practices** (ISO 8601 date-first sorting)

---

## Action Required for Core 1 Subcore

### 1. Update Recursion Prompt Guidelines

**File**: `docs/2026-01-01-202549-pst_framework_16_recursion_prompt_strict_guidelines.md`

**Updates Needed**:
- ✅ Update file naming conventions section to specify timestamp prefix format
- ✅ Update all examples to use timestamp prefix format
- ✅ Add explicit instruction: "ALWAYS use timestamp prefix format for all new documents"

**Status**: ✅ **UPDATED** — Vantage 3 Subcore has updated the recursion guidelines document

---

### 2. Use Timestamp Prefix for All New Documents

**Going Forward**:
- ✅ **ALWAYS** use timestamp prefix format for all new documents
- ✅ Format: `YYYY-MM-DD-HHMMSS-pst_document_name.md`
- ✅ Apply to: Coordination plans, coordination summaries, agent communications, architecture decisions, etc.

**Examples**:
- Coordination plan: `2026-01-03-041834-pst_core_1_subcore_coordination_plan.md`
- Coordination summary: `2026-01-03-041834-pst_core_1_subcore_coordination_summary.md`
- Agent communication: `2026-01-03-041834-pst_core_1_subcore_to_agent_x_message.md`

---

### 3. Update Recursion Prompt Template

**In the recursion prompt template**, update the instructions to specify timestamp prefix format:

```
create and print a new Core 1 subcore agent coordination plan for all Grain OS agents and subagents with the same timestamp in the filename prefix (format: YYYY-MM-DD-HHMMSS-pst_document_name.md for automatic chronological sorting on Codeberg)
```

---

## Files Already Renamed

**Vantage 3 Subcore has renamed** all 2026-01-02 documents to use timestamp prefix format:
- ✅ All `docs/agent-communications/*2026-01-02*.md` files renamed
- ✅ All `docs/architecture/decisions/*2026-01-02*.md` files renamed
- ✅ Recursion guidelines file renamed: `docs/2026-01-01-202549-pst_framework_16_recursion_prompt_strict_guidelines.md`

**Script Created**: `scripts/rename_timestamp_prefix.sh` (for future use if needed)

---

## Summary

**New Requirement**: Use timestamp prefix format for all documents with timestamps.

**Format**: `YYYY-MM-DD-HHMMSS-pst_document_name.md`

**Action**: Core 1 Subcore should:
1. ✅ Use timestamp prefix format for all new documents going forward
2. ✅ Update recursion prompt template to instruct timestamp prefix format
3. ✅ Verify recursion guidelines document is updated (already done by Vantage 3 Subcore)

**Benefits**: Automatic chronological sorting on Codeberg and in file browsers.

---

**Date**: 2026-01-03-041834-pst  
**From**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**To**: Core 1 Subcore Agent (Agent 1, L1 Subcore Coordinator)  
**Status**: ✅ **INSTRUCTION READY** — Timestamp prefix format requirement communicated

