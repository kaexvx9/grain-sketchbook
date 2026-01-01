# Component API Design Document

**Agent**: Grain Component Library Agent (2c, L2 Sub-Agent)  
**Phase**: Phase 0.5 — Component API Design  
**Status**: Design Complete ✅  
**Date**: 2025-12-31  
**Priority**: HIGHEST — Blocks Bubble Agent JG UI work

---

## Executive Summary

This document describes the unified Component API architecture for Editor, Browser, and JG Project applications. The Component API provides a type-safe, performant system for building UI components with lifecycle management, state management, and rendering integration.

**Key Design Decisions**:
- Reuse existing base Component types from Workspace Agent (`src/grain_workspace/components.zig`)
- Build on existing Browser Component API structure (`src/dream_browser_components.zig`)
- Integrate with GrainAurora rendering system (`src/grain_aurora.zig`)
- Support Editor, Browser, and future JG Project components
- Follow GrainStyle principles (grain_case, u32/u64, bounded allocations, assertions)

**Status**: ✅ Design complete — Ready for Phase 1 implementation

---

## Architecture Overview

### Component API Layers

```
┌─────────────────────────────────────────────────────────────┐
│  Application Layer (Editor, Browser, JG Project)            │
│  - Editor Components (panes, tabs, status bars)             │
│  - Browser Components (navigation, tabs, address bar)       │
│  - JG Project Components (3D, dashboards, mobile)           │
├─────────────────────────────────────────────────────────────┤
│  Component Library Layer (Phase 2)                          │
│  - Basic UI Components (buttons, inputs, labels)            │
│  - Layout Components (columns, rows, containers)            │
│  - Component Styling and Theming                            │
├─────────────────────────────────────────────────────────────┤
│  Component API Core Layer (Phase 1)                         │
│  - Component Base Types (state/size/theme variants)         │
│  - Component Lifecycle Management                           │
│  - Component State Management                               │
│  - Component Rendering Integration                          │
├─────────────────────────────────────────────────────────────┤
│  Rendering Layer (GrainAurora)                              │
│  - Component Rendering Function Signature                   │
│  - RenderContext and RenderResult                           │
│  - Node Types (text, column, row, button)                   │
└─────────────────────────────────────────────────────────────┘
```

### Existing Code Foundation

1. **Base Component Types** (`src/grain_workspace/components.zig`):
   - `Component` struct (id, name, state, size, theme, visible, enabled)
   - `ComponentState` enum (normal, hover, active, disabled, focused)
   - `ComponentSize` enum (small, medium, large)
   - `ComponentTheme` enum (light, dark, high_contrast)
   - Component initialization and state management methods

2. **Browser Component API** (`src/dream_browser_components.zig`):
   - `DreamBrowserComponentAPI` unified API
   - Component groups (NavigationComponents, AddressBarComponents, TabComponents, BrowserViewComponents)
   - Group-level state/size/theme management (`set_theme_all()`, `set_size_all()`)

3. **Rendering System** (`src/grain_aurora.zig`):
   - `Component` function signature: `fn (context: *RenderContext) RenderResult`
   - `RenderContext` (allocator, buffer, route)
   - `RenderResult` (root Node, readonly_spans, diagnostic_spans, etc.)
   - Node types (text, column, row, button)

---

## Component API Core Design

### Component Base Types

**Reuse Existing**: Use Workspace Agent's base Component types (`src/grain_workspace/components.zig`).

```zig
// Base Component (from Workspace Agent)
pub const Component = struct {
    id: u32,
    name: [MAX_COMPONENT_NAME_LEN]u8,
    name_len: u32,
    state: ComponentState,
    size: ComponentSize,
    theme: ComponentTheme,
    visible: bool,
    enabled: bool,
    
    pub fn init(id: u32, name: []const u8) Component;
    pub fn set_state(self: *Component, state: ComponentState) void;
    pub fn set_size(self: *Component, size: ComponentSize) void;
    pub fn set_theme(self: *Component, theme: ComponentTheme) void;
};
```

**Why Reuse**: Workspace Agent's Component base types are well-designed, follow GrainStyle principles, and are already in use. No need to duplicate.

### Component Lifecycle Management

**Design**: Component lifecycle is managed through initialization and state updates. Components are stateless data structures (no dynamic allocation after initialization).

**Lifecycle Stages**:
1. **Initialization**: `Component.init(id, name)` creates a component with default state
2. **Configuration**: `set_state()`, `set_size()`, `set_theme()` update component properties
3. **Rendering**: Component data is used by GrainAurora rendering system
4. **Cleanup**: No explicit cleanup needed (components are value types, no dynamic allocation)

**Design Decision**: Components are value types (no pointers, no dynamic allocation). This follows GrainStyle principles and simplifies lifecycle management.

### Component State Management

**Design**: Component state is managed through explicit state/size/theme variants.

**State Variants**:
- `ComponentState`: normal, hover, active, disabled, focused
- `ComponentSize`: small, medium, large
- `ComponentTheme`: light, dark, high_contrast

**State Management Patterns**:
1. **Individual Component State**: `component.set_state(state)`, `component.set_size(size)`, `component.set_theme(theme)`
2. **Group-Level State**: `components.set_theme_all(theme)`, `components.set_size_all(size)` (existing pattern in Browser Component API)
3. **Application-Level State**: Application manages component state based on user interaction, application state, etc.

**Design Decision**: State is explicit and type-safe. No hidden state, no implicit state transitions.

### Component Rendering Integration

**Design**: Components integrate with GrainAurora rendering system through component data structures. Components provide data, GrainAurora handles rendering.

**Rendering Flow**:
1. Application creates Component instances (using Component API)
2. Application provides Component data to GrainAurora rendering system
3. GrainAurora rendering function uses Component data to render UI
4. Rendering function returns `RenderResult` with Node tree and spans

**Integration Pattern**:
- Components are data structures (Component API layer)
- Rendering functions use component data (GrainAurora layer)
- No tight coupling between Component API and GrainAurora (separation of concerns)

**Existing Pattern** (from `src/grain_aurora.zig`):
```zig
pub const Component = fn (context: *RenderContext) RenderResult;

pub const RenderContext = struct {
    allocator: std.mem.Allocator,
    buffer: *GrainBuffer,
    route: []const u8,
};

pub const RenderResult = struct {
    root: Node,
    readonly_spans: []const Span,
    // ... other span types
};
```

**Design Decision**: Component API provides component data, GrainAurora provides rendering. Clear separation of concerns.

---

## Component API Structure

### Component Groups Pattern

**Existing Pattern** (from Browser Component API): Component groups organize related components.

**Pattern**:
```zig
pub const ComponentGroup = struct {
    component1: Component,
    component2: Component,
    // ...
    
    pub fn init() ComponentGroup;
    pub fn set_theme_all(self: *ComponentGroup, theme: ComponentTheme) void;
    pub fn set_size_all(self: *ComponentGroup, size: ComponentSize) void;
    pub fn set_state_all(self: *ComponentGroup, state: ComponentState) void;
};
```

**Design Decision**: Use component groups pattern for organizing related components. This pattern is already established in Browser Component API.

### Unified Application API Pattern

**Existing Pattern** (from Browser Component API): Unified API provides access to all component groups.

**Pattern**:
```zig
pub const ApplicationComponentAPI = struct {
    group1: ComponentGroup1,
    group2: ComponentGroup2,
    // ...
    
    pub fn init() ApplicationComponentAPI;
    pub fn set_theme_all(self: *ApplicationComponentAPI, theme: ComponentTheme) void;
    pub fn set_size_all(self: *ApplicationComponentAPI, size: ComponentSize) void;
};
```

**Design Decision**: Use unified application API pattern for applications (Editor, Browser, JG Project). This pattern is already established in Browser Component API.

---

## Editor Component API Design

### Editor Component Groups

**Design**: Editor components organized into logical groups.

**Proposed Groups**:
1. **PaneComponents**: Editor panes (left_pane, center_pane, right_pane, etc.)
2. **TabComponents**: Editor tabs (tab_bar, tab_view, new_tab_button, close_tab_button)
3. **StatusBarComponents**: Status bar (status_bar, line_number, column_number, mode_indicator)
4. **ToolbarComponents**: Toolbar (toolbar, save_button, open_button, etc.)

**Design Decision**: Follow Browser Component API pattern for Editor components. Coordinate with Editor Agent (2a) on final component groups.

### Editor Component API Structure

**Proposed Structure**:
```zig
pub const EditorPaneComponents = struct {
    left_pane: Component,
    center_pane: Component,
    right_pane: Component,
    // ...
    
    pub fn init() EditorPaneComponents;
    pub fn set_theme_all(self: *EditorPaneComponents, theme: ComponentTheme) void;
    // ...
};

pub const EditorTabComponents = struct {
    tab_bar: Component,
    tab_view: Component,
    new_tab_button: Component,
    close_tab_button: Component,
    
    pub fn init() EditorTabComponents;
    pub fn set_theme_all(self: *EditorTabComponents, theme: ComponentTheme) void;
    // ...
};

pub const DreamEditorComponentAPI = struct {
    panes: EditorPaneComponents,
    tabs: EditorTabComponents,
    status_bar: EditorStatusBarComponents,
    toolbar: EditorToolbarComponents,
    
    pub fn init() DreamEditorComponentAPI;
    pub fn set_theme_all(self: *DreamEditorComponentAPI, theme: ComponentTheme) void;
    pub fn set_size_all(self: *DreamEditorComponentAPI, size: ComponentSize) void;
};
```

**Files**: `src/dream_editor_components.zig` (to be created in Phase 1)

**Design Decision**: Create Editor Component API following Browser Component API pattern. Coordinate with Editor Agent (2a) on component groups and IDs.

---

## Browser Component API Design

### Browser Component API Status

**Existing**: Browser Component API already implemented (`src/dream_browser_components.zig`).

**Structure**:
- `NavigationComponents` (navigation_bar, back_button, forward_button, reload_button, home_button)
- `AddressBarComponents` (address_bar, search_bar, bookmark_button)
- `TabComponents` (tab_bar, tab_view, new_tab_button, close_tab_button)
- `BrowserViewComponents` (browser_view, content_area, status_bar)
- `DreamBrowserComponentAPI` (unified API)

**Design Decision**: Review existing Browser Component API, update if needed based on unified Component API design. Existing structure is good, may need minor refinements.

### Browser Component API Updates (if needed)

**Potential Updates** (Phase 1):
- Ensure consistency with unified Component API design
- Add any missing component groups (if needed)
- Refine component IDs if needed (coordinate with Editor Component API)

**Design Decision**: Existing Browser Component API is well-designed. Minimal updates expected.

---

## JG Project Component API Design (Months 7-12)

### JG Project Component Groups (Future)

**Design**: JG Project components organized into logical groups (Months 7-12).

**Proposed Groups**:
1. **VisualizationComponents**: 3D visualization components
2. **DashboardComponents**: Dashboard components
3. **MobileComponents**: Mobile UI components

**Design Decision**: JG Project Component API follows same patterns (component groups, unified API). Design will be finalized when JG Project foundation is ready (Core Agent Months 1-6).

**Files**: `src/grain_jg_project/components/` (to be created in Phase 4, Months 7-12)

---

## Component Library Design (Phase 2)

### Basic UI Components

**Design**: Reusable UI components built on Component API.

**Components**:
- Button component
- Input component (text input)
- Label component
- Checkbox component
- Radio button component
- Select/dropdown component

**Structure**:
```zig
pub const Button = struct {
    component: Component,
    label: []const u8,
    // ...
    
    pub fn init(id: u32, label: []const u8) Button;
    pub fn render(self: *const Button, context: *RenderContext) RenderResult;
};
```

**Files**: `src/grain_component_library/` (to be created in Phase 2)

**Design Decision**: Component library provides reusable components. Components wrap base Component type and add component-specific data and rendering.

### Layout Components

**Design**: Layout components for organizing UI.

**Components**:
- Column layout component
- Row layout component
- Container/panel component
- Scrollable container component
- Grid layout component (if needed)

**Structure**: Similar to basic UI components, with layout-specific rendering logic.

**Files**: `src/grain_component_library/layout.zig` (to be created in Phase 2)

---

## Component Styling and Theming

### Theme System

**Design**: Component themes managed through `ComponentTheme` enum and component styling system.

**Themes**: light, dark, high_contrast (from base Component type)

**Theme Application**:
- Component-level: `component.set_theme(theme)`
- Group-level: `components.set_theme_all(theme)`
- Application-level: `api.set_theme_all(theme)`

**Design Decision**: Theme system is explicit and type-safe. Coordinate with Bubble Agent on design patterns for styling/theming.

---

## Integration Patterns

### Editor Agent Integration

**Pattern**: Editor Agent uses Editor Component API for UI components.

**Integration Points**:
1. Editor Agent creates `DreamEditorComponentAPI` instance
2. Editor Agent updates component state based on editor state
3. Editor Agent provides component data to GrainAurora rendering
4. Theme synchronization between editor and components

**Design Decision**: Editor Agent uses Component API, manages component state, integrates with GrainAurora rendering.

### Browser Agent Integration

**Pattern**: Browser Agent uses Browser Component API for UI components (already implemented).

**Integration Points**:
1. Browser Agent uses existing `DreamBrowserComponentAPI`
2. Browser Agent updates component state based on browser state
3. Browser Agent provides component data to GrainAurora rendering
4. Theme synchronization between browser and components

**Design Decision**: Browser Agent already integrated. Review and refine as needed.

### Bubble Agent Integration

**Pattern**: Bubble Agent's SLC components render within Browser Component API's `content_area` component.

**Existing Integration** (from `src/grain_bubble/aurora_integration.zig`):
- SLC components render within `browser_view.content_area` component
- Design patterns synchronized with browser theme
- Animation utilities integrated

**Design Decision**: Bubble Agent integration pattern is established. Component API design supports this pattern.

---

## GrainStyle Compliance

### Code Style

- `grain_case` function names
- Explicit `u32`/`u64` types (not `usize`/`isize`)
- `grainwrap-100` (max 100 characters per line)
- `grain validate-70` (max 70 lines per function)
- Minimum 2 assertions per function
- Bounded allocations
- All compiler warnings enabled

### Component API Style

- Components are value types (no dynamic allocation after initialization)
- Explicit state management (no hidden state)
- Type-safe variants (enums for state/size/theme)
- Comprehensive assertions (preconditions, postconditions, invariants)

---

## Component ID Allocation

### ID Ranges

**Design**: Allocate component ID ranges to avoid conflicts.

**Proposed Ranges**:
- Workspace Agent: 1-29 (existing)
- Editor Agent: 70-99 (proposed)
- Browser Agent: 30-69 (existing)
- JG Project: 100-999 (future, Months 7-12)
- Component Library: 1000-9999 (future, Phase 2)

**Design Decision**: Coordinate with agents on component ID ranges to avoid conflicts.

---

## Summary

### Design Decisions

1. **Reuse Existing Base Types**: Use Workspace Agent's Component base types
2. **Component Groups Pattern**: Organize components into logical groups
3. **Unified Application API**: Provide unified API for applications
4. **Value Types**: Components are value types (no dynamic allocation)
5. **Explicit State Management**: State is explicit and type-safe
6. **Rendering Integration**: Clear separation between Component API and GrainAurora rendering
7. **GrainStyle Compliance**: Follow GrainStyle principles throughout

### Phase 1 Implementation Plan

1. Review existing Component code
2. Create Editor Component API (`src/dream_editor_components.zig`)
3. Review and update Browser Component API if needed
4. Document Component API usage patterns
5. Coordinate with Editor and Browser agents on component requirements

### Phase 2 Implementation Plan

1. Create component library module structure
2. Implement basic UI components
3. Implement layout components
4. Implement component styling and theming
5. Coordinate with Bubble Agent on design patterns

### Coordination Points

- **Editor Agent (2a)**: Coordinate on Editor Component API structure
- **Browser Agent (2b)**: Review existing Browser Component API
- **Bubble Agent**: Component API design ready for Bubble Agent JG UI work
- **Workspace Agent**: Coordinate on component ID ranges (if needed)

---

## Status

✅ **Component API Design Complete** — Ready for Phase 1 implementation

**Next Steps**:
1. Coordinate with Editor and Browser agents on component requirements
2. Begin Phase 1 Component API implementation
3. Create Editor Component API
4. Review and update Browser Component API if needed

---

**Agent**: Grain Component Library Agent (2c, L2 Sub-Agent)  
**Phase**: Phase 0.5 — Component API Design  
**Status**: ✅ Design Complete  
**Date**: 2025-12-31