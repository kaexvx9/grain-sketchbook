# Core 1 Subcore Integration Tests

**Purpose**: Integration tests for Core 1 Subcore L2 sub-agents (1a Auth, 1b Network, 1c Storage, 1d Compositor, 1e Grainscript Shell)

**Status**: 🆕 **FRAMEWORK CREATED** — Test runner and isolation helpers ready

**Last Updated**: 2026-01-02-004000-pst

---

## Test Structure

### Test Runner

**File**: `tests/integration/core_1_subcore/runner.zig`

**Features**:
- Test execution with timing
- Result tracking and reporting
- Error message capture
- Test summary generation

### Test Isolation

**File**: `tests/integration/core_1_subcore/runner.zig` (TestIsolation)

**Features**:
- Setup/teardown functions
- Test isolation between runs
- Resource cleanup

---

## Planned Integration Tests

### Auth ↔ Network Integration

**Test**: Authentication middleware integration
- Test Auth Agent provides middleware to Network Agent
- Test Network Agent uses Auth middleware for route protection
- Test token validation in network requests

### Network ↔ Storage Integration

**Test**: File transfer integration
- Test Network Agent uploads files to Storage Agent
- Test Network Agent downloads files from Storage Agent
- Test file transfer error handling

### Storage ↔ Auth Integration

**Test**: Credential storage integration
- Test Auth Agent stores credentials via Storage Agent
- Test Auth Agent retrieves credentials from Storage Agent
- Test secure credential storage

### Compositor ↔ Storage Integration

**Test**: Workspace state persistence
- Test Compositor Agent saves workspace state to Storage Agent
- Test Compositor Agent loads workspace state from Storage Agent
- Test workspace state recovery

### Shell ↔ Core Services Integration

**Test**: Shell command execution
- Test Shell executes commands that interact with Core services
- Test Shell provides command-line interface for Core operations
- Test Shell error handling

### sevenos Integration Tests

**Test**: Init System ↔ Core Services
- Test Init System starts Core services in dependency order
- Test Init System manages Core service lifecycle
- Test service dependency management

**Test**: Shell ↔ Init System
- Test Shell integrates with Init System for service management
- Test Shell provides command-line interface for Init System
- Test cross-subcore coordination

---

## Test Execution

### Run All Integration Tests

```bash
zig build test-integration-core-1-subcore
```

### Run Specific Test

```bash
zig build test-integration-core-1-subcore --test-filter <test_name>
```

---

## Grain Style Compliance

All integration tests must follow Grain Style:
- `grain_case` function names
- Explicit `u32`/`u64` types (no `usize`/`isize`)
- Bounded allocations (MAX_ constants)
- Minimum 2 assertions per function
- Max 70 lines per function
- Max 100 characters per line
- All compiler warnings addressed

---

## Future Work

- [ ] Implement Auth ↔ Network integration tests
- [ ] Implement Network ↔ Storage integration tests
- [ ] Implement Storage ↔ Auth integration tests
- [ ] Implement Compositor ↔ Storage integration tests
- [ ] Implement Shell ↔ Core Services integration tests
- [ ] Implement sevenos integration tests
- [ ] Add performance benchmarks
- [ ] Add multi-architecture testing support

---

**Date**: 2026-01-02-004000-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: Framework Ready — Awaiting L2 Sub-Agent Implementation

