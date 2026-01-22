# Core 1 Subcore Agent Summary - Campaign Website Project

**Date**: 2026-01-21  
**Context**: Pivot from Basin Kernel development to Svelte campaign website  
**Current Status**: Project setup complete, ready to run and debug

---

## 🎯 Current Mission/Task

**Primary Goal**: Get the campaign website running successfully and debug any errors that appear.

**Immediate Task**: 
- Run the Svelte campaign website from `/home/xy/ry/campaign-website/`
- Identify and fix any errors preventing the site from running
- User wants to submit screenshots of errors (easier in Cursor GUI than CLI)

**Context**: We've just installed nvm and npm (Node.js v24.13.0, npm v11.6.2), and the project is set up. User is seeing some errors and needs help debugging.

---

## 📋 Project Overview

### What We Built

A **fast, responsive Svelte 5 campaign website** for Keaton Livermore's 2026 California Governor race with:

1. **Custom Color Scheme**: Light/dark mode with colors inspired by campaign avatar image
   - Light mode: Off-white background, neon orange (#fc9206), seafoam green (#91ab06), sand beige (#aa903a), darker green-blues
   - Dark mode: Dark brown background, lighter purple-mauve-rose accents
   - Implemented via CSS custom properties with `prefers-color-scheme` and `data-theme` override

2. **Vision Page with Custom SVGs**: Full integration of campaign vision document
   - 6 custom SVG components illustrating permaculture, traditional urbanism, technology, job guarantee, regional optimization
   - All SVGs use CSS variables for automatic theme adaptation
   - Integrated directly into main `App.svelte` (no separate routing)

3. **Performance-First Architecture**:
   - Svelte 5 with runes mode
   - Vite for fast builds
   - Lazy loading utilities for images/embeds
   - Minimal JavaScript bundle
   - Inline SVGs for performance

4. **Theme Toggle Component**: ASCII `*` button that cycles Auto → Light → Dark → Auto
   - Saves preference to localStorage
   - Works with system preference

5. **Component Structure**:
   - Header with navigation
   - Hero section with "risk love" slogan
   - About section (stubbed)
   - Vision section (fully implemented with SVGs)
   - Platform section (stubbed)
   - Social links (stubbed)
   - Get Involved section (stubbed)
   - Footer

---

## 🗂️ Key Files & Paths

### Project Root
- **Base Directory**: `/home/xy/ry/campaign-website/`
- **Documentation**: `/home/xy/ry/docs/campaign/`

### Main Application Files
- **Entry Point**: `/home/xy/ry/campaign-website/src/main.js`
- **Main App**: `/home/xy/ry/campaign-website/src/App.svelte`
- **Global Styles**: `/home/xy/ry/campaign-website/src/app.css` (contains full color scheme)
- **HTML Template**: `/home/xy/ry/campaign-website/index.html`

### Components
- **Header**: `/home/xy/ry/campaign-website/src/lib/components/Header.svelte`
- **Footer**: `/home/xy/ry/campaign-website/src/lib/components/Footer.svelte`
- **Hero**: `/home/xy/ry/campaign-website/src/lib/components/Hero.svelte`
- **Theme Toggle**: `/home/xy/ry/campaign-website/src/lib/components/ThemeToggle.svelte`
- **Vision Components**: `/home/xy/ry/campaign-website/src/lib/components/vision/`
  - `VisionHero.svelte`
  - `PermacultureSection.svelte`
  - `TraditionalUrbanismSection.svelte`
  - `TechnologySection.svelte`
  - `JobGuaranteeSection.svelte`
  - `RegionalSection.svelte`

### Configuration
- **Package Config**: `/home/xy/ry/campaign-website/package.json`
- **Vite Config**: `/home/xy/ry/campaign-website/vite.config.js`
- **Svelte Config**: `/home/xy/ry/campaign-website/svelte.config.js`

### Documentation
- **Running Instructions**: `/home/xy/ry/docs/campaign/0007-running-instructions.md`
- **Complete Setup Guide**: `/home/xy/ry/docs/campaign/COMPLETE_SETUP_GUIDE.md`
- **Architecture**: `/home/xy/ry/docs/campaign/0001-website-architecture.md`
- **Color Scheme**: `/home/xy/ry/docs/campaign/0004-color-scheme-design.md`
- **Vision Design**: `/home/xy/ry/docs/campaign/0009-vision-page-design.md`

---

## 🛠️ Technical Stack

### Installed & Configured
- **nvm** (Node Version Manager): Installed at `~/.nvm/`
- **Node.js**: v24.13.0 (LTS) via nvm
- **npm**: v11.6.2 (comes with Node.js)

### Dependencies (from package.json)
- **Svelte**: ^5.0.0 (runes mode enabled)
- **Vite**: Latest (build tool)
- **@sveltejs/vite-plugin-svelte**: For Vite integration

### Build Configuration
- **Svelte Config**: `runes: true` (Svelte 5 runes mode)
- **Vite Config**: Includes minification, code splitting, chunk size warnings

---

## 🚀 How to Run

### Commands (from `/home/xy/ry/campaign-website/`)

```bash
# 1. Navigate to project
cd /home/xy/ry/campaign-website

# 2. If npm not found, load nvm first:
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# 3. Install dependencies (first time only)
npm install

# 4. Start development server
npm run dev
```

**Expected Output**: Vite dev server on http://localhost:5173

---

## 🐛 Common Issues to Check

### If npm/node not found:
- Load nvm: `export NVM_DIR="$HOME/.nvm" && [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"`
- Verify: `node --version` (should show v24.13.0)
- Verify: `npm --version` (should show 11.6.2)

### If dependencies missing:
- Run `npm install` from `/home/xy/ry/campaign-website/`
- Check `node_modules/` exists

### If build errors:
- Check all imports in `App.svelte` match actual component files
- Verify file paths are correct
- Check browser console for runtime errors

### If port conflicts:
- Vite will auto-select next available port
- Check terminal output for actual URL

---

## 📝 Recent Work Summary

### Last Few Days Timeline

1. **Pivot Decision**: User requested shift from Basin Kernel (RISC-V) development to campaign website
2. **Project Setup**: Created Svelte 5 project with Vite, configured for performance
3. **Color Scheme**: Designed light/dark mode palette based on campaign avatar image
4. **Component Development**: Built Header, Footer, Hero, ThemeToggle, and placeholder sections
5. **Vision Integration**: Adapted campaign vision document into 6 SVG-illustrated components
6. **Documentation**: Created comprehensive docs in `/home/xy/ry/docs/campaign/`
7. **npm Installation**: Just installed nvm and latest Node.js/npm for Ubuntu 24.04 LTS
8. **Current**: Ready to run, user seeing errors, needs debugging help

### Key Design Decisions

- **Svelte 5 over WebAssembly**: Chose Svelte for proven speed, battle-tested utility, alignment with RyeStyle principles (explicit types, compiled approach, small bundles)
- **No SvelteKit**: Using plain Svelte + Vite for simplicity and performance
- **Inline SVGs**: Custom illustrations embedded directly in components for performance
- **CSS Variables**: Full color scheme managed via CSS custom properties for dynamic theming
- **Direct Integration**: Vision page integrated into main App.svelte (no routing needed yet)
- **Performance First**: Lazy loading, minimal JS, optimized builds

---

## 🎨 Design Elements

### Color Variables (in app.css)
- Light mode: `--bg-primary`, `--text-primary`, `--accent-orange`, `--accent-green`, `--accent-beige`, `--accent-blue-green`
- Dark mode: `--bg-primary-dark`, `--text-primary-dark`, `--accent-purple-mauve`, etc.
- Uses `@media (prefers-color-scheme: dark)` with `:root:not([data-theme="light"])` logic
- Manual override via `data-theme="light"` or `data-theme="dark"` on `document.documentElement`

### SVG Integration
- All vision SVGs use CSS variables (e.g., `fill: var(--accent-orange)`)
- Automatically adapt to light/dark mode
- Inline in components (no external files for performance)

---

## 🔍 What to Look For When Debugging

1. **Console Errors**: Check browser dev tools console
2. **Build Errors**: Check terminal where `npm run dev` is running
3. **Import Errors**: Verify all component imports in `App.svelte` match actual files
4. **CSS Issues**: Check if color variables are defined correctly in `app.css`
5. **Svelte 5 Syntax**: Ensure using runes (`$state`, `$derived`, etc.) not old reactive syntax
6. **Vite Config**: Verify `vite.config.js` and `svelte.config.js` are correct

---

## 📚 Reference Documents

All documentation is in `/home/xy/ry/docs/campaign/`:
- `0001-website-architecture.md` - Architecture overview
- `0002-svelte-component-design.md` - Component design patterns
- `0004-color-scheme-design.md` - Color palette details
- `0005-performance-strategy.md` - Performance approach
- `0007-running-instructions.md` - Complete running guide
- `0009-vision-page-design.md` - Vision page implementation
- `0010-svg-illustration-guide.md` - SVG creation guide

---

## 🎯 Next Steps After Debugging

1. ✅ Get site running successfully
2. Replace stubs with real content
3. Add real social media links
4. Test performance (Lighthouse)
5. Deploy when ready

---

**User is ready to share screenshots of errors in Cursor GUI. Help debug and get the site running!**
