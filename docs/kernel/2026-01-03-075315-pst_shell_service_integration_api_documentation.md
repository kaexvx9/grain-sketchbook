# Shell Service Integration API Documentation

**Date**: 2026-01-03-075315-pst  
**Agent**: Grain sevenos Init System Agent (3d)  
**Target**: Grain Grainscript Shell Agent (1e)  
**Purpose**: API documentation for shell ↔ init system integration

---

## Overview

This document provides API documentation for integrating Grainscript Shell with the sevenos Init System. The APIs allow the shell to manage services, query service status, and interact with the supervision system.

---

## Supervisor API Reference

**Location**: `grainstore/sevenos/src/lib/supervision.zig`

### Supervisor Struct

```zig
pub const Supervisor = struct {
    services: std.StringHashMap(*Service),
    allocator: std.mem.Allocator,
    
    pub fn init(allocator: std.mem.Allocator) Supervisor;
    pub fn deinit(self: *Supervisor) void;
    pub fn add_service(self: *Supervisor, service: *Service) !void;
    pub fn get_service(self: *Supervisor, name: []const u8) ?*Service;
    pub fn start_all(self: *Supervisor) !void;
    pub fn stop_all(self: *Supervisor) !void;
    pub fn update_all(self: *Supervisor) !void;
    pub fn supervise(self: *Supervisor) !void;
    pub fn run_supervision_loop(self: *Supervisor, allocator: std.mem.Allocator) void;
};
```

---

## Service Management APIs

### Get Service by Name

**Function**: `Supervisor.get_service()`

**Signature**:
```zig
pub fn get_service(self: *Supervisor, name: []const u8) ?*Service
```

**Description**: Get a service by name from the supervisor.

**Parameters**:
- `self`: Supervisor instance
- `name`: Service name (string)

**Returns**: `?*Service` - Service pointer if found, `null` if not found

**Example**:
```zig
const service = supervisor.get_service("grainscript_shell");
if (service) |s| {
    // Service found, use s
} else {
    // Service not found
}
```

---

### Service State Query

**Function**: `Service.state`

**Field**:
```zig
pub const ServiceState = enum {
    stopped,      // Service is not running
    starting,     // Service is starting up
    running,      // Service is running normally
    stopping,     // Service is shutting down
    failed,       // Service failed to start or crashed
    restarting,   // Service crashed and is being restarted
};
```

**Usage**:
```zig
const service = supervisor.get_service("grainscript_shell") orelse return error.ServiceNotFound;
const state = service.state;
// Use state: .stopped, .starting, .running, .stopping, .failed, .restarting
```

---

### Start Service

**Function**: `Service.start()`

**Signature**:
```zig
pub fn start(self: *Service, allocator: std.mem.Allocator) !void
```

**Description**: Start a service (spawn the process).

**Parameters**:
- `self`: Service instance
- `allocator`: Memory allocator

**Returns**: `void` (error union)

**Errors**: 
- `error.ProcessSpawnFailed` - Failed to spawn process
- `error.ServiceAlreadyRunning` - Service is already running

**Example**:
```zig
const service = supervisor.get_service("grainscript_shell") orelse return error.ServiceNotFound;
try service.start(allocator);
```

---

### Stop Service

**Function**: `Service.stop()`

**Signature**:
```zig
pub fn stop(self: *Service) !void
```

**Description**: Stop a service (terminate the process).

**Parameters**:
- `self`: Service instance

**Returns**: `void` (error union)

**Errors**: None (always succeeds, even if service is already stopped)

**Example**:
```zig
const service = supervisor.get_service("grainscript_shell") orelse return error.ServiceNotFound;
try service.stop();
```

---

### Restart Service

**Function**: `Service.restart()`

**Signature**:
```zig
pub fn restart(self: *Service, allocator: std.mem.Allocator) !void
```

**Description**: Restart a service (stop then start).

**Parameters**:
- `self`: Service instance
- `allocator`: Memory allocator

**Returns**: `void` (error union)

**Errors**:
- `error.ProcessSpawnFailed` - Failed to spawn process after stop

**Example**:
```zig
const service = supervisor.get_service("grainscript_shell") orelse return error.ServiceNotFound;
try service.restart(allocator);
```

---

### Check if Service is Alive

**Function**: `Service.is_alive()`

**Signature**:
```zig
pub fn is_alive(self: *Service) bool
```

**Description**: Check if the service process is still alive.

**Parameters**:
- `self`: Service instance

**Returns**: `bool` - `true` if process is alive, `false` otherwise

**Example**:
```zig
const service = supervisor.get_service("grainscript_shell") orelse return error.ServiceNotFound;
const alive = service.is_alive();
```

---

### Get Service Configuration

**Function**: `Service.config`

**Field**:
```zig
config: ServiceConfig
```

**Description**: Access service configuration.

**Usage**:
```zig
const service = supervisor.get_service("grainscript_shell") orelse return error.ServiceNotFound;
const config = service.config;
const service_name = config.name;
const command = config.command;
const restart_policy = config.restart_policy;
```

---

### List All Services

**Function**: Iterate over `Supervisor.services`

**Method**: Use `Supervisor.services.iterator()`

**Description**: Iterate over all services in the supervisor.

**Example**:
```zig
var it = supervisor.services.iterator();
while (it.next()) |entry| {
    const service_name = entry.key_ptr.*;
    const service = entry.value_ptr.*;
    const state = service.state;
    // Process service_name and state
}
```

---

## ServiceManager Integration Pattern

**Recommended Pattern**: Create a ServiceManager module that wraps Supervisor APIs.

**Location**: `grainstore/sevenos/src/shell/service_manager.zig` (to be created by Agent 1e)

**Example Structure**:
```zig
pub const ServiceManager = struct {
    supervisor: *supervision.Supervisor,
    allocator: std.mem.Allocator,
    
    pub fn init(supervisor: *supervision.Supervisor, allocator: std.mem.Allocator) ServiceManager {
        return ServiceManager{
            .supervisor = supervisor,
            .allocator = allocator,
        };
    }
    
    pub fn get_service_status(self: *ServiceManager, name: []const u8) !ServiceState {
        const service = self.supervisor.get_service(name) orelse return error.ServiceNotFound;
        return service.state;
    }
    
    pub fn start_service(self: *ServiceManager, name: []const u8) !void {
        const service = self.supervisor.get_service(name) orelse return error.ServiceNotFound;
        try service.start(self.allocator);
    }
    
    pub fn stop_service(self: *ServiceManager, name: []const u8) !void {
        const service = self.supervisor.get_service(name) orelse return error.ServiceNotFound;
        try service.stop();
    }
    
    pub fn restart_service(self: *ServiceManager, name: []const u8) !void {
        const service = self.supervisor.get_service(name) orelse return error.ServiceNotFound;
        try service.restart(self.allocator);
    }
    
    pub fn list_services(self: *ServiceManager) ![]const ServiceInfo {
        // Implementation: iterate over supervisor.services
        // Return array of ServiceInfo (name, state, etc.)
    }
};
```

---

## Error Handling

### Common Errors

**ServiceNotFound**:
- Service name does not exist in supervisor
- Check: `supervisor.get_service(name) == null`

**ServiceAlreadyRunning**:
- Service is already running (when calling `start()`)
- Check: `service.state == .running` before starting

**ProcessSpawnFailed**:
- Failed to spawn process (executable not found, permission denied, etc.)
- Check: Command path is correct, executable exists, permissions are correct

---

## Usage Examples

### Example 1: Query Service Status

```zig
const service = supervisor.get_service("grainscript_shell") orelse {
    std.debug.print("Service not found\n", .{});
    return;
};
std.debug.print("Service state: {}\n", .{service.state});
```

---

### Example 2: Start a Service

```zig
const service = supervisor.get_service("grainscript_shell") orelse return error.ServiceNotFound;
if (service.state == .stopped) {
    try service.start(allocator);
    std.debug.print("Service started\n", .{});
} else {
    std.debug.print("Service already running\n", .{});
}
```

---

### Example 3: Stop a Service

```zig
const service = supervisor.get_service("grainscript_shell") orelse return error.ServiceNotFound;
try service.stop();
std.debug.print("Service stopped\n", .{});
```

---

### Example 4: List All Services

```zig
var it = supervisor.services.iterator();
std.debug.print("Services:\n", .{});
while (it.next()) |entry| {
    const service_name = entry.key_ptr.*;
    const service = entry.value_ptr.*;
    std.debug.print("  {s}: {}\n", .{ service_name, service.state });
}
```

---

## Integration Notes

**For Agent 1e (Shell)**:
- Use these APIs to implement service management commands
- Wrap APIs in ServiceManager module for cleaner interface
- Handle errors appropriately (ServiceNotFound, etc.)
- Format output for shell users

**For Agent 3d (Init System)**:
- These APIs are ready for shell integration
- Supervisor must be accessible to shell (see Supervisor Access API document)
- All APIs are thread-safe for single-threaded use (no concurrent access)

---

**Last Updated**: 2026-01-03-075315-pst  
**Agent**: Grain sevenos Init System Agent (3d)  
**Status**: ✅ API documentation ready for shell integration

