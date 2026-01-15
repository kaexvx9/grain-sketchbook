# Component Library Phase 1 Implementation Preparation

**Date**: 2026-01-02-085302-pst  
**Agent**: Grain Component Library Agent (2c, L2 Sub-Agent)  
**Phase**: Phase 1 Preparation — Implementation Structure Planning  
**Status**: ⏳ **PREPARATION** — Ready for implementation once requirements received

---

## Purpose

This document outlines the implementation structure and approach for Phase 1 Component API implementation. This preparation work will accelerate implementation once Editor and Browser agent requirements are received.

---

## Module Structure Planning

### Proposed File Organization

```
src/
├── grain_component_library/          (new module, Phase 1)
│   ├── root.zig                      (module root, exports)
│   ├── component_api.zig             (Component API core types)
│   ├── lifecycle.zig                 (lifecycle management)
│   └── state_management.zig          (state/size/theme management)
├── dream_editor_components.zig       (new file, Phase 1)
├── dream_browser_components.zig      (existing, may update)
└── grain_aurora.zig                  (existing, may extend)
```

### Module Responsibilities

**`grain_component_library/root.zig`**:
- Module root exports
- Public API surface
- Re-exports from submodules

**`grain_component_library/component_api.zig`**:
- Component base type wrappers (if needed beyond Workspace Agent types)
- Component group structures
- Component ID management utilities
- Component lookup and management

**`grain_component_library/lifecycle.zig`**:
- Component initialization patterns
- Component update patterns
- Component cleanup patterns
- Lifecycle state management

**`grain_component_library/state_management.zig`**:
- State/size/theme variant management
- Group-level state management utilities
- State transition validation
- Theme synchronization utilities

**`dream_editor_components.zig`**:
- Editor-specific Component API
- Editor component groups (panes, tabs, status bar, toolbar)
- Editor component initialization
- Editor component integration patterns

---

## Key Implementation Patterns

### Component Base Types

**Reuse Existing**: Use Workspace Agent's `Component` struct from `src/grain_workspace/components.zig`.

**No Duplication**: Do not redefine base Component types. Import and use existing types.

### Component Groups Pattern

Following the Browser Component API pattern:

```zig
pub const EditorPaneComponents = struct {
    editor_pane: Component,
    line_numbers: Component,
    gutter: Component,
    // ... other pane components
    
    pub fn init(allocator: Allocator) EditorPaneComponents;
    pub fn set_theme_all(self: *EditorPaneComponents, theme: ComponentTheme) void;
    pub fn set_size_all(self: *EditorPaneComponents, size: ComponentSize) void;
    pub fn update_all(self: *EditorPaneComponents, context: *RenderContext) void;
};
```

### Component Lifecycle Management

**Pattern**:
1. **Init**: Component initialization with ID allocation
2. **Update**: State/size/theme updates, render preparation
3. **Render**: GrainAurora rendering integration
4. **Cleanup**: Resource cleanup (if needed)

**Function Signatures** (Grain Style):
```zig
pub fn init_component(id: u32, name: []const u8) Component;
pub fn update_component(component: *Component, state: ComponentState) void;
pub fn render_component(component: *Component, context: *RenderContext) RenderResult;
pub fn cleanup_component(component: *Component) void;
```

### Component ID Management

**ID Ranges** (from design doc):
- Workspace Agent: 1-29 (existing)
- Browser Agent: 30-69 (existing)
- Editor Agent: 70-99 (proposed)
- Component Library: 1000-9999 (Phase 2, future)

**Utilities**:
```zig
pub fn allocate_component_id(range_start: u32, range_end: u32) u32;
pub fn validate_component_id(id: u32, range_start: u32, range_end: u32) bool;
```

---

## Grain Style Compliance

### Function Naming

- All functions: `grain_case` (snake_case)
- Component groups: `PascalCase` (e.g., `EditorPaneComponents`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `MAX_COMPONENT_NAME_LEN`)

### Type Usage

- **Explicit types**: `u32`, `u64` (NO `usize`/`isize`)
- **Bounded allocations**: All MAX_ constants defined
- **Function length**: ≤70 lines (`grain validate-70`)
- **Line length**: ≤100 characters (`grainwrap-100`)
- **Assertions**: Minimum 2 per function

### Code Organization

- Helper functions extracted to keep main functions ≤70 lines
- Clear separation of concerns (lifecycle, state, rendering)
- Comprehensive assertions for preconditions, postconditions, invariants

---

## Test Structure Planning

### Test File Organization

```
tests/
├── component_library/
│   ├── component_api_test.zig
│   ├── lifecycle_test.zig
│   ├── state_management_test.zig
│   └── integration_test.zig
└── dream_editor_components_test.zig (when created)
```

### Test Coverage Goals

**Component API Core** (following existing test patterns):
- Component initialization (`Component.init()`)
- Component state/size/theme setters (`set_state()`, `set_size()`, `set_theme()`)
- Component name truncation (edge case: names > MAX_COMPONENT_NAME_LEN)
- Component variant combinations (state + size + theme combinations)
- Component ID validation

**Component Groups** (following existing test patterns):
- Component group initialization (`EditorPaneComponents.init()`, etc.)
- Group-level state management (`set_state_all()`, `set_size_all()`, `set_theme_all()`)
- Component ID verification within groups
- Component name verification within groups

**Unified API** (when implemented):
- Unified API initialization (`DreamEditorComponentAPI.init()`)
- Unified API theme/size management (`set_theme_all()`, `set_size_all()`)
- Cross-group state management

**Lifecycle Management**:
- Init/update/render/cleanup patterns (if lifecycle functions added)
- Lifecycle state transitions

**Integration**:
- GrainAurora rendering integration (if integration functions added)
- Component composition patterns
- Editor component integration (when implemented)
- Browser component integration (when updated)

### Test Pattern Examples (from existing tests)

**Component Init Test**:
```zig
test "Component init" {
    const comp = Component.init(1, "test_component");
    try testing.expect(comp.id == 1);
    try testing.expect(comp.name_len == 14);
    try testing.expect(comp.state == .normal);
    try testing.expect(comp.size == .medium);
    try testing.expect(comp.theme == .light);
    try testing.expect(comp.visible == true);
    try testing.expect(comp.enabled == true);
}
```

**Component Group Test**:
```zig
test "EditorPaneComponents init" {
    const pane_components = EditorPaneComponents.init();
    try testing.expect(pane_components.editor_pane.id == 70);
    try testing.expect(pane_components.line_numbers.id == 71);
    try testing.expect(pane_components.editor_pane.name_len > 0);
}
```

**Component Group State Management Test**:
```zig
test "EditorPaneComponents set_theme_all" {
    var pane_components = EditorPaneComponents.init();
    pane_components.set_theme_all(.dark);
    try testing.expect(pane_components.editor_pane.theme == .dark);
    try testing.expect(pane_components.line_numbers.theme == .dark);
    pane_components.set_theme_all(.high_contrast);
    try testing.expect(pane_components.editor_pane.theme == .high_contrast);
}
```

**Edge Case Test**:
```zig
test "Component name truncation" {
    const long_name = "a" ** 100;
    const comp = Component.init(1, long_name);
    try testing.expect(comp.name_len == MAX_COMPONENT_NAME_LEN);
    try testing.expect(comp.name_len <= MAX_COMPONENT_NAME_LEN);
}
```

---

## Implementation Readiness Checklist

### Design Phase (Phase 0.5) ✅

- [x] Component API design document complete
- [x] Architecture decisions documented
- [x] Integration patterns documented
- [x] Coordination documents sent to Editor/Browser agents

### Requirements Phase (Phase 0.5 Finalization) ✅

- [x] Receive Editor Agent (2a) component requirements
- [x] Receive Browser Agent (2b) component requirements
- [x] Finalize Component API design based on requirements
- [x] Coordinate Component ID allocation with Aurora 2 Subcore

### Implementation Phase (Phase 1) 📋

- [ ] Create module structure (`grain_component_library/`)
- [ ] Implement Component API core (`component_api.zig`)
- [ ] Implement lifecycle management (`lifecycle.zig`)
- [ ] Implement state management (`state_management.zig`)
- [ ] Create Editor Component API (`dream_editor_components.zig`)
- [ ] Review/update Browser Component API if needed
- [ ] Implement comprehensive tests
- [ ] Verify Grain Style compliance (`grainwrap-100`, `grain validate-70`)
- [ ] Address all compiler warnings

---

## Dependencies and Coordination

### Dependencies

**Reuses**:
- `src/grain_workspace/components.zig` - Base Component types
- `src/dream_browser_components.zig` - Browser Component API patterns
- `src/grain_aurora.zig` - Rendering system

**Coordinates With**:
- Editor Agent (2a) - Component requirements, integration patterns
- Browser Agent (2b) - Component requirements, API updates
- Aurora 2 Subcore - Component ID allocation, architecture approval
- Bubble Agent (via Aurora 2 Subcore) - Component API review for JG UI work

### Integration Points

1. **Editor Agent Integration**:
   - Editor component groups structure
   - Editor component initialization patterns
   - Editor component rendering integration

2. **Browser Agent Integration**:
   - Browser Component API updates (if needed)
   - Browser component rendering integration
   - Browser component state management

3. **Bubble Agent Integration**:
   - Component API review for JG UI components
   - Design pattern integration
   - Animation integration approach

---

## Next Steps

### Immediate (Awaiting Requirements)

1. **Wait for Editor/Browser Requirements**:
   - Editor Agent (2a) component requirements
   - Browser Agent (2b) component requirements

2. **Prepare for Coordination**:
   - Review requirements when received
   - Finalize Component API design
   - Coordinate Component ID allocation

### Once Requirements Received

1. **Begin Implementation**:
   - Create module structure
   - Implement Component API core
   - Implement lifecycle management
   - Implement state management
   - Create Editor Component API
   - Review/update Browser Component API

2. **Testing**:
   - Implement comprehensive tests
   - Verify Grain Style compliance
   - Address compiler warnings

3. **Coordination**:
   - Coordinate with Editor Agent on integration
   - Coordinate with Browser Agent on integration
   - Coordinate with Bubble Agent on API review

---

## Notes

- This preparation document does not implement code — it outlines structure and approach
- Implementation will begin once Editor and Browser requirements are received
- All implementation will follow Grain Style strictly
- All functions will be ≤70 lines, all lines ≤100 characters
- All types will be explicit (`u32`/`u64`, no `usize`/`isize`)
- All allocations will be bounded with MAX_ constants
- All functions will have minimum 2 assertions

---

**Date**: 2026-01-02-085302-pst  
**Agent**: Grain Component Library Agent (2c)  
**Status**: ⏳ **PREPARATION COMPLETE** — Ready for implementation once requirements received

