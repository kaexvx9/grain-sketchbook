# Aurora 2 Subcore: Integration Test Framework Design

**Date**: 2026-01-02-085016-pst  
**Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Status**: ✅ **DESIGN COMPLETE** — Ready for implementation after Phase 1 Component API

---

## Executive Summary

This document designs the integration test framework for Aurora 2 Subcore L2 sub-agents (2a Dream Editor, 2b Dream Browser, 2c Component Library). The framework provides test execution, isolation, and reporting infrastructure for cross-sub-agent integration testing.

**Purpose**: Test integration between Editor, Browser, and Component Library agents to ensure Component API, shared modules, and cross-application features work correctly.

**Status**: Design complete — Implementation can begin after Phase 1 Component API is complete

---

## Framework Components

### 1. Test Directory Structure

```
tests/integration/aurora_2_subcore/
├── runner.zig              # Test runner with execution, timing, reporting
├── helpers.zig             # Test helpers (setup/teardown, fixtures)
├── editor_component.zig    # Editor + Component Library integration tests
├── browser_component.zig   # Browser + Component Library integration tests
├── editor_browser.zig      # Editor + Browser integration tests
├── shared_modules.zig      # Shared module integration tests (GrainBuffer, DAG Core)
└── README.md               # Framework documentation
```

### 2. Test Runner (`runner.zig`)

**Responsibilities**:
- Test execution with timing
- Result tracking and reporting
- Error message capture
- Test summary generation
- Test isolation helpers (setup/teardown)

**Key Features**:
- Test execution loop
- Timing per test
- Result aggregation
- Summary reporting (passed/failed/total)
- Error message collection

**Grain Style Compliance**:
- `grain_case` function names
- Explicit `u32`/`u64` types (no `usize`/`isize`)
- Bounded allocations (`MAX_TEST_RESULTS: u32 = 1000`)
- Minimum 2 assertions per function
- Max 70 lines per function
- Max 100 characters per line
- All compiler warnings addressed

**API Structure**:
```zig
// Test result structure
pub const TestResult = struct {
    name: [MAX_TEST_NAME_LEN]u8,
    name_len: u32,
    passed: bool,
    duration_ms: u64,
    error_msg: [MAX_ERROR_MSG_LEN]u8,
    error_msg_len: u32,
};

// Test runner
pub const TestRunner = struct {
    results: [MAX_TEST_RESULTS]TestResult,
    result_count: u32,
    
    pub fn init() TestRunner;
    pub fn run_all_tests(self: *TestRunner) void;
    pub fn add_result(self: *TestRunner, result: TestResult) void;
    pub fn print_summary(self: *TestRunner) void;
};
```

### 3. Test Helpers (`helpers.zig`)

**Responsibilities**:
- Test setup/teardown utilities
- Test data fixtures
- Component API test helpers
- Shared module test helpers
- Mock/fake implementations for isolation

**Key Features**:
- Component API setup helpers
- GrainBuffer test helpers
- DAG Core test helpers
- Theme/state management test helpers
- Memory allocation helpers for tests

**API Structure**:
```zig
// Component API test helpers
pub fn setup_component_api() ComponentAPITestContext;
pub fn teardown_component_api(ctx: *ComponentAPITestContext) void;

// GrainBuffer test helpers
pub fn setup_grain_buffer() GrainBufferTestContext;
pub fn teardown_grain_buffer(ctx: *GrainBufferTestContext) void;

// DAG Core test helpers
pub fn setup_dag_core() DAGCoreTestContext;
pub fn teardown_dag_core(ctx: *DAGCoreTestContext) void;
```

---

## Integration Test Scenarios

### 1. Editor + Component Library Integration Tests

**Test File**: `editor_component.zig`

**Test Scenarios**:

#### A. Component API Integration
- Test Editor UI components using Component API
- Test Component lifecycle (init, update, render, cleanup)
- Test Component state management (state/size/theme variants)
- Test Component ID allocation (Editor: 70-99)

**Test Cases**:
1. `test "Editor pane components initialization"`
2. `test "Editor tab components with Component API"`
3. `test "Editor status bar components rendering"`
4. `test "Component theme synchronization"`
5. `test "Component state management (normal, hover, active)"`
6. `test "Component size variants (small, medium, large)"`

#### B. Multi-Pane Layout Integration
- Test multi-pane layout with Component API
- Test pane splitting (vertical, horizontal)
- Test pane resizing
- Test pane state management

**Test Cases**:
1. `test "Multi-pane layout with Component API"`
2. `test "Vertical split pane rendering"`
3. `test "Horizontal split pane rendering"`
4. `test "Pane resizing with Component API"`
5. `test "Pane state persistence"`

#### C. Component Rendering Integration
- Test Component rendering with GrainAurora
- Test Component rendering result validation
- Test Component rendering performance

**Test Cases**:
1. `test "Editor components render with GrainAurora"`
2. `test "Component rendering result validation"`
3. `test "Component rendering performance (basic)"`

---

### 2. Browser + Component Library Integration Tests

**Test File**: `browser_component.zig`

**Test Scenarios**:

#### A. Component API Integration
- Test Browser UI components using Component API
- Test Component lifecycle (init, update, render, cleanup)
- Test Component state management (state/size/theme variants)
- Test Component ID allocation (Browser: 30-69)

**Test Cases**:
1. `test "Browser navigation components initialization"`
2. `test "Browser address bar components with Component API"`
3. `test "Browser tab components rendering"`
4. `test "Browser view components with Component API"`
5. `test "Component theme synchronization (browser)"`
6. `test "Component state management (browser)"`

#### B. Content Area Integration
- Test `content_area` component for Bubble Agent SLC components
- Test content area rendering
- Test content area state management

**Test Cases**:
1. `test "Browser content_area component initialization"`
2. `test "Content area rendering with Component API"`
3. `test "Content area state management"`

#### C. Component Rendering Integration
- Test Component rendering with GrainAurora
- Test Component rendering result validation
- Test Component rendering performance

**Test Cases**:
1. `test "Browser components render with GrainAurora"`
2. `test "Component rendering result validation (browser)"`
3. `test "Component rendering performance (browser)"`

---

### 3. Editor + Browser Integration Tests

**Test File**: `editor_browser.zig`

**Test Scenarios**:

#### A. Shared Component Rendering
- Test shared Component rendering across Editor and Browser
- Test Component theme synchronization across applications
- Test Component state synchronization

**Test Cases**:
1. `test "Shared Component rendering (Editor + Browser)"`
2. `test "Component theme synchronization across applications"`
3. `test "Component state synchronization"`

#### B. Cross-Application State
- Test cross-application Component state management
- Test Component state propagation
- Test Component state isolation

**Test Cases**:
1. `test "Cross-application Component state management"`
2. `test "Component state propagation (Editor → Browser)"`
3. `test "Component state isolation"`

#### C. Unified IDE Features
- Test unified IDE features (Editor + Browser)
- Test component sharing between Editor and Browser
- Test integrated workflow

**Test Cases**:
1. `test "Unified IDE Component sharing"`
2. `test "Integrated workflow (Editor + Browser)"`
3. `test "Component API consistency across applications"`

---

### 4. Shared Module Integration Tests

**Test File**: `shared_modules.zig`

**Test Scenarios**:

#### A. GrainBuffer Integration
- Test GrainBuffer usage in Editor and Component Library
- Test GrainBuffer state management
- Test GrainBuffer error handling

**Test Cases**:
1. `test "GrainBuffer integration (Editor + Component Library)"`
2. `test "GrainBuffer state management"`
3. `test "GrainBuffer error handling"`
4. `test "GrainBuffer concurrent access"`

#### B. DAG Core Integration
- Test DAG Core usage across all sub-agents
- Test DAG Core event recording
- Test DAG Core event history

**Test Cases**:
1. `test "DAG Core integration (Editor)"`
2. `test "DAG Core integration (Browser)"`
3. `test "DAG Core event recording"`
4. `test "DAG Core event history retrieval"`
5. `test "DAG Core version management"`

#### C. Shared Font Renderer Integration
- Test shared font renderer usage
- Test font rendering consistency
- Test font rendering performance

**Test Cases**:
1. `test "Shared font renderer integration"`
2. `test "Font rendering consistency"`
3. `test "Font rendering performance"`

---

## Test Execution Flow

### Setup Phase
1. Initialize test runner
2. Setup test helpers (Component API, GrainBuffer, DAG Core)
3. Create test fixtures
4. Initialize test contexts

### Execution Phase
1. Run Editor + Component Library integration tests
2. Run Browser + Component Library integration tests
3. Run Editor + Browser integration tests
4. Run shared module integration tests
5. Track results and timing for each test

### Teardown Phase
1. Cleanup test contexts
2. Teardown test helpers
3. Aggregate results
4. Generate summary report

---

## Grain Style Compliance

### Requirements
- ✅ `grain_case` function names
- ✅ Explicit `u32`/`u64` types (no `usize`/`isize`)
- ✅ Bounded allocations (`MAX_TEST_RESULTS`, `MAX_TEST_NAME_LEN`, etc.)
- ✅ Minimum 2 assertions per function
- ✅ Max 70 lines per function
- ✅ Max 100 characters per line
- ✅ All compiler warnings addressed
- ✅ Comprehensive error handling

### Bounded Allocation Constants
```zig
const MAX_TEST_RESULTS: u32 = 1000;
const MAX_TEST_NAME_LEN: u32 = 256;
const MAX_ERROR_MSG_LEN: u32 = 512;
const MAX_TEST_CONTEXTS: u32 = 100;
```

---

## Implementation Timeline

### Phase 1: Framework Structure (After Component API Phase 1)
- Create test directory structure
- Implement test runner (`runner.zig`)
- Implement test helpers (`helpers.zig`)
- Create README documentation

**Estimated Time**: 1-2 days

### Phase 2: Test Scenarios (After Component API Phase 1)
- Implement Editor + Component Library tests
- Implement Browser + Component Library tests
- Implement Editor + Browser tests
- Implement shared module tests

**Estimated Time**: 3-5 days

### Phase 3: Integration and Validation
- Integrate with build system (`build.zig`)
- Run integration tests
- Validate test coverage
- Document test results

**Estimated Time**: 1-2 days

---

## Dependencies

### Required (Before Implementation)
- ✅ Component API Phase 1 implementation complete
- ✅ Editor Agent Component API integration
- ✅ Browser Agent Component API integration

### Optional (Can Add Later)
- Performance benchmarking
- Stress testing
- Error injection testing
- Concurrency testing

---

## Future Enhancements

### Phase 2 Features
- Performance benchmarking suite
- Stress testing scenarios
- Error injection testing
- Concurrency testing
- Memory leak detection
- Coverage reporting

### Phase 3 Features
- Continuous integration (CI) integration
- Test result visualization
- Test result history tracking
- Automated regression detection

---

## Coordination

### With L2 Sub-Agents
- Editor Agent (2a): Provides Component API integration for testing
- Browser Agent (2b): Provides Component API integration for testing
- Component Library Agent (2c): Provides Component API implementation for testing

### With Core 1 Subcore
- Coordinate shared module test patterns (if applicable)
- Coordinate test infrastructure patterns (if applicable)

---

## Summary

**Framework Design**: ✅ **COMPLETE**

**Key Components**:
- Test runner with execution, timing, reporting
- Test helpers for setup/teardown, fixtures
- Integration test scenarios (Editor + Component Library, Browser + Component Library, Editor + Browser, Shared Modules)

**Implementation Status**: ⏳ **READY FOR IMPLEMENTATION** (after Component API Phase 1)

**Next Steps**: 
1. Wait for Component API Phase 1 implementation
2. Implement test framework structure
3. Implement integration test scenarios
4. Integrate with build system

---

**Date**: 2026-01-02-085016-pst  
**Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Status**: ✅ **FRAMEWORK DESIGN COMPLETE** — Ready for implementation after Component API Phase 1

