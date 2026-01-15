//! Grain Core File Transfer Routes: Route registration for file transfer endpoints.
//!
//! Why: Register HTTP file transfer routes with ApiServer.
//! Architecture: Route registration helpers for file upload/download endpoints.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.

const std = @import("std");
const api_server = @import("api_server.zig");
const file_transfer_handlers = @import("file_transfer_handlers.zig");

// Register file transfer routes with API server.
pub fn register_file_transfer_routes(
    server: *api_server.ApiServer,
    handlers: *file_transfer_handlers.FileTransferHandlers,
) bool {
    std.debug.assert(server != null);
    std.debug.assert(handlers != null);
    const upload_handler = struct {
        fn handle(req: *api_server.HttpRequest, res: *api_server.HttpResponse) void {
            handlers.handle_file_upload(req, res);
        }
    }.handle;
    const download_handler = struct {
        fn handle(req: *api_server.HttpRequest, res: *api_server.HttpResponse) void {
            handlers.handle_file_download(req, res);
        }
    }.handle;
    const progress_handler = struct {
        fn handle(req: *api_server.HttpRequest, res: *api_server.HttpResponse) void {
            handlers.handle_transfer_progress(req, res);
        }
    }.handle;
    if (!server.register_route(api_server.HttpMethod.post, "/api/files/upload", upload_handler)) {
        return false;
    }
    if (!server.register_route(api_server.HttpMethod.get, "/api/files/{file_id}/download", download_handler)) {
        return false;
    }
    if (!server.register_route(api_server.HttpMethod.get, "/api/files/{transfer_id}/progress", progress_handler)) {
        return false;
    }
    std.debug.assert(server.routes_len >= 3);
    return true;
}
