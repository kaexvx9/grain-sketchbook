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
const riscv = @import("riscv_core.zig");

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

/// Usable memory region for VM.
var vm_memory_base: u64 = 0;
var vm_memory_ptr: [*]u8 = undefined;
var vm_memory_size: u64 = 0;

/// RISC-V core instance.
var riscv_core: riscv.RiscvCore = .{};

/// Console framebuffer for RISC-V output.
var console_fb: riscv.Framebuffer = undefined;

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

/// Initialize memory map and find usable region for VM.
fn init_memory() bool {
    if (memmap_request.response) |response| {
        const entries = response.entries();
        total_memory = 0;

        // Find largest usable region for VM (need at least 8MB).
        const MIN_VM_MEMORY: u64 = 8 * 1024 * 1024;

        for (entries) |entry| {
            if (entry.type == .usable) {
                total_memory += entry.length;

                // Use largest region that's at least 8MB for VM memory.
                if (entry.length >= MIN_VM_MEMORY and entry.length > vm_memory_size) {
                    vm_memory_base = entry.base;
                    vm_memory_size = entry.length;
                    // Limit VM to 64MB max (reasonable for Basin).
                    if (vm_memory_size > 64 * 1024 * 1024) {
                        vm_memory_size = 64 * 1024 * 1024;
                    }
                }
            }
        }

        // Convert physical address to virtual using HHDM.
        if (vm_memory_size >= MIN_VM_MEMORY) {
            vm_memory_ptr = @ptrFromInt(hhdm_offset + vm_memory_base);
        }

        return total_memory > 0 and vm_memory_size >= MIN_VM_MEMORY;
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
    print_at(70, 80, "Vantage VM 20260121.194401.vantage", banner_color);
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

/// Load ELF and set up RISC-V core.
/// Why: Parse RISC-V ELF from Limine module and load into VM memory.
fn load_basin_kernel() bool {
    if (module_request.response) |response| {
        const modules = response.modules();
        if (modules.len > 0) {
            const basin_module = modules[0];
            const elf_data = basin_module.address[0..basin_module.size];

            // Validate ELF header.
            if (elf_data.len < 64) return false;

            // Check ELF magic.
            if (elf_data[0] != 0x7F or elf_data[1] != 'E' or
                elf_data[2] != 'L' or elf_data[3] != 'F')
            {
                return false;
            }

            // Check 64-bit, little-endian, RISC-V.
            if (elf_data[4] != 2) return false; // 64-bit
            if (elf_data[5] != 1) return false; // Little-endian

            // Read machine type (offset 18-19, little-endian).
            const machine: u16 = @as(u16, elf_data[18]) | (@as(u16, elf_data[19]) << 8);
            if (machine != 243) return false; // RISC-V

            // Read entry point (offset 24-31, little-endian).
            var entry: u64 = 0;
            var i: u6 = 0;
            while (i < 8) : (i += 1) {
                entry |= @as(u64, elf_data[24 + i]) << @intCast(i * 8);
            }

            // Read program header offset (offset 32-39).
            var phoff: u64 = 0;
            i = 0;
            while (i < 8) : (i += 1) {
                phoff |= @as(u64, elf_data[32 + i]) << @intCast(i * 8);
            }

            // Read program header count (offset 56-57).
            const phnum: u16 = @as(u16, elf_data[56]) | (@as(u16, elf_data[57]) << 8);

            // Load each PT_LOAD segment.
            const KERNEL_BASE: u64 = 0x80000000;
            var ph_idx: u16 = 0;
            while (ph_idx < phnum) : (ph_idx += 1) {
                const ph_offset = phoff + @as(u64, ph_idx) * 56; // 56 bytes per Phdr
                if (ph_offset + 56 > elf_data.len) break;

                // Read p_type (first 4 bytes).
                const p_type: u32 = @as(u32, elf_data[@intCast(ph_offset)]) |
                    (@as(u32, elf_data[@intCast(ph_offset + 1)]) << 8) |
                    (@as(u32, elf_data[@intCast(ph_offset + 2)]) << 16) |
                    (@as(u32, elf_data[@intCast(ph_offset + 3)]) << 24);

                if (p_type != 1) continue; // Skip non-PT_LOAD

                // Read p_offset (bytes 8-15).
                var p_off: u64 = 0;
                var j: u6 = 0;
                while (j < 8) : (j += 1) {
                    p_off |= @as(u64, elf_data[@intCast(ph_offset + 8 + j)]) << @intCast(j * 8);
                }

                // Read p_vaddr (bytes 16-23).
                var p_vaddr: u64 = 0;
                j = 0;
                while (j < 8) : (j += 1) {
                    p_vaddr |= @as(u64, elf_data[@intCast(ph_offset + 16 + j)]) << @intCast(j * 8);
                }

                // Read p_filesz (bytes 32-39).
                var p_filesz: u64 = 0;
                j = 0;
                while (j < 8) : (j += 1) {
                    p_filesz |= @as(u64, elf_data[@intCast(ph_offset + 32 + j)]) << @intCast(j * 8);
                }

                // Read p_memsz (bytes 40-47).
                var p_memsz: u64 = 0;
                j = 0;
                while (j < 8) : (j += 1) {
                    p_memsz |= @as(u64, elf_data[@intCast(ph_offset + 40 + j)]) << @intCast(j * 8);
                }

                // Translate virtual address to physical.
                const phys_addr = if (p_vaddr >= KERNEL_BASE)
                    p_vaddr - KERNEL_BASE
                else
                    p_vaddr;

                // Bounds check.
                if (phys_addr + p_filesz > vm_memory_size) continue;
                if (p_off + p_filesz > elf_data.len) continue;

                // Copy segment to VM memory.
                var k: u64 = 0;
                while (k < p_filesz) : (k += 1) {
                    vm_memory_ptr[@intCast(phys_addr + k)] = elf_data[@intCast(p_off + k)];
                }

                // Zero-fill BSS (memsz > filesz).
                while (k < p_memsz and phys_addr + k < vm_memory_size) : (k += 1) {
                    vm_memory_ptr[@intCast(phys_addr + k)] = 0;
                }
            }

            // Set entry point.
            riscv_core.set_pc(entry);
            return true;
        }
    }
    return false;
}

/// Vantage VM entry point.
/// Why: Called by Limine after boot.
export fn _start() callconv(.c) noreturn {
    // Verify base revision is supported.
    if (!base_revision.is_supported()) {
        limine.hcf();
    }

    // Initialize framebuffer.
    if (!init_framebuffer()) {
        limine.hcf();
    }
    vantage_state = .framebuffer_init;

    // Initialize HHDM (needed before memory init).
    if (!init_hhdm()) {
        limine.hcf();
    }

    // Initialize memory map.
    if (!init_memory()) {
        limine.hcf();
    }
    vantage_state = .memory_init;

    // Draw boot banner.
    draw_boot_banner();

    // Initialize RISC-V core with allocated memory.
    riscv_core.init(vm_memory_ptr, vm_memory_size);
    vantage_state = .vm_init;
    update_status("RISC-V core initialized");

    // Set up console framebuffer for SBI output.
    console_fb = riscv.Framebuffer.init(
        fb_addr,
        @intCast(fb_width),
        @intCast(fb_height),
        @intCast(fb_pitch),
    );
    // Position console below boot banner.
    console_fb.cursor_y = 16;
    riscv_core.framebuffer = &console_fb;

    // Load Basin kernel from Limine module.
    if (load_basin_kernel()) {
        vantage_state = .basin_loaded;
        update_status("Basin kernel loaded - starting RISC-V");

        // Draw success indicator (green rectangle).
        fill_rect(fb_width - 120, 80, 50, 50, 0x0044ff44);

        // Start RISC-V execution loop.
        vantage_state = .running;

        // Run in batches for responsiveness.
        while (riscv_core.state == .running or riscv_core.state == .ecall) {
            const executed = riscv_core.run(10000);
            if (executed == 0) break;
        }

        // Show final state.
        if (riscv_core.state == .halted) {
            update_status("Basin kernel halted");
        } else if (riscv_core.state == .errored) {
            update_status("Basin kernel error");
            fill_rect(fb_width - 120, 80, 50, 50, 0x00ff4444);
        }
    } else {
        // No Basin kernel module provided.
        update_status("No Basin kernel module - halting");
        fill_rect(fb_width - 120, 80, 50, 50, 0x00ffaa00); // Orange indicator.
    }

    // Halt.
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
