# Framework 16 Testing Environment Guide

**Date**: 2026-01-02-083246-pst  
**Agent**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**Purpose**: Comprehensive testing environment guide for Framework 16 (x86_64 AMD) with Ubuntu 24.04 LTS  
**Target**: Supports Step 5 (Agent 3c multi-arch testing framework)

---

## Executive Summary

This document provides a comprehensive guide for setting up and using the Framework 16 testing environment for Grain OS sevenos testing. It covers test execution environment setup, multi-architecture testing considerations, performance testing, debugging test failures, test result reporting, and CI/CD integration.

**Key Topics**:
- Test execution environment setup
- Multi-architecture testing (ARM64, x86_64 AMD, x86_64 Intel)
- Performance testing on Framework x86_64
- Debugging test failures
- Test result reporting and analysis
- CI/CD integration considerations

---

## Test Execution Environment Setup

### Prerequisites

**Required Software**:
```bash
# Install testing dependencies
sudo apt install -y \
    gdb \
    valgrind \
    perf \
    strace \
    ltrace \
    hyperfine \
    jq \
    python3 \
    python3-pip

# Install Python testing tools (if needed)
pip3 install pytest pytest-html
```

**Environment Variables**:
```bash
# Add to ~/.bashrc or ~/.zshrc
export TEST_RESULTS_DIR="$HOME/test_results"
export TEST_TIMEOUT=30  # seconds
export TEST_PARALLEL_JOBS=$(nproc)

# Create test results directory
mkdir -p "$TEST_RESULTS_DIR"
```

### Test Execution Scripts

**Basic Test Execution**:
```bash
#!/bin/bash
# Run all tests on Framework x86_64
set -euo pipefail

# Build tests
zig build test

# Run tests with summary
zig build test --summary all

# Run specific test
zig build test --test-filter test_name
```

**Framework x86_64 Test Runner**:
```bash
#!/bin/bash
# tools/run_tests_framework_x86_64.sh
# Framework x86_64 Test Runner Script
set -euo pipefail

ARCHITECTURE="${ARCHITECTURE:-amd}"  # Default to AMD (Framework 16)
TEST_FILTER="${TEST_FILTER:-}"       # Optional test filter
OUTPUT_DIR="${OUTPUT_DIR:-./test_results}"  # Test results directory

# Create output directory
mkdir -p "$OUTPUT_DIR"

# Execute tests via Zig test runner
zig build test --summary all

# Generate test report
TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REPORT_FILE="$OUTPUT_DIR/test_results_${ARCHITECTURE}_${TIMESTAMP}.json"

# Generate JSON report (placeholder)
echo "{\"architecture\": \"$ARCHITECTURE\", \"timestamp\": \"$TIMESTAMP\"}" > "$REPORT_FILE"

# Report results
echo "Test execution complete."
echo "Results: $REPORT_FILE"
```

---

## Multi-Architecture Testing

### Architecture Support Matrix

| Architecture | Platform | Use Case | Priority |
|-------------|----------|----------|----------|
| **ARM64** | macOS (MacBook Air M2) | Development/testing | HIGH |
| **x86_64 AMD** | Framework 16 Ubuntu | Primary deployment target | HIGH |
| **x86_64 Intel** | Legacy hardware | Dispatch software deployment | HIGH |

### Architecture Detection

**Runtime Architecture Detection**:
```zig
// In test framework
const builtin = @import("builtin");

/// Detect current test architecture.
/// Why: Determine which architecture tests are running on.
pub fn detect_test_architecture() TestArchitecture {
    return switch (builtin.cpu.arch) {
        .aarch64 => .arm64,
        .x86_64 => {
            // Distinguish AMD vs Intel via CPUID
            const vendor = detect_cpu_vendor();
            return switch (vendor) {
                .amd => .x86_64_amd,
                .intel => .x86_64_intel,
                .unknown => .x86_64_amd, // Default to AMD (Framework 16)
            };
        },
        else => .unknown,
    };
}
```

**Architecture-Specific Test Filtering**:
```zig
/// Execute architecture-specific tests.
/// Why: Run tests that are specific to Framework x86_64.
test "Framework x86_64: architecture-specific tests" {
    const arch = detect_test_architecture();
    
    // Only run on x86_64 architectures
    if (arch != .x86_64_amd and arch != .x86_64_intel) {
        return; // Skip on non-x86_64 architectures
    }
    
    // Execute Framework x86_64 specific tests
    test_framework_x86_64_features();
}
```

### Cross-Architecture Test Comparison

**Compare Test Results**:
```bash
# Run tests on ARM64 (MacBook Air M2)
zig build test > arm64_results.txt

# Run tests on Framework x86_64 AMD
zig build test > x86_64_amd_results.txt

# Compare results
diff arm64_results.txt x86_64_amd_results.txt
```

**Test Result Aggregation**:
```zig
/// Compare test results across architectures.
/// Why: Validate test behavior is consistent across architectures.
pub fn compare_test_results(
    arm64_results: TestResults,
    x86_64_amd_results: TestResults,
    x86_64_intel_results: ?TestResults,
) !ComparisonReport {
    // Compare test results
    // Assert: Test counts should match (postcondition)
    std.debug.assert(arm64_results.total_tests == x86_64_amd_results.total_tests);
    
    // Generate comparison report
    return ComparisonReport{
        .arm64 = arm64_results,
        .x86_64_amd = x86_64_amd_results,
        .x86_64_intel = x86_64_intel_results,
    };
}
```

---

## Performance Testing

### Benchmarking Setup

**Performance Testing Tools**:
```bash
# Install hyperfine for benchmarking
sudo apt install -y hyperfine

# Benchmark single command
hyperfine './zig-out/bin/graincard'

# Compare multiple builds
hyperfine \
    './zig-out/bin/graincard-debug' \
    './zig-out/bin/graincard-release'

# Benchmark with warmup
hyperfine --warmup 3 './zig-out/bin/graincard'
```

### CPU Performance Profiling

**perf Profiling**:
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

# Generate flamegraph
perf script | stackcollapse-perf.pl | flamegraph.pl > flamegraph.svg
```

**CPU Frequency Scaling**:
```bash
# Check CPU frequency scaling
cpupower frequency-info

# Set to performance mode (for consistent benchmarking)
sudo cpupower frequency-set -g performance

# Set back to ondemand (for normal use)
sudo cpupower frequency-set -g ondemand
```

### Memory Performance Profiling

**Memory Profiling**:
```bash
# Use valgrind massif for memory profiling
valgrind --tool=massif ./zig-out/bin/graincard
ms_print massif.out.* > massif_report.txt

# Use heaptrack for heap profiling
heaptrack ./zig-out/bin/graincard
heaptrack_gui heaptrack.*.gz
```

**Memory Benchmarking**:
```bash
# Monitor memory usage during test execution
/usr/bin/time -v ./zig-out/bin/graincard

# Track memory allocations
valgrind --tool=massif --massif-out-file=massif.out ./zig-out/bin/graincard
```

### Performance Targets

**Performance Requirements**:
- **Syscall Latency**: < 1ms per syscall
- **JIT Compilation**: < 100ms per block
- **Test Execution**: < 30 seconds per test
- **Memory Usage**: < 4MB per process (default VM memory)

**Performance Validation**:
```zig
/// Validate performance requirements.
/// Why: Ensure system meets performance targets.
test "performance: syscall latency" {
    const start_time = std.time.nanoTimestamp();
    
    // Execute syscall
    try kernel.handle_syscall(...);
    
    const end_time = std.time.nanoTimestamp();
    const latency_ns = @as(u64, @intCast(end_time - start_time));
    const latency_ms = latency_ns / 1_000_000;
    
    // Assert: Latency must be < 1ms
    try std.testing.expect(latency_ms < 1);
}
```

---

## Debugging Test Failures

### Test Failure Analysis

**Common Failure Patterns**:
1. **Compilation Errors**: Check Zig version, build configuration
2. **Runtime Errors**: Check memory access, null pointers
3. **Timeout Errors**: Check test execution time, increase timeout
4. **Architecture-Specific Errors**: Check architecture detection, CPU features

**Debugging Workflow**:
```bash
# 1. Run test with verbose output
zig build test --summary all --test-filter test_name

# 2. Run with GDB
gdb --args zig build test --test-filter test_name

# 3. Run with valgrind (memory errors)
valgrind --leak-check=full zig build test --test-filter test_name

# 4. Run with strace (system calls)
strace zig build test --test-filter test_name
```

### Test Logging

**Structured Logging**:
```zig
/// Test logging helper.
/// Why: Provide structured logging for test debugging.
pub fn log_test_event(
    test_name: []const u8,
    event: []const u8,
    data: ?[]const u8,
) void {
    const timestamp = std.time.nanoTimestamp();
    std.debug.print("[{d}] {s}: {s}", .{ timestamp, test_name, event });
    
    if (data) |d| {
        std.debug.print(": {s}\n", .{d});
    } else {
        std.debug.print("\n", .{});
    }
}
```

**Test Result Logging**:
```bash
# Log test results to file
zig build test --summary all 2>&1 | tee test_results.log

# Filter for failures
grep -i "fail\|error" test_results.log

# Count test results
grep -c "PASS\|FAIL" test_results.log
```

### Core Dump Analysis

**Enable Core Dumps**:
```bash
# Enable core dumps
ulimit -c unlimited
echo "kernel.core_pattern=/tmp/core.%e.%p.%h.%t" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Analyze core dump
gdb ./zig-out/bin/graincard /tmp/core.graincard.*
```

---

## Test Result Reporting

### Test Result Formats

**JSON Report Format**:
```json
{
  "architecture": "x86_64_amd",
  "timestamp": "2026-01-02T08:32:46Z",
  "total_tests": 100,
  "passed_tests": 95,
  "failed_tests": 5,
  "results": [
    {
      "test_name": "test_syscall_spawn",
      "passed": true,
      "duration_ns": 1000000,
      "architecture": "x86_64_amd"
    },
    {
      "test_name": "test_jit_compilation",
      "passed": false,
      "duration_ns": 5000000,
      "error_message": "JIT compilation failed",
      "architecture": "x86_64_amd"
    }
  ]
}
```

**Human-Readable Report**:
```
Framework x86_64 Test Results
==============================
Architecture: x86_64_amd
Timestamp: 2026-01-02T08:32:46Z

Total Tests: 100
Passed: 95
Failed: 5

Failed Tests:
  - test_jit_compilation (JIT compilation failed)
  - test_syscall_timeout (Timeout exceeded)
  - test_memory_allocation (Out of memory)
  - test_process_spawn (Process spawn failed)
  - test_resource_limits (Resource limit exceeded)

Performance:
  Average Test Duration: 1.5ms
  Longest Test: test_jit_compilation (5ms)
  Shortest Test: test_syscall_basic (0.1ms)
```

### Test Result Analysis

**Result Aggregation**:
```bash
# Aggregate test results from multiple runs
jq -s '.[] | .results[]' test_results_*.json | jq -s 'group_by(.test_name)'

# Compare test results across architectures
diff <(jq '.results' arm64_results.json) <(jq '.results' x86_64_amd_results.json)

# Generate test coverage report
zig build test --summary all | grep -E "PASS|FAIL" | sort | uniq -c
```

**Performance Analysis**:
```bash
# Analyze test execution times
jq '.results[] | select(.duration_ns > 1000000) | {test_name, duration_ns}' test_results.json

# Find slowest tests
jq '.results | sort_by(.duration_ns) | reverse | .[0:10]' test_results.json
```

---

## CI/CD Integration

### GitHub Actions Integration

**GitHub Actions Workflow**:
```yaml
# .github/workflows/framework-x86-64-tests.yml
name: Framework x86_64 Tests

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Install Zig
        run: |
          wget https://ziglang.org/download/0.15.2/zig-linux-x86_64-0.15.2.tar.xz
          tar -xf zig-linux-x86_64-0.15.2.tar.xz
          sudo mv zig-linux-x86_64-0.15.2 /usr/local/zig-0.15.2
          echo "$/usr/local/zig-0.15.2" >> $GITHUB_PATH
      
      - name: Run Tests
        run: |
          zig build test --summary all
      
      - name: Upload Test Results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-results
          path: test_results/
```

### Test Result Artifacts

**Artifact Generation**:
```bash
# Generate test artifacts
mkdir -p test_artifacts
cp test_results.json test_artifacts/
cp test_results.log test_artifacts/
cp -r core_dumps/ test_artifacts/ 2>/dev/null || true

# Archive artifacts
tar -czf test_artifacts.tar.gz test_artifacts/
```

---

## Best Practices

### Test Organization

**Test Directory Structure**:
```
tests/
├── unit/              # Unit tests
├── integration/       # Integration tests
├── framework_x86_64/  # Framework x86_64 specific tests
├── performance/       # Performance tests
└── architecture/      # Architecture-specific tests
```

### Test Naming Conventions

**Test Naming**:
```zig
// Unit test
test "component: feature_name" {
    // Test implementation
}

// Integration test
test "integration: component_a_component_b" {
    // Test implementation
}

// Framework x86_64 specific test
test "framework_x86_64: feature_name" {
    // Test implementation
}

// Performance test
test "performance: feature_name" {
    // Test implementation
}
```

### Test Isolation

**Test Isolation Requirements**:
- Each test should be independent
- Tests should not depend on execution order
- Tests should clean up after themselves
- Tests should not share global state

**Test Cleanup**:
```zig
/// Test cleanup helper.
/// Why: Ensure tests clean up resources properly.
pub fn cleanup_test(test_name: []const u8) void {
    // Clean up test resources
    // Remove temporary files
    // Reset global state
    // Free allocated memory
}
```

---

## Troubleshooting

### Common Issues

**Issue: Tests timeout**
```bash
# Solution: Increase test timeout
export TEST_TIMEOUT=60  # seconds

# Or in test code
test "long_running_test" {
    // Set timeout in test
    const timeout_ns = 60 * 1_000_000_000; // 60 seconds
    // ...
}
```

**Issue: Tests fail on Framework x86_64 but pass on ARM64**
```bash
# Solution: Check architecture-specific code
# Verify CPU feature detection
# Check endianness assumptions
# Verify memory alignment

# Debug with architecture detection
zig build test --test-filter test_name 2>&1 | grep -i architecture
```

**Issue: Performance tests fail**
```bash
# Solution: Check CPU frequency scaling
cpupower frequency-info
sudo cpupower frequency-set -g performance

# Check system load
htop

# Check for background processes
ps aux | grep -v grep
```

**Issue: Memory tests fail**
```bash
# Solution: Check memory limits
ulimit -v  # Check virtual memory limit
ulimit -m  # Check physical memory limit

# Increase memory limits if needed
ulimit -v unlimited
ulimit -m unlimited
```

---

## Summary

**Framework 16 Testing Environment**:
- ✅ Test execution environment setup complete
- ✅ Multi-architecture testing support (ARM64, x86_64 AMD, x86_64 Intel)
- ✅ Performance testing tools and workflows
- ✅ Debugging tools and techniques
- ✅ Test result reporting and analysis
- ✅ CI/CD integration ready

**Key Advantages**:
- Native x86_64 test execution (no emulation)
- High RAM capacity for parallel test execution
- Excellent debugging and profiling tools
- Multi-architecture test comparison support

**Next Steps**:
- Set up testing environment following this guide
- Run initial test suite on Framework x86_64
- Compare results with ARM64 execution
- Begin multi-architecture testing framework implementation

---

**Date**: 2026-01-02-083246-pst  
**Agent**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore)  
**Status**: ✅ **TESTING ENVIRONMENT GUIDE COMPLETE** — Ready to support Agent 3c multi-arch testing framework

