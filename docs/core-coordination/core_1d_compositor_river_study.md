# River Compositor Architecture Study

**Date**: 2025-12-30  
**Agent**: Grain Compositor Agent (1d)  
**Purpose**: Document River-inspired architecture patterns and implementation differences

---

## ⚠️ License Compliance

**Critical**: River Compositor is GPL-3.0 licensed. This document describes architectural patterns studied from River, with all implementation done independently in clean-room fashion.

**River Protocols**: The `protocol/` directory contains ISC-licensed protocols that can be referenced:
- `river-layout-v3.xml` (ISC license)
- `river-control-unstable-v1.xml` (ISC license)
- `river-status-unstable-v1.xml` (ISC license)

---

## Key River Architectural Patterns

### 1. Layout Generator Separation

**River's Approach**:
- Layout generators run as **separate processes**
- Communication via custom Wayland protocol (`river-layout-v3.xml`)
- Compositor sends layout demands to generator
- Generator responds with view positions/dimensions
- Enables hot-reload, multi-language support

**Our Approach**:
- Layout generators are **in-process function pointers**
- Simpler, more efficient for initial implementation
- Policy vs. implementation separation maintained
- All code in Zig, follows Grain Style

**Trade-offs**:
- **River's**: More flexible (can write generators in any language), hot-reloadable
- **Ours**: Simpler, more efficient, zero-process overhead, easier to maintain

**Future Enhancement**: Could adopt River's protocol approach if separate-process generators become desirable.

### 2. Runtime Configuration (riverctl)

**River's Approach**:
- `riverctl` command-line tool for runtime configuration
- Uses `river-control-unstable-v1.xml` protocol (ISC licensed)
- Commands built with `add_argument` requests, executed with `run_command`
- Success/failure callbacks

**Our Approach**:
- IPC-based configuration (`runtime_config.zig`)
- Command parsing and execution in-process
- Similar functionality, different implementation

**Status**: ✅ Implemented (riverctl-inspired)

### 3. Window Organization

**River's Approach**:
- Uses **tags** (multi-tag system)
- Window can have multiple tags
- Multiple tags can be displayed on monitor
- More flexible organization

**Our Approach**:
- Uses **workspaces** (1 window per workspace concept)
- Simpler model, easier to understand
- Workspace switching (River-style)
- Window assignment to workspaces

**Note**: Both approaches are valid. Tags are more flexible; workspaces are simpler.

### 4. Rendering Backend

**River's Approach**:
- Uses **wlroots** (C library, MIT licensed)
- Industry-standard Wayland compositor library
- Hardware acceleration, multi-monitor support

**Our Approach**:
- Uses **kernel framebuffer** (pure Zig)
- Zero dependencies, RISC-V native
- Direct syscall-based rendering
- Simpler for our use case

**Trade-offs**:
- **River's**: More features, hardware acceleration, industry-standard
- **Ours**: Zero dependencies, pure Zig, RISC-V optimized

---

## River Protocols (ISC Licensed - Can Reference)

### river-layout-v3.xml

**Purpose**: Protocol for separate-process layout generators

**Key Concepts**:
- `river_layout_manager_v3`: Factory for layout objects
- `river_layout_v3`: Layout demand/response interface
- `layout_demand` event: Compositor requests layout
- `push_view_dimensions` request: Generator proposes view positions
- `commit` request: Generator completes layout

**Our Status**: Not implemented (using in-process generators)

**Future Option**: Could adopt this protocol for separate-process generators if needed.

### river-control-unstable-v1.xml

**Purpose**: Runtime configuration interface

**Key Concepts**:
- `zriver_control_v1`: Control interface
- `add_argument` request: Build command arguments
- `run_command` request: Execute command
- `zriver_command_callback_v1`: Success/failure callback

**Our Status**: ✅ Implemented (similar functionality in `runtime_config.zig`)

### river-status-unstable-v1.xml

**Purpose**: Status bar integration

**Our Status**: ⏳ Not yet implemented (desktop shell in progress)

---

## Implementation Comparison

| Feature | River | Grain Compositor | Status |
|---------|-------|------------------|--------|
| Layout Generators | Separate processes (protocol) | In-process (function pointers) | ✅ Implemented (different approach) |
| Runtime Config | riverctl + protocol | IPC commands | ✅ Implemented |
| Window Organization | Tags (multi-tag) | Workspaces | ✅ Implemented (different model) |
| Rendering | wlroots (C) | Kernel framebuffer (Zig) | ✅ Implemented (different backend) |
| Tiling Layouts | Separate processes | In-process algorithms | ✅ Implemented |
| Input Handling | wlroots | Kernel input | ✅ Implemented |
| Focus Management | wlroots | Custom implementation | ✅ Implemented |

---

## Architectural Decisions

### Why In-Process Layout Generators?

**Advantages**:
1. **Simplicity**: No process management, no IPC overhead
2. **Performance**: Direct function calls, no serialization
3. **Grain Style**: All code in Zig, follows style guide
4. **Zero Dependencies**: No external processes to manage
5. **Easier Testing**: Unit test function pointers directly

**Disadvantages**:
1. **Less Flexible**: Can't write generators in other languages
2. **No Hot Reload**: Must restart compositor to change layouts
3. **Less Modular**: Generators are part of compositor binary

**Decision**: Start with in-process generators for simplicity. Can adopt River's protocol approach later if needed.

### Why Workspaces Instead of Tags?

**Advantages**:
1. **Simplicity**: Easier to understand (1 workspace = set of windows)
2. **Clear State**: Each workspace has clear window membership
3. **Workspace Switching**: Clear visual feedback
4. **Easier Implementation**: Simpler data structures

**Disadvantages**:
1. **Less Flexible**: Can't assign window to multiple workspaces
2. **Fewer Features**: Can't display multiple workspaces simultaneously

**Decision**: Workspaces are simpler for initial implementation. Tags could be added later if needed.

### Why Kernel Framebuffer Instead of wlroots?

**Advantages**:
1. **Zero Dependencies**: Pure Zig, no C libraries
2. **RISC-V Native**: Direct kernel integration
3. **Simpler**: Direct syscall-based rendering
4. **Grain Style**: All code follows style guide

**Disadvantages**:
1. **Less Features**: No hardware acceleration (initially)
2. **More Work**: Must implement rendering ourselves
3. **Less Standard**: Not using industry-standard library

**Decision**: Kernel framebuffer aligns with Grain OS philosophy (zero dependencies, pure Zig, RISC-V native).

---

## Key Insights from River

### 1. Policy vs. Implementation Separation

River excellently separates **policy** (layout logic) from **implementation** (compositor core). Our in-process generators maintain this separation through function pointer interfaces.

### 2. Runtime Configuration

River's `riverctl` approach is excellent - runtime configuration without restart. Our IPC-based approach provides similar functionality.

### 3. Layout Generator Protocol

River's `river-layout-v3.xml` protocol is well-designed. While we don't use separate processes, we could adopt the protocol concepts for future enhancements.

### 4. Clean Architecture

River's codebase demonstrates clean separation of concerns. We follow similar principles in our module organization.

---

## Future Enhancements (Optional)

### 1. Separate-Process Layout Generators

**If Needed**: Could adopt River's `river-layout-v3.xml` protocol for separate-process generators.

**Benefits**:
- Hot-reload layouts without restarting compositor
- Write generators in any language
- More modular architecture

**Costs**:
- Added complexity (process management, IPC)
- Performance overhead (serialization, IPC)
- More dependencies (process spawning, communication)

**Decision**: Not needed for initial implementation. Can add later if use case arises.

### 2. Tag System

**If Needed**: Could add River-style tags alongside or instead of workspaces.

**Benefits**:
- More flexible window organization
- Multiple tags per window
- Display multiple tags simultaneously

**Costs**:
- More complex data structures
- More complex UI/UX
- Harder to understand

**Decision**: Workspaces are sufficient for initial implementation. Tags could be added later.

### 3. Status Protocol

**If Needed**: Could adopt River's `river-status-unstable-v1.xml` for status bar integration.

**Status**: Desktop shell implementation in progress. Can reference River's protocol for ideas.

---

## Summary

**River Inspiration**: ✅ Architectural patterns studied and understood  
**Clean-Room Implementation**: ✅ All code written independently  
**River Protocols**: 📋 ISC-licensed protocols available for reference  
**Current Approach**: ✅ Simpler, more efficient for initial implementation  
**Future Flexibility**: ✅ Can adopt River's protocol approach if needed

**Key Takeaway**: River's architecture is excellent, but our simpler approach fits our goals better (zero dependencies, pure Zig, RISC-V native, Grain Style compliant).

---

**Last Updated**: 2025-12-30  
**Reference**: River v0.3.12 in `grainstore/codeberg/river/river-0.3.12/`
