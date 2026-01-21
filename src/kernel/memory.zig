//! Grain Basin Memory Allocator
//! Why: Kernel-side memory allocation with page-based management.

const std = @import("std");
const Debug = @import("debug.zig");

pub const PAGE_SIZE: u64 = 4096;
pub const MAX_PAGES: u32 = 1024;
pub const MAX_POOL_SIZE: u64 = 4 * 1024 * 1024;

/// Page state (free or allocated).
/// Why: Explicit page state enumeration.
pub const PageState = enum(u8) { free = 0, allocated = 1 };

/// Memory pool for kernel allocations.
/// Why: Provide kernel-side memory allocation without external allocator.
pub const MemoryPool = struct {
    buffer: [MAX_POOL_SIZE]u8,
    page_states: [MAX_PAGES]PageState,
    allocated_pages: u32,
    next_free_page: u32,

    /// Initialize memory pool.
    /// Why: Set up memory pool state.
    pub fn init() MemoryPool {
        return MemoryPool{
            .buffer = [_]u8{0} ** MAX_POOL_SIZE,
            .page_states = [_]PageState{.free} ** MAX_PAGES,
            .allocated_pages = 0,
            .next_free_page = 0,
        };
    }

    /// Initialize memory pool in-place to avoid 4MB stack allocation.
    /// Why: Critical for heap-allocated kernels.
    pub fn init_in_place(target: *MemoryPool) void {
        @memset(&target.buffer, 0);
        for (&target.page_states) |*ps| ps.* = .free;
        target.allocated_pages = 0;
        target.next_free_page = 0;
    }

    /// Allocate pages.
    /// Why: Allocate contiguous pages for kernel use.
    pub fn allocate_pages(self: *MemoryPool, num: u32) ?u32 {
        if (num == 0 or num > MAX_PAGES) return null;

        var start: ?u32 = null;
        var run: u32 = 0;
        for (0..MAX_PAGES) |i| {
            const idx = @as(u32, @intCast(i));
            if (self.page_states[idx] == .free) {
                if (run == 0) start = idx;
                run += 1;
                if (run >= num) break;
            } else {
                run = 0;
                start = null;
            }
        }

        if (start == null or run < num) return null;
        const s = start.?;
        for (0..num) |i| self.page_states[s + @as(u32, @intCast(i))] = .allocated;
        self.allocated_pages += num;
        return s;
    }

    /// Deallocate pages.
    /// Why: Free pages for reuse.
    pub fn deallocate_pages(self: *MemoryPool, start: u32, num: u32) bool {
        if (start >= MAX_PAGES or num == 0 or start + num > MAX_PAGES) return false;

        for (0..num) |i| {
            const idx = start + @as(u32, @intCast(i));
            if (self.page_states[idx] != .allocated) return false;
            self.page_states[idx] = .free;
        }
        self.allocated_pages -= num;
        return true;
    }

    /// Get page address.
    /// Why: Convert page index to physical address.
    pub fn get_page_address(self: *const MemoryPool, idx: u32) u64 {
        _ = self;
        Debug.kassert(idx < MAX_PAGES, "Page idx >= MAX", .{});
        return @as(u64, idx) * PAGE_SIZE;
    }

    /// Get allocated page count.
    /// Why: Query number of allocated pages.
    pub fn get_allocated_pages(self: *const MemoryPool) u32 {
        return self.allocated_pages;
    }

    /// Get free page count.
    /// Why: Query number of free pages.
    pub fn get_free_pages(self: *const MemoryPool) u32 {
        return MAX_PAGES - self.allocated_pages;
    }

    /// Allocate memory (convenience function).
    /// Why: Allocate memory in bytes.
    pub fn allocate(self: *MemoryPool, size: u64) ?u32 {
        if (size == 0 or size > MAX_POOL_SIZE) return null;
        return self.allocate_pages(@as(u32, @intCast((size + PAGE_SIZE - 1) / PAGE_SIZE)));
    }

    /// Deallocate memory (convenience function).
    /// Why: Deallocate memory in bytes.
    pub fn deallocate(self: *MemoryPool, start: u32, size: u64) bool {
        if (size == 0) return false;
        return self.deallocate_pages(start, @as(u32, @intCast((size + PAGE_SIZE - 1) / PAGE_SIZE)));
    }
};

test "memory pool init" {
    const p = MemoryPool.init();
    try std.testing.expect(p.allocated_pages == 0);
    try std.testing.expect(p.get_free_pages() == MAX_PAGES);
}

test "memory pool allocate pages" {
    var p = MemoryPool.init();
    const idx = p.allocate_pages(1);
    try std.testing.expect(idx != null);
    try std.testing.expect(p.get_allocated_pages() == 1);
}

test "memory pool deallocate pages" {
    var p = MemoryPool.init();
    const idx = p.allocate_pages(1);
    try std.testing.expect(idx != null);
    try std.testing.expect(p.deallocate_pages(idx.?, 1));
    try std.testing.expect(p.get_allocated_pages() == 0);
}

test "memory pool page address" {
    var p = MemoryPool.init();
    try std.testing.expect(p.get_page_address(10) == 10 * PAGE_SIZE);
}
