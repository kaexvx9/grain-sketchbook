//! Why: Test runtime index with inline for pattern for RISC-V freestanding.
//! This matches the pattern used in Debug.kprint() - inline for with runtime index.
//! Verifies if this pattern causes Issue 2.

const builtin = @import("builtin");
const std = @import("std");

// Why: Test function matching Debug.kprint() pattern.
fn print_arg(args: anytype, idx: usize) void {
    // Why: inline for with runtime index - same pattern as Debug.kprint().
    inline for (std.meta.fields(@TypeOf(args)), 0..) |field, i| {
        if (i == idx) {
            const val = @field(args, field.name);
            _ = val;  // Simulate using the value
            return;
        }
    }
}

// Why: Test runtime index selection with inline for.
pub fn test_runtime_index_inline_for() void {
    // Why: Test with different argument counts.
    print_arg(.{@as(u32, 42)}, 0);
    print_arg(.{@as(u32, 10), @as(u64, 20)}, 0);
    print_arg(.{@as(u32, 10), @as(u64, 20)}, 1);
    print_arg(.{@as(u32, 1), @as(u64, 2), @as(i32, 3)}, 0);
    print_arg(.{@as(u32, 1), @as(u64, 2), @as(i32, 3)}, 1);
    print_arg(.{@as(u32, 1), @as(u64, 2), @as(i32, 3)}, 2);
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Obj
