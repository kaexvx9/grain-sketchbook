/// Aurora Agent Error Types: Structured error handling for DAG operations.
/// ~<~ Glow Airbend: explicit error types, bounded error context.
/// ~~~~ Glow Waterbend: errors flow deterministically through system.
///
/// This module provides error types and utilities for Aurora Agent operations.
/// **Note**: HTTP/WebSocket errors use Core Agent's types (`grain_core/http_errors.zig`,
/// `grain_core/websocket_errors.zig`). LLM errors use Court Agent's types
/// (`grain_court/llm_provider.zig`).
///
/// **Status**: ✅ **REFINED** — Using Core/Court Agent types directly
/// - ✅ Core Agent: HTTP/WebSocket error types integrated
/// - ✅ Court Agent: LLM provider error types available
/// - ⏳ DAG Core: DAG operation error types (pending coordination)
const std = @import("std");
const grain_core = @import("grain_core");

// Re-export Core Agent error types for convenience.
pub const HttpClientError = grain_core.http_errors.HttpClientError;
pub const WebSocketError = grain_core.websocket_errors.WebSocketError;

// Re-export Core Agent retryability functions for convenience.
pub const is_http_error_retryable = grain_core.http_errors.is_http_error_retryable;
pub const is_websocket_error_retryable = grain_core.websocket_errors.is_websocket_error_retryable;

// Re-export Court Agent LLM error types (imported when needed).
// Use: `const llm_provider = @import("grain_court/llm_provider.zig");`
// Then: `llm_provider.LlmProviderError`

/// DAG operation error types.
/// Used by `aurora_dag_integration.zig` and `dream_browser_dag_integration.zig`.
/// **Note**: Will be refined based on DAG Core coordination (HIGH PRIORITY).
pub const DagError = error{
    /// DAG node limit exceeded (DAG_MAX_NODES reached).
    NodeLimitExceeded,
    /// DAG event limit exceeded (DAG_MAX_EVENTS reached).
    EventLimitExceeded,
    /// Invalid event data (malformed event, missing fields).
    InvalidEventData,
    /// DAG corruption detected (inconsistent state).
    DagCorruption,
    /// Node not found in DAG.
    NodeNotFound,
    /// Event not found in DAG.
    EventNotFound,
    /// Invalid DAG operation (invalid parameters).
    InvalidOperation,
};

/// Check if DAG error is retryable.
/// Retryable errors: None (all DAG errors are non-retryable).
/// Non-retryable errors: All DAG errors indicate permanent failures.
pub fn isDagErrorRetryable(err: DagError) bool {
    _ = err;
    return false;
}

/// Get retry delay for retryable errors (exponential backoff).
/// Returns delay in milliseconds based on retry attempt (1s, 2s, 4s, 8s).
/// Max retries: 3 (attempts 0, 1, 2).
pub fn getRetryDelayMs(attempt: u32) u32 {
    std.debug.assert(attempt < 3);
    return switch (attempt) {
        0 => 1_000,   // 1 second
        1 => 2_000,   // 2 seconds
        2 => 4_000,   // 4 seconds
        else => 8_000, // 8 seconds (max)
    };
}

/// Max retry attempts for retryable errors.
pub const MAX_RETRY_ATTEMPTS: u32 = 3;

/// Default timeout values (in milliseconds).
pub const TimeoutConfig = struct {
    /// Default HTTP request timeout (30 seconds).
    pub const HTTP_REQUEST_MS: u32 = 30_000;
    /// Default HTTP content fetch timeout (60 seconds).
    pub const HTTP_CONTENT_MS: u32 = 60_000;
    /// Default LLM completion request timeout (60 seconds).
    pub const LLM_COMPLETION_MS: u32 = 60_000;
    /// Default WebSocket connection timeout (10 seconds).
    pub const WEBSOCKET_CONNECT_MS: u32 = 10_000;
    /// Default WebSocket message send timeout (5 seconds).
    pub const WEBSOCKET_SEND_MS: u32 = 5_000;
};
