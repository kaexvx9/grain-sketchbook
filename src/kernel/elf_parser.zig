//! ELF Parser for Kernel
//! Why: Parse ELF headers to extract entry point and segment information for process spawning.
//! Grain Style: Explicit types (u32/u64 not usize), comprehensive assertions, static allocation.

const std = @import("std");
const Debug = @import("debug.zig");

/// Read little-endian u64 from buffer at offset.
/// Why: Common pattern for reading ELF fields.
fn read_le_u64(buffer: []const u8, offset: u32) ?u64 {
    if (buffer.len < offset + 8) return null;
    var value: u64 = 0;
    var i: u32 = 0;
    while (i < 8) : (i += 1) {
        value |= (@as(u64, buffer[offset + i]) << @as(u6, @intCast(i * 8)));
    }
    return value;
}

/// Read little-endian u16 from buffer at offset.
/// Why: Common pattern for reading ELF fields.
fn read_le_u16(buffer: []const u8, offset: u32) ?u16 {
    if (buffer.len < offset + 2) return null;
    return @as(u16, buffer[offset]) | (@as(u16, buffer[offset + 1]) << 8);
}

/// Read little-endian u32 from buffer at offset.
/// Why: Common pattern for reading ELF fields.
fn read_le_u32(buffer: []const u8, offset: u32) ?u32 {
    if (buffer.len < offset + 4) return null;
    return @as(u32, buffer[offset]) | (@as(u32, buffer[offset + 1]) << 8) |
        (@as(u32, buffer[offset + 2]) << 16) | (@as(u32, buffer[offset + 3]) << 24);
}

/// Validate ELF magic number, class, and endianness.
/// Why: Common validation for ELF header parsing.
fn validate_elf_magic(buffer: []const u8) bool {
    if (buffer.len < 64) return false;
    if (buffer[0] != ELF_MAGIC[0] or buffer[1] != ELF_MAGIC[1]) return false;
    if (buffer[2] != ELF_MAGIC[2] or buffer[3] != ELF_MAGIC[3]) return false;
    if (buffer[4] != 2) return false; // Must be 64-bit
    if (buffer[5] != 1) return false; // Must be little-endian
    return true;
}

/// ELF header structure (64-bit, little-endian).
/// Why: Explicit ELF structure for parsing entry point and segment info.
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

/// ELF magic number: 0x7F "ELF".
/// Why: Validate ELF file format.
const ELF_MAGIC = [_]u8{ 0x7F, 'E', 'L', 'F' };

/// ELF program header structure (64-bit, little-endian).
/// Why: Parse program headers to extract segment information.
const Elf64_Phdr = extern struct {
    /// Segment type (1 = PT_LOAD, 2 = PT_DYNAMIC, etc.).
    p_type: u32,
    /// Segment flags (read, write, execute).
    p_flags: u32,
    /// Segment file offset.
    p_offset: u64,
    /// Segment virtual address.
    p_vaddr: u64,
    /// Segment physical address (usually same as virtual).
    p_paddr: u64,
    /// Segment size in file.
    p_filesz: u64,
    /// Segment size in memory.
    p_memsz: u64,
    /// Segment alignment.
    p_align: u64,
};

/// ELF parser result.
/// Why: Return parsed ELF information for process setup.
pub const ElfInfo = struct {
    /// Entry point virtual address.
    /// Why: Set process PC to entry point.
    entry_point: u64,
    /// Whether ELF is valid.
    /// Why: Validate ELF format before using.
    valid: bool,
    /// Program header table offset.
    /// Why: Location of program headers for segment loading.
    phoff: u64,
    /// Program header entry size.
    /// Why: Size of each program header entry.
    phentsize: u16,
    /// Program header count.
    /// Why: Number of program headers.
    phnum: u16,
    
    /// Initialize empty ELF info.
    /// Why: Explicit initialization, clear state.
    pub fn init() ElfInfo {
        return ElfInfo{
            .entry_point = 0,
            .valid = false,
            .phoff = 0,
            .phentsize = 0,
            .phnum = 0,
        };
    }
};

/// Parse ELF header from memory buffer.
/// Why: Extract entry point and validate ELF format for process spawning.
/// Contract: buffer must be >= 64 bytes (ELF header size), buffer must be valid ELF format.
/// Returns: ElfInfo with entry point if valid, invalid ElfInfo otherwise.
/// Grain Style: Static allocation, no recursion, explicit types.
pub fn parse_elf_header(buffer: []const u8) ElfInfo {
    Debug.kassert(buffer.len > 0, "Buffer empty", .{});
    if (!validate_elf_magic(buffer)) return ElfInfo.init();

    const entry_point = read_le_u64(buffer, 24) orelse return ElfInfo.init();
    if (entry_point == 0 or entry_point > 0xFFFFFFFFFFFF) return ElfInfo.init();

    const phoff = read_le_u64(buffer, 32) orelse return ElfInfo.init();
    const phentsize = read_le_u16(buffer, 54) orelse return ElfInfo.init();
    const phnum = read_le_u16(buffer, 56) orelse return ElfInfo.init();

    // Assert: Program header entry size must be reasonable (56 bytes for ELF64).
    const ELF64_PHDR_SIZE: u16 = 56;
    if (phentsize != 0 and phentsize < ELF64_PHDR_SIZE) {
        return ElfInfo.init(); // Invalid: phentsize too small
    }
    
    // Assert: Program header count must be reasonable (max 128 segments).
    const MAX_PHDR_COUNT: u16 = 128;
    if (phnum > MAX_PHDR_COUNT) {
        return ElfInfo.init(); // Invalid: too many program headers
    }
    
    // Return valid ELF info with program header information.
    const info = ElfInfo{
        .entry_point = entry_point,
        .valid = true,
        .phoff = phoff,
        .phentsize = phentsize,
        .phnum = phnum,
    };
    
    // Assert: ELF info must be valid (postcondition).
    Debug.kassert(info.valid, "ELF info not valid", .{});
    Debug.kassert(info.entry_point != 0, "Entry point is zero", .{});
    
    return info;
}

/// Program segment information.
/// Why: Track segment details for loading into VM memory.
pub const ProgramSegment = struct {
    /// Segment type (1 = PT_LOAD, etc.).
    p_type: u32,
    /// Segment virtual address.
    p_vaddr: u64,
    /// Segment size in file.
    p_filesz: u64,
    /// Segment size in memory.
    p_memsz: u64,
    /// Segment flags (read, write, execute).
    p_flags: u32,
    /// Segment file offset.
    p_offset: u64,
    /// Segment alignment.
    p_align: u64,
    /// Whether segment is valid for loading.
    valid: bool,
    
    /// Initialize empty segment.
    /// Why: Explicit initialization, clear state.
    pub fn init() ProgramSegment {
        return ProgramSegment{
            .p_type = 0,
            .p_vaddr = 0,
            .p_filesz = 0,
            .p_memsz = 0,
            .p_flags = 0,
            .p_offset = 0,
            .p_align = 0,
            .valid = false,
        };
    }
};

/// Parse program header from memory buffer.
/// Why: Extract segment information for loading into VM memory.
/// Contract: buffer >= 56 bytes (ELF64 phdr size), valid program header format.
pub fn parse_program_header(buffer: []const u8) ProgramSegment {
    Debug.kassert(buffer.len > 0, "Buffer empty", .{});
    if (buffer.len < 56) return ProgramSegment.init();

    const p_type = read_le_u32(buffer, 0) orelse return ProgramSegment.init();
    const p_flags = read_le_u32(buffer, 4) orelse return ProgramSegment.init();
    const p_offset = read_le_u64(buffer, 8) orelse return ProgramSegment.init();
    const p_vaddr = read_le_u64(buffer, 16) orelse return ProgramSegment.init();
    const p_filesz = read_le_u64(buffer, 32) orelse return ProgramSegment.init();
    const p_memsz = read_le_u64(buffer, 40) orelse return ProgramSegment.init();
    const p_align = read_le_u64(buffer, 48) orelse return ProgramSegment.init();

    if (!validate_program_segment(p_type, p_vaddr, p_filesz, p_memsz, p_align)) {
        return ProgramSegment.init();
    }

    return ProgramSegment{
        .p_type = p_type,
        .p_vaddr = p_vaddr,
        .p_filesz = p_filesz,
        .p_memsz = p_memsz,
        .p_flags = p_flags,
        .p_offset = p_offset,
        .p_align = p_align,
        .valid = true,
    };
}

/// Validate program segment fields.
/// Why: Ensure segment is valid for loading.
fn validate_program_segment(p_type: u32, p_vaddr: u64, p_filesz: u64, p_memsz: u64, p_align: u64) bool {
    const PT_LOAD: u32 = 1;
    if (p_type != PT_LOAD) return false;
    if (p_vaddr == 0 or p_vaddr > 0xFFFFFFFFFFFF) return false;
    if (p_memsz < p_filesz) return false;
    if (p_align != 0 and (p_align & (p_align - 1)) != 0) return false;
    return true;
}

