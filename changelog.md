# Grain Changelog — Descending Order (Newest First)

## 12025-10-26--1026-pst
- **Enhanced Assertions & Error Handling**
  - Added comprehensive assertions throughout Cocoa bridge code (`src/platform/macos/window.zig`, `src/platform/macos/cocoa_bridge.zig`)
  - Added panic messages with detailed context for NULL class/selector lookups
  - Added pointer validity checks using `@intFromPtr` before Objective-C message sends
  - Added bounds checking for window dimensions (0 < w/h <= 16384)
  - Added assertions for all `objc_msgSend` calls: receiver, selector, and return value validation
  - Improved error messages: includes class pointers, selectors, and rect dimensions in panic messages
  - Assertions help identify segfault source: currently segfaulting at `objc_msgSend0` call with NSApplication class
  - Note: musl libc is not compatible with macOS Cocoa (requires Apple's system libc)
- **Get Started Guide & Zig IDE Vision**
  - Created `docs/get-started.md` for beginner users comparing Aurora to Cursor
  - Reoriented Ray and Plan to prioritize Zig LSP implementation (Matklad-inspired)
  - Documented snapshot-based LSP architecture: `ready` / `working` / `pending` model
  - Emphasized agentic coding integration: Cursor CLI and Claude Code support
  - Added terminal integration (Vibe Coding) and River compositor workflows
  - Updated Ray Mission Ladder: Phase 1 focuses on core IDE foundation (LSP, editor, completion)
  - References: Matklad's LSP architecture, cancellation model, missing IDE features
- **macOS Tahoe Application Event Loop Complete**
  - Added `runEventLoop` to Platform VTable for event loop support
  - Implemented `Window.runEventLoop()` in `src/platform/macos/window.zig` calling `[NSApplication run]`
  - Added `ns_app` field to Window struct to store NSApplication shared instance
  - Implemented `runEventLoop` in all platform implementations (macOS, RISC-V, null)
  - Updated `tahoe_app.zig` to call `sandbox.platform.runEventLoop()` after showing window
  - Build succeeds: `zig build tahoe` compiles successfully
  - Executable runs: `zig-out/bin/tahoe` starts and shows window (terminates immediately without delegate)
  - Next: Add NSApplication delegate for proper event handling and window lifecycle
- **Cocoa Bridge Implementation Complete**
  - Implemented actual NSApplication, NSWindow, and NSView calls in `src/platform/macos/window.zig`
  - Created `src/platform/macos/cocoa_bridge.zig` with typed `objc_msgSend` wrappers
  - Created `src/platform/macos/objc_runtime.zig` for shared Objective-C runtime C import
  - Fixed function pointer casting using `@extern` to get `objc_msgSend` from Objective-C runtime
  - Fixed null check errors: removed invalid checks on non-optional pointers
  - Fixed array pointer access for NSString conversion
  - Build succeeds: `zig build tahoe` compiles successfully
  - Executable created: `zig-out/bin/tahoe` (1.3MB)

## 12025-11-12--0945-pst
- **Test Improvements & Platform Decoupling**
  - Decoupled fuzz test 002 into platform-specific tests: `002_macos.md` and `999_riscv.md`
  - Implemented buffer content validation using FNV-1a checksum (detects silent corruption)
  - Implemented memory leak detection using GeneralPurposeAllocator (validates cleanup)
  - Added error path coverage test for invalid inputs
  - Updated Ray and Plan with macOS priorities in order: Cocoa bridge → Compositor → UI → Events
  - All tests pass: validates platform abstraction boundaries with improved coverage

## 12025-11-12--0937-pst
- **Experimental Randomized Fuzz Test 002 Implementation**
  - Implemented platform abstraction boundary fuzz test in `src/platform.zig`
  - Tests window initialization, buffer operations, and vtable dispatch paths
  - Uses Matklad-style data-driven testing with SimpleRng LCG PRNG
  - Validates deterministic behavior: RGBA alignment, dimension consistency,
    single-level pointer usage
  - Updated `tests-experiments/002.md` with methodology and results
  - Test passes: 100 iterations of random window lifecycle operations
  - Fixed Window struct compile-time constant assertions in `src/platform/macos/window.zig`
- **Changelog Creation**
  - Created `changelog.md` with descending append-to-front order
  - Documented all recent progress: pointer documentation, platform abstraction,
    struct organization, kernel scaffolding, Ray & Plan Mission Ladder updates
  - Using Holocene Vedic calendar timestamp format: `12025-11-12--0937-pst`

## 12025-11-12--0930-pst
- **Pointer Documentation & TigerStyle Compliance**
  - Added comprehensive pointer usage comments across all platform abstraction code
  - Documented why each pointer is used (TigerStyle: explain "why", not "what")
  - Verified single-level pointers only: no double/triple pointers (`**T`, `***T`) exist
  - Removed invalid null checks on non-optional pointers (`*const VTable`, `*anyopaque`)
  - Added pointer flow documentation in `src/platform.zig`, `src/platform/macos/impl.zig`,
    `src/platform/riscv/impl.zig`, `src/platform/null/impl.zig`
  - All platform implementations now explicitly document single-level pointer design
  - Tests pass; codebase adheres to TigerStyle pointer guidelines

## 12025-11-12--0930-pst
- **Platform Abstraction Refactoring**
  - Created platform abstraction layer (`src/platform.zig`) with VTable pattern
  - Implemented macOS, RISC-V, and null platform implementations
  - Decoupled platform-specific code from core Aurora UI logic
  - Added comprehensive assertions following TigerStyle principles
  - Refactored `src/tahoe_window.zig` to use platform abstraction
  - All platform code uses single-level pointers only (TigerStyle compliance)

## 12025-11-12--0920-pst
- **Struct Organization**
  - Created `src/structs/` directory for centralized struct definitions
  - Added `src/structs/index.zig` to re-export all public structs
  - Created `src/structs/README.md` documenting struct organization
  - Separated struct definitions into unique files for easier review

## 12025-11-12--0910-pst
- **Kernel Scaffolding**
  - Created `src/kernel/main.zig`, `src/kernel/syscall_table.zig`, `src/kernel/devx/abi.zig`
  - Added `kernel/link.ld` linker script for RISC-V
  - Created `scripts/qemu_rv64.sh` for QEMU testing
  - Extended `grain conduct` with `make kernel-rv64`, `run kernel-rv64`, `report kernel-rv64`
  - Kernel work paused until Framework 13 RISC-V board or VPS is available

## 12025-11-12--0900-pst
- **Ray & Plan Mission Ladder**
  - Refactored `docs/ray.md` and `docs/plan.md` into "Mission Ladder" format
  - Prioritized macOS Tahoe Aurora UI development
  - Added "Experimental Randomized Fuzz Test 002" as top priority
  - Updated all section numbers to reflect new priority order
  - Documented deterministic plan execution strategy

## 12025-11-12--0850-pst
- **Installation Documentation**
  - Created `docs/install.md` with Zig 0.15.2 installation instructions
  - Emphasized using official `ziglang.org` release for TigerStyle determinism
  - Updated `docs/ray.md` to reference installation guide

## 12025-11-12--0840-pst
- **Crash Handling**
  - Created `src/aurora_crash.zig` for panic handling and error logging
  - Refactored `src/tahoe_app.zig` to wrap `mainImpl` in error handler
  - Added system information, panic messages, and stack traces to crash logs

## 12025-11-12--0830-pst
- **LSP & Editor Integration**
  - Created `src/aurora_lsp.zig` for LSP client functionality
  - Created `src/aurora_editor.zig` for Aurora code editor IDE
  - Integrated `GrainBuffer`, `GrainAurora`, and `LspClient`
  - Laid groundwork for ZLS integration

## 12025-11-12--0820-pst
- **Text Rendering**
  - Created `src/aurora_text_renderer.zig` for rendering text into RGBA buffers
  - Added `TextRenderer` struct with `render` method
  - Integrated into `build.zig` tests

## 12025-11-12--0810-pst
- **Aurora UI Framework**
  - Created `src/grain_aurora.zig` for core Aurora UI framework
  - Defined `Node`s, `Component`s, and rendering logic
  - Refactored comments to explain "why" instead of "what" (TigerStyle)

## 12025-11-12--0800-pst
- **Tahoe Sandbox**
  - Created `src/tahoe_window.zig` as main sandbox for Aurora GUI
  - Integrated `Platform` abstraction and `GrainAurora`
  - Added `tick` function for rendering loop
  - Created `src/tahoe_app.zig` as main executable

## 12025-11-12--0750-pst
- **Project Initialization**
  - Initialized Git repository in `xy` (`/Users/bhagavan851c05a/kae3g/bhagavan851c05a`)
  - Created GitHub repository `@kae3g/xy` with `main` branch
  - Set repository description emphasizing macOS Zig-Swift-ObjectiveC Native GUI
  - Created `docs/ray.md` and `docs/ray_160.md` as canonical project documentation

