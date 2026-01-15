# Grain OS: sevenos + Core 1 Subcore Unified Plan

**Date**: 2026-01-01-193653-pst  
**Context**: Framework 16 (x86_64 AMD, 64GB RAM) running Ubuntu 24.04 LTS  
**Purpose**: Unified plan merging sevenos (Grain Style Zig OS) with Core 1 Subcore agent architecture, focusing on Basin Kernel syscall → RISC-V → Vantage pipeline for Framework Ubuntu x86

---

## Executive Summary

**Unified Approach**: Merge sevenos (Grain Style OS in Zig) with Core 1 Subcore agent architecture, abandoning QEMU/KVM VM approach in favor of direct Framework Ubuntu x86 development with Basin Kernel syscall → RISC-V → Vantage pipeline.

**Key Changes from Previous Plans**:
- ❌ **Abandoned**: QEMU/KVM VM approach (all related docs deprecated)
- ✅ **New Focus**: Direct Framework Ubuntu x86 development
- ✅ **Architecture**: Basin Kernel syscall → RISC-V → Vantage pipeline
- ✅ **Language**: Zig (Grain Style principles)
- ✅ **Integration**: Core 1 Subcore agent architecture

---

## Architecture Overview

### System Flow

```
Framework Ubuntu x86 (Host)
  ↓
Basin Kernel (RISC-V syscalls)
  ↓
RISC-V VM Runtime (JIT compilation)
  ↓
Vantage System Integration
  ↓
Core 1 Subcore Agents (1a-1d)
```

### Components

1. **Basin Kernel** (Vantage 3a Agent)
   - RISC-V kernel with syscall interface
   - Runs in VM (RISC-V target)
   - Profiler infrastructure complete
   - **Status**: Ready for performance data collection

2. **VM Runtime** (Vantage 3b Agent)
   - RISC-V → x86_64 JIT compilation pipeline
   - **Priority**: HIGH for Framework migration
   - **Current**: RISC-V → ARM64 JIT (macOS)
   - **Target**: RISC-V → x86_64 JIT (Framework Ubuntu)

3. **System Integration** (Vantage 3c Agent)
   - Multi-architecture testing framework
   - **Current**: ARM64 only (MacBook Air M2)
   - **Target**: ARM64 + x86_64 AMD + x86_64 Intel

4. **sevenos Init System** (New Component)
   - Grain Style init system in Zig
   - S6-inspired supervision (native Zig implementation)
   - Explicit configuration, minimal dependencies
   - **Status**: Initial implementation in progress

5. **Core 1 Subcore Agents** (1a-1d)
   - 1a: Auth Agent
   - 1b: Network Agent
   - 1c: Storage Agent
   - 1d: Compositor Agent

---

## Grain Style Principles Applied

### sevenos Component

1. **Minimalism**: Small footprint, avoid unnecessary complexity
2. **Simplicity**: Easy to understand, maintain, and reason about
3. **Explicit Configuration**: No hidden behavior, clear and declarative
4. **Minimal Dependencies**: libc-free where possible, minimal runtime
5. **Safety**: Fail-fast, bounded operations, explicit limits
6. **Performance**: Fast boot times, efficient resource utilization
7. **Zero Technical Debt**: Do it right the first time

### Core 1 Subcore Integration

- **Agent Architecture**: Modular, explicit agent coordination
- **Framework Native**: Direct x86_64 development (no VM overhead)
- **RISC-V Kernel**: Basin Kernel provides syscall interface
- **JIT Pipeline**: Efficient RISC-V → x86_64 compilation

---

## Implementation Plan

### Phase 1: Framework Ubuntu x86 Setup (Week 1)

**Goals**:
- Set up Framework Ubuntu 24.04 LTS development environment
- Configure build system for x86_64 native development
- Set up agent workspace (Core 1 Subcore agents)

**Tasks**:
1. Framework 16 Ubuntu setup verification
2. Zig build system configuration for x86_64
3. Agent workspace recreation (Core 1 Subcore priority)
4. Build system verification (x86_64 native)

**Deliverables**:
- Working Framework Ubuntu development environment
- Agent workspace with Core 1 Subcore agents
- Build system verified for x86_64

---

### Phase 2: Basin Kernel → RISC-V Pipeline (Weeks 2-3)

**Goals**:
- Ensure Basin Kernel syscall interface works correctly
- Verify RISC-V VM runtime integration
- Test syscall → RISC-V → VM pipeline

**Tasks**:
1. Basin Kernel profiler data collection (3a Agent)
2. RISC-V VM runtime Phase 2 completion (3b Agent)
3. RISC-V → x86_64 JIT pipeline implementation (3b Agent)
4. System integration testing (3c Agent)

**Deliverables**:
- Working Basin Kernel syscall interface
- RISC-V → x86_64 JIT compilation pipeline
- Integration tests passing on Framework x86_64

---

### Phase 3: sevenos Init System (Weeks 4-6)

**Goals**:
- Implement sevenos init system in Zig
- S6-inspired supervision (native Zig)
- Integration with Basin Kernel syscall interface

**Tasks**:
1. sevenos init system core implementation
2. Service supervision system (S6-inspired)
3. Service dependency management
4. Integration with Basin Kernel syscalls
5. Configuration system (explicit, declarative)

**Deliverables**:
- Working sevenos init system
- Service supervision system
- Integration with Basin Kernel

---

### Phase 4: Core 1 Subcore Integration (Weeks 7-8)

**Goals**:
- Integrate Core 1 Subcore agents with sevenos
- Agent coordination via sevenos init system
- Multi-agent system testing

**Tasks**:
1. Core 1a Auth Agent integration
2. Core 1b Network Agent integration
3. Core 1c Storage Agent integration
4. Core 1d Compositor Agent integration
5. Agent coordination testing

**Deliverables**:
- Integrated Core 1 Subcore agents
- Agent coordination system
- Multi-agent system tests passing

---

### Phase 5: Vantage System Integration (Weeks 9-10)

**Goals**:
- Complete Vantage 3b VM Runtime Phase 3
- Multi-architecture testing framework (3c Agent)
- Full system integration testing

**Tasks**:
1. VM Runtime Phase 3 completion
2. Multi-architecture testing (ARM64, x86_64 AMD, x86_64 Intel)
3. Full system integration tests
4. Performance optimization

**Deliverables**:
- Complete VM Runtime implementation
- Multi-architecture testing
- Full system integration tests passing

---

## Technical Architecture

### sevenos Init System (Zig)

**Location**: `grainstore/sevenos/src/init/`

**Components**:
- `main.zig` - Init system entry point
- `supervision.zig` - Service supervision (S6-inspired)
- `services/` - Service definitions
- `config/` - Configuration system

**Integration Points**:
- Basin Kernel syscall interface
- Core 1 Subcore agent coordination
- Vantage system integration

---

### Basin Kernel Integration

**Syscall Interface**:
- RISC-V syscalls from Basin Kernel
- VM Runtime JIT compilation (RISC-V → x86_64)
- System integration layer

**File Paths**:
- Kernel: `src/kernel/` (8 kernel modules)
- VM Runtime: `src/kernel_vm/`
- Integration: `src/kernel_vm/integration.zig`

---

### Core 1 Subcore Agents

**Agent Structure**:
- 1a: Auth Agent (`src/core_1a_auth/`)
- 1b: Network Agent (`src/core_1b_network/`)
- 1c: Storage Agent (`src/core_1c_storage/`)
- 1d: Compositor Agent (`src/core_1d_compositor/`)

**Coordination**:
- Agent coordination via sevenos init system
- Explicit agent dependencies
- Agent lifecycle management

---

## Framework Ubuntu x86 Considerations

### Development Environment

- **OS**: Ubuntu 24.04 LTS
- **Architecture**: x86_64 AMD (Framework 16)
- **RAM**: 64GB (vs 24GB on MacBook Air M2)
- **Native Development**: Direct x86_64 compilation (no emulation)

### Build System

- **Language**: Zig
- **Target**: x86_64 native (Framework Ubuntu)
- **Kernel Target**: RISC-V (Basin Kernel in VM)
- **JIT Target**: x86_64 (VM Runtime compilation)

### Testing

- **Multi-Architecture**: ARM64 (MacBook Air M2), x86_64 AMD (Framework 16), x86_64 Intel (legacy)
- **Integration Tests**: Full system integration on Framework x86_64
- **Performance Tests**: Native x86_64 performance profiling

---

## Abandoned Approaches

### QEMU/KVM VM Approach

**Status**: ❌ **ABANDONED**

**Reason**: Direct Framework Ubuntu x86 development is more efficient and aligns better with Core 1 Subcore agent architecture.

**Deprecated Documents**:
- All `nixos-vm/` related documentation
- QEMU/KVM setup guides
- VM-specific configuration files

**Note**: Basin Kernel still runs in RISC-V VM, but host development is direct Framework Ubuntu x86.

---

## Migration from macOS Development

### Existing Work to Preserve

1. **Core 1 Subcore Agents**: All agent implementations
2. **Basin Kernel**: RISC-V kernel with syscall interface
3. **VM Runtime**: RISC-V → ARM64 JIT (adapt to x86_64)
4. **System Integration**: Integration test framework
5. **Agent Coordination**: Agent coordination patterns

### Framework-Specific Adaptations

1. **JIT Pipeline**: RISC-V → ARM64 → RISC-V → x86_64
2. **Build System**: ARM64 → x86_64 native compilation
3. **Testing**: ARM64 only → Multi-architecture (ARM64 + x86_64)
4. **Agent Workspace**: macOS Cursor → Framework Cursor

---

## Success Criteria

### Phase 1 Success
- ✅ Framework Ubuntu development environment working
- ✅ Agent workspace recreated
- ✅ Build system verified for x86_64

### Phase 2 Success
- ✅ Basin Kernel syscall interface working
- ✅ RISC-V → x86_64 JIT pipeline functional
- ✅ Integration tests passing

### Phase 3 Success
- ✅ sevenos init system implemented
- ✅ Service supervision working
- ✅ Integration with Basin Kernel

### Phase 4 Success
- ✅ Core 1 Subcore agents integrated
- ✅ Agent coordination working
- ✅ Multi-agent system tests passing

### Phase 5 Success
- ✅ Full system integration complete
- ✅ Multi-architecture testing working
- ✅ Performance optimized

---

## Timeline

**Total Duration**: 10 weeks

- **Week 1**: Framework Ubuntu x86 setup
- **Weeks 2-3**: Basin Kernel → RISC-V pipeline
- **Weeks 4-6**: sevenos init system
- **Weeks 7-8**: Core 1 Subcore integration
- **Weeks 9-10**: Vantage system integration

---

## Next Steps

### Immediate Actions

1. **Abandon QEMU/KVM VM Documentation**:
   - Mark all VM-related docs as deprecated
   - Remove VM setup from active plans

2. **Framework Ubuntu Setup**:
   - Verify Framework Ubuntu 24.04 LTS environment
   - Configure Zig build system for x86_64
   - Set up agent workspace

3. **Begin Phase 1 Implementation**:
   - Framework development environment setup
   - Agent workspace recreation
   - Build system verification

---

## Coordination

**Status**: ✅ **UNIFIED PLAN CREATED**

**Next Coordination**: Begin Phase 1 implementation (Framework Ubuntu x86 setup)

**Timeline**: 10-week implementation plan

---

**Date**: 2026-01-01-193653-pst  
**Status**: ✅ **GRAIN OS SEVENOS + CORE 1 SUBCORE UNIFIED PLAN COMPLETE**  
**Next Steps**: Begin Phase 1 (Framework Ubuntu x86 setup)

