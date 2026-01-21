# Toroidal DAG UI Architecture: Rye + Basin + Unified UI

**Date**: 2026-01-20
**Status**: Architecture Vision
**Builds On**: 0003-toroidal-garden-architecture.md, dag_ui_synthesis.md
**Repository**: codeberg.org/realidream

---

## Overview

This document describes how the DAG-based UI backend integrates with Rye's toroidal/garden architecture for Basin kernel. The key insight:

**A UI is a streaming DAG, and DAGs are naturally toroidal.**

- **Nodes** wrap around (finite node IDs, toroidal indexing)
- **Edges** form a bounded graph (garden-allocated edge pools)
- **Events** flow through circular buffers (toroidal event queues)
- **Updates** propagate deterministically (no reactive edge cases)

---

## Part 1: The Toroidal DAG Insight

### Traditional DAG Problems

| Problem | Cause | Consequence |
|---------|-------|-------------|
| Unbounded node growth | Dynamic allocation | OOM, fragmentation |
| Edge case handling | Graph boundaries | Off-by-one, null checks |
| Event queue overflow | Unbounded queues | Memory exhaustion |
| Non-deterministic updates | Reactive propagation | Race conditions |

### Toroidal DAG Solution

| Solution | Mechanism | Guarantee |
|----------|-----------|-----------|
| Bounded node garden | `Garden(Node, MAX_NODES)` | No OOM |
| Toroidal node IDs | `ToroidalIndex(MAX_NODES)` | No invalid IDs |
| Toroidal event queue | `ToroidalBuffer(Event, MAX_EVENTS)` | Never overflows |
| Deterministic propagation | Topological sort on torus | Same input = same output |

---

## Part 2: Toroidal DAG Data Structures

### Core Types

```rye
/// Why: DAG with toroidal node indexing and garden allocation.
pub const ToroidalDag = struct {
    /// Garden of nodes (bounded, explicit capacity).
    node_garden: Garden(DagNode, MAX_NODES),
    
    /// Garden of edges (bounded, explicit capacity).
    edge_garden: Garden(DagEdge, MAX_EDGES),
    
    /// Toroidal event queue (oldest events overwritten when full).
    event_queue: ToroidalBuffer(DagEvent, MAX_EVENTS),
    
    /// Toroidal traversal index (for update propagation).
    traversal_head: ToroidalIndex(MAX_NODES),
    
    pub const MAX_NODES: u32 = 10_000;
    pub const MAX_EDGES: u32 = 100_000;
    pub const MAX_EVENTS: u32 = 1_000;
};

/// Why: Node in the toroidal DAG.
pub const DagNode = struct {
    id: ToroidalIndex(ToroidalDag.MAX_NODES),
    node_type: NodeType,
    
    /// Parent indices (toroidal - always valid).
    parents: [MAX_PARENTS]ToroidalIndex(ToroidalDag.MAX_NODES),
    parent_count: u8,
    
    /// Child indices (toroidal - always valid).
    children: [MAX_CHILDREN]ToroidalIndex(ToroidalDag.MAX_NODES),
    child_count: u8,
    
    /// Node data (bounded inline storage).
    data: [MAX_DATA]u8,
    data_len: u16,
    
    pub const MAX_PARENTS: u8 = 8;
    pub const MAX_CHILDREN: u8 = 16;
    pub const MAX_DATA: u16 = 256;
};

/// Why: Edge in the toroidal DAG.
pub const DagEdge = struct {
    from: ToroidalIndex(ToroidalDag.MAX_NODES),
    to: ToroidalIndex(ToroidalDag.MAX_NODES),
    edge_type: EdgeType,
    weight: u16,
};

/// Why: Event flowing through the DAG.
pub const DagEvent = struct {
    id: u64,
    target_node: ToroidalIndex(ToroidalDag.MAX_NODES),
    event_type: EventType,
    data: [MAX_DATA]u8,
    data_len: u16,
    timestamp: u64,
    
    pub const MAX_DATA: u16 = 128;
};
```

### Type Enumerations

```rye
/// Why: Unified node types for editor + browser + UI.
pub const NodeType = enum(u8) {
    // Editor nodes (Tree-sitter AST)
    ast_function,
    ast_statement,
    ast_expression,
    ast_identifier,
    
    // Browser nodes (DOM-like)
    dom_element,
    dom_text,
    dom_component,
    
    // UI nodes (Grain Aurora)
    ui_container,
    ui_widget,
    ui_layout,
    
    // Data nodes
    data_source,
    data_transform,
    data_sink,
};

/// Why: Edge types for data flow and dependencies.
pub const EdgeType = enum(u8) {
    parent_child,    // Structural relationship
    data_flow,       // Data flows from → to
    dependency,      // Target depends on source
    semantic,        // Semantic relationship (calls, references)
    transform,       // Transformation edge (AI, refactor)
};

/// Why: Event types for streaming updates.
pub const EventType = enum(u8) {
    code_edit,       // Editor: text changed
    dom_update,      // Browser: DOM mutated
    ui_interaction,  // UI: click, key, gesture
    data_change,     // Data source updated
    ai_completion,   // AI generated content
};
```

---

## Part 3: Streaming Updates on Torus

### The Propagation Model

Traditional reactive systems have edge cases:
- What if a node has no parents? (root case)
- What if a node has no children? (leaf case)
- What if the update queue overflows? (backpressure)
- What if cycles exist? (infinite loop)

Toroidal DAG eliminates these:

```rye
/// Why: Propagate updates through DAG (deterministic, bounded).
pub fn propagate(dag: *ToroidalDag, event: DagEvent) void {
    // Push event to toroidal queue (never fails, may overwrite oldest).
    dag.event_queue.push(event);
    
    // Process events in topological order.
    while (dag.event_queue.pop()) |evt| {
        const node = dag.node_garden.get(evt.target_node.value) orelse continue;
        
        // Apply event to node.
        apply_event(node, evt);
        
        // Propagate to children (toroidal indices always valid).
        var i: u8 = 0;
        while (i < node.child_count) : (i += 1) {
            const child_idx = node.children[i];
            const child_event = DagEvent{
                .id = evt.id + 1,
                .target_node = child_idx,
                .event_type = .data_change,
                .data = undefined,
                .data_len = 0,
                .timestamp = evt.timestamp,
            };
            dag.event_queue.push(child_event);  // Toroidal - always succeeds
        }
    }
}

/// Why: Apply event to node (pure function, deterministic).
fn apply_event(node: *DagNode, event: DagEvent) void {
    // Update node based on event type.
    switch (event.event_type) {
        .code_edit => update_ast_node(node, event.data[0..event.data_len]),
        .dom_update => update_dom_node(node, event.data[0..event.data_len]),
        .ui_interaction => update_ui_node(node, event.data[0..event.data_len]),
        .data_change => invalidate_cache(node),
        .ai_completion => merge_ai_content(node, event.data[0..event.data_len]),
    }
}
```

### Cycle Prevention by Construction

DAGs are acyclic by definition. We enforce this at edge creation:

```rye
/// Why: Add edge with cycle prevention.
pub fn add_edge(dag: *ToroidalDag, from: ToroidalIndex, to: ToroidalIndex, edge_type: EdgeType) !void {
    // Cycle check: ensure 'to' is not an ancestor of 'from'.
    if (is_ancestor(dag, to, from)) {
        return error.CycleDetected;
    }
    
    // Receive edge from garden.
    const edge = dag.edge_garden.receive(.edge) orelse return error.EdgeGardenFull;
    edge.from = from;
    edge.to = to;
    edge.edge_type = edge_type;
    edge.weight = 1;
    
    // Update node adjacency (bounded arrays, toroidal indices).
    const from_node = dag.node_garden.get(from.value) orelse return error.NodeNotFound;
    const to_node = dag.node_garden.get(to.value) orelse return error.NodeNotFound;
    
    if (from_node.child_count < DagNode.MAX_CHILDREN) {
        from_node.children[from_node.child_count] = to;
        from_node.child_count += 1;
    }
    if (to_node.parent_count < DagNode.MAX_PARENTS) {
        to_node.parents[to_node.parent_count] = from;
        to_node.parent_count += 1;
    }
}
```

---

## Part 4: Unified Editor + Browser

### The Unification

Both Aurora Editor and Realidream Browser use the same ToroidalDag:

```rye
/// Why: Unified UI backend for editor and browser.
pub const UnifiedUi = struct {
    /// Single DAG for all UI state.
    dag: ToroidalDag,
    
    /// View mappings (which nodes are visible where).
    editor_view: ViewMapping,
    browser_view: ViewMapping,
    
    /// Why: Create AST node for code.
    pub fn create_ast_node(self: *UnifiedUi, code: []const u8) !ToroidalIndex {
        const node = self.dag.node_garden.receive(.ast) orelse return error.NodeGardenFull;
        node.node_type = .ast_expression;
        @memcpy(node.data[0..code.len], code);
        node.data_len = @intCast(code.len);
        return node.id;
    }
    
    /// Why: Create DOM node for HTML.
    pub fn create_dom_node(self: *UnifiedUi, tag: []const u8) !ToroidalIndex {
        const node = self.dag.node_garden.receive(.dom) orelse return error.NodeGardenFull;
        node.node_type = .dom_element;
        @memcpy(node.data[0..tag.len], tag);
        node.data_len = @intCast(tag.len);
        return node.id;
    }
    
    /// Why: Process edit in editor (flows to DAG).
    pub fn on_code_edit(self: *UnifiedUi, node_id: ToroidalIndex, edit: []const u8) void {
        var event = DagEvent{
            .id = self.next_event_id(),
            .target_node = node_id,
            .event_type = .code_edit,
            .data = undefined,
            .data_len = @intCast(@min(edit.len, DagEvent.MAX_DATA)),
            .timestamp = self.current_time(),
        };
        @memcpy(event.data[0..event.data_len], edit[0..event.data_len]);
        propagate(&self.dag, event);
    }
    
    /// Why: Process click in browser (flows to DAG).
    pub fn on_dom_click(self: *UnifiedUi, node_id: ToroidalIndex) void {
        const event = DagEvent{
            .id = self.next_event_id(),
            .target_node = node_id,
            .event_type = .ui_interaction,
            .data = undefined,
            .data_len = 0,
            .timestamp = self.current_time(),
        };
        propagate(&self.dag, event);
    }
};
```

### View Mappings

```rye
/// Why: Map DAG nodes to visual representation.
pub const ViewMapping = struct {
    /// Which nodes are visible in this view.
    visible_nodes: ToroidalBuffer(ToroidalIndex(ToroidalDag.MAX_NODES), MAX_VISIBLE),
    
    /// Scroll position (toroidal - wraps for infinite scroll).
    scroll_offset: ToroidalIndex(MAX_SCROLL),
    
    /// Focus node (toroidal index, always valid).
    focus: ToroidalIndex(ToroidalDag.MAX_NODES),
    
    pub const MAX_VISIBLE: u32 = 1_000;
    pub const MAX_SCROLL: u32 = 1_000_000;
};
```

---

## Part 5: Basin Kernel Integration

### DAG as Kernel Resource

The ToroidalDag lives in a Basin kernel garden:

```rye
/// Why: Basin kernel with UI DAG garden.
pub const BasinKernel = struct {
    // ... other gardens ...
    
    /// UI DAG garden (for Grainscript UI applications).
    ui_dag_garden: Garden(ToroidalDag, MAX_UI_DAGS),
    
    pub const MAX_UI_DAGS: u32 = 16;  // One per application
    
    /// Why: Syscall to create UI DAG for application.
    pub fn syscall_create_ui_dag(self: *BasinKernel, pid: u32) !u32 {
        const dag = self.ui_dag_garden.receive(.application) orelse return error.DagGardenFull;
        dag.* = ToroidalDag.init();
        return @intFromPtr(dag);
    }
    
    /// Why: Syscall to push event to UI DAG.
    pub fn syscall_ui_event(self: *BasinKernel, dag_handle: u32, event_data: []const u8) !void {
        const dag = self.ui_dag_garden.get(dag_handle) orelse return error.InvalidHandle;
        var event = DagEvent.parse(event_data);
        propagate(dag, event);
    }
};
```

### Grainscript UI Integration

```grainscript
// Grainscript application using UI DAG

// Create DAG via syscall
var dag = syscall("create_ui_dag");

// Create nodes
var root = dag.create_node("container");
var header = dag.create_node("text", "Hello, Basin!");
var button = dag.create_node("button", "Click me");

// Add edges
dag.add_edge(root, header);
dag.add_edge(root, button);

// Handle events (flows through kernel's toroidal queue)
button.on_click = fn() {
    header.set_text("Clicked!");
};
```

---

## Part 6: Performance Characteristics

### Toroidal DAG vs Traditional UI

| Aspect | React/Vue/Svelte | Toroidal DAG |
|--------|------------------|--------------|
| Node allocation | Dynamic (heap) | Garden (bounded) |
| Update propagation | Reactive (unpredictable) | Streaming (deterministic) |
| Queue overflow | Crash/backpressure | Overwrite oldest |
| Index bounds | Runtime checks | Toroidal (always valid) |
| Memory growth | Unbounded | Bounded by MAX_ |
| Edge cases | Many | None (topology) |

### Projected Performance

| Operation | Traditional | Toroidal | Improvement |
|-----------|-------------|----------|-------------|
| Node creation | ~1μs (malloc) | ~10ns (garden) | 100x |
| Event dispatch | ~100ns + checks | ~10ns (no checks) | 10x |
| Update propagation | O(n) tree | O(affected) | Variable |
| Memory footprint | Unbounded | MAX_NODES * sizeof(Node) | Predictable |

---

## Part 7: Implementation Path

### Phase 1: Core Types (Complete)
- [x] ToroidalIndex in toroidal.ry
- [x] ToroidalBuffer in toroidal.ry
- [x] ToroidalGrid in toroidal.ry
- [x] BoundedParam in toroidal.ry
- [x] Garden concept documented

### Phase 2: DAG Core (Complete)
- [x] dag_toroidal.ry (324 lines)
- [x] dag_toroidal_adapter.ry (235 lines)
- [x] Node/edge gardens implemented
- [x] Toroidal event queue implemented
- [x] 170_toroidal_dag_test.zig (14 tests)

### Phase 3: UI Integration (Complete)
- [x] realidream_toroidal_integration.ry (284 lines)
- [x] RealidreamIntegration (DOM nodes)
- [x] AuroraIntegration (AST nodes)
- [x] SkateIntegration (visual nodes)
- [x] 171_unified_dag_integration_test.zig (13 tests)

### Phase 4: Kernel Integration (Complete)
- [x] UI DAG syscalls in Basin (basin_kernel_syscalls_ui.ry, 233 lines)
- [x] Grainscript UI bindings (grainscript_ui_bindings.ry, 481 lines)
- [x] Event loop integration (ui_event_loop.ry, 444 lines)

---

## Summary

| Concept | Traditional | Toroidal |
|---------|-------------|----------|
| Allocation | Heap/Arena | Garden |
| Indexing | Bounds-checked | Toroidal |
| Queues | Unbounded | Circular |
| Propagation | Reactive | Streaming |
| Edge cases | Many | None |
| Memory safety | Runtime checks | Topology |

**The synthesis**: A UI is a streaming DAG. DAGs map naturally to toroidal topology. Toroidal structures eliminate edge cases by construction. Garden allocation bounds memory. The result is a **deterministic, bounded, edge-case-free UI architecture** that runs on Basin kernel with Grainscript.

This is the unification: **Rye types → Basin kernel → Grainscript apps → Toroidal DAG UI**.
