//! Toroidal DAG: Unified UI Backend for Basin Kernel
//! Why: DAG-based UI with toroidal indexing and garden allocation.
//! See: docs/rye/0005-toroidal-dag-ui-architecture.md

const std = @import("std");
const toroidal = @import("toroidal.zig");
const ToroidalIndex = toroidal.ToroidalIndex;
const ToroidalBuffer = toroidal.ToroidalBuffer;

/// Why: Maximum nodes in DAG (bounded, garden-allocated).
pub const MAX_NODES: u32 = 10_000;

/// Why: Maximum edges in DAG (bounded, garden-allocated).
pub const MAX_EDGES: u32 = 100_000;

/// Why: Maximum pending events (toroidal queue).
pub const MAX_EVENTS: u32 = 1_000;

/// Why: Maximum parents per node.
pub const MAX_PARENTS: u8 = 8;

/// Why: Maximum children per node.
pub const MAX_CHILDREN: u8 = 16;

/// Why: Maximum data per node (inline storage).
pub const MAX_NODE_DATA: u16 = 256;

/// Why: Maximum data per event.
pub const MAX_EVENT_DATA: u16 = 128;

/// Why: Unified node types for editor, browser, and UI.
pub const NodeType = enum(u8) {
    empty,
    ast_function,
    ast_statement,
    ast_expression,
    ast_identifier,
    dom_element,
    dom_text,
    dom_component,
    ui_container,
    ui_widget,
    ui_layout,
    data_source,
    data_transform,
    data_sink,
};

/// Why: Edge types for data flow and dependencies.
pub const EdgeType = enum(u8) {
    none,
    parent_child,
    data_flow,
    dependency,
    semantic,
    transform,
};

/// Why: Event types for streaming updates.
pub const EventType = enum(u8) {
    none,
    code_edit,
    dom_update,
    ui_interaction,
    data_change,
    ai_completion,
};

/// Why: Node in the toroidal DAG.
pub const DagNode = struct {
    id: u32,
    node_type: NodeType,
    allocated: bool,
    parent_count: u8,
    child_count: u8,
    parents: [MAX_PARENTS]u32,
    children: [MAX_CHILDREN]u32,
    data: [MAX_NODE_DATA]u8,
    data_len: u16,

    /// Why: Initialize empty node.
    pub fn init() DagNode {
        return DagNode{
            .id = 0,
            .node_type = .empty,
            .allocated = false,
            .parent_count = 0,
            .child_count = 0,
            .parents = [_]u32{0} ** MAX_PARENTS,
            .children = [_]u32{0} ** MAX_CHILDREN,
            .data = [_]u8{0} ** MAX_NODE_DATA,
            .data_len = 0,
        };
    }

    /// Why: Add parent to node (bounded).
    pub fn add_parent(self: *DagNode, parent_id: u32) bool {
        if (self.parent_count >= MAX_PARENTS) return false;
        self.parents[self.parent_count] = parent_id;
        self.parent_count += 1;
        return true;
    }

    /// Why: Add child to node (bounded).
    pub fn add_child(self: *DagNode, child_id: u32) bool {
        if (self.child_count >= MAX_CHILDREN) return false;
        self.children[self.child_count] = child_id;
        self.child_count += 1;
        return true;
    }
};

/// Why: Edge in the toroidal DAG.
pub const DagEdge = struct {
    from: u32,
    to: u32,
    edge_type: EdgeType,
    weight: u16,
    allocated: bool,

    /// Why: Initialize empty edge.
    pub fn init() DagEdge {
        return DagEdge{ .from = 0, .to = 0, .edge_type = .none, .weight = 0, .allocated = false };
    }
};

/// Why: Event flowing through the DAG.
pub const DagEvent = struct {
    id: u64,
    target_node: u32,
    event_type: EventType,
    data: [MAX_EVENT_DATA]u8,
    data_len: u16,
    timestamp: u64,

    /// Why: Initialize empty event.
    pub fn init() DagEvent {
        return DagEvent{
            .id = 0,
            .target_node = 0,
            .event_type = .none,
            .data = [_]u8{0} ** MAX_EVENT_DATA,
            .data_len = 0,
            .timestamp = 0,
        };
    }
};

/// Why: Toroidal DAG with garden allocation.
pub const ToroidalDag = struct {
    nodes: [MAX_NODES]DagNode,
    node_count: u32,
    edges: [MAX_EDGES]DagEdge,
    edge_count: u32,
    events: ToroidalBuffer(DagEvent, MAX_EVENTS),
    next_node_id: u32,
    next_event_id: u64,

    /// Why: Initialize empty DAG.
    pub fn init() ToroidalDag {
        var dag = ToroidalDag{
            .nodes = undefined,
            .node_count = 0,
            .edges = undefined,
            .edge_count = 0,
            .events = ToroidalBuffer(DagEvent, MAX_EVENTS).init(),
            .next_node_id = 1,
            .next_event_id = 1,
        };
        for (&dag.nodes) |*n| n.* = DagNode.init();
        for (&dag.edges) |*e| e.* = DagEdge.init();
        return dag;
    }

    /// Why: Create node (garden allocation).
    pub fn create_node(self: *ToroidalDag, node_type: NodeType) ?u32 {
        if (self.node_count >= MAX_NODES) return null;
        const slot = self.find_free_node_slot() orelse return null;
        self.nodes[slot].id = self.next_node_id;
        self.nodes[slot].node_type = node_type;
        self.nodes[slot].allocated = true;
        self.next_node_id += 1;
        self.node_count += 1;
        return self.nodes[slot].id;
    }

    fn find_free_node_slot(self: *ToroidalDag) ?usize {
        for (self.nodes, 0..) |*n, i| {
            if (!n.allocated) return i;
        }
        return null;
    }

    /// Why: Get node by ID (toroidal - wraps).
    pub fn get_node(self: *ToroidalDag, id: u32) ?*DagNode {
        for (&self.nodes) |*n| {
            if (n.allocated and n.id == id) return n;
        }
        return null;
    }

    /// Why: Add edge between nodes.
    pub fn add_edge(self: *ToroidalDag, from: u32, to: u32, edge_type: EdgeType) bool {
        if (self.edge_count >= MAX_EDGES) return false;
        const from_node = self.get_node(from) orelse return false;
        const to_node = self.get_node(to) orelse return false;
        if (!from_node.add_child(to)) return false;
        if (!to_node.add_parent(from)) return false;
        const slot = self.find_free_edge_slot() orelse return false;
        self.edges[slot] = DagEdge{ .from = from, .to = to, .edge_type = edge_type, .weight = 1, .allocated = true };
        self.edge_count += 1;
        return true;
    }

    fn find_free_edge_slot(self: *ToroidalDag) ?usize {
        for (self.edges, 0..) |*e, i| {
            if (!e.allocated) return i;
        }
        return null;
    }

    /// Why: Push event to toroidal queue.
    pub fn push_event(self: *ToroidalDag, target: u32, event_type: EventType, data: []const u8) void {
        var event = DagEvent.init();
        event.id = self.next_event_id;
        event.target_node = target;
        event.event_type = event_type;
        event.timestamp = 0;
        const len = @min(data.len, MAX_EVENT_DATA);
        @memcpy(event.data[0..len], data[0..len]);
        event.data_len = @intCast(len);
        self.events.push(event);
        self.next_event_id += 1;
    }

    /// Why: Process pending events (propagate through DAG).
    pub fn process_events(self: *ToroidalDag) u32 {
        var processed: u32 = 0;
        while (self.events.pop()) |event| {
            self.apply_event(event);
            processed += 1;
        }
        return processed;
    }

    fn apply_event(self: *ToroidalDag, event: DagEvent) void {
        const node = self.get_node(event.target_node) orelse return;
        switch (event.event_type) {
            .code_edit, .dom_update => self.update_node_data(node, event.data[0..event.data_len]),
            .ui_interaction => self.mark_node_dirty(node),
            .data_change => self.propagate_to_children(node, event),
            .ai_completion => self.merge_ai_data(node, event.data[0..event.data_len]),
            .none => {},
        }
    }

    fn update_node_data(self: *ToroidalDag, node: *DagNode, data: []const u8) void {
        _ = self;
        const len = @min(data.len, MAX_NODE_DATA);
        @memcpy(node.data[0..len], data[0..len]);
        node.data_len = @intCast(len);
    }

    fn mark_node_dirty(self: *ToroidalDag, node: *DagNode) void {
        _ = self;
        _ = node;
    }

    fn propagate_to_children(self: *ToroidalDag, node: *DagNode, event: DagEvent) void {
        var i: u8 = 0;
        while (i < node.child_count) : (i += 1) {
            self.push_event(node.children[i], .data_change, event.data[0..event.data_len]);
        }
    }

    fn merge_ai_data(self: *ToroidalDag, node: *DagNode, data: []const u8) void {
        _ = self;
        const len = @min(data.len, MAX_NODE_DATA);
        @memcpy(node.data[0..len], data[0..len]);
        node.data_len = @intCast(len);
    }

    /// Why: Release node back to garden.
    pub fn release_node(self: *ToroidalDag, id: u32) bool {
        const node = self.get_node(id) orelse return false;
        node.* = DagNode.init();
        self.node_count -= 1;
        return true;
    }
};
