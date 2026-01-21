//! Limine Boot Protocol for Basin Kernel
//! Why: Interface with Limine bootloader for x86_64/aarch64/riscv64 boot.
//! Grain Style: Explicit types, static allocation, comprehensive assertions.
//!
//! Reference: https://github.com/limine-bootloader/limine/blob/trunk/PROTOCOL.md
//! Based on Limine Protocol Revision 3

const std = @import("std");

/// Limine magic numbers for request identification.
pub const LIMINE_COMMON_MAGIC = [4]u64{
    0xc7b1dd30df4c8b88,
    0x0a82e883a194f07b,
    0, // Filled per-request
    0, // Filled per-request
};

// Request IDs (magic numbers from Limine protocol)
pub const BOOTLOADER_INFO_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0xf55038d8e2a1202f, 0x279426fcf5f59740 };
pub const STACK_SIZE_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x224ef0460a8e8926, 0xe1cb0fc25f46ea3d };
pub const HHDM_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x48dcf1cb8ad2b852, 0x63984e959a98244b };
pub const FRAMEBUFFER_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x9d5827dcd881dd75, 0xa3148604f6fab11b };
pub const PAGING_MODE_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x95c1a0edab0944cb, 0xa4e5cb3842f7488a };
pub const SMP_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x95a67b819a1b857e, 0xa0b61b723b6a73e0 };
pub const MEMMAP_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x67cf3d9d378a806f, 0xe304acdfc50c3c62 };
pub const ENTRY_POINT_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x13d86c035a1cd3e1, 0x2b0caa89d8f3026a };
pub const KERNEL_FILE_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0xad97e90e83f1ed67, 0x31eb5d1c5ff23b69 };
pub const MODULE_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x3e7e279702be32af, 0xca1c4f3bd1280cee };
pub const RSDP_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0xc5e77b6b397e7b43, 0x27637845accdcf3c };
pub const SMBIOS_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x9e9046f11e095391, 0xaa4a520fefbde5ee };
pub const EFI_SYSTEM_TABLE_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x5ceba5163eaaf6d6, 0x0a6981610cf65fcc };
pub const EFI_MEMMAP_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x7df62a431d6872d5, 0xa4fcdfb3e57306c8 };
pub const BOOT_TIME_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x502746e184c088aa, 0xfbc5ec83e6327893 };
pub const KERNEL_ADDRESS_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0x71ba76863cc55f63, 0xb2644a48c516a487 };
pub const DEVICE_TREE_BLOB_REQUEST = [4]u64{ 0xc7b1dd30df4c8b88, 0x0a82e883a194f07b, 0xb40ddb48fb54bac7, 0x545081493f81ffb7 };

/// Base revision marker.
/// Why: Kernel declares minimum protocol revision it supports.
pub const BaseRevision = extern struct {
    id: [2]u64 = .{ 0xf9562b2d5c95a6c8, 0x6a7b384944536bdc },
    revision: u64,

    /// Check if bootloader supports this revision.
    pub fn is_supported(self: *const volatile BaseRevision) bool {
        return self.revision == 0;
    }
};

/// Bootloader info response.
pub const BootloaderInfoResponse = extern struct {
    revision: u64,
    name: [*:0]const u8,
    version: [*:0]const u8,
};

/// Bootloader info request.
pub const BootloaderInfoRequest = extern struct {
    id: [4]u64 = BOOTLOADER_INFO_REQUEST,
    revision: u64 = 0,
    response: ?*BootloaderInfoResponse = null,
};

/// Stack size request.
pub const StackSizeRequest = extern struct {
    id: [4]u64 = STACK_SIZE_REQUEST,
    revision: u64 = 0,
    response: ?*StackSizeResponse = null,
    stack_size: u64 = 65536, // 64KB default
};

/// Stack size response.
pub const StackSizeResponse = extern struct {
    revision: u64,
};

/// Higher Half Direct Map response.
pub const HhdmResponse = extern struct {
    revision: u64,
    offset: u64,
};

/// Higher Half Direct Map request.
/// Why: Get offset for physical memory access in higher half.
pub const HhdmRequest = extern struct {
    id: [4]u64 = HHDM_REQUEST,
    revision: u64 = 0,
    response: ?*HhdmResponse = null,
};

/// Framebuffer memory model.
pub const FramebufferMemoryModel = enum(u8) {
    rgb = 1,
    _,
};

/// Framebuffer structure.
pub const Framebuffer = extern struct {
    address: [*]volatile u32,
    width: u64,
    height: u64,
    pitch: u64,
    bpp: u16,
    memory_model: FramebufferMemoryModel,
    red_mask_size: u8,
    red_mask_shift: u8,
    green_mask_size: u8,
    green_mask_shift: u8,
    blue_mask_size: u8,
    blue_mask_shift: u8,
    unused: [7]u8,
    edid_size: u64,
    edid: ?[*]const u8,

    // Video modes follow (revision 1+)
};

/// Framebuffer response.
pub const FramebufferResponse = extern struct {
    revision: u64,
    framebuffer_count: u64,

    /// Get framebuffers array.
    pub fn framebuffers(self: *const FramebufferResponse) []*Framebuffer {
        const ptr: [*]*Framebuffer = @ptrFromInt(@intFromPtr(self) + @sizeOf(FramebufferResponse));
        return ptr[0..self.framebuffer_count];
    }
};

/// Framebuffer request.
pub const FramebufferRequest = extern struct {
    id: [4]u64 = FRAMEBUFFER_REQUEST,
    revision: u64 = 0,
    response: ?*FramebufferResponse = null,
};

/// Memory map entry types.
pub const MemoryMapEntryType = enum(u64) {
    usable = 0,
    reserved = 1,
    acpi_reclaimable = 2,
    acpi_nvs = 3,
    bad_memory = 4,
    bootloader_reclaimable = 5,
    kernel_and_modules = 6,
    framebuffer = 7,
    _,
};

/// Memory map entry.
pub const MemoryMapEntry = extern struct {
    base: u64,
    length: u64,
    type: MemoryMapEntryType,
};

/// Memory map response.
pub const MemoryMapResponse = extern struct {
    revision: u64,
    entry_count: u64,

    /// Get memory map entries.
    pub fn entries(self: *const MemoryMapResponse) []*MemoryMapEntry {
        const ptr: [*]*MemoryMapEntry = @ptrFromInt(@intFromPtr(self) + @sizeOf(MemoryMapResponse));
        return ptr[0..self.entry_count];
    }
};

/// Memory map request.
pub const MemoryMapRequest = extern struct {
    id: [4]u64 = MEMMAP_REQUEST,
    revision: u64 = 0,
    response: ?*MemoryMapResponse = null,
};

/// Kernel address response.
pub const KernelAddressResponse = extern struct {
    revision: u64,
    physical_base: u64,
    virtual_base: u64,
};

/// Kernel address request.
pub const KernelAddressRequest = extern struct {
    id: [4]u64 = KERNEL_ADDRESS_REQUEST,
    revision: u64 = 0,
    response: ?*KernelAddressResponse = null,
};

/// RSDP response (ACPI).
pub const RsdpResponse = extern struct {
    revision: u64,
    address: u64,
};

/// RSDP request.
pub const RsdpRequest = extern struct {
    id: [4]u64 = RSDP_REQUEST,
    revision: u64 = 0,
    response: ?*RsdpResponse = null,
};

/// Boot time response.
pub const BootTimeResponse = extern struct {
    revision: u64,
    boot_time: i64, // Unix timestamp
};

/// Boot time request.
pub const BootTimeRequest = extern struct {
    id: [4]u64 = BOOT_TIME_REQUEST,
    revision: u64 = 0,
    response: ?*BootTimeResponse = null,
};

/// File structure (for kernel file and modules).
pub const File = extern struct {
    revision: u64,
    address: [*]const u8,
    size: u64,
    path: [*:0]const u8,
    cmdline: [*:0]const u8,
    media_type: u32,
    unused: u32,
    tftp_ip: u32,
    tftp_port: u32,
    partition_index: u32,
    mbr_disk_id: u32,
    gpt_disk_uuid: Uuid,
    gpt_part_uuid: Uuid,
    part_uuid: Uuid,
};

/// UUID structure.
pub const Uuid = extern struct {
    a: u32,
    b: u16,
    c: u16,
    d: [8]u8,
};

/// Kernel file response.
pub const KernelFileResponse = extern struct {
    revision: u64,
    kernel_file: *File,
};

/// Kernel file request.
pub const KernelFileRequest = extern struct {
    id: [4]u64 = KERNEL_FILE_REQUEST,
    revision: u64 = 0,
    response: ?*KernelFileResponse = null,
};

/// Module response.
pub const ModuleResponse = extern struct {
    revision: u64,
    module_count: u64,

    /// Get modules array.
    pub fn modules(self: *const ModuleResponse) []*File {
        const ptr: [*]*File = @ptrFromInt(@intFromPtr(self) + @sizeOf(ModuleResponse));
        return ptr[0..self.module_count];
    }
};

/// Internal module structure for requests.
pub const InternalModule = extern struct {
    path: [*:0]const u8,
    cmdline: [*:0]const u8,
    flags: u64,
};

/// Module request.
pub const ModuleRequest = extern struct {
    id: [4]u64 = MODULE_REQUEST,
    revision: u64 = 0,
    response: ?*ModuleResponse = null,
    internal_module_count: u64 = 0,
    internal_modules: ?[*]const *const InternalModule = null,
};

/// SMP info structure (per-CPU).
pub const SmpInfo = extern struct {
    processor_id: u32,
    lapic_id: u32,
    reserved: u64,
    goto_address: ?*const fn (*SmpInfo) callconv(.C) noreturn,
    extra_argument: u64,
};

/// SMP response.
pub const SmpResponse = extern struct {
    revision: u64,
    flags: u32,
    bsp_lapic_id: u32,
    cpu_count: u64,

    /// Get CPU info array.
    pub fn cpus(self: *const SmpResponse) []*SmpInfo {
        const ptr: [*]*SmpInfo = @ptrFromInt(@intFromPtr(self) + @sizeOf(SmpResponse));
        return ptr[0..self.cpu_count];
    }
};

/// SMP request.
pub const SmpRequest = extern struct {
    id: [4]u64 = SMP_REQUEST,
    revision: u64 = 0,
    response: ?*SmpResponse = null,
    flags: u64 = 0,
};

// Paging modes
pub const PagingMode = enum(u64) {
    four_level = 0, // x86_64 default
    five_level = 1, // x86_64 with LA57
    _,
};

/// Paging mode response.
pub const PagingModeResponse = extern struct {
    revision: u64,
    mode: PagingMode,
    flags: u64,
};

/// Paging mode request.
pub const PagingModeRequest = extern struct {
    id: [4]u64 = PAGING_MODE_REQUEST,
    revision: u64 = 0,
    response: ?*PagingModeResponse = null,
    mode: PagingMode = .four_level,
    flags: u64 = 0,
};

// Helper functions

/// Halt the CPU.
pub inline fn hcf() noreturn {
    while (true) {
        asm volatile ("cli; hlt");
    }
}

/// Convert physical address to virtual using HHDM offset.
pub inline fn phys_to_virt(phys: u64, hhdm_offset: u64) u64 {
    return phys + hhdm_offset;
}

/// Convert virtual address to physical using HHDM offset.
pub inline fn virt_to_phys(virt: u64, hhdm_offset: u64) u64 {
    return virt - hhdm_offset;
}
