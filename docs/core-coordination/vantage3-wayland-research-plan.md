# Vantage 3: Wayland Protocol Research Plan

**Date**: 2026-01-23-163941-pst  
**Status**: 🚧 **READY TO BEGIN**

---

## Overview

Research plan for implementing Wayland protocol support in Rye. Wayland is MIT licensed and can be used/adapted. This research will inform the implementation strategy for Phase 5 GUI Foundation work.

---

## Research Objectives

### Primary Goals
1. **Evaluate Wayland Protocol Against Rye Style**
   - **CRITICAL**: Assess Rye Style compliance (like Tend garden allocator decision)
   - Bounded operations analysis
   - Memory safety evaluation
   - Type safety assessment
   - Complexity analysis
   - **Decision**: Adapt Wayland or innovate new protocol?

2. **Understand Wayland Protocol Architecture** (if adapting)
   - Protocol specification structure
   - Client-server communication model
   - Protocol wire format
   - Message passing mechanism

3. **Design Rye-Native Protocol** (if innovating)
   - Bounded operations by design
   - Type-safe protocol
   - Memory-safe implementation
   - Simple, clear APIs
   - Rye Style compliant from ground up

4. **Plan Implementation Strategy**
   - Protocol code generation approach (if adapting)
   - Rye-native protocol design (if innovating)
   - Rye-specific implementation patterns
   - Integration with Rye Style constraints
   - Memory management (Garden/Toroidal)

5. **Document Findings**
   - Rye Style compliance evaluation
   - Decision rationale (adapt vs innovate)
   - Implementation approach
   - Required libraries/components
   - Timeline estimates

---

## Research Areas

### 1. Wayland Protocol Rye Style Evaluation ⚠️ **CRITICAL**
**Priority**: **CRITICAL** (Highest)  
**Time**: 3-4 days

**Topics**:
- **Bounded Operations Analysis**
  - Message size limits?
  - Object count limits?
  - Buffer size limits?
  - Event queue limits?
- **Memory Safety Evaluation**
  - Object ID validation?
  - Buffer overflow protection?
  - Use-after-free prevention?
  - Error handling completeness?
- **Type Safety Assessment**
  - Explicit types throughout?
  - No usize/isize usage?
  - Strong typing?
- **Complexity Analysis**
  - Protocol complexity?
  - Implementation complexity?
  - Can it be simplified?
- **Recursion Check**
  - Does implementation use recursion?
  - Can it be made iterative?
- **Function Length Assessment**
  - Can implementation meet 64-line limit?
  - What refactoring would be needed?

**Resources**:
- **Wayland 1.24.0 Release** (latest stable)
- Wayland protocol specification (official)
- Protocol XML files (from 1.24.0 release)
- Existing implementations (libwayland)
- Rye Style compliance framework
- **Reference**: Tend garden allocator decision process

**Deliverable**: **Rye Style compliance evaluation and decision** (adapt Wayland or innovate new protocol)

---

### 2. Existing Wayland Implementations
**Priority**: High  
**Time**: 2-3 days

**Topics**:
- Reference implementations (libwayland)
- Protocol code generation tools
- Client library patterns
- Compositor implementation patterns
- RISC-V compatibility considerations

**Resources**:
- libwayland source code (MIT licensed)
- Wayland compositor examples
- Client library examples
- Existing Zig Wayland bindings (if any)

**Deliverable**: Implementation pattern analysis

---

### 3. Rye Integration Requirements
**Priority**: Medium  
**Time**: 1-2 days

**Topics**:
- Rye Style compliance (64-line functions, etc.)
- Garden/Toroidal memory management
- RISC-V64 freestanding considerations
- Basin kernel integration
- Multi-architecture support (x86_64, aarch64, RISC-V64)

**Resources**:
- Rye Style constraints
- Garden/Toroidal documentation
- Basin kernel requirements

**Deliverable**: Rye-specific implementation strategy

---

### 4. Protocol Code Generation
**Priority**: Medium  
**Time**: 1-2 days

**Topics**:
- Wayland scanner/protocol generator
- Code generation from XML
- Rye code generation approach
- Type-safe protocol bindings

**Resources**:
- wayland-scanner tool
- Protocol XML files
- Code generation patterns

**Deliverable**: Code generation strategy

---

## Research Timeline

### Week 1 (Days 1-3)
- **Day 1-2**: Wayland protocol specification study
- **Day 3**: Protocol architecture documentation

### Week 1 (Days 4-5)
- **Day 4**: Existing implementation analysis
- **Day 5**: Rye integration requirements

### Week 1 (Days 6-7)
- **Day 6**: Protocol code generation research
- **Day 7**: Research summary and implementation plan

**Total Estimated Time**: 1 week

---

## Key Questions to Answer

### ⚠️ CRITICAL: Rye Style Compliance
1. **Can Wayland be made Rye Style compliant?**
   - Are operations bounded?
   - Is memory safety guaranteed?
   - Can functions be kept ≤ 64 lines?
   - Is recursion avoidable?
   - **Decision**: Adapt Wayland or innovate new protocol?

2. **What are the trade-offs?**
   - Compatibility vs Rye Style compliance
   - Adaptation effort vs innovation effort
   - Safety vs performance
   - Complexity vs simplicity

3. **What would a Rye-native protocol look like?**
   - Bounded operations by design
   - Type-safe throughout
   - Memory-safe with Garden/Toroidal
   - Simple, clear APIs
   - Rye Style compliant from ground up

### Implementation Questions (if adapting)
4. **Protocol Architecture**
   - How does Wayland protocol work?
   - What are the core interfaces?
   - How are messages serialized?

5. **Implementation Approach**
   - Generate code from XML or write manually?
   - Use existing library or implement from scratch?
   - How to handle protocol versioning?

6. **Rye Integration**
   - How to make it Rye Style compliant?
   - How to use Garden/Toroidal for memory?
   - How to support RISC-V64 freestanding?

7. **Compositor Requirements**
   - What interfaces are needed for compositor?
   - What interfaces are needed for clients?
   - What extensions are required?

---

## Deliverables

### Research Documents
1. **Wayland Protocol Architecture Summary**
   - Protocol overview
   - Core concepts
   - Message flow

2. **Implementation Strategy Document**
   - Approach (code generation vs manual)
   - Rye-specific considerations
   - Integration plan

3. **Required Components List**
   - Core protocol interfaces
   - Extension protocols needed
   - Dependencies

4. **Timeline and Estimates**
   - Implementation phases
   - Time estimates
   - Dependencies

---

## Resources

### Official Documentation
- **Wayland 1.24.0 Release** (Latest): https://gitlab.freedesktop.org/wayland/wayland/-/releases/1.24.0
- **Release Announcement**: https://lore.freedesktop.org/wayland-devel/plU5smxin5VXbiedTGtL7CNHe0t2mHtgQlQ3-xwREmSSNYaClAcZpEBV8L7JvMT8JHwdD_a_uSFkDUaP45CAWyL545iZh5gInAdToX6hgt4=@emersion.fr/T/#u
- **Download**: https://gitlab.freedesktop.org/wayland/wayland/-/releases/1.24.0/downloads/wayland-1.24.0.tar.xz
- Wayland protocol specification
- Wayland protocol XML files
- Wayland documentation

### Reference Implementations
- libwayland (MIT licensed, can reference)
- Wayland compositors (reference only)
- Client libraries (reference only)
- Existing Zig Wayland code: `/home/xy/codeberg/kae3g/zig-wayland/`
- **Existing Grain Core Wayland**: `/home/xy/grain-sketchbook/src/grain_core/wayland/protocol.zig` (183 lines)
  - ✅ Already Rye Style compliant (grain_case, u32/u64, bounded allocations)
  - ✅ Core structures: Object, Surface, Output, Seat, Registry
  - ✅ Can be extended and adapted for Rye compiler integration

### Tools
- wayland-scanner (protocol code generator)
- Protocol XML files
- **Wayland 1.24.0 Source**: Can download for reference (MIT licensed)

---

## Success Criteria

### Research Complete When
- ✅ Protocol architecture understood
- ✅ Implementation approach decided
- ✅ Rye integration strategy defined
- ✅ Required components identified
- ✅ Timeline and estimates documented
- ✅ Implementation plan created

---

## Next Steps After Research

1. **Begin Implementation**
   - Start with basic protocol support
   - Implement core interfaces
   - Test with simple client

2. **Iterate**
   - Add required interfaces
   - Test with compositor
   - Optimize for Rye Style

3. **Integration**
   - Integrate with window system
   - Test with Skate GUI
   - Basin kernel integration

---

**Status**: 🚧 **READY TO BEGIN** — Research plan created, ready to start Week 14 work

---

**Date**: 2026-01-23-163941-pst  
**Agent**: Vantage 3 Subcore (Rye Compiler Fork Development)
