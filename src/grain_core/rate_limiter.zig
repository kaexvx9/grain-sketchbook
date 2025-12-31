//! Grain OS Rate Limiter: Rate limiting for API server.
//!
//! Why: Prevent abuse and ensure fair resource usage.
//! Architecture: Token bucket algorithm with per-IP rate limiting.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const api_server = @import("api_server.zig");

// Bounded: Max rate limit entries.
pub const MAX_RATE_LIMIT_ENTRIES: u32 = 1000;

// Bounded: Max IP address length (IPv6).
pub const MAX_IP_LEN: u32 = 45;

// Rate limit entry: tracks rate limit state for an IP address.
pub const RateLimitEntry = struct {
    ip_address: [MAX_IP_LEN]u8,
    ip_len: u32,
    tokens: u32,
    last_refill: u64,
    active: bool,

    pub fn init() RateLimitEntry {
        var entry = RateLimitEntry{
            .ip_address = undefined,
            .ip_len = 0,
            .tokens = 0,
            .last_refill = 0,
            .active = false,
        };
        var i: u32 = 0;
        while (i < MAX_IP_LEN) : (i += 1) {
            entry.ip_address[i] = 0;
        }
        std.debug.assert(entry.ip_len == 0);
        std.debug.assert(!entry.active);
        return entry;
    }
};

// Rate limiter: manages rate limiting for API server.
pub const RateLimiter = struct {
    entries: [MAX_RATE_LIMIT_ENTRIES]RateLimitEntry,
    entries_len: u32,
    tokens_per_second: u32,
    max_tokens: u32,
    current_time_fn: *const fn () u64,

    pub fn init(
        tokens_per_second: u32,
        max_tokens: u32,
        current_time_fn: *const fn () u64,
    ) RateLimiter {
        std.debug.assert(tokens_per_second > 0);
        std.debug.assert(max_tokens > 0);
        var limiter = RateLimiter{
            .entries = undefined,
            .entries_len = 0,
            .tokens_per_second = tokens_per_second,
            .max_tokens = max_tokens,
            .current_time_fn = current_time_fn,
        };
        var i: u32 = 0;
        while (i < MAX_RATE_LIMIT_ENTRIES) : (i += 1) {
            limiter.entries[i] = RateLimitEntry.init();
        }
        std.debug.assert(limiter.entries_len == 0);
        std.debug.assert(limiter.tokens_per_second == tokens_per_second);
        return limiter;
    }

    // Check if request should be rate limited.
    pub fn check_rate_limit(
        self: *RateLimiter,
        ip_address: []const u8,
    ) bool {
        std.debug.assert(ip_address.len > 0);
        std.debug.assert(ip_address.len <= MAX_IP_LEN);
        std.debug.assert(self.entries_len <= MAX_RATE_LIMIT_ENTRIES);
        const current_time = self.current_time_fn();
        const entry = self.get_or_create_entry(ip_address, current_time);
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

    // Get or create rate limit entry for IP address.
    fn get_or_create_entry(
        self: *RateLimiter,
        ip_address: []const u8,
        current_time: u64,
    ) ?*RateLimitEntry {
        std.debug.assert(ip_address.len > 0);
        std.debug.assert(self.entries_len <= MAX_RATE_LIMIT_ENTRIES);
        var i: u32 = 0;
        while (i < self.entries_len) : (i += 1) {
            if (self.entries[i].active) {
                const entry_ip = self.entries[i].ip_address[0..self.entries[i].ip_len];
                if (std.mem.eql(u8, entry_ip, ip_address)) {
                    return &self.entries[i];
                }
            }
        }
        if (self.entries_len >= MAX_RATE_LIMIT_ENTRIES) {
            return null;
        }
        const entry = &self.entries[self.entries_len];
        entry.* = RateLimitEntry.init();
        const ip_len = @min(ip_address.len, MAX_IP_LEN);
        var j: u32 = 0;
        while (j < ip_len) : (j += 1) {
            entry.ip_address[j] = ip_address[j];
        }
        entry.ip_len = @intCast(ip_len);
        entry.tokens = self.max_tokens;
        entry.last_refill = current_time;
        entry.active = true;
        self.entries_len += 1;
        std.debug.assert(self.entries_len <= MAX_RATE_LIMIT_ENTRIES);
        return entry;
    }

    // Refill tokens based on elapsed time.
    fn refill_tokens(
        self: *RateLimiter,
        entry: *RateLimitEntry,
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

    // Clear expired entries (cleanup).
    pub fn clear_expired_entries(self: *RateLimiter, max_age_seconds: u64) u32 {
        std.debug.assert(self.entries_len <= MAX_RATE_LIMIT_ENTRIES);
        const current_time = self.current_time_fn();
        var cleared_count: u32 = 0;
        var i: u32 = 0;
        while (i < self.entries_len) : (i += 1) {
            if (!self.entries[i].active) {
                continue;
            }
            const age_seconds = (current_time - self.entries[i].last_refill) / 1000000000;
            if (age_seconds > max_age_seconds) {
                self.entries[i].active = false;
                cleared_count += 1;
            }
        }
        std.debug.assert(cleared_count <= self.entries_len);
        return cleared_count;
    }
};
