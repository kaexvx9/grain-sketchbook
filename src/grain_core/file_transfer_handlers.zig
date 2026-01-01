//! Grain Core File Transfer Handlers: HTTP file transfer route handlers.
//!
//! Why: Integrate Storage Agent file transfer APIs with Network Agent HTTP server.
//! Architecture: HTTP route handlers for file upload/download with Storage Agent integration.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const api_server = @import("api_server.zig");
const file_transfer = @import("file_transfer.zig");
const file_mime_type = @import("file_mime_type.zig");
const chunked_transfer = @import("chunked_transfer.zig");
const integrated_file_io = @import("integrated_file_io.zig");
const file_id_manager = @import("file_id_manager.zig");

// Bounded: Max file ID length (UUID format).
pub const MAX_FILE_ID_LEN: u32 = 64;

// Bounded: Max JSON response size.
pub const MAX_JSON_RESPONSE_SIZE: u32 = 1024;

// File transfer handlers context.
pub const FileTransferHandlers = struct {
    transfer_manager: *file_transfer.FileTransferManager,
    mime_detector: *file_mime_type.FileMimeTypeDetector,
    file_io: *integrated_file_io.IntegratedFileIO,
    file_id_manager: *file_id_manager.FileIdManager,
    current_time_fn: *const fn () u64,
    allocator: std.mem.Allocator,
    default_user_id: u32,
    default_group_id: u32,

    pub fn init(
        transfer_manager: *file_transfer.FileTransferManager,
        mime_detector: *file_mime_type.FileMimeTypeDetector,
        file_io: *integrated_file_io.IntegratedFileIO,
        file_id_mgr: *file_id_manager.FileIdManager,
        current_time_fn: *const fn () u64,
        allocator: std.mem.Allocator,
        default_user_id: u32,
        default_group_id: u32,
    ) FileTransferHandlers {
        std.debug.assert(transfer_manager != null);
        std.debug.assert(mime_detector != null);
        std.debug.assert(file_io != null);
        std.debug.assert(file_id_mgr != null);
        std.debug.assert(@intFromPtr(current_time_fn) != 0);
        std.debug.assert(default_user_id > 0);
        std.debug.assert(default_group_id > 0);
        const handlers = FileTransferHandlers{
            .transfer_manager = transfer_manager,
            .mime_detector = mime_detector,
            .file_io = file_io,
            .file_id_manager = file_id_mgr,
            .current_time_fn = current_time_fn,
            .allocator = allocator,
            .default_user_id = default_user_id,
            .default_group_id = default_group_id,
        };
        std.debug.assert(handlers.transfer_manager != null);
        return handlers;
    }

    // Handle file upload: POST /api/files/upload
    pub fn handle_file_upload(
        self: *FileTransferHandlers,
        request: *api_server.HttpRequest,
        response: *api_server.HttpResponse,
    ) void {
        std.debug.assert(request != null);
        std.debug.assert(response != null);
        if (request.body_len == 0) {
            response.status = api_server.HttpStatus.bad_request;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "bad_request", "No file data provided");
            return;
        }
        const file_size = request.body_len;
        if (file_size > integrated_file_io.MAX_IO_BUFFER_SIZE) {
            response.status = api_server.HttpStatus.payload_too_large;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "payload_too_large", "File too large");
            return;
        }
        const current_time = self.current_time_fn();
        const local_path = self.extract_filename_from_request(request);
        const remote_url = self.build_remote_url(request);
        const transfer_id_opt = self.transfer_manager.create_upload(
            local_path,
            remote_url,
            file_size,
            current_time,
        );
        if (transfer_id_opt == null) {
            response.status = api_server.HttpStatus.service_unavailable;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "service_unavailable", "Transfer manager unavailable");
            return;
        }
        const transfer_id = transfer_id_opt.?;
        if (self.write_file_data(local_path, request.body[0..request.body_len])) {
            const file_id = self.file_id_manager.generate_file_id_string(local_path);
            if (!self.file_id_manager.store_mapping(file_id, local_path, file_size)) {
                _ = self.update_transfer_state(transfer_id, file_transfer.TransferState.failed);
                response.status = api_server.HttpStatus.service_unavailable;
                _ = response.add_header("Content-Type", "application/json");
                self.write_error_response(response, "service_unavailable", "File ID mapping storage full");
                return;
            }
            if (self.update_transfer_state(transfer_id, file_transfer.TransferState.completed)) {
                response.status = api_server.HttpStatus.created;
                _ = response.add_header("Content-Type", "application/json");
                self.write_upload_success_response(response, transfer_id, file_id, file_size, "completed");
            } else {
                response.status = api_server.HttpStatus.internal_server_error;
                _ = response.add_header("Content-Type", "application/json");
                self.write_error_response(response, "internal_server_error", "Failed to update transfer state");
            }
        } else {
            _ = self.update_transfer_state(transfer_id, file_transfer.TransferState.failed);
            response.status = api_server.HttpStatus.internal_server_error;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "internal_server_error", "Failed to write file");
        }
    }

    // Handle file download: GET /api/files/{file_id}/download
    pub fn handle_file_download(
        self: *FileTransferHandlers,
        request: *api_server.HttpRequest,
        response: *api_server.HttpResponse,
    ) void {
        std.debug.assert(request != null);
        std.debug.assert(response != null);
        const file_id = self.extract_file_id_from_path(request.path[0..request.path_len]);
        if (file_id.len == 0) {
            response.status = api_server.HttpStatus.bad_request;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "bad_request", "Missing file_id");
            return;
        }
        const local_path_opt = self.file_id_to_path(file_id);
        if (local_path_opt == null) {
            response.status = api_server.HttpStatus.not_found;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "not_found", "File not found");
            return;
        }
        const local_path = local_path_opt.?;
        const accept_header = request.get_header("Accept");
        const mime_type = self.mime_detector.negotiate_file_content_type(
            local_path,
            accept_header,
        );
        const current_time = self.current_time_fn();
        const file_size_opt = self.get_file_size(file_id);
        if (file_size_opt == null) {
            response.status = api_server.HttpStatus.not_found;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "not_found", "File not found");
            return;
        }
        const file_size = file_size_opt.?;
        const remote_url = self.build_remote_url(request);
        const transfer_id_opt = self.transfer_manager.create_download(
            remote_url,
            local_path,
            file_size,
            current_time,
        );
        if (transfer_id_opt == null) {
            response.status = api_server.HttpStatus.service_unavailable;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "service_unavailable", "Transfer manager unavailable");
            return;
        }
        const transfer_id = transfer_id_opt.?;
        if (self.read_and_stream_file(local_path, response, mime_type)) {
            _ = self.update_transfer_state(transfer_id, file_transfer.TransferState.completed);
            response.status = api_server.HttpStatus.ok;
        } else {
            _ = self.update_transfer_state(transfer_id, file_transfer.TransferState.failed);
            response.status = api_server.HttpStatus.internal_server_error;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "internal_server_error", "Failed to read file");
        }
    }

    // Handle transfer progress: GET /api/files/{transfer_id}/progress
    pub fn handle_transfer_progress(
        self: *FileTransferHandlers,
        request: *api_server.HttpRequest,
        response: *api_server.HttpResponse,
    ) void {
        std.debug.assert(request != null);
        std.debug.assert(response != null);
        const transfer_id_str = self.extract_transfer_id_from_path(request.path[0..request.path_len]);
        if (transfer_id_str.len == 0) {
            response.status = api_server.HttpStatus.bad_request;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "bad_request", "Missing transfer_id");
            return;
        }
        const transfer_id = self.parse_transfer_id(transfer_id_str);
        if (transfer_id == 0) {
            response.status = api_server.HttpStatus.bad_request;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "bad_request", "Invalid transfer_id");
            return;
        }
        if (self.transfer_manager.get_progress(transfer_id)) |progress| {
            response.status = api_server.HttpStatus.ok;
            _ = response.add_header("Content-Type", "application/json");
            self.write_progress_response(response, transfer_id, progress);
        } else {
            response.status = api_server.HttpStatus.not_found;
            _ = response.add_header("Content-Type", "application/json");
            self.write_error_response(response, "not_found", "Transfer not found");
        }
    }

    // Helper: Extract filename from request.
    fn extract_filename_from_request(
        self: *FileTransferHandlers,
        request: *api_server.HttpRequest,
    ) []const u8 {
        _ = self;
        std.debug.assert(request != null);
        if (request.get_header("X-Filename")) |filename| {
            return filename;
        }
        return "uploaded_file";
    }

    // Helper: Build remote URL from request.
    fn build_remote_url(
        self: *FileTransferHandlers,
        request: *api_server.HttpRequest,
    ) []const u8 {
        _ = self;
        std.debug.assert(request != null);
        const path = request.path[0..request.path_len];
        if (path.len > 0) {
            return path;
        }
        return "/api/files/upload";
    }

    // Helper: Extract file ID from path.
    fn extract_file_id_from_path(self: *FileTransferHandlers, path: []const u8) []const u8 {
        _ = self;
        std.debug.assert(path.len > 0);
        const prefix = "/api/files/";
        const suffix = "/download";
        if (path.len < prefix.len + suffix.len) {
            return "";
        }
        if (!std.mem.startsWith(u8, path, prefix)) {
            return "";
        }
        if (!std.mem.endsWith(u8, path, suffix)) {
            return "";
        }
        const start = prefix.len;
        const end = path.len - suffix.len;
        if (start >= end) {
            return "";
        }
        return path[start..end];
    }

    // Helper: Extract transfer ID from path.
    fn extract_transfer_id_from_path(
        self: *FileTransferHandlers,
        path: []const u8,
    ) []const u8 {
        _ = self;
        std.debug.assert(path.len > 0);
        const prefix = "/api/files/";
        const suffix = "/progress";
        if (path.len < prefix.len + suffix.len) {
            return "";
        }
        if (!std.mem.startsWith(u8, path, prefix)) {
            return "";
        }
        if (!std.mem.endsWith(u8, path, suffix)) {
            return "";
        }
        const start = prefix.len;
        const end = path.len - suffix.len;
        if (start >= end) {
            return "";
        }
        return path[start..end];
    }

    // Helper: Convert file ID to file path using FileIdManager.
    fn file_id_to_path(self: *FileTransferHandlers, file_id: []const u8) ?[]const u8 {
        std.debug.assert(file_id.len > 0);
        std.debug.assert(self != null);
        return self.file_id_manager.get_file_path(file_id);
    }

    // Helper: Get file size from FileIdManager or file path.
    fn get_file_size(self: *FileTransferHandlers, file_id: []const u8) ?u64 {
        std.debug.assert(file_id.len > 0);
        std.debug.assert(self != null);
        if (self.file_id_manager.get_file_size(file_id)) |size| {
            return size;
        }
        return null;
    }

    // Helper: Parse transfer ID from string.
    fn parse_transfer_id(self: *FileTransferHandlers, transfer_id_str: []const u8) u32 {
        _ = self;
        std.debug.assert(transfer_id_str.len > 0);
        var result: u32 = 0;
        var i: u32 = 0;
        while (i < transfer_id_str.len) : (i += 1) {
            if (transfer_id_str[i] < '0' or transfer_id_str[i] > '9') {
                return 0;
            }
            result = result * 10 + (transfer_id_str[i] - '0');
            if (result == 0) {
                return 0;
            }
        }
        return result;
    }

    // Helper: Update transfer state.
    fn update_transfer_state(
        self: *FileTransferHandlers,
        transfer_id: u32,
        state: file_transfer.TransferState,
    ) bool {
        std.debug.assert(transfer_id > 0);
        std.debug.assert(self != null);
        if (self.transfer_manager.get_transfer(transfer_id)) |transfer| {
            transfer.state = state;
            return true;
        }
        return false;
    }

    // Helper: Write file data using IntegratedFileIO.
    fn write_file_data(
        self: *FileTransferHandlers,
        file_path: []const u8,
        data: []const u8,
    ) bool {
        std.debug.assert(file_path.len > 0);
        std.debug.assert(data.len > 0);
        std.debug.assert(self != null);
        const current_time = self.current_time_fn();
        const user_id: u32 = 1;
        const group_id: u32 = 1;
        self.file_io.write_file(
            self.allocator,
            file_path,
            data,
            current_time,
            self.default_user_id,
            self.default_group_id,
        ) catch return false;
        return true;
    }

    // Helper: Read and stream file using IntegratedFileIO.
    fn read_and_stream_file(
        self: *FileTransferHandlers,
        file_path: []const u8,
        response: *api_server.HttpResponse,
        mime_type: []const u8,
    ) bool {
        std.debug.assert(file_path.len > 0);
        std.debug.assert(response != null);
        std.debug.assert(mime_type.len > 0);
        std.debug.assert(self != null);
        const current_time = self.current_time_fn();
        const user_id: u32 = 1;
        const group_id: u32 = 1;
        const file_data = self.file_io.read_file(
            self.allocator,
            file_path,
            current_time,
            self.default_user_id,
            self.default_group_id,
        ) catch return false;
        defer self.allocator.free(file_data);
        const content_len = @min(file_data.len, api_server.MAX_RESPONSE_SIZE);
        var i: u32 = 0;
        while (i < content_len) : (i += 1) {
            response.body[i] = file_data[i];
        }
        response.body_len = @intCast(content_len);
        _ = response.add_header("Content-Type", mime_type);
        var length_buf: [32]u8 = undefined;
        const length_str = std.fmt.bufPrint(&length_buf, "{}", .{content_len}) catch return false;
        _ = response.add_header("Content-Length", length_str[0..]);
        return true;
    }

    // Helper: Write error response JSON.
    fn write_error_response(
        self: *FileTransferHandlers,
        response: *api_server.HttpResponse,
        error_code: []const u8,
        message: []const u8,
    ) void {
        _ = self;
        std.debug.assert(response != null);
        std.debug.assert(error_code.len > 0);
        std.debug.assert(message.len > 0);
        var json_buf: [MAX_JSON_RESPONSE_SIZE]u8 = undefined;
        const json_str = std.fmt.bufPrint(
            &json_buf,
            "{{\"error\":\"{s}\",\"message\":\"{s}\"}}",
            .{ error_code, message },
        ) catch return;
        const json_len = @min(json_str.len, api_server.MAX_RESPONSE_SIZE);
        var i: u32 = 0;
        while (i < json_len) : (i += 1) {
            response.body[i] = json_str[i];
        }
        response.body_len = @intCast(json_len);
    }

    // Helper: Write upload success response JSON with file_id.
    fn write_upload_success_response(
        self: *FileTransferHandlers,
        response: *api_server.HttpResponse,
        transfer_id: u32,
        file_id: []const u8,
        file_size: u64,
        status: []const u8,
    ) void {
        _ = self;
        std.debug.assert(response != null);
        std.debug.assert(transfer_id > 0);
        std.debug.assert(file_id.len > 0);
        std.debug.assert(status.len > 0);
        var json_buf: [MAX_JSON_RESPONSE_SIZE]u8 = undefined;
        const file_id_escaped = self.escape_json_string(file_id);
        const json_str = std.fmt.bufPrint(
            &json_buf,
            "{{\"transfer_id\":{},\"file_id\":\"{s}\",\"file_size\":{},\"status\":\"{s}\"}}",
            .{ transfer_id, file_id_escaped, file_size, status },
        ) catch return;
        const json_len = @min(json_str.len, api_server.MAX_RESPONSE_SIZE);
        var i: u32 = 0;
        while (i < json_len) : (i += 1) {
            response.body[i] = json_str[i];
        }
        response.body_len = @intCast(json_len);
    }

    // Helper: Escape JSON string (simple implementation - returns input as-is for now).
    fn escape_json_string(self: *FileTransferHandlers, input: []const u8) []const u8 {
        _ = self;
        std.debug.assert(input.len > 0);
        return input;
    }

    // Helper: Write progress response JSON.
    fn write_progress_response(
        self: *FileTransferHandlers,
        response: *api_server.HttpResponse,
        transfer_id: u32,
        progress: file_transfer.TransferProgress,
    ) void {
        _ = self;
        std.debug.assert(response != null);
        std.debug.assert(transfer_id > 0);
        var json_buf: [MAX_JSON_RESPONSE_SIZE]u8 = undefined;
        const json_str = std.fmt.bufPrint(
            &json_buf,
            "{{\"transfer_id\":{},\"bytes_transferred\":{},\"total_bytes\":{},\"percentage\":{d:.2}}}",
            .{ transfer_id, progress.bytes_transferred, progress.total_bytes, progress.percentage },
        ) catch return;
        const json_len = @min(json_str.len, api_server.MAX_RESPONSE_SIZE);
        var i: u32 = 0;
        while (i < json_len) : (i += 1) {
            response.body[i] = json_str[i];
        }
        response.body_len = @intCast(json_len);
    }
};
