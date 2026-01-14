# macOS Tahoe/Vantage Archive

**Date**: 2026-01-13 03:22:03 PST  
**Reason**: Focus on x86 Framework tasks before integrating back with aarch64 macOS Apple Silicon support

## Archived Components

### Source Files
- `src/platform/macos_tahoe/` → `archaeology/platform/macos_tahoe/`
- `src/tahoe_app.zig` → `archaeology/src/tahoe/tahoe_app.zig`
- `src/tahoe_window.zig` → `archaeology/src/tahoe/tahoe_window.zig`
- `src/grain_skate_main.zig` → `archaeology/src/tahoe/grain_skate_main.zig`

### Build Configuration
- Tahoe executable build steps (commented out in `build.zig`)
- Grain Skate executable build steps (commented out in `build.zig`)
- `macos_window_terminal` module (commented out in `build.zig`)
- `grain_terminal` module (commented out in `build.zig`)
- `grain_skate` module (commented out in `build.zig`)
- Vantage adaptation tests (commented out in `build.zig`)

## Restoration

To restore macOS Tahoe/Vantage support:
1. Uncomment all sections marked with `ARCHIVED 2026-01-13 03:22:03 PST` in `build.zig`
2. Move files back from `archaeology/` to their original locations
3. Verify build with `zig build tahoe-build` and `zig build grain-skate-build`

## Notes

- All archived code is preserved and can be restored when x86 Framework tasks are complete
- Timestamps added to all archive comments for tracking
- Build system remains functional for non-macOS targets (kernel-rv64, etc.)
