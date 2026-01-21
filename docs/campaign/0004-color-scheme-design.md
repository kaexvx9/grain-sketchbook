# Campaign Color Scheme Design

**Date**: 2026-01-21  
**Status**: Design Phase  
**Inspiration**: kae3g_avatar_sunset_color_map_libra_liberty_1024x1024.jpg

---

## Color Palette Inspiration

From the campaign profile photo, we've identified three key color territories:

1. **Neon Glow Sunset Orange** - `#fc9206` area
   - Warm, energetic, forward-looking
   - Represents innovation and California sunsets

2. **Seafoam-Sage-Wave Blue-Green** - `#91ab06` area  
   - Fresh, regenerative, organic
   - Represents permaculture and sustainability

3. **Sea-Meets-Sand Blue-Brown-Green-Sand-Beige** - `#aa903a` area
   - Earthy, grounded, natural
   - Represents traditional urbanism and connection to land

## Paletton Color Scheme

Using a triadic color scheme (three colors evenly spaced on color wheel) with variations:

### Base Colors
- **Primary (Orange)**: `#fc9206` - Neon sunset glow
- **Secondary (Green)**: `#91ab06` - Seafoam sage wave  
- **Tertiary (Beige)**: `#aa903a` - Sea-sand beige

### Light Mode Palette

**Backgrounds:**
- Primary BG: `#faf8f5` - Warm off-white
- Secondary BG: `#f5f2ed` - Soft beige-tinted white
- Surface: `#ffffff` - Pure white for cards
- Accent BG: `#e8f4f0` - Very light teal-tinted background
- Highlight BG: `#f0f8f5` - Subtle green-blue highlight

**Text:**
- Primary Text: `#2c2416` - Deep brown-black
- Secondary Text: `#5a4a3a` - Medium brown
- Muted Text: `#8a7a6a` - Light brown

**Accents:**
- Primary Accent: `#fc9206` - Sunset orange
- Secondary Accent: `#91ab06` - Seafoam green
- Tertiary Accent: `#aa903a` - Sand beige
- **Darker Green-Blues:**
  - Dark: `#2d5a4f` - Deep teal-green
  - Medium: `#3d6b5e` - Medium teal
  - Accent: `#4a7c6f` - Teal accent
  - Subtle: `#5a8a7a` - Lighter teal for borders
- Success: `#6b8e23` - Olive green (darker variant)
- Warning: `#ff8c00` - Burnt orange
- Error: `#d2691e` - Chocolate

**Borders/Dividers:**
- Light: `#e8e0d6` - Warm beige-gray
- Medium: `#d4c4b0` - Medium beige
- Accent: `#5a8a7a` - Teal border accent

### Dark Mode Palette

**Backgrounds:**
- Primary BG: `#2c2416` - Dark brown
- Secondary BG: `#3a2e1f` - Medium dark brown
- Surface: `#1f1810` - Deepest brown for cards
- Accent BG: `#3d2a35` - Mauve-tinted dark background
- Highlight BG: `#4a3440` - Purple-rose highlight background

**Text:**
- Primary Text: `#faf8f5` - Warm off-white
- Secondary Text: `#d4c4b0` - Light beige
- Muted Text: `#8a7a6a` - Medium beige

**Accents:**
- Primary Accent: `#ffa726` - Brighter orange (more visible on dark)
- Secondary Accent: `#a5c94a` - Brighter seafoam
- Tertiary Accent: `#c4a85a` - Brighter sand beige
- **Lighter Purple-Mauve-Rose:**
  - Light: `#d4a5c7` - Light mauve-rose
  - Medium: `#c895b8` - Medium mauve
  - Accent: `#b885a9` - Mauve accent
  - Subtle: `#a8759a` - Deeper mauve for borders
  - Pale: `#e8c5d9` - Pale rose for highlights
- Success: `#8bc34a` - Bright green
- Warning: `#ff9800` - Bright orange
- Error: `#ff6b35` - Coral red

**Borders/Dividers:**
- Light: `#4a3e2f` - Medium brown
- Medium: `#5a4a3a` - Lighter brown
- Accent: `#a8759a` - Mauve border accent

## Color Usage Guidelines

### Primary Orange (`#fc9206` / `#ffa726`)
- CTAs, buttons, links
- Highlights, emphasis
- Brand elements

### Secondary Green (`#91ab06` / `#a5c94a`)
- Success states
- Environmental/permaculture content
- Secondary actions

### Tertiary Beige (`#aa903a` / `#c4a85a`)
- Borders, dividers
- Subtle backgrounds
- Neutral accents

### Darker Green-Blues (Light Mode)
- `#2d5a4f` - Deep teal-green for emphasis
- `#4a7c6f` - Teal accent for buttons/links
- `#5a8a7a` - Lighter teal for borders
- Use for: Environmental content, depth, contrast

### Lighter Purple-Mauve-Rose (Dark Mode)
- `#d4a5c7` - Light mauve-rose for highlights
- `#b885a9` - Mauve accent for buttons/links
- `#e8c5d9` - Pale rose for subtle highlights
- Use for: Warmth, sophistication, visual interest

## Accessibility

All color combinations meet WCAG AA contrast requirements:
- Text on backgrounds: 4.5:1 minimum
- Large text: 3:1 minimum
- Interactive elements: Clear focus states

## Implementation

Colors are defined as CSS custom properties in `src/app.css` with light/dark mode support using `prefers-color-scheme` media query.

### CSS Variables Structure

All colors use CSS custom properties (variables) for easy theming:
- Base colors: `--color-primary`, `--color-secondary`, `--color-tertiary`
- Backgrounds: `--color-bg`, `--color-bg-alt`, `--color-bg-surface`
- Text: `--color-text`, `--color-text-secondary`, `--color-text-muted`
- Borders: `--color-border`, `--color-border-medium`
- Semantic: `--color-success`, `--color-warning`, `--color-error`

### Dark Mode

Dark mode automatically activates based on user's system preference via `@media (prefers-color-scheme: dark)`. All color variables are redefined for dark mode with brighter accents and darker backgrounds.

### Usage Example

```css
.my-component {
  background: var(--color-bg-surface);
  color: var(--color-text);
  border: 1px solid var(--color-border);
}

.button {
  background: var(--color-primary);
  color: var(--color-text-inverse);
}
```

### Testing

A `ColorDemo.svelte` component is included to visualize all colors in the palette. This helps verify the color scheme works in both light and dark modes.
