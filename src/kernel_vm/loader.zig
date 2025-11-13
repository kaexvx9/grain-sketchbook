const std = @import("std");
const VM = @import("vm.zig").VM;

/// RISC-V64 ELF kernel loader.
/// Tiger Style: Static allocation where possible, comprehensive assertions.
/// ~<~ Glow Earthbend: ELF parsing is explicit, no hidden allocations.

/// ELF header structure (64-bit, little-endian).
/// Why: Explicit ELF structure for kernel loading.
const Elf64_Ehdr = extern struct {
    /// ELF magic number: 0x7F "ELF".
    e_ident: [16]u8,
    /// Object file type (1 = relocatable, 2 = executable, 3 = shared).
    e_type: u16,
    /// Machine architecture (243 = RISC-V).
    e_machine: u16,
    /// Object file version (usually 1).
    e_version: u32,
    /// Entry point virtual address.
    e_entry: u64,
    /// Program header table file offset.
    e_phoff: u64,
    /// Section header table file offset.
    e_shoff: u64,
    /// Processor-specific flags.
    e_flags: u32,
    /// ELF header size in bytes.
    e_ehsize: u16,
    /// Program header table entry size.
    e_phentsize: u16,
    /// Program header table entry count.
    e_phnum: u16,
    /// Section header table entry size.
    e_shentsize: u16,
    /// Section header table entry count.
    e_shnum: u16,
    /// Section header string table index.
    e_shstrndx: u16,
};

/// Program header structure (64-bit, little-endian).
/// Why: Explicit program header for loading kernel segments.
const Elf64_Phdr = extern struct {
    /// Segment type (1 = loadable).
    p_type: u32,
    /// Segment flags (read, write, execute).
    p_flags: u32,
    /// Segment file offset.
    p_offset: u64,
    /// Segment virtual address.
    p_vaddr: u64,
    /// Segment physical address.
    p_paddr: u64,
    /// Segment size in file.
    p_filesz: u64,
    /// Segment size in memory.
    p_memsz: u64,
    /// Segment alignment.
    p_align: u64,
};

/// ELF magic number: 0x7F "ELF".
const ELF_MAGIC = [_]u8{ 0x7F, 'E', 'L', 'F' };

/// Load RISC-V64 kernel ELF into VM.
/// Why: Parse ELF file and load kernel segments into VM memory.
/// Note: allocator parameter reserved for future use (ELF parsing may need allocation).
pub fn loadKernel(_: std.mem.Allocator, elf_data: []const u8) !VM {
    // Assert: ELF data must be non-empty.
    std.debug.assert(elf_data.len > 0);
    
    // Assert: ELF data must be large enough for ELF header.
    std.debug.assert(elf_data.len >= @sizeOf(Elf64_Ehdr));
    
    // Parse ELF header.
    const ehdr = @as(*const Elf64_Ehdr, @ptrCast(elf_data.ptr));
    
    // Assert: ELF magic number must match.
    std.debug.assert(std.mem.eql(u8, &ehdr.e_ident[0..4], &ELF_MAGIC));
    
    // Assert: ELF class must be 64-bit (e_ident[4] = 2).
    std.debug.assert(ehdr.e_ident[4] == 2);
    
    // Assert: ELF endianness must be little-endian (e_ident[5] = 1).
    std.debug.assert(ehdr.e_ident[5] == 1);
    
    // Assert: ELF version must be 1 (e_ident[6] = 1).
    std.debug.assert(ehdr.e_ident[6] == 1);
    
    // Assert: Machine architecture must be RISC-V (243).
    std.debug.assert(ehdr.e_machine == 243);
    
    // Assert: ELF type must be executable (2).
    std.debug.assert(ehdr.e_type == 2);
    
    // Assert: Program header table must be present.
    std.debug.assert(ehdr.e_phnum > 0);
    std.debug.assert(ehdr.e_phoff > 0);
    
    // Assert: Program header table must fit in ELF data.
    const phdr_size = @as(usize, ehdr.e_phnum) * @sizeOf(Elf64_Phdr);
    std.debug.assert(ehdr.e_phoff + phdr_size <= elf_data.len);
    
    // Initialize VM (will be populated with kernel segments).
    var vm = VM.init(&[_]u8{}, 0);
    
    // Load each program header segment.
    // Why: Load kernel code/data segments into VM memory.
    const phdr_base = elf_data[@intCast(ehdr.e_phoff)..];
    var phdr_idx: u16 = 0;
    while (phdr_idx < ehdr.e_phnum) : (phdr_idx += 1) {
        const phdr_offset = phdr_idx * @sizeOf(Elf64_Phdr);
        std.debug.assert(phdr_offset + @sizeOf(Elf64_Phdr) <= phdr_base.len);
        
        const phdr = @as(*const Elf64_Phdr, @ptrCast(phdr_base.ptr + phdr_offset));
        
        // Only load PT_LOAD segments (type 1).
        if (phdr.p_type == 1) {
            // Assert: Segment must fit in ELF data.
            std.debug.assert(phdr.p_offset + phdr.p_filesz <= elf_data.len);
            
            // Assert: Segment must fit in VM memory.
            std.debug.assert(phdr.p_vaddr + phdr.p_memsz <= vm.memory_size);
            
            // Load segment data into VM memory.
            const segment_data = elf_data[@intCast(phdr.p_offset)..][0..@intCast(phdr.p_filesz)];
            @memcpy(vm.memory[@intCast(phdr.p_vaddr)..][0..segment_data.len], segment_data);
            
            // Zero-fill memory beyond file size (if memsz > filesz).
            if (phdr.p_memsz > phdr.p_filesz) {
                const zero_start = @as(usize, @intCast(phdr.p_vaddr + phdr.p_filesz));
                const zero_len = @as(usize, @intCast(phdr.p_memsz - phdr.p_filesz));
                @memset(vm.memory[zero_start..][0..zero_len], 0);
            }
        }
    }
    
    // Set VM PC to ELF entry point.
    vm.regs.pc = ehdr.e_entry;
    
    // Assert: PC must be set to entry point.
    std.debug.assert(vm.regs.pc == ehdr.e_entry);
    
    return vm;
}

