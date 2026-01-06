#!/bin/bash
# RISC-V Environment Setup Script (Grain Style - No QEMU)
# Date: 2026-01-05-170300-pst
# Purpose: Set up RISC-V64 build and Vantage VM Runtime for Framework x86_64

set -e

echo "=== RISC-V Environment Setup (Grain Style) ==="
echo "Date: $(date +"%Y-%m-%d-%H%M%S-pst")"
echo "Architecture: RISC-V64 → Vantage VM Runtime (JIT) → Framework Ubuntu x86_64"

# Check for Zig RISC-V64 target
if command -v zig &> /dev/null; then
    echo "✅ Zig is installed"
    ZIG_VERSION=$(zig version)
    echo "   Version: $ZIG_VERSION"
    echo "   Testing RISC-V64 target support..."
    if zig targets 2>/dev/null | grep -q riscv64; then
        echo "   ✅ RISC-V64 target supported"
    else
        echo "   ⚠️  RISC-V64 target check (may need Zig 0.15.2)"
    fi
else
    echo "⚠️  Zig not found"
    echo "   Install Zig 0.15.2 for RISC-V64 support"
    echo "   Download: https://ziglang.org/download/"
fi

# Check for Vantage VM Runtime
if [ -f "src/kernel_vm/jit.zig" ]; then
    echo "✅ Vantage VM Runtime found (src/kernel_vm/jit.zig)"
    echo "   JIT compilation: RISC-V64 → x86_64"
else
    echo "⚠️  Vantage VM Runtime not found"
    echo "   Expected: src/kernel_vm/jit.zig"
fi

# Create RISC-V build script
echo "📝 Creating RISC-V64 build configuration..."
cat > autonomous/scripts/build/build_riscv64.sh << 'BUILD_SCRIPT'
#!/bin/bash
# Build for RISC-V64 target (Grain Style - No QEMU)
# Usage: ./build_riscv64.sh [optimize]

OPTIMIZE=${1:-Debug}

echo "Building for RISC-V64 (Grain Style)"
echo "Target: riscv64-linux-gnu"
echo "Optimize: $OPTIMIZE"
echo "Runtime: Vantage VM (JIT RISC-V → x86_64)"

zig build -Dtarget=riscv64-linux-gnu -Doptimize=$OPTIMIZE

echo "✅ Build complete"
echo "   Binary will run via Vantage VM Runtime on Framework x86_64"
BUILD_SCRIPT

chmod +x autonomous/scripts/build/build_riscv64.sh

# Create Vantage VM run script
echo "📝 Creating Vantage VM runtime script..."
cat > autonomous/scripts/test/run_vantage_vm.sh << 'VM_SCRIPT'
#!/bin/bash
# Run RISC-V64 binary via Vantage VM Runtime
# Usage: ./run_vantage_vm.sh [binary]

BINARY=${1:-zig-out/bin/grainscript-shell}

if [ ! -f "$BINARY" ]; then
    echo "❌ Binary not found: $BINARY"
    echo "   Build first: zig build -Dtarget=riscv64-linux-gnu"
    exit 1
fi

echo "Running via Vantage VM Runtime (JIT: RISC-V64 → x86_64)"
echo "Binary: $BINARY"

# Run via Vantage VM (when implemented)
# For now, this is a placeholder
echo "⚠️  Vantage VM Runtime execution (to be implemented)"
echo "   Architecture: RISC-V64 binary → JIT → x86_64 execution"
VM_SCRIPT

chmod +x autonomous/scripts/test/run_vantage_vm.sh

echo "=== Setup Complete (Grain Style - No QEMU) ==="
echo "Architecture:"
echo "  1. Build for RISC-V64: ./autonomous/scripts/build/build_riscv64.sh"
echo "  2. Run via Vantage VM: ./autonomous/scripts/test/run_vantage_vm.sh"
echo "  3. JIT compilation: RISC-V64 → x86_64 (Framework Ubuntu)"

