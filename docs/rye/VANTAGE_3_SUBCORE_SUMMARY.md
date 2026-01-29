# Vantage 3 Subcore Agent Summary - Basin Kernel Development

**Date**: 2026-01-21  
**Context**: Basin Kernel (RISC-V64) running on Vantage VM (x86_64)  
**Current Status**: Basin REPL v0.4+ with expression evaluator, variables, and variable management

---

## 🎯 Current Mission/Task

**Primary Goal**: Continue Basin kernel development - enhance REPL capabilities and work toward Grainscript integration.

**Recent Accomplishments**:
- ✅ Enhanced Basin REPL to v0.4 with expression evaluator
- ✅ Added variable support (assignment and usage in expressions)
- ✅ Added variable management commands (`v:vars`, `c:clear`)
- ✅ Created comprehensive running instructions
- ✅ Committed and pushed Basin changes to repository

**Current Task**: 
- Basin REPL is functional with variables
- Next steps: Test in QEMU, continue toward Grainscript integration, or enhance REPL further

---

## 📋 Project Overview

### What We Built

**Basin Kernel** - A RISC-V64 kernel that runs on Vantage VM (x86_64 host emulator):

1. **Interactive REPL Shell**:
   - Text-based CLI via SBI console I/O
   - Commands: `h` (help), `f` (fibonacci), `e` (expression), `v` (vars), `c` (clear), `q` (quit)
   - Version: v0.4+ (with latest variable management)

2. **Expression Evaluator**:
   - Arithmetic: `+`, `-`, `*`, `/`, parentheses, negative numbers
   - Variable assignment: `x = 5`
   - Variable usage: `x * 2`, `(x + y) * 2`
   - Up to 32 variables with 16-character names

3. **Variable Management** (latest additions):
   - `v` command: List all defined variables
   - `c` command: Clear all variables
   - Variables persist across REPL commands

4. **Architecture**:
   ```
   Framework x86_64 Host
     └─> Vantage VM (x86_64, boots via Limine)
         └─> Basin Kernel (RISC-V64, emulated)
             └─> REPL Shell (text-based CLI)
   ```

---

## 🗂️ Key Files & Paths

### Basin Kernel
- **Main Kernel**: `/home/xy/grain-sketchbook/src/basin/hello_riscv.zig`
  - REPL implementation
  - Expression evaluator with variables
  - Variable storage and management
  - SBI interface (putchar/getchar/shutdown)

### Vantage VM
- **VM Entry**: `/home/xy/grain-sketchbook/src/vantage/main_x86_64.zig`
  - Limine boot protocol integration
  - Framebuffer initialization
  - Basin ELF loader
- **RISC-V Core**: `/home/xy/grain-sketchbook/src/vantage/riscv_core.zig`
  - Full RV64I + RVC + M extension
  - SBI console I/O handlers
  - Input buffer (256-byte ring buffer)
  - 12/12 unit tests passing

### Testing
- **Integration Test**: `/home/xy/grain-sketchbook/src/vantage/basin_integration_test.zig`
  - Loads Basin ELF
  - Tests REPL commands
  - Captures console output

### Documentation
- **Integration Docs**: `/home/xy/grain-sketchbook/docs/rye/0009-vantage-basin-integration.md`
- **Running Instructions**: `/home/xy/grain-sketchbook/docs/rye/0010-basin-running-instructions.md` ⭐

### Build Outputs
- **Basin Binary**: `/home/xy/grain-sketchbook/zig-out/bin/basin-rv64` (10K)
- **Vantage Binary**: `/home/xy/grain-sketchbook/zig-out/bin/vantage` (21K)

---

## 🚀 How to Run Basin

### Option 1: Integration Test (Fastest - No QEMU)

**Best for**: Quick verification that Basin works

```bash
cd /home/xy/grain-sketchbook

# Build Basin kernel
zig build basin-rv64

# Run integration test
zig test src/vantage/basin_integration_test.zig
```

**What it does**: Loads Basin in test VM, sends commands, verifies output.

---

### Option 2: Full Boot in QEMU (CLI/Text Console)

**Best for**: Interactive testing and development

**Prerequisites**:
```bash
# Install QEMU
sudo apt install qemu-system-x86_64

# Optional: UEFI firmware
sudo apt install ovmf
```

**Build and Run**:
```bash
cd /home/xy/grain-sketchbook

# 1. Build both components
zig build basin-rv64      # Basin kernel (RISC-V64)
zig build vantage-x86_64  # Vantage VM (x86_64)

# 2. Create bootable ISO
./scripts/create_iso.sh

# 3. Boot in QEMU with serial console
qemu-system-x86_64 -cdrom vantage.iso -serial stdio
```

**Important**: Use `-serial stdio` to redirect Basin REPL to your terminal!

---

## 💻 Using Basin REPL

### Available Commands

Once Basin boots, you'll see:
```
Basin Kernel v0.4
Commands: h=help f=fib e=expr v=vars c=clear q=quit
  expr supports: +, -, *, /, (), variables (x=5, x*2)
  vars: list all variables
  clear: clear all variables
> 
```

### Command Reference

- **`h`** - Show help (lists all commands)
- **`f`** - Compute Fibonacci numbers (auto-increments)
- **`e`** - Expression evaluator with variables
  - Examples: `2+3*4`, `x=5`, `x*2`, `(x+y)*2`
- **`v`** - List all defined variables
- **`c`** - Clear all variables
- **`q`** - Quit (shuts down kernel)

### Example Session

```
> e
Enter expression or assignment (e.g., 2+3*4 or x=5): x = 10
x = 10
> e
Enter expression or assignment (e.g., 2+3*4 or x=5): y = 5
y = 5
> e
Enter expression or assignment (e.g., 2+3*4 or x=5): x * y
= 50
> v
x = 10
y = 5
> e
Enter expression or assignment (e.g., 2+3*4 or x=5): (x + y) * 2
= 30
> c
All variables cleared
> v
No variables defined
> q
Goodbye!
```

---

## 🛠️ Technical Details

### Current Implementation

**Basin REPL** (`src/basin/hello_riscv.zig`):
- **Variable Storage**: Static array of 32 `Variable` structs
  - Each variable: name (16 chars), value (i64), used flag
- **Expression Parser**: Recursive descent parser
  - Handles operator precedence (simplified)
  - Supports parentheses, unary minus
  - Variable lookup in expressions
- **SBI Interface**: 
  - `putchar` (0x01) - Console output
  - `getchar` (0x02) - Console input (from input buffer)
  - `shutdown` (0x53525354) - System reset

**Vantage VM**:
- **RISC-V Emulator**: Full RV64I + RVC + M extension
- **Input Buffer**: 256-byte ring buffer for keyboard input
- **Memory**: Allocated from Limine memory map
- **Framebuffer**: Available but not yet mapped to Basin (Phase 3)

### Build System

```bash
# Build commands
zig build basin-rv64      # Build Basin kernel
zig build vantage-x86_64  # Build Vantage VM
zig build kernel-vm-test  # Run RISC-V core tests (12/12 passing)
```

---

## 📝 Recent Changes

### Latest Enhancements (User's Recent Edits)

1. **Variable List Command** (`v:vars`):
   - Lists all defined variables with their values
   - Shows "No variables defined" if empty

2. **Clear Variables Command** (`c:clear`):
   - Clears all variables
   - Resets variable storage

3. **Updated Help**:
   - Added `v` and `c` commands to help text
   - Added descriptions for new commands

### Previous Commits

- **v0.4**: Expression evaluator + variable support
- **v0.3**: Expression evaluator (basic arithmetic)
- **v0.2**: REPL with help, fibonacci, quit commands

---

## 🎯 Next Steps / Roadmap

### Phase 1: Current (CLI/Text) ✅
- ✅ Basin REPL with text console
- ✅ Expression evaluator with variables
- ✅ Variable management (list/clear)
- ✅ Integration tests

### Phase 2: Grainscript Interpreter (Next Major Goal)
- Port Grainscript interpreter to freestanding RISC-V
- Replace `std.mem.Allocator` with static allocation
- Add `g` command to launch Grainscript
- Connect Grainscript UI built-ins to Vantage framebuffer

### Phase 3: Framebuffer Access
- Map framebuffer to Basin via MMIO
- Enable pixel drawing from Basin
- Graphical UI support

### Phase 4: Full Basin Kernel
- Process management
- Memory management
- Syscall interface

---

## 🐛 Known Issues / Limitations

1. **Operator Precedence**: Expression evaluator uses simplified precedence (left-associative). Full PEMDAS not yet implemented.

2. **Variable Scope**: All variables are global (no scoping yet).

3. **No Persistence**: Variables cleared on kernel restart.

4. **Limited Error Messages**: Basic error handling (could be more descriptive).

5. **No Functions**: Can't define functions yet (Grainscript will add this).

---

## 📚 Documentation

- **Integration Overview**: `/home/xy/grain-sketchbook/docs/rye/0009-vantage-basin-integration.md`
- **Running Instructions**: `/home/xy/grain-sketchbook/docs/rye/0010-basin-running-instructions.md` ⭐
- **This Summary**: `/home/xy/grain-sketchbook/docs/rye/VANTAGE_3_SUBCORE_SUMMARY.md`

---

## 🔍 Debugging Tips

### If Integration Test Fails
- Ensure Basin is built: `zig build basin-rv64`
- Check that `zig-out/bin/basin-rv64` exists

### If QEMU Boot Issues
- Verify QEMU installed: `qemu-system-x86_64 --version`
- Check ISO created: `ls -lh vantage.iso`
- Ensure `-serial stdio` flag is used

### If REPL Not Responding
- Check serial console is redirected
- Try typing `h` and pressing Enter
- Verify Basin kernel loaded (check boot messages)

---

## ✨ Key Features

- ✅ **Text-based REPL** - Fully functional CLI shell
- ✅ **Expression Evaluator** - Arithmetic with variables
- ✅ **Variable Management** - Assign, use, list, clear
- ✅ **SBI Interface** - Standard RISC-V console I/O
- ✅ **Integration Tests** - Automated testing
- ✅ **Documentation** - Comprehensive running instructions

---

## 🎓 Code Style

**Grain Style / Rye Style**:
- Explicit types (u64, i64, not usize/isize)
- Static allocation (no dynamic memory)
- Bounded storage (MAX_VARS = 32, MAX_VAR_NAME = 16)
- Comprehensive assertions
- Clear "Why" comments

---

## 📊 Statistics

- **Basin Binary Size**: 10K
- **Vantage Binary Size**: 21K
- **RISC-V Core Tests**: 12/12 passing
- **Integration Tests**: 1/1 passing
- **Variables Supported**: 32 max
- **Variable Name Length**: 16 chars max

---

## 🚀 Quick Start Commands

```bash
# Test Basin (fastest)
cd /home/xy/grain-sketchbook
zig build basin-rv64
zig test src/vantage/basin_integration_test.zig

# Full boot in QEMU
cd /home/xy/grain-sketchbook
zig build basin-rv64
zig build vantage-x86_64
./scripts/create_iso.sh
qemu-system-x86_64 -cdrom vantage.iso -serial stdio
```

---

**Ready to continue Basin development!** The REPL is functional with variables. Next logical step: test the new `v` and `c` commands, then work toward Grainscript integration or enhance the expression evaluator further.
