# Complete Setup Guide - Campaign Website

**Date**: 2026-01-21  
**Status**: Ready to Run  
**Node.js**: v24.13.0 (via nvm)  
**npm**: v11.6.2

---

## ✅ Prerequisites Installed

- **nvm** (Node Version Manager) - ✅ Installed at `~/.nvm/`
- **Node.js** v24.13.0 (LTS) - ✅ Installed via nvm
- **npm** v11.6.2 - ✅ Installed with Node.js

## 📍 Important Paths

- **Project Directory**: `/home/xy/ry/campaign-website/`
- **Documentation**: `/home/xy/ry/docs/campaign/`
- **Main App**: `/home/xy/ry/campaign-website/src/App.svelte`
- **Components**: `/home/xy/ry/campaign-website/src/lib/components/`
- **Vision SVGs**: `/home/xy/ry/campaign-website/src/lib/components/vision/`
- **Styles**: `/home/xy/ry/campaign-website/src/app.css`

## 🚀 Quick Start (3 Commands)

**Run these commands from `/home/xy/ry/campaign-website/`:**

```bash
# 1. Navigate to project (if not already there)
cd /home/xy/ry/campaign-website

# 2. Install dependencies (first time only)
npm install

# 3. Start development server
npm run dev
```

Then open: **http://localhost:5173**

## 📋 Complete Command Reference

### If Opening New Terminal

If `npm` command not found, load nvm first:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

Or restart terminal (nvm auto-loads from `~/.zshrc`).

### All Commands (from `/home/xy/ry/campaign-website/`)

```bash
# Navigate to project
cd /home/xy/ry/campaign-website

# Install dependencies (first time only)
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

## 📁 Project Structure

```
/home/xy/ry/campaign-website/
├── src/
│   ├── lib/
│   │   ├── components/
│   │   │   ├── vision/              # Vision page with custom SVGs
│   │   │   │   ├── VisionHero.svelte
│   │   │   │   ├── PermacultureSection.svelte
│   │   │   │   ├── TraditionalUrbanismSection.svelte
│   │   │   │   ├── TechnologySection.svelte
│   │   │   │   ├── JobGuaranteeSection.svelte
│   │   │   │   └── RegionalSection.svelte
│   │   │   ├── Header.svelte
│   │   │   ├── Footer.svelte
│   │   │   ├── Hero.svelte
│   │   │   ├── ThemeToggle.svelte   # * button for theme switching
│   │   │   └── ...
│   │   └── utils/
│   │       └── lazyLoad.js
│   ├── App.svelte                   # Main app component
│   ├── main.js                      # Entry point
│   └── app.css                      # Global styles & color scheme
├── index.html                       # HTML template
├── package.json                     # Dependencies
├── vite.config.js                   # Build configuration
├── node_modules/                    # Dependencies (created by npm install)
└── dist/                            # Production build (created by npm run build)
```

## 📚 Documentation Files

All in `/home/xy/ry/docs/campaign/`:

- **`0007-running-instructions.md`** ⭐ - Complete running instructions (this guide)
- `0001-website-architecture.md` - Overall architecture
- `0002-svelte-component-design.md` - Component design
- `0003-setup-instructions.md` - Setup guide
- `0004-color-scheme-design.md` - Color palette details
- `0005-performance-strategy.md` - Performance approach
- `0006-content-management-strategy.md` - Content workflow
- `0008-theme-toggle-component.md` - Theme toggle (`*` button) details
- `0009-vision-page-design.md` - Vision page with SVGs
- `0010-svg-illustration-guide.md` - SVG creation guide
- `0011-vision-integration-summary.md` - Vision integration summary

## 🎨 What You'll See

### Homepage Sections

1. **Hero** - Campaign banner with "risk love" slogan
2. **About** - Keaton Livermore & Reya (Virtual Lieutenant Governor)
3. **Vision** - Full vision page with custom SVG illustrations:
   - California landscape with permaculture pattern
   - Food forest layers
   - Traditional urbanism community layout
   - Technology infrastructure network
   - Job Guarantee work types
   - Regional California icons
4. **Platform** - Key campaign points
5. **Connect** - Social media links (stubbed)
6. **Get Involved** - Volunteer, donate, contact (stubbed)

### Theme Toggle

- **`*` button** in top-right corner
- Cycles: Auto → Light → Dark → Auto
- Saves preference to localStorage
- Works with system dark mode preference

### Stubs/Placeholders

Look for orange **STUB** badges - clearly marked placeholder content.

## 🔧 Troubleshooting

### "Command not found: npm"

Load nvm in current terminal:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### Port Already in Use

Vite will automatically use next available port. Check terminal output.

### Dependencies Issues

```bash
cd /home/xy/ry/campaign-website
rm -rf node_modules package-lock.json
npm install
```

### Build Errors

1. Make sure you're in `/home/xy/ry/campaign-website/`
2. Check all file paths are correct
3. Verify components are properly imported

## ✨ Features

- ✅ Fast loading (inline SVGs, minimal JS)
- ✅ Custom color scheme (light/dark mode)
- ✅ Theme toggle (`*` button)
- ✅ Vision page with custom SVGs
- ✅ Performance optimizations
- ✅ Responsive design
- ✅ Clear stubs for content

## 🎯 Next Steps

1. **Run the site**: `cd /home/xy/ry/campaign-website && npm install && npm run dev`
2. **Explore**: Visit http://localhost:5173
3. **Edit content**: Replace stubs in `src/lib/components/`
4. **Add social links**: Edit `src/App.svelte` (uncomment socialLinks)
5. **Customize**: Adjust colors in `src/app.css`

---

**Ready to go!** 🚀

**Full instructions**: `/home/xy/ry/docs/campaign/0007-running-instructions.md`
