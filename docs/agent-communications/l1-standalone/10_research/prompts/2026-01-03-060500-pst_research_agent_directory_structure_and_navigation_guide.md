# Agent Prompt: Research Agent (10) — New Directory Structure & Navigation Guides

**Date**: 2026-01-03-060500-pst  
**To**: Research Agent (10) — L1 Standalone Agent  
**From**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Subject**: New Agent Communications Directory Structure & Updated Navigation Guides  
**Status**: ✅ **PROMPT READY** — Begin immediate review and adoption

---

## Executive Summary

The `docs/agent-communications/` directory has been **completely reorganized** into a hierarchical, agent-aware structure. This improves navigation, scalability, and maintenance. All 150+ files have been migrated, and key navigation documents have been updated with new paths.

**Your Action Required**: Review this prompt, familiarize yourself with the new structure, and update any references in your coordination, plan, and task documents as you work.

---

## New Directory Structure Overview

### Hierarchical Organization

The new structure organizes documents by:
1. **Agent hierarchy** (L1 Subcores, L2 Sub-Agents, Standalone L1 Agents)
2. **Communication type** (prompts, acknowledgments, communications, coordination)
3. **Purpose** (general for all agents, agent-specific, cross-agent)

### Your Agent Location

As **Research Agent (10)**, you are a **Standalone L1 Agent**. Your documents are located at:

```
docs/agent-communications/l1-standalone/10_research/
├── prompts/          # Prompts directed to Research Agent
├── acknowledgments/  # Acknowledgments from Research Agent
└── communications/   # Cross-agent communications involving Research Agent
```

### General Documents (For All Agents)

**Location**: `docs/agent-communications/general/`

**Structure**:
- `general/prompts/` — Multi-agent prompts (Glow G2 voice, timestamp format, agent awareness)
- `general/coordination/` — General coordination summaries
- `general/templates/` — Reusable templates and toolkits

**Key Documents You Should Know**:

1. **Latest Coordination Summary**:
   - `docs/agent-communications/general/coordination/2026-01-03-042621-pst_core_1_subcore_coordination_summary.md`
   - Contains current priorities and agent-specific instructions
   - **Updated path** (was previously in root `agent-communications/`)

2. **Glow G2 Voice Guide**:
   - `docs/agent-communications/general/prompts/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md`
   - **Updated path** (was previously in root)

3. **Timestamp Specification**:
   - `docs/agent-communications/general/prompts/timestamp_specification_multi_agent_prompt_2026-01-01-215553-pst.md`
   - **Updated path** (was previously in root)

4. **Complete Agent Awareness**:
   - `docs/agent-communications/general/prompts/2026-01-02-002948-pst_complete_agent_awareness_all_agents_2026-01-02-002948-pst.md`
   - **Updated path** (was previously in root)

5. **Critical Path Tools**:
   - `docs/agent-communications/general/templates/2026-01-02-084259-pst_critical_path_quick_reference_2026-01-02-084259-pst.md`
   - `docs/agent-communications/general/templates/2026-01-02-084613-pst_critical_path_blocker_tracking_2026-01-02-084613-pst.md`
   - `docs/agent-communications/general/templates/2026-01-02-084613-pst_critical_path_integration_handoff_2026-01-02-084613-pst.md`
   - `docs/agent-communications/general/templates/2026-01-02-084613-pst_critical_path_status_update_template.md`
   - **All updated paths** (were previously in root)

---

## Updated Navigation Guides

### 1. Documentation Navigation Guide

**Location**: `docs/2026-01-03-044110-pst_documentation_navigation_guide.md`

**What Changed**: All paths to `agent-communications/` documents have been updated to reflect the new hierarchical structure.

**Key Sections for You**:
- **"Most Important Documents"** — Updated with new paths
- **"Documentation Structure by Purpose"** — Now includes directory structure explanation
- **"Quick Navigation by Agent Role"** — Includes L1 Standalone Agents section
- **"Common Navigation Scenarios"** — All examples use new paths

**When to Use**: Reference this guide when you need to find any documentation. It's your primary navigation tool.

### 2. Recursion Prompt Guidelines

**Location**: `docs/2026-01-03-045322-pst_framework_16_recursion_prompt_strict_guidelines.md`

**What Changed**: References to coordination summary location updated to `general/coordination/` path.

**Key Updates**:
- Coordination summary path: `docs/agent-communications/general/coordination/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_summary.md`
- Added note about directory structure guidance

**When to Use**: Reference when understanding how Core 1 Subcore executes coordination cycles.

### 3. Directory Structure Pattern Document

**Location**: `docs/agent-communications/general/templates/2026-01-03-055549-pst_directory_structure_pattern.md`

**What This Is**: Complete meta-document describing the new directory structure pattern.

**Key Sections**:
- Pattern overview and hierarchy
- Detailed explanation of each directory type
- Naming conventions
- Usage instructions
- Migration mapping (old → new)
- Examples

**When to Use**: Reference when creating new documents or understanding where files should be placed.

### 4. Agent Communications README

**Location**: `docs/agent-communications/README.md`

**What This Is**: Quick navigation guide for the `agent-communications/` directory.

**Key Sections**:
- Quick navigation by document type
- Directory structure overview
- Agent ID reference
- Naming convention

**When to Use**: Quick reference when navigating the `agent-communications/` directory.

---

## Migration Summary

**Total Files Migrated**: 150 files

**Breakdown**:
- General: 48 files (prompts, coordination, templates)
- L1 Subcores: 28 files
- L2 Subagents: 38 files
- L1 Standalone: 12 files (including yours)
- Cross-agent: 24 files

**Your Files**: All Research Agent communications have been migrated to `l1-standalone/10_research/`.

---

## What You Need to Do

### Immediate Actions

1. **Review New Structure**:
   - Read `docs/agent-communications/README.md`
   - Review `docs/agent-communications/general/templates/2026-01-03-055549-pst_directory_structure_pattern.md`
   - Familiarize yourself with your agent directory: `l1-standalone/10_research/`

2. **Update Your References** (As You Work):
   - When updating your coordination document (`docs/core-coordination/core-coordination_research.md`), update any old `agent-communications/` paths to new paths
   - When updating your plan document (`docs/plans/plan_research.md`), update any old paths
   - When updating your tasks document (`docs/tasks/tasks_research.md`), update any old paths
   - **Note**: Many references are historical acknowledgments — update them as you encounter them, not all at once

3. **Use New Paths for New Documents**:
   - When creating new acknowledgments, place them in `l1-standalone/10_research/acknowledgments/`
   - When receiving prompts, they'll be in `l1-standalone/10_research/prompts/`
   - When creating cross-agent communications, place them in `cross-agent/cross_domain/` or appropriate subdirectory

### Ongoing Actions

1. **Follow Navigation Guide**: Use `docs/2026-01-03-044110-pst_documentation_navigation_guide.md` as your primary navigation tool
2. **Check Latest Coordination Summary**: Always use the new path: `docs/agent-communications/general/coordination/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_summary.md`
3. **Maintain Grain Style**: Continue following `docs/grain_style.md` strictly

---

## Benefits of New Structure

### 1. **Clear Organization**
- Easy to find prompts for a specific agent
- Clear separation between general and specific communications
- Logical grouping by agent hierarchy

### 2. **Scalability**
- Easy to add new agents/sub-agents
- Structure scales to 24+ agents without clutter
- Clear patterns for new document types

### 3. **Navigation**
- Intuitive path: `l1-standalone/10_research/prompts/` → find all prompts for Research Agent
- Chronological sorting within each directory (timestamp prefix format)
- Easy to browse by agent or by communication type

### 4. **Maintenance**
- Clear ownership: each agent's directory contains their communications
- Easy to archive: move entire agent directory when agent work is complete
- Easy to audit: see all communications for an agent in one place

---

## Common Path Updates

### Old Path → New Path

**General Prompts**:
- `docs/agent-communications/glow_g2_voice_multi_agent_prompt_*.md`
  → `docs/agent-communications/general/prompts/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md`

- `docs/agent-communications/timestamp_specification_multi_agent_prompt_*.md`
  → `docs/agent-communications/general/prompts/timestamp_specification_multi_agent_prompt_2026-01-01-215553-pst.md`

**Coordination Summaries**:
- `docs/agent-communications/core_1_subcore_coordination_summary_*.md`
  → `docs/agent-communications/general/coordination/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_summary.md`

**Critical Path Tools**:
- `docs/agent-communications/critical_path_quick_reference_*.md`
  → `docs/agent-communications/general/templates/2026-01-02-084259-pst_critical_path_quick_reference_2026-01-02-084259-pst.md`

---

## Questions or Issues?

If you encounter any issues navigating the new structure:
1. Check `docs/agent-communications/README.md` first
2. Review `docs/2026-01-03-044110-pst_documentation_navigation_guide.md`
3. Reference `docs/agent-communications/general/templates/2026-01-03-055549-pst_directory_structure_pattern.md`
4. Contact Core 1 Subcore if you need clarification

---

## Acknowledgment Requested

Please acknowledge receipt of this prompt by:
1. Reviewing the new directory structure
2. Familiarizing yourself with the updated navigation guides
3. Updating your coordination document with a brief note about the new structure (when convenient)

**Your Acknowledgment Location**: `docs/agent-communications/l1-standalone/10_research/acknowledgments/YYYY-MM-DD-HHMMSS-pst_research_agent_directory_structure_acknowledgment.md`

---

**Date**: 2026-01-03-060500-pst  
**Agent**: Research Agent (10)  
**Status**: ✅ **PROMPT READY** — Begin immediate review and adoption

