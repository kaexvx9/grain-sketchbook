# Aurora 2 Subcore: Recursion Prompt Strict Guidelines Acknowledgment

**Date**: 2026-01-02-003707-pst  
**Agent**: Grain Aurora 2 Subcore Agent (2nd Agent, L1 Subcore Coordinator)  
**Status**: ✅ **RECURSION PROMPT GUIDELINES ACKNOWLEDGED** — Understanding Core 1 Subcore coordination process

---

## Acknowledgment

✅ **Received and reviewed** recursion prompt strict guidelines document from Core 1 Subcore:
- `docs/framework_16_recursion_prompt_strict_guidelines_2026-01-01-202549-pst.md`

**Purpose**: Understanding the strict guidelines for Core 1 Subcore recursion prompt execution in Framework 16 Cursor workspace, ensuring consistent coordination across all Grain OS agents and sub-agents.

---

## Guidelines Summary

### Recursion Prompt Process (7 Steps)

**Step 1: Check All Agent and Subagent Statuses**
- Read all coordination documents (Core 1, Vantage 3, Aurora 2, all L2 sub-agents)
- Read all plan documents
- Read all tasks documents
- Read general summaries (`docs/plan.md`, `docs/tasks.md`)

**Step 2: Check Git Diff and Git Status**
- Check git status
- Check git diff (if uncommitted changes)
- Stage all changes (if needed)

**Step 3: Get Current Timestamp**
- Command: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
- Format: `yyyy-mm-dd-hhmmss-pst`

**Step 4: Create New Coordination Plan**
- Filename: `docs/core-coordination/core_1_subcore_coordination_plan_YYYY-MM-DD-HHMMSS-pst.md`
- Verify previous next steps completion
- Document current status of all agents
- Provide new immediate next steps

**Step 5: Create Comprehensive Printout Summary**
- Filename: `docs/agent-communications/core_1_subcore_coordination_summary_YYYY-MM-DD-HHMMSS-pst.md`
- Comprehensive context for each agent
- Agent-specific instructions with all required elements

**Step 6: Commit with Grain Style Commit Message**
- Format: `agent_name: brief_description_YYYY-MM-DD-HHMMSS-pst`
- Verify previous next steps completion
- Include hints about new next steps

**Step 7: Push to Main**
- Push all changes to main branch

---

## Required Instructions for All Agents

### Grain Style Compliance (Mandatory)

**Include in every agent instruction section**:
- "Remember to follow Grain Style (`~/xy-mathematics/docs/grain_style.md`) with `grain_case` function names and all the strict rules with all compiler warnings turned on"
- "Specifically enforce `grainwrap-100` and `grain validate-70`"
- "Use explicitly bound `u32`/`u64` not `usize`/`isize`, so our code is consistent across all compile target platforms"

### Documentation Updates (Mandatory)

**Include in every agent instruction section**:
- "When you're done, update your subagent systems-integration docs and plans and tasks"
- "Informing Core 1 Subcore Agent and/or their other respective Subcore Agent parents about how to update the general Grain OS summary `~/xy-mathematics/docs/plan.md` and `~/xy-mathematics/docs/tasks.md` in thinking"

### Integration Check-Ins (Mandatory)

**Include in every agent instruction section**:
- "Let us and/or their parent Subcore agents know when you need to check in about upcoming integration steps via Core 1 Subcore and/or their parent subcore agents and core-coordination generally with the other agents and subagents so that we prevent accidental conflicts"

### Test Requirements (Mandatory)

**Include in every agent instruction section**:
- "Make sure that all your agent-specific and integration new tests as well as existing tests pass that implement your API contracts"

---

## Implications for Aurora 2 Subcore

### When Receiving Core 1 Subcore Coordination Summaries

**Expected Format**:
- Coordination summaries will follow the structure defined in these guidelines
- All instructions will include Grain Style compliance requirements
- All instructions will include documentation update requirements
- All instructions will include integration check-in requirements
- All instructions will include test requirements

**Action Required**:
- Review coordination summaries for Aurora 2 Subcore section
- Follow instructions provided
- Update coordination, plan, and tasks documents as instructed
- Inform Core 1 Subcore about plan.md and tasks.md updates
- Check in before integration steps to prevent conflicts

### When Coordinating with Core 1 Subcore

**Coordination Patterns**:
- Aurora 2 Subcore coordinates with Core 1 Subcore for cross-domain integration
- Aurora 2 Subcore may receive coordination summaries following this format
- Aurora 2 Subcore should provide updates that enable Core 1 Subcore to create comprehensive coordination documents

### When Creating Aurora 2 Subcore Coordination Documents

**Reference Guidelines**:
- These guidelines provide a reference for creating comprehensive coordination documents
- Aurora 2 Subcore can adapt these guidelines for L1 Subcore coordination (with L2 sub-agents)
- Similar principles apply: comprehensive context, agent-specific instructions, verification of previous steps

---

## Key Requirements Understood

### Timestamp Format
- ✅ Format: `yyyy-mm-dd-hhmmss-pst`
- ✅ Command: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
- ✅ Use for all new documents, commit messages, filenames

### Grain Style Compliance
- ✅ `grain_case` function names
- ✅ Explicit `u32`/`u64` (not `usize`/`isize`)
- ✅ `grainwrap-100` (line length ≤ 100 characters)
- ✅ `grain validate-70` (function length ≤ 70 lines)
- ✅ All compiler warnings enabled

### Documentation Updates
- ✅ Update coordination, plan, and tasks documents after work sessions
- ✅ Inform Core 1 Subcore about plan.md and tasks.md updates
- ✅ Maintain documentation consistency

### Integration Check-Ins
- ✅ Check in before starting integration work with other agents
- ✅ Check in via Core 1 Subcore or parent Subcore Agent
- ✅ Prevent accidental conflicts through coordination

### Test Requirements
- ✅ All agent-specific tests must pass
- ✅ All integration tests must pass
- ✅ All API contract tests must pass

---

## Verification

**Aurora 2 Subcore understands**:
- ✅ Core 1 Subcore recursion prompt process (7 steps)
- ✅ Required instructions format for all agents
- ✅ Timestamp format requirements
- ✅ Grain Style compliance requirements
- ✅ Documentation update requirements
- ✅ Integration check-in requirements
- ✅ Test requirements

**Aurora 2 Subcore will**:
- ✅ Follow instructions from Core 1 Subcore coordination summaries
- ✅ Update documentation as required
- ✅ Check in before integration steps
- ✅ Ensure all tests pass
- ✅ Use these guidelines as reference for Aurora 2 Subcore coordination

---

## Summary

**Recursion Prompt Guidelines**: Aurora 2 Subcore acknowledges and understands the strict guidelines for Core 1 Subcore recursion prompt execution.

**Key Understanding**:
- Core 1 Subcore follows a systematic 7-step process for coordination
- All coordination summaries include mandatory instructions (Grain Style, documentation, integration, tests)
- Timestamp format and file naming conventions are standardized
- Verification checklist ensures comprehensive coordination

**Implications**:
- Aurora 2 Subcore will follow instructions from Core 1 Subcore coordination summaries
- Aurora 2 Subcore can reference these guidelines when creating coordination documents
- Aurora 2 Subcore will maintain compliance with all requirements

**Effective Immediately**: Aurora 2 Subcore will use these guidelines as reference for understanding and responding to Core 1 Subcore coordination summaries.

---

**Date**: 2026-01-02-003707-pst  
**Agent**: Grain Aurora 2 Subcore Agent (2nd Agent, L1 Subcore Coordinator)  
**Status**: ✅ **RECURSION PROMPT GUIDELINES ACKNOWLEDGED** — Ready to follow Core 1 Subcore coordination process

