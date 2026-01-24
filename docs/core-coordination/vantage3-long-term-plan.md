# Vantage 3: Long-Term Plan

**Last Updated**: 2026-01-23-163538-pst  
**Status**: 📋 **ACTIVE PLANNING**

---

## Mission Overview

Develop Rye compiler fork for Basin kernel, Skate porting, and Grain OS GUI integration. Support RISC-V64 freestanding, enforce Rye Style constraints, and enable GUI applications on Grain OS.

---

## Completed Phases ✅

### Phase 1: Fork & Setup
- **Status**: ✅ Complete
- **Duration**: Week 1
- **Achievements**: Forked Zig 0.15.2, established repository structure

### Phase 2: RISC-V Freestanding Fixes
- **Status**: ✅ Complete
- **Duration**: Weeks 2-4
- **Achievements**:
  - Fixed global variable addressing (AUIPC)
  - Optimized conditional branch codegen
  - Fixed frame layout for large frames
  - Verified kernel integration

### Phase 3: Toroidal/Garden Types + Basic Stdlib
- **Status**: ✅ Complete
- **Duration**: Weeks 5-8
- **Achievements**:
  - Implemented bounded data structures
  - Established memory allocation model
  - Basic stdlib modules available

### Phase 4: Rye Style Enforcement
- **Status**: ✅ Complete (Core Checks)
- **Duration**: Weeks 9-12
- **Achievements**:
  - Function length check (64 lines, AST-based)
  - Line length check (128 chars, optimized)
  - Why comment check (comprehensive, nested)
  - Explicit type check (no usize/isize)
  - 11 comprehensive test cases
  - Integration with Core 1 (19/19 modules validated)

---

## Current Phase: GUI/OS Integration Foundation

### Phase 5: GUI Foundation (Weeks 13-16)
**Status**: 🚧 **IN PROGRESS** (25% Complete)

#### Objectives
1. ✅ Add `.ry` file extension support — **COMPLETE**
2. 🚧 Wayland protocol implementation (basic) — **PLANNING**
3. 🚧 Basic window system primitives — **PENDING**
4. 🚧 Input handling library — **PENDING**

#### Success Criteria
- ✅ `.ry` files compile directly — **COMPLETE** (rebuild needed)
- 🚧 Basic Wayland protocol working — **PENDING**
- 🚧 Simple window can be created — **PENDING**
- 🚧 Input handling functional — **PENDING**

#### Dependencies
- ✅ `.ry` file support — **COMPLETE**

#### Timeline
- ✅ **Week 13**: `.ry` file support (1-2 weeks) — **COMPLETE**
- 🚧 **Week 14**: Wayland protocol research (1 week) — **NEXT**
- 🚧 **Week 15-16**: Basic Wayland implementation (2-3 weeks) — **PENDING**
- 🚧 **Week 16**: Window system primitives (1-2 weeks) — **PENDING**

---

## Upcoming Phases

### Phase 6: Window Compositor (Weeks 17-20)
**Status**: 📋 **PLANNED**

#### Objectives
1. Write compositor from scratch (River-inspired, clean-room)
2. Window management
3. Tiling logic
4. Focus management
5. QEMU integration testing

#### Success Criteria
- ✅ Compositor written from scratch
- ✅ Basic tiling works
- ✅ Runs in QEMU on x86_64/aarch64
- ✅ New name chosen (avoid River reference)

#### Dependencies
- Phase 5 (Wayland protocol, window system)

#### Timeline
- **Week 17-18**: Compositor core (2 weeks)
- **Week 18-19**: Tiling logic (1 week)
- **Week 19-20**: QEMU testing (1 week)

---

### Phase 7: Skate GUI Integration (Weeks 21-24)
**Status**: 📋 **PLANNED**

#### Objectives
1. Adapt Skate for GUI mode
2. Window integration
3. Input handling integration
4. Grain OS system integration

#### Success Criteria
- ✅ Skate runs as GUI application
- ✅ Window management works
- ✅ Input handling works
- ✅ Integrated with Grain OS

#### Dependencies
- Phase 6 (Window compositor)

#### Timeline
- **Week 21-22**: Skate GUI adaptation (2 weeks)
- **Week 23**: System integration (1 week)
- **Week 24**: Testing and refinement (1 week)

---

### Phase 8: RISC-V Native (Weeks 25-28)
**Status**: 📋 **PLANNED**

#### Objectives
1. Port Wayland to RISC-V
2. Port compositor to RISC-V
3. Basin kernel integration
4. QEMU RISC-V64 testing

#### Success Criteria
- ✅ Wayland works on RISC-V
- ✅ Compositor works on RISC-V
- ✅ Runs on Basin kernel
- ✅ QEMU RISC-V64 testing passes

#### Dependencies
- Phase 7 (Skate GUI integration)
- Basin kernel readiness

#### Timeline
- **Week 25-26**: Wayland RISC-V port (2 weeks)
- **Week 26-27**: Compositor RISC-V port (2 weeks)
- **Week 27-28**: Basin kernel integration (1 week)
- **Week 28**: QEMU testing (1 week)

---

### Phase 9: In-House Components (Weeks 29-32)
**Status**: 📋 **PLANNED**

#### Objectives
1. Wayland in-house (Vantage implementation)
2. Compositor in-house (Vantage implementation)
3. Multi-architecture support (x86_64/aarch64/RISC-V64)
4. Production readiness

#### Success Criteria
- ✅ All components in-house
- ✅ Multi-architecture support
- ✅ Production ready
- ✅ Documentation complete

#### Dependencies
- Phase 8 (RISC-V native)

#### Timeline
- **Week 29-30**: Wayland in-house (2 weeks)
- **Week 30-31**: Compositor in-house (2 weeks)
- **Week 31-32**: Multi-architecture validation (1 week)
- **Week 32**: Production readiness (1 week)

---

## Long-Term Vision (6+ Months)

### Goals
1. **Self-Hosting**: Compile Rye compiler with itself
2. **Complete Rye Style**: All 5 checks (including recursion detection)
3. **Full GUI Stack**: Complete GUI application framework
4. **Production Deployment**: Grain OS with Skate GUI running natively

### Optional Enhancements
- Additional Rye Style checks
- Performance optimizations
- Extended stdlib
- Development tools

---

## Key Milestones

### ✅ Completed Milestones
- ✅ RISC-V64 freestanding support
- ✅ Rye Style enforcement (4/5 checks)
- ✅ Core 1 integration (19/19 modules)
- ✅ Validation testing

### ✅ Completed Milestones
- ✅ `.ry` file extension support — **COMPLETE**

### 🚧 Current Milestones
- 🚧 Wayland protocol research — **NEXT**
- 🚧 GUI/OS integration planning — **ONGOING**

### 📋 Upcoming Milestones
- 📋 Wayland protocol implementation
- 📋 Window compositor (from scratch)
- 📋 Skate GUI integration
- 📋 RISC-V native support

---

## Risk Management

### Identified Risks
1. **GPLv3 Licensing (River)**: Cannot use River code
   - **Mitigation**: Write compositor from scratch, clean-room implementation
   - **Status**: Understood, plan accounts for this

2. **Wayland Complexity**: Protocol is complex
   - **Mitigation**: Start with basic protocol, iterate
   - **Status**: Acceptable risk

3. **Timeline**: 20-24 weeks is significant
   - **Mitigation**: Phased approach, prioritize critical path
   - **Status**: Acceptable for long-term goals

4. **Multi-Architecture**: x86_64/aarch64 may need validation
   - **Mitigation**: Use QEMU for testing, validate early
   - **Status**: Baseline exists, needs validation

---

## Coordination

### With Core 1
- **Status**: ✅ 19/19 modules converted
- **Next**: Awaiting compiler validation (blocked by `.ry` support)
- **Coordination**: Regular status updates, shared planning documents

### With Other Subcores
- **Basin Kernel**: RISC-V64 support ready
- **Grain OS**: Planning GUI integration
- **Skate**: Modules converted, ready for GUI adaptation

---

## Success Metrics

### Technical Metrics
- ✅ RISC-V64 codegen: Working
- ✅ Rye Style checks: 4/5 active
- ✅ Test coverage: 11 comprehensive tests
- 🚧 `.ry` file support: Not started
- 🚧 Wayland protocol: Not started
- 🚧 Compositor: Not started

### Integration Metrics
- ✅ Skate modules: 19/19 converted
- ✅ Core 1 coordination: Complete
- 🚧 Full compilation: Blocked by `.ry` support
- 🚧 GUI integration: Planned

---

## Timeline Summary

### Completed (Weeks 1-12)
- ✅ Phase 1: Fork & Setup
- ✅ Phase 2: RISC-V Fixes
- ✅ Phase 3: Toroidal/Garden
- ✅ Phase 4: Rye Style Enforcement

### Current (Weeks 13-16)
- 🚧 Phase 5: GUI Foundation

### Planned (Weeks 17-32)
- 📋 Phase 6: Window Compositor
- 📋 Phase 7: Skate GUI Integration
- 📋 Phase 8: RISC-V Native
- 📋 Phase 9: In-House Components

**Total Estimated Time**: 32 weeks (8 months) from start

---

**Status**: 📋 **ACTIVE PLANNING** — Long-term plan maintained and updated regularly

---

**Date**: 2026-01-23-163538-pst  
**Agent**: Vantage 3 Subcore (Rye Compiler Fork Development)
