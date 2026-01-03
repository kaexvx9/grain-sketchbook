# Basin Kernel Syscall Quick Reference: Init System

**Date**: 2026-01-03-055800-pst  
**Agent**: Grain Basin Kernel Agent (3a)  
**Target**: sevenos Init System Agent (3d)  
**Purpose**: Quick reference for common Init System syscall patterns

---

## Most Common Syscalls for Init System

### Process Management

**`spawn` (1)** - Spawn service process
```zig
kernel.handle_syscall(Syscall.spawn, executable_ptr, args_ptr, args_len, 0)
// Returns: SyscallResult.ok(pid: u64)
```

**`wait` (4)** - Wait for service exit
```zig
kernel.handle_syscall(Syscall.wait, pid, 0, 0, 0)
// Returns: SyscallResult.ok(exit_code: u64)
```

**`exit` (2)** - Exit process
```zig
kernel.handle_syscall(Syscall.exit, exit_code, 0, 0, 0)
// Never returns
```

### Process Groups

**`setpgid` (56)** - Set process group
```zig
kernel.handle_syscall(Syscall.setpgid, pid, pgid, 0, 0)
// Returns: SyscallResult.ok(0)
```

**`setsid` (58)** - Create new session
```zig
kernel.handle_syscall(Syscall.setsid, 0, 0, 0, 0)
// Returns: SyscallResult.ok(sid: u64)
```

### Signal Handling

**`kill` (80)** - Send signal to process
```zig
kernel.handle_syscall(Syscall.kill, pid, signal_num, 0, 0)
// Returns: SyscallResult.ok(0)
```

**`signal` (81)** - Set signal handler
```zig
kernel.handle_syscall(Syscall.signal, signal_num, handler_ptr, 0, 0)
// Returns: SyscallResult.ok(0)
```

### Resource Management

**`set_resource_limit` (140)** - Set resource limit
```zig
kernel.handle_syscall(Syscall.set_resource_limit, resource_type, limit_value, 0, 0)
// Returns: SyscallResult.ok(0)
```

**`get_resource_usage` (137)** - Get resource usage
```zig
kernel.handle_syscall(Syscall.get_resource_usage, pid, usage_ptr, usage_size, 0)
// Returns: SyscallResult.ok(0)
```

### File I/O

**`open` (30)** - Open file
```zig
kernel.handle_syscall(Syscall.open, path_ptr, path_len, flags, 0)
// Returns: SyscallResult.ok(handle: u64)
```

**`read` (31)** - Read file
```zig
kernel.handle_syscall(Syscall.read, handle, buffer_ptr, buffer_size, 0)
// Returns: SyscallResult.ok(bytes_read: u64)
```

**`close` (33)** - Close file
```zig
kernel.handle_syscall(Syscall.close, handle, 0, 0, 0)
// Returns: SyscallResult.ok(0)
```

### Time & Scheduling

**`clock_gettime` (40)** - Get current time
```zig
kernel.handle_syscall(Syscall.clock_gettime, clock_id, time_ptr, time_size, 0)
// Returns: SyscallResult.ok(0)
```

**`sleep_until` (41)** - Sleep until time
```zig
kernel.handle_syscall(Syscall.sleep_until, target_time_ns, 0, 0, 0)
// Returns: SyscallResult.ok(0)
```

---

## Common Error Codes

- `invalid_argument` - Invalid argument
- `out_of_memory` - Out of memory
- `process_not_found` - Process not found
- `too_many_processes` - Process limit exceeded
- `permission_denied` - Permission denied
- `resource_exhausted` - Resource limit exceeded
- `interrupted` - Operation interrupted
- `not_found` - File/resource not found
- `too_many_files` - File handle limit exceeded

---

## Service Lifecycle Pattern (Quick)

```zig
// 1. Spawn
const pid = spawn_service(executable_ptr, args_ptr, args_len);

// 2. Set process group (optional)
setpgid(pid, pgid);

// 3. Set resource limits (optional)
set_resource_limit(pid, memory_limit);

// 4. Monitor (in supervision loop)
const exit_code = wait(pid);

// 5. Restart if needed
if (should_restart(exit_code)) {
    restart_service();
}
```

---

## Full Documentation

- **Complete Reference**: `docs/kernel/syscall_interface_reference.md` (140 syscalls)
- **Init System Guide**: `docs/kernel/syscall_interface_for_init.md` (detailed patterns)
- **Phase 5 Guidance**: `docs/agent-communications/2026-01-03-055500-pst_vantage_3a_to_3d_phase5_syscall_guidance.md`

---

**Date**: 2026-01-03-055800-pst  
**Agent**: Grain Basin Kernel Agent (3a)  
**Status**: Quick reference for Init System development

