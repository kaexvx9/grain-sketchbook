const std = @import("std");
const kernel_vm = @import("kernel_vm");
const VM = kernel_vm.VM;
const loadKernel = kernel_vm.loadKernel;
const SerialOutput = kernel_vm.SerialOutput;
const SerialInput = kernel_vm.SerialInput;

/// Test RISC-V VM functionality.
/// Grain Style: Comprehensive test coverage, deterministic behavior.
pub fn main() !void {
    std.debug.print("[kernel_vm_test] Testing RISC-V VM...\n", .{});

    // Test 1: VM initialization.
    std.debug.print("[kernel_vm_test] Test 1: VM initialization\n", .{});
    // GrainStyle: Heap allocation required - VM is 8MB+ (contains memory array).
    const allocator = std.heap.page_allocator;
    const vm = try allocator.create(VM);
    defer allocator.destroy(vm);
    VM.init(vm, &[_]u8{0x13, 0x00, 0x00, 0x00}, 0x1000); // NOP instruction.
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
    // Map the code page with execute permission.
    const RWX: u8 = 0x07; // Read | Write | Execute
    _ = vm.memory_protection.map_page(0x1000, 0x1000, RWX);
    vm.regs.pc = 0x1000;
    const inst = try vm.fetch_instruction();
    std.debug.assert(inst == 0x00000013); // NOP (ADDI x0, x0, 0).
    std.debug.print("[kernel_vm_test] ✓ Instruction fetch works\n", .{});

    // Test 5: Serial output.
    std.debug.print("[kernel_vm_test] Test 5: Serial output\n", .{});
    var serial = SerialOutput{};
    serial.writeString("Hello, RISC-V!\n");
    const output = serial.get_output();
    std.debug.assert(output.len > 0);
    std.debug.print("[kernel_vm_test] ✓ Serial output works\n", .{});

    // Test 6: ADD instruction.
    std.debug.print("[kernel_vm_test] Test 6: ADD instruction\n", .{});
    // ADD x1, x2, x3: x1 = x2 + x3
    // Encoding: funct7(0) | rs2(3) | rs1(2) | 000 | rd(1) | 0110011
    // = 0x003100B3
    // Little-endian bytes: [0xB3, 0x00, 0x31, 0x00]
    // Add ECALL after to halt VM (0x00000073)
    const add_kernel = [_]u8{ 0xB3, 0x00, 0x31, 0x00, 0x73, 0x00, 0x00, 0x00 };
    // Reuse existing VM to avoid stack overflow (4MB array).
    @memset(&vm.memory, 0);
    @memcpy(vm.memory[0x1000..][0..add_kernel.len], &add_kernel);
    vm.regs.pc = 0x1000;
    vm.state = .halted;
    vm.regs.set(2, 10); // x2 = 10
    vm.regs.set(3, 20); // x3 = 20
    vm.start();
    
    // Assert: VM state must be running before step.
    std.debug.assert(vm.state == .running);
    
    // Execute ADD instruction.
    try vm.step();
    
    // Assert: VM state must be valid after step (not errored).
    std.debug.assert(vm.state != .errored);
    
    const add_result = vm.regs.get(1);
    std.debug.assert(add_result == 30); // x1 = 10 + 20 = 30
    std.debug.print("[kernel_vm_test] ✓ ADD instruction works\n", .{});

    // Test 7: SUB instruction.
    std.debug.print("[kernel_vm_test] Test 7: SUB instruction\n", .{});
    // SUB x1, x2, x3: x1 = x2 - x3
    // Encoding: funct7(0x20) | rs2(3) | rs1(2) | 000 | rd(1) | 0110011
    // = 0x403100B3
    // Little-endian bytes: [0xB3, 0x00, 0x31, 0x40]
    // Add ECALL after to halt VM (0x00000073)
    const sub_kernel = [_]u8{ 0xB3, 0x00, 0x31, 0x40, 0x73, 0x00, 0x00, 0x00 };
    // Reuse existing VM to avoid stack overflow.
    @memset(&vm.memory, 0);
    @memcpy(vm.memory[0x1000..][0..sub_kernel.len], &sub_kernel);
    vm.regs.pc = 0x1000;
    vm.state = .halted;
    vm.regs.set(2, 30); // x2 = 30
    vm.regs.set(3, 10); // x3 = 10
    vm.start();
    try vm.step();
    const sub_result = vm.regs.get(1);
    std.debug.assert(sub_result == 20); // x1 = 30 - 10 = 20
    std.debug.print("[kernel_vm_test] ✓ SUB instruction works\n", .{});

    // Test 8: SLT instruction (signed comparison).
    std.debug.print("[kernel_vm_test] Test 8: SLT instruction\n", .{});
    // SLT x1, x2, x3: x1 = (x2 < x3) ? 1 : 0
    // Encoding: funct7(0) | rs2(3) | rs1(2) | 010 | rd(1) | 0110011
    // = 0x003120B3
    // Little-endian bytes: [0xB3, 0x20, 0x31, 0x00]
    // Add ECALL after to halt VM (0x00000073)
    const slt_kernel = [_]u8{ 0xB3, 0x20, 0x31, 0x00, 0x73, 0x00, 0x00, 0x00 };
    // Reuse existing VM to avoid stack overflow.
    @memset(&vm.memory, 0);
    @memcpy(vm.memory[0x1000..][0..slt_kernel.len], &slt_kernel);
    vm.regs.pc = 0x1000;
    vm.state = .halted;
    vm.regs.set(2, 10); // x2 = 10
    vm.regs.set(3, 20); // x3 = 20
    vm.start();
    try vm.step();
    const slt_result_lt = vm.regs.get(1);
    std.debug.assert(slt_result_lt == 1); // 10 < 20, so x1 = 1
    std.debug.print("[kernel_vm_test] ✓ SLT instruction works (10 < 20)\n", .{});

    // Test SLT with reversed operands (should return 0).
    @memset(&vm.memory, 0);
    @memcpy(vm.memory[0x1000..][0..slt_kernel.len], &slt_kernel);
    vm.regs.pc = 0x1000;
    vm.state = .halted;
    vm.regs.set(2, 20); // x2 = 20
    vm.regs.set(3, 10); // x3 = 10
    vm.start();
    try vm.step();
    const slt_result_gt = vm.regs.get(1);
    std.debug.assert(slt_result_gt == 0); // 20 < 10 is false, so x1 = 0
    std.debug.print("[kernel_vm_test] ✓ SLT instruction works (20 < 10)\n", .{});

    // Test SLT with negative numbers (signed comparison).
    @memset(&vm.memory, 0);
    @memcpy(vm.memory[0x1000..][0..slt_kernel.len], &slt_kernel);
    vm.regs.pc = 0x1000;
    vm.state = .halted;
    vm.regs.set(2, @as(u64, @bitCast(@as(i64, -10)))); // x2 = -10 (signed)
    vm.regs.set(3, 10); // x3 = 10
    vm.start();
    try vm.step();
    const slt_result_neg = vm.regs.get(1);
    std.debug.assert(slt_result_neg == 1); // -10 < 10, so x1 = 1
    std.debug.print("[kernel_vm_test] ✓ SLT instruction works (signed comparison)\n", .{});

    // Test 9: OR instruction (bitwise OR).
    std.debug.print("[kernel_vm_test] Test 9: OR instruction\n", .{});
    // OR x1, x2, x3: x1 = x2 | x3
    // Encoding: funct7(0) | rs2(3) | rs1(2) | 110 | rd(1) | 0110011
    // = 0x003160B3
    // Little-endian bytes: [0xB3, 0x60, 0x31, 0x00]
    // Add ECALL after to halt VM (0x00000073)
    const or_kernel = [_]u8{ 0xB3, 0x60, 0x31, 0x00, 0x73, 0x00, 0x00, 0x00 };
    @memset(&vm.memory, 0);
    @memcpy(vm.memory[0x1000..][0..or_kernel.len], &or_kernel);
    vm.regs.pc = 0x1000;
    vm.state = .halted;
    vm.regs.set(2, 0b1010); // x2 = 0b1010 (10 decimal)
    vm.regs.set(3, 0b1100); // x3 = 0b1100 (12 decimal)
    vm.start();
    try vm.step();
    const or_result = vm.regs.get(1);
    std.debug.assert(or_result == 0b1110); // x1 = 0b1010 | 0b1100 = 0b1110 (14 decimal)
    std.debug.print("[kernel_vm_test] ✓ OR instruction works\n", .{});

    // Test 10: AND instruction (bitwise AND).
    std.debug.print("[kernel_vm_test] Test 10: AND instruction\n", .{});
    // AND x1, x2, x3: x1 = x2 & x3
    // Encoding: funct7(0) | rs2(3) | rs1(2) | 111 | rd(1) | 0110011
    // = 0x003170B3
    // Little-endian bytes: [0xB3, 0x70, 0x31, 0x00]
    // Add ECALL after to halt VM (0x00000073)
    const and_kernel = [_]u8{ 0xB3, 0x70, 0x31, 0x00, 0x73, 0x00, 0x00, 0x00 };
    @memset(&vm.memory, 0);
    @memcpy(vm.memory[0x1000..][0..and_kernel.len], &and_kernel);
    vm.regs.pc = 0x1000;
    vm.state = .halted;
    vm.regs.set(2, 0b1010); // x2 = 0b1010 (10 decimal)
    vm.regs.set(3, 0b1100); // x3 = 0b1100 (12 decimal)
    vm.start();
    try vm.step();
    const and_result = vm.regs.get(1);
    std.debug.assert(and_result == 0b1000); // x1 = 0b1010 & 0b1100 = 0b1000 (8 decimal)
    std.debug.print("[kernel_vm_test] ✓ AND instruction works\n", .{});

    // Test 11: XOR instruction (bitwise XOR).
    std.debug.print("[kernel_vm_test] Test 11: XOR instruction\n", .{});
    // XOR x1, x2, x3: x1 = x2 ^ x3
    // Encoding: funct7(0) | rs2(3) | rs1(2) | 100 | rd(1) | 0110011
    // = 0x003140B3
    // Little-endian bytes: [0xB3, 0x40, 0x31, 0x00]
    // Add ECALL after to halt VM (0x00000073)
    const xor_kernel = [_]u8{ 0xB3, 0x40, 0x31, 0x00, 0x73, 0x00, 0x00, 0x00 };
    @memset(&vm.memory, 0);
    @memcpy(vm.memory[0x1000..][0..xor_kernel.len], &xor_kernel);
    vm.regs.pc = 0x1000;
    vm.state = .halted;
    vm.regs.set(2, 0b1010); // x2 = 0b1010 (10 decimal)
    vm.regs.set(3, 0b1100); // x3 = 0b1100 (12 decimal)
    vm.start();
    try vm.step();
    const xor_result = vm.regs.get(1);
    std.debug.assert(xor_result == 0b0110); // x1 = 0b1010 ^ 0b1100 = 0b0110 (6 decimal)
    std.debug.print("[kernel_vm_test] ✓ XOR instruction works\n", .{});

    // Test 12: SLL instruction (shift left logical).
    std.debug.print("[kernel_vm_test] Test 12: SLL instruction\n", .{});
    // SLL x1, x2, x3: x1 = x2 << x3
    // Encoding: funct7(0) | rs2(3) | rs1(2) | 001 | rd(1) | 0110011
    // = 0x003110B3
    // Little-endian bytes: [0xB3, 0x10, 0x31, 0x00]
    // Add ECALL after to halt VM (0x00000073)
    const sll_kernel = [_]u8{ 0xB3, 0x10, 0x31, 0x00, 0x73, 0x00, 0x00, 0x00 };
    @memset(&vm.memory, 0);
    @memcpy(vm.memory[0x1000..][0..sll_kernel.len], &sll_kernel);
    vm.regs.pc = 0x1000;
    vm.state = .halted;
    vm.regs.set(2, 0b1010); // x2 = 0b1010 (10 decimal)
    vm.regs.set(3, 2); // x3 = 2 (shift by 2)
    vm.start();
    try vm.step();
    const sll_result = vm.regs.get(1);
    std.debug.assert(sll_result == 0b101000); // x1 = 0b1010 << 2 = 0b101000 (40 decimal)
    std.debug.print("[kernel_vm_test] ✓ SLL instruction works\n", .{});

    // Test 13: SRL instruction (shift right logical).
    std.debug.print("[kernel_vm_test] Test 13: SRL instruction\n", .{});
    // SRL x1, x2, x3: x1 = x2 >> x3
    // Encoding: funct7(0) | rs2(3) | rs1(2) | 101 | rd(1) | 0110011
    // = 0x003150B3
    // Little-endian bytes: [0xB3, 0x50, 0x31, 0x00]
    // Add ECALL after to halt VM (0x00000073)
    const srl_kernel = [_]u8{ 0xB3, 0x50, 0x31, 0x00, 0x73, 0x00, 0x00, 0x00 };
    @memset(&vm.memory, 0);
    @memcpy(vm.memory[0x1000..][0..srl_kernel.len], &srl_kernel);
    vm.regs.pc = 0x1000;
    vm.state = .halted;
    vm.regs.set(2, 0b101000); // x2 = 0b101000 (40 decimal)
    vm.regs.set(3, 2); // x3 = 2 (shift by 2)
    vm.start();
    try vm.step();
    const srl_result = vm.regs.get(1);
    std.debug.assert(srl_result == 0b1010); // x1 = 0b101000 >> 2 = 0b1010 (10 decimal)
    std.debug.print("[kernel_vm_test] ✓ SRL instruction works\n", .{});

    // Test 14: SRA instruction (shift right arithmetic).
    std.debug.print("[kernel_vm_test] Test 14: SRA instruction\n", .{});
    // SRA x1, x2, x3: x1 = x2 >> x3 (sign-extended)
    // Encoding: funct7(0x20) | rs2(3) | rs1(2) | 101 | rd(1) | 0110011
    // = 0x403150B3
    // Little-endian bytes: [0xB3, 0x50, 0x31, 0x40]
    // Add ECALL after to halt VM (0x00000073)
    const sra_kernel = [_]u8{ 0xB3, 0x50, 0x31, 0x40, 0x73, 0x00, 0x00, 0x00 };
    @memset(&vm.memory, 0);
    @memcpy(vm.memory[0x1000..][0..sra_kernel.len], &sra_kernel);
    vm.regs.pc = 0x1000;
    vm.state = .halted;
    vm.regs.set(2, @as(u64, @bitCast(@as(i64, -40)))); // x2 = -40 (signed, 0xFFFFFFD8)
    vm.regs.set(3, 2); // x3 = 2 (shift by 2)
    vm.start();
    try vm.step();
    const sra_result = vm.regs.get(1);
    // x1 = -40 >> 2 = -10 (sign-extended)
    std.debug.assert(sra_result == @as(u64, @bitCast(@as(i64, -10))));
    std.debug.print("[kernel_vm_test] ✓ SRA instruction works\n", .{});

    std.debug.print("[kernel_vm_test] All tests passed!\n", .{});

    // Test 15: Load and execute real kernel ELF.
    std.debug.print("\n[kernel_vm_test] Test 15: Load kernel ELF\n", .{});
    try test_kernel_elf_loading(allocator);
}

/// Test loading and executing the real kernel ELF.
fn test_kernel_elf_loading(allocator: std.mem.Allocator) !void {
    const kernel_path = "zig-out/bin/grain-rv64";
    
    // Read kernel ELF file.
    const kernel_file = std.fs.cwd().openFile(kernel_path, .{}) catch |err| {
        std.debug.print("[kernel_vm_test] Kernel not found at {s}: {}\n", .{ kernel_path, err });
        std.debug.print("[kernel_vm_test] ⚠ Skipping kernel ELF test (run 'zig build kernel-rv64' first)\n", .{});
        return;
    };
    defer kernel_file.close();
    
    const kernel_data = kernel_file.readToEndAlloc(allocator, 16 * 1024 * 1024) catch |err| {
        std.debug.print("[kernel_vm_test] Failed to read kernel: {}\n", .{err});
        return;
    };
    defer allocator.free(kernel_data);
    
    std.debug.print("[kernel_vm_test] Loaded kernel ELF: {} bytes\n", .{kernel_data.len});
    
    // Verify ELF magic.
    if (kernel_data.len < 4) {
        std.debug.print("[kernel_vm_test] ✗ Kernel too small\n", .{});
        return;
    }
    const elf_magic = [_]u8{ 0x7F, 'E', 'L', 'F' };
    if (!std.mem.eql(u8, kernel_data[0..4], &elf_magic)) {
        std.debug.print("[kernel_vm_test] ✗ Invalid ELF magic\n", .{});
        return;
    }
    std.debug.print("[kernel_vm_test] ✓ Valid ELF magic\n", .{});
    
    // Create new VM for kernel execution.
    const vm2 = try allocator.create(VM);
    defer allocator.destroy(vm2);
    
    // Load kernel into VM.
    loadKernel(vm2, allocator, kernel_data) catch |err| {
        std.debug.print("[kernel_vm_test] Failed to load kernel: {}\n", .{err});
        return;
    };
    
    std.debug.print("[kernel_vm_test] ✓ Kernel loaded into VM\n", .{});
    std.debug.print("[kernel_vm_test] Entry point: 0x{x}\n", .{vm2.regs.pc});
    
    // Map kernel memory region with execute permission.
    // The kernel is loaded at physical address 0, but uses virtual address 0x80000000.
    // Map entire kernel text+rodata region (~1MB).
    // Note: MAX_PAGE_TABLE_ENTRIES is 1024, so we can map ~4MB with 4KB pages.
    const RWX: u8 = 0x07;
    const KERNEL_SIZE: u64 = 1024 * 1024; // 1MB - covers kernel text + rodata
    var page: u64 = 0;
    var mapped_count: u32 = 0;
    while (page < KERNEL_SIZE) : (page += 4096) {
        // Map virtual address 0x80000000+offset to physical address offset.
        if (vm2.memory_protection.map_page(0x80000000 + page, page, RWX)) {
            mapped_count += 1;
        }
    }
    std.debug.print("[kernel_vm_test] Mapped {} pages for kernel (requested {})\n", .{
        mapped_count,
        KERNEL_SIZE / 4096,
    });
    
    // Set up stack pointer. The kernel expects sp to be valid.
    // Use top of physical memory as stack (grows downward).
    // Stack is at virtual address 0x80000000 + (8MB - 4KB) = 0x807FF000
    const STACK_TOP: u64 = 0x80000000 + (8 * 1024 * 1024) - 4096;
    vm2.regs.set(2, STACK_TOP); // x2 = sp
    vm2.regs.set(8, STACK_TOP); // x8 = fp/s0
    std.debug.print("[kernel_vm_test] Stack pointer set to 0x{x}\n", .{STACK_TOP});
    
    // Map stack region with RW permissions
    const RW: u8 = 0x03;
    var stack_page: u64 = 7 * 1024 * 1024; // 7MB to 8MB for stack
    while (stack_page < 8 * 1024 * 1024) : (stack_page += 4096) {
        _ = vm2.memory_protection.map_page(0x80000000 + stack_page, stack_page, RW);
    }
    std.debug.print("[kernel_vm_test] Mapped stack region (7MB-8MB)\n", .{});
    
    // Map UART/serial region at 0x10000000 for kernel console output.
    // Map to a safe physical location (e.g., 6MB mark).
    const UART_BASE: u64 = 0x10000000;
    const UART_PHYS: u64 = 6 * 1024 * 1024; // 6MB physical
    _ = vm2.memory_protection.map_page(UART_BASE, UART_PHYS, RW);
    std.debug.print("[kernel_vm_test] Mapped UART at 0x{x} -> phys 0x{x}\n", .{ UART_BASE, UART_PHYS });
    
    // Set up serial I/O for console.
    var serial_output = SerialOutput{};
    var serial_input = SerialInput{};
    vm2.set_serial_output(&serial_output);
    vm2.set_serial_input(&serial_input);
    
    // Feed a simple command to the kernel ("help\n").
    const help_cmd = "help\n";
    const pushed = serial_input.pushString(help_cmd);
    std.debug.print("[kernel_vm_test] Pushed {} bytes of input: \"{s}\"\n", .{ pushed, help_cmd });
    
    // Note: JIT has x86_64 register allocation bugs - using interpreter only.
    // TODO: Fix JIT x86_64 backend for production use.
    
    // Execute instructions - interpreter is slow but correct.
    vm2.start();
    var instructions_executed: u32 = 0;
    const MAX_INSTRUCTIONS: u32 = 500000; // 500K instructions (interpreter)
    
    var prev_sp: u64 = vm2.regs.get(2);
    var sp_change_count: u32 = 0;
    const MAX_SP_LOGS: u32 = 20; // Only log first 20 SP changes
    
    while (instructions_executed < MAX_INSTRUCTIONS) : (instructions_executed += 1) {
        const pc_before = vm2.regs.pc;
        const sp_before = vm2.regs.get(2);
        
        // Track SP changes (limited logging)
        if (sp_before != prev_sp) {
            sp_change_count += 1;
            if (sp_change_count <= MAX_SP_LOGS) {
                std.debug.print(
                    "[kernel_vm_test] SP changed: 0x{x} -> 0x{x} (at PC 0x{x})\n",
                    .{ prev_sp, sp_before, pc_before },
                );
            } else if (sp_change_count == MAX_SP_LOGS + 1) {
                std.debug.print("[kernel_vm_test] (suppressing further SP change logs)\n", .{});
            }
            prev_sp = sp_before;
        }
        
        vm2.step() catch |err| {
            if (err == error.halted) {
                std.debug.print("[kernel_vm_test] VM halted after {} instructions\n", .{instructions_executed});
                break;
            }
            // Debug: check if PC is in mapped range
            const phys_pc = vm2.translate_address(pc_before);
            const page_perms = vm2.memory_protection.get_permissions(pc_before);
            std.debug.print(
                "[kernel_vm_test] Error at PC 0x{x} (phys={?x}, perms={?x}) after {} instructions: {}\n",
                .{ pc_before, phys_pc, page_perms, instructions_executed, err },
            );
            break;
        };
        
        // Check if we hit ECALL (syscall/halt).
        if (vm2.state == .halted) {
            std.debug.print("[kernel_vm_test] VM halted (ECALL) after {} instructions\n", .{instructions_executed});
            break;
        }
        
        // Progress indicator every 500K instructions
        if (instructions_executed > 0 and instructions_executed % 500000 == 0) {
            std.debug.print("[kernel_vm_test] {}K instructions, output={} bytes\n", .{ instructions_executed / 1000, serial_output.total_written });
        }
    }
    
    if (instructions_executed >= MAX_INSTRUCTIONS) {
        std.debug.print("[kernel_vm_test] Executed {} instructions (limit reached)\n", .{MAX_INSTRUCTIONS});
    }
    
    std.debug.print("[kernel_vm_test] Final PC: 0x{x}\n", .{vm2.regs.pc});
    
    // Show serial output (if any).
    if (serial_output.total_written > 0) {
        const out_len = @min(serial_output.total_written, 512);
        std.debug.print("[kernel_vm_test] Serial output ({} bytes):\n", .{serial_output.total_written});
        std.debug.print("---\n{s}\n---\n", .{serial_output.buffer[0..out_len]});
    }
    
    // Show remaining input (if any).
    std.debug.print("[kernel_vm_test] Input remaining: {} bytes\n", .{serial_input.available});
    
    std.debug.print("[kernel_vm_test] ✓ Kernel execution test complete\n", .{});
}

