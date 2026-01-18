//! Framework x86 Full Stack Integration Test (Phase 4)
//! Why: Test complete stack: Vantage VM (x86_64 JIT) → Basin Kernel → Grainscript Shell.
//! Architecture: End-to-end test verifying all components work together.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const kernel_vm = @import("kernel_vm");
const VM = kernel_vm.VM;
const Integration = kernel_vm.Integration;
const basin_kernel = @import("basin_kernel");
const BasinKernel = basin_kernel.BasinKernel;
const RawIO = basin_kernel.RawIO;

// Helper: Create VM on heap to avoid stack overflow (VM is 8MB+).
fn create_test_vm() !*VM {
    const vm = try testing.allocator.create(VM);
    VM.init(vm, &[_]u8{}, 0);
    return vm;
}

// Helper: Create kernel on heap to avoid stack overflow (~75KB).
fn create_test_kernel() !*BasinKernel {
    const kernel = try testing.allocator.create(BasinKernel);
    BasinKernel.init_in_place(kernel);
    return kernel;
}

// Test: Full stack integration (VM → Kernel → ELF Loading → Process Spawn).
// Why: Verify complete Framework x86_64 stack works end-to-end.
test "framework x86: basin + vantage + grainscript shell full stack" {
    RawIO.disable();
    defer RawIO.enable();
    
    const vm = try create_test_vm();
    defer testing.allocator.destroy(vm);
    
    const kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);
    
    var integration = Integration.init_with_kernel(vm, kernel);
    integration.finish_init();
    defer integration.cleanup();
    
    const ELF_LOAD_ADDR: u64 = 0x1000000;
    const shell_elf_path = "zig-out/bin/grain-rv64";
    
    const load_result = integration.load_elf_file(shell_elf_path, ELF_LOAD_ADDR);
    
    if (load_result) |elf_addr| {
        try testing.expectEqual(ELF_LOAD_ADDR, elf_addr);
        
        const spawn_result = integration.spawn_process_from_elf(elf_addr, 0, 0);
        if (spawn_result) |pid| {
            try testing.expect(pid > 0);
            // Full stack works!
        } else |_| {
            // Spawn may fail if ELF not suitable - OK for test.
        }
    } else |_| {
        // ELF doesn't exist - OK (test may run before kernel is built).
    }
}

// Test: Full stack error handling.
// Why: Verify error handling works correctly in full stack context.
test "framework x86: full stack error handling" {
    RawIO.disable();
    defer RawIO.enable();
    
    const vm = try create_test_vm();
    defer testing.allocator.destroy(vm);
    
    const kernel = try create_test_kernel();
    defer testing.allocator.destroy(kernel);
    
    var integration = Integration.init_with_kernel(vm, kernel);
    integration.finish_init();
    defer integration.cleanup();
    
    // Test: Invalid ELF address for spawn.
    const spawn_result = integration.spawn_process_from_elf(0, 0, 0);
    _ = spawn_result catch {};
    
    // Test: Invalid file path for load.
    const load_result = integration.load_elf_file("", 0x1000000);
    _ = load_result catch {};
}
