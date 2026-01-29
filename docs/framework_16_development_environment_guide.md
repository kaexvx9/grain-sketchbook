# Framework 16 Development Environment Guide

**Date**: 2026-01-02-083246-pst  
**Agent**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**Purpose**: Comprehensive development environment guide for Framework 16 (x86_64 AMD) with Ubuntu 24.04 LTS  
**Target**: All agents working on Framework Ubuntu x86 development

---

## Executive Summary

This document provides a comprehensive guide for setting up and using the Framework 16 development environment for Grain OS sevenos development. It covers hardware specifications, Ubuntu 24.04 LTS setup, Zig 0.15.2 installation, build system configuration, development workflow, debugging tools, and performance optimization.

**Key Topics**:
- Framework 16 hardware specifications
- Ubuntu 24.04 LTS installation and configuration
- Zig 0.15.2 installation and setup
- Build system configuration for x86_64
- Development workflow and best practices
- Debugging and profiling tools
- Performance optimization considerations

---

## Hardware Specifications

### Framework 16 (Primary Development Machine)

**Hardware**:
- **Architecture**: x86_64 AMD
- **CPU**: AMD Ryzen (specific model varies by configuration)
- **RAM**: 64GB (vs 24GB on MacBook Air M2)
- **Storage**: NVMe SSD (varies by configuration)
- **Display**: Framework 16 display module (varies by configuration)
- **Modularity**: Repairable/upgradeable design (Framework philosophy)

**Advantages**:
- ✅ High RAM capacity (64GB) for parallel builds and testing
- ✅ Native x86_64 development (no emulation needed)
- ✅ Repairable/upgradeable hardware
- ✅ Open-source firmware support
- ✅ Excellent for multi-architecture testing

**Use Cases**:
- Primary development environment for Framework Ubuntu x86
- Native x86_64 JIT compilation testing
- Multi-architecture testing (x86_64 AMD, x86_64 Intel)
- Performance benchmarking and profiling

### Legacy Intel Hardware (Secondary Target)

**Hardware**:
- **Architecture**: x86_64 Intel
- **CPU**: Various Intel processors (legacy systems)
- **RAM**: Variable (typically 8-16GB)
- **OS**: Ubuntu 24.04 LTS (or compatible)

**Use Cases**:
- Dispatch software deployment on existing first-responder systems
- Legacy hardware compatibility testing
- Performance testing on older hardware

---

## Ubuntu 24.04 LTS Setup

### Installation

**Installation Steps**:
1. Download Ubuntu 24.04 LTS ISO from [ubuntu.com](https://ubuntu.com/download)
2. Create bootable USB drive
3. Boot Framework 16 from USB
4. Follow Ubuntu installation wizard
5. Configure disk partitioning (recommended: separate `/home` partition)
6. Set up user account and password
7. Complete installation and reboot

**Post-Installation Configuration**:
```bash
# Update system packages
sudo apt update
sudo apt upgrade -y

# Install essential development tools
sudo apt install -y \
    build-essential \
    git \
    curl \
    wget \
    vim \
    tmux \
    htop \
    tree \
    jq

# Install additional tools
sudo apt install -y \
    gdb \
    valgrind \
    perf \
    strace \
    ltrace \
    file \
    binutils

# Configure git (if not already done)
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### System Configuration

**Enable Development Tools**:
```bash
# Enable core dumps for debugging
ulimit -c unlimited
echo "kernel.core_pattern=/tmp/core.%e.%p.%h.%t" | sudo tee -a /etc/sysctl.conf

# Increase file descriptor limits
echo "* soft nofile 65536" | sudo tee -a /etc/security/limits.conf
echo "* hard nofile 65536" | sudo tee -a /etc/security/limits.conf

# Enable performance monitoring
echo "kernel.perf_event_paranoid=1" | sudo tee -a /etc/sysctl.conf
```

**Configure Shell** (if using zsh):
```bash
# Install zsh (if not already installed)
sudo apt install -y zsh

# Install oh-my-zsh (optional)
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Configure .zshrc
cat >> ~/.zshrc << 'EOF'
# Zig path
export PATH="$HOME/zig:$PATH"

# Development aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias gs='git status'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate'
EOF
```

---

## Zig 0.15.2 Installation

### Installation from Official Release

**Why Official Release?**
- Official releases are the canonical source for reproducibility
- Version pinning is more explicit with official releases
- Grain Style emphasizes determinism: everyone should use identical binaries

**Installation Steps**:
```bash
# Create zig directory
mkdir -p ~/zig

# Download Zig 0.15.2 for x86_64 Linux
cd ~/zig
curl -L https://ziglang.org/download/0.15.2/zig-linux-x86_64-0.15.2.tar.xz -o zig.tar.xz

# Extract
tar -xf zig.tar.xz

# Move to final location
mv zig-linux-x86_64-0.15.2 zig-0.15.2

# Create symlink
ln -sf ~/zig/zig-0.15.2/zig ~/zig/zig

# Add to PATH
echo 'export PATH="$HOME/zig:$PATH"' >> ~/.bashrc
echo 'export PATH="$HOME/zig:$PATH"' >> ~/.zshrc

# Reload shell configuration
source ~/.bashrc  # or source ~/.zshrc
```

**Verify Installation**:
```bash
zig version  # Should output: 0.15.2
which zig    # Should point to ~/zig/zig
zig targets  # Should show x86_64-linux-gnu as available target
```

### Alternative: System Package Manager (Not Recommended)

**Ubuntu Package Manager**:
```bash
# Note: Ubuntu package manager may not have Zig 0.15.2
# Use official release instead (recommended)
sudo apt install zig  # May install different version
```

**Why Not Recommended**:
- Package manager versions may differ from official release
- Less control over version pinning
- Potential compatibility issues

---

## Build System Configuration

### Target Architecture

**Primary Target**: `x86_64-linux-gnu`
- **Host**: x86_64 native (Framework Ubuntu)
- **Kernel Target**: RISC-V (Basin Kernel runs in VM)
- **JIT Target**: x86_64 (VM Runtime compiles RISC-V → x86_64)

**Build Commands**:
```bash
# Build for x86_64 native
zig build

# Build with specific target
zig build -Dtarget=x86_64-linux-gnu

# Build with optimization
zig build -Doptimize=ReleaseFast

# Build and run tests
zig build test

# Build specific executable
zig build graincard
zig build vantage
```

### Build Configuration in build.zig

**Standard Target Options**:
```zig
// In build.zig
const target = b.standardTargetOptions(.{
    .default_target = .{
        .cpu_arch = .x86_64,
        .os_tag = .linux,
        .abi = .gnu,
    },
});

const optimize = b.standardOptimizeOption(.{});
```

**Framework x86_64 Specific Configuration**:
```zig
// Framework x86_64 specific build options
const framework_x86_64_target = std.Target{
    .cpu_arch = .x86_64,
    .os_tag = .linux,
    .abi = .gnu,
    .cpu = .{
        .model = .baseline,
        .features = .{
            // Enable x86_64 features as needed
            .sse2 = true,
            .sse4_1 = true,
            .avx = true,
            .avx2 = true,
        },
    },
};
```

### Build Optimization Levels

**Optimization Options**:
- `Debug` - No optimization, full debugging info
- `ReleaseSafe` - Optimized with safety checks
- `ReleaseFast` - Optimized for speed
- `ReleaseSmall` - Optimized for size

**Usage**:
```bash
# Debug build (default)
zig build

# Release build
zig build -Doptimize=ReleaseFast

# Small release build
zig build -Doptimize=ReleaseSmall
```

---

## Development Workflow

### Repository Setup

**Clone Repository**:
```bash
# Clone xy-mathematics repository
git clone https://codeberg.org/keatonlivermore/grain-sketchbook.git
cd xy-mathematics

# Verify build works
zig build test
```

### Development Cycle

**Typical Workflow**:
1. **Make Changes**: Edit source files
2. **Build**: `zig build` or `zig build test`
3. **Test**: `zig build test` or run specific tests
4. **Debug**: Use debugging tools (gdb, valgrind, perf)
5. **Commit**: `git commit -m "..."` (Grain Style commit messages)
6. **Push**: `git push`

**Grain Style Commit Messages**:
```bash
# Format: <component>: <brief description>
# Example:
git commit -m "vantage_3_subcore: add JIT integration planning document

- Comprehensive integration planning for RISC-V → x86_64 JIT
- ECALL fallback pattern and JIT-compiled pattern
- Error handling and performance considerations
- Testing strategy and Framework x86_64 execution environment

Grain Style: grain_case, u32/u64, grainwrap-100, grain validate-70."
```

### Parallel Builds

**Leveraging 64GB RAM**:
```bash
# Build multiple targets in parallel
zig build graincard &
zig build vantage &
zig build test &
wait

# Or use make -j for parallel builds (if using Makefile)
make -j$(nproc)
```

**Build Cache**:
```bash
# Zig automatically caches build artifacts
# Cache location: ~/.cache/zig/
# Clear cache if needed:
rm -rf ~/.cache/zig/
```

---

## Debugging Tools

### GDB (GNU Debugger)

**Basic Usage**:
```bash
# Compile with debug info
zig build -Doptimize=Debug

# Run with gdb
gdb ./zig-out/bin/graincard

# Common gdb commands:
# (gdb) break main
# (gdb) run
# (gdb) next
# (gdb) step
# (gdb) print variable_name
# (gdb) backtrace
# (gdb) quit
```

**GDB Configuration**:
```bash
# Create ~/.gdbinit for better experience
cat > ~/.gdbinit << 'EOF'
set print pretty on
set print array on
set print array-indexes on
set print elements 0
set history save on
set history size 10000
EOF
```

### Valgrind (Memory Debugging)

**Usage**:
```bash
# Check for memory leaks
valgrind --leak-check=full --show-leak-kinds=all ./zig-out/bin/graincard

# Check for memory errors
valgrind --tool=memcheck ./zig-out/bin/graincard

# Check for undefined behavior
valgrind --tool=helgrind ./zig-out/bin/graincard
```

### perf (Performance Profiling)

**Usage**:
```bash
# Profile CPU usage
perf record ./zig-out/bin/graincard
perf report

# Profile specific events
perf record -e cpu-cycles,instructions,cache-misses ./zig-out/bin/graincard

# Real-time profiling
perf top

# Profile specific function
perf record -g --call-graph dwarf ./zig-out/bin/graincard
perf report --stdio
```

### strace/ltrace (System Call Tracing)

**Usage**:
```bash
# Trace system calls
strace ./zig-out/bin/graincard

# Trace library calls
ltrace ./zig-out/bin/graincard

# Save trace to file
strace -o trace.log ./zig-out/bin/graincard
```

---

## Performance Optimization

### Compiler Optimizations

**Optimization Flags**:
```zig
// In build.zig
const optimize = b.standardOptimizeOption(.{
    .release_safe = .{
        .strip = true,
        .omit_frame_pointer = true,
    },
    .release_fast = .{
        .strip = true,
        .omit_frame_pointer = true,
        .vectorize = true,
    },
});
```

### CPU Feature Detection

**Runtime CPU Feature Detection**:
```zig
// Detect CPU features at runtime
const builtin = @import("builtin");

if (builtin.cpu.features.has(.avx2)) {
    // Use AVX2 optimized code
} else if (builtin.cpu.features.has(.sse4_1)) {
    // Use SSE4.1 optimized code
} else {
    // Fallback to baseline
}
```

### Memory Optimization

**Memory Profiling**:
```bash
# Use valgrind massif for memory profiling
valgrind --tool=massif ./zig-out/bin/graincard
ms_print massif.out.* > massif_report.txt

# Use heaptrack for heap profiling
heaptrack ./zig-out/bin/graincard
heaptrack_gui heaptrack.*.gz
```

### Benchmarking

**Performance Benchmarking**:
```bash
# Use hyperfine for benchmarking
hyperfine './zig-out/bin/graincard'

# Compare multiple builds
hyperfine './zig-out/bin/graincard-debug' './zig-out/bin/graincard-release'

# Use perf for detailed profiling
perf stat ./zig-out/bin/graincard
```

---

## Best Practices

### Code Organization

**Directory Structure**:
```
xy-mathematics/
├── src/              # Source code
├── tests/            # Test files
├── docs/             # Documentation
├── grainstore/       # Grain OS components
│   ├── sevenos/      # sevenos init system and shell
│   └── vantage/      # VM Runtime
├── build.zig         # Build configuration
└── README.md         # Project documentation
```

### Grain Style Compliance

**Requirements**:
- ✅ `grain_case` function names
- ✅ `grainwrap-100` (line length ≤100 characters)
- ✅ `grain validate-70` (function length ≤70 lines)
- ✅ Explicit `u32`/`u64` types (NO `usize`/`isize`)
- ✅ All compiler warnings addressed
- ✅ Bounded allocations with `MAX_` constants
- ✅ Minimum 2 assertions per function

**Validation**:
```bash
# Check line length (grainwrap-100)
# Use editor plugins or scripts to check line length

# Check function length (grain validate-70)
# Use editor plugins or scripts to check function length

# Check for compiler warnings
zig build 2>&1 | grep -i warning
```

### Testing

**Test Execution**:
```bash
# Run all tests
zig build test

# Run specific test
zig build test --test-filter test_name

# Run tests with verbose output
zig build test --summary all

# Run tests in parallel
zig build test -j$(nproc)
```

**Test Organization**:
- Unit tests in `tests/` directory
- Integration tests in `tests/integration/`
- Framework x86_64 specific tests in `tests/framework_x86_64/`

---

## Troubleshooting

### Common Issues

**Issue: Zig not found**
```bash
# Solution: Check PATH
echo $PATH | grep zig
# If not found, add to PATH:
export PATH="$HOME/zig:$PATH"
```

**Issue: Build fails with linker errors**
```bash
# Solution: Install development libraries
sudo apt install -y libc6-dev libstdc++-dev

# Check for missing libraries
ldd ./zig-out/bin/graincard
```

**Issue: Performance issues**
```bash
# Solution: Check CPU frequency scaling
cpupower frequency-info
# Set to performance mode:
sudo cpupower frequency-set -g performance
```

**Issue: Out of memory during builds**
```bash
# Solution: Reduce parallel builds
# Use fewer parallel jobs:
zig build -j4  # Instead of -j$(nproc)
```

---

## Summary

**Framework 16 Development Environment**:
- ✅ Hardware: x86_64 AMD, 64GB RAM, Ubuntu 24.04 LTS
- ✅ Zig 0.15.2: Official release installation
- ✅ Build System: x86_64-linux-gnu target
- ✅ Debugging: GDB, Valgrind, perf, strace/ltrace
- ✅ Performance: Optimization flags, CPU feature detection, profiling

**Key Advantages**:
- High RAM capacity for parallel builds
- Native x86_64 development (no emulation)
- Excellent debugging and profiling tools
- Repairable/upgradeable hardware

**Next Steps**:
- Set up development environment following this guide
- Verify build system works correctly
- Run tests to verify environment
- Begin Framework x86_64 development work

---

**Date**: 2026-01-02-083246-pst  
**Agent**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**Status**: ✅ **DEVELOPMENT ENVIRONMENT GUIDE COMPLETE** — Ready for all agents working on Framework Ubuntu x86

