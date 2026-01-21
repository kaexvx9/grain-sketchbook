# Running the Campaign Website

**Date**: 2026-01-21  
**Status**: Ready to Run

---

## Quick Start

### Prerequisites

1. **Node.js** (version 18 or later)
   - Check if installed: `node --version`
   - Download: https://nodejs.org/
   - Or use nvm: `nvm install 18` (if you have nvm)

2. **npm** (comes with Node.js)
   - Check if installed: `npm --version`

### Installation

```bash
# Navigate to the campaign website directory
cd /home/xy/ry/campaign-website

# Install dependencies (first time only)
npm install
```

This will:
- Download all required packages (Svelte, Vite, etc.)
- Create `node_modules/` directory
- Take 1-2 minutes on first run

### Running Development Server

```bash
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

### Build for Production

```bash
npm run build
```

Creates optimized files in `dist/` directory ready for deployment.

### Preview Production Build

```bash
npm run preview
```

Starts a local server to preview the production build.

## Project Structure

```
campaign-website/
├── src/
│   ├── lib/
│   │   ├── components/     # All Svelte components
│   │   └── utils/          # Utility functions
│   ├── App.svelte          # Main app
│   ├── main.js             # Entry point
│   └── app.css             # Global styles
├── index.html              # HTML template
├── package.json            # Dependencies
└── vite.config.js          # Build config
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

### "Command not found: npm"

Node.js/npm is not installed. Install from https://nodejs.org/

### "Cannot find module" Errors

Dependencies not installed. Run:
```bash
npm install
```

### Build Errors

Make sure all file paths are correct and components are properly imported.

### Colors Look Wrong

The site uses system dark mode preference. Toggle your OS dark/light mode to see both themes.

## Next Steps After Running

1. **Explore the site** - See what's implemented
2. **Check the code** - Understand the structure
3. **Replace stubs** - Add real content
4. **Add social links** - Uncomment and add real URLs
5. **Customize** - Adjust colors, content, layout

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

- Check `/docs/campaign/` for detailed documentation
- Review component files in `src/lib/components/`
- See `README.md` in campaign-website directory

---

**Ready to go!** Run `npm install` then `npm run dev` and start building! 🚀
