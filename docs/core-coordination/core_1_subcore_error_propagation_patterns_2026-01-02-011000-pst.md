# Core 1 Subcore: Error Propagation Patterns

**Date**: 2026-01-02-011000-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Error propagation patterns for Core 1 Subcore

---

## Executive Summary

This document defines error propagation patterns for Core 1 Subcore L2 sub-agents. These patterns ensure consistent, safe, and informative error handling across Auth (1a), Network (1b), Storage (1c), Compositor (1d), and Grainscript Shell (1e) agents.

**Purpose**: Provide standardized error propagation patterns for cross-sub-agent integration.

---

## Core Principles

### Explicit Error Types

- All errors must be explicitly defined
- Error types must be bounded and documented
- Error context must be preserved
- Error recovery must be possible

### Error Propagation

- Errors must propagate explicitly
- Error context must be maintained
- Error recovery must be attempted where possible
- Fatal errors must be logged and propagated

### Grain Style Compliance

- `grain_case` function names
- Explicit `u32`/`u64` types
- Bounded error messages
- Minimum 2 assertions per function

---

## Error Type Hierarchy

### Integration Errors

```zig
pub const IntegrationError = error{
    // Auth errors
    AuthValidationFailed,
    AuthTokenExpired,
    AuthTokenInvalid,
    AuthPermissionDenied,
    
    // Network errors
    NetworkConnectionFailed,
    NetworkTimeout,
    NetworkProtocolError,
    NetworkRateLimitExceeded,
    
    // Storage errors
    StorageFileNotFound,
    StoragePermissionDenied,
    StorageQuotaExceeded,
    StorageCorruption,
    
    // Compositor errors
    CompositorWindowNotFound,
    CompositorResourceExhausted,
    CompositorInvalidState,
    
    // Shell errors
    ShellCommandNotFound,
    ShellExecutionFailed,
    ShellPermissionDenied,
};
```

### Error Context

```zig
pub const ErrorContext = struct {
    error_type: IntegrationError,
    message: []const u8,
    message_len: u32,
    source_agent: AgentId,
    timestamp: u64,
    
    pub const MAX_MESSAGE_LEN: u32 = 512;
    pub const AgentId = enum(u8) {
        auth = 1,
        network = 2,
        storage = 3,
        compositor = 4,
        shell = 5,
    };
};
```

---

## Error Propagation Pattern 1: Immediate Propagation

### Pattern Overview

**Purpose**: Propagate error immediately without modification.

**Use Case**: Fatal errors, errors that cannot be recovered

### Implementation

```zig
pub fn process_request(...) IntegrationError!void {
    // Validate input
    validate_input(input) catch |err| {
        return err;  // Immediate propagation
    };
    
    // Process request
    process_data(data) catch |err| {
        return err;  // Immediate propagation
    };
}
```

### When to Use

- Fatal errors
- Errors that cannot be recovered
- Errors that require immediate attention
- Errors that block further processing

---

## Error Propagation Pattern 2: Error Transformation

### Pattern Overview

**Purpose**: Transform error to provide context or map to different error type.

**Use Case**: Cross-sub-agent integration, error context addition

### Implementation

```zig
pub fn transfer_file(...) IntegrationError!void {
    // Attempt file transfer
    storage.save_file(data) catch |err| {
        // Transform storage error to network error
        return switch (err) {
            error.StorageFileNotFound => error.NetworkConnectionFailed,
            error.StoragePermissionDenied => error.NetworkProtocolError,
            else => err,
        };
    };
}
```

### When to Use

- Cross-sub-agent integration
- Error type mapping
- Error context addition
- Error normalization

---

## Error Propagation Pattern 3: Error Recovery

### Pattern Overview

**Purpose**: Attempt error recovery before propagating.

**Use Case**: Retryable errors, transient failures

### Implementation

```zig
pub fn process_with_retry(...) IntegrationError!void {
    const max_retries: u32 = 3;
    var retry_count: u32 = 0;
    
    while (retry_count < max_retries) : (retry_count += 1) {
        process_data(data) catch |err| {
            // Check if retryable
            if (is_retryable_error(err)) {
                // Wait before retry
                wait_for_retry(retry_count);
                continue;
            }
            
            // Non-retryable error, propagate
            return err;
        };
        
        // Success
        return;
    }
    
    // All retries exhausted
    return error.NetworkTimeout;
}
```

### When to Use

- Retryable errors
- Transient failures
- Network timeouts
- Temporary resource unavailability

---

## Error Propagation Pattern 4: Error Logging

### Pattern Overview

**Purpose**: Log error before propagating.

**Use Case**: All errors (for debugging and monitoring)

### Implementation

```zig
pub fn process_with_logging(...) IntegrationError!void {
    process_data(data) catch |err| {
        // Log error
        log_error(err, "process_data failed", .{}) catch {
            // Logging failed, but continue propagation
        };
        
        // Propagate error
        return err;
    };
}
```

### When to Use

- All errors (for debugging)
- Critical errors (for monitoring)
- Error tracking
- Debugging support

---

## Error Propagation Pattern 5: Error Aggregation

### Pattern Overview

**Purpose**: Aggregate multiple errors into single error.

**Use Case**: Batch operations, multiple error sources

### Implementation

```zig
pub const ErrorAggregator = struct {
    errors: [MAX_ERRORS]ErrorContext,
    errors_len: u32,
    
    pub const MAX_ERRORS: u32 = 100;
    
    /// Add error to aggregator.
    pub fn add_error(
        self: *ErrorAggregator,
        err: IntegrationError,
        message: []const u8,
    ) !void {
        std.debug.assert(self.errors_len < MAX_ERRORS);
        std.debug.assert(message.len <= ErrorContext.MAX_MESSAGE_LEN);
        
        self.errors[self.errors_len] = ErrorContext{
            .error_type = err,
            .message = message,
            .message_len = @as(u32, @intCast(message.len)),
            .source_agent = .network,
            .timestamp = std.time.timestamp(),
        };
        
        self.errors_len += 1;
    }
    
    /// Get aggregated error.
    pub fn get_aggregated_error(self: *const ErrorAggregator) IntegrationError {
        std.debug.assert(self.errors_len > 0);
        
        // Return first error (or most critical)
        return self.errors[0].error_type;
    }
};
```

### When to Use

- Batch operations
- Multiple error sources
- Error collection
- Error reporting

---

## Error Handling Strategy

### Strategy 1: Immediate Errors

**Description**: Return error immediately without recovery.

**Use Case**: Fatal errors, invalid input, permission denied

**Implementation**: Immediate error propagation

### Strategy 2: Retryable Errors

**Description**: Attempt retry with exponential backoff.

**Use Case**: Network timeouts, temporary failures

**Implementation**: Retry logic with exponential backoff

### Strategy 3: Fatal Errors

**Description**: Log error and propagate to caller.

**Use Case**: System errors, corruption, resource exhaustion

**Implementation**: Error logging + propagation

### Strategy 4: Recoverable Errors

**Description**: Return default/fallback value.

**Use Case**: Optional features, degraded mode

**Implementation**: Error handling with fallback

---

## Error Recovery Patterns

### Pattern 1: Exponential Backoff

```zig
pub fn wait_for_retry(retry_count: u32) void {
    std.debug.assert(retry_count > 0);
    
    const delay_ms = @as(u64, 1) << @as(u6, @intCast(retry_count - 1));  // 1s, 2s, 4s, 8s
    const max_delay_ms: u64 = 60_000;  // 60 seconds max
    
    const actual_delay = @min(delay_ms, max_delay_ms);
    std.time.sleep(actual_delay * 1_000_000);  // Convert to nanoseconds
}
```

### Pattern 2: Circuit Breaker

```zig
pub const CircuitBreaker = struct {
    failure_count: u32,
    last_failure_time: u64,
    state: CircuitState,
    
    pub const CircuitState = enum(u8) {
        closed,  // Normal operation
        open,    // Failing, reject requests
        half_open,  // Testing recovery
    };
    
    pub const MAX_FAILURES: u32 = 5;
    pub const CIRCUIT_OPEN_TIMEOUT_MS: u64 = 60_000;  // 60 seconds
    
    /// Check if circuit is open.
    pub fn is_open(self: *CircuitBreaker) bool {
        const now = std.time.timestamp() * 1000;  // Convert to ms
        
        switch (self.state) {
            .closed => return false,
            .open => {
                // Check if timeout expired
                if (now - self.last_failure_time > CIRCUIT_OPEN_TIMEOUT_MS) {
                    self.state = .half_open;
                    return false;
                }
                return true;
            },
            .half_open => return false,
        }
    }
    
    /// Record failure.
    pub fn record_failure(self: *CircuitBreaker) void {
        self.failure_count += 1;
        self.last_failure_time = std.time.timestamp() * 1000;
        
        if (self.failure_count >= MAX_FAILURES) {
            self.state = .open;
        }
    }
    
    /// Record success.
    pub fn record_success(self: *CircuitBreaker) void {
        self.failure_count = 0;
        self.state = .closed;
    }
};
```

---

## Error Context Preservation

### Pattern: Error Wrapping

```zig
pub fn process_with_context(...) IntegrationError!void {
    process_data(data) catch |err| {
        // Wrap error with context
        return error_with_context(
            err,
            "process_data failed in process_with_context",
            .{},
        );
    };
}

fn error_with_context(
    err: IntegrationError,
    context: []const u8,
    args: anytype,
) IntegrationError {
    // Log error with context
    log_error(err, context, args) catch {};
    
    // Return original error (preserve error type)
    return err;
}
```

---

## Error Classification

### Retryable Errors

```zig
pub fn is_retryable_error(err: IntegrationError) bool {
    return switch (err) {
        .NetworkTimeout,
        .NetworkConnectionFailed,
        .StorageQuotaExceeded,
        => true,
        else => false,
    };
}
```

### Fatal Errors

```zig
pub fn is_fatal_error(err: IntegrationError) bool {
    return switch (err) {
        .StorageCorruption,
        .CompositorInvalidState,
        .AuthPermissionDenied,
        => true,
        else => false,
    };
}
```

### Recoverable Errors

```zig
pub fn is_recoverable_error(err: IntegrationError) bool {
    return switch (err) {
        .StorageFileNotFound,
        .CompositorWindowNotFound,
        .ShellCommandNotFound,
        => true,
        else => false,
    };
}
```

---

## Error Propagation Across Sub-Agents

### Pattern: Error Mapping

```zig
// Auth Agent error → Network Agent error
pub fn map_auth_error(err: AuthError) IntegrationError {
    return switch (err) {
        .InvalidCredentials => IntegrationError.AuthValidationFailed,
        .TokenExpired => IntegrationError.AuthTokenExpired,
        .PermissionDenied => IntegrationError.AuthPermissionDenied,
        else => IntegrationError.AuthValidationFailed,
    };
}

// Network Agent error → Storage Agent error
pub fn map_network_error(err: NetworkError) IntegrationError {
    return switch (err) {
        .ConnectionFailed => IntegrationError.NetworkConnectionFailed,
        .Timeout => IntegrationError.NetworkTimeout,
        .ProtocolError => IntegrationError.NetworkProtocolError,
        else => IntegrationError.NetworkConnectionFailed,
    };
}
```

---

## Error Logging Patterns

### Pattern: Structured Logging

```zig
pub fn log_integration_error(
    err: IntegrationError,
    context: ErrorContext,
) void {
    std.debug.print(
        "[ERROR] {s}: {s} (agent: {}, time: {})\n",
        .{
            @errorName(err),
            context.message,
            @intFromEnum(context.source_agent),
            context.timestamp,
        },
    );
}
```

---

## Notes

- All patterns follow Grain Style strictly
- All patterns use explicit error types
- All patterns preserve error context
- All patterns support error recovery
- Patterns support both Core services and sevenos integration

---

**Date**: 2026-01-02-011000-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: Design In Progress — Error Propagation Patterns Ready for Implementation

