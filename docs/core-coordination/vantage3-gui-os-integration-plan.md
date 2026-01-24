# Vantage 3: GUI/OS Integration Plan

**Date**: 2026-01-23-163138-pst  
**Status**: 📋 **PLANNING PHASE**

---

## Overview

Plan for integrating Skate as a GUI application for Grain OS, written in Rye. This includes adapting window compositor functionality (inspired by River, but written from scratch due to GPLv3 licensing), Wayland protocol support, and QEMU VM integration for testing.

---

## Objectives

### Primary Goals
1. **Skate GUI Application**: Run Skate as GUI application on Grain OS
2. **Window Compositor**: Create Rye-based window compositor (River-inspired, from scratch)
3. **Wayland Support**: Integrate Wayland protocol (MIT licensed, can use)
4. **QEMU Integration**: Use QEMU as control case target for testing
5. **Multi-Architecture**: Support x86_64, aarch64, and RISC-V64

### Long-Term Goals
1. **In-House Components**: Bring Wayland, compositor, and QEMU in-house via Vantage
2. **RISC-V Native**: Wayland and compositor for Grain OS/Basin/RISC-V
3. **New Names**: Create new names for in-house modules (avoid River attribution)

---

## Licensing Constraints

### ✅ Wayland (MIT License)
- **Status**: Can use and adapt
- **Action**: Can integrate Wayland protocol implementation
- **Attribution**: Must include MIT license notice
- **Forking**: Allowed

### ❌ River (GPLv3 License)
- **Status**: Cannot fork or adapt source code
- **Action**: Must write compositor from scratch
- **Attribution**: Cannot mention River in repository
- **Inspiration**: Can use River as reference (clean-room implementation)
- **Note**: GPLv3 incompatible with project goals

### ✅ QEMU (GPLv2 License)
- **Status**: Can use for testing/development
- **Action**: Can integrate QEMU for VM testing
- **Attribution**: Must include GPLv2 license notice
- **Forking**: Allowed (but consider in-house rewrite for RISC-V)

---

## Current Rye Capabilities Assessment

### ✅ Completed Capabilities

#### Phase 2: RISC-V Freestanding
- ✅ RISC-V64 codegen working
- ✅ Freestanding compilation support
- ✅ Basin kernel compatibility

#### Phase 3: Toroidal/Garden Types
- ✅ Bounded data structures
- ✅ Memory allocation model
- ✅ Basic stdlib available

#### Phase 4: Rye Style Enforcement
- ✅ Function length check (64 lines)
- ✅ Line length check (128 chars)
- ✅ Why comment check (public functions)
- ✅ Explicit type check (no usize/isize)

### 🚧 Partial Capabilities

#### Architecture Support
- ✅ RISC-V64: Full support
- 🚧 x86_64: Supported (Zig baseline)
- 🚧 aarch64: Supported (Zig baseline)
- **Status**: Multi-architecture support exists but needs validation

#### Standard Library
- ✅ Basic modules (mem, fmt, io)
- 🚧 GUI libraries: Not yet available
- 🚧 Wayland bindings: Not yet available
- 🚧 Window management: Not yet available

### ❌ Missing Capabilities

#### GUI/Window System
- ❌ Wayland protocol implementation
- ❌ Window compositor (must write from scratch)
- ❌ GUI toolkit/library
- ❌ Input handling (keyboard, mouse, touch)

#### System Integration
- ❌ QEMU integration helpers
- ❌ VM management utilities
- ❌ Device driver framework
- ❌ Graphics stack integration

#### Development Tools
- ❌ `.ry` file extension support (blocks full compilation)
- ❌ GUI application build system
- ❌ Window system testing framework

---

## Gap Analysis

### What We Have
1. ✅ RISC-V64 compiler support
2. ✅ Rye Style enforcement
3. ✅ Basic stdlib
4. ✅ Skate modules converted (19/19)
5. ✅ Multi-architecture baseline

### What We Need
1. ❌ Wayland protocol implementation in Rye
2. ❌ Window compositor (from scratch, River-inspired)
3. ❌ GUI application framework
4. ❌ QEMU integration for testing
5. ❌ `.ry` file support in compiler
6. ❌ Graphics/input libraries
7. ❌ Multi-architecture validation

---

## Roadmap

### Phase 5: GUI Foundation (Weeks 13-16)
**Goal**: Establish foundation for GUI applications

1. **Add `.ry` File Support**
   - Extend compiler to recognize `.ry` extension
   - Enable full Skate codebase compilation
   - Priority: High

2. **Wayland Protocol Implementation**
   - Implement Wayland protocol in Rye
   - Create Wayland bindings/library
   - MIT license compliance
   - Priority: High

3. **Basic Window System**
   - Create window management primitives
   - Input handling (keyboard, mouse)
   - Basic compositor framework
   - Priority: High

### Phase 6: Window Compositor (Weeks 17-20)
**Goal**: Create window compositor from scratch

1. **Compositor Core**
   - Write compositor from scratch (River-inspired, clean-room)
   - Window management
   - Tiling logic
   - Focus management
   - Priority: High

2. **Naming**
   - Choose new name for compositor (avoid River reference)
   - Document in third-party licenses (Wayland only)
   - Priority: Medium

3. **Integration Testing**
   - Test with QEMU
   - Validate on x86_64, aarch64
   - Priority: High

### Phase 7: Skate GUI Integration (Weeks 21-24)
**Goal**: Run Skate as GUI application

1. **Skate GUI Adaptation**
   - Adapt Skate for GUI mode
   - Window integration
   - Input handling
   - Priority: High

2. **Grain OS Integration**
   - Integrate with Grain OS
   - System service integration
   - Priority: Medium

### Phase 8: RISC-V Native (Weeks 25-28)
**Goal**: Native RISC-V support

1. **Wayland for RISC-V**
   - Port Wayland implementation to RISC-V
   - Optimize for Basin kernel
   - Priority: High

2. **Compositor for RISC-V**
   - Port compositor to RISC-V
   - Basin kernel integration
   - Priority: High

3. **QEMU RISC-V Testing**
   - QEMU RISC-V64 VM support
   - Integration testing
   - Priority: Medium

### Phase 9: In-House Components (Weeks 29-32)
**Goal**: Bring components in-house

1. **Wayland In-House**
   - Vantage implementation in Rye
   - x86_64/aarch64 support
   - Priority: Medium

2. **Compositor In-House**
   - Vantage implementation
   - Multi-architecture
   - Priority: Medium

3. **QEMU Alternative (Optional)**
   - Consider in-house VM for RISC-V
   - Or continue using QEMU (GPLv2 acceptable)
   - Priority: Low

---

## Technical Requirements

### Compiler Requirements
- ✅ RISC-V64 support (complete)
- ✅ x86_64 support (baseline exists)
- ✅ aarch64 support (baseline exists)
- ❌ `.ry` file extension support (needed)
- ❌ GUI application linking (needed)

### Library Requirements
- ❌ Wayland protocol library
- ❌ Window management library
- ❌ Input handling library
- ❌ Graphics rendering library
- ❌ Event loop library

### System Requirements
- ❌ QEMU integration utilities
- ❌ VM management tools
- ❌ Device driver framework
- ❌ Graphics stack

---

## Estimated Timeline

### Immediate (Weeks 13-16)
- Add `.ry` file support: 1-2 weeks
- Wayland protocol implementation: 2-3 weeks
- Basic window system: 1-2 weeks

### Short-Term (Weeks 17-24)
- Window compositor: 4 weeks
- Skate GUI integration: 4 weeks

### Medium-Term (Weeks 25-32)
- RISC-V native support: 4 weeks
- In-house components: 4 weeks

**Total Estimated Time**: 20-24 weeks (5-6 months)

---

## Dependencies

### External Dependencies
- ✅ Wayland protocol spec (MIT licensed)
- ✅ QEMU (GPLv2, for testing)
- ❌ River (GPLv3, cannot use - reference only)

### Internal Dependencies
- ✅ RISC-V compiler support
- ✅ Rye Style enforcement
- ✅ Skate modules (19/19 converted)
- ❌ `.ry` file support
- ❌ GUI libraries

---

## Risks and Mitigations

### Risk 1: GPLv3 Licensing (River)
- **Risk**: Cannot use River code
- **Mitigation**: Write compositor from scratch, use River as reference only
- **Status**: Understood, plan accounts for this

### Risk 2: Wayland Complexity
- **Risk**: Wayland protocol is complex
- **Mitigation**: Start with basic protocol, iterate
- **Status**: Acceptable risk

### Risk 3: Multi-Architecture Support
- **Risk**: x86_64/aarch64 may need validation
- **Mitigation**: Use QEMU for testing, validate early
- **Status**: Baseline exists, needs validation

### Risk 4: Timeline
- **Risk**: 20-24 weeks is significant
- **Mitigation**: Phased approach, prioritize critical path
- **Status**: Acceptable for long-term goals

---

## Success Criteria

### Phase 5 Success
- ✅ `.ry` file support added
- ✅ Basic Wayland protocol working
- ✅ Simple window can be created

### Phase 6 Success
- ✅ Compositor written from scratch
- ✅ Basic tiling works
- ✅ Runs in QEMU on x86_64/aarch64

### Phase 7 Success
- ✅ Skate runs as GUI application
- ✅ Window management works
- ✅ Input handling works

### Phase 8 Success
- ✅ Wayland works on RISC-V
- ✅ Compositor works on RISC-V
- ✅ Runs on Basin kernel

### Phase 9 Success
- ✅ All components in-house
- ✅ Multi-architecture support
- ✅ Production ready

---

## Next Steps

### Immediate Actions
1. **Add `.ry` File Support** (Priority: High)
   - Extend compiler file extension handling
   - Enable full Skate compilation
   - Estimated: 1-2 weeks

2. **Wayland Protocol Research** (Priority: High)
   - Study Wayland protocol specification
   - Plan Rye implementation
   - Estimated: 1 week

3. **Compositor Design** (Priority: Medium)
   - Design compositor architecture
   - Choose new name
   - Estimated: 1 week

### Coordination with Core 1
- Share this plan for review
- Coordinate on Skate GUI adaptation
- Plan integration timeline

---

## Questions for Discussion

1. **Compositor Name**: What should we name the new compositor?
2. **Timeline**: Is 20-24 weeks acceptable?
3. **Priorities**: Which phases should be prioritized?
4. **Resources**: What resources are available?
5. **Testing**: QEMU setup and testing approach?

---

**Status**: 📋 **PLANNING PHASE** — Document created, ready for review and coordination

---

**Date**: 2026-01-23-163138-pst  
**Agent**: Vantage 3 Subcore (Rye Compiler Fork Development)
