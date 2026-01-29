# Rye Style Implementation Roadmap

**Date**: 20260122.190100.rye  
**Author**: Developer  
**Status**: 🚀 **ACTION PLAN** — Concrete steps for Rye Style adoption  

---

## Executive Summary

**Summary**: Concrete path forward. We have the guides, we have the tools, we have the code. Now let's execute. Start with Rye compiler setup, then convert Skate modules one by one, validate with Rye tools, integrate into build system. Step by step, function by function, line by line.

**Details**: Steadfast foundation. The path is clear: set up tools, convert code, validate, integrate. We start small, prove the approach, then scale. Every function ≤ 64 lines. Every line ≤ 128 characters. Every public function has a "why" comment.

**Focus**: Immediate actionable steps to bring Rye Style into Skate desktop development.

---

## Current State Assessment

### Skate Desktop Code

**Location**: `src/grain_skate/`

**Files** (19 .zig files):
- `root.zig` - Root module re-exports
- `block.zig` - Block data structure
- `editor.zig` - Editor implementation
- `graph_viz.zig` - Graph visualization
- `graph_renderer.zig` - Graph rendering
- `temporal_graph.zig` - Temporal graph queries
- `ai_insights.zig` - AI-powered insights
- `slc_dag_integration.zig` - DAG integration
- `storage_integration.zig` - Storage integration
- `editor_renderer.zig` - Editor rendering
- `bracket_matching.zig` - Bracket matching
- `line_buffer_adapter.zig` - Line buffer adapter
- `language_detector.zig` - Language detection
- `language_keywords.zig` - Language keywords
- `social.zig` - Social threading
- `modal_editor.zig` - Modal editor
- `editor_dag_integration.zig` - Editor DAG integration
- `window.zig` - Window management
- `app.zig` - Application entry point

**Status**: All in Zig (.zig), need conversion to Rye (.ry) with Rye Style compliance.

---

## Implementation Roadmap

### Phase 1: Tool Setup & Validation (Day 1)

**Goal**: Set up Rye compiler and validation tools, verify they work.

**Steps**:
1. **Build Rye Compiler**:
   ```bash
   cd /home/xy/grain-sketchbook/rye
   zig build
   ```

2. **Verify Installation**:
   ```bash
   ./zig-out/bin/rye version
   # Should output: rye 0.4.0
   ```

3. **Test Rye Check** (on existing .ry files if any):
   ```bash
   cd /home/xy/grain-sketchbook
   ./rye/zig-out/bin/rye check src/kernel/*.ry 2>&1 | head -20
   ```

4. **Create Test Rye File**:
   ```bash
   # Create test file to verify Rye works
   cat > /tmp/test_rye.ry << 'EOF'
   /// Test function.
   /// Why: Verify Rye compiler works correctly.
   pub fn test_function() void {
       std.debug.assert(true);
   }
   EOF
   
   ./rye/zig-out/bin/rye check /tmp/test_rye.ry
   ```

**Success Criteria**:
- ✅ Rye compiler builds successfully
- ✅ `rye check` command works
- ✅ `rye version` outputs correct version
- ✅ Can validate Rye files

**Deliverable**: Working Rye compiler and validation tools.

---

### Phase 2: Pilot Conversion (Day 2-3)

**Goal**: Convert one small Skate module to Rye Style as proof of concept.

**Target Module**: `block.zig` (likely smallest, core data structure)

**Steps**:
1. **Analyze Current Code**:
   - Read `src/grain_skate/block.zig`
   - Identify function length violations (> 64 lines)
   - Identify line length violations (> 128 chars)
   - Identify missing "why" comments
   - Identify type usage issues (usize/isize)
   - Identify missing assertions
   - Identify recursion (if any)

2. **Convert to Rye Style**:
   - Rename `block.zig` to `block.ry`
   - Fix function length (extract helpers if needed)
   - Fix line length (break long lines)
   - Add "why" comments to all public functions
   - Fix type usage (u32/u64, not usize/isize)
   - Add assertions (2+ per function)
   - Convert recursion to iteration (if any)

3. **Validate with Rye**:
   ```bash
   ./rye/zig-out/bin/rye check src/grain_skate/block.ry
   ```

4. **Fix Violations**:
   - Address all Rye Style violations
   - Re-check until clean

5. **Update Build System**:
   - Update `build.zig` to handle `.ry` files
   - Ensure `block.ry` compiles correctly
   - Run tests to verify functionality

**Success Criteria**:
- ✅ `block.ry` passes `rye check` with zero violations
- ✅ `block.ry` compiles and works correctly
- ✅ All tests passing
- ✅ Build system updated for `.ry` files

**Deliverable**: One Skate module fully converted to Rye Style, proof of concept complete.

---

### Phase 3: Systematic Conversion (Week 1-2)

**Goal**: Convert all Skate modules to Rye Style, one module at a time.

**Conversion Order** (smallest to largest, or dependency order):
1. `block.ry` (already done in Phase 2)
2. `bracket_matching.ry`
3. `language_keywords.ry`
4. `language_detector.ry`
5. `line_buffer_adapter.ry`
6. `temporal_graph.ry`
7. `storage_integration.ry`
8. `editor_dag_integration.ry`
9. `slc_dag_integration.ry`
10. `ai_insights.ry`
11. `social.ry`
12. `graph_viz.ry`
13. `graph_renderer.ry`
14. `editor_renderer.ry`
15. `modal_editor.ry`
16. `editor.ry`
17. `window.ry`
18. `app.ry`
19. `root.ry`

**Process for Each Module**:
1. Analyze current code
2. Convert to Rye Style (same steps as Phase 2)
3. Validate with `rye check`
4. Fix violations
5. Update build system
6. Run tests
7. Commit with Rye Style verified

**Success Criteria**:
- ✅ All Skate modules converted to `.ry` files
- ✅ All modules pass `rye check` with zero violations
- ✅ All modules compile and work correctly
- ✅ All tests passing
- ✅ Build system fully supports `.ry` files

**Deliverable**: All Skate desktop code in Rye Style.

---

### Phase 4: Build System Integration (Week 2)

**Goal**: Integrate Rye validation into build system and CI.

**Steps**:
1. **Add Rye Check Step to build.zig**:
   ```zig
   // In build.zig
   const rye_check = b.addSystemCommand(&.{
       "rye/zig-out/bin/rye",
       "check",
       "--json",
   });
   rye_check.addArgs(&.{
       "src/grain_skate/*.ry",
   });
   const test_step = b.step("rye-check", "Check Rye Style compliance");
   test_step.dependOn(&rye_check.step);
   ```

2. **Add Pre-Commit Hook** (optional):
   ```bash
   # .git/hooks/pre-commit
   #!/bin/sh
   ./rye/zig-out/bin/rye check src/grain_skate/*.ry
   if [ $? -ne 0 ]; then
       echo "Rye Style violations detected. Fix before committing."
       exit 1
   fi
   ```

3. **Add CI Integration** (if CI exists):
   - Run `rye check` in CI pipeline
   - Fail build on violations

**Success Criteria**:
- ✅ `zig build rye-check` validates all Rye files
- ✅ Pre-commit hook prevents commits with violations (if enabled)
- ✅ CI validates Rye Style (if CI exists)

**Deliverable**: Rye Style validation integrated into build system.

---

### Phase 5: Linux Port Preparation (Week 3-4)

**Goal**: Prepare Skate desktop for x86_64 Linux port while maintaining Rye Style.

**Steps**:
1. **Identify Platform-Specific Code**:
   - Find macOS-specific code (Cocoa, AppKit, etc.)
   - Identify UI framework dependencies
   - Identify platform-specific system calls

2. **Abstract Platform Layer**:
   - Create platform abstraction layer
   - All platform-specific code in separate modules
   - Rye Style compliant throughout

3. **Choose Linux UI Framework**:
   - Research: GTK, Qt, or native X11/Wayland
   - Decision: GTK recommended (mature, well-documented)
   - Create Linux UI implementation

4. **Port Window Management**:
   - Port from macOS to Linux
   - Maintain Rye Style compliance
   - Test on Framework x86_64

5. **Port Input Handling**:
   - Port from macOS to Linux
   - Maintain Rye Style compliance
   - Test on Framework x86_64

6. **Port Graphics Rendering**:
   - Port from macOS to Linux
   - Maintain Rye Style compliance
   - Test on Framework x86_64

**Success Criteria**:
- ✅ Platform abstraction layer created
- ✅ Linux UI framework chosen and integrated
- ✅ Window management working on Linux
- ✅ Input handling working on Linux
- ✅ Graphics rendering working on Linux
- ✅ All code Rye Style compliant
- ✅ Tested on Framework x86_64

**Deliverable**: Skate desktop running on Framework x86_64 Linux, all Rye Style compliant.

---

## Immediate Next Steps (Today)

### Step 1: Build Rye Compiler

```bash
cd /home/xy/grain-sketchbook/rye
zig build
```

**Verify**:
```bash
./zig-out/bin/rye version
```

---

### Step 2: Analyze First Module

**Target**: `src/grain_skate/block.zig`

**Analysis**:
1. Count functions and lines per function
2. Check line lengths
3. Check for "why" comments
4. Check type usage
5. Check assertions
6. Check for recursion

**Command**:
```bash
cd /home/xy/grain-sketchbook
wc -l src/grain_skate/block.zig
# Analyze function lengths, line lengths, etc.
```

---

### Step 3: Create Conversion Checklist

**For Each Module**:
- [ ] Rename `.zig` to `.ry`
- [ ] Fix function length (≤ 64 lines)
- [ ] Fix line length (≤ 128 chars)
- [ ] Add "why" comments to all `pub fn`
- [ ] Fix type usage (u32/u64, not usize/isize)
- [ ] Add assertions (2+ per function)
- [ ] Convert recursion to iteration
- [ ] Run `rye check` and fix violations
- [ ] Update build system
- [ ] Run tests
- [ ] Commit with Rye Style verified

---

## Success Metrics

### Phase 1 Success
- ✅ Rye compiler builds
- ✅ `rye check` works
- ✅ Can validate Rye files

### Phase 2 Success
- ✅ One module converted to Rye Style
- ✅ Passes `rye check` with zero violations
- ✅ Compiles and works correctly
- ✅ Proof of concept complete

### Phase 3 Success
- ✅ All Skate modules converted to Rye Style
- ✅ All pass `rye check` with zero violations
- ✅ All compile and work correctly
- ✅ All tests passing

### Phase 4 Success
- ✅ Rye validation in build system
- ✅ Pre-commit hook working (if enabled)
- ✅ CI validation working (if CI exists)

### Phase 5 Success
- ✅ Skate desktop running on Framework x86_64 Linux
- ✅ All code Rye Style compliant
- ✅ Platform abstraction complete
- ✅ Linux UI framework integrated

---

## Timeline Summary

**Day 1**: Tool setup and validation
**Day 2-3**: Pilot conversion (one module)
**Week 1-2**: Systematic conversion (all modules)
**Week 2**: Build system integration
**Week 3-4**: Linux port preparation

**Total**: ~4 weeks to complete Rye Style conversion and Linux port.

---

## Summary

**Summary**: Concrete path forward. Set up tools, convert code, validate, integrate. Start with one module, prove the approach, then scale. Every function ≤ 64 lines. Every line ≤ 128 characters. Every public function has a "why" comment.

**Details**: Steadfast foundation. The path is clear: Phase 1 (tools), Phase 2 (pilot), Phase 3 (systematic), Phase 4 (integration), Phase 5 (Linux port). Step by step, function by function, line by line. Rye Style throughout.

**Status**: 🚀 **ACTION PLAN** — Ready to execute

---

**Date**: 20260122.190100.rye  
**Author**: Developer  
**Status**: 🚀 **ACTION PLAN** — Concrete steps for Rye Style adoption  

**Let's execute. Let's build. Let's convert. Rye Style throughout.**