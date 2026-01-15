//! Streaming DAG Updates: Hyperfiddle-style deterministic update propagation.
//! Why: Media workflows need real-time streaming updates as operations complete.
//! Architecture: Updates flow through DAG edges, only affected nodes update.
//!
//! GrainStyle compliance:
//! - grain_case function names
//! - u32/u64 types (not usize/isize)
//! - MAX_ constants for bounded allocations
//! - Assertions for preconditions/postconditions
//! - No recursion (iterative algorithms, stack-based)

const std = @import("std");
const dag_core = @import("dag_core");

/// Streaming update handler for media workflow DAGs.
pub const StreamingUpdates = struct {
    allocator: std.mem.Allocator,
    dag: *dag_core.DagCore,

    // Bounded: Max pending updates per node (explicit limit)
    pub const MAX_PENDING_UPDATES: u32 = 100;

    // Bounded: Max update queue size (explicit limit)
    pub const MAX_UPDATE_QUEUE: u32 = 1000;

    /// Update event for media operations.
    pub const MediaUpdate = struct {
        node_id: u32,
        update_type: MediaUpdateType,
        data: []const u8,
        data_len: u32,
        timestamp: u64,
    };

    /// Type of media update.
    pub const MediaUpdateType = enum(u8) {
        node_ready, // Node execution complete
        node_error, // Node execution failed
        data_loaded, // Image/video data loaded
        transform_applied, // Transform operation complete
        filter_applied, // Filter operation complete
        output_saved, // Output file saved
    };

    /// Initialize streaming updates handler.
    pub fn init(allocator: std.mem.Allocator, dag: *dag_core.DagCore) !StreamingUpdates {
        // Assert: Allocator and DAG must be valid
        std.debug.assert(allocator.ptr != null);
        std.debug.assert(dag.nodes_len <= dag_core.DagCore.MAX_NODES);

        return StreamingUpdates{
            .allocator = allocator,
            .dag = dag,
        };
    }

    /// Propagate update to dependent nodes (Hyperfiddle-style streaming).
    pub fn propagate_update(
        self: *StreamingUpdates,
        update: MediaUpdate,
    ) !void {
        // Assert: Update must be valid
        std.debug.assert(update.node_id < self.dag.nodes_len);
        std.debug.assert(update.data_len <= 10 * 1024 * 1024); // Max 10MB per update

        // Get outgoing edges from updated node
        const outgoing_edges = self.dag.getEdges(update.node_id, false);

        // Assert: Edges must be within bounds
        std.debug.assert(outgoing_edges.len <= dag_core.DagCore.MAX_EDGES);

        // Propagate update to dependent nodes (only affected nodes update)
        for (outgoing_edges) |edge| {
            // Assert: Edge must be valid
            std.debug.assert(edge.to_node < self.dag.nodes_len);

            // Only propagate along data_flow edges (not dependency edges)
            if (edge.edge_type == .data_flow) {
                try self.notify_node_update(edge.to_node, update);
            }
        }
    }

    /// Notify a node of an update (queues event for deterministic processing).
    fn notify_node_update(
        self: *StreamingUpdates,
        node_id: u32,
        update: MediaUpdate,
    ) !void {
        // Assert: Node ID must be valid
        std.debug.assert(node_id < self.dag.nodes_len);

        // Convert MediaUpdate to dag_core.Event for deterministic processing
        const event_type: dag_core.DagCore.EventType = switch (update.update_type) {
            .node_ready => .ai_completion, // Use ai_completion as placeholder for node ready
            .node_error => .code_edit, // Use code_edit as placeholder for node error
            .data_loaded => .web_request, // Use web_request as placeholder for data loaded
            .transform_applied => .ai_completion,
            .filter_applied => .ai_completion,
            .output_saved => .vcs_update, // Use vcs_update as placeholder for output saved
        };

        // Get latest parent events (HashDAG-style)
        const parent_events = try self.get_latest_parent_events();

        // Add event to DAG for deterministic processing
        // Note: addEvent doesn't take timestamp parameter, it uses current time
        const event_id = try self.dag.addEvent(
            event_type,
            node_id,
            update.data[0..update.data_len],
            parent_events,
        );

        // Assert: Event ID must be valid (non-zero)
        std.debug.assert(event_id > 0);
    }

    /// Get latest parent events (HashDAG-style for deterministic ordering).
    fn get_latest_parent_events(self: *StreamingUpdates) ![]const u64 {
        // Assert: DAG must be valid
        std.debug.assert(self.dag.pending_events_len <= dag_core.DagCore.MAX_PENDING_EVENTS);

        // For now, return empty parent events (single-threaded deterministic)
        // In full HashDAG implementation, this would return actual parent event IDs
        // TODO: Implement full HashDAG parent tracking
        return &[_]u64{};
    }

    /// Process all pending streaming updates (called after workflow execution).
    pub fn process_pending_updates(self: *StreamingUpdates) !void {
        // Assert: DAG must be valid
        std.debug.assert(self.dag.pending_events_len <= dag_core.DagCore.MAX_PENDING_EVENTS);

        // Process events deterministically (TigerBeetle-style)
        try self.dag.processEvents();
    }

    /// Create media update from node execution result.
    pub fn create_update(
        self: *StreamingUpdates,
        node_id: u32,
        update_type: MediaUpdateType,
        data: []const u8,
    ) !MediaUpdate {
        // Assert: Node ID and data must be valid
        std.debug.assert(node_id < self.dag.nodes_len);
        std.debug.assert(data.len <= 10 * 1024 * 1024); // Max 10MB per update

        // Get current timestamp (Unix seconds)
        const timestamp = @as(u64, @intFromFloat(std.time.timestamp()));

        return MediaUpdate{
            .node_id = node_id,
            .update_type = update_type,
            .data = data,
            .data_len = @as(u32, @intCast(data.len)),
            .timestamp = timestamp,
        };
    }

    /// Deinitialize streaming updates handler.
    pub fn deinit(self: *StreamingUpdates) void {
        // Assert: DAG must still be valid
        std.debug.assert(self.dag.nodes_len <= dag_core.DagCore.MAX_NODES);
        // No cleanup needed (DAG owns data)
    }
};
