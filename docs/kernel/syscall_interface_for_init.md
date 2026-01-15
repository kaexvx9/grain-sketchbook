# Basin Kernel Syscall Interface for sevenos Init System

**Date**: 2026-01-01-233240-pst  
**Agent**: Grain Basin Kernel Agent (3a)  
**Target**: sevenos Init System Agent (3d)  
**Purpose**: Init system-specific syscall interface documentation for Grain OS sevenos

---

## Overview

This document provides init system-specific syscall interface documentation for implementing the sevenos Init System. It focuses on syscalls needed for service management, process supervision, resource management, and system initialization.

---

## Critical Syscalls for Init System

### 1. Process Management

#### `spawn` (1) - Spawn Service Process
**Purpose**: Spawn a new service process from ELF executable

**Usage in Init System**:
- Spawn service processes from service configuration
- Execute service binaries
- Create service process hierarchy

**Arguments**:
- `arg1: u64` - Executable pointer (VM memory address, ELF binary)
- `arg2: u64` - Arguments pointer (VM memory address, null-terminated strings)
- `arg3: u64` - Arguments length (bytes)
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(pid: u64)` - Process ID on success

**Errors**: `invalid_argument`, `out_of_memory`, `process_not_found`, `too_many_processes`

**Init System Pattern**:
```zig
// Read service executable from configuration
const executable_ptr = read_service_executable(service_config);

// Prepare service arguments
const args_ptr = prepare_service_args(service_config);
const args_len = calculate_args_len(service_config);

// Spawn service process
const result = kernel.handle_syscall(
    @intFromEnum(Syscall.spawn),
    executable_ptr,
    args_ptr,
    args_len,
    0,
);

// Extract process ID
const pid = switch (result) {
    .success => |value| value,
    .err => |err| return handle_spawn_error(err),
};
```

#### `wait` (4) - Wait for Service Exit
**Purpose**: Wait for child service process to exit

**Usage in Init System**:
- Wait for service process termination
- Monitor service lifecycle
- Handle service exit codes

**Arguments**:
- `arg1: u64` - Process ID (0 = any child)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(exit_code: u64)` - Exit code on success

**Errors**: `process_not_found`, `interrupted`

**Init System Pattern**:
```zig
// Wait for service process to exit
const result = kernel.handle_syscall(
    @intFromEnum(Syscall.wait),
    pid,
    0,
    0,
    0,
);

// Handle service exit
const exit_code = switch (result) {
    .success => |value| value,
    .err => |err| return handle_wait_error(err),
};

// Restart service if needed (based on service configuration)
if (service_config.restart_on_exit) {
    restart_service(service_config);
}
```

#### `exit` (2) - Exit Init System
**Purpose**: Exit init system process (shutdown)

**Usage in Init System**:
- System shutdown
- Init system termination

**Arguments**:
- `arg1: u64` - Exit code
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: Never returns (process exits)

---

### 2. Process Group & Session Management

#### `setpgid` (56) - Set Process Group ID
**Purpose**: Set process group ID for service

**Usage in Init System**:
- Create process groups for services
- Manage service process groups
- Enable signal delivery to process groups

**Arguments**:
- `arg1: u64` - Process ID (0 = current process)
- `arg2: u64` - Process group ID
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `process_not_found`, `permission_denied`

**Init System Pattern**:
```zig
// Create process group for service
const pgid = allocate_process_group_id();

const result = kernel.handle_syscall(
    @intFromEnum(Syscall.setpgid),
    pid,
    pgid,
    0,
    0,
);

switch (result) {
    .success => {},
    .err => |err| return handle_setpgid_error(err),
}
```

#### `setsid` (58) - Create New Session
**Purpose**: Create new session for service

**Usage in Init System**:
- Create sessions for services
- Enable terminal management
- Isolate service sessions

**Arguments**:
- `arg1: u64` - Unused
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(sid: u64)` - Session ID on success

**Errors**: `permission_denied`

**Init System Pattern**:
```zig
// Create session for service (after spawn, before exec)
const result = kernel.handle_syscall(
    @intFromEnum(Syscall.setsid),
    0,
    0,
    0,
    0,
);

const sid = switch (result) {
    .success => |value| value,
    .err => |err| return handle_setsid_error(err),
};
```

#### `getpgid` (57) - Get Process Group ID
**Purpose**: Get process group ID

**Usage in Init System**:
- Query service process group
- Verify process group assignment

#### `getsid` (59) - Get Session ID
**Purpose**: Get session ID

**Usage in Init System**:
- Query service session
- Verify session assignment

---

### 3. File I/O for Service Configuration

#### `open` (30) - Open Service Configuration File
**Purpose**: Open service configuration file

**Usage in Init System**:
- Read service configuration files
- Load service definitions
- Parse service settings

**Arguments**:
- `arg1: u64` - Path pointer (VM memory address, null-terminated string)
- `arg2: u64` - Path length (bytes, max 4096)
- `arg3: u64` - Flags (OpenFlags: read=true, write=false, create=false, truncate=false)
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(handle: u64)` - File handle on success

**Errors**: `invalid_argument`, `not_found`, `permission_denied`, `too_many_files`

**Init System Pattern**:
```zig
// Open service configuration file
const config_path = "/etc/sevenos/services/my_service.conf";
const path_ptr = string_to_vm_memory(config_path);
const path_len = config_path.len;

const flags = OpenFlags.init(.{ .read = true });
const flags_u64 = @as(u64, @bitCast(@as(u32, @truncate(@intFromEnum(flags)))));

const result = kernel.handle_syscall(
    @intFromEnum(Syscall.open),
    path_ptr,
    path_len,
    flags_u64,
    0,
);

const config_handle = switch (result) {
    .success => |value| value,
    .err => |err| return handle_open_error(err),
};
```

#### `read` (31) - Read Service Configuration
**Purpose**: Read service configuration data

**Usage in Init System**:
- Read service configuration file contents
- Parse service definitions
- Load service settings

**Arguments**:
- `arg1: u64` - File handle
- `arg2: u64` - Buffer pointer (VM memory address)
- `arg3: u64` - Buffer size (bytes)
- `arg4: u64` - Timeout (nanoseconds, 0 = no timeout)

**Returns**: `SyscallResult.ok(size: u64)` - Bytes read on success

**Errors**: `invalid_handle`, `invalid_argument`, `file_io_timeout`, `interrupted`

#### `close` (33) - Close Configuration File
**Purpose**: Close service configuration file

**Usage in Init System**:
- Close configuration file after reading
- Release file handles

**Arguments**:
- `arg1: u64` - File handle
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_handle`

---

### 4. Signal Handling

#### `kill` (80) - Send Signal to Service
**Purpose**: Send signal to service process

**Usage in Init System**:
- Stop service (SIGTERM)
- Kill service (SIGKILL)
- Reload service (SIGHUP)
- Restart service

**Arguments**:
- `arg1: u64` - Process ID
- `arg2: u64` - Signal number
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `process_not_found`, `permission_denied`

**Init System Pattern**:
```zig
// Stop service (send SIGTERM)
const result = kernel.handle_syscall(
    @intFromEnum(Syscall.kill),
    pid,
    SIGTERM, // Signal number
    0,
    0,
);

switch (result) {
    .success => {},
    .err => |err| return handle_kill_error(err),
}

// Wait for service to exit gracefully
wait_for_service_exit(pid, timeout);
```

#### `signal` (81) - Set Signal Handler
**Purpose**: Set signal handler for init system

**Usage in Init System**:
- Handle shutdown signals (SIGTERM, SIGINT)
- Handle reload signals (SIGHUP)
- Handle service management signals

**Arguments**:
- `arg1: u64` - Signal number
- `arg2: u64` - Handler pointer (VM memory address, function pointer)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `invalid_address`

---

### 5. Resource Management

#### `set_resource_limit` (140) - Set Service Resource Limits
**Purpose**: Set resource limits for service process

**Usage in Init System**:
- Set CPU limits for services
- Set memory limits for services
- Set file descriptor limits
- Set network connection limits

**Arguments**:
- `arg1: u64` - Process ID (0 = current process)
- `arg2: u64` - Resource type (0=CPU, 1=Memory, 2=Files, 3=Connections)
- `arg3: u64` - Limit value
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `process_not_found`, `permission_denied`

**Init System Pattern**:
```zig
// Set memory limit for service (e.g., 256MB)
const result = kernel.handle_syscall(
    @intFromEnum(Syscall.set_resource_limit),
    pid,
    1, // Resource type: Memory
    256 * 1024 * 1024, // Limit: 256MB
    0,
);

switch (result) {
    .success => {},
    .err => |err| return handle_set_limit_error(err),
}
```

#### `get_resource_usage` (137) - Get Service Resource Usage
**Purpose**: Get resource usage for service process

**Usage in Init System**:
- Monitor service resource usage
- Track CPU time
- Track memory usage
- Track file descriptors
- Track network connections

**Arguments**:
- `arg1: u64` - Process ID (0 = current process)
- `arg2: u64` - ResourceUsage pointer (VM memory address)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `process_not_found`, `invalid_address`

**Init System Pattern**:
```zig
// Get resource usage for service
var usage: ResourceUsage = ResourceUsage.init();
const usage_ptr = @intFromPtr(&usage);

const result = kernel.handle_syscall(
    @intFromEnum(Syscall.get_resource_usage),
    pid,
    usage_ptr,
    0,
    0,
);

switch (result) {
    .success => {},
    .err => |err| return handle_get_usage_error(err),
}

// Check if service exceeds limits
if (usage.memory_used > service_config.memory_limit) {
    handle_memory_limit_exceeded(pid);
}
```

---

### 6. Time & Scheduling

#### `clock_gettime` (40) - Get Current Time
**Purpose**: Get current time for service timing

**Usage in Init System**:
- Service startup timing
- Service restart timing
- Service timeout management
- Service scheduling

**Arguments**:
- `arg1: u64` - Clock ID (0=monotonic, 1=realtime)
- `arg2: u64` - Time pointer (VM memory address, writes `u64` nanoseconds)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `invalid_address`

#### `sleep_until` (41) - Sleep Until Time
**Purpose**: Sleep until specified time

**Usage in Init System**:
- Service restart delays
- Service scheduling
- Timeout management

---

### 7. System Information

#### `sysinfo` (50) - Get System Information
**Purpose**: Get system information for monitoring

**Usage in Init System**:
- System health monitoring
- Resource availability checking
- System load monitoring

**Arguments**:
- `arg1: u64` - SysInfo pointer (VM memory address)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `invalid_address`

#### `enumerate_processes` (51) - Enumerate All Processes
**Purpose**: Enumerate all processes for monitoring

**Usage in Init System**:
- Service process monitoring
- Process health checking
- Process count tracking

#### `get_process_info` (52) - Get Process Information
**Purpose**: Get process information for service

**Usage in Init System**:
- Service process status
- Process state checking
- Process monitoring

---

## Init System Service Management Pattern

### Service Lifecycle

**1. Service Startup**:
```zig
// 1. Read service configuration
const config = read_service_config(service_name);

// 2. Spawn service process
const pid = spawn_service(config);

// 3. Set process group
set_service_process_group(pid, config);

// 4. Set resource limits
set_service_resource_limits(pid, config);

// 5. Monitor service
monitor_service(pid, config);
```

**2. Service Monitoring**:
```zig
// Monitor service resource usage
const usage = get_service_resource_usage(pid);

// Check resource limits
if (usage.memory_used > config.memory_limit) {
    restart_service(pid, config);
}

// Check service health
if (!is_service_healthy(pid)) {
    restart_service(pid, config);
}
```

**3. Service Shutdown**:
```zig
// 1. Send SIGTERM to service
kill_service(pid, SIGTERM);

// 2. Wait for graceful shutdown
wait_for_service_exit(pid, config.shutdown_timeout);

// 3. Force kill if needed
if (is_service_running(pid)) {
    kill_service(pid, SIGKILL);
    wait_for_service_exit(pid, 0);
}
```

**4. Service Restart**:
```zig
// 1. Shutdown service
shutdown_service(pid, config);

// 2. Wait for restart delay
sleep_until(get_current_time() + config.restart_delay);

// 3. Start service again
start_service(config);
```

---

## Service Configuration Pattern

### Configuration File Structure

**Service Configuration** (example):
```
[service]
name = my_service
executable = /bin/my_service
args = --config /etc/my_service.conf
restart_on_exit = true
restart_delay = 1000000000  # 1 second in nanoseconds
memory_limit = 268435456    # 256MB
cpu_limit = 50              # 50% CPU
```

### Configuration Loading

**Init System Pattern**:
```zig
// 1. Open configuration file
const config_handle = open_service_config(service_name);

// 2. Read configuration data
const config_data = read_service_config(config_handle);

// 3. Parse configuration
const config = parse_service_config(config_data);

// 4. Close configuration file
close_service_config(config_handle);

// 5. Validate configuration
validate_service_config(config);
```

---

## Dependency Management

### Service Dependencies

**Dependency Types**:
- **Required**: Service must start before dependent services
- **Optional**: Service can start after dependent services
- **Conflicts**: Service cannot run with conflicting services

**Dependency Resolution**:
1. Build dependency graph
2. Resolve dependencies (topological sort)
3. Start services in dependency order
4. Handle dependency failures

**Syscalls for Dependency Management**:
- `spawn` (1) - Start dependent services
- `wait` (4) - Wait for dependent services
- `get_process_info` (52) - Check dependent service status
- `sysinfo` (50) - Check system resources

---

## Error Handling

### Service Error Handling

**Spawn Errors**:
- `invalid_argument` - Invalid executable or arguments
- `out_of_memory` - Out of memory
- `too_many_processes` - Process limit exceeded

**Wait Errors**:
- `process_not_found` - Process not found
- `interrupted` - Wait interrupted

**Resource Errors**:
- `resource_exhausted` - Resource limit exceeded
- `permission_denied` - Permission denied

**Error Recovery**:
1. Log error
2. Attempt recovery (restart service, retry operation)
3. Escalate if recovery fails
4. Notify system administrator

---

## Summary

**Critical Syscalls for Init System**:
1. **Process Management**: `spawn` (1), `wait` (4), `exit` (2)
2. **Process Groups**: `setpgid` (56), `setsid` (58), `getpgid` (57), `getsid` (59)
3. **File I/O**: `open` (30), `read` (31), `close` (33)
4. **Signal Handling**: `kill` (80), `signal` (81)
5. **Resource Management**: `set_resource_limit` (140), `get_resource_usage` (137)
6. **Time & Scheduling**: `clock_gettime` (40), `sleep_until` (41)
7. **System Information**: `sysinfo` (50), `enumerate_processes` (51), `get_process_info` (52)

**Service Management Pattern**:
1. Read service configuration
2. Spawn service process
3. Set process group/session
4. Set resource limits
5. Monitor service
6. Handle service lifecycle (start, stop, restart)
7. Manage service dependencies

---

**Date**: 2026-01-01-233240-pst  
**Agent**: Grain Basin Kernel Agent (3a)  
**Status**: ✅ **COMPLETE** — Ready for Agent 3d (sevenos Init System) implementation

