//! Grain Core File Transfer: File upload and download.
//!
//! Why: Provide file upload/download functionality with Network Agent
//! integration.
//! Architecture: High-level API for file transfer, progress tracking, resume
//! support.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70
//! lines.

const std = @import("std");
const file_storage = @import("file_storage.zig");
const path_resolver = @import("path_resolver.zig");

// Bounded: Max concurrent transfers.
pub const MAX_CONCURRENT_TRANSFERS: u32 = 8;

// Bounded: Max transfer URL length.
pub const MAX_TRANSFER_URL_LEN: u32 = 2048;

// Bounded: Max chunk size for transfer (1MB).
pub const MAX_CHUNK_SIZE: u32 = 1024 * 1024;

// Transfer state.
pub const TransferState = enum(u8) {
    pending,
    in_progress,
    paused,
    completed,
    failed,
    cancelled,
};

// Transfer direction.
pub const TransferDirection = enum(u8) {
    upload,
    download,
};

// Transfer progress.
pub const TransferProgress = struct {
    bytes_transferred: u64,
    total_bytes: u64,
    percentage: f32,
    transfer_rate: u64, // bytes per second

    pub fn init() TransferProgress {
        return TransferProgress{
            .bytes_transferred = 0,
            .total_bytes = 0,
            .percentage = 0.0,
            .transfer_rate = 0,
        };
    }

    pub fn calculate_percentage(self: *TransferProgress) void {
        std.debug.assert(self != null);
        if (self.total_bytes > 0) {
            self.percentage = @as(f32, @floatFromInt(self.bytes_transferred)) /
                @as(f32, @floatFromInt(self.total_bytes)) * 100.0;
        } else {
            self.percentage = 0.0;
        }
    }
};

// File transfer.
pub const FileTransfer = struct {
    transfer_id: u32,
    direction: TransferDirection,
    local_path: [file_storage.MAX_FILENAME_LEN]u8,
    local_path_len: u32,
    remote_url: [MAX_TRANSFER_URL_LEN]u8,
    remote_url_len: u32,
    state: TransferState,
    progress: TransferProgress,
    file_size: u64,
    created_at: u64,
    started_at: u64,
    completed_at: u64,
    error_code: u32,
    active: bool,

    pub fn init() FileTransfer {
        var transfer = FileTransfer{
            .transfer_id = 0,
            .direction = TransferDirection.upload,
            .local_path = undefined,
            .local_path_len = 0,
            .remote_url = undefined,
            .remote_url_len = 0,
            .state = TransferState.pending,
            .progress = TransferProgress.init(),
            .file_size = 0,
            .created_at = 0,
            .started_at = 0,
            .completed_at = 0,
            .error_code = 0,
            .active = false,
        };
        var i: u32 = 0;
        while (i < file_storage.MAX_FILENAME_LEN) : (i += 1) {
            transfer.local_path[i] = 0;
        }
        i = 0;
        while (i < MAX_TRANSFER_URL_LEN) : (i += 1) {
            transfer.remote_url[i] = 0;
        }
        return transfer;
    }

    pub fn set_local_path(self: *FileTransfer, path: []const u8) bool {
        std.debug.assert(path.len > 0);
        std.debug.assert(path.len <= file_storage.MAX_FILENAME_LEN);
        if (path.len == 0 or path.len > file_storage.MAX_FILENAME_LEN) {
            return false;
        }
        var i: u32 = 0;
        while (i < file_storage.MAX_FILENAME_LEN) : (i += 1) {
            self.local_path[i] = 0;
        }
        const path_len = @min(path.len, file_storage.MAX_FILENAME_LEN);
        i = 0;
        while (i < path_len) : (i += 1) {
            self.local_path[i] = path[i];
        }
        self.local_path_len = path_len;
        return true;
    }

    pub fn set_remote_url(self: *FileTransfer, url: []const u8) bool {
        std.debug.assert(url.len > 0);
        std.debug.assert(url.len <= MAX_TRANSFER_URL_LEN);
        if (url.len == 0 or url.len > MAX_TRANSFER_URL_LEN) {
            return false;
        }
        var i: u32 = 0;
        while (i < MAX_TRANSFER_URL_LEN) : (i += 1) {
            self.remote_url[i] = 0;
        }
        const url_len = @min(url.len, MAX_TRANSFER_URL_LEN);
        i = 0;
        while (i < url_len) : (i += 1) {
            self.remote_url[i] = url[i];
        }
        self.remote_url_len = url_len;
        return true;
    }

    pub fn update_progress(
        self: *FileTransfer,
        bytes_transferred: u64,
        current_time: u64,
    ) void {
        std.debug.assert(self != null);
        std.debug.assert(bytes_transferred <= self.file_size);
        self.progress.bytes_transferred = bytes_transferred;
        self.progress.total_bytes = self.file_size;
        self.progress.calculate_percentage();
        if (self.started_at > 0) {
            const elapsed: u64 = current_time - self.started_at;
            if (elapsed > 0) {
                self.progress.transfer_rate = bytes_transferred / elapsed;
            }
        }
        std.debug.assert(self.progress.percentage >= 0.0);
        std.debug.assert(self.progress.percentage <= 100.0);
    }
};

// File transfer manager.
pub const FileTransferManager = struct {
    transfers: [MAX_CONCURRENT_TRANSFERS]FileTransfer,
    transfers_len: u32,
    next_transfer_id: u32,

    pub fn init() FileTransferManager {
        var manager = FileTransferManager{
            .transfers = undefined,
            .transfers_len = 0,
            .next_transfer_id = 1,
        };
        var i: u32 = 0;
        while (i < MAX_CONCURRENT_TRANSFERS) : (i += 1) {
            manager.transfers[i] = FileTransfer.init();
        }
        return manager;
    }

    pub fn create_upload(
        self: *FileTransferManager,
        local_path: []const u8,
        remote_url: []const u8,
        file_size: u64,
        current_time: u64,
    ) ?u32 {
        std.debug.assert(local_path.len > 0);
        std.debug.assert(remote_url.len > 0);
        std.debug.assert(self != null);
        if (self.transfers_len >= MAX_CONCURRENT_TRANSFERS) {
            return null;
        }
        const transfer_id = self.next_transfer_id;
        self.next_transfer_id += 1;
        self.transfers[self.transfers_len] = FileTransfer.init();
        self.transfers[self.transfers_len].transfer_id = transfer_id;
        self.transfers[self.transfers_len].direction = TransferDirection.upload;
        _ = self.transfers[self.transfers_len].set_local_path(local_path);
        _ = self.transfers[self.transfers_len].set_remote_url(remote_url);
        self.transfers[self.transfers_len].file_size = file_size;
        self.transfers[self.transfers_len].created_at = current_time;
        self.transfers[self.transfers_len].state = TransferState.pending;
        self.transfers[self.transfers_len].active = true;
        self.transfers_len += 1;
        std.debug.assert(self.transfers_len <= MAX_CONCURRENT_TRANSFERS);
        return transfer_id;
    }

    pub fn create_download(
        self: *FileTransferManager,
        remote_url: []const u8,
        local_path: []const u8,
        file_size: u64,
        current_time: u64,
    ) ?u32 {
        std.debug.assert(remote_url.len > 0);
        std.debug.assert(local_path.len > 0);
        std.debug.assert(self != null);
        if (self.transfers_len >= MAX_CONCURRENT_TRANSFERS) {
            return null;
        }
        const transfer_id = self.next_transfer_id;
        self.next_transfer_id += 1;
        self.transfers[self.transfers_len] = FileTransfer.init();
        self.transfers[self.transfers_len].transfer_id = transfer_id;
        self.transfers[self.transfers_len].direction = TransferDirection.download;
        _ = self.transfers[self.transfers_len].set_local_path(local_path);
        _ = self.transfers[self.transfers_len].set_remote_url(remote_url);
        self.transfers[self.transfers_len].file_size = file_size;
        self.transfers[self.transfers_len].created_at = current_time;
        self.transfers[self.transfers_len].state = TransferState.pending;
        self.transfers[self.transfers_len].active = true;
        self.transfers_len += 1;
        std.debug.assert(self.transfers_len <= MAX_CONCURRENT_TRANSFERS);
        return transfer_id;
    }

    pub fn get_transfer(
        self: *FileTransferManager,
        transfer_id: u32,
    ) ?*FileTransfer {
        std.debug.assert(transfer_id > 0);
        std.debug.assert(self != null);
        var i: u32 = 0;
        while (i < self.transfers_len) : (i += 1) {
            if (self.transfers[i].transfer_id == transfer_id and
                self.transfers[i].active)
            {
                return &self.transfers[i];
            }
        }
        return null;
    }

    pub fn pause_transfer(
        self: *FileTransferManager,
        transfer_id: u32,
    ) bool {
        std.debug.assert(transfer_id > 0);
        std.debug.assert(self != null);
        if (self.get_transfer(transfer_id)) |transfer| {
            if (transfer.state == TransferState.in_progress) {
                transfer.state = TransferState.paused;
                return true;
            }
        }
        return false;
    }

    pub fn resume_transfer(
        self: *FileTransferManager,
        transfer_id: u32,
    ) bool {
        std.debug.assert(transfer_id > 0);
        std.debug.assert(self != null);
        if (self.get_transfer(transfer_id)) |transfer| {
            if (transfer.state == TransferState.paused) {
                transfer.state = TransferState.in_progress;
                return true;
            }
        }
        return false;
    }

    pub fn cancel_transfer(
        self: *FileTransferManager,
        transfer_id: u32,
    ) bool {
        std.debug.assert(transfer_id > 0);
        std.debug.assert(self != null);
        if (self.get_transfer(transfer_id)) |transfer| {
            transfer.state = TransferState.cancelled;
            transfer.active = false;
            return true;
        }
        return false;
    }

    pub fn get_progress(
        self: *FileTransferManager,
        transfer_id: u32,
    ) ?TransferProgress {
        std.debug.assert(transfer_id > 0);
        std.debug.assert(self != null);
        if (self.get_transfer(transfer_id)) |transfer| {
            return transfer.progress;
        }
        return null;
    }
};
