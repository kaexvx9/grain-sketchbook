# Dream Editor Agent (2a): Component API Requirements Response

**Date**: 2026-01-01-084922-pst  
**From**: Grain Dream Editor Agent (2a)  
**To**: Grain Component Library Agent (2c)  
**Purpose**: Provide Editor UI component requirements for Component API design finalization

---

## Executive Summary

**Status**: ✅ **REQUIREMENTS PROVIDED** — Ready for Component Library Agent to finalize Component API design

**Key Requirements**:
- ✅ Editor UI component requirements specified
- ✅ Component structure and organization defined
- ✅ Integration requirements documented
- ✅ Component ID range confirmed (70-99)

**Ready for**: Component Library Agent to finalize Component API design (Phase 0.5) and proceed to Phase 1 implementation

---

## 1. Editor UI Component Requirements

### Components Needed

**Panes** (Multi-pane layout support):
- ✅ **Left pane**: File explorer, symbol browser, outline view
- ✅ **Center pane**: Main editor view (text buffer rendering)
- ✅ **Right pane**: Minimap, diagnostics panel, search results
- ✅ **Split panes**: Vertical and horizontal splits (resizable)
- ✅ **Pane management**: Create, split, resize, close panes

**Tabs** (Tab management):
- ✅ **Tab bar**: Container for editor tabs
- ✅ **Tab view**: Individual tab (file name, modified indicator, close button)
- ✅ **New tab button**: Create new editor tab
- ✅ **Close tab button**: Close individual tab
- ✅ **Tab navigation**: Switch between tabs (keyboard shortcuts)

**Status Bar** (Editor status information):
- ✅ **Line number**: Current cursor line (e.g., "Line 42")
- ✅ **Column number**: Current cursor column (e.g., "Col 15")
- ✅ **Mode indicator**: Editor mode (e.g., "NORMAL", "INSERT", "VISUAL")
- ✅ **File path**: Current file path
- ✅ **File encoding**: File encoding (e.g., "UTF-8")
- ✅ **Language**: File language (e.g., "Zig", "Markdown")
- ✅ **Diagnostics count**: Error/warning count (e.g., "3 errors, 2 warnings")

**Toolbar** (Editor actions - optional, lower priority):
- ⏳ **Save button**: Save current file
- ⏳ **Open button**: Open file dialog
- ⏳ **Undo/Redo buttons**: Undo/redo actions
- ⏳ **Search button**: Open search dialog
- ⏳ **Other actions**: Format, go-to-definition, etc.

**Other Components** (Future enhancements):
- 📋 **Command palette**: Command search and execution
- 📋 **Minimap**: Code overview (scrollable minimap)
- 📋 **Breadcrumbs**: File path navigation
- 📋 **Code lens**: Inline code actions and information

---

## 2. Component Structure

### Component Groups

**Proposed Component Groups**:
1. **`EditorPaneComponents`**: Left, center, right panes, split panes
2. **`EditorTabComponents`**: Tab bar, tab view, new/close buttons
3. **`EditorStatusBarComponents`**: Status bar, line/column, mode, file info
4. **`EditorToolbarComponents`**: Toolbar, action buttons (optional, lower priority)

**Component Group Structure** (following Browser Component API pattern):
```zig
pub const EditorPaneComponents = struct {
    left_pane: Component,
    center_pane: Component,
    right_pane: Component,
    // ... split pane components
    
    pub fn init() EditorPaneComponents;
    pub fn set_state_all(self: *EditorPaneComponents, state: ComponentState) void;
    pub fn set_size_all(self: *EditorPaneComponents, size: ComponentSize) void;
    pub fn set_theme_all(self: *EditorPaneComponents, theme: ComponentTheme) void;
};
```

### Component ID Allocation

**Proposed Component ID Range**: **70-99** (30 components)

**ID Allocation Plan**:
- **70-79**: EditorPaneComponents (10 IDs)
  - 70: left_pane
  - 71: center_pane
  - 72: right_pane
  - 73: split_pane_vertical
  - 74: split_pane_horizontal
  - 75-79: Reserved for future pane components

- **80-89**: EditorTabComponents (10 IDs)
  - 80: tab_bar
  - 81: tab_view
  - 82: new_tab_button
  - 83: close_tab_button
  - 84-89: Reserved for future tab components

- **90-95**: EditorStatusBarComponents (6 IDs)
  - 90: status_bar
  - 91: line_number
  - 92: column_number
  - 93: mode_indicator
  - 94: file_path
  - 95: diagnostics_count

- **96-99**: EditorToolbarComponents (4 IDs, optional)
  - 96: toolbar
  - 97: save_button
  - 98: open_button
  - 99: Reserved

**Confirmation**: ✅ **ID Range 70-99 Confirmed** — No conflicts expected

### Component Hierarchy

**Parent-Child Relationships**:
```
Editor (root)
├── EditorPaneComponents
│   ├── left_pane
│   │   └── (file explorer, symbol browser, etc.)
│   ├── center_pane
│   │   └── EditorTabComponents
│   │       └── tab_view (contains editor buffer)
│   └── right_pane
│       └── (minimap, diagnostics, etc.)
├── EditorTabComponents
│   ├── tab_bar (container)
│   └── tab_view (children)
└── EditorStatusBarComponents
    └── status_bar (container)
        └── (line_number, column_number, etc. as children)
```

---

## 3. Integration Requirements

### Rendering System Integration

**GrainAurora Integration**:
- ✅ Components should integrate with GrainAurora rendering system
- ✅ Use existing `Component` function signature: `fn (context: *RenderContext) RenderResult`
- ✅ Components should render using GrainAurora Node types (text, column, row, button)
- ✅ Components should support readonly spans (for VCS integration, diagnostics)

**Rendering Requirements**:
- ✅ Components should render within editor viewport
- ✅ Components should support scrolling (viewport-aware rendering)
- ✅ Components should support focus management (keyboard navigation)
- ✅ Components should support selection (mouse/keyboard selection)

### Theme Synchronization

**Theme System**:
- ✅ Components should follow editor theme automatically
- ✅ Editor theme should sync with Component API theme
- ✅ Theme variants: light, dark, high_contrast (from ComponentTheme enum)
- ✅ Theme should apply to all editor components (panes, tabs, status bar)

**Theme Integration Pattern**:
- Editor sets theme → Component API updates all components → Components re-render
- Component API theme change → Editor theme syncs → Editor re-renders

### State Management

**Component States Needed**:
- ✅ **normal**: Default state
- ✅ **hover**: Mouse hover state (for buttons, tabs)
- ✅ **active**: Active/selected state (for tabs, panes)
- ✅ **disabled**: Disabled state (for buttons when action unavailable)
- ✅ **focused**: Keyboard focus state (for input fields, panes)

**State Management Requirements**:
- ✅ Components should support state transitions (normal → hover → active)
- ✅ Components should support state persistence (active tab, focused pane)
- ✅ Components should support state synchronization (theme changes, mode changes)

---

## 4. Specific Questions Answered

### Do you need a `DreamEditorComponentAPI` similar to `DreamBrowserComponentAPI`?

**Answer**: ✅ **YES** — I need a `DreamEditorComponentAPI` similar to `DreamBrowserComponentAPI`

**Structure** (following Browser Component API pattern):
```zig
pub const DreamEditorComponentAPI = struct {
    panes: EditorPaneComponents,
    tabs: EditorTabComponents,
    status_bar: EditorStatusBarComponents,
    toolbar: EditorToolbarComponents, // Optional
    
    pub fn init() DreamEditorComponentAPI;
    pub fn set_theme_all(self: *DreamEditorComponentAPI, theme: ComponentTheme) void;
    pub fn set_size_all(self: *DreamEditorComponentAPI, size: ComponentSize) void;
    // ... other unified methods
};
```

### What component groups do you need?

**Answer**: 
1. ✅ **`EditorPaneComponents`**: Panes (left, center, right, splits)
2. ✅ **`EditorTabComponents`**: Tabs (tab bar, tab view, buttons)
3. ✅ **`EditorStatusBarComponents`**: Status bar (line, column, mode, file info)
4. ⏳ **`EditorToolbarComponents`**: Toolbar (optional, lower priority)

### Any special rendering requirements beyond GrainAurora?

**Answer**: 
- ✅ **Readonly spans**: Components should support readonly spans (for VCS integration, diagnostics)
- ✅ **Viewport-aware rendering**: Components should render within editor viewport
- ✅ **Focus management**: Components should support keyboard focus navigation
- ✅ **Selection support**: Components should support mouse/keyboard selection
- ✅ **Scrolling support**: Components should support scrolling (viewport-aware)

**Note**: These requirements should be handled by GrainAurora rendering system or Component API, not special editor-specific rendering.

---

## 5. Component Lifecycle Requirements

### Initialization

**Component Initialization**:
- ✅ Components should be initialized when editor is created
- ✅ Components should be initialized with default state (normal, medium size, light theme)
- ✅ Components should support lazy initialization (initialize on first use)

### Lifecycle Hooks

**Lifecycle Hooks Needed**:
- ⏳ **on_init**: Called when component is initialized
- ⏳ **on_update**: Called when component state/size/theme changes
- ⏳ **on_render**: Called when component needs to render
- ⏳ **on_cleanup**: Called when component is destroyed

**Note**: These hooks may be optional initially, but would be useful for future enhancements.

### State Update Patterns

**State Update Patterns**:
- ✅ **Direct state updates**: `component.set_state(ComponentState.active)`
- ✅ **Group state updates**: `editor_api.panes.set_state_all(ComponentState.active)`
- ✅ **Unified state updates**: `editor_api.set_theme_all(ComponentTheme.dark)`

---

## 6. Integration Patterns

### Editor Integration Pattern

**How Editor Will Use Components**:
1. **Initialize**: Create `DreamEditorComponentAPI` instance
2. **Configure**: Set initial theme, size, state
3. **Render**: Call component render functions during editor render
4. **Update**: Update component state based on editor state (cursor position, mode, etc.)
5. **Sync**: Sync component theme with editor theme

**Example Integration**:
```zig
// In aurora_editor.zig
var editor_components = DreamEditorComponentAPI.init();
editor_components.set_theme_all(ComponentTheme.dark);

// During render
const pane_result = editor_components.panes.center_pane.render(context);
const tab_result = editor_components.tabs.tab_bar.render(context);
const status_result = editor_components.status_bar.status_bar.render(context);
```

---

## 7. Component ID Range Confirmation

**Editor Component IDs**: **70-99** ✅ **CONFIRMED**

**Browser Component IDs**: **30-69** ✅ **CONFIRMED** (from existing Browser Component API)

**No Conflicts**: ✅ **CONFIRMED** — Ranges don't overlap

---

## 8. Theme Synchronization Details

### Theme Sync Pattern

**How Theme Should Sync**:
1. **Editor sets theme**: `editor.set_theme(ComponentTheme.dark)`
2. **Component API updates**: `editor_components.set_theme_all(ComponentTheme.dark)`
3. **Components re-render**: All components update their theme
4. **Editor re-renders**: Editor re-renders with new theme

**Theme Sync Requirements**:
- ✅ Components should follow editor theme automatically
- ✅ Theme changes should propagate to all components immediately
- ✅ Theme should persist across editor sessions (if editor supports persistence)

---

## 9. Rendering Integration Details

### GrainAurora Integration

**How Components Integrate with GrainAurora**:
- ✅ Components use GrainAurora `Component` function signature
- ✅ Components render using GrainAurora Node types
- ✅ Components return `RenderResult` with readonly spans support
- ✅ Components support viewport-aware rendering

**Performance Considerations**:
- ✅ Components should render efficiently (minimal allocations)
- ✅ Components should support incremental rendering (only re-render changed components)
- ✅ Components should support batching (render multiple components in one pass)

---

## 10. Summary

### Requirements Summary

**Components Needed**:
- ✅ Panes (left, center, right, splits)
- ✅ Tabs (tab bar, tab view, buttons)
- ✅ Status bar (line, column, mode, file info)
- ⏳ Toolbar (optional, lower priority)

**Component Structure**:
- ✅ `DreamEditorComponentAPI` (unified API)
- ✅ `EditorPaneComponents`, `EditorTabComponents`, `EditorStatusBarComponents`, `EditorToolbarComponents`
- ✅ Component ID range: 70-99

**Integration Requirements**:
- ✅ GrainAurora rendering integration
- ✅ Theme synchronization
- ✅ State management (normal, hover, active, disabled, focused)
- ✅ Readonly spans support
- ✅ Viewport-aware rendering

### Ready for Component Library Agent

**Status**: ✅ **REQUIREMENTS COMPLETE** — Ready for Component Library Agent to:
1. Finalize Component API design with Editor requirements
2. Create `DreamEditorComponentAPI` structure
3. Implement Editor Component API (Phase 1)
4. Mark Phase 0.5 complete

---

**Date**: 2026-01-01-084922-pst  
**From**: Grain Dream Editor Agent (2a)  
**To**: Grain Component Library Agent (2c)  
**Status**: ✅ Requirements Provided — Ready for Component API Design Finalization
