# Aurora 2 Subcore: Shared Module Usage Guide

**Date**: 2026-01-06-100156-pst  
**Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Purpose**: Comprehensive guide for L2 sub-agents on shared module usage patterns  
**Status**: ✅ **GUIDE COMPLETE** — Ready for L2 sub-agent reference

---

## Executive Summary

This guide provides comprehensive documentation for shared module usage across Aurora 2 Subcore L2 sub-agents (2a Dream Editor, 2b Dream Browser, 2c Component Library). It covers usage patterns, coordination requirements, and best practices for GrainBuffer, DAG Core, and GrainAurora rendering integration.

**Audience**: L2 sub-agents (2a, 2b, 2c)  
**Purpose**: Ensure consistent, conflict-free shared module usage

---

## Shared Module Overview

### Modules Available

**1. GrainBuffer** (`src/grain_buffer.zig`)
- **Purpose**: Text buffer for editor and component library
- **Used By**: Editor Agent (2a), Component Library Agent (2c)
- **Coordination**: Aurora 2 Subcore

**2. DAG Core** (`src/dag_core.zig`)
- **Purpose**: Event recording and deterministic state management
- **Used By**: All sub-agents (Editor, Browser, Component Library)
- **Coordination**: Aurora 2 Subcore

**3. GrainAurora** (`src/grain_aurora.zig`)
- **Purpose**: Component-first UI rendering engine
- **Used By**: All sub-agents (Editor, Browser, Component Library)
- **Coordination**: Aurora 2 Subcore

**4. Shared Font Renderer** (`src/shared/`)
- **Purpose**: Font rendering utilities
- **Used By**: All sub-agents
- **Coordination**: Aurora 2 Subcore

---

## GrainBuffer Usage

### Overview

**Location**: `src/grain_buffer.zig`  
**Purpose**: Text buffer for editor content and component text rendering  
**Shared Between**: Editor Agent (2a) and Component Library Agent (2c)

### Usage Patterns

**Editor Agent (2a)**:
- Primary text buffer for editor content
- LSP document snapshot management
- Undo/redo history
- Cursor and selection management

**Component Library Agent (2c)**:
- Component text rendering
- Label and text component content
- Editor Component API text integration

### Coordination Requirements

**Change Protocol**:
1. Sub-agent identifies need for GrainBuffer change
2. Sub-agent coordinates with Aurora 2 Subcore
3. Aurora 2 Subcore coordinates with other affected sub-agents (2a or 2c)
4. Aurora 2 Subcore approves and implements change
5. Both sub-agents update to use new GrainBuffer version

**Example Changes Requiring Coordination**:
- API changes (new functions, modified signatures)
- Behavior changes (text encoding, buffer limits)
- Performance optimizations affecting API
- Bug fixes affecting shared behavior

**Non-Coordinating Changes**:
- Internal optimizations (performance improvements, code cleanup)
- Documentation updates
- Test additions (doesn't affect API)

### Best Practices

**1. Read-Only Usage (Preferred)**
- Use GrainBuffer APIs as documented
- Avoid modifying internal state directly
- Use provided accessor functions

**2. Bounded Allocations**
- Respect MAX_ constants defined in GrainBuffer
- Use bounded buffer operations
- Handle allocation failures gracefully

**3. Thread Safety**
- GrainBuffer is not thread-safe
- Coordinate access through single-threaded patterns
- Use appropriate synchronization if needed

### Code Examples

**Editor Agent Usage**:
```zig
const GrainBuffer = @import("grain_buffer.zig").GrainBuffer;

// Initialize buffer
var buffer = GrainBuffer.init(allocator);

// Insert text
try buffer.insert(text, position);

// Get line
const line = buffer.get_line(line_number);

// Get content
const content = buffer.get_content();
```

**Component Library Usage**:
```zig
const GrainBuffer = @import("grain_buffer.zig").GrainBuffer;

// Use buffer for component text rendering
fn render_text_component(buffer: *GrainBuffer, text: []const u8) void {
    // Render text using buffer
    // Component text rendering pattern
}
```

---

## DAG Core Usage

### Overview

**Location**: `src/dag_core.zig`  
**Purpose**: Event recording and deterministic state management  
**Shared Between**: All sub-agents (Editor, Browser, Component Library)

### Usage Patterns

**Editor Agent (2a)**:
- Editor operation recording (edits, cursor movements)
- LSP event recording
- Document change tracking

**Browser Agent (2b)**:
- Browser navigation recording
- WebSocket message recording
- Nostr event recording

**Component Library Agent (2c)**:
- Component lifecycle event recording
- Component state change tracking
- Rendering event recording

### Coordination Requirements

**Change Protocol**:
1. Sub-agent identifies need for DAG Core change
2. Sub-agent coordinates with Aurora 2 Subcore
3. Aurora 2 Subcore coordinates with all affected sub-agents (2a, 2b, 2c)
4. Aurora 2 Subcore approves and implements change
5. All sub-agents update to use new DAG Core version

**Example Changes Requiring Coordination**:
- Event schema changes
- Recording API changes
- Deterministic state management changes
- Performance optimizations affecting API

### Best Practices

**1. Event Recording**
- Record all significant state changes
- Use consistent event schemas
- Maintain event ordering

**2. Deterministic State**
- Ensure state management is deterministic
- Avoid non-deterministic operations in event handlers
- Test for deterministic behavior

**3. Performance**
- Batch event recordings when possible
- Use efficient event serialization
- Monitor DAG size and performance

### Code Examples

**Editor Agent Usage**:
```zig
const DagCore = @import("dag_core.zig").DagCore;

// Record edit operation
fn record_edit(dag: *DagCore, edit: EditOperation) void {
    // Record edit event to DAG
    dag.record_event(.editor_edit, edit);
}
```

**Browser Agent Usage**:
```zig
const DagCore = @import("dag_core.zig").DagCore;

// Record navigation event
fn record_navigation(dag: *DagCore, url: []const u8) void {
    // Record navigation event to DAG
    dag.record_event(.browser_navigation, url);
}
```

**Component Library Usage**:
```zig
const DagCore = @import("dag_core.zig").DagCore;

// Record component state change
fn record_component_state_change(dag: *DagCore, component_id: u32, state: ComponentState) void {
    // Record component state change to DAG
    dag.record_event(.component_state_change, .{component_id, state});
}
```

---

## GrainAurora Rendering Usage

### Overview

**Location**: `src/grain_aurora.zig`  
**Purpose**: Component-first UI rendering engine  
**Shared Between**: All sub-agents (Editor, Browser, Component Library)

### Usage Patterns

**Editor Agent (2a)**:
- Editor UI component rendering
- Diagnostics rendering
- Inlay hints rendering
- Code lens rendering

**Browser Agent (2b)**:
- Browser UI component rendering
- Content area rendering
- Navigation components rendering

**Component Library Agent (2c)**:
- Component rendering integration
- Render context management
- Component tree rendering

### Coordination Requirements

**Change Protocol**:
1. Sub-agent identifies need for GrainAurora change
2. Sub-agent coordinates with Aurora 2 Subcore
3. Aurora 2 Subcore coordinates with all affected sub-agents (2a, 2b, 2c)
4. Aurora 2 Subcore approves and implements change
5. All sub-agents update to use new GrainAurora version

**Example Changes Requiring Coordination**:
- Render context API changes
- Component rendering API changes
- Rendering pipeline changes
- Performance optimizations affecting API

### Best Practices

**1. Render Context**
- Use RenderContext for component rendering
- Pass context through component tree
- Maintain context state correctly

**2. Component Rendering**
- Use component-first rendering patterns
- Keep renders light and efficient
- Batch rendering operations when possible

**3. Bounded Allocations**
- Respect MAX_ constants defined in GrainAurora
- Use bounded rendering operations
- Handle allocation failures gracefully

### Code Examples

**Editor Agent Usage**:
```zig
const GrainAurora = @import("grain_aurora.zig").GrainAurora;

// Render editor component
fn render_editor(context: *GrainAurora.RenderContext) GrainAurora.RenderResult {
    // Render editor using GrainAurora
    // Component-first rendering pattern
}
```

**Browser Agent Usage**:
```zig
const GrainAurora = @import("grain_aurora.zig").GrainAurora;

// Render browser component
fn render_browser(context: *GrainAurora.RenderContext) GrainAurora.RenderResult {
    // Render browser using GrainAurora
    // Component-first rendering pattern
}
```

**Component Library Usage**:
```zig
const GrainAurora = @import("grain_aurora.zig").GrainAurora;

// Render component using GrainAurora
fn render_component(component: *Component, context: *GrainAurora.RenderContext) GrainAurora.RenderResult {
    // Render component using GrainAurora
    // Component rendering integration
}
```

---

## Shared Font Renderer Usage

### Overview

**Location**: `src/shared/`  
**Purpose**: Font rendering utilities  
**Shared Between**: All sub-agents

### Usage Patterns

**All Sub-Agents**:
- Text rendering with fonts
- Font loading and management
- Font metrics and layout

### Coordination Requirements

**Change Protocol**:
1. Sub-agent identifies need for font renderer change
2. Sub-agent coordinates with Aurora 2 Subcore
3. Aurora 2 Subcore coordinates with all affected sub-agents
4. Aurora 2 Subcore approves and implements change
5. All sub-agents update to use new font renderer version

---

## Coordination Checklist

### Before Making Changes

- [ ] Identify which shared module(s) need changes
- [ ] Document proposed changes
- [ ] Check if changes affect API or behavior
- [ ] Coordinate with Aurora 2 Subcore
- [ ] Wait for approval before implementing

### After Making Changes

- [ ] Update shared module implementation
- [ ] Update all affected sub-agents
- [ ] Run integration tests
- [ ] Update documentation
- [ ] Notify Aurora 2 Subcore of completion

---

## Troubleshooting

### Common Issues

**1. Shared Module Conflicts**
- **Symptom**: Multiple sub-agents modifying same module
- **Solution**: Coordinate through Aurora 2 Subcore, use change protocol

**2. API Compatibility Issues**
- **Symptom**: Breaking changes in shared module API
- **Solution**: Coordinate API changes, maintain backward compatibility

**3. Performance Issues**
- **Symptom**: Shared module performance degradation
- **Solution**: Profile shared module usage, optimize hot paths

**4. Integration Issues**
- **Symptom**: Integration tests failing after shared module change
- **Solution**: Update all affected sub-agents, run integration tests

---

## References

**Coordination Strategy**: `docs/architecture/decisions/adr_004_shared_module_coordination_2026-01-02-090305-pst.md`  
**Integration Patterns**: `docs/architecture/aurora_2_integration_patterns_2026-01-02-090305-pst.md`  
**Aurora 2 Subcore Coordination**: `docs/core-coordination/aurora_2_subcore_coordination.md`

---

**Date**: 2026-01-06-100156-pst  
**Agent**: Grain Aurora 2 Subcore Agent (L1 Subcore Coordinator)  
**Status**: ✅ **GUIDE COMPLETE** — Ready for L2 sub-agent reference

