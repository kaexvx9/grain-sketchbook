# Cross-Subcore Integration Planning: Grainscript Shell ↔ sevenos Init System

**Date**: 2026-01-02-083246-pst  
**Agent**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**Purpose**: Integration planning document for cross-subcore integration between Grainscript Shell (1e) and sevenos Init System (3d)  
**Target**: Supports Step 4 (Grainscript Shell integration) when Step 3 completes

---

## Executive Summary

This document provides comprehensive integration planning for cross-subcore integration between **Grainscript Shell (Agent 1e, Core 1 Subcore)** and **sevenos Init System (Agent 3d, Vantage 3 Subcore)**. This integration enables the shell to interact with the Init System for service management, process supervision, and system control.

**Key Integration Points**:
- Shell as Init System client pattern
- Service management API integration
- Process spawning integration
- Dependency management integration
- Configuration management integration
- Cross-subcore coordination patterns

**Critical Path Dependency**: This integration is **Step 4** of the single-threaded computation priority chain, blocked on:
- **Step 3**: Init System (3d) must complete Phase 3 (dependency manager) and Phase 4 (main init loop) and integrate with Basin Kernel syscalls

---

## Architecture Overview

### Integration Flow

```
┌─────────────────────┐
│  Grainscript Shell  │
│  (1e, Core 1)       │
│  (Zig, x86_64)      │
└──────────┬──────────┘
           │
           │ Service Management API
           ▼
┌─────────────────────┐
│  Service Manager    │
│  (shell module)     │
└──────────┬──────────┘
           │
           │ Direct Function Calls
           ▼
┌─────────────────────┐
│  sevenos Init       │
│  System (3d)        │
│  (Vantage 3)        │
└──────────┬──────────┘
           │
           │ Basin Kernel Syscalls
           ▼
┌─────────────────────┐
│  Basin Kernel (3a)  │
│  (RISC-V)           │
└─────────────────────┘
```

### Component Integration

**1. Grainscript Shell (Agent 1e, Core 1 Subcore)**
- Service management built-in commands
- Service Manager module (`shell/service_manager.zig`)
- Process spawning integration
- Configuration management integration

**2. sevenos Init System (Agent 3d, Vantage 3 Subcore)**
- Service supervision APIs
- Dependency management APIs
- Configuration loader APIs
- Process management APIs

**3. Basin Kernel (Agent 3a, Vantage 3 Subcore)**
- Process management syscalls
- Resource management syscalls
- Signal handling syscalls

---

## Integration Patterns

### Pattern 1: Shell as Init System Client

**Strategy**: Shell interacts with Init System as a client via direct function calls

**Implementation**:
```zig
// In Shell (shell/service_manager.zig)
const ServiceManager = struct {
    supervisor: *supervision.Supervisor,
    dependency_graph: *dependency.DependencyGraph,
    config_loader: *config.ConfigLoader,
    allocator: Allocator,
    
    pub fn get_service_status(
        self: *ServiceManager,
        service_name: []const u8,
    ) !supervision.ServiceState {
        // Query Init System Supervisor
        return self.supervisor.get_service_status(service_name);
    }
    
    pub fn start_service(
        self: *ServiceManager,
        service_name: []const u8,
    ) !void {
        // Start service via Init System Supervisor
        try self.supervisor.start_service(service_name);
    }
    
    pub fn stop_service(
        self: *ServiceManager,
        service_name: []const u8,
    ) !void {
        // Stop service via Init System Supervisor
        try self.supervisor.stop_service(service_name);
    }
    
    pub fn restart_service(
        self: *ServiceManager,
        service_name: []const u8,
    ) !void {
        // Restart service via Init System Supervisor
        try self.supervisor.restart_service(service_name);
    }
    
    pub fn list_services(
        self: *ServiceManager,
    ) ![]const ServiceInfo {
        // List all services from Init System Supervisor
        return self.supervisor.list_services();
    }
};
```

**Benefits**:
- ✅ Simple implementation (direct function calls)
- ✅ No IPC overhead
- ✅ Type-safe API contracts
- ✅ Easy to test and debug

**Considerations**:
- ⚠️ Requires same process (shell and init system in same process)
- ✅ Can migrate to IPC later if needed

---

### Pattern 2: Service Management Commands

**Strategy**: Add service management built-in commands to shell

**Implementation**:
```zig
// In Shell (shell/builtins.zig)
pub fn execute_service_command(
    self: *Shell,
    args: []const []const u8,
) !void {
    if (args.len < 2) {
        try self.print_error("Usage: service <command> [args]");
        return;
    }
    
    const command = args[1];
    
    if (std.mem.eql(u8, command, "status")) {
        try self.handle_service_status(args);
    } else if (std.mem.eql(u8, command, "start")) {
        try self.handle_service_start(args);
    } else if (std.mem.eql(u8, command, "stop")) {
        try self.handle_service_stop(args);
    } else if (std.mem.eql(u8, command, "restart")) {
        try self.handle_service_restart(args);
    } else if (std.mem.eql(u8, command, "list")) {
        try self.handle_service_list();
    } else {
        try self.print_error("Unknown service command: {s}", .{command});
    }
}

fn handle_service_status(self: *Shell, args: []const []const u8) !void {
    if (args.len < 3) {
        try self.print_error("Usage: service status <service_name>");
        return;
    }
    
    const service_name = args[2];
    const status = try self.service_manager.get_service_status(service_name);
    
    // Format and display status
    try self.print_service_status(service_name, status);
}

fn handle_service_start(self: *Shell, args: []const []const u8) !void {
    if (args.len < 3) {
        try self.print_error("Usage: service start <service_name>");
        return;
    }
    
    const service_name = args[2];
    try self.service_manager.start_service(service_name);
    try self.print("Service '{s}' started", .{service_name});
}
```

**Commands**:
- `service status [service_name]` - Query service status
- `service start <service_name>` - Start a service
- `service stop <service_name>` - Stop a service
- `service restart <service_name>` - Restart a service
- `service list` - List all services
- `service logs <service_name>` - View service logs
- `service deps <service_name>` - Show service dependencies
- `service config <service_name>` - View service configuration

---

### Pattern 3: Process Spawning Integration

**Strategy**: Shell can spawn processes through Init System for supervision

**Implementation**:
```zig
// In Shell (shell/executor.zig)
fn execute_command(
    self: *Shell,
    command: Command,
) !void {
    // Check if command should be supervised
    if (command.supervised) {
        // Spawn through Init System
        try self.spawn_supervised_process(command);
    } else {
        // Spawn directly (current behavior)
        try self.spawn_direct_process(command);
    }
}

fn spawn_supervised_process(
    self: *Shell,
    command: Command,
) !void {
    // Create service config for command
    const service_config = ServiceConfig{
        .name = command.name,
        .executable = command.executable,
        .args = command.args,
        .supervised = true,
    };
    
    // Spawn via Init System Supervisor
    try self.service_manager.supervisor.spawn_supervised_process(service_config);
}
```

**Use Cases**:
- Long-running processes (should be supervised)
- Processes that need resource limits
- Processes that need dependency management
- Processes that need automatic restart

---

### Pattern 4: Dependency Management Integration

**Strategy**: Shell can query and manage service dependencies

**Implementation**:
```zig
// In Shell (shell/service_manager.zig)
pub fn get_service_dependencies(
    self: *ServiceManager,
    service_name: []const u8,
) ![]const []const u8 {
    // Query Init System DependencyGraph
    return self.dependency_graph.get_service_dependencies(service_name);
}

pub fn get_dependency_tree(
    self: *ServiceManager,
) !DependencyTree {
    // Get full dependency tree from Init System
    return self.dependency_graph.get_dependency_tree();
}
```

**Commands**:
- `service deps <service_name>` - Show service dependencies
- `service tree` - Show service dependency tree

---

### Pattern 5: Configuration Management Integration

**Strategy**: Shell can view and reload service configuration

**Implementation**:
```zig
// In Shell (shell/service_manager.zig)
pub fn get_service_config(
    self: *ServiceManager,
    service_name: []const u8,
) !?config.ServiceConfig {
    // Query Init System ConfigLoader
    return self.config_loader.get_service_config(service_name);
}

pub fn reload_service_config(
    self: *ServiceManager,
    service_name: []const u8,
) !void {
    // Reload service configuration via Init System
    try self.config_loader.reload_service_config(service_name);
    
    // Restart service if running
    const status = try self.supervisor.get_service_status(service_name);
    if (status == .running) {
        try self.supervisor.restart_service(service_name);
    }
}
```

**Commands**:
- `service config <service_name>` - View service configuration
- `service reload <service_name>` - Reload service configuration

---

## Error Handling Patterns

### Pattern 1: Service Not Found

**Strategy**: Clear error messages for service not found

**Implementation**:
```zig
fn handle_service_start(self: *Shell, args: []const []const u8) !void {
    const service_name = args[2];
    
    self.service_manager.start_service(service_name) catch |err| {
        switch (err) {
            error.ServiceNotFound => {
                try self.print_error("Service '{s}' not found", .{service_name});
                try self.print("Use 'service list' to see available services");
            },
            error.DependencyNotMet => {
                try self.print_error("Service '{s}' dependencies not met", .{service_name});
                try self.print("Use 'service deps {s}' to see dependencies", .{service_name});
            },
            else => {
                try self.print_error("Failed to start service '{s}': {s}", .{
                    service_name,
                    @errorName(err),
                });
            },
        }
        return err;
    };
}
```

### Pattern 2: Dependency Resolution Errors

**Strategy**: Help users understand and resolve dependency issues

**Implementation**:
```zig
fn handle_service_start_with_deps(self: *Shell, args: []const []const u8) !void {
    const service_name = args[2];
    
    // Try to start service
    self.service_manager.start_service(service_name) catch |err| {
        if (err == error.DependencyNotMet) {
            // Show dependencies
            const deps = try self.service_manager.get_service_dependencies(service_name);
            try self.print_error("Service '{s}' requires:", .{service_name});
            for (deps) |dep| {
                try self.print("  - {s}", .{dep});
            }
            
            // Suggest starting dependencies
            try self.print("Start dependencies first:");
            for (deps) |dep| {
                try self.print("  service start {s}", .{dep});
            }
        }
        return err;
    };
}
```

---

## Testing Strategy

### Unit Tests

**Test Coverage**:
1. **Service Manager**: Test service operations (status, start, stop, restart, list)
2. **Shell Built-ins**: Test service command parsing and execution
3. **Error Handling**: Test error handling for all error cases
4. **Dependency Management**: Test dependency queries and resolution
5. **Configuration Management**: Test configuration viewing and reloading

**Test Files**:
- `tests/173_shell_service_manager_test.zig` - Service Manager tests
- `tests/174_shell_service_builtins_test.zig` - Service built-in command tests
- `tests/175_shell_service_error_test.zig` - Error handling tests

### Integration Tests

**Test Coverage**:
1. **Shell ↔ Init System Integration**: Test complete service management flow
2. **Process Spawning**: Test supervised process spawning
3. **Dependency Resolution**: Test dependency resolution from shell
4. **Configuration Management**: Test configuration viewing and reloading
5. **Error Recovery**: Test error recovery and user guidance

**Test Files**:
- `tests/176_shell_init_integration_test.zig` - Shell ↔ Init System integration tests
- `tests/177_shell_process_spawning_test.zig` - Process spawning integration tests

### Framework x86_64 Testing

**Test Coverage**:
1. **Framework x86_64 AMD**: Test on Framework 16 (x86_64 AMD)
2. **End-to-End**: Test complete shell → Init System → Kernel flow
3. **Performance**: Test service management performance

**Test Files**:
- `tests/178_shell_framework_x86_64_test.zig` - Framework x86_64 tests

---

## Coordination Points

### Cross-Subcore Coordination

**Core 1 Subcore (Agent 1) ↔ Vantage 3 Subcore (Agent 3)**:
- Weekly check-ins on integration progress
- Bi-weekly deep dives on API contracts
- Immediate check-ins for blockers or conflicts
- Coordination on integration timeline

**Coordination Schedule**:
- **Weekly**: Integration status check-ins
- **Bi-Weekly**: API contract reviews
- **As Needed**: Blocker resolution

### Agent Coordination

**Agent 1e (Grainscript Shell) ↔ Agent 3d (sevenos Init System)**:
- Direct coordination on API contracts
- Coordination on implementation timeline
- Coordination on testing strategy

**Coordination Schedule**:
- **Bi-Weekly**: Direct coordination on API contracts
- **As Needed**: Implementation questions and blockers

### With Other Agents

**Agent 3a (Basin Kernel)**:
- Syscall interface for process management
- Resource management syscalls
- Signal handling syscalls

**Agent 3b (VM Runtime)**:
- JIT compilation for service processes
- VM execution environment

**Agent 3c (System Integration)**:
- Integration testing framework
- Multi-architecture testing

---

## Implementation Roadmap

### Phase 1: Basic Service Management (Week 1-2)

**Tasks**:
1. **Agent 3d**: Complete Init System Phase 4 (main init loop) - **BLOCKS**
2. **Agent 1e**: Create ServiceManager module (`shell/service_manager.zig`)
3. **Agent 1e**: Add service management built-in commands
4. **Both Agents**: Test basic service management integration

**Success Criteria**:
- ✅ ServiceManager module complete
- ✅ Service management built-in commands working
- ✅ Shell can query and control services
- ✅ Basic integration tests passing

**Dependencies**:
- Init System Phase 4 (main init loop) complete
- Init System Supervisor APIs ready

### Phase 2: Advanced Service Management (Week 2-3)

**Tasks**:
1. **Agent 1e**: Add dependency management commands
2. **Agent 1e**: Add configuration management commands
3. **Both Agents**: Test advanced service management integration

**Success Criteria**:
- ✅ Dependency management commands working
- ✅ Configuration management commands working
- ✅ Advanced integration tests passing

**Dependencies**:
- Phase 1 complete
- Init System dependency manager complete
- Init System config loader complete

### Phase 3: Process Spawning Integration (Week 3-4)

**Tasks**:
1. **Agent 1e**: Add supervised process spawning
2. **Agent 1e**: Add process management commands
3. **Both Agents**: Test process spawning integration

**Success Criteria**:
- ✅ Supervised process spawning working
- ✅ Process management commands working
- ✅ Process integration tests passing

**Dependencies**:
- Phase 2 complete
- Init System Basin Kernel syscall integration complete

### Phase 4: Logging and Monitoring (Week 4)

**Tasks**:
1. **Agent 1e**: Add logging commands
2. **Agent 1e**: Add status monitoring commands
3. **Both Agents**: Test logging and monitoring integration

**Success Criteria**:
- ✅ Logging commands working
- ✅ Status monitoring working
- ✅ All integration tests passing
- ✅ **END GOAL**: Usable Grainscript shell with Init System integration

**Dependencies**:
- Phase 3 complete
- Init System logging system complete

---

## Success Criteria

### Week 1-2 Success
- ✅ ServiceManager module created
- ✅ Service management built-in commands implemented
- ✅ Shell can query and control services
- ✅ Basic integration tests passing

### Week 2-3 Success
- ✅ Dependency management commands working
- ✅ Configuration management commands working
- ✅ Advanced integration tests passing

### Week 3-4 Success
- ✅ Supervised process spawning working
- ✅ Process management commands working
- ✅ Process integration tests passing

### Week 4 Success (END GOAL)
- ✅ Logging commands working
- ✅ Status monitoring working
- ✅ All integration tests passing
- ✅ **Usable Grainscript shell running on Vantage/Basin Kernel Framework x86_64**

---

## Risks and Mitigations

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

## Summary

**Integration Approach**:
1. **Shell as Client**: Shell interacts with Init System as a client
2. **Direct Function Calls**: Simple implementation, no IPC overhead
3. **Service Management**: Complete service lifecycle management
4. **Process Spawning**: Supervised process spawning support
5. **Dependency Management**: Dependency queries and resolution
6. **Configuration Management**: Configuration viewing and reloading

**Key Integration Points**:
- ServiceManager module in shell wraps Init System APIs
- Service management built-in commands in shell
- Process spawning integration for supervised processes
- Dependency and configuration management integration

**Testing Strategy**:
- Unit tests for ServiceManager and built-in commands
- Integration tests for shell ↔ Init System integration
- Framework x86_64 testing for real hardware

**Coordination**:
- Core 1 Subcore ↔ Vantage 3 Subcore: Cross-subcore coordination
- Agent 1e ↔ Agent 3d: Direct coordination on API contracts
- Weekly check-ins and bi-weekly deep dives

---

**Date**: 2026-01-02-083246-pst  
**Agent**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**Status**: ✅ **INTEGRATION PLANNING COMPLETE** — Ready to support cross-subcore integration when Step 3 completes

