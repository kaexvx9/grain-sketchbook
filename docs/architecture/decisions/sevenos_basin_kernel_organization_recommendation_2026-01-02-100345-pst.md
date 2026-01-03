# Architecture Decision: sevenos and Basin Kernel Organization

**Date**: 2026-01-02-100345-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: ✅ **RECOMMENDATION PROVIDED** — Organization recommendation for sevenos and Basin Kernel

---

## Executive Summary

**Recommendation**: **Keep Basin Kernel and sevenos separate** — Maintain current organization with Basin Kernel at `src/kernel/` and sevenos at `grainstore/sevenos/`.

**Reasoning**: Clear separation of concerns (kernel infrastructure vs userspace application), different build targets (RISC-V kernel vs x86_64 init system), modular architecture, and clean interface boundaries (syscall interface).

---

## Current Architecture

### Component Locations

**Basin Kernel**:
- **Location**: `src/kernel/` (58 files)
- **Target**: RISC-V64 (runs in VM)
- **Role**: Kernel infrastructure providing syscall interface
- **Agent**: Vantage 3a (Basin Kernel Agent)

**sevenos Init System**:
- **Location**: `grainstore/sevenos/` (separate project)
- **Target**: x86_64 (runs on host, uses kernel syscalls)
- **Role**: Userspace init system using Basin Kernel syscalls
- **Agent**: Vantage 3d (sevenos Init System Agent)

### Integration Flow

```
Framework Ubuntu x86 (Host)
  ↓
sevenos Init System (x86_64, userspace)
  ↓ (uses Basin Kernel syscalls)
Basin Kernel (RISC-V, runs in VM)
  ↓ (process management)
VM Runtime (3b) JIT compilation
  ↓
Service Processes (RISC-V, in VM)
```

---

## Recommendation: Keep Separate

### Rationale

1. **Separation of Concerns**:
   - Basin Kernel = **Infrastructure** (kernel layer)
   - sevenos Init System = **Application** (userspace layer)
   - Clear architectural boundary (kernel vs userspace)

2. **Different Build Targets**:
   - Basin Kernel: RISC-V64 (kernel binary)
   - sevenos Init System: x86_64 (userspace binary)
   - Separate build systems and compilation targets

3. **Different Development Cycles**:
   - Basin Kernel: Kernel development (syscalls, process management)
   - sevenos Init System: Init system development (service management, configuration)
   - Independent development and testing

4. **Modular Architecture**:
   - Basin Kernel provides syscall interface (stable API)
   - sevenos Init System uses syscall interface (client of kernel)
   - Clear interface boundary (syscall interface documentation)

5. **Build System Organization**:
   - Basin Kernel: `build/kernel.zig` (kernel build configuration)
   - sevenos Init System: `grainstore/sevenos/build.zig` (separate build)
   - Maintains build system modularity

6. **Agent Organization**:
   - Basin Kernel: Agent 3a (separate agent, separate responsibilities)
   - sevenos Init System: Agent 3d (separate agent, separate responsibilities)
   - Clear agent boundaries and coordination points

---

## Alternative Considered: Moving Basin Kernel into sevenos

### Why This Would Be Problematic

1. **Loss of Separation of Concerns**:
   - Kernel and userspace would be mixed
   - Breaks architectural clarity (kernel vs userspace boundary)

2. **Build System Complexity**:
   - Would require integrating kernel build into sevenos build
   - Different compilation targets (RISC-V vs x86_64) in same build

3. **Agent Organization Confusion**:
   - Basin Kernel Agent (3a) and sevenos Init System Agent (3d) would share codebase
   - Coordination boundaries would become unclear

4. **Reusability**:
   - Basin Kernel is infrastructure used by multiple components
   - Moving it into sevenos would reduce reusability

5. **Documentation Clarity**:
   - Current organization makes kernel vs userspace distinction clear
   - Moving would blur boundaries

---

## Recommended Organization

### Current Structure (Recommended)

```
src/
  kernel/              ← Basin Kernel (RISC-V, kernel infrastructure)
    basin_kernel.zig
    basin_kernel_core.zig
    basin_kernel_types.zig
    ... (58 files)

grainstore/
  sevenos/            ← sevenos Init System (x86_64, userspace application)
    src/
      init/
        main.zig
      lib/
        supervision.zig
        config/
          loader.zig
        dependency.zig
    build.zig
```

### Interface Boundary

**Syscall Interface Documentation** (provides clear boundary):
- `docs/kernel/syscall_interface_reference.md` (complete syscall reference)
- `docs/kernel/syscall_interface_for_init.md` (Init System-specific guide)
- `docs/kernel/syscall_interface_for_jit.md` (JIT-specific guide)

**Integration Pattern**:
- sevenos Init System uses Basin Kernel syscalls via VM Runtime
- Clear interface: syscall numbers, arguments, return values
- Well-documented API boundary

---

## Benefits of Current Organization

1. **Clear Architecture**:
   - Kernel (infrastructure) vs Userspace (applications)
   - Clear separation of concerns

2. **Modular Development**:
   - Independent development cycles
   - Independent testing and validation

3. **Build System Clarity**:
   - Separate build configurations
   - Clear compilation targets

4. **Agent Organization**:
   - Clear agent boundaries (3a vs 3d)
   - Clear coordination points (syscall interface)

5. **Reusability**:
   - Basin Kernel is infrastructure for multiple userspace components
   - sevenos Init System is one client of the kernel

6. **Documentation Clarity**:
   - Clear documentation structure
   - Clear interface boundaries

---

## Integration Approach

### Current Integration Pattern (Recommended)

1. **Interface**: Basin Kernel syscall interface (documented)
2. **Implementation**: sevenos Init System uses syscalls via VM Runtime
3. **Coordination**: Agents 3a and 3d coordinate via syscall interface documentation
4. **Testing**: System Integration (3c) tests integration via syscall interface

### Integration Flow

```
sevenos Init System (3d)
  ↓ (uses)
Basin Kernel Syscall Interface (3a)
  ↓ (documented in)
docs/kernel/syscall_interface_for_init.md
  ↓ (tested by)
System Integration (3c)
```

---

## Conclusion

**Recommendation**: **Keep Basin Kernel and sevenos separate** — Maintain current organization.

**Key Points**:
- Clear separation of concerns (kernel vs userspace)
- Different build targets (RISC-V vs x86_64)
- Modular architecture with clear interface boundaries
- Maintains agent organization clarity
- Preserves reusability and documentation clarity

**Action**: No structural changes needed. Continue with current organization and focus on integration via syscall interface documentation.

---

**Date**: 2026-01-02-100345-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: ✅ **RECOMMENDATION PROVIDED** — Keep Basin Kernel and sevenos separate

