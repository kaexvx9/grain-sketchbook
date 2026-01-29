# Running the Campaign Website

**Date**: 2026-01-21  
**Status**: Ready to Run

---

## Quick Start

### Prerequisites

1. **nvm (Node Version Manager)** - Installed ✅
   - Location: `~/.nvm/`
   - Already installed and configured

2. **Node.js** - Installed ✅
   - Version: v24.13.0 (LTS)
   - Installed via nvm
   - Check: `node --version`

3. **npm** - Installed ✅
   - Version: v11.6.2 (comes with Node.js)
   - Check: `npm --version`

**Note**: If you open a new terminal, you may need to load nvm:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

Or it will auto-load from your `~/.zshrc` file.

### Installation

```bash
# Navigate to the campaign website directory
cd /home/xy/grain-sketchbook/campaign-website

# Install dependencies (first time only)
npm install
```

This will:
- Download all required packages (Svelte, Vite, etc.)
- Create `node_modules/` directory in `/home/xy/grain-sketchbook/campaign-website/`
- Take 1-2 minutes on first run

### Running Development Server

```bash
# Make sure you're in the campaign website directory
cd /home/xy/grain-sketchbook/campaign-website

# Start the development server
npm run dev
```

You should see:
```
  VITE v5.x.x  ready in xxx ms

  ➜  Local:   http://localhost:5173/
  ➜  Network: use --host to expose
```

**Open your browser to `http://localhost:5173`**

The site will:
- ✅ Auto-reload when you edit files
- ✅ Show errors in browser console
- ✅ Provide fast hot module replacement

### Stopping the Server

Press `Ctrl+C` in the terminal where the server is running.

## Other Commands

**All commands should be run from `/home/xy/grain-sketchbook/campaign-website/`**

### Build for Production

```bash
cd /home/xy/grain-sketchbook/campaign-website
npm run build
```

Creates optimized files in `/home/xy/grain-sketchbook/campaign-website/dist/` directory ready for deployment.

### Preview Production Build

```bash
cd /home/xy/grain-sketchbook/campaign-website
npm run preview
```

Starts a local server to preview the production build.

## Project Structure

**Base Directory**: `/home/xy/grain-sketchbook/campaign-website/`

```
/home/xy/grain-sketchbook/campaign-website/
├── src/
│   ├── lib/
│   │   ├── components/           # All Svelte components
│   │   │   ├── vision/           # Vision page components with SVGs
│   │   │   ├── Header.svelte
│   │   │   ├── Footer.svelte
│   │   │   ├── Hero.svelte
│   │   │   └── ...
│   │   └── utils/                # Utility functions
│   ├── App.svelte                # Main app
│   ├── main.js                   # Entry point
│   └── app.css                   # Global styles & color scheme
├── index.html                    # HTML template
├── package.json                  # Dependencies
├── vite.config.js                # Build config
├── node_modules/                 # Dependencies (created by npm install)
└── dist/                         # Production build (created by npm run build)
```

## What You'll See

### Homepage Sections

1. **Hero** - Campaign banner with "risk love" slogan
2. **About** - Keaton Livermore & Reya (Virtual Lieutenant Governor)
3. **Platform** - Key campaign points (Job Guarantee, Permaculture, etc.)
4. **Connect** - Social media links (currently stubbed)
5. **Get Involved** - Volunteer, donate, contact (currently stubbed)

### Stubs/Placeholders

Look for orange **STUB** badges - these indicate placeholder content:
- Social media links (commented out in code)
- Volunteer sign-up form
- Donation platform
- Contact form
- Detailed content sections

All stubs are clearly marked and easy to find/replace.

## Troubleshooting

### Port Already in Use

If port 5173 is taken, Vite will automatically use the next available port (5174, 5175, etc.). Check the terminal output for the actual URL.

### "Command not found: npm" or "Command not found: node"

**If in a new terminal session**, load nvm first:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

Or restart your terminal (nvm auto-loads from `~/.zshrc`).

Then verify:
```bash
node --version  # Should show: v24.13.0
npm --version   # Should show: 11.6.2
```

### "Cannot find module" Errors

Dependencies not installed. Run:
```bash
cd /home/xy/grain-sketchbook/campaign-website
npm install
```

### Build Errors

Make sure:
1. You're in the correct directory: `/home/xy/grain-sketchbook/campaign-website/`
2. All file paths are correct
3. Components are properly imported

### Colors Look Wrong

The site uses system dark mode preference by default. Use the `*` button (top-right) to manually toggle themes, or toggle your OS dark/light mode.

## Next Steps After Running

1. **Explore the site** - See what's implemented
   - Visit `http://localhost:5173` in your browser
   - Check all sections: Hero, About, Vision (with SVGs!), Platform, Get Involved

2. **Check the code** - Understand the structure
   - Main app: `/home/xy/grain-sketchbook/campaign-website/src/App.svelte`
   - Components: `/home/xy/grain-sketchbook/campaign-website/src/lib/components/`
   - Vision SVGs: `/home/xy/grain-sketchbook/campaign-website/src/lib/components/vision/`

3. **Replace stubs** - Add real content
   - Look for orange "STUB" badges
   - Edit components in `src/lib/components/`

4. **Add social links** - Uncomment and add real URLs
   - Edit `/home/xy/grain-sketchbook/campaign-website/src/App.svelte`
   - Find the `socialLinks` object

5. **Customize** - Adjust colors, content, layout
   - Colors: `/home/xy/grain-sketchbook/campaign-website/src/app.css`
   - Components: `/home/xy/grain-sketchbook/campaign-website/src/lib/components/`

## Development Tips

- **Edit files** - Changes appear instantly (hot reload)
- **Check browser console** - Errors show there
- **Use browser dev tools** - Inspect elements, test responsive design
- **Toggle dark mode** - Test both color schemes

## Performance

The site is optimized for speed:
- Lazy loading for images
- Minimal JavaScript bundle
- CSS custom properties for theming
- No blocking resources

Check performance with browser DevTools → Lighthouse.

## Getting Help

- **Documentation**: `/home/xy/grain-sketchbook/docs/campaign/` for detailed docs
  - `0007-running-instructions.md` - This file
  - `0001-website-architecture.md` - Architecture overview
  - `0004-color-scheme-design.md` - Color palette
  - `0009-vision-page-design.md` - Vision page with SVGs
- **Code**: Review component files in `/home/xy/grain-sketchbook/campaign-website/src/lib/components/`
- **Quick Reference**: `/home/xy/grain-sketchbook/campaign-website/README.md` and `QUICK_START.md`

---

## Complete Command Reference

**From `/home/xy/grain-sketchbook/campaign-website/` directory:**

```bash
# First time setup (if nvm not loaded)
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Navigate to project
cd /home/xy/grain-sketchbook/campaign-website

# Install dependencies (first time only)
npm install

# Start development server
npm run dev

# Build for production
npm run build

# Preview production build
npm run preview
```

**Ready to go!** Run `npm install` then `npm run dev` from `/home/xy/grain-sketchbook/campaign-website/` and start building! 🚀
