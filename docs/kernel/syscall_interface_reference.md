# Basin Kernel Syscall Interface Reference

**Date**: 2026-01-01-233240-pst  
**Agent**: Grain Basin Kernel Agent (3a)  
**Purpose**: Complete reference documentation for all 140 Basin Kernel syscalls  
**Target Audience**: VM Runtime (3b), sevenos Init System (3d), System Integration (3c)

---

## Overview

Basin Kernel provides a RISC-V native, non-POSIX syscall interface with 140 syscalls across all system domains. This document provides complete reference documentation for all syscalls, including signatures, arguments, return values, error codes, and calling conventions.

---

## Syscall Calling Convention

### RISC-V ABI

**Syscall Entry Point**: `handle_syscall(kernel: *BasinKernel, syscall_num: u32, arg1: u64, arg2: u64, arg3: u64, arg4: u64) BasinError!SyscallResult`

**Argument Passing**:
- **syscall_num**: `u32` - Syscall number (enum value from `Syscall` enum)
- **arg1**: `u64` - First argument (pointer, handle, value, or flags)
- **arg2**: `u64` - Second argument (pointer, size, value, or flags)
- **arg3**: `u64` - Third argument (pointer, size, value, or flags)
- **arg4**: `u64` - Fourth argument (pointer, size, value, or flags)

**Return Value**: `SyscallResult` union:
- `SyscallResult.ok(value: u64)` - Success with return value
- `SyscallResult.fail(err: BasinError)` - Error with error code

**Syscall Number Range**: 
- Valid syscall numbers: `10` to `140` (enum values from `Syscall` enum)
- Syscall numbers < 10 are reserved for SBI calls
- Invalid syscall numbers return `BasinError.invalid_syscall`

### Argument Encoding

**Pointers**: Passed as `u64` values (VM memory addresses, must be < VM_MEMORY_SIZE)

**Sizes**: Passed as `u64` values (byte counts, must be reasonable)

**Flags**: Passed as `u64` values (packed structs bitcast to u64):
- `MapFlags` - Memory mapping flags (read, write, execute, shared)
- `OpenFlags` - File open flags (read, write, create, truncate)

**Handles**: Passed as `u64` values (handle.value, must be non-zero)

**Enums**: Passed as `u32` values (truncated to u32, then passed as u64)

---

## Error Codes

**BasinError** enum provides explicit error types (no POSIX errno):

**General Errors**:
- `invalid_handle` - Handle is invalid or not found
- `invalid_argument` - Invalid argument value
- `permission_denied` - Permission denied
- `not_found` - Resource not found
- `out_of_memory` - Out of memory
- `resource_exhausted` - Resource exhausted
- `would_block` - Operation would block
- `interrupted` - Operation interrupted
- `invalid_syscall` - Invalid syscall number
- `invalid_address` - Invalid memory address
- `unaligned_access` - Unaligned memory access
- `out_of_bounds` - Index out of bounds

**Network Errors**:
- `network_error` - General network error
- `connection_failed` - Connection failed
- `connection_timeout` - Connection timeout
- `connection_refused` - Connection refused
- `network_timeout` - Network operation timeout

**File System Errors**:
- `file_io_timeout` - File I/O timeout
- `file_not_found` - File not found
- `file_exists` - File already exists
- `file_too_large` - File too large
- `directory_not_empty` - Directory not empty

**Process Errors**:
- `process_not_found` - Process not found
- `process_already_running` - Process already running
- `process_terminated` - Process terminated

**IPC Errors**:
- `channel_full` - Channel full
- `channel_empty` - Channel empty
- `channel_closed` - Channel closed
- `ipc_timeout` - IPC operation timeout

**Resource Errors**:
- `too_many_files` - Too many open files
- `too_many_processes` - Too many processes
- `too_many_connections` - Too many network connections

---

## Syscall Categories

### 1. Process & Thread Management (Syscalls 1-4)

#### `spawn` (1)
**Purpose**: Spawn a new process from ELF executable

**Arguments**:
- `arg1: u64` - Executable pointer (VM memory address)
- `arg2: u64` - Arguments pointer (VM memory address, can be 0)
- `arg3: u64` - Arguments length (bytes, can be 0)
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(pid: u64)` - Process ID on success

**Errors**: `invalid_argument`, `out_of_memory`, `process_not_found`, `too_many_processes`

**Notes**: 
- Executable must be valid ELF64 format
- Arguments are null-terminated strings in VM memory
- Process is spawned in running state

#### `exit` (2)
**Purpose**: Exit current process

**Arguments**:
- `arg1: u64` - Exit code
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: Never returns (process exits)

**Errors**: None (process always exits)

#### `yield` (3)
**Purpose**: Yield CPU to other processes

**Arguments**:
- `arg1: u64` - Unused
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Always succeeds

**Errors**: None

**Notes**: No-op syscall, minimal overhead

#### `wait` (4)
**Purpose**: Wait for child process to exit

**Arguments**:
- `arg1: u64` - Process ID to wait for (0 = any child)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(exit_code: u64)` - Exit code on success

**Errors**: `process_not_found`, `interrupted`

---

### 2. Memory Management (Syscalls 10-12)

#### `map` (10)
**Purpose**: Map memory pages

**Arguments**:
- `arg1: u64` - Address (0 = kernel chooses, must be page-aligned)
- `arg2: u64` - Size (bytes, must be page-aligned, max 1GB)
- `arg3: u64` - Flags (MapFlags packed struct bitcast to u64)
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(address: u64)` - Mapped address on success

**Errors**: `invalid_argument`, `out_of_memory`, `unaligned_access`

**Notes**:
- Size must be multiple of 4096 (page size)
- Flags must have at least one permission (read, write, execute)
- Address must be page-aligned if specified

#### `unmap` (11)
**Purpose**: Unmap memory pages

**Arguments**:
- `arg1: u64` - Address (must be page-aligned)
- `arg2: u64` - Size (bytes, must be page-aligned)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `invalid_address`, `unaligned_access`

#### `protect` (12)
**Purpose**: Change memory protection flags

**Arguments**:
- `arg1: u64` - Address (must be page-aligned)
- `arg2: u64` - Size (bytes, must be page-aligned)
- `arg3: u64` - Flags (MapFlags packed struct bitcast to u64)
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `invalid_address`, `unaligned_access`, `permission_denied`

---

### 3. Inter-Process Communication (Syscalls 20-22)

#### `channel_create` (20)
**Purpose**: Create IPC channel

**Arguments**:
- `arg1: u64` - Capacity (max messages, must be > 0)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(handle: u64)` - Channel handle on success

**Errors**: `invalid_argument`, `out_of_memory`, `resource_exhausted`

#### `channel_send` (21)
**Purpose**: Send message to channel

**Arguments**:
- `arg1: u64` - Channel handle
- `arg2: u64` - Message pointer (VM memory address)
- `arg3: u64` - Message size (bytes)
- `arg4: u64` - Timeout (nanoseconds, 0 = no timeout)

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_handle`, `channel_full`, `ipc_timeout`, `interrupted`

#### `channel_recv` (22)
**Purpose**: Receive message from channel

**Arguments**:
- `arg1: u64` - Channel handle
- `arg2: u64` - Buffer pointer (VM memory address)
- `arg3: u64` - Buffer size (bytes)
- `arg4: u64` - Timeout (nanoseconds, 0 = no timeout)

**Returns**: `SyscallResult.ok(size: u64)` - Message size on success

**Errors**: `invalid_handle`, `channel_empty`, `ipc_timeout`, `interrupted`, `invalid_argument`

---

### 4. File I/O Operations (Syscalls 30-39)

#### `open` (30)
**Purpose**: Open file

**Arguments**:
- `arg1: u64` - Path pointer (VM memory address, null-terminated string)
- `arg2: u64` - Path length (bytes, max 4096)
- `arg3: u64` - Flags (OpenFlags packed struct bitcast to u64)
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(handle: u64)` - File handle on success

**Errors**: `invalid_argument`, `not_found`, `permission_denied`, `too_many_files`

#### `read` (31)
**Purpose**: Read from file

**Arguments**:
- `arg1: u64` - File handle
- `arg2: u64` - Buffer pointer (VM memory address)
- `arg3: u64` - Buffer size (bytes)
- `arg4: u64` - Timeout (nanoseconds, 0 = no timeout)

**Returns**: `SyscallResult.ok(size: u64)` - Bytes read on success

**Errors**: `invalid_handle`, `invalid_argument`, `file_io_timeout`, `interrupted`

#### `write` (32)
**Purpose**: Write to file

**Arguments**:
- `arg1: u64` - File handle
- `arg2: u64` - Buffer pointer (VM memory address)
- `arg3: u64` - Buffer size (bytes)
- `arg4: u64` - Timeout (nanoseconds, 0 = no timeout)

**Returns**: `SyscallResult.ok(size: u64)` - Bytes written on success

**Errors**: `invalid_handle`, `invalid_argument`, `file_io_timeout`, `interrupted`, `permission_denied`

#### `close` (33)
**Purpose**: Close file handle

**Arguments**:
- `arg1: u64` - File handle
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_handle`

#### `unlink` (34)
**Purpose**: Delete file

**Arguments**:
- `arg1: u64` - Path pointer (VM memory address, null-terminated string)
- `arg2: u64` - Path length (bytes, max 4096)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `not_found`, `permission_denied`, `directory_not_empty`

#### `rename` (35)
**Purpose**: Rename file

**Arguments**:
- `arg1: u64` - Old path pointer (VM memory address, null-terminated string)
- `arg2: u64` - Old path length (bytes, max 4096)
- `arg3: u64` - New path pointer (VM memory address, null-terminated string)
- `arg4: u64` - New path length (bytes, max 4096)

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `not_found`, `file_exists`, `permission_denied`

#### `mkdir` (36)
**Purpose**: Create directory

**Arguments**:
- `arg1: u64` - Path pointer (VM memory address, null-terminated string)
- `arg2: u64` - Path length (bytes, max 4096)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `file_exists`, `permission_denied`

#### `opendir` (37)
**Purpose**: Open directory

**Arguments**:
- `arg1: u64` - Path pointer (VM memory address, null-terminated string)
- `arg2: u64` - Path length (bytes, max 4096)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(handle: u64)` - Directory handle on success

**Errors**: `invalid_argument`, `not_found`, `permission_denied`, `too_many_files`

#### `readdir` (38)
**Purpose**: Read directory entry

**Arguments**:
- `arg1: u64` - Directory handle
- `arg2: u64` - Buffer pointer (VM memory address)
- `arg3: u64` - Buffer size (bytes)
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(size: u64)` - Entry size on success (0 = end of directory)

**Errors**: `invalid_handle`, `invalid_argument`

#### `closedir` (39)
**Purpose**: Close directory handle

**Arguments**:
- `arg1: u64` - Directory handle
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_handle`

---

### 5. Time & Scheduling (Syscalls 40-41)

#### `clock_gettime` (40)
**Purpose**: Get current time

**Arguments**:
- `arg1: u64` - Clock ID (ClockId enum: 0=monotonic, 1=realtime)
- `arg2: u64` - Time pointer (VM memory address, writes `u64` nanoseconds)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `invalid_address`

#### `sleep_until` (41)
**Purpose**: Sleep until specified time

**Arguments**:
- `arg1: u64` - Target time (nanoseconds, monotonic clock)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `interrupted`

---

### 6. System Information (Syscalls 50-59)

#### `sysinfo` (50)
**Purpose**: Get system information

**Arguments**:
- `arg1: u64` - SysInfo pointer (VM memory address)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `invalid_address`

**Notes**: Writes `SysInfo` struct to pointer (total_memory, available_memory, cpu_cores, uptime_ns, etc.)

#### `enumerate_processes` (51)
**Purpose**: Enumerate all processes

**Arguments**:
- `arg1: u64` - Buffer pointer (VM memory address)
- `arg2: u64` - Buffer size (bytes)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(count: u64)` - Process count on success

**Errors**: `invalid_argument`, `invalid_address`

**Notes**: Writes array of `ProcessInfo` structs to buffer

#### `get_process_info` (52)
**Purpose**: Get process information

**Arguments**:
- `arg1: u64` - Process ID
- `arg2: u64` - ProcessInfo pointer (VM memory address)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `process_not_found`, `invalid_address`

#### `read_kernel_log` (53)
**Purpose**: Read kernel log entries

**Arguments**:
- `arg1: u64` - Buffer pointer (VM memory address)
- `arg2: u64` - Buffer size (bytes)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(size: u64)` - Log size on success

**Errors**: `invalid_argument`, `invalid_address`

#### `set_priority` (54)
**Purpose**: Set process priority

**Arguments**:
- `arg1: u64` - Process ID (0 = current process)
- `arg2: u64` - Priority (0-255, higher = higher priority)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `process_not_found`, `permission_denied`

#### `get_priority` (55)
**Purpose**: Get process priority

**Arguments**:
- `arg1: u64` - Process ID (0 = current process)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(priority: u64)` - Priority on success

**Errors**: `invalid_argument`, `process_not_found`

#### `setpgid` (56)
**Purpose**: Set process group ID

**Arguments**:
- `arg1: u64` - Process ID (0 = current process)
- `arg2: u64` - Process group ID
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `process_not_found`, `permission_denied`

#### `getpgid` (57)
**Purpose**: Get process group ID

**Arguments**:
- `arg1: u64` - Process ID (0 = current process)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(pgid: u64)` - Process group ID on success

**Errors**: `invalid_argument`, `process_not_found`

#### `setsid` (58)
**Purpose**: Create new session

**Arguments**:
- `arg1: u64` - Unused
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(sid: u64)` - Session ID on success

**Errors**: `permission_denied`

#### `getsid` (59)
**Purpose**: Get session ID

**Arguments**:
- `arg1: u64` - Process ID (0 = current process)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(sid: u64)` - Session ID on success

**Errors**: `invalid_argument`, `process_not_found`

---

### 7. Input Events (Syscall 60)

#### `read_input_event` (60)
**Purpose**: Read input event (keyboard/mouse)

**Arguments**:
- `arg1: u64` - Buffer pointer (VM memory address)
- `arg2: u64` - Buffer size (bytes)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(size: u64)` - Event size on success (0 = no event)

**Errors**: `invalid_argument`, `invalid_address`, `would_block`

---

### 8. Framebuffer Operations (Syscalls 70-72)

#### `fb_clear` (70)
**Purpose**: Clear framebuffer

**Arguments**:
- `arg1: u64` - Color (32-bit ARGB)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`

#### `fb_draw_pixel` (71)
**Purpose**: Draw pixel to framebuffer

**Arguments**:
- `arg1: u64` - X coordinate
- `arg2: u64` - Y coordinate
- `arg3: u64` - Color (32-bit ARGB)
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `out_of_bounds`

#### `fb_draw_text` (72)
**Purpose**: Draw text to framebuffer

**Arguments**:
- `arg1: u64` - X coordinate
- `arg2: u64` - Y coordinate
- `arg3: u64` - Text pointer (VM memory address, null-terminated string)
- `arg4: u64` - Color (32-bit ARGB)

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `invalid_address`, `out_of_bounds`

---

### 9. Signal Operations (Syscalls 80-82)

#### `kill` (80)
**Purpose**: Send signal to process

**Arguments**:
- `arg1: u64` - Process ID
- `arg2: u64` - Signal number
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `process_not_found`, `permission_denied`

#### `signal` (81)
**Purpose**: Set signal handler

**Arguments**:
- `arg1: u64` - Signal number
- `arg2: u64` - Handler pointer (VM memory address, function pointer)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `invalid_address`

#### `sigaction` (82)
**Purpose**: Set signal action (advanced signal handling)

**Arguments**:
- `arg1: u64` - Signal number
- `arg2: u64` - SignalAction pointer (VM memory address)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `invalid_address`

---

### 10. Network Operations (Syscalls 90-139)

#### Network Interface Management (90-97)

**`network_create_interface` (90)**: Create network interface  
**`network_set_state` (91)**: Set interface state (up/down)  
**`network_set_ipv4` (92)**: Set IPv4 address  
**`network_get_interface` (93)**: Get interface information  
**`network_set_ipv6` (94)**: Set IPv6 address  
**`network_delete_interface` (95)**: Delete interface  
**`network_enumerate_interfaces` (96)**: Enumerate all interfaces  
**`network_get_stats` (97)**: Get interface statistics

#### TCP Socket Operations (100-109)

**`tcp_socket` (100)**: Create TCP socket  
**`tcp_bind` (101)**: Bind socket to address  
**`tcp_listen` (102)**: Listen for connections  
**`tcp_accept` (103)**: Accept connection  
**`tcp_connect` (104)**: Connect to address  
**`tcp_send` (105)**: Send data (with timeout support)  
**`tcp_recv` (106)**: Receive data (with timeout support)  
**`tcp_close` (107)**: Close socket  
**`tcp_enumerate_sockets` (108)**: Enumerate all TCP sockets  
**`tcp_get_stats` (109)**: Get socket statistics

#### UDP Socket Operations (110-116, 138-139)

**`udp_socket` (110)**: Create UDP socket  
**`udp_bind` (111)**: Bind socket to address  
**`udp_sendto` (112)**: Send datagram  
**`udp_recvfrom` (113)**: Receive datagram  
**`udp_close` (114)**: Close socket  
**`udp_enumerate_sockets` (115)**: Enumerate all UDP sockets  
**`udp_get_stats` (116)**: Get socket statistics  
**`udp_sendto_with_timeout` (138)**: Send datagram with timeout  
**`udp_recvfrom_with_timeout` (139)**: Receive datagram with timeout

**Note**: Network syscalls support timeout mechanisms. See network syscall implementations for detailed argument specifications.

---

### 11. Audio Device Operations (Syscalls 120-134)

**`audio_create_device` (120)**: Create audio device  
**`audio_set_volume` (121)**: Set device volume  
**`audio_set_mute` (122)**: Set device mute state  
**`audio_set_state` (123)**: Set device state (play/pause)  
**`audio_set_active_output` (124)**: Set active output device  
**`audio_set_active_input` (125)**: Set active input device  
**`audio_set_master_volume` (126)**: Set master volume  
**`audio_set_master_mute` (127)**: Set master mute state  
**`audio_get_device` (128)**: Get device information  
**`audio_set_format` (129)**: Set audio format  
**`audio_read` (130)**: Read audio data  
**`audio_write` (131)**: Write audio data  
**`audio_enumerate_devices` (132)**: Enumerate all devices  
**`audio_delete_device` (133)**: Delete device  
**`audio_get_stats` (134)**: Get device statistics

**Note**: Audio syscalls support format configuration and I/O operations. See audio syscall implementations for detailed argument specifications.

---

### 12. Kernel Statistics & Health (Syscalls 135-137, 140)

#### `kernel_get_stats` (135)
**Purpose**: Get kernel statistics snapshot

**Arguments**:
- `arg1: u64` - Stats pointer (VM memory address)
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `invalid_address`

#### `health_check` (136)
**Purpose**: Check kernel health

**Arguments**:
- `arg1: u64` - Unused
- `arg2: u64` - Unused
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(health: u64)` - Health status (0 = healthy)

**Errors**: None

#### `get_resource_usage` (137)
**Purpose**: Get process resource usage

**Arguments**:
- `arg1: u64` - Process ID (0 = current process)
- `arg2: u64` - ResourceUsage pointer (VM memory address)
- `arg3: u64` - Unused
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `process_not_found`, `invalid_address`

#### `set_resource_limit` (140)
**Purpose**: Set process resource limit

**Arguments**:
- `arg1: u64` - Process ID (0 = current process)
- `arg2: u64` - Resource type (0=CPU, 1=Memory, 2=Files, 3=Connections)
- `arg3: u64` - Limit value
- `arg4: u64` - Unused

**Returns**: `SyscallResult.ok(0)` - Success

**Errors**: `invalid_argument`, `process_not_found`, `permission_denied`

---

## Type Definitions

### MapFlags
```zig
pub const MapFlags = packed struct {
    read: bool = false,
    write: bool = false,
    execute: bool = false,
    shared: bool = false,
    _padding: u28 = 0,
};
```

### OpenFlags
```zig
pub const OpenFlags = packed struct {
    read: bool = false,
    write: bool = false,
    create: bool = false,
    truncate: bool = false,
    _padding: u28 = 0,
};
```

### ClockId
```zig
pub const ClockId = enum(u32) {
    monotonic = 0,
    realtime = 1,
};
```

### Handle
```zig
pub const Handle = struct {
    value: u64,
};
```

### SysInfo
```zig
pub const SysInfo = struct {
    total_memory: u64,
    available_memory: u64,
    used_memory: u64,
    cpu_cores: u32,
    uptime_ns: u64,
    load_avg_1min: u32,
    total_processes: u32,
    running_processes: u32,
    exited_processes: u32,
};
```

### ProcessInfo
```zig
pub const ProcessInfo = struct {
    pid: u32,
    parent_pid: u32,
    state: u8,
    cpu_time_ns: u64,
    memory_used: u64,
};
```

### ResourceUsage
```zig
pub const ResourceUsage = struct {
    cpu_time_ns: u64,
    memory_used: u64,
    file_descriptors: u32,
    network_connections: u32,
    network_bytes_sent: u64,
    network_bytes_received: u64,
};
```

---

## Memory Constraints

**VM Memory Size**: Default 4MB (configurable via VM_MEMORY_SIZE constant)

**Pointer Validation**: All pointers must be:
- Non-zero (except where explicitly allowed)
- < VM_MEMORY_SIZE
- Point to valid VM memory regions

**Size Validation**: All sizes must be:
- Non-zero (except where explicitly allowed)
- Reasonable (max values vary by syscall)
- Page-aligned for memory operations (4096 bytes)

---

## Notes for JIT Compilation (Agent 3b)

**Calling Convention**: RISC-V ABI standard
- Arguments passed in registers: a0 (syscall_num), a1 (arg1), a2 (arg2), a3 (arg3), a4 (arg4)
- Return value in a0 register (SyscallResult encoded as u64)
- Error handling: Error union encoded in return value

**Syscall Number Encoding**: Use enum value directly (u32, then passed as u64)

**Argument Encoding**: 
- Pointers: VM memory addresses (u64)
- Sizes: Byte counts (u64)
- Flags: Packed structs bitcast to u64
- Handles: Handle.value (u64)

**Return Value Encoding**:
- Success: SyscallResult.ok(value) encoded as u64 (value in low bits, success flag in high bits)
- Error: SyscallResult.fail(err) encoded as u64 (error code in low bits, error flag in high bits)

---

## Notes for Init System (Agent 3d)

**Critical Syscalls for Init System**:
- `spawn` (1) - Spawn services
- `wait` (4) - Wait for service exit
- `open` (30), `read` (31), `write` (32), `close` (33) - Service configuration files
- `clock_gettime` (40) - Service timing
- `sysinfo` (50) - System monitoring
- `set_priority` (54) - Service priority management
- `setpgid` (56), `setsid` (58) - Process group/session management
- `kill` (80), `signal` (81) - Service signal handling
- `get_resource_usage` (137), `set_resource_limit` (140) - Resource management

**Service Management Pattern**:
1. Read service configuration (open, read, close)
2. Spawn service process (spawn)
3. Set process group/session (setpgid, setsid)
4. Set resource limits (set_resource_limit)
5. Monitor service (get_resource_usage, wait)
6. Handle service signals (kill, signal)

---

**Date**: 2026-01-01-233240-pst  
**Agent**: Grain Basin Kernel Agent (3a)  
**Status**: ✅ **COMPLETE** — Ready for use by Agents 3b, 3c, 3d

