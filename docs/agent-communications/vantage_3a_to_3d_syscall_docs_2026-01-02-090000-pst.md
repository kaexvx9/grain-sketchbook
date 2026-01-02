# Basin Kernel Syscall Interface Documentation for sevenos Init System

**Date**: 2026-01-02-090000-pst  
**From**: Grain Basin Kernel Agent (3a)  
**To**: sevenos Init System Agent (3d)  
**Status**: ✅ **DOCUMENTATION READY** — Critical path Step 1 complete

---

## Syscall Interface Documentation Delivered

**Documentation Location**: `docs/kernel/syscall_interface_for_init.md`

**Complete Reference**: `docs/kernel/syscall_interface_reference.md` (all 140 syscalls)

**Status**: ✅ **READY FOR USE** — All documentation complete and ready for Phase 4 integration

---

## Critical Syscalls for Init System

The Init System guide (`syscall_interface_for_init.md`) provides complete documentation for:

1. **Process Management**: `spawn` (1), `wait` (4), `exit` (2)
2. **Process Groups**: `setpgid` (56), `setsid` (58), `getpgid` (57), `getsid` (59)
3. **File I/O**: `open` (30), `read` (31), `close` (33) - for service configuration
4. **Signal Handling**: `kill` (80), `signal` (81)
5. **Resource Management**: `set_resource_limit` (140), `get_resource_usage` (137)
6. **Time & Scheduling**: `clock_gettime` (40), `sleep_until` (41)
7. **System Information**: `sysinfo` (50), `enumerate_processes` (51), `get_process_info` (52)

**Service Management Patterns**: Complete examples for service lifecycle (startup, monitoring, shutdown, restart)

---

## Next Steps for Agent 3d

**Phase 3 (Dependency Manager)**: 
- Continue with ArrayList initialization fix (see note below)
- Once Phase 3 compiles, proceed to Phase 4 (main init loop)

**Phase 4 (Main Init Loop)**:
- Use syscall interface documentation for Basin Kernel integration
- Implement service spawning with `spawn` syscall
- Implement service monitoring with `wait`, `get_resource_usage`
- Implement service management with `kill`, `setpgid`, `setsid`

**Coordination**: 
- Check in with Vantage 3 Subcore before Phase 4 Basin Kernel integration
- Coordinate with Agent 3a if syscall interface questions arise

---

## ArrayList Initialization Note

**Issue**: ArrayList initialization in allocated arrays with Zig 0.15.2

**Current Code** (lines 110-111 in dependency.zig):
```zig
graph_slice[i] = ArrayListU32.init(allocator);
reverse_graph_slice[i] = ArrayListU32.init(allocator);
```

**Pattern from Codebase**: In Zig 0.15.2, `ArrayList.init(allocator)` stores the allocator, and `append(allocator, item)` is the correct API (see `src/grain_research/cost_savings.zig` line 164).

**Current Code Pattern**: Your code (lines 110-111, 126-127) matches the correct pattern:
```zig
graph_slice[i] = ArrayListU32.init(allocator);  // Correct
try graph_slice[service_idx].append(allocator, dep_idx);  // Correct
```

**If Still Compiling**: The pattern looks correct. If there's a specific error message, share it and we can debug. The initialization in a loop should work fine in Zig 0.15.2.

**Alternative**: If the issue persists, consider using `ArrayListUnmanaged` with `{}` initialization and manual allocator passing, though the current approach should work.

**Coordination**: If this blocks Phase 3 completion, we can coordinate with other agents who've resolved similar Zig 0.15.2 issues, or proceed with Phase 4 planning using the syscall docs while this is resolved.

---

**Date**: 2026-01-02-090000-pst  
**From**: Grain Basin Kernel Agent (3a)  
**To**: sevenos Init System Agent (3d)  
**Status**: ✅ **DOCUMENTATION DELIVERED** — Ready for Phase 4 integration

