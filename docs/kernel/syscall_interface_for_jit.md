# Basin Kernel Syscall Interface for JIT Compilation

**Date**: 2026-01-01-233240-pst  
**Agent**: Grain Basin Kernel Agent (3a)  
**Target**: VM Runtime Agent (3b) - x86_64 JIT Compilation  
**Purpose**: JIT-specific syscall interface documentation for RISC-V → x86_64 JIT compilation

---

## Overview

This document provides JIT-specific syscall interface documentation for implementing RISC-V → x86_64 JIT compilation in the VM Runtime. It focuses on syscall invocation from JIT-compiled code, register conventions, return value handling, and x86_64-specific considerations.

---

## Syscall Invocation from JIT-Compiled Code

### RISC-V ECALL Instruction

**ECALL Instruction**: System call instruction in RISC-V
- **Opcode**: `0b1110011` (ECALL)
- **Function**: Invokes kernel syscall or SBI call
- **Register Convention**: 
  - `a7` (x17) - Syscall number
  - `a0` (x10) - First argument (arg1)
  - `a1` (x11) - Second argument (arg2)
  - `a2` (x12) - Third argument (arg3)
  - `a3` (x13) - Fourth argument (arg4)
  - `a0` (x10) - Return value (on return)

### JIT Translation Strategy

**Current Implementation** (ARM64):
- ECALL instructions are not JIT-compiled (fall back to interpreter)
- Interpreter handles ECALL and calls kernel `handle_syscall()`

**x86_64 JIT Implementation** (Required):
- Option 1: **ECALL not JIT-compiled** (fall back to interpreter) - **RECOMMENDED**
  - Simpler implementation
  - Interpreter handles syscall invocation
  - No syscall-specific JIT code needed
- Option 2: **ECALL JIT-compiled** (direct syscall invocation)
  - More complex implementation
  - Requires syscall stub generation
  - Requires register mapping (RISC-V → x86_64)
  - Requires return value handling

**Recommendation**: Use Option 1 (ECALL not JIT-compiled) for initial x86_64 JIT implementation. This matches current ARM64 JIT behavior and simplifies implementation.

---

## Syscall Argument Passing (RISC-V ABI)

### Register Mapping (RISC-V → Kernel)

**RISC-V Registers**:
- `a0` (x10) → `arg1: u64`
- `a1` (x11) → `arg2: u64`
- `a2` (x12) → `arg3: u64`
- `a3` (x13) → `arg4: u64`
- `a7` (x17) → `syscall_num: u32`

**Kernel Function Signature**:
```zig
pub fn handle_syscall(
    self: *BasinKernel,
    syscall_num: u32,
    arg1: u64,
    arg2: u64,
    arg3: u64,
    arg4: u64,
) BasinError!SyscallResult
```

### Argument Encoding

**Pointers**: VM memory addresses (u64)
- Must be < VM_MEMORY_SIZE (default 4MB)
- Must be non-zero (except where explicitly allowed)

**Sizes**: Byte counts (u64)
- Must be reasonable (max values vary by syscall)
- Must be page-aligned for memory operations (4096 bytes)

**Flags**: Packed structs bitcast to u64
- `MapFlags` - Memory mapping flags
- `OpenFlags` - File open flags

**Handles**: Handle.value (u64)
- Must be non-zero
- Validated by kernel

**Enums**: Enum values (u32, passed as u64)
- `ClockId` - Clock type
- `Syscall` - Syscall number

---

## Return Value Handling

### SyscallResult Encoding

**Success Case**:
```zig
SyscallResult.ok(value: u64)
```
- Encoded as: `value` in low 64 bits, success flag in high bits
- Returned in `a0` register (x10)

**Error Case**:
```zig
SyscallResult.fail(err: BasinError)
```
- Encoded as: Error code in low bits, error flag in high bits
- Returned in `a0` register (x10)

### Return Value Decoding (JIT Code)

**From JIT-compiled code** (if ECALL is JIT-compiled):
1. Call kernel `handle_syscall()` function
2. Receive `SyscallResult` union
3. Decode result:
   - Check success/error flag
   - Extract value or error code
4. Write result to `a0` register (x10)

**From Interpreter** (current implementation, recommended):
1. Interpreter handles ECALL instruction
2. Interpreter calls kernel `handle_syscall()`
3. Interpreter receives `SyscallResult` union
4. Interpreter decodes result and updates VM registers
5. JIT code continues execution with updated registers

---

## Error Handling

### BasinError Types

**Error Encoding**: Error code in low bits, error flag in high bits

**Common Errors for JIT**:
- `invalid_syscall` - Invalid syscall number
- `invalid_argument` - Invalid argument value
- `invalid_address` - Invalid memory address
- `out_of_memory` - Out of memory
- `resource_exhausted` - Resource exhausted

**Error Handling Strategy**:
1. JIT code should not handle errors directly (interpreter handles)
2. If ECALL is JIT-compiled, check error flag in return value
3. If error, fall back to interpreter for error handling
4. Interpreter updates VM state and handles error appropriately

---

## x86_64 JIT Specific Considerations

### Register Mapping (RISC-V → x86_64)

**For ECALL Arguments** (if ECALL is JIT-compiled):
- RISC-V `a0` (x10) → x86_64 `rdi` (1st argument)
- RISC-V `a1` (x11) → x86_64 `rsi` (2nd argument)
- RISC-V `a2` (x12) → x86_64 `rdx` (3rd argument)
- RISC-V `a3` (x13) → x86_64 `rcx` (4th argument)
- RISC-V `a7` (x17) → x86_64 `r8` (5th argument, syscall_num)

**x86_64 Calling Convention**:
- Arguments: `rdi`, `rsi`, `rdx`, `rcx`, `r8`, `r9`
- Return value: `rax`
- Callee-saved: `rbx`, `rsp`, `rbp`, `r12-r15`

### Syscall Stub Generation (if ECALL is JIT-compiled)

**Stub Function**:
```zig
// Generated JIT code stub
fn syscall_stub(syscall_num: u32, arg1: u64, arg2: u64, arg3: u64, arg4: u64) u64 {
    // Call kernel handle_syscall()
    const result = kernel.handle_syscall(syscall_num, arg1, arg2, arg3, arg4);
    
    // Decode result
    switch (result) {
        .success => |value| return encode_success(value),
        .err => |err| return encode_error(err),
    }
}
```

**Encoding Functions**:
- `encode_success(value: u64) u64` - Encode success result
- `encode_error(err: BasinError) u64` - Encode error result

### Memory Access Validation

**VM Memory Bounds**:
- All pointers must be < VM_MEMORY_SIZE (default 4MB)
- Kernel validates all pointers before use
- JIT code should not validate pointers (kernel handles)

**Pointer Validation** (Kernel Side):
- Kernel checks pointer < VM_MEMORY_SIZE
- Kernel checks pointer + size < VM_MEMORY_SIZE
- Kernel returns `invalid_address` if validation fails

---

## Recommended Implementation Strategy

### Phase 1: ECALL Not JIT-Compiled (Initial)

**Strategy**: ECALL instructions fall back to interpreter

**Benefits**:
- Simpler implementation
- Matches current ARM64 JIT behavior
- No syscall-specific JIT code needed
- Interpreter handles all syscall complexity

**Implementation**:
1. JIT compiler detects ECALL instruction
2. JIT compiler emits interpreter fallback
3. Interpreter handles ECALL and calls kernel
4. Interpreter updates VM registers with result
5. JIT code continues execution

### Phase 2: ECALL JIT-Compiled (Future Optimization)

**Strategy**: ECALL instructions generate syscall stubs

**Benefits**:
- Faster syscall invocation
- Reduced interpreter overhead
- Better performance for syscall-heavy workloads

**Implementation**:
1. JIT compiler detects ECALL instruction
2. JIT compiler generates syscall stub
3. Stub calls kernel `handle_syscall()` directly
4. Stub decodes result and updates registers
5. JIT code continues execution

**Requirements**:
- Register mapping (RISC-V → x86_64)
- Syscall stub generation
- Return value encoding/decoding
- Error handling

---

## Critical Syscalls for JIT

### Memory Management
- `map` (10) - Map memory pages (for JIT code buffer)
- `unmap` (11) - Unmap memory pages
- `protect` (12) - Change memory protection (for JIT code protection)

### Process Management
- `spawn` (1) - Spawn processes (for JIT-compiled code execution)
- `exit` (2) - Exit process
- `yield` (3) - Yield CPU (for cooperative multitasking)

### Time & Scheduling
- `clock_gettime` (40) - Get current time (for JIT performance metrics)
- `sleep_until` (41) - Sleep until time (for scheduling)

### System Information
- `sysinfo` (50) - Get system information
- `get_resource_usage` (137) - Get resource usage (for JIT resource tracking)

---

## Testing Considerations

### JIT Syscall Testing

**Test Cases**:
1. ECALL fallback to interpreter (Phase 1)
2. Syscall argument passing (all argument types)
3. Return value handling (success and error cases)
4. Error handling (all error types)
5. Memory access validation (pointer validation)
6. Performance (syscall overhead measurement)

**Integration Testing**:
- Test with real syscalls from JIT-compiled code
- Test error handling from JIT-compiled code
- Test performance compared to interpreter-only execution

---

## Compatibility Notes

### RISC-V ABI Compliance

**Syscall Number Range**: 10-140 (kernel syscalls)
- Syscall numbers < 10 are SBI calls (handled separately)
- Invalid syscall numbers return `invalid_syscall` error

**Argument Validation**: Kernel validates all arguments
- Pointers must be < VM_MEMORY_SIZE
- Sizes must be reasonable
- Flags must be valid
- Handles must be valid

### x86_64 Host Integration

**Kernel Target**: RISC-V (runs in VM)
**JIT Target**: x86_64 (native host code)
**Syscall Invocation**: JIT code → Interpreter → Kernel (VM) → Host

**Call Chain**:
1. JIT-compiled code executes (x86_64 native)
2. ECALL instruction encountered
3. Fall back to interpreter (RISC-V emulation)
4. Interpreter calls kernel `handle_syscall()` (RISC-V kernel in VM)
5. Kernel executes syscall (RISC-V kernel)
6. Result returned to interpreter
7. Interpreter updates VM registers
8. JIT code continues execution

---

## Summary

**For x86_64 JIT Implementation**:
1. **Recommended**: ECALL not JIT-compiled (fall back to interpreter)
2. **Register Mapping**: RISC-V a0-a3, a7 → Kernel arg1-arg4, syscall_num
3. **Return Value**: SyscallResult encoded in a0 register
4. **Error Handling**: Interpreter handles errors (if ECALL not JIT-compiled)
5. **Memory Validation**: Kernel validates all pointers
6. **Testing**: Test ECALL fallback, argument passing, return values

**Key Points**:
- Syscall interface is RISC-V ABI compliant
- Kernel validates all arguments
- Return values are encoded as SyscallResult union
- Error handling is explicit (BasinError enum)
- JIT can defer syscall handling to interpreter (simpler)

---

**Date**: 2026-01-01-233240-pst  
**Agent**: Grain Basin Kernel Agent (3a)  
**Status**: ✅ **COMPLETE** — Ready for Agent 3b (VM Runtime) x86_64 JIT implementation

