# Init System Integration Planning: sevenos Init System with Basin Kernel

**Date**: 2026-01-02-083246-pst  
**Agent**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**Purpose**: Integration planning document for sevenos Init System with Basin Kernel syscall integration  
**Target**: Supports Step 3 (Agent 3d Init System completion) when unblocked

---

## Executive Summary

This document provides comprehensive integration planning for implementing the sevenos Init System (Agent 3d) with Basin Kernel syscall integration. It covers service lifecycle management, dependency management, configuration loading, error handling, and testing strategies.

**Key Integration Points**:
- Basin Kernel syscall interface for process management
- Service lifecycle management patterns
- Dependency management integration
- Configuration loading patterns
- Error handling and recovery patterns
- Testing and validation approaches

---

## Architecture Overview

### Integration Flow

```
┌─────────────────────┐
│  sevenos Init      │
│  System (3d)       │
│  (Zig, x86_64)     │
└──────────┬──────────┘
           │
           │ Service Management
           ▼
┌─────────────────────┐
│  Basin Kernel       │
│  Syscalls (3a)      │
│  (RISC-V)           │
└──────────┬──────────┘
           │
           │ Process Operations
           ▼
┌─────────────────────┐
│  VM Runtime (3b)     │
│  JIT Execution       │
│  (x86_64)           │
└──────────┬──────────┘
           │
           │ Service Processes
           ▼
┌─────────────────────┐
│  Service Processes   │
│  (RISC-V, in VM)    │
└─────────────────────┘
```

### Component Integration

**1. Init System (Agent 3d)**
- Service supervision (S6-inspired)
- Dependency management
- Configuration loading
- Service lifecycle management

**2. Basin Kernel (Agent 3a)**
- Process management syscalls (`spawn`, `wait`, `exit`)
- Process group/session management (`setpgid`, `setsid`)
- Signal handling (`kill`, `signal`)
- Resource management (`set_resource_limit`, `get_resource_usage`)

**3. VM Runtime (Agent 3b)**
- JIT compilation for service processes
- VM execution environment
- Memory management

---

## Integration Patterns

### Pattern 1: Service Lifecycle Management

**Strategy**: Use Basin Kernel syscalls for process management

**Implementation**:
```zig
// In Init System (init/supervision.zig)
const Supervision = struct {
    kernel: *BasinKernel,
    
    fn start_service(self: *Supervision, config: ServiceConfig) !void {
        // 1. Load service executable
        const executable_ptr = try self.load_service_executable(config);
        
        // 2. Prepare service arguments
        const args_ptr = try self.prepare_service_args(config);
        const args_len = self.calculate_args_len(config);
        
        // 3. Spawn service process via Basin Kernel
        const result = try self.kernel.handle_syscall(
            @intFromEnum(Syscall.spawn),
            executable_ptr,
            args_ptr,
            args_len,
            0,
        );
        
        // 4. Extract process ID
        const pid = switch (result) {
            .ok => |value| value,
            .fail => |err| return handle_spawn_error(err),
        };
        
        // 5. Create process group for service
        try self.create_process_group(pid, config);
        
        // 6. Set resource limits
        try self.set_service_resource_limits(pid, config);
        
        // 7. Track service state
        self.services[config.name] = ServiceState{
            .pid = pid,
            .status = .running,
            .config = config,
        };
    }
    
    fn stop_service(self: *Supervision, name: []const u8) !void {
        const service = self.services.get(name) orelse return error.ServiceNotFound;
        
        // 1. Send SIGTERM to service process group
        const result = try self.kernel.handle_syscall(
            @intFromEnum(Syscall.kill),
            service.pid,
            @intFromEnum(Signal.SIGTERM),
            0,
            0,
        );
        
        // 2. Wait for service to exit
        const wait_result = try self.kernel.handle_syscall(
            @intFromEnum(Syscall.wait),
            service.pid,
            0,
            0,
            0,
        );
        
        // 3. Update service state
        service.status = .stopped;
    }
    
    fn restart_service(self: *Supervision, name: []const u8) !void {
        try self.stop_service(name);
        const config = self.services.get(name).?.config;
        try self.start_service(config);
    }
};
```

**Critical Syscalls**:
- `spawn` (1) - Spawn service process
- `wait` (4) - Wait for service exit
- `kill` (57) - Send signal to service
- `setpgid` (56) - Create process group
- `setsid` (58) - Create session

---

### Pattern 2: Dependency Management

**Strategy**: Resolve dependencies before starting services

**Implementation**:
```zig
// In Init System (init/dependency.zig)
const DependencyManager = struct {
    kernel: *BasinKernel,
    services: *ServiceRegistry,
    
    fn start_service_with_dependencies(
        self: *DependencyManager,
        config: ServiceConfig,
    ) !void {
        // 1. Resolve service dependencies
        const dependencies = try self.resolve_dependencies(config);
        
        // 2. Start dependencies first (recursive)
        for (dependencies) |dep_name| {
            const dep_config = self.services.get_config(dep_name);
            try self.start_service_with_dependencies(dep_config);
        }
        
        // 3. Wait for dependencies to be ready
        try self.wait_for_dependencies_ready(dependencies);
        
        // 4. Start service
        try self.supervision.start_service(config);
    }
    
    fn resolve_dependencies(
        self: *DependencyManager,
        config: ServiceConfig,
    ) ![]const []const u8 {
        // Parse dependencies from config
        var deps = std.ArrayList([]const u8).init(self.allocator);
        errdefer deps.deinit();
        
        for (config.dependencies) |dep_name| {
            try deps.append(dep_name);
        }
        
        return deps.toOwnedSlice();
    }
    
    fn wait_for_dependencies_ready(
        self: *DependencyManager,
        dependencies: []const []const u8,
    ) !void {
        // Wait for each dependency to be running
        for (dependencies) |dep_name| {
            const service = self.services.get(dep_name) orelse {
                return error.DependencyNotFound;
            };
            
            // Poll service status until ready
            while (service.status != .running) {
                // Check service status via Basin Kernel
                const result = try self.kernel.handle_syscall(
                    @intFromEnum(Syscall.get_process_info),
                    service.pid,
                    0,
                    0,
                    0,
                );
                
                // Update service status
                if (result.ok) |info| {
                    service.status = parse_process_status(info);
                }
                
                // Yield to allow other processes to run
                _ = try self.kernel.handle_syscall(
                    @intFromEnum(Syscall.yield),
                    0,
                    0,
                    0,
                    0,
                );
            }
        }
    }
};
```

**Dependency Resolution**:
1. Parse dependencies from service configuration
2. Build dependency graph
3. Topological sort for startup order
4. Start dependencies recursively
5. Wait for dependencies to be ready
6. Start service

---

### Pattern 3: Configuration Loading

**Strategy**: Load and validate service configuration from explicit config files

**Implementation**:
```zig
// In Init System (init/config/loader.zig)
const ConfigLoader = struct {
    allocator: Allocator,
    kernel: *BasinKernel,
    
    fn load_service_config(
        self: *ConfigLoader,
        config_path: []const u8,
    ) !ServiceConfig {
        // 1. Open configuration file
        const handle = try self.open_config_file(config_path);
        defer self.close_config_file(handle);
        
        // 2. Read configuration data
        const config_data = try self.read_config_data(handle);
        defer self.allocator.free(config_data);
        
        // 3. Parse configuration (JSON or custom format)
        const config = try self.parse_config(config_data);
        
        // 4. Validate configuration
        try self.validate_config(config);
        
        return config;
    }
    
    fn open_config_file(self: *ConfigLoader, path: []const u8) !Handle {
        // Use Basin Kernel file syscalls
        const result = try self.kernel.handle_syscall(
            @intFromEnum(Syscall.open),
            @ptrToInt(path.ptr),
            @intFromEnum(OpenFlags.read_only),
            0,
            0,
        );
        
        const handle = switch (result) {
            .ok => |value| Handle{ .value = value },
            .fail => |err| return handle_open_error(err),
        };
        
        return handle;
    }
    
    fn read_config_data(self: *ConfigLoader, handle: Handle) ![]u8 {
        // Read configuration file via Basin Kernel
        var buffer: [4096]u8 = undefined;
        const result = try self.kernel.handle_syscall(
            @intFromEnum(Syscall.read),
            handle.value,
            @ptrToInt(buffer.ptr),
            buffer.len,
            0,
        );
        
        const bytes_read = switch (result) {
            .ok => |value| value,
            .fail => |err| return handle_read_error(err),
        };
        
        // Allocate and copy data
        const data = try self.allocator.alloc(u8, bytes_read);
        @memcpy(data, buffer[0..bytes_read]);
        
        return data;
    }
    
    fn validate_config(self: *ConfigLoader, config: ServiceConfig) !void {
        // Validate service configuration
        if (config.name.len == 0) {
            return error.InvalidConfig;
        }
        
        if (config.executable.len == 0) {
            return error.InvalidConfig;
        }
        
        // Validate resource limits
        if (config.resource_limits.max_memory_bytes > MAX_MEMORY_LIMIT) {
            return error.InvalidConfig;
        }
        
        // Validate dependencies (check for cycles)
        try self.validate_dependency_graph(config);
    }
};
```

**Configuration Format** (Example):
```json
{
  "name": "network-service",
  "executable": "/services/network",
  "args": ["--port", "8080"],
  "dependencies": ["storage-service"],
  "resource_limits": {
    "max_memory_bytes": 1048576,
    "max_cpu_time_ns": 1000000000
  },
  "restart_policy": "always"
}
```

**Critical Syscalls**:
- `open` (20) - Open configuration file
- `read` (21) - Read configuration data
- `close` (23) - Close configuration file

---

### Pattern 4: Resource Management

**Strategy**: Set resource limits for services via Basin Kernel

**Implementation**:
```zig
// In Init System (init/supervision.zig)
fn set_service_resource_limits(
    self: *Supervision,
    pid: u64,
    config: ServiceConfig,
) !void {
    // Set memory limit
    const memory_limit = ResourceLimit{
        .resource_type = .memory,
        .max_bytes = config.resource_limits.max_memory_bytes,
    };
    
    const result = try self.kernel.handle_syscall(
        @intFromEnum(Syscall.set_resource_limit),
        pid,
        @ptrToInt(&memory_limit),
        @sizeOf(ResourceLimit),
        0,
    );
    
    switch (result) {
        .ok => {},
        .fail => |err| return handle_resource_limit_error(err),
    }
    
    // Set CPU time limit
    const cpu_limit = ResourceLimit{
        .resource_type = .cpu_time,
        .max_ns = config.resource_limits.max_cpu_time_ns,
    };
    
    const result2 = try self.kernel.handle_syscall(
        @intFromEnum(Syscall.set_resource_limit),
        pid,
        @ptrToInt(&cpu_limit),
        @sizeOf(ResourceLimit),
        0,
    );
    
    switch (result2) {
        .ok => {},
        .fail => |err| return handle_resource_limit_error(err),
    }
}

fn monitor_service_resources(
    self: *Supervision,
    pid: u64,
) !ResourceUsage {
    // Get resource usage via Basin Kernel
    const result = try self.kernel.handle_syscall(
        @intFromEnum(Syscall.get_resource_usage),
        pid,
        0,
        0,
        0,
    );
    
    const usage = switch (result) {
        .ok => |value| parse_resource_usage(value),
        .fail => |err| return handle_resource_usage_error(err),
    };
    
    return usage;
}
```

**Critical Syscalls**:
- `set_resource_limit` (140) - Set resource limits
- `get_resource_usage` (137) - Get resource usage

---

## Error Handling Patterns

### Pattern 1: Service Startup Errors

**Strategy**: Fail-fast with clear error messages

**Implementation**:
```zig
fn handle_spawn_error(err: BasinError) InitSystemError {
    return switch (err) {
        .invalid_argument => InitSystemError.InvalidExecutable,
        .out_of_memory => InitSystemError.OutOfMemory,
        .process_not_found => InitSystemError.ExecutableNotFound,
        .too_many_processes => InitSystemError.TooManyProcesses,
        else => InitSystemError.UnknownError,
    };
}

fn start_service(self: *Supervision, config: ServiceConfig) !void {
    const pid = self.spawn_service(config) catch |err| {
        // Log error
        std.log.err("Failed to start service '{s}': {s}", .{
            config.name,
            @errorName(err),
        });
        
        // Update service state
        self.services[config.name].status = .failed;
        self.services[config.name].error = err;
        
        return err;
    };
    
    // Service started successfully
    self.services[config.name].pid = pid;
    self.services[config.name].status = .running;
}
```

### Pattern 2: Service Restart on Failure

**Strategy**: Restart service based on restart policy

**Implementation**:
```zig
fn monitor_service(self: *Supervision, name: []const u8) !void {
    const service = self.services.get(name) orelse return error.ServiceNotFound;
    
    // Wait for service to exit
    const wait_result = try self.kernel.handle_syscall(
        @intFromEnum(Syscall.wait),
        service.pid,
        0,
        0,
        0,
    );
    
    const exit_code = switch (wait_result) {
        .ok => |value| value,
        .fail => |err| return handle_wait_error(err),
    };
    
    // Check restart policy
    if (service.config.restart_policy == .always) {
        // Restart service
        try self.restart_service(name);
    } else if (service.config.restart_policy == .on_failure and exit_code != 0) {
        // Restart on failure
        try self.restart_service(name);
    } else {
        // Don't restart
        service.status = .stopped;
    }
}
```

---

## Testing Strategy

### Unit Tests

**Test Coverage**:
1. **Service Lifecycle**: Test service start/stop/restart
2. **Dependency Management**: Test dependency resolution and startup order
3. **Configuration Loading**: Test config loading and validation
4. **Resource Management**: Test resource limit setting and monitoring
5. **Error Handling**: Test error handling for all error cases

**Test Files**:
- `tests/166_init_service_lifecycle_test.zig` - Service lifecycle tests
- `tests/167_init_dependency_test.zig` - Dependency management tests
- `tests/168_init_config_test.zig` - Configuration loading tests
- `tests/169_init_resource_test.zig` - Resource management tests

### Integration Tests

**Test Coverage**:
1. **End-to-End Service Management**: Test complete service lifecycle
2. **Dependency Resolution**: Test complex dependency graphs
3. **Error Recovery**: Test service restart on failure
4. **Resource Limits**: Test resource limit enforcement

**Test Files**:
- `tests/170_init_integration_test.zig` - End-to-end integration tests
- `tests/171_init_dependency_integration_test.zig` - Dependency integration tests

### Framework x86_64 Testing

**Test Coverage**:
1. **Framework x86_64 AMD**: Test on Framework 16 (x86_64 AMD)
2. **Service Execution**: Test service execution in VM Runtime
3. **JIT Integration**: Test JIT compilation for service processes

**Test Files**:
- `tests/172_init_framework_x86_64_test.zig` - Framework x86_64 tests

---

## Coordination Points

### With Agent 3a (Basin Kernel)

**Coordination Needs**:
- ✅ Syscall interface documentation (COMPLETE)
- ✅ Process management syscall requirements
- ✅ Resource management syscall requirements
- ✅ Signal handling syscall requirements

**Coordination Timeline**:
- **Step 1 (THIS WEEK)**: Agent 3a distributes syscall docs
- **Step 3 (WEEK 1-2)**: Agent 3d implements Init System with syscall integration

### With Agent 3b (VM Runtime)

**Coordination Needs**:
- JIT compilation for service processes
- VM execution environment
- Memory management

**Coordination Timeline**:
- **Step 2 (WEEK 1-2)**: Agent 3b implements JIT
- **Step 3 (WEEK 1-2)**: Agent 3d integrates with JIT for service execution

### With Agent 1e (Grainscript Shell) - Cross-Subcore

**Coordination Needs**:
- Shell integration with Init System
- Service management commands
- Process supervision integration

**Coordination Timeline**:
- **Step 3 (WEEK 1-2)**: Agent 3d completes Init System
- **Step 4 (WEEK 1-2)**: Agent 1e integrates with Init System (via Core 1 Subcore)

### With Agent 3c (System Integration)

**Coordination Needs**:
- Integration testing
- Multi-architecture testing
- End-to-end testing

**Coordination Timeline**:
- **Step 5 (WEEK 1-2)**: Agent 3c implements multi-arch testing framework
- **After Step 3**: Agent 3d coordinates testing with Agent 3c

---

## Implementation Roadmap

### Phase 1: Fix Compilation Issue (THIS WEEK)

**Tasks**:
1. Fix dependency manager compilation issue (Zig 0.15.2 ArrayList initialization)
2. Verify all existing code compiles
3. Run existing tests

**Success Criteria**:
- ✅ All code compiles without errors
- ✅ All existing tests pass

### Phase 2: Basin Kernel Syscall Integration (WEEK 1-2)

**Tasks**:
1. ✅ Receive syscall interface docs from Agent 3a (Step 1)
2. Integrate `spawn` syscall for service startup
3. Integrate `wait` syscall for service monitoring
4. Integrate `kill` syscall for service shutdown
5. Integrate `setpgid`/`setsid` for process group management
6. Integrate `set_resource_limit`/`get_resource_usage` for resource management

**Success Criteria**:
- ✅ Services can be spawned via Basin Kernel
- ✅ Services can be monitored via Basin Kernel
- ✅ Services can be stopped via Basin Kernel
- ✅ Resource limits can be set and monitored

### Phase 3: Main Init Loop (WEEK 1-2)

**Tasks**:
1. Implement main init loop
2. Integrate service supervision
3. Integrate dependency management
4. Integrate configuration loading
5. Implement service monitoring and restart

**Success Criteria**:
- ✅ Main init loop running
- ✅ Services supervised correctly
- ✅ Dependencies resolved correctly
- ✅ Services restart on failure

### Phase 4: Integration Testing (WEEK 2-3)

**Tasks**:
1. Integration testing with Basin Kernel
2. Integration testing with VM Runtime JIT
3. Integration testing with Grainscript Shell (Agent 1e)
4. Framework x86_64 testing

**Success Criteria**:
- ✅ All integration tests passing
- ✅ Services running on Framework x86_64
- ✅ Shell integration working

---

## Success Criteria

### Week 1 Success
- ✅ Compilation issues fixed
- ✅ Basin Kernel syscall integration started
- ✅ Basic service lifecycle working

### Week 2 Success
- ✅ Basin Kernel syscall integration complete
- ✅ Main init loop implemented
- ✅ Service supervision working
- ✅ Dependency management working

### Week 3 Success
- ✅ Configuration loading complete
- ✅ Resource management complete
- ✅ Integration tests passing

### Week 4 Success
- ✅ Grainscript Shell integration complete
- ✅ Framework x86_64 testing passing
- ✅ Documentation complete

---

## Risks and Mitigations

### Risk 1: Syscall Integration Complexity

**Mitigation**: Use Agent 3a's syscall interface documentation, start with simple syscalls, expand gradually

### Risk 2: Dependency Resolution Complexity

**Mitigation**: Start with simple dependency graphs, add cycle detection, test with complex graphs

### Risk 3: Configuration Loading Errors

**Mitigation**: Validate configuration early, provide clear error messages, test with various config formats

---

## Summary

**Integration Approach**:
1. **Basin Kernel Syscalls**: Use for process management, resource management, signal handling
2. **Service Lifecycle**: Start/stop/restart services via syscalls
3. **Dependency Management**: Resolve dependencies before starting services
4. **Configuration Loading**: Load and validate service configuration
5. **Resource Management**: Set and monitor resource limits

**Key Integration Points**:
- Init System uses Basin Kernel syscalls for all process operations
- Services run in VM Runtime with JIT compilation
- Shell integrates with Init System for service management

**Testing Strategy**:
- Unit tests for service lifecycle, dependencies, configuration
- Integration tests for end-to-end service management
- Framework x86_64 testing for real hardware

**Coordination**:
- Agent 3a: Syscall interface docs (Step 1)
- Agent 3b: JIT integration (Step 2)
- Agent 3d: Init System implementation (Step 3)
- Agent 1e: Shell integration (Step 4, cross-subcore)

---

**Date**: 2026-01-02-083246-pst  
**Agent**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**Status**: ✅ **INTEGRATION PLANNING COMPLETE** — Ready to support Agent 3d Init System implementation

