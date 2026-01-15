#!/bin/bash
# Alternative: Use lldb instead of GDB (for macOS/LLVM)
# Why: Some systems prefer lldb over GDB
# Usage: ./scripts/debug_test_164_alternative.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== Debug Test 164 - Automated LLDB Stack Trace ==="
echo ""

# Step 1: Build test with debug symbols
echo "Step 1: Building test with debug symbols..."
zig build test -Doptimize=Debug 2>&1 | tee /tmp/test_164_build.log || {
    echo "ERROR: Build failed. Check /tmp/test_164_build.log"
    exit 1
}

# Step 2: Find the test executable
echo ""
echo "Step 2: Finding test executable..."
TEST_EXE=$(find .zig-cache -name "test" -type f -executable | grep -E "(164|end_to_end)" | head -1)

if [ -z "$TEST_EXE" ]; then
    TEST_EXE=$(find .zig-cache -name "test" -type f -executable | head -1)
    if [ -z "$TEST_EXE" ]; then
        echo "ERROR: Could not find test executable"
        exit 1
    fi
    echo "WARNING: Using generic test executable: $TEST_EXE"
else
    echo "Found test executable: $TEST_EXE"
fi

# Step 3: Create LLDB script
echo ""
echo "Step 3: Creating LLDB script..."
LLDB_SCRIPT=$(mktemp)
cat > "$LLDB_SCRIPT" << 'LLDBEOF'
# LLDB script for test 164 crash debugging
settings set target.process.stop-on-shared-library-events false
settings set stop-disassembly-count 20

# Run the test
run --test-filter "164_end_to_end_integration_test.test.process lifecycle: spawn integration"

# If it crashes, get backtrace
process status
thread backtrace all
frame select 0
frame variable
disassemble --pc

quit
LLDBEOF

echo "LLDB script created: $LLDB_SCRIPT"

# Step 4: Run LLDB
echo ""
echo "Step 4: Running LLDB..."
OUTPUT_FILE="$PROJECT_ROOT/docs/core-coordination/$(date -u +"%Y-%m-%d-%H%M%S-utc")_test_164_lldb_trace.txt"

lldb -s "$LLDB_SCRIPT" "$TEST_EXE" 2>&1 | tee "$OUTPUT_FILE"

# Step 5: Check results
echo ""
echo "Step 5: Analyzing results..."
if grep -q "signal 11\|SIGSEGV\|Segmentation fault\|EXC_BAD_ACCESS" "$OUTPUT_FILE"; then
    echo "✅ Crash detected! Stack trace saved to: $OUTPUT_FILE"
    echo ""
    echo "=== Summary ==="
    grep -A 10 "signal 11\|SIGSEGV\|Segmentation fault" "$OUTPUT_FILE" | head -20 || true
    echo ""
    echo "Full trace: $OUTPUT_FILE"
else
    echo "⚠️  Check output: $OUTPUT_FILE"
fi

# Cleanup
rm -f "$LLDB_SCRIPT"

echo ""
echo "=== Debug session complete ==="
