# Kernel Performance Optimization Roadmap

**Date**: 2025-12-30  
**Agent**: Grain Basin Kernel Agent (3a)  
**Status**: Ready for Data Collection

---

## Overview

This document provides a comprehensive roadmap for kernel performance optimization based on code review findings. All optimizations should be validated with profiling data before implementation.

---

## Quick Wins (Implemented)

### ✅ Handle Lookup MRU Cache (COMPLETE)
- **Status**: ✅ **IMPLEMENTED**
- **Implementation**: MRU (Most Recently Used) cache for handle lookup
- **Files Modified**:
  - `src/kernel/basin_kernel_core.zig` - Added MRU fields, updated `find_handle_by_id()`, added `invalidate_mru_handle_cache()`
  - `src/kernel/basin_kernel_syscalls_file.zig` - Integrated cache invalidation in `syscall_close`
- **Expected Improvement**: 10-30% for repeated handle access
- **Risk**: Low (simple optimization, maintains correctness)

### ✅ Handle Lookup Hash Table (COMPLETE)
- **Status**: ✅ **IMPLEMENTED** (2026-01-02-100345-pst)
- **Implementation**: Hash table for O(1) handle lookup instead of O(n) linear search
- **Files Modified**:
  - `src/kernel/basin_kernel_core.zig` - Added `handle_id_to_index` hash table, updated `find_handle_by_id()` with three-tier lookup (MRU cache, hash table, linear search fallback), added `update_handle_hash_table()` and `invalidate_handle_hash_table()`
  - `src/kernel/basin_kernel_syscalls_file.zig` - Updated `syscall_open()` and `syscall_close()` to maintain hash table
- **Expected Improvement**: 2-10x for handle lookup operations (if read/write are hot paths)
- **Risk**: Low (hash table with linear search fallback, maintains correctness)
- **Documentation**: `docs/kernel/handle_lookup_hash_table_optimization.md`

---

## Optimization Priority Matrix

### High Priority (If Confirmed Hot Paths)

These optimizations should be implemented if profiling data confirms these syscalls are frequently called:

#### 1. Handle Lookup Optimization
- **Status**: ✅ **COMPLETE** (2026-01-02-100345-pst)
- **Current**: ~~Linear search O(n) through MAX_HANDLES=64~~ → **Hash table O(1) lookup**
- **Affected Syscalls**: `read`, `write`, `close`, `unlink`, `rename`
- **Optimization**: Hash table O(1) lookup with MRU cache and linear search fallback
- **Impact**: High (if read/write are hot paths) - **IMPLEMENTED**
- **Implementation Complexity**: Medium - **COMPLETE**
- **Estimated Improvement**: 2-10x for handle lookup - **READY FOR VALIDATION**

**Implementation Complete**:
1. ✅ Created hash table structure for handle lookup (handle_id → index mapping)
2. ✅ Maintain hash table when handles are created/destroyed
3. ✅ Replaced `find_handle_by_id()` with three-tier lookup (MRU cache, hash table, linear search fallback)
4. ✅ Linear search fallback for hash collisions (robustness)

**Grain Style Compliance**:
- ✅ Static allocation (bounded hash table size)
- ✅ No dynamic allocation
- ✅ Maintains deterministic behavior
- ✅ Comprehensive assertions

**Documentation**: `docs/kernel/handle_lookup_hash_table_optimization.md`

---

### Medium Priority (If Confirmed Slow Paths)

These optimizations should be implemented if profiling data confirms these syscalls have high execution times:

#### 2. Timer Call Optimization
- **Current**: `get_monotonic_ns()` may involve system calls
- **Affected Syscalls**: `read`, `write`, `sleep_until`, network syscalls (with timeout)
- **Optimization**: Cache timer value or use fast timer
- **Impact**: Medium (affects multiple syscalls)
- **Implementation Complexity**: Low-Medium
- **Estimated Improvement**: 10-50% reduction in timeout checking overhead

**Implementation Plan**:
1. Profile timer call overhead (measure `get_monotonic_ns()` execution time)
2. If overhead is significant, implement timer caching:
   - Cache timer value at syscall entry
   - Reuse cached value for timeout checks within same syscall
   - Update cache periodically (e.g., every 1ms)
3. Alternative: Use fast timer if available (hardware timer register)

#### 3. Mapping Lookup Optimization
- **Status**: ✅ **COMPLETE** (2026-01-06-100000-pst)
- **Current**: ~~Linear search O(n) through MAX_MAPPINGS=256~~ → **Hash table O(1) lookup**
- **Affected Syscalls**: `map`, `unmap`
- **Optimization**: Hash table O(1) lookup with linear search fallback
- **Impact**: Medium (if map/unmap are slow paths) - **IMPLEMENTED**
- **Implementation Complexity**: Medium - **COMPLETE**
- **Estimated Improvement**: 2-5x for mapping lookup - **READY FOR VALIDATION**

**Implementation Complete**:
1. ✅ Created hash table structure for mapping lookup (address → index mapping)
2. ✅ Maintain hash table when mappings are created/destroyed
3. ✅ Replaced `find_mapping_by_address()` with hash table lookup (three-tier: hash table, linear search fallback)
4. ✅ Integrated hash table maintenance in `syscall_map()` and `syscall_unmap()`

**Grain Style Compliance**:
- ✅ Static allocation (bounded hash table size)
- ✅ No dynamic allocation
- ✅ Maintains deterministic behavior
- ✅ Comprehensive assertions

**Documentation**: `docs/kernel/mapping_lookup_hash_table_optimization.md`

#### 4. Overlap Checking Optimization
- **Current**: Iterates through all mappings
- **Affected Syscalls**: `map`
- **Optimization**: Sorted list or interval tree
- **Impact**: Medium (if map is slow path)
- **Implementation Complexity**: Medium-High
- **Estimated Improvement**: 2-10x for overlap checking (depending on number of mappings)

**Implementation Plan**:
1. Maintain mappings in sorted order by address
2. Use binary search for overlap checking
3. Alternative: Implement interval tree for complex cases

#### 5. Handle Lookup by Path
- **Current**: Linear search through MAX_HANDLES=64
- **Affected Syscalls**: `unlink`, `rename`
- **Optimization**: Hash table (path → handle_id mapping)
- **Impact**: Medium (if unlink/rename are slow paths)
- **Implementation Complexity**: Medium
- **Estimated Improvement**: 2-5x for path-based lookup

---

### Low Priority

These optimizations have lower impact but may be worth implementing if profiling shows they're bottlenecks:

#### 6. Process Lookup Optimization
- **Current**: Linear search O(n) through MAX_PROCESSES=16
- **Affected Syscalls**: Multiple (spawn, resource tracking, etc.)
- **Optimization**: Hash table (process_id → index mapping)
- **Impact**: Low (small array, O(16) = effectively constant)
- **Implementation Complexity**: Low
- **Estimated Improvement**: Minimal (array is small)

**Note**: Only implement if profiling shows process lookup is a bottleneck.

#### 7. Sysinfo Caching
- **Current**: Aggregates statistics on every call
- **Affected Syscalls**: `sysinfo`
- **Optimization**: Cache results, update periodically
- **Impact**: Low (if sysinfo is called very frequently)
- **Implementation Complexity**: Low
- **Estimated Improvement**: 10-50% if called frequently

**Implementation Plan**:
1. Cache sysinfo results
2. Update cache every N milliseconds (e.g., 100ms)
3. Return cached value if within update interval

#### 8. Directory Handle Lookup
- **Current**: Linear search through MAX_DIR_HANDLES
- **Affected Syscalls**: `opendir`, `readdir`, `closedir`
- **Optimization**: Hash table (if MAX_DIR_HANDLES is large)
- **Impact**: Low (small array)
- **Implementation Complexity**: Low
- **Estimated Improvement**: Minimal

---

## Optimization Workflow

### Phase 1: Data Collection (Current Phase)
1. ✅ Profiler infrastructure complete
2. ✅ Code review complete
3. ⏳ Enable profiling in test scenarios
4. ⏳ Run comprehensive syscall benchmarks
5. ⏳ Collect performance data for all syscalls

### Phase 2: Data Analysis
1. Identify hot paths (most frequently called syscalls)
2. Identify slow paths (syscalls with highest execution time)
3. Cross-reference with code review findings
4. Prioritize optimizations based on:
   - Call frequency (hot paths)
   - Execution time (slow paths)
   - Impact potential
   - Implementation complexity

### Phase 3: Optimization Implementation
1. Implement high-priority optimizations first
2. Measure performance improvements
3. Validate correctness (ensure no regressions)
4. Document optimization results

### Phase 4: Validation
1. Re-run benchmarks with optimizations
2. Compare before/after performance
3. Verify no correctness regressions
4. Update documentation

---

## Expected Performance Improvements

Based on code review and typical kernel optimization patterns:

### Best Case Scenario (If Read/Write are Hot Paths)
- **Handle lookup optimization**: 2-10x improvement for read/write syscalls
- **Overall syscall performance**: 10-30% improvement

### Realistic Scenario
- **Handle lookup optimization**: 2-5x improvement (if read/write are moderately hot)
- **Timer call optimization**: 10-20% improvement (if timer overhead is significant)
- **Overall syscall performance**: 5-15% improvement

### Conservative Scenario
- **Minor optimizations**: 5-10% improvement
- **Code quality improvements**: Better maintainability

---

## Risk Assessment

### Low Risk Optimizations
- Timer call caching (if overhead is significant)
- Process lookup optimization (small impact, low complexity)
- Sysinfo caching (low complexity)

### Medium Risk Optimizations
- Handle lookup hash table (requires careful testing)
- Mapping lookup hash table (requires careful testing)

### High Risk Optimizations
- Overlap checking with sorted list (complex, requires extensive testing)
- Major architectural changes

---

## Success Metrics

### Performance Metrics
- Syscall execution time reduction (target: 10-30%)
- Hot path syscall improvement (target: 2-5x for handle lookup)
- Overall system responsiveness improvement

### Code Quality Metrics
- No correctness regressions
- Maintain Grain Style compliance
- Zero technical debt
- Comprehensive test coverage

---

## Next Steps

1. **Immediate**: Enable profiling and collect data
2. **Short-term**: Analyze profiling data and prioritize optimizations
3. **Medium-term**: Implement high-priority optimizations
4. **Long-term**: Continuous monitoring and optimization

---

## Notes

- All optimizations must be validated with profiling data
- Maintain Grain Style compliance (static allocation, bounded operations)
- No dynamic allocation allowed
- All optimizations must have comprehensive test coverage
- Document all optimization decisions and results

---

**Status**: Hash Table Optimization Complete, Ready for Profiler Validation  
**Last Updated**: 2026-01-02-100345-pst
