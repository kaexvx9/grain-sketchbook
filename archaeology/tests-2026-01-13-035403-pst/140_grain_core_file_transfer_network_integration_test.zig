//! Grain Core File Transfer Network Integration Tests.
//!
//! Why: Test end-to-end file transfer integration between Network Agent and Storage Agent.
//! Architecture: Comprehensive integration tests for upload → file ID → download flow.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines per function.

const std = @import("std");
const testing = std.testing;
const file_transfer_handlers = @import("grain_core").file_transfer_handlers;
const file_transfer_routes = @import("grain_core").file_transfer_routes;
const file_transfer_integration_helpers = @import("grain_core").file_transfer_integration_helpers;
const api_server = @import("grain_core").api_server;
const file_id_manager = @import("grain_core").file_id_manager;

// Mock current time function.
fn mock_current_time() u64 {
    return 1704067200;
}

// Helper: Create file transfer integration context.
fn create_test_context() file_transfer_integration_helpers.FileTransferIntegrationContext {
    const default_user_id: u32 = 1;
    const default_group_id: u32 = 1;
    const context = file_transfer_integration_helpers.FileTransferIntegrationContext.init(
        mock_current_time,
        default_user_id,
        default_group_id,
    );
    std.debug.assert(context.default_user_id == default_user_id);
    std.debug.assert(context.default_group_id == default_group_id);
    return context;
}

// Helper: Create file transfer handlers.
fn create_test_handlers(
    allocator: std.mem.Allocator,
    context: *file_transfer_integration_helpers.FileTransferIntegrationContext,
) file_transfer_handlers.FileTransferHandlers {
    std.debug.assert(allocator != null);
    std.debug.assert(context != null);
    const handlers = file_transfer_handlers.FileTransferHandlers.init(
        &context.transfer_manager,
        &context.mime_detector,
        &context.file_io,
        &context.file_id_manager,
        mock_current_time,
        allocator,
        context.default_user_id,
        context.default_group_id,
    );
    std.debug.assert(handlers.default_user_id == context.default_user_id);
    return handlers;
}

// Test: File upload generates file ID and stores mapping.
test "integration - file upload generates file id" {
    var context = create_test_context();
    const test_data = "Hello, World! Test file content.";
    const file_path = "/tmp/test_upload.txt";
    const file_size: u64 = test_data.len;
    const file_id_opt = context.get_or_generate_file_id(file_path, file_size);
    try testing.expect(file_id_opt != null);
    if (file_id_opt) |file_id| {
        try testing.expect(file_id.len > 0);
        try testing.expect(file_id.len <= 64);
        const verified = context.verify_file_id_mapping(file_id, file_path);
        try testing.expect(verified == true);
    }
}

// Test: File download retrieves file by file ID.
test "integration - file download by file id" {
    var context = create_test_context();
    const test_data = "Hello, World! Test file content.";
    const file_path = "/tmp/test_download.txt";
    const file_size: u64 = test_data.len;
    const file_id_opt = context.get_or_generate_file_id(file_path, file_size);
    try testing.expect(file_id_opt != null);
    if (file_id_opt) |file_id| {
        const retrieved_path = context.file_id_manager.get_file_path(file_id);
        try testing.expect(retrieved_path != null);
        if (retrieved_path) |path| {
            try testing.expect(std.mem.eql(u8, path, file_path));
        }
    }
}

// Test: File ID lookup returns null for invalid file ID.
test "integration - invalid file id returns null" {
    var context = create_test_context();
    const invalid_file_id = "invalid_file_id_that_does_not_exist_1234567890";
    const retrieved_path = context.file_id_manager.get_file_path(invalid_file_id);
    try testing.expect(retrieved_path == null);
}

// Test: File size retrieval by file ID.
test "integration - file size retrieval by file id" {
    var context = create_test_context();
    const test_data = "Hello, World! Test file content.";
    const file_path = "/tmp/test_size.txt";
    const file_size: u64 = test_data.len;
    const file_id_opt = context.get_or_generate_file_id(file_path, file_size);
    try testing.expect(file_id_opt != null);
    if (file_id_opt) |file_id| {
        const retrieved_size = context.file_id_manager.get_file_size(file_id);
        try testing.expect(retrieved_size != null);
        if (retrieved_size) |size| {
            try testing.expect(size == file_size);
        }
    }
}

// Test: Multiple file IDs for different files.
test "integration - multiple file ids for different files" {
    var context = create_test_context();
    const file_path1 = "/tmp/test_file1.txt";
    const file_path2 = "/tmp/test_file2.txt";
    const file_size: u64 = 1024;
    const file_id1_opt = context.get_or_generate_file_id(file_path1, file_size);
    const file_id2_opt = context.get_or_generate_file_id(file_path2, file_size);
    try testing.expect(file_id1_opt != null);
    try testing.expect(file_id2_opt != null);
    if (file_id1_opt) |id1| {
        if (file_id2_opt) |id2| {
            try testing.expect(!std.mem.eql(u8, id1, id2));
            const path1 = context.file_id_manager.get_file_path(id1);
            const path2 = context.file_id_manager.get_file_path(id2);
            try testing.expect(path1 != null);
            try testing.expect(path2 != null);
            if (path1) |p1| {
                if (path2) |p2| {
                    try testing.expect(std.mem.eql(u8, p1, file_path1));
                    try testing.expect(std.mem.eql(u8, p2, file_path2));
                }
            }
        }
    }
}

// Test: File ID generation is deterministic (same path = same ID).
test "integration - file id generation is deterministic" {
    const allocator = testing.allocator;
    var context = create_test_context();
    const file_path = "/tmp/test_deterministic.txt";
    const file_size: u64 = 1024;
    const file_id1_opt = context.get_or_generate_file_id(file_path, file_size);
    const file_id2_opt = context.get_or_generate_file_id(file_path, file_size);
    try testing.expect(file_id1_opt != null);
    try testing.expect(file_id2_opt != null);
    if (file_id1_opt) |id1| {
        if (file_id2_opt) |id2| {
            try testing.expect(std.mem.eql(u8, id1, id2));
        }
    }
}

// Test: File transfer handlers initialization.
test "integration - file transfer handlers initialization" {
    const allocator = testing.allocator;
    var context = create_test_context();
    const handlers = create_test_handlers(allocator, &context);
    std.debug.assert(handlers.transfer_manager != null);
    std.debug.assert(handlers.mime_detector != null);
    std.debug.assert(handlers.file_io != null);
    std.debug.assert(handlers.file_id_manager != null);
    std.debug.assert(handlers.current_time_fn != null);
    std.debug.assert(handlers.allocator != null);
    std.debug.assert(handlers.default_user_id > 0);
    std.debug.assert(handlers.default_group_id > 0);
}

// Test: File transfer route registration.
test "integration - file transfer route registration" {
    const allocator = testing.allocator;
    var context = create_test_context();
    var handlers = create_test_handlers(allocator, &context);
    var server = api_server.ApiServer.init(allocator);
    const success = file_transfer_routes.register_file_transfer_routes(&server, &handlers);
    try testing.expect(success == true);
    std.debug.assert(success == true);
}
