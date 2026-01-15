//! Job Manager for Background Process Tracking
//! Why: Track background jobs in the shell (jobs, fg, bg commands).
//! Grain Style: Explicit error handling, bounded allocations, minimal dependencies.

const std = @import("std");
const posix = std.posix;

/// Maximum number of jobs to track.
const MAX_JOBS = 256;

/// Job status.
pub const JobStatus = enum {
    running,
    stopped,
    done,
};

/// Background job information.
pub const Job = struct {
    job_id: u32,
    pid: posix.pid_t,
    command: [256]u8, // Command string for display
    command_len: u32,
    status: JobStatus,
    exit_code: ?u8,

    /// Check if job is done.
    pub fn is_done(self: *const Job) bool {
        return self.status == .done;
    }

    /// Check if job is stopped.
    pub fn is_stopped(self: *const Job) bool {
        return self.status == .stopped;
    }

    /// Update job status by checking process state.
    pub fn update_status(self: *Job) !void {
        // Check if process is still running using kill(pid, 0) (non-destructive check)
        posix.kill(self.pid, 0) catch |err| {
            switch (err) {
                error.ProcessNotFound => {
                    // Process doesn't exist (has terminated)
                    self.status = .done;
                // Try to get exit code via waitpid (non-blocking)
                const result = posix.waitpid(self.pid, posix.W.NOHANG);
                if (result.pid == self.pid) {
                    // result.status is already the exit code (u32)
                    // Convert to u8 for exit_code field
                    self.exit_code = @intCast(result.status);
                }
                    return;
                },
                else => {
                    // Other error (PermissionDenied, etc.) - assume still running
                    return;
                },
            }
        };
        // Process exists - check if it's stopped
        // For now, assume running (stopped detection requires more complex handling)
        if (self.status == .stopped) {
            // Keep stopped status unless explicitly resumed
        } else {
            self.status = .running;
        }
    }
};

/// Job manager for tracking background processes.
pub const JobManager = struct {
    jobs: std.ArrayList(Job),
    next_job_id: u32,
    allocator: std.mem.Allocator,

    /// Initialize job manager.
    pub fn init(allocator: std.mem.Allocator) JobManager {
        const jobs = std.ArrayList(Job).initCapacity(allocator, MAX_JOBS) catch std.ArrayList(Job).initCapacity(allocator, 16) catch @panic("Out of memory");
        return JobManager{
            .jobs = jobs,
            .next_job_id = 1,
            .allocator = allocator,
        };
    }

    /// Deinitialize job manager.
    pub fn deinit(self: *JobManager) void {
        self.jobs.deinit(self.allocator);
    }

    /// Add a new background job.
    pub fn add_job(self: *JobManager, pid: posix.pid_t, command: []const u8) !u32 {
        if (self.jobs.items.len >= MAX_JOBS) {
            return error.TooManyJobs;
        }

        var job = Job{
            .job_id = self.next_job_id,
            .pid = pid,
            .command = undefined,
            .command_len = 0,
            .status = .running,
            .exit_code = null,
        };

        // Copy command string (bounded)
        const cmd_len = @min(command.len, job.command.len - 1);
        if (cmd_len > 0) {
            @memcpy(job.command[0..cmd_len], command[0..cmd_len]);
            job.command_len = @intCast(cmd_len);
        }

        try self.jobs.append(self.allocator, job);
        const job_id = self.next_job_id;
        self.next_job_id += 1;

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

    /// Get all jobs.
    pub fn get_all_jobs(self: *JobManager) []Job {
        return self.jobs.items;
    }

    /// Update status of all jobs.
    pub fn update_all_jobs(self: *JobManager) !void {
        for (self.jobs.items) |*job| {
            if (job.status != .done) {
                job.update_status() catch {
                    // If update fails, mark as done
                    job.status = .done;
                };
            }
        }
    }

    /// Remove a job by ID.
    pub fn remove_job(self: *JobManager, job_id: u32) bool {
        for (self.jobs.items, 0..) |*job, i| {
            if (job.job_id == job_id) {
                _ = self.jobs.swapRemove(i);
                return true;
            }
        }
        return false;
    }

    /// Remove all done jobs.
    pub fn remove_done_jobs(self: *JobManager) void {
        var i: usize = 0;
        while (i < self.jobs.items.len) {
            if (self.jobs.items[i].status == .done) {
                _ = self.jobs.swapRemove(i);
            } else {
                i += 1;
            }
        }
    }
};
