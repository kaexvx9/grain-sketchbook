//! Grain Core Workspace Persistence Errors: Structured error types for workspace persistence operations.
//!
//! Why: Replace generic anyerror with structured error unions for better error
//! handling and retryability classification.
//! Architecture: Error enum with retryability classification.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");

// Workspace persistence error types.
pub const WorkspacePersistenceError = error{
    file_not_found,
    permission_denied,
    disk_full,
    invalid_format,
    path_too_long,
    corrupted_data,
    serialization_failed,
    deserialization_failed,
    workspace_not_found,
    window_not_found,
};

// Check if workspace persistence error is retryable.
pub fn is_workspace_persistence_error_retryable(
    err: WorkspacePersistenceError,
) bool {
    std.debug.assert(err != null);
    return switch (err) {
        .disk_full => true,
        .permission_denied => true,
        .file_not_found => false,
        .invalid_format => false,
        .path_too_long => false,
        .corrupted_data => false,
        .serialization_failed => false,
        .deserialization_failed => false,
        .workspace_not_found => false,
        .window_not_found => false,
    };
}

// Get error message for workspace persistence error.
pub fn get_workspace_persistence_error_message(
    err: WorkspacePersistenceError,
) []const u8 {
    std.debug.assert(err != null);
    return switch (err) {
        .file_not_found => "Workspace persistence file not found",
        .permission_denied => "Permission denied for workspace persistence operation",
        .disk_full => "Disk full, cannot save workspace state",
        .invalid_format => "Invalid workspace persistence data format",
        .path_too_long => "Workspace persistence path exceeds maximum length",
        .corrupted_data => "Workspace persistence data is corrupted",
        .serialization_failed => "Workspace state serialization failed",
        .deserialization_failed => "Workspace state deserialization failed",
        .workspace_not_found => "Workspace not found",
        .window_not_found => "Window state not found",
    };
}

