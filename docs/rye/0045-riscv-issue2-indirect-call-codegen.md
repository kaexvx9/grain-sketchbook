# RISC-V Issue 2: Indirect Call Codegen Analysis

**Date**: 20260122.192500.rye  
**Status**: 🔍 **ANALYSIS** — Indirect call codegen implementation  
**Finding**: Codegen handles function pointers correctly

---

## Indirect Call Codegen Implementation

### Function Pointer Call Handling

**Location**: `src/arch/riscv64/CodeGen.zig` lines 5015-5029

**Key Code**:
```zig
} else {
    assert(func.typeOf(callee).zigTypeTag(zcu) == .pointer);
    const addr_reg, const addr_lock = try func.allocReg(.int);
    defer func.register_manager.unlockReg(addr_lock);
    try func.genSetReg(Type.u64, addr_reg, .{ .air_ref = callee });

    _ = try func.addInst(.{
        .tag = .jalr,
        .data = .{ .i_type = .{
            .rd = .ra,
            .rs1 = addr_reg,
            .imm12 = Immediate.s(0),
        } },
    });
}
```

**Observations**:
1. ✅ Detects function pointer (`.pointer` type)
2. ✅ Allocates register for function address
3. ✅ Loads function pointer into register
4. ✅ Uses `JALR` instruction (correct for indirect calls)
5. ✅ Sets return address register (`.ra`)

**Conclusion**: Indirect call codegen looks correct.

---

## JALR Instruction

### RISC-V JALR Instruction

**Format**: `JALR rd, rs1, imm12`

**Semantics**:
- Jump to address in `rs1` + `imm12`
- Store return address in `rd`
- Used for indirect function calls

**Codegen Usage**:
- `rd = .ra` (return address register)
- `rs1 = addr_reg` (function pointer register)
- `imm12 = 0` (no offset)

**Conclusion**: Instruction usage is correct.

---

## Direct vs Indirect Calls

### Direct Function Calls

**Location**: `src/arch/riscv64/CodeGen.zig` lines 4978-4995

**Code**:
```zig
.func => |func_val| {
    // ...
    try func.genSetReg(Type.u64, .ra, .{ .lea_symbol = .{ .sym = sym_index } });
    _ = try func.addInst(.{
        .tag = .jalr,
        .data = .{ .i_type = .{
            .rd = .ra,
            .rs1 = .ra,
            .imm12 = Immediate.s(0),
        } },
    });
}
```

**Observations**:
- Uses `lea_symbol` to get function address
- Uses same `JALR` instruction
- Sets `.ra` register with function address

### Indirect Function Calls

**Location**: `src/arch/riscv64/CodeGen.zig` lines 5015-5029

**Code**:
```zig
assert(func.typeOf(callee).zigTypeTag(zcu) == .pointer);
const addr_reg, const addr_lock = try func.allocReg(.int);
try func.genSetReg(Type.u64, addr_reg, .{ .air_ref = callee });
_ = try func.addInst(.{
    .tag = .jalr,
    .data = .{ .i_type = .{
        .rd = .ra,
        .rs1 = addr_reg,
        .imm12 = Immediate.s(0),
    } },
});
```

**Observations**:
- Allocates separate register for function pointer
- Loads function pointer from AIR reference
- Uses `JALR` with function pointer register

**Conclusion**: Both direct and indirect calls use correct codegen.

---

## Potential Issues

### Issue 1: Function Pointer Loading

**Question**: Is the function pointer correctly loaded into the register?

**Check**: `genSetReg` with `.air_ref` should load the function pointer value.

**Potential Problem**: If `.air_ref` doesn't correctly load the function pointer, the call will fail.

### Issue 2: Register Allocation

**Question**: Is the register correctly allocated and used?

**Check**: Register allocation and locking looks correct.

**Potential Problem**: If register is clobbered before use, call will fail.

### Issue 3: Calling Convention

**Question**: Is the calling convention correct for indirect calls?

**Check**: Same calling convention as direct calls.

**Potential Problem**: If calling convention differs, parameters might be wrong.

---

## Test Case Compilation

### Expected Behavior

**If Codegen is Correct**:
- ✅ Tests compile successfully
- ✅ Function pointers loaded correctly
- ✅ `JALR` instructions generated correctly
- ✅ No invalid instructions

**If Codegen is Incorrect**:
- ⚠️ Tests may compile but generate incorrect code
- ⚠️ Function pointers may not be loaded correctly
- ⚠️ `JALR` may use wrong register
- ⚠️ Invalid instructions generated

---

## Next Steps

### Immediate

1. **Compile Test Cases**
   - Compile `indirect_function_call.zig`
   - Compile `vtable_dispatch.zig`
   - Analyze compilation results

2. **Analyze Generated Code**
   - Check function pointer loading
   - Verify `JALR` instruction usage
   - Check for invalid instructions

### Short-Term

3. **Trace Function Pointer Flow**
   - Trace from AIR to codegen
   - Verify function pointer loading
   - Check register allocation

4. **Compare with Working Targets**
   - Compare indirect call codegen
   - Identify differences
   - Find freestanding-specific issues

---

## Key Insights

### What Looks Correct

1. ✅ Function pointer detection (`.pointer` type)
2. ✅ Register allocation for function address
3. ✅ `JALR` instruction usage
4. ✅ Return address handling

### What Needs Verification

1. 🔍 Function pointer loading (`.air_ref` handling)
2. 🔍 Register usage (no clobbering)
3. 🔍 Calling convention (parameter passing)
4. 🔍 Generated code correctness

---

## References

- **genCall**: `src/arch/riscv64/CodeGen.zig` lines 4842-5039
- **Indirect Calls**: `src/arch/riscv64/CodeGen.zig` lines 5015-5029
- **Direct Calls**: `src/arch/riscv64/CodeGen.zig` lines 4978-4995

---

**Date**: 20260122.192500.rye  
**Status**: 🔍 **ANALYSIS** — Codegen looks correct, needs verification

**Next Action**: Compile test cases, verify generated code, trace function pointer flow.
