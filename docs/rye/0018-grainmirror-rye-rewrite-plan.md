# Grainmirror Rye Rewrite Plan

**Date**: 2026-01-22-065200-pst  
**Status**: 🆕 **PLANNING** — Plan to rewrite grainmirror in Rye  
**Current**: Written in Zig (`packages/grainmirror/`)  
**Target**: Written in Rye (`packages/grainmirror/`)

---

## Overview

Grainmirror will be rewritten in Rye to:
- Demonstrate Rye compiler capabilities
- Use Rye Style constraints (64 lines, 128 chars, "why" comments)
- Leverage toroidal/garden types for bounded operations
- Self-host Rye development workflow

---

## Current State

### Architecture (Zig)

**Location**: `packages/grainmirror/`

**Modules**:
- `sync.zig` - Repository cloning and updating logic
- `grainmirror.zig` - Public API and re-exports
- `cli.zig` - Command line interface

**Status**: Work in progress (basic structure, TODO implementations)

### Functionality

**Current**:
- ✅ Basic CLI structure
- ✅ Manifest reading (planned)
- ⏳ Repository cloning (TODO)
- ⏳ Repository updating (TODO)
- ⏳ Status checking (TODO)

---

## Target State (Rye)

### Architecture (Rye)

**Location**: `packages/grainmirror/` (same location, rewritten in Rye)

**Modules**:
- `sync.ry` - Repository cloning and updating logic
- `grainmirror.ry` - Public API and re-exports
- `cli.ry` - Command line interface
- `manifest.ry` - Manifest parsing and validation

**Rye Style Compliance**:
- ✅ Functions ≤ 64 lines
- ✅ Lines ≤ 128 characters
- ✅ "Why" comments for all `pub fn`
- ✅ Explicit types (no `usize`/`isize`)
- ✅ Minimum 2 assertions per function
- ✅ No recursion (iterative only)

### Toroidal/Garden Types

**Bounded Operations**:
- `ToroidalBuffer` for repository queue (bounded sync queue)
- `BoundedParam` for retry limits (max retries, timeout)
- `Garden` for repository metadata (bounded repository list)

**Example**:
```rye
/// Why: Bounded repository sync queue with toroidal wrap-around.
const SyncQueue = ToroidalBuffer(Repository, MAX_SYNC_QUEUE_SIZE);

/// Why: Bounded retry count for failed syncs.
const RetryCount = BoundedParam(0, MAX_RETRIES);
```

---

## Migration Strategy

### Phase 1: Parallel Development (Current)

**Status**: Zig version continues development  
**Rye Version**: Start from scratch in Rye

**Approach**:
1. Keep Zig version functional
2. Create Rye version alongside
3. Test Rye version with Rye compiler (when available)
4. Gradually migrate functionality

### Phase 2: Rye Compiler Ready

**When**: Rye compiler Phase 2 (native compiler) is functional

**Approach**:
1. Build grainmirror with Rye compiler
2. Test against real repositories
3. Compare performance with Zig version
4. Fix RISC-V freestanding issues if needed

### Phase 3: Full Migration

**When**: Rye version is feature-complete and tested

**Approach**:
1. Replace Zig version with Rye version
2. Update build system to use Rye
3. Update documentation
4. Remove Zig source files

---

## Implementation Plan

### Module 1: Manifest Parser (`manifest.ry`)

**Purpose**: Parse and validate grainmirror manifest

**Functions**:
- `parseManifest(path: []const u8) Manifest` - Parse TOML manifest
- `validateManifest(manifest: Manifest) !void` - Validate manifest structure
- `getMirror(manifest: Manifest, name: []const u8) ?Mirror` - Get mirror by name

**Rye Style**:
- Max 64 lines per function
- Explicit types (`u32`, `u64`, not `usize`)
- "Why" comments for all public functions
- Minimum 2 assertions per function

### Module 2: Repository Sync (`sync.ry`)

**Purpose**: Clone and update repositories

**Functions**:
- `syncRepository(mirror: Mirror) !void` - Sync single repository
- `cloneRepository(mirror: Mirror) !void` - Clone new repository
- `updateRepository(mirror: Mirror) !void` - Update existing repository
- `checkStatus(mirror: Mirror) Status` - Check repository status

**Toroidal Types**:
- `ToroidalBuffer` for sync queue
- `BoundedParam` for retry limits

**Rye Style**:
- Iterative algorithms (no recursion)
- Bounded operations (MAX_ constants)
- Explicit error handling

### Module 3: CLI (`cli.ry`)

**Purpose**: Command-line interface

**Functions**:
- `main() !void` - Entry point
- `handleSync(args: []const []const u8) !void` - Handle sync command
- `handleStatus(args: []const []const u8) !void` - Handle status command
- `printUsage() void` - Print usage information

**Rye Style**:
- Clear command parsing
- Bounded argument lists
- Explicit error messages

### Module 4: Core API (`grainmirror.ry`)

**Purpose**: Public API and re-exports

**Functions**:
- Re-export all public functions
- Provide unified API
- Document usage

---

## Testing Strategy

### Unit Tests

**Location**: `packages/grainmirror/test/`

**Tests**:
- Manifest parsing tests
- Repository sync tests (mocked)
- CLI argument parsing tests
- Toroidal type tests

**Format**:
```rye
// test/manifest_parser_test.ry
test "parse valid manifest" {
    const manifest = try parseManifest("test_manifest.toml");
    try expect(manifest.mirrors.len > 0);
}
```

### Integration Tests

**Location**: `packages/grainmirror/test/integration/`

**Tests**:
- Full sync workflow
- Error handling
- Retry logic
- Status checking

### Self-Hosting Test

**Purpose**: Use Rye-compiled grainmirror to sync Rye compiler

**Test**:
```bash
# Build grainmirror with Rye
rye build packages/grainmirror/

# Use Rye-compiled grainmirror to sync Rye compiler
./build/bin/grainmirror sync ryelang/rye
```

---

## Build System Integration

### Current (Zig)

```zig
// build.zig
const grainmirror = b.addExecutable("grainmirror", "packages/grainmirror/src/cli.zig");
```

### Future (Rye)

```rye
// build.ry (when Rye build system is ready)
const grainmirror = b.addExecutable("grainmirror", "packages/grainmirror/src/cli.ry");
```

### Transition

**Phase 1**: Build with Zig (current)  
**Phase 2**: Build with Rye transpiler (transpiles to Zig)  
**Phase 3**: Build with Rye compiler (native compilation)

---

## Performance Considerations

### Bounded Operations

**Toroidal Types**: Eliminate edge cases, improve performance

**Example**:
```rye
// Before (unbounded):
for (repos) |repo| { ... }  // No bounds, potential overflow

// After (bounded):
const queue = ToroidalBuffer(Repository, MAX_REPOS);
for (queue.items) |repo| { ... }  // Bounded, no overflow
```

### Garden Allocation

**Memory Management**: Use garden allocation instead of heap

**Example**:
```rye
// Before (heap):
var repos = try allocator.alloc(Repository, count);

// After (garden):
var repo_garden = Garden(Repository, MAX_REPOS);
const repo = try repo_garden.receive(.sync_queue);
```

---

## Documentation

### Code Documentation

**Rye Style**: "Why" comments for all public functions

**Example**:
```rye
/// Why: Sync repository from manifest specification with bounded retries.
pub fn syncRepository(mirror: Mirror) !void {
    // Implementation
}
```

### User Documentation

**Location**: `packages/grainmirror/readme.md`

**Updates**:
- Rewrite in Rye (when complete)
- Document Rye-specific features
- Update examples to use Rye syntax

---

## Success Criteria

### Phase 1 Complete

- ✅ Rye version compiles with Rye compiler
- ✅ All tests pass
- ✅ Rye Style compliance verified
- ✅ Toroidal/garden types integrated

### Phase 2 Complete

- ✅ Feature parity with Zig version
- ✅ Performance comparable or better
- ✅ Self-hosting test passes
- ✅ Documentation updated

### Phase 3 Complete

- ✅ Zig version removed
- ✅ Build system uses Rye
- ✅ All integration tests pass
- ✅ Production ready

---

## Timeline

### Short-Term (Months 1-2)

- Start Rye version development
- Implement manifest parser
- Implement basic sync functionality

### Medium-Term (Months 3-4)

- Complete all modules
- Add toroidal/garden types
- Write comprehensive tests

### Long-Term (Months 5-6)

- Self-hosting test
- Performance optimization
- Full migration from Zig

---

## Dependencies

### Rye Compiler

**Requirement**: Rye compiler Phase 2 (native compiler) must be functional

**Status**: In planning (see `docs/rye/0011-rye-compiler-fork-plan.md`)

### Toroidal/Garden Types

**Requirement**: Rye standard library must include toroidal/garden types

**Status**: In planning (see `docs/rye/0014-toroidal-garden-stdlib-spec.md`)

### Build System

**Requirement**: Rye build system must support executable building

**Status**: Will be part of Rye compiler fork

---

## References

- **Rye Compiler Fork Plan**: `docs/rye/0011-rye-compiler-fork-plan.md`
- **Toroidal/Garden Stdlib Spec**: `docs/rye/0014-toroidal-garden-stdlib-spec.md`
- **Rye Style Guide**: `docs/rye_style.md`
- **Grainmirror Setup**: `docs/rye/0017-rye-compiler-grainmirror-setup.md`
- **Current Grainmirror**: `packages/grainmirror/`

---

**Date**: 2026-01-22-065200-pst  
**Status**: 🆕 **PLANNING** — Plan to rewrite grainmirror in Rye

**Rewrite grainmirror in Rye. Use toroidal types. Enforce Rye Style. Self-host development.**
