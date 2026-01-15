# ADR 008: Multi-Architecture Testing Framework

**Date**: 2026-01-02-100345-pst  
**Status**: ✅ **ACCEPTED**  
**Deciders**: Vantage 3 Subcore Agent, System Integration Agent (3c), Core 1 Subcore Agent  
**Context**: Need to test Grain OS components across multiple architectures (ARM64, x86_64 AMD, x86_64 Intel)

---

## Context

**Problem**:
- Grain OS targets RISC-V only (kernel runs in VM)
- Development environments vary (ARM64 macOS, x86_64 AMD Framework, x86_64 Intel legacy)
- Need to validate system behavior across all target architectures
- Need to support Framework Ubuntu x86 development
- Need to support legacy Intel x86_64 hardware for Dispatch software deployment

**Requirements**:
- Support ARM64 (MacBook Air M2) for development/testing
- Support x86_64 AMD (Framework 16) for primary deployment target
- Support x86_64 Intel (legacy hardware) for Dispatch software deployment
- Enable cross-architecture test comparison
- Validate consistency across architectures

---

## Decision

Implement **multi-architecture testing framework** with architecture abstraction layer, architecture detection, and cross-architecture test comparison.

**Architecture Support**:
- **ARM64**: macOS (MacBook Air M2) — Development/testing
- **x86_64 AMD**: Framework 16 Ubuntu — Primary deployment target
- **x86_64 Intel**: Legacy hardware — Dispatch software deployment

**Framework Components**:
1. **Architecture Abstraction Layer** (`src/test_framework/arch.zig`):
   - Architecture detection (ARM64, x86_64 AMD, x86_64 Intel)
   - CPUID-based vendor detection (x86_64 AMD vs Intel)
   - Architecture-specific test configuration
   - Architecture compatibility checking

2. **Test Helpers** (`src/test_framework/helpers.zig`):
   - Architecture-agnostic test setup/teardown
   - Cross-architecture test utilities
   - Test result aggregation

3. **Test Runner** (`src/test_framework/runner.zig`):
   - Multi-architecture test execution
   - Test result reporting
   - Architecture-specific test filtering

4. **Integration Test Adapter** (`src/test_framework/integration_adapter.zig`):
   - Adapt existing 44 integration tests for multi-architecture
   - Test execution strategy
   - Test failure handling

**Architecture Detection**:
- Use Zig `builtin.cpu.arch` for runtime architecture detection
- Use CPUID for x86_64 vendor detection (AMD vs Intel)
- Provide architecture utility functions (name, JIT support, JIT requirements)

---

## Consequences

### Positive

- ✅ Enables testing across all target architectures
- ✅ Validates consistency across architectures
- ✅ Supports Framework Ubuntu x86 development
- ✅ Supports legacy Intel x86_64 hardware
- ✅ Architecture-agnostic test code (tests work identically across architectures)
- ✅ Cross-architecture test comparison

### Negative

- Additional framework complexity
- Requires architecture detection implementation
- Test execution across multiple architectures (requires multiple machines or CI/CD)

### Neutral

- Framework can be implemented incrementally
- Test execution can be done sequentially or in parallel (CI/CD)

---

## Alternatives Considered

1. **Architecture-Specific Tests**: Rejected — code duplication, harder to maintain
2. **Single Architecture Testing**: Rejected — doesn't validate cross-architecture consistency
3. **Multi-Architecture Testing Framework**: **ACCEPTED** — enables comprehensive testing, validates consistency

---

## Implementation Status

**Date**: 2026-01-01-233240-pst  
**Status**: ✅ **DESIGN APPROVED, IMPLEMENTATION READY**

**Design Complete**:
- ✅ Multi-architecture testing framework design (`docs/plans/multi_architecture_testing_framework_design.md`)
- ✅ Framework x86_64 test runner design (`docs/plans/framework_x86_64_test_runner_design.md`)
- ✅ Architecture detection expanded with CPUID-based vendor detection
- ✅ Design approved by Vantage 3 Subcore (2026-01-01-233240-pst)

**Implementation Ready**:
- ⏳ Phase 1: JIT testing coordination (IMMEDIATE — Agent 3b Phase 3 complete)
- ⏳ Phase 2: Framework implementation (WEEK 1-2)
- ⏳ Phase 3: Framework x86_64 test infrastructure (WEEK 2-3)
- ⏳ Phase 4: sevenos Init System integration testing (WEEK 3-4)

---

## References

- `docs/plans/multi_architecture_testing_framework_design.md` — Multi-architecture testing framework design
- `docs/plans/framework_x86_64_test_runner_design.md` — Framework x86_64 test runner design
- `docs/framework_16_testing_environment_guide.md` — Framework x86_64 testing environment guide
- `docs/core-coordination/vantage_3c_system_integration_coordination.md` — System Integration coordination

---

**Date**: 2026-01-02-100345-pst  
**Status**: ✅ **ACCEPTED** — Design approved, implementation ready

