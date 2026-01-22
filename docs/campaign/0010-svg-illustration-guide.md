# SVG Illustration Guide

**Date**: 2026-01-21  
**Status**: Reference Guide

---

## Overview

Guide for creating custom SVGs that match the campaign vision content and color themes.

## SVG Best Practices

### Inline SVGs
- Always inline (no external files)
- Use CSS custom properties for colors
- Keep viewBox consistent
- Optimize paths

### Color Integration

Use CSS variables so SVGs automatically adapt to light/dark mode:

```svg
<circle fill="var(--color-primary)" />
<path stroke="var(--color-secondary)" />
```

### Fallbacks

Provide fallback colors for variables that might not exist:

```svg
<circle fill="var(--color-green-blue-accent, var(--color-secondary))" />
```

## Visual Concepts

### Permaculture Food Forests
- **Elements**: Layered circles (canopy/understory/ground), connecting lines (mycelium)
- **Colors**: Seafoam green, teal-green variations
- **Style**: Organic, interconnected, diverse

### Traditional Urbanism
- **Elements**: Geometric buildings, walls, streets, productive trees, water
- **Colors**: Sand beige, warm earth tones
- **Style**: Structured, human-scaled, permanent

### Technology Infrastructure
- **Elements**: Networked nodes, solar panels, robots, open-source symbols
- **Colors**: Primary orange, secondary green, info blue
- **Style**: Modern, connected, modular

### California Regions
- **Central Valley**: Fields, food forests, geometric patterns
- **Bay Area**: Urban skyline, buildings, tech
- **LA Basin**: Ocean, coast, marine elements

## SVG Structure Template

```svg
<svg viewBox="0 0 400 400" class="illustration-svg" aria-hidden="true">
  <defs>
    <!-- Gradients, patterns -->
  </defs>
  
  <!-- Background elements -->
  
  <!-- Main illustration -->
  
  <!-- Details/accents -->
</svg>
```

## Performance Tips

1. **Minimize paths** - Use simple shapes where possible
2. **Reuse elements** - Use `<g>` groups and transforms
3. **Optimize gradients** - Keep gradient definitions simple
4. **Remove metadata** - Strip unnecessary SVG metadata
5. **Use CSS** - Style with CSS, not inline attributes where possible

## Accessibility

- Always include `aria-hidden="true"` for decorative SVGs
- Provide text alternatives in surrounding content
- Ensure sufficient color contrast
- Test with screen readers

## Color Palette Reference

### Light Mode
- `--color-primary`: #fc9206 (Sunset orange)
- `--color-secondary`: #91ab06 (Seafoam green)
- `--color-tertiary`: #aa903a (Sand beige)
- `--color-green-blue-accent`: #4a7c6f (Teal accent)

### Dark Mode
- `--color-primary`: #ffa726 (Brighter orange)
- `--color-secondary`: #a5c94a (Brighter green)
- `--color-tertiary`: #c4a85a (Brighter beige)
- `--color-purple-rose-accent`: #b885a9 (Mauve accent)

## Examples

See implemented components:
- `VisionHero.svelte` - California landscape
- `PermacultureSection.svelte` - Food forest layers
- `TraditionalUrbanismSection.svelte` - Community layout
- `TechnologySection.svelte` - Infrastructure network
- `JobGuaranteeSection.svelte` - Work icons
- `RegionalSection.svelte` - Region icons
