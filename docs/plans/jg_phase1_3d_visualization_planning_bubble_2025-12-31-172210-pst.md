# Bubble Agent: JG Project Phase 1 (3D Visualization) Planning

**Date**: 2025-12-31-172210-pst  
**Agent**: Grain Bubble Agent (5th Agent)  
**Status**: Planning Document — Phase 1 Component Design Patterns  
**JG Project Design**: `docs/zyx/grainbank_mmt_job_guarantee_housing_program_2025-12-28-232324-pst.md`  
**Aurora Requirements**: `docs/plans/aurora_jg_project_requirements_2025-12-31-050600-pst.md`  
**Voice**: Grain Glow G2 (positive, first-principles, helpful, succinct yet complete)

---

## Executive Summary

This document outlines Bubble Agent's planning for **JG Project Phase 1: 3D Visualization Components** (Months 7-9). Bubble Agent is responsible for providing **design patterns, animations, and component variants** for 3D visualization components that Aurora Agent will implement using Dream Browser Component API.

**Bubble Agent Responsibilities**:
- Design patterns for 3D visualization components (layout, styling, interactions)
- Animation patterns for 3D visualization interactions (transitions, interactions, visual feedback)
- Component variant patterns (state/size/theme variants) for 3D visualization components
- Integration with Aurora Agent's Dream Browser Component API
- Coordination with Aurora Agent on component design requirements

**Timeline**: Months 7-9 (Phase 1 preparation: Months 1-6)

---

## JG Project Overview

**Program Vision**: Build beautiful, affordable, sustainable housing using fastest-growing renewable materials (hemp, bamboo, timber, rammed earth) through a federal Job Guarantee program that creates jobs, builds communities, and restores traditional urbanism principles.

**Bubble Agent Scope**: Design patterns and component variants for JG project UI components, integrated with Aurora Agent (browser-based components), Workspace Agent (desktop dashboards), and Carry Agent (mobile apps).

---

## Phase 1: 3D Visualization Components (Months 7-9)

### Component Types Required

Based on Aurora Agent's requirements, Bubble Agent needs to provide design patterns for:

#### 1. 3D Architectural Visualization Components

**Components**:
- Building structure visualization (walls, roofs, foundations, windows, doors)
- Material type visualization (hempcrete, LBL, CLT, rammed earth, brick, stone)
- Construction phase visualization (planning, foundation, framing, enclosure, finishing)
- Multi-story building visualization
- Building code compliance visualization (fire safety, accessibility, structural integrity)

**Design Pattern Requirements**:
- **Layout**: 3D canvas viewport with camera controls (pan, zoom, rotate)
- **Styling**: Material-specific color schemes (hempcrete = light brown, timber = wood grain, rammed earth = earth tones)
- **Interactions**: Hover states for building elements, click to select, drag to rotate camera
- **Animations**: Smooth camera transitions, material highlight animations, construction phase transitions
- **Component Variants**: 
  - State: `normal`, `hover`, `selected`, `disabled` (for building elements)
  - Size: `small` (mobile), `medium` (desktop), `large` (full-screen)
  - Theme: `light`, `dark`, `auto` (sync with browser theme)

#### 2. Site Layout Visualization Components

**Components**:
- Site plan visualization (property boundaries, building footprints, roads, canals, walls)
- Community layout visualization (mixed-use zones, walkable neighborhoods, productive landscapes)
- Material staging area visualization
- Worker flow visualization (construction site traffic patterns)
- Utility infrastructure visualization (fiber ethernet, water, graywater, power)

**Design Pattern Requirements**:
- **Layout**: Top-down 2D/3D hybrid view with zoom/pan controls
- **Styling**: Zone-specific color schemes (residential = blue, commercial = green, productive landscapes = brown/green)
- **Interactions**: Click to zoom, hover to show details, drag to pan
- **Animations**: Smooth zoom transitions, layer fade-in/fade-out, worker flow animations
- **Component Variants**:
  - State: `normal`, `hover`, `selected`, `loading` (for site elements)
  - Size: `small` (mobile), `medium` (desktop), `large` (full-screen)
  - Theme: `light`, `dark`, `auto`

#### 3. Material Quantity Visualization Components

**Components**:
- Material quantity calculations (tons, cubic yards, linear feet, square feet, blocks, bricks, boards)
- Batch tracking visualization (cultivation date, harvest date, processing date, expiration date)
- Material flow visualization (from cultivation → processing → construction)
- Regional sourcing visualization (cooperative locations, transportation routes)
- Inventory level visualization (reorder points, stock levels, quality certifications)

**Design Pattern Requirements**:
- **Layout**: Dashboard-style layout with charts, tables, and maps
- **Styling**: Material-specific color schemes, quantity-based color gradients (low = red, medium = yellow, high = green)
- **Interactions**: Click to filter, hover to show details, drag to reorder
- **Animations**: Quantity update animations, flow animation (material movement), loading states
- **Component Variants**:
  - State: `normal`, `hover`, `selected`, `loading`, `warning` (for inventory levels)
  - Size: `small` (mobile), `medium` (desktop), `large` (full-screen)
  - Theme: `light`, `dark`, `auto`

#### 4. Energy Efficiency Visualization Components

**Components**:
- Thermal mass visualization (passive heating/cooling, insulation, thermal bridges)
- Energy performance visualization (heating/cooling loads, ventilation, natural lighting)
- Carbon sequestration visualization (hemp, bamboo, timber carbon storage)
- Embodied energy visualization (material production, transportation, construction energy)
- Life cycle assessment visualization (LCA metrics, environmental impact)

**Design Pattern Requirements**:
- **Layout**: Heat map-style visualization with overlay controls
- **Styling**: Temperature-based color gradients (cold = blue, warm = red), efficiency-based colors (high = green, low = red)
- **Interactions**: Hover to show metrics, click to toggle layers, drag to adjust parameters
- **Animations**: Heat map animations, metric update animations, layer transition animations
- **Component Variants**:
  - State: `normal`, `hover`, `selected`, `loading`, `warning` (for efficiency metrics)
  - Size: `small` (mobile), `medium` (desktop), `large` (full-screen)
  - Theme: `light`, `dark`, `auto`

---

## Design Pattern Specifications

### Color Schemes

**JG Project Color Palette** (based on sustainable materials theme):

1. **Material Colors**:
   - Hempcrete: `#D4C4A8` (light brown, warm)
   - Timber/LBL: `#8B6F47` (wood brown, natural)
   - CLT: `#A0826D` (medium brown, structural)
   - Rammed Earth: `#C19A6B` (earth tone, warm)
   - Brick: `#B8860B` (terracotta, warm)
   - Stone: `#708090` (slate gray, cool)

2. **Functional Colors**:
   - Residential Zone: `#4A90E2` (blue, calm)
   - Commercial Zone: `#50C878` (green, active)
   - Productive Landscape: `#8B7355` (brown-green, natural)
   - Infrastructure: `#708090` (gray, utility)

3. **Status Colors**:
   - High Inventory: `#50C878` (green, good)
   - Medium Inventory: `#FFD700` (yellow, warning)
   - Low Inventory: `#FF6B6B` (red, urgent)
   - Efficient: `#50C878` (green, good)
   - Inefficient: `#FF6B6B` (red, warning)

4. **Theme Adaptations**:
   - Light Theme: Full color palette as above
   - Dark Theme: Darken base colors by 30%, adjust brightness
   - Auto Theme: Follow system preference (light/dark)

### Spacing Schemes

**JG Project Spacing System** (aligned with existing SLC spacing):

- **3D Viewport Padding**: `16px` (small), `24px` (medium), `32px` (large)
- **Component Gaps**: `8px` (small), `12px` (medium), `16px` (large)
- **Control Panel Padding**: `12px` (small), `16px` (medium), `24px` (large)
- **Chart/Graph Margins**: `16px` (small), `24px` (medium), `32px` (large)

### Typography Schemes

**JG Project Typography** (readable, professional):

- **3D Viewport Labels**: `14px` (small), `16px` (medium), `18px` (large) — sans-serif, bold
- **Control Panel Text**: `12px` (small), `14px` (medium), `16px` (large) — sans-serif, regular
- **Dashboard Headings**: `18px` (small), `24px` (medium), `32px` (large) — sans-serif, bold
- **Dashboard Body Text**: `12px` (small), `14px` (medium), `16px` (large) — sans-serif, regular

### Animation Patterns

**JG Project Animation System** (smooth, informative):

1. **Camera Transitions**:
   - Type: `slide` (smooth pan/zoom)
   - Duration: `300ms` (quick), `500ms` (smooth), `700ms` (slow)
   - Easing: `ease-in-out` (natural motion)

2. **Material Highlights**:
   - Type: `fade` (opacity change)
   - Duration: `200ms` (quick feedback)
   - Easing: `ease-out` (snappy)

3. **Construction Phase Transitions**:
   - Type: `slide` + `fade` (combined)
   - Duration: `400ms` (smooth transition)
   - Easing: `ease-in-out` (natural)

4. **Quantity Updates**:
   - Type: `scale` (brief pulse)
   - Duration: `300ms` (attention-grabbing)
   - Easing: `ease-out` (snappy)

5. **Loading States**:
   - Type: `fade` (pulse animation)
   - Duration: `1000ms` (slow, continuous)
   - Easing: `linear` (consistent)

---

## Component Variant Patterns

### State Variants

**JG 3D Visualization Component States**:

1. **`normal`**: Default state, component is interactive
2. **`hover`**: Mouse hover state, show additional details
3. **`selected`**: Component is selected, highlight with accent color
4. **`disabled`**: Component is disabled, reduce opacity to 50%
5. **`loading`**: Component is loading data, show loading animation
6. **`warning`**: Component has warning state (low inventory, inefficiency), show warning color
7. **`error`**: Component has error state, show error color

### Size Variants

**JG 3D Visualization Component Sizes**:

1. **`small`**: Mobile viewport (320px-768px width)
   - Reduced padding, smaller fonts, compact controls
   - Simplified 3D view (lower detail, fewer elements)
   - Stacked layout (vertical arrangement)

2. **`medium`**: Desktop viewport (768px-1920px width)
   - Standard padding, medium fonts, standard controls
   - Full 3D view (standard detail, all elements)
   - Side-by-side layout (horizontal arrangement)

3. **`large`**: Full-screen viewport (1920px+ width)
   - Increased padding, larger fonts, expanded controls
   - Enhanced 3D view (high detail, all elements + overlays)
   - Multi-panel layout (complex arrangements)

### Theme Variants

**JG 3D Visualization Component Themes**:

1. **`light`**: Light theme (white/light gray background, dark text)
2. **`dark`**: Dark theme (dark gray/black background, light text)
3. **`auto`**: Follow system preference (sync with browser theme)

---

## Integration with Aurora Agent

### Dream Browser Component API Integration

**Integration Pattern**: Bubble Agent's design patterns integrate with Aurora Agent's Dream Browser Component API:

1. **Component Structure**: Aurora Agent implements components using `DreamBrowserComponentAPI`, Bubble Agent provides design patterns for styling these components

2. **Theme Synchronization**: Bubble Agent's theme variants sync with browser theme via `browser_api.set_theme_all(theme)`

3. **Component Variants**: Bubble Agent's state/size/theme variants map to `ComponentState`, `ComponentSize`, `ComponentTheme` in Dream Browser Component API

4. **Rendering Approach**: 
   - DOM for UI controls (Bubble Agent's design patterns)
   - WebGL for 3D visualization (Aurora Agent's implementation)
   - Canvas for 2D overlays (hybrid approach)

### Coordination Points

**What Bubble Agent Provides**:
- Design pattern specifications (color schemes, spacing, typography)
- Animation specifications (types, durations, easing)
- Component variant specifications (state/size/theme)
- CSS generation utilities (if needed for DOM-based UI controls)
- Integration examples (how to apply patterns to Dream Browser components)

**What Bubble Agent Needs from Aurora Agent**:
- Component implementation feedback (design pattern usability)
- Performance requirements (animation smoothness, rendering efficiency)
- Accessibility requirements (keyboard navigation, screen reader support)
- Browser-specific considerations (WebGL support, Canvas performance)

---

## JG-Specific Component Module Structure

### Proposed Module: `jg_ui_components.zig`

**Purpose**: JG-specific UI components module that extends SLC UI components with JG project-specific design patterns and component types.

**Structure**:
```zig
src/grain_bubble/
└── jg_ui_components.zig  # JG-specific UI components
```

**Component Types**:
1. **JG 3D Visualization Components**: Design patterns for 3D architectural visualization
2. **JG Site Layout Components**: Design patterns for site layout visualization
3. **JG Material Quantity Components**: Design patterns for material quantity visualization
4. **JG Energy Efficiency Components**: Design patterns for energy efficiency visualization

**Design Patterns**:
1. **JG Color Schemes**: Material colors, functional colors, status colors, theme adaptations
2. **JG Spacing Schemes**: 3D viewport padding, component gaps, control panel padding
3. **JG Typography Schemes**: 3D viewport labels, control panel text, dashboard headings
4. **JG Animation Patterns**: Camera transitions, material highlights, construction phase transitions, quantity updates, loading states

**Integration**:
- Extends `slc_ui_components.zig` (reuses base component structures)
- Integrates with `aurora_integration.zig` (applies patterns to Dream Browser components)
- Uses existing design pattern infrastructure (DesignPattern, Animation, Component variants)

---

## Implementation Plan

### Preparation Phase (Months 1-6)

**Bubble Agent Actions**:
- ✅ Review JG project design document (`docs/zyx/grainbank_mmt_job_guarantee_housing_program_2025-12-28-232324-pst.md`)
- ✅ Review Aurora Agent requirements (`docs/plans/aurora_jg_project_requirements_2025-12-31-050600-pst.md`)
- ✅ Review Aurora Agent coordination document (component API design received, 2025-12-30-123545-pst)
- ✅ Create JG Phase 1 planning document (this document)
- ⏳ Design JG-specific color schemes (material colors, functional colors, status colors)
- ⏳ Design JG-specific spacing schemes (3D viewport, component gaps, control panels)
- ⏳ Design JG-specific typography schemes (labels, text, headings)
- ⏳ Design JG-specific animation patterns (camera, highlights, transitions, updates, loading)
- ⏳ Plan JG-specific component module structure (`jg_ui_components.zig`)
- ⏳ Coordinate with Aurora Agent on design pattern requirements (Months 7-9)

### Phase 1 Implementation (Months 7-9)

**Tasks**:
- [ ] Implement JG-specific design patterns (`jg_ui_components.zig`)
  - [ ] JG color schemes (material, functional, status, theme adaptations)
  - [ ] JG spacing schemes (viewport, component gaps, control panels)
  - [ ] JG typography schemes (labels, text, headings)
  - [ ] JG animation patterns (camera, highlights, transitions, updates, loading)
- [ ] Implement JG 3D visualization component design patterns
  - [ ] 3D architectural visualization patterns
  - [ ] Site layout visualization patterns
  - [ ] Material quantity visualization patterns
  - [ ] Energy efficiency visualization patterns
- [ ] Implement component variant patterns (state/size/theme)
- [ ] Integrate with Aurora Agent's Dream Browser Component API
- [ ] Add comprehensive tests
- [ ] Update documentation

**Deliverables**:
- JG-specific UI components module (`src/grain_bubble/jg_ui_components.zig`)
- Design pattern specifications (color, spacing, typography, animation)
- Component variant specifications (state/size/theme)
- Integration with Aurora Agent (Dream Browser Component API)
- Tests (`tests/jg_ui_components_test.zig`)
- Documentation (design pattern usage, integration guide)

---

## Dependencies

### Required Dependencies

- **SLC UI Components**: `src/grain_bubble/slc_ui_components.zig` ✅ Complete
- **Aurora Integration**: `src/grain_bubble/aurora_integration.zig` ✅ Complete
- **Dream Browser Component API**: Available via Aurora Agent ✅ Complete

### Pending Dependencies

- **Core Agent JG Module APIs**: API contracts for JG modules (Month 6+, not blocking design pattern work)
- **Aurora Agent Component Implementation Feedback**: Design pattern usability feedback (Months 7-9)

---

## Grain Style Requirements

### Code Style

- All functions use `grain_case` naming
- Bounded allocations: Fixed-size arrays for spans and strings
- Minimum 2 assertions per function
- Max 70 lines per function
- Max 103 characters per line (graincard compatibility)
- All compiler warnings enabled
- Explicit types (`u32`/`u64`, no `usize`)

### Component Style

- Follow SLC UI components patterns (component structure, variants, design patterns)
- Integrate with Aurora Agent's Dream Browser Component API
- Optimize for performance (efficient rendering, smooth animations)
- Ensure accessibility (keyboard navigation, screen reader support, ARIA labels, color contrast)

---

## Success Criteria

### Preparation Phase (Months 1-6)

- ✅ JG project design document reviewed
- ✅ Aurora Agent requirements reviewed
- ✅ JG Phase 1 planning document created
- ⏳ JG-specific design patterns designed (color, spacing, typography, animation)
- ⏳ JG-specific component module structure planned
- ⏳ Coordination with Aurora Agent initiated

### Phase 1 Implementation (Months 7-9)

- ⏳ JG-specific design patterns implemented
- ⏳ JG 3D visualization component design patterns implemented
- ⏳ Component variant patterns implemented
- ⏳ Integration with Aurora Agent complete
- ⏳ Comprehensive tests added
- ⏳ Documentation complete

---

## Next Steps

**Immediate** (Preparation Phase, Months 1-6):
1. Design JG-specific color schemes (material colors, functional colors, status colors, theme adaptations)
2. Design JG-specific spacing schemes (3D viewport, component gaps, control panels)
3. Design JG-specific typography schemes (labels, text, headings)
4. Design JG-specific animation patterns (camera, highlights, transitions, updates, loading)
5. Plan JG-specific component module structure (`jg_ui_components.zig`)
6. Coordinate with Aurora Agent on design pattern requirements (when Aurora Agent begins Phase 1, Month 7)

**Short-term** (Phase 1 Implementation, Months 7-9):
1. Implement JG-specific design patterns
2. Implement JG 3D visualization component design patterns
3. Integrate with Aurora Agent's Dream Browser Component API
4. Complete Phase 1 deliverables

**Medium-term** (Phase 2, Months 10-11):
1. Design dashboard component patterns (project management, task tracking, inventory, supply chain)
2. Integrate with Workspace Agent desktop dashboards

**Long-term** (Phase 3, Month 12):
1. Design mobile UI component patterns (worker app, resident app, cooperative app)
2. Integrate with Carry Agent mobile apps

---

**Status**: Planning phase complete. Ready for design pattern specification (Months 1-6) and implementation (Months 7-9).
