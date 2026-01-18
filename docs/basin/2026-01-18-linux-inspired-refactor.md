# Linux-Inspired Codebase Refactoring Plan

**Date**: 2026-01-18  
**Status**: Planning  
**Goal**: Reorganize Basin/Vantage to follow Linux 6.x patterns with smaller files

## Current State

Large monolithic files that are hard to navigate:

| File | Lines | Issue |
|------|-------|-------|
| `src/kernel_vm/vm.zig` | ~4400 | Too large, mixed concerns |
| `src/kernel_vm/jit.zig` | ~3700 | Multiple backends in one file |
| `src/kernel/basin_kernel.zig` | ~1600 | Exports + implementation mixed |
| `src/kernel/basin_kernel_core.zig` | ~1400 | Many subsystems in one struct |

## Target State

Files should be 200-500 lines each (Grain Style: 64-line functions fit well).

## Linux Kernel Patterns to Follow

### 1. Subsystem Directories

```
arch/           # Architecture-specific code
  riscv64/      # RISC-V 64-bit
  x86_64/       # x86-64 (for JIT)
core/           # Core kernel (scheduler, process, syscall)
mm/             # Memory management
fs/             # Filesystem
net/            # Networking
drivers/        # Device drivers
lib/            # Shared utilities
include/        # Type definitions
```

### 2. File Size Guidelines

- **~100 lines**: Type definitions, constants
- **~200-300 lines**: Single subsystem implementation
- **~400-500 lines**: Complex subsystem with helpers
- **Never >1000 lines**: Split into multiple files

### 3. Import Patterns

Linux uses headers. In Zig, we use:
- `types.zig` - Shared type definitions
- `api.zig` or `mod.zig` - Public interface (re-exports)
- `internal.zig` - Internal helpers (not exported)

## Refactoring Plan

### Phase 1: Vantage VM (src/kernel_vm/)

Current `vm.zig` (~4400 lines) splits into:

```
src/kernel_vm/
├── vm.zig              # Main VM struct, step(), step_fast() (~300 lines)
├── registers.zig       # Register file (~100 lines) - DONE
├── memory.zig          # Memory read/write (~200 lines)
├── fetch.zig           # Instruction fetch (~100 lines)
├── decode.zig          # Instruction decoding (~200 lines)
├── execute/
│   ├── mod.zig         # Execute dispatcher (~100 lines)
│   ├── alu.zig         # ADD, SUB, AND, OR, XOR (~200 lines)
│   ├── load_store.zig  # LB, LH, LW, LD, SB, SH, SW, SD (~300 lines)
│   ├── branch.zig      # BEQ, BNE, BLT, BGE, etc. (~200 lines)
│   ├── jump.zig        # JAL, JALR (~100 lines)
│   ├── system.zig      # ECALL, EBREAK, CSR (~200 lines)
│   └── compressed.zig  # RVC instructions (~400 lines)
├── sbi.zig             # SBI interface (~150 lines) - DONE
├── serial.zig          # Serial I/O (~200 lines) - DONE
├── memory_protection.zig # Page table (~200 lines) - DONE
└── loader.zig          # ELF loader (~200 lines) - DONE
```

### Phase 2: JIT (src/kernel_vm/jit/)

Current `jit.zig` (~3700 lines) splits into:

```
src/kernel_vm/jit/
├── mod.zig             # JitContext, compile_block() (~300 lines)
├── types.zig           # Instruction struct, enums (~100 lines)
├── cache.zig           # Block cache (~150 lines)
├── perf.zig            # Performance counters (~200 lines)
├── arm64/
│   ├── mod.zig         # ARM64 backend entry (~100 lines)
│   ├── emit.zig        # ARM64 instruction emission (~400 lines)
│   └── translate.zig   # RISC-V to ARM64 (~500 lines)
└── x86_64/
    ├── mod.zig         # x86_64 backend entry (~100 lines)
    ├── emit.zig        # x86_64 instruction emission (~400 lines)
    └── translate.zig   # RISC-V to x86_64 (~500 lines)
```

### Phase 3: Basin Kernel (src/kernel/)

Follow Linux arch/core/mm/fs/net/drivers pattern:

```
src/kernel/
├── main.zig            # Entry point, kmain() (~100 lines)
├── arch/
│   └── riscv64/
│       ├── boot.zig    # Boot sequence (~100 lines)
│       ├── trap.zig    # Trap handling (~200 lines)
│       ├── platform.zig # Platform abstraction (~150 lines)
│       ├── entry.S     # Assembly entry
│       └── linker.ld   # Linker script
├── core/
│   ├── syscall.zig     # Syscall dispatch (~200 lines)
│   ├── process.zig     # Process management (~300 lines)
│   ├── scheduler.zig   # Scheduler (~200 lines)
│   └── signal.zig      # Signal handling (~200 lines)
├── mm/
│   ├── memory.zig      # Memory management (~200 lines)
│   ├── page.zig        # Page allocation (~200 lines)
│   └── cow.zig         # Copy-on-write (~150 lines)
├── fs/
│   ├── vfs.zig         # Virtual filesystem (~200 lines)
│   ├── storage.zig     # In-memory storage (~200 lines)
│   └── elf.zig         # ELF parsing (~200 lines)
├── net/
│   ├── socket.zig      # Socket abstraction (~200 lines)
│   ├── tcp.zig         # TCP implementation (~300 lines)
│   ├── udp.zig         # UDP implementation (~200 lines)
│   └── channel.zig     # IPC channels (~200 lines)
├── drivers/
│   ├── console.zig     # Console/UART (~150 lines)
│   ├── framebuffer.zig # Display (~200 lines)
│   ├── keyboard.zig    # Input (~150 lines)
│   └── audio.zig       # Audio (~200 lines)
├── lib/
│   ├── debug.zig       # Debug/logging (~150 lines)
│   ├── raw_io.zig      # Raw I/O (~100 lines)
│   └── time.zig        # Time utilities (~100 lines)
└── include/
    ├── types.zig       # Shared types (~300 lines)
    ├── syscall_nums.zig # Syscall numbers (~100 lines)
    └── error.zig       # Error types (~100 lines)
```

## Implementation Strategy

1. **Create directory structure** first (empty dirs)
2. **Move type definitions** to include/ (low risk)
3. **Extract small utilities** to lib/ (low risk)
4. **Split VM execute functions** into execute/ (medium risk)
5. **Split JIT backends** into jit/arm64/ and jit/x86_64/ (medium risk)
6. **Reorganize kernel** into arch/core/mm/fs/net/drivers (higher risk)

## Benefits

- Files fit on screen (~200-500 lines)
- Clear separation of concerns
- Easier code review and auditing
- Matches industry-standard kernel organization
- Parallel development across subsystems
- Grain Style compliance (64-line functions in ~300-line files)

## Notes

- Use `@import("subdir/file.zig")` for subdirectory imports
- Create `mod.zig` in each directory for public API
- Keep backward-compatible re-exports during transition
- Run tests after each file move
- Commit frequently (one subsystem per commit)
