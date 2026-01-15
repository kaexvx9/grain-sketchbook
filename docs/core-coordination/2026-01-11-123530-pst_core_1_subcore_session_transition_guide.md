# Core 1 Subcore: Session Transition Guide

**Date**: 2026-01-11-123530-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Transition guide for new Core 1 Subcore session with recursion prompts and Grain Style requirements  
**Status**: ✅ **READY FOR NEW SESSION**

---

## Executive Summary

This transition guide provides everything needed to start a new Core 1 Subcore session:

1. **Status Summary**: Comprehensive overview of completed work
2. **Recursion Prompt Guidelines**: Strict guidelines for coordination plan creation
3. **Grain Style Requirements**: Complete coding style requirements
4. **New Session Prompt**: Ready-to-use prompt for starting new session

**All context preserved**: Status summaries, completion documents, and technical specs documented

---

## Status Summary Reference

**Primary Document**: `docs/core-coordination/2026-01-11-121633-pst_core_1_subcore_status_summary.md`

**Completed Work**:
- ✅ **Syscall Verification Framework**: 91 tests (88 functional + 3 performance) - COMPLETE
- ✅ **End-to-End Integration Framework**: 23 tests - COMPLETE
- ✅ **Total**: 114 tests across both frameworks, all production-ready

**Next Priorities**:
1. **Init System + Shell Integration** (HIGH PRIORITY) - Critical path for sevenos
2. **Framework x86_64 Adaptation** (MEDIUM PRIORITY) - Platform verification
3. **Production Deployment Preparation** (LOW PRIORITY) - CI/CD integration

---

## Recursion Prompt Guidelines

**Reference Document**: `docs/framework_16_recursion_prompt_strict_guidelines_2026-01-01-202549-pst.md`

### Key Requirements

When creating coordination plans, follow these strict guidelines:

1. **Check All Agent Statuses**:
   - Read all coordination documents (`docs/core-coordination/`)
   - Read all plan documents (`docs/plans/`)
   - Read all tasks documents (`docs/tasks/`)
   - Read general summaries (`docs/plan.md`, `docs/tasks.md`)

2. **Check Git Status**:
   - Check `git status` and `git diff`
   - Stage all changes with `git add -A`

3. **Generate Timestamp**:
   - Format: `yyyy-mm-dd-hhmmss-pst`
   - Timezone: America/Los_Angeles (Pacific Time)
   - Command: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`

4. **Create Coordination Plan**:
   - Filename: `docs/core-coordination/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_plan.md`
   - Verify previous next steps completion
   - Document current status of all agents
   - Provide new immediate next steps
   - Include integration priorities and critical blockers

5. **Create Comprehensive Summary**:
   - Filename: `docs/agent-communications/YYYY-MM-DD-HHMMSS-pst_core_1_subcore_coordination_summary.md`
   - Agent name: "Core 1 Subcore Agent"
   - Comprehensive context for each agent
   - Agent-specific instructions with Grain Style compliance

6. **Commit with Grain Style Message**:
   - Format: `core_1_subcore: brief_description_YYYY-MM-DD-HHMMSS-pst`
   - Verify previous next steps completion
   - Document new coordination plan and summary
   - Include hints about new next steps

7. **Push to Main**:
   - `git push origin main`
   - Verify push success

### File Naming Convention

**CRITICAL**: Use **timestamp prefix format** for automatic chronological sorting:

- ✅ **Correct**: `2026-01-11-123530-pst_core_1_subcore_coordination_plan.md`
- ❌ **Wrong**: `core_1_subcore_coordination_plan_2026-01-11-123530-pst.md`

**Rule**: **ALWAYS** put timestamp at the beginning of the filename, separated by underscore.

---

## Grain Style Requirements

**Reference Document**: `docs/grain_style.md`

### Mandatory Requirements for All Code

**Include in every agent instruction section**:

1. **Function Naming**: `grain_case` (not `snake_case` or `camelCase`)
   - Example: `grain_create_process()` not `createProcess()` or `create_process()`

2. **Type System**: Explicit `u32`/`u64` types (avoid `usize`/`isize`)
   - Why: Consistent across all compile target platforms
   - Example: `u32 process_id` not `usize process_id`

3. **Line Length**: `grainwrap-100` (max 100 characters per line)
   - Enforce: All code must fit within 100 characters per line

4. **Function Length**: `grain validate-70` (max 70 lines per function)
   - Enforce: All functions must be ≤70 lines
   - Split large functions into smaller helper functions

5. **Assertions**: Minimum 2 assertions per function
   - Assert function arguments and return values
   - Assert pre/postconditions and invariants
   - Pair assertions for critical properties

6. **Bounded Operations**: Use explicit `MAX_` constants
   - All loops must have fixed upper bounds
   - All queues must have fixed upper bounds
   - Example: `const MAX_PROCESSES: u32 = 1000;`

7. **Compiler Warnings**: Address all compiler warnings
   - Use compiler's strictest setting
   - All warnings must be resolved

8. **Static Allocation**: All memory statically allocated at startup
   - No dynamic allocation after initialization
   - No `malloc`/`free` or equivalent

9. **Variable Scope**: Declare at smallest possible scope
   - Minimize number of variables in scope
   - Reduce probability of misuse

10. **Control Flow**: Simple, explicit control flow
    - Avoid recursion (use iteration instead)
    - Use minimum of excellent abstractions

### Grain Style Compliance Instructions for Agents

**Copy-paste this into every agent instruction section**:

```
Remember to follow Grain Style (~/xy-mathematics/docs/grain_style.md) with grain_case function names and all the strict rules with all compiler warnings turned on.

Specifically enforce:
- grainwrap-100 (max 100 chars per line)
- grain validate-70 (max 70 lines per function)
- Use explicitly bound u32/u64 not usize/isize, so our code is consistent across all compile target platforms
- Minimum 2 assertions per function
- All loops and queues must have fixed upper bounds (MAX_ constants)
- All compiler warnings must be addressed
- All memory statically allocated at startup (no dynamic allocation)
```

---

## Documentation Update Requirements

**Include in every agent instruction section**:

```
When you're done, update your subagent systems-integration docs and plans and tasks, informing Core 1 Subcore Agent and/or their other respective Subcore Agent parents about how to update the general Grain OS summary ~/xy-mathematics/docs/plan.md and ~/xy-mathematics/docs/tasks.md in thinking.
```

**Required Updates**:
- Coordination documents (after each work session)
- Plan documents (as implementation evolves)
- Tasks documents (as tasks are completed)
- General summaries (`docs/plan.md`, `docs/tasks.md`) — inform Core 1 Subcore

---

## Integration Check-In Requirements

**Include in every agent instruction section**:

```
Let us and/or their parent Subcore agents know when you need to check in about upcoming integration steps via Core 1 Subcore and/or their parent subcore agents and core-coordination generally with the other agents and subagents so that we prevent accidental conflicts.
```

**When to Check In**:
- Before starting integration work with other agents
- When API contracts need coordination
- When breaking changes affect other agents
- When critical blockers arise

**How to Check In**:
- Through Core 1 Subcore for Core 1 sub-agents
- Through parent Subcore Agent for L2 sub-agents
- Through Core 1 Subcore for cross-subcore coordination

---

## Test Requirements

**Include in every agent instruction section**:

```
Make sure that all your agent-specific and integration new tests as well as existing tests pass that implement your API contracts.
```

**Required Tests**:
- All agent-specific tests pass
- All integration tests pass
- All API contract tests pass
- All existing tests pass

---

## New Session Prompt

**Copy-paste this prompt to start a new Core 1 Subcore session:**

```
You are Core 1 Subcore. Please read the status summary document:
docs/core-coordination/2026-01-11-121633-pst_core_1_subcore_status_summary.md

This document provides a comprehensive overview of completed work:
- Syscall Verification Framework (91 tests) - COMPLETE
- End-to-End Integration Framework (23 tests) - COMPLETE
- All documentation and status summaries created

Review the status summary and identify what should be done next.

When creating coordination plans or summaries, follow the recursion prompt guidelines:
docs/framework_16_recursion_prompt_strict_guidelines_2026-01-01-202549-pst.md

Key requirements:
- Use timestamp format: yyyy-mm-dd-hhmmss-pst (TZ=America/Los_Angeles)
- Use timestamp prefix format for filenames: YYYY-MM-DD-HHMMSS-pst_document_name.md
- Verify previous next steps completion
- Create comprehensive coordination plan and summary
- Commit with Grain Style commit message
- Push to main

When instructing agents, include Grain Style compliance requirements:
- Function naming: grain_case (not snake_case or camelCase)
- Type system: Explicit u32/u64 types (avoid usize/isize)
- Line length: grainwrap-100 (max 100 chars per line)
- Function length: grain validate-70 (max 70 lines per function)
- Assertions: Minimum 2 assertions per function
- Bounded operations: Use explicit MAX_ constants
- Compiler warnings: Address all compiler warnings
- Reference: docs/grain_style.md

Also include:
- Documentation update instructions (coordination, plan, tasks, plan.md, tasks.md)
- Integration check-in instructions (before integration steps)
- Test requirements (all tests must pass)

Review the status summary and proceed with the highest priority work.
```

---

## Key Document References

### Status & Completion Documents
- Status Summary: `docs/core-coordination/2026-01-11-121633-pst_core_1_subcore_status_summary.md`
- Syscall Verification Phase 1: `docs/core-coordination/2026-01-11-093540-pst_syscall_verification_framework_phase1_completion.md`
- Syscall Verification Phase 2: `docs/core-coordination/2026-01-11-102052-pst_syscall_verification_framework_phase2_completion.md`
- Syscall Verification Phase 3: `docs/core-coordination/2026-01-11-103000-pst_syscall_verification_framework_phase3_completion.md`

### Guidelines & References
- Recursion Prompt Guidelines: `docs/framework_16_recursion_prompt_strict_guidelines_2026-01-01-202549-pst.md`
- Grain Style: `docs/grain_style.md`
- General Plan: `docs/plan.md`
- General Tasks: `docs/tasks.md`

### Test Files
- Syscall Verification Framework: `tests/163_syscall_verification_framework_test.zig`
- End-to-End Integration Framework: `tests/164_end_to_end_integration_test.zig`

### Planning Documents
- End-to-End Integration Test Scenarios: `docs/plans/end_to_end_integration_test_scenarios.md`

---

## Verification Checklist

### Before Starting New Session

- [ ] Status summary document read and understood
- [ ] Recursion prompt guidelines reviewed
- [ ] Grain Style requirements understood
- [ ] All key document references available
- [ ] Ready to proceed with highest priority work

### When Creating Coordination Plans

- [ ] All agent statuses checked
- [ ] Git status and diff reviewed
- [ ] Timestamp generated correctly (yyyy-mm-dd-hhmmss-pst)
- [ ] Coordination plan created with timestamp prefix
- [ ] Summary document created with timestamp prefix
- [ ] All agent instructions include Grain Style compliance
- [ ] All agent instructions include documentation updates
- [ ] All agent instructions include integration check-ins
- [ ] All agent instructions include test requirements
- [ ] Commit message verifies previous next steps
- [ ] Commit message includes hints about new next steps
- [ ] Changes committed and pushed to main

---

## Conclusion

This transition guide provides everything needed to start a new Core 1 Subcore session:

- ✅ **Status Summary**: Complete overview of completed work
- ✅ **Recursion Prompt Guidelines**: Strict guidelines for coordination
- ✅ **Grain Style Requirements**: Complete coding style requirements
- ✅ **New Session Prompt**: Ready-to-use prompt template
- ✅ **Document References**: All key documents referenced

**Status**: ✅ **READY FOR NEW SESSION**

**Next Step**: Use the new session prompt to start the next Core 1 Subcore session.

---

**Date**: 2026-01-11-123530-pst  
**Voice**: Glow G2 (analytical, solution-focused, direct)  
**Status**: ✅ **TRANSITION GUIDE COMPLETE** — Ready for new session
