# Svelte Component Design

**Date**: 2026-01-21  
**Status**: Design Phase

---

## Component Philosophy

Following RyeStyle principles:
- **Explicit props** - No hidden state
- **Bounded complexity** - Clear component boundaries
- **Composable** - Small, reusable pieces
- **Performant** - Leverage Svelte's compiled optimizations

## Core Components

### Layout Components

- `Layout.svelte` - Main page wrapper
- `Header.svelte` - Navigation header
- `Footer.svelte` - Site footer
- `Container.svelte` - Content container with max-width

### Content Components

- `Hero.svelte` - Hero section with "risk love" slogan
- `Section.svelte` - Content section wrapper
- `Card.svelte` - Content card component
- `Button.svelte` - Styled button component
- `TextBlock.svelte` - Typography wrapper

### Campaign-Specific

- `VisionBlock.svelte` - Vision statement display
- `PlatformItem.svelte` - Platform policy item
- `BioCard.svelte` - Candidate bio card
- `ContactForm.svelte` - Contact/volunteer form

## State Management

Use Svelte stores for:
- Navigation state
- Form state
- Theme/preferences (if needed)

Keep it minimal - Svelte's reactivity handles most cases.

## Styling Approach

- CSS modules or scoped styles
- Design tokens for consistency
- Responsive utilities
- Accessible focus states

## Component Example Structure

```svelte
<script>
  // Explicit props
  export let title: string;
  export let subtitle: string = '';
  
  // Local state (explicit)
  let isExpanded = false;
</script>

<div class="component">
  <h2>{title}</h2>
  {#if subtitle}
    <p>{subtitle}</p>
  {/if}
</div>

<style>
  .component {
    /* Scoped styles */
  }
</style>
```
