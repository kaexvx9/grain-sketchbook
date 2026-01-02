# Documentation Navigation Guide for All Agents

**Date**: 2026-01-01-235538-pst  
**Agent**: Free 12 (Coordination and Documentation Support, Core 1 Subcore)  
**Status**: ✅ **NAVIGATION GUIDE READY** — Quick reference for all agents

---

## Purpose

This guide helps agents quickly find the coordination and communication documents they need. The documentation structure is intricate, but we can navigate it systematically.

**Quick Navigation**:
- **Current Priorities**: See latest coordination plan and summary
- **Agent-Specific Instructions**: Find your agent section
- **Voice Guidelines**: Adopt Glow G2 voice consistently
- **Coordination Patterns**: Understand coordination workflows

---

## Most Important Documents (Start Here)

### 1. Current Coordination Plan and Summary

**Latest Coordination Plan**:
- `docs/core-coordination/core_1_subcore_coordination_plan_2026-01-01-233240-pst.md`
- Contains current agent statuses, priorities, and next steps
- Updated by Core 1 Subcore with latest coordination information

**Latest Coordination Summary**:
- `docs/agent-communications/core_1_subcore_coordination_summary_2026-01-01-233240-pst.md`
- Copy-paste ready instructions for all agents
- Agent-specific sections with immediate next steps

**When to Use**: Start here for current priorities and agent-specific instructions.

### 2. Glow G2 Voice Guidelines

**Multi-Agent Voice Prompt**:
- `docs/agent-communications/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md`
- Comprehensive voice adoption guide
- Examples and verification checklist

**Source Voice Definition**:
- `docs/zyx/glow_g2.md`
- Core voice characteristics and directives

**When to Use**: Reference when writing communications, documentation, or code comments.

### 3. Timestamp Specification

**Multi-Agent Timestamp Prompt**:
- `docs/agent-communications/timestamp_specification_multi_agent_prompt_2026-01-01-215553-pst.md`
- Format: `yyyy-mm-dd-hhmmss-pst`
- Command: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`

**When to Use**: When creating documents, filenames, or git commits.

---

## Documentation Structure by Purpose

### Coordination Documents

**Location**: `docs/core-coordination/`

**Purpose**: Agent-specific coordination status and integration points

**Key Files**:
- `core_1_subcore_coordination_plan_*.md` - Latest coordination plan
- `core_1{X}_{agent}_coordination.md` - L2 sub-agent coordination (where X is a/b/c/d/e)
- `vantage_3{X}_{agent}_coordination.md` - Vantage 3 L2 sub-agent coordination

**When to Use**: 
- Update your coordination document after each work session
- Read other agents' coordination documents for integration points
- Check latest coordination plan for current priorities

### Agent Communication Documents

**Location**: `docs/agent-communications/`

**Purpose**: Multi-agent prompts, voice guidelines, and coordination summaries

**Key Files**:
- `core_1_subcore_coordination_summary_*.md` - Latest coordination summary
- `glow_g2_voice_multi_agent_prompt_*.md` - Voice adoption guide
- `timestamp_specification_multi_agent_prompt_*.md` - Timestamp requirements
- `{agent}_glow_g2_voice_adoption_*.md` - Agent voice adoption acknowledgments

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

---

## Quick Navigation by Agent Role

### L1 Subcore Coordinators (Agent 1, 2, 3)

**Start Here**:
1. Latest coordination plan: `docs/core-coordination/core_1_subcore_coordination_plan_*.md`
2. Latest coordination summary: `docs/agent-communications/core_1_subcore_coordination_summary_*.md`
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
1. Latest coordination summary: `docs/agent-communications/core_1_subcore_coordination_summary_*.md`
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
1. Latest coordination summary: `docs/agent-communications/core_1_subcore_coordination_summary_*.md`
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

1. Read latest coordination summary: `docs/agent-communications/core_1_subcore_coordination_summary_*.md`
2. Find your agent-specific section
3. Review "Immediate Next Steps" and "Current Blocker" sections

### "I need to coordinate with another agent"

1. Check latest coordination plan: `docs/core-coordination/core_1_subcore_coordination_plan_*.md`
2. Review "Integration Priorities" section
3. Read the other agent's coordination document: `docs/core-coordination/{agent}_coordination.md`
4. Check in with Core 1 Subcore (or your parent L1 subcore) before starting integration

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
2. Use format: `yyyy-mm-dd-hhmmss-pst`
3. Include in filename: `{document_name}_{timestamp}.md`
4. Reference: `docs/agent-communications/timestamp_specification_multi_agent_prompt_*.md`

---

## Documentation Best Practices

### When Creating Documents

1. **Use Timestamps**: Always include timestamp in filename and header
2. **Use Glow G2 Voice**: Maintain calm, helpful, solution-focused tone
3. **Be Succinct**: Complete but concise
4. **Include Context**: Reference related documents and coordination points

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

**Pattern**: Documents are timestamped with format `yyyy-mm-dd-hhmmss-pst`

**Latest Documents**: Look for highest timestamp value

**Example**:
- `core_1_subcore_coordination_plan_2026-01-01-233240-pst.md` (newer)
- `core_1_subcore_coordination_plan_2026-01-01-210806-pst.md` (older)

**Quick Find**: Sort files by modification date or search for latest timestamp pattern.

---

## Getting Help

### Documentation Questions

If you need help finding documentation:
1. Check this navigation guide first
2. Review latest coordination summary for context
3. Check Core 1 Subcore coordination plan for current priorities
4. Contact Free 12 (documentation support) if needed

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
- Coordination: `docs/core-coordination/`
- Communications: `docs/agent-communications/`
- Plans: `docs/plans/`
- Tasks: `docs/tasks/`

**Remember**:
- Always use timestamps in document filenames
- Maintain Glow G2 voice in all communications
- Update coordination documents after work sessions
- Check in before integration steps

---

**Date**: 2026-01-01-235538-pst  
**Agent**: Free 12 (Coordination and Documentation Support, Core 1 Subcore)  
**Status**: ✅ **NAVIGATION GUIDE COMPLETE** — Ready for agent use

