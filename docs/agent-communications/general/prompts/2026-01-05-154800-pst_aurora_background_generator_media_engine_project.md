# Aurora Background Generator & Media Engine Project

**Date**: 2026-01-05-154800-pst  
**Purpose**: Multi-agent project prompt for background generator and ffmpeg rewrite  
**Agents**: Aurora 2 Subcore, Bubble Agent, Workspace Agent, Court Agent  
**Status**: 🆕 **PROJECT PROPOSAL** — Ready for coordination

---

## Executive Summary

This project creates a **unified media processing and background generation system** for Grain OS, integrating:
- **Aurora 2 Subcore**: Editor/Browser integration, component library
- **Bubble Agent**: Visual design tool, filter presets, UI components
- **Workspace Agent**: Desktop application framework, media management
- **Court Agent**: LLM-powered background generation, creative AI features

**Core Component**: Native Zig rewrite of ffmpeg functionality in Grain Style, named **Grainflow Media Engine**.

---

## Project Vision

**Grainflow Media Engine**: A Grain Style-compliant media processing library written in pure Zig, providing:
1. Image format support (PNG, JPEG, WebP, AVIF, BMP, TIFF)
2. Video format support (H.264, H.265, VP9, AV1 - future phases)
3. Automated photo cropping and editing
4. API for Photos-style editing applications
5. Prequel/GIMP-style filter pipeline
6. Background generation with AI (Court integration)

---

## Agent Responsibilities

### Aurora 2 Subcore (L1 Subcore Coordinator)

**Primary Responsibilities**:
1. **Component Library Integration** (Agent 2c):
   - Media viewer components
   - Filter preview components
   - Crop/transform UI components
   - Background generator UI components

2. **Dream Browser Integration** (Agent 2b):
   - Image format rendering support
   - Media preview capabilities
   - Browser-based media viewer

3. **Dream Editor Integration** (Agent 2a):
   - Media asset management in editor
   - Image/video metadata display
   - Timeline integration for video editing (future)

**Integration Points**:
- Use Grainflow Media Engine API for all media operations
- Integrate with Bubble Agent for filter presets
- Integrate with Workspace Agent for desktop app components
- Integrate with Court Agent for AI background generation

---

### Bubble Agent (5th Agent, L1 Standalone)

**Primary Responsibilities**:
1. **Filter Preset Library**:
   - GIMP-style filter implementations
   - Prequel-style aesthetic filters
   - Custom filter design tools
   - Filter parameter UI components

2. **Visual Design Integration**:
   - Apply filters to canvas elements
   - Filter preview in design tool
   - Export filtered images/video
   - Filter workflow visualization

3. **Component Design**:
   - Filter control UI components
   - Crop/transform tool components
   - Background generator UI components

**Integration Points**:
- Use Grainflow Media Engine API for filter processing
- Share filter presets with Workspace Agent
- Design UI components for Aurora 2 Subcore Component Library
- Coordinate with Court Agent on AI-generated backgrounds

---

### Workspace Agent (8th Agent, L1 Standalone)

**Primary Responsibilities**:
1. **Desktop Media Application**:
   - Photos-style media library application
   - Media management and organization
   - Batch processing capabilities
   - Media editing workflow

2. **Automation Features**:
   - Automated photo cropping
   - Batch filter application
   - Background replacement automation
   - Media format conversion

3. **Integration with System Services**:
   - File system integration (Core 1c Storage)
   - Media metadata indexing
   - Thumbnail generation
   - Media search and filtering

**Integration Points**:
- Use Grainflow Media Engine API for all media operations
- Use Bubble Agent filter presets
- Use Aurora 2 Subcore components for UI
- Integrate with Court Agent for AI features

---

### Court Agent (11th Agent, L1 Standalone)

**Primary Responsibilities**:
1. **AI Background Generation**:
   - LLM-powered background prompts
   - Style transfer and aesthetic generation
   - Text-to-image generation (via LLM orchestration)
   - Background variation generation

2. **Creative AI Features**:
   - Smart crop suggestions (AI-powered composition)
   - Automated editing suggestions
   - Style matching and recommendations
   - Content-aware editing assistance

**Integration Points**:
- Provide background generation API
- Integrate with Grainflow Media Engine for output processing
- Coordinate with Bubble Agent on aesthetic filters
- Support Workspace Agent automation features

---

## Grainflow Media Engine: Technical Architecture

### Project Name: **Grainflow**

**Rationale**: 
- "Grain" aligns with Grain OS naming
- "flow" suggests media processing pipeline
- Single word, memorable, aligns with Grain Style philosophy

### Core Library Structure

```
grainstore/grainflow/
├── src/
│   ├── lib/
│   │   ├── formats/          # Image/video format decoders/encoders
│   │   │   ├── png.zig       # PNG decoder/encoder
│   │   │   ├── jpeg.zig      # JPEG decoder/encoder
│   │   │   ├── webp.zig      # WebP decoder/encoder
│   │   │   ├── avif.zig      # AVIF decoder/encoder
│   │   │   ├── bmp.zig       # BMP decoder/encoder
│   │   │   ├── tiff.zig      # TIFF decoder/encoder
│   │   │   └── video.zig     # Video format support (future)
│   │   ├── processing/       # Image processing operations
│   │   │   ├── crop.zig      # Cropping operations
│   │   │   ├── resize.zig    # Resizing operations
│   │   │   ├── transform.zig # Rotation, flip, etc.
│   │   │   └── color.zig     # Color space conversion
│   │   ├── filters/          # Filter pipeline
│   │   │   ├── filter.zig    # Base filter interface
│   │   │   ├── blur.zig      # Blur filters
│   │   │   ├── sharpen.zig   # Sharpen filters
│   │   │   ├── color_adjust.zig # Color adjustment filters
│   │   │   ├── artistic.zig  # Artistic filters (Prequel-style)
│   │   │   └── preset.zig    # Filter presets
│   │   ├── pipeline.zig      # Processing pipeline
│   │   └── engine.zig        # Main engine API
│   └── cli/                  # CLI tools
│       └── grainflow.zig     # Command-line interface
├── build.zig
└── README.md
```

### API Design (Grain Style)

```zig
// Main engine API
pub const GrainflowEngine = struct {
    allocator: std.mem.Allocator,
    
    pub const MAX_IMAGE_WIDTH: u32 = 32768;
    pub const MAX_IMAGE_HEIGHT: u32 = 32768;
    pub const MAX_FILTER_COUNT: u32 = 64;
    
    pub fn init(allocator: std.mem.Allocator) GrainflowEngine {
        // ...
    }
    
    pub fn load_image(
        self: *GrainflowEngine,
        data: []const u8,
    ) !Image {
        // Assert: data must be non-empty
        std.debug.assert(data.len > 0);
        std.debug.assert(data.len <= MAX_IMAGE_SIZE);
        
        // Detect format and decode
        // ...
    }
    
    pub fn apply_filter(
        self: *GrainflowEngine,
        image: *Image,
        filter: Filter,
    ) !void {
        // Assert: image must be valid
        std.debug.assert(image.width > 0);
        std.debug.assert(image.height > 0);
        std.debug.assert(image.width <= MAX_IMAGE_WIDTH);
        std.debug.assert(image.height <= MAX_IMAGE_HEIGHT);
        
        // Apply filter to image
        // ...
    }
    
    pub fn crop_image(
        self: *GrainflowEngine,
        image: *Image,
        x: u32,
        y: u32,
        width: u32,
        height: u32,
    ) !Image {
        // Assert: crop bounds must be valid
        std.debug.assert(x + width <= image.width);
        std.debug.assert(y + height <= image.height);
        std.debug.assert(width > 0);
        std.debug.assert(height > 0);
        
        // Crop image
        // ...
    }
    
    pub fn save_image(
        self: *GrainflowEngine,
        image: *Image,
        format: ImageFormat,
        path: []const u8,
    ) !void {
        // Assert: image and path must be valid
        std.debug.assert(image.width > 0);
        std.debug.assert(image.height > 0);
        std.debug.assert(path.len > 0);
        std.debug.assert(path.len <= MAX_PATH_LEN);
        
        // Encode and save
        // ...
    }
};
```

### Image Format Support (Phase 1)

**Priority Order**:
1. **PNG** (RGBA, indexed, grayscale)
2. **JPEG** (baseline, progressive)
3. **WebP** (lossy, lossless, animated)
4. **AVIF** (lossy, lossless)
5. **BMP** (RGB, RGBA)
6. **TIFF** (RGB, RGBA, compression)

### Video Format Support (Phase 2 - Future)

**Priority Order**:
1. **H.264** (decoding)
2. **VP9** (decoding)
3. **H.265** (decoding)
4. **AV1** (decoding)
5. **Encoding support** (after decoding)

---

## Background Generator Integration

### Architecture

```
Court Agent (LLM)
    ↓ (generate background prompt/description)
Background Generator Service
    ↓ (use Grainflow Engine)
Grainflow Media Engine
    ↓ (apply filters)
Bubble Agent (Filter Presets)
    ↓ (render background)
Aurora 2 Subcore (Component Library)
    ↓ (display in UI)
Workspace Agent (Desktop App)
```

### Background Generation API

```zig
// Background generation request
pub const BackgroundRequest = struct {
    prompt: []const u8,
    style: BackgroundStyle,
    dimensions: ImageDimensions,
    filter_preset: ?[]const u8,
};

// Background generator (Court Agent provides)
pub fn generate_background(
    engine: *GrainflowEngine,
    request: BackgroundRequest,
    allocator: std.mem.Allocator,
) !Image {
    // 1. Use Court Agent LLM to generate background concept
    // 2. Render background (synthetic or AI-generated)
    // 3. Apply filters from Bubble Agent
    // 4. Return processed image
}
```

---

## Photos-Style Editing API

### Core Editing Operations

```zig
pub const EditOperation = union(enum) {
    crop: CropParams,
    resize: ResizeParams,
    rotate: RotateParams,
    flip: FlipParams,
    adjust_brightness: f32,
    adjust_contrast: f32,
    adjust_saturation: f32,
    apply_filter: FilterPreset,
    apply_custom_filter: Filter,
};

pub const EditHistory = struct {
    operations: []EditOperation,
    operations_len: u32,
    
    pub const MAX_OPERATIONS: u32 = 256;
};

pub fn apply_edit(
    engine: *GrainflowEngine,
    image: *Image,
    operation: EditOperation,
) !void {
    // Apply single edit operation
    // Maintain edit history for undo/redo
}
```

---

## Filter Pipeline (Prequel/GIMP-Style)

### Filter Categories

1. **Color Adjustments**:
   - Brightness/Contrast
   - Saturation/Hue
   - Levels/Curves
   - Color Balance
   - Vibrance

2. **Artistic Filters**:
   - Vintage/Retro
   - Cinematic
   - Matte/Desaturated
   - High Contrast B&W
   - Duotone

3. **Blur/Sharpen**:
   - Gaussian Blur
   - Motion Blur
   - Unsharp Mask
   - Smart Sharpen

4. **Stylistic**:
   - Oil Painting
   - Watercolor
   - Sketch/Outline
   - Glitch Effects

### Filter Preset System

```zig
pub const FilterPreset = struct {
    name: []const u8,
    category: FilterCategory,
    filters: []Filter,
    filters_len: u32,
    
    pub const MAX_FILTERS_PER_PRESET: u32 = 16;
    pub const MAX_PRESET_NAME_LEN: u32 = 128;
};
```

**Bubble Agent Responsibility**: Design and maintain filter presets.

---

## Automated Photo Cropping

### Smart Crop Features

1. **Rule of Thirds**: Automatic composition-based cropping
2. **Face Detection**: Crop to faces (if detection available)
3. **Aspect Ratio**: Crop to standard ratios (16:9, 4:3, 1:1, etc.)
4. **AI-Powered**: Court Agent suggests crop regions
5. **Batch Processing**: Process multiple images

```zig
pub const CropStrategy = enum {
    rule_of_thirds,
    face_detection,
    aspect_ratio,
    ai_suggested,
    manual,
};

pub fn auto_crop(
    engine: *GrainflowEngine,
    image: *Image,
    strategy: CropStrategy,
    params: CropParams,
) !Image {
    // Apply automatic cropping based on strategy
}
```

---

## Integration Workflow

### Phase 1: Foundation (Weeks 1-4)

1. **Grainflow Engine Core**:
   - Project structure and build system
   - Image format decoders (PNG, JPEG)
   - Basic image processing (crop, resize, rotate)
   - Filter pipeline foundation

2. **Aurora 2 Subcore Integration**:
   - Component Library: Media viewer component
   - Browser: Image rendering support
   - Editor: Media asset integration

3. **Bubble Agent Integration**:
   - Filter preset system design
   - Basic filter implementations
   - Filter UI component designs

4. **Workspace Agent Integration**:
   - Media library application foundation
   - Basic media management UI

5. **Court Agent Integration**:
   - Background generation API design
   - LLM prompt integration planning

### Phase 2: Enhanced Features (Weeks 5-8)

1. **Additional Image Formats**:
   - WebP support
   - AVIF support
   - BMP/TIFF support

2. **Advanced Filter Pipeline**:
   - Complete Prequel-style filter set
   - Filter preset library (Bubble Agent)
   - Filter preview system

3. **Photos-Style Editing**:
   - Edit history system
   - Undo/redo support
   - Batch editing

4. **Background Generator**:
   - Court Agent integration
   - AI-powered generation
   - Style transfer

5. **Automated Cropping**:
   - Smart crop algorithms
   - Batch processing
   - AI suggestions (Court Agent)

### Phase 3: Video Support (Weeks 9-12 - Future)

1. **Video Decoding**:
   - H.264 decoder
   - VP9 decoder
   - Basic video processing

2. **Video Editing**:
   - Timeline integration (Aurora 2a Editor)
   - Video filter application
   - Video export

---

## Grain Style Compliance Requirements

**All code must follow**:
- `grain_case` function names
- `grainwrap-100` (max 100 characters per line)
- `grain validate-70` (max 70 lines per function)
- Explicit `u32`/`u64` types (no `usize`/`isize`)
- Bounded allocations (MAX_ constants)
- Minimum 2 assertions per function
- All compiler warnings addressed
- Zero technical debt policy

---

## Coordination Points

### Aurora 2 Subcore ↔ Bubble Agent

**Coordination Needed**:
- Filter preset format and API
- Component Library UI component designs
- Filter preview integration
- Background generator UI components

**Timeline**: Phase 1 (Weeks 1-4)

### Aurora 2 Subcore ↔ Workspace Agent

**Coordination Needed**:
- Desktop app component requirements
- Media library API design
- Batch processing interface

**Timeline**: Phase 1 (Weeks 1-4)

### Bubble Agent ↔ Court Agent

**Coordination Needed**:
- Background generation API
- AI filter suggestions
- Style matching algorithms

**Timeline**: Phase 2 (Weeks 5-8)

### Workspace Agent ↔ Court Agent

**Coordination Needed**:
- Automated editing suggestions
- Smart crop AI recommendations
- Background generation automation

**Timeline**: Phase 2 (Weeks 5-8)

---

## Success Criteria

**Phase 1 Success**:
- ✅ Grainflow Engine loads PNG/JPEG images
- ✅ Basic cropping and resizing works
- ✅ Filter pipeline functional
- ✅ Aurora 2 Subcore components display images
- ✅ Workspace Agent media library basic functionality
- ✅ Bubble Agent filter presets designed

**Phase 2 Success**:
- ✅ All image formats supported
- ✅ Complete filter preset library
- ✅ Background generator functional
- ✅ Photos-style editing API complete
- ✅ Automated cropping working
- ✅ Full multi-agent integration

---

## Next Steps

1. **Aurora 2 Subcore**: Review and approve project plan
2. **Bubble Agent**: Design filter preset format and initial presets
3. **Workspace Agent**: Design media library application requirements
4. **Court Agent**: Design background generation API
5. **All Agents**: Coordinate on API contracts and integration points
6. **Begin Phase 1**: Foundation development

---

**Date**: 2026-01-05-154800-pst  
**Voice**: Glow G2 (steadfast, calm, helpful guidance)  
**Status**: 🆕 **PROJECT PROPOSAL** — Ready for agent coordination

