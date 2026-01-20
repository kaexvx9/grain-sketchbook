# Rye

Rye is a systems programming language for Grain OS. It's designed for bare-metal RISC-V64 targets
with compiler-enforced style constraints.

**Version**: 0.4.0

## Phase 1: Transpiler

Currently, Rye is a transpiler that validates `.ry` files against RyeStyle constraints and emits
`.zig` files. This gives us the benefits of Zig's mature backend while enforcing our stricter
requirements at compile time.

## Features (All Implemented)

- **64-line function limit** - Compiler-enforced
- **128-character line limit** - Compiler-enforced
- **Why comments required** - Public functions must have `/// Why:` documentation
- **Zig compatibility** - Rye syntax is a strict subset of Zig
- **Lexer** - Full tokenization of Rye/Zig syntax
- **Parser** - Function detection with doc comment tracking
- **Validator** - All RyeStyle constraints checked
- **Project init** - Scaffold new Rye projects
- **Project stats** - Analyze codebase metrics
- **JSON output** - `--json` flag for CI integration

## Usage

```bash
# Build the compiler
zig build

# Create a new project
./zig-out/bin/rye init myproject

# Check files for RyeStyle compliance
./zig-out/bin/rye check src/*.ry

# View project statistics
./zig-out/bin/rye stats src/*.ry

# Compile to Zig (Phase 1)
./zig-out/bin/rye build src/main.ry
```

## Example

```rye
//! Kernel entry point.
//! Why: Called by bootloader after hardware init.

/// Initialize UART.
/// Why: Required for early boot console output before interrupts are enabled.
pub fn uart_init() void {
    asm volatile {
        lui t1, 0x10000
        // UART setup
    };
}
```

## File Extension

Rye source files use `.ry`:

```
src/
  kernel/
    main.ry
    uart.ry
```

## See Also

- [RyeStyle](../docs/rye_style.md) - The coding style Rye enforces
- [Rye Vision](../docs/rye/0001-rye-language-vision.md) - Language design document
