# Basin Kernel Architecture Plan

**Date**: 2026-01-18  
**Status**: Planning Phase  
**Goal**: Reorganize Basin kernel to follow Linux 6.x architectural patterns in Grain Style

## Current State (Updated 2026-01-18)

**MAJOR MILESTONE**: The Basin kernel now **boots fully and reaches the Grainscript REPL** in the Vantage VM!

Key accomplishments:

- RISC-V64 kernel loads at 0x80000000
- RVC (compressed instructions) fully supported
- Function calls work (JALR, C.JR, C.JALR)
- Branch instructions work (BEQ, BNE, BLTU, etc.)
- Stack management works (C.ADDI16SP, C.SDSP, C.LDSP)
- **UART MMIO implemented** - full console I/O working
- BSS reduced from 44.5MB to 6.3MB to fit in 8MB VM
- Serial input buffer ready for keyboard commands
- 249/249 tests pass

### Boot Success Evidence

The kernel outputs "G" - the first character of "Grainscript REPL v0.1.0"!

This confirms the kernel has:
1. Initialized TimeSource, Platform, and BasinKernel
2. Executed boot sequence validation
3. Reached and started the REPL
4. Begun printing the welcome message

### Console I/O Implementation

| Feature | Status | Notes |
|---------|--------|-------|
| Serial output (SB to UART) | Working | Characters captured |
| Serial input (LBU from UART) | Working | Input buffer implemented |
| LSR status register | Working | Bit 0=data ready, Bit 5=THR empty |
| SBI CONSOLE_PUTCHAR | Working | Via serial output |
| SBI CONSOLE_GETCHAR | Working | Via serial input |

Performance: ~500K instructions per output character (interpreted execution)

### BSS Reduction Summary

| Component | Before | After | Savings |
|-----------|--------|-------|---------|
| TCP sockets | 64 × 128KB | 8 × 8KB | ~8MB |
| UDP sockets | 64 × 128KB | 8 × 8KB | ~8MB |
| Channels | 64 × 128KB | 8 × 4KB | ~8MB |
| Audio | 16 × 128KB | 4 × 8KB | ~2MB |
| Storage | 64 × 64KB | 16 × 4KB | ~4MB |
| Mappings | 256 | 32 | variable |
| Handles | 64 | 16 | variable |
| Users | 256 | 8 | variable |
| **Total BSS** | **44.5MB** | **6.3MB** | **38MB** |

### Current Structure (Flat)

```
src/kernel/
├── basin_kernel.zig          # Main kernel (~73KB)
├── basin_kernel_core.zig     # Core functions (~68KB)
├── basin_kernel_types.zig    # Type definitions
├── basin_kernel_syscalls_*.zig  # Syscall handlers
├── scheduler.zig             # Process scheduler
├── memory.zig                # Memory management
├── network.zig               # Networking
├── tcp_socket.zig            # TCP implementation
├── audio.zig                 # Audio driver
├── framebuffer.zig           # Display driver
├── boot.zig                  # Boot sequence
├── trap.zig                  # Trap handling
├── platform_riscv.zig        # RISC-V platform
└── ... (60+ files mixed together)
```

## Target Structure (Linux-style)

Following Linux 6.x patterns, reimplemented in Zig with Grain Style:

```
src/kernel/
├── arch/
│   └── riscv64/
│       ├── boot.zig           # Architecture-specific boot
│       ├── entry.S            # Entry point assembly
│       ├── trap.zig           # Trap/interrupt handling
│       ├── platform.zig       # Platform abstraction
│       ├── interrupt.zig      # Interrupt controller
│       └── linker.ld          # Linker script
├── core/
│   ├── sched.zig              # Scheduler (like kernel/sched/)
│   ├── process.zig            # Process management
│   ├── signal.zig             # Signal handling
│   ├── syscall.zig            # Syscall dispatch
│   ├── timer.zig              # Timer subsystem
│   └── panic.zig              # Kernel panic
├── mm/
│   ├── page_alloc.zig         # Page allocator
│   ├── page_table.zig         # Page table management
│   ├── memory.zig             # Memory regions
│   └── cow.zig                # Copy-on-write
├── fs/
│   ├── vfs.zig                # Virtual filesystem
│   └── elf.zig                # ELF loader
├── net/
│   ├── socket.zig             # Socket abstraction
│   ├── tcp.zig                # TCP protocol
│   ├── udp.zig                # UDP protocol
│   └── channel.zig            # IPC channels
├── drivers/
│   ├── console.zig            # Console/UART
│   ├── framebuffer.zig        # Display
│   ├── keyboard.zig           # Input
│   ├── audio.zig              # Audio
│   └── storage.zig            # Block devices
├── init/
│   ├── main.zig               # Kernel main entry
│   └── version.zig            # Version info
└── include/
    └── types.zig              # Shared type definitions
```

## Implementation Strategy

### Phase 1: Architecture Isolation (Priority)

Move RISC-V specific code to `arch/riscv64/`:
- `boot.zig`, `entry.S`, `linker.ld`
- `trap.zig`, `interrupt.zig`
- `platform.zig`, `platform_riscv.zig`

**Benefit**: Enables future ARM64/x86 ports

### Phase 2: Core Subsystem

Move scheduler and process management to `core/`:
- `scheduler.zig`, `process.zig`, `signal.zig`
- `timer.zig`, `syscall_*.zig`

### Phase 3: Memory Management

Move to `mm/`:
- `memory.zig`, `page_table.zig`, `cow.zig`

### Phase 4: Drivers

Move device drivers to `drivers/`:
- `framebuffer.zig`, `keyboard.zig`, `audio.zig`

### Phase 5: Networking

Move to `net/`:
- `network.zig`, `tcp_socket.zig`, `udp_socket.zig`

## Technical Challenges

### Import Path Updates

Each file move requires updating imports in:
1. The moved file itself
2. All files that import it

Example: Moving `scheduler.zig` to `core/scheduler.zig` requires:
```zig
// Before: @import("scheduler.zig")
// After:  @import("core/scheduler.zig")
```

### Build System Updates

`build.zig` must be updated for:
- New source paths
- Module definitions
- Assembly file locations

### Grain Style Compliance

All reorganized code must maintain:
- 64-line function limit
- 128-character line limit
- Explicit u32/u64 types
- 2+ assertions per function
- "Why" comments

## Immediate Next Steps

1. **Continue VM development** - Get kernel past BSS limitation
2. **Document current architecture** - Map all imports/dependencies
3. **Incremental migration** - One subsystem at a time
4. **Test after each move** - Ensure 249/249 tests pass

## Linux 6.x Reference

Key directories in Linux kernel for reference:
- `arch/riscv/` - RISC-V architecture code
- `kernel/` - Core kernel (sched, fork, signal)
- `mm/` - Memory management
- `fs/` - Filesystems
- `drivers/` - Device drivers
- `net/` - Networking stack
- `include/` - Headers

## Notes

- Current kernel BSS needs ~44MB, VM has 8MB
- Kernel executes correctly until hitting unmapped data
- JALR alignment fix was critical for RVC support
- Re-export shims don't work in Zig 0.15

## Related Documents

- `docs/grain_style.md` - Coding standards
- `docs/core-coordination/` - Development history
- `archaeology/` - Historical context
