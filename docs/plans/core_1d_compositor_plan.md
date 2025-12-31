# Grain Compositor Agent (1d) Implementation Plan

**Date**: 2025-12-30  
**Agent**: Grain Compositor Agent (1d)  
**Parent Agent**: Grain Core 1 Subcore Agent (L1 Subcore)  
**Status**: Initial Plan

---

## Overview

The Grain Compositor Agent is responsible for window management and compositing for the Grain OS ecosystem. This includes window lifecycle, compositing pipeline, input handling, workspace management, and desktop environment components.

---

## Architecture

### Core Components

1. **Compositor Core** (`compositor.zig`)
   - Main compositor state and event loop
   - Window registry and management
   - Wayland protocol implementation

2. **Window Management** (`window_*.zig` modules)
   - Window creation, destruction, lifecycle
   - Window positioning, sizing, constraints
   - Window focus, stacking, grouping
   - Window animations, effects, decorations
   - Window rules and policies

3. **Compositing Pipeline** (`framebuffer_renderer.zig`)
   - Framebuffer rendering
   - Window compositing
   - Visual effects (opacity, shadows, blur)
   - Multi-monitor support

4. **Input Handling** (`input_handler.zig`)
   - Keyboard input routing
   - Mouse/touch input routing
   - Input focus management
   - Keyboard shortcuts

5. **Workspace Management** (`workspace.zig`)
   - Workspace creation and switching
   - Workspace layout management
   - Workspace window organization
   - Workspace state persistence (coordinate with Storage Agent)

6. **Desktop Environment**
   - Desktop shell (`desktop_shell.zig`)
   - Display management (`display_management.zig`)
   - Notification system (`notification.zig`)
   - Lock screen (`lock_screen.zig`)
   - Theme management (`theme_manager.zig`)
   - Settings management (`settings_manager.zig`)

---

## Implementation Phases

### Phase 1: Assessment & Foundation (Current)

**Goal**: Understand existing codebase and establish foundation

**Tasks**:
1. Review existing compositor code
2. Assess Grain Style compliance
3. Identify gaps and incomplete features
4. Create coordination documents
5. Establish development workflow

**Deliverables**:
- Coordination document
- Implementation plan (this document)
- Tasks document
- Code assessment report

**Status**: In Progress

---

### Phase 2: Code Review & Grain Style Compliance

**Goal**: Ensure all existing code follows Grain Style

**Tasks**:
1. Review all compositor modules for Grain Style compliance
2. Fix function naming (`grain_case`)
3. Replace `usize`/`isize` with explicit `u32`/`u64`
4. Ensure all functions have minimum 2 assertions
5. Verify bounded allocations with `MAX_` constants
6. Check function length (max 70 lines)
7. Check line length (max 100 characters)
8. Remove any recursion, convert to iterative
9. Enable all compiler warnings

**Deliverables**:
- Grain Style compliant compositor code
- Updated tests

**Dependencies**: None

---

### Phase 3: Core Window Management

**Goal**: Complete and polish core window management features

**Tasks**:
1. Window creation and destruction
2. Window positioning and sizing
3. Window focus management
4. Window stacking and z-order
5. Window constraints and snapping
6. Window lifecycle events

**Deliverables**:
- Complete window management API
- Comprehensive tests
- Documentation

**Dependencies**: Phase 2

---

### Phase 4: Compositing Pipeline

**Goal**: Complete compositing and rendering pipeline

**Tasks**:
1. Framebuffer rendering
2. Window compositing pipeline
3. Display management
4. Multi-monitor support
5. Visual effects (opacity, shadows, blur)
6. Window preview and thumbnails

**Deliverables**:
- Complete compositing pipeline
- Multi-monitor support
- Visual effects system
- Tests

**Dependencies**: Phase 3

---

### Phase 5: Advanced Window Features

**Goal**: Implement advanced window management features

**Tasks**:
1. Window grouping and tiling
2. Window animations and transitions
3. Window drag and drop
4. Window rules and policies
5. Window decorations and effects

**Deliverables**:
- Advanced window features
- Tiling system
- Animation system
- Rules engine
- Tests

**Dependencies**: Phase 4

---

### Phase 6: Input Handling

**Goal**: Complete input handling system

**Tasks**:
1. Keyboard input routing
2. Mouse/touch input routing
3. Input focus management
4. Keyboard shortcuts
5. Input event distribution

**Deliverables**:
- Complete input handling system
- Keyboard shortcut system
- Tests

**Dependencies**: Phase 3

---

### Phase 7: Workspace Management

**Goal**: Complete workspace management with persistence

**Tasks**:
1. Workspace creation and switching
2. Workspace layout management
3. Workspace window organization
4. Workspace state persistence (coordinate with Storage Agent 1c)
5. Workspace restoration on startup

**Deliverables**:
- Complete workspace system
- State persistence integration
- Tests

**Dependencies**: Phase 3, Storage Agent coordination

---

### Phase 8: Desktop Environment

**Goal**: Complete desktop environment components

**Tasks**:
1. Desktop shell (launcher, dock, panels)
2. Notification system
3. Lock screen
4. Theme management
5. Settings management
6. Runtime configuration

**Deliverables**:
- Complete desktop environment
- Theme system
- Settings system
- Tests

**Dependencies**: Phase 4, Phase 6

---

## Architecture Decisions

### Pending Decisions

1. **Workspace State Format**: Need to coordinate with Storage Agent (1c) on data format
2. **Multi-monitor Architecture**: Review existing implementation
3. **Animation System**: Performance requirements and implementation approach
4. **Input Event Distribution**: Event routing architecture

### Made Decisions

1. **Wayland Protocol**: Using Wayland protocol for compositor-client communication
2. **Framebuffer Rendering**: Kernel framebuffer for rendering
3. **Bounded Allocations**: All data structures have `MAX_` constants
4. **Grain Style**: Strict adherence to Grain Style guide

---

## Integration Points

### With Storage Agent (1c)

**Purpose**: Workspace state persistence

**API Needed**:
- Save workspace configuration
- Load workspace configuration
- Window positions and sizes
- Workspace organization

**Status**: To be coordinated through Core 1 Subcore

### With Network Agent (1b)

**Purpose**: Remote desktop support (future)

**Status**: Future consideration, architecture should support this

---

## Testing Strategy

1. **Unit Tests**: Each module has comprehensive unit tests
2. **Integration Tests**: Test compositor subsystems together
3. **End-to-End Tests**: Test full compositor functionality
4. **Performance Tests**: Ensure compositor meets performance requirements

**Test Organization**:
- `tests/*_compositor_*_test.zig`
- `tests/*_window_*_test.zig`
- `tests/*_desktop_*_test.zig`

---

## Success Criteria

1. All code follows Grain Style strictly
2. All features are complete (no TODOs or stubs)
3. Comprehensive test coverage
4. All compiler warnings resolved
5. Performance meets requirements
6. Integration with Storage Agent for workspace persistence
7. Multi-monitor support working
8. Desktop environment fully functional

---

**Last Updated**: 2025-12-30  
**Next Review**: After Phase 1 completion
