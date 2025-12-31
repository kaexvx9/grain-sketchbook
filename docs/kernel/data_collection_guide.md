# Performance Data Collection Guide

**Date**: 2025-12-31  
**Agent**: Grain Basin Kernel Agent (3a)  
**Status**: Ready for Execution

---

## Overview

This guide provides step-by-step instructions for collecting performance data using the syscall performance profiler. The data collected will be used to validate code review findings and prioritize optimization work.

---

## Prerequisites

1. ✅ Profiler infrastructure complete
2. ✅ Benchmark tests created
3. ✅ Code review complete
4. ⏳ Compilation issues in other parts of codebase resolved (minor blocker)

---

## Data Collection Workflow

### Step 1: Enable Profiling

```zig
var kernel = BasinKernel.init();
kernel.syscall_profiler.enable();
```

**Verify**: Check that profiling is enabled:
```zig
const summary = kernel.get_profiler_summary();
try testing.expect(summary.enabled);
```

### Step 2: Run Comprehensive Benchmarks

Execute the benchmark test suite:

```bash
zig build test --summary all
```

Or run specific benchmark test:
```bash
zig build test tests/144_syscall_performance_benchmark_test.zig
```

**Test Coverage**:
- ✅ Basic syscall execution (`syscall performance benchmark`)
- ✅ Hot path identification (`identify hot paths`)
- ✅ Slow path identification (`identify slow paths`)
- ✅ Top N hot paths (`get top hot paths`)
- ✅ Top N slow paths (`get top slow paths`)
- ✅ Profiler reset (`profiler reset new measurement`)

### Step 3: Collect Performance Data

After running benchmarks, collect metrics:

```zig
// Get summary statistics
const summary = kernel.get_profiler_summary();
std.debug.print("Total syscalls: {}\n", .{summary.total_syscall_count});
std.debug.print("Total time: {} ns\n", .{summary.total_execution_time_ns});

// Get hot path (most frequently called)
const hot_path = kernel.find_profiler_hot_path();
if (hot_path) |hp| {
    std.debug.print("Hot path: syscall {}, called {} times\n", .{hp.syscall_num, hp.call_count});
}

// Get slow path (highest average execution time)
const slow_path = kernel.find_profiler_slow_path();
if (slow_path) |sp| {
    std.debug.print("Slow path: syscall {}, avg time {} ns\n", .{sp.syscall_num, sp.avg_time_ns});
}

// Get top 10 hot paths
const top_hot = kernel.get_profiler_top_syscalls_by_count(10);
var i: u32 = 0;
while (i < top_hot.count) : (i += 1) {
    const entry = top_hot.entries[i];
    std.debug.print("Hot path {}: syscall {}, called {} times\n", .{i, entry.syscall_num, entry.call_count});
}

// Get top 10 slow paths
const top_slow = kernel.get_profiler_top_syscalls_by_time(10);
i = 0;
while (i < top_slow.count) : (i += 1) {
    const entry = top_slow.entries[i];
    std.debug.print("Slow path {}: syscall {}, avg time {} ns\n", .{i, entry.syscall_num, entry.avg_time_ns});
}
```

### Step 4: Analyze Individual Syscall Metrics

For specific syscalls of interest:

```zig
const syscall_num = @intFromEnum(Syscall.read);
const metrics = kernel.syscall_profiler.get_metrics(syscall_num);
if (metrics) |m| {
    std.debug.print("Syscall {} metrics:\n", .{syscall_num});
    std.debug.print("  Call count: {}\n", .{m.call_count});
    std.debug.print("  Total time: {} ns\n", .{m.total_time_ns});
    std.debug.print("  Average time: {} ns\n", .{m.get_average_time_ns()});
    std.debug.print("  Min time: {} ns\n", .{m.min_time_ns});
    std.debug.print("  Max time: {} ns\n", .{m.max_time_ns});
}
```

---

## Benchmark Scenarios

### Scenario 1: Lightweight Syscalls

Test frequently called, lightweight syscalls:
- `yield` (process scheduling)
- `clock_gettime` (time queries)
- `sysinfo` (system information)
- `health_check` (health monitoring)

**Expected Results**: High call counts, low execution times

### Scenario 2: I/O Operations

Test file and network I/O:
- `read` / `write` (file operations)
- `tcp_send` / `tcp_recv` (network operations)
- `channel_send` / `channel_recv` (IPC operations)

**Expected Results**: Medium call counts, medium execution times (may be hot paths)

### Scenario 3: Heavy Operations

Test complex operations:
- `spawn` (process creation)
- `map` / `unmap` (memory management)
- `tcp_connect` (network connection)

**Expected Results**: Low call counts, high execution times (may be slow paths)

### Scenario 4: Mixed Workload

Test realistic mixed workload:
- Combination of all syscall types
- Varying frequencies (some syscalls called more often)
- Realistic argument patterns

**Expected Results**: Identify actual hot paths and slow paths in realistic scenarios

---

## Data Analysis Checklist

After collecting data, analyze:

### Hot Path Analysis
- [ ] Identify top 10 most frequently called syscalls
- [ ] Check if `read`/`write` are hot paths (validate handle lookup optimization priority)
- [ ] Check if `yield` is hot path (already optimal, no-op)
- [ ] Check if `clock_gettime` is hot path (likely optimal, integration layer)
- [ ] Check if `sysinfo` is hot path (may benefit from caching)

### Slow Path Analysis
- [ ] Identify top 10 slowest syscalls (by average execution time)
- [ ] Check if `spawn` is slow path (validate process lookup optimization)
- [ ] Check if `map`/`unmap` are slow paths (validate mapping lookup optimization)
- [ ] Check if network operations are slow paths (validate timer call optimization)
- [ ] Check if file operations are slow paths (validate handle lookup optimization)

### Cross-Reference with Code Review
- [ ] Compare hot paths with code review findings
- [ ] Compare slow paths with code review findings
- [ ] Validate optimization priorities based on actual data
- [ ] Identify any unexpected hot/slow paths not covered in code review

### Optimization Prioritization
- [ ] High priority: Hot paths with identified optimization opportunities
- [ ] Medium priority: Slow paths with identified optimization opportunities
- [ ] Low priority: Hot/slow paths with small arrays (effectively constant time)

---

## Expected Findings (Based on Code Review)

### Likely Hot Paths
1. **`yield`** - Already optimal (no-op)
2. **`read`/`write`** - May be hot paths (handle lookup optimization opportunity)
3. **`clock_gettime`** - May be hot path (likely optimal)
4. **`sysinfo`** - May be hot path (caching opportunity)

### Likely Slow Paths
1. **`spawn`** - Process creation, ELF parsing (multiple linear searches)
2. **`map`/`unmap`** - Memory management (mapping lookup, overlap checking)
3. **Network operations** - Timer calls, network stack processing
4. **File operations** - Handle lookup (if read/write are hot paths)

---

## Data Collection Best Practices

### 1. Run Multiple Iterations
- Run benchmarks multiple times to get average results
- Account for system noise and variability

### 2. Use Realistic Workloads
- Test with workloads that match actual usage patterns
- Vary syscall frequencies to match real scenarios

### 3. Collect Comprehensive Data
- Don't just collect hot/slow paths
- Collect metrics for all syscalls to get full picture

### 4. Document Findings
- Record all collected metrics
- Note any unexpected findings
- Compare with code review predictions

### 5. Validate Profiler Overhead
- Measure profiler overhead (should be minimal when enabled)
- Compare with/without profiling to ensure accuracy

---

## Troubleshooting

### Issue: Profiler Not Recording Data

**Check**:
- Is profiling enabled? (`kernel.syscall_profiler.enabled`)
- Are syscalls actually being executed?
- Are syscalls succeeding (not failing immediately)?

**Solution**:
```zig
// Verify profiling is enabled
try testing.expect(kernel.syscall_profiler.enabled);

// Check summary
const summary = kernel.get_profiler_summary();
std.debug.print("Profiling enabled: {}\n", .{summary.enabled});
std.debug.print("Total syscalls: {}\n", .{summary.total_syscall_count});
```

### Issue: All Metrics Show Zero

**Check**:
- Are syscalls being called?
- Are syscalls succeeding?
- Is profiler reset being called accidentally?

**Solution**:
- Verify syscall execution with error handling
- Check that profiler isn't being reset between measurements
- Ensure sufficient iterations for data collection

### Issue: Unexpected Hot/Slow Paths

**Action**:
- Review syscall implementation
- Check for unexpected overhead
- Validate with code review findings
- Document unexpected findings

---

## Next Steps After Data Collection

1. **Analyze Data**: Use analysis checklist above
2. **Prioritize Optimizations**: Based on actual hot/slow paths
3. **Implement Optimizations**: Follow optimization roadmap
4. **Validate Improvements**: Re-run benchmarks after optimizations
5. **Document Results**: Update optimization roadmap with results

---

## References

- **Profiler Usage**: `docs/kernel/syscall_performance_profiler_usage.md`
- **Optimization Roadmap**: `docs/kernel/optimization_roadmap.md`
- **Code Review Summary**: `docs/kernel/code_review_summary_2025-12-30.md`
- **Performance Analysis**: `docs/kernel/performance_optimization_analysis.md`

---

**Status**: Ready for execution  
**Last Updated**: 2025-12-31-000500-pst
