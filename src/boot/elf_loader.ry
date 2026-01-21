//! x86_64 ELF Loader for UEFI Bootloader
//! Why: Load Basin kernel ELF into memory before jumping to it.
//! Grain Style: Explicit types, static allocation, comprehensive assertions.

const std = @import("std");

/// ELF header structure (64-bit, little-endian).
/// Why: Explicit ELF structure for kernel loading.
pub const Elf64_Ehdr = extern struct {
    /// ELF magic number: 0x7F "ELF".
    e_ident: [16]u8,
    /// Object file type (2 = executable).
    e_type: u16,
    /// Machine architecture (0x3E = x86_64).
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
pub const Elf64_Phdr = extern struct {
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
pub const ELF_MAGIC = [_]u8{ 0x7F, 'E', 'L', 'F' };

/// ELF machine type for x86_64.
pub const EM_X86_64: u16 = 0x3E;

/// ELF class for 64-bit.
pub const ELFCLASS64: u8 = 2;

/// ELF data encoding for little-endian.
pub const ELFDATA2LSB: u8 = 1;

/// Program header type: loadable segment.
pub const PT_LOAD: u32 = 1;

/// Program header flags.
pub const PF_X: u32 = 1; // Executable
pub const PF_W: u32 = 2; // Writable
pub const PF_R: u32 = 4; // Readable

/// Loader errors.
pub const LoaderError = error{
    InvalidElfMagic,
    InvalidElfClass,
    InvalidElfEndian,
    InvalidElfMachine,
    InvalidElfType,
    SegmentOutOfBounds,
    ProgramHeaderOutOfBounds,
};

/// Loaded kernel information.
/// Why: Return information about loaded kernel to bootloader.
pub const LoadedKernel = struct {
    /// Entry point address.
    entry_point: u64,
    /// Lowest loaded address.
    load_base: u64,
    /// Highest loaded address + 1.
    load_end: u64,
    /// Number of segments loaded.
    segments_loaded: u32,
};

/// Validate ELF header.
/// Why: Ensure ELF file is valid x86_64 executable.
pub fn validate_elf_header(header: *const Elf64_Ehdr) LoaderError!void {
    // Check magic number
    if (!std.mem.eql(u8, header.e_ident[0..4], &ELF_MAGIC)) {
        return LoaderError.InvalidElfMagic;
    }

    // Check 64-bit class
    if (header.e_ident[4] != ELFCLASS64) {
        return LoaderError.InvalidElfClass;
    }

    // Check little-endian
    if (header.e_ident[5] != ELFDATA2LSB) {
        return LoaderError.InvalidElfEndian;
    }

    // Check x86_64 machine
    if (header.e_machine != EM_X86_64) {
        return LoaderError.InvalidElfMachine;
    }

    // Check executable type
    if (header.e_type != 2) {
        return LoaderError.InvalidElfType;
    }
}

/// Load x86_64 ELF kernel into memory.
/// Why: Parse ELF and load segments to their physical addresses.
/// Contract: elf_data must point to valid ELF file.
/// Contract: Memory at physical addresses must be available.
/// Returns: LoadedKernel with entry point and load range.
pub fn load_kernel(elf_data: []const u8) LoaderError!LoadedKernel {
    // Parse ELF header
    if (elf_data.len < @sizeOf(Elf64_Ehdr)) {
        return LoaderError.InvalidElfMagic;
    }

    const header: *const Elf64_Ehdr = @ptrCast(@alignCast(elf_data.ptr));
    try validate_elf_header(header);

    var result = LoadedKernel{
        .entry_point = header.e_entry,
        .load_base = std.math.maxInt(u64),
        .load_end = 0,
        .segments_loaded = 0,
    };

    // Process program headers
    const phoff = header.e_phoff;
    const phnum = header.e_phnum;
    const phentsize = header.e_phentsize;

    var i: u16 = 0;
    while (i < phnum) : (i += 1) {
        const ph_offset = phoff + @as(u64, i) * @as(u64, phentsize);
        if (ph_offset + @sizeOf(Elf64_Phdr) > elf_data.len) {
            return LoaderError.ProgramHeaderOutOfBounds;
        }

        const phdr: *const Elf64_Phdr = @ptrCast(@alignCast(elf_data.ptr + ph_offset));

        // Only load PT_LOAD segments
        if (phdr.p_type != PT_LOAD) {
            continue;
        }

        // Calculate segment bounds
        const seg_start = phdr.p_paddr;
        const seg_end = seg_start + phdr.p_memsz;

        // Update load range
        if (seg_start < result.load_base) {
            result.load_base = seg_start;
        }
        if (seg_end > result.load_end) {
            result.load_end = seg_end;
        }

        // Copy segment data from ELF to physical memory
        if (phdr.p_filesz > 0) {
            const file_offset = phdr.p_offset;
            if (file_offset + phdr.p_filesz > elf_data.len) {
                return LoaderError.SegmentOutOfBounds;
            }

            // Copy from ELF file to physical address
            const src = elf_data.ptr + file_offset;
            const dst: [*]u8 = @ptrFromInt(phdr.p_paddr);
            @memcpy(dst[0..@intCast(phdr.p_filesz)], src[0..@intCast(phdr.p_filesz)]);
        }

        // Zero-fill BSS (memsz > filesz)
        if (phdr.p_memsz > phdr.p_filesz) {
            const bss_start = phdr.p_paddr + phdr.p_filesz;
            const bss_size = phdr.p_memsz - phdr.p_filesz;
            const bss_ptr: [*]u8 = @ptrFromInt(bss_start);
            @memset(bss_ptr[0..@intCast(bss_size)], 0);
        }

        result.segments_loaded += 1;
    }

    return result;
}

/// Get segment permissions as string.
/// Why: Debug output for loaded segments.
pub fn segment_flags_str(flags: u32) [3]u8 {
    return .{
        if ((flags & PF_R) != 0) 'R' else '-',
        if ((flags & PF_W) != 0) 'W' else '-',
        if ((flags & PF_X) != 0) 'X' else '-',
    };
}

// Tests
test "ELF header validation" {
    const testing = std.testing;

    // Valid header
    var header = std.mem.zeroes(Elf64_Ehdr);
    header.e_ident[0] = 0x7F;
    header.e_ident[1] = 'E';
    header.e_ident[2] = 'L';
    header.e_ident[3] = 'F';
    header.e_ident[4] = ELFCLASS64;
    header.e_ident[5] = ELFDATA2LSB;
    header.e_machine = EM_X86_64;
    header.e_type = 2;

    try validate_elf_header(&header);

    // Invalid magic
    header.e_ident[0] = 0;
    try testing.expectError(LoaderError.InvalidElfMagic, validate_elf_header(&header));
}

test "segment flags" {
    const testing = std.testing;

    const rwx = segment_flags_str(PF_R | PF_W | PF_X);
    try testing.expectEqualStrings("RWX", &rwx);

    const ro = segment_flags_str(PF_R);
    try testing.expectEqualStrings("R--", &ro);

    const rx = segment_flags_str(PF_R | PF_X);
    try testing.expectEqualStrings("R-X", &rx);
}
