//! Example: File ID Manager Usage
//!
//! Why: Demonstrate how to use FileIdManager for file ID generation and mapping.
//! Architecture: Example showing file ID generation, storage, and lookup.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const file_id_manager = @import("../src/grain_core/file_id_manager.zig");

// Example: Generate file ID and store mapping.
pub fn example_file_id_usage() void {
    var manager = file_id_manager.FileIdManager.init(get_current_time);
    const file_path = "/tmp/example_file.txt";
    const file_size: u64 = 1024;
    const file_id = manager.generate_file_id_string(file_path);
    std.debug.assert(file_id.len > 0);
    const stored = manager.store_mapping(file_id, file_path, file_size);
    std.debug.assert(stored == true);
    const retrieved_path = manager.get_file_path(file_id);
    std.debug.assert(retrieved_path != null);
    if (retrieved_path) |path| {
        std.debug.assert(std.mem.eql(u8, path, file_path));
    }
    const retrieved_size = manager.get_file_size(file_id);
    std.debug.assert(retrieved_size != null);
    if (retrieved_size) |size| {
        std.debug.assert(size == file_size);
    }
}

// Helper: Get current time (mock implementation).
fn get_current_time() u64 {
    return @intCast(std.time.timestamp());
}
