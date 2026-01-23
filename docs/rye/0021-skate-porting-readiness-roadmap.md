# Skate Porting to Rye: Readiness Roadmap

**Date**: 20260122.183500.rye  
**Status**: 🗺️ **ROADMAP** — When Core 1 Subcore can start porting Skate from Zig to Rye  
**Target**: Skate desktop (x86_64 Linux) ported to Rye

---

## Executive Summary

**Question**: When can Core 1 Subcore start porting Skate from Zig to Rye?

**Answer**: Skate porting can begin after **Phase 2 completion** (RISC-V freestanding fixes), but **Phase 3 completion** (toroidal/garden types + basic stdlib) is recommended for a smoother porting experience.

**Timeline Estimate**: 
- **Earliest start**: Week 5 (after Phase 2)
- **Recommended start**: Week 9 (after Phase 3)
- **Full Rye Style**: Week 13+ (after Phase 4)

---

## Current Skate Status

### Skate Application

**What Skate Is**:
- Native macOS knowledge graph application with social threading
- DAG-based data structures for thought relationships
- Block-based content with transclusion
- Native macOS UI with Vim/Kakoune keybindings
- Currently implemented in **Zig 0.15.2** for macOS Tahoe 26.1

**Target for Porting**:
- **Skate Desktop**: x86_64 Linux (Framework laptop)
- Port from Zig 0.15.2 to Rye
- Maintain functionality while adopting Rye Style

### Skate Dependencies

**Standard Library Features Used**:
- File I/O (`std.fs`, `std.fs.File`, `std.fs.Dir`)
- JSON parsing (`std.json`)
- String manipulation (`std.mem`, `std.fmt`)
- Collections (`std.ArrayList`, `std.HashMap`)
- Networking (if sync features are implemented)
- DAG data structures (custom, but uses stdlib collections)

**Platform Features**:
- Native macOS UI (AppKit/Cocoa)
- File system access
- Window management
- Event handling

---

## Rye Compiler Development Phases

### Phase 1: Fork and Setup ✅ **COMPLETE**

**Status**: ✅ Done  
**Deliverable**: Rye compiler repository with proper attribution

**What This Means for Skate**:
- Repository exists, but compiler not yet functional
- Cannot port Skate yet

---

### Phase 2: RISC-V Freestanding Fixes 🚧 **IN PROGRESS**

**Status**: 🚧 In Progress  
**Timeline**: Weeks 2-4  
**Deliverable**: RISC-V freestanding codegen works correctly

**What This Means for Skate**:
- ✅ Rye compiler can compile code
- ✅ Basic codegen works (not just RISC-V, but x86_64 too)
- ⚠️ Standard library may be incomplete
- ⚠️ Some Zig features may not be fully ported

**Skate Porting Feasibility**: 
- **Possible but challenging**: Can start porting, but will encounter missing stdlib features
- **Workaround**: Use Zig stdlib temporarily, port gradually
- **Risk**: High - many features may not work yet

---

### Phase 3: Toroidal/Garden Types + Basic Stdlib 🎯 **RECOMMENDED START**

**Status**: 🎯 Recommended Start Point  
**Timeline**: Weeks 5-8  
**Deliverable**: Toroidal/garden types available, basic stdlib functional

**What This Means for Skate**:
- ✅ Toroidal/garden types available (may not be needed for Skate initially)
- ✅ Basic stdlib features (file I/O, collections, strings)
- ✅ JSON parsing (if prioritized)
- ✅ Compiler stable enough for application development
- ⚠️ Rye Style enforcement may not be fully integrated

**Skate Porting Feasibility**:
- **Recommended**: Good balance of compiler maturity and feature completeness
- **Approach**: Port Skate gradually, using Rye stdlib where available
- **Risk**: Medium - some features may need workarounds

---

### Phase 4: Rye Style Enforcement 🎨 **FULL RYE STYLE**

**Status**: 🎨 Full Rye Style Ready  
**Timeline**: Weeks 9-12  
**Deliverable**: Rye Style constraints enforced at compiler level

**What This Means for Skate**:
- ✅ All Rye Style constraints enforced (64 lines, 128 chars, "why" comments)
- ✅ Compiler errors for style violations
- ✅ Skate code must be Rye Style compliant
- ✅ Full stdlib available

**Skate Porting Feasibility**:
- **Ideal**: Full Rye Style enforcement, complete stdlib
- **Approach**: Port with Rye Style from the start
- **Risk**: Low - compiler is mature, stdlib complete

---

### Phase 5: Self-Hosting 🔄 **OPTIONAL FOR SKATE**

**Status**: 🔄 Optional for Skate  
**Timeline**: Weeks 13-16  
**Deliverable**: Rye compiler written in Rye, built with Rye

**What This Means for Skate**:
- ✅ Compiler is self-hosted (not required for Skate)
- ✅ Demonstrates Rye maturity
- ✅ Skate can use self-hosted compiler

**Skate Porting Feasibility**:
- **Not Required**: Self-hosting is for compiler development, not application development
- **Benefit**: More stable compiler, but not a blocker

---

## Recommended Porting Strategy

### Option 1: Early Start (After Phase 2) ⚠️ **CHALLENGING**

**When**: Week 5 (after RISC-V fixes complete)  
**Approach**:
- Start porting Skate core data structures
- Use Zig stdlib temporarily where Rye stdlib is missing
- Gradually replace Zig dependencies as Rye stdlib matures
- Accept that some features may not work initially

**Pros**:
- Early feedback on Rye compiler for application code
- Can identify missing stdlib features early
- Parallel development with compiler phases

**Cons**:
- High risk of blockers (missing stdlib features)
- May need to maintain Zig compatibility layer
- Slower progress due to compiler limitations

---

### Option 2: Recommended Start (After Phase 3) ✅ **RECOMMENDED**

**When**: Week 9 (after toroidal/garden types + basic stdlib)  
**Approach**:
- Port Skate with Rye stdlib from the start
- Use toroidal/garden types where beneficial (optional)
- Full Rye Style compliance (if Phase 4 is also complete)
- Clean port without Zig compatibility layer

**Pros**:
- Stable compiler with complete basic stdlib
- Can use Rye features (toroidal/garden) if beneficial
- Cleaner port without Zig workarounds
- Better developer experience

**Cons**:
- Must wait for Phase 3 completion
- Some advanced features may still need work

---

### Option 3: Full Rye Style Start (After Phase 4) 🎨 **IDEAL**

**When**: Week 13 (after Rye Style enforcement)  
**Approach**:
- Port Skate with full Rye Style compliance from day one
- All compiler constraints enforced
- Complete stdlib available
- Production-ready code

**Pros**:
- Full Rye Style enforcement
- Complete stdlib
- Production-ready compiler
- No technical debt from style violations

**Cons**:
- Must wait longer (Week 13+)
- May delay Skate development timeline

---

## Skate-Specific Requirements

### Critical Features for Skate Porting

**Must Have** (for basic functionality):
1. ✅ File I/O (`std.fs.File`, `std.fs.Dir`)
2. ✅ String manipulation (`std.mem`, `std.fmt`)
3. ✅ Collections (`std.ArrayList`, `std.HashMap`)
4. ✅ Basic error handling

**Should Have** (for full functionality):
1. ⚠️ JSON parsing (`std.json`)
2. ⚠️ UUID generation (`std.crypto`)
3. ⚠️ Date/time handling (`std.time`)
4. ⚠️ Path manipulation (`std.fs.path`)

**Nice to Have** (for advanced features):
1. 🔮 Networking (if sync features)
2. 🔮 Native UI bindings (x86_64 Linux, not macOS)
3. 🔮 Graph visualization libraries

### Platform Considerations

**Current Skate**: macOS Tahoe 26.1 (native AppKit/Cocoa)  
**Target Skate**: x86_64 Linux (Framework laptop)

**Porting Challenges**:
- Native UI: Must port from AppKit/Cocoa to Linux UI framework
- Platform-specific APIs: File system, window management
- Event handling: Different event models

**Rye Compiler Requirements**:
- ✅ x86_64 Linux target support (not just RISC-V)
- ✅ C interop for UI libraries
- ✅ Platform-specific stdlib features

---

## Timeline Estimate

### Conservative Estimate (Recommended Start)

**Week 9** (After Phase 3):
- ✅ Rye compiler stable
- ✅ Basic stdlib complete
- ✅ Can start Skate porting
- ⚠️ Some features may need workarounds

**Week 13** (After Phase 4):
- ✅ Full Rye Style enforcement
- ✅ Complete stdlib
- ✅ Production-ready compiler

**Week 17+** (Skate Porting):
- Port Skate core (2-4 weeks)
- Port Skate UI (2-4 weeks)
- Testing and refinement (1-2 weeks)
- **Total**: 5-10 weeks for complete port

### Aggressive Estimate (Early Start)

**Week 5** (After Phase 2):
- ⚠️ Start porting with limitations
- ⚠️ Use Zig compatibility layer
- ⚠️ Gradual migration as stdlib matures

**Week 9** (After Phase 3):
- ✅ Migrate to Rye stdlib
- ✅ Remove Zig compatibility layer

**Week 13** (After Phase 4):
- ✅ Full Rye Style compliance
- ✅ Production-ready code

**Total**: 8-12 weeks (longer due to workarounds)

---

## Decision Matrix

| Factor | Early Start (Week 5) | Recommended (Week 9) | Full Style (Week 13) |
|--------|---------------------|---------------------|---------------------|
| **Compiler Stability** | ⚠️ Medium | ✅ High | ✅ Very High |
| **Stdlib Completeness** | ⚠️ Low | ✅ Medium | ✅ High |
| **Rye Style Enforcement** | ❌ No | ⚠️ Partial | ✅ Full |
| **Porting Speed** | ⚠️ Slow | ✅ Medium | ✅ Fast |
| **Technical Debt** | ⚠️ High | ✅ Low | ✅ None |
| **Risk Level** | ⚠️ High | ✅ Medium | ✅ Low |

---

## Recommendation

### 🎯 **Start Skate Porting After Phase 3 (Week 9)**

**Rationale**:
1. **Compiler Maturity**: Rye compiler is stable enough for application development
2. **Stdlib Completeness**: Basic features (file I/O, collections, strings) are available
3. **Clean Port**: Can use Rye stdlib from the start, no Zig compatibility layer needed
4. **Timeline**: Reasonable wait time (4 weeks from now), not too long
5. **Risk**: Medium risk, manageable with good planning

**If Phase 4 Completes Early**:
- Start with full Rye Style enforcement from day one
- Even better developer experience
- No technical debt from style violations

**If Phase 3 Delays**:
- Can start earlier (Week 5) with workarounds
- Use Zig compatibility layer temporarily
- Migrate to Rye stdlib as it becomes available

---

## Next Steps

### For Rye Compiler Development

1. **Complete Phase 2** (Weeks 2-4):
   - Fix RISC-V freestanding bugs
   - Ensure x86_64 target also works
   - Test with simple applications

2. **Complete Phase 3** (Weeks 5-8):
   - Add toroidal/garden types
   - Implement basic stdlib (file I/O, collections, strings)
   - Prioritize JSON parsing if Skate needs it
   - Test with application-like code

3. **Complete Phase 4** (Weeks 9-12):
   - Integrate Rye Style enforcement
   - Make constraints compiler errors
   - Test with real application code

### For Core 1 Subcore (Skate Porting)

1. **Prepare for Porting** (Now - Week 9):
   - Document Skate dependencies
   - Identify which stdlib features are critical
   - Plan porting strategy (gradual vs. all-at-once)
   - Prepare test cases

2. **Start Porting** (Week 9+):
   - Port Skate core data structures first
   - Port Skate file I/O and storage
   - Port Skate UI (x86_64 Linux)
   - Test and refine

3. **Rye Style Compliance** (Week 13+):
   - Ensure all code meets Rye Style constraints
   - Refactor if needed for 64-line/128-char limits
   - Add "why" comments to all public functions

---

## Success Criteria

### Skate Porting Can Begin When:

- ✅ Rye compiler can compile x86_64 Linux applications
- ✅ Basic stdlib features available (file I/O, collections, strings)
- ✅ Compiler is stable enough for application development
- ✅ Test cases can be written and run

### Skate Porting Complete When:

- ✅ Skate compiles with Rye compiler
- ✅ Skate runs on x86_64 Linux (Framework laptop)
- ✅ All functionality preserved from Zig version
- ✅ Code is Rye Style compliant (64 lines, 128 chars, "why" comments)
- ✅ No Zig dependencies remaining

---

## References

- **Rye Fork Plan**: `docs/rye/0011-rye-compiler-fork-plan.md`
- **Rye Fork Summary**: `docs/rye/0016-rye-compiler-fork-summary.md`
- **RISC-V Fix Strategy**: `docs/rye/0013-riscv-freestanding-fix-strategy.md`
- **Toroidal/Garden Types**: `docs/rye/0014-toroidal-garden-stdlib-spec.md`
- **Rye Style Enforcement**: `docs/rye/0015-rye-style-compiler-enforcement.md`
- **Skate Specification**: `docs/grain_skate_agent_prompt.md`
- **Rye Style Conversion Guide**: `docs/rye/0022-rye-style-conversion-vs-compiler-fork.md`

---

**Date**: 20260122.183500.rye  
**Status**: 🗺️ **ROADMAP** — Ready for review and decision

**Recommendation**: Start Skate porting after **Phase 3 completion (Week 9)** for best balance of compiler maturity and feature completeness.
