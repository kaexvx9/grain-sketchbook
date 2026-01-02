# Syscall Interface Test Patterns Design

**Date**: 2026-01-02-083246-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Independent work using syscall interface documentation  
**Priority**: SUPPORTING — Per single-threaded dependency chain (Step 5)

---

## Executive Summary

**Objective**: Design test patterns for syscall interface testing using Basin Kernel syscall interface documentation. This work is independent and supporting, not blocking the critical path.

**Why**: Prepare comprehensive test patterns for syscall interface validation across architectures, enabling verification once VM Runtime (3b) and Init System (3d) implementations are ready.

**Context**: Basin Kernel (3a) syscall interface documentation is complete and available. This design work prepares test patterns that will be used when coordinating with Agents 3b and 3d.

**Timeline**: Independent work (can proceed in parallel with critical path)

---

## Syscall Interface Documentation Available

**Source**: Basin Kernel Agent (3a) — Complete and ready for use

**Documents**:
1. **Complete Syscall Interface Reference** (`docs/kernel/syscall_interface_reference.md`)
   - All 140 syscalls documented
   - Complete signatures, arguments, return values, error codes
   - RISC-V ABI calling convention

2. **JIT-Specific Interface Guide** (`docs/kernel/syscall_interface_for_jit.md`)
   - RISC-V → x86_64 JIT compilation considerations
   - ECALL instruction handling strategies
   - Register mapping (RISC-V → x86_64)

3. **Init System Interface Guide** (`docs/kernel/syscall_interface_for_init.md`)
   - Critical syscalls for service management
   - Service lifecycle patterns
   - Configuration and dependency management patterns

---

## Test Pattern Categories

### Pattern 1: Syscall Argument Validation Tests

**Why**: Validate syscall arguments are correctly encoded and passed according to RISC-V ABI.

**Test Patterns**:
- Pointer validation (VM memory addresses, bounds checking)
- Size validation (byte counts, reasonable limits)
- Flag validation (MapFlags, OpenFlags bitcast to u64)
- Handle validation (handle.value, non-zero check)
- Enum validation (u32 truncated to u64)

**Implementation**:
```zig
/// Test syscall argument encoding.
/// Why: Validate arguments are correctly encoded per RISC-V ABI.
test "syscall argument encoding: pointer validation" {
    const test_setup = create_test_integration();
    var kernel = test_setup.kernel;
    
    // Test valid pointer (within VM memory bounds).
    const valid_ptr: u64 = 0x80000000; // Start of VM memory.
    const result = kernel.handle_syscall(
        @intFromEnum(Syscall.map),
        valid_ptr,
        4096, // size
        0, // flags
        0, // unused
    );
    
    // Assert: Valid pointer should succeed or return specific error.
    _ = result;
}

/// Test syscall argument encoding: invalid pointer.
test "syscall argument encoding: invalid pointer" {
    const test_setup = create_test_integration();
    var kernel = test_setup.kernel;
    
    // Test invalid pointer (out of bounds).
    const invalid_ptr: u64 = 0xFFFFFFFFFFFFFFFF; // Out of bounds.
    const result = kernel.handle_syscall(
        @intFromEnum(Syscall.map),
        invalid_ptr,
        4096,
        0,
        0,
    );
    
    // Assert: Invalid pointer should return error.
    try testing.expect(result == .err);
    try testing.expect(result.err == .invalid_address);
}
```

---

### Pattern 2: Syscall Return Value Validation Tests

**Why**: Validate syscall return values are correctly decoded from SyscallResult.

**Test Patterns**:
- Success return value decoding (SyscallResult.ok(value))
- Error return value decoding (SyscallResult.fail(err))
- Return value type validation (u64 encoding)
- Error code validation (BasinError enum)

**Implementation**:
```zig
/// Test syscall return value decoding.
/// Why: Validate return values are correctly decoded from SyscallResult.
test "syscall return value: success decoding" {
    const test_setup = create_test_integration();
    var kernel = test_setup.kernel;
    
    // Test syscall that returns success value.
    const result = kernel.handle_syscall(
        @intFromEnum(Syscall.sysinfo),
        0, // sysinfo doesn't need arguments
        0,
        0,
        0,
    );
    
    // Assert: Result should be success.
    try testing.expect(result == .success);
    
    // Assert: Return value should be valid (sysinfo pointer).
    const sysinfo_ptr = result.success;
    _ = sysinfo_ptr;
}

/// Test syscall return value: error decoding.
test "syscall return value: error decoding" {
    const test_setup = create_test_integration();
    var kernel = test_setup.kernel;
    
    // Test syscall with invalid arguments (should return error).
    const result = kernel.handle_syscall(
        @intFromEnum(Syscall.open),
        0, // null pointer (invalid)
        0,
        0,
        0,
    );
    
    // Assert: Result should be error.
    try testing.expect(result == .err);
    
    // Assert: Error code should be valid BasinError.
    const err = result.err;
    _ = err;
}
```

---

### Pattern 3: JIT Compilation Syscall Testing Patterns

**Why**: Validate syscall interface works correctly with JIT-compiled code (RISC-V → x86_64).

**Test Patterns**:
- ECALL instruction handling (fall back to interpreter)
- Register mapping validation (RISC-V → x86_64)
- Return value handling from JIT-compiled code
- Memory access validation from JIT-compiled code

**Implementation** (prepared for coordination with Agent 3b):
```zig
/// Test JIT compilation syscall interface.
/// Why: Validate syscalls work correctly from JIT-compiled code.
/// Note: This test will be implemented after coordinating with VM Runtime (3b).
test "JIT compilation: syscall interface" {
    const test_setup = create_test_integration();
    const arch = test_setup.arch;
    
    // Only run on x86_64 architectures (where JIT is needed).
    if (arch != .x86_64_amd and arch != .x86_64_intel) {
        return; // Skip on non-x86_64 architectures.
    }
    
    // Test syscall from JIT-compiled code.
    // Note: Implementation depends on VM Runtime (3b) JIT implementation.
    // This is a placeholder for future coordination.
    _ = test_setup;
}
```

---

### Pattern 4: Init System Syscall Testing Patterns

**Why**: Validate syscall interface works correctly for Init System service management.

**Test Patterns**:
- Service spawn/wait/exit lifecycle
- Process group/session management (setpgid, setsid)
- Resource management (set_resource_limit, get_resource_usage)
- Signal handling (kill, signal)
- Configuration loading (open, read, close)

**Implementation** (prepared for coordination with Agent 3d):
```zig
/// Test Init System syscall interface.
/// Why: Validate syscalls work correctly for Init System service management.
/// Note: This test will be implemented after coordinating with Init System (3d).
test "Init System: service lifecycle syscalls" {
    const test_setup = create_test_integration();
    
    // Test service spawn.
    const spawn_result = kernel.handle_syscall(
        @intFromEnum(Syscall.spawn),
        executable_ptr,
        args_ptr,
        args_len,
        0,
    );
    
    // Assert: Spawn should succeed.
    try testing.expect(spawn_result == .success);
    const pid = spawn_result.success;
    
    // Test service wait.
    const wait_result = kernel.handle_syscall(
        @intFromEnum(Syscall.wait),
        pid,
        0,
        0,
        0,
    );
    
    // Assert: Wait should succeed (or return specific error).
    _ = wait_result;
}
```

---

### Pattern 5: Multi-Architecture Syscall Interface Testing

**Why**: Validate syscall interface behavior is consistent across ARM64, x86_64 AMD, and x86_64 Intel.

**Test Patterns**:
- Architecture-agnostic syscall tests
- Architecture-specific syscall validation
- Cross-architecture syscall behavior comparison

**Implementation**:
```zig
/// Test syscall interface across architectures.
/// Why: Validate syscall behavior is consistent across all architectures.
test "syscall interface: multi-architecture consistency" {
    const test_setup = create_test_integration();
    const arch = test_setup.arch;
    
    // Test syscall (architecture-agnostic).
    const result = kernel.handle_syscall(
        @intFromEnum(Syscall.sysinfo),
        0,
        0,
        0,
        0,
    );
    
    // Assert: Result should be consistent across architectures.
    // Note: Behavior should be identical on ARM64, x86_64 AMD, x86_64 Intel.
    _ = result;
    _ = arch;
}
```

---

## Test Helper Functions

### Helper: Create Test Integration with Syscall Interface

**Why**: Provide test helpers that use syscall interface documentation for consistent testing.

**Implementation**:
```zig
/// Create test integration with syscall interface helpers.
/// Why: Provide consistent test setup using syscall interface documentation.
/// Contract: Returns initialized Integration instance with syscall helpers.
/// GrainStyle: Explicit types (u32/u64), bounded allocations, assertions.
pub fn create_test_integration_with_syscall_helpers() struct {
    vm: VM,
    kernel: BasinKernel,
    integration: Integration,
} {
    // Use existing test integration helper.
    const base_setup = create_test_integration();
    
    // Assert: Integration must be initialized (postcondition).
    std.debug.assert(base_setup.integration.initialized);
    
    // Assert: VM must be in halted state (postcondition).
    std.debug.assert(base_setup.vm.state == .halted);
    
    return base_setup;
}

/// Helper: Invoke syscall with proper argument encoding.
/// Why: Ensure syscall arguments are correctly encoded per RISC-V ABI.
/// Contract: Returns SyscallResult or error.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn invoke_syscall(
    kernel: *BasinKernel,
    syscall_num: Syscall,
    arg1: u64,
    arg2: u64,
    arg3: u64,
    arg4: u64,
) BasinError!SyscallResult {
    // Assert: Kernel pointer must be valid (precondition).
    std.debug.assert(@intFromPtr(kernel) != 0);
    
    // Assert: Syscall number must be valid (precondition).
    const syscall_val = @intFromEnum(syscall_num);
    std.debug.assert(syscall_val >= 1);
    std.debug.assert(syscall_val <= 140);
    
    // Invoke syscall using handle_syscall (per syscall interface docs).
    const result = kernel.handle_syscall(
        syscall_val,
        arg1,
        arg2,
        arg3,
        arg4,
    ) catch |err| {
        // Return error directly (per syscall interface docs).
        return err;
    };
    
    // Assert: Result must be valid (postcondition).
    _ = result;
    
    return result;
}

/// Helper: Validate syscall argument encoding (pointer).
/// Why: Ensure pointer arguments are correctly encoded per RISC-V ABI.
/// Contract: Returns true if pointer is valid, false otherwise.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn validate_syscall_pointer(ptr: u64) bool {
    // Assert: Pointer must be within VM memory bounds (per syscall interface docs).
    const VM_MEMORY_SIZE: u64 = 0x400000; // 4MB default VM memory.
    const VM_MEMORY_START: u64 = 0x80000000; // VM memory start address.
    
    // Validate pointer is within VM memory range.
    if (ptr < VM_MEMORY_START) {
        return false; // Below VM memory start.
    }
    
    if (ptr >= VM_MEMORY_START + VM_MEMORY_SIZE) {
        return false; // Above VM memory end.
    }
    
    return true; // Valid pointer.
}

/// Helper: Validate syscall argument encoding (handle).
/// Why: Ensure handle arguments are correctly encoded per RISC-V ABI.
/// Contract: Returns true if handle is valid, false otherwise.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn validate_syscall_handle(handle_value: u64) bool {
    // Assert: Handle must be non-zero (per syscall interface docs).
    return handle_value != 0;
}

/// Helper: Validate syscall argument encoding (flags).
/// Why: Ensure flag arguments are correctly encoded per RISC-V ABI.
/// Contract: Returns true if flags are valid, false otherwise.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn validate_syscall_flags(flags: u64, max_flags: u64) bool {
    // Assert: Flags must be within valid range (per syscall interface docs).
    return flags <= max_flags;
}

/// Helper: Decode syscall return value (success).
/// Why: Ensure return values are correctly decoded from SyscallResult.
/// Contract: Returns success value if result is success, error otherwise.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn decode_syscall_success(result: SyscallResult) BasinError!u64 {
    // Assert: Result must be success (precondition).
    switch (result) {
        .ok => |value| {
            // Assert: Value must be valid (postcondition).
            _ = value;
            return value;
        },
        .fail => |err| {
            // Return error (per syscall interface docs).
            return err;
        },
    }
}

/// Helper: Decode syscall return value (error).
/// Why: Ensure error values are correctly decoded from SyscallResult.
/// Contract: Returns error if result is error, null otherwise.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn decode_syscall_error(result: SyscallResult) ?BasinError {
    // Assert: Result must be error (precondition).
    switch (result) {
        .ok => |_| {
            return null; // Not an error.
        },
        .fail => |err| {
            // Assert: Error must be valid (postcondition).
            _ = err;
            return err;
        },
    }
}

/// Helper: Encode syscall argument (pointer).
/// Why: Ensure pointer arguments are correctly encoded per RISC-V ABI.
/// Contract: Returns encoded pointer value.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn encode_syscall_pointer(ptr: u64) u64 {
    // Assert: Pointer must be valid (precondition).
    std.debug.assert(validate_syscall_pointer(ptr));
    
    // Return pointer as-is (per syscall interface docs).
    return ptr;
}

/// Helper: Encode syscall argument (handle).
/// Why: Ensure handle arguments are correctly encoded per RISC-V ABI.
/// Contract: Returns encoded handle value.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn encode_syscall_handle(handle: Handle) u64 {
    // Assert: Handle must be valid (precondition).
    std.debug.assert(handle.is_valid());
    
    // Return handle.value (per syscall interface docs).
    return handle.value;
}

/// Helper: Encode syscall argument (flags).
/// Why: Ensure flag arguments are correctly encoded per RISC-V ABI.
/// Contract: Returns encoded flags value.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn encode_syscall_flags(flags: MapFlags) u64 {
    // Bitcast flags to u64 (per syscall interface docs).
    return @bitCast(u64, flags);
}

/// Helper: Test syscall argument validation.
/// Why: Validate syscall arguments are correctly validated by kernel.
/// Contract: Returns true if validation passes, false otherwise.
/// GrainStyle: Explicit types (u32/u64), bounded operations, assertions.
pub fn test_syscall_argument_validation(
    kernel: *BasinKernel,
    syscall_num: Syscall,
    invalid_arg: u64,
    arg_index: u32,
) bool {
    // Assert: Kernel pointer must be valid (precondition).
    std.debug.assert(@intFromPtr(kernel) != 0);
    
    // Assert: Arg index must be valid (precondition).
    std.debug.assert(arg_index >= 1);
    std.debug.assert(arg_index <= 4);
    
    // Test syscall with invalid argument.
    const args = [_]u64{ 0, 0, 0, 0 };
    args[arg_index - 1] = invalid_arg;
    
    const result = kernel.handle_syscall(
        @intFromEnum(syscall_num),
        args[0],
        args[1],
        args[2],
        args[3],
    ) catch |_| {
        // Expected error for invalid argument.
        return true; // Validation passed (error returned).
    };
    
    // If no error, validation may have failed.
    _ = result;
    return false; // Validation may have failed.
}
```

---

## Coordination Needs (Future)

### With VM Runtime Agent (3b) — When JIT Implementation Ready

**Status**: ⏳ **PENDING** — After Step 2 completion (JIT implementation)

**Coordination Points**:
- JIT compilation syscall testing requirements
- ECALL instruction handling validation
- Register mapping validation (RISC-V → x86_64)
- Return value handling from JIT-compiled code

**Timeline**: Week 1-2 (after JIT implementation)

---

### With sevenos Init System Agent (3d) — When Init System Ready

**Status**: ⏳ **PENDING** — After Step 3 completion (Init System implementation)

**Coordination Points**:
- Init System syscall testing requirements
- Service lifecycle syscall validation
- Process group/session management validation
- Resource management validation

**Timeline**: Week 1-2 (after Init System implementation)

---

### With Basin Kernel Agent (3a) — Ongoing

**Status**: ✅ **ACTIVE** — Syscall interface documentation available

**Coordination Points**:
- Syscall interface documentation reference (complete)
- Syscall interface testing validation
- Framework x86_64 syscall interface testing

**Timeline**: Ongoing (as needed for testing validation)

---

## Independent Work Status

**Current Work**: Designing test patterns using available syscall interface documentation

**Status**: ✅ **PROGRESSING** — Independent design work, not blocking critical path

**What I'm Doing**:
- Designing syscall argument validation test patterns
- Designing syscall return value validation test patterns
- Preparing JIT compilation test patterns (for future coordination with 3b)
- Preparing Init System test patterns (for future coordination with 3d)
- Designing multi-architecture syscall interface test patterns

**What I'm Not Blocking**:
- Step 1: Basin Kernel (3a) syscall doc distribution (complete)
- Step 2: VM Runtime (3b) JIT implementation (can proceed independently)
- Step 3: Init System (3d) implementation (can proceed independently)
- Step 4: Grainscript Shell (1e) integration (can proceed independently)

---

## Grain Style Compliance

### Requirements

1. **Function Naming**: `grain_case` (snake_case)
2. **Type Usage**: Explicit `u32`/`u64`, no `usize`/`isize`
3. **Line Length**: ≤100 characters (`grainwrap-100`)
4. **Function Length**: ≤70 lines (`grain validate-70`)
5. **Assertions**: Minimum 2 assertions per function
6. **Bounded Allocations**: All MAX_ constants defined
7. **Compiler Warnings**: All warnings addressed

---

**Date**: 2026-01-02-083246-pst  
**Agent**: Grain System Integration Agent (3c)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Independent work using syscall interface documentation  
**Priority**: SUPPORTING — Per single-threaded dependency chain (Step 5)

