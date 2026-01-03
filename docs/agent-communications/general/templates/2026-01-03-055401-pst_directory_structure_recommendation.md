# Agent Communications Directory Structure Recommendation

**Date**: 2026-01-03-055401-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Purpose**: Recommend improved directory structure for organizing Grain OS agent prompts and communications  
**Status**: ✅ **RECOMMENDATION READY** — Ready for review and implementation

---

## Executive Summary

The current `docs/agent-communications/` directory contains **163+ files** with mixed naming conventions and purposes, making navigation difficult. This document proposes a **hierarchical, agent-aware directory structure** that:

1. **Separates general prompts** (for all agents) from **agent-specific prompts**
2. **Organizes by agent hierarchy** (L1 Subcores, L2 Sub-Agents, Standalone L1 Agents)
3. **Groups by communication type** (prompts, acknowledgments, coordination, cross-agent)
4. **Maintains timestamp prefix format** for chronological sorting
5. **Scales cleanly** for all 24 agents/sub-agents

---

## Current Structure Analysis

### Current Issues

1. **Flat directory**: All 163+ files in single `docs/agent-communications/` directory
2. **Mixed purposes**: General prompts, agent-specific prompts, acknowledgments, coordination summaries all mixed together
3. **Inconsistent naming**: Some with timestamps, some without; some with agent IDs, some without
4. **Hard to navigate**: Difficult to find:
   - Latest prompt for a specific agent
   - All communications for a specific agent
   - General prompts for all agents
   - Cross-agent coordination documents

### Current File Types Identified

1. **General Prompts** (for all agents):
   - `glow_g2_voice_multi_agent_prompt_*.md`
   - `timestamp_specification_multi_agent_prompt_*.md`
   - `complete_agent_awareness_all_agents_*.md`
   - `timestamp_prefix_format_all_agents.md`

2. **Coordination Summaries** (general):
   - `core_1_subcore_coordination_summary_*.md`
   - `vantage_3_subcore_coordination_summary_*.md`

3. **Agent-Specific Prompts**:
   - `basin_kernel_agent_3a_prompt.md`
   - `core_1a_auth_*.md`
   - `core_1d_compositor_*.md`

4. **Cross-Agent Communications**:
   - `vantage_3a_to_3b_*.md`
   - `core_1c_storage_to_1d_compositor_*.md`
   - `aurora_2_subcore_to_bubble_*.md`

5. **Acknowledgment Documents**:
   - `*_acknowledgment_*.md`
   - `*_acknowledgment.md`

6. **Templates and Toolkits**:
   - `critical_path_*.md`
   - `pre_work_session_checklist_*.md`

---

## Recommended Directory Structure

### Proposed Hierarchy

```
docs/agent-communications/
├── general/                          # General prompts for ALL agents
│   ├── prompts/                      # Multi-agent prompts
│   │   ├── 2026-01-01-235155-pst_glow_g2_voice_multi_agent_prompt.md
│   │   ├── 2026-01-01-215553-pst_timestamp_specification_multi_agent_prompt.md
│   │   ├── 2026-01-03-051300-pst_timestamp_prefix_format_all_agents.md
│   │   └── 2026-01-02-002948-pst_complete_agent_awareness_all_agents.md
│   ├── coordination/                 # General coordination summaries
│   │   ├── 2026-01-03-042621-pst_core_1_subcore_coordination_summary.md
│   │   └── 2026-01-02-100345-pst_vantage_3_subcore_coordination_summary.md
│   └── templates/                    # Templates and toolkits
│       ├── 2026-01-02-084613-pst_critical_path_toolkit_summary.md
│       ├── 2026-01-02-090326-pst_pre_work_session_checklist.md
│       └── 2026-01-02-084613-pst_critical_path_coordination_agenda_template.md
│
├── l1-subcores/                      # L1 Subcore Coordinators (1, 2, 3)
│   ├── core_1_subcore/              # Core 1 Subcore (Agent 1)
│   │   ├── prompts/                 # Prompts for Core 1 Subcore
│   │   ├── acknowledgments/         # Acknowledgments from Core 1 Subcore
│   │   └── coordination/            # Core 1 Subcore coordination docs
│   ├── aurora_2_subcore/            # Aurora 2 Subcore (Agent 2)
│   │   ├── prompts/
│   │   ├── acknowledgments/
│   │   └── coordination/
│   └── vantage_3_subcore/          # Vantage 3 Subcore (Agent 3)
│       ├── prompts/
│       ├── acknowledgments/
│       └── coordination/
│
├── l2-subagents/                     # L2 Sub-Agents (1a-1e, 2a-2c, 3a-3d)
│   ├── core_1/                      # Core 1 L2 Sub-Agents
│   │   ├── 1a_auth/
│   │   │   ├── prompts/
│   │   │   ├── acknowledgments/
│   │   │   └── communications/      # Cross-agent communications
│   │   ├── 1b_network/
│   │   ├── 1c_storage/
│   │   ├── 1d_compositor/
│   │   └── 1e_grainscript_shell/
│   ├── aurora_2/                    # Aurora 2 L2 Sub-Agents
│   │   ├── 2a_dream_editor/
│   │   ├── 2b_dream_browser/
│   │   └── 2c_component_library/
│   └── vantage_3/                   # Vantage 3 L2 Sub-Agents
│       ├── 3a_basin_kernel/
│       │   ├── prompts/
│       │   │   └── 2026-01-03-055237-pst_basin_kernel_agent_3a_prompt.md
│       │   ├── acknowledgments/
│       │   └── communications/
│       ├── 3b_vm_runtime/
│       ├── 3c_system_integration/
│       └── 3d_sevenos_init_system/
│
├── l1-standalone/                    # Standalone L1 Agents (4-12)
│   ├── 4_skate/
│   ├── 5_bubble/
│   ├── 6_carry/
│   ├── 7_silo/
│   ├── 8_workspace/
│   ├── 9_flow/
│   ├── 10_research/
│   ├── 11_court/
│   └── 12_free/
│
└── cross-agent/                      # Cross-agent communications
    ├── core_1_internal/             # Core 1 sub-agents ↔ Core 1 sub-agents
    │   └── 2026-01-02-090144-pst_core_1c_storage_to_1d_compositor_coordination_response.md
    ├── vantage_3_internal/          # Vantage 3 sub-agents ↔ Vantage 3 sub-agents
    │   └── 2026-01-02-090000-pst_vantage_3a_to_3b_ecall_reminder.md
    ├── l1_to_l1/                    # L1 Subcore ↔ L1 Subcore
    ├── l1_to_l2/                    # L1 Subcore ↔ L2 Sub-Agent
    └── cross_domain/                 # Cross-domain (e.g., Aurora ↔ Bubble)
        └── 2026-01-02-084110-pst_aurora_2_subcore_to_bubble_component_api_coordination.md
```

---

## Directory Structure Details

### 1. `general/` — General Prompts for ALL Agents

**Purpose**: Documents that apply to all agents/sub-agents

**Subdirectories**:
- **`prompts/`**: Multi-agent prompts (Glow G2 voice, timestamp format, agent awareness)
- **`coordination/`**: General coordination summaries (Core 1 Subcore, Vantage 3 Subcore)
- **`templates/`**: Reusable templates and toolkits (critical path, checklists)

**Naming Convention**: `YYYY-MM-DD-HHMMSS-pst_document_name.md`

**Examples**:
- `general/prompts/2026-01-01-235155-pst_glow_g2_voice_multi_agent_prompt.md`
- `general/coordination/2026-01-03-042621-pst_core_1_subcore_coordination_summary.md`
- `general/templates/2026-01-02-090326-pst_pre_work_session_checklist.md`

---

### 2. `l1-subcores/` — L1 Subcore Coordinators

**Purpose**: Communications specific to L1 Subcore Coordinators (Agents 1, 2, 3)

**Structure**: One directory per L1 Subcore
- `core_1_subcore/`
- `aurora_2_subcore/`
- `vantage_3_subcore/`

**Subdirectories** (per L1 Subcore):
- **`prompts/`**: Prompts directed to this L1 Subcore
- **`acknowledgments/`**: Acknowledgments from this L1 Subcore
- **`coordination/`**: L1 Subcore-specific coordination documents

**Naming Convention**: `YYYY-MM-DD-HHMMSS-pst_{subcore_name}_{document_type}.md`

**Examples**:
- `l1-subcores/core_1_subcore/prompts/2026-01-03-154811-pst_core_1_subcore_timestamp_prefix_acknowledgment.md`
- `l1-subcores/vantage_3_subcore/coordination/2026-01-02-083246-pst_vantage_3_subcore_coordination_status.md`

---

### 3. `l2-subagents/` — L2 Sub-Agents

**Purpose**: Communications specific to L2 Sub-Agents (1a-1e, 2a-2c, 3a-3d)

**Structure**: Grouped by parent L1 Subcore, then by agent ID
- `core_1/1a_auth/`, `core_1/1b_network/`, etc.
- `aurora_2/2a_dream_editor/`, `aurora_2/2b_dream_browser/`, etc.
- `vantage_3/3a_basin_kernel/`, `vantage_3/3b_vm_runtime/`, etc.

**Subdirectories** (per L2 Sub-Agent):
- **`prompts/`**: Prompts directed to this L2 Sub-Agent
- **`acknowledgments/`**: Acknowledgments from this L2 Sub-Agent
- **`communications/`**: Cross-agent communications involving this L2 Sub-Agent

**Naming Convention**: `YYYY-MM-DD-HHMMSS-pst_{agent_id}_{agent_name}_{document_type}.md`

**Examples**:
- `l2-subagents/vantage_3/3a_basin_kernel/prompts/2026-01-03-055237-pst_basin_kernel_agent_3a_prompt.md`
- `l2-subagents/core_1/1d_compositor/acknowledgments/2026-01-02-100500-pst_core_1d_compositor_coordination_summary_acknowledgment.md`

---

### 4. `l1-standalone/` — Standalone L1 Agents

**Purpose**: Communications specific to standalone L1 Agents (4-12)

**Structure**: One directory per standalone agent
- `4_skate/`, `5_bubble/`, `6_carry/`, `7_silo/`, `8_workspace/`, `9_flow/`, `10_research/`, `11_court/`, `12_free/`

**Subdirectories** (per standalone agent):
- **`prompts/`**: Prompts directed to this agent
- **`acknowledgments/`**: Acknowledgments from this agent
- **`communications/`**: Cross-agent communications involving this agent

**Naming Convention**: `YYYY-MM-DD-HHMMSS-pst_{agent_id}_{agent_name}_{document_type}.md`

**Examples**:
- `l1-standalone/5_bubble/prompts/2026-01-01-081614-pst_bubble_agent_parallel_development_response.md`

---

### 5. `cross-agent/` — Cross-Agent Communications

**Purpose**: Communications between agents (not general, not single-agent-specific)

**Subdirectories**:
- **`core_1_internal/`**: Core 1 sub-agents ↔ Core 1 sub-agents
- **`vantage_3_internal/`**: Vantage 3 sub-agents ↔ Vantage 3 sub-agents
- **`aurora_2_internal/`**: Aurora 2 sub-agents ↔ Aurora 2 sub-agents
- **`l1_to_l1/`**: L1 Subcore ↔ L1 Subcore
- **`l1_to_l2/`**: L1 Subcore ↔ L2 Sub-Agent (outside parent subcore)
- **`cross_domain/`**: Cross-domain communications (e.g., Aurora ↔ Bubble, Core ↔ Vantage)

**Naming Convention**: `YYYY-MM-DD-HHMMSS-pst_{from_agent}_to_{to_agent}_{document_type}.md`

**Examples**:
- `cross-agent/core_1_internal/2026-01-02-090144-pst_core_1c_storage_to_1d_compositor_coordination_response.md`
- `cross-agent/vantage_3_internal/2026-01-02-090000-pst_vantage_3a_to_3b_ecall_reminder.md`
- `cross-agent/cross_domain/2026-01-02-084110-pst_aurora_2_subcore_to_bubble_component_api_coordination.md`

---

## Migration Strategy

### Phase 1: Create New Structure (This Week)

1. **Create directory structure**:
   ```bash
   mkdir -p docs/agent-communications/{general/{prompts,coordination,templates},l1-subcores/{core_1_subcore,aurora_2_subcore,vantage_3_subcore}/{prompts,acknowledgments,coordination},l2-subagents/{core_1/{1a_auth,1b_network,1c_storage,1d_compositor,1e_grainscript_shell},aurora_2/{2a_dream_editor,2b_dream_browser,2c_component_library},vantage_3/{3a_basin_kernel,3b_vm_runtime,3c_system_integration,3d_sevenos_init_system}}/{prompts,acknowledgments,communications},l1-standalone/{4_skate,5_bubble,6_carry,7_silo,8_workspace,9_flow,10_research,11_court,12_free}/{prompts,acknowledgments,communications},cross-agent/{core_1_internal,vantage_3_internal,aurora_2_internal,l1_to_l1,l1_to_l2,cross_domain}}
   ```

2. **Create migration script** to categorize and move files based on:
   - Filename patterns (agent IDs, agent names)
   - Document content (prompt, acknowledgment, coordination)
   - Cross-agent indicators (`_to_`, `_from_`)

### Phase 2: Migrate Files (Week 1-2)

1. **Migrate general prompts** to `general/prompts/`
2. **Migrate coordination summaries** to `general/coordination/`
3. **Migrate templates** to `general/templates/`
4. **Migrate agent-specific files** to appropriate `l1-subcores/`, `l2-subagents/`, or `l1-standalone/` directories
5. **Migrate cross-agent communications** to `cross-agent/` subdirectories

### Phase 3: Update References (Week 2)

1. **Update all document references** in:
   - Coordination documents
   - Plan documents
   - Tasks documents
   - Navigation guides
   - README files

2. **Create symlinks** (optional) from old locations to new locations for backward compatibility during transition

### Phase 4: Archive Old Structure (Week 2-3)

1. **Move old flat structure** to `archaeology/docs/agent-communications/legacy/`
2. **Create migration log** documenting all file moves
3. **Update documentation** to reference new structure

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
- Intuitive path: `l2-subagents/vantage_3/3a_basin_kernel/prompts/` → find all prompts for Agent 3a
- Chronological sorting within each directory (timestamp prefix format)
- Easy to browse by agent or by communication type

### 4. **Maintenance**
- Clear ownership: each agent's directory contains their communications
- Easy to archive: move entire agent directory when agent work is complete
- Easy to audit: see all communications for an agent in one place

### 5. **Consistency**
- Uniform naming convention across all directories
- Clear patterns for new documents
- Easy to enforce structure with scripts

---

## File Naming Convention (Unified)

**Format**: `YYYY-MM-DD-HHMMSS-pst_{agent_context}_{document_type}.md`

**Examples**:
- General prompt: `2026-01-01-235155-pst_glow_g2_voice_multi_agent_prompt.md`
- Agent-specific prompt: `2026-01-03-055237-pst_basin_kernel_agent_3a_prompt.md`
- Cross-agent communication: `2026-01-02-090000-pst_vantage_3a_to_3b_ecall_reminder.md`
- Acknowledgment: `2026-01-02-100500-pst_core_1d_compositor_coordination_summary_acknowledgment.md`

---

## Implementation Checklist

### Immediate Actions

- [ ] Review and approve this directory structure recommendation
- [ ] Create new directory structure
- [ ] Create migration script to categorize existing files
- [ ] Test migration script on sample files
- [ ] Execute migration for all 163+ files
- [ ] Update all document references
- [ ] Create migration log
- [ ] Archive old structure to `archaeology/`
- [ ] Update navigation guides
- [ ] Update README files

### Documentation Updates

- [ ] Update `docs/2026-01-03-044110-pst_documentation_navigation_guide.md`
- [ ] Update `docs/2026-01-03-045322-pst_framework_16_recursion_prompt_strict_guidelines.md`
- [ ] Create `docs/agent-communications/README.md` explaining new structure
- [ ] Update all coordination documents with new paths

---

## Alternative: Simplified Structure (If Full Hierarchy Too Complex)

If the full hierarchy is too complex, consider a **simplified 3-tier structure**:

```
docs/agent-communications/
├── general/              # All general prompts, coordination summaries, templates
├── agents/               # All agent-specific communications
│   ├── 1_core_1_subcore/
│   ├── 1a_auth/
│   ├── 1b_network/
│   ├── ...
│   ├── 3a_basin_kernel/
│   └── ...
└── cross-agent/          # All cross-agent communications
```

**Pros**: Simpler, easier to migrate  
**Cons**: Less organized, harder to navigate with 24 agents

---

## Recommendation

**Recommend the full hierarchical structure** for:
1. **Long-term scalability** (24 agents, growing)
2. **Clear organization** (easy to find agent-specific documents)
3. **Maintainability** (clear ownership and structure)
4. **Professional appearance** (well-organized codebase)

The migration effort is one-time, and the benefits compound over time.

---

**Date**: 2026-01-03-055401-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **RECOMMENDATION COMPLETE** — Ready for review and implementation

---

**Next Action**: Review this recommendation, approve structure, and begin Phase 1 (create directory structure).

