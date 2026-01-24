# Vantage 3: To-Do List

**Last Updated**: 2026-01-23-163538-pst  
**Status**: 📋 **ACTIVE**

---

## Immediate Priorities (Next 1-2 Weeks)

### 🔴 High Priority

#### 1. Add .ry File Extension Support
- **Status**: 🚧 Not Started
- **Priority**: Critical (blocks full Skate compilation)
- **Estimated Time**: 1-2 weeks
- **Dependencies**: None
- **Description**: Extend compiler to recognize `.ry` file extension
- **Why**: Enable direct compilation of Core 1's converted Skate modules
- **Files**: `src/Zcu.zig`, file extension handling code

#### 2. Wayland Protocol Research
- **Status**: 🚧 Not Started
- **Priority**: High (needed for GUI integration)
- **Estimated Time**: 1 week
- **Dependencies**: None
- **Description**: Study Wayland protocol specification, plan Rye implementation
- **Why**: Foundation for GUI/OS integration plan
- **Resources**: Wayland protocol spec (MIT licensed)

#### 3. Update Long-Term Plan Documents
- **Status**: 🚧 In Progress
- **Priority**: High (coordination)
- **Estimated Time**: 1 day
- **Dependencies**: GUI/OS integration plan
- **Description**: Update long-term plan with new objectives
- **Why**: Keep planning documents synchronized

---

## Short-Term Tasks (Next 2-4 Weeks)

### 🟡 Medium Priority

#### 4. Wayland Protocol Implementation (Basic)
- **Status**: 🚧 Not Started
- **Priority**: Medium
- **Estimated Time**: 2-3 weeks
- **Dependencies**: Wayland protocol research, .ry file support
- **Description**: Implement basic Wayland protocol in Rye
- **Why**: Required for GUI/OS integration

#### 5. Basic Window System Primitives
- **Status**: 🚧 Not Started
- **Priority**: Medium
- **Estimated Time**: 1-2 weeks
- **Dependencies**: Wayland protocol implementation
- **Description**: Create window management primitives
- **Why**: Foundation for compositor

#### 6. Input Handling Library
- **Status**: 🚧 Not Started
- **Priority**: Medium
- **Estimated Time**: 1-2 weeks
- **Dependencies**: Wayland protocol implementation
- **Description**: Keyboard, mouse, touch input handling
- **Why**: Required for GUI applications

---

## Medium-Term Tasks (Next 1-3 Months)

### 🟢 Lower Priority

#### 7. Window Compositor (From Scratch)
- **Status**: 🚧 Not Started
- **Priority**: Medium
- **Estimated Time**: 4 weeks
- **Dependencies**: Basic window system, input handling
- **Description**: Write compositor from scratch (River-inspired, clean-room)
- **Why**: Required for Skate GUI on Grain OS
- **Note**: Cannot use River code (GPLv3), must write from scratch

#### 8. Compositor Naming
- **Status**: 🚧 Not Started
- **Priority**: Low
- **Estimated Time**: 1 day
- **Dependencies**: Compositor design
- **Description**: Choose new name for compositor (avoid River reference)
- **Why**: Need distinct identity, avoid GPLv3 attribution issues

#### 9. QEMU Integration Utilities
- **Status**: 🚧 Not Started
- **Priority**: Low
- **Estimated Time**: 1-2 weeks
- **Dependencies**: None
- **Description**: Create QEMU integration helpers for testing
- **Why**: Enable testing on x86_64/aarch64 via QEMU

#### 10. Multi-Architecture Validation
- **Status**: 🚧 Not Started
- **Priority**: Medium
- **Estimated Time**: 1-2 weeks
- **Dependencies**: .ry file support
- **Description**: Validate x86_64 and aarch64 support
- **Why**: Required for GUI/OS integration plan

---

## Long-Term Tasks (3-6 Months)

### 🔵 Future Work

#### 11. Skate GUI Adaptation
- **Status**: 🚧 Not Started
- **Priority**: Medium
- **Estimated Time**: 4 weeks
- **Dependencies**: Window compositor, input handling
- **Description**: Adapt Skate for GUI mode on Grain OS
- **Why**: Primary goal - run Skate as GUI application

#### 12. Wayland for RISC-V
- **Status**: 🚧 Not Started
- **Priority**: Medium
- **Estimated Time**: 2-3 weeks
- **Dependencies**: Wayland protocol implementation
- **Description**: Port Wayland to RISC-V, optimize for Basin kernel
- **Why**: Native RISC-V support for Grain OS

#### 13. Compositor for RISC-V
- **Status**: 🚧 Not Started
- **Priority**: Medium
- **Estimated Time**: 2-3 weeks
- **Dependencies**: Compositor implementation, Wayland for RISC-V
- **Description**: Port compositor to RISC-V, Basin kernel integration
- **Why**: Native RISC-V support

#### 14. Recursion Detection (Optional)
- **Status**: 🚧 Not Started
- **Priority**: Low (optional)
- **Estimated Time**: 2-3 weeks
- **Dependencies**: None
- **Description**: Implement recursion detection for Rye Style
- **Why**: Complete Phase 4 (5/5 checks)

---

## Completed Tasks ✅

### Phase 2: RISC-V Freestanding
- ✅ Global variable addressing fix
- ✅ Conditional branch codegen optimization
- ✅ Frame layout fix for large frames
- ✅ Kernel integration testing

### Phase 3: Toroidal/Garden Types
- ✅ Bounded data structures
- ✅ Memory allocation model
- ✅ Basic stdlib modules

### Phase 4: Rye Style Enforcement
- ✅ Function length check (64 lines)
- ✅ Line length check (128 chars)
- ✅ Why comment check (public functions)
- ✅ Explicit type check (no usize/isize)
- ✅ 11 comprehensive test cases

### Integration
- ✅ Core 1 coordination (19/19 modules converted)
- ✅ Validation testing (test cases)
- ✅ Documentation (validation reports, integration plans)

---

## Blocked Tasks

### Currently Blocked
- **Full Skate Codebase Compilation**: Blocked by `.ry` file support
- **Wayland Implementation**: Blocked by `.ry` file support (for Rye code)
- **Compositor Development**: Blocked by Wayland protocol

### Dependencies
- Most GUI/OS tasks depend on `.ry` file support
- Compositor depends on Wayland protocol
- Skate GUI depends on compositor

---

## Notes

### Current Focus
- **Primary**: Add `.ry` file extension support
- **Secondary**: Wayland protocol research
- **Tertiary**: Update planning documents

### Coordination
- Core 1: 19/19 modules complete, awaiting compiler validation
- Vantage 3: Ready for next phase (GUI/OS integration)
- Integration: Blocked by `.ry` file support

### Timeline
- **Immediate**: 1-2 weeks (`.ry` support, research)
- **Short-term**: 2-4 weeks (Wayland basic, window system)
- **Medium-term**: 1-3 months (compositor, GUI integration)
- **Long-term**: 3-6 months (RISC-V native, in-house components)

---

**Status**: 📋 **ACTIVE** — To-do list maintained and updated regularly
