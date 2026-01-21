//! Basin Kernel Integration Test
//! Why: Verify Basin kernel ELF can be loaded and executed by RISC-V core.
//! Tests both console output and keyboard input (REPL).

const std = @import("std");
const riscv = @import("riscv_core.zig");

// Test console output buffer
var console_output: [4096]u8 = undefined;
var console_pos: usize = 0;

/// Load Basin ELF into VM memory.
fn load_basin_elf(vm_memory: []u8, basin_elf: []const u8) !u64 {
    if (basin_elf.len < 64) return error.InvalidElf;

    // Check ELF magic
    if (basin_elf[0] != 0x7F or basin_elf[1] != 'E' or
        basin_elf[2] != 'L' or basin_elf[3] != 'F')
    {
        return error.InvalidElf;
    }

    // Read entry point
    var entry: u64 = 0;
    for (0..8) |i| {
        entry |= @as(u64, basin_elf[24 + i]) << @intCast(i * 8);
    }

    // Read program header offset
    var phoff: u64 = 0;
    for (0..8) |i| {
        phoff |= @as(u64, basin_elf[32 + i]) << @intCast(i * 8);
    }

    // Read program header count
    const phnum: u16 = @as(u16, basin_elf[56]) | (@as(u16, basin_elf[57]) << 8);

    // Load PT_LOAD segments
    const KERNEL_BASE: u64 = 0x80000000;

    for (0..phnum) |ph_idx| {
        const ph_offset = phoff + ph_idx * 56;
        if (ph_offset + 56 > basin_elf.len) break;

        const p_type: u32 = @as(u32, basin_elf[@intCast(ph_offset)]) |
            (@as(u32, basin_elf[@intCast(ph_offset + 1)]) << 8) |
            (@as(u32, basin_elf[@intCast(ph_offset + 2)]) << 16) |
            (@as(u32, basin_elf[@intCast(ph_offset + 3)]) << 24);

        var p_off: u64 = 0;
        var p_vaddr: u64 = 0;
        var p_filesz: u64 = 0;
        var p_memsz: u64 = 0;

        for (0..8) |i| {
            p_off |= @as(u64, basin_elf[@intCast(ph_offset + 8 + i)]) << @intCast(i * 8);
            p_vaddr |= @as(u64, basin_elf[@intCast(ph_offset + 16 + i)]) << @intCast(i * 8);
            p_filesz |= @as(u64, basin_elf[@intCast(ph_offset + 32 + i)]) << @intCast(i * 8);
            p_memsz |= @as(u64, basin_elf[@intCast(ph_offset + 40 + i)]) << @intCast(i * 8);
        }

        if (p_type != 1) continue;

        const phys_addr = if (p_vaddr >= KERNEL_BASE) p_vaddr - KERNEL_BASE else p_vaddr;

        if (phys_addr + p_filesz <= vm_memory.len and p_off + p_filesz <= basin_elf.len) {
            @memcpy(
                vm_memory[@intCast(phys_addr)..@intCast(phys_addr + p_filesz)],
                basin_elf[@intCast(p_off)..@intCast(p_off + p_filesz)],
            );
        }

        if (p_memsz > p_filesz and phys_addr + p_memsz <= vm_memory.len) {
            @memset(
                vm_memory[@intCast(phys_addr + p_filesz)..@intCast(phys_addr + p_memsz)],
                0,
            );
        }
    }

    return entry;
}

/// Run core with SBI handling, returns instruction count.
fn run_core(core: *riscv.RiscvCore, max_instructions: u64) u64 {
    var instructions: u64 = 0;

    core.state = .running;
    while (instructions < max_instructions) {
        if (!core.step()) {
            if (core.state == .ecall) {
                const ext_id = core.get_reg(17);
                const arg0 = core.get_reg(10);

                if (ext_id == 0x01) {
                    // Console putchar
                    const c: u8 = @truncate(arg0);
                    if (console_pos < console_output.len) {
                        console_output[console_pos] = c;
                        console_pos += 1;
                    }
                    core.set_reg(10, 0);
                    core.set_reg(11, 0);
                    core.state = .running;
                    core.regs.pc += 4;
                } else if (ext_id == 0x02) {
                    // Console getchar - use core's input buffer
                    if (core.pop_input()) |c| {
                        core.set_reg(10, c);
                    } else {
                        core.set_reg(10, @bitCast(@as(i64, -1)));
                    }
                    core.set_reg(11, 0);
                    core.state = .running;
                    core.regs.pc += 4;
                } else if (ext_id == 0x53525354) {
                    // System reset
                    core.state = .halted;
                    break;
                } else {
                    core.set_reg(10, @bitCast(@as(i64, -2)));
                    core.set_reg(11, 0);
                    core.state = .running;
                    core.regs.pc += 4;
                }
            } else {
                break;
            }
        }
        instructions += 1;
    }

    return instructions;
}

test "basin integration: REPL with commands" {
    // Reset console
    console_pos = 0;
    @memset(&console_output, 0);

    // Allocate VM memory
    const vm_memory = try std.testing.allocator.alloc(u8, 8 * 1024 * 1024);
    defer std.testing.allocator.free(vm_memory);
    @memset(vm_memory, 0);

    // Load Basin kernel
    const basin_file = std.fs.cwd().openFile("zig-out/bin/basin-rv64", .{}) catch |err| {
        std.debug.print("Failed to open basin-rv64: {}. Run 'zig build basin-rv64' first.\n", .{err});
        return error.FileNotFound;
    };
    defer basin_file.close();

    const basin_elf = try basin_file.readToEndAlloc(std.testing.allocator, 1024 * 1024);
    defer std.testing.allocator.free(basin_elf);

    const entry = try load_basin_elf(vm_memory, basin_elf);

    // Initialize core
    var core: riscv.RiscvCore = .{};
    core.init(vm_memory.ptr, vm_memory.len);
    core.set_pc(entry);

    // Queue input: h=help, f=fib(0), f=fib(1), f=fib(2), q=quit
    _ = core.push_input('h');
    _ = core.push_input('f');
    _ = core.push_input('f');
    _ = core.push_input('f');
    _ = core.push_input('q');

    // Run kernel
    const instructions = run_core(&core, 1_000_000);

    // Get output
    const output = console_output[0..console_pos];

    // Verify kernel ran and shutdown
    try std.testing.expect(instructions > 0);
    try std.testing.expectEqual(riscv.VMState.halted, core.state);

    // Check banner
    try std.testing.expect(std.mem.indexOf(u8, output, "Basin Kernel") != null);

    // Check help output
    try std.testing.expect(std.mem.indexOf(u8, output, "h:help") != null);

    // Check fib outputs
    try std.testing.expect(std.mem.indexOf(u8, output, "fib(0)=0") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "fib(1)=1") != null);
    try std.testing.expect(std.mem.indexOf(u8, output, "fib(2)=1") != null);

    // Check goodbye
    try std.testing.expect(std.mem.indexOf(u8, output, "Goodbye!") != null);
}
