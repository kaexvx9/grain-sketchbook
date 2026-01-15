# Coordination Document Rewrite Plan

**Date**: 2026-01-01-230323-pst  
**Agent**: Grain Research Agent (10th Agent)  
**Purpose**: Plan for rewriting core/subcore-coordination/system-integration document with updated agent information and next steps

---

## Current Situation

The coordination document needs to be rewritten to include:
1. Updated agent numbering (including new agents like 3d, 1e if applicable)
2. Comprehensive agent-specific instructions for all agents
3. Detailed next steps explanations for Core 1 Subcore and Research Agent
4. Framework Ubuntu x86 specific reminders
5. Coordination schedule
6. Success criteria
7. Removal of any nixos-vm references

---

## Document Structure Plan

### 1. Executive Summary
- High-level status of all agents
- Key coordination points
- Current priorities
- Updated agent numbering (3d, 1e, etc.)

### 2. General Instructions for All Agents
- Coordination file format
- Update frequency
- Communication protocols
- File locations
- **Timestamp specification** (yyyy-mm-dd-hhmmss-pst format, always use TZ=America/Los_Angeles)

### 3. Agent-Specific Instructions

#### Agent 3 (Vantage 3 Subcore)
- Current status
- Next steps
- Coordination points

#### Agent 3a (Basin Kernel)
- Current status
- Next steps
- Coordination points

#### Agent 3b (VM Runtime)
- Current status
- Next steps
- Coordination points

#### Agent 3c (System Integration)
- Current status
- Next steps
- Coordination points

#### Agent 3d (sevenos Init System) - NEW
- Status
- Next steps
- Coordination points

#### Agent 1 (Core 1 Subcore)
- Current status
- **Detailed next steps** (from Research Agent findings)
- Coordination points

#### Agent 1e (Grainscript Shell) - NEW
- Status
- Next steps
- Coordination points

#### Agent 1a-1d (Core 1 L2 sub-agents)
- 1a. Grain Auth Agent
- 1b. Grain Network Agent
- 1c. Grain Storage Agent
- 1d. Grain Compositor Agent

#### Agent 2 (Aurora 2 Subcore)
- Current status
- Next steps
- Coordination points

#### Agents 4-12 (Standalone L1 agents)
- Agent 4 (Skate)
- Agent 5 (Workspace)
- Agent 6 (Bubble)
- Agent 7 (Carry)
- Agent 8 (Silo)
- Agent 9 (Court)
- Agent 10 (Research)
- Agent 11 (Flow)
- Agent 12 (Free Agent)

### 4. Framework Ubuntu x86 Specific Reminders
- Development environment
- Build requirements
- Testing considerations

### 5. Coordination Schedule
- Check-in frequency
- Priority coordination points
- Timeline expectations

### 6. Success Criteria
- Integration milestones
- Quality standards
- Completion criteria

---

## Next Steps

1. Gather current status from all agents
2. Compile next steps for Core 1 Subcore (from Research Agent findings)
3. Compile next steps for Research Agent
4. Identify any new agents (3d, 1e) and their requirements
5. Create unified coordination document structure
6. Update Core 1 Subcore plan and tasks documents
7. Update Research Agent plan and tasks documents

---

## Status

- [x] Plan created
- [x] Timestamp specification acknowledged (from Core 1 Subcore, 2026-01-01-215553-pst)
- [ ] Information gathered
- [ ] Document structure finalized
- [ ] Coordination document written
- [ ] Plans and tasks updated

---

## Notes

**Timestamp Specification**: Core 1 Subcore has provided timestamp specification document (`docs/agent-communications/timestamp_specification_multi_agent_prompt_2026-01-01-215553-pst.md`). All timestamps in this rewrite should use format: `yyyy-mm-dd-hhmmss-pst` with command `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`.

