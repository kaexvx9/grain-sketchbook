# Supervisor Access API Documentation

**Date**: 2026-01-03-075315-pst  
**Agent**: Grain sevenos Init System Agent (3d)  
**Target**: Grain Grainscript Shell Agent (1e)  
**Purpose**: Documentation for how shell accesses Supervisor instance

---

## Overview

This document explains how the Grainscript Shell can access the Supervisor instance to manage services. Since the shell and init system are separate processes, we need a mechanism for the shell to interact with the supervisor.

---

## Architecture Considerations

### Current Architecture

**Init System Process**:
- Runs as PID 1 (or separate process)
- Owns the Supervisor instance
- Manages all services

**Shell Process**:
- Runs as a separate process
- Needs to interact with Supervisor
- Cannot directly access Supervisor (separate process)

### Integration Options

**Option 1: Shared Library (Recommended for Initial Integration)**
- Init System and Shell link against same supervision library
- Shell gets Supervisor reference via IPC or shared state
- Direct function calls (same library, different processes)

**Option 2: IPC (Future Enhancement)**
- Shell communicates with Init System via IPC (Unix socket, pipe, etc.)
- Init System exposes service management API via IPC
- More complex, but enables distributed service management

**Option 3: Shell Embedded in Init System (Not Recommended)**
- Shell runs in same process as Init System
- Direct access to Supervisor
- Not recommended (decomplected design)

---

## Recommended Approach: Shared Library + Supervisor Reference

### Phase 1: Shared Library Approach

**Implementation**:
1. Both Init System and Shell link against `supervision.zig` library
2. Supervisor instance is created and managed by Init System
3. Shell gets Supervisor reference via:
   - Global/static reference (if same process)
   - IPC mechanism (if different processes)
   - Shared memory (future enhancement)

### Supervisor Reference Access

**Current Limitation**: Init System and Shell are separate processes, so direct Supervisor reference is not possible.

**Solution for Phase 1**: 
- For testing/integration: Shell can create its own Supervisor instance (limited functionality)
- For production: Need IPC mechanism (future work)

**Recommendation**: 
- **For initial integration (Step 4)**: Shell creates ServiceManager that accepts Supervisor reference
- **ServiceManager API**: `ServiceManager.init(supervisor: *Supervisor, allocator: Allocator)`
- **Supervisor reference**: Provided by Init System via IPC or shared state (to be implemented)

---

## Supervisor Reference API (To Be Implemented)

### Future: Supervisor Access API

**Planned API** (to be implemented in Phase 2):

```zig
// Init System provides Supervisor access
pub const SupervisorAccess = struct {
    pub fn get_supervisor() ?*Supervisor;
    pub fn connect_to_supervisor() !*Supervisor;
};
```

**Implementation Options**:
1. **Unix Socket**: Init System listens on Unix socket, Shell connects
2. **Shared Memory**: Supervisor state in shared memory (complex)
3. **File-based**: Supervisor state serialized to file (simpler, less efficient)

---

## Current Implementation Guidance

### For Agent 1e (Shell): ServiceManager Design

**Design**: ServiceManager accepts Supervisor reference as parameter

**API**:
```zig
pub const ServiceManager = struct {
    supervisor: *supervision.Supervisor,
    allocator: std.mem.Allocator,
    
    pub fn init(
        supervisor: *supervision.Supervisor,
        allocator: std.mem.Allocator,
    ) ServiceManager {
        return ServiceManager{
            .supervisor = supervisor,
            .allocator = allocator,
        };
    }
    
    // ... service management methods
};
```

**Usage Pattern**:
```zig
// Shell gets Supervisor reference (to be provided by Init System)
const supervisor = get_supervisor_reference() orelse return error.SupervisorNotAvailable;

// Create ServiceManager with Supervisor reference
var service_manager = ServiceManager.init(supervisor, allocator);

// Use ServiceManager for service management
try service_manager.start_service("grainscript_shell");
```

---

## Integration Phases

### Phase 1: Initial Integration (Step 4)

**Goal**: Shell can manage services (start, stop, restart, status, list)

**Implementation**:
- Shell creates ServiceManager module
- ServiceManager accepts Supervisor reference
- Supervisor reference provided by Init System (mechanism TBD)
- For testing: Shell can create temporary Supervisor instance

**Timeline**: Step 4 (current phase)

---

### Phase 2: IPC Integration (Future)

**Goal**: Shell communicates with Init System via IPC

**Implementation**:
- Init System exposes service management API via Unix socket
- Shell connects to Init System socket
- Shell sends commands, Init System executes via Supervisor
- Responses sent back to shell

**Timeline**: After Step 4, future enhancement

---

## Testing Approach

### For Agent 1e (Shell): Testing ServiceManager

**Option 1: Mock Supervisor**
- Create mock Supervisor for testing
- Test ServiceManager logic without real Supervisor

**Option 2: Temporary Supervisor**
- Create temporary Supervisor instance for testing
- Test service management functionality
- Limitations: No real process spawning (unit tests only)

**Option 3: Integration Tests**
- Test with real Init System process
- Requires Init System to be running
- Full integration testing

---

## Coordination Needed

### For Agent 1e (Shell)

**Immediate**:
- Create ServiceManager that accepts Supervisor reference
- Design ServiceManager API based on Supervisor APIs
- Implement service management commands

**Waiting For**:
- Supervisor reference mechanism (from Init System)
- IPC mechanism (future)

### For Agent 3d (Init System)

**Immediate**:
- Document Supervisor APIs (✅ complete)
- Provide service configuration template (✅ complete)

**Future**:
- Implement Supervisor access API (IPC mechanism)
- Provide Supervisor reference to shell
- Coordinate on IPC protocol

---

## Summary

**Current Status**:
- ✅ Supervisor APIs documented
- ✅ ServiceManager design pattern documented
- ⏳ Supervisor reference mechanism (to be coordinated)

**Recommendation**:
- **For Step 4**: Shell creates ServiceManager that accepts Supervisor reference
- **Supervisor reference**: To be provided by Init System (coordination needed)
- **Testing**: Use mock/temporary Supervisor for initial testing
- **Future**: Implement IPC mechanism for production use

**Next Steps**:
1. Agent 1e: Create ServiceManager with Supervisor reference parameter
2. Agent 3d + Agent 1e: Coordinate on Supervisor reference mechanism
3. Agent 3d: Implement Supervisor access API (future)
4. Both: Test integration with real Supervisor

---

**Last Updated**: 2026-01-03-075315-pst  
**Agent**: Grain sevenos Init System Agent (3d)  
**Status**: ✅ Supervisor access API documentation ready. Coordination needed on Supervisor reference mechanism.

