# Core 1 Subcore: System Integration & Coordination Document

**Date**: 2026-01-01-224946-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: 🆕 **SYSTEM INTEGRATION PLANNING** — Coordination with sevenos and Grainscript Shell

---

## Executive Summary

**Core 1 Subcore** serves as the L1 Subcore Coordinator for Core system services (Auth, Network, Storage, Compositor) and now includes coordination responsibilities for **sevenos Init System (Agent 3d)** and **Grainscript Shell (Agent 1e)** as part of the Grain OS sevenos effort.

**Current Focus**: 
- Coordinate Core 1 L2 sub-agents (1a-1d) for system services
- Coordinate with sevenos Init System for OS-level integration
- Coordinate with Grainscript Shell for first shell implementation
- Plan system integration between Core services and sevenos

---

## Core 1 Subcore: Next Steps & Responsibilities

### Primary Role: L1 Subcore Coordinator

**Core 1 Subcore** coordinates:
1. **Core System Services** (L2 sub-agents 1a-1d):
   - 1a. Grain Auth Agent — Authentication and authorization
   - 1b. Grain Network Agent — Network services (HTTP, WebSocket, DNS, TCP/UDP)
   - 1c. Grain Storage Agent — File system and storage services
   - 1d. Grain Compositor Agent — Window management and compositing

2. **sevenos Integration** (New):
   - 3d. sevenos Init System — Grain Style init system (S6-inspired)
   - 1e. Grainscript Shell — First shell for Grain OS sevenos

### Immediate Next Steps for Core 1 Subcore

#### Phase 1: sevenos Integration Planning (Weeks 1-2)

**Priority**: **HIGH** — Enable sevenos and Grainscript Shell integration

**Tasks**:
1. **Coordinate with sevenos Init System (Agent 3d)**:
   - Review init system architecture and service supervision model
   - Plan integration points for Core 1 services (Auth, Network, Storage, Compositor)
   - Design service lifecycle management (start, stop, restart, status)
   - Plan service dependency management (Auth before Network, Storage before Compositor)
   - Document service configuration requirements

2. **Coordinate with Grainscript Shell (Agent 1e)**:
   - Review shell implementation status and architecture
   - Plan integration with Core 1 services (Auth for user sessions, Network for remote commands, Storage for file operations)
   - Design shell command integration (how shell commands interact with Core services)
   - Plan script execution support (Grainscript scripts that use Core services)
   - Document shell → Core service API contracts

3. **System Integration Architecture**:
   - Design sevenos → Core 1 service integration points
   - Design init system → Core service startup sequence
   - Design shell → Core service command execution flow
   - Document integration patterns and best practices
   - Create integration test framework for sevenos + Core services

**Deliverables**:
- sevenos integration architecture document
- Service lifecycle management design
- Shell → Core service API contracts
- Integration test framework

#### Phase 2: Core Services sevenos Adaptation (Weeks 3-4)

**Priority**: **HIGH** — Adapt Core services for sevenos environment

**Tasks**:
1. **Auth Agent (1a) sevenos Integration**:
   - Adapt authentication for sevenos init system (service-based auth)
   - Design user session management for shell users
   - Plan credential storage integration with sevenos file system
   - Test authentication flow in sevenos environment

2. **Network Agent (1b) sevenos Integration**:
   - Adapt network services for sevenos init system (service startup)
   - Design network service lifecycle (start/stop with init system)
   - Plan network service configuration for sevenos
   - Test network services in sevenos environment

3. **Storage Agent (1c) sevenos Integration**:
   - Adapt storage services for sevenos file system
   - Design storage service integration with Basin Kernel syscalls
   - Plan storage service lifecycle (start/stop with init system)
   - Test storage services in sevenos environment

4. **Compositor Agent (1d) sevenos Integration**:
   - Adapt compositor for sevenos (if window management needed)
   - Design compositor service lifecycle (start/stop with init system)
   - Plan compositor integration with sevenos (if applicable)
   - Test compositor in sevenos environment (if applicable)

**Deliverables**:
- Core service sevenos adaptation documents
- Service lifecycle integration tests
- sevenos environment test results

#### Phase 3: Integration Testing & Validation (Weeks 5-6)

**Priority**: **HIGH** — Ensure sevenos + Core services work together

**Tasks**:
1. **End-to-End Integration Testing**:
   - Test init system → Core service startup sequence
   - Test shell → Core service command execution
   - Test service dependency management (Auth → Network → Storage)
   - Test service lifecycle (start, stop, restart, status)
   - Test error handling across init system and Core services

2. **Performance Analysis**:
   - Profile service startup times
   - Profile shell command execution with Core services
   - Identify performance bottlenecks
   - Optimize integration points

3. **Cross-System Validation**:
   - Validate API contracts between init system and Core services
   - Validate API contracts between shell and Core services
   - Validate error propagation
   - Validate resource sharing
   - Validate security boundaries

**Deliverables**:
- Integration test suite
- Performance analysis reports
- Validation reports
- Integration documentation

---

## Grainscript Shell (Agent 1e): Next Steps & Status

### Current Status

**Agent**: Grainscript Shell (Agent 1e, L2 Sub-Agent under Core 1 Subcore)  
**Status**: 🆕 **IMPLEMENTATION IN PROGRESS** — Core structure complete, API compatibility in progress  
**Last Updated**: 2026-01-01-224946-pst

### Completed Work ✅

1. **Shell Architecture Complete**:
   - ✅ Command parser (`parser.zig`) — handles basic shell syntax, pipes, redirections
   - ✅ Command executor (`executor.zig`) — executes built-ins and external programs
   - ✅ Built-in commands (`builtins.zig`) — cd, ls, pwd, echo, exit
   - ✅ Main shell loop (`grainscript.zig`) — REPL loop with command parsing/execution
   - ✅ Build system integration — shell executable in `build.zig`

2. **File Structure**:
   - `grainstore/sevenos/src/shell/parser.zig` — Command line parsing
   - `grainstore/sevenos/src/shell/executor.zig` — Command execution
   - `grainstore/sevenos/src/shell/builtins.zig` — Built-in commands
   - `grainstore/sevenos/src/shell/grainscript.zig` — Main shell entry point
   - `grainstore/sevenos/src/shell/stdio_wrapper.zig` — Compatibility layer (in progress)

### Current Blocker ⚠️

**Zig 0.15.2 API Compatibility**:
- **Issue**: stdio APIs changed significantly in Zig 0.15.2
  - `std.io.getStdOut()` no longer exists
  - `File.writer()` API changed (requires buffer parameter)
  - `File.reader()` API changed (requires buffer parameter)
- **Impact**: Shell cannot compile due to API incompatibilities
- **Status**: In progress — working on compatibility layer
- **Priority**: **HIGH** — Blocks shell functionality

### Immediate Next Steps for Grainscript Shell

#### Phase 1: Fix API Compatibility (This Week)

**Priority**: **HIGHEST** — Unblock shell compilation

**Tasks**:
1. **Fix stdio Wrapper**:
   - Update `stdio_wrapper.zig` for Zig 0.15.2 API
   - Use `std.posix.STDOUT_FILENO` / `STDERR_FILENO` / `STDIN_FILENO` directly
   - Implement proper buffer-based writer/reader APIs
   - Test with minimal shell commands

2. **Update Shell Code**:
   - Replace all `std.io.getStdOut()` calls with compatible API
   - Replace all `std.io.getStdErr()` calls with compatible API
   - Replace all `std.io.getStdIn()` calls with compatible API
   - Update file I/O operations for Zig 0.15.2

3. **Verify Compilation**:
   - Ensure shell compiles successfully
   - Test basic commands (cd, ls, pwd, echo, exit)
   - Verify output/error handling works correctly

**Deliverables**:
- Working shell that compiles and runs
- Basic command execution verified
- API compatibility layer complete

#### Phase 2: Basic Shell Functionality (Week 2)

**Priority**: **HIGH** — Get shell fully functional

**Tasks**:
1. **Complete Built-in Commands**:
   - Verify all built-in commands work (cd, ls, pwd, echo, exit)
   - Add error handling for edge cases
   - Test command argument parsing
   - Test command output formatting

2. **External Program Execution**:
   - Test external program execution (e.g., `ls`, `cat`, `grep`)
   - Test program argument passing
   - Test exit code handling
   - Test error propagation

3. **Shell Features**:
   - Test command history (if implemented)
   - Test command completion (if implemented)
   - Test shell variables (if implemented)
   - Test environment variable access

**Deliverables**:
- Fully functional basic shell
- All built-in commands working
- External program execution working

#### Phase 3: Grainscript Script Execution (Week 3)

**Priority**: **MEDIUM** — Enable script execution

**Tasks**:
1. **Grainscript Interpreter Integration**:
   - Integrate existing Grainscript interpreter (`research/src_backup/grainscript/`)
   - Design script execution API
   - Implement script file parsing
   - Implement script execution flow

2. **Script Features**:
   - Support `.gr` script files
   - Support shebang (`#!/usr/bin/env grainscript-shell`)
   - Support script arguments
   - Support script exit codes

3. **Script Testing**:
   - Test basic script execution
   - Test script with Core service integration (future)
   - Test error handling in scripts
   - Test script performance

**Deliverables**:
- Grainscript script execution support
- Script execution tests
- Script execution documentation

#### Phase 4: Core Service Integration (Week 4+)

**Priority**: **MEDIUM** — Integrate with Core 1 services

**Tasks**:
1. **Auth Integration**:
   - Integrate with Auth Agent (1a) for user sessions
   - Support user authentication in shell
   - Support user session management
   - Test authentication flow

2. **Network Integration**:
   - Integrate with Network Agent (1b) for remote commands
   - Support network-based command execution (future)
   - Test network integration

3. **Storage Integration**:
   - Integrate with Storage Agent (1c) for file operations
   - Support secure file operations
   - Test storage integration

**Deliverables**:
- Core service integration complete
- Integration tests
- Integration documentation

---

## Coordination Schedule

### Weekly Coordination (Core 1 Subcore ↔ L2 Sub-Agents)

**Schedule**: Every Monday, 10:00 AM PST  
**Format**: Async coordination document updates + sync check-in if needed

**Agenda**:
1. Review sub-agent progress (1a-1d, 1e)
2. Review sevenos integration progress (3d, 1e)
3. Discuss blockers and coordination needs
4. Plan next week's priorities
5. Update coordination documents

### Bi-Weekly Deep Dive (Core 1 Subcore ↔ sevenos Agents)

**Schedule**: Every other Friday, 2:00 PM PST  
**Format**: Architecture review and integration planning

**Agenda**:
1. Review sevenos architecture decisions
2. Review integration points (init system ↔ Core services, shell ↔ Core services)
3. Plan integration milestones
4. Review test results
5. Update integration documentation

### As-Needed Coordination

**Triggers**:
- Architecture decisions affecting multiple agents
- Breaking changes requiring coordination
- Critical blockers requiring immediate attention
- Integration phases requiring coordination

---

## Success Criteria

### Phase 1 Success (Weeks 1-2)
- ✅ sevenos integration architecture documented
- ✅ Service lifecycle management designed
- ✅ Shell → Core service API contracts defined
- ✅ Integration test framework created

### Phase 2 Success (Weeks 3-4)
- ✅ All Core services adapted for sevenos
- ✅ Service lifecycle integration working
- ✅ sevenos environment tests passing

### Phase 3 Success (Weeks 5-6)
- ✅ End-to-end integration tests passing
- ✅ Performance meets requirements
- ✅ Cross-system validation complete

### Grainscript Shell Success
- ✅ Shell compiles and runs (API compatibility fixed)
- ✅ All built-in commands working
- ✅ External program execution working
- ✅ Grainscript script execution working
- ✅ Core service integration complete

---

## Framework Ubuntu x86 Specific Considerations

### Build System
- **Target**: x86_64 native (Framework Ubuntu)
- **Kernel Target**: RISC-V (Basin Kernel in VM)
- **JIT Target**: x86_64 (VM Runtime compilation)
- **Language**: Zig 0.15.2

### Development Environment
- **OS**: Ubuntu 24.04 LTS
- **Architecture**: x86_64 AMD (Framework 16)
- **RAM**: 64GB (vs 24GB on MacBook Air M2)
- **Native Development**: Direct x86_64 compilation (no emulation)

### Testing
- **Multi-Architecture**: ARM64 (MacBook Air M2), x86_64 AMD (Framework 16), x86_64 Intel (legacy)
- **Integration Tests**: Full system integration on Framework x86_64
- **Performance Tests**: Native x86_64 performance profiling

---

## Document References

**Core 1 Subcore Documents**:
- Plan: `docs/plans/core_1_subcore_plan.md`
- Tasks: `docs/tasks/core_1_subcore_tasks.md`
- Coordination: `docs/core-coordination/core_1_subcore_coordination.md`

**Grainscript Shell Documents**:
- Implementation: `grainstore/sevenos/src/shell/`
- Build: `grainstore/sevenos/build.zig`

**sevenos Documents**:
- Setup Prompt: `docs/agent-communications/grain_os_sevenos_cursor_workspace_setup_prompt_2026-01-01-193706-pst.md`
- Init System: `grainstore/sevenos/src/init/`

**L2 Sub-Agent Documents**:
- 1a Auth: `docs/core-coordination/core_1a_auth_coordination.md`
- 1b Network: `docs/core-coordination/core_1b_network_coordination.md`
- 1c Storage: `docs/core-coordination/core_1c_storage_coordination.md`
- 1d Compositor: `docs/core-coordination/core_1d_compositor_coordination.md`

---

**Date**: 2026-01-01-224946-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: System Integration Planning — Ready for Coordination  
**Next Update**: After Phase 1 progress


