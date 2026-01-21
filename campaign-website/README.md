# Keaton Livermore Campaign Website

Campaign website for Keaton Livermore's 2026 California Governor race.

**Slogan**: risk love — Elegant simplicity with compassionate purpose

## Quick Start

### Prerequisites

- **Node.js** (v18 or later) - [Download](https://nodejs.org/)
- **npm** (comes with Node.js)

### Installation & Running

```bash
# 1. Navigate to project directory
cd campaign-website

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
If port 5173 is taken, Vite will suggest another port automatically.

### Dependencies Issues
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
```

### Build Errors
Check that all components are properly imported and paths are correct.

## License

MIT - Open source campaign

## Contributing

This is a campaign website. For contribution guidelines, see the main repository documentation.
