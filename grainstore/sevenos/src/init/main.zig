//! sevenos-init: Grain Style init system in Zig
//!
//! Inspired by S6 supervision suite, but implemented natively in Zig
//! following Grain Style principles: minimalism, simplicity, explicit
//! configuration.
//!
//! **What does the init system do?**
//!
//! The init system is responsible for:
//! - Starting system services in the correct order (respecting dependencies)
//! - Monitoring services and restarting them if they crash
//! - Managing service lifecycle (start, stop, restart)
//! - Handling system shutdown gracefully
//!
//! **Grain Style principles:**
//! - Explicit configuration (clear service definitions)
//! - Fail-fast error handling (detect problems early)
//! - Bounded resource limits (prevent resource exhaustion)
//! - Educational code (clear comments, simple structure)

const std = @import("std");
const posix = std.posix;
const supervision = @import("supervision");
const config_loader = @import("config_loader");
const dependency = @import("dependency");

const Service = supervision.Service;
const ServiceConfig = supervision.ServiceConfig;
const Supervisor = supervision.Supervisor;
const DependencyGraph = dependency.DependencyGraph;

// default configuration file path
// grain style: explicit default values
const DEFAULT_CONFIG_PATH = "/etc/sevenos/services.conf";

// supervision loop sleep duration (100ms)
// grain style: explicit timing prevents busy-waiting
const SUPERVISION_SLEEP_NS: u64 = std.time.ns_per_s / 10;

// main entry point
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // parse command line arguments
    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    const config_path = if (args.len > 1) args[1] else DEFAULT_CONFIG_PATH;
    std.debug.print("sevenos-init: starting with config: {s}\n", .{config_path});

    // load service configurations
    const configs = try config_loader.load_service_configs(allocator, config_path);
    defer allocator.free(configs);

    if (configs.len == 0) {
        std.debug.print("sevenos-init: no services configured\n", .{});
        return;
    }

    std.debug.print("sevenos-init: loaded {d} service(s)\n", .{configs.len});

    // build dependency graph
    var dep_graph = try DependencyGraph.init(allocator, configs);
    defer dep_graph.deinit();

    // detect circular dependencies
    if (dep_graph.detect_cycles()) |cycle| {
        std.debug.print(
            "sevenos-init: error: circular dependency detected\n",
            .{},
        );
        defer allocator.free(cycle);
        return error.CircularDependency;
    }

    // compute startup layers (services that can start in parallel)
    const startup_layers = try dep_graph.compute_startup_layers();
    defer {
        for (startup_layers) |*layer| layer.deinit(allocator);
        allocator.free(startup_layers);
    }

    // create supervisor
    var supervisor = Supervisor.init(allocator);
    defer supervisor.deinit();

    // create service instances from configs
    // grain style: explicit service creation with bounded allocation
    const services = try allocator.alloc(*Service, configs.len);
    defer allocator.free(services);

    for (configs, 0..) |config, i| {
        services[i] = try allocator.create(Service);
        services[i].* = Service.init(config);
        try supervisor.add_service(services[i]);
    }

    // setup signal handlers for graceful shutdown
    try setup_signal_handlers(&supervisor);

    // start services in dependency order (layer by layer)
    std.debug.print("sevenos-init: starting services\n", .{});
    for (startup_layers, 0..) |layer, layer_idx| {
        std.debug.print(
            "sevenos-init: starting layer {d} ({d} service(s))\n",
            .{ layer_idx, layer.items.len },
        );

        // start all services in this layer (can start in parallel)
        for (layer.items) |service_idx| {
            const service_name = dep_graph.service_names[service_idx];
            const service = supervisor.get_service(service_name) orelse {
                std.debug.print(
                    "sevenos-init: error: service {s} not found\n",
                    .{service_name},
                );
                continue;
            };

            service.start(allocator) catch |err| {
                std.debug.print(
                    "sevenos-init: error starting {s}: {}\n",
                    .{ service_name, err },
                );
                // continue with other services even if one fails
            };
        }

        // sleep to allow services in this layer to stabilize
        // grain style: explicit timing prevents race conditions
        const stabilization_delay_ns = SUPERVISION_SLEEP_NS * 2; // 200ms
        posix.nanosleep(stabilization_delay_ns / std.time.ns_per_s, stabilization_delay_ns % std.time.ns_per_s);
    }

    std.debug.print("sevenos-init: all services started, entering supervision loop\n", .{});

    // enter supervision loop (monitor and manage services)
    try run_supervision_loop(&supervisor, allocator);
}

// setup signal handlers for graceful shutdown
// grain style: explicit signal handling for clear shutdown behavior
fn setup_signal_handlers(_: *Supervisor) !void {
    // SIGTERM: graceful shutdown (stop all services)
    // grain style: explicit signal handler setup
    const empty_mask = posix.sigemptyset();
    
    var act_term: posix.Sigaction = undefined;
    act_term.handler = .{ .handler = handle_sigterm };
    act_term.mask = empty_mask;
    act_term.flags = 0;
    _ = posix.sigaction(posix.SIG.TERM, &act_term, null);

    // SIGINT: graceful shutdown (stop all services)
    var act_int: posix.Sigaction = undefined;
    act_int.handler = .{ .handler = handle_sigterm };
    act_int.mask = empty_mask;
    act_int.flags = 0;
    _ = posix.sigaction(posix.SIG.INT, &act_int, null);

    // SIGHUP: reload configuration (future: implement reload)
    var act_hup: posix.Sigaction = undefined;
    act_hup.handler = .{ .handler = handle_sighup };
    act_hup.mask = empty_mask;
    act_hup.flags = 0;
    _ = posix.sigaction(posix.SIG.HUP, &act_hup, null);
}

// global flag for graceful shutdown
var should_shutdown: bool = false;

// signal handler for SIGTERM/SIGINT (graceful shutdown)
fn handle_sigterm(sig: c_int) callconv(.c) void {
    _ = sig;
    should_shutdown = true;
}

// signal handler for SIGHUP (reload configuration)
// grain style: explicit signal handling (future: implement reload)
fn handle_sighup(sig: c_int) callconv(.c) void {
    _ = sig;
    // TODO: implement configuration reload
    std.debug.print("sevenos-init: SIGHUP received (reload not yet implemented)\n", .{});
}

// supervision loop: continuously monitor and manage services
// grain style: explicit loop with bounded iteration and clear exit condition
fn run_supervision_loop(supervisor: *Supervisor, _: std.mem.Allocator) !void {
    while (!should_shutdown) {
        // update all services (check status, handle crashes)
        supervisor.update_all() catch |err| {
            std.debug.print(
                "sevenos-init: error in supervision update: {}\n",
                .{err},
            );
            // continue supervision loop even if update fails
        };

        // sleep before next iteration
        // grain style: bounded sleep prevents busy-waiting
        posix.nanosleep(SUPERVISION_SLEEP_NS / std.time.ns_per_s, SUPERVISION_SLEEP_NS % std.time.ns_per_s);
    }

    // graceful shutdown: stop all services
    std.debug.print("sevenos-init: shutdown signal received, stopping services\n", .{});
    supervisor.stop_all() catch |err| {
        std.debug.print("sevenos-init: error stopping services: {}\n", .{err});
    };
    std.debug.print("sevenos-init: shutdown complete\n", .{});
}
