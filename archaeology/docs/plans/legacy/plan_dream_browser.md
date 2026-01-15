# Grain Dream Browser Agent: Development Plan

**Agent**: Grain Dream Browser Agent (2b, L2 Sub-Agent)  
**Parent Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Status**: ⏳ **PHASE 1 IN PROGRESS** ⏳ — Core Browser Foundation  
**Last Updated**: 2026-01-01-092301-pst  
**Coordination File**: `docs/core-coordination/aurora_2b_dream_browser_coordination.md`

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

## Current Implementation Status

### Phase 1: Core Browser Foundation ⏳ **IN PROGRESS**

#### 1.1: Nostr Protocol Integration ⏳ **IN PROGRESS**
- ✅ Nostr URL parsing (`nostr:note1...`, `nostr:npub1...`, etc.)
- ✅ Subscription management (basic structure)
- ⏳ WebSocket connection to Nostr relays (TODO in `dream_protocol.zig`)
- ⏳ Event streaming and handling (TODO in `dream_browser_nostr.zig`)
- ⏳ Event ordering and consensus (Dream Protocol integration)
- **Files**: `src/dream_browser_nostr.zig`, `src/dream_protocol.zig`

#### 1.2: WebSocket Transport ✅ **MOSTLY COMPLETE** (2026-01-01)
- ✅ WebSocket client structure (`dream_websocket.zig`)
- ✅ Frame parsing structure
- ✅ Full WebSocket handshake implementation (complete with `Sec-WebSocket-Accept` verification)
- ✅ Frame parsing implementation (improved, Grain Style compliant)
- ✅ Frame serialization (masking for client frames)
- ✅ Close frame handling
- ⚠️ TLS support deferred (`ws://` only, `wss://` TODO)
- ⏳ Frame fragmentation handling (future enhancement)
- ⏳ Compression support (permessage-deflate, future enhancement)
- **Files**: `src/dream_websocket.zig`, `src/dream_browser_websocket.zig`
- **Status**: Core functionality complete, TLS support deferred

#### 1.3: HTML/CSS Parsing ⏳ **IN PROGRESS**
- ✅ HTML parser structure (`dream_browser_parser.zig`)
- ✅ CSS parser structure
- ✅ DOM tree construction (basic structure)
- ⏳ Full HTML5 parser implementation (TODO: currently basic structure)
- ⏳ Full CSS3 parser implementation (TODO: currently basic structure)
- ⏳ Style computation (cascade, specificity)
- **Files**: `src/dream_browser_parser.zig`

#### 1.4: Rendering Engine ⏳ **IN PROGRESS**
- ✅ Renderer structure (`dream_browser_renderer.zig`)
- ✅ Layout engine structure (block/inline flow)
- ✅ Grain Aurora rendering integration (structure)
- ⏳ Complete layout algorithm implementation (TODO)
- ⏳ Readonly spans for metadata integration
- ⏳ Editable spans for content
- **Files**: `src/dream_browser_renderer.zig`

#### 1.5: Viewport Management ✅ **COMPLETE**
- ✅ Viewport state management
- ✅ Scrolling (vertical, horizontal)
- ✅ Navigation history (back/forward)
- ✅ URL handling
- ✅ Bounds checking
- **Files**: `src/dream_browser_viewport.zig`

#### 1.6: Performance Monitoring ✅ **COMPLETE**
- ✅ Performance metrics collection (`dream_browser_performance.zig`)
- ✅ Performance profiling (`dream_browser_profiler.zig`)
- ✅ Hot path identification
- **Files**: `src/dream_browser_performance.zig`, `src/dream_browser_profiler.zig`

#### 1.7: Bookmarks ⏳ **IN PROGRESS**
- ✅ Bookmark structure (`dream_browser_bookmarks.zig`)
- ⏳ Bookmark management (add, remove, edit)
- ⏳ Bookmark persistence
- **Files**: `src/dream_browser_bookmarks.zig`

#### 1.8: HTTP Client ✅ **COMPLETE**
- ✅ HTTPS support via TLS
- ✅ Request/response handling
- ✅ Timeout support
- ✅ Error handling (Core Agent integration)
- **Files**: `src/dream_http_client.zig`

#### 1.9: Image Decoding ⏳ **IN PROGRESS**
- ✅ Image decoder structure (`dream_browser_image_decoder.zig`)
- ⏳ PNG decoder implementation (TODO: placeholder returns error)
- ⏳ JPEG decoder implementation (TODO: placeholder returns error)
- ⏳ Image caching
- **Files**: `src/dream_browser_image_decoder.zig`

#### 1.10: Font Rendering ⏳ **IN PROGRESS**
- ✅ Font renderer structure (`dream_browser_font_renderer.zig`)
- ✅ Glyph caching
- ⏳ Full glyph rendering implementation (TODO: placeholder returns error)
- ⏳ Subpixel rendering (anti-aliasing)
- ⏳ Kerning support
- **Files**: `src/dream_browser_font_renderer.zig`

#### 1.11: DAG Integration ✅ **COMPLETE**
- ✅ DOM-to-DAG node mapping
- ✅ Web request-to-DAG event mapping
- ✅ Nostr event-to-DAG event mapping
- ✅ Streaming updates
- ✅ Unified state (editor + browser share same DAG)
- **Files**: `src/dream_browser_dag_integration.zig`

#### 1.12: Dream Protocol Foundation ✅ **MOSTLY COMPLETE** (2026-01-01)
- ✅ Dream Protocol structure (`dream_protocol.zig`)
- ✅ Nostr + WebSocket + State machine structure
- ✅ WebSocket connection implementation (`connect()`, `disconnect()`)
- ✅ REQ message serialization (JSON)
- ✅ CLOSE message serialization (JSON)
- ✅ EVENT message deserialization (JSON)
- ✅ EOSE message deserialization (JSON)
- ✅ NOTICE message deserialization (JSON)
- ✅ Connection state management
- ⚠️ TLS support deferred (`ws://` only, `wss://` returns `error.TlsNotSupported`)
- ⏳ Event ordering and consensus (TigerBeetle-style state machine)
- ⏳ State machine execution (event ordering/consensus)
- ⏳ Event deduplication and caching
- **Files**: `src/dream_protocol.zig`
- **Status**: Core connection functionality complete (works for `ws://`), state machine execution pending

#### 1.13: Protocol Optimizer ✅ **COMPLETE**
- ✅ Protocol optimization structure
- ✅ Performance optimization for Dream Protocol
- **Files**: `src/dream_browser_protocol_optimizer.zig`

---

## Phase 2: Integration and Enhancements (Planned)

### 2.1: WebSocket TLS Support ⏳ **PLANNED** (2026-01-01)
**Priority**: Medium (deferred from Phase 1)

**Status**: Core WebSocket functionality complete (`ws://`), TLS support deferred

**Tasks**:
- Implement TLS support for `wss://` connections
- Integrate with Core Agent TLS client
- Test TLS handshake and secure connections
- **Estimated**: 2-3 days

**Note**: Core WebSocket handshake, frame parsing, and serialization are complete. TLS support was deferred to prioritize core functionality.

### 2.2: Dream Protocol State Machine ⏳ **PLANNED** (2026-01-01)
**Priority**: High (completes Dream Protocol functionality)

**Status**: Connection functionality complete (connect, subscribe, receive), state machine execution pending

**Tasks**:
- Implement event ordering (TigerBeetle-style state machine)
- Implement event consensus
- Implement state machine execution
- Implement event deduplication
- Implement event caching
- **Estimated**: 1-2 weeks

**Note**: Core connection functionality (connect, subscribe, receive with JSON serialization/deserialization) is complete. State machine execution is the remaining major component.

### 2.3: Complete HTML/CSS Parser ⏳ **PLANNED**
**Priority**: High (required for web content rendering)

**Tasks**:
- Implement full HTML5 parser (handle nested tags, attributes, text nodes)
- Implement full CSS3 parser (handle selectors, properties, values)
- Implement style cascade and specificity
- Implement computed styles
- Handle malformed HTML/CSS gracefully
- **Estimated**: 5-7 days

### 2.4: Complete Rendering Engine ⏳ **PLANNED**
**Priority**: High (required for web content display)

**Tasks**:
- Complete layout algorithm (block/inline flow, positioning)
- Integrate readonly spans for metadata (event ID, timestamp)
- Integrate editable spans for content
- Implement paint order (z-index, stacking context)
- Implement clipping and overflow handling
- **Estimated**: 4-5 days

### 2.5: Complete Image Decoding ⏳ **PLANNED**
**Priority**: Medium (required for image display)

**Tasks**:
- Implement PNG decoder (IHDR, IDAT, IEND chunks)
- Implement JPEG decoder (SOF, DHT, DQT, SOS segments)
- Implement image caching
- Handle progressive image loading
- **Estimated**: 7-10 days

### 2.6: Complete Font Rendering ⏳ **PLANNED**
**Priority**: Medium (required for text rendering)

**Tasks**:
- Implement glyph rendering from font files
- Implement subpixel rendering (anti-aliasing)
- Implement kerning support
- Integrate with layout engine
- **Estimated**: 5-7 days

### 2.7: Complete Bookmark Management ⏳ **PLANNED**
**Priority**: Low (nice-to-have feature)

**Tasks**:
- Implement bookmark add/remove/edit
- Implement bookmark persistence (file or DAG)
- Implement bookmark organization (folders, tags)
- **Estimated**: 2-3 days

### 2.8: Browser State Management ⏳ **PLANNED**
**Priority**: Medium (required for multi-tab support)

**Tasks**:
- Implement browser state tracking
- Coordinate with Component Library Agent for tab UI
- Implement tab lifecycle (create, close, switch)
- Implement tab state persistence
- **Estimated**: 3-4 days

---

## Phase 3: Advanced Features (Future)

### 3.1: Advanced Nostr Features
- Profile rendering (kind 0)
- Thread rendering (reply chains)
- Reaction rendering (kind 7)
- Repost rendering (kind 6)
- Media embedding (images, videos)

### 3.2: Performance Optimizations
- Virtual scrolling for long content
- Lazy loading for images and content
- Connection pooling for WebSocket
- Event deduplication
- Incremental rendering

### 3.3: Security Features
- Pubkey verification
- Relay reputation system
- Content filtering
- Privacy mode
- Certificate pinning

---

## Dependencies

### Shared Modules (Coordinated via Aurora 2 Subcore)
- **`src/grain_buffer.zig`** - Text buffer (shared with Component Library Agent)
- **`src/dag_core.zig`** - DAG (shared with all agents)
- **`src/shared/`** - Shared modules (coordinated by Aurora 2 Subcore)

### External Dependencies
- **Nostr relays** (WebSocket servers for Nostr protocol)
- **WebSocket servers** (for Nostr relay communication)
- **DNS resolution** (via Core Agent's DNS client for Dream URL resolution)
- **TLS/HTTPS** (via Core Agent's TLS client for secure connections)

---

## Coordination

### With Aurora 2 Subcore (L1 Subcore Coordinator)
- **Weekly/bi-weekly check-ins** for status updates and architecture decisions
- **As-needed coordination** for breaking changes, cross-sub-agent dependencies
- **Shared module coordination** (GrainBuffer, DAG Core)

### With Component Library Agent (2c)
- **Component API** for browser UI components (tabs, bookmarks bar, address bar)
- **UI component requirements** coordination
- **Theme synchronization** (if applicable)

### With Dream Editor Agent (2a)
- **Minimal direct coordination** (different domains)
- **Via Aurora 2 Subcore** for shared foundation coordination

### With Core Agent (L1 Subcore)
- **DNS resolution** for Dream URL resolution (DNS TXT/SRV records)
- **Network stack** for HTTP/WebSocket communication
- **TLS client** for HTTPS connections

---

## Grain Style Requirements

All code must follow **Grain Style** (`~/xy-mathematics/docs/grain_style.md`):

- **`grain_case`** function names
- **Explicit `u32`/`u64` types** (not `usize`/`isize`)
- **`grainwrap-100`** (max 100 characters per line)
- **`grain validate-70`** (max 70 lines per function)
- **Minimum 2 assertions per function**
- **Bounded allocations** (all limits explicitly defined)
- **All compiler warnings enabled**
- **Zero technical debt policy**

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

## Status

**Current Phase**: Phase 1 - Core Browser Foundation (In Progress)  
**Priority**: High (browser is core IDE functionality)  
**Next Steps**: Complete WebSocket implementation, Dream Protocol connection, HTML/CSS parser

---

**Agent Name**: Grain Dream Browser Agent (2b, L2 Sub-Agent)  
**L1 Subcore**: Aurora 2 Subcore  
**Domain**: Browser Features  
**Status**: Active
