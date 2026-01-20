# Basin-Grainscript Integration Roadmap

## Current State (Rye v0.6.0)

**Kernel Boot Path**:
1. `entry.S` → `kmain()` in `main.zig`
2. `main.zig` runs inline ASM REPL (basic commands: h, i, v, c, e)
3. No Grainscript execution yet

**Grainscript Shell** (`kernel_shell.ry`):
- Full interpreter integration via `eval` command
- Uses `FixedBufferAllocator` (64KB) for freestanding mode
- Built as separate RISC-V64 executable (`kernel-shell-rv64`)
- Designed to be spawned as process by kernel

**Current Limitations**:
- `main.zig` uses pure inline ASM (RV64 codegen workaround)
- No process loading in minimal kernel boot
- `kernel_shell` needs to be loaded as ELF process

## Integration Options

### Option A: Inline Grainscript in kmain (Recommended for Alpha)

Replace the inline ASM REPL with a Zig-based Grainscript REPL.

**Pros**:
- Immediate Grainscript evaluation
- No process loader needed
- Single binary kernel

**Cons**:
- Requires fixing RV64 freestanding codegen issues
- May need more inline ASM wrappers

**Implementation**:
```zig
// main.zig - simplified
pub export fn kmain() noreturn {
    Uart.print("Basin Kernel v0.1.0\n");
    
    // Garden-allocated buffer (static, bounded)
    var repl_garden: [64 * 1024]u8 = undefined;
    var allocator = std.heap.FixedBufferAllocator.init(&repl_garden);
    
    // Run Grainscript REPL
    grainscript_repl(allocator.allocator());
    
    while (true) { asm volatile ("wfi"); }
}
```

### Option B: Process-Based Shell (Full OS)

Load `kernel_shell` as first userspace process.

**Pros**:
- Proper OS architecture
- Process isolation
- Tests full process management

**Cons**:
- Requires ELF loader integration
- More complex boot sequence
- Longer development path

**Implementation**:
1. Kernel boots to scheduler
2. Spawn `kernel_shell` as PID 1
3. Shell runs Grainscript interpreter
4. Shell can spawn additional processes

### Option C: Hybrid (Pragmatic)

Use Zig REPL with inline ASM I/O wrappers.

**Pros**:
- Works around RV64 codegen issues
- Can use Grainscript for logic
- Minimal changes to current code

**Implementation**:
```zig
// uart_asm.zig - inline ASM wrappers
pub inline fn getc() u8 {
    return asm volatile (
        \\lui t1, 0x10000
        \\.Lwait: lbu t2, 5(t1)
        \\andi t2, t2, 1
        \\beqz t2, .Lwait
        \\lbu %[ret], 0(t1)
        : [ret] "=r" (-> u8),
        :
    );
}

pub inline fn putc(c: u8) void {
    asm volatile (
        \\lui t1, 0x10000
        \\sb %[byte], 0(t1)
        :
        : [byte] "r" (c),
    );
}
```

## Recommended Path

**Phase 1: Option C** (This Session)
- Create `uart_asm.ry` with inline ASM wrappers
- Integrate with `kernel_shell.ry` for REPL I/O
- Test Grainscript `eval` command in kernel

**Phase 2: Option A** (Next Session)
- Replace inline ASM REPL with Zig/Rye REPL
- Full Grainscript as default shell
- Single kernel binary

**Phase 3: Option B** (Future)
- Process-based shell architecture
- ELF loader integration
- Multi-process OS

## Garden Allocation Pattern

All Grainscript components use garden allocation:

```rye
// Bounded memory plots for interpreter
const LEXER_GARDEN_SIZE: u32 = 8 * 1024;   // 8KB tokens
const PARSER_GARDEN_SIZE: u32 = 16 * 1024; // 16KB AST
const INTERP_GARDEN_SIZE: u32 = 32 * 1024; // 32KB runtime

// Each component gets a fixed plot from the kernel garden
pub fn create_interpreter_garden() [64 * 1024]u8 {
    return undefined; // Stack-allocated garden
}
```

This ensures:
- No dynamic allocation failures
- Predictable memory usage
- Bounds-checked at compile time
- Toroidal buffer reuse when full

## Testing Strategy

1. **Unit Tests**: 249/249 passing (x86_64)
2. **VM Test**: `kernel-vm-test` boots and reaches REPL
3. **QEMU Test**: `scripts/qemu_rv64.sh` for interactive testing
4. **Integration**: `eval "42 + 8"` should return `50`
