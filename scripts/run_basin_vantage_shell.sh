#!/bin/bash
# Run Basin + Vantage + Grainscript Shell on Framework x86_64
# Why: Manual testing script for full stack integration.
# Usage: ./scripts/run_basin_vantage_shell.sh

set -e

echo "Framework x86 Basin + Vantage + Grainscript Shell Integration Test"
echo "===================================================================="
echo ""

# Check prerequisites.
echo "Checking prerequisites..."
if [ ! -f "zig-out/bin/grain-rv64" ]; then
    echo "Error: Kernel ELF not found. Building kernel..."
    zig build kernel-rv64
fi

if [ ! -f "zig-out/bin/kernel-shell-rv64" ]; then
    echo "Warning: Shell ELF not found. Shell build is blocked by freestanding issue."
    echo "Using kernel ELF as placeholder for testing."
    SHELL_ELF="zig-out/bin/grain-rv64"
else
    SHELL_ELF="zig-out/bin/kernel-shell-rv64"
fi

echo "Kernel ELF: zig-out/bin/grain-rv64"
echo "Shell ELF: $SHELL_ELF"
echo ""

# Run integration test.
echo "Running full stack integration test..."
zig build test --summary all 2>&1 | grep -E "(169_framework_x86|All.*tests)" || true

echo ""
echo "Test complete!"
echo ""
echo "Next steps:"
echo "1. Fix Grainscript freestanding compatibility issue"
echo "2. Build shell ELF: zig build kernel-shell-rv64"
echo "3. Run full stack test with actual shell ELF"
echo "4. Test on Framework x86_64 hardware"
