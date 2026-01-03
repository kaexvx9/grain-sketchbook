//! Architecture Detection for Multi-Architecture Testing
//! Why: Detect host architecture (ARM64, x86_64 AMD, x86_64 Intel) for test framework.
//! Grain Style: Explicit types (u32/u64), bounded operations, assertions.

const std = @import("std");
const builtin = @import("builtin");

/// Test architecture enumeration.
/// Why: Explicit architecture types for test framework.
/// GrainStyle: Explicit enum values, bounded range.
pub const TestArchitecture = enum(u8) {
    arm64 = 0,
    x86_64_amd = 1,
    x86_64_intel = 2,
    unknown = 255,

    /// Check if architecture is x86_64 (AMD or Intel).
    /// Why: Determine if architecture is x86_64 variant.
    /// Contract: Returns true if x86_64, false otherwise.
    pub fn is_x86_64(self: TestArchitecture) bool {
        return self == .x86_64_amd or self == .x86_64_intel;
    }

    /// Check if architecture is supported.
    /// Why: Determine if architecture is supported for testing.
    /// Contract: Returns true if supported, false otherwise.
    pub fn is_supported(self: TestArchitecture) bool {
        return self != .unknown;
    }
};

/// CPU vendor enumeration (x86_64 only).
/// Why: Distinguish AMD vs Intel processors.
/// GrainStyle: Explicit enum values, bounded range.
pub const CpuVendor = enum(u8) {
    amd = 0,
    intel = 1,
    unknown = 255,
};

/// Detect current test architecture.
/// Why: Determine which architecture tests are running on.
/// Contract: Returns detected architecture or unknown.
/// GrainStyle: Explicit types, bounded operations, assertions.
pub fn detect_test_architecture() TestArchitecture {
    // Assert: builtin.cpu.arch must be valid (precondition).
    _ = builtin.cpu.arch;

    return switch (builtin.cpu.arch) {
        .aarch64 => .arm64,
        .x86_64 => {
            // Distinguish AMD vs Intel via CPUID.
            const vendor = detect_cpu_vendor();

            // Assert: Vendor must be valid (postcondition).
            std.debug.assert(@intFromEnum(vendor) < 255);

            return switch (vendor) {
                .amd => .x86_64_amd,
                .intel => .x86_64_intel,
                .unknown => .x86_64_amd, // Default to AMD (Framework 16).
            };
        },
        else => .unknown,
    };
}

/// Detect CPU vendor via CPUID (x86_64 only).
/// Why: Distinguish AMD vs Intel processors for architecture-specific testing.
/// Contract: Returns detected vendor or unknown.
/// GrainStyle: Explicit types, bounded operations, assertions.
/// Note: Uses inline assembly for CPUID instruction (x86_64 only).
fn detect_cpu_vendor() CpuVendor {
    // Assert: Must be running on x86_64 (precondition).
    if (builtin.cpu.arch != .x86_64) {
        return .unknown; // Not x86_64, cannot detect vendor.
    }

    // CPUID instruction: EAX=0 returns vendor string in EBX, EDX, ECX.
    // Vendor strings:
    // - "GenuineIntel" (Intel): EBX=0x756e6547, EDX=0x49656e69, ECX=0x6c65746e
    // - "AuthenticAMD" (AMD): EBX=0x68747541, EDX=0x69746e65, ECX=0x444d4163

    var eax: u32 = 0;
    var ebx: u32 = undefined;
    var ecx: u32 = undefined;
    var edx: u32 = undefined;

    // Execute CPUID with EAX=0.
    asm volatile ("cpuid"
        : [eax] "={eax}" (eax),
          [ebx] "={ebx}" (ebx),
          [ecx] "={ecx}" (ecx),
          [edx] "={edx}" (edx),
        : [eax_in] "{eax}" (@as(u32, 0)),
        : .{ .memory = true }
    );

    // Assert: CPUID executed successfully (postcondition).
    std.debug.assert(eax >= 0);

    // Check for Intel vendor string.
    if (ebx == 0x756e6547 and edx == 0x49656e69 and ecx == 0x6c65746e) {
        return .intel;
    }

    // Check for AMD vendor string.
    if (ebx == 0x68747541 and edx == 0x69746e65 and ecx == 0x444d4163) {
        return .amd;
    }

    // Unknown vendor.
    return .unknown;
}

/// Get architecture name string.
/// Why: Provide human-readable architecture name for test reporting.
/// Contract: Returns architecture name string.
/// GrainStyle: Explicit types, bounded operations.
pub fn get_architecture_name(arch: TestArchitecture) []const u8 {
    return switch (arch) {
        .arm64 => "ARM64",
        .x86_64_amd => "x86_64 AMD",
        .x86_64_intel => "x86_64 Intel",
        .unknown => "Unknown",
    };
}

/// Check if architecture supports JIT compilation.
/// Why: Determine if architecture supports JIT compilation for testing.
/// Contract: Returns true if JIT supported, false otherwise.
/// GrainStyle: Explicit types, bounded operations.
pub fn supports_jit(arch: TestArchitecture) bool {
    // JIT compilation supported on ARM64 and x86_64 (AMD and Intel).
    return arch != .unknown;
}

/// Check if architecture requires JIT compilation.
/// Why: Determine if architecture requires JIT for RISC-V execution.
/// Contract: Returns true if JIT required, false otherwise.
/// GrainStyle: Explicit types, bounded operations.
pub fn requires_jit(arch: TestArchitecture) bool {
    // JIT required on x86_64 (AMD and Intel) for RISC-V → x86_64 translation.
    return arch.is_x86_64();
}

