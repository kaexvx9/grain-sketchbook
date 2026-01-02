# Grainscript Shell → sevenos Init System Integration Design

**Date**: 2026-01-02  
**Agent**: Grainscript Shell Agent (1e, L2 Sub-Agent under Core 1 Subcore)  
**Status**: 🆕 **INTEGRATION DESIGN** — Prepared for Init System (3d) completion  
**Blocked On**: Step 3 (Init System Phase 3/4 completion)

---

## Executive Summary

This document designs the integration points between **Grainscript Shell (1e)** and **sevenos Init System (3d)**. The integration will enable the shell to interact with the init system for service management, process supervision, and system-level operations.

**Integration Goal**: Shell can execute commands that interact with Init System services, manage processes, and coordinate with the supervision system.

---

## Integration Architecture

### High-Level Flow

```
Grainscript Shell (1e)
    ↓
Command Execution
    ↓
Built-in Commands (cd, ls, pwd, echo, exit)
    ↓
External Programs (via std.process.Child)
    ↓
Init System Integration (NEW)
    ↓
sevenos Init System (3d)
    ↓
Basin Kernel Syscalls (3a)
```

### Integration Points

#### 1. Service Management Commands

**New Built-in Commands** (to be added):
- `service start <name>` — Start a service via Init System
- `service stop <name>` — Stop a service via Init System
- `service restart <name>` — Restart a service via Init System
- `service status <name>` — Get service status from Init System
- `service list` — List all services managed by Init System

**Integration Pattern**:
- Shell built-in commands call Init System API
- Init System manages service lifecycle
- Shell displays results to user

#### 2. Process Supervision Integration

**Integration Points**:
- Shell processes can be supervised by Init System
- Shell can query process status from Init System
- Shell can manage process groups via Init System

**API Contract** (to be defined with Init System):
```zig
// Init System API (to be implemented by 3d)
pub const InitSystemAPI = struct {
    start_service: fn(name: []const u8) InitSystemError!void,
    stop_service: fn(name: []const u8) InitSystemError!void,
    restart_service: fn(name: []const u8) InitSystemError!void,
    get_service_status: fn(name: []const u8) InitSystemError!ServiceStatus,
    list_services: fn() InitSystemError![]const ServiceInfo,
};
```

#### 3. Shell Process Management

**Integration Points**:
- Shell can register itself with Init System
- Shell can spawn supervised child processes
- Shell can query child process status

**Pattern**:
- Shell uses Init System for process management
- Init System provides supervision and lifecycle management
- Basin Kernel syscalls used for actual process operations

---

## Implementation Plan

### Phase 1: API Contract Design (Week 1)

**Tasks**:
1. Coordinate with Init System (3d) on API contract
2. Define service management API
3. Define process supervision API
4. Document API contracts

**Deliverables**:
- API contract document
- Integration test plan

### Phase 2: Shell Integration (Week 1-2, after Step 3)

**Tasks**:
1. Add service management built-in commands
2. Implement Init System API client
3. Integrate with Init System supervision
4. Add process management commands

**Deliverables**:
- Service management commands working
- Process supervision integration working
- Integration tests passing

### Phase 3: Testing and Validation (Week 2)

**Tasks**:
1. Test service management commands
2. Test process supervision integration
3. Test error handling
4. Verify Framework x86_64 compatibility

**Deliverables**:
- All integration tests passing
- Framework x86_64 verification complete

---

## API Contracts (To Be Defined with Init System)

### Service Management API

```zig
// Service status
pub const ServiceStatus = enum {
    stopped,
    starting,
    running,
    stopping,
    failed,
};

// Service information
pub const ServiceInfo = struct {
    name: []const u8,
    status: ServiceStatus,
    pid: u32,
};

// Init System API
pub const InitSystemClient = struct {
    allocator: std.mem.Allocator,
    
    pub fn start_service(self: *InitSystemClient, name: []const u8) !void;
    pub fn stop_service(self: *InitSystemClient, name: []const u8) !void;
    pub fn restart_service(self: *InitSystemClient, name: []const u8) !void;
    pub fn get_service_status(self: *InitSystemClient, name: []const u8) !ServiceStatus;
    pub fn list_services(self: *InitSystemClient) ![]ServiceInfo;
};
```

### Process Supervision API

```zig
// Process supervision
pub const ProcessSupervisor = struct {
    allocator: std.mem.Allocator,
    
    pub fn spawn_supervised(self: *ProcessSupervisor, cmd: []const u8, args: [][]const u8) !u32; // Returns PID
    pub fn wait_for_process(self: *ProcessSupervisor, pid: u32) !ProcessResult;
    pub fn get_process_status(self: *ProcessSupervisor, pid: u32) !ProcessStatus;
};
```

---

## Coordination Requirements

### With Init System (3d)

**Before Integration**:
- ✅ Check in with Core 1 Subcore
- ✅ Coordinate with Vantage 3 Subcore (cross-subcore)
- ✅ Review Init System API contracts
- ✅ Agree on integration patterns

**During Integration**:
- Coordinate on API changes
- Test integration points
- Verify error handling

**After Integration**:
- Update documentation
- Run integration tests
- Verify Framework x86_64 compatibility

### With Core 1 Subcore

**Check-in Points**:
- Before API contract design
- Before implementation start
- After integration complete
- Before Framework x86_64 verification

---

## Dependencies

**Blocking**:
- Step 3: Init System (3d) must complete Phase 3/4
- Step 2: VM Runtime (3b) must implement x86_64 JIT
- Step 1: Basin Kernel (3a) must distribute syscall docs

**Non-blocking**:
- Can design API contracts now
- Can prepare integration code structure
- Can write integration tests (mocked)

---

## Success Criteria

### Phase 1 Success
- ✅ API contracts defined and agreed
- ✅ Integration test plan complete
- ✅ Documentation updated

### Phase 2 Success
- ✅ Service management commands working
- ✅ Process supervision integration working
- ✅ All integration tests passing

### Phase 3 Success
- ✅ Framework x86_64 verification complete
- ✅ End-to-end integration working
- ✅ Documentation complete

---

## Next Steps

1. **Wait for Step 3 completion** (Init System Phase 3/4)
2. **Coordinate API contract design** with Init System (3d)
3. **Implement integration** when unblocked
4. **Test and verify** on Framework x86_64

---

**Status**: Integration design complete, waiting for Init System (3d) to complete Step 3.

