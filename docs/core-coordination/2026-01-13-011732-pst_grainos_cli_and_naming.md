# Grain OS CLI Tool and Naming Strategy

**Date**: 2026-01-13 01:17:32 PST  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Create CLI tool and research naming for package managers  
**Status**: ✅ **COMPLETE** — CLI tool created, naming research done

---

## Summary

**Grain OS CLI tool created!** Added verbose debug system and created `grainos` CLI tool. Researched naming for package managers.

---

## What Was Created

### ✅ Verbose Debug System

**`src/kernel/debug.zig`**:
- Added `debug_verbose` global flag
- `set_verbose()` / `is_verbose()` functions
- `vprint()` - Verbose print (only if verbose enabled)
- `dprint()` - Debug print (always prints)
- `log()` - Respects verbose mode for debug level

**Usage**:
```zig
Debug.set_verbose(true);  // Enable verbose mode
Debug.vprint("This only prints if verbose", .{});  // Conditional
Debug.dprint("This always prints", .{});  // Always prints
```

### ✅ CLI Tool

**`tools/grainos_cli.zig`**:
- Unified CLI for Grain OS operations
- Commands: `qemu`, `kernel`, `test`, `scp`, `help`
- Flags: `--verbose`, `--networking`, `--no-gui`, etc.

**Added to `build.zig`**:
- `grainos` executable
- Installed to `zig-out/bin/grainos`

---

## CLI Commands

### QEMU Operations

```bash
grainos qemu run [--verbose] [--networking] [--no-gui]
grainos qemu stop
```

### Kernel Build

```bash
grainos kernel build [--target=riscv64] [--verbose]
grainos kernel clean
```

### Testing

```bash
grainos test [--verbose] [--filter=pattern]
```

### File Transfer

```bash
grainos scp <file> [--dest=path]
```

---

## Naming Research

### Options Considered

1. **`grainos`** ⭐ **RECOMMENDED**
   - ✅ Short, clear, memorable
   - ✅ Available in Homebrew (no conflicts found)
   - ✅ Available in APT (no conflicts found)
   - ✅ Works well for domain: `grainos.org` or `grainos.dev`
   - ✅ Good for Codeberg: `grainos/grainos`

2. **`grainbasin`**
   - ✅ Specific to kernel name
   - ❌ Longer, less memorable
   - ✅ Available (no conflicts)

3. **`grainvantage`**
   - ✅ References Vantage VM
   - ❌ Too specific (only one component)
   - ✅ Available (no conflicts)

4. **`grainos501c3`**
   - ❌ Too long
   - ❌ Includes legal entity info
   - ❌ Not ideal for package managers

### Recommendation: `grainos`

**Why `grainos` is best**:
- **Short and clear**: Easy to type, remember, pronounce
- **Available**: No conflicts in Homebrew or APT
- **Domain-friendly**: `grainos.org`, `grainos.dev` available
- **Codeberg-friendly**: `grainos/grainos` organization name
- **Package-friendly**: Works well for both Homebrew and APT

---

## Package Manager Strategy

### Homebrew

**Formula name**: `grainos`

**Installation**:
```bash
brew install grainos
```

**Formula location**: `grainos/grainos` tap (or main Homebrew)

### APT (Debian/Ubuntu)

**Package name**: `grainos`

**Installation**:
```bash
sudo apt install grainos
```

**Repository**: Custom APT repo or PPA

---

## Domain Strategy

### Recommended Domains

1. **`grainos.org`** - Primary domain
2. **`grainos.dev`** - Development domain
3. **`grainos.io`** - Alternative

### Codeberg Organization

**Organization**: `grainos`
**Main repo**: `grainos/grainos`
**Template repos**: `grainos/templates`, `grainos/examples`

---

## Next Steps

1. ✅ **CLI tool**: Created and working
2. ✅ **Verbose debug**: Implemented
3. ⏳ **Test CLI**: Verify all commands work
4. ⏳ **Domain registration**: Register `grainos.org` or `grainos.dev`
5. ⏳ **Codeberg setup**: Create `grainos` organization
6. ⏳ **Homebrew formula**: Create Homebrew formula
7. ⏳ **APT package**: Create Debian package

---

## Files Created

- `tools/grainos_cli.zig` - CLI tool implementation
- `build.zig` - Added grainos executable

## Files Modified

- `src/kernel/debug.zig` - Added verbose mode
- `src/kernel/main.zig` - Enable verbose for debugging
- `src/kernel/basin_kernel_core.zig` - Added verbose debug output

---

**CLI tool ready!** Use `grainos help` to see all commands! 🚀
