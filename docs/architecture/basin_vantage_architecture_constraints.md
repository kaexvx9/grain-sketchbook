# Basin/Vantage Architecture Constraints

**Date**: 2026-01-21-194401-pst  
**Status**: ✅ **MANDATORY** — Architecture separation requirements  
**Purpose**: Enforce strict separation between Basin (RISC-V) and Vantage (x86_64)

---

## Core Principle

**Basin targets RISC-V only. Vantage handles x86_64 only.**

This is a fundamental architectural constraint that ensures:
- Basin kernel code remains portable and RISC-V compliant
- Vantage VM properly isolates x86_64-specific code
- Clear separation of concerns between kernel and VM layers

---

## Architecture Separation Rules

### 1. Basin Layer (RISC-V Only)

**Location**: `src/basin/`, `src/kernel/`

**Constraint**: **NO x86_64 code allowed**

**Allowed**:
- ✅ RISC-V64 target only (`riscv64-freestanding-none`)
- ✅ RISC-V assembly only
- ✅ RISC-V SBI (Supervisor Binary Interface) only
- ✅ RISC-V linker scripts only (`linker_riscv64.ld`)

**Forbidden**:
- ❌ x86_64 targets
- ❌ x86_64 assembly
- ❌ x86_64 linker scripts
- ❌ x86_64-specific code paths
- ❌ Architecture conditionals that target x86_64

**Build Targets**:
- `zig build basin-rv64` → RISC-V64 only

### 2. Vantage Layer (x86_64 Only)

**Location**: `src/vantage/`, `src/kernel_vm/`

**Constraint**: **x86_64 host, RISC-V emulation**

**Allowed**:
- ✅ x86_64 target for Vantage VM itself
- ✅ x86_64 linker scripts (`linker_x86_64.ld`)
- ✅ x86_64 JIT compilation (RISC-V → x86_64)
- ✅ x86_64 boot protocol (Limine)
- ✅ RISC-V emulation/interpreter code

**Forbidden**:
- ❌ Direct RISC-V code execution (must use emulation/JIT)
- ❌ RISC-V build targets for Vantage itself

**Build Targets**:
- `zig build vantage-x86_64` → x86_64 only

### 3. Boot Layer (Architecture-Specific)

**Location**: `src/boot/`

**Constraint**: **Architecture-specific bootloaders allowed**

**Allowed**:
- ✅ x86_64 bootloader (`x86_64_uefi.zig`, `x86_64_drivers.zig`)
- ✅ RISC-V bootloader (future, if needed)
- ✅ Architecture-specific boot code

**Note**: Bootloaders are inherently architecture-specific, so this is expected.

---

## File Organization

### Basin (RISC-V)
```
src/basin/
  ├── hello_riscv.zig      # RISC-V kernel entry
  ├── linker_riscv64.ld    # RISC-V linker script
  └── ...

src/kernel/
  ├── *.zig                 # RISC-V kernel code
  ├── *.ry                  # RISC-V kernel code (Rye)
  ├── linker.ld             # RISC-V linker script
  └── ...
```

### Vantage (x86_64)
```
src/vantage/
  ├── main_x86_64.zig       # x86_64 Vantage VM entry
  ├── riscv_core.zig        # RISC-V emulator (runs on x86_64)
  ├── linker_x86_64.ld      # x86_64 linker script
  └── ...

src/kernel_vm/
  ├── vm.zig                # VM runtime (x86_64 host)
  ├── jit.zig               # JIT compiler (RISC-V → x86_64)
  ├── x86_64.zig            # x86_64 JIT backend
  └── ...
```

### Boot (Architecture-Specific)
```
src/boot/
  ├── x86_64_uefi.zig       # x86_64 bootloader
  ├── x86_64_drivers.zig    # x86_64 drivers
  ├── limine.zig            # Limine boot protocol (x86_64)
  └── ...
```

---

## Build System Constraints

### Basin Build
```zig
// ✅ CORRECT: RISC-V64 target only
const basin_rv64_exe = b.addExecutable(.{
    .name = "basin-rv64",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/basin/hello_riscv.zig"),
        .target = riscv64_freestanding,  // RISC-V only
        ...
    }),
});
```

### Vantage Build
```zig
// ✅ CORRECT: x86_64 target for Vantage VM
const vantage_x86_64_exe = b.addExecutable(.{
    .name = "vantage",
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/vantage/main_x86_64.zig"),
        .target = x86_64_kernel_resolved,  // x86_64 only
        ...
    }),
});
vantage_x86_64_exe.setLinkerScript(b.path("src/vantage/linker_x86_64.ld"));
```

---

## Violation Detection

### Common Violations

1. **x86_64 linker script in `src/kernel/`**
   - ❌ `src/kernel/linker_x86_64.ld`
   - ✅ `src/vantage/linker_x86_64.ld`

2. **x86_64 target in Basin build**
   - ❌ `basin_x86_64_exe` build step
   - ✅ Only `basin-rv64` build step

3. **x86_64 code paths in kernel code**
   - ❌ `if (target == .x86_64) { ... }` in `src/kernel/`
   - ✅ Architecture detection only in `src/vantage/` or `src/kernel_vm/`

4. **RISC-V build target for Vantage**
   - ❌ `vantage_rv64_exe` build step
   - ✅ Only `vantage-x86_64` build step

### Verification Commands

```bash
# Check for x86_64 references in Basin/kernel
grep -r "x86_64\|x86-64" src/basin/ src/kernel/ --exclude-dir=devx

# Check for RISC-V build targets for Vantage
grep -r "riscv64.*vantage\|vantage.*riscv64" build.zig

# Verify linker script locations
find src/kernel -name "*x86*" -o -name "*x86*"
find src/vantage -name "*x86*"
```

---

## Enforcement

**All new code must comply with these constraints.**

**Before committing**:
1. Verify no x86_64 code in `src/basin/` or `src/kernel/`
2. Verify no RISC-V build targets for Vantage VM itself
3. Verify linker scripts are in correct directories
4. Run verification commands above

**Code review checklist**:
- [ ] No x86_64 targets in Basin builds
- [ ] No x86_64 linker scripts in `src/kernel/`
- [ ] No architecture conditionals targeting x86_64 in Basin code
- [ ] Vantage uses x86_64 target only
- [ ] All x86_64 code is in `src/vantage/` or `src/kernel_vm/`

---

## Rationale

### Why This Separation?

1. **Portability**: Basin kernel code remains RISC-V portable
2. **Clarity**: Clear separation between kernel and VM layers
3. **Compliance**: RISC-V compliance requirements (see `docs/riscv_compliance_requirements.md`)
4. **Maintainability**: Easier to understand and maintain architecture-specific code

### Related Documents

- `docs/riscv_compliance_requirements.md` — RISC-V compliance requirements
- `docs/architecture/decisions/adr_005_riscv_to_x86_64_jit_strategy_2026-01-02-100345-pst.md` — JIT strategy
- `docs/kernel_vm/x86_64_jit_backend_design.md` — x86_64 JIT design

---

**Date**: 2026-01-21-194401-pst  
**Status**: ✅ **MANDATORY** — Architecture separation requirements
