# Vision Page Design

**Date**: 2026-01-21  
**Status**: Implemented  
**Goal**: Fast, visually compelling layout that tells the campaign vision story

---

## Overview

The Vision page adapts Reya's comprehensive campaign vision document into a fast, beautiful website layout using custom SVGs that match our color themes.

## Design Principles

1. **Fast Loading** - Inline SVGs, no external images
2. **Visual Storytelling** - SVGs illustrate key concepts
3. **Color Integration** - Uses our sunset orange, seafoam green, sand beige palette
4. **Progressive Enhancement** - Core content first, visuals enhance
5. **Responsive** - Works on all screen sizes

## Page Structure

### 1. Vision Hero
- **SVG**: California landscape with sunset, mountains, permaculture food forest pattern
- **Colors**: Sunset gradient (orange → green → beige), green-blue mountains
- **Message**: "The Aspiring Beauty - A California Vision"

### 2. Permaculture Section
- **SVG**: Food forest layers (canopy, understory, ground cover, mycelium network)
- **Colors**: Seafoam green, teal-green variations
- **Content**: Regeneration, diversity, community

### 3. Traditional Urbanism Section
- **SVG**: Community layout with walls, buildings, streets, productive trees, water features
- **Colors**: Sand beige, warm tones
- **Content**: Human-scaled, local materials, productive beauty

### 4. Technology Section
- **SVG**: Local compute clusters (networked nodes), solar panels, autonomous robot, open-source symbol
- **Colors**: Primary orange, secondary green, info blue
- **Content**: Fair-trade infrastructure, community ownership

### 5. Job Guarantee Section
- **SVGs**: Four work icons (farming, construction, technology, education)
- **Colors**: Each card uses different accent color
- **Content**: Types of meaningful work

### 6. Regional Section
- **SVGs**: Three region icons (Central Valley fields, Bay Area urban, LA Basin ocean)
- **Colors**: Region-specific color accents
- **Content**: Regional optimization for each area

## SVG Design Approach

### Inline SVGs
- All SVGs are inline (no external files)
- Use CSS custom properties for colors
- Automatically adapt to light/dark mode
- Minimal file size

### Color Integration
- **Sunset Orange** (`--color-primary`): Energy, innovation, California sunsets
- **Seafoam Green** (`--color-secondary`): Permaculture, regeneration, sustainability
- **Sand Beige** (`--color-tertiary`): Traditional urbanism, earth, permanence
- **Green-Blues** (light mode): Depth, environmental focus
- **Purple-Mauve-Rose** (dark mode): Warmth, sophistication

### Visual Metaphors
- **Food Forests**: Layered circles (canopy/understory/ground), connecting lines (mycelium)
- **Urbanism**: Geometric buildings, walls, productive trees, water canals
- **Technology**: Networked nodes, solar panels, modular robots
- **Regions**: Iconic landscapes (valley fields, urban skyline, ocean coast)

## Performance

### Optimizations
- ✅ Inline SVGs (no HTTP requests)
- ✅ CSS custom properties (automatic theme switching)
- ✅ Minimal DOM (simple shapes)
- ✅ No JavaScript for visuals (pure CSS/SVG)
- ✅ Lazy loading for any future images

### File Size
- Each SVG: ~1-3KB (text)
- Total SVG content: ~15-20KB
- Much smaller than equivalent images

## Responsive Design

### Desktop
- Side-by-side layouts (text + illustration)
- Full-width hero
- Grid layouts for cards

### Mobile
- Stacked layouts
- Illustrations above text
- Single column cards
- Smaller SVG sizes

## Accessibility

- All SVGs have `aria-hidden="true"` (decorative)
- Text content is separate (screen reader accessible)
- High contrast colors
- Focus states on interactive elements

## Future Enhancements

Could add:
- Animated SVGs (CSS animations)
- Interactive elements (hover states)
- More detailed illustrations
- Regional map of California
- Timeline visualization

## Implementation

All components are in `src/lib/components/vision/`:
- `VisionHero.svelte`
- `PermacultureSection.svelte`
- `TraditionalUrbanismSection.svelte`
- `TechnologySection.svelte`
- `JobGuaranteeSection.svelte`
- `RegionalSection.svelte`

The main page is at `src/routes/vision/+page.svelte` (or can be integrated into main App.svelte).

## Color Usage in SVGs

### Light Mode
- Primary: Sunset orange for energy/innovation
- Secondary: Seafoam green for permaculture
- Tertiary: Sand beige for urbanism
- Green-Blues: Environmental depth

### Dark Mode
- Brighter versions of primary/secondary
- Purple-Mauve-Rose: Warmth and sophistication
- Higher contrast for visibility

All colors automatically switch via CSS custom properties!
