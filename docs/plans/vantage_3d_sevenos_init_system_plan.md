# Grain sevenos Init System Agent: Implementation Plan

**Agent**: Grain sevenos Init System Agent (3d)  
**Parent Agent**: Grain Vantage 3 Subcore Agent (3rd Agent, L1 Subcore)  
**Last Updated**: 2026-01-01-220000-pst  
**Status**: ✅ **SUPERVISION LIBRARY FOUNDATION COMPLETE** — Core supervision library implemented. Next: Service configuration system, dependency manager, main init loop.

---

## Current Status

**Phase**: ✅ **Phase 1 Complete** — Supervision Library Foundation  
**Focus**: **SERVICE CONFIGURATION SYSTEM** — Implement configuration loading and validation system

---

## Completed Phases

### ✅ Phase 1: Supervision Library Foundation (COMPLETE)

**Date**: 2026-01-01-220000-pst  
**Status**: COMPLETE

**Completed Work**:
- ✅ Supervision library created (`grainstore/sevenos/src/lib/supervision.zig`)
- ✅ ServiceState enum (stopped, starting, running, stopping, failed, restarting)
- ✅ RestartPolicy enum (always, never, on_failure, on_success) integrated from z6
- ✅ ServiceConfig struct with validation
- ✅ Service struct with lifecycle management (start, stop, restart, update)
- ✅ Supervisor struct for multi-service management
- ✅ Resource limits (max_memory_bytes, max_restarts)
- ✅ Restart delay configuration (restart_delay_ms)
- ✅ Obsolete z6 files removed (Basin Kernel specific, not applicable)

**Results**:
- Core supervision infrastructure ready for use
- Grain Style principles applied (explicit limits, clear validation, educational code)
- RestartPolicy concept successfully adapted from kernel context to userspace context

---

## Implementation Phases

### Phase 2: Service Configuration System (NEXT PRIORITY)

**Goal**: Implement explicit configuration loading and validation

**Timeline**: 1-2 weeks  
**Priority**: HIGH  
**Status**: PENDING

**Tasks**:

1. **Configuration Format Design**:
   - Choose configuration format (JSON/TOML/YAML or custom Grain Style format)
   - Define service configuration schema
   - Design validation rules
   - Document configuration format specification

2. **Configuration Loader Implementation**:
   - File parsing implementation
   - ServiceConfig struct population from configuration
   - Configuration validation with helpful error messages
   - Line number reporting for configuration errors

3. **Error Reporting**:
   - Clear error messages for invalid configurations
   - Helpful suggestions for common mistakes
   - Validation error aggregation (report all errors, not just first)

4. **Configuration Testing**:
   - Unit tests for configuration parser
   - Validation error tests
   - Edge case tests (empty config, missing fields, invalid values)

**Deliverables**:
- Configuration format specification document
- Configuration loader implementation
- Configuration validation with error reporting
- Unit tests for configuration system

**Dependencies**: None (can proceed independently)

---

### Phase 3: Dependency Manager (HIGH PRIORITY)

**Goal**: Implement service dependency resolution and startup ordering

**Timeline**: 1-2 weeks  
**Priority**: HIGH  
**Status**: PENDING

**Tasks**:

1. **Topological Sort Implementation**:
   - Graph construction from service dependencies
   - Topological sort algorithm (Kahn's algorithm or DFS-based)
   - Cycle detection and reporting
   - Dependency graph validation

2. **Startup Ordering**:
   - Service startup sequence generation
   - Parallel startup for independent services
   - Dependency satisfaction checking
   - Startup timeout handling

3. **Integration with Supervisor**:
   - Dependency-aware service starting
   - Dependency tracking during runtime
   - Dependency failure handling (cascade failure or graceful degradation)
   - Service restart dependency handling

4. **Dependency Testing**:
   - Unit tests for topological sort
   - Cycle detection tests
   - Startup ordering tests
   - Dependency failure handling tests

**Deliverables**:
- Dependency manager implementation
- Topological sort with cycle detection
- Dependency-aware service startup
- Unit tests for dependency system

**Dependencies**: Service Configuration System (Phase 2)

---

### Phase 4: Main Init Loop (HIGH PRIORITY)

**Goal**: Implement main supervision loop and signal handling

**Timeline**: 1-2 weeks  
**Priority**: HIGH  
**Status**: PENDING

**Tasks**:

1. **Supervision Loop**:
   - Continuous service monitoring loop
   - Service status updates (Service.update() calls)
   - Crash detection and automatic restart
   - Service health monitoring

2. **Signal Handling**:
   - SIGTERM handling (graceful shutdown of all services)
   - SIGINT handling (interrupt, immediate shutdown)
   - SIGHUP handling (reload configuration)
   - Signal safety (async-signal-safe functions)

3. **Logging and Status**:
   - Service status logging (stdout/stderr or syslog)
   - Error reporting and logging
   - Status query interface (status command or IPC)
   - Service lifecycle event logging

4. **Integration with Supervisor**:
   - Main loop integration with Supervisor struct
   - Service lifecycle coordination
   - Shutdown sequence (stop services in reverse dependency order)

5. **Init Loop Testing**:
   - Unit tests for supervision loop
   - Signal handling tests
   - Service lifecycle tests
   - Shutdown sequence tests

**Deliverables**:
- Main init loop implementation
- Signal handling implementation
- Logging and status reporting
- Unit tests for init loop

**Dependencies**: Dependency Manager (Phase 3)

---

### Phase 5: Testing and Integration (MEDIUM PRIORITY)

**Goal**: Comprehensive testing and integration with sevenos infrastructure

**Timeline**: 2-3 weeks  
**Priority**: MEDIUM  
**Status**: PENDING

**Tasks**:

1. **Unit Tests**:
   - Supervision library comprehensive tests
   - Configuration loader tests
   - Dependency manager tests
   - Main init loop tests

2. **Integration Tests**:
   - End-to-end service lifecycle tests
   - Dependency resolution integration tests
   - Signal handling integration tests
   - Multi-service supervision tests

3. **Build System Integration**:
   - Update `build.zig` to build supervision library
   - Link supervision library to init executable
   - Test infrastructure setup
   - CI/CD integration (if applicable)

4. **Documentation**:
   - User documentation (configuration format, service definitions)
   - Developer documentation (architecture, API reference)
   - Integration guide (how to integrate with sevenos)

**Deliverables**:
- Comprehensive test suite
- Build system integration
- Documentation (user and developer)

**Dependencies**: Main Init Loop (Phase 4)

---

## Architecture Principles

### Grain Style Compliance

**Explicit Limits**:
- MAX_SERVICES = 256 (bounded service count)
- MAX_RESTARTS = 10 (bounded restart count)
- MAX_MEMORY_BYTES = 1GB (bounded memory per service)

**Clear Validation**:
- ServiceConfig.validate() with helpful error messages
- Configuration validation with line number reporting
- Dependency cycle detection with clear error messages

**Educational Code**:
- Comprehensive comments explaining "why"
- Clear function names and structure
- Examples in documentation

**Decomplected Design**:
- Supervision logic separate from configuration
- Configuration separate from dependency management
- Dependency management separate from main loop

**Fail-Fast Error Handling**:
- Validation catches problems early
- Clear error messages guide users
- No silent failures

---

## Integration Points

### With sevenos Infrastructure

**Service Definitions**:
- Service configuration format aligned with sevenos conventions
- Integration with NixOS service definitions (future)
- Integration with sixos service definitions (future)

**Testing**:
- Integration with sevenos testing framework (if applicable)
- VM-based testing (if needed)
- Standalone Linux testing (primary approach)

---

## Success Criteria

### Phase 2: Service Configuration System

- ✅ Configuration format defined and documented
- ✅ Configuration loader parses valid configurations correctly
- ✅ Configuration validation catches all invalid configurations
- ✅ Error messages are clear and helpful
- ✅ Unit tests pass with 100% coverage

### Phase 3: Dependency Manager

- ✅ Topological sort correctly orders services by dependencies
- ✅ Cycle detection catches all dependency cycles
- ✅ Startup ordering respects dependencies
- ✅ Parallel startup works for independent services
- ✅ Unit tests pass with 100% coverage

### Phase 4: Main Init Loop

- ✅ Supervision loop continuously monitors services
- ✅ Services restart according to RestartPolicy
- ✅ Signal handling works correctly (SIGTERM, SIGINT, SIGHUP)
- ✅ Shutdown sequence stops services in correct order
- ✅ Logging provides useful information
- ✅ Unit tests pass with 100% coverage

### Phase 5: Testing and Integration

- ✅ All unit tests pass
- ✅ All integration tests pass
- ✅ Build system integration works
- ✅ Documentation is complete and accurate
- ✅ Integration with sevenos infrastructure validated

---

## Summary

**Status**: ✅ **Phase 1 Complete** — Supervision library foundation ready. Next: Service configuration system.

**Current Focus**: Service Configuration System (Phase 2)

**Next Milestones**:
1. Configuration format design and specification
2. Configuration loader implementation
3. Configuration validation and error reporting
4. Unit tests for configuration system

**Timeline**: 1-2 weeks for Phase 2, then proceed to Phase 3 (Dependency Manager)

---

**Last Updated**: 2026-01-01-220000-pst  
**Agent**: Grain sevenos Init System Agent (3d)  
**Parent Agent**: Grain Vantage 3 Subcore Agent (3rd Agent, L1 Subcore)  
**Status**: ✅ **SUPERVISION LIBRARY FOUNDATION COMPLETE** — Ready for service configuration system implementation.


