#!/bin/bash
# Debug Test 164 - Automated GDB Stack Trace Capture
# Why: Automate crash debugging for test 164 runtime crash (signal 11)
# Usage: ./scripts/debug_test_164.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== Debug Test 164 - Automated GDB Stack Trace ==="
echo ""

# Step 1: Build test with debug symbols (only test 164)
echo "Step 1: Building test 164 with debug symbols..."
# Try to build just test 164 by compiling it directly
zig test -ODebug tests/164_end_to_end_integration_test.zig \
    --dep kernel_vm \
    --dep basin_kernel \
    --dep grain_core \
    --dep grain_carry_core \
    --dep grainstore \
    -Mkernel_vm=/home/xy/xy-mathematics/src/kernel_vm/vm.zig \
    -Mbasin_kernel=/home/xy/xy-mathematics/src/kernel/basin_kernel.zig \
    --cache-dir .zig-cache \
    --name test_164 \
    2>&1 | tee /tmp/test_164_build.log || {
    echo "WARNING: Direct build failed, trying zig build test..."
    # Fallback: use zig build but continue even if other tests fail
    zig build test -Doptimize=Debug 2>&1 | tee /tmp/test_164_build.log || true
}

# Step 2: Find the test executable
echo ""
echo "Step 2: Finding test executable..."
# Look for test_164 first (from direct build)
TEST_EXE=$(find .zig-cache -name "test_164" -type f -executable | head -1)

if [ -z "$TEST_EXE" ]; then
    # Fallback: look for test with 164 in path
    TEST_EXE=$(find .zig-cache -name "test" -type f -executable | grep -E "(164|end_to_end)" | head -1)
fi

if [ -z "$TEST_EXE" ]; then
    # Last resort: any test executable
    TEST_EXE=$(find .zig-cache -name "test" -type f -executable | head -1)
    if [ -z "$TEST_EXE" ]; then
        echo "ERROR: Could not find test executable"
        echo "Trying to build test 164 directly..."
        # Build test 164 directly as a workaround
        zig test -ODebug tests/164_end_to_end_integration_test.zig \
            --dep kernel_vm \
            --dep basin_kernel \
            -Mkernel_vm=/home/xy/xy-mathematics/src/kernel_vm/vm.zig \
            -Mbasin_kernel=/home/xy/xy-mathematics/src/kernel/basin_kernel.zig \
            --cache-dir .zig-cache \
            --name test_164_debug \
            -fno-strip \
            -fLLVM \
            -fcompiler-rt \
            --test-filter "process lifecycle: spawn integration" || {
            echo "ERROR: Failed to build test 164"
            exit 1
        }
        TEST_EXE=$(find .zig-cache -name "test_164_debug" -type f -executable | head -1)
    fi
fi

if [ -z "$TEST_EXE" ]; then
    echo "ERROR: Could not find or build test executable"
    exit 1
fi

echo "Found test executable: $TEST_EXE"

# Step 3: Create GDB script
echo ""
echo "Step 3: Creating GDB script..."
GDB_SCRIPT=$(mktemp)
cat > "$GDB_SCRIPT" << 'GDBEOF'
# GDB script for test 164 crash debugging
set pagination off
set confirm off

# Run the test
run

# If it crashes, get backtrace
if $_siginfo
    echo \n=== CRASH DETECTED ===\n
    echo === Backtrace ===\n
    bt 20
    echo \n=== Registers ===\n
    info registers
    echo \n=== Instruction at PC ===\n
    x/10i $pc
    echo \n=== Stack Frame ===\n
    info frame
    echo \n=== Local Variables ===\n
    info locals
    echo \n=== Arguments ===\n
    info args
    echo \n=== Memory at PC ===\n
    x/16x $pc
else
    echo \n=== TEST COMPLETED SUCCESSFULLY ===\n
end

quit
GDBEOF

echo "GDB script created: $GDB_SCRIPT"

# Step 4: Run GDB
echo ""
echo "Step 4: Running GDB..."
OUTPUT_FILE="$PROJECT_ROOT/docs/core-coordination/$(date -u +"%Y-%m-%d-%H%M%S-utc")_test_164_gdb_trace.txt"

# Filter test to only run test 164
TEST_FILTER="164_end_to_end_integration_test.test.process lifecycle: spawn integration"

gdb -batch -x "$GDB_SCRIPT" --args "$TEST_EXE" --test-filter "$TEST_FILTER" 2>&1 | tee "$OUTPUT_FILE"

# Step 5: Check if we got useful output
echo ""
echo "Step 5: Analyzing results..."
if grep -q "CRASH DETECTED\|signal 11\|SIGSEGV\|Segmentation fault" "$OUTPUT_FILE"; then
    echo "✅ Crash detected! Stack trace saved to: $OUTPUT_FILE"
    echo ""
    echo "=== Summary ==="
    grep -A 5 "CRASH DETECTED" "$OUTPUT_FILE" || true
    echo ""
    echo "Full trace: $OUTPUT_FILE"
elif grep -q "TEST COMPLETED SUCCESSFULLY" "$OUTPUT_FILE"; then
    echo "✅ Test completed successfully (no crash)"
    echo "Output: $OUTPUT_FILE"
else
    echo "⚠️  Unexpected output. Check: $OUTPUT_FILE"
fi

# Cleanup
rm -f "$GDB_SCRIPT"

echo ""
echo "=== Debug session complete ==="
