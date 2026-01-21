# Campaign Website Performance Strategy

**Date**: 2026-01-21  
**Status**: Strategy Phase  
**Goal**: Fast, responsive site that appeals to general audience

---

## Core Principles

1. **Performance First** - Fast loading is non-negotiable
2. **Progressive Enhancement** - Core content loads fast, enhancements layer on
3. **Visual Appeal** - Don't sacrifice aesthetics for speed
4. **Smart Lazy Loading** - Load heavy content only when needed

## Performance Targets

- **First Contentful Paint (FCP)**: < 1.0s
- **Largest Contentful Paint (LCP)**: < 2.5s
- **Time to Interactive (TTI)**: < 3.5s
- **Cumulative Layout Shift (CLS)**: < 0.1
- **Total Bundle Size**: < 100KB (initial load)

## Strategy Overview

### 1. Core Content (Fast Path)
- HTML/CSS/JS: Minimal, optimized
- Custom SVGs: Inline or sprite sheets
- Typography: System fonts initially, web fonts as enhancement
- No blocking resources

### 2. Enhanced Content (Progressive)
- Images: Lazy loaded, WebP/AVIF with fallbacks
- Videos: Thumbnail placeholders, YouTube embeds on demand
- Social embeds: Load on scroll/click
- Web fonts: Load asynchronously

### 3. Heavy Content (On Demand)
- Full videos: YouTube links (external)
- Social feeds: Link out, don't embed
- Rich media: Load only when user requests

## Implementation Plan

### Phase 1: Fast Foundation

**HTML Structure:**
- Semantic HTML5
- Minimal initial markup
- Critical CSS inlined
- Defer non-critical CSS

**CSS Strategy:**
- Critical CSS: ~10KB inline
- Non-critical: Load asynchronously
- Use CSS custom properties (already done)
- Minimize specificity

**JavaScript:**
- Vanilla JS where possible
- Svelte compiles to minimal JS
- Code splitting for routes
- No framework bloat

### Phase 2: Smart Media Loading

**Images:**
- Custom SVGs for icons, illustrations
- WebP/AVIF with JPEG fallback
- Responsive images (`srcset`, `sizes`)
- Lazy loading (`loading="lazy"`)
- Blur-up placeholders (low-res base64)

**Videos:**
- Thumbnail images as placeholders
- Click to load YouTube embed
- Or link directly to YouTube
- No autoplay, no preload

**SVGs:**
- Inline for critical icons
- Sprite sheet for common icons
- Custom illustrations as SVGs
- Optimize with SVGO

### Phase 3: Social Media Strategy

**Option A: Simple Links (Recommended)**
- Text/icon links to platforms
- No embeds, no widgets
- Fastest, most reliable
- User controls experience

**Option B: Lazy Embeds**
- Load embeds on scroll
- Use lightweight libraries
- Fallback to links if slow

**Platforms to Link:**
- YouTube (video content)
- TikTok (short videos)
- Twitter/X (updates)
- Threads (conversations)
- Bluesky (decentralized)
- Nostr (protocol)
- Instagram (visuals)
- Facebook (reach)

**Management:**
- Single source of truth (CMS or config file)
- Volunteer/staff can update links
- Automated posting tools (Buffer, etc.)
- Analytics to track engagement

## Technical Implementation

### Image Optimization

```html
<!-- Responsive image with lazy loading -->
<picture>
  <source srcset="image.avif" type="image/avif">
  <source srcset="image.webp" type="image/webp">
  <img 
    src="image.jpg" 
    alt="Description"
    loading="lazy"
    decoding="async"
    width="800"
    height="600"
  >
</picture>
```

### SVG Strategy

```html
<!-- Inline SVG for critical icons -->
<svg width="24" height="24" aria-hidden="true">
  <use href="#icon-name"></use>
</svg>

<!-- Sprite sheet for common icons -->
<svg style="display:none">
  <symbol id="icon-name">...</symbol>
</svg>
```

### Video Placeholder

```html
<!-- Thumbnail with play button -->
<div class="video-placeholder" data-youtube-id="abc123">
  <img src="thumbnail.jpg" alt="Video title" loading="lazy">
  <button class="play-button" aria-label="Play video">
    <svg>...</svg>
  </button>
</div>
```

### Social Links Component

```svelte
<!-- Simple, fast social links -->
<div class="social-links">
  <a href="https://youtube.com/@..." target="_blank" rel="noopener">
    <svg>YouTube icon</svg>
    <span>YouTube</span>
  </a>
  <!-- Repeat for other platforms -->
</div>
```

## Content Strategy

### What Goes Fast Path
- Hero section (text + SVG)
- Campaign message
- Key platform points
- Call-to-action buttons
- Navigation

### What Loads Progressively
- Photo gallery (lazy load)
- Video thumbnails
- Testimonials
- News/blog posts
- Social proof

### What Links Out
- Full videos → YouTube
- Long-form content → Blog
- Social engagement → Platform pages
- Donations → Payment processor

## Team Management

### Content Updates
- **CMS or Config File**: Single source of truth
- **Git-based**: Version control, easy rollback
- **Markdown**: Easy for volunteers to edit
- **Automated Build**: Deploy on update

### Social Media Management
- **Content Calendar**: Plan posts ahead
- **Cross-posting Tools**: Buffer, Hootsuite
- **Volunteer Roles**: 
  - Content creators
  - Social media managers
  - Video editors
  - Graphics designers

### Performance Monitoring
- **Lighthouse CI**: Automated performance checks
- **Real User Monitoring**: Track actual performance
- **Budget Alerts**: Warn if bundle size grows

## Recommendations

### Do
✅ Use custom SVGs for illustrations  
✅ Lazy load images and videos  
✅ Link to YouTube instead of embedding  
✅ Use system fonts initially  
✅ Progressive enhancement  
✅ Monitor performance continuously  

### Don't
❌ Autoplay videos  
❌ Load all social embeds upfront  
❌ Use heavy web fonts initially  
❌ Block rendering with JS  
❌ Load full images on mobile  
❌ Embed social feeds directly  

## Success Metrics

- **Performance**: Lighthouse score > 90
- **User Experience**: Low bounce rate, high engagement
- **Content**: Videos get views (on YouTube)
- **Social**: Links drive traffic to platforms
- **Maintenance**: Easy for team to update

## Next Steps

1. Implement lazy loading for images
2. Create SVG icon system
3. Build video placeholder component
4. Design social links component
5. Set up performance monitoring
6. Create content management workflow
