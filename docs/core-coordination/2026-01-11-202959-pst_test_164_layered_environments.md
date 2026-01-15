# Test 164: Layered Test Environments

**Date**: 2026-01-11-202959-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Break down FullStackTestEnv into smaller, focused test environments  
**Status**: ✅ **IMPLEMENTED** — Smaller environments created, test updated

---

## Problem

`FullStackTestEnv` initializes everything at once:
- VM (8MB memory array)
- Kernel (~76KB users array)
- Integration
- Supervisor
- ServiceManager
- Executor
- ShellEnvironment
- JobManager
- ArenaAllocator

This causes stack overflow issues and makes tests harder to debug.

---

## Solution: Layered Test Environments

Created 5 smaller test environments, each focused on specific layers:

### 1. **VMOnlyTestEnv** (Smallest)
- **Contains**: VM only
- **Use**: VM-only tests (register operations, memory access, etc.)
- **Size**: ~8MB (just VM)

### 2. **VMKernelTestEnv**
- **Contains**: VM + Kernel
- **Use**: Kernel syscall tests that don't need integration layer
- **Size**: ~8MB + ~76KB

### 3. **VMKernelIntegrationTestEnv** (Used by failing test)
- **Contains**: VM + Kernel + Integration
- **Use**: Integration tests (VM-Kernel communication)
- **Size**: ~8MB + ~76KB + small
- **Current test uses this**: `test "process lifecycle: spawn integration"`

### 4. **InitSystemTestEnv**
- **Contains**: Supervisor + ServiceManager
- **Use**: Init system tests (service management, no VM/Kernel needed)
- **Size**: Small (no VM)

### 5. **ShellTestEnv**
- **Contains**: Supervisor + ServiceManager + Executor + Environment + JobManager
- **Use**: Shell tests (command execution, no VM/Kernel needed)
- **Size**: Small (no VM)

### 6. **FullStackTestEnv** (Largest - use sparingly)
- **Contains**: Everything
- **Use**: Only for tests that truly need all layers
- **Size**: ~8MB + ~76KB + everything else

---

## Benefits

1. **Easier debugging**: Smaller environments = fewer moving parts
2. **Faster tests**: Less initialization overhead
3. **Clearer intent**: Test environment shows what layers are being tested
4. **Reduced stack pressure**: Smaller environments = less stack usage
5. **Better isolation**: Test one layer at a time

---

## Migration Strategy

1. ✅ Created smaller test environments
2. ✅ Updated first test to use `VMKernelIntegrationTestEnv`
3. ⏳ Migrate other tests to use appropriate smaller environments
4. ⏳ Keep `FullStackTestEnv` only for tests that truly need everything

---

## Test Environment Selection Guide

| Test Type | Use This Environment |
|-----------|---------------------|
| VM register/memory tests | `VMOnlyTestEnv` |
| Kernel syscall tests | `VMKernelTestEnv` |
| VM-Kernel integration tests | `VMKernelIntegrationTestEnv` |
| Init system tests | `InitSystemTestEnv` |
| Shell command tests | `ShellTestEnv` |
| Full end-to-end tests | `FullStackTestEnv` |

---

## Files Modified

- `tests/164_end_to_end_integration_test.zig`: Added 5 smaller test environments, updated first test

---

## Status

✅ **Smaller environments created**  
✅ **First test migrated**  
⏳ **Remaining tests**: Can be migrated as needed
