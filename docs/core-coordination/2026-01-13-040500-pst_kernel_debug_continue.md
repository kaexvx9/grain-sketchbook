# Kernel Debugging - Continuing Investigation

**Date**: 2026-01-13 04:05:00 PST  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Continue kernel boot debugging - fix `init_process_group_managers()` return issue  
**Status**: ⏳ **IN PROGRESS** — Investigating stack temporary in ProcessGroupStatsManager.init()

---

## Current Issue

Kernel crashes with `signal 15` immediately after `init_process_group_managers()` completes, before returning to `init_managers()`.

**Last known state**:
- ✅ Function executes through all steps
- ✅ Prints "PGM_FUNC_RETURNING" and "PGM_FUNC_ABOUT_TO_RETURN"
- ❌ Crashes before "JUST_RETURNED_FROM_PGM" is printed

---

## Root Cause Hypothesis

**Issue**: `ProcessGroupStatsManager.init()` creates a large struct on the stack:
- `stats: [64]ProcessGroupStats` - 64 entries
- Each `ProcessGroupStats` is ~32 bytes
- Total: ~2KB temporary struct created on stack
- When assigned: `target.process_group_stats = ProcessGroupStatsManager.init()`, creates stack temporary

**Solution**: Initialize `ProcessGroupStatsManager` in-place, similar to `ProcessGroupManager` and `ProcessGroupLimitsManager`.

---

## Changes Made

### Modified `init_process_group_managers()` in `src/kernel/basin_kernel_core.zig`

**Before**:
```zig
target.process_group_stats = ProcessGroupStatsManager.init();
```

**After**:
```zig
// Initialize ProcessGroupStatsManager in-place to avoid stack temporary
const ProcessGroupStats = @import("process_group_stats.zig").ProcessGroupStats;
i = 0; // Reuse existing i variable
while (i < 64) : (i += 1) {
    target.process_group_stats.stats[i] = ProcessGroupStats.init();
}
target.process_group_stats.initialized = true;
```

**Why**: Avoids creating a ~2KB temporary struct on the stack during return.

---

## Testing

**Next Steps**:
1. Build kernel: `zig build kernel-rv64`
2. Run in QEMU: `./run_qemu.sh`
3. Check output for:
   - "PGM_FUNC_RETURNING" ✅
   - "JUST_RETURNED_FROM_PGM" ⏳ (should appear now)
   - "MANAGERS_COMPLETE" ⏳

---

## Status

- ✅ Build successful
- ⏳ Testing in progress
- ⏳ Waiting for QEMU output

---

**Continuing kernel debugging!** 🚀
