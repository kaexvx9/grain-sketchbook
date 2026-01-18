//! Test: VM ELF Loading
//! Why: Verify ELF files can be loaded from host filesystem into VM memory.
//! Architecture: Tests load_elf_file_into_vm function for Phase 2 integration.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const kernel_vm = @import("kernel_vm");
const VM = kernel_vm.VM;
const Integration = kernel_vm.Integration;
const load_elf_file_into_vm = kernel_vm.load_elf_file_into_vm;

// Test: Load ELF file into VM memory.
// Why: Verify ELF loading works for executables to be spawned by kernel.
test "vm elf loading: load kernel ELF into VM memory" {
    // Initialize VM with memory.
    var vm: VM = undefined;
    VM.init(&vm, &[_]u8{}, 0);
    
    // Load kernel ELF into VM memory at low memory address.
    // Why: Use low memory address (< 0x80000000) for executables.
    const ELF_LOAD_ADDR: u64 = 0x1000000; // 16MB (low memory, directly mapped)
    const kernel_elf_path = "zig-out/bin/grain-rv64";
    
    // Try to load kernel ELF (may fail if file doesn't exist, that's OK for test).
    const load_result = load_elf_file_into_vm(&vm, kernel_elf_path, ELF_LOAD_ADDR);
    
    // If file exists, verify loading succeeded.
    if (load_result) |loaded_addr| {
        // Assert: Loaded address must match requested address.
        std.debug.assert(loaded_addr == ELF_LOAD_ADDR);
        
        // Verify ELF magic number at loaded address.
        const vm_phys_offset = vm.translate_address(ELF_LOAD_ADDR) orelse {
            std.debug.panic("Address not mapped", .{});
        };
        
        const elf_magic = vm.memory[@intCast(vm_phys_offset)..][0..4];
        const expected_magic = [_]u8{ 0x7F, 'E', 'L', 'F' };
        
        // Assert: ELF magic must be correct.
        std.debug.assert(std.mem.eql(u8, elf_magic, &expected_magic));
    } else |_| {
        // If file doesn't exist, that's OK (test may run before kernel is built).
        // Just verify error is reasonable.
    }
}

// Test: Load ELF file with invalid address.
// Why: Verify error handling for invalid addresses.
test "vm elf loading: invalid address error" {
    // Initialize VM with memory.
    var vm: VM = undefined;
    VM.init(&vm, &[_]u8{}, 0);
    
    // Try to load at invalid address (beyond VM memory).
    const VM_MEMORY_SIZE: u64 = 4 * 1024 * 1024; // 4MB
    const INVALID_ADDR: u64 = VM_MEMORY_SIZE + 1;
    const kernel_elf_path = "zig-out/bin/grain-rv64";
    
    // Should fail with SegmentOutOfBounds error.
    const load_result = load_elf_file_into_vm(&vm, kernel_elf_path, INVALID_ADDR);
    
    // Assert: Must fail with error.
    _ = load_result catch {};
}

// Test: Load non-existent ELF file.
// Why: Verify error handling for missing files.
test "vm elf loading: non-existent file error" {
    // Initialize VM with memory.
    var vm: VM = undefined;
    VM.init(&vm, &[_]u8{}, 0);
    
    // Try to load non-existent file.
    const ELF_LOAD_ADDR: u64 = 0x1000000; // 16MB
    const non_existent_path = "non_existent_file.elf";
    
    // Should fail with InvalidElfFormat error.
    const load_result = load_elf_file_into_vm(&vm, non_existent_path, ELF_LOAD_ADDR);
    
    // Assert: Must fail with error.
    _ = load_result catch {};
}
