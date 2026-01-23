const std = @import("std");

/// Why: Sync external Rye repository to monorepo grainstore location.
pub const RyeSyncDaemon = struct {
    const MAX_PATH_LEN = 512;
    const SYNC_INTERVAL_MS = 2000;
    const MAX_RETRIES = 3;

    allocator: std.mem.Allocator,
    external_path: []const u8,
    grainstore_path: []const u8,
    running: bool,

    /// Why: Initialize daemon with external and grainstore paths.
    pub fn init(
        allocator: std.mem.Allocator,
        external: []const u8,
        grainstore: []const u8,
    ) RyeSyncDaemon {
        std.debug.assert(external.len > 0);
        std.debug.assert(external.len <= MAX_PATH_LEN);
        std.debug.assert(grainstore.len > 0);
        std.debug.assert(grainstore.len <= MAX_PATH_LEN);

        return RyeSyncDaemon{
            .allocator = allocator,
            .external_path = external,
            .grainstore_path = grainstore,
            .running = false,
        };
    }

    /// Why: Run daemon loop, syncing periodically.
    pub fn run(self: *RyeSyncDaemon) !void {
        std.debug.assert(!self.running);
        self.running = true;

        while (self.running) {
            try self.sync_once();
            std.time.sleep(SYNC_INTERVAL_MS * std.time.ns_per_ms);
        }
    }

    /// Why: Perform single sync operation from external to grainstore.
    fn sync_once(self: *RyeSyncDaemon) !void {
        std.debug.assert(self.running);

        var retry_count: u32 = 0;
        while (retry_count < MAX_RETRIES) : (retry_count += 1) {
            const result = self.sync_inner();
            if (result) |_| {
                return;
            } else |err| {
                if (retry_count == MAX_RETRIES - 1) {
                    return err;
                }
                std.time.sleep(500 * std.time.ns_per_ms);
            }
        }
    }

    /// Why: Inner sync logic using git pull.
    fn sync_inner(self: *RyeSyncDaemon) !void {
        std.debug.assert(self.running);

        var git_pull = std.process.Child.init(
            &.{ "git", "pull", "origin", "main" },
            self.allocator,
        );
        git_pull.cwd = self.grainstore_path;
        git_pull.stdout_behavior = .Ignore;
        git_pull.stderr_behavior = .Ignore;

        try git_pull.spawn();
        _ = try git_pull.wait();
    }

    /// Why: Stop daemon gracefully.
    pub fn stop(self: *RyeSyncDaemon) void {
        std.debug.assert(self.running);
        self.running = false;
    }
};

/// Why: CLI entry point for Rye sync daemon.
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const home = try std.process.getEnvVarOwned(allocator, "HOME");
    defer allocator.free(home);
    const full_external = try std.fmt.allocPrint(
        allocator,
        "{s}/codeberg/ryelang/rye",
        .{home},
    );
    defer allocator.free(full_external);

    const grainstore_path = "/home/xy/ry/grainstore/codeberg/ryelang/rye";

    var daemon = RyeSyncDaemon.init(allocator, full_external, grainstore_path);
    try daemon.run();
}
