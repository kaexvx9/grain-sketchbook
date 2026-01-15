//! Minimal tests to isolate crash in test 164
//! Why: Test each component separately to find where crash occurs

const std = @import("std");
const testing = std.testing;
const kernel_vm = @import("kernel_vm");
const VM = kernel_vm.VM;
const Integration = kernel_vm.Integration;
const basin_kernel = @import("basin_kernel");
const BasinKernel = basin_kernel.BasinKernel;

// Test 1: Just VM initialization
test "minimal: VM only" {
    var vm: VM = undefined;
    VM.init(&vm, &[_]u8{}, 0x80000000);
    try testing.expect(vm.state == .halted);
    try testing.expect(vm.memory_size > 0);
}

// Test 2: VM + Kernel initialization
test "minimal: VM + Kernel" {
    var vm: VM = undefined;
    VM.init(&vm, &[_]u8{}, 0x80000000);
    
    var kernel: BasinKernel = undefined;
    BasinKernel.init_in_place(&kernel);
    
    try testing.expect(vm.state == .halted);
    try testing.expect(kernel.user_count >= 1);
}

// Test 3: VM + Kernel + Integration (heap allocated)
test "minimal: VM + Kernel + Integration (heap)" {
    const env = try testing.allocator.create(struct {
        vm: VM,
        kernel: BasinKernel,
        integration: Integration,
    });
    defer testing.allocator.destroy(env);
    
    VM.init(&env.vm, &[_]u8{}, 0x80000000);
    BasinKernel.init_in_place(&env.kernel);
    env.integration = Integration.init_with_kernel(&env.vm, &env.kernel);
    env.integration.finish_init();
    
    try testing.expect(env.integration.initialized);
    try testing.expect(env.vm.state == .halted);
}

// Test 4: Full test but without syscall
test "minimal: full env without syscall" {
    const env = try testing.allocator.create(struct {
        vm: VM,
        kernel: BasinKernel,
        integration: Integration,
    });
    defer testing.allocator.destroy(env);
    
    VM.init(&env.vm, &[_]u8{}, 0x80000000);
    BasinKernel.init_in_place(&env.kernel);
    env.integration = Integration.init_with_kernel(&env.vm, &env.kernel);
    env.integration.finish_init();
    
    const vm = &env.vm;
    const info_ptr: u64 = 0x1000;
    const SYSINFO_SIZE: u64 = 32;
    
    // Just verify memory access works
    const mem_slice = vm.memory[@intCast(info_ptr)..@intCast(info_ptr + SYSINFO_SIZE)];
    @memset(mem_slice, 0);
    
    try testing.expect(env.integration.initialized);
}
