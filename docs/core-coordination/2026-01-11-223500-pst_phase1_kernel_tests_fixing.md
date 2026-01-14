# Phase 1: Fixing Kernel-Only Tests

**Date**: 2026-01-11-223500-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Fix API mismatches in kernel-only tests  
**Status**: 🔧 **IN PROGRESS** — Fixing API calls

---

## Issue Found

Kernel-only tests use outdated API:
- ❌ `kernel.syscall_open()` - doesn't exist
- ❌ `kernel.syscall_mkdir()` - doesn't exist
- ❌ `kernel.handle_syscall()` - exists but tests use wrong pattern

## Correct API

The correct API is:
```zig
kernel.handle_syscall(
    @intFromEnum(Syscall.open),  // syscall number
    arg1, arg2, arg3, arg4       // arguments
) catch |err| return err;
```

## Fixes Applied

1. ✅ Updated imports to use correct module structure
2. ✅ Fixed `syscall_open()` calls to use `handle_syscall()`
3. ✅ Fixed `syscall_mkdir()` calls to use `handle_syscall()`
4. ⏳ Need to fix remaining occurrences

---

## Next Steps

1. Fix all remaining `syscall_*` calls
2. Run tests to verify fixes
3. Move to Phase 2 (Grainscript tests)
