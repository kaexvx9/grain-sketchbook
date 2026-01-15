# Signal Handling for Init System: POSIX to Basin Kernel Transition

**Date**: 2026-01-03-060400-pst  
**Agent**: Grain Basin Kernel Agent (3a)  
**Target**: sevenos Init System Agent (3d)  
**Purpose**: Signal handling patterns for service management (stop, restart, kill)

---

## Current POSIX Pattern (Phase 5A)

Agent 3d is currently using POSIX signal handling in `supervision.zig`:

```zig
// Stop service (send SIGTERM)
try posix.kill(pid, posix.SIG.TERM);

// Wait for process to exit
_ = posix.waitpid(pid, 0);

// Force kill if needed
try posix.kill(pid, posix.SIG.KILL);
_ = posix.waitpid(pid, 0);

// Check if process is alive (signal 0)
posix.kill(pid, 0) catch return false;
```

---

## Basin Kernel Pattern (Phase 5B - Future)

When ready for Basin Kernel integration, use Basin Kernel syscalls:

### `kill` (80) - Send Signal to Process

**Purpose**: Send signal to service process

**Arguments**:
- `arg1: u64` - Process ID
- `arg2: u64` - Signal number (SIGTERM=15, SIGKILL=9, SIGINT=2, SIGHUP=1, etc.)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `process_not_found`, `permission_denied`

**Basin Kernel Pattern**:
```zig
// Stop service (send SIGTERM)
const SIGTERM: u64 = 15; // Signal number for SIGTERM
const result = kernel.handle_syscall(
    @intFromEnum(Syscall.kill),
    pid,
    SIGTERM,
    0,
    0,
);

switch (result) {
    .success => {},
    .err => |err| return handle_kill_error(err),
}

// Wait for service to exit gracefully
const wait_result = kernel.handle_syscall(
    @intFromEnum(Syscall.wait),
    pid,
    0,
    0,
    0,
);

// Force kill if still running
if (wait_result == .err) {
    const SIGKILL: u64 = 9; // Signal number for SIGKILL
    _ = kernel.handle_syscall(
        @intFromEnum(Syscall.kill),
        pid,
        SIGKILL,
        0,
        0,
    );
    _ = kernel.handle_syscall(
        @intFromEnum(Syscall.wait),
        pid,
        0,
        0,
        0,
    );
}
```

### `wait` (4) - Wait for Process Exit

**Purpose**: Wait for child process to exit

**Arguments**:
- `arg1: u64` - Process ID (0 = any child)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(exit_code: u64)` - Exit code on success

**Errors**: `process_not_found`, `interrupted`

**Basin Kernel Pattern**:
```zig
// Wait for service process to exit
const result = kernel.handle_syscall(
    @intFromEnum(Syscall.wait),
    pid,
    0,
    0,
    0,
);

const exit_code = switch (result) {
    .success => |value| value,
    .err => |err| {
        if (err == .process_not_found) {
            // Process already exited
            return 0;
        }
        return handle_wait_error(err);
    },
};
```

---

## Service Stop Pattern (Complete)

### POSIX Pattern (Current)
```zig
pub fn stop(self: *Service) !void {
    if (self.state == .stopped) {
        return;
    }
    
    self.state = .stopping;
    
    if (self.pid) |pid| {
        // Send SIGTERM for graceful shutdown
        try posix.kill(pid, posix.SIG.TERM);
        
        // Wait for process to exit
        _ = posix.waitpid(pid, 0);
        
        // Force kill if needed
        try posix.kill(pid, posix.SIG.KILL);
        _ = posix.waitpid(pid, 0);
        
        self.pid = null;
    }
    
    self.state = .stopped;
}
```

### Basin Kernel Pattern (Future)
```zig
pub fn stop(self: *Service, kernel: *BasinKernel) !void {
    if (self.state == .stopped) {
        return;
    }
    
    self.state = .stopping;
    
    if (self.pid) |pid| {
        const SIGTERM: u64 = 15;
        const SIGKILL: u64 = 9;
        
        // Send SIGTERM for graceful shutdown
        _ = kernel.handle_syscall(
            @intFromEnum(Syscall.kill),
            pid,
            SIGTERM,
            0,
            0,
        );
        
        // Wait for process to exit (with timeout check)
        const wait_result = kernel.handle_syscall(
            @intFromEnum(Syscall.wait),
            pid,
            0,
            0,
            0,
        );
        
        // Force kill if still running
        if (wait_result == .err) {
            _ = kernel.handle_syscall(
                @intFromEnum(Syscall.kill),
                pid,
                SIGKILL,
                0,
                0,
            );
            _ = kernel.handle_syscall(
                @intFromEnum(Syscall.wait),
                pid,
                0,
                0,
                0,
            );
        }
        
        self.pid = null;
    }
    
    self.state = .stopped;
}
```

---

## Process Alive Check Pattern

### POSIX Pattern (Current)
```zig
pub fn is_alive(self: *Service) bool {
    if (self.pid) |pid| {
        // Signal 0 doesn't actually kill, just checks if process exists
        posix.kill(pid, 0) catch return false;
        return true;
    }
    return false;
}
```

### Basin Kernel Pattern (Future)
```zig
pub fn is_alive(self: *Service, kernel: *BasinKernel) bool {
    if (self.pid) |pid| {
        // Use get_process_info to check if process exists
        const result = kernel.handle_syscall(
            @intFromEnum(Syscall.get_process_info),
            pid,
            info_ptr,
            info_size,
            0,
        );
        
        return result == .success;
    }
    return false;
}
```

---

## Signal Numbers Reference

**Common Signals**:
- `SIGHUP` (1) - Hangup (reload configuration)
- `SIGINT` (2) - Interrupt (Ctrl+C)
- `SIGTERM` (15) - Terminate (graceful shutdown)
- `SIGKILL` (9) - Kill (force termination, cannot be caught)
- `SIGUSR1` (10) - User-defined signal 1
- `SIGUSR2` (12) - User-defined signal 2

**Basin Kernel Signal Numbers**: Same as POSIX (standard signal numbers)

---

## Service Restart Pattern

### Complete Pattern (Basin Kernel)
```zig
pub fn restart(self: *Service, kernel: *BasinKernel, allocator: std.mem.Allocator) !void {
    // 1. Stop service
    self.stop(kernel) catch |err| {
        std.log.err("error stopping service {s}: {}", .{ self.config.name, err });
    };
    
    // 2. Wait for restart delay
    const current_time = get_current_time_ns(kernel);
    const restart_delay_ns = self.config.restart_delay;
    const target_time = current_time + restart_delay_ns;
    
    _ = kernel.handle_syscall(
        @intFromEnum(Syscall.sleep_until),
        target_time,
        0,
        0,
        0,
    );
    
    // 3. Start service again
    self.restart_count += 1;
    try self.start(kernel, allocator);
}
```

---

## Error Handling

### Kill Errors
- `invalid_argument` - Invalid signal number
- `process_not_found` - Process doesn't exist
- `permission_denied` - No permission to send signal

### Wait Errors
- `process_not_found` - Process doesn't exist (may have already exited)
- `interrupted` - Wait interrupted (can retry)

---

## Transition Strategy

**Phase 5A (Current)**: Use POSIX APIs
- `posix.kill()` for signals
- `posix.waitpid()` for waiting
- Works on Linux userspace immediately

**Phase 5B (Future)**: Use Basin Kernel syscalls
- `kill` (80) for signals
- `wait` (4) for waiting
- `get_process_info` (52) for process status
- Requires Basin Kernel integration

---

## Full Documentation

- **Complete Reference**: `docs/kernel/syscall_interface_reference.md` (kill, wait, signal syscalls)
- **Init System Guide**: `docs/kernel/syscall_interface_for_init.md` (signal handling section)
- **Quick Reference**: `docs/kernel/syscall_quick_reference_init_system.md` (signal syscalls)

---

**Date**: 2026-01-03-060400-pst  
**Agent**: Grain Basin Kernel Agent (3a)  
**Status**: Signal handling guide for Init System service management

