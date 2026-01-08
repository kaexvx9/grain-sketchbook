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
const streaming = @import("streaming.zig");

/// DAG UI Synthesis: Media workflow engine using DAG architecture.
pub const DagSynthesis = struct {
    allocator: std.mem.Allocator,
    dag: dag_core.DagCore,
    streaming_updates: ?streaming.StreamingUpdates,
    node_results: std.HashMapUnmanaged(u32, grainflow_media.GrainflowEngine.Image, std.hash_map.getAutoHashFn(u32), std.hash_map.getAutoEqlFn(u32)),

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

        // Initialize streaming updates (optional, can be enabled later)
        const streaming_updates = try streaming.StreamingUpdates.init(allocator, &dag);

        const node_results = std.HashMapUnmanaged(u32, grainflow_media.GrainflowEngine.Image, std.hash_map.getAutoHashFn(u32), std.hash_map.getAutoEqlFn(u32)){};

        return DagSynthesis{
            .allocator = allocator,
            .dag = dag,
            .streaming_updates = streaming_updates,
            .node_results = node_results,
        };
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

        // Process streaming updates (Hyperfiddle-style deterministic propagation)
        if (self.streaming_updates) |*updates| {
            try updates.process_pending_updates();
        }
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

        // Execute based on node type
        switch (node.node_type) {
            .data_source => {
                // Load image from path (data contains file path)
                const image = try engine.load_image(node.data[0..node.data_len]);

                // Store image result for dependent nodes
                try self.node_results.put(self.allocator, node_id, image);

                // Notify streaming updates (Hyperfiddle-style)
                if (self.streaming_updates) |*updates| {
                    const update = try updates.create_update(
                        node_id,
                        .data_loaded,
                        node.data[0..node.data_len],
                    );
                    try updates.propagate_update(update);
                }
            },
            .computation => {
                // Get input images from parent nodes (data flow edges)
                const incoming_edges = self.dag.getEdges(node_id, true);
                var input_images = std.ArrayList(grainflow_media.GrainflowEngine.Image).init(self.allocator);
                defer {
                    // Defer cleanup of input images (will be freed after computation)
                    for (input_images.items) |*img| {
                        img.deinit();
                    }
                    input_images.deinit();
                }

                // Collect input images from parent nodes
                for (incoming_edges) |edge| {
                    if (edge.edge_type == .data_flow) {
                        if (self.node_results.get(edge.from_node)) |parent_image| {
                            // Clone image for computation (to avoid ownership issues)
                            const cloned_pixels = try self.allocator.alloc(u8, parent_image.pixels.len);
                            @memcpy(cloned_pixels, parent_image.pixels);

                            const cloned_image = grainflow_media.GrainflowEngine.Image{
                                .width = parent_image.width,
                                .height = parent_image.height,
                                .format = parent_image.format,
                                .pixels = cloned_pixels,
                                .allocator = self.allocator,
                            };
                            try input_images.append(cloned_image);
                        }
                    }
                }

                // Process media operation (transform, filter, composition, output)
                // TODO: Parse node data to determine operation type
                // TODO: Execute operation using engine with input_images
                // For now, use first input image as output (placeholder)
                if (input_images.items.len > 0) {
                    const output_image = input_images.items[0];
                    // Store result for dependent nodes (ownership transferred)
                    try self.node_results.put(self.allocator, node_id, output_image);
                    _ = input_images.swapRemove(0); // Remove from cleanup list
                }

                // Notify streaming updates (Hyperfiddle-style)
                if (self.streaming_updates) |*updates| {
                    const update = try updates.create_update(
                        node_id,
                        .node_ready,
                        node.data[0..node.data_len],
                    );
                    try updates.propagate_update(update);
                }
            },
            else => {
                // Other node types not supported for media workflows
                return error.InvalidNodeType;
            },
        }
    }

    /// Deinitialize DAG synthesis and free all resources.
    pub fn deinit(self: *DagSynthesis) void {
        // Assert: DAG must be valid
        std.debug.assert(self.dag.nodes_len <= MAX_WORKFLOW_NODES);

        // Free stored node results
        var result_iter = self.node_results.iterator();
        while (result_iter.next()) |entry| {
            entry.value_ptr.deinit();
        }
        self.node_results.deinit(self.allocator);

        // Deinitialize DAG
        self.dag.deinit();

        // Deinitialize streaming updates (if initialized)
        if (self.streaming_updates) |*updates| {
            updates.deinit();
        }
    }
};

