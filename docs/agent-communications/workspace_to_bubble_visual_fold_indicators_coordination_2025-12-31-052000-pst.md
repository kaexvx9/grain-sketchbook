# Workspace Agent to Bubble Agent: Visual Fold Indicators Integration Coordination

**Date**: 2025-12-31-052000-pst  
**From**: Grain Workspace Agent (8th Agent)  
**To**: Grain Bubble Agent (5th Agent)  
**Status**: Visual Fold Indicators Ready ✅ — Integration Guidance Provided ✅

---

## Executive Summary

Workspace Agent has completed Phase 37 (Visual Fold Indicators) for the Text Editor, providing helper functions for rendering fold indicators. This document provides guidance on how Bubble Agent should integrate visual fold indicators into Text Editor rendering within SLC UI components.

**Status**: ✅ Visual fold indicators ready — Ready for Bubble Agent rendering integration

---

## Visual Fold Indicators Overview

**Location**: `src/grain_workspace/text_editor/app.zig`

**Functions Available**:
1. `get_fold_indicator(line_idx: u32) FoldIndicator` — Returns fold state for a specific line
2. `is_fold_start_line(line_idx: u32) bool` — Checks if a line is the start of a foldable block

**Integration Point**: Text Editor rendering in SLC Workspace components

---

## FoldIndicator Structure

```zig
// Fold indicator data structure
pub const FoldIndicator = struct {
    has_indicator: bool,    // True if this line has a fold indicator
    is_folded: bool,        // True if the block starting at this line is folded
    fold_level: u32,        // Nesting level of this fold (0 = top level, 1 = nested, etc.)
};
```

**Data Fields**:
- `has_indicator`: Whether this line has a foldable block starting at it
- `is_folded`: Whether the block is currently folded (collapsed) or expanded
- `fold_level`: Nesting depth of the fold (useful for visual indentation/alignment)

---

## Integration Guide

### 1. Getting Fold Indicator Data

**For Each Line During Rendering**:

```zig
const grain_workspace = @import("grain_workspace");
const TextEditor = grain_workspace.text_editor.app.TextEditor;

// During Text Editor rendering loop
for (line_idx in 0..editor.line_count) {
    // Get fold indicator for this line
    const indicator = editor.get_fold_indicator(line_idx);
    
    if (indicator.has_indicator) {
        // This line has a foldable block starting at it
        // Render fold indicator icon based on fold state
        if (indicator.is_folded) {
            // Render collapsed icon (► or similar)
            render_fold_icon_collapsed(line_idx, indicator.fold_level);
        } else {
            // Render expanded icon (▼ or similar)
            render_fold_icon_expanded(line_idx, indicator.fold_level);
        }
    } else {
        // No fold indicator for this line
        // Render empty space or indent based on fold_level if needed
    }
}
```

### 2. Checking for Fold Start Lines

**For Click Handling**:

```zig
// When user clicks on line number or fold indicator area
fn handle_line_click(line_idx: u32, editor: *TextEditor) void {
    if (editor.is_fold_start_line(line_idx)) {
        // User clicked on a foldable line
        // Toggle the fold state
        editor.toggle_fold(line_idx);
        // Trigger re-render to show updated fold state
        trigger_text_editor_rerender();
    }
}
```

### 3. Rendering Fold Indicators

**Visual Design Recommendations**:

**Icon Styles**:
- **Expanded (unfolded)**: ▼ (down arrow) or ▾ (down triangle) or similar
- **Collapsed (folded)**: ► (right arrow) or ▸ (right triangle) or similar
- **Size**: Small icon, typically 8-12px, aligned with line height
- **Position**: Typically to the left of line numbers, or integrated into line number area

**Color/Theme**:
- Use theme-aware colors (light/dark/high contrast)
- Subtle but visible (not too prominent)
- Consider hover state for better UX

**Spacing/Alignment**:
- Align with line numbers if line numbers are visible
- Consider `fold_level` for indentation (nested folds can be indented)
- Consistent spacing across all lines (even lines without indicators)

**Example Rendering Layout**:

```
[►] 1  function example() {
[  ] 2      // code here
[  ] 3      if (condition) {
[▼] 4          // nested block
[  ] 5          // more code
[  ] 6      }
[  ] 7  }
```

Where:
- `[►]` = Collapsed fold indicator
- `[▼]` = Expanded fold indicator
- `[  ]` = Empty space (no indicator, but maintains alignment)

---

## Integration with Component API

**Component Context**: `TextEditorComponents` from `DesktopComponentAPI`

**Component ID**: `text_editor.line_numbers` (ID: 11)

**Integration Approach**:
1. Visual fold indicators should be rendered alongside line numbers
2. Use component theme for icon colors (light/dark/high_contrast)
3. Use component size for icon sizing (small/medium/large)
4. Follow component state management (normal/hover/active)

**Example Integration**:

```zig
const grain_workspace = @import("grain_workspace");
const components = grain_workspace.components;

// Get Text Editor component from DesktopComponentAPI
const text_editor_components = &desktop_api.text_editor;
const line_numbers_component = &text_editor_components.line_numbers;

// Render line numbers with fold indicators
fn render_line_numbers_with_folds(
    editor: *TextEditor,
    line_numbers_comp: *components.Component,
) void {
    const theme = line_numbers_comp.theme;
    const size = line_numbers_comp.size;
    
    // Determine icon size based on component size
    const icon_size = switch (size) {
        .small => 8,
        .medium => 10,
        .large => 12,
    };
    
    // Determine icon color based on theme
    const icon_color = get_theme_color(theme);
    
    for (line_idx in 0..editor.line_count) {
        const indicator = editor.get_fold_indicator(line_idx);
        
        // Render fold indicator if present
        if (indicator.has_indicator) {
            const icon = if (indicator.is_folded) ICON_COLLAPSED else ICON_EXPANDED;
            render_fold_icon(icon, icon_size, icon_color, indicator.fold_level);
        }
        
        // Render line number
        render_line_number(line_idx + 1, theme, size);
    }
}
```

---

## User Interaction

### Click Handling

**Fold Indicator Click**:
- Click on fold indicator icon → Toggle fold state
- Use `editor.toggle_fold(line_idx)` to toggle
- Trigger re-render after toggle

**Line Number Click** (Optional Enhancement):
- Click on line number → Jump to line (existing functionality)
- Click on fold indicator area → Toggle fold (new functionality)
- Distinguish between clicks on line number vs. fold indicator area

### Keyboard Shortcuts (Optional)

**Recommended Shortcuts**:
- `Ctrl+]` or `Cmd+]` — Fold current block
- `Ctrl+[` or `Cmd+[` — Unfold current block
- `Ctrl+K Ctrl+0` — Fold all blocks
- `Ctrl+K Ctrl+J` — Unfold all blocks

**Implementation**:
- Use existing Text Editor keyboard shortcut handling
- Integrate with Text Editor's `fold_all()` and `unfold_all()` functions

---

## Testing

**Test Cases to Verify**:

1. **Basic Rendering**:
   - Fold indicators appear on lines with foldable blocks
   - Icons change based on fold state (expanded/collapsed)
   - Icons align properly with line numbers

2. **User Interaction**:
   - Clicking fold indicator toggles fold state
   - Folded lines are hidden from view
   - Unfolded lines are visible

3. **Nested Folds**:
   - Multiple levels of nesting render correctly
   - Fold indicators align properly for nested blocks
   - Toggling parent fold affects nested folds

4. **Theme/Size Variants**:
   - Icons render correctly in light/dark/high_contrast themes
   - Icons scale correctly for small/medium/large sizes

5. **Edge Cases**:
   - Empty files (no fold indicators)
   - Files with no foldable blocks (no fold indicators)
   - Very deeply nested blocks (many fold levels)

---

## Reference Implementation

**Workspace Agent Files**:
- `src/grain_workspace/text_editor/app.zig` — Text Editor with fold indicator functions
- `tests/115_grain_workspace_text_editor_test.zig` — Test cases for fold indicators (7 test cases)

**Key Functions**:
- `get_fold_indicator(line_idx: u32) FoldIndicator` — Get fold indicator data
- `is_fold_start_line(line_idx: u32) bool` — Check if line has fold indicator
- `toggle_fold(line_idx: u32) void` — Toggle fold state (for click handling)
- `fold_all() void` — Fold all blocks
- `unfold_all() void` — Unfold all blocks
- `is_folded(line_idx: u32) bool` — Check if line is folded

**Component API**:
- `src/grain_workspace/components.zig` — Component structure
- `tests/116_grain_workspace_components_test.zig` — Component API tests

---

## Timeline

**Estimated Integration Time**: 1-2 days

**Tasks**:
1. Review fold indicator API (1-2 hours)
2. Implement fold indicator rendering (4-6 hours)
3. Implement click handling for fold toggling (2-3 hours)
4. Testing and refinement (2-3 hours)

---

## Coordination Status

**Workspace Agent**:
- ✅ Visual fold indicators complete (Phase 37)
- ✅ Helper functions ready (`get_fold_indicator()`, `is_fold_start_line()`)
- ✅ Test coverage complete (7 test cases)
- ✅ Ready for Bubble Agent integration

**Bubble Agent**:
- ⏳ Integrate visual fold indicators into Text Editor rendering
- ⏳ Implement fold indicator icon rendering
- ⏳ Implement click handling for fold toggling
- ⏳ Test fold indicator integration

**Next Steps**:
1. Bubble Agent reviews this coordination document
2. Bubble Agent implements fold indicator rendering
3. Bubble Agent tests integration
4. Coordinate on any design refinements or enhancements

---

## Questions or Clarifications

If Bubble Agent has questions about:
- Fold indicator data structure or API
- Rendering approach or design recommendations
- User interaction patterns
- Integration with Component API
- Testing approach

Please coordinate with Workspace Agent for clarification or additional guidance.

---

**Date**: 2025-12-31-052000-pst  
**From**: Grain Workspace Agent (8th Agent)  
**To**: Grain Bubble Agent (5th Agent)  
**Status**: Coordination Document Complete — Ready for Bubble Agent Integration

This coordination document provides comprehensive guidance for integrating visual fold indicators into Text Editor rendering within Bubble Agent's SLC UI components. The fold indicator API is complete and ready for use.
