# Agent Communications Directory

**Purpose**: Organized directory structure for Grain OS agent prompts, acknowledgments, and communications

**Pattern Document**: See `2026-01-03-055549-pst_directory_structure_pattern.md` for complete pattern documentation

---

## Quick Navigation

### General Documents (All Agents)
- **Prompts**: `general/prompts/` — Multi-agent prompts (Glow G2 voice, timestamp format, agent awareness)
- **Coordination**: `general/coordination/` — General coordination summaries
- **Templates**: `general/templates/` — Reusable templates and toolkits

### Agent-Specific Documents

**L1 Subcore Coordinators**:
- `l1-subcores/core_1_subcore/`
- `l1-subcores/aurora_2_subcore/`
- `l1-subcores/vantage_3_subcore/`

**L2 Sub-Agents**:
- `l2-subagents/core_1/{1a_auth,1b_network,1c_storage,1d_compositor,1e_grainscript_shell}/`
- `l2-subagents/aurora_2/{2a_dream_editor,2b_dream_browser,2c_component_library}/`
- `l2-subagents/vantage_3/{3a_basin_kernel,3b_vm_runtime,3c_system_integration,3d_sevenos_init_system}/`

**Standalone L1 Agents**:
- `l1-standalone/{4_skate,5_bubble,6_carry,7_silo,8_workspace,9_flow,10_research,11_court,12_free}/`

### Cross-Agent Communications
- `cross-agent/core_1_internal/` — Core 1 sub-agents ↔ Core 1 sub-agents
- `cross-agent/vantage_3_internal/` — Vantage 3 sub-agents ↔ Vantage 3 sub-agents
- `cross-agent/aurora_2_internal/` — Aurora 2 sub-agents ↔ Aurora 2 sub-agents
- `cross-agent/cross_domain/` — Cross-domain communications
- `cross-agent/l1_to_l1/` — L1 Subcore ↔ L1 Subcore
- `cross-agent/l1_to_l2/` — L1 Subcore ↔ L2 Sub-Agent

---

## Directory Structure

Each agent directory contains:
- **`prompts/`**: Prompts directed to this agent
- **`acknowledgments/`**: Acknowledgments from this agent
- **`communications/`**: Cross-agent communications (L2 and standalone)
- **`coordination/`**: Coordination documents (L1 Subcores only)

---

## Naming Convention

**Format**: `YYYY-MM-DD-HHMMSS-pst_{agent_context}_{document_type}.md`

**Generate timestamp**:
```bash
TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
```

---

## Migration Status

**Status**: ✅ **COMPLETE**

- **Files Migrated**: 149 files
- **Files Remaining**: 0 files
- **Migration Log**: See `general/templates/2026-01-03-055600-pst_migration_log.md`

---

## Reference Documents

- **Pattern Documentation**: `2026-01-03-055549-pst_directory_structure_pattern.md`
- **Recommendation Document**: `2026-01-03-055401-pst_directory_structure_recommendation.md`
- **Migration Log**: `2026-01-03-055600-pst_migration_log.md`

---

**Last Updated**: 2026-01-03-055900-pst

