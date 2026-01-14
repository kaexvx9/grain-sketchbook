//! Minimal test for VM + Kernel initialization
//! Why: Isolate the crash to see if it's test file specific
//! Grain Style: Arena allocator with pointers

const std = @import("std");
const testing = std.testing;
const kernel_vm = @import("kernel_vm");
const VM = kernel_vm.VM;
const basin_kernel = @import("basin_kernel");
const BasinKernel = basin_kernel.BasinKernel;

test "isolated: VM + Kernel" {
    // Grain Style: Arena allocator (bounded, explicit, startup-time)
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    // Allocate VM via arena (Grain Style: bounded, explicit)
    const vm = try allocator.create(VM);
    VM.init(vm, &[_]u8{}, 0x80000000);
    
    // Allocate Kernel via arena (Grain Style: bounded, explicit)
    const kernel = try allocator.create(BasinKernel);
    BasinKernel.init_in_place(kernel);
    
    std.debug.assert(vm.state == .halted);
    std.debug.assert(kernel.user_count >= 1);
}
