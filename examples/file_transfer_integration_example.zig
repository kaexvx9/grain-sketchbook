//! Example: File Transfer Integration with Network Agent
//!
//! Why: Demonstrate how to use Storage Agent file transfer APIs with Network Agent HTTP server.
//! Architecture: Example showing FileTransferHandlers initialization and usage.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const grain_core = @import("../src/grain_core/root.zig");
const api_server = grain_core.api_server;
const file_transfer_handlers = grain_core.file_transfer_handlers;
const file_transfer_routes = grain_core.file_transfer_routes;

// Example: Initialize file transfer handlers and register routes.
pub fn example_file_transfer_setup(
    allocator: std.mem.Allocator,
    server: *api_server.ApiServer,
) bool {
    std.debug.assert(allocator != null);
    std.debug.assert(server != null);
    var transfer_manager = grain_core.file_transfer.FileTransferManager.init();
    var mime_detector = grain_core.file_mime_type.FileMimeTypeDetector.init();
    var file_id_manager = grain_core.file_id_manager.FileIdManager.init(get_current_time);
    var storage_manager = grain_core.integrated_file_storage.IntegratedFileStorageManager.init(get_current_time);
    var file_io = grain_core.integrated_file_io.IntegratedFileIO.init(&storage_manager);
    const default_user_id: u32 = 1;
    const default_group_id: u32 = 1;
    var handlers = file_transfer_handlers.FileTransferHandlers.init(
        &transfer_manager,
        &mime_detector,
        &file_io,
        &file_id_manager,
        get_current_time,
        allocator,
        default_user_id,
        default_group_id,
    );
    const success = file_transfer_routes.register_file_transfer_routes(server, &handlers);
    std.debug.assert(success == true);
    return success;
}

// Helper: Get current time (mock implementation).
fn get_current_time() u64 {
    return @intCast(std.time.timestamp());
}
