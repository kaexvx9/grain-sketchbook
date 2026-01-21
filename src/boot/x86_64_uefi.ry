//! UEFI Bootloader for Basin Kernel on x86_64
//! Why: Boot Basin kernel on Framework laptop via UEFI.
//! Grain Style: Explicit types, static allocation, comprehensive assertions.
//!
//! Boot Sequence:
//! 1. UEFI firmware loads this bootloader
//! 2. Bootloader sets up memory map
//! 3. Bootloader loads kernel ELF
//! 4. Bootloader sets up page tables (identity mapping + higher half)
//! 5. Bootloader jumps to kernel entry point
//!
//! Reference: UEFI Specification 2.10

const std = @import("std");

/// UEFI Status codes.
/// Why: Define UEFI return values.
pub const EfiStatus = enum(u64) {
    success = 0,
    load_error = 1,
    invalid_parameter = 2,
    unsupported = 3,
    bad_buffer_size = 4,
    buffer_too_small = 5,
    not_ready = 6,
    device_error = 7,
    write_protected = 8,
    out_of_resources = 9,
    volume_corrupted = 10,
    volume_full = 11,
    no_media = 12,
    media_changed = 13,
    not_found = 14,
    access_denied = 15,
    no_response = 16,
    no_mapping = 17,
    timeout = 18,
    not_started = 19,
    already_started = 20,
    aborted = 21,
    // High bit set = error
    _,
};

/// UEFI Memory Types.
/// Why: Classify memory regions for kernel handoff.
pub const EfiMemoryType = enum(u32) {
    reserved = 0,
    loader_code = 1,
    loader_data = 2,
    boot_services_code = 3,
    boot_services_data = 4,
    runtime_services_code = 5,
    runtime_services_data = 6,
    conventional = 7,
    unusable = 8,
    acpi_reclaim = 9,
    acpi_nvs = 10,
    mmio = 11,
    mmio_port_space = 12,
    pal_code = 13,
    persistent = 14,
    max_memory_type = 15,
};

/// UEFI Memory Descriptor.
/// Why: Describe a memory region from UEFI memory map.
pub const EfiMemoryDescriptor = extern struct {
    type: EfiMemoryType,
    padding: u32,
    physical_start: u64,
    virtual_start: u64,
    number_of_pages: u64,
    attribute: u64,
};

/// UEFI Table Header.
/// Why: Common header for all UEFI tables.
pub const EfiTableHeader = extern struct {
    signature: u64,
    revision: u32,
    header_size: u32,
    crc32: u32,
    reserved: u32,
};

/// UEFI Simple Text Output Protocol.
/// Why: Console output for boot messages.
pub const EfiSimpleTextOutputProtocol = extern struct {
    reset: *const fn (*EfiSimpleTextOutputProtocol, bool) callconv(.C) EfiStatus,
    output_string: *const fn (*EfiSimpleTextOutputProtocol, [*:0]const u16) callconv(.C) EfiStatus,
    test_string: *const fn (*EfiSimpleTextOutputProtocol, [*:0]const u16) callconv(.C) EfiStatus,
    query_mode: *const fn (*EfiSimpleTextOutputProtocol, u64, *u64, *u64) callconv(.C) EfiStatus,
    set_mode: *const fn (*EfiSimpleTextOutputProtocol, u64) callconv(.C) EfiStatus,
    set_attribute: *const fn (*EfiSimpleTextOutputProtocol, u64) callconv(.C) EfiStatus,
    clear_screen: *const fn (*EfiSimpleTextOutputProtocol) callconv(.C) EfiStatus,
    set_cursor_position: *const fn (*EfiSimpleTextOutputProtocol, u64, u64) callconv(.C) EfiStatus,
    enable_cursor: *const fn (*EfiSimpleTextOutputProtocol, bool) callconv(.C) EfiStatus,
    mode: *anyopaque,
};

/// UEFI Boot Services (subset).
/// Why: Services needed for bootloader operation.
pub const EfiBootServices = extern struct {
    hdr: EfiTableHeader,

    // Task Priority Services (unused)
    raise_tpl: *anyopaque,
    restore_tpl: *anyopaque,

    // Memory Services
    allocate_pages: *const fn (u32, EfiMemoryType, u64, *u64) callconv(.C) EfiStatus,
    free_pages: *const fn (u64, u64) callconv(.C) EfiStatus,
    get_memory_map: *const fn (*u64, [*]EfiMemoryDescriptor, *u64, *u64, *u32) callconv(.C) EfiStatus,
    allocate_pool: *const fn (EfiMemoryType, u64, *?*anyopaque) callconv(.C) EfiStatus,
    free_pool: *const fn (*anyopaque) callconv(.C) EfiStatus,

    // Event & Timer Services (unused for now)
    create_event: *anyopaque,
    set_timer: *anyopaque,
    wait_for_event: *anyopaque,
    signal_event: *anyopaque,
    close_event: *anyopaque,
    check_event: *anyopaque,

    // Protocol Handler Services (subset)
    install_protocol_interface: *anyopaque,
    reinstall_protocol_interface: *anyopaque,
    uninstall_protocol_interface: *anyopaque,
    handle_protocol: *anyopaque,
    reserved: *anyopaque,
    register_protocol_notify: *anyopaque,
    locate_handle: *anyopaque,
    locate_device_path: *anyopaque,
    install_configuration_table: *anyopaque,

    // Image Services
    load_image: *anyopaque,
    start_image: *anyopaque,
    exit: *const fn (*anyopaque, EfiStatus, u64, ?[*:0]const u16) callconv(.C) EfiStatus,
    unload_image: *anyopaque,
    exit_boot_services: *const fn (*anyopaque, u64) callconv(.C) EfiStatus,

    // Miscellaneous Services
    get_next_monotonic_count: *anyopaque,
    stall: *const fn (u64) callconv(.C) EfiStatus,
    set_watchdog_timer: *const fn (u64, u64, u64, ?[*:0]const u16) callconv(.C) EfiStatus,
};

/// UEFI System Table.
/// Why: Main entry point for UEFI services.
pub const EfiSystemTable = extern struct {
    hdr: EfiTableHeader,
    firmware_vendor: [*:0]const u16,
    firmware_revision: u32,
    console_in_handle: *anyopaque,
    con_in: *anyopaque,
    console_out_handle: *anyopaque,
    con_out: *EfiSimpleTextOutputProtocol,
    standard_error_handle: *anyopaque,
    std_err: *EfiSimpleTextOutputProtocol,
    runtime_services: *anyopaque,
    boot_services: *EfiBootServices,
    number_of_table_entries: u64,
    configuration_table: *anyopaque,
};

/// Boot information passed to kernel.
/// Why: Kernel needs memory map and other boot info.
/// GrainStyle: Static allocation, explicit sizes.
pub const BootInfo = struct {
    /// Memory map from UEFI.
    memory_map: [256]EfiMemoryDescriptor = undefined,
    /// Number of valid entries in memory_map.
    memory_map_count: u32 = 0,
    /// Size of each memory descriptor.
    memory_descriptor_size: u32 = 0,

    /// Framebuffer base address.
    framebuffer_base: u64 = 0,
    /// Framebuffer width in pixels.
    framebuffer_width: u32 = 0,
    /// Framebuffer height in pixels.
    framebuffer_height: u32 = 0,
    /// Framebuffer stride (bytes per row).
    framebuffer_stride: u32 = 0,
    /// Framebuffer bits per pixel.
    framebuffer_bpp: u32 = 0,

    /// ACPI RSDP address.
    acpi_rsdp: u64 = 0,

    /// Kernel command line.
    cmdline: [256]u8 = [_]u8{0} ** 256,
    cmdline_len: u32 = 0,
};

/// Page table entry flags.
/// Why: x86_64 page table bit definitions.
pub const PageFlags = struct {
    pub const PRESENT: u64 = 1 << 0;
    pub const WRITABLE: u64 = 1 << 1;
    pub const USER: u64 = 1 << 2;
    pub const WRITE_THROUGH: u64 = 1 << 3;
    pub const NO_CACHE: u64 = 1 << 4;
    pub const ACCESSED: u64 = 1 << 5;
    pub const DIRTY: u64 = 1 << 6;
    pub const HUGE_PAGE: u64 = 1 << 7;
    pub const GLOBAL: u64 = 1 << 8;
    pub const NO_EXECUTE: u64 = 1 << 63;
};

/// Page table level 4 (PML4).
/// Why: Top-level page table for x86_64.
pub const PageTable = struct {
    entries: [512]u64 = [_]u64{0} ** 512,

    /// Map a 2MB huge page.
    /// Why: Simple identity mapping for bootloader.
    pub fn map_2mb(self: *PageTable, virt: u64, phys: u64, flags: u64) void {
        const pml4_idx = (virt >> 39) & 0x1FF;
        const pdpt_idx = (virt >> 30) & 0x1FF;
        const pd_idx = (virt >> 21) & 0x1FF;

        // TODO: Allocate PDPT and PD if not present
        _ = self;
        _ = pml4_idx;
        _ = pdpt_idx;
        _ = pd_idx;
        _ = phys;
        _ = flags;
    }
};

/// Bootloader state.
/// Why: Track bootloader state for debugging.
pub const BootState = enum(u8) {
    initializing = 0,
    memory_map_acquired = 1,
    kernel_loaded = 2,
    page_tables_setup = 3,
    boot_services_exited = 4,
    jumping_to_kernel = 5,
};

/// Global boot state for debugging.
var boot_state: BootState = .initializing;

/// Global boot info to pass to kernel.
var boot_info: BootInfo = BootInfo{};

/// Print a simple message to UEFI console.
/// Why: Debug output during boot.
fn print(con_out: *EfiSimpleTextOutputProtocol, comptime msg: []const u8) void {
    // Convert ASCII to UCS-2 at comptime
    comptime var buf: [msg.len + 1]u16 = undefined;
    comptime {
        for (msg, 0..) |c, i| {
            buf[i] = c;
        }
        buf[msg.len] = 0;
    }
    _ = con_out.output_string(con_out, &buf);
}

/// UEFI entry point.
/// Why: Called by UEFI firmware to start bootloader.
/// Note: Zig's UEFI target provides system table via std.os.uefi.
pub fn main() void {
    // Get UEFI system table from Zig's UEFI support
    const uefi = @import("std").os.uefi;
    const system_table = uefi.system_table;
    const con_out = system_table.con_out orelse {
        // No console, halt
        while (true) {
            asm volatile ("hlt");
        }
    };

    // Clear screen and print banner
    _ = con_out.clearScreen() catch false;
    
    // Print welcome message (UCS-2 string)
    const banner = comptime blk: {
        const msg = "Basin Kernel Bootloader v0.1\r\n";
        var buf: [msg.len:0]u16 = undefined;
        for (msg, 0..) |c, i| {
            buf[i] = c;
        }
        break :blk buf;
    };
    _ = con_out.outputString(&banner) catch false;

    const line2 = comptime blk: {
        const msg = "=============================\r\n\r\n";
        var buf: [msg.len:0]u16 = undefined;
        for (msg, 0..) |c, i| {
            buf[i] = c;
        }
        break :blk buf;
    };
    _ = con_out.outputString(&line2) catch false;

    const status_msg = comptime blk: {
        const msg = "[BOOT] UEFI bootloader started successfully.\r\n";
        var buf: [msg.len:0]u16 = undefined;
        for (msg, 0..) |c, i| {
            buf[i] = c;
        }
        break :blk buf;
    };
    _ = con_out.outputString(&status_msg) catch false;

    const halt_msg = comptime blk: {
        const msg = "[BOOT] Halting (kernel loading not yet implemented).\r\n";
        var buf: [msg.len:0]u16 = undefined;
        for (msg, 0..) |c, i| {
            buf[i] = c;
        }
        break :blk buf;
    };
    _ = con_out.outputString(&halt_msg) catch false;

    // Halt
    while (true) {
        asm volatile ("hlt");
    }
}

/// Alternative entry point with full UEFI parameters (for custom entry).
/// Why: Direct UEFI entry when not using Zig's start code.
pub fn efi_main(image_handle: *anyopaque, system_table: *EfiSystemTable) callconv(.C) EfiStatus {
    const con_out = system_table.con_out;
    const boot_services = system_table.boot_services;

    // Clear screen and print banner
    _ = con_out.clear_screen(con_out);
    print(con_out, "Basin Kernel Bootloader v0.1\r\n");
    print(con_out, "=============================\r\n\r\n");

    // Disable watchdog timer
    _ = boot_services.set_watchdog_timer(0, 0, 0, null);

    // Get memory map
    print(con_out, "[BOOT] Getting memory map...\r\n");
    var map_size: u64 = @sizeOf(@TypeOf(boot_info.memory_map));
    var map_key: u64 = 0;
    var descriptor_size: u64 = 0;
    var descriptor_version: u32 = 0;

    var status = boot_services.get_memory_map(
        &map_size,
        &boot_info.memory_map,
        &map_key,
        &descriptor_size,
        &descriptor_version,
    );

    if (status != .success) {
        print(con_out, "[BOOT] Failed to get memory map!\r\n");
        return status;
    }

    boot_info.memory_map_count = @intCast(map_size / descriptor_size);
    boot_info.memory_descriptor_size = @intCast(descriptor_size);
    boot_state = .memory_map_acquired;
    print(con_out, "[BOOT] Memory map acquired.\r\n");

    // TODO: Load kernel ELF from filesystem
    print(con_out, "[BOOT] Kernel loading not yet implemented.\r\n");
    boot_state = .kernel_loaded;

    // TODO: Set up page tables
    print(con_out, "[BOOT] Page table setup not yet implemented.\r\n");
    boot_state = .page_tables_setup;

    // Exit boot services
    print(con_out, "[BOOT] Exiting boot services...\r\n");
    status = boot_services.exit_boot_services(image_handle, map_key);
    if (status != .success) {
        // Memory map may have changed, try again
        map_size = @sizeOf(@TypeOf(boot_info.memory_map));
        _ = boot_services.get_memory_map(
            &map_size,
            &boot_info.memory_map,
            &map_key,
            &descriptor_size,
            &descriptor_version,
        );
        status = boot_services.exit_boot_services(image_handle, map_key);
        if (status != .success) {
            // Can't print anymore - boot services are partially exited
            return status;
        }
    }
    boot_state = .boot_services_exited;

    // TODO: Jump to kernel
    boot_state = .jumping_to_kernel;

    // For now, halt
    while (true) {
        asm volatile ("hlt");
    }
}

// Build configuration for UEFI target
pub const std_options = struct {
    pub const os_tag = .uefi;
};
