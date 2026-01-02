# Framework 16: Linux Bootloader Recommendation Aligned with Grain Style

**Date**: 2026-01-01-175712-pst  
**Context**: Framework 16 (x86_64 AMD, 64GB RAM) running Ubuntu 24.04 LTS, migrating to NixOS  
**Purpose**: Recommend Linux bootloader that best aligns with Grain Style principles

---

## Executive Summary

**Recommendation**: **systemd-boot** (for NixOS) or **EFI Stub Booting** (minimal option)

**Rationale**:
1. **systemd-boot**: Minimal, simple, EFI-only, no legacy BIOS support (simpler codebase), integrates with NixOS declarative configuration
2. **EFI Stub Booting**: No bootloader at all (just EFI firmware), absolute minimalism, aligns with "libc-free where possible"
3. **Grain Style Alignment**: Both options prioritize simplicity, minimal dependencies, and explicit configuration

**Alternative Considered**: Limine (modern, simple, minimal dependencies) — **Good option** but less integrated with NixOS

---

## Grain Style Principles Applied to Bootloaders

### Core Principles

From `docs/grain_style.md`:

1. **Minimalism**: Small footprint, avoid unnecessary complexity
2. **Simplicity**: Ease of configuration and maintenance
3. **Explicit Configuration**: No hidden behavior, clear and declarative
4. **Minimal Dependencies**: "libc-free where possible" (or minimal libc usage)
5. **Safety**: Fail-fast, bounded operations, explicit limits
6. **Performance**: Fast boot times, efficient resource utilization
7. **Zero Technical Debt**: Do it right the first time

### Bootloader Evaluation Criteria

**Grain Style Alignment**:
- ✅ **Minimal Dependencies**: Few or no dependencies, minimal libc usage
- ✅ **Simple Codebase**: Small, maintainable, understandable
- ✅ **Explicit Configuration**: Clear, declarative configuration files
- ✅ **Fast Boot**: Minimal overhead, efficient execution
- ✅ **Bounded Operations**: No unbounded loops, explicit limits
- ✅ **Safety**: Fail-fast, clear error handling

---

## Bootloader Options Analysis

### Option 1: systemd-boot ✅ **RECOMMENDED FOR NIXOS**

**Description**: Simple UEFI boot manager (formerly Gummiboot), EFI-only, no legacy BIOS support

**Grain Style Alignment**: ✅ **EXCELLENT**

**Advantages**:
1. **Minimal Dependencies**:
   - EFI-only (no legacy BIOS complexity)
   - Minimal codebase (~10,000 lines of C)
   - No complex filesystem drivers (EFI firmware handles filesystem)
   - Integrates with systemd (if using systemd, which NixOS uses)

2. **Simplicity**:
   - Simple configuration files (`.conf` files in `/boot/loader/entries/`)
   - Declarative configuration (aligns with NixOS philosophy)
   - No complex scripting language (unlike GRUB)
   - Easy to understand and maintain

3. **Explicit Configuration**:
   - Clear, declarative configuration files
   - No hidden behavior
   - Easy to version control (configuration files are text)

4. **Performance**:
   - Fast boot times (minimal overhead)
   - Efficient resource utilization
   - No unnecessary features

5. **NixOS Integration**:
   - NixOS has built-in support for systemd-boot
   - Declarative configuration via `configuration.nix`
   - Automatic generation of boot entries
   - Aligns with NixOS philosophy (declarative, reproducible)

**Disadvantages**:
1. **systemd Dependency**: Requires systemd (but NixOS uses systemd anyway)
2. **EFI-Only**: No legacy BIOS support (but Framework 16 is EFI-only)
3. **Limited Features**: No advanced features like GRUB (but aligns with Grain Style minimalism)

**Configuration Example** (NixOS `configuration.nix`):
```nix
{ config, pkgs, ... }:

{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Explicit boot entries (declarative)
  boot.loader.systemd-boot.configurationLimit = 10;  # Bounded (Grain Style)
}
```

**Grain Style Compliance**:
- ✅ Minimal dependencies (EFI-only, minimal codebase)
- ✅ Simple configuration (declarative `.conf` files)
- ✅ Explicit limits (`configurationLimit` bounds boot entries)
- ✅ Fast boot (minimal overhead)
- ✅ NixOS integration (declarative, reproducible)

---

### Option 2: EFI Stub Booting ✅ **MOST MINIMAL OPTION**

**Description**: No bootloader at all, EFI firmware directly boots Linux kernel

**Grain Style Alignment**: ✅ **EXCELLENT** (Most aligned with "libc-free where possible")

**Advantages**:
1. **Absolute Minimalism**:
   - No bootloader code at all
   - Zero dependencies
   - No libc usage (kernel is self-contained)
   - Aligns perfectly with "libc-free where possible"

2. **Simplicity**:
   - No configuration files
   - No bootloader to maintain
   - EFI firmware handles boot directly

3. **Performance**:
   - Fastest boot (no bootloader overhead)
   - Minimal resource usage
   - Direct kernel execution

4. **Safety**:
   - Fewer components = fewer failure points
   - Kernel handles boot directly
   - No bootloader bugs

**Disadvantages**:
1. **Limited Flexibility**:
   - No boot menu (single kernel boot)
   - No easy kernel switching
   - Requires EFI firmware support

2. **Configuration Complexity**:
   - Must configure EFI firmware directly
   - Less user-friendly
   - Harder to manage multiple kernels

3. **NixOS Integration**:
   - NixOS supports EFI stub booting
   - But less convenient than systemd-boot for multiple kernel versions

**Configuration Example** (NixOS `configuration.nix`):
```nix
{ config, pkgs, ... }:

{
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;  # No bootloader
  
  # EFI stub booting (kernel directly booted by EFI firmware)
  boot.kernelParams = [ "quiet" "splash" ];
}
```

**Grain Style Compliance**:
- ✅ Absolute minimalism (no bootloader)
- ✅ Zero dependencies
- ✅ No libc usage
- ✅ Fastest boot
- ✅ Fewest failure points

---

### Option 3: Limine ⚠️ **GOOD ALTERNATIVE**

**Description**: Modern, portable bootloader written in C, supports multiple architectures

**Grain Style Alignment**: ✅ **GOOD**

**Advantages**:
1. **Minimal Dependencies**:
   - Written in C (no complex dependencies)
   - Minimal codebase (~15,000 lines)
   - Supports multiple architectures (x86_64, ARM64, RISC-V)
   - No systemd dependency

2. **Simplicity**:
   - Simple configuration file (TOML format)
   - Clear, declarative configuration
   - Easy to understand

3. **Modern Design**:
   - Designed for modern systems (EFI, modern hardware)
   - Clean codebase
   - Good documentation

**Disadvantages**:
1. **NixOS Integration**:
   - No built-in NixOS support (would need custom configuration)
   - Less integrated with NixOS declarative configuration
   - Requires manual setup

2. **Community Support**:
   - Smaller community than GRUB or systemd-boot
   - Less documentation for NixOS integration

**Grain Style Compliance**:
- ✅ Minimal dependencies (C only, minimal codebase)
- ✅ Simple configuration (TOML format)
- ✅ Modern design
- ⚠️ Less NixOS integration (requires custom setup)

---

### Option 4: GRUB ❌ **NOT RECOMMENDED**

**Description**: GNU GRUB (GRand Unified Bootloader), most common Linux bootloader

**Grain Style Alignment**: ❌ **POOR**

**Disadvantages**:
1. **Complex Dependencies**:
   - Large codebase (~100,000+ lines)
   - Many dependencies
   - Complex filesystem drivers
   - Legacy BIOS support (unnecessary complexity)

2. **Complexity**:
   - Complex configuration language (GRUB scripting)
   - Hidden behavior
   - Hard to understand and maintain

3. **Performance**:
   - Slower boot (more overhead)
   - More resource usage
   - Unnecessary features

**Grain Style Compliance**:
- ❌ Complex dependencies (large codebase, many dependencies)
- ❌ Complex configuration (GRUB scripting)
- ❌ Hidden behavior
- ❌ Slower boot
- ❌ Not aligned with Grain Style minimalism

**Verdict**: GRUB is too complex and has too many dependencies to align with Grain Style principles.

---

## Recommendation: systemd-boot for NixOS

### Primary Recommendation: systemd-boot

**Why systemd-boot**:
1. **NixOS Integration**: Built-in support, declarative configuration, automatic boot entry generation
2. **Grain Style Alignment**: Minimal dependencies, simple configuration, explicit limits, fast boot
3. **Framework 16 Compatibility**: EFI-only (Framework 16 is EFI-only), no legacy BIOS complexity
4. **Maintainability**: Simple codebase, clear configuration, easy to understand

**Configuration** (NixOS `configuration.nix`):
```nix
{ config, pkgs, ... }:

{
  # Enable systemd-boot
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  
  # Explicit limits (Grain Style: bounded allocations)
  boot.loader.systemd-boot.configurationLimit = 10;  # Max 10 boot entries
  
  # Boot timeout (explicit, bounded)
  boot.loader.timeout = 5;  # 5 seconds
  
  # Editor in boot menu (optional, for debugging)
  boot.loader.systemd-boot.editor = false;  # Disable editor (security)
}
```

**Grain Style Benefits**:
- ✅ Minimal dependencies (EFI-only, minimal codebase)
- ✅ Simple configuration (declarative `.conf` files)
- ✅ Explicit limits (`configurationLimit` bounds boot entries)
- ✅ Fast boot (minimal overhead)
- ✅ NixOS integration (declarative, reproducible)

---

### Alternative Recommendation: EFI Stub Booting

**If absolute minimalism is desired**:

**Configuration** (NixOS `configuration.nix`):
```nix
{ config, pkgs, ... }:

{
  # EFI stub booting (no bootloader)
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.grub.enable = false;  # No bootloader
  
  # Kernel parameters (explicit, bounded)
  boot.kernelParams = [
    "quiet"
    "splash"
    "console=ttyS0,115200"  # Serial console (if needed)
  ];
}
```

**Grain Style Benefits**:
- ✅ Absolute minimalism (no bootloader)
- ✅ Zero dependencies
- ✅ No libc usage
- ✅ Fastest boot
- ✅ Fewest failure points

**Trade-off**: Less convenient for multiple kernel versions, requires EFI firmware configuration.

---

## Implementation Plan

### Phase 1: systemd-boot Setup (Recommended)

**Steps**:
1. **Configure NixOS** (`configuration.nix`):
   ```nix
   boot.loader.systemd-boot.enable = true;
   boot.loader.efi.canTouchEfiVariables = true;
   boot.loader.systemd-boot.configurationLimit = 10;
   ```

2. **Rebuild NixOS**:
   ```bash
   sudo nixos-rebuild switch
   ```

3. **Verify Boot**:
   - Reboot and verify systemd-boot menu appears
   - Verify boot entries are generated correctly
   - Test booting into NixOS

4. **Verify Grain Style Compliance**:
   - Check boot time (should be fast)
   - Verify configuration is declarative (in `configuration.nix`)
   - Verify explicit limits (`configurationLimit`)

**Timeline**: 30 minutes - 1 hour

---

### Phase 2: EFI Stub Booting (Optional, If Desired)

**Steps**:
1. **Configure NixOS** (`configuration.nix`):
   ```nix
   boot.loader.efi.canTouchEfiVariables = true;
   boot.loader.grub.enable = false;
   ```

2. **Rebuild NixOS**:
   ```bash
   sudo nixos-rebuild switch
   ```

3. **Configure EFI Firmware**:
   - Set EFI firmware to boot Linux kernel directly
   - Configure kernel parameters in EFI firmware

4. **Verify Boot**:
   - Reboot and verify EFI firmware boots kernel directly
   - Verify no bootloader is used

**Timeline**: 1-2 hours (more complex EFI firmware configuration)

---

## Grain Style Compliance Summary

### systemd-boot ✅ **RECOMMENDED**

**Grain Style Principles**:
- ✅ **Minimal Dependencies**: EFI-only, minimal codebase (~10,000 lines)
- ✅ **Simplicity**: Simple configuration files, no complex scripting
- ✅ **Explicit Configuration**: Declarative `.conf` files, clear and version-controlled
- ✅ **Bounded Operations**: `configurationLimit` bounds boot entries
- ✅ **Fast Boot**: Minimal overhead, efficient execution
- ✅ **Safety**: Fail-fast, clear error handling
- ✅ **NixOS Integration**: Declarative, reproducible configuration

**Alignment Score**: **9/10** (Excellent alignment with Grain Style)

---

### EFI Stub Booting ✅ **MOST MINIMAL**

**Grain Style Principles**:
- ✅ **Absolute Minimalism**: No bootloader, zero dependencies
- ✅ **No libc Usage**: Kernel is self-contained
- ✅ **Fastest Boot**: No bootloader overhead
- ✅ **Fewest Failure Points**: Fewer components = fewer bugs
- ⚠️ **Less Convenient**: Harder to manage multiple kernels

**Alignment Score**: **10/10** (Perfect alignment with "libc-free where possible", but less convenient)

---

### Limine ⚠️ **GOOD ALTERNATIVE**

**Grain Style Principles**:
- ✅ **Minimal Dependencies**: C only, minimal codebase (~15,000 lines)
- ✅ **Simple Configuration**: TOML format, declarative
- ✅ **Modern Design**: Clean codebase, good documentation
- ⚠️ **Less NixOS Integration**: Requires custom setup

**Alignment Score**: **7/10** (Good alignment, but less NixOS integration)

---

### GRUB ❌ **NOT RECOMMENDED**

**Grain Style Principles**:
- ❌ **Complex Dependencies**: Large codebase (~100,000+ lines), many dependencies
- ❌ **Complexity**: GRUB scripting, hidden behavior
- ❌ **Slower Boot**: More overhead
- ❌ **Not Minimal**: Too many features, unnecessary complexity

**Alignment Score**: **3/10** (Poor alignment with Grain Style minimalism)

---

## Conclusion

**Primary Recommendation**: **systemd-boot** for NixOS on Framework 16

**Why**:
1. **Best NixOS Integration**: Built-in support, declarative configuration, automatic boot entry generation
2. **Grain Style Alignment**: Minimal dependencies, simple configuration, explicit limits, fast boot
3. **Framework 16 Compatibility**: EFI-only (no legacy BIOS complexity)
4. **Maintainability**: Simple codebase, clear configuration, easy to understand

**Alternative**: **EFI Stub Booting** if absolute minimalism is desired (no bootloader at all)

**Implementation**: Configure in NixOS `configuration.nix`, rebuild, verify boot

**Grain Style Compliance**: Both options align well with Grain Style principles (systemd-boot: 9/10, EFI Stub: 10/10)

---

**Date**: 2026-01-01-175712-pst  
**Status**: ✅ **BOOTLOADER RECOMMENDATION COMPLETE** — Ready for Framework 16 NixOS setup  
**Next Steps**: Configure systemd-boot in NixOS `configuration.nix` and rebuild
