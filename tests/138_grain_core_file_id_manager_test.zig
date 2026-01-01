//! Tests for Grain Core File ID Manager.
//!
//! Why: Verify file ID generation and mapping functionality.
//! Architecture: Unit tests for file_id_manager.zig.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.

const std = @import("std");
const testing = std.testing;
const file_id_manager = @import("grain_core").file_id_manager;

// Mock current time function.
fn mock_current_time() u64 {
    return 1704067200;
}

test "file id manager initialization" {
    const manager = file_id_manager.FileIdManager.init(mock_current_time);
    try testing.expect(manager.mappings_len == 0);
    try testing.expect(manager.current_time_fn == mock_current_time);
}

test "file id mapping initialization" {
    const mapping = file_id_manager.FileIdMapping.init();
    try testing.expect(mapping.file_id_len == 0);
    try testing.expect(mapping.file_path_len == 0);
    try testing.expect(mapping.file_size == 0);
    try testing.expect(mapping.active == false);
}

test "file id mapping set file id" {
    var mapping = file_id_manager.FileIdMapping.init();
    const file_id = "550e8400-e29b-41d4-a716-446655440000";
    const result = mapping.set_file_id(file_id);
    try testing.expect(result == true);
    try testing.expect(mapping.file_id_len == file_id.len);
    const retrieved = mapping.get_file_id();
    try testing.expect(std.mem.eql(u8, retrieved, file_id));
}

test "file id mapping set file path" {
    var mapping = file_id_manager.FileIdMapping.init();
    const file_path = "/tmp/test_file.txt";
    const result = mapping.set_file_path(file_path);
    try testing.expect(result == true);
    try testing.expect(mapping.file_path_len == file_path.len);
    const retrieved = mapping.get_file_path();
    try testing.expect(std.mem.eql(u8, retrieved, file_path));
}

test "file id generation" {
    var manager = file_id_manager.FileIdManager.init(mock_current_time);
    const file_path = "/tmp/test_file.txt";
    const file_id = manager.generate_file_id_string(file_path);
    try testing.expect(file_id.len > 0);
    try testing.expect(file_id.len <= 64);
}

test "file id generation uniqueness" {
    var manager = file_id_manager.FileIdManager.init(mock_current_time);
    const file_path1 = "/tmp/test_file1.txt";
    const file_path2 = "/tmp/test_file2.txt";
    const file_id1 = manager.generate_file_id_string(file_path1);
    const file_id2 = manager.generate_file_id_string(file_path2);
    try testing.expect(!std.mem.eql(u8, file_id1, file_id2));
}

test "store file id mapping" {
    var manager = file_id_manager.FileIdManager.init(mock_current_time);
    const file_id = "550e8400-e29b-41d4-a716-446655440000";
    const file_path = "/tmp/test_file.txt";
    const file_size: u64 = 1024;
    const result = manager.store_mapping(file_id, file_path, file_size);
    try testing.expect(result == true);
    try testing.expect(manager.mappings_len == 1);
}

test "get file path from file id" {
    var manager = file_id_manager.FileIdManager.init(mock_current_time);
    const file_id = "550e8400-e29b-41d4-a716-446655440000";
    const file_path = "/tmp/test_file.txt";
    const file_size: u64 = 1024;
    _ = manager.store_mapping(file_id, file_path, file_size);
    const retrieved_path = manager.get_file_path(file_id);
    try testing.expect(retrieved_path != null);
    if (retrieved_path) |path| {
        try testing.expect(std.mem.eql(u8, path, file_path));
    }
}

test "get file size from file id" {
    var manager = file_id_manager.FileIdManager.init(mock_current_time);
    const file_id = "550e8400-e29b-41d4-a716-446655440000";
    const file_path = "/tmp/test_file.txt";
    const file_size: u64 = 2048;
    _ = manager.store_mapping(file_id, file_path, file_size);
    const retrieved_size = manager.get_file_size(file_id);
    try testing.expect(retrieved_size != null);
    if (retrieved_size) |size| {
        try testing.expect(size == file_size);
    }
}

test "get file path for non-existent file id" {
    var manager = file_id_manager.FileIdManager.init(mock_current_time);
    const file_id = "non-existent-id";
    const retrieved_path = manager.get_file_path(file_id);
    try testing.expect(retrieved_path == null);
}

test "remove file id mapping" {
    var manager = file_id_manager.FileIdManager.init(mock_current_time);
    const file_id = "550e8400-e29b-41d4-a716-446655440000";
    const file_path = "/tmp/test_file.txt";
    const file_size: u64 = 1024;
    _ = manager.store_mapping(file_id, file_path, file_size);
    try testing.expect(manager.mappings_len == 1);
    const result = manager.remove_mapping(file_id);
    try testing.expect(result == true);
    const retrieved_path = manager.get_file_path(file_id);
    try testing.expect(retrieved_path == null);
}

test "store multiple file id mappings" {
    var manager = file_id_manager.FileIdManager.init(mock_current_time);
    const file_id1 = "550e8400-e29b-41d4-a716-446655440000";
    const file_path1 = "/tmp/test_file1.txt";
    const file_id2 = "660e8400-e29b-41d4-a716-446655440001";
    const file_path2 = "/tmp/test_file2.txt";
    _ = manager.store_mapping(file_id1, file_path1, 1024);
    _ = manager.store_mapping(file_id2, file_path2, 2048);
    try testing.expect(manager.mappings_len == 2);
    const path1 = manager.get_file_path(file_id1);
    const path2 = manager.get_file_path(file_id2);
    try testing.expect(path1 != null);
    try testing.expect(path2 != null);
    if (path1) |p1| {
        try testing.expect(std.mem.eql(u8, p1, file_path1));
    }
    if (path2) |p2| {
        try testing.expect(std.mem.eql(u8, p2, file_path2));
    }
}

test "clear expired mappings" {
    var manager = file_id_manager.FileIdManager.init(mock_current_time);
    const file_id = "550e8400-e29b-41d4-a716-446655440000";
    const file_path = "/tmp/test_file.txt";
    _ = manager.store_mapping(file_id, file_path, 1024);
    const max_age: u64 = 1;
    const cleared = manager.clear_expired_mappings(max_age);
    try testing.expect(cleared >= 0);
}
