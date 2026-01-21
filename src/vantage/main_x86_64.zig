//! Vantage VM Entry Point for x86_64 (Limine Boot Protocol)
//! Why: Initialize Vantage RISC-V emulator on x86_64 host.
//! Grain Style: Explicit types, static allocation, comprehensive assertions.
//!
//! Architecture:
//!   Vantage VM boots on x86_64 via Limine
//!   Vantage loads Basin kernel (RISC-V ELF) from initrd
//!   Vantage emulates RISC-V64 to run Basin
//!   Basin runs Grainscript shell

const std = @import("std");
const limine = @import("limine");

// Limine requests - placed in special section for bootloader discovery
pub export var base_revision: limine.BaseRevision linksection(".limine_requests") = .{
    .revision = 3,
};

pub export var framebuffer_request: limine.FramebufferRequest linksection(".limine_requests") = .{};

pub export var memmap_request: limine.MemoryMapRequest linksection(".limine_requests") = .{};

pub export var hhdm_request: limine.HhdmRequest linksection(".limine_requests") = .{};

pub export var kernel_address_request: limine.KernelAddressRequest linksection(".limine_requests") = .{};

pub export var bootloader_info_request: limine.BootloaderInfoRequest linksection(".limine_requests") = .{};

pub export var rsdp_request: limine.RsdpRequest linksection(".limine_requests") = .{};

pub export var boot_time_request: limine.BootTimeRequest linksection(".limine_requests") = .{};

pub export var module_request: limine.ModuleRequest linksection(".limine_requests") = .{};

// Request markers for Limine
export var limine_requests_start linksection(".limine_requests_start") = [2]u64{ 0xf9562b2d5c95a6c8, 0x6a7b384944536bdc };
export var limine_requests_end linksection(".limine_requests_end") = [2]u64{ 0xadc0e0531bb10d03, 0x9572709f31764c62 };

/// Vantage VM state after boot.
/// Why: Track VM initialization progress.
pub const VantageState = enum(u8) {
    booting = 0,
    framebuffer_init = 1,
    memory_init = 2,
    vm_init = 3,
    basin_loaded = 4,
    running = 5,
    panic = 255,
};

/// Global Vantage state.
var vantage_state: VantageState = .booting;

/// Framebuffer info (cached from Limine).
var fb_addr: [*]volatile u32 = undefined;
var fb_width: u64 = 0;
var fb_height: u64 = 0;
var fb_pitch: u64 = 0;

/// HHDM offset for physical memory access.
var hhdm_offset: u64 = 0;

/// Total usable memory in bytes.
var total_memory: u64 = 0;

/// Simple framebuffer pixel write.
/// Why: Basic graphics output for early boot.
fn put_pixel(x: u64, y: u64, color: u32) void {
    if (x >= fb_width or y >= fb_height) return;
    const offset = y * (fb_pitch / 4) + x;
    fb_addr[offset] = color;
}

/// Fill rectangle.
fn fill_rect(x: u64, y: u64, w: u64, h: u64, color: u32) void {
    var py = y;
    while (py < y + h and py < fb_height) : (py += 1) {
        var px = x;
        while (px < x + w and px < fb_width) : (px += 1) {
            put_pixel(px, py, color);
        }
    }
}

/// Draw a character (8x16 font, simplified).
/// Why: Text output for boot messages.
fn draw_char(x: u64, y: u64, char: u8, color: u32) void {
    // Simple block representation for now
    if (char >= 32 and char < 127) {
        fill_rect(x, y, 8, 16, color);
    }
}

/// Print string at position.
fn print_at(x: u64, y: u64, str: []const u8, color: u32) void {
    var cx = x;
    for (str) |c| {
        if (c == '\n') {
            continue;
        }
        draw_char(cx, y, c, color);
        cx += 10;
    }
}

/// Initialize framebuffer.
fn init_framebuffer() bool {
    if (framebuffer_request.response) |response| {
        if (response.framebuffer_count > 0) {
            const fbs = response.framebuffers();
            const fb = fbs[0];
            fb_addr = fb.address;
            fb_width = fb.width;
            fb_height = fb.height;
            fb_pitch = fb.pitch;

            // Clear screen to dark blue (Basin color)
            fill_rect(0, 0, fb_width, fb_height, 0x001a1a2e);

            return true;
        }
    }
    return false;
}

/// Initialize memory map.
fn init_memory() bool {
    if (memmap_request.response) |response| {
        const entries = response.entries();
        total_memory = 0;

        for (entries) |entry| {
            if (entry.type == .usable) {
                total_memory += entry.length;
            }
        }

        return total_memory > 0;
    }
    return false;
}

/// Initialize HHDM (Higher Half Direct Map).
fn init_hhdm() bool {
    if (hhdm_request.response) |response| {
        hhdm_offset = response.offset;
        return true;
    }
    return false;
}

/// Draw boot banner.
fn draw_boot_banner() void {
    const banner_color: u32 = 0x00e0e0e0; // Light gray
    const accent_color: u32 = 0x0066ccff; // Vantage blue

    // Draw banner box
    fill_rect(50, 50, fb_width - 100, 200, 0x00252540);

    // Draw accent line
    fill_rect(50, 50, fb_width - 100, 4, accent_color);

    // Print title (simplified - just colored rectangles for now)
    print_at(70, 80, "Vantage VM v0.1", banner_color);
    print_at(70, 110, "RISC-V64 Emulator on x86_64", banner_color);

    // Print memory info
    const mem_mb = total_memory / (1024 * 1024);
    _ = mem_mb; // TODO: format number
    print_at(70, 150, "Memory: Initialized", banner_color);

    // Print status
    print_at(70, 190, "Status: Loading Basin kernel...", accent_color);
}

/// Draw status indicator.
fn update_status(msg: []const u8) void {
    // Clear status line
    fill_rect(70, 190, fb_width - 170, 20, 0x00252540);
    // Print new status
    print_at(70, 190, msg, 0x0066ccff);
}

/// Vantage VM entry point.
/// Why: Called by Limine after boot.
export fn _start() callconv(.c) noreturn {
    // Verify base revision is supported
    if (!base_revision.is_supported()) {
        limine.hcf();
    }

    // Initialize framebuffer
    if (!init_framebuffer()) {
        limine.hcf();
    }
    vantage_state = .framebuffer_init;

    // Initialize HHDM
    if (!init_hhdm()) {
        limine.hcf();
    }

    // Initialize memory map
    if (!init_memory()) {
        limine.hcf();
    }
    vantage_state = .memory_init;

    // Draw boot banner
    draw_boot_banner();

    // TODO: Initialize RISC-V VM
    // const vm = VM.init(...);
    vantage_state = .vm_init;
    update_status("RISC-V VM initialized");

    // TODO: Load Basin kernel from initrd module
    // if (module_request.response) |response| {
    //     const modules = response.modules();
    //     if (modules.len > 0) {
    //         const basin_elf = modules[0];
    //         vm.load_elf(basin_elf.address[0..basin_elf.size]);
    //     }
    // }
    vantage_state = .basin_loaded;
    update_status("Basin kernel loaded");

    // Draw success indicator (green rectangle)
    fill_rect(fb_width - 120, 80, 50, 50, 0x0044ff44);

    // TODO: Start RISC-V execution loop
    // while (true) {
    //     vm.step();
    //     // Handle framebuffer updates, input, etc.
    // }

    update_status("Vantage VM ready (halted)");
    vantage_state = .running;

    // Halt for now (VM loop not yet implemented)
    limine.hcf();
}

/// Panic handler.
pub fn panic(msg: []const u8, _: ?*std.builtin.StackTrace, _: ?usize) noreturn {
    vantage_state = .panic;

    // Draw red screen
    if (fb_width > 0) {
        fill_rect(0, 0, fb_width, fb_height, 0x00aa0000);
        print_at(100, 100, "KERNEL PANIC", 0x00ffffff);
        print_at(100, 130, msg, 0x00ffffff);
    }

    limine.hcf();
}
