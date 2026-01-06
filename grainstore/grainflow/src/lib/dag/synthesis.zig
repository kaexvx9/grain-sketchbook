//! DAG UI Synthesis: Streaming DAG-based UI workflow engine.
//! Why: Hyperfiddle-inspired streaming DAG architecture for media workflows.
//! Architecture: Media operations as DAG nodes, data flow as DAG edges.
//!
//! GrainStyle compliance:
//! - grain_case function names
//! - u32/u64 types (not usize/isize)
//! - MAX_ constants for bounded allocations
//! - Assertions for preconditions/postconditions
//! - No recursion (iterative algorithms, stack-based)

const std = @import("std");
const dag_core = @import("dag_core");
const grainflow_media = @import("grainflow_media");

/// DAG UI Synthesis: Media workflow engine using DAG architecture.
pub const DagSynthesis = struct {
    allocator: std.mem.Allocator,
    dag: dag_core.DagCore,

    // Bounded: Max workflow nodes (explicit limit)
    pub const MAX_WORKFLOW_NODES: u32 = 1000;

    // Bounded: Max workflow edges (explicit limit)
    pub const MAX_WORKFLOW_EDGES: u32 = 2000;

    /// Media operation node type.
    pub const MediaNodeType = enum(u8) {
        data_source, // Load image/video
        transform, // Crop, resize, rotate
        filter, // Apply filter (blur, sharpen, color adjust)
        composition, // Composite multiple images
        output, // Save to file
    };

    /// Media operation edge type.
    pub const MediaEdgeType = enum(u8) {
        data_flow, // Image data flows from source to target
        dependency, // Operation depends on another
        parallel, // Parallel execution (batch processing)
    };

    /// Initialize DAG synthesis engine.
    pub fn init(allocator: std.mem.Allocator) !DagSynthesis {
        // Assert: Allocator must be valid
        std.debug.assert(allocator.ptr != null);

        const dag = try dag_core.DagCore.init(allocator);

        return DagSynthesis{
            .allocator = allocator,
            .dag = dag,
        };
    }

    /// Deinitialize DAG synthesis engine.
    pub fn deinit(self: *DagSynthesis) void {
        // Assert: DAG must be valid
        std.debug.assert(self.dag.allocator.ptr != null);

        self.dag.deinit();
    }

    /// Create media operation node.
    pub fn create_media_node(
        self: *DagSynthesis,
        node_type: MediaNodeType,
        data: []const u8,
    ) !u32 {
        // Assert: Data must be non-empty
        std.debug.assert(data.len > 0);
        std.debug.assert(self.dag.nodes_len < dag_core.DagCore.MAX_NODES);
        std.debug.assert(data.len <= MAX_WORKFLOW_NODES);

        // Convert MediaNodeType to DagCore.NodeType
        const dag_node_type: dag_core.DagCore.NodeType = switch (node_type) {
            .data_source => .data_source,
            .transform => .computation,
            .filter => .computation,
            .composition => .computation,
            .output => .computation,
        };

        // Create DAG node using dag_core API (data is copied internally)
        const attributes = dag_core.DagCore.Attributes{
            .is_readonly = false,
            .readonly_start = 0,
            .readonly_end = 0,
            .metadata = "",
            .metadata_len = 0,
        };

        const node_id = try self.dag.addNode(
            dag_node_type,
            data,
            attributes,
        );

        return node_id;
    }

    /// Create media operation edge.
    pub fn create_media_edge(
        self: *DagSynthesis,
        from_node: u32,
        to_node: u32,
        edge_type: MediaEdgeType,
    ) !void {
        // Assert: Node IDs must be valid
        std.debug.assert(from_node < self.dag.nodes_len);
        std.debug.assert(to_node < self.dag.nodes_len);
        std.debug.assert(self.dag.edges_len < dag_core.DagCore.MAX_EDGES);
        std.debug.assert(self.dag.edges_len < MAX_WORKFLOW_EDGES);

        // Convert MediaEdgeType to DagCore.EdgeType
        const dag_edge_type: dag_core.DagCore.EdgeType = switch (edge_type) {
            .data_flow => .data_flow,
            .dependency => .dependency,
            .parallel => .data_flow,
        };

        // Create DAG edge using dag_core API
        try self.dag.addEdge(
            from_node,
            to_node,
            dag_edge_type,
        );
    }

    /// Execute media workflow (DAG execution).
    /// Uses topological sort to execute nodes in dependency order.
    pub fn execute_workflow(
        self: *DagSynthesis,
        engine: *grainflow_media.GrainflowEngine,
    ) !void {
        // Assert: Engine must be valid
        std.debug.assert(engine.allocator.ptr != null);
        std.debug.assert(self.dag.nodes_len > 0);
        std.debug.assert(self.dag.nodes_len <= MAX_WORKFLOW_NODES);

        // Topological sort: Find nodes with no incoming edges (ready nodes)
        var in_degree = try self.allocator.alloc(u32, self.dag.nodes_len);
        defer self.allocator.free(in_degree);
        @memset(in_degree, 0);

        // Calculate in-degree for each node
        var i: u32 = 0;
        while (i < self.dag.edges_len) : (i += 1) {
            const edge = &self.dag.edges[i];
            std.debug.assert(edge.to_node < self.dag.nodes_len);
            in_degree[edge.to_node] += 1;
        }

        // Find ready nodes (in-degree == 0)
        var ready_nodes = try self.allocator.alloc(u32, self.dag.nodes_len);
        defer self.allocator.free(ready_nodes);
        var ready_count: u32 = 0;

        i = 0;
        while (i < self.dag.nodes_len) : (i += 1) {
            if (in_degree[i] == 0) {
                ready_nodes[ready_count] = i;
                ready_count += 1;
            }
        }

        // Execute nodes in topological order
        var processed: u32 = 0;
        while (processed < ready_count) {
            const node_id = ready_nodes[processed];
            const node = self.dag.getNode(node_id);
            std.debug.assert(node != null);

            // Execute node based on type
            _ = try self.execute_media_node(engine, node_id, node.?);

            // Update in-degrees of dependent nodes
            i = 0;
            while (i < self.dag.edges_len) : (i += 1) {
                const edge = &self.dag.edges[i];
                if (edge.from_node == node_id) {
                    std.debug.assert(in_degree[edge.to_node] > 0);
                    in_degree[edge.to_node] -= 1;
                    if (in_degree[edge.to_node] == 0) {
                        ready_nodes[ready_count] = edge.to_node;
                        ready_count += 1;
                    }
                }
            }

            processed += 1;
        }

        // Assert: All nodes processed
        std.debug.assert(processed == self.dag.nodes_len);
    }

    /// Execute a single media operation node.
    fn execute_media_node(
        self: *DagSynthesis,
        engine: *grainflow_media.GrainflowEngine,
        node_id: u32,
        node: *const dag_core.DagCore.Node,
    ) !void {
        // Assert: Node must be valid
        std.debug.assert(node.id == node_id);
        std.debug.assert(engine.allocator.ptr != null);
        _ = self; // Will be used for node state management

        // Execute based on node type
        switch (node.node_type) {
            .data_source => {
                // Load image from path (data contains file path)
                const image = try engine.load_image(node.data[0..node.data_len]);
                defer image.deinit();
                // TODO: Store image result for dependent nodes
            },
            .computation => {
                // Process media operation (transform, filter, composition, output)
                // TODO: Parse node data to determine operation type
                // TODO: Execute operation using engine
                // Engine will be used for media operations
                _ = engine.allocator;
            },
            else => {
                // Other node types not supported for media workflows
                return error.InvalidNodeType;
            },
        }
    }
};

