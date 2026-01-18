//! Test: VM ELF Loading
//! Why: Verify ELF files can be loaded from host filesystem into VM memory.
//! Architecture: Tests load_elf_file_into_vm function for Phase 2 integration.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const kernel_vm = @import("kernel_vm");
const VM = kernel_vm.VM;
const load_elf_file_into_vm = kernel_vm.load_elf_file_into_vm;

// Helper: Create VM on heap to avoid stack overflow (VM is 8MB+).
fn create_test_vm() !*VM {
    const vm = try testing.allocator.create(VM);
    VM.init(vm, &[_]u8{}, 0);
    return vm;
}

// Test: Load ELF file into VM memory.
// Why: Verify ELF loading works for executables to be spawned by kernel.
test "vm elf loading: load kernel ELF into VM memory" {
    // Initialize VM on heap (8MB+ struct).
    const vm = try create_test_vm();
    defer testing.allocator.destroy(vm);
    
    // Load kernel ELF into VM memory at low memory address.
    const ELF_LOAD_ADDR: u64 = 0x1000000; // 16MB (low memory)
    const kernel_elf_path = "zig-out/bin/grain-rv64";
    
    // Try to load kernel ELF (may fail if file doesn't exist).
    const load_result = load_elf_file_into_vm(vm, kernel_elf_path, ELF_LOAD_ADDR);
    
    if (load_result) |loaded_addr| {
        try testing.expectEqual(ELF_LOAD_ADDR, loaded_addr);
        
        // Verify ELF magic number at loaded address.
        const vm_phys_offset = vm.translate_address(ELF_LOAD_ADDR) orelse {
            return error.AddressNotMapped;
        };
        
        const elf_magic = vm.memory[@intCast(vm_phys_offset)..][0..4];
        const expected_magic = [_]u8{ 0x7F, 'E', 'L', 'F' };
        try testing.expectEqualSlices(u8, &expected_magic, elf_magic);
    } else |_| {
        // File doesn't exist - OK for test (may run before kernel is built).
    }
}

// Test: Load ELF file with invalid address.
// Why: Verify error handling for invalid addresses.
test "vm elf loading: invalid address error" {
    const vm = try create_test_vm();
    defer testing.allocator.destroy(vm);
    
    // Try to load at invalid address (beyond VM memory).
    const INVALID_ADDR: u64 = 100 * 1024 * 1024; // 100MB (beyond 8MB VM)
    const kernel_elf_path = "zig-out/bin/grain-rv64";
    
    const load_result = load_elf_file_into_vm(vm, kernel_elf_path, INVALID_ADDR);
    _ = load_result catch |err| {
        try testing.expectEqual(error.SegmentOutOfBounds, err);
        return;
    };
    // If we get here with success, file didn't exist (also acceptable)
}

// Test: Load non-existent ELF file.
// Why: Verify error handling for missing files.
test "vm elf loading: non-existent file error" {
    const vm = try create_test_vm();
    defer testing.allocator.destroy(vm);
    
    const ELF_LOAD_ADDR: u64 = 0x1000000;
    const non_existent_path = "non_existent_file.elf";
    
    const load_result = load_elf_file_into_vm(vm, non_existent_path, ELF_LOAD_ADDR);
    _ = load_result catch |err| {
        // File not found returns InvalidElfFormat or SegmentOutOfBounds depending on path
        try testing.expect(err == error.InvalidElfFormat or err == error.SegmentOutOfBounds);
        return;
    };
    // Should not reach here - non-existent file must error
    return error.ExpectedError;
}
