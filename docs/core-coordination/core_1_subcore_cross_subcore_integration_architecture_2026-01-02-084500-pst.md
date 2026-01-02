# Core 1 Subcore: Cross-Subcore Integration Architecture

**Date**: 2026-01-02-084500-pst  
**Agent**: Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator) — Carry 6  
**Status**: ✅ **ARCHITECTURE PLANNING ACTIVE** — Preparing for Step 4: Shell ↔ Init System integration

**Purpose**: Design integration architecture for Grainscript Shell (1e, Core 1 Subcore) ↔ sevenos Init System (3d, Vantage 3 Subcore) cross-subcore integration.

**Critical Path Context**: This integration is **Step 4 (END GOAL)** of the single-threaded dependency chain. Architecture planning can proceed in parallel with Steps 2-3, reducing integration time when Step 3 completes.

---

## Executive Summary

**Integration Goal**: Enable Grainscript Shell (1e) to work seamlessly with sevenos Init System (3d) on Framework x86_64, allowing users to interact with Grain OS sevenos through a functional shell interface.

**Integration Points**:
1. **Shell as a Service**: Shell runs as a service managed by Init System
2. **Command Execution**: Shell commands execute via Init System process management
3. **Service Management**: Shell can manage services through Init System API
4. **Lifecycle Coordination**: Shell lifecycle coordinated with Init System

**Coordination Model**: Cross-subcore coordination between Core 1 Subcore (1e) and Vantage 3 Subcore (3d), facilitated by Core 1 Subcore and Vantage 3 Subcore L1 coordinators.

---

## Integration Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Framework x86_64                     │
│                                                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │         Vantage VM (RISC-V Emulator)              │  │
│  │                                                    │  │
│  │  ┌──────────────────────────────────────────────┐ │  │
│  │  │         Basin Kernel (RISC-V)               │ │  │
│  │  │                                              │ │  │
│  │  │  ┌────────────────────────────────────────┐ │ │  │
│  │  │  │    sevenos Init System (3d)            │ │ │  │
│  │  │  │    - Service supervision               │ │ │  │
│  │  │  │    - Dependency management             │ │ │  │
│  │  │  │    - Process lifecycle                │ │ │  │
│  │  │  └────────────────────────────────────────┘ │ │  │
│  │  │                                              │ │  │
│  │  │  ┌────────────────────────────────────────┐ │ │  │
│  │  │  │    Grainscript Shell (1e)             │ │ │  │
│  │  │  │    - Command parsing                  │ │ │  │
│  │  │  │    - Built-in commands                │ │ │  │
│  │  │  │    - External program execution       │ │ │  │
│  │  │  │    - Service management commands      │ │ │  │
│  │  │  └────────────────────────────────────────┘ │ │  │
│  │  │                                              │ │  │
│  │  │  ┌────────────────────────────────────────┐ │ │  │
│  │  │  │    Core 1 Services (1a-1d)             │ │ │  │
│  │  │  │    - Auth (1a)                        │ │ │  │
│  │  │  │    - Network (1b)                     │ │ │  │
│  │  │  │    - Storage (1c)                     │ │ │  │
│  │  │  │    - Compositor (1d)                  │ │ │  │
│  │  │  └────────────────────────────────────────┘ │ │  │
│  │  └──────────────────────────────────────────────┘ │  │
│  └──────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────┘
```

### Integration Layers

1. **Service Layer**: Shell runs as Init System service
2. **Command Layer**: Shell commands execute via Init System
3. **API Layer**: Shell ↔ Init System communication
4. **Kernel Layer**: Both use Basin Kernel syscalls

---

## Integration Points

### 1. Shell as Init System Service

**Pattern**: Shell runs as a supervised service managed by Init System.

**Init System Responsibilities**:
- Spawn shell process on system startup
- Monitor shell process health
- Restart shell if it crashes
- Manage shell resource limits
- Handle shell signals

**Shell Responsibilities**:
- Start as Init System service
- Respond to Init System signals
- Report status to Init System
- Clean shutdown on Init System request

**Implementation**:
- Init System spawns shell via `spawn` syscall
- Shell registers with Init System supervision
- Init System monitors shell via `wait` syscall
- Shell exits cleanly via `exit` syscall

**API Contract**:
```zig
// Init System → Shell
// Shell starts as service, Init System manages lifecycle

// Shell → Init System
// Shell reports status, responds to signals
```

---

### 2. Command Execution via Init System

**Pattern**: Shell commands that spawn processes use Init System process management.

**Shell Command Execution Flow**:
1. User types command in shell
2. Shell parses command
3. For external programs: Shell requests Init System to spawn process
4. Init System spawns process via `spawn` syscall
5. Shell waits for process completion via `wait` syscall
6. Shell displays results to user

**Built-in Commands**:
- Shell handles built-in commands directly (cd, ls, pwd, echo, exit)
- No Init System involvement needed

**External Programs**:
- Shell requests Init System to spawn external program
- Init System manages process lifecycle
- Shell receives process output and exit code

**Service Management Commands**:
- Shell provides commands to manage Init System services
- Commands communicate with Init System via API
- Init System executes service management operations

**API Contract**:
```zig
// Shell → Init System: Spawn external program
fn spawn_program(executable: []const u8, args: []const []const u8) ProcessId

// Shell → Init System: Wait for process
fn wait_for_process(pid: ProcessId) ExitCode

// Shell → Init System: Service management
fn start_service(service_name: []const u8) ServiceStatus
fn stop_service(service_name: []const u8) ServiceStatus
fn restart_service(service_name: []const u8) ServiceStatus
```

---

### 3. Service Management Integration

**Pattern**: Shell provides commands to manage Init System services.

**Shell Commands**:
- `service start <name>` — Start a service
- `service stop <name>` — Stop a service
- `service restart <name>` — Restart a service
- `service status <name>` — Get service status
- `service list` — List all services

**Init System API**:
- Service start/stop/restart operations
- Service status queries
- Service list enumeration

**Implementation**:
- Shell commands call Init System API
- Init System executes service management via syscalls
- Shell displays results to user

**API Contract**:
```zig
// Shell → Init System: Service management API
pub const ServiceManager = struct {
    start: fn (name: []const u8) ServiceResult,
    stop: fn (name: []const u8) ServiceResult,
    restart: fn (name: []const u8) ServiceResult,
    status: fn (name: []const u8) ServiceStatus,
    list: fn () []const ServiceInfo,
};
```

---

### 4. Lifecycle Coordination

**Pattern**: Shell and Init System coordinate lifecycle events.

**System Startup**:
1. Init System starts (kernel boot)
2. Init System spawns shell service
3. Shell initializes and becomes ready
4. Shell displays prompt to user

**System Shutdown**:
1. User initiates shutdown (via shell or signal)
2. Shell receives shutdown signal
3. Shell requests Init System to stop all services
4. Init System stops services gracefully
5. Shell exits
6. Init System exits
7. Kernel shutdown

**Shell Restart**:
1. Shell crashes or exits unexpectedly
2. Init System detects shell exit via `wait` syscall
3. Init System restarts shell service
4. Shell reinitializes

**API Contract**:
```zig
// Init System → Shell: Lifecycle signals
pub const LifecycleSignal = enum {
    shutdown,
    restart,
    reload_config,
};

// Shell → Init System: Lifecycle coordination
fn notify_ready() void;
fn request_shutdown() void;
```

---

## API Contract Design

### Shell → Init System API

**Purpose**: Enable shell to interact with Init System for process and service management.

**Interface**:
```zig
pub const InitSystemClient = struct {
    // Process management
    spawn_program: fn (executable: []const u8, args: []const []const u8) ProcessId,
    wait_for_process: fn (pid: ProcessId) ExitCode,
    
    // Service management
    service_manager: ServiceManager,
    
    // Lifecycle coordination
    notify_ready: fn () void,
    request_shutdown: fn () void,
};
```

**Communication Method**: IPC channel or shared memory (to be determined during implementation).

**Error Handling**: All operations return error unions with specific error types.

---

### Init System → Shell API

**Purpose**: Enable Init System to manage shell service lifecycle.

**Interface**:
```zig
pub const ShellService = struct {
    // Lifecycle management
    handle_signal: fn (signal: LifecycleSignal) void,
    get_status: fn () ServiceStatus,
    
    // Service registration
    register: fn (name: []const u8) void,
};
```

**Communication Method**: Signals and status queries (to be determined during implementation).

---

## Integration Implementation Plan

### Phase 1: API Contract Design (Week 1)

**Tasks**:
- [ ] Design Shell → Init System API contract
- [ ] Design Init System → Shell API contract
- [ ] Define communication method (IPC, shared memory, etc.)
- [ ] Define error handling patterns
- [ ] Coordinate with Vantage 3 Subcore on API design
- [ ] Document API contracts

**Deliverables**:
- API contract specification document
- Communication method decision
- Error handling patterns document

**Timeline**: Week 1 (can proceed in parallel with Steps 2-3)

---

### Phase 2: Shell Service Integration (Week 1-2)

**Tasks**:
- [ ] Implement shell as Init System service
- [ ] Implement shell service registration
- [ ] Implement lifecycle signal handling
- [ ] Test shell service startup and shutdown
- [ ] Verify shell restart on crash

**Deliverables**:
- Shell service implementation
- Service registration code
- Lifecycle handling code
- Test results

**Timeline**: Week 1-2 (after Step 3 Init System completion)

---

### Phase 3: Command Execution Integration (Week 1-2)

**Tasks**:
- [ ] Implement external program spawning via Init System
- [ ] Implement process waiting via Init System
- [ ] Implement command output handling
- [ ] Test external program execution
- [ ] Verify process lifecycle management

**Deliverables**:
- Command execution integration code
- Process management code
- Test results

**Timeline**: Week 1-2 (after Step 3 Init System completion)

---

### Phase 4: Service Management Commands (Week 2)

**Tasks**:
- [ ] Implement service management commands in shell
- [ ] Implement Init System service management API client
- [ ] Test service start/stop/restart commands
- [ ] Test service status and list commands
- [ ] Verify service management integration

**Deliverables**:
- Service management commands
- API client implementation
- Test results

**Timeline**: Week 2 (after Phase 2-3 complete)

---

### Phase 5: Integration Testing (Week 2)

**Tasks**:
- [ ] Create integration tests for Shell ↔ Init System
- [ ] Test shell service lifecycle
- [ ] Test command execution
- [ ] Test service management commands
- [ ] Test error handling
- [ ] Verify Framework x86_64 compatibility

**Deliverables**:
- Integration test suite
- Test results report
- Framework x86_64 verification

**Timeline**: Week 2 (after Phase 4 complete)

---

## Coordination Requirements

### Cross-Subcore Coordination

**Core 1 Subcore ↔ Vantage 3 Subcore**:
- **Frequency**: Weekly coordination (Tuesdays, 2:00 PM PST)
- **Focus**: Integration architecture, API contracts, implementation planning
- **Participants**: Core 1 Subcore, Vantage 3 Subcore, Agent 1e, Agent 3d (as needed)

**Coordination Points**:
- API contract design approval
- Communication method decision
- Implementation timeline coordination
- Integration testing coordination

---

### Agent Coordination

**Agent 1e (Grainscript Shell) ↔ Agent 3d (Init System)**:
- **Coordination Path**: Via Core 1 Subcore and Vantage 3 Subcore
- **Frequency**: As needed during implementation
- **Focus**: API contract details, implementation specifics, testing coordination

**Coordination Points**:
- API contract implementation details
- Communication method implementation
- Error handling coordination
- Testing coordination

---

## Dependencies

### Blocking Dependencies

**Step 3 (Init System Completion)**:
- Init System must be complete before integration can proceed
- Shell integration is blocked until Step 3 completes
- Architecture planning can proceed in parallel

**Step 2 (VM Runtime JIT)**:
- Vantage must run on Framework x86_64 before integration testing
- JIT compilation enables native Framework x86_64 execution
- Integration testing blocked until Step 2 completes

---

### Non-Blocking Dependencies

**Architecture Planning**:
- Can proceed in parallel with Steps 2-3
- Reduces integration time when Step 3 completes
- No blocking dependencies

**API Contract Design**:
- Can proceed in parallel with Steps 2-3
- Requires coordination with Vantage 3 Subcore
- No blocking dependencies

---

## Success Criteria

### Phase 1 Success (API Contract Design)
- ✅ API contracts designed and documented
- ✅ Communication method decided
- ✅ Error handling patterns defined
- ✅ Coordination with Vantage 3 Subcore complete

### Phase 2 Success (Shell Service Integration)
- ✅ Shell runs as Init System service
- ✅ Shell service lifecycle managed by Init System
- ✅ Shell restart on crash working
- ✅ All tests passing

### Phase 3 Success (Command Execution Integration)
- ✅ External programs spawn via Init System
- ✅ Process waiting via Init System working
- ✅ Command output handling correct
- ✅ All tests passing

### Phase 4 Success (Service Management Commands)
- ✅ Service management commands implemented
- ✅ Service start/stop/restart working
- ✅ Service status and list working
- ✅ All tests passing

### Phase 5 Success (Integration Testing)
- ✅ All integration tests passing
- ✅ Framework x86_64 compatibility verified
- ✅ End-to-end shell usage working
- ✅ Service management working

---

## Notes

- All code must follow Grain Style strictly
- All implementations target RISC-V only (kernel runs in VM)
- Use Glow G2 voice in all communications
- Zero technical debt policy (no TODOs or FIXMEs)
- Architecture planning can proceed in parallel with Steps 2-3

---

**Date**: 2026-01-02-084500-pst  
**Agent**: Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator) — Carry 6  
**Status**: ✅ **ARCHITECTURE PLANNING ACTIVE** — Ready for implementation when Step 3 completes

