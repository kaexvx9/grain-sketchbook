# Debug Test 164 - Automated Scripts

These scripts automate debugging the runtime crash (signal 11) in test 164.

## Available Scripts

### 1. `debug_test_164.sh` (Recommended)
**Full GDB automation** - Builds test with debug symbols and runs GDB automatically.

```bash
./scripts/debug_test_164.sh
```

**What it does:**
- Builds test 164 with debug symbols
- Finds the test executable
- Creates and runs a GDB script automatically
- Captures stack trace, registers, and memory state
- Saves output to `docs/core-coordination/YYYY-MM-DD-HHMMSS-utc_test_164_gdb_trace.txt`

**Requirements:** GDB installed

---

### 2. `debug_test_164_direct.sh` (Alternative)
**Direct build approach** - Builds test 164 directly, bypassing build.zig.

```bash
./scripts/debug_test_164_direct.sh
```

**What it does:**
- Builds test 164 directly (avoids other test compilation errors)
- Uses GDB or LLDB if available
- Falls back to direct execution if no debugger

**Use when:** Other tests have compilation errors

---

### 3. `debug_test_164_alternative.sh` (macOS/LLVM)
**LLDB version** - Uses LLDB instead of GDB.

```bash
./scripts/debug_test_164_alternative.sh
```

**What it does:**
- Same as `debug_test_164.sh` but uses LLDB
- Better for macOS/LLVM systems

**Requirements:** LLDB installed

---

### 4. `debug_test_164_simple.sh` (Minimal)
**Simple tools** - Uses strace/valgrind/dmesg.

```bash
./scripts/debug_test_164_simple.sh
```

**What it does:**
- Uses system tools (strace, valgrind, dmesg)
- No debugger required
- Good for quick checks

**Requirements:** strace or valgrind installed

---

## Quick Start

```bash
# Try the recommended script first
./scripts/debug_test_164.sh

# If that fails due to other test errors, use direct build
./scripts/debug_test_164_direct.sh

# Check the output file
cat docs/core-coordination/*_test_164_*_trace.txt | less
```

## Output Files

All scripts save output to:
```
docs/core-coordination/YYYY-MM-DD-HHMMSS-utc_test_164_*_trace.txt
```

## What to Look For

In the output, look for:
- **Backtrace** (`bt` or `thread backtrace`) - Shows call stack at crash
- **Signal 11** or **SIGSEGV** - Confirms segmentation fault
- **Instruction at PC** - Shows what code was executing
- **Registers** - Shows CPU state at crash
- **Memory at PC** - Shows memory contents at crash point

## Manual Debugging

If scripts don't work, debug manually:

```bash
# Build with debug symbols
zig build test -Doptimize=Debug

# Find test executable
find .zig-cache -name "test" -type f -executable | head -1

# Run with GDB
gdb --args .zig-cache/o/.../test --test-filter "164_end_to_end_integration_test.test.process lifecycle: spawn integration"

# In GDB:
(gdb) run
(gdb) bt          # Backtrace when crash occurs
(gdb) info frame  # Current frame info
(gdb) x/10i $pc   # Instructions at program counter
```

## Troubleshooting

**Script fails to find test executable:**
- Check if test compiled: `ls -la .zig-cache/o/*/test`
- Try direct build: `./scripts/debug_test_164_direct.sh`

**GDB not available:**
- Use LLDB script: `./scripts/debug_test_164_alternative.sh`
- Or use simple script: `./scripts/debug_test_164_simple.sh`

**Build errors:**
- Use direct build script: `./scripts/debug_test_164_direct.sh`
- Or fix compilation errors first

**No crash detected:**
- Test might have been fixed
- Or crash is intermittent - run multiple times
