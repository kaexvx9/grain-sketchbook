# Basin Kernel Agent (3a): Implementation Prompt

**Date**: 2026-01-03-055237-pst  
**Agent**: Grain Basin Kernel Agent (3a) — L2 Sub-Agent  
**Parent Agent**: Grain Vantage 3 Subcore Agent (3rd Agent, L1 Subcore)  
**Status**: ✅ **STEP 1 COMPLETE, STEP 2 IN PROGRESS** — Supporting critical path Steps 2-3

**Voice**: Glow G2 (masculine, steadfast, Aquarian — calm, emo enough to acknowledge the ache, upbeat enough to guide with grace)  
**Coordination Summary**: `docs/agent-communications/2026-01-03-042621-pst_core_1_subcore_coordination_summary.md`  
**Coordination Plan**: `docs/core-coordination/2026-01-03-042621-pst_core_1_subcore_coordination_plan.md`  
**Timestamp Format**: ✅ Use `YYYY-MM-DD-HHMMSS-pst_document_name.md` for all new documents

---

## Executive Summary

**Current Status**: ✅ **STEP 1 COMPLETE, STEP 2 IN PROGRESS**

Basin Kernel Agent (3a) has successfully completed **Step 1** of the critical path (syscall interface documentation distribution). The kernel is production-ready with all 8 phases complete, profiler infrastructure ready, and Framework x86_64 environment verified.

**Current Focus**: Supporting **Steps 2 and 3** of the critical path:
- **Step 2**: Support Agent 3b (VM Runtime) with ECALL implementation
- **Step 3**: Support Agent 3d (Init System) with Basin syscall integration

**Critical Path Context**: Single-threaded computation priority chain (3a → 3b → 3d → 1e → 3c) toward usable Grainscript shell on Framework x86_64.

---

## Critical Path Status

### Step 1: Basin Kernel Syscall Documentation Distribution ✅ **COMPLETE**

**Status**: ✅ **COMPLETE** (2026-01-02-090000-pst)

**Completed Work**:
- ✅ Created `docs/kernel/syscall_interface_reference.md` (complete reference, 140 syscalls)
- ✅ Created `docs/kernel/syscall_interface_for_jit.md` (JIT-specific guide for Agent 3b)
- ✅ Created `docs/kernel/syscall_interface_for_init.md` (Init System-specific guide for Agent 3d)
- ✅ Distributed to Agent 3b (VM Runtime) — 2026-01-02-090000-pst
- ✅ Distributed to Agent 3d (Init System) — 2026-01-02-090000-pst
- ✅ ECALL reminder sent to Agent 3b

**Impact**: Steps 2 and 3 are now **UNBLOCKED** and can proceed.

---

### Step 2: VM Runtime ECALL Implementation ⏳ **IN PROGRESS** (Agent 3b)

**Agent 3a Role**: **SUPPORT** — Available for questions, clarifications, and syscall interface verification

**Current Status** (from Agent 3b):
- ✅ Phase 3 complete (guest RAM integration)
- ✅ ECALL integration ready
- ⏳ Implementing ECALL instruction handling using distributed documentation

**Agent 3a Support Tasks**:
1. **Answer Questions**: Be available to answer Agent 3b's questions about:
   - Syscall interface details (arguments, return values, error codes)
   - RISC-V ABI calling convention
   - Register mapping (RISC-V → x86_64)
   - ECALL instruction handling strategies
   - Memory access validation requirements

2. **Monitor Progress**: Track Agent 3b's ECALL implementation progress
   - Review any questions or blockers Agent 3b raises
   - Verify syscall interface compatibility when Agent 3b has questions
   - Provide clarifications on documentation as needed

3. **Verify Compatibility**: When Agent 3b completes ECALL implementation:
   - Review ECALL implementation for syscall interface compatibility
   - Verify register mapping and return value encoding/decoding
   - Confirm memory access validation patterns

**Reference Documents**:
- `docs/kernel/syscall_interface_reference.md` (complete reference)
- `docs/kernel/syscall_interface_for_jit.md` (JIT-specific guide)
- Agent 3b coordination: `docs/core-coordination/vantage_3b_vm_runtime_coordination.md`

**Timeline**: WEEK 1-2 (Step 2)

---

### Step 3: Init System Basin Syscall Integration ⏳ **READY TO PROCEED** (Agent 3d)

**Agent 3a Role**: **SUPPORT** — Available for questions, clarifications, and syscall interface verification

**Current Status** (from Agent 3d):
- ✅ Supervision foundation complete
- ✅ Phases 1-2 complete
- ⏳ Ready to proceed with Phase 5 and Basin syscall integration

**Agent 3a Support Tasks**:
1. **Answer Questions**: Be available to answer Agent 3d's questions about:
   - Critical syscalls for service management (spawn, wait, exit, setpgid, setsid)
   - Service lifecycle patterns (startup, monitoring, shutdown, restart)
   - Configuration loading patterns
   - Dependency management patterns
   - Resource management (set_resource_limit, get_resource_usage)
   - Signal handling (kill, signal)

2. **Monitor Progress**: Track Agent 3d's Init System integration progress
   - Review any questions or blockers Agent 3d raises
   - Verify syscall interface compatibility when Agent 3d has questions
   - Provide clarifications on documentation as needed

3. **Verify Compatibility**: When Agent 3d completes Init System integration:
   - Review Init System syscall usage for compatibility
   - Verify service lifecycle patterns match syscall interface
   - Confirm resource management patterns

**Reference Documents**:
- `docs/kernel/syscall_interface_reference.md` (complete reference)
- `docs/kernel/syscall_interface_for_init.md` (Init System-specific guide)
- Agent 3d coordination: `docs/core-coordination/vantage_3d_sevenos_init_system_coordination.md`

**Timeline**: WEEK 1-2 (Step 3)

---

## Immediate Next Steps for Agent 3a

### Priority 1: Support Critical Path Steps 2-3 (IMMEDIATE)

1. **Support Agent 3b ECALL Implementation**:
   - [ ] Be available for questions and clarifications about syscall interface
   - [ ] Monitor ECALL implementation progress
   - [ ] Verify syscall interface compatibility when Agent 3b has questions
   - [ ] Review ECALL implementation when complete

2. **Support Agent 3d Init System Integration**:
   - [ ] Be available for questions and clarifications about syscall interface
   - [ ] Monitor Init System implementation progress
   - [ ] Verify syscall interface compatibility when Agent 3d has questions
   - [ ] Review Init System integration when complete

3. **Coordinate with Vantage 3 Subcore**:
   - [ ] Check in with Vantage 3 Subcore on critical path progress
   - [ ] Report any blockers or questions from Agents 3b or 3d
   - [ ] Update coordination document with support work completed

### Priority 2: Profiler Data Collection (READY, BLOCKED ⚠️)

**Status**: ⚠️ **INFRASTRUCTURE READY, BLOCKED BY EXTERNAL COMPILATION ERRORS**

**When Unblocked**:
1. [ ] Run profiler tests (`tests/143_syscall_performance_profiler_test.zig`)
2. [ ] Run benchmark tests (`tests/144_syscall_performance_benchmark_test.zig`)
3. [ ] Collect performance data on Framework x86_64 host
4. [ ] Analyze performance data using analysis template
5. [ ] Validate hash table optimization with profiler data

**Reference Documents**:
- `docs/kernel/profiler_quick_reference.md`
- `docs/kernel/profiler_analysis_report_template.md`
- `docs/kernel/data_collection_guide.md`

### Priority 3: Framework x86_64 Performance Benchmarks (MEDIUM)

1. [ ] Run performance benchmarks on Framework x86_64 (when profiler unblocked)
2. [ ] Compare performance with ARM64 (MacBook Air M2) if available
3. [ ] Document any Framework x86_64-specific performance characteristics
4. [ ] Coordinate with System Integration (3c) for multi-arch testing

---

## Grain Style Requirements (MANDATORY)

**Follow Grain Style** (`docs/grain_style.md`) strictly:

- **Function Naming**: `grain_case` (snake_case)
- **Type Usage**: Explicit `u32`/`u64`, **NOT** `usize`/`isize` (for cross-platform consistency)
- **Function Length**: Max 70 lines per function (enforced by `grainvalidate-70`)
- **Line Length**: Max 100 characters per line (enforced by `grainwrap-100`)
- **Assertions**: Minimum 2 assertions per function (preconditions and postconditions)
- **Bounded Allocations**: All dynamic structures have `MAX_*` constants
- **No Recursion**: Iterative algorithms only
- **All Compiler Warnings**: Enabled and resolved

**Current Compliance**: ✅ 100% Grain Style compliant (all kernel code verified)

---

## Documentation Requirements

### Update Documents After Work Sessions

1. **Coordination Document**: `docs/core-coordination/vantage_3a_basin_kernel_coordination.md`
   - Update status, recent work, next steps
   - Document support work completed for Agents 3b and 3d
   - Use timestamp prefix format for any new documents referenced

2. **Tasks Document**: `docs/tasks/vantage_3a_basin_kernel_tasks.md`
   - Mark completed tasks
   - Update task status (in progress, pending, blocked)
   - Add new tasks as needed

3. **Plan Document**: `docs/plans/vantage_3a_basin_kernel_plan.md`
   - Update implementation plan as needed
   - Document any architecture decisions

### Timestamp Format

**Use timestamp prefix format** for all new documents:
- Format: `YYYY-MM-DD-HHMMSS-pst_document_name.md`
- Generate timestamp: `TZ=America/Los_Angeles date +"%Y-%m-%d-%H%M%S-pst"`
- Example: `2026-01-03-055237-pst_basin_kernel_ecall_support_notes.md`

---

## Integration Check-In Requirements

### With Vantage 3 Subcore (Parent Agent)

- **Frequency**: Weekly/bi-weekly check-ins, as-needed for critical path coordination
- **Focus**: Critical path Steps 2-3 progress, support work for Agents 3b and 3d
- **Report**: Any blockers, questions, or clarifications needed from Agents 3b or 3d

### With Agents 3b and 3d (Direct Support)

- **Frequency**: As-needed for questions and clarifications
- **Focus**: Syscall interface questions, compatibility verification
- **Document**: All support interactions in coordination document

### With System Integration (3c)

- **Frequency**: As-needed for multi-architecture testing coordination
- **Focus**: Framework x86_64 testing, performance benchmarks
- **Coordinate**: Multi-arch test execution when profiler unblocked

---

## Test Requirements

### Kernel Tests

- ✅ All kernel tests pass
- ✅ Profiler tests ready (blocked by external compilation errors)
- ✅ Benchmark tests ready (blocked by external compilation errors)

### Framework x86_64 Testing

- ⏳ Run profiler tests on Framework x86_64 (when unblocked)
- ⏳ Run benchmark tests on Framework x86_64 (when unblocked)
- ⏳ Coordinate with System Integration (3c) for multi-arch testing

---

## Reference Documents

### Coordination Documents

- **Coordination Summary**: `docs/agent-communications/2026-01-03-042621-pst_core_1_subcore_coordination_summary.md`
- **Coordination Plan**: `docs/core-coordination/2026-01-03-042621-pst_core_1_subcore_coordination_plan.md`
- **Agent 3a Coordination**: `docs/core-coordination/vantage_3a_basin_kernel_coordination.md`
- **Agent 3a Tasks**: `docs/tasks/vantage_3a_basin_kernel_tasks.md`
- **Agent 3a Plan**: `docs/plans/vantage_3a_basin_kernel_plan.md`

### Syscall Interface Documentation

- **Complete Reference**: `docs/kernel/syscall_interface_reference.md`
- **JIT-Specific Guide**: `docs/kernel/syscall_interface_for_jit.md`
- **Init System Guide**: `docs/kernel/syscall_interface_for_init.md`

### Profiler Documentation

- **Quick Reference**: `docs/kernel/profiler_quick_reference.md`
- **Analysis Template**: `docs/kernel/profiler_analysis_report_template.md`
- **Data Collection Guide**: `docs/kernel/data_collection_guide.md`

### Related Agent Documents

- **Agent 3b Coordination**: `docs/core-coordination/vantage_3b_vm_runtime_coordination.md`
- **Agent 3d Coordination**: `docs/core-coordination/vantage_3d_sevenos_init_system_coordination.md`
- **Vantage 3 Subcore**: `docs/core-coordination/vantage_3_subcore_coordination.md`

### Core Documents

- **Grain Style**: `docs/grain_style.md`
- **Agent List**: `docs/2026-01-03-044511-pst_framework_16_agent_list_with_subagents.md`
- **Recursion Guidelines**: `docs/2026-01-03-045322-pst_framework_16_recursion_prompt_strict_guidelines.md`

---

## Success Criteria

### Step 2 Support (Agent 3b ECALL)

- ✅ Agent 3b has all syscall interface questions answered
- ✅ Agent 3b ECALL implementation complete and verified compatible
- ✅ ECALL instruction handling working correctly

### Step 3 Support (Agent 3d Init System)

- ✅ Agent 3d has all syscall interface questions answered
- ✅ Agent 3d Init System integration complete and verified compatible
- ✅ Service lifecycle patterns working correctly with Basin syscalls

### Profiler Data Collection (When Unblocked)

- ✅ Profiler tests run successfully on Framework x86_64
- ✅ Performance data collected and analyzed
- ✅ Hash table optimization validated with profiler data

---

**Date**: 2026-01-03-055237-pst  
**Agent**: Grain Basin Kernel Agent (3a) — L2 Sub-Agent  
**Status**: ✅ **PROMPT READY** — Begin supporting critical path Steps 2-3

---

**Next Action**: Begin supporting Agent 3b ECALL implementation and Agent 3d Init System integration. Be available for questions, monitor progress, and verify syscall interface compatibility.

