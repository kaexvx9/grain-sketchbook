# Grain OS sevenos: Framework Ubuntu Cursor Workspace Setup Prompt

**Date**: 2026-01-01-193706-pst  
**Context**: Framework 16 (x86_64 AMD, 64GB RAM) running Ubuntu 24.04 LTS  
**Purpose**: Copy-paste prompt to recreate all agents/sub-agents for Grain OS sevenos development  
**Goal**: Maximize parallelism with Cursor Ultra Auto Mode unlimited plan

---

## Copy-Paste Prompt for Cursor

```
# Grain OS sevenos: Framework Ubuntu Cursor Workspace Setup

## Context
- Framework 16 (x86_64 AMD, 64GB RAM) running Ubuntu 24.04 LTS
- Goal: Get Vantage x86 working for Basin Kernel and first Grainscript shell running Grain OS sevenos
- Architecture: Basin Kernel syscall → RISC-V → Vantage → Core 1 Subcore → sevenos
- Maximize parallelism with Cursor Ultra Auto Mode unlimited plan

## Priority Order (HIGH → MEDIUM)

### HIGH PRIORITY (Start Immediately)

**Existing Agents (1-12)**:

1. **Vantage 3 Subcore (L1)** - VM Runtime coordination
   - File: `docs/core-coordination/vantage_3_subcore_coordination.md`
   - Focus: RISC-V → x86_64 JIT pipeline, VM Runtime Phase 2 completion, Phase 3 planning
   - Framework Impact: Critical for x86_64 JIT compilation

2. **Vantage 3b VM Runtime Agent (L2)** - JIT compilation
   - File: `docs/core-coordination/vantage_3b_vm_runtime_coordination.md`
   - Code: `src/kernel_vm/`
   - Focus: RISC-V → x86_64 JIT pipeline implementation
   - Framework Impact: HIGH - Enable x86_64 native execution

3. **Vantage 3a Basin Kernel Agent (L2)** - Kernel syscalls
   - File: `docs/core-coordination/vantage_3a_basin_kernel_coordination.md`
   - Code: `src/kernel/` (8 kernel modules)
   - Tests: `tests/143_syscall_performance_profiler_test.zig`, `tests/144_syscall_performance_benchmark_test.zig`
   - Focus: Profiler data collection, syscall interface verification
   - Framework Impact: Kernel runs in RISC-V VM, but needs x86_64 host integration

4. **Vantage 3c System Integration Agent (L2)** - Multi-arch testing
   - File: `docs/core-coordination/vantage_3c_system_integration_coordination.md`
   - Code: `src/kernel_vm/integration.zig`
   - Tests: `tests/riscv_compliance_validation_test.zig`, `tests/149-153_*_integration_test.zig` (44 total tests)
   - Focus: Multi-architecture testing framework (ARM64, x86_64 AMD, x86_64 Intel)
   - Framework Impact: HIGH - Enable multi-arch testing on Framework x86_64

5. **Core 1 Subcore (L1)** - Core services coordination
   - File: `docs/plans/core_1_subcore_plan.md`
   - Tasks: `docs/tasks/core_1_subcore_tasks.md`
   - Focus: Coordinate L2 sub-agents, integration testing
   - Framework Impact: Core system services architecture

**New Agents (13-14)**:

13. **sevenos Init System Agent (NEW)** - Grain Style init system
   - File: `grainstore/sevenos/src/init/main.zig`
   - Build: `grainstore/sevenos/build.zig`
   - Focus: Implement Grain Style init system in Zig (S6-inspired supervision)
   - Framework Impact: NEW - Core OS component
   - Priority: HIGH - Needed for first Grainscript shell

14. **Grainscript Shell Agent (NEW)** - First shell implementation
   - File: `grainstore/sevenos/src/shell/grainscript.zig` (to be created)
   - Focus: Implement first Grainscript shell for Grain OS sevenos
   - Framework Impact: NEW - User interface component
   - Priority: HIGH - Goal: First shell running

### MEDIUM PRIORITY (After HIGH priority agents working)

**Existing Agents (6-12)**:

6. **Core 1a Auth Agent (L2)** - Authentication
   - File: `docs/core-coordination/core_1a_auth_coordination.md`
   - Code: `src/core_1a_auth/`
   - Focus: Auth services, API keys, RBAC, audit logging
   - Framework Impact: Core system service

7. **Core 1b Network Agent (L2)** - Network services
   - File: `docs/core-coordination/core_1b_network_coordination.md`
   - Code: `src/core_1b_network/`
   - Focus: HTTP, WebSocket, DNS, TCP/UDP services
   - Framework Impact: Core system service

8. **Core 1c Storage Agent (L2)** - Storage services
   - File: `docs/core-coordination/core_1c_storage_coordination.md`
   - Code: `src/core_1c_storage/`
   - Focus: File system, storage services
   - Framework Impact: Core system service

9. **Core 1d Compositor Agent (L2)** - Window management
   - File: `docs/core-coordination/core_1d_compositor_coordination.md`
   - Code: `src/core_1d_compositor/`
   - Focus: Window management, compositing
   - Framework Impact: Core system service

10. **Aurora 2 Subcore (L1)** - IDE/Browser coordination
    - File: `docs/core-coordination/aurora_2_subcore_coordination.md`
    - Focus: IDE and Browser coordination
    - Framework Impact: Medium priority

11. **Aurora 2a-2c Agents (L2)** - IDE/Browser features
    - Files: `docs/core-coordination/aurora_2a_*_coordination.md`, etc.
    - Focus: Editor, Browser, Component Library features
    - Framework Impact: Medium priority

12. **Other L1 Agents** - Silo, Skate, Bubble, Carry, Workspace, Flow, Research, Court
    - Files: Various coordination documents
    - Focus: Domain-specific services
    - Framework Impact: Medium priority

## Framework Ubuntu x86 Specific Considerations

### Build System
- Target: x86_64 native (Framework Ubuntu)
- Kernel Target: RISC-V (Basin Kernel in VM)
- JIT Target: x86_64 (VM Runtime compilation)
- Language: Zig

### Development Environment
- OS: Ubuntu 24.04 LTS
- Architecture: x86_64 AMD (Framework 16)
- RAM: 64GB (vs 24GB on MacBook Air M2)
- Native Development: Direct x86_64 compilation (no emulation)

### Testing
- Multi-Architecture: ARM64 (MacBook Air M2), x86_64 AMD (Framework 16), x86_64 Intel (legacy)
- Integration Tests: Full system integration on Framework x86_64
- Performance Tests: Native x86_64 performance profiling

## Parallelization Strategy

### Phase 1: Foundation (Weeks 1-2)
- **Parallel Work**:
  - Vantage 3b: RISC-V → x86_64 JIT pipeline (can work in parallel with others)
  - Vantage 3a: Basin Kernel profiler data collection (independent)
  - Vantage 3c: Multi-arch testing framework design (can start in parallel)
  - sevenos Init: Core init system implementation (independent)
  - Grainscript Shell: Shell implementation (can start after init system basics)

### Phase 2: Integration (Weeks 3-4)
- **Parallel Work**:
  - Vantage 3b + 3a: JIT + Kernel integration (coordinate)
  - Vantage 3c: Integration testing (can run in parallel)
  - sevenos + Grainscript: Init system + Shell integration (coordinate)
  - Core 1 Subcore: Agent coordination setup (can start in parallel)

### Phase 3: Core Services (Weeks 5-6)
- **Parallel Work**:
  - Core 1a-1d: All sub-agents can work in parallel
  - Integration with sevenos init system (coordinate)
  - Testing and validation (parallel)

## Agent Recreation Checklist

### For Each Agent/Sub-Agent:

1. **Read Coordination Document**:
   - Review agent's coordination document
   - Understand current status and priorities
   - Review Framework x86 adaptations needed

2. **Review Code Structure**:
   - Check source code files
   - Review test files
   - Understand build system integration

3. **Framework x86 Adaptations**:
   - Update build targets (ARM64 → x86_64)
   - Update JIT targets (ARM64 → x86_64)
   - Update test targets (multi-architecture)
   - Verify Ubuntu-specific dependencies

4. **Verify Build**:
   - Run `zig build` for x86_64 target
   - Verify tests pass on Framework x86_64
   - Check for architecture-specific issues

5. **Update Documentation**:
   - Update coordination documents with Framework x86 status
   - Document any Framework-specific changes
   - Update test results

## New Agents to Create

### Agent 13: sevenos Init System Agent

**Agent Number**: 13  
**Purpose**: Implement Grain Style init system in Zig

**Responsibilities**:
- Service supervision (S6-inspired, native Zig)
- Service dependency management
- Explicit configuration system
- Integration with Basin Kernel syscalls
- Agent lifecycle management

**File Structure**:
```
grainstore/sevenos/
├── src/
│   ├── init/
│   │   ├── main.zig          # Init system entry point
│   │   ├── supervision.zig   # Service supervision
│   │   └── config.zig        # Configuration system
│   ├── services/              # Service definitions
│   └── lib/                   # Shared libraries
├── build.zig                  # Build configuration
└── docs/                      # Documentation
```

**Integration Points**:
- Basin Kernel syscall interface
- Core 1 Subcore agent coordination
- Vantage system integration

### Agent 14: Grainscript Shell Agent

**Agent Number**: 14  
**Purpose**: Implement first Grainscript shell for Grain OS sevenos

**Responsibilities**:
- Shell command parsing and execution
- Integration with sevenos init system
- Integration with Basin Kernel syscalls
- Basic shell commands (cd, ls, pwd, etc.)
- Script execution support

**File Structure**:
```
grainstore/sevenos/
├── src/
│   ├── shell/
│   │   ├── grainscript.zig   # Shell implementation
│   │   ├── parser.zig        # Command parsing
│   │   └── executor.zig      # Command execution
│   └── commands/              # Built-in commands
```

**Integration Points**:
- sevenos init system
- Basin Kernel syscalls
- Core 1 Subcore services (when available)

## Verification Steps

### After Agent Recreation:

1. **Build Verification**:
   ```bash
   cd ~/xy-mathematics
   zig build
   ```

2. **Test Verification**:
   ```bash
   zig build test
   ```

3. **Framework x86 Verification**:
   ```bash
   zig build -Dtarget=x86_64-linux-gnu
   zig build test -Dtarget=x86_64-linux-gnu
   ```

4. **Integration Verification**:
   - Run integration tests
   - Verify agent coordination
   - Check system integration

## Success Criteria

### Phase 1 Success:
- ✅ All HIGH priority agents recreated and working
- ✅ Build system verified for x86_64
- ✅ Basin Kernel syscall interface working
- ✅ RISC-V → x86_64 JIT pipeline functional
- ✅ sevenos init system basic implementation
- ✅ Grainscript shell basic implementation

### Phase 2 Success:
- ✅ Full system integration working
- ✅ Multi-architecture testing passing
- ✅ Core 1 Subcore agents integrated
- ✅ First Grainscript shell running on Grain OS sevenos

## Next Steps

1. **Recreate HIGH Priority Agents** (in parallel where possible)
2. **Verify Framework x86 Build System**
3. **Begin Integration Testing**
4. **Create New Agents** (sevenos Init, Grainscript Shell)
5. **Coordinate Agent Work** (weekly/bi-weekly check-ins)

---

**Status**: ✅ **CURSOR WORKSPACE SETUP PROMPT READY**  
**Next**: Begin agent recreation in Framework Ubuntu Cursor workspace
```

---

## Usage Instructions

1. **Copy the prompt above** (everything between the triple backticks)
2. **Paste into Cursor** (new chat or agent setup)
3. **Execute in Cursor Ultra Auto Mode** for maximum parallelism
4. **Monitor progress** across all agents/sub-agents
5. **Coordinate weekly/bi-weekly** for integration

## Parallelization Tips

### Maximize Cursor Ultra Auto Mode:

1. **Create Separate Cursor Windows/Tabs** for each HIGH priority agent
2. **Use Cursor Auto Mode** for each agent independently
3. **Coordinate via shared documents** (coordination docs)
4. **Run builds/tests in parallel** (64GB RAM allows multiple builds)
5. **Use Framework's 64GB RAM** for parallel compilation

### Agent Coordination:

- **Daily Standups**: Quick status updates
- **Weekly Coordination**: Integration planning
- **Bi-Weekly Deep Dives**: Architecture decisions
- **Shared Documents**: All coordination in `docs/core-coordination/`

---

**Date**: 2026-01-01-193706-pst  
**Status**: ✅ **CURSOR WORKSPACE SETUP PROMPT COMPLETE**  
**Ready for**: Framework Ubuntu Cursor workspace agent recreation

