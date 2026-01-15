#!/bin/bash
# Direct: Build and debug test 164 directly (bypasses build.zig)
# Why: Avoids other test compilation errors
# Usage: ./scripts/debug_test_164_direct.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== Debug Test 164 - Direct Build & Debug ==="
echo ""

# Step 1: Build test 164 directly with all dependencies
echo "Step 1: Building test 164 directly with debug symbols..."

# Get the build command from build.zig by checking what dependencies test 164 needs
# For now, use a simplified approach: build with minimal deps and let it fail gracefully

TEST_FILE="tests/164_end_to_end_integration_test.zig"
BUILD_DIR=".zig-cache/debug_test_164"
mkdir -p "$BUILD_DIR"

# Try to compile test 164 with debug symbols
echo "Compiling $TEST_FILE..."
zig test -ODebug "$TEST_FILE" \
    --dep kernel_vm \
    --dep basin_kernel \
    --dep grain_core \
    -Mkernel_vm="$PROJECT_ROOT/src/kernel_vm/vm.zig" \
    -Mbasin_kernel="$PROJECT_ROOT/src/kernel/basin_kernel.zig" \
    -Mgrain_core="$PROJECT_ROOT/src/grain_core/root.zig" \
    --cache-dir "$BUILD_DIR" \
    --name test_164_debug \
    -fno-strip \
    --test-filter "process lifecycle: spawn integration" \
    2>&1 | tee /tmp/test_164_direct_build.log

# Check if build succeeded
if [ ${PIPESTATUS[0]} -ne 0 ]; then
    echo ""
    echo "WARNING: Direct build had errors, but continuing..."
    echo "This is expected if dependencies aren't fully resolved."
    echo "Trying alternative: use zig build but filter to test 164 only"
    echo ""
fi

# Step 2: Find or use the test executable
echo ""
echo "Step 2: Finding test executable..."
TEST_EXE=$(find "$BUILD_DIR" -name "test_164_debug" -type f -executable 2>/dev/null | head -1)

if [ -z "$TEST_EXE" ]; then
    # Fallback: use zig build test and find the executable
    echo "Building via zig build test..."
    zig build test -Doptimize=Debug --summary all 2>&1 | grep -E "(164|test)" | head -10 || true
    
    TEST_EXE=$(find .zig-cache -name "test" -type f -executable | head -1)
fi

if [ -z "$TEST_EXE" ] || [ ! -f "$TEST_EXE" ]; then
    echo "ERROR: Could not find test executable"
    echo "Build log: /tmp/test_164_direct_build.log"
    exit 1
fi

echo "Using test executable: $TEST_EXE"
ls -lh "$TEST_EXE"

# Step 3: Run with GDB if available, otherwise just run and capture output
echo ""
echo "Step 3: Running test with debugging..."

OUTPUT_FILE="$PROJECT_ROOT/docs/core-coordination/$(date -u +"%Y-%m-%d-%H%M%S-utc")_test_164_direct_trace.txt"

if command -v gdb &> /dev/null; then
    echo "Using GDB for debugging..."
    
    GDB_SCRIPT=$(mktemp)
    cat > "$GDB_SCRIPT" << 'GDBEOF'
set pagination off
set confirm off
run --test-filter "process lifecycle: spawn integration"
if $_siginfo
    echo \n=== CRASH DETECTED (Signal $_siginfo.si_signo) ===\n
    echo === Backtrace ===\n
    bt 30
    echo \n=== Registers ===\n
    info registers
    echo \n=== Instruction at PC ===\n
    x/20i $pc
    echo \n=== Stack Frame ===\n
    info frame
    echo \n=== Local Variables ===\n
    info locals
    echo \n=== Arguments ===\n
    info args
    echo \n=== Memory at PC ===\n
    x/32x $pc
    echo \n=== Memory at SP ===\n
    x/32x $sp
else
    echo \n=== TEST COMPLETED ===\n
end
quit
GDBEOF

    gdb -batch -x "$GDB_SCRIPT" "$TEST_EXE" 2>&1 | tee "$OUTPUT_FILE"
    rm -f "$GDB_SCRIPT"
    
elif command -v lldb &> /dev/null; then
    echo "Using LLDB for debugging..."
    lldb "$TEST_EXE" -- --test-filter "process lifecycle: spawn integration" \
        -o "thread backtrace all" \
        -o "frame select 0" \
        -o "frame variable" \
        -o "disassemble --pc" \
        -o "quit" 2>&1 | tee "$OUTPUT_FILE"
else
    echo "No debugger found, running test directly..."
    "$TEST_EXE" --test-filter "process lifecycle: spawn integration" 2>&1 | tee "$OUTPUT_FILE" || {
        echo ""
        echo "Test crashed with exit code: $?"
        echo "Output saved to: $OUTPUT_FILE"
    }
fi

# Step 4: Analyze results
echo ""
echo "Step 4: Analyzing results..."
if grep -qE "CRASH DETECTED|signal 11|SIGSEGV|Segmentation fault|EXC_BAD_ACCESS" "$OUTPUT_FILE"; then
    echo "✅ Crash detected! Stack trace saved to: $OUTPUT_FILE"
    echo ""
    echo "=== Crash Summary ==="
    grep -A 10 -E "CRASH DETECTED|signal 11|SIGSEGV" "$OUTPUT_FILE" | head -30
    echo ""
    echo "Full trace: $OUTPUT_FILE"
elif grep -q "TEST COMPLETED\|All tests passed" "$OUTPUT_FILE"; then
    echo "✅ Test completed successfully"
    echo "Output: $OUTPUT_FILE"
else
    echo "⚠️  Check output: $OUTPUT_FILE"
    echo ""
    echo "Last 20 lines:"
    tail -20 "$OUTPUT_FILE"
fi

echo ""
echo "=== Debug session complete ==="
echo "Output file: $OUTPUT_FILE"
