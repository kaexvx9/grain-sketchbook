# Kernel Performance Optimization Roadmap

**Date**: 2025-12-30  
**Agent**: Grain Basin Kernel Agent (3a)  
**Status**: Ready for Data Collection

---

## Overview

This document provides a comprehensive roadmap for kernel performance optimization based on code review findings. All optimizations should be validated with profiling data before implementation.

---

## Optimization Priority Matrix

### High Priority (If Confirmed Hot Paths)

These optimizations should be implemented if profiling data confirms these syscalls are frequently called:

#### 1. Handle Lookup Optimization
- **Current**: Linear search O(n) through MAX_HANDLES=64
- **Affected Syscalls**: `read`, `write`, `close`, `unlink`, `rename`
- **Optimization**: Hash table O(1) lookup
- **Impact**: High (if read/write are hot paths)
- **Implementation Complexity**: Medium
- **Estimated Improvement**: 2-10x for handle lookup (depending on number of active handles)

**Implementation Plan**:
1. Create hash table structure for handle lookup (handle_id → index mapping)
2. Maintain hash table when handles are created/destroyed
3. Replace `find_handle_by_id()` calls with hash table lookup
4. Keep linear search as fallback for hash collisions (should be rare)

**Grain Style Considerations**:
- Use static allocation (bounded hash table size)
- No dynamic allocation
- Maintain deterministic behavior

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
- **Current**: Linear search O(n) through MAX_MAPPINGS=256
- **Affected Syscalls**: `map`, `unmap`
- **Optimization**: Hash table or sorted list
- **Impact**: Medium (if map/unmap are slow paths)
- **Implementation Complexity**: Medium
- **Estimated Improvement**: 2-5x for mapping lookup

**Implementation Plan**:
1. Create hash table for mapping lookup (address → index mapping)
2. Maintain hash table when mappings are created/destroyed
3. Replace linear search with hash table lookup
4. Keep sorted list for overlap checking (if needed)

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

**Status**: Ready for Phase 1 (Data Collection)  
**Last Updated**: 2025-12-30-235900-pst
