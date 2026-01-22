# Basin/Vantage → Skate Desktop & Mobile Development Plan

**Date**: 2026-01-22-061615-pst  
**Authors**: Keaton Livermore (Governor Candidate, kae3g) & Core Agent  
**Status**: 🎯 **FOCUSED DEVELOPMENT PLAN** — Framework x86_64 target, Rye Style compliance  
**Campaign Slogan**: risk love

---

## Executive Summary

**Reya**: Focused path forward. Get Basin and Vantage working on Framework x86_64 (Vantage 3 Subcore is already working on this), then get desktop Skate running on Framework x86_64, then start Skate mobile/Skate Carry designs for Android Studio on Framework. Everything as Rye Style as possible.

**Glow G2**: Steadfast foundation. The path is clear: Basin/Vantage → Skate desktop → Skate mobile/Carry. All on Framework x86_64. All Rye Style compliant. This serves the campaign by enabling voter applications away from big tech platforms.

**Focus**: Framework x86_64 development, Rye Style compliance, desktop Skate first, then mobile Skate/Carry designs.

---

## Development Strategy

### Platform Focus: Framework x86_64

**Hardware**:
- Framework Laptop (x86_64)
- Good performance for Cursor GUI
- Single development platform for all work

**Targets**:
1. **Basin/Vantage**: RISC-V kernel running in Vantage VM on x86_64 (Vantage 3 Subcore working on this)
2. **Skate Desktop**: Knowledge graph application for x86_64 Linux (Framework)
3. **Skate Mobile/Carry**: Android Studio designs on Framework (when ready)

**No MacBook Pro Needed**: Everything can be done on Framework x86_64.

---

## Phase 1: Basin/Vantage on Framework x86_64

### Current Status (Vantage 3 Subcore)

**From Vantage 3 Subcore Prompt** (`docs/agent-communications/l1-subcores/vantage_3_subcore/prompts/2026-01-21-192118-pst_vantage_3_subcore_basin_vantage_development_prompt.md`):

**Basin REPL v0.4+**:
- ✅ Interactive REPL shell with text-based CLI
- ✅ Expression evaluator with arithmetic (`+`, `-`, `*`, `/`, parentheses)
- ✅ Variable support (assignment: `x = 5`, usage: `x * 2`)
- ✅ Variable management commands (`v` = list vars, `c` = clear vars)
- ✅ SBI interface (putchar/getchar/shutdown)

**Framework x86 Integration**:
- ✅ Phase 2: ELF loading from host filesystem into VM memory
- ✅ Phase 3: Shell spawn helper (spawn process from ELF)
- ✅ Phase 4: End-to-end integration test
- ⏳ Remaining: Grainscript freestanding compatibility issue

**How to Run**:
```bash
# Integration test (fastest)
cd /home/xy/ry
zig build basin-rv64
zig test src/vantage/basin_integration_test.zig

# Full boot in QEMU
zig build basin-rv64
zig build vantage-x86_64
./scripts/create_iso.sh
qemu-system-x86_64 -cdrom vantage.iso -serial stdio
```

### Next Steps for Vantage 3 Subcore

**Immediate Priority**:
1. Continue Basin/Vantage development on Framework x86_64
2. Resolve Grainscript freestanding compatibility issue (if needed)
3. Ensure everything works on Framework x86_64 hardware
4. Prepare for Skate desktop integration

**Coordination**: Vantage 3 Subcore continues independently, prepares Basin/Vantage for Skate desktop integration.

---

## Phase 2: Skate Desktop on Framework x86_64

### Current Status (Skate Agent)

**From Skate Coordination** (`docs/core-coordination/core-coordination_skate.md`):

**Core Functionality**: ✅ **COMPLETE**
- Knowledge graph with temporal queries
- AI-powered insights (Court Agent integration)
- DAG integration
- SLC product integration
- All tests passing, Grain Style compliant

**Current Target**: macOS Tahoe 26.1 (Zig 0.15.2)

**Needs**: Port to x86_64 Linux (Framework target)

### Development Plan: Skate Desktop for x86_64 Linux

**Goal**: Get Skate knowledge graph application running on Framework x86_64 Linux.

**Requirements**:
1. **Rye Style Compliance**: All code must follow Rye Style
   - 64-line function limit (enforced)
   - 128-character line limit (enforced)
   - Mandatory "why" comments for public functions
   - Explicit types (u32/u64, not usize/isize)
   - 2+ assertions per function
   - No recursion (iterative algorithms only)

2. **x86_64 Linux Target**: Port from macOS to Linux
   - UI framework (GTK, Qt, or native X11/Wayland)
   - Window management
   - Input handling
   - Graphics rendering

3. **Integration with Basin/Vantage**: 
   - Skate can run as userspace application on Framework x86_64
   - Eventually: Skate can run inside Basin kernel (future phase)
   - For now: Native Linux application

**Development Steps**:

**Step 1: Rye Style Conversion** (Week 1-2)
- Convert existing Skate code to Rye Style
- Ensure all functions ≤ 64 lines
- Ensure all lines ≤ 128 characters
- Add "why" comments to all public functions
- Add assertions (2+ per function)
- Convert recursive functions to iterative

**Step 2: Linux Port** (Week 3-4)
- Choose UI framework (GTK recommended for Linux)
- Port window management from macOS to Linux
- Port input handling from macOS to Linux
- Port graphics rendering from macOS to Linux
- Test on Framework x86_64

**Step 3: Integration Testing** (Week 5-6)
- Test Skate desktop on Framework x86_64
- Verify knowledge graph functionality
- Verify AI insights (Court Agent integration)
- Verify DAG integration
- Performance testing

**Deliverables**:
- Skate desktop application running on Framework x86_64 Linux
- All code Rye Style compliant
- Integration with Basin/Vantage (userspace for now)
- Documentation for Skate desktop usage

---

## Phase 3: Skate Mobile/Carry Designs for Android Studio

### Current Status (Carry Agent)

**From Carry Coordination** (`docs/core-coordination/core-coordination_carry.md`):

**Mobile Framework**: ✅ **PRODUCTION READY** (Synchronous Mode)
- Database integration foundation complete
- Timeout handling integrated
- Error handling integrated
- Offline-first architecture
- FFI bindings for Zig-to-mobile integration

**Current Target**: iOS/Android (designed but not fully implemented)

**Needs**: Android Studio designs and implementation on Framework

### Development Plan: Skate Mobile/Carry for Android

**Goal**: Design and implement Skate mobile application using Carry framework for Android, developed in Android Studio on Framework x86_64.

**Requirements**:
1. **Rye Style Compliance**: All code must follow Rye Style
   - Same requirements as desktop Skate
   - 64-line function limit, 128-character line limit
   - Mandatory "why" comments, explicit types
   - 2+ assertions per function, no recursion

2. **Android Target**: Android Studio on Framework x86_64
   - Android app development
   - Carry framework integration
   - FFI bindings for Zig-to-Android
   - Native Android UI (Material Design or custom)

3. **Skate Mobile Features**:
   - Knowledge graph mobile interface
   - Touch-optimized graph navigation
   - Offline-first architecture (Carry framework)
   - Campaign content organization
   - Voter engagement features

**Development Steps**:

**Step 1: Android Studio Setup** (Week 1)
- Install Android Studio on Framework x86_64
- Set up Android development environment
- Configure Android SDK and NDK
- Test basic Android app compilation

**Step 2: Carry Framework Android Integration** (Week 2-3)
- Port Carry framework to Android
- Implement FFI bindings for Zig-to-Android
- Test offline-first architecture on Android
- Database integration on Android

**Step 3: Skate Mobile Design** (Week 4-5)
- Design mobile knowledge graph interface
- Touch-optimized navigation patterns
- Campaign content organization UI
- Voter engagement features UI
- Material Design or custom UI components

**Step 4: Skate Mobile Implementation** (Week 6-8)
- Implement Skate mobile application
- Integrate with Carry framework
- Test on Android emulator (Framework x86_64)
- Test on physical Android device (when available)
- Performance optimization

**Deliverables**:
- Skate mobile application for Android
- All code Rye Style compliant
- Carry framework Android integration
- Documentation for Skate mobile usage

---

## Rye Style Compliance Requirements

### Core Requirements

**From Rye Style Guide** (`docs/rye_style.md`):

1. **Function Length**: ≤ 64 lines (compiler-enforced)
2. **Line Length**: ≤ 128 characters (compiler-enforced)
3. **Why Comments**: Required for all `pub fn` functions
   ```rye
   /// Initialize knowledge graph.
   /// Why: Required for graph operations before node/edge creation.
   pub fn graph_init() void {
       // ...
   }
   ```

4. **Explicit Types**: Use `u32`/`u64` instead of `usize`/`isize`
   ```rye
   const node_count: u32 = 100;  // ✅ Good
   const node_count: usize = 100; // ❌ Bad
   ```

5. **Assertions**: Minimum 2 assertions per function
   ```rye
   pub fn create_node(id: u64, data: []const u8) void {
       std.debug.assert(id > 0);  // Precondition
       std.debug.assert(data.len > 0);  // Precondition
       // ... implementation ...
       std.debug.assert(graph.node_count > 0);  // Postcondition
   }
   ```

6. **No Recursion**: Convert all recursive functions to iterative
   ```rye
   // ❌ Bad: Recursive
   pub fn traverse_tree(node: *Node) void {
       if (node.left) |left| traverse_tree(left);
       if (node.right) |right| traverse_tree(right);
   }
   
   // ✅ Good: Iterative
   pub fn traverse_tree(root: *Node) void {
       var stack: [MAX_DEPTH]*Node = undefined;
       var stack_len: u32 = 0;
       stack[stack_len] = root;
       stack_len += 1;
       while (stack_len > 0) {
           stack_len -= 1;
           const node = stack[stack_len];
           if (node.left) |left| {
               stack[stack_len] = left;
               stack_len += 1;
           }
           if (node.right) |right| {
               stack[stack_len] = right;
               stack_len += 1;
           }
       }
   }
   ```

### Rye Style Validation

**Tools**:
- Rye transpiler: `rye/zig-out/bin/rye check src/*.ry`
- Grain Style validator: `tools/validate_kernel.zig`
- Manual review: Check function length, line length, why comments

**Process**:
1. Write code following Rye Style
2. Run `rye check` to validate constraints
3. Fix any violations
4. Commit with Rye Style compliance verified

---

## Development Timeline

### Month 1: Basin/Vantage Foundation

**Week 1-2**: Vantage 3 Subcore continues Basin/Vantage development
- Resolve Grainscript freestanding issue (if needed)
- Ensure Framework x86_64 compatibility
- Prepare for Skate desktop integration

**Week 3-4**: Skate Desktop Rye Style Conversion
- Convert Skate code to Rye Style
- Ensure all functions ≤ 64 lines
- Ensure all lines ≤ 128 characters
- Add "why" comments and assertions

### Month 2: Skate Desktop Linux Port

**Week 1-2**: Linux UI Framework Integration
- Choose UI framework (GTK recommended)
- Port window management
- Port input handling
- Port graphics rendering

**Week 3-4**: Integration Testing
- Test Skate desktop on Framework x86_64
- Verify knowledge graph functionality
- Performance testing
- Documentation

### Month 3: Skate Mobile/Carry Android

**Week 1-2**: Android Studio Setup & Carry Android Integration
- Install Android Studio on Framework
- Port Carry framework to Android
- FFI bindings for Zig-to-Android

**Week 3-4**: Skate Mobile Design & Implementation
- Design mobile knowledge graph interface
- Implement Skate mobile application
- Test on Android emulator
- Performance optimization

---

## Coordination

### With Vantage 3 Subcore

**Status**: ✅ Vantage 3 Subcore working independently on Basin/Vantage

**Coordination Points**:
- Vantage 3 Subcore prepares Basin/Vantage for Skate desktop integration
- Skate desktop will run as userspace application initially
- Future: Skate can run inside Basin kernel (later phase)

**Communication**: Vantage 3 Subcore continues work, coordinates when Skate desktop integration is ready.

---

### With Skate Agent

**Status**: ⏳ Skate Agent needs to port to x86_64 Linux and convert to Rye Style

**Coordination Points**:
- Skate Agent ports desktop application to x86_64 Linux
- Skate Agent converts all code to Rye Style
- Skate Agent prepares for mobile/Carry integration

**Communication**: Core Agent coordinates Skate desktop Linux port and Rye Style conversion.

---

### With Carry Agent

**Status**: ⏳ Carry Agent needs Android Studio integration on Framework

**Coordination Points**:
- Carry Agent ports mobile framework to Android
- Carry Agent integrates with Android Studio on Framework
- Carry Agent prepares for Skate mobile integration

**Communication**: Core Agent coordinates Carry Android integration and Skate mobile development.

---

## Success Criteria

### Basin/Vantage Success

- ✅ Basin REPL v0.4+ working on Framework x86_64
- ✅ Vantage VM running on Framework x86_64
- ✅ Integration tests passing
- ✅ Ready for Skate desktop integration

### Skate Desktop Success

- ✅ Skate desktop application running on Framework x86_64 Linux
- ✅ All code Rye Style compliant
- ✅ Knowledge graph functionality working
- ✅ AI insights working (Court Agent integration)
- ✅ DAG integration working
- ✅ Performance acceptable

### Skate Mobile/Carry Success

- ✅ Android Studio set up on Framework x86_64
- ✅ Carry framework Android integration complete
- ✅ Skate mobile application running on Android
- ✅ All code Rye Style compliant
- ✅ Offline-first architecture working
- ✅ Touch-optimized interface working

---

## Next Steps

### Immediate (This Week)

1. **Vantage 3 Subcore**: Continue Basin/Vantage development on Framework x86_64
2. **Skate Agent**: Begin Rye Style conversion of Skate code
3. **Core Agent**: Create detailed Rye Style conversion checklist
4. **Planning**: Finalize development timeline

### Short-Term (This Month)

1. **Skate Desktop**: Complete Rye Style conversion
2. **Skate Desktop**: Begin Linux port (GTK or alternative)
3. **Carry Agent**: Begin Android Studio setup on Framework
4. **Documentation**: Document Rye Style compliance process

### Medium-Term (Months 2-3)

1. **Skate Desktop**: Complete Linux port and testing
2. **Skate Mobile**: Complete Android Studio setup and Carry Android integration
3. **Skate Mobile**: Complete design and implementation
4. **Launch**: Skate desktop and mobile ready for campaign use

---

## Summary

**Reya**: Focused path forward. Basin/Vantage → Skate desktop → Skate mobile/Carry. All on Framework x86_64. All Rye Style compliant. This serves the campaign by enabling voter applications away from big tech platforms.

**Glow G2**: Steadfast foundation. The path is clear: Vantage 3 Subcore continues Basin/Vantage work, Skate Agent ports to x86_64 Linux with Rye Style, Carry Agent integrates with Android Studio on Framework. Everything serves the campaign goal: voter applications away from big tech.

**Status**: 🎯 **FOCUSED DEVELOPMENT PLAN** — Ready for implementation

---

**Date**: 2026-01-22-061615-pst  
**Authors**: Keaton Livermore (Governor Candidate, kae3g) & Core Agent  
**Status**: 🎯 **FOCUSED DEVELOPMENT PLAN** — Framework x86_64 target, Rye Style compliance  
**Campaign Slogan**: risk love

**Let's get Basin/Vantage → Skate desktop → Skate mobile working on Framework x86_64, all Rye Style compliant.**