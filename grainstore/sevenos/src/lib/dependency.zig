//! dependency: Service dependency management for sevenos-init
//!
//! this module provides dependency resolution and service startup
//! ordering for sevenos-init services.
//!
//! **what are service dependencies?**
//!
//! imagine you have a web server that needs a database. the web
//! server can't start until the database is running. dependencies
//! let you express this relationship, and the dependency manager
//! ensures services start in the correct order.
//!
//! the dependency manager:
//! - builds a dependency graph from service configurations
//! - detects circular dependencies (A depends on B, B depends on A)
//! - computes startup order (topological sort)
//! - enables parallel startup for independent services
//!
//! **grain style principles applied:**
//! - explicit validation (detect cycles early)
//! - clear error messages (help users fix dependency issues)
//! - bounded operations (max dependencies, max services)
//! - decomplected design (graph building separate from sorting)

const std = @import("std");
const supervision = @import("supervision");
const ServiceConfig = supervision.ServiceConfig;

// maximum services in dependency graph (aligned with supervision)
const MAX_SERVICES: u32 = 256;

// maximum dependencies per service (aligned with config loader)
const MAX_DEPENDENCIES: u32 = 16;

// type alias for ArrayListUnmanaged (zig 0.15 compatibility)
const ArrayListU32 = std.ArrayListUnmanaged(u32);

// dependency error types
// grain style: explicit error types make error handling clear
pub const DependencyError = error{
    CircularDependency,
    UnknownDependency,
    TooManyServices,
    InvalidGraph,
};

// service dependency graph
// grain style: explicit graph structure with bounded limits
pub const DependencyGraph = struct {
    // service names (indexed by service index)
    service_names: []const []const u8,

    // adjacency list: for each service, list of dependency indices
    // graph[i] contains indices of services that service i depends on
    // grain style: using slice for dynamic sizing with bounded max
    graph: []ArrayListU32,

    // reverse graph: for each service, list of dependents
    // reverse_graph[i] contains indices of services that depend on i
    reverse_graph: []ArrayListU32,

    // in-degree count for each service (for Kahn's algorithm)
    in_degree: []u32,

    // actual number of services (<= MAX_SERVICES)
    service_count: u32,

    allocator: std.mem.Allocator,

    // build dependency graph from service configurations
    // grain style: explicit graph construction with validation
    pub fn init(
        allocator: std.mem.Allocator,
        configs: []const ServiceConfig,
    ) !DependencyGraph {
        if (configs.len > MAX_SERVICES) {
            return DependencyError.TooManyServices;
        }

        const count = @as(u32, @intCast(configs.len));

        // allocate service names
        const service_names = try allocator.alloc([]const u8, count);
        errdefer allocator.free(service_names);

        // allocate graph structures (arrays of ArrayLists)
        const graph_slice = try allocator.alloc(ArrayListU32, count);
        errdefer {
            for (graph_slice) |*list| {
                list.deinit(allocator);
            }
            allocator.free(graph_slice);
        }

        const reverse_graph_slice = try allocator.alloc(ArrayListU32, count);
        errdefer {
            for (reverse_graph_slice) |*list| {
                list.deinit(allocator);
            }
            allocator.free(reverse_graph_slice);
        }

        const in_degree_slice = try allocator.alloc(u32, count);
        errdefer allocator.free(in_degree_slice);

        // initialize structures
        for (0..count) |i| {
            service_names[i] = configs[i].name;
            // zig 0.15: use ArrayListUnmanaged with .{} initialization
            graph_slice[i] = .{};
            reverse_graph_slice[i] = .{};
            in_degree_slice[i] = 0;
        }

        // build dependency edges
        for (configs, 0..) |config, i| {
            const service_idx = @as(u32, @intCast(i));

            for (config.dependencies) |dep_name| {
                // find dependency index
                const dep_idx = find_service_index(configs, dep_name) orelse {
                    return DependencyError.UnknownDependency;
                };

                // add edge: service depends on dep
                try graph_slice[service_idx].append(allocator, dep_idx);
                try reverse_graph_slice[dep_idx].append(allocator, service_idx);
                in_degree_slice[service_idx] += 1;
            }
        }

        return DependencyGraph{
            .service_names = service_names,
            .graph = graph_slice,
            .reverse_graph = reverse_graph_slice,
            .in_degree = in_degree_slice,
            .service_count = count,
            .allocator = allocator,
        };
    }

    // deinitialize dependency graph
    pub fn deinit(self: *DependencyGraph) void {
        for (self.graph) |*list| {
            list.deinit(self.allocator);
        }
        for (self.reverse_graph) |*list| {
            list.deinit(self.allocator);
        }
        self.allocator.free(self.graph);
        self.allocator.free(self.reverse_graph);
        self.allocator.free(self.in_degree);
        self.allocator.free(self.service_names);
    }

    // find service index by name
    fn find_service_index(
        configs: []const ServiceConfig,
        name: []const u8,
    ) ?u32 {
        for (configs, 0..) |config, i| {
            if (std.mem.eql(u8, config.name, name)) {
                return @as(u32, @intCast(i));
            }
        }
        return null;
    }

    // compute topological sort (Kahn's algorithm)
    // grain style: explicit algorithm with clear steps
    pub fn topological_sort(self: *DependencyGraph) ![]u32 {
        const service_count = self.service_count;
        var result = ArrayListU32{};
        errdefer result.deinit(self.allocator);

        // initialize in-degree copy (don't modify original)
        var in_degree_copy = try self.allocator.alloc(u32, service_count);
        defer self.allocator.free(in_degree_copy);
        @memcpy(in_degree_copy, self.in_degree);

        // queue for services with no dependencies
        var queue = ArrayListU32{};
        defer queue.deinit(self.allocator);

        // find all services with no dependencies
        for (0..service_count) |i| {
            if (in_degree_copy[i] == 0) {
                try queue.append(self.allocator, @as(u32, @intCast(i)));
            }
        }

        // process queue
        while (queue.items.len > 0) {
            const service_idx = queue.orderedRemove(0);
            try result.append(self.allocator, service_idx);

            // decrease in-degree for dependents
            for (self.reverse_graph[service_idx].items) |dependent_idx| {
                std.debug.assert(in_degree_copy[dependent_idx] > 0);
                in_degree_copy[dependent_idx] -= 1;

                if (in_degree_copy[dependent_idx] == 0) {
                    try queue.append(self.allocator, dependent_idx);
                }
            }
        }

        // check for cycles (if result length != service_count)
        if (result.items.len != service_count) {
            return DependencyError.CircularDependency;
        }

        return try result.toOwnedSlice(self.allocator);
    }

    // compute startup layers (services that can start in parallel)
    // grain style: explicit layer computation for parallel startup
    pub fn compute_startup_layers(
        self: *DependencyGraph,
    ) ![]ArrayListU32 {
        const sort_result = try self.topological_sort();
        defer self.allocator.free(sort_result);

        var layers = std.ArrayListUnmanaged(ArrayListU32){};
        errdefer {
            for (layers.items) |*layer| layer.deinit(self.allocator);
            layers.deinit(self.allocator);
        }

        // track which services are started
        var started = try self.allocator.alloc(bool, self.service_count);
        defer self.allocator.free(started);
        @memset(started, false);

        // process services in topological order
        // grain style: place each service in layer after its latest dependency
        for (sort_result) |service_idx| {
            // find which layer this service's dependencies are in
            var max_dep_layer: i32 = -1;
            for (self.graph[service_idx].items) |dep_idx| {
                // find which layer contains this dependency
                for (layers.items, 0..) |layer, layer_idx| {
                    for (layer.items) |layer_service_idx| {
                        if (layer_service_idx == dep_idx) {
                            const layer_num = @as(i32, @intCast(layer_idx));
                            if (layer_num > max_dep_layer) {
                                max_dep_layer = layer_num;
                            }
                            break;
                        }
                    }
                }
            }

            // service goes in layer (max_dep_layer + 1)
            const target_layer = @as(u32, @intCast(max_dep_layer + 1));

            // ensure we have enough layers
            while (layers.items.len <= target_layer) {
                try layers.append(self.allocator, ArrayListU32{});
            }

            // add service to target layer
            try layers.items[target_layer].append(self.allocator, service_idx);
            started[service_idx] = true;
        }

        return try layers.toOwnedSlice(self.allocator);
    }

    // detect circular dependencies (returns cycle if found)
    // grain style: explicit cycle detection with helpful error info
    pub fn detect_cycles(self: *DependencyGraph) ?[]u32 {
        const service_count = self.service_count;
        const visited_array = std.heap.page_allocator.alloc(
            bool,
            service_count,
        ) catch return null;
        defer std.heap.page_allocator.free(visited_array);
        @memset(visited_array, false);

        const rec_stack_array = std.heap.page_allocator.alloc(
            bool,
            service_count,
        ) catch return null;
        defer std.heap.page_allocator.free(rec_stack_array);
        @memset(rec_stack_array, false);

        var cycle_path = ArrayListU32{};
        defer cycle_path.deinit(std.heap.page_allocator);

        for (0..service_count) |i| {
            if (!visited_array[i]) {
                if (dfs_cycle(
                    self,
                    @as(u32, @intCast(i)),
                    visited_array,
                    rec_stack_array,
                    &cycle_path,
                )) {
                    return cycle_path.toOwnedSlice(std.heap.page_allocator) catch null;
                }
            }
        }

        return null;
    }

    // depth-first search for cycle detection
    fn dfs_cycle(
        self: *DependencyGraph,
        service_idx: u32,
        visited: []bool,
        rec_stack: []bool,
        cycle_path: *ArrayListU32,
    ) bool {
        visited[service_idx] = true;
        rec_stack[service_idx] = true;
        cycle_path.append(std.heap.page_allocator, service_idx) catch return true;

        for (self.graph[service_idx].items) |dep_idx| {
            if (!visited[dep_idx]) {
                if (dfs_cycle(self, dep_idx, visited, rec_stack, cycle_path)) {
                    return true;
                }
            } else if (rec_stack[dep_idx]) {
                // found cycle
                return true;
            }
        }

        _ = cycle_path.pop();
        rec_stack[service_idx] = false;
        return false;
    }
};

// tests
test "topological sort - simple dependencies" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // create simple configs: A depends on B, B has no deps
    var configs = [_]ServiceConfig{
        .{ .name = "A", .command = &.{"/bin/a"}, .dependencies = &.{"B"} },
        .{ .name = "B", .command = &.{"/bin/b"}, .dependencies = &.{} },
    };

    var graph = try DependencyGraph.init(allocator, &configs);
    defer graph.deinit();

    const sort_result = try graph.topological_sort();
    defer allocator.free(sort_result);

    try testing.expect(sort_result.len == 2);
    // B should come before A
    try testing.expect(sort_result[0] == 1); // B
    try testing.expect(sort_result[1] == 0); // A
}

test "topological sort - circular dependency" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // create circular configs: A depends on B, B depends on A
    var configs = [_]ServiceConfig{
        .{ .name = "A", .command = &.{"/bin/a"}, .dependencies = &.{"B"} },
        .{ .name = "B", .command = &.{"/bin/b"}, .dependencies = &.{"A"} },
    };

    var graph = try DependencyGraph.init(allocator, &configs);
    defer graph.deinit();

    try testing.expectError(
        DependencyError.CircularDependency,
        graph.topological_sort(),
    );
}

test "compute startup layers - parallel startup" {
    const testing = std.testing;
    const allocator = testing.allocator;

    // create configs: A and B independent, C depends on both
    var configs = [_]ServiceConfig{
        .{ .name = "A", .command = &.{"/bin/a"}, .dependencies = &.{} },
        .{ .name = "B", .command = &.{"/bin/b"}, .dependencies = &.{} },
        .{
            .name = "C",
            .command = &.{"/bin/c"},
            .dependencies = &.{ "A", "B" },
        },
    };

    var graph = try DependencyGraph.init(allocator, &configs);
    defer graph.deinit();

    const layers = try graph.compute_startup_layers();
    defer {
        for (layers) |*layer| layer.deinit(allocator);
        allocator.free(layers);
    }

    // first layer should have A and B (can start in parallel)
    try testing.expect(layers.len >= 1);
    try testing.expect(layers[0].items.len == 2);

    // second layer should have C (depends on A and B)
    try testing.expect(layers.len >= 2);
    try testing.expect(layers[1].items.len == 1);
}

