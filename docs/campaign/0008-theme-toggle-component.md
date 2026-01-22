# Theme Toggle Component

**Date**: 2026-01-21  
**Status**: Implemented  
**Inspiration**: `/home/xy/github/kae3g/12025-10/web-app/src/lib/ThemeToggle.svelte`

---

## Overview

A minimal, elegant theme toggle using ASCII `*` character as a clickable button. Inspired by the previous project's clean design.

## Features

- **ASCII Button**: Uses `*` character (simple, elegant)
- **Three-State Toggle**: Cycles through Auto → Light → Dark → Auto
- **System Preference**: Respects `prefers-color-scheme` when in Auto mode
- **Manual Override**: User can explicitly set Light or Dark
- **Persistent**: Saves preference to localStorage
- **Responsive**: Adjusts position for mobile devices
- **Accessible**: Proper ARIA labels and keyboard support

## Usage

```svelte
<script>
  import ThemeToggle from './lib/components/ThemeToggle.svelte';
</script>

<ThemeToggle />
```

## Behavior

### Theme States

1. **Auto** (default)
   - Follows system preference
   - Updates when system preference changes
   - Shows current effective theme in tooltip

2. **Light**
   - Forces light mode
   - Overrides system preference

3. **Dark**
   - Forces dark mode
   - Overrides system preference

### Toggle Cycle

Clicking the `*` button cycles:
```
Auto → Light → Dark → Auto
```

## Implementation Details

### CSS Variables

The component works with CSS custom properties:
- Light mode: Uses default `:root` variables
- Dark mode: Uses `:root[data-theme="dark"]` variables
- System preference: Uses `@media (prefers-color-scheme: dark)` with `:not([data-theme="light"])` to allow manual override

### Positioning

- **Desktop**: Fixed at top-right, aligned with content container
- **Mobile**: Adjusts to top-right corner, below header if needed
- **Responsive**: Uses `max()` CSS function for smart positioning

### Styling

- Font: Times New Roman (serif, elegant)
- Size: 28px desktop, 24px mobile
- Hover: Scales to 1.2x, changes color to primary
- Active: Scales to 1.1x
- Opacity: 0.6 default, 1.0 on hover

## Accessibility

- `aria-label`: "Toggle theme"
- `title`: Dynamic tooltip showing current state
- Keyboard accessible (focus styles)
- High contrast on hover

## Technical Notes

### localStorage Key
- Key: `'theme'`
- Values: `'auto'`, `'light'`, `'dark'`

### DOM Attributes
- `data-theme="dark"`: Applied when dark mode is active
- `data-theme="light"`: Applied when light mode is explicitly set
- No attribute: Auto mode (follows system)

### System Preference Listener
- Listens to `matchMedia('(prefers-color-scheme: dark)')` changes
- Updates automatically when system preference changes (in Auto mode)

## Future Enhancements

Could add:
- `%` button for palette toggle (warm/cold) if needed
- Animation on theme change
- Visual indicator of current state
- Keyboard shortcut support

## Inspiration

Based on the elegant design from `/home/xy/github/kae3g/12025-10`:
- Simple ASCII character buttons
- Fixed positioning at top-right
- Minimal, unobtrusive design
- Responsive adjustments
