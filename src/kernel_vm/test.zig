const std = @import("std");
const kernel_vm = @import("kernel_vm");
const VM = kernel_vm.VM;
const loadKernel = kernel_vm.loadKernel;
const SerialOutput = kernel_vm.SerialOutput;

/// Test RISC-V VM functionality.
/// Tiger Style: Comprehensive test coverage, deterministic behavior.
pub fn main() !void {
    std.debug.print("[kernel_vm_test] Testing RISC-V VM...\n", .{});

    // Test 1: VM initialization.
    std.debug.print("[kernel_vm_test] Test 1: VM initialization\n", .{});
    var vm = VM.init(&[_]u8{0x13, 0x00, 0x00, 0x00}, 0x1000); // NOP instruction.
    std.debug.assert(vm.regs.pc == 0x1000);
    std.debug.assert(vm.state == .halted);
    std.debug.print("[kernel_vm_test] ✓ VM initialized correctly\n", .{});

    // Test 2: Register file (x0 hardwired to zero).
    std.debug.print("[kernel_vm_test] Test 2: Register file (x0 hardwired)\n", .{});
    vm.regs.set(0, 0x12345678);
    const x0_value = vm.regs.get(0);
    std.debug.assert(x0_value == 0); // x0 must always be zero.
    std.debug.print("[kernel_vm_test] ✓ x0 hardwired to zero\n", .{});

    // Test 3: Memory read/write.
    std.debug.print("[kernel_vm_test] Test 3: Memory read/write\n", .{});
    try vm.write64(0x2000, 0xDEADBEEFCAFEBABE);
    const read_value = try vm.read64(0x2000);
    std.debug.assert(read_value == 0xDEADBEEFCAFEBABE);
    std.debug.print("[kernel_vm_test] ✓ Memory read/write works\n", .{});

    // Test 4: Instruction fetch.
    std.debug.print("[kernel_vm_test] Test 4: Instruction fetch\n", .{});
    vm.regs.pc = 0x1000;
    const inst = try vm.fetchInstruction();
    std.debug.assert(inst == 0x00000013); // NOP (ADDI x0, x0, 0).
    std.debug.print("[kernel_vm_test] ✓ Instruction fetch works\n", .{});

    // Test 5: Serial output.
    std.debug.print("[kernel_vm_test] Test 5: Serial output\n", .{});
    var serial = SerialOutput{};
    serial.writeString("Hello, RISC-V!\n");
    const output = serial.getOutput();
    std.debug.assert(output.len > 0);
    std.debug.print("[kernel_vm_test] ✓ Serial output works\n", .{});

    std.debug.print("[kernel_vm_test] All tests passed!\n", .{});
}

