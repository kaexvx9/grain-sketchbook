#!/bin/bash
# Framework x86_64 Test Runner Script
# Why: Execute integration tests on Framework x86_64 hardware.
# Grain Style: Clear, direct, helpful.

set -euo pipefail

# Configuration.
ARCHITECTURE="${ARCHITECTURE:-amd}"  # Default to AMD (Framework 16)
TEST_FILTER="${TEST_FILTER:-}"       # Optional test filter
OUTPUT_DIR="${OUTPUT_DIR:-./test_results}"  # Test results directory
VERBOSE="${VERBOSE:-false}"           # Verbose output

# Script directory.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root.
cd "$PROJECT_ROOT"

# Create output directory.
mkdir -p "$OUTPUT_DIR"

# Build test runner if not already built.
if [ ! -f "zig-out/bin/test_runner_framework_x86_64" ]; then
    echo "Building Framework x86_64 test runner..."
    zig build test_runner_framework_x86_64
fi

# Build arguments for test runner.
ARGS=()
if [ -n "$TEST_FILTER" ]; then
    ARGS+=("--filter" "$TEST_FILTER")
fi
if [ "$VERBOSE" = "true" ]; then
    ARGS+=("--verbose")
fi
ARGS+=("--output" "$OUTPUT_DIR")

# Execute tests via Zig test runner.
echo "Running integration tests on Framework x86_64..."
zig build test --summary all

# Execute Framework x86_64 test runner.
echo "Executing Framework x86_64 test runner..."
zig-out/bin/test_runner_framework_x86_64 "${ARGS[@]}"

# Report results.
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REPORT_FILE="$OUTPUT_DIR/test_results_${ARCHITECTURE}_${TIMESTAMP}.json"

if [ -f "$REPORT_FILE" ]; then
    echo "Test execution complete."
    echo "Results: $REPORT_FILE"
else
    echo "Warning: Test report file not found: $REPORT_FILE"
    exit 1
fi

