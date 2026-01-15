# QEMU Terminal and Grainscript REPL Plan

**Date**: 2026-01-12 22:26:25 PST  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Plan for adding Grainscript REPL to QEMU boot sequence  
**Status**: 📋 **PLAN** — Design for REPL integration

---

## Summary

**QEMU terminal-only is intentional!** Planning to add Grainscript REPL to boot sequence for interactive use.

---

## QEMU Terminal Output

### ✅ Intentional Design

- **`-nographic` flag**: QEMU runs in terminal, no GUI window
- **Serial output**: All kernel output goes to terminal via UART
- **This is correct**: Terminal-only is the intended design for headless operation

**Why Terminal-Only?**
- Works over SSH (no X11 needed)
- Standard for embedded/OS development
- Easy logging (all output in one place)
- Can run on servers without display

---

## Current Boot Sequence

1. **Kernel boots**: Shows banner, initializes subsystems
2. **Enters trap loop**: Infinite loop processing interrupts
3. **No user interface**: Just waits for interrupts/syscalls

**Problem**: No way to interact with the system!

---

## Solution: Add Grainscript REPL

### What We Need

1. **Simple init process**: Spawns after kernel boot
2. **Grainscript REPL**: Interactive shell for running commands
3. **Basic commands**: File operations, process management, etc.

### Implementation Options

#### Option 1: Embedded REPL in Kernel (Quick)
- Add simple REPL directly in kernel
- Read from UART, parse commands, execute
- Pros: Fast to implement, no process spawning needed
- Cons: Not ideal architecture (REPL should be userspace)

#### Option 2: Spawn Grainscript Shell Process (Proper)
- Create minimal init that spawns Grainscript shell
- Shell runs as userspace process
- Pros: Proper architecture, matches real OS
- Cons: Requires ELF executable for shell, process spawning

#### Option 3: Simple Command Handler (Minimal)
- Add basic command handler in kernel
- Handle simple commands (sysinfo, echo, etc.)
- Pros: Very simple, works immediately
- Cons: Limited functionality

---

## Recommended Approach: Option 1 (Quick Start)

For now, add a simple embedded REPL in the kernel that:
1. Reads commands from UART
2. Parses basic Grainscript commands
3. Executes via kernel syscalls
4. Prints results to UART

**Later**: Migrate to proper userspace shell when process spawning is ready.

---

## Basic Commands to Support

### System Info
- `sysinfo` - System information
- `ps` - List processes
- `uptime` - System uptime

### File Operations (when storage is ready)
- `ls` - List directory
- `cat` - Read file
- `echo` - Print text

### Grainscript Execution
- `eval <code>` - Execute Grainscript code
- `run <script>` - Run Grainscript file

---

## Implementation Plan

### Phase 1: Simple REPL (Now)
1. Add REPL loop in `main.zig` after boot
2. Read from UART (serial input)
3. Parse simple commands
4. Execute via kernel functions
5. Print results

### Phase 2: Grainscript Integration (Later)
1. Integrate Grainscript interpreter
2. Support full Grainscript syntax
3. Execute Grainscript code interactively

### Phase 3: Userspace Shell (Future)
1. Create ELF executable for Grainscript shell
2. Spawn as process via `syscall_spawn`
3. Full userspace shell experience

---

## Files to Modify

- `src/kernel/main.zig` - Add REPL loop after boot
- `src/kernel/repl.zig` - Simple REPL implementation (new file)
- `src/kernel/raw_io.zig` - Add read functions for UART input

---

## Example Usage

```
Grain Basin Kernel v0.1.0 (RISC-V64)
Copyright (c) 2026 Team Carry

[kernel] Initializing Basin...
[kernel] Boot sequence complete
[kernel] System ready. Starting REPL...

grainscript> sysinfo
System: Grain OS v0.1.0
Processes: 1
Memory: 512MB

grainscript> echo "Hello, Grain OS!"
Hello, Grain OS!

grainscript> exit
```

---

## Next Steps

1. ✅ **Terminal confirmed**: Intentional design
2. 🔧 **Add simple REPL**: Read from UART, parse commands
3. ⏳ **Basic commands**: sysinfo, echo, etc.
4. ⏳ **Grainscript integration**: Full interpreter support

---

**Ready to implement simple REPL!** 🚀
