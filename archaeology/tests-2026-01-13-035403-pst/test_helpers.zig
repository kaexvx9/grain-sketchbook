//! Test Helpers - Grain Style Arena-Based Allocation
//! Why: Provide stack-safe test utilities using arena allocators (Grain Style: bounded, explicit)
//! Grain Style: Arena allocators are MORE bounded than stack (explicit size, predictable)

const std = @import("std");
const testing = std.testing;
const kernel_vm = @import("kernel_vm");
const VM = kernel_vm.VM;
const Integration = kernel_vm.Integration;
const basin_kernel = @import("basin_kernel");
const BasinKernel = basin_kernel.BasinKernel;

/// Test Helpers - Arena-based allocation (Grain Style)
pub const TestHelpers = struct {
    /// Create VM via arena (Grain Style: bounded, explicit, startup-time allocation)
    /// Why: Allocate large VM struct (8MB) via arena to avoid stack overflow
    /// Contract: arena must be valid allocator, returns initialized VM pointer
    pub fn create_vm(arena: std.mem.Allocator) !*VM {
        // Assert: arena must be valid (precondition)
        std.debug.assert(arena.ptr != null);
        
        // Allocate VM on heap via arena (Grain Style: explicit, bounded)
        const vm = try arena.create(VM);
        
        // Initialize VM in-place (Grain Style: no stack temporary)
        VM.init(vm, &[_]u8{}, 0x80000000);
        
        // Assert: VM must be initialized (postcondition)
        std.debug.assert(vm.state == .halted);
        std.debug.assert(vm.memory_size > 0);
        
        return vm;
    }
    
    /// Create Kernel via arena (Grain Style: bounded, explicit, startup-time allocation)
    /// Why: Allocate large Kernel struct (~76KB) via arena to avoid stack overflow
    /// Contract: arena must be valid allocator, returns initialized Kernel pointer
    pub fn create_kernel(arena: std.mem.Allocator) !*BasinKernel {
        // Assert: arena must be valid (precondition)
        std.debug.assert(arena.ptr != null);
        
        // Allocate Kernel on heap via arena (Grain Style: explicit, bounded)
        const kernel = try arena.create(BasinKernel);
        
        // Initialize Kernel in-place (Grain Style: no stack temporary)
        BasinKernel.init_in_place(kernel);
        
        // Assert: Kernel must be initialized (postcondition)
        std.debug.assert(kernel.user_count >= 1);
        
        return kernel;
    }
    
    /// Create Integration via arena (Grain Style: bounded, explicit, startup-time allocation)
    /// Why: Allocate Integration struct via arena, uses pointers to VM and Kernel
    /// Contract: vm and kernel must be valid pointers, arena must be valid allocator
    pub fn create_integration(arena: std.mem.Allocator, vm: *VM, kernel: *BasinKernel) !*Integration {
        // Assert: Pointers must be valid (precondition)
        std.debug.assert(@intFromPtr(vm) != 0);
        std.debug.assert(@intFromPtr(kernel) != 0);
        std.debug.assert(arena.ptr != null);
        
        // Allocate Integration on heap via arena (Grain Style: explicit, bounded)
        const integration = try arena.create(Integration);
        
        // Initialize Integration (stores pointers, not values)
        integration.* = Integration.init_with_kernel(vm, kernel);
        integration.finish_init();
        
        // Assert: Integration must be initialized (postcondition)
        std.debug.assert(integration.initialized);
        std.debug.assert(integration.vm == vm);
        std.debug.assert(integration.kernel == kernel);
        
        return integration;
    }
};
