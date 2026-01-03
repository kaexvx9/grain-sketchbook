# Grainscript Shell Service Command Design

**Date**: 2026-01-03-080000-pst  
**Agent**: Grainscript Shell Agent (1e)  
**Purpose**: Detailed design for service management command implementation  
**Status**: Design phase — Ready for implementation when Init System APIs available

---

## Overview

This document provides detailed design for the `service` built-in command that enables shell users to interact with the Init System for service management.

**Command Structure**:
```
service <subcommand> [arguments]
```

**Subcommands**:
- `status [service_name]` - Show service status(es)
- `start <service_name>` - Start a service
- `stop <service_name>` - Stop a service
- `restart <service_name>` - Restart a service
- `list` - List all services
- `logs <service_name>` - View service logs (future)
- `deps <service_name>` - Show service dependencies (future)
- `config <service_name>` - Show service configuration (future)

---

## Architecture

### ServiceManager Module

**File**: `grainstore/sevenos/src/shell/service_manager.zig`

**Purpose**: Wraps Init System Supervisor APIs for shell use.

**Key Functions**:
- `get_service_status(service_name)` - Get service state
- `start_service(service_name)` - Start service
- `stop_service(service_name)` - Stop service
- `restart_service(service_name)` - Restart service
- `list_services()` - Get all services
- `get_service_info(service_name)` - Get full service info

**Error Handling**:
- `ServiceNotFound` - Service doesn't exist
- `ServiceAlreadyRunning` - Can't start (already running)
- `ServiceNotRunning` - Can't stop (not running)
- `StartFailed` - Start operation failed
- `StopFailed` - Stop operation failed
- `RestartFailed` - Restart operation failed

### Service Command Implementation

**File**: `grainstore/sevenos/src/shell/builtins.zig`

**Function**: `builtin_service(allocator, args, env)`

**Subcommand Parsing**:
```zig
if (args.len == 0) {
    return error("service: missing subcommand");
}

const subcommand = args[0];

if (std.mem.eql(u8, subcommand, "status")) {
    return handle_service_status(allocator, args[1..], service_manager);
} else if (std.mem.eql(u8, subcommand, "start")) {
    return handle_service_start(allocator, args[1..], service_manager);
} else if (std.mem.eql(u8, subcommand, "stop")) {
    return handle_service_stop(allocator, args[1..], service_manager);
} else if (std.mem.eql(u8, subcommand, "restart")) {
    return handle_service_restart(allocator, args[1..], service_manager);
} else if (std.mem.eql(u8, subcommand, "list")) {
    return handle_service_list(allocator, service_manager);
} else {
    return error("service: unknown subcommand");
}
```

---

## Implementation Details

### Service Status Command

**Usage**: `service status [service_name]`

**Behavior**:
- If `service_name` provided: Show status of that service
- If no `service_name`: Show status of all services

**Output Format**:
```
service_name: state (pid: 1234)
```

**Example**:
```
$ service status web
web: running (pid: 1234)

$ service status
web: running (pid: 1234)
db: stopped
network: running (pid: 5678)
```

### Service Start Command

**Usage**: `service start <service_name>`

**Behavior**:
- Start the specified service
- Return error if service not found or already running

**Output**:
- Success: No output (exit code 0)
- Error: Error message to stderr (exit code 1)

**Example**:
```
$ service start web
$ echo $?
0

$ service start web
service: web is already running
$ echo $?
1
```

### Service Stop Command

**Usage**: `service stop <service_name>`

**Behavior**:
- Stop the specified service
- Return error if service not found or not running

**Output**:
- Success: No output (exit code 0)
- Error: Error message to stderr (exit code 1)

### Service Restart Command

**Usage**: `service restart <service_name>`

**Behavior**:
- Stop then start the specified service
- Return error if service not found

**Output**:
- Success: No output (exit code 0)
- Error: Error message to stderr (exit code 1)

### Service List Command

**Usage**: `service list`

**Behavior**:
- List all services with their status

**Output Format**:
```
SERVICE_NAME    STATE      PID
web             running    1234
db              stopped    -
network         running    5678
```

---

## Integration Points

### Shell → Init System Access

**Current Design**: ServiceManager needs Supervisor reference.

**Options**:
1. **IPC Communication** (future): Shell connects to Init System via IPC
2. **Shared Library** (current): Shell links against Init System library, gets Supervisor reference
3. **API Wrapper** (recommended): Agent 3d provides API wrapper for shell access

**Recommended Approach**: Agent 3d provides API wrapper that:
- Exposes Supervisor operations via clean API
- Handles IPC or shared library access transparently
- Provides service management functions

### Executor Integration

**Current**: Executor has `env: *ShellEnvironment`

**Proposed**: Add `service_manager: ?*ServiceManager` to Executor

**Initialization**:
```zig
// In grainscript.zig main()
var service_manager: ?ServiceManager = null;

// If Init System available, initialize ServiceManager
if (init_system_available) {
    const supervisor = get_supervisor_reference(); // From Agent 3d API
    service_manager = ServiceManager.init(allocator, supervisor);
}

// Pass to executor
var exec = executor.Executor.init(allocator, &env, service_manager);
```

**Built-in Access**:
```zig
// In builtin_service()
if (self.service_manager) |sm| {
    // Use service manager
} else {
    return error("service: Init System not available");
}
```

---

## Error Messages

**User-Friendly Error Messages**:
- `service: missing subcommand` - No subcommand provided
- `service: unknown subcommand '<name>'` - Invalid subcommand
- `service: missing service name` - Service name required but not provided
- `service: service '<name>' not found` - Service doesn't exist
- `service: service '<name>' is already running` - Can't start (already running)
- `service: service '<name>' is not running` - Can't stop (not running)
- `service: failed to start '<name>': <error>` - Start operation failed
- `service: failed to stop '<name>': <error>` - Stop operation failed
- `service: Init System not available` - ServiceManager not initialized

---

## Testing Strategy

### Unit Tests

**ServiceManager Tests**:
- Test service status queries
- Test service start/stop/restart operations
- Test error handling (not found, already running, etc.)
- Test service listing

**Service Command Tests**:
- Test subcommand parsing
- Test argument validation
- Test output formatting
- Test error message formatting

### Integration Tests

**Shell ↔ Init System Integration**:
- Test service management end-to-end
- Test error handling
- Test concurrent operations
- Test service state transitions

---

## Grain Style Compliance

**All Code Must**:
- Use `grain_case` function names
- Enforce `grainwrap-100` (line length ≤100)
- Enforce `grain validate-70` (function length ≤70)
- Use explicit `u32`/`u64` types (NO `usize`/`isize`)
- Define MAX_ constants for bounded allocations
- Minimum 2 assertions per function
- Address ALL compiler warnings

---

## Implementation Phases

### Phase 1: Basic Service Management (Current)

**Status**: ✅ ServiceManager module created, service command stub added

**Tasks**:
- ✅ Create ServiceManager module structure
- ✅ Add service command stub
- ⏳ Wait for Agent 3d API wrapper
- ⏳ Implement service command subcommands
- ⏳ Integrate ServiceManager with executor

### Phase 2: Full Implementation

**Tasks**:
- Implement all subcommands (status, start, stop, restart, list)
- Add error handling
- Add output formatting
- Add tests

### Phase 3: Advanced Features (Future)

**Tasks**:
- Add `service logs` command
- Add `service deps` command
- Add `service config` command
- Add `service reload` command

---

## Dependencies

**Required from Agent 3d**:
- Service configuration template
- Service integration API documentation
- Supervisor access API (how shell gets Supervisor reference)

**Timeline**: ~10-15 hours for complete implementation (per hybrid approach)

---

**Date**: 2026-01-03-080000-pst  
**Agent**: Grainscript Shell (1e)  
**Status**: ✅ **DESIGN COMPLETE** — Ready for implementation when APIs available

