#!/bin/bash
# Grain OS Build Script
#
# Why: Build complete Grain OS system including kernel, compositor, and applications.
# Coordinates compilation of all components with proper dependencies.
#
# Agent: Vantage 3 (Build System)

set -e

RYE_COMPILER="${RYE_COMPILER:-/home/xy/codeberg/ryelang/rye/zig-out/bin/zig}"
BUILD_DIR="${BUILD_DIR:-build}"
SRC_DIR="${SRC_DIR:-src}"

echo "=== Grain OS Build System ==="
echo ""
echo "Compiler: $RYE_COMPILER"
echo "Build directory: $BUILD_DIR"
echo "Source directory: $SRC_DIR"
echo ""

# Why: Create build directory.
mkdir -p "$BUILD_DIR"

# Why: Build kernel components.
echo "Building kernel components..."
"$RYE_COMPILER" build-lib "$SRC_DIR/basin_kernel/boot/grain_os_init.zig" -o "$BUILD_DIR/grain_os_init.o" || {
    echo "ERROR: Kernel build failed"
    exit 1
}

# Why: Build display subsystem.
echo "Building display subsystem..."
"$RYE_COMPILER" build-lib "$SRC_DIR/basin_kernel/display/shine_bridge.zig" -o "$BUILD_DIR/shine_bridge.o" || {
    echo "ERROR: Display subsystem build failed"
    exit 1
}

# Why: Build Grain Shine compositor.
echo "Building Grain Shine compositor..."
"$RYE_COMPILER" build-lib "$SRC_DIR/grain_core/shine/compositor_core.zig" -o "$BUILD_DIR/compositor_core.o" || {
    echo "ERROR: Compositor build failed"
    exit 1
}

# Why: Build Skate application.
echo "Building Skate application..."
"$RYE_COMPILER" build-exe "$SRC_DIR/grain_skate/gui/skate_app.zig" -o "$BUILD_DIR/skate" || {
    echo "ERROR: Skate build failed"
    exit 1
}

echo ""
echo "=== Build Complete ==="
echo "Outputs in: $BUILD_DIR"