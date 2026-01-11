//! Tests for Aurora Virtual File System (VFS).
//!
//! Why: Verify VFS functionality (virtual file registration, file handles, read/write operations).
//! Architecture: Comprehensive test coverage for VFS operations.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions.
//!
//! 2026-01-06-095708-pst: Grain Aurora Agent

const std = @import("std");
const testing = std.testing;
const Vfs = @import("aurora_vfs").Vfs;

test "vfs initialization" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    // Assert: VFS initialized correctly
    std.debug.assert(vfs.virtual_files.items.len == 0);
    std.debug.assert(vfs.file_handles.items.len == 0);
    std.debug.assert(vfs.next_handle_id == 1);
}

test "vfs register virtual file" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    const GrainBuffer = @import("grain_buffer").GrainBuffer;

    // Create virtual file buffer
    const text = "virtual file content\n";
    var buffer = try GrainBuffer.fromSlice(allocator, text);
    defer buffer.deinit();

    // Register virtual file
    const path = ".jj/status.jj";
    const registered = try vfs.register_virtual_file(path, buffer, null);

    // Assert: Virtual file registered successfully
    std.debug.assert(registered == true);
    std.debug.assert(vfs.virtual_files.items.len == 1);
    std.debug.assert(std.mem.eql(u8, vfs.virtual_files.items[0].path, path));
}

test "vfs register virtual file with readonly ranges" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    const GrainBuffer = @import("grain_buffer").GrainBuffer;

    // Create virtual file buffer
    const text = "commit abc123\nfile: test.zig\n";
    var buffer = try GrainBuffer.fromSlice(allocator, text);
    defer buffer.deinit();

    // Create readonly ranges
    const readonly_ranges = [_]Vfs.ReadonlyRange{
        Vfs.ReadonlyRange{
            .start = 0,
            .end = 13, // "commit abc123"
            .type = .commit_hash,
        },
    };

    // Register virtual file
    const path = ".jj/status.jj";
    const registered = try vfs.register_virtual_file(path, buffer, &readonly_ranges);

    // Assert: Virtual file registered with readonly ranges
    std.debug.assert(registered == true);
    std.debug.assert(vfs.virtual_files.items.len == 1);
    std.debug.assert(vfs.virtual_files.items[0].readonly_ranges.len == 1);
    std.debug.assert(vfs.virtual_files.items[0].readonly_ranges[0].type == .commit_hash);
}

test "vfs get virtual file" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    const GrainBuffer = @import("grain_buffer").GrainBuffer;

    // Create and register virtual file
    const text = "virtual file content\n";
    var buffer = try GrainBuffer.fromSlice(allocator, text);
    defer buffer.deinit();

    const path = ".jj/status.jj";
    _ = try vfs.register_virtual_file(path, buffer, null);

    // Get virtual file
    const vf = vfs.get_virtual_file(path);

    // Assert: Virtual file found
    std.debug.assert(vf != null);
    std.debug.assert(std.mem.eql(u8, vf.?.path, path));
}

test "vfs get virtual file not found" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    // Get non-existent virtual file
    const vf = vfs.get_virtual_file(".jj/nonexistent.jj");

    // Assert: Virtual file not found
    std.debug.assert(vf == null);
}

test "vfs open file virtual" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    const GrainBuffer = @import("grain_buffer").GrainBuffer;

    // Register virtual file
    const text = "virtual file content\n";
    var buffer = try GrainBuffer.fromSlice(allocator, text);
    defer buffer.deinit();

    const path = ".jj/status.jj";
    _ = try vfs.register_virtual_file(path, buffer, null);

    // Open virtual file
    const handle_id = try vfs.open_file(path, false);

    // Assert: File handle created
    std.debug.assert(handle_id > 0);
    std.debug.assert(vfs.file_handles.items.len == 1);
    std.debug.assert(vfs.file_handles.items[0].handle_id == handle_id);
    std.debug.assert(vfs.file_handles.items[0].file_type == .virtual);
}

test "vfs open file regular" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    // Open regular file (creates in-memory file)
    const path = "test.zig";
    const handle_id = try vfs.open_file(path, false);

    // Assert: File handle created
    std.debug.assert(handle_id > 0);
    std.debug.assert(vfs.file_handles.items.len == 1);
    std.debug.assert(vfs.file_handles.items[0].handle_id == handle_id);
    std.debug.assert(vfs.file_handles.items[0].file_type == .regular);
}

test "vfs read file" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    const GrainBuffer = @import("grain_buffer").GrainBuffer;

    // Register virtual file
    const text = "virtual file content\n";
    var buffer = try GrainBuffer.fromSlice(allocator, text);
    defer buffer.deinit();

    const path = ".jj/status.jj";
    _ = try vfs.register_virtual_file(path, buffer, null);

    // Open and read file
    const handle_id = try vfs.open_file(path, false);
    var read_buffer: [256]u8 = undefined;
    const bytes_read = try vfs.read_file(handle_id, &read_buffer);

    // Assert: File read successfully
    std.debug.assert(bytes_read > 0);
    std.debug.assert(std.mem.eql(u8, read_buffer[0..bytes_read], text[0..bytes_read]));
}

test "vfs write file" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    // Open regular file
    const path = "test.zig";
    const handle_id = try vfs.open_file(path, false);

    // Write to file
    const data = "test content\n";
    const bytes_written = try vfs.write_file(handle_id, data);

    // Assert: File written successfully
    std.debug.assert(bytes_written == data.len);

    // Read back
    var read_buffer: [256]u8 = undefined;
    _ = try vfs.seek_file(handle_id, 0);
    const bytes_read = try vfs.read_file(handle_id, &read_buffer);

    // Assert: Content matches
    std.debug.assert(bytes_read == data.len);
    std.debug.assert(std.mem.eql(u8, read_buffer[0..bytes_read], data));
}

test "vfs write file readonly" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    const GrainBuffer = @import("grain_buffer").GrainBuffer;

    // Register virtual file with readonly ranges
    const text = "commit abc123\n";
    var buffer = try GrainBuffer.fromSlice(allocator, text);
    defer buffer.deinit();

    const readonly_ranges = [_]Vfs.ReadonlyRange{
        Vfs.ReadonlyRange{
            .start = 0,
            .end = 13, // "commit abc123"
            .type = .commit_hash,
        },
    };

    const path = ".jj/status.jj";
    _ = try vfs.register_virtual_file(path, buffer, &readonly_ranges);

    // Open file (should be readonly due to readonly ranges)
    const handle_id = try vfs.open_file(path, false);

    // Try to write (should fail)
    const data = "test\n";
    const write_result = vfs.write_file(handle_id, data);

    // Assert: Write failed (read-only)
    std.debug.assert(write_result == error.ReadOnlyFile);
}

test "vfs seek file" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    const GrainBuffer = @import("grain_buffer").GrainBuffer;

    // Register virtual file
    const text = "line 1\nline 2\nline 3\n";
    var buffer = try GrainBuffer.fromSlice(allocator, text);
    defer buffer.deinit();

    const path = ".jj/status.jj";
    _ = try vfs.register_virtual_file(path, buffer, null);

    // Open and seek file
    const handle_id = try vfs.open_file(path, false);
    const seek_success = vfs.seek_file(handle_id, 7); // Seek to "line 2"

    // Assert: Seek successful
    std.debug.assert(seek_success == true);

    // Read from new position
    var read_buffer: [256]u8 = undefined;
    const bytes_read = try vfs.read_file(handle_id, &read_buffer);

    // Assert: Read from correct position
    std.debug.assert(bytes_read > 0);
    std.debug.assert(std.mem.startsWith(u8, read_buffer[0..bytes_read], "line 2"));
}

test "vfs get file size" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    const GrainBuffer = @import("grain_buffer").GrainBuffer;

    // Register virtual file
    const text = "test content\n";
    var buffer = try GrainBuffer.fromSlice(allocator, text);
    defer buffer.deinit();

    const path = ".jj/status.jj";
    _ = try vfs.register_virtual_file(path, buffer, null);

    // Open and get file size
    const handle_id = try vfs.open_file(path, false);
    const file_size = vfs.get_file_size(handle_id);

    // Assert: File size correct
    std.debug.assert(file_size == text.len);
}

test "vfs close file" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    // Open file
    const path = "test.zig";
    const handle_id = try vfs.open_file(path, false);

    // Close file
    const closed = vfs.close_file(handle_id);

    // Assert: File closed successfully
    std.debug.assert(closed == true);

    // Try to read (should fail)
    var read_buffer: [256]u8 = undefined;
    const read_result = vfs.read_file(handle_id, &read_buffer);

    // Assert: Read failed (file closed)
    std.debug.assert(read_result == error.FileNotFound);
}

test "vfs multiple file handles" {
    var arena = std.heap.ArenaAllocator.init(testing.allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var vfs = Vfs.init(allocator);
    defer vfs.deinit();

    const GrainBuffer = @import("grain_buffer").GrainBuffer;

    // Register virtual file
    const text = "shared content\n";
    var buffer = try GrainBuffer.fromSlice(allocator, text);
    defer buffer.deinit();

    const path = ".jj/status.jj";
    _ = try vfs.register_virtual_file(path, buffer, null);

    // Open multiple handles
    const handle1 = try vfs.open_file(path, false);
    const handle2 = try vfs.open_file(path, false);

    // Assert: Multiple handles created
    std.debug.assert(handle1 != handle2);
    std.debug.assert(vfs.file_handles.items.len == 2);

    // Each handle has independent position
    _ = try vfs.write_file(handle1, "handle1\n");
    _ = try vfs.write_file(handle2, "handle2\n");

    // Assert: Both handles can write independently
    std.debug.assert(vfs.get_file_size(handle1) > 0);
    std.debug.assert(vfs.get_file_size(handle2) > 0);
}


