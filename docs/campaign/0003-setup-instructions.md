# Campaign Website Setup Instructions

**Date**: 2026-01-21  
**Status**: Ready for Setup

---

## Prerequisites

1. **Node.js** (v18 or later)
   - Check: `node --version`
   - Install: https://nodejs.org/

2. **npm** (comes with Node.js)
   - Check: `npm --version`

## Initial Setup

```bash
# Navigate to project
cd /home/xy/grain-sketchbook/campaign-website

# Install dependencies
npm install

# Start development server
npm run dev
```

The site will be available at `http://localhost:5173`

## Available Commands

- `npm run dev` - Start development server with hot reload
- `npm run build` - Build for production (outputs to `dist/`)
- `npm run preview` - Preview production build locally
- `npm run check` - Type check Svelte components

## Project Status

✅ Project structure created  
✅ Core components scaffolded  
✅ Configuration files ready  
⏳ Ready for content and styling refinement

## Next Steps

1. Install Node.js/npm if not already installed
2. Run `npm install` to install dependencies
3. Run `npm run dev` to start development
4. Begin adding content and refining components
5. Add routing (if needed) with SvelteKit or custom router

## Notes

- Using Svelte 5 with runes mode (explicit reactivity)
- Vite for fast development and optimized builds
- Static site - can deploy to any static host
- All code follows RyeStyle principles (explicit, compiled, performant)
