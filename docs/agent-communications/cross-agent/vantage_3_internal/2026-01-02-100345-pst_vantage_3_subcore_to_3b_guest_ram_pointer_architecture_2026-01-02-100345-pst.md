# Vantage 3 Subcore: Guest RAM Pointer Architecture for x86_64 JIT

**Date**: 2026-01-02-100345-pst  
**From**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**To**: VM Runtime Agent (Agent 3b, L2 Sub-Agent)  
**Status**: ✅ **ARCHITECTURE APPROVED** — Proceed with implementation

---

## Executive Summary

**Architecture Decision**: Use **callee-saved register (R12)** to pass `guest_ram` pointer to x86_64 compiled functions, matching ARM64's approach with x27.

**Rationale**:
- ✅ Matches ARM64 architecture (x27 = mem_base)
- ✅ No function signature changes needed
- ✅ Minimal code changes
- ✅ Consistent with existing JIT architecture

---

## Architecture Overview

### Current State

**ARM64**:
- `enter_jit()` passes `mem_base` in register **x27** (callee-saved)
- Compiled functions can access `guest_ram` via x27
- No function signature changes needed

**x86_64** (Current):
- Compiled functions only receive `*GuestState` (RDI = first argument)
- No `guest_ram` pointer available
- Address translation implemented but cannot access memory

---

## Proposed Architecture

### x86_64 Guest RAM Pointer Passing

**Strategy**: Pass `guest_ram` pointer via **R12** (callee-saved register), matching ARM64's x27 approach.

**Implementation**:

1. **Create `enter_jit_x86_64()` function**:
   ```zig
   pub fn enter_jit_x86_64(
       code: *const anyopaque,
       state: *GuestState,
       mem_base: [*]u8,
   ) void {
       asm volatile (
           \\  mov %rdi, %r12  // Save GuestState pointer (1st arg) to R12
           \\  mov %rsi, %rdi  // Move mem_base (2nd arg) to RDI
           \\  mov %rdi, %r13  // Save mem_base to R13 (callee-saved)
           \\  mov %r12, %rdi  // Restore GuestState to RDI
           \\  jmp %[code]
           :
           : [code] "r" (code),
             [state] "{rdi}" (state),
             [mem_base] "{rsi}" (mem_base),
           : .{ .r12 = true, .r13 = true, .memory = true });
   }
   ```

   **Simpler approach** (using inline assembly with register constraints):
   ```zig
   pub fn enter_jit_x86_64(
       code: *const anyopaque,
       state: *GuestState,
       mem_base: [*]u8,
   ) void {
       asm volatile (
           \\  mov %[mem_base], %%r13
           \\  jmp %[code]
           :
           : [code] "r" (code),
             [state] "{rdi}" (state),
             [mem_base] "r" (mem_base),
           : .{ .r13 = true, .memory = true });
   }
   ```

2. **Update compiled function access**:
   - Use **R13** (callee-saved) for `guest_ram` base pointer
   - Access memory: `[r13 + offset]` instead of direct addressing

3. **Update `emit_ldr_x86_64()` and `emit_str_x86_64()`**:
   - Use R13 as base register for guest RAM access
   - Example: `mov rax, [r13 + rcx]` (load from guest RAM)

---

## Register Allocation

### x86_64 System V ABI

**Argument Registers**:
- RDI = 1st argument (GuestState pointer)
- RSI = 2nd argument (available for mem_base)
- RDX, RCX, R8, R9 = additional arguments

**Callee-Saved Registers** (preserved across calls):
- RBX, RBP, R12, R13, R14, R15

**Proposed Allocation**:
- **R13** = `guest_ram` base pointer (callee-saved, matches ARM64 x27)
- **RDI** = GuestState pointer (1st argument, matches ARM64 x28)
- **R12-R15** = Available for other uses if needed

---

## Implementation Steps

### Step 1: Create `enter_jit_x86_64()` Function

**Location**: `src/kernel_vm/jit.zig`

**Function**:
```zig
/// Enter JIT-compiled code (x86_64).
/// Why: Bridge between host and JIT-compiled code.
/// Contract: Passes GuestState and guest_ram pointer to compiled function.
/// GrainStyle: Explicit register allocation, deterministic behavior.
pub fn enter_jit_x86_64(
    code: *const anyopaque,
    state: *GuestState,
    mem_base: [*]u8,
) void {
    asm volatile (
        \\  mov %[mem_base], %%r13
        \\  jmp %[code]
        :
        : [code] "r" (code),
          [state] "{rdi}" (state),
          [mem_base] "r" (mem_base),
        : .{ .r13 = true, .memory = true });
}
```

---

### Step 2: Update VM Runtime to Use `enter_jit_x86_64()`

**Location**: `src/kernel_vm/vm.zig` or `src/kernel_vm/integration.zig`

**Change**: Use `enter_jit_x86_64()` for x86_64, `enter_jit()` for ARM64

**Example**:
```zig
// In VM execution path
if (builtin.cpu.arch == .x86_64) {
    JitContext.enter_jit_x86_64(func, &state, ram.ptr);
} else if (builtin.cpu.arch == .aarch64) {
    JitContext.enter_jit(func, &state, ram.ptr);
}
```

---

### Step 3: Update `emit_ldr_x86_64()` to Use R13

**Location**: `src/kernel_vm/jit.zig`

**Change**: Use R13 as base register for guest RAM access

**Current** (direct addressing):
```zig
pub fn emit_ldr_x86_64(self: *JitContext, rt: u5, base: u5, offset: i32) void {
    // Load from [base + offset]
    // Currently uses direct addressing (needs guest_ram)
}
```

**Updated** (using R13):
```zig
pub fn emit_ldr_x86_64(self: *JitContext, rt: u5, base: u5, offset: i32) void {
    // Load base register value (RISC-V register) into temporary
    // Calculate address: base + offset
    // Load from [r13 + address] (guest_ram base + offset)
    // R13 = guest_ram base pointer (set by enter_jit_x86_64)
}
```

**Implementation**:
1. Load base register value from GuestState (RDI + offset)
2. Add offset to base (if offset != 0)
3. Translate address (kernel space, framebuffer, low memory)
4. Load from `[r13 + translated_offset]` (guest_ram base + offset)
5. Store result to destination register

---

### Step 4: Update `emit_str_x86_64()` to Use R13

**Location**: `src/kernel_vm/jit.zig`

**Change**: Use R13 as base register for guest RAM access

**Implementation**:
1. Load base register value from GuestState (RDI + offset)
2. Add offset to base (if offset != 0)
3. Translate address (kernel space, framebuffer, low memory)
4. Store to `[r13 + translated_offset]` (guest_ram base + offset)

---

### Step 5: Complete Address Translation

**Location**: `src/kernel_vm/jit.zig` - `emit_translate_address_x86_64()`

**Current**: Basic kernel space translation (0x80000000+)

**Complete**:
1. **Kernel space** (0x80000000+): `offset = addr - 0x80000000`
2. **Framebuffer** (0x90000000+): `offset = addr - 0x90000000` (or special handling)
3. **Low memory** (< 0x80000000): Handle appropriately (may need special handling)

---

## Testing Strategy

### Unit Tests

**Test Files**:
- `tests/154_x86_64_jit_emit_test.zig` - Emit function tests
- `tests/155_x86_64_jit_translation_test.zig` - Translation tests

**Test Coverage**:
1. **Guest RAM Access**: Test load/store with R13 base pointer
2. **Address Translation**: Test kernel space, framebuffer, low memory
3. **Register Allocation**: Verify R13 is preserved across calls
4. **Memory Bounds**: Test bounds checking

### Integration Tests

**Test Files**:
- `tests/156_x86_64_jit_guest_ram_test.zig` - Guest RAM integration tests

**Test Coverage**:
1. **End-to-End**: Test complete JIT compilation with guest RAM access
2. **Memory Access**: Test load/store operations with real guest RAM
3. **Address Translation**: Test all address ranges (kernel, framebuffer, low memory)

---

## Coordination Points

### With System Integration Agent (3c)

**What Agent 3c Needs**:
- JIT compilation test patterns for multi-architecture testing
- Guest RAM access test patterns
- Address translation test patterns

**What Agent 3c Can Provide**:
- Multi-architecture testing framework for JIT validation
- Framework x86_64 test infrastructure
- Test execution coordination

**Action**: Coordinate with Agent 3c on JIT testing requirements (IMMEDIATE — Agent 3c ready for coordination).

---

## Implementation Timeline

### Week 1 (Immediate)

**Tasks**:
1. ✅ Create `enter_jit_x86_64()` function
2. ✅ Update VM runtime to use `enter_jit_x86_64()`
3. ✅ Update `emit_ldr_x86_64()` to use R13
4. ✅ Update `emit_str_x86_64()` to use R13
5. ✅ Complete address translation (kernel space, framebuffer, low memory)

**Success Criteria**:
- ✅ Guest RAM access working via R13
- ✅ Address translation complete
- ✅ Load/store operations working
- ✅ Unit tests passing

### Week 2 (Testing)

**Tasks**:
1. ✅ Write integration tests
2. ✅ Test on Framework x86_64
3. ✅ Coordinate with Agent 3c for multi-architecture testing
4. ✅ Performance validation

**Success Criteria**:
- ✅ All tests passing
- ✅ Framework x86_64 testing complete
- ✅ Performance meets targets

---

## Summary

**Architecture**: Use **R13** (callee-saved register) to pass `guest_ram` pointer to x86_64 compiled functions, matching ARM64's x27 approach.

**Implementation Steps**:
1. Create `enter_jit_x86_64()` function
2. Update VM runtime to use `enter_jit_x86_64()`
3. Update `emit_ldr_x86_64()` and `emit_str_x86_64()` to use R13
4. Complete address translation
5. Write tests and validate

**Coordination**:
- ⏳ **IMMEDIATE**: Coordinate with Agent 3c on JIT testing requirements
- ⏳ **WEEK 2**: Framework x86_64 testing coordination

**Timeline**: WEEK 1-2 (implementation and testing)

---

**Date**: 2026-01-02-100345-pst  
**From**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**To**: VM Runtime Agent (Agent 3b, L2 Sub-Agent)  
**Status**: ✅ **ARCHITECTURE APPROVED** — Proceed with implementation

