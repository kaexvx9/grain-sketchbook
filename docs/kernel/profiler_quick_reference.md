# Syscall Performance Profiler Quick Reference

**Date**: 2026-01-02  
**Agent**: Grain Basin Kernel Agent (3a)  
**Status**: ✅ Infrastructure Ready

---

## Quick Start

### Enable Profiling

```zig
var kernel = BasinKernel.init();
kernel.syscall_profiler.enable();
```

### Get Summary Statistics

```zig
const summary = kernel.get_profiler_summary();
std.debug.print("Enabled: {}\n", .{summary.enabled});
std.debug.print("Total syscalls: {}\n", .{summary.total_syscall_count});
std.debug.print("Total time: {} ns\n", .{summary.total_execution_time_ns});
```

### Find Hot Path (Most Frequently Called)

```zig
const hot_path = kernel.find_profiler_hot_path();
if (hot_path) |hp| {
    std.debug.print("Hot path: syscall {}, called {} times\n", .{hp.syscall_num, hp.call_count});
}
```

### Find Slow Path (Highest Average Time)

```zig
const slow_path = kernel.find_profiler_slow_path();
if (slow_path) |sp| {
    std.debug.print("Slow path: syscall {}, avg time {} ns\n", .{sp.syscall_num, sp.avg_time_ns});
}
```

### Get Top N Hot Paths

```zig
const top_hot = kernel.get_profiler_top_syscalls_by_count(10);
var i: u32 = 0;
while (i < top_hot.count) : (i += 1) {
    const entry = top_hot.entries[i];
    std.debug.print("Hot path {}: syscall {}, called {} times\n", .{i, entry.syscall_num, entry.call_count});
}
```

### Get Top N Slow Paths

```zig
const top_slow = kernel.get_profiler_top_syscalls_by_time(10);
var i: u32 = 0;
while (i < top_slow.count) : (i += 1) {
    const entry = top_slow.entries[i];
    std.debug.print("Slow path {}: syscall {}, avg time {} ns\n", .{i, entry.syscall_num, entry.avg_time_ns});
}
```

### Get Individual Syscall Metrics

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

### Reset Profiler

```zig
kernel.syscall_profiler.reset();
```

---

## API Reference

### BasinKernel Methods

- `kernel.syscall_profiler.enable()` - Enable profiling
- `kernel.syscall_profiler.disable()` - Disable profiling
- `kernel.syscall_profiler.reset()` - Reset all metrics
- `kernel.get_profiler_summary()` - Get summary statistics
- `kernel.find_profiler_hot_path()` - Find most frequently called syscall
- `kernel.find_profiler_slow_path()` - Find slowest syscall (by average time)
- `kernel.get_profiler_top_syscalls_by_count(n)` - Get top N hot paths
- `kernel.get_profiler_top_syscalls_by_time(n)` - Get top N slow paths

### Direct Profiler Access

- `kernel.syscall_profiler.get_metrics(syscall_num)` - Get metrics for specific syscall
- `kernel.syscall_profiler.get_total_syscall_count()` - Get total call count
- `kernel.syscall_profiler.get_total_execution_time_ns()` - Get total execution time

---

## Test Files

- `tests/143_syscall_performance_profiler_test.zig` - Profiler module tests
- `tests/144_syscall_performance_benchmark_test.zig` - Benchmark tests

**Status**: ✅ Configured in `build.zig`, ready to run once external compilation issues resolved

---

## Current Status

- ✅ Profiler infrastructure complete
- ✅ Tests configured in build system
- ✅ Module imports correct
- ⚠️ **BLOCKED**: External compilation errors preventing test execution
- ⏳ Ready to run immediately once external issues resolved

---

**Last Updated**: 2026-01-02-090000-pst

