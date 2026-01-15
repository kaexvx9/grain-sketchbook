//! service_manager: Shell integration with Init System
//!
//! Why: Provides shell commands access to Init System service management.
//! Grain Style: Explicit error handling, bounded allocations, minimal dependencies.
//!
//! This module wraps Init System supervision APIs to provide a clean
//! interface for shell built-in commands to manage services.

const std = @import("std");
const supervision = @import("supervision");
const stdio = @import("stdio_wrapper.zig");

/// Maximum service name length.
const MAX_SERVICE_NAME_LEN = 256;

/// Maximum number of services to list.
const MAX_SERVICES_LIST = 256;

/// Service manager for shell integration.
pub const ServiceManager = struct {
    supervisor: *supervision.Supervisor,
    allocator: std.mem.Allocator,

    /// Initialize service manager.
    pub fn init(
        allocator: std.mem.Allocator,
        supervisor: *supervision.Supervisor,
    ) ServiceManager {
        return ServiceManager{
            .supervisor = supervisor,
            .allocator = allocator,
        };
    }

    /// Get service status.
    pub fn get_service_status(
        self: *ServiceManager,
        service_name: []const u8,
    ) ?supervision.ServiceState {
        const service = self.supervisor.get_service(service_name) orelse return null;
        return service.state;
    }

    /// Start a service.
    pub fn start_service(
        self: *ServiceManager,
        service_name: []const u8,
    ) ServiceManagerError!void {
        const service = self.supervisor.get_service(service_name) orelse {
            return ServiceManagerError.ServiceNotFound;
        };

        if (service.state == .running) {
            return ServiceManagerError.ServiceAlreadyRunning;
        }

        service.start(self.allocator) catch |err| {
            return switch (err) {
                error.OutOfMemory => ServiceManagerError.OutOfMemory,
                else => ServiceManagerError.StartFailed,
            };
        };
    }

    /// Stop a service.
    pub fn stop_service(
        self: *ServiceManager,
        service_name: []const u8,
    ) ServiceManagerError!void {
        const service = self.supervisor.get_service(service_name) orelse {
            return ServiceManagerError.ServiceNotFound;
        };

        if (service.state == .stopped) {
            return ServiceManagerError.ServiceNotRunning;
        }

        service.stop() catch {
            return ServiceManagerError.StopFailed;
        };
    }

    /// Restart a service.
    pub fn restart_service(
        self: *ServiceManager,
        service_name: []const u8,
    ) ServiceManagerError!void {
        const service = self.supervisor.get_service(service_name) orelse {
            return ServiceManagerError.ServiceNotFound;
        };

        service.restart(self.allocator) catch |err| {
            return switch (err) {
                error.OutOfMemory => ServiceManagerError.OutOfMemory,
                else => ServiceManagerError.RestartFailed,
            };
        };
    }

    /// List all services.
    pub fn list_services(
        self: *ServiceManager,
    ) ServiceManagerError![]const ServiceInfo {
        var services_list = try std.ArrayList(ServiceInfo).initCapacity(
            self.allocator,
            MAX_SERVICES_LIST,
        );
        defer services_list.deinit(self.allocator);

        var it = self.supervisor.services.iterator();
        var count: u32 = 0;
        while (it.next()) |entry| : (count += 1) {
            if (count >= MAX_SERVICES_LIST) {
                break;
            }

            const service = entry.value_ptr.*;
            const info = ServiceInfo{
                .name = service.config.name,
                .state = service.state,
                .pid = service.pid,
            };
            try services_list.append(self.allocator, info);
        }

        const result = try services_list.toOwnedSlice(self.allocator);
        return result;
    }

    /// Format service status for display.
    pub fn format_service_status(
        self: *ServiceManager,
        service_name: []const u8,
        output_buf: []u8,
    ) ServiceManagerError![]const u8 {
        const info = self.get_service_info(service_name) orelse {
            return ServiceManagerError.ServiceNotFound;
        };

        const state_str = switch (info.state) {
            .stopped => "stopped",
            .starting => "starting",
            .running => "running",
            .stopping => "stopping",
            .failed => "failed",
            .restarting => "restarting",
        };

        if (info.pid) |pid| {
            return std.fmt.bufPrint(
                output_buf,
                "{s}: {s} (pid: {d})\n",
                .{ service_name, state_str, pid },
            ) catch ServiceManagerError.OutOfMemory;
        } else {
            return std.fmt.bufPrint(
                output_buf,
                "{s}: {s}\n",
                .{ service_name, state_str },
            ) catch ServiceManagerError.OutOfMemory;
        }
    }

    /// Get service information.
    pub fn get_service_info(
        self: *ServiceManager,
        service_name: []const u8,
    ) ?ServiceInfo {
        const service = self.supervisor.get_service(service_name) orelse return null;
        return ServiceInfo{
            .name = service.config.name,
            .state = service.state,
            .pid = service.pid,
        };
    }
};

/// Service information for display.
pub const ServiceInfo = struct {
    name: []const u8,
    state: supervision.ServiceState,
    pid: ?std.posix.pid_t,
};

/// Service manager errors.
pub const ServiceManagerError = error{
    ServiceNotFound,
    ServiceAlreadyRunning,
    ServiceNotRunning,
    StartFailed,
    StopFailed,
    RestartFailed,
    OutOfMemory,
};

