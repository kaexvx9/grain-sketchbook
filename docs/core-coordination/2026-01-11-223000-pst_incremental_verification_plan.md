# Incremental Verification Plan: Basin → Grainscript → QEMU → Vantage

**Date**: 2026-01-11-223000-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Incremental verification plan starting with smaller components  
**Status**: 📋 **PLAN CREATED** — Ready for execution

---

## Strategy: Build Up Incrementally

**Approach**: Verify each layer independently before attempting full stack integration.

**Why This Works**:
- ✅ Isolates issues to specific components
- ✅ Builds confidence in each layer
- ✅ Easier to debug when things break
- ✅ Validates patterns before complex integration

---

## Phase 1: Pure Kernel Tests (No VM)

### Goal
Verify Basin Kernel works in isolation, without VM runtime.

### Tests to Run
1. **Kernel-only tests** (no VM required):
   - `tests/097_file_system_kernel_test.zig` - File system syscalls
   - `tests/023_ipc_channel_test.zig` - IPC channels
   - `tests/038_cow_test.zig` - Copy-on-Write
   - `tests/082_signal_process_group_test.zig` - Signal handling
   - `tests/110_kernel_stats_aggregator_test.zig` - Kernel stats

2. **Kernel initialization tests**:
   - Verify `BasinKernel.init_in_place()` works
   - Test kernel state management
   - Test user management

### Expected Outcome
- ✅ All kernel-only tests pass
- ✅ Kernel can be initialized and used without VM
- ✅ Kernel syscalls work in isolation

### Success Criteria
- All kernel-only tests pass
- No stack overflow issues
- Kernel state is correct

---

## Phase 2: Grainscript Tests (No Kernel/VM)

### Goal
Verify Grainscript interpreter works independently.

### Tests to Run
1. **Grainscript core tests**:
   - `tests/039_grainscript_lexer_test.zig` - Lexer
   - `tests/040_grainscript_parser_test.zig` - Parser
   - `tests/041_grainscript_interpreter_test.zig` - Interpreter
   - `tests/042_grainscript_variable_handling_test.zig` - Variables
   - `tests/043_grainscript_control_flow_test.zig` - Control flow
   - `tests/044_grainscript_type_system_test.zig` - Type system

### Expected Outcome
- ✅ All Grainscript tests pass
- ✅ Grainscript can parse and execute scripts
- ✅ No integration dependencies

### Success Criteria
- All Grainscript tests pass
- Interpreter works correctly
- Ready for kernel integration

---

## Phase 3: Basin + Grainscript Integration (No VM)

### Goal
Verify Basin Kernel and Grainscript work together without VM runtime.

### Tests to Create
1. **Kernel + Grainscript integration**:
   - Grainscript calling kernel syscalls
   - Kernel spawning Grainscript processes
   - IPC between kernel and Grainscript

### Expected Outcome
- ✅ Basin and Grainscript integrate correctly
- ✅ Syscalls work from Grainscript
- ✅ Process management works

### Success Criteria
- Integration tests pass
- No VM runtime needed
- Ready for QEMU testing

---

## Phase 4: QEMU Integration (Basin + Grainscript)

### Goal
Verify Basin Kernel and Grainscript work on QEMU (real RISC-V hardware emulation).

### Setup
1. **Build kernel for QEMU**:
   ```bash
   zig build kernel-rv64
   ```

2. **Run in QEMU**:
   ```bash
   ./run_qemu.sh
   ```

3. **Test Grainscript in QEMU**:
   - Load Grainscript interpreter
   - Execute scripts
   - Verify syscalls work

### Expected Outcome
- ✅ Kernel boots in QEMU
- ✅ Grainscript runs in QEMU
- ✅ Syscalls work correctly
- ✅ Real RISC-V hardware emulation works

### Success Criteria
- QEMU boots successfully
- Grainscript executes in QEMU
- All syscalls work
- Ready for Vantage integration

---

## Phase 5: Vantage Integration (Full Stack)

### Goal
Verify Vantage VM works with Basin Kernel and Grainscript.

### Setup
1. **Use verified components**:
   - Basin Kernel (verified in Phases 1-3)
   - Grainscript (verified in Phases 2-3)
   - QEMU integration (verified in Phase 4)

2. **Test in Vantage VM**:
   - Run Basin Kernel in Vantage
   - Execute Grainscript in Vantage
   - Verify JIT compilation works

### Expected Outcome
- ✅ Vantage VM works with Basin
- ✅ Grainscript runs in Vantage
- ✅ JIT compilation works
- ✅ Full stack integration complete

### Success Criteria
- Vantage boots successfully
- All components work together
- Performance is acceptable
- Ready for production use

---

## Implementation Plan

### Step 1: Run Kernel-Only Tests
```bash
# Test kernel without VM
zig build test --summary all 2>&1 | grep -E "097_file_system_kernel|023_ipc_channel|038_cow"
```

### Step 2: Run Grainscript Tests
```bash
# Test Grainscript independently
zig build test --summary all 2>&1 | grep -E "039_grainscript|040_grainscript|041_grainscript"
```

### Step 3: Create Integration Tests
- Create `tests/165_basin_grainscript_integration_test.zig`
- Test kernel + Grainscript without VM
- Use Grain Style arena pattern

### Step 4: Test QEMU
```bash
# Build and run in QEMU
zig build kernel-rv64
./run_qemu.sh
```

### Step 5: Test Vantage
- Use verified components
- Test full stack integration
- Apply Grain Style patterns

---

## Benefits of This Approach

### 1. Isolation
- Each phase tests one component
- Issues are easier to identify
- No complex dependencies

### 2. Confidence Building
- Each success builds confidence
- Patterns verified incrementally
- Less risk of cascading failures

### 3. Debugging
- Smaller scope = easier debugging
- Clear boundaries between components
- Faster iteration

### 4. Pattern Validation
- Grain Style patterns verified early
- Arena allocators tested in isolation
- Stack overflow issues caught early

---

## Current Status

### ✅ Completed
- Grain Style arena pattern identified
- Pattern verified in simple tests
- All test environments use pointers

### ⏳ Next Steps
1. **Run Phase 1**: Kernel-only tests
2. **Run Phase 2**: Grainscript tests
3. **Create Phase 3**: Integration tests
4. **Test Phase 4**: QEMU integration
5. **Test Phase 5**: Vantage integration

---

## Key Insight

**Start small, build up incrementally.** Verify each component works independently before attempting complex integrations. This approach:
- Reduces risk
- Makes debugging easier
- Builds confidence
- Validates patterns early

**Don't try to test everything at once.** Test one layer at a time, verify it works, then move to the next.

---

## Files to Create

1. **Phase 3 Integration Test**:
   - `tests/165_basin_grainscript_integration_test.zig`
   - Test kernel + Grainscript without VM
   - Use Grain Style arena pattern

2. **QEMU Test Script**:
   - `scripts/test_qemu_basin_grainscript.sh`
   - Automated QEMU testing
   - Verify kernel + Grainscript in QEMU

3. **Vantage Integration Test**:
   - `tests/166_vantage_full_stack_test.zig`
   - Test full stack in Vantage
   - Use verified components

---

## Success Metrics

### Phase 1 Success
- ✅ All kernel-only tests pass
- ✅ No stack overflow
- ✅ Kernel works independently

### Phase 2 Success
- ✅ All Grainscript tests pass
- ✅ Interpreter works correctly
- ✅ Ready for integration

### Phase 3 Success
- ✅ Kernel + Grainscript integration works
- ✅ Syscalls work from Grainscript
- ✅ Ready for QEMU

### Phase 4 Success
- ✅ QEMU boots successfully
- ✅ Grainscript runs in QEMU
- ✅ Ready for Vantage

### Phase 5 Success
- ✅ Vantage works with full stack
- ✅ All components integrated
- ✅ Production ready

---

## Next Action

**Start with Phase 1**: Run kernel-only tests to verify Basin Kernel works independently.
