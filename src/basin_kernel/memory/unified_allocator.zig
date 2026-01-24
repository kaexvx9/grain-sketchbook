//! Basin Kernel: Unified Memory Management Architecture
//!
//! Why: System-wide memory coordination with explicit bounds and safety guarantees.
//! Provides unified memory management across kernel, display, and application regions.
//!
//! Agent: Reya (Systems Architecture Strategist)

const std = @import("std");

/// Why: System-wide memory bounds for Grain OS.
/// Defines explicit maximums for all memory regions to prevent exhaustion.
pub const SYSTEM_MEMORY_BOUNDS = struct {
    pub const TOTAL_SYSTEM_MEMORY: u64 = 512 * 1024 * 1024; // 512MB for QEMU
    pub const KERNEL_HEAP_MAX: u64 = 64 * 1024 * 1024;      // 64MB kernel
    pub const DISPLAY_BUFFER_MAX: u64 = 32 * 1024 * 1024;   // 32MB display
    pub const APPLICATION_HEAP_MAX: u64 = 256 * 1024 * 1024; // 256MB apps
    pub const PROTOCOL_BUFFER_MAX: u64 = 16 * 1024 * 1024;   // 16MB protocol
    pub const SHARED_MEMORY_MAX: u64 = 32 * 1024 * 1024;     // 32MB shared
};

/// Why: Memory region types for allocation tracking.
pub const MemoryRegion = enum {
    kernel_heap,
    display_buffer,
    application_heap,
    protocol_buffer,
    shared_memory,
};

/// Why: Memory usage statistics for monitoring.
pub const MemoryUsageStats = struct {
    kernel_used: u64,
    display_used: u64,
    application_used: u64,
    protocol_used: u64,
    shared_used: u64,
    total_used: u64,
};

/// Why: Unified memory manager coordinating all system memory.
/// Provides region-specific allocators with bounds checking.
pub const UnifiedMemoryManager = struct {
    const Self = @This();
    
    allocator: std.mem.Allocator,
    kernel_allocator: std.heap.FixedBufferAllocator,
    kernel_buffer: []u8,
    stats: MemoryUsageStats,
    
    /// Why: Initialize unified memory management system.
    pub fn init(allocator: std.mem.Allocator) !Self {
        // Why: Allocate kernel heap buffer with bounds.
        const kernel_buffer = try allocator.alloc(u8, SYSTEM_MEMORY_BOUNDS.KERNEL_HEAP_MAX);
        errdefer allocator.free(kernel_buffer);
        
        var kernel_alloc = std.heap.FixedBufferAllocator.init(kernel_buffer);
        
        return Self{
            .allocator = allocator,
            .kernel_allocator = kernel_alloc,
            .kernel_buffer = kernel_buffer,
            .stats = std.mem.zeroes(MemoryUsageStats),
        };
    }
    
    /// Why: Cleanup memory manager and all resources.
    pub fn deinit(self: *Self) void {
        self.allocator.free(self.kernel_buffer);
    }
    
    /// Why: Allocate memory from kernel heap with bounds checking.
    pub fn allocateKernel(self: *Self, size: u64) !?[]u8 {
        if (size > SYSTEM_MEMORY_BOUNDS.KERNEL_HEAP_MAX) {
            return error.AllocationTooLarge;
        }
        
        if (self.stats.kernel_used + size > SYSTEM_MEMORY_BOUNDS.KERNEL_HEAP_MAX) {
            return error.KernelHeapExhausted;
        }
        
        const result = self.kernel_allocator.allocator().alloc(u8, size) catch {
            return error.AllocationFailed;
        };
        
        self.stats.kernel_used += size;
        self.stats.total_used += size;
        
        return result;
    }
    
    /// Why: Deallocate kernel memory and update statistics.
    pub fn deallocateKernel(self: *Self, ptr: ?[]u8) void {
        if (ptr) |p| {
            const size = p.len;
            self.kernel_allocator.allocator().free(p);
            self.stats.kernel_used -|= size;
            self.stats.total_used -|= size;
        }
    }
    
    /// Why: Get current memory usage statistics.
    pub fn getStats(self: *const Self) MemoryUsageStats {
        return self.stats;
    }
    
    /// Why: Get maximum kernel allocation size available.
    pub fn getMaxKernelAllocation(self: *const Self) u64 {
        return SYSTEM_MEMORY_BOUNDS.KERNEL_HEAP_MAX - self.stats.kernel_used;
    }
};

/// Why: Initialize system memory management.
/// Creates unified memory manager for Grain OS.
pub fn initializeSystemMemory(allocator: std.mem.Allocator) !UnifiedMemoryManager {
    return UnifiedMemoryManager.init(allocator);
}