# Sevenos Module Architecture: Holistic Design Decision

**Date**: 2026-01-11-143502-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Holistic design decision for sevenos module architecture in build system  
**Status**: 📋 **DESIGN DECISION** — Architecture recommendation

---

## Executive Summary

This document provides a holistic design decision for integrating sevenos (Init System + Shell) modules into the main build.zig. The recommendation is to create a proper module hierarchy that matches sevenos's actual architecture: standalone supervision library + interdependent shell components.

**Goal**: Design module structure that enables test 164 to import sevenos components correctly

**Priority**: HIGH (blocking test execution)

---

## Current Architecture Analysis

### Sevenos Structure

```
grainstore/sevenos/src/
├── lib/
│   └── supervision.zig          # Standalone library (no dependencies on shell)
├── shell/
│   ├── grainscript.zig         # Main shell entry point
│   ├── executor.zig            # Command executor (imports builtins, parser, service_manager, job_manager)
│   ├── builtins.zig            # Built-in commands (imports service_manager)
│   ├── service_manager.zig     # Shell → Init System bridge (imports supervision module)
│   ├── job_manager.zig        # Background job tracking (standalone)
│   ├── parser.zig              # Command parser (standalone)
│   └── stdio_wrapper.zig       # I/O wrapper (standalone)
└── init/
    └── main.zig                # Init system entry point
```

### Dependency Graph

**supervision.zig**:
- ✅ Standalone (only imports std)

**shell/executor.zig**:
- Imports: builtins.zig, parser.zig, stdio_wrapper.zig, service_manager.zig, job_manager.zig
- All relative imports within same directory

**shell/builtins.zig**:
- Imports: stdio_wrapper.zig, service_manager.zig

**shell/service_manager.zig**:
- Imports: supervision (as module), stdio_wrapper.zig

**shell/job_manager.zig**:
- ✅ Standalone (only imports std, posix)

---

## Problem Statement

### Current Issue

Test 164 needs to import:
- `supervision.zig` → Supervisor, ServiceConfig, Service
- `executor.zig` → Executor
- `builtins.zig` → ShellEnvironment
- `service_manager.zig` → ServiceManager
- `job_manager.zig` → JobManager

**Challenge**: These files use relative imports within the same directory, which conflicts with Zig's module system when each file is a separate module root.

### Root Cause

Zig's module system has two modes:
1. **File-based imports**: `@import("../path/file.zig")` - works when files are in same directory structure
2. **Module imports**: `@import("module_name")` - requires proper module configuration

When using modules (as in build.zig), relative file imports from outside the module path are restricted. Files in the same directory that import each other need to be part of the same module.

---

## Design Options

### Option 1: Single Shell Module with Re-exports (RECOMMENDED)

**Approach**: Create a single `sevenos_shell` module with a root file that re-exports all needed types.

**Implementation**:
1. Create `grainstore/sevenos/src/shell/root.zig` that re-exports:
   - `pub const Executor = @import("executor.zig").Executor;`
   - `pub const ShellEnvironment = @import("builtins.zig").ShellEnvironment;`
   - `pub const ServiceManager = @import("service_manager.zig").ServiceManager;`
   - `pub const JobManager = @import("job_manager.zig").JobManager;`
2. Create `sevenos_shell` module pointing to this root.zig
3. Keep `supervision` as separate module (it's standalone)

**Pros**:
- ✅ Matches actual architecture (shell files are interdependent)
- ✅ Allows relative imports to work (all files in same module)
- ✅ Clean API surface (test imports from module, not individual files)
- ✅ Follows Zig module best practices
- ✅ Minimal changes to existing code

**Cons**:
- ⚠️ Requires creating root.zig file (one-time setup)
- ⚠️ Need to maintain re-exports if types change

**Effort**: LOW (create one root.zig file)

---

### Option 2: Individual Modules with Dependency Configuration

**Approach**: Create separate modules but configure dependencies properly.

**Implementation**:
1. Create modules: supervision, executor, builtins, service_manager, job_manager
2. Configure dependencies: executor depends on builtins, service_manager, job_manager, etc.
3. Update imports in files to use module names instead of relative paths

**Pros**:
- ✅ Fine-grained module control
- ✅ Explicit dependencies

**Cons**:
- ❌ Requires changing all relative imports in shell files to module imports
- ❌ More complex dependency management
- ❌ Breaks existing sevenos build.zig structure
- ❌ High effort (modify multiple files)

**Effort**: HIGH (modify 5+ files)

---

### Option 3: Use sevenos's Existing Module Structure

**Approach**: Use the modules already defined in `grainstore/sevenos/build.zig`.

**Implementation**:
1. Import sevenos's build.zig modules into main build.zig
2. Reference them in test configuration

**Pros**:
- ✅ Uses existing structure
- ✅ No duplication

**Cons**:
- ❌ Requires importing build.zig from subdirectory (complex)
- ❌ May not expose what test needs
- ❌ Build system complexity

**Effort**: MEDIUM-HIGH (build system integration)

---

### Option 4: Direct File Imports (No Modules)

**Approach**: Don't use modules for test 164, allow direct file imports.

**Implementation**:
1. Configure test 164 to not use module system
2. Allow direct `@import("../grainstore/...")` imports

**Pros**:
- ✅ Simplest for test file
- ✅ No module configuration needed

**Cons**:
- ❌ Doesn't work with Zig's module system (restricted)
- ❌ Not a sustainable solution
- ❌ Conflicts with other tests using modules

**Effort**: N/A (not possible with current Zig version)

---

## Recommended Solution: Option 1

### Rationale

**Option 1 (Single Shell Module with Re-exports)** is the best holistic design because:

1. **Matches Architecture**: Shell files are interdependent and belong together as a single module
2. **Minimal Changes**: Only requires creating one root.zig file
3. **Clean API**: Test imports from module, not individual files
4. **Maintainable**: Re-exports are easy to maintain
5. **Scalable**: Can add more re-exports as needed
6. **Follows Patterns**: Similar to how other modules work (grain_core, etc.)

### Implementation Plan

1. **Create `grainstore/sevenos/src/shell/root.zig`**:
   ```zig
   //! Sevenos Shell Module Root
   //! Why: Re-export shell components for module-based imports.
   //! Grain Style: Explicit exports, clear API surface.

   // Re-export executor
   pub const Executor = @import("executor.zig").Executor;

   // Re-export builtins
   pub const ShellEnvironment = @import("builtins.zig").ShellEnvironment;
   pub const BuiltinHandler = @import("builtins.zig").BuiltinHandler;
   pub const BuiltinError = @import("builtins.zig").BuiltinError;
   pub const BuiltinResult = @import("builtins.zig").BuiltinResult;

   // Re-export service manager
   pub const ServiceManager = @import("service_manager.zig").ServiceManager;
   pub const ServiceManagerError = @import("service_manager.zig").ServiceManagerError;

   // Re-export job manager
   pub const JobManager = @import("job_manager.zig").JobManager;
   pub const JobStatus = @import("job_manager.zig").JobStatus;

   // Re-export parser (if needed)
   pub const CommandParser = @import("parser.zig").CommandParser;
   ```

2. **Update build.zig**:
   ```zig
   // Supervision module (standalone)
   const sevenos_supervision_module = b.addModule("supervision", .{
       .root_source_file = b.path("grainstore/sevenos/src/lib/supervision.zig"),
       .target = target,
       .optimize = optimize,
   });

   // Shell module (with root.zig re-exports)
   const sevenos_shell_module = b.addModule("sevenos_shell", .{
       .root_source_file = b.path("grainstore/sevenos/src/shell/root.zig"),
       .target = target,
       .optimize = optimize,
       .imports = &.{
           .{ .name = "supervision", .module = sevenos_supervision_module },
       },
   });
   ```

3. **Update test 164 imports**:
   ```zig
   // Init System supervision library
   const supervision = @import("supervision");
   const Supervisor = supervision.Supervisor;
   const ServiceConfig = supervision.ServiceConfig;
   const Service = supervision.Service;

   // Shell components (from module)
   const shell = @import("sevenos_shell");
   const Executor = shell.Executor;
   const ShellEnvironment = shell.ShellEnvironment;
   const ServiceManager = shell.ServiceManager;
   const JobManager = shell.JobManager;
   ```

---

## Benefits of Recommended Solution

### Architecture Alignment

- ✅ **Matches Reality**: Shell files are interdependent, supervision is standalone
- ✅ **Clear Boundaries**: Supervision (lib) vs Shell (shell directory)
- ✅ **Proper Encapsulation**: Module API surface is explicit

### Maintainability

- ✅ **Single Source of Truth**: root.zig defines what's exported
- ✅ **Easy to Extend**: Add re-exports as needed
- ✅ **No Breaking Changes**: Existing sevenos code unchanged

### Testability

- ✅ **Clean Imports**: Test imports from modules, not files
- ✅ **Type Safety**: All types available through module
- ✅ **Documentation**: root.zig serves as API documentation

### Scalability

- ✅ **Future-Proof**: Can add more components easily
- ✅ **Consistent Pattern**: Matches other modules in codebase
- ✅ **Build System Friendly**: Works with Zig's module system

---

## Implementation Steps

1. ✅ **Create root.zig** in `grainstore/sevenos/src/shell/`
2. ✅ **Update build.zig** with proper module configuration
3. ✅ **Update test 164** to use module imports
4. ✅ **Verify compilation** and test execution
5. ✅ **Document** the module structure

---

## Alternative Considerations

### If root.zig Approach Doesn't Work

**Fallback**: Option 2 (Individual Modules with Dependencies)
- More complex but gives fine-grained control
- Requires updating imports in shell files
- Higher maintenance burden

### If Module System Conflicts Persist

**Fallback**: Create wrapper modules in main build.zig
- Create thin wrapper files that re-export types
- Place in `src/` or `tests/` directory
- Less clean but works around restrictions

---

## Conclusion

**Recommended Solution**: **Option 1 - Single Shell Module with Re-exports**

This approach:
- ✅ Matches the actual architecture
- ✅ Requires minimal changes (one new file)
- ✅ Provides clean API surface
- ✅ Is maintainable and scalable
- ✅ Follows Zig module best practices

**Next Action**: Implement root.zig and update build.zig accordingly

---

**Date**: 2026-01-11-143502-pst  
**Voice**: Glow G2 (analytical, solution-focused, direct)  
**Status**: 📋 **DESIGN DECISION** — Option 1 recommended
