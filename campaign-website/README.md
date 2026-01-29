# Keaton Livermore Campaign Website

Campaign website for Keaton Livermore's 2026 California Governor race.

**Slogan**: risk love — Elegant simplicity with compassionate purpose

## Quick Start

### Prerequisites

- **nvm (Node Version Manager)** - ✅ Installed
- **Node.js** v24.13.0 (LTS) - ✅ Installed via nvm
- **npm** v11.6.2 - ✅ Installed with Node.js

**Note**: If opening a new terminal, nvm may need to be loaded:
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### Installation & Running

**All commands from `/home/xy/grain-sketchbook/campaign-website/`:**

```bash
# 1. Navigate to project directory
cd /home/xy/grain-sketchbook/campaign-website

# 2. Install dependencies (first time only)
npm install

# 3. Start development server
npm run dev

# 4. Open browser to http://localhost:5173
```

The development server will:
- Auto-reload on file changes
- Show errors in browser console
- Provide fast refresh for Svelte components

### Other Commands

```bash
# Build for production
npm run build

# Preview production build locally
npm run preview

# Type check (if using TypeScript)
npm run check
```

## Project Structure

```
campaign-website/
├── src/
│   ├── lib/
│   │   ├── components/       # Reusable Svelte components
│   │   │   ├── Header.svelte
│   │   │   ├── Footer.svelte
│   │   │   ├── Hero.svelte
│   │   │   ├── PlatformSection.svelte
│   │   │   ├── AboutSection.svelte
│   │   │   ├── GetInvolvedSection.svelte
│   │   │   ├── SocialLinks.svelte
│   │   │   ├── VideoPlaceholder.svelte
│   │   │   ├── OptimizedImage.svelte
│   │   │   └── Stub.svelte    # Placeholder indicator
│   │   └── utils/
│   │       └── lazyLoad.js    # Lazy loading utilities
│   ├── App.svelte             # Main app component
│   ├── main.js                # Entry point
│   └── app.css                # Global styles & color scheme
├── index.html                 # HTML template
├── vite.config.js             # Build configuration
├── svelte.config.js           # Svelte configuration
├── package.json               # Dependencies
└── README.md                  # This file
```

## Current Status

### ✅ Implemented
- Basic site structure
- Color scheme (light/dark mode)
- **Theme toggle** (`*` button, top-right, cycles Auto→Light→Dark)
- Core components (Header, Footer, Hero)
- Platform section
- About section
- Get Involved section
- Social links component
- Performance optimizations (lazy loading, etc.)

### 🚧 Stubs/Placeholders
- Social media links (commented out - add when accounts exist)
- Volunteer sign-up form
- Donation platform
- Contact form
- Full content/details (marked with STUB components)

**Note**: Stubs are clearly marked with orange "STUB" badges and italic text.

### 🎨 Vision Page Components
- Custom SVG illustrations matching campaign vision
- Permaculture food forest visuals
- Traditional urbanism community layouts
- Technology infrastructure networks
- Regional California icons
- All using our color scheme (auto light/dark mode)

## Development Principles

Following RyeStyle alignment:
- **Explicit over implicit** - Clear props, no hidden state
- **Compiled over runtime** - Svelte compiles to vanilla JS
- **Small bundles** - Minimal runtime overhead
- **Battle-tested** - Proven reliability
- **Performance first** - Fast loading, lazy loading, optimized assets

## Color Scheme

The site uses a custom color scheme inspired by the campaign avatar:
- **Light Mode**: Warm off-white backgrounds, sunset orange, seafoam green, sand beige
- **Dark Mode**: Dark brown backgrounds, brighter accents, purple-mauve-rose tones
- Automatically switches based on system preference

## Documentation

See `/docs/campaign/` (parent directory) for detailed docs:
- `0001-website-architecture.md` - Overall architecture
- `0002-svelte-component-design.md` - Component design
- `0003-setup-instructions.md` - Setup guide
- `0004-color-scheme-design.md` - Color palette
- `0005-performance-strategy.md` - Performance approach
- `0006-content-management-strategy.md` - Content workflow

## Next Steps

1. **Add Content**: Replace stubs with actual content
2. **Social Media**: Add real social media links
3. **Forms**: Implement volunteer/donation/contact forms
4. **Images**: Add optimized images and videos
5. **Deploy**: Set up hosting and deployment

## Troubleshooting

### Port Already in Use
If port 5173 is taken, Vite will suggest another port automatically. Check terminal output.

### "Command not found: npm"
Load nvm first (if in new terminal):
```bash
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
```

### Dependencies Issues
```bash
cd /home/xy/grain-sketchbook/campaign-website
rm -rf node_modules package-lock.json
npm install
```

### Build Errors
Check that:
1. You're in `/home/xy/grain-sketchbook/campaign-website/`
2. All components are properly imported
3. File paths are correct

## License

MIT - Open source campaign

## Contributing

This is a campaign website. For contribution guidelines, see the main repository documentation.
