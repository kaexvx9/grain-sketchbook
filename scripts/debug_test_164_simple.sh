#!/bin/bash
# Simple: Just run with strace/valgrind to catch the crash
# Why: Simpler alternative that doesn't require GDB/lldb
# Usage: ./scripts/debug_test_164_simple.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

echo "=== Debug Test 164 - Simple Crash Detection ==="
echo ""

# Build test
echo "Building test..."
zig build test -Doptimize=Debug 2>&1 | tail -5

# Find test executable
TEST_EXE=$(find .zig-cache -name "test" -type f -executable | head -1)
if [ -z "$TEST_EXE" ]; then
    echo "ERROR: Could not find test executable"
    exit 1
fi

# Try different debugging approaches
OUTPUT_FILE="$PROJECT_ROOT/docs/core-coordination/$(date -u +"%Y-%m-%d-%H%M%S-utc")_test_164_simple_trace.txt"

echo ""
echo "=== Option 1: Run with strace (system calls) ==="
if command -v strace &> /dev/null; then
    strace -e trace=memory -o "$OUTPUT_FILE.strace" "$TEST_EXE" --test-filter "164_end_to_end_integration_test.test.process lifecycle: spawn integration" 2>&1 | tee "$OUTPUT_FILE" || true
    echo "strace output: $OUTPUT_FILE.strace"
else
    echo "strace not available, skipping..."
fi

echo ""
echo "=== Option 2: Run with valgrind (memory errors) ==="
if command -v valgrind &> /dev/null; then
    valgrind --leak-check=full --show-leak-kinds=all --track-origins=yes \
        "$TEST_EXE" --test-filter "164_end_to_end_integration_test.test.process lifecycle: spawn integration" 2>&1 | tee "$OUTPUT_FILE.valgrind" || true
    echo "valgrind output: $OUTPUT_FILE.valgrind"
else
    echo "valgrind not available, skipping..."
fi

echo ""
echo "=== Option 3: Run with dmesg (kernel messages) ==="
if [ -w /dev/kmsg ] || [ "$(id -u)" = "0" ]; then
    dmesg -C
    "$TEST_EXE" --test-filter "164_end_to_end_integration_test.test.process lifecycle: spawn integration" 2>&1 || true
    dmesg | tail -20 | tee "$OUTPUT_FILE.dmesg"
    echo "dmesg output: $OUTPUT_FILE.dmesg"
else
    echo "Cannot access dmesg, skipping..."
fi

echo ""
echo "=== Results saved to: $OUTPUT_FILE.* ==="
