//! Grain Core File Transfer Integration Helpers: Utilities for Network Agent integration.
//!
//! Why: Provide helper functions for Network Agent to integrate with Storage Agent file transfer.
//! Architecture: Utility functions for file transfer integration testing and setup.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const file_transfer = @import("file_transfer.zig");
const file_mime_type = @import("file_mime_type.zig");
const integrated_file_io = @import("integrated_file_io.zig");
const integrated_file_storage = @import("integrated_file_storage.zig");
const file_id_manager = @import("file_id_manager.zig");

// File transfer integration context.
pub const FileTransferIntegrationContext = struct {
    transfer_manager: file_transfer.FileTransferManager,
    mime_detector: file_mime_type.FileMimeTypeDetector,
    file_io: integrated_file_io.IntegratedFileIO,
    file_id_manager: file_id_manager.FileIdManager,
    storage_manager: integrated_file_storage.IntegratedFileStorageManager,
    current_time_fn: *const fn () u64,
    default_user_id: u32,
    default_group_id: u32,

    pub fn init(
        current_time_fn: *const fn () u64,
        default_user_id: u32,
        default_group_id: u32,
    ) FileTransferIntegrationContext {
        std.debug.assert(@intFromPtr(current_time_fn) != 0);
        std.debug.assert(default_user_id > 0);
        std.debug.assert(default_group_id > 0);
        var storage_mgr = integrated_file_storage.IntegratedFileStorageManager.init(current_time_fn);
        var io = integrated_file_io.IntegratedFileIO.init(&storage_mgr);
        var context = FileTransferIntegrationContext{
            .transfer_manager = file_transfer.FileTransferManager.init(),
            .mime_detector = file_mime_type.FileMimeTypeDetector.init(),
            .file_io = io,
            .file_id_manager = file_id_manager.FileIdManager.init(current_time_fn),
            .storage_manager = storage_mgr,
            .current_time_fn = current_time_fn,
            .default_user_id = default_user_id,
            .default_group_id = default_group_id,
        };
        std.debug.assert(context.default_user_id > 0);
        std.debug.assert(context.default_group_id > 0);
        return context;
    }

    // Get file ID for a file path (generate if not exists).
    pub fn get_or_generate_file_id(
        self: *FileTransferIntegrationContext,
        file_path: []const u8,
        file_size: u64,
    ) ?[]const u8 {
        std.debug.assert(file_path.len > 0);
        std.debug.assert(self != null);
        const file_id = self.file_id_manager.generate_file_id_string(file_path);
        if (self.file_id_manager.get_file_path(file_id) == null) {
            if (!self.file_id_manager.store_mapping(file_id, file_path, file_size)) {
                return null;
            }
        }
        return file_id;
    }

    // Verify file ID mapping exists.
    pub fn verify_file_id_mapping(
        self: *const FileTransferIntegrationContext,
        file_id: []const u8,
        expected_path: []const u8,
    ) bool {
        std.debug.assert(file_id.len > 0);
        std.debug.assert(expected_path.len > 0);
        std.debug.assert(self != null);
        if (self.file_id_manager.get_file_path(file_id)) |path| {
            return std.mem.eql(u8, path, expected_path);
        }
        return false;
    }
};
