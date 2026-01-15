# RISC-V Compliance Requirements

**Date**: 2025-12-31-000443-pst  
**Agent**: Grain System Integration Agent (3c)  
**Purpose**: Comprehensive RISC-V compliance requirements documentation for Basin kernel and Vantage VM

---

## Executive Summary

This document defines the RISC-V compliance requirements for the Grain OS Basin kernel and Vantage VM. All kernel and VM code must strictly comply with RISC-V architecture specifications to ensure correct operation and portability.

**Core Principle**: **RISC-V Only** — All Grain OS software (including Basin kernel) targets RISC-V only. No ARM64/AArch64-specific code is allowed in the kernel.

---

## Compliance Scope

### Kernel Compliance
- **Target Architecture**: RISC-V64 only (`riscv64-freestanding-none`)
- **Platform Code**: RISC-V SBI (Supervisor Binary Interface) only
- **Assembly Code**: RISC-V assembly only
- **Build Targets**: RISC-V64 build target only
- **No ARM64 Code**: No ARM64/AArch64-specific code, assembly, or build targets

### VM Compliance
- **Emulation Target**: RISC-V64 instruction set
- **Register File**: 32 RISC-V registers (x0-x31)
- **Instruction Set**: RISC-V RV64I base instruction set
- **Memory Model**: RISC-V memory model (little-endian, alignment requirements)
- **Exception Model**: RISC-V exception model

---

## RISC-V Architecture Requirements

### Register File
- **32 Registers**: x0 through x31
- **x0 Register**: Hardwired to zero (writes to x0 must be ignored)
- **Register Width**: 64 bits (RV64I)
- **Calling Convention**: RISC-V calling convention (x10-x17 for arguments, x1 for return address)

### Instruction Set
- **Base Instruction Set**: RV64I (64-bit base integer instruction set)
- **Instruction Width**: 32 bits (4 bytes)
- **Instruction Alignment**: All instructions must be 4-byte aligned
- **Instruction Encoding**: RISC-V instruction encoding format

### Memory Model
- **Byte Order**: Little-endian
- **Alignment Requirements**:
  - Word (4-byte) accesses: 4-byte aligned
  - Doubleword (8-byte) accesses: 8-byte aligned
- **Address Space**: 64-bit address space

### Exception Model
- **Exception Types**: RISC-V exception types (instruction page fault, load page fault, store page fault, environment call, etc.)
- **Exception Handling**: RISC-V exception handling model
- **Interrupt Model**: RISC-V interrupt model

---

## Compliance Validation

### Test Suite
- **File**: `tests/riscv_compliance_validation_test.zig`
- **Purpose**: Validate RISC-V compliance of VM emulation and kernel
- **Test Coverage**:
  - x0 register hardwired to zero
  - ADDI, ADD, LUI, JAL, BEQ instruction encoding and execution
  - Instruction alignment requirements
  - Memory alignment requirements
  - Calling convention register usage
  - Instruction encoding validation
  - Memory model compliance (little-endian)

### Validation Process
1. **Run RISC-V Compliance Test Suite**:
   - Execute `tests/riscv_compliance_validation_test.zig`
   - Validate VM instruction emulation accuracy
   - Validate RISC-V register file behavior
   - Validate RISC-V memory model implementation
   - Test RISC-V exception handling

2. **Kernel RISC-V-Only Validation**:
   - Search kernel codebase for any ARM64-specific code
   - Verify no ARM64 assembly or architecture-specific code
   - Verify `main.zig` only uses RISC-V platform code (`.riscv64`)
   - Validate all kernel code compiles for RISC-V target only
   - Document findings

3. **VM RISC-V Emulation Validation**:
   - Validate VM correctly emulates RISC-V instruction set
   - Validate VM register file has 32 registers
   - Validate VM memory model matches RISC-V requirements
   - Validate VM exception handling matches RISC-V model

---

## Compliance Checklist

### Kernel RISC-V-Only Compliance
- [x] AArch64 implementation files removed
- [x] AArch64 build target removed
- [x] Kernel main uses RISC-V platform only (`.riscv64`)
- [x] No ARM64 assembly files remain
- [x] No AArch64 implementation code remains
- [x] Build configuration targets RISC-V only (`riscv64-freestanding-none`)
- [x] Remaining AArch64 references are type definitions only (unified platform interface, acceptable)

### VM RISC-V Emulation Compliance
- [x] RISC-V compliance test suite created
- [x] Test suite added to build system
- [ ] Test suite executed (blocked by codebase compilation errors)
- [ ] VM instruction emulation validated
- [ ] VM register file behavior validated (32 registers, x0 hardwired to zero)
- [ ] VM memory model validated (little-endian, alignment)
- [ ] VM exception handling validated

### Documentation
- [x] RISC-V compliance validation report created
- [x] RISC-V compliance requirements documentation created (this document)
- [ ] Compliance test methodology documented
- [ ] Compliance validation process documented
- [x] Compliance checklist created (this document)

---

## Test Methodology

### Test Execution
1. **Build Test Suite**: `zig build test` (includes RISC-V compliance test suite)
2. **Run Test Suite**: Execute `tests/riscv_compliance_validation_test.zig`
3. **Validate Results**: All tests must pass
4. **Document Failures**: Any test failures must be documented and fixed

### Test Coverage
- **Instruction Tests**: Validate RISC-V instruction encoding and execution
- **Register Tests**: Validate RISC-V register file behavior
- **Memory Tests**: Validate RISC-V memory model
- **Alignment Tests**: Validate RISC-V alignment requirements
- **Exception Tests**: Validate RISC-V exception handling

### Test Requirements
- **Grain Style Compliance**: All tests must follow Grain Style (`grainwrap-100`, `grain validate-70`, explicit `u32`/`u64` types)
- **Comprehensive Assertions**: All tests must have preconditions and postconditions
- **Bounded Operations**: All tests must have explicit execution bounds
- **Clear Documentation**: All tests must have "Why" comments explaining RISC-V requirements

---

## Compliance Validation Process

### Phase 1: Kernel RISC-V-Only Validation
1. **Code Search**: Search kernel codebase for ARM64/AArch64-specific code
2. **Build Validation**: Verify kernel compiles for RISC-V target only
3. **Platform Validation**: Verify kernel uses RISC-V platform code only
4. **Documentation**: Document findings in compliance report

### Phase 2: VM RISC-V Emulation Validation
1. **Test Suite Execution**: Run RISC-V compliance test suite
2. **Instruction Validation**: Validate VM correctly emulates RISC-V instructions
3. **Register Validation**: Validate VM register file matches RISC-V requirements
4. **Memory Validation**: Validate VM memory model matches RISC-V requirements
5. **Exception Validation**: Validate VM exception handling matches RISC-V model

### Phase 3: Integration Validation
1. **Kernel/VM Integration**: Validate kernel/VM integration maintains RISC-V compliance
2. **End-to-End Testing**: Validate end-to-end RISC-V compliance
3. **Performance Validation**: Validate RISC-V compliance doesn't impact performance
4. **Documentation**: Document integration compliance

---

## Compliance Standards

### Code Standards
- **No ARM64 Code**: No ARM64/AArch64-specific code in kernel
- **RISC-V Only**: All kernel code must target RISC-V only
- **Platform Abstraction**: Use unified platform interface (type definitions acceptable, implementation code must be RISC-V only)

### Build Standards
- **RISC-V Target Only**: Build configuration must target RISC-V only
- **No ARM64 Build Targets**: No ARM64/AArch64 build targets allowed
- **Target Architecture**: `riscv64-freestanding-none` only

### Test Standards
- **Comprehensive Coverage**: Test suite must cover all RISC-V compliance requirements
- **Grain Style Compliance**: All tests must follow Grain Style
- **Documentation**: All tests must be well-documented

---

## Compliance Reporting

### Compliance Report
- **File**: `docs/riscv_compliance_validation_report.md`
- **Purpose**: Document compliance validation findings
- **Contents**: Findings, checklist, recommendations

### Compliance Status
- **Kernel RISC-V-Only**: ✅ **VERIFIED** — All AArch64 implementation code removed
- **VM RISC-V Emulation**: ⏳ **PENDING** — Test suite ready, execution blocked by compilation errors
- **Documentation**: ✅ **COMPLETE** — Compliance requirements documented

---

## Recommendations

### Immediate
1. **Resolve Compilation Errors**: Core Agent Priority 2 — Resolve codebase compilation errors to unblock test execution
2. **Execute Test Suite**: Run RISC-V compliance test suite once compilation errors resolved
3. **Validate VM Emulation**: Complete VM RISC-V emulation validation

### Short-Term
1. **Complete Documentation**: Finalize compliance test methodology and validation process documentation
2. **Integration Validation**: Validate kernel/VM integration maintains RISC-V compliance
3. **Performance Validation**: Validate RISC-V compliance doesn't impact performance

### Long-Term
1. **Continuous Compliance**: Maintain RISC-V-only compliance as codebase evolves
2. **Automated Validation**: Automate RISC-V compliance validation in CI/CD
3. **Compliance Monitoring**: Monitor compliance status regularly

---

## Conclusion

**RISC-V Compliance Requirements**: ✅ **DOCUMENTED** — Comprehensive requirements documented for kernel and VM.

**Kernel RISC-V-Only Compliance**: ✅ **VERIFIED** — All AArch64 implementation code removed, kernel strictly targets RISC-V only.

**VM RISC-V Emulation Compliance**: ⏳ **PENDING** — Test suite ready, execution blocked by compilation errors.

**Status**: ✅ **REQUIREMENTS DOCUMENTED** — RISC-V compliance requirements comprehensive documented. Proceeding with test suite execution once compilation errors are resolved.

---

**Date**: 2025-12-31-000443-pst  
**Agent**: Grain System Integration Agent (3c)  
**Parent Agent**: Grain Vantage 3 Subcore Agent (3rd Agent, L1 Subcore)
