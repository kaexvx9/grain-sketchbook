# RISC-V Issue 2: Kernel Usage Analysis

**Date**: 20260122.193500.rye  
**Status**: 🔍 **ANALYSIS** — Actual kernel usage patterns examined  
**Finding**: Real usage patterns identified, comprehensive test created

---

## Actual Kernel Usage Patterns

### Debug.kprint() Call Sites

**Location**: `src/kernel/trap.zig`, `src/kernel/kernel_shell.zig`

**Common Patterns**:

1. **Single u64 with {x}**:
   ```zig
   Debug.kprint("kernel: illegal instr PC=0x{x}\n", .{pc});
   ```

2. **Two u64 with {x}**:
   ```zig
   Debug.kprint("kernel: misaligned PC=0x{x} addr=0x{x}\n", .{ pc, val });
   ```

3. **Enum + u64 with {d} and {x}**:
   ```zig
   Debug.kprint("kernel: exc {d} PC=0x{x}\n", .{ @intFromEnum(exc), pc });
   ```

4. **String with {s}**:
   ```zig
   Debug.kprint("Unknown command: {s}\n", .{command});
   ```

5. **Simple string**:
   ```zig
   Debug.kprint("Grainscript Shell 20260121.194401.grainscript (Basin Kernel)\n", .{});
   ```

---

## Debug.kprint() Implementation Analysis

### Complete Pattern

**Location**: `src/kernel/debug.zig` lines 34-143

**Components**:
1. Runtime format string parsing
2. Runtime index selection with `inline for`
3. Type-dependent operations (`print_int`, `print_hex`)
4. `@typeInfo` usage for type checking

**Key Functions**:
- `kprint()` - Main function with runtime parsing
- `print_arg()` - Runtime index + inline for + type-dependent
- `print_hex_arg()` - Runtime index + inline for + type-dependent
- `print_int()` - Type-dependent integer printing
- `print_hex()` - Type-dependent hex printing

---

## Test Case Created

### debug_kprint_pattern.zig

**Purpose**: Test the complete Debug.kprint() pattern

**Includes**:
- Runtime format parsing simulation
- Runtime index + inline for pattern
- Type-dependent operations (`print_int`, `print_hex`)
- `@typeInfo` usage
- All actual kernel usage patterns

**Test Patterns**:
- Single u64 with {x}
- Two u64 with {x}
- String with {s}
- Int with {d}
- Enum with {d}

**Status**: Created, waiting for sync and compilation

---

## Potential Issue Areas

### Area 1: Type-Dependent Operations

**Functions**: `print_int()`, `print_hex()`

**Operations**:
- `@typeInfo(@TypeOf(val))` - Type introspection
- Type-dependent logic (signed/unsigned)
- Runtime loops with type-dependent operations

**Potential Issue**: Type introspection or type-dependent codegen might fail for freestanding.

### Area 2: @typeInfo Usage

**Usage**: `@typeInfo(@TypeOf(val))`

**Potential Issue**: `@typeInfo` might not work correctly for freestanding, or might generate incorrect code.

### Area 3: Combination of Patterns

**Pattern**: Runtime index + inline for + type-dependent + @typeInfo

**Potential Issue**: The combination of all these might cause issues even though each works individually.

---

## Next Steps

### Immediate

1. **Compile Comprehensive Test**
   - Wait for sync
   - Compile `debug_kprint_pattern.zig`
   - Verify if it reproduces the issue

2. **Analyze Results**
   - If test fails: Identifies exact issue
   - If test passes: Issue is kernel-specific

### Short-Term

3. **Test Type-Dependent Operations**
   - Test `@typeInfo` usage
   - Test type-dependent codegen
   - Verify for freestanding

4. **Kernel Integration Testing**
   - Test actual `Debug.kprint()` in kernel
   - Compare with test results
   - Identify differences

---

## Key Insights

### What We Know

1. ✅ All general patterns work
2. ✅ Runtime index + inline for works
3. 🔍 Type-dependent operations need testing
4. 🔍 `@typeInfo` usage needs testing
5. 🔍 Combination needs testing

### What We Need

1. 🔍 Comprehensive test compilation results
2. 🔍 Type-dependent operation analysis
3. 🔍 `@typeInfo` codegen analysis
4. 🔍 Kernel integration testing

---

## References

- **Real Code**: `src/kernel/debug.zig` lines 34-143
- **Usage Sites**: `src/kernel/trap.zig`, `src/kernel/kernel_shell.zig`
- **Real Code Analysis**: `docs/rye/0049-riscv-issue2-real-code-analysis.md`

---

**Date**: 20260122.193500.rye  
**Status**: 🔍 **ANALYSIS** — Kernel usage patterns identified, comprehensive test created

**Next Action**: Compile comprehensive test, analyze type-dependent operations.
