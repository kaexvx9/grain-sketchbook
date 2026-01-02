# JIT Integration Planning: RISC-V → x86_64 JIT with Basin Kernel

**Date**: 2026-01-02-083246-pst  
**Agent**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**Purpose**: Integration planning document for RISC-V → x86_64 JIT compilation with Basin Kernel syscall integration  
**Target**: Supports Step 2 (Agent 3b JIT implementation) when unblocked

---

## Executive Summary

This document provides comprehensive integration planning for implementing RISC-V → x86_64 JIT compilation in the VM Runtime (Agent 3b) with Basin Kernel syscall integration. It covers integration patterns, error handling, performance considerations, and testing strategies.

**Key Integration Points**:
- RISC-V → x86_64 JIT compilation architecture
- Basin Kernel syscall interface integration
- Framework x86_64 JIT execution environment
- Error handling and recovery patterns
- Performance optimization strategies
- Testing and validation approaches

---

## Architecture Overview

### Integration Flow

```
┌─────────────────┐
│  RISC-V Code    │
│  (Guest Memory) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  JIT Compiler   │  ← x86_64 Backend
│  (x86_64)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  JIT Code       │  ← x86_64 Native Code
│  (Executable)   │
└────────┬────────┘
         │
         │ ECALL encountered
         ▼
┌─────────────────┐
│  Interpreter    │  ← Fallback (Phase 1)
│  (RISC-V)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Basin Kernel   │  ← RISC-V Kernel
│  handle_syscall │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Syscall Result │
│  (SyscallResult)│
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  VM Registers   │  ← Updated by Interpreter
│  (Guest State)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  JIT Code       │  ← Continue Execution
│  (Resume)       │
└─────────────────┘
```

### Component Integration

**1. JIT Compiler (Agent 3b)**
- RISC-V → x86_64 instruction translation
- x86_64 code generation and optimization
- Code buffer management
- ECALL detection and fallback handling

**2. Basin Kernel (Agent 3a)**
- Syscall interface (`handle_syscall()`)
- Argument validation and processing
- Return value encoding (`SyscallResult`)
- Error handling (`BasinError`)

**3. VM Runtime (Agent 3b)**
- Interpreter fallback for ECALL
- VM state management (`GuestState`)
- Register mapping (RISC-V → x86_64)
- Memory access validation

---

## Integration Patterns

### Pattern 1: ECALL Fallback (Phase 1 - Recommended)

**Strategy**: ECALL instructions fall back to interpreter

**Implementation**:
```zig
// In JIT compiler (jit.zig)
fn compile_block(self: *JitContext, pc: u64) !void {
    // ... instruction translation ...
    
    // Detect ECALL instruction
    if (is_ecall_instruction(instruction)) {
        // Emit interpreter fallback
        try self.emit_interpreter_fallback(pc);
        return;
    }
    
    // ... continue JIT compilation ...
}

// In VM runtime (vm.zig)
fn step(self: *VM) !void {
    // Check JIT cache
    if (self.jit.lookup(self.cpu.pc)) |native_addr| {
        // Execute JIT code
        const native_fn = @ptrCast(*const fn(*GuestState) callconv(.C) void, native_addr);
        native_fn(&self.cpu);
        
        // JIT code returns when ECALL encountered
        // Interpreter handles ECALL
        if (self.cpu.pc == ECALL_PC) {
            try self.handle_ecall();
        }
    } else {
        // Fallback to interpreter
        try self.interpreter.step();
    }
}

fn handle_ecall(self: *VM) !void {
    // Extract syscall arguments from VM registers
    const syscall_num = @intCast(u32, self.cpu.regs[17]); // a7
    const arg1 = self.cpu.regs[10]; // a0
    const arg2 = self.cpu.regs[11]; // a1
    const arg3 = self.cpu.regs[12]; // a2
    const arg4 = self.cpu.regs[13]; // a3
    
    // Call kernel handle_syscall()
    const result = try self.kernel.handle_syscall(
        syscall_num,
        arg1,
        arg2,
        arg3,
        arg4,
    );
    
    // Update VM registers with result
    switch (result) {
        .ok => |value| {
            self.cpu.regs[10] = value; // a0
        },
        .fail => |err| {
            // Encode error in a0 register
            self.cpu.regs[10] = encode_error(err);
        },
    }
}
```

**Benefits**:
- ✅ Simpler implementation
- ✅ Matches current ARM64 JIT behavior
- ✅ No syscall-specific JIT code needed
- ✅ Interpreter handles all syscall complexity

**Considerations**:
- ⚠️ Interpreter overhead for syscall-heavy workloads
- ⚠️ Performance impact for frequent syscalls
- ✅ Can optimize later with Phase 2 (ECALL JIT-compiled)

---

### Pattern 2: ECALL JIT-Compiled (Phase 2 - Future Optimization)

**Strategy**: ECALL instructions generate syscall stubs

**Implementation**:
```zig
// In JIT compiler (jit.zig)
fn compile_ecall(self: *JitContext, syscall_num: u32) !void {
    // Generate syscall stub
    // 1. Map RISC-V registers to x86_64 registers
    //    a0 (x10) → rdi (1st argument)
    //    a1 (x11) → rsi (2nd argument)
    //    a2 (x12) → rdx (3rd argument)
    //    a3 (x13) → rcx (4th argument)
    //    a7 (x17) → r8 (syscall_num)
    
    // 2. Emit x86_64 code to call kernel handle_syscall()
    try self.emit_call_kernel_syscall(syscall_num);
    
    // 3. Decode result and update RISC-V registers
    //    rax (return value) → a0 (x10)
    try self.emit_decode_result();
}

fn emit_call_kernel_syscall(self: *JitContext, syscall_num: u32) !void {
    // Emit x86_64 code:
    // mov %rdi, [GuestState + offset(a0)]
    // mov %rsi, [GuestState + offset(a1)]
    // mov %rdx, [GuestState + offset(a2)]
    // mov %rcx, [GuestState + offset(a3)]
    // mov %r8, syscall_num
    // call kernel_handle_syscall
    // mov [GuestState + offset(a0)], %rax
}
```

**Benefits**:
- ✅ Faster syscall invocation
- ✅ Reduced interpreter overhead
- ✅ Better performance for syscall-heavy workloads

**Considerations**:
- ⚠️ More complex implementation
- ⚠️ Requires register mapping (RISC-V → x86_64)
- ⚠️ Requires syscall stub generation
- ⚠️ Requires return value encoding/decoding

**Recommendation**: Implement Phase 1 first, optimize with Phase 2 later if needed.

---

## Error Handling Patterns

### Pattern 1: Interpreter Error Handling (Phase 1)

**Strategy**: Interpreter handles all syscall errors

**Implementation**:
```zig
// In VM runtime (vm.zig)
fn handle_ecall(self: *VM) !void {
    const syscall_num = @intCast(u32, self.cpu.regs[17]);
    const arg1 = self.cpu.regs[10];
    const arg2 = self.cpu.regs[11];
    const arg3 = self.cpu.regs[12];
    const arg4 = self.cpu.regs[13];
    
    // Call kernel (may return error)
    const result = self.kernel.handle_syscall(
        syscall_num,
        arg1,
        arg2,
        arg3,
        arg4,
    ) catch |err| {
        // Handle kernel error
        self.cpu.regs[10] = encode_error(err);
        return;
    };
    
    // Handle success
    switch (result) {
        .ok => |value| {
            self.cpu.regs[10] = value;
        },
        .fail => |err| {
            self.cpu.regs[10] = encode_error(err);
        },
    }
}
```

**Error Types**:
- `invalid_syscall` - Invalid syscall number
- `invalid_argument` - Invalid argument value
- `invalid_address` - Invalid memory address
- `out_of_memory` - Out of memory
- `resource_exhausted` - Resource exhausted

**Error Encoding**:
```zig
fn encode_error(err: BasinError) u64 {
    // Encode error code in low bits, error flag in high bits
    return (@intCast(u64, @enumToInt(err)) << 32) | 0xFFFFFFFF00000000;
}
```

---

### Pattern 2: JIT Error Handling (Phase 2)

**Strategy**: JIT code handles syscall errors directly

**Implementation**:
```zig
// In JIT compiler (jit.zig)
fn compile_ecall_with_error_handling(self: *JitContext, syscall_num: u32) !void {
    // Generate syscall stub with error handling
    // 1. Call kernel handle_syscall()
    try self.emit_call_kernel_syscall(syscall_num);
    
    // 2. Check error flag in return value
    try self.emit_check_error_flag();
    
    // 3. Branch to error handler if error
    try self.emit_branch_on_error();
    
    // 4. Extract value and update registers (success path)
    try self.emit_decode_success();
    
    // 5. Error handler (fallback to interpreter)
    try self.emit_error_handler();
}
```

**Considerations**:
- ⚠️ More complex JIT code generation
- ⚠️ Requires error flag checking in JIT code
- ✅ Faster error handling for common cases
- ✅ Can fall back to interpreter for complex errors

---

## Performance Considerations

### JIT Compilation Overhead

**Metrics to Track**:
- JIT compilation time per block
- Code buffer size
- Cache hit rate
- Execution time (JIT vs interpreter)

**Optimization Strategies**:
1. **Block Caching**: Cache compiled blocks to avoid recompilation
2. **Lazy Compilation**: Compile blocks on first execution
3. **Hot Path Optimization**: Optimize frequently executed blocks
4. **Code Buffer Management**: Reuse code buffers to reduce allocation overhead

### Syscall Overhead

**Phase 1 (ECALL Fallback)**:
- Interpreter overhead: ~100-200 cycles per syscall
- JIT → Interpreter transition: ~50-100 cycles
- Total overhead: ~150-300 cycles per syscall

**Phase 2 (ECALL JIT-Compiled)**:
- Direct syscall invocation: ~10-20 cycles
- Register mapping: ~5-10 cycles
- Total overhead: ~15-30 cycles per syscall

**Performance Target**: < 1ms syscall latency on Framework x86_64

---

## Testing Strategy

### Unit Tests

**Test Coverage**:
1. **ECALL Detection**: Verify JIT detects ECALL instructions
2. **Interpreter Fallback**: Verify ECALL falls back to interpreter
3. **Argument Passing**: Verify syscall arguments passed correctly
4. **Return Value Handling**: Verify return values decoded correctly
5. **Error Handling**: Verify errors handled correctly

**Test Files**:
- `tests/159_jit_ecall_detection_test.zig` - ECALL detection tests
- `tests/160_jit_syscall_integration_test.zig` - Syscall integration tests
- `tests/161_jit_error_handling_test.zig` - Error handling tests

### Integration Tests

**Test Coverage**:
1. **End-to-End Syscall Execution**: Test complete syscall flow
2. **Multiple Syscall Types**: Test different syscall categories
3. **Error Scenarios**: Test error handling for all error types
4. **Performance**: Benchmark syscall overhead

**Test Files**:
- `tests/162_jit_syscall_e2e_test.zig` - End-to-end syscall tests
- `tests/163_jit_syscall_performance_test.zig` - Performance benchmarks

### Framework x86_64 Testing

**Test Coverage**:
1. **Framework x86_64 AMD**: Test on Framework 16 (x86_64 AMD)
2. **Legacy Intel x86_64**: Test on legacy Intel hardware
3. **Multi-Architecture**: Test across ARM64, x86_64 AMD, x86_64 Intel

**Test Files**:
- `tests/164_jit_framework_x86_64_test.zig` - Framework x86_64 tests
- `tests/165_jit_multi_arch_test.zig` - Multi-architecture tests

---

## Framework x86_64 Execution Environment

### Environment Setup

**Hardware**:
- Framework 16 (x86_64 AMD)
- 64GB RAM
- Ubuntu 24.04 LTS

**Software**:
- Zig 0.15.2
- Basin Kernel (RISC-V, runs in VM)
- VM Runtime (x86_64 native)
- JIT Compiler (x86_64 native)

### Memory Layout

```
┌─────────────────────────────────────┐
│  Host Memory (x86_64)               │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  JIT Code Buffer               │ │  ← Executable (x86_64)
│  │  (RWX memory)                   │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  VM Memory                     │ │  ← Guest Memory (RISC-V)
│  │  (RISC-V code + data)          │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  Basin Kernel                  │ │  ← RISC-V Kernel
│  │  (RISC-V code)                 │ │
│  └───────────────────────────────┘ │
└─────────────────────────────────────┘
```

### Code Buffer Management

**Requirements**:
- Executable memory (RWX permissions)
- Page-aligned allocation (4096 bytes)
- Memory protection (write-protect after compilation)
- Code buffer size limits (MAX_JIT_CODE_SIZE)

**Implementation**:
```zig
// In JIT compiler (jit.zig)
const MAX_JIT_CODE_SIZE: u64 = 16 * 1024 * 1024; // 16MB

fn allocate_code_buffer(self: *JitContext) ![]u8 {
    // Allocate executable memory
    const size = MAX_JIT_CODE_SIZE;
    const aligned_size = std.mem.alignForward(size, 4096);
    
    // Use platform-specific memory allocation
    const code = try self.host.allocate_executable_memory(aligned_size);
    
    // Set memory protection (RWX initially, RX after compilation)
    try self.host.set_memory_protection(code, .read_write_execute);
    
    return code;
}
```

---

## Coordination Points

### With Agent 3a (Basin Kernel)

**Coordination Needs**:
- ✅ Syscall interface documentation (COMPLETE)
- ✅ Syscall argument validation requirements
- ✅ Return value encoding format
- ✅ Error handling patterns

**Coordination Timeline**:
- **Step 1 (THIS WEEK)**: Agent 3a distributes syscall docs
- **Step 2 (WEEK 1-2)**: Agent 3b implements JIT with syscall integration

### With Agent 3c (System Integration)

**Coordination Needs**:
- Multi-architecture testing framework
- Framework x86_64 test runner
- Performance benchmarking infrastructure

**Coordination Timeline**:
- **Step 5 (WEEK 1-2)**: Agent 3c implements multi-arch testing framework
- **After Step 2**: Agent 3b coordinates testing with Agent 3c

### With Vantage 3 Subcore (L1 Parent)

**Coordination Needs**:
- Approval for JIT integration approach
- Integration planning guidance
- Performance requirements

**Coordination Timeline**:
- **This Week**: Vantage 3 Subcore provides integration planning (this document)
- **Step 2 (WEEK 1-2)**: Vantage 3 Subcore coordinates JIT implementation

---

## Implementation Roadmap

### Phase 1: ECALL Fallback (Week 1-2)

**Tasks**:
1. ✅ Receive syscall interface docs from Agent 3a (Step 1)
2. Implement ECALL detection in JIT compiler
3. Implement interpreter fallback for ECALL
4. Integrate with Basin Kernel `handle_syscall()`
5. Test syscall execution from JIT-compiled code

**Success Criteria**:
- ✅ ECALL instructions detected correctly
- ✅ Interpreter fallback works correctly
- ✅ Syscalls execute successfully from JIT code
- ✅ Return values handled correctly

### Phase 2: ECALL JIT-Compiled (Future)

**Tasks**:
1. Implement syscall stub generation
2. Implement register mapping (RISC-V → x86_64)
3. Implement return value encoding/decoding
4. Optimize syscall performance
5. Test performance improvements

**Success Criteria**:
- ✅ Syscall stubs generated correctly
- ✅ Register mapping works correctly
- ✅ Performance improved (target: < 30 cycles per syscall)
- ✅ All tests passing

---

## Success Criteria

### Week 1 Success
- ✅ ECALL detection implemented
- ✅ Interpreter fallback working
- ✅ Basic syscall execution from JIT code

### Week 2 Success
- ✅ All syscall types working from JIT code
- ✅ Error handling working correctly
- ✅ Performance benchmarks completed

### Future Success
- ✅ ECALL JIT-compiled (Phase 2) if needed
- ✅ Performance targets met (< 1ms syscall latency)
- ✅ Multi-architecture testing passing

---

## Risks and Mitigations

### Risk 1: Syscall Integration Complexity

**Mitigation**: Start with Phase 1 (ECALL fallback), optimize later with Phase 2

### Risk 2: Performance on Framework x86_64

**Mitigation**: Benchmark early, optimize hot paths, consider Phase 2 if needed

### Risk 3: Error Handling Complexity

**Mitigation**: Use interpreter for error handling initially, optimize later

---

## Summary

**Integration Approach**:
1. **Phase 1 (Recommended)**: ECALL fallback to interpreter
2. **Phase 2 (Future)**: ECALL JIT-compiled for performance

**Key Integration Points**:
- JIT compiler detects ECALL instructions
- Interpreter handles syscall execution
- Basin Kernel provides syscall interface
- VM Runtime manages state transitions

**Testing Strategy**:
- Unit tests for ECALL detection and handling
- Integration tests for syscall execution
- Framework x86_64 testing for real hardware

**Coordination**:
- Agent 3a: Syscall interface docs (Step 1)
- Agent 3b: JIT implementation (Step 2)
- Agent 3c: Multi-arch testing (Step 5)

---

**Date**: 2026-01-02-083246-pst  
**Agent**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**Status**: ✅ **INTEGRATION PLANNING COMPLETE** — Ready to support Agent 3b JIT implementation

