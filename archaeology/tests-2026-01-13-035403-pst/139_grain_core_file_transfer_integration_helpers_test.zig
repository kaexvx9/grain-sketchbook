//! Tests for Grain Core File Transfer Integration Helpers.
//!
//! Why: Verify integration helper functions for Network Agent integration.
//! Architecture: Unit tests for file_transfer_integration_helpers.zig.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const file_transfer_integration_helpers = @import("grain_core").file_transfer_integration_helpers;

// Mock current time function.
fn mock_current_time() u64 {
    return 1704067200;
}

test "file transfer integration context initialization" {
    const default_user_id: u32 = 1;
    const default_group_id: u32 = 1;
    const context = file_transfer_integration_helpers.FileTransferIntegrationContext.init(
        mock_current_time,
        default_user_id,
        default_group_id,
    );
    try testing.expect(context.default_user_id == default_user_id);
    try testing.expect(context.default_group_id == default_group_id);
    try testing.expect(context.current_time_fn == mock_current_time);
}

test "get or generate file id" {
    const default_user_id: u32 = 1;
    const default_group_id: u32 = 1;
    var context = file_transfer_integration_helpers.FileTransferIntegrationContext.init(
        mock_current_time,
        default_user_id,
        default_group_id,
    );
    const file_path = "/tmp/test_file.txt";
    const file_size: u64 = 1024;
    const file_id = context.get_or_generate_file_id(file_path, file_size);
    try testing.expect(file_id != null);
    if (file_id) |id| {
        try testing.expect(id.len > 0);
        try testing.expect(id.len <= 64);
    }
}

test "verify file id mapping" {
    const default_user_id: u32 = 1;
    const default_group_id: u32 = 1;
    var context = file_transfer_integration_helpers.FileTransferIntegrationContext.init(
        mock_current_time,
        default_user_id,
        default_group_id,
    );
    const file_path = "/tmp/test_file.txt";
    const file_size: u64 = 1024;
    const file_id_opt = context.get_or_generate_file_id(file_path, file_size);
    try testing.expect(file_id_opt != null);
    if (file_id_opt) |file_id| {
        const verified = context.verify_file_id_mapping(file_id, file_path);
        try testing.expect(verified == true);
    }
}

test "verify file id mapping with wrong path" {
    const default_user_id: u32 = 1;
    const default_group_id: u32 = 1;
    var context = file_transfer_integration_helpers.FileTransferIntegrationContext.init(
        mock_current_time,
        default_user_id,
        default_group_id,
    );
    const file_path = "/tmp/test_file.txt";
    const file_size: u64 = 1024;
    const file_id_opt = context.get_or_generate_file_id(file_path, file_size);
    try testing.expect(file_id_opt != null);
    if (file_id_opt) |file_id| {
        const wrong_path = "/tmp/wrong_file.txt";
        const verified = context.verify_file_id_mapping(file_id, wrong_path);
        try testing.expect(verified == false);
    }
}

test "get or generate file id for multiple files" {
    const default_user_id: u32 = 1;
    const default_group_id: u32 = 1;
    var context = file_transfer_integration_helpers.FileTransferIntegrationContext.init(
        mock_current_time,
        default_user_id,
        default_group_id,
    );
    const file_path1 = "/tmp/test_file1.txt";
    const file_path2 = "/tmp/test_file2.txt";
    const file_size: u64 = 1024;
    const file_id1 = context.get_or_generate_file_id(file_path1, file_size);
    const file_id2 = context.get_or_generate_file_id(file_path2, file_size);
    try testing.expect(file_id1 != null);
    try testing.expect(file_id2 != null);
    if (file_id1) |id1| {
        if (file_id2) |id2| {
            try testing.expect(!std.mem.eql(u8, id1, id2));
        }
    }
}
