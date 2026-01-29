# Clutch OS Codebase Renaming Plan

**Date**: 2026-01-15-150758-pst  
**Variant**: Clutch OS (keatonlivermore/grain-sketchbook)  
**System**: Clutch Synonym (adapted from Grain Synonym spec)  
**Status**: 🆕 **PLAN** — Comprehensive renaming strategy

---

## Executive Summary

This plan outlines the systematic renaming of codebase elements from Grain OS naming to Clutch OS naming, following the **Clutch Synonym** variant system principles. The goal is to transform the technical codebase to use Clutch OS aesthetic names (Harbor, Clutch, etc.) while maintaining technical compatibility and code quality.

**Key Principle**: Following the Clutch Synonym spec, we maintain semantic mapping between technical concepts and aesthetic names, but in Clutch OS's own codebase, we can use the aesthetic names directly in code.

---

## 1. Renaming Strategy

### 1.1 Core Principle

**Clutch Synonym Approach**: In Clutch OS's own codebase (`keatonlivermore/grain-sketchbook`), we use Clutch OS aesthetic names directly in code, not just in documentation. This is a variant-specific implementation choice.

**Semantic Mappings**:
- `Basin` (kernel) → `Harbor` (mechanical/industrial destination)
- `Grain` (general) → `Clutch` (enabling framework)
- `Vantage` → `Vantage` (unchanged, neutral)

### 1.2 Scope

**What Gets Renamed**:
- File names (`basin_kernel.zig` → `harbor_kernel.zig`)
- Type names (`BasinKernel` → `HarborKernel`)
- Function names (`basin_*` → `harbor_*`)
- Variable names (`basin_*` → `harbor_*`)
- Module names (`grain_synonym` → `clutch_synonym`)
- Documentation references
- Test file names
- Build system references

**What Stays the Same**:
- `Vantage` (neutral, works for both variants)
- Technical interfaces (syscalls, APIs remain compatible)
- Core functionality (no behavioral changes)

---

## 2. Phase 1: Module and File Renaming

### 2.1 Kernel Files (Basin → Harbor)

**Source Files** (`src/kernel/`):
- `basin_kernel.zig` → `harbor_kernel.zig`
- `basin_kernel_core.zig` → `harbor_kernel_core.zig`
- `basin_kernel_types.zig` → `harbor_kernel_types.zig`
- `basin_kernel_syscalls_process.zig` → `harbor_kernel_syscalls_process.zig`
- `basin_kernel_syscalls_file.zig` → `harbor_kernel_syscalls_file.zig`
- `basin_kernel_syscalls_network.zig` → `harbor_kernel_syscalls_network.zig`
- `basin_kernel_syscalls_audio.zig` → `harbor_kernel_syscalls_audio.zig`
- `basin_kernel_syscalls_stats.zig` → `harbor_kernel_syscalls_stats.zig`

**Test Files** (`tests/`):
- `*_basin_*.zig` → `*_harbor_*.zig`
- Update test imports and references

**Documentation Files** (`docs/`):
- `*basin*.md` → `*harbor*.md` (where appropriate)
- Update content references

### 2.2 Synonym Module (Grain → Clutch)

**Source Files** (`src/`):
- `grain_synonym/` → `clutch_synonym/`
  - `variant_config.zig` → Update to use "Clutch Synonym" terminology
  - `semantic_map.zig` → Update mappings to Clutch OS
  - `root.zig` → Update exports

### 2.3 Build System

**Files**:
- `build.zig` → Update references to `basin` → `harbor`
- `build/kernel.zig` → Update kernel build references

---

## 3. Phase 2: Type and Function Renaming

### 3.1 Kernel Types

**Core Types**:
- `BasinKernel` → `HarborKernel`
- `BasinError` → `HarborError`
- `BasinSyscall` → `HarborSyscall`
- `BasinHandle` → `HarborHandle`
- All `Basin*` types → `Harbor*`

**Function Names**:
- `basin_kernel_*` → `harbor_kernel_*`
- `basin_*` → `harbor_*`
- Update all function implementations

### 3.2 Module Imports

**Update All Imports**:
```zig
// Old
const BasinKernel = @import("basin_kernel.zig").BasinKernel;

// New
const HarborKernel = @import("harbor_kernel.zig").HarborKernel;
```

### 3.3 Variable Names

**Update Variable Names**:
- `basin` → `harbor`
- `basin_kernel` → `harbor_kernel`
- `basin_*` → `harbor_*`

---

## 4. Phase 3: Documentation Updates

### 4.1 Code Comments

**Update All Comments**:
- "Basin kernel" → "Harbor kernel"
- "Grain OS" → "Clutch OS" (where appropriate)
- Update module documentation

### 4.2 Documentation Files

**Update Documentation**:
- Replace "Basin" with "Harbor" in all docs
- Update semantic mapping references
- Update architecture diagrams
- Update agent prompts and coordination docs

### 4.3 README and Project Files

**Update Project Files**:
- `readme.md` → Update references
- `readme_org.md` → Update org references
- Repository description → Update to Clutch OS

---

## 5. Phase 4: Test Updates

### 5.1 Test File Renaming

**Test Files**:
- Rename all `*basin*` test files to `*harbor*`
- Update test imports
- Update test function names
- Update test descriptions

### 5.2 Test Content

**Update Test Code**:
- Replace `Basin*` types with `Harbor*`
- Update test assertions
- Update test documentation

---

## 6. Implementation Steps

### Step 1: Preparation
1. Create backup branch: `git checkout -b backup-before-renaming`
2. Commit current state
3. Create feature branch: `git checkout -b rename-basin-to-harbor`

### Step 2: File Renaming
1. Rename kernel files (`basin_*` → `harbor_*`)
2. Rename synonym module (`grain_synonym` → `clutch_synonym`)
3. Rename test files
4. Commit: `feat: Rename kernel files from Basin to Harbor`

### Step 3: Type Renaming
1. Update all type definitions (`Basin*` → `Harbor*`)
2. Update all type usages
3. Update imports
4. Commit: `feat: Rename kernel types from Basin to Harbor`

### Step 4: Function Renaming
1. Update function names (`basin_*` → `harbor_*`)
2. Update function calls
3. Update exports
4. Commit: `feat: Rename kernel functions from Basin to Harbor`

### Step 5: Variable Renaming
1. Update variable names (`basin` → `harbor`)
2. Update all references
3. Commit: `feat: Rename variables from Basin to Harbor`

### Step 6: Build System
1. Update `build.zig` references
2. Update `build/kernel.zig`
3. Test build
4. Commit: `feat: Update build system for Harbor kernel`

### Step 7: Documentation
1. Update code comments
2. Update documentation files
3. Update README
4. Commit: `docs: Update documentation for Harbor kernel`

### Step 8: Tests
1. Rename test files
2. Update test code
3. Run test suite
4. Fix any failures
5. Commit: `test: Update tests for Harbor kernel`

### Step 9: Final Verification
1. Run full test suite
2. Verify build works
3. Check for any remaining references
4. Final commit: `feat: Complete Basin → Harbor renaming`

### Step 10: Merge
1. Merge to main
2. Push to remote
3. Update any external references

---

## 7. Search and Replace Patterns

### 7.1 Exact Matches

**Basin → Harbor**:
- `Basin` → `Harbor` (type names)
- `basin` → `harbor` (variable/function names)
- `BASIN` → `HARBOR` (constants)

**File Patterns**:
- `basin_kernel` → `harbor_kernel`
- `basin_*` → `harbor_*`

### 7.2 Context-Aware Replacements

**Comments and Documentation**:
- "Basin kernel" → "Harbor kernel"
- "the Basin" → "the Harbor"
- "Basin's" → "Harbor's"

**Module References**:
- `@import("basin_kernel.zig")` → `@import("harbor_kernel.zig")`
- `grain_synonym` → `clutch_synonym`

---

## 8. Verification Checklist

### 8.1 Code Verification
- [ ] All files renamed
- [ ] All types renamed
- [ ] All functions renamed
- [ ] All variables renamed
- [ ] All imports updated
- [ ] All exports updated
- [ ] Build compiles successfully
- [ ] No compilation errors
- [ ] No unused imports

### 8.2 Test Verification
- [ ] All test files renamed
- [ ] All tests pass
- [ ] Test coverage maintained
- [ ] No test failures

### 8.3 Documentation Verification
- [ ] All code comments updated
- [ ] All documentation files updated
- [ ] README updated
- [ ] No broken references

### 8.4 Build System Verification
- [ ] `build.zig` updated
- [ ] `build/kernel.zig` updated
- [ ] Build succeeds
- [ ] No build warnings

---

## 9. Risk Mitigation

### 9.1 Potential Issues

**Import Cycles**: Renaming might create import issues
- **Mitigation**: Update imports systematically, test after each phase

**Breaking Changes**: External code might depend on old names
- **Mitigation**: This is Clutch OS's own codebase, so external dependencies are minimal

**Test Failures**: Tests might fail after renaming
- **Mitigation**: Run tests after each phase, fix incrementally

**Build Failures**: Build might break during renaming
- **Mitigation**: Commit after each phase, test build frequently

### 9.2 Rollback Plan

**If Issues Arise**:
1. Revert to backup branch
2. Identify problematic changes
3. Fix incrementally
4. Re-apply changes in smaller batches

---

## 10. Timeline

### Week 1: File and Type Renaming
- Days 1-2: File renaming
- Days 3-4: Type renaming
- Day 5: Testing and fixes

### Week 2: Function and Variable Renaming
- Days 1-2: Function renaming
- Days 3-4: Variable renaming
- Day 5: Testing and fixes

### Week 3: Build System and Documentation
- Days 1-2: Build system updates
- Days 3-4: Documentation updates
- Day 5: Final verification

---

## 11. Success Criteria

**Phase 1 Complete**:
- All kernel files renamed to Harbor
- All types renamed to Harbor
- Build compiles successfully

**Phase 2 Complete**:
- All functions renamed to Harbor
- All variables renamed to Harbor
- Tests pass

**Phase 3 Complete**:
- Build system updated
- Documentation updated
- All references updated

**Final Success**:
- Full test suite passes
- Build succeeds
- No remaining "Basin" references in code
- Clutch OS aesthetic identity fully reflected in codebase

---

## 12. Notes

**Clutch Synonym Principle**: This renaming follows the Clutch Synonym variant system, where Clutch OS uses its own aesthetic names in code, not just in documentation. This is a variant-specific choice that maintains technical compatibility while expressing Clutch OS's mechanical/industrial identity.

**Technical Compatibility**: Despite renaming, the kernel maintains technical compatibility with the original Basin kernel design. The renaming is semantic/aesthetic, not functional.

**Future Cross-Pollination**: After renaming, Clutch OS (Harbor) and Grain OS (Basin) can still exchange ideas through semantic analysis, as the technical concepts remain compatible even with different names.

---

**Date**: 2026-01-15-150758-pst  
**Status**: 🆕 **PLAN READY** — Ready for Implementation  
**Next Steps**: Begin Phase 1 (File Renaming)
