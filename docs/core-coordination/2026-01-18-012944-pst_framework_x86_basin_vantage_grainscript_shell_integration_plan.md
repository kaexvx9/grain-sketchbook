# Framework x86 Basin + Vantage + Grainscript Shell Integration Plan

**Date**: 2026-01-18-012944-pst  
**Voices**: Reya (vegan cyberpunk) & Glow G2 (steadfast brick foundation)  
**Purpose**: Complete plan for getting Basin Kernel and Vantage VM working on Framework x86_64 to load and run Grainscript shell  
**Status**: 🚀 **INTEGRATION PLAN** — Ready for implementation

---

## Executive Summary

**Reya**: Neon-bright integration path. Basin Kernel in Vantage VM on Framework x86_64, loading Grainscript shell. Terminal-native, keyboard-driven, Grain Style integrated.

**Glow G2**: Steadfast foundation. The path with heart. Critical path Steps 1-4 complete. Now we integrate all components for Framework x86_64 execution.

**Goal**: Get Basin Kernel running in Vantage VM (x86_64 JIT) on Framework x86_64, and successfully load and run Grainscript shell as a process inside the kernel.

---

## Architecture Overview

### Component Stack

```
Framework x86_64 (Ubuntu 24.04 LTS)
└── Vantage VM Runtime (x86_64 JIT backend)
    └── Basin Kernel (RISC-V, running in VM)
        └── Grainscript Shell Process (spawned via spawn syscall)
```

### Integration Points

1. **Vantage VM → Basin Kernel**: VM loads kernel, provides syscall interface
2. **Basin Kernel → Grainscript Shell**: Kernel spawns shell process from ELF executable
3. **Grainscript Shell → Basin Kernel**: Shell makes syscalls to kernel
4. **Framework x86_64 → Vantage VM**: Host system runs VM with x86_64 JIT

---

## Current Status Assessment

### ✅ Completed Components

1. **Basin Kernel (3a)**:
   - ✅ All 8 phases complete
   - ✅ Syscall interface complete (140 syscalls)
   - ✅ REPL with Grainscript eval capability
   - ✅ Process spawn syscall implemented
   - ✅ ELF loading implemented
   - ✅ VM memory reader/writer integration complete

2. **Vantage VM Runtime (3b)**:
   - ✅ x86_64 JIT backend complete
   - ✅ ECALL fallback implemented
   - ✅ Guest RAM pointer architecture (R13 register)
   - ✅ Step 2 complete (critical path)

3. **Grainscript Shell (1e)**:
   - ✅ Shell implementation complete
   - ✅ All tests passing
   - ✅ Step 4 complete (critical path)
   - ✅ Integration tests passing

4. **Integration Layer**:
   - ✅ `src/kernel_vm/integration.zig` exists
   - ✅ VM memory reader/writer wrappers implemented
   - ✅ Syscall handler wrapper implemented

### ⏳ Missing/Incomplete Components

1. **Grainscript Shell ELF Executable**:
   - ⚠️ Shell is built for x86_64 Linux (POSIX)
   - ⚠️ Need RISC-V ELF executable for Basin Kernel VM
   - ⚠️ Need to build shell targeting RISC-V64

2. **VM Executable Loading**:
   - ⏳ Need to load Grainscript shell ELF into VM memory
   - ⏳ Need to spawn shell process from loaded ELF
   - ⏳ Need to verify spawn syscall works in VM context

3. **End-to-End Integration Test**:
   - ⏳ Need test that verifies full stack works
   - ⏳ Need Framework x86_64 specific test
   - ⏳ Need manual testing workflow

---

## Implementation Plan

### Phase 1: Build Grainscript Shell for RISC-V64

**Goal**: Create RISC-V64 ELF executable of Grainscript shell that can run in Basin Kernel VM.

**Tasks**:

1. **Create RISC-V64 Build Target for Shell**:
   - Add RISC-V64 build target to `grainstore/sevenos/build.zig`
   - Configure shell to build for RISC-V64 (freestanding, no libc)
   - Ensure shell uses Basin Kernel syscalls (not POSIX)

2. **Adapt Shell for Freestanding Environment**:
   - Remove POSIX dependencies (getcwd, etc.)
   - Use Basin Kernel syscalls instead
   - Ensure shell works in freestanding kernel environment

3. **Build Shell ELF**:
   - Build shell targeting RISC-V64
   - Verify ELF format is correct
   - Test ELF loading in kernel tests

**Files to Modify**:
- `grainstore/sevenos/build.zig` - Add RISC-V64 target
- `grainstore/sevenos/src/shell/grainscript.zig` - Adapt for freestanding
- `grainstore/sevenos/src/shell/builtins.zig` - Use kernel syscalls

**Deliverables**:
- `zig-out/bin/grainscript-shell-rv64` - RISC-V64 ELF executable
- Shell works in freestanding kernel environment

**Estimated Time**: 2-4 hours

---

### Phase 2: Load Shell ELF into VM Memory

**Goal**: Load Grainscript shell ELF executable into Vantage VM memory so Basin Kernel can spawn it.

**Tasks**:

1. **Create ELF Loader Helper**:
   - Add function to load ELF file from host filesystem into VM memory
   - Use VM memory writer to write ELF data
   - Verify ELF is loaded correctly

2. **Integrate with Vantage VM**:
   - Add ELF loading to VM initialization
   - Load shell ELF during VM setup
   - Store ELF address for kernel spawn syscall

3. **Test ELF Loading**:
   - Create test that loads shell ELF into VM
   - Verify ELF data is correct in VM memory
   - Verify kernel can read ELF from VM memory

**Files to Create/Modify**:
- `src/kernel_vm/loader.zig` - Add ELF file loading function
- `src/kernel_vm/integration.zig` - Integrate ELF loading
- `tests/167_vm_elf_loading_test.zig` - Test ELF loading

**Deliverables**:
- ELF loader function
- Shell ELF loaded in VM memory
- Test verifying ELF loading

**Estimated Time**: 2-3 hours

---

### Phase 3: Spawn Shell Process in Kernel

**Goal**: Use Basin Kernel spawn syscall to create Grainscript shell process from loaded ELF.

**Tasks**:

1. **Verify Spawn Syscall in VM Context**:
   - Test spawn syscall works with VM memory reader
   - Verify ELF parsing works with VM memory
   - Verify process creation succeeds

2. **Create Shell Spawn Helper**:
   - Add helper function to spawn shell process
   - Use loaded ELF address
   - Handle spawn errors appropriately

3. **Test Shell Process Creation**:
   - Create test that spawns shell in VM
   - Verify process is created correctly
   - Verify process can execute

**Files to Create/Modify**:
- `src/kernel_vm/integration.zig` - Add shell spawn helper
- `tests/168_vm_shell_spawn_test.zig` - Test shell spawning

**Deliverables**:
- Shell spawn helper function
- Shell process created in kernel
- Test verifying shell spawn

**Estimated Time**: 2-3 hours

---

### Phase 4: End-to-End Integration Test

**Goal**: Create complete end-to-end test that verifies full stack works on Framework x86_64.

**Tasks**:

1. **Create Full Stack Test**:
   - Initialize Vantage VM with x86_64 JIT
   - Load Basin Kernel into VM
   - Load Grainscript shell ELF into VM
   - Spawn shell process
   - Verify shell runs and responds

2. **Framework x86_64 Specific Test**:
   - Test on Framework x86_64 hardware
   - Verify JIT compilation works
   - Verify performance is acceptable

3. **Manual Testing Workflow**:
   - Create script to run full stack
   - Document testing procedures
   - Create troubleshooting guide

**Files to Create**:
- `tests/169_framework_x86_full_stack_test.zig` - Full stack test
- `scripts/run_basin_vantage_shell.sh` - Manual test script
- `docs/framework_x86_integration_testing.md` - Testing guide

**Deliverables**:
- End-to-end integration test
- Manual testing script
- Testing documentation

**Estimated Time**: 3-4 hours

---

## Detailed Implementation Steps

### Step 1: Build Shell for RISC-V64

**File**: `grainstore/sevenos/build.zig`

**Changes Needed**:
```zig
// Add RISC-V64 build target for shell
const shell_rv64_mod = b.addModule("shell_rv64", .{
    .root_source_file = b.path("src/shell/grainscript.zig"),
    .target = .{
        .cpu_arch = .riscv64,
        .os_tag = .freestanding,
        .abi = .none,
    },
    .optimize = optimize,
    .imports = &.{
        .{ .name = "grainscript", .module = grainscript_mod },
    },
});

const shell_rv64_exe = b.addExecutable(.{
    .name = "grainscript-shell-rv64",
    .root_module = shell_rv64_mod,
});
// No libc linking for freestanding
b.installArtifact(shell_rv64_exe);
```

**Shell Adaptations Needed**:
- Replace `std.posix.getcwd()` with kernel syscall
- Replace file I/O with kernel syscalls
- Remove POSIX dependencies
- Use kernel memory allocator

---

### Step 2: Load ELF into VM Memory

**File**: `src/kernel_vm/loader.zig`

**New Function**:
```zig
/// Load ELF file from host filesystem into VM memory.
/// Why: Load executables (like Grainscript shell) into VM for kernel to spawn.
/// Contract: file_path must be valid, vm must be initialized, addr must be valid.
pub fn load_elf_file_into_vm(
    vm: *VM,
    file_path: []const u8,
    vm_addr: u64,
) !u64 {
    // Read ELF file from host
    // Write ELF data to VM memory using vm_memory_writer
    // Return VM address where ELF is loaded
}
```

**Integration**:
- Call `load_elf_file_into_vm()` during VM initialization
- Store shell ELF address for kernel use
- Verify ELF is loaded correctly

---

### Step 3: Spawn Shell Process

**File**: `src/kernel_vm/integration.zig`

**New Function**:
```zig
/// Spawn Grainscript shell process in Basin Kernel.
/// Why: Create shell process from loaded ELF executable.
/// Contract: kernel and vm must be initialized, shell_elf_addr must be valid.
pub fn spawn_shell_process(
    kernel: *BasinKernel,
    vm: *VM,
    shell_elf_addr: u64,
) !u64 {
    // Use kernel spawn syscall with shell ELF address
    // Return process ID
}
```

**Test**:
- Create test that spawns shell
- Verify process is created
- Verify process can execute

---

### Step 4: End-to-End Test

**File**: `tests/169_framework_x86_full_stack_test.zig`

**Test Structure**:
```zig
test "framework x86: basin + vantage + grainscript shell full stack" {
    // 1. Initialize Vantage VM with x86_64 JIT
    // 2. Load Basin Kernel into VM
    // 3. Load Grainscript shell ELF into VM
    // 4. Spawn shell process
    // 5. Verify shell runs
    // 6. Test shell commands
}
```

---

## Testing Strategy

### Unit Tests

1. **Shell RISC-V64 Build Test**:
   - Verify shell builds for RISC-V64
   - Verify ELF format is correct
   - Verify no POSIX dependencies

2. **ELF Loading Test**:
   - Test ELF file loading into VM memory
   - Verify ELF data integrity
   - Verify address translation works

3. **Shell Spawn Test**:
   - Test shell process creation
   - Verify process execution
   - Verify syscall integration

### Integration Tests

1. **Full Stack Test**:
   - Test complete stack on Framework x86_64
   - Verify JIT compilation works
   - Verify shell runs correctly

2. **Manual Testing**:
   - Boot VM with kernel
   - Load and spawn shell
   - Test shell commands interactively

---

## Success Criteria

### Phase 1 Success
- ✅ Shell builds for RISC-V64
- ✅ Shell ELF is valid
- ✅ Shell has no POSIX dependencies

### Phase 2 Success
- ✅ Shell ELF loads into VM memory
- ✅ ELF data is correct in VM
- ✅ Kernel can read ELF from VM

### Phase 3 Success
- ✅ Shell process spawns successfully
- ✅ Process executes correctly
- ✅ Shell can make syscalls

### Phase 4 Success
- ✅ Full stack test passes
- ✅ Shell runs on Framework x86_64
- ✅ Manual testing workflow works

---

## Blockers and Dependencies

### Current Blockers

1. **Shell Build Target**:
   - Shell currently builds for x86_64 Linux (POSIX)
   - Need RISC-V64 freestanding build
   - Need to adapt shell for kernel environment

2. **ELF Loading**:
   - Need ELF file loader for VM
   - Need integration with VM memory writer
   - Need address translation

3. **Process Spawn in VM**:
   - Need to verify spawn works with VM memory
   - Need to test ELF parsing from VM memory
   - Need to verify process execution

### Dependencies

1. **Vantage VM** (3b):
   - ✅ x86_64 JIT backend complete
   - ✅ VM memory writer available
   - ✅ Integration layer exists

2. **Basin Kernel** (3a):
   - ✅ Spawn syscall implemented
   - ✅ ELF loading implemented
   - ✅ VM memory reader/writer integrated

3. **Grainscript Shell** (1e):
   - ✅ Shell implementation complete
   - ⚠️ Need RISC-V64 build
   - ⚠️ Need kernel syscall adaptation

---

## Next Steps (Immediate)

### This Week

1. **Build Shell for RISC-V64** (Phase 1):
   - Add RISC-V64 build target
   - Adapt shell for freestanding
   - Build and verify ELF

2. **Load ELF into VM** (Phase 2):
   - Create ELF loader function
   - Integrate with VM
   - Test ELF loading

3. **Spawn Shell Process** (Phase 3):
   - Create spawn helper
   - Test process creation
   - Verify execution

### Next Week

1. **End-to-End Integration** (Phase 4):
   - Create full stack test
   - Test on Framework x86_64
   - Document workflow

2. **Manual Testing**:
   - Create test script
   - Test interactively
   - Document procedures

---

## Coordination Needs

### With Vantage 3 Subcore

**Request**: Coordinate on VM integration and testing framework.

**Context**: Need to verify VM memory writer works correctly, need to test JIT compilation with shell execution.

**Timeline**: This week (Phases 1-3)

### With Basin Kernel (3a)

**Request**: Verify spawn syscall works with VM memory reader, verify ELF loading works from VM memory.

**Context**: Need to ensure kernel can spawn processes from ELF loaded in VM memory.

**Timeline**: This week (Phase 3)

### With Core 1e Grainscript (1e)

**Request**: Coordinate on shell adaptations for freestanding kernel environment.

**Context**: Need to adapt shell to use kernel syscalls instead of POSIX.

**Timeline**: This week (Phase 1)

---

## Summary

**Reya**: Neon-bright integration path. Four phases to get Basin + Vantage + Grainscript shell working on Framework x86_64. Terminal-native, keyboard-driven, Grain Style integrated.

**Glow G2**: Steadfast foundation. The path with heart. Clear phases, clear deliverables, clear success criteria. Ready to implement.

**Status**: 🚀 **READY FOR IMPLEMENTATION**

**Next Action**: Begin Phase 1 - Build Shell for RISC-V64

---

**Date**: 2026-01-18-012944-pst  
**Voices**: Reya (vegan cyberpunk) & Glow G2 (steadfast foundation)  
**Status**: ✅ **INTEGRATION PLAN COMPLETE** — Ready for implementation
