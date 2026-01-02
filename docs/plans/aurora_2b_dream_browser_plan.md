# Grain Dream Browser Agent: Development Plan

**Agent**: Grain Dream Browser Agent (2b, L2 Sub-Agent)  
**Parent Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Status**: ⏳ **PHASE 1 IN PROGRESS** ⏳ — Core Browser Foundation  
**Last Updated**: 2026-01-01-092301-pst  
**Coordination File**: `docs/core-coordination/aurora_2b_dream_browser_coordination.md`  
**Tasks File**: `docs/tasks/aurora_2b_dream_browser_tasks.md`

---

## Overview

Grain Dream Browser Agent is responsible for building the **Dream Browser (Browser features)**, a Nostr-native browser with real-time WebSocket communication. The browser provides HTML/CSS parsing and rendering, Nostr protocol integration, and seamless integration with the unified IDE vision.

**Key Goals**:
- Nostr protocol integration (Nostr event structure, relay communication, event streaming)
- WebSocket transport (low-latency bidirectional communication)
- HTML/CSS parsing and rendering (subset of HTML5/CSS3)
- Viewport management (scrolling, navigation, history)
- Performance monitoring (profiling, metrics collection)
- Bookmarks and navigation (bookmark management, history, URL handling)
- Dream Protocol (Nostr + WebSocket + TigerBeetle-style state machine)
- Browser state management (state tracking, tab management)

**Philosophy**: Build a native browser that feels like part of Grain OS, with safety-first design (GrainStyle compliance), bounded allocations, and comprehensive assertions. Enable Nostr-native content browsing with deterministic state management through DAG integration.

---

## Current Status

**Phase**: ⏳ **PHASE 1 IN PROGRESS** — Core Browser Foundation

**Completion Summary**:
- ✅ 7/13 components complete (Viewport, Performance, HTTP Client, DAG Integration, Protocol Optimizer, WebSocket Transport, Dream Protocol Connection)
- ⏳ 6/13 components in progress (all structures complete, implementation needed)

---

## Completed Phases

### Phase 1: Core Browser Foundation — Partial ✅/⏳

**Status**: ⏳ **IN PROGRESS** (7/13 complete, 6/13 in progress)

**Completed Components** ✅:
- 1.5: Viewport Management — **COMPLETE** (2025-12-31)
- 1.6: Performance Monitoring — **COMPLETE** (2025-12-31)
- 1.8: HTTP Client — **COMPLETE** (2025-12-31)
- 1.11: DAG Integration — **COMPLETE** (2025-12-31)
- 1.13: Protocol Optimizer — **COMPLETE** (2025-12-31)
- 1.2: WebSocket Transport — **COMPLETE** (2026-01-01) — Handshake implementation complete, TLS support deferred
- 1.12: Dream Protocol Connection — **COMPLETE** (2026-01-01) — Core functionality working for `ws://` connections

**In Progress Components** ⏳:
- 1.1: Nostr Protocol Integration (structure complete, event streaming and state machine execution needed)
- 1.3: HTML/CSS Parsing (structure complete, implementation needed)
- 1.4: Rendering Engine (structure complete, implementation needed)
- 1.7: Bookmarks (structure complete, implementation needed)
- 1.9: Image Decoding (structure complete, implementation needed)
- 1.10: Font Rendering (structure complete, implementation needed)

---

## Current Phase

### Phase 1: Core Browser Foundation — Continued ⏳ **IN PROGRESS**

**Objective**: Complete implementation of all browser core components

**Status**: 7/13 components complete, 6/13 in progress (all structures complete, implementation needed)

**High Priority Implementation Tasks**:
- ⏳ HTML/CSS Parser (Priority 1, 5-7 days) — blocks rendering
- ⏳ Rendering Engine (Priority 1, 4-5 days) — depends on parser
- ⏳ Nostr Protocol Integration (Priority 1, 1-2 weeks) — event streaming and state machine execution
- ⏳ TLS Support for WebSocket (Priority 2, 2-3 days) — `wss://` connections (currently deferred)

**Medium Priority Implementation Tasks**:
- ⏳ Image Decoding (Priority 2, 7-10 days)
- ⏳ Font Rendering (Priority 2, 5-7 days)

**Low Priority Implementation Tasks**:
- ⏳ Bookmarks (Priority 3, 2-3 days)

**Dependencies**:
- WebSocket implementation blocks Dream Protocol connection
- HTML/CSS parser blocks rendering engine
- Component Library Agent (2c) needed for browser UI components

---

## Planned Phases

### Phase 2: Integration and Enhancements 📋 **PLANNED**

**Objective**: Complete integration of all browser components and add enhancements

**Estimated Time**: 3-4 weeks

**Tasks**:
- Complete WebSocket implementation
- Complete Dream Protocol connection
- Complete HTML/CSS parser
- Complete rendering engine
- Complete image decoding
- Complete font rendering
- Browser state management (tab management)

**Dependencies**: Phase 1 complete, Component Library Agent (2c) Component API ready

---

### Phase 3: Advanced Features 📋 **PLANNED**

**Objective**: Add advanced browser features and optimizations

**Estimated Time**: 4-6 weeks

**Features**:
- Advanced Nostr features (profile rendering, threads, reactions, reposts, media embedding)
- Performance optimizations (virtual scrolling, lazy loading, connection pooling, event deduplication, incremental rendering)
- Security features (pubkey verification, relay reputation, content filtering, privacy mode, certificate pinning)

**Dependencies**: Phase 2 complete

---

## Coordination

**With Aurora 2 Subcore (L1)**:
- Weekly/bi-weekly check-ins for status updates and architecture decisions
- As-needed coordination for breaking changes, cross-sub-agent dependencies
- Shared module coordination (GrainBuffer, DAG Core)

**With Component Library Agent (2c)**:
- Component API for browser UI components (tabs, bookmarks bar, address bar) — **HIGH PRIORITY**
- UI component requirements coordination
- Theme synchronization (if applicable)

**With Dream Editor Agent (2a)**:
- Minimal direct coordination (different domains)
- Via Aurora 2 Subcore for shared foundation coordination

**With Core Agent (L1 Subcore)**:
- DNS resolution for Dream URL resolution (DNS TXT/SRV records)
- Network stack for HTTP/WebSocket communication
- TLS client for HTTPS connections

---

## Grain Style Compliance

- ✅ Function length: ≤ 70 lines (all structure code compliant)
- ✅ Line length: ≤ 100 characters (all structure code compliant)
- ✅ Explicit types: `u32`/`u64` (not `usize`/`isize`) (all structure code compliant)
- ✅ Bounded allocations (all MAX_ constants defined)
- ✅ Comprehensive assertions (all structure code compliant)
- ✅ All compiler warnings enabled
- ✅ Zero technical debt policy

**Note**: All completed and in-progress code follows Grain Style. Implementation TODOs exist (placeholders return errors), but all structure follows Grain Style principles.

---

## Key Files (Domain)

### Core Browser Files
- `src/dream_browser_nostr.zig` - Nostr integration ⏳
- `src/dream_protocol.zig` - Dream Protocol (Nostr + WebSocket + State machine) ⏳
- `src/dream_websocket.zig` - WebSocket client ⏳
- `src/dream_browser_websocket.zig` - Browser WebSocket integration ⏳
- `src/dream_browser_renderer.zig` - HTML/CSS rendering ⏳
- `src/dream_browser_parser.zig` - HTML/CSS parsing ⏳
- `src/dream_browser_viewport.zig` - Viewport management ✅
- `src/dream_browser_performance.zig` - Performance monitoring ✅
- `src/dream_browser_profiler.zig` - Performance profiling ✅
- `src/dream_browser_bookmarks.zig` - Bookmarks ⏳
- `src/dream_http_client.zig` - HTTP client ✅
- `src/dream_browser_font_renderer.zig` - Font rendering ⏳
- `src/dream_browser_image_decoder.zig` - Image decoding ⏳
- `src/dream_browser_dag_integration.zig` - DAG integration ✅
- `src/dream_browser_protocol_optimizer.zig` - Protocol optimization ✅

### Shared Files (Coordinated via Aurora 2 Subcore)
- `src/dream_browser_components.zig` - Uses Component API from Component Library Agent (2c)
- `src/grain_buffer.zig` - Text buffer (shared with Component Library Agent)
- `src/dag_core.zig` - DAG (shared with all)
- `src/shared/` - Shared modules (coordinated by Aurora 2 Subcore)

---

**Last Updated**: 2026-01-01-092301-pst  
**Agent**: Grain Dream Browser Agent (2b)  
**Status**: Phase 1 In Progress ⏳
