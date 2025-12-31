//! Grain Core File Operation Rate Limiter: Rate limiting for file operations.
//!
//! Why: Prevent abuse of file operations (too many opens, reads, writes).
//! Architecture: Token bucket algorithm with per-user rate limiting.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");

// Bounded: Max rate limit entries (users).
pub const MAX_RATE_LIMIT_ENTRIES: u32 = 1000;

// Rate limit entry: tracks rate limit state for a user.
pub const FileOperationRateLimitEntry = struct {
    user_id: u32,
    tokens: u32,
    last_refill: u64,
    active: bool,

    pub fn init() FileOperationRateLimitEntry {
        var entry = FileOperationRateLimitEntry{
            .user_id = 0,
            .tokens = 0,
            .last_refill = 0,
            .active = false,
        };
        std.debug.assert(entry.user_id == 0);
        std.debug.assert(!entry.active);
        return entry;
    }
};

// File operation rate limiter: manages rate limiting for file operations.
pub const FileOperationRateLimiter = struct {
    entries: [MAX_RATE_LIMIT_ENTRIES]FileOperationRateLimitEntry,
    entries_len: u32,
    tokens_per_second: u32,
    max_tokens: u32,
    current_time_fn: *const fn () u64,

    pub fn init(
        tokens_per_second: u32,
        max_tokens: u32,
        current_time_fn: *const fn () u64,
    ) FileOperationRateLimiter {
        std.debug.assert(tokens_per_second > 0);
        std.debug.assert(max_tokens > 0);
        var limiter = FileOperationRateLimiter{
            .entries = undefined,
            .entries_len = 0,
            .tokens_per_second = tokens_per_second,
            .max_tokens = max_tokens,
            .current_time_fn = current_time_fn,
        };
        var i: u32 = 0;
        while (i < MAX_RATE_LIMIT_ENTRIES) : (i += 1) {
            limiter.entries[i] = FileOperationRateLimitEntry.init();
        }
        std.debug.assert(limiter.entries_len == 0);
        std.debug.assert(limiter.tokens_per_second == tokens_per_second);
        return limiter;
    }

    pub fn check_rate_limit(
        self: *FileOperationRateLimiter,
        user_id: u32,
    ) bool {
        std.debug.assert(user_id > 0);
        std.debug.assert(self.entries_len <= MAX_RATE_LIMIT_ENTRIES);
        const current_time = self.current_time_fn();
        const entry = self.get_or_create_entry(user_id, current_time);
        if (entry == null) {
            return false;
        }
        const e = entry.?;
        self.refill_tokens(e, current_time);
        if (e.tokens > 0) {
            e.tokens -= 1;
            std.debug.assert(e.tokens < self.max_tokens);
            return true;
        }
        return false;
    }

    fn get_or_create_entry(
        self: *FileOperationRateLimiter,
        user_id: u32,
        current_time: u64,
    ) ?*FileOperationRateLimitEntry {
        std.debug.assert(user_id > 0);
        std.debug.assert(self.entries_len <= MAX_RATE_LIMIT_ENTRIES);
        var i: u32 = 0;
        while (i < self.entries_len) : (i += 1) {
            if (self.entries[i].active and self.entries[i].user_id == user_id) {
                return &self.entries[i];
            }
        }
        if (self.entries_len >= MAX_RATE_LIMIT_ENTRIES) {
            return null;
        }
        const entry = &self.entries[self.entries_len];
        entry.* = FileOperationRateLimitEntry.init();
        entry.user_id = user_id;
        entry.tokens = self.max_tokens;
        entry.last_refill = current_time;
        entry.active = true;
        self.entries_len += 1;
        std.debug.assert(self.entries_len <= MAX_RATE_LIMIT_ENTRIES);
        return entry;
    }

    fn refill_tokens(
        self: *FileOperationRateLimiter,
        entry: *FileOperationRateLimitEntry,
        current_time: u64,
    ) void {
        std.debug.assert(entry.active);
        std.debug.assert(current_time >= entry.last_refill);
        const elapsed_nanos = current_time - entry.last_refill;
        const elapsed_seconds = elapsed_nanos / 1000000000;
        if (elapsed_seconds > 0) {
            const elapsed_u32 = @as(u32, @intCast(elapsed_seconds));
            const tokens_to_add = elapsed_u32 * self.tokens_per_second;
            entry.tokens = @min(entry.tokens + tokens_to_add, self.max_tokens);
            entry.last_refill = current_time;
            std.debug.assert(entry.tokens <= self.max_tokens);
        }
    }

    pub fn clear_expired_entries(
        self: *FileOperationRateLimiter,
        max_age_seconds: u64,
    ) u32 {
        std.debug.assert(self.entries_len <= MAX_RATE_LIMIT_ENTRIES);
        const current_time = self.current_time_fn();
        var cleared_count: u32 = 0;
        var i: u32 = 0;
        while (i < self.entries_len) : (i += 1) {
            if (!self.entries[i].active) {
                continue;
            }
            const age_seconds = (current_time - self.entries[i].last_refill) /
                1000000000;
            if (age_seconds > max_age_seconds) {
                self.entries[i].active = false;
                cleared_count += 1;
            }
        }
        std.debug.assert(cleared_count <= self.entries_len);
        return cleared_count;
    }
};
