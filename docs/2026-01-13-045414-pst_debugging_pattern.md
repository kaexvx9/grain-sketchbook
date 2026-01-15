# Kernel Debugging Pattern

**Date**: 2026-01-13 04:54:14 PST  
**Status**: ✅ **ACTIVE PATTERN** — Standard debugging approach for Grain OS kernel  
**Purpose**: Define consistent debugging patterns with CLI flag control  
**Context**: Grain OS Basin Kernel — RISC-V64 kernel debugging and development

---

## Overview

This document defines the standard debugging pattern for the Grain OS kernel. It establishes:
- **Debug output levels** and when to use each
- **CLI flag control** for debug verbosity
- **Best practices** for adding and removing debug output
- **Pattern consistency** across all kernel code

---

## Debug Output Levels

### 1. `Debug.kprint()` — Always-On Kernel Print
**When to use**: Essential kernel messages that should always appear
- Boot banner
- Critical error messages
- System status messages
- User-facing output (REPL prompts, help text)

**Example**:
```zig
Debug.kprint("Grain Basin Kernel v0.1.0 (RISC-V64)\n", .{});
Debug.kprint("System ready.\n", .{});
```

**Characteristics**:
- Always prints (no conditional)
- Use for production messages
- Minimal overhead
- No formatting overhead (simple string output)

---

### 2. `Debug.log()` — Structured Logging with Levels
**When to use**: Structured logging with severity levels
- Info messages: Normal operation status
- Warnings: Non-critical issues
- Errors: Critical problems
- Debug: Detailed debugging (controlled by verbose flag)

**Example**:
```zig
Debug.log(.info, "Initializing Basin...", .{});
Debug.log(.warn, "Memory pool 80% full", .{});
Debug.log(.error_lvl, "Kernel panic: {s}", .{reason});
Debug.log(.debug, "Timer interrupt at {d}ns", .{timestamp});
```

**Characteristics**:
- Level-based filtering (debug level requires verbose mode)
- Consistent prefix format: `[INFO]`, `[WARN]`, `[ERROR]`, `[DEBUG]`
- Use for production logging
- Debug level automatically filtered unless verbose enabled

---

### 3. `Debug.dprint()` — Always-On Debug Print
**When to use**: Critical debugging that must always appear
- Boot sequence debugging
- Critical path tracing
- Assertion failures
- Emergency debugging

**Example**:
```zig
Debug.dprint("About to call init_in_place...", .{});
Debug.dprint("Kernel address: 0x{x}", .{@intFromPtr(kernel)});
```

**Characteristics**:
- Always prints (no conditional)
- Use sparingly (only for critical debugging)
- Prefixed with `[DEBUG]`
- Should be removed after debugging is complete

**⚠️ Warning**: `dprint()` should be temporary. Remove after debugging is complete.

---

### 4. `Debug.vprint()` — Verbose Debug Print
**When to use**: Detailed debugging that should only appear in verbose mode
- Detailed initialization steps
- Function entry/exit tracing
- State dumps
- Performance metrics

**Example**:
```zig
Debug.vprint("Initializing timer...", .{});
Debug.vprint("Timer initialized in {d}ns", .{elapsed});
Debug.vprint("Process {d} state: {s}", .{pid, state_str});
```

**Characteristics**:
- Only prints if `Debug.is_verbose()` returns true
- Controlled by CLI flag (future: kernel parameter)
- Prefixed with `[VERBOSE]`
- Safe to leave in code (filtered by default)

**✅ Best Practice**: Use `vprint()` for detailed debugging that might be useful later.

---

### 5. `RawIO.write()` — Low-Level Raw Output
**When to use**: **Only for emergency debugging or boot-time tracing**
- Early boot debugging (before Debug system is ready)
- Stack overflow debugging
- Function call tracing during development
- **Should be removed after debugging is complete**

**Example**:
```zig
// ⚠️ TEMPORARY: Remove after debugging
const RawIO = @import("raw_io.zig");
RawIO.write("!!!INIT_IN_PLACE_START!!!\n");
```

**Characteristics**:
- No formatting support
- No conditional filtering
- Always prints
- **Must be removed after debugging**

**⚠️ Critical**: `RawIO.write()` should **never** remain in production code. It's for emergency debugging only.

---

## CLI Flag Control (Future Implementation)

### Planned Implementation

**Kernel Parameter Support**:
- `--verbose` or `-v`: Enable verbose debug output
- `--debug`: Enable all debug output (including `dprint()`)
- `--quiet` or `-q`: Suppress all non-critical output

**Current State**:
- Verbose mode controlled by `Debug.set_verbose(true/false)` in code
- Default: `false` (verbose disabled)
- Can be enabled at compile-time or runtime

**Future Enhancement**:
```zig
// Future: Parse kernel parameters from bootloader
pub fn parse_kernel_params(params: []const u8) void {
    if (std.mem.indexOf(u8, params, "verbose") != null) {
        Debug.set_verbose(true);
    }
    if (std.mem.indexOf(u8, params, "debug") != null) {
        Debug.set_debug(true); // Enable dprint()
    }
}
```

---

## Debugging Pattern Guidelines

### ✅ DO

1. **Use `Debug.log(.info, ...)` for normal operation messages**
   - Boot sequence status
   - System initialization
   - User-facing messages

2. **Use `Debug.vprint()` for detailed debugging**
   - Function entry/exit
   - State transitions
   - Performance metrics
   - Can safely remain in code

3. **Use `Debug.dprint()` sparingly for critical debugging**
   - Only during active debugging
   - Remove after debugging complete
   - Document why it's needed

4. **Use `RawIO.write()` only for emergency debugging**
   - Early boot (before Debug system ready)
   - Stack overflow debugging
   - **Always remove after debugging**

5. **Document debug output purpose**
   - Add comments explaining why debug output exists
   - Mark temporary debug output with `// ⚠️ TEMPORARY`

---

### ❌ DON'T

1. **Don't leave `RawIO.write()` in production code**
   - Always remove after debugging
   - Use `Debug.vprint()` instead for permanent debugging

2. **Don't use `Debug.dprint()` for normal logging**
   - Use `Debug.log(.info, ...)` instead
   - `dprint()` is for critical debugging only

3. **Don't add excessive debug output**
   - Use appropriate level for each message
   - Consider performance impact

4. **Don't hardcode verbose mode**
   - Use `Debug.set_verbose()` with runtime control
   - Allow users to control verbosity

---

## Debug Output Cleanup Pattern

### When to Clean Up

1. **After debugging session complete**
   - Remove all `RawIO.write()` statements
   - Remove temporary `Debug.dprint()` statements
   - Keep useful `Debug.vprint()` statements (they're filtered by default)

2. **Before code review**
   - Review all debug output
   - Remove unnecessary statements
   - Document why remaining debug output exists

3. **Before production release**
   - Audit all debug output
   - Ensure no `RawIO.write()` remains
   - Ensure no sensitive information in debug output

### Cleanup Checklist

- [ ] Remove all `RawIO.write()` statements
- [ ] Remove temporary `Debug.dprint()` statements
- [ ] Review `Debug.vprint()` statements (keep useful ones)
- [ ] Ensure `Debug.log()` messages are appropriate
- [ ] Verify no sensitive information in debug output
- [ ] Test with verbose mode enabled/disabled

---

## Example: Proper Debugging Pattern

### ✅ Good Example

```zig
pub fn init_in_place(target: *BasinKernel) void {
    // Use log() for normal operation status
    Debug.log(.info, "Initializing kernel subsystems...", .{});
    
    // Use vprint() for detailed debugging (filtered by default)
    Debug.vprint("Initializing timer...", .{});
    target.timer = Timer.init();
    Debug.vprint("Timer initialized", .{});
    
    // Use vprint() for state transitions
    Debug.vprint("Initializing interrupt controller...", .{});
    target.interrupt_controller = InterruptController.init();
    Debug.vprint("Interrupt controller initialized", .{});
    
    // Use log() for completion
    Debug.log(.info, "Kernel initialization complete", .{});
}
```

### ❌ Bad Example

```zig
pub fn init_in_place(target: *BasinKernel) void {
    // ❌ Don't use RawIO.write() for normal debugging
    const RawIO = @import("raw_io.zig");
    RawIO.write("INIT_START\n");
    RawIO.write("BEFORE_TIMER\n");
    
    // ❌ Don't use dprint() for normal logging
    Debug.dprint("Initializing timer...", .{});
    
    target.timer = Timer.init();
    
    RawIO.write("AFTER_TIMER\n");
    RawIO.write("INIT_DONE\n");
}
```

---

## Migration Pattern: Cleaning Up Existing Code

### Step 1: Identify Debug Output

```bash
# Find all RawIO.write() calls
grep -r "RawIO.write" src/kernel/

# Find all Debug.dprint() calls
grep -r "Debug.dprint" src/kernel/
```

### Step 2: Categorize

- **Emergency debugging** (`RawIO.write()`): Remove or convert to `vprint()`
- **Critical debugging** (`Debug.dprint()`): Remove or convert to `vprint()`
- **Normal logging**: Convert to `Debug.log(.info, ...)`
- **Detailed debugging**: Keep as `Debug.vprint()`

### Step 3: Convert

```zig
// Before (temporary debugging)
const RawIO = @import("raw_io.zig");
RawIO.write("BEFORE_INIT\n");

// After (proper logging)
Debug.vprint("Initializing subsystem...", .{});
```

### Step 4: Test

- Test with verbose mode disabled (should see minimal output)
- Test with verbose mode enabled (should see detailed output)
- Verify no `RawIO.write()` remains

---

## Summary

**Debug Output Hierarchy** (from most to least visible):

1. **`Debug.kprint()`** — Always visible, production messages
2. **`Debug.log(.info/warn/error)`** — Always visible, structured logging
3. **`Debug.dprint()`** — Always visible, temporary debugging (remove after use)
4. **`Debug.vprint()`** — Only in verbose mode, detailed debugging (safe to keep)
5. **`RawIO.write()`** — Always visible, emergency only (must remove)

**Key Principles**:
- Use appropriate level for each message
- `vprint()` is safe to keep (filtered by default)
- `RawIO.write()` and `dprint()` should be temporary
- Always document why debug output exists
- Clean up debug output before production

---

**Pattern established! Use this pattern for all kernel debugging.** 🚀
