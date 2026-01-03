# Pre-Work Session Checklist for All Agents

**Date**: 2026-01-02-090326-pst  
**Agent**: Free 12 (Coordination and Documentation Support, Core 1 Subcore)  
**Status**: ✅ **CHECKLIST READY** — Use before starting work sessions

---

## Purpose

This checklist helps agents prepare effectively before starting a work session. Completing this checklist ensures you have the context, tools, and coordination awareness needed for productive work.

---

## Pre-Work Session Checklist

### 1. Context Review (5 minutes)

**Latest Coordination Documents**:
- [ ] Read latest coordination summary: `docs/agent-communications/core_1_subcore_coordination_summary_2026-01-02-083246-pst.md`
- [ ] Review your agent-specific section
- [ ] Check for new priorities or blockers
- [ ] Review critical path status if you're in the critical path

**Agent Awareness**:
- [ ] Review complete agent awareness: `docs/agent-communications/complete_agent_awareness_all_agents_2026-01-02-002948-pst.md`
- [ ] Understand current status of other agents
- [ ] Identify potential integration points

**Critical Path Awareness** (if in critical path):
- [ ] Review critical path quick reference: `docs/agent-communications/critical_path_quick_reference_2026-01-02-084259-pst.md`
- [ ] Understand your step and dependencies
- [ ] Check current blocker status
- [ ] Review handoff requirements if completing a step

---

### 2. Documentation Review (5 minutes)

**Your Documentation**:
- [ ] Review your coordination document: `docs/core-coordination/{agent}_coordination.md`
- [ ] Review your plan document: `docs/plans/{agent}_plan.md`
- [ ] Review your tasks document: `docs/tasks/{agent}_tasks.md`
- [ ] Note what you completed last session
- [ ] Note what you planned for this session

**Related Documentation**:
- [ ] Review integration partner coordination docs (if integrating)
- [ ] Review parent Subcore coordination doc (if L2 sub-agent)
- [ ] Check for new documentation updates

---

### 3. Requirements Check (3 minutes)

**Grain Style Requirements**:
- [ ] Review Grain Style: `docs/grain_style.md`
- [ ] Verify `grainwrap-100` compliance needed
- [ ] Verify `grain validate-70` compliance needed
- [ ] Remember explicit `u32`/`u64` types (no `usize`/`isize`)

**Voice Requirements**:
- [ ] Review Glow G2 voice: `docs/agent-communications/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md`
- [ ] Remember to use Glow G2 voice in communications

**Timestamp Requirements**:
- [ ] Remember timestamp format: `yyyy-mm-dd-hhmmss-pst`
- [ ] Command ready: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`

---

### 4. Coordination Check (5 minutes)

**Integration Check-Ins**:
- [ ] Check if you need to coordinate before starting work
- [ ] Review integration check-in requirements
- [ ] Identify any coordination needs
- [ ] Check in with parent Subcore if needed

**Blockers Check**:
- [ ] Review current blockers (yours and others')
- [ ] Check if any blockers are resolved
- [ ] Identify new blockers if any
- [ ] Report blockers immediately if found

**Dependencies Check**:
- [ ] Verify your dependencies are met
- [ ] Check if you're blocking others
- [ ] Understand dependency timeline
- [ ] Plan work accordingly

---

### 5. Work Session Planning (5 minutes)

**Session Goals**:
- [ ] Define clear goals for this session
- [ ] Prioritize tasks (P0, P1, P2, P3)
- [ ] Estimate session duration
- [ ] Set realistic expectations

**Task Breakdown**:
- [ ] Break down work into manageable tasks
- [ ] Identify first task to start
- [ ] Prepare necessary tools and context
- [ ] Clear any distractions

**Success Criteria**:
- [ ] Define what "done" looks like for this session
- [ ] Set completion criteria
- [ ] Plan for documentation updates

---

### 6. Tools and Resources (2 minutes)

**Documentation Tools**:
- [ ] Navigation guide bookmarked: `docs/agent-communications/documentation_navigation_guide_2026-01-01-235538-pst.md`
- [ ] Critical path tools accessible (if in critical path)
- [ ] Templates ready (status update, blocker tracking, etc.)

**Code Tools**:
- [ ] Code editor ready
- [ ] Build system ready
- [ ] Test framework ready
- [ ] Grain Style tools ready (`grainwrap-100`, `grain validate-70`)

**Communication Tools**:
- [ ] Coordination channels accessible
- [ ] Status update template ready
- [ ] Blocker reporting template ready (if needed)

---

## Critical Path Specific Checklist

**If you're in the critical path (3a, 3b, 3d, 1e, 3c)**:

**Step Awareness**:
- [ ] Know which step you're on (1, 2, 3, 4, or 5)
- [ ] Understand what you're waiting for (dependencies)
- [ ] Understand what you're blocking (downstream steps)
- [ ] Review step-specific requirements

**Status Preparation**:
- [ ] Prepare status update using template
- [ ] Identify blockers if any
- [ ] Prepare handoff if completing step
- [ ] Review handoff checklist if needed

**Coordination Preparation**:
- [ ] Review coordination meeting agenda if meeting scheduled
- [ ] Prepare status for coordination meeting
- [ ] Identify coordination needs

---

## Post-Work Session Checklist

**After completing work session**:

**Documentation Updates**:
- [ ] Update coordination document with progress
- [ ] Update plan document if implementation evolved
- [ ] Update tasks document with completed tasks
- [ ] Include timestamp in all updates

**Status Reporting**:
- [ ] Provide status update if needed
- [ ] Report blockers immediately
- [ ] Report completion if step finished
- [ ] Check in with parent Subcore if needed

**Quality Check**:
- [ ] Verify Grain Style compliance
- [ ] Verify tests passing
- [ ] Verify documentation updated
- [ ] Verify Glow G2 voice in communications

---

## Quick Reference

**Before Starting Work**:
1. Review latest coordination summary
2. Check your documentation status
3. Verify requirements (Grain Style, voice, timestamps)
4. Check coordination needs
5. Plan session goals

**During Work**:
- Follow Grain Style strictly
- Use Glow G2 voice
- Report blockers immediately
- Check in before integration

**After Work**:
- Update documentation
- Report status
- Check in if needed

---

## Common Mistakes to Avoid

**Before Work**:
- ❌ Starting without reviewing latest coordination
- ❌ Not checking for blockers
- ❌ Not understanding dependencies
- ❌ Not preparing status update

**During Work**:
- ❌ Not following Grain Style
- ❌ Not using Glow G2 voice
- ❌ Not reporting blockers
- ❌ Not checking in before integration

**After Work**:
- ❌ Not updating documentation
- ❌ Not reporting status
- ❌ Not including timestamps
- ❌ Not checking in when needed

---

## Success Indicators

**Well-Prepared Session When**:
- ✅ You understand current priorities
- ✅ You know your dependencies and blockers
- ✅ You have clear session goals
- ✅ You have necessary tools ready
- ✅ You're ready to work effectively

**Productive Session When**:
- ✅ You complete planned work
- ✅ You follow all requirements
- ✅ You update documentation
- ✅ You report status appropriately
- ✅ You coordinate effectively

---

**Date**: 2026-01-02-090326-pst  
**Agent**: Free 12 (Coordination and Documentation Support, Core 1 Subcore)  
**Status**: ✅ **PRE-WORK SESSION CHECKLIST COMPLETE** — Ready for agent use

