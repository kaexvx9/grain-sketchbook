//! Minimal Isolated Test - Grain Style Arena Pattern
//! Why: Test Grain Style arena pattern in isolation to verify it works
//! Grain Style: Arena allocators (bounded, explicit, startup-time)

const std = @import("std");
const testing = std.testing;
const kernel_vm = @import("kernel_vm");
const VM = kernel_vm.VM;
const Integration = kernel_vm.Integration;
const basin_kernel = @import("basin_kernel");
const BasinKernel = basin_kernel.BasinKernel;

// Minimal test: VM only (Grain Style: arena allocator)
test "isolated: VM only" {
    // Grain Style: Arena allocator (bounded, explicit, startup-time)
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    // Allocate VM via arena (Grain Style: bounded, explicit)
    const vm = try allocator.create(VM);
    VM.init(vm, &[_]u8{}, 0x80000000);
    
    try testing.expect(vm.state == .halted);
    try testing.expect(vm.memory_size > 0);
}

// Minimal test: VM + Kernel (Grain Style: arena allocator)
test "isolated: VM + Kernel" {
    // Grain Style: Arena allocator (bounded, explicit, startup-time)
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    // Allocate VM via arena
    const vm = try allocator.create(VM);
    VM.init(vm, &[_]u8{}, 0x80000000);
    
    // Allocate Kernel via arena
    const kernel = try allocator.create(BasinKernel);
    BasinKernel.init_in_place(kernel);
    
    try testing.expect(vm.state == .halted);
    try testing.expect(kernel.user_count >= 1);
}

// Minimal test: VM + Kernel + Integration (Grain Style: arena allocator)
test "isolated: VM + Kernel + Integration" {
    // Grain Style: Arena allocator (bounded, explicit, startup-time)
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    
    // Allocate VM via arena
    const vm = try allocator.create(VM);
    VM.init(vm, &[_]u8{}, 0x80000000);
    
    // Allocate Kernel via arena
    const kernel = try allocator.create(BasinKernel);
    BasinKernel.init_in_place(kernel);
    
    // Allocate Integration via arena
    const integration = try allocator.create(Integration);
    integration.* = Integration.init_with_kernel(vm, kernel);
    integration.finish_init();
    
    try testing.expect(integration.initialized);
    try testing.expect(vm.state == .halted);
    try testing.expect(kernel.user_count >= 1);
}
