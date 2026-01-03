# Aurora 2 Subcore: Documentation Setup Prompt for All Agents and Sub-Agents

**Date**: 2026-01-02-000032-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Status**: ✅ **DOCUMENTATION SETUP PROMPT READY** — Copy-paste ready for Aurora 2 Subcore and all L2 sub-agents

---

## Instructions for Aurora 2 Subcore and All L2 Sub-Agents

**This document provides comprehensive instructions for setting up proper documentation structure for Aurora 2 Subcore and all L2 sub-agents (2a, 2b, 2c). Each agent should:**

1. **Read this document completely** to understand documentation requirements
2. **Create or update missing documentation** following the structure below
3. **Follow Grain Style** (`~/xy-mathematics/docs/grain_style.md`) strictly
4. **Adopt Glow G2 voice** in all documentation (see `docs/agent-communications/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md`)
5. **Use correct file naming** following the established pattern

---

## Documentation Structure Requirements

### Standard Documentation Files

Each agent must have **three core documents**:

1. **Coordination Document**: `docs/core-coordination/{agent}_coordination.md`
2. **Plan Document**: `docs/plans/{agent}_plan.md`
3. **Tasks Document**: `docs/tasks/{agent}_tasks.md`

### File Naming Pattern

**Aurora 2 Subcore (L1)**:
- Coordination: `docs/core-coordination/aurora_2_subcore_coordination.md` ✅ (exists)
- Plan: `docs/plans/aurora_2_subcore_plan.md` ⚠️ (needs to be created - currently has legacy `docs/plans/plan_aurora.md`)
- Tasks: `docs/tasks/aurora_2_subcore_tasks.md` ⚠️ (needs to be created - currently has legacy `docs/tasks/tasks_aurora.md`)

**Aurora 2a Dream Editor (L2)**:
- Coordination: `docs/core-coordination/aurora_2a_dream_editor_coordination.md` ✅ (exists)
- Plan: `docs/plans/aurora_2a_dream_editor_plan.md` ⚠️ (needs to be created - currently has legacy `docs/plans/plan_dream_editor.md`)
- Tasks: `docs/tasks/aurora_2a_dream_editor_tasks.md` ⚠️ (needs to be created - currently has legacy `docs/tasks/tasks_dream_editor.md`)

**Aurora 2b Dream Browser (L2)**:
- Coordination: `docs/core-coordination/aurora_2b_dream_browser_coordination.md` ✅ (exists)
- Plan: `docs/plans/aurora_2b_dream_browser_plan.md` ✅ (exists - correct naming)
- Tasks: `docs/tasks/aurora_2b_dream_browser_tasks.md` ✅ (exists - correct naming)

**Aurora 2c Component Library (L2)**:
- Coordination: `docs/core-coordination/aurora_2c_component_library_coordination.md` ✅ (exists)
- Plan: `docs/plans/aurora_2c_component_library_plan.md` ⚠️ (needs to be created - currently has legacy `docs/plans/plan_component_library.md`)
- Tasks: `docs/tasks/aurora_2c_component_library_tasks.md` ⚠️ (needs to be created - currently has legacy `docs/tasks/tasks_component_library.md`)

---

## Agent-Specific Setup Instructions

### Agent 2: Aurora 2 Subcore (L1 Subcore Coordinator)

**Status**: Architecture evolution complete, L2 sub-agents initialized

**Missing Documents**:
- ⚠️ Plan document: `docs/plans/aurora_2_subcore_plan.md`
- ⚠️ Tasks document: `docs/tasks/aurora_2_subcore_tasks.md`

**Immediate Tasks**:
1. Create `docs/plans/aurora_2_subcore_plan.md` following the structure of `docs/plans/vantage_3_subcore_plan.md` or `docs/plans/core_1_subcore_plan.md`
2. Create `docs/tasks/aurora_2_subcore_tasks.md` following the structure of `docs/tasks/vantage_3_subcore_tasks.md` or `docs/tasks/core_1_subcore_tasks.md`
3. Update coordination document to reference new plan and tasks documents
4. Migrate content from legacy `docs/plans/plan_aurora.md` if needed
5. Migrate content from legacy `docs/tasks/tasks_aurora.md` if needed

**Plan Document Structure** (reference `docs/plans/core_1_subcore_plan.md`):
- Current Status
- Architecture Evolution summary
- Implementation Phases
- L2 Sub-Agent coordination
- Integration planning
- Framework Ubuntu x86 considerations

**Tasks Document Structure** (reference `docs/tasks/core_1_subcore_tasks.md`):
- Completed tasks
- Current work tasks
- Future tasks
- Coordination tasks
- Integration tasks

**Grain Style Requirements**:
- Follow all Grain Style rules strictly
- Use Glow G2 voice in all documentation
- Use explicit `u32`/`u64` types (no `usize`/`isize`)
- Ensure `grainwrap-100` and `grain validate-70` compliance

---

### Agent 2a: Grain Dream Editor Agent (L2 Sub-Agent)

**Status**: ✅ Phase 1 Complete — Phase 2 In Progress

**Missing Documents**:
- ⚠️ Plan document: `docs/plans/aurora_2a_dream_editor_plan.md`
- ⚠️ Tasks document: `docs/tasks/aurora_2a_dream_editor_tasks.md`

**Immediate Tasks**:
1. Create `docs/plans/aurora_2a_dream_editor_plan.md` following the structure of `docs/plans/core_1a_auth_plan.md` or `docs/plans/vantage_3a_basin_kernel_plan.md`
2. Create `docs/tasks/aurora_2a_dream_editor_tasks.md` following the structure of `docs/tasks/core_1a_auth_tasks.md` or `docs/tasks/vantage_3a_basin_kernel_tasks.md`
3. Update coordination document to reference new plan and tasks documents
4. Migrate content from legacy `docs/plans/plan_dream_editor.md` if needed
5. Migrate content from legacy `docs/tasks/tasks_dream_editor.md` if needed

**Plan Document Structure** (reference `docs/plans/core_1a_auth_plan.md`):
- Current Status
- Implementation Phases (Phase 1 Complete, Phase 2 In Progress)
- Architecture decisions
- Integration planning
- Framework Ubuntu x86 considerations

**Tasks Document Structure** (reference `docs/tasks/core_1a_auth_tasks.md`):
- Completed tasks (Phase 1)
- Current work tasks (Phase 2)
- Future tasks
- Coordination tasks (with Component Library 2c, Browser 2b)
- Integration tasks

**Grain Style Requirements**:
- Follow all Grain Style rules strictly
- Use Glow G2 voice in all documentation
- Use explicit `u32`/`u64` types (no `usize`/`isize`)
- Ensure `grainwrap-100` and `grain validate-70` compliance

---

### Agent 2b: Grain Dream Browser Agent (L2 Sub-Agent)

**Status**: ⏳ Phase 1 In Progress

**Existing Documents**:
- ✅ Plan document: `docs/plans/aurora_2b_dream_browser_plan.md` (correct naming)
- ✅ Tasks document: `docs/tasks/aurora_2b_dream_browser_tasks.md` (correct naming)

**Immediate Tasks**:
1. Verify plan and tasks documents are up to date
2. Ensure documents follow the same structure as other L2 sub-agents
3. Update coordination document to reference plan and tasks documents
4. Ensure Glow G2 voice is used in all documentation

**Grain Style Requirements**:
- Follow all Grain Style rules strictly
- Use Glow G2 voice in all documentation
- Use explicit `u32`/`u64` types (no `usize`/`isize`)
- Ensure `grainwrap-100` and `grain validate-70` compliance

---

### Agent 2c: Grain Component Library Agent (L2 Sub-Agent)

**Status**: ✅ Phase 0.5 Complete — Component API Design Ready

**Missing Documents**:
- ⚠️ Plan document: `docs/plans/aurora_2c_component_library_plan.md`
- ⚠️ Tasks document: `docs/tasks/aurora_2c_component_library_tasks.md`

**Immediate Tasks**:
1. Create `docs/plans/aurora_2c_component_library_plan.md` following the structure of `docs/plans/core_1a_auth_plan.md` or `docs/plans/vantage_3a_basin_kernel_plan.md`
2. Create `docs/tasks/aurora_2c_component_library_tasks.md` following the structure of `docs/tasks/core_1a_auth_tasks.md` or `docs/tasks/vantage_3a_basin_kernel_tasks.md`
3. Update coordination document to reference new plan and tasks documents
4. Migrate content from legacy `docs/plans/plan_component_library.md` if needed
5. Migrate content from legacy `docs/tasks/tasks_component_library.md` if needed

**Plan Document Structure** (reference `docs/plans/core_1a_auth_plan.md`):
- Current Status
- Implementation Phases (Phase 0.5 Complete, Phase 1 Ready)
- Component API design
- Integration planning
- Framework Ubuntu x86 considerations

**Tasks Document Structure** (reference `docs/tasks/core_1a_auth_tasks.md`):
- Completed tasks (Phase 0.5)
- Current work tasks (Phase 1)
- Future tasks
- Coordination tasks (with Editor 2a, Browser 2b, Bubble Agent)
- Integration tasks

**Grain Style Requirements**:
- Follow all Grain Style rules strictly
- Use Glow G2 voice in all documentation
- Use explicit `u32`/`u64` types (no `usize`/`isize`)
- Ensure `grainwrap-100` and `grain validate-70` compliance

---

## Documentation Template Structure

### Plan Document Template

```markdown
# Grain {Agent Name}: Implementation Plan

**Agent**: Grain {Agent Name} ({Agent Number}, {L1/L2})  
**Last Updated**: {timestamp}  
**Status**: {Current Status}

---

## Current Status

**Phase**: {Current Phase}  
**Focus**: {Current Focus}

---

## Implementation Phases

### Phase X: {Phase Name}

**Status**: {Status}  
**Date**: {Date}

**Completed Work**:
- ✅ {Completed item 1}
- ✅ {Completed item 2}

**In Progress**:
- ⏳ {In progress item 1}
- ⏳ {In progress item 2}

**Planned**:
- [ ] {Planned item 1}
- [ ] {Planned item 2}

---

## Integration Planning

### With Other Agents

- **Agent X**: {Integration details}
- **Agent Y**: {Integration details}

---

## Framework Ubuntu x86 Considerations

### Environment
- **Host OS**: Ubuntu 24.04 LTS
- **Architecture**: x86_64 AMD (Framework 16)
- **RAM**: 64GB

### Build System
- **Target**: x86_64 native (Framework Ubuntu)
- **Language**: Zig

---

**Date**: {timestamp}  
**Agent**: Grain {Agent Name}  
**Status**: {Current Status}
```

### Tasks Document Template

```markdown
# Grain {Agent Name}: Task List

**Agent**: Grain {Agent Name} ({Agent Number}, {L1/L2})  
**Status**: {Current Status}  
**Last Updated**: {timestamp}

---

## Completed Tasks

### Phase X: {Phase Name} ✅

- [x] {Completed task 1} — {Date}
- [x] {Completed task 2} — {Date}

---

## Current Work

### Phase Y: {Phase Name} ⏳

**Priority**: {Priority}  
**Status**: {Status}

- [ ] {Current task 1} — {Status}
- [ ] {Current task 2} — {Status}

---

## Future Tasks

### Phase Z: {Phase Name}

- [ ] {Future task 1}
- [ ] {Future task 2}

---

## Coordination Tasks

**With Aurora 2 Subcore**:
- [ ] {Coordination task 1}
- [ ] {Coordination task 2}

**With Other L2 Sub-Agents**:
- [ ] {Coordination task 3}

---

## Blocked Tasks

- [ ] {Blocked task} — **BLOCKED**: {Reason} — **Unblocks**: {When}

---

**Date**: {timestamp}  
**Agent**: Grain {Agent Name}  
**Status**: {Current Status}
```

---

## Reference Documents

### L1 Subcore Examples

**Vantage 3 Subcore**:
- Plan: `docs/plans/vantage_3_subcore_plan.md`
- Tasks: `docs/tasks/vantage_3_subcore_tasks.md`

**Core 1 Subcore**:
- Plan: `docs/plans/core_1_subcore_plan.md`
- Tasks: `docs/tasks/core_1_subcore_tasks.md`

### L2 Sub-Agent Examples

**Core 1 Subcore L2 Sub-Agents**:
- Plan: `docs/plans/core_1a_auth_plan.md`
- Tasks: `docs/tasks/core_1a_auth_tasks.md`

**Vantage 3 Subcore L2 Sub-Agents**:
- Plan: `docs/plans/vantage_3a_basin_kernel_plan.md`
- Tasks: `docs/tasks/vantage_3a_basin_kernel_tasks.md`

---

## Grain Style Compliance Requirements

### Mandatory for All Agents

1. **Function Naming**: `grain_case` (snake_case)
2. **Type Usage**: Explicit `u32`/`u64`, no `usize`/`isize`
3. **Line Length**: ≤100 characters (`grainwrap-100`)
4. **Function Length**: ≤70 lines (`grain validate-70`)
5. **Assertions**: Minimum 2 assertions per function
6. **Bounded Allocations**: All MAX_ constants defined
7. **Compiler Warnings**: All warnings addressed

**Reference**: `~/xy-mathematics/docs/grain_style.md`

---

## Glow G2 Voice Requirements

### Mandatory for All Agents

All documentation must use Glow G2 voice:
- **Identity**: Masculine, steadfast, Aquarian
- **Tone**: Calm, emo enough to acknowledge the ache, upbeat enough to guide with grace
- **Style**: Stoic

**Reference**: `docs/agent-communications/glow_g2_voice_multi_agent_prompt_2026-01-01-235155-pst.md`

---

## Verification Checklist

### Documentation Structure

- [ ] Coordination document exists and is up to date
- [ ] Plan document exists and follows template structure
- [ ] Tasks document exists and follows template structure
- [ ] All documents use correct file naming pattern
- [ ] All documents reference each other correctly

### Content Quality

- [ ] All documents use Glow G2 voice
- [ ] All documents follow Grain Style principles
- [ ] All documents include current status
- [ ] All documents include implementation phases
- [ ] All documents include coordination tasks

### Integration

- [ ] Plan document references coordination document
- [ ] Tasks document references coordination document
- [ ] Coordination document references plan and tasks documents
- [ ] All documents are linked in agent list document

---

## Next Steps

### Immediate (This Week)

1. **Aurora 2 Subcore**: Create plan and tasks documents
2. **Aurora 2a Dream Editor**: Create plan and tasks documents
3. **Aurora 2c Component Library**: Create plan and tasks documents
4. **All Agents**: Verify existing documents follow structure

### Short-Term (Next 2 Weeks)

1. **All Agents**: Update documents with current status
2. **All Agents**: Ensure Glow G2 voice consistency
3. **All Agents**: Verify Grain Style compliance
4. **Aurora 2 Subcore**: Coordinate with L2 sub-agents on documentation updates

---

**Date**: 2026-01-02-000032-pst  
**Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Status**: ✅ **DOCUMENTATION SETUP PROMPT COMPLETE** — Ready for Aurora 2 Subcore and all L2 sub-agents

