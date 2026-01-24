# Vantage 3: Grain Shine Implementation Plan

**Date**: 2026-01-23-182130-pst  
**Status**: 🚧 **IMPLEMENTATION PLANNING**

---

## Overview

Implementation plan for Grain Shine display protocol based on completed analysis. Grain Shine is Wayland wire-format compatible with Rye Style bounds and safety constraints.

---

## Implementation Strategy

### Phase 5A: Core Protocol Extension
**Current**: Extend existing `grain_core/shine/protocol.zig`  
**Goal**: Add message parsing with bounds checking  
**Timeline**: 1-2 days

#### Tasks:
1. **Message Structure**: Define wire format structures
2. **Message Parser**: Implement bounded message parsing
3. **Bounds Validation**: Enforce all MAX_ constants
4. **Error Handling**: Protocol error reporting
5. **Test Suite**: Verify bounds enforcement

### Phase 5B: Protocol Interfaces  
**Goal**: Implement core Wayland interfaces  
**Timeline**: 2-3 days

#### Core Interfaces (Priority Order):
1. `wl_display` - Core global object
2. `wl_registry` - Global registry (already started)
3. `wl_compositor` - The compositor singleton
4. `wl_surface` - Surface management (already started)
5. `wl_output` - Display output (already started)
6. `wl_seat` - Input devices (already started)

### Phase 5C: Compositor Integration
**Goal**: Basic compositor functionality  
**Timeline**: 3-4 days

#### Tasks:
1. **Client Management**: Handle client connections
2. **Event Loop**: Process protocol events
3. **Surface Composition**: Basic window composition
4. **Input Routing**: Route input to surfaces

---

## Current Assets

### ✅ Existing Code
- `grain_core/shine/protocol.zig`: Core structures (183 lines, Rye Style compliant)
- `grain_core/compositor.zig`: Compositor framework (updated to use Shine)
- All bounds constants defined and implemented

### ✅ Infrastructure
- Compiler: `.ry` extension support, Rye Style validation
- Core 1: All Skate modules converted to `.ry`
- Basin kernel: RISC-V64 freestanding support

---

## Implementation Approach

### Message Parsing Architecture

```zig
// Message header structure
pub const MessageHeader = struct {
    object_id: ObjectId,
    opcode: u16,
    size: u16,
    
    pub fn parse(data: []const u8) !MessageHeader { ... }
    pub fn validate(self: MessageHeader) !void { ... }
};

// Argument parsers with bounds checking
pub const ArgumentParser = struct {
    pub fn parseString(data: []const u8, offset: *u32) ![]const u8 { ... }
    pub fn parseArray(data: []const u8, offset: *u32) ![]const u8 { ... }
    pub fn parseInt(data: []const u8, offset: *u32) !i32 { ... }
    pub fn parseUint(data: []const u8, offset: *u32) !u32 { ... }
};
```

### Error Handling Strategy
- **Protocol Errors**: Report to client and continue
- **Bounds Violations**: Close connection (security)
- **Memory Errors**: Graceful degradation
- **Invalid Data**: Protocol error

### Memory Management
- **Garden Allocator**: For protocol objects and buffers
- **Bounded Arrays**: For object storage  
- **Stack Allocation**: For message parsing (small buffers)

---

## Next Steps

### Immediate (1-2 days)
1. **Message Parser**: Implement bounded message parsing
2. **Bounds Validation**: Test all MAX_ constants
3. **Basic Interface**: Extend wl_display, wl_registry

### Short-term (3-5 days)
1. **Core Interfaces**: Complete wl_compositor, wl_surface
2. **Client Management**: Basic connection handling
3. **Event Processing**: Simple event loop

### Medium-term (1-2 weeks)
1. **Full Protocol**: All core interfaces
2. **Compositor Integration**: Window management
3. **Input Handling**: Keyboard, mouse, touch
4. **Testing**: QEMU integration, Skate testing

---

## Quality Assurance

### Rye Style Compliance
- ✅ Functions ≤ 64 lines
- ✅ Lines ≤ 128 characters  
- ✅ All public functions have "/// Why:" comments
- ✅ Explicit types (no usize/isize)
- ✅ Bounded operations (all MAX_ constants)
- ✅ No recursion (iterative algorithms)

### Testing Strategy
1. **Unit Tests**: Each function/structure
2. **Integration Tests**: Protocol message flows
3. **Bounds Tests**: Verify all limits enforced
4. **Compatibility Tests**: Wire format compatibility
5. **Performance Tests**: Memory usage, latency

---

## Success Criteria

### Phase 5A Complete When:
- ✅ Message parser implemented with bounds checking
- ✅ All MAX_ constants enforced
- ✅ Basic protocol errors handled
- ✅ Test suite passes

### Full Implementation Complete When:
- ✅ Core interfaces implemented
- ✅ Basic compositor functionality
- ✅ Skate can connect and display
- ✅ QEMU integration working

---

**Status**: 🚧 **READY FOR IMPLEMENTATION** — Planning complete, code structure defined

---

**Date**: 2026-01-23-182130-pst  
**Agent**: Vantage 3 Subcore (Rye Compiler Fork Development)