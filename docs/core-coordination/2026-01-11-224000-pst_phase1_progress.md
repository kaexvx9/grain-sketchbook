# Phase 1 Progress: Kernel-Only Tests

**Date**: 2026-01-11-224000-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Track progress on Phase 1 (kernel-only tests)  
**Status**: 🔧 **IN PROGRESS** — Fixing API calls

---

## Issue Identified

Kernel tests use outdated API:
- ❌ `kernel.handle_syscall()` - wrong (it's a module-level function)
- ❌ `kernel.syscall_open()` - doesn't exist
- ✅ `basin_kernel.handle_syscall(&kernel, ...)` - correct

## Fixes Applied

1. ✅ Updated imports in `097_file_system_kernel_test.zig`
2. ✅ Fixed `syscall_open()` → `handle_syscall()` calls
3. ✅ Fixed `syscall_mkdir()` → `handle_syscall()` calls
4. 🔧 Fixing `023_ipc_channel_test.zig` - in progress

## Pattern

```zig
const basin_kernel_mod = @import("basin_kernel");
const result = basin_kernel_mod.handle_syscall(
    &kernel,
    @intFromEnum(Syscall.open),  // or syscall number
    arg1, arg2, arg3, arg4
) catch |err| {
    return err;
};
```

## Next Steps

1. Fix all remaining `kernel.handle_syscall()` calls
2. Run tests to verify
3. Move to Phase 2 (Grainscript tests)
