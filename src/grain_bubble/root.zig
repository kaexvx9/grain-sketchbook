//! Grain Bubble: Visual design tool for Grain OS.
//!
//! Why: Native visual design tool with SLC philosophy.
//! Architecture: Native desktop app with Grain OS integration.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2025-12-21-102906-pst: Grain Bubble Agent
//! 2026-01-01-235500-pst: Enhanced module documentation (Glow G2 voice)

//! Core Canvas Modules
//! These modules provide the foundation for the design canvas.

//! Infinite canvas with zoom, pan, and shape management.
//! Use this for canvas data structures, viewport transformations, and shape operations.
pub const canvas = @import("canvas.zig");

//! Bubble renderer for drawing rounded rectangles and shapes.
//! Use this for rendering individual shapes (bubbles, circles, rectangles).
pub const bubble_renderer = @import("bubble_renderer.zig");

//! Canvas renderer integrating canvas with framebuffer rendering.
//! Use this for rendering the entire canvas to the framebuffer.
pub const canvas_renderer = @import("canvas_renderer.zig");

//! Canvas input handler for mouse and keyboard events.
//! Use this for handling user input on the canvas (selection, pan, zoom, shortcuts).
pub const canvas_input = @import("canvas_input.zig");

//! Undo/redo system using command pattern with bounded history.
//! Use this for implementing undo/redo functionality with safe memory bounds.
pub const undo_redo = @import("undo_redo.zig");

//! Component System Modules
//! These modules enable reusable design components.

//! Reusable design components with variants and design tokens.
//! Use this for creating component libraries with state/size/theme variants.
pub const component = @import("component.zig");

//! SLC UI components for Profile, Website, and Workspace applications.
//! Use this for SLC product UI component management and design patterns.
pub const slc_ui_components = @import("slc_ui_components.zig");

//! Export Modules
//! These modules handle exporting designs to various formats.

//! PDF export for vector graphics and text.
//! Use this for exporting designs to PDF format (future enhancement).
pub const export_pdf = @import("export_pdf.zig");

//! HTML export for responsive web designs.
//! Use this for exporting designs to web-ready HTML/CSS.
pub const export_html = @import("export_html.zig");

//! Framework export for generating Svelte components.
//! Use this for exporting designs as Svelte framework components.
pub const export_framework = @import("export_framework.zig");

//! SLC export for self-contained demo bundles.
//! Use this for creating SLC asset bundles with minimal dependencies.
pub const export_slc = @import("export_slc.zig");

//! Export optimization for minifying HTML and CSS.
//! Use this for optimizing export output size and compression.
pub const export_optimize = @import("export_optimize.zig");

//! Export preview generation for export metadata.
//! Use this for generating preview data and metadata from exports.
pub const export_preview = @import("export_preview.zig");

//! Integration Modules
//! These modules integrate Bubble with other Grain OS agents.

//! Silo integration for design asset storage.
//! Use this for storing and retrieving design assets from Silo database.
pub const silo_integration = @import("silo_integration.zig");

//! Court integration for vector search and LLM suggestions.
//! Use this for intelligent design features via Court spatial computing.
pub const court_integration = @import("court_integration.zig");

//! DAG integration for design version history.
//! Use this for tracking design changes and version snapshots in the DAG.
pub const dag_integration = @import("dag_integration.zig");

//! Workspace Agent integration for desktop app component synchronization.
//! Use this for applying design patterns and themes to Workspace components.
pub const workspace_integration = @import("workspace_integration.zig");

//! Aurora Agent integration for Dream Browser component synchronization.
//! Use this for applying design patterns and themes to Dream Browser components.
pub const aurora_integration = @import("aurora_integration.zig");

//! Async pattern integration using Flow Agent Event Bus.
//! Use this for async design operations with event-driven architecture.
pub const async_integration = @import("async_integration.zig");

//! Agent Flow Modules
//! These modules enable visual agent workflow design.

//! Agent flow for visual workflow design and execution visualization.
//! Use this for creating and visualizing agent workflows on the canvas.
pub const agent_flow = @import("agent_flow.zig");

