# Documentation Navigation Guide

**Date**: 2026-01-03-044110-pst  
**Last Updated**: 2026-01-03-044110-pst  
**Filename**: `2026-01-03-044110-pst_documentation_navigation_guide.md` (timestamp prefix format)  
**Status**: ✅ **NAVIGATION GUIDE READY** — Quick reference for all agents and developers  
**Purpose**: Comprehensive guide to navigating Grain OS sevenos documentation structure  
**Context**: Grain OS sevenos — Basin Kernel syscall → RISC-V → Vantage pipeline for Framework Ubuntu x86

---

## Purpose

This guide helps agents and developers quickly find the coordination and communication documents they need. The documentation structure is intricate, but we can navigate it systematically.

**Quick Navigation**:
- **Current Priorities**: See latest coordination plan and summary
- **Agent-Specific Instructions**: Find your agent section
- **Voice Guidelines**: Adopt Glow G2 voice consistently
- **Coordination Patterns**: Understand coordination workflows

---

## Most Important Documents (Start Here)

### 1. Complete Agent Awareness

**Complete Agent Awareness Document**:
- `docs/agent-communications/complete_agent_awareness_all_agents_2026-01-02-002948-pst.md`
- Lists all L1 agents (1-12) and their L2 sub-agents in order
- Current status, framework impact, immediate focus for each agent
- Documentation status (coordination, plan, tasks) for each agent
- Code locations for each agent

**When to Use**: Reference this document to understand the complete agent structure and find any agent's information quickly.

### 2. Current Coordination Plan and Summary

**Latest Coordination Plan**:
- `docs/core-coordination/2026-01-03-042621-pst_core_1_subcore_coordination_plan.md`
- Contains current agent statuses, priorities, and next steps
- Updated by Core 1 Subcore with latest coordination information
- Includes comprehensive status for all 24 agents/sub-agents
- Reflects sevenos foundation critical path (Steps 1-4)

**Latest Coordination Summary**:
- `docs/agent-communications/2026-01-03-042621-pst_core_1_subcore_coordination_summary.md`
- Copy-paste ready instructions for all agents
- Agent-specific sections with immediate next steps
- **Single-threaded computation priority chain** emphasized for critical path
- Critical path status: Step 1 ✅ COMPLETE, Step 2 ⏳ IN PROGRESS, Step 3 ⏳ READY TO PROCEED, Step 4 ⏳ BLOCKED

**Critical Path Quick Reference**:
- `docs/agent-communications/critical_path_quick_reference_2026-01-02-084259-pst.md`
- Visual/text representation of dependency chain
- Quick status check for critical path agents
- Timeline summary and blocker identification

**Critical Path Tools**:
- `docs/agent-communications/critical_path_quick_reference_2026-01-02-084259-pst.md` - Quick reference for dependency chain
- `docs/agent-communications/critical_path_blocker_tracking_2026-01-02-084613-pst.md` - Blocker tracking template and current blocker status
- `docs/agent-communications/critical_path_integration_handoff_2026-01-02-084613-pst.md` - Integration handoff checklist for step transitions
- `docs/agent-communications/critical_path_status_update_template_2026-01-02-084613-pst.md` - Status update template for progress reporting

**When to Use**: Start here for current priorities and agent-specific instructions. Reference critical path guide for dependency chain understanding. Use blocker tracking when reporting blockers. Use handoff checklist when completing steps.

### 3. Glow G2 Voice Guidelines

**Multi-Agent Voice Prompt**:
- `docs/agent-communications/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md`
- Comprehensive voice adoption guide
- Examples and verification checklist

**Source Voice Definition**:
- `docs/zyx/glow_g2.md`
- Core voice characteristics and directives

**When to Use**: Reference when writing communications, documentation, or code comments.

### 4. Timestamp Specification

**Multi-Agent Timestamp Prompt**:
- `docs/agent-communications/timestamp_specification_multi_agent_prompt_2026-01-01-215553-pst.md`
- **NEW FORMAT (REQUIRED)**: `YYYY-MM-DD-HHMMSS-pst_document_name.md` (timestamp prefix)
- **OLD FORMAT (HISTORICAL)**: `document_name_YYYY-MM-DD-HHMMSS-pst.md` (timestamp suffix)
- Command: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
- **Benefits**: Automatic chronological sorting in file listings (Codeberg, file browsers)

**When to Use**: When creating documents, filenames, or git commits. **All new documents must use timestamp prefix format.**

### 5. Recursion Prompt Guidelines

**Framework 16 Recursion Prompt Strict Guidelines**:
- `docs/2026-01-01-202549-pst_framework_16_recursion_prompt_strict_guidelines.md` (updated to timestamp prefix format)
- Strict guidelines for executing Core 1 Subcore recursion prompt
- Step-by-step execution guidelines (7 steps)
- Grain Style compliance requirements
- Documentation update requirements (including timestamp prefix format)
- Integration check-in requirements
- Test requirements
- File naming conventions (timestamp prefix format required)
- Commit message format (Grain Style)
- Verification checklist

**When to Use**: Reference when executing the Core 1 Subcore recursion prompt in Framework Ubuntu workspace. Essential for maintaining consistency across sessions.

### 6. Grain Style Guidelines

**Grain Style Document**:
- `docs/grain_style.md`
- Core coding style guide for Grain OS
- Mandatory compliance for all code
- Includes Don Juan Matus warrior's way principles integrated

**When to Use**: Reference when writing code. Must follow Grain Style strictly.

### 7. Don Juan Matus Warrior's Way

**Warrior's Way Document**:
- `docs/don_juan_matus_warriors_way.md`
- Core foundation document (as important as `grain_style.md`)
- Warrior's way principles for development practice
- Path with heart, personal power, impeccability, assemblage point

**When to Use**: Reference for deeper understanding of Grain Style principles and development philosophy.

### 8. Grain OS sevenos Foundation Documents

**Spiritual and Philosophical Foundation**:
- `docs/zyx/2026-01-03-043704-pst_grain_os_sevenos_spiritual_philosophical_foundation.md`
- Updated foundation document for sevenos project
- Integrates Bhakti devotion and Berdyaev's creative freedom
- Emphasizes service to vegan activists, first responders, mentors, MMT proposers
- References Basin Kernel, RISC-V VM Runtime, Vantage, Framework Ubuntu x86

**MMT Job Guarantee Housing Program**:
- `docs/zyx/2026-01-03-043815-pst_grainbank_mmt_job_guarantee_housing_program_sevenos.md`
- Updated MMT JG program design for sevenos foundation
- Emphasizes bottom-up sequential development (Steps 1-4)
- Shows how foundation enables modules, modules enable program
- Connects to target users and sevenos technical stack

**Project Philosophy Audiobook**:
- `docs/2026-01-03-042621-pst_grain_os_project_philosophy_audiobook.md`
- Text-to-speech audiobook-friendly narration
- Uses only 10000 most common English words
- Describes project and philosophy from scratch
- Emphasizes goal to help vegan activists, first responders, mentors, MMT proposers

**When to Use**: Reference for understanding the deeper purpose and vision of Grain OS sevenos, and how the foundation enables the MMT JG program.

---

## Documentation Structure by Purpose

### Coordination Documents

**Location**: `docs/core-coordination/`

**Purpose**: Agent-specific coordination status and integration points

**Key Files**:
- `2026-01-03-042621-pst_core_1_subcore_coordination_plan.md` - Latest coordination plan (timestamp prefix format)
- `core_1{X}_{agent}_coordination.md` - L2 sub-agent coordination (where X is a/b/c/d/e)
- `vantage_3{X}_{agent}_coordination.md` - Vantage 3 L2 sub-agent coordination
- `aurora_2{X}_{agent}_coordination.md` - Aurora 2 L2 sub-agent coordination
- Note: New coordination documents use timestamp prefix format

**When to Use**: 
- Update your coordination document after each work session
- Read other agents' coordination documents for integration points
- Check latest coordination plan for current priorities

### Agent Communication Documents

**Location**: `docs/agent-communications/`

**Purpose**: Multi-agent prompts, voice guidelines, and coordination summaries

**Key Files**:
- `2026-01-03-042621-pst_core_1_subcore_coordination_summary.md` - Latest coordination summary (timestamp prefix format)
- `glow_g2_voice_multi_agent_prompt_*.md` - Voice adoption guide
- `timestamp_specification_multi_agent_prompt_*.md` - Timestamp requirements (includes new prefix format)
- `{agent}_glow_g2_voice_adoption_*.md` - Agent voice adoption acknowledgments
- Note: New communication documents use timestamp prefix format

**When to Use**:
- Reference for voice consistency
- Check for latest coordination instructions
- Find timestamp format requirements

### Plan and Task Documents

**Location**: `docs/plans/` and `docs/tasks/`

**Purpose**: Long-term planning and task tracking

**Key Files**:
- `docs/plans/{agent}_plan.md` - Agent-specific plans
- `docs/tasks/{agent}_tasks.md` - Agent-specific tasks
- `docs/plan.md` - General project plan
- `docs/tasks.md` - General project tasks

**When to Use**:
- Update plan documents as implementation evolves
- Update task documents as tasks are completed
- Reference for long-term project context

### Agent Prompt Documents

**Location**: `docs/` (root level)

**Purpose**: Agent-specific prompts and guidelines

**Key Files**:
- `docs/grain_{agent}_agent_prompt.md` - Agent-specific prompts
- `docs/grain_{agent}_agent_prompt.md` - L2 sub-agent prompts (if exists)

**When to Use**: Reference for agent-specific guidelines and responsibilities.

### Kernel Documentation

**Location**: `docs/kernel/`

**Purpose**: Basin Kernel syscall interface documentation

**Key Files**:
- `docs/kernel/syscall_interface_reference.md` - Complete reference for all 140 syscalls
- `docs/kernel/syscall_interface_for_jit.md` - JIT-specific guide (for VM Runtime 3b)
- `docs/kernel/syscall_interface_for_init.md` - Init System-specific guide (for Init System 3d)

**When to Use**: Reference when implementing JIT compilation or Init System integration with Basin Kernel.

---

## Quick Navigation by Agent Role

### L1 Subcore Coordinators (Agent 1, 2, 3)

**Start Here**:
1. Latest coordination plan: `docs/core-coordination/2026-01-03-042621-pst_core_1_subcore_coordination_plan.md`
2. Latest coordination summary: `docs/agent-communications/2026-01-03-042621-pst_core_1_subcore_coordination_summary.md`
3. Glow G2 voice guide: `docs/agent-communications/glow_g2_voice_multi_agent_prompt_*.md`

**Your Coordination Documents**:
- `docs/core-coordination/{subcore}_coordination.md` - Your coordination status
- `docs/plans/{subcore}_plan.md` - Your planning documents
- `docs/tasks/{subcore}_tasks.md` - Your task tracking

**When Coordinating**:
- Read L2 sub-agent coordination documents weekly/bi-weekly
- Update coordination plan as priorities evolve
- Coordinate with other L1 subcores through Core 1 Subcore

### L2 Sub-Agents (1a-1e, 2a-2c, 3a-3d)

**Start Here**:
1. Latest coordination summary: `docs/agent-communications/2026-01-03-042621-pst_core_1_subcore_coordination_summary.md`
2. Your agent-specific section in the coordination summary
3. Glow G2 voice guide: `docs/agent-communications/glow_g2_voice_multi_agent_prompt_*.md`

**Your Coordination Documents**:
- `docs/core-coordination/{parent}_{agent}_coordination.md` - Your coordination status
- `docs/plans/{parent}_{agent}_plan.md` - Your planning documents
- `docs/tasks/{parent}_{agent}_tasks.md` - Your task tracking

**When Working**:
- Update your coordination document after each work session
- Check in with parent L1 subcore before integration steps
- Reference Grain Style guidelines: `docs/grain_style.md`

### L1 Standalone Agents (4-12)

**Start Here**:
1. Latest coordination summary: `docs/agent-communications/2026-01-03-042621-pst_core_1_subcore_coordination_summary.md`
2. Glow G2 voice guide: `docs/agent-communications/glow_g2_voice_multi_agent_prompt_*.md`
3. Your agent prompt: `docs/grain_{agent}_agent_prompt.md`

**Your Coordination Documents**:
- `docs/core-coordination/{agent}_coordination.md` - Your coordination status
- `docs/plans/{agent}_plan.md` - Your planning documents
- `docs/tasks/{agent}_tasks.md` - Your task tracking

**When Working**:
- Coordinate through Core 1 Subcore as needed
- Update your documentation as implementation evolves
- Check in before integration steps with other agents

---

## Common Navigation Scenarios

### "I need to know my current priorities"

1. Read latest coordination summary: `docs/agent-communications/2026-01-03-042621-pst_core_1_subcore_coordination_summary.md`
2. Find your agent-specific section
3. Review "Immediate Next Steps" and "Current Blocker" sections
4. Check single-threaded computation priority chain for critical path dependencies
5. Review critical path status: Step 1 ✅ COMPLETE, Step 2 ⏳ IN PROGRESS, Step 3 ⏳ READY TO PROCEED, Step 4 ⏳ BLOCKED

### "I need to coordinate with another agent"

1. Check latest coordination plan: `docs/core-coordination/2026-01-03-042621-pst_core_1_subcore_coordination_plan.md`
2. Review "Integration Priorities" section
3. Read the other agent's coordination document: `docs/core-coordination/{agent}_coordination.md`
4. Check in with Core 1 Subcore (or your parent L1 subcore) before starting integration
5. Review critical path dependencies if coordinating with Basin Kernel (3a), VM Runtime (3b), Init System (3d), or Grainscript Shell (1e)

### "I need to update my documentation"

1. Update your coordination document: `docs/core-coordination/{agent}_coordination.md`
2. Update your plan document: `docs/plans/{agent}_plan.md`
3. Update your tasks document: `docs/tasks/{agent}_tasks.md`
4. Inform Core 1 Subcore of updates needed for general documentation

### "I need to adopt Glow G2 voice"

1. Read voice guide: `docs/agent-communications/glow_g2_voice_multi_agent_prompt_*.md`
2. Review source definition: `docs/zyx/glow_g2.md`
3. Create adoption acknowledgment: `docs/agent-communications/{agent}_glow_g2_voice_adoption_*.md`
4. Apply voice to all future communications

### "I need to create a timestamped document"

1. Generate timestamp: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
2. **Use NEW format (REQUIRED)**: `YYYY-MM-DD-HHMMSS-pst_document_name.md` (timestamp prefix)
3. **OLD format (historical only)**: `document_name_YYYY-MM-DD-HHMMSS-pst.md` (timestamp suffix)
4. Reference: `docs/agent-communications/timestamp_specification_multi_agent_prompt_*.md`
5. **Benefits**: Automatic chronological sorting in file listings (Codeberg, file browsers)

### "I need to understand the critical path"

1. Read latest coordination summary: `docs/agent-communications/2026-01-03-042621-pst_core_1_subcore_coordination_summary.md`
2. Review "Single-Threaded Computation Priority Chain" section
3. Check critical path quick reference: `docs/agent-communications/critical_path_quick_reference_*.md`
4. Use blocker tracking template if reporting blockers
5. **Current Status**: Step 1 (Basin Kernel 3a) ✅ COMPLETE, Step 2 (VM Runtime 3b) ⏳ IN PROGRESS, Step 3 (Init System 3d) ⏳ READY TO PROCEED, Step 4 (Grainscript Shell 1e) ⏳ BLOCKED ON STEP 3

---

## Documentation Best Practices

### When Creating Documents

1. **Use Timestamps**: Always include timestamp in filename and header
2. **Use Timestamp Prefix Format**: `YYYY-MM-DD-HHMMSS-pst_document_name.md` (required for all new documents)
3. **Use Glow G2 Voice**: Maintain calm, helpful, solution-focused tone
4. **Be Succinct**: Complete but concise
5. **Include Context**: Reference related documents and coordination points
6. **Reference sevenos Foundation**: When relevant, reference Basin Kernel, RISC-V VM Runtime, Vantage, Framework Ubuntu x86

### When Updating Documents

1. **Update After Work Sessions**: Keep coordination documents current
2. **Update Plans as Implementation Evolves**: Plans should reflect reality
3. **Update Tasks as Completed**: Mark tasks complete with timestamps
4. **Inform Core 1 Subcore**: Share updates needed for general documentation

### When Reading Documents

1. **Start with Latest**: Always check for most recent timestamp
2. **Read Agent-Specific Sections**: Focus on your agent's instructions
3. **Check Integration Points**: Review integration priorities and blockers
4. **Reference Source Documents**: Use source documents for detailed guidance

---

## Finding Documents by Timestamp

**NEW FORMAT (REQUIRED)**: `YYYY-MM-DD-HHMMSS-pst_document_name.md` (timestamp prefix)
- **Benefits**: Automatic chronological sorting in file listings (Codeberg, file browsers)
- **Example**: `2026-01-03-042621-pst_core_1_subcore_coordination_plan.md`

**OLD FORMAT (HISTORICAL)**: `document_name_YYYY-MM-DD-HHMMSS-pst.md` (timestamp suffix)
- **Example**: `core_1_subcore_coordination_plan_2026-01-02-010910-pst.md`

**Latest Documents**: Look for highest timestamp value (prefix format sorts automatically)

**Quick Find**: Sort files by modification date or search for latest timestamp pattern. Prefix format files will sort chronologically by default.

---

## Getting Help

### Documentation Questions

If you need help finding documentation:
1. Check this navigation guide first
2. Review latest coordination summary for context
3. Check Core 1 Subcore coordination plan for current priorities
4. Contact Core 1 Subcore for coordination support

### Coordination Questions

If you need coordination help:
1. Check latest coordination plan for integration priorities
2. Read relevant agent coordination documents
3. Check in with Core 1 Subcore (or your parent L1 subcore)
4. Review integration check-in requirements in coordination summary

---

## Summary

**Quick Start**:
1. Read latest coordination summary for current priorities
2. Find your agent-specific section
3. Review Glow G2 voice guide for communication style
4. Update your coordination documents as you work

**Key Locations**:
- Coordination: `docs/core-coordination/` (new documents use timestamp prefix format)
- Communications: `docs/agent-communications/` (new documents use timestamp prefix format)
- Plans: `docs/plans/`
- Tasks: `docs/tasks/`
- Kernel: `docs/kernel/`
- Core Guidelines: `docs/grain_style.md`, `docs/don_juan_matus_warriors_way.md`
- sevenos Foundation: `docs/zyx/` (spiritual foundation, MMT JG program, audiobook narration)

**Remember**:
- Always use timestamps in document filenames (timestamp prefix format required for new documents)
- Maintain Glow G2 voice in all communications
- Follow Grain Style strictly in all code
- Update coordination documents after work sessions
- Check in before integration steps
- Understand critical path dependencies (Steps 1-4: Basin Kernel → VM Runtime → Init System → Shell)

---

**Date**: 2026-01-03-044110-pst  
**Last Updated**: 2026-01-03-044110-pst  
**Status**: ✅ **NAVIGATION GUIDE COMPLETE** — Ready for use by all agents and developers  
**Context**: Grain OS sevenos — Basin Kernel syscall → RISC-V → Vantage pipeline for Framework Ubuntu x86

