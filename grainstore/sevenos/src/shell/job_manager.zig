//! Background Job Manager
//! Why: Track and manage background processes in Grainscript Shell.
//! Grain Style: Explicit error handling, bounded allocations, u32/u64 over usize/isize.

const std = @import("std");

/// Background job status.
pub const JobStatus = enum {
    running,
    stopped,
    done,
};

/// Background job information.
pub const Job = struct {
    job_id: u32, // Job number (1, 2, 3, ...)
    pid: std.posix.pid_t, // Process ID
    command: []const u8, // Command string (owned by caller)
    status: JobStatus, // Current status
    exit_code: ?u8 = null, // Exit code (if done)

    /// Check if job is still running.
    pub fn is_running(self: *const Job) bool {
        return self.status == .running;
    }

    /// Check if job is stopped.
    pub fn is_stopped(self: *const Job) bool {
        return self.status == .stopped;
    }

    /// Check if job is done.
    pub fn is_done(self: *const Job) bool {
        return self.status == .done;
    }

    /// Update job status by checking process.
    pub fn update_status(self: *Job) !void {
        if (self.status == .done) {
            return; // Already done, no need to check
        }

        // Check if process is still running using kill(pid, 0)
        // Signal 0 doesn't actually send a signal, just checks if process exists
        std.posix.kill(self.pid, 0) catch |err| {
            // Process doesn't exist or we can't access it - assume it's done
            if (err == error.ProcessNotFound or err == error.PermissionDenied) {
                self.status = .done;
                self.exit_code = 0; // Default exit code (we don't know the actual code)
            }
            return; // Other errors - keep current status
        };

        // Process exists - check if it's stopped (this is a simplified check)
        // In a full implementation, we'd use waitpid to get more detailed status
        self.status = .running;
    }
};

/// Job manager for tracking background processes.
pub const JobManager = struct {
    allocator: std.mem.Allocator,
    jobs: std.ArrayListUnmanaged(Job),
    next_job_id: u32,

    /// Initialize job manager.
    pub fn init(allocator: std.mem.Allocator) JobManager {
        return JobManager{
            .allocator = allocator,
            .jobs = .{},
            .next_job_id = 1,
        };
    }

    /// Deinitialize job manager.
    pub fn deinit(self: *JobManager) void {
        // Free command strings (if owned)
        for (self.jobs.items) |*job| {
            // Command strings are owned by caller, so we don't free them here
            _ = job;
        }
        self.jobs.deinit(self.allocator);
    }

    /// Add a new background job.
    pub fn add_job(self: *JobManager, pid: std.posix.pid_t, command: []const u8) !u32 {
        const job_id = self.next_job_id;
        self.next_job_id += 1;

        const job = Job{
            .job_id = job_id,
            .pid = pid,
            .command = command,
            .status = .running,
            .exit_code = null,
        };

        try self.jobs.append(self.allocator, job);
        return job_id;
    }

    /// Get job by ID.
    pub fn get_job(self: *JobManager, job_id: u32) ?*Job {
        for (self.jobs.items) |*job| {
            if (job.job_id == job_id) {
                return job;
            }
        }
        return null;
    }

    /// Get job by PID.
    pub fn get_job_by_pid(self: *JobManager, pid: std.posix.pid_t) ?*Job {
        for (self.jobs.items) |*job| {
            if (job.pid == pid) {
                return job;
            }
        }
        return null;
    }

    /// Remove job by ID (after it's done).
    pub fn remove_job(self: *JobManager, job_id: u32) bool {
        for (self.jobs.items, 0..) |*job, i| {
            if (job.job_id == job_id) {
                _ = self.jobs.swapRemove(@intCast(i));
                return true;
            }
        }
        return false;
    }

    /// Update all job statuses.
    pub fn update_all_jobs(self: *JobManager) !void {
        for (self.jobs.items) |*job| {
            try job.update_status();
        }
    }

    /// Remove all done jobs.
    pub fn remove_done_jobs(self: *JobManager) void {
        var i: u32 = 0;
        while (i < self.jobs.items.len) {
            if (self.jobs.items[i].is_done()) {
                _ = self.jobs.swapRemove(@intCast(i));
            } else {
                i += 1;
            }
        }
    }

    /// Get all jobs (for `jobs` command).
    pub fn get_all_jobs(self: *JobManager) []const Job {
        return self.jobs.items;
    }

    /// Get number of jobs.
    pub fn job_count(self: *const JobManager) u32 {
        return @intCast(self.jobs.items.len);
    }
};
