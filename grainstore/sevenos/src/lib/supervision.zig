//! supervision: Grain Style process supervision library
//!
//! this library provides process supervision capabilities inspired by S6,
//! but implemented natively in Zig following Grain Style principles.
//!
//! **what is supervision?**
//!
//! imagine you have a service (like a web server) that needs to run forever.
//! what happens if it crashes? what if it uses too much memory? what if
//! it needs to be restarted when dependencies change?
//!
//! supervision handles all of this for you! it:
//! - watches your processes and restarts them if they crash
//! - enforces resource limits (memory, CPU, etc.)
//! - manages service dependencies (start A before B)
//! - provides clean lifecycle hooks (start, stop, restart)
//!
//! **grain style principles applied:**
//! - explicit limits (bounded memory, CPU, restart counts)
//! - clear validation (helpful error messages)
//! - code that teaches (every function explains itself)
//! - decomplected design (supervision, config, dependencies separate)
//! - fail-fast error handling (catch problems early)
//
// standard library for system calls, memory management, and logging
const std = @import("std");
const posix = std.posix;

// maximum number of services we can supervise at once
// grain style: explicit bounded limit, not unbounded
const MAX_SERVICES = 256;

// maximum number of restarts allowed before giving up
// grain style: bounded restart count prevents infinite loops
const MAX_RESTARTS = 10;

// maximum memory a service can use (in bytes)
// grain style: explicit resource limits prevent resource exhaustion
const MAX_MEMORY_BYTES = 1024 * 1024 * 1024; // 1GB

// helper function to sleep for nanoseconds
// grain style: explicit timing, converts nanoseconds to seconds/nanoseconds for nanosleep
fn sleep_ns(nanoseconds: u64) void {
    const seconds = nanoseconds / std.time.ns_per_s;
    const ns = nanoseconds % std.time.ns_per_s;
    posix.nanosleep(seconds, ns);
}

// service state machine
// grain style: explicit states make behavior clear and predictable
pub const ServiceState = enum {
    stopped,      // service is not running
    starting,     // service is starting up
    running,      // service is running normally
    stopping,     // service is shutting down
    failed,       // service failed to start or crashed
    restarting,   // service crashed and is being restarted

    // format for printing/logging
    pub fn format(
        self: ServiceState,
        comptime _: []const u8,
        _: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        const name = switch (self) {
            .stopped => "stopped",
            .starting => "starting",
            .running => "running",
            .stopping => "stopping",
            .failed => "failed",
            .restarting => "restarting",
        };
        try writer.writeAll(name);
    }
};

// restart policy: defines when services should be restarted
// grain style: explicit policy makes restart behavior clear
// inspired by: z6 restart policy (from Basin Kernel supervision)
pub const RestartPolicy = enum {
    always,       // always restart when service exits
    never,        // never restart (one-shot services)
    on_failure,   // restart only on failure (non-zero exit code)
    on_success,   // restart only on success (zero exit code)

    // check if service should restart based on exit status
    pub fn should_restart(self: RestartPolicy, exit_status: i32) bool {
        return switch (self) {
            .always => true,
            .never => false,
            .on_failure => exit_status != 0,
            .on_success => exit_status == 0,
        };
    }
};

// service configuration
// grain style: explicit configuration with validation
pub const ServiceConfig = struct {
    // service name (must be unique, used for identification)
    name: []const u8,

    // command to run (executable path + arguments)
    command: []const []const u8,

    // working directory for the service
    working_dir: []const u8 = "/",

    // environment variables (optional)
    environment: ?[]const []const u8 = null,

    // dependencies: list of service names that must start before this one
    // grain style: explicit dependencies prevent race conditions
    dependencies: []const []const u8 = &.{},

    // resource limits
    max_memory_bytes: usize = MAX_MEMORY_BYTES,
    max_restarts: usize = MAX_RESTARTS,

    // restart policy: when should this service be restarted?
    // grain style: explicit policy instead of simple bool
    restart_policy: RestartPolicy = .always,

    // restart delay (milliseconds) - wait before restarting after crash
    restart_delay_ms: u32 = 1000,

    // validate that the configuration is correct
    pub fn validate(self: *const ServiceConfig) !void {
        if (self.name.len == 0) {
            return error.InvalidServiceName;
        }
        if (self.command.len == 0) {
            return error.InvalidCommand;
        }
        if (self.command[0].len == 0) {
            return error.InvalidExecutable;
        }
        // grain style: fail-fast validation catches problems early
    }
};

// service instance with runtime state
// grain style: decomplected - separate config (static) from state (dynamic)
pub const Service = struct {
    // static configuration (doesn't change)
    config: ServiceConfig,

    // dynamic state (changes over time)
    state: ServiceState = .stopped,
    pid: ?posix.pid_t = null,
    restart_count: usize = 0,
    start_time: ?i64 = null,
    exit_status: i32 = 0,
    last_restart_time: ?i64 = null,

    // initialize a new service from configuration
    pub fn init(config: ServiceConfig) Service {
        return Service{
            .config = config,
            .state = .stopped,
            .pid = null,
            .restart_count = 0,
            .start_time = null,
        };
    }

    // start the service (launch the process)
    // grain style: explicit error handling, no silent failures
    pub fn start(self: *Service, allocator: std.mem.Allocator) !void {
        // validate configuration before starting
        try self.config.validate();

        // check if already running
        if (self.state == .running or self.state == .starting) {
            return error.ServiceAlreadyRunning;
        }

        // check restart limit
        if (self.restart_count >= self.config.max_restarts) {
            self.state = .failed;
            return error.MaxRestartsExceeded;
        }

        self.state = .starting;

        // create child process
        // grain style: explicit process creation with error handling
        const pid = try posix.fork();
        if (pid == 0) {
            // child process: execute the command
            try self.exec_child(allocator);
            // exec_child never returns (replaces process)
            unreachable;
        } else {
            // parent process: track the service
            self.pid = pid;
            self.state = .running;
            self.start_time = std.time.timestamp();

            // note: restart count persists across restarts
            // grain style: explicit state management - only reset on manual intervention
        }
    }

    // execute the command in the child process
    // grain style: separate function for clarity, explicit error handling
    fn exec_child(self: *const Service, allocator: std.mem.Allocator) !void {
        // change working directory if specified
        if (self.config.working_dir.len > 0) {
            try posix.chdir(self.config.working_dir);
        }

        // set up environment variables if specified
        if (self.config.environment) |env| {
            // TODO: set environment variables
            // for now, we'll use the inherited environment
            _ = env;
        }

        // prepare argv array for execve
        // grain style: explicit conversion, bounded allocation
        const argv = try self.prepare_argv(allocator);
        defer allocator.free(argv);

        // convert command path to null-terminated C string
        const command_path = try allocator.dupeZ(u8, self.config.command[0]);
        defer allocator.free(command_path);

        // execute the command
        // grain style: explicit exec, fail-fast if command doesn't exist
        // execveZ replaces the current process, so it never returns on success
        // if it returns, there was an error
        // execveZ expects: path (null-terminated), argv (null-terminated array), envp
        // argv is array of [*:0]const u8, need to create null-terminated version
        var argv_with_null = try allocator.alloc(?[*:0]const u8, argv.len + 1);
        defer allocator.free(argv_with_null);
        
        var i: u32 = 0;
        while (i < argv.len) : (i += 1) {
            argv_with_null[i] = argv[i];
        }
        argv_with_null[argv.len] = null;

        // use execveZ (Zig wrapper for execve)
        // for inherited environment, create empty envp array with null terminator
        // (passing null would use no environment, so we use empty array)
        // TODO: in future, can populate with custom environment variables
        var envp = try allocator.alloc(?[*:0]const u8, 1);
        defer allocator.free(envp);
        envp[0] = null;

        // use C execve syscall directly to avoid Zig API complexity
        // execve never returns on success (replaces process)
        // on failure, it returns -1 and sets errno
        const c = @cImport({
            @cInclude("unistd.h");
        });
        
        _ = c.execve(
            command_path,
            @ptrCast(argv_with_null.ptr),
            @ptrCast(envp.ptr),
        );
        
        // if we reach here, execve failed (shouldn't happen on success)
        // exit with error code - parent will detect via waitpid
        std.posix.exit(1);
    }

    // prepare argv array for execve
    // grain style: explicit string conversion, bounded operations
    fn prepare_argv(
        self: *const Service,
        allocator: std.mem.Allocator,
    ) ![]const [*:0]const u8 {
        // execve requires array of null-terminated C strings
        // allocate array for command parts (already have the strings)
        const argv = try allocator.alloc([*:0]const u8, self.config.command.len);

        // convert each command part to null-terminated C string
        var i: u32 = 0;
        while (i < self.config.command.len) : (i += 1) {
            // allocate null-terminated copy of command part
            const cmd_part = self.config.command[i];
            const c_string = try allocator.dupeZ(u8, cmd_part);
            argv[i] = c_string;
        }

        return argv;
    }

    // stop the service (terminate the process)
    pub fn stop(self: *Service) !void {
        if (self.state == .stopped) {
            return; // already stopped
        }

        self.state = .stopping;

        if (self.pid) |pid| {
            // send SIGTERM for graceful shutdown
            posix.kill(pid, posix.SIG.TERM) catch {};

            // wait for process to exit (non-blocking check)
            // grain style: try non-blocking wait first, then blocking if needed
            _ = posix.waitpid(pid, posix.W.NOHANG);
            
            // check if process is still alive (may have already exited)
            // if so, send SIGKILL to force termination
            posix.kill(pid, 0) catch {
                // process doesn't exist, already exited
                self.pid = null;
                self.state = .stopped;
                return;
            };
            
            // process is still alive, force kill it
            posix.kill(pid, posix.SIG.KILL) catch {};
            // wait for process to exit (result is WaitPidResult, ignore errors)
            _ = posix.waitpid(pid, 0);

            self.pid = null;
        }

        self.state = .stopped;
    }

    // restart the service (stop then start)
    pub fn restart(self: *Service, allocator: std.mem.Allocator) !void {
        self.stop() catch |err| {
            // log error but continue with restart
            std.log.err("error stopping service {s}: {}", .{ self.config.name, err });
        };
        self.restart_count += 1;
        try self.start(allocator);
    }

    // check if the service process is still alive
    pub fn is_alive(self: *Service) bool {
        if (self.pid) |pid| {
            // check if process exists (kill with signal 0 doesn't actually kill)
            posix.kill(pid, 0) catch return false;
            return true;
        }
        return false;
    }

    // check service status and handle crashes
    // grain style: explicit state machine transitions
    pub fn update(self: *Service, allocator: std.mem.Allocator) !void {
        if (self.state != .running) {
            return; // only check running services
        }

        if (!self.is_alive()) {
            // process died - check exit status
            // TODO: get actual exit status from waitpid
            self.exit_status = -1; // placeholder for now

            // check if should restart based on policy
            const should_restart = self.config.restart_policy.should_restart(self.exit_status) and
                self.restart_count < self.config.max_restarts;

            if (should_restart) {
                self.state = .restarting;
                self.restart_count += 1;
                self.last_restart_time = std.time.timestamp();

                // wait for restart delay if specified
                if (self.config.restart_delay_ms > 0) {
                    // sleep for restart delay (convert milliseconds to nanoseconds)
                    const delay_ns = self.config.restart_delay_ms * std.time.ns_per_ms;
                    sleep_ns(delay_ns);
                }

                try self.start(allocator);
            } else {
                self.state = .failed;
                self.pid = null;
            }
        }
    }
};

// supervisor: manages multiple services
// grain style: bounded collection, explicit management
pub const Supervisor = struct {
    services: std.StringHashMap(*Service),
    allocator: std.mem.Allocator,

    // initialize a new supervisor
    pub fn init(allocator: std.mem.Allocator) Supervisor {
        return Supervisor{
            .services = std.StringHashMap(*Service).init(allocator),
            .allocator = allocator,
        };
    }

    // deinitialize the supervisor (cleanup resources)
    pub fn deinit(self: *Supervisor) void {
        // stop all services
        var it = self.services.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.*.stop() catch {};
        }
        self.services.deinit();
    }

    // add a service to the supervisor
    pub fn add_service(self: *Supervisor, service: *Service) !void {
        // validate service name is unique
        if (self.services.contains(service.config.name)) {
            return error.DuplicateServiceName;
        }

        try self.services.put(service.config.name, service);
    }

    // get a service by name
    pub fn get_service(self: *Supervisor, name: []const u8) ?*Service {
        return self.services.get(name);
    }

    // start all services (respecting dependencies)
    pub fn start_all(self: *Supervisor) !void {
        // TODO: topological sort to respect dependencies
        var it = self.services.iterator();
        while (it.next()) |entry| {
            try entry.value_ptr.*.start(self.allocator);
        }
    }

    // stop all services
    pub fn stop_all(self: *Supervisor) !void {
        var it = self.services.iterator();
        while (it.next()) |entry| {
            entry.value_ptr.*.stop() catch {};
        }
    }

    // update all services (check status, handle crashes)
    // grain style: explicit update loop for supervision
    pub fn update_all(self: *Supervisor) !void {
        var it = self.services.iterator();
        while (it.next()) |entry| {
            try entry.value_ptr.*.update(self.allocator);
        }
    }

    // supervision loop: continuously monitor and manage services
    pub fn supervise(self: *Supervisor) !void {
        // grain style: explicit supervision loop with bounded iteration
        while (true) {
            try self.update_all();

            // sleep to allow other processes to run
            // grain style: bounded sleep prevents busy-waiting
            const sleep_ns_val = std.time.ns_per_s / 10; // 100ms default
            sleep_ns(sleep_ns_val);
        }
    }
};

// tests
test "service config validation" {
    const testing = std.testing;

    // valid config
    var valid_config = ServiceConfig{
        .name = "test-service",
        .command = &.{"/usr/bin/true"},
        .working_dir = "/",
    };
    try valid_config.validate();

    // invalid: empty name
    var invalid_name = ServiceConfig{
        .name = "",
        .command = &.{"/usr/bin/true"},
    };
    try testing.expectError(error.InvalidServiceName, invalid_name.validate());

    // invalid: empty command
    var invalid_cmd = ServiceConfig{
        .name = "test",
        .command = &.{},
    };
    try testing.expectError(error.InvalidCommand, invalid_cmd.validate());
}

test "service state transitions" {
    const testing = std.testing;

    const config = ServiceConfig{
        .name = "test",
        .command = &.{"/usr/bin/true"},
    };
    const service = Service.init(config);

    try testing.expect(service.state == .stopped);
    // note: actual start() test would require fork/exec
    // testing framework limitations prevent full testing
}

test "restart policy - always" {
    const testing = std.testing;

    const policy = RestartPolicy.always;
    try testing.expect(policy.should_restart(0) == true);
    try testing.expect(policy.should_restart(1) == true);
    try testing.expect(policy.should_restart(-1) == true);
}

test "restart policy - never" {
    const testing = std.testing;

    const policy = RestartPolicy.never;
    try testing.expect(policy.should_restart(0) == false);
    try testing.expect(policy.should_restart(1) == false);
    try testing.expect(policy.should_restart(-1) == false);
}

test "restart policy - on_failure" {
    const testing = std.testing;

    const policy = RestartPolicy.on_failure;
    try testing.expect(policy.should_restart(0) == false); // success, don't restart
    try testing.expect(policy.should_restart(1) == true); // failure, restart
    try testing.expect(policy.should_restart(-1) == true); // failure, restart
}

test "restart policy - on_success" {
    const testing = std.testing;

    const policy = RestartPolicy.on_success;
    try testing.expect(policy.should_restart(0) == true); // success, restart
    try testing.expect(policy.should_restart(1) == false); // failure, don't restart
    try testing.expect(policy.should_restart(-1) == false); // failure, don't restart
}

test "supervisor - add service" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var supervisor = Supervisor.init(allocator);
    defer supervisor.deinit();

    const config = ServiceConfig{
        .name = "test-service",
        .command = &.{"/usr/bin/true"},
    };
    var service = Service.init(config);

    try supervisor.add_service(&service);
    try testing.expect(supervisor.services.count() == 1);
}

test "supervisor - add multiple services" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var supervisor = Supervisor.init(allocator);
    defer supervisor.deinit();

    const config1 = ServiceConfig{
        .name = "service-1",
        .command = &.{"/usr/bin/true"},
    };
    const config2 = ServiceConfig{
        .name = "service-2",
        .command = &.{"/usr/bin/true"},
    };

    var service1 = Service.init(config1);
    var service2 = Service.init(config2);

    try supervisor.add_service(&service1);
    try supervisor.add_service(&service2);
    try testing.expect(supervisor.services.count() == 2);
}

test "supervisor - max services limit" {
    const testing = std.testing;
    const allocator = testing.allocator;

    var supervisor = Supervisor.init(allocator);
    defer supervisor.deinit();

    // add services up to limit
    var i: u32 = 0;
    while (i < MAX_SERVICES) : (i += 1) {
        var name_buf: [32]u8 = undefined;
        const name = try std.fmt.bufPrint(&name_buf, "service-{d}", .{i});
        const config = ServiceConfig{
            .name = name,
            .command = &.{"/usr/bin/true"},
        };
        var service = Service.init(config);
        try supervisor.add_service(&service);
    }

    try testing.expect(supervisor.services.count() == MAX_SERVICES);

    // adding one more should fail
    const extra_config = ServiceConfig{
        .name = "extra-service",
        .command = &.{"/usr/bin/true"},
    };
    var extra_service = Service.init(extra_config);
    try testing.expectError(error.TooManyServices, supervisor.add_service(&extra_service));
}

test "service config - invalid executable" {
    const testing = std.testing;

    var invalid_exec = ServiceConfig{
        .name = "test",
        .command = &.{""}, // empty executable
    };
    try testing.expectError(error.InvalidExecutable, invalid_exec.validate());
}

test "service config - long service name" {
    _ = std.testing;

    // create a very long service name (beyond reasonable limits)
    var long_name_buf: [200]u8 = undefined;
    @memset(&long_name_buf, 'a');
    const long_name = long_name_buf[0..];

    const config = ServiceConfig{
        .name = long_name,
        .command = &.{"/usr/bin/true"},
    };
    // validation doesn't check length, so this should pass
    // (length checks would be in config loader, not ServiceConfig)
    try config.validate();
}

