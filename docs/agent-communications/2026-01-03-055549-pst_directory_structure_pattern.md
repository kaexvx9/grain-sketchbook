# Agent Communications Directory Structure Pattern

**Date**: 2026-01-03-055549-pst  
**Purpose**: Meta-document describing the hierarchical directory structure pattern for Grain OS agent communications  
**Status**: ✅ **PATTERN DOCUMENTED** — Reference guide for all agents

---

## Executive Summary

This document describes the **hierarchical, agent-aware directory structure pattern** for organizing Grain OS agent communications. The pattern separates general prompts (for all agents) from agent-specific prompts, organizes by agent hierarchy (L1 Subcores, L2 Sub-Agents, Standalone L1 Agents), and groups by communication type (prompts, acknowledgments, coordination, cross-agent).

**Key Principle**: **Agent-aware organization** — Each agent's communications are grouped in their own directory, making it easy to find all documents related to a specific agent.

---

## Pattern Overview

### Directory Hierarchy

```
docs/agent-communications/
├── general/              # General prompts for ALL agents
├── l1-subcores/         # L1 Subcore Coordinators (1, 2, 3)
├── l2-subagents/        # L2 Sub-Agents (1a-1e, 2a-2c, 3a-3d)
├── l1-standalone/       # Standalone L1 Agents (4-12)
└── cross-agent/         # Cross-agent communications
```

### Communication Types

Each agent directory contains three subdirectories:
- **`prompts/`**: Prompts directed to this agent
- **`acknowledgments/`**: Acknowledgments from this agent
- **`communications/`**: Cross-agent communications involving this agent (for L2 and standalone)
- **`coordination/`**: Coordination documents (for L1 Subcores only)

---

## Pattern Details

### 1. General Communications (`general/`)

**Purpose**: Documents that apply to **all agents/sub-agents**

**Structure**:
```
general/
├── prompts/          # Multi-agent prompts
├── coordination/     # General coordination summaries
└── templates/        # Reusable templates and toolkits
```

**When to Use**:
- Creating a prompt for **all agents** (e.g., Glow G2 voice adoption, timestamp format)
- Creating a **general coordination summary** (e.g., Core 1 Subcore coordination summary)
- Creating a **reusable template** (e.g., critical path toolkit, pre-work checklist)

**Examples**:
- `general/prompts/2026-01-01-235155-pst_glow_g2_voice_multi_agent_prompt.md`
- `general/coordination/2026-01-03-042621-pst_core_1_subcore_coordination_summary.md`
- `general/templates/2026-01-02-090326-pst_pre_work_session_checklist.md`

**Naming Convention**: `YYYY-MM-DD-HHMMSS-pst_{document_name}.md`

---

### 2. L1 Subcore Coordinators (`l1-subcores/`)

**Purpose**: Communications specific to **L1 Subcore Coordinators** (Agents 1, 2, 3)

**Structure**:
```
l1-subcores/
├── core_1_subcore/
│   ├── prompts/
│   ├── acknowledgments/
│   └── coordination/
├── aurora_2_subcore/
│   ├── prompts/
│   ├── acknowledgments/
│   └── coordination/
└── vantage_3_subcore/
    ├── prompts/
    ├── acknowledgments/
    └── coordination/
```

**When to Use**:
- Creating a prompt **for** a specific L1 Subcore Coordinator
- An acknowledgment **from** a specific L1 Subcore Coordinator
- Coordination documents **for** a specific L1 Subcore Coordinator

**Examples**:
- `l1-subcores/core_1_subcore/prompts/2026-01-03-154811-pst_core_1_subcore_timestamp_prefix_acknowledgment.md`
- `l1-subcores/vantage_3_subcore/coordination/2026-01-02-083246-pst_vantage_3_subcore_coordination_status.md`

**Naming Convention**: `YYYY-MM-DD-HHMMSS-pst_{subcore_name}_{document_type}.md`

---

### 3. L2 Sub-Agents (`l2-subagents/`)

**Purpose**: Communications specific to **L2 Sub-Agents** (1a-1e, 2a-2c, 3a-3d)

**Structure**:
```
l2-subagents/
├── core_1/
│   ├── 1a_auth/
│   │   ├── prompts/
│   │   ├── acknowledgments/
│   │   └── communications/
│   ├── 1b_network/
│   ├── 1c_storage/
│   ├── 1d_compositor/
│   └── 1e_grainscript_shell/
├── aurora_2/
│   ├── 2a_dream_editor/
│   ├── 2b_dream_browser/
│   └── 2c_component_library/
└── vantage_3/
    ├── 3a_basin_kernel/
    │   ├── prompts/
    │   ├── acknowledgments/
    │   └── communications/
    ├── 3b_vm_runtime/
    ├── 3c_system_integration/
    └── 3d_sevenos_init_system/
```

**When to Use**:
- Creating a prompt **for** a specific L2 Sub-Agent
- An acknowledgment **from** a specific L2 Sub-Agent
- Cross-agent communications **involving** a specific L2 Sub-Agent

**Examples**:
- `l2-subagents/vantage_3/3a_basin_kernel/prompts/2026-01-03-055237-pst_basin_kernel_agent_3a_prompt.md`
- `l2-subagents/core_1/1d_compositor/acknowledgments/2026-01-02-100500-pst_core_1d_compositor_coordination_summary_acknowledgment.md`

**Naming Convention**: `YYYY-MM-DD-HHMMSS-pst_{agent_id}_{agent_name}_{document_type}.md`

---

### 4. Standalone L1 Agents (`l1-standalone/`)

**Purpose**: Communications specific to **Standalone L1 Agents** (4-12)

**Structure**:
```
l1-standalone/
├── 4_skate/
│   ├── prompts/
│   ├── acknowledgments/
│   └── communications/
├── 5_bubble/
├── 6_carry/
├── 7_silo/
├── 8_workspace/
├── 9_flow/
├── 10_research/
├── 11_court/
└── 12_free/
```

**When to Use**:
- Creating a prompt **for** a specific standalone L1 Agent
- An acknowledgment **from** a specific standalone L1 Agent
- Cross-agent communications **involving** a specific standalone L1 Agent

**Examples**:
- `l1-standalone/5_bubble/prompts/2026-01-01-081614-pst_bubble_agent_parallel_development_response.md`

**Naming Convention**: `YYYY-MM-DD-HHMMSS-pst_{agent_id}_{agent_name}_{document_type}.md`

---

### 5. Cross-Agent Communications (`cross-agent/`)

**Purpose**: Communications **between agents** (not general, not single-agent-specific)

**Structure**:
```
cross-agent/
├── core_1_internal/        # Core 1 sub-agents ↔ Core 1 sub-agents
├── vantage_3_internal/     # Vantage 3 sub-agents ↔ Vantage 3 sub-agents
├── aurora_2_internal/      # Aurora 2 sub-agents ↔ Aurora 2 sub-agents
├── l1_to_l1/               # L1 Subcore ↔ L1 Subcore
├── l1_to_l2/               # L1 Subcore ↔ L2 Sub-Agent (outside parent)
└── cross_domain/           # Cross-domain (e.g., Aurora ↔ Bubble)
```

**When to Use**:
- Communication **from** one agent **to** another agent
- Coordination between agents in the same subcore (internal)
- Coordination between agents in different subcores (cross-domain)
- L1 Subcore ↔ L2 Sub-Agent communication (outside parent subcore)

**Examples**:
- `cross-agent/core_1_internal/2026-01-02-090144-pst_core_1c_storage_to_1d_compositor_coordination_response.md`
- `cross-agent/vantage_3_internal/2026-01-02-090000-pst_vantage_3a_to_3b_ecall_reminder.md`
- `cross-agent/cross_domain/2026-01-02-084110-pst_aurora_2_subcore_to_bubble_component_api_coordination.md`

**Naming Convention**: `YYYY-MM-DD-HHMMSS-pst_{from_agent}_to_{to_agent}_{document_type}.md`

---

## Naming Convention (Unified)

### Format

```
YYYY-MM-DD-HHMMSS-pst_{agent_context}_{document_type}.md
```

### Components

1. **Timestamp**: `YYYY-MM-DD-HHMMSS-pst` (Pacific Standard Time)
   - Generate with: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
   - Enables chronological sorting

2. **Agent Context**: Identifies the agent(s) involved
   - General: `glow_g2_voice_multi_agent_prompt`
   - Single agent: `basin_kernel_agent_3a_prompt`
   - Cross-agent: `vantage_3a_to_3b_ecall_reminder`

3. **Document Type**: Describes the document purpose
   - `prompt`, `acknowledgment`, `coordination`, `communication`, `response`, `request`, etc.

### Examples

- **General prompt**: `2026-01-01-235155-pst_glow_g2_voice_multi_agent_prompt.md`
- **Agent-specific prompt**: `2026-01-03-055237-pst_basin_kernel_agent_3a_prompt.md`
- **Acknowledgment**: `2026-01-02-100500-pst_core_1d_compositor_coordination_summary_acknowledgment.md`
- **Cross-agent communication**: `2026-01-02-090000-pst_vantage_3a_to_3b_ecall_reminder.md`

---

## How to Use This Pattern

### Creating a New Document

1. **Determine the document type**:
   - General (for all agents) → `general/`
   - Agent-specific → `l1-subcores/`, `l2-subagents/`, or `l1-standalone/`
   - Cross-agent → `cross-agent/`

2. **Determine the subdirectory**:
   - Prompt → `prompts/`
   - Acknowledgment → `acknowledgments/`
   - Coordination → `coordination/` (L1 Subcores only)
   - Cross-agent communication → `communications/` (L2 and standalone)

3. **Generate timestamp**:
   ```bash
   TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"
   ```

4. **Create filename**:
   - Follow naming convention: `YYYY-MM-DD-HHMMSS-pst_{agent_context}_{document_type}.md`
   - Use `grain_case` (snake_case) for all parts

5. **Create file in correct location**:
   - Full path: `docs/agent-communications/{category}/{agent_path}/{subdirectory}/{filename}.md`

### Finding Documents

#### Find All Documents for a Specific Agent

**L2 Sub-Agent (e.g., 3a Basin Kernel)**:
```bash
ls -la docs/agent-communications/l2-subagents/vantage_3/3a_basin_kernel/
```

**L1 Subcore (e.g., Core 1 Subcore)**:
```bash
ls -la docs/agent-communications/l1-subcores/core_1_subcore/
```

**Standalone L1 Agent (e.g., 5 Bubble)**:
```bash
ls -la docs/agent-communications/l1-standalone/5_bubble/
```

#### Find All Prompts for an Agent

```bash
ls -la docs/agent-communications/l2-subagents/vantage_3/3a_basin_kernel/prompts/
```

#### Find Latest Document (Chronological Sort)

```bash
ls -t docs/agent-communications/l2-subagents/vantage_3/3a_basin_kernel/prompts/ | head -1
```

#### Find Cross-Agent Communications

**Between Core 1 sub-agents**:
```bash
ls -la docs/agent-communications/cross-agent/core_1_internal/
```

**Between Vantage 3 sub-agents**:
```bash
ls -la docs/agent-communications/cross-agent/vantage_3_internal/
```

**Cross-domain**:
```bash
ls -la docs/agent-communications/cross-agent/cross_domain/
```

---

## Agent ID Reference

### L1 Subcore Coordinators

- **1**: Core 1 Subcore (`core_1_subcore`)
- **2**: Aurora 2 Subcore (`aurora_2_subcore`)
- **3**: Vantage 3 Subcore (`vantage_3_subcore`)

### L2 Sub-Agents

**Core 1**:
- **1a**: Auth (`1a_auth`)
- **1b**: Network (`1b_network`)
- **1c**: Storage (`1c_storage`)
- **1d**: Compositor (`1d_compositor`)
- **1e**: Grainscript Shell (`1e_grainscript_shell`)

**Aurora 2**:
- **2a**: Dream Editor (`2a_dream_editor`)
- **2b**: Dream Browser (`2b_dream_browser`)
- **2c**: Component Library (`2c_component_library`)

**Vantage 3**:
- **3a**: Basin Kernel (`3a_basin_kernel`)
- **3b**: VM Runtime (`3b_vm_runtime`)
- **3c**: System Integration (`3c_system_integration`)
- **3d**: sevenos Init System (`3d_sevenos_init_system`)

### Standalone L1 Agents

- **4**: Skate (`4_skate`)
- **5**: Bubble (`5_bubble`)
- **6**: Carry (`6_carry`)
- **7**: Silo (`7_silo`)
- **8**: Workspace (`8_workspace`)
- **9**: Flow (`9_flow`)
- **10**: Research (`10_research`)
- **11**: Court (`11_court`)
- **12**: Free (`12_free`)

---

## Best Practices

### 1. Always Use Timestamp Prefix Format

✅ **Correct**: `2026-01-03-055237-pst_basin_kernel_agent_3a_prompt.md`  
❌ **Incorrect**: `basin_kernel_agent_3a_prompt_2026-01-03-055237-pst.md`

**Why**: Enables automatic chronological sorting in file browsers and on Codeberg.

### 2. Use Descriptive Document Types

✅ **Good**: `prompt`, `acknowledgment`, `coordination_response`, `ecall_reminder`  
❌ **Avoid**: `doc`, `file`, `message`, `thing`

### 3. Group Related Documents

- Keep all documents for an agent in their directory
- Use subdirectories (`prompts/`, `acknowledgments/`, `communications/`) to organize by type
- Don't create flat structures within agent directories

### 4. Use Consistent Agent Names

- Use official agent names from `docs/2026-01-03-044511-pst_framework_16_agent_list_with_subagents.md`
- Use `grain_case` (snake_case) for all agent names
- Be consistent: `basin_kernel`, not `basin-kernel` or `BasinKernel`

### 5. Cross-Agent Communications

- Always place in `cross-agent/` directory
- Use appropriate subdirectory (`core_1_internal/`, `vantage_3_internal/`, `cross_domain/`, etc.)
- Use `{from_agent}_to_{to_agent}` format in filename

### 6. General Documents

- Only use `general/` for documents that apply to **all agents**
- If a document applies to a subset (e.g., all L2 sub-agents), consider creating it in each agent's directory or use a more specific location

---

## Migration from Old Structure

### Old Location → New Location Mapping

**General Prompts**:
- `docs/agent-communications/glow_g2_voice_multi_agent_prompt_*.md`
  → `docs/agent-communications/general/prompts/2026-01-01-235155-pst_glow_g2_voice_multi_agent_prompt.md`

**Agent-Specific Prompts**:
- `docs/agent-communications/basin_kernel_agent_3a_prompt.md`
  → `docs/agent-communications/l2-subagents/vantage_3/3a_basin_kernel/prompts/2026-01-03-055237-pst_basin_kernel_agent_3a_prompt.md`

**Cross-Agent Communications**:
- `docs/agent-communications/vantage_3a_to_3b_ecall_reminder_*.md`
  → `docs/agent-communications/cross-agent/vantage_3_internal/2026-01-02-090000-pst_vantage_3a_to_3b_ecall_reminder.md`

**Acknowledgment Documents**:
- `docs/agent-communications/*_acknowledgment_*.md`
  → `docs/agent-communications/{agent_path}/acknowledgments/{filename}.md`

---

## Examples

### Example 1: Creating a Prompt for Agent 3a

**Path**: `docs/agent-communications/l2-subagents/vantage_3/3a_basin_kernel/prompts/2026-01-03-055237-pst_basin_kernel_agent_3a_prompt.md`

**Steps**:
1. Generate timestamp: `2026-01-03-055237-pst`
2. Determine agent: `3a_basin_kernel`
3. Determine type: `prompt`
4. Create filename: `2026-01-03-055237-pst_basin_kernel_agent_3a_prompt.md`
5. Create file in: `l2-subagents/vantage_3/3a_basin_kernel/prompts/`

### Example 2: Creating a Cross-Agent Communication

**Path**: `docs/agent-communications/cross-agent/vantage_3_internal/2026-01-02-090000-pst_vantage_3a_to_3b_ecall_reminder.md`

**Steps**:
1. Determine it's cross-agent: `3a` → `3b` (both in Vantage 3)
2. Determine subdirectory: `vantage_3_internal/` (both in same subcore)
3. Generate timestamp: `2026-01-02-090000-pst`
4. Create filename: `2026-01-02-090000-pst_vantage_3a_to_3b_ecall_reminder.md`
5. Create file in: `cross-agent/vantage_3_internal/`

### Example 3: Creating a General Prompt

**Path**: `docs/agent-communications/general/prompts/2026-01-01-235155-pst_glow_g2_voice_multi_agent_prompt.md`

**Steps**:
1. Determine it's general (for all agents)
2. Determine subdirectory: `prompts/` (it's a prompt)
3. Generate timestamp: `2026-01-01-235155-pst`
4. Create filename: `2026-01-01-235155-pst_glow_g2_voice_multi_agent_prompt.md`
5. Create file in: `general/prompts/`

---

## Reference Documents

- **Agent List**: `docs/2026-01-03-044511-pst_framework_16_agent_list_with_subagents.md`
- **Directory Structure Recommendation**: `docs/agent-communications/2026-01-03-055401-pst_directory_structure_recommendation.md`
- **Documentation Navigation Guide**: `docs/2026-01-03-044110-pst_documentation_navigation_guide.md`
- **Timestamp Format**: `docs/agent-communications/general/prompts/2026-01-03-051300-pst_timestamp_prefix_format_all_agents.md`

---

## Questions?

If you're unsure where to place a document:

1. **Is it for all agents?** → `general/`
2. **Is it for a specific agent?** → `l1-subcores/`, `l2-subagents/`, or `l1-standalone/`
3. **Is it between agents?** → `cross-agent/`
4. **Is it a prompt?** → `prompts/`
5. **Is it an acknowledgment?** → `acknowledgments/`
6. **Is it coordination?** → `coordination/` (L1 Subcores) or `communications/` (L2/standalone)

When in doubt, ask Core 1 Subcore or check existing similar documents for patterns.

---

**Date**: 2026-01-03-055549-pst  
**Status**: ✅ **PATTERN DOCUMENTED** — Reference guide for all agents  
**Maintained By**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)

---

**Last Updated**: 2026-01-03-055549-pst

