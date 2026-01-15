# Grainscript Shell ↔ sevenos Init System Integration Plan

**Date**: 2026-01-02-084136-pst  
**Agents**: Grainscript Shell Agent (1e) ↔ sevenos Init System Agent (3d)  
**Coordination**: Core 1 Subcore (Agent 1) ↔ Vantage 3 Subcore (Agent 3) — Cross-Subcore  
**Purpose**: Comprehensive integration plan for shell and init system integration  
**Status**: Planning phase — Ready for implementation when both agents are ready

---

## Executive Summary

This document provides a comprehensive integration plan for integrating **Grainscript Shell (Agent 1e)** with **sevenos Init System (Agent 3d)**. This is a **cross-subcore integration** requiring coordination between Core 1 Subcore (Agent 1) and Vantage 3 Subcore (Agent 3).

**Goal**: Enable Grainscript Shell to interact with Init System for service management, process supervision, and system control, creating a usable shell environment on Grain OS sevenos Framework x86_64.

**Critical Path Dependency**: This integration is **Step 4** of the single-threaded computation priority chain, blocked on:
- **Step 3**: Init System (3d) must complete Phase 3 (dependency manager) and Phase 4 (main init loop) and integrate with Basin Kernel syscalls

---

## Current Status

### Grainscript Shell (Agent 1e) — Core 1 Subcore

**Status**: ✅ **PHASE 1 COMPLETE**
- ✅ Zig 0.15.2 API compatibility fixed
- ✅ stdio wrapper complete
- ✅ Basic shell functionality working (built-in commands, external programs, pipes)
- ✅ Command parser, executor, builtins implemented
- ✅ Location: `grainstore/sevenos/src/shell/`

**Architecture**:
- `shell/parser.zig` - Command parsing
- `shell/executor.zig` - Command execution (built-ins and external programs)
- `shell/builtins.zig` - Built-in commands (cd, ls, pwd, echo, exit)
- `shell/stdio_wrapper.zig` - stdio wrapper for Zig 0.15.2
- `shell/grainscript.zig` - Grainscript script execution (future)

**Ready For**:
- Basic shell functionality testing
- Integration with Init System for service management
- Integration with Core services (1a-1d) for authentication, network, storage, compositor

### sevenos Init System (Agent 3d) — Vantage 3 Subcore

**Status**: ✅ **PHASES 1-2 COMPLETE, PHASE 3 IN PROGRESS**
- ✅ Supervision library complete (438 lines, Grain Style compliant)
- ✅ Configuration loader complete (464 lines, Grain Style compliant)
- ⏳ Dependency manager implementation mostly complete (391 lines, compilation issue to resolve)
- ⏳ Phase 4 (main init loop) - Not yet implemented
- ⏳ Basin Kernel syscall integration - Not yet implemented
- ✅ Location: `grainstore/sevenos/src/init/` and `grainstore/sevenos/src/lib/`

**Architecture**:
- `init/main.zig` - Init system entry point (TODO implementation)
- `lib/supervision.zig` - Process supervision (S6-inspired, 438 lines)
- `lib/dependency.zig` - Service dependency management (391 lines, compilation issue)
- `lib/config/loader.zig` - Configuration loading (464 lines)

**Ready For**:
- Fix dependency manager compilation issue (Zig 0.15.2 ArrayList initialization)
- Complete Phase 3 (dependency manager)
- Implement Phase 4 (main init loop)
- Integrate with Basin Kernel syscalls (spawn, wait, exit, setpgid, setsid)
- Integrate with Grainscript Shell (1e) for shell interaction

---

## Integration Architecture

### Overview

**Integration Pattern**: Shell as Init System Client

The Grainscript Shell will interact with the Init System as a **client**, using Init System APIs to:
- Query service status
- Start/stop/restart services
- View service logs
- Manage service dependencies
- Execute commands that spawn processes managed by Init System

**Communication Mechanism**: Direct function calls (same process) or IPC (future)

**Initial Implementation**: Direct function calls (simpler, same process)
**Future Enhancement**: IPC for distributed service management

---

## Integration Points

### 1. Service Management Commands

**Shell Commands to Add**:
- `service status [service_name]` - Query service status
- `service start <service_name>` - Start a service
- `service stop <service_name>` - Stop a service
- `service restart <service_name>` - Restart a service
- `service list` - List all services
- `service logs <service_name>` - View service logs

**Init System APIs Needed**:
```zig
// From supervision.zig
pub fn get_service_status(supervisor: *Supervisor, service_name: []const u8) ServiceState
pub fn start_service(supervisor: *Supervisor, service_name: []const u8) !void
pub fn stop_service(supervisor: *Supervisor, service_name: []const u8) !void
pub fn restart_service(supervisor: *Supervisor, service_name: []const u8) !void
pub fn list_services(supervisor: *Supervisor) []const ServiceInfo
pub fn get_service_logs(supervisor: *Supervisor, service_name: []const u8) []const u8
```

**Implementation**:
- Add service management built-in commands to `shell/builtins.zig`
- Create `shell/service_manager.zig` module that wraps Init System supervision APIs
- Integrate service manager with shell executor

### 2. Process Spawning Integration

**Current Shell Behavior**: Shell spawns processes directly using `std.process.Child`

**Integrated Behavior**: Shell can optionally spawn processes through Init System

**Use Cases**:
- Long-running processes (should be supervised)
- Processes that need resource limits
- Processes that need dependency management

**Init System APIs Needed**:
```zig
// From supervision.zig (via Basin Kernel syscalls)
pub fn spawn_supervised_process(
    supervisor: *Supervisor,
    config: ServiceConfig,
) !ProcessHandle
```

**Implementation**:
- Add `--supervised` flag to shell command execution
- When `--supervised` is used, spawn through Init System instead of direct process
- Shell executor checks flag and routes to appropriate spawn method

### 3. Service Configuration Integration

**Shell Commands to Add**:
- `service config <service_name>` - View service configuration
- `service reload <service_name>` - Reload service configuration

**Init System APIs Needed**:
```zig
// From config/loader.zig
pub fn get_service_config(loader: *ConfigLoader, service_name: []const u8) ?ServiceConfig
pub fn reload_service_config(loader: *ConfigLoader, service_name: []const u8) !void
```

**Implementation**:
- Add configuration commands to shell builtins
- Integrate with Init System config loader

### 4. Dependency Management Integration

**Shell Commands to Add**:
- `service deps <service_name>` - Show service dependencies
- `service tree` - Show service dependency tree

**Init System APIs Needed**:
```zig
// From dependency.zig
pub fn get_service_dependencies(graph: *DependencyGraph, service_name: []const u8) []const []const u8
pub fn get_dependency_tree(graph: *DependencyGraph) DependencyTree
```

**Implementation**:
- Add dependency commands to shell builtins
- Integrate with Init System dependency manager

### 5. Logging and Status Integration

**Shell Commands to Add**:
- `service logs <service_name> [--follow]` - View service logs (with optional follow)
- `service status` - Show all service statuses

**Init System APIs Needed**:
```zig
// From supervision.zig
pub fn get_service_logs(supervisor: *Supervisor, service_name: []const u8) []const u8
pub fn follow_service_logs(supervisor: *Supervisor, service_name: []const u8) LogStream
pub fn get_all_service_statuses(supervisor: *Supervisor) []const ServiceStatus
```

**Implementation**:
- Add logging commands to shell builtins
- Integrate with Init System logging system

---

## API Contract Design

### Shell → Init System Interface

**Module**: `shell/service_manager.zig` (new file to create)

```zig
//! service_manager: Shell integration with Init System
//!
//! This module provides shell commands access to Init System
//! service management capabilities.

const std = @import("std");
const supervision = @import("../../lib/supervision.zig");
const dependency = @import("../../lib/dependency.zig");
const config = @import("../../lib/config/loader.zig");

/// Service manager for shell integration
pub const ServiceManager = struct {
    supervisor: *supervision.Supervisor,
    dependency_graph: *dependency.DependencyGraph,
    config_loader: *config.ConfigLoader,
    allocator: std.mem.Allocator,

    /// Initialize service manager
    pub fn init(
        allocator: std.mem.Allocator,
        supervisor: *supervision.Supervisor,
        dependency_graph: *dependency.DependencyGraph,
        config_loader: *config.ConfigLoader,
    ) ServiceManager {
        return ServiceManager{
            .supervisor = supervisor,
            .dependency_graph = dependency_graph,
            .config_loader = config_loader,
            .allocator = allocator,
        };
    }

    /// Get service status
    pub fn get_service_status(
        self: *ServiceManager,
        service_name: []const u8,
    ) !supervision.ServiceState {
        // Implementation: query supervisor for service status
    }

    /// Start a service
    pub fn start_service(
        self: *ServiceManager,
        service_name: []const u8,
    ) !void {
        // Implementation: start service via supervisor
    }

    /// Stop a service
    pub fn stop_service(
        self: *ServiceManager,
        service_name: []const u8,
    ) !void {
        // Implementation: stop service via supervisor
    }

    /// Restart a service
    pub fn restart_service(
        self: *ServiceManager,
        service_name: []const u8,
    ) !void {
        // Implementation: restart service via supervisor
    }

    /// List all services
    pub fn list_services(
        self: *ServiceManager,
    ) ![]const ServiceInfo {
        // Implementation: get all services from supervisor
    }

    /// Get service logs
    pub fn get_service_logs(
        self: *ServiceManager,
        service_name: []const u8,
    ) ![]const u8 {
        // Implementation: get logs from supervisor
    }

    /// Get service dependencies
    pub fn get_service_dependencies(
        self: *ServiceManager,
        service_name: []const u8,
    ) ![]const []const u8 {
        // Implementation: query dependency graph
    }

    /// Get service configuration
    pub fn get_service_config(
        self: *ServiceManager,
        service_name: []const u8,
    ) !?config.ServiceConfig {
        // Implementation: query config loader
    }
};
```

### Init System → Shell Interface

**No direct interface needed** (Init System doesn't call shell)

**Indirect Integration**:
- Init System manages processes that shell spawns
- Init System provides status/logs that shell queries
- Init System supervises services that shell controls

---

## Implementation Phases

### Phase 1: Basic Service Management (Week 1-2)

**Goal**: Shell can query and control services via Init System

**Tasks**:
1. **Create Service Manager Module** (`shell/service_manager.zig`):
   - Implement ServiceManager struct
   - Implement basic service operations (status, start, stop, restart, list)
   - Integrate with Init System Supervisor

2. **Add Service Management Built-ins** (`shell/builtins.zig`):
   - Add `service` built-in command
   - Implement subcommands: `status`, `start`, `stop`, `restart`, `list`
   - Integrate with ServiceManager

3. **Integration Testing**:
   - Test service status query
   - Test service start/stop/restart
   - Test service list
   - Verify error handling

**Deliverables**:
- ServiceManager module complete
- Service management built-in commands working
- Basic integration tests passing

**Dependencies**:
- Init System Phase 4 (main init loop) must be complete
- Init System must have working Supervisor with service management

### Phase 2: Advanced Service Management (Week 2-3)

**Goal**: Shell can manage service dependencies and configuration

**Tasks**:
1. **Add Dependency Management**:
   - Add `service deps` and `service tree` commands
   - Integrate with Init System DependencyGraph

2. **Add Configuration Management**:
   - Add `service config` and `service reload` commands
   - Integrate with Init System ConfigLoader

3. **Integration Testing**:
   - Test dependency queries
   - Test configuration viewing/reloading
   - Verify dependency resolution

**Deliverables**:
- Dependency management commands working
- Configuration management commands working
- Advanced integration tests passing

**Dependencies**:
- Phase 1 complete
- Init System dependency manager complete
- Init System config loader complete

### Phase 3: Process Spawning Integration (Week 3-4)

**Goal**: Shell can spawn processes through Init System

**Tasks**:
1. **Add Supervised Process Spawning**:
   - Add `--supervised` flag to shell executor
   - Implement supervised spawn path
   - Integrate with Init System process spawning

2. **Add Process Management**:
   - Add `ps` command (list processes)
   - Add `kill` command (signal processes)
   - Integrate with Init System process management

3. **Integration Testing**:
   - Test supervised process spawning
   - Test process listing
   - Test process signaling
   - Verify resource limits enforced

**Deliverables**:
- Supervised process spawning working
- Process management commands working
- Process integration tests passing

**Dependencies**:
- Phase 2 complete
- Init System Basin Kernel syscall integration complete
- Init System process spawning working

### Phase 4: Logging and Monitoring (Week 4)

**Goal**: Shell can view and follow service logs

**Tasks**:
1. **Add Logging Commands**:
   - Enhance `service logs` command
   - Add `--follow` flag for log following
   - Integrate with Init System logging

2. **Add Status Monitoring**:
   - Add `service status` command (all services)
   - Add status formatting and display
   - Integrate with Init System status reporting

3. **Integration Testing**:
   - Test log viewing
   - Test log following
   - Test status display
   - Verify log rotation and management

**Deliverables**:
- Logging commands working
- Status monitoring working
- Logging integration tests passing

**Dependencies**:
- Phase 3 complete
- Init System logging system complete

---

## Error Handling and Recovery

### Error Types

**Service Manager Errors**:
- `ServiceNotFound` - Service doesn't exist
- `ServiceAlreadyRunning` - Service already started
- `ServiceNotRunning` - Service not started (can't stop)
- `DependencyNotMet` - Service dependencies not satisfied
- `CircularDependency` - Circular dependency detected
- `ConfigurationError` - Service configuration invalid
- `ResourceLimitExceeded` - Resource limits exceeded

### Error Handling Strategy

**Grain Style Error Handling**:
- Explicit error types (no generic errors)
- Clear error messages (help users understand and fix)
- Fail-fast (catch errors early)
- Bounded retries (prevent infinite loops)

**Error Recovery**:
- Automatic retry for transient errors (with bounded retry count)
- Clear error messages for user errors
- Logging for debugging

---

## Testing Strategy

### Unit Tests

**Service Manager Tests**:
- Test service status queries
- Test service start/stop/restart operations
- Test error handling
- Test dependency queries
- Test configuration queries

**Shell Built-in Tests**:
- Test service command parsing
- Test service command execution
- Test error message formatting
- Test output formatting

### Integration Tests

**Shell ↔ Init System Integration Tests**:
- Test service management end-to-end
- Test process spawning through Init System
- Test dependency resolution
- Test configuration reloading
- Test logging integration
- Test error recovery

**Framework x86_64 Tests**:
- Verify all integration tests pass on Framework x86_64
- Test performance characteristics
- Test resource limit enforcement

---

## Grain Style Compliance

### Code Requirements

**All Integration Code Must**:
- Follow Grain Style (`~/xy-mathematics/docs/grain_style.md`) strictly
- Use `grain_case` function names
- Enforce `grainwrap-100` (line length ≤100 characters)
- Enforce `grain validate-70` (function length ≤70 lines)
- Use explicit `u32`/`u64` types (NO `usize`/`isize`)
- Address ALL compiler warnings
- Define MAX_ constants for bounded allocations
- Minimum 2 assertions per function

### Documentation Requirements

**All Integration Code Must**:
- Include comprehensive comments explaining why
- Document API contracts clearly
- Provide usage examples
- Update coordination documents as implementation progresses

---

## Coordination Requirements

### Cross-Subcore Coordination

**Core 1 Subcore (Agent 1)**:
- Coordinates Grainscript Shell (1e)
- Facilitates cross-subcore integration with Vantage 3 Subcore
- Monitors integration progress
- Unblocks integration issues

**Vantage 3 Subcore (Agent 3)**:
- Coordinates sevenos Init System (3d)
- Facilitates cross-subcore integration with Core 1 Subcore
- Monitors integration progress
- Unblocks integration issues

**Integration Check-Ins**:
- Weekly check-ins between Core 1 Subcore and Vantage 3 Subcore
- Bi-weekly check-ins with Agents 1e and 3d
- Immediate check-ins for blockers or conflicts

### Agent Coordination

**Agent 1e (Grainscript Shell)**:
- Check in with Core 1 Subcore before starting integration work
- Coordinate with Agent 3d on API contracts
- Update coordination documents as integration progresses

**Agent 3d (sevenos Init System)**:
- Check in with Vantage 3 Subcore before starting integration work
- Coordinate with Agent 1e on API contracts
- Update coordination documents as integration progresses

---

## Timeline and Milestones

### Week 1-2: Phase 1 - Basic Service Management

**Milestones**:
- ✅ ServiceManager module created
- ✅ Service management built-ins implemented
- ✅ Basic integration tests passing
- ✅ Shell can query and control services

**Dependencies**:
- Init System Phase 4 (main init loop) complete
- Init System Supervisor working

### Week 2-3: Phase 2 - Advanced Service Management

**Milestones**:
- ✅ Dependency management commands working
- ✅ Configuration management commands working
- ✅ Advanced integration tests passing

**Dependencies**:
- Phase 1 complete
- Init System dependency manager complete
- Init System config loader complete

### Week 3-4: Phase 3 - Process Spawning Integration

**Milestones**:
- ✅ Supervised process spawning working
- ✅ Process management commands working
- ✅ Process integration tests passing

**Dependencies**:
- Phase 2 complete
- Init System Basin Kernel syscall integration complete

### Week 4: Phase 4 - Logging and Monitoring

**Milestones**:
- ✅ Logging commands working
- ✅ Status monitoring working
- ✅ All integration tests passing
- ✅ **END GOAL**: Usable Grainscript shell with Init System integration

**Dependencies**:
- Phase 3 complete
- Init System logging system complete

---

## Success Criteria

### Phase 1 Success
- ✅ Shell can query service status
- ✅ Shell can start/stop/restart services
- ✅ Shell can list all services
- ✅ All Phase 1 integration tests passing

### Phase 2 Success
- ✅ Shell can query service dependencies
- ✅ Shell can view service configuration
- ✅ Shell can reload service configuration
- ✅ All Phase 2 integration tests passing

### Phase 3 Success
- ✅ Shell can spawn supervised processes
- ✅ Shell can list processes
- ✅ Shell can signal processes
- ✅ All Phase 3 integration tests passing

### Phase 4 Success (END GOAL)
- ✅ Shell can view and follow service logs
- ✅ Shell can monitor all service statuses
- ✅ All integration tests passing
- ✅ **Usable Grainscript shell running on Vantage/Basin Kernel Framework x86_64**

---

## Risk Mitigation

### Risk 1: Init System Not Ready

**Mitigation**:
- Monitor Init System progress closely
- Adjust integration timeline based on Init System readiness
- Work on shell-side integration code in parallel (can be tested with mocks)

### Risk 2: API Contract Changes

**Mitigation**:
- Define API contracts early
- Document API contracts clearly
- Coordinate API changes through Core 1 Subcore and Vantage 3 Subcore
- Version API contracts if needed

### Risk 3: Cross-Subcore Coordination Delays

**Mitigation**:
- Establish clear communication channels
- Schedule regular check-ins
- Use Core 1 Subcore and Vantage 3 Subcore as coordination points
- Document all coordination decisions

---

## Next Steps

### Immediate (This Week)
1. **Agent 3d**: Complete Init System Phase 3 and Phase 4 (blocks integration)
2. **Agent 1e**: Complete basic shell functionality testing (prepares for integration)
3. **Core 1 Subcore & Vantage 3 Subcore**: Review and approve this integration plan

### Week 1-2 (When Ready)
1. **Agent 1e**: Create ServiceManager module
2. **Agent 1e**: Add service management built-ins
3. **Agent 3d**: Ensure Init System APIs are ready for shell integration
4. **Both Agents**: Begin Phase 1 implementation

### Ongoing
1. **Core 1 Subcore & Vantage 3 Subcore**: Monitor integration progress
2. **All Agents**: Coordinate on API contracts and implementation
3. **All Agents**: Update documentation as integration progresses

---

## Communication Plan

### Regular Check-Ins

**Weekly**:
- Core 1 Subcore ↔ Vantage 3 Subcore (integration status)
- Agent 1e ↔ Core 1 Subcore (shell progress)
- Agent 3d ↔ Vantage 3 Subcore (init system progress)

**Bi-Weekly**:
- Agent 1e ↔ Agent 3d (direct coordination on API contracts)
- All agents (integration planning session)

**As Needed**:
- API contract changes
- Blockers or conflicts
- Critical integration decisions

---

**Date**: 2026-01-02-084136-pst  
**Agents**: Grainscript Shell (1e) ↔ sevenos Init System (3d)  
**Coordination**: Core 1 Subcore (1) ↔ Vantage 3 Subcore (3)  
**Status**: ✅ **INTEGRATION PLAN COMPLETE** — Ready for review and implementation

