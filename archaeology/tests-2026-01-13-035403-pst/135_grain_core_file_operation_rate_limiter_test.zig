//! Grain Core File Operation Rate Limiter Tests.
//!
//! Why: Test file operation rate limiting functionality.
//! Architecture: Unit tests for rate limiter.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const file_operation_rate_limiter = @import("grain_core").file_operation_rate_limiter;

test "file operation rate limiter init" {
    var time_counter: u64 = 1000;
    fn get_time() u64 {
        return time_counter;
    }
    const limiter = file_operation_rate_limiter.FileOperationRateLimiter.init(
        10,
        100,
        get_time,
    );
    std.debug.assert(limiter.tokens_per_second == 10);
    std.debug.assert(limiter.max_tokens == 100);
    std.debug.assert(limiter.entries_len == 0);
}

test "file operation rate limiter check rate limit" {
    var time_counter: u64 = 1000;
    fn get_time() u64 {
        return time_counter;
    }
    var limiter = file_operation_rate_limiter.FileOperationRateLimiter.init(
        10,
        100,
        get_time,
    );
    const user_id: u32 = 1000;
    const allowed = limiter.check_rate_limit(user_id);
    std.debug.assert(allowed);
    std.debug.assert(limiter.entries_len == 1);
    std.debug.assert(limiter.entries[0].user_id == user_id);
    std.debug.assert(limiter.entries[0].tokens == 99);
}

test "file operation rate limiter exhaust tokens" {
    var time_counter: u64 = 1000;
    fn get_time() u64 {
        return time_counter;
    }
    var limiter = file_operation_rate_limiter.FileOperationRateLimiter.init(
        10,
        5,
        get_time,
    );
    const user_id: u32 = 1000;
    var i: u32 = 0;
    while (i < 5) : (i += 1) {
        const allowed = limiter.check_rate_limit(user_id);
        std.debug.assert(allowed);
    }
    const denied = limiter.check_rate_limit(user_id);
    std.debug.assert(!denied);
}

test "file operation rate limiter token refill" {
    var time_counter: u64 = 1000;
    fn get_time() u64 {
        return time_counter;
    }
    var limiter = file_operation_rate_limiter.FileOperationRateLimiter.init(
        10,
        100,
        get_time,
    );
    const user_id: u32 = 1000;
    _ = limiter.check_rate_limit(user_id);
    std.debug.assert(limiter.entries[0].tokens == 99);
    time_counter = 2000;
    const allowed = limiter.check_rate_limit(user_id);
    std.debug.assert(allowed);
    std.debug.assert(limiter.entries[0].tokens >= 98);
}

test "file operation rate limiter multiple users" {
    var time_counter: u64 = 1000;
    fn get_time() u64 {
        return time_counter;
    }
    var limiter = file_operation_rate_limiter.FileOperationRateLimiter.init(
        10,
        100,
        get_time,
    );
    const user1: u32 = 1000;
    const user2: u32 = 2000;
    const allowed1 = limiter.check_rate_limit(user1);
    const allowed2 = limiter.check_rate_limit(user2);
    std.debug.assert(allowed1);
    std.debug.assert(allowed2);
    std.debug.assert(limiter.entries_len == 2);
}

test "file operation rate limiter clear expired entries" {
    var time_counter: u64 = 1000;
    fn get_time() u64 {
        return time_counter;
    }
    var limiter = file_operation_rate_limiter.FileOperationRateLimiter.init(
        10,
        100,
        get_time,
    );
    const user_id: u32 = 1000;
    _ = limiter.check_rate_limit(user_id);
    std.debug.assert(limiter.entries_len == 1);
    time_counter = 1000 + (100 * 1000000000);
    const cleared = limiter.clear_expired_entries(60);
    std.debug.assert(cleared == 1);
}
