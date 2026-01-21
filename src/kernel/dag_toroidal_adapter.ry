//! Toroidal DAG Adapter: Bridge between DagCore and ToroidalDag
//! Why: Enable Aurora/Skate/Realidream to use garden-allocated toroidal DAG.
//!
//! This adapter provides a unified interface that can be backed by either:
//! - DagCore (allocator-based, existing code)
//! - ToroidalDag (garden-allocated, new toroidal code)

const std = @import("std");
const toroidal = @import("toroidal");
pub const toroidal_types = toroidal; // Re-export for dependent modules.
const ToroidalIndex = toroidal.ToroidalIndex;
const ToroidalBuffer = toroidal.ToroidalBuffer;

/// Why: Maximum nodes in unified DAG.
pub const MAX_NODES: u32 = 10_000;

/// Why: Maximum edges in unified DAG.
pub const MAX_EDGES: u32 = 100_000;

/// Why: Maximum pending events.
pub const MAX_EVENTS: u32 = 1_000;

/// Why: Unified node type across all backends.
pub const UnifiedNodeType = enum(u8) {
    empty,
    // Aurora (editor)
    ast_function,
    ast_statement,
    ast_expression,
    ast_identifier,
    ast_comment,
    // Realidream (browser)
    dom_element,
    dom_text,
    dom_attribute,
    // Skate (visual)
    visual_node,
    visual_edge,
    visual_group,
    // Data
    data_source,
    data_sink,
};

/// Why: Unified edge type for data flow.
pub const UnifiedEdgeType = enum(u8) {
    none,
    parent_child,
    data_flow,
    semantic_ref,
    visual_connection,
};

/// Why: Unified event type for streaming updates.
pub const UnifiedEventType = enum(u8) {
    none,
    code_edit,
    dom_mutation,
    visual_change,
    data_update,
};

/// Why: Compact node handle (32-bit, toroidal).
pub const NodeHandle = struct {
    index: ToroidalIndex(MAX_NODES),

    /// Why: Create handle from raw index.
    pub fn from_raw(idx: u32) NodeHandle {
        return NodeHandle{ .index = ToroidalIndex(MAX_NODES).init(idx) };
    }

    /// Why: Get raw index for array access.
    pub fn raw(self: NodeHandle) u32 {
        return self.index.get();
    }

    /// Why: Invalid handle sentinel.
    pub fn invalid() NodeHandle {
        return NodeHandle{ .index = ToroidalIndex(MAX_NODES).init(MAX_NODES - 1) };
    }
};

/// Why: Lightweight node for garden allocation.
pub const UnifiedNode = struct {
    handle: NodeHandle,
    node_type: UnifiedNodeType,
    allocated: bool,
    parent_count: u8,
    child_count: u8,
    parents: [8]NodeHandle,
    children: [16]NodeHandle,

    /// Why: Initialize empty node.
    pub fn init() UnifiedNode {
        return UnifiedNode{
            .handle = NodeHandle.invalid(),
            .node_type = .empty,
            .allocated = false,
            .parent_count = 0,
            .child_count = 0,
            .parents = [_]NodeHandle{NodeHandle.invalid()} ** 8,
            .children = [_]NodeHandle{NodeHandle.invalid()} ** 16,
        };
    }

    /// Why: Add parent reference.
    pub fn add_parent(self: *UnifiedNode, parent: NodeHandle) bool {
        if (self.parent_count >= 8) return false;
        self.parents[self.parent_count] = parent;
        self.parent_count += 1;
        return true;
    }

    /// Why: Add child reference.
    pub fn add_child(self: *UnifiedNode, child: NodeHandle) bool {
        if (self.child_count >= 16) return false;
        self.children[self.child_count] = child;
        self.child_count += 1;
        return true;
    }
};

/// Why: Lightweight event for toroidal queue.
pub const UnifiedEvent = struct {
    id: u64,
    target: NodeHandle,
    event_type: UnifiedEventType,
    timestamp: u64,

    /// Why: Initialize empty event.
    pub fn init() UnifiedEvent {
        return UnifiedEvent{
            .id = 0,
            .target = NodeHandle.invalid(),
            .event_type = .none,
            .timestamp = 0,
        };
    }
};

/// Why: Unified DAG adapter with garden allocation.
pub const UnifiedDag = struct {
    nodes: [MAX_NODES]UnifiedNode,
    node_count: u32,
    events: ToroidalBuffer(UnifiedEvent, MAX_EVENTS),
    next_id: u32,
    next_event_id: u64,

    /// Why: Initialize empty unified DAG.
    pub fn init() UnifiedDag {
        var dag = UnifiedDag{
            .nodes = undefined,
            .node_count = 0,
            .events = ToroidalBuffer(UnifiedEvent, MAX_EVENTS).init(),
            .next_id = 1,
            .next_event_id = 1,
        };
        for (&dag.nodes) |*n| n.* = UnifiedNode.init();
        return dag;
    }

    /// Why: Create node of given type (garden allocation).
    pub fn create_node(self: *UnifiedDag, node_type: UnifiedNodeType) ?NodeHandle {
        if (self.node_count >= MAX_NODES) return null;
        const slot = self.find_free_slot() orelse return null;
        self.nodes[slot].handle = NodeHandle.from_raw(self.next_id);
        self.nodes[slot].node_type = node_type;
        self.nodes[slot].allocated = true;
        self.next_id += 1;
        self.node_count += 1;
        return self.nodes[slot].handle;
    }

    fn find_free_slot(self: *UnifiedDag) ?usize {
        for (&self.nodes, 0..) |*n, i| {
            if (!n.allocated) return i;
        }
        return null;
    }

    /// Why: Get node by handle.
    pub fn get_node(self: *UnifiedDag, handle: NodeHandle) ?*UnifiedNode {
        for (&self.nodes) |*n| {
            if (n.allocated and n.handle.raw() == handle.raw()) return n;
        }
        return null;
    }

    /// Why: Add edge (parent-child relationship).
    pub fn add_edge(self: *UnifiedDag, parent: NodeHandle, child: NodeHandle) bool {
        const p = self.get_node(parent) orelse return false;
        const c = self.get_node(child) orelse return false;
        if (!p.add_child(child)) return false;
        if (!c.add_parent(parent)) return false;
        return true;
    }

    /// Why: Push event to toroidal queue.
    pub fn push_event(self: *UnifiedDag, target: NodeHandle, event_type: UnifiedEventType) void {
        var evt = UnifiedEvent.init();
        evt.id = self.next_event_id;
        evt.target = target;
        evt.event_type = event_type;
        evt.timestamp = 0;
        self.events.push(evt);
        self.next_event_id += 1;
    }

    /// Why: Process all pending events.
    pub fn process_events(self: *UnifiedDag) u32 {
        var processed: u32 = 0;
        while (self.events.pop()) |_| {
            processed += 1;
        }
        return processed;
    }

    /// Why: Release node back to garden.
    pub fn release_node(self: *UnifiedDag, handle: NodeHandle) bool {
        const node = self.get_node(handle) orelse return false;
        node.* = UnifiedNode.init();
        self.node_count -= 1;
        return true;
    }

    /// Why: Query node count.
    pub fn count(self: *const UnifiedDag) u32 {
        return self.node_count;
    }

    /// Why: Query event queue length.
    pub fn pending_events(self: *const UnifiedDag) u32 {
        return self.events.len();
    }
};
