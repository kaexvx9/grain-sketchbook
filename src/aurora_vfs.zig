const std = @import("std");
const GrainBuffer = @import("grain_buffer.zig").GrainBuffer;

/// Virtual File System (VFS): File system abstraction for editor.
/// ~<~ Glow Airbend: explicit file handles, bounded file system state.
/// ~~~~ Glow Waterbend: deterministic file operations, iterative algorithms.
///
/// GrainStyle/TigerStyle compliance:
/// - grain_case function names
/// - u32/u64 types (not usize)
/// - MAX_ constants for bounded allocations
/// - Assertions for preconditions/postconditions
/// - No recursion (iterative algorithms, stack-based)
pub const Vfs = struct {
    // Bounded: Max virtual files (explicit limit)
    pub const MAX_VIRTUAL_FILES: u32 = 1000;

    // Bounded: Max file handles (explicit limit)
    pub const MAX_FILE_HANDLES: u32 = 256;

    // Bounded: Max file path length (explicit limit, in bytes)
    pub const MAX_PATH_LEN: u32 = 4096;

    // Bounded: Max file name length (explicit limit, in bytes)
    pub const MAX_NAME_LEN: u32 = 256;

    /// File type enumeration.
    pub const FileType = enum(u8) {
        regular, // Regular file (on disk or in-memory)
        virtual, // Virtual file (e.g., VCS status, diff)
        directory, // Directory
        symlink, // Symbolic link
    };

    /// File handle: represents an open file.
    pub const FileHandle = struct {
        handle_id: u32, // Unique handle ID
        file_type: FileType, // File type
        path: []const u8, // File path
        buffer: ?GrainBuffer = null, // File buffer (for virtual/in-memory files)
        readonly: bool = false, // Read-only flag
        position: u64 = 0, // Current read/write position
        active: bool = false, // Handle is active
    };

    /// Virtual file entry: represents a virtual file in the VFS.
    pub const VirtualFileEntry = struct {
        path: []const u8, // Virtual file path (e.g., ".jj/status.jj")
        buffer: GrainBuffer, // File buffer
        readonly_ranges: []const ReadonlyRange, // Read-only ranges (for VCS metadata)
        file_type: FileType = .virtual, // Always virtual
    };

    /// Read-only range: marks a range of text as read-only (for VCS metadata).
    pub const ReadonlyRange = struct {
        start: u32, // Start position (byte offset)
        end: u32, // End position (byte offset)
        type: ReadonlyType, // Type of read-only content
    };

    /// Read-only range type enumeration.
    pub const ReadonlyType = enum(u8) {
        commit_hash, // Git/JJ commit hash
        parent_info, // Parent commit information
        file_path, // File path in diff
        diff_header, // Diff header
        metadata, // General metadata
    };

    allocator: std.mem.Allocator,
    virtual_files: std.ArrayList(VirtualFileEntry),
    file_handles: std.ArrayList(FileHandle),
    next_handle_id: u32 = 1, // Start at 1 (0 is invalid)

    /// Why: Initialize VFS.
    /// Why: Create VFS with bounded allocations.
    /// Contract: allocator must be valid.
    /// Why: Initialize module state.
    pub fn init(allocator: std.mem.Allocator) Vfs {
        return Vfs{
            .allocator = allocator,
            .virtual_files = std.ArrayList(VirtualFileEntry).init(allocator),
            .file_handles = std.ArrayList(FileHandle).init(allocator),
        };
    }

    /// Why: Deinitialize VFS.
    /// Why: Free all allocated resources.
    /// Contract: VFS must be initialized.
    /// Why: Release resources.
    pub fn deinit(self: *Vfs) void {
        // Free all virtual file buffers and paths
        for (self.virtual_files.items) |*vf| {
            vf.buffer.deinit();
            self.allocator.free(vf.path);
            if (vf.readonly_ranges.len > 0) {
                self.allocator.free(vf.readonly_ranges);
            }
        }
        self.virtual_files.deinit();

        // Free all file handle paths
        for (self.file_handles.items) |*handle| {
            if (handle.active) {
                if (handle.buffer) |*buf| {
                    buf.deinit();
                }
                self.allocator.free(handle.path);
            }
        }
        self.file_handles.deinit();
    }

    /// Register virtual file.
    /// Why: Add virtual file to VFS (e.g., VCS status, diff).
    /// Contract: path must be valid, buffer must be valid, path length must be <= MAX_PATH_LEN.
    /// Returns: True if registered successfully, false if limit reached.
    pub fn register_virtual_file(
        self: *Vfs,
        path: []const u8,
        buffer: GrainBuffer,
        readonly_ranges: ?[]const ReadonlyRange,
    ) !bool {
        // Assert: Bounded virtual files
        std.debug.assert(self.virtual_files.items.len < MAX_VIRTUAL_FILES);
        std.debug.assert(path.len > 0);
        std.debug.assert(path.len <= MAX_PATH_LEN);

        // Check if virtual file already exists
        for (self.virtual_files.items) |*vf| {
            if (std.mem.eql(u8, vf.path, path)) {
                // Virtual file already exists, update it
                vf.buffer.deinit();
                if (vf.readonly_ranges.len > 0) {
                    self.allocator.free(vf.readonly_ranges);
                }
                vf.buffer = buffer;
                if (readonly_ranges) |ranges| {
                    const ranges_copy = try self.allocator.dupe(ReadonlyRange, ranges);
                    vf.readonly_ranges = ranges_copy;
                } else {
                    vf.readonly_ranges = &[_]ReadonlyRange{};
                }
                return true;
            }
        }

        // Create new virtual file entry
        const path_copy = try self.allocator.dupe(u8, path);
        errdefer self.allocator.free(path_copy);

        const readonly_ranges_copy = if (readonly_ranges) |ranges| blk: {
            const copy = try self.allocator.dupe(ReadonlyRange, ranges);
            break :blk copy;
        } else &[_]ReadonlyRange{};

        errdefer if (readonly_ranges_copy.len > 0) {
            self.allocator.free(readonly_ranges_copy);
        };

        const virtual_file = VirtualFileEntry{
            .path = path_copy,
            .buffer = buffer,
            .readonly_ranges = readonly_ranges_copy,
            .file_type = .virtual,
        };

        try self.virtual_files.append(virtual_file);

        // Assert: Virtual file added successfully
        std.debug.assert(self.virtual_files.items.len <= MAX_VIRTUAL_FILES);

        return true;
    }

    /// Get virtual file by path.
    /// Why: Retrieve virtual file from VFS.
    /// Contract: path must be valid.
    /// Returns: Virtual file entry if found, null otherwise.
    pub fn get_virtual_file(self: *Vfs, path: []const u8) ?*VirtualFileEntry {
        std.debug.assert(path.len > 0);
        std.debug.assert(path.len <= MAX_PATH_LEN);

        for (self.virtual_files.items) |*vf| {
            if (std.mem.eql(u8, vf.path, path)) {
                return vf;
            }
        }

        return null;
    }

    /// Open file handle.
    /// Why: Open file (regular or virtual) and return handle.
    /// Contract: path must be valid, path length must be <= MAX_PATH_LEN.
    /// Returns: File handle ID if successful, error otherwise.
    pub fn open_file(self: *Vfs, path: []const u8, readonly: bool) !u32 {
        // Assert: Bounded file handles
        std.debug.assert(self.file_handles.items.len < MAX_FILE_HANDLES);
        std.debug.assert(path.len > 0);
        std.debug.assert(path.len <= MAX_PATH_LEN);

        // Check if file is virtual
        if (self.get_virtual_file(path)) |vf| {
            // Open virtual file
            const path_copy = try self.allocator.dupe(u8, path);
            errdefer self.allocator.free(path_copy);

            // Clone buffer for handle (virtual files can have multiple handles)
            const buffer_copy = try vf.buffer.clone(self.allocator);
            errdefer buffer_copy.deinit();

            const handle_id = self.next_handle_id;
            self.next_handle_id += 1;

            const handle = FileHandle{
                .handle_id = handle_id,
                .file_type = .virtual,
                .path = path_copy,
                .buffer = buffer_copy,
                .readonly = readonly or (vf.readonly_ranges.len > 0), // Virtual files with readonly ranges are read-only
                .position = 0,
                .active = true,
            };

            try self.file_handles.append(handle);

            // Assert: File handle added successfully
            std.debug.assert(self.file_handles.items.len <= MAX_FILE_HANDLES);

            return handle_id;
        }

        // Regular file (not virtual) - for now, create in-memory file
        // TODO: Integrate with actual file system when available
        const path_copy = try self.allocator.dupe(u8, path);
        errdefer self.allocator.free(path_copy);

        // Create empty buffer for new file
        const buffer = try GrainBuffer.init(self.allocator);
        errdefer buffer.deinit();

        const handle_id = self.next_handle_id;
        self.next_handle_id += 1;

        const handle = FileHandle{
            .handle_id = handle_id,
            .file_type = .regular,
            .path = path_copy,
            .buffer = buffer,
            .readonly = readonly,
            .position = 0,
            .active = true,
        };

        try self.file_handles.append(handle);

        // Assert: File handle added successfully
        std.debug.assert(self.file_handles.items.len <= MAX_FILE_HANDLES);

        return handle_id;
    }

    /// Get file handle by ID.
    /// Why: Retrieve file handle from VFS.
    /// Contract: handle_id must be valid.
    /// Returns: File handle if found, null otherwise.
    pub fn get_file_handle(self: *Vfs, handle_id: u32) ?*FileHandle {
        for (self.file_handles.items) |*handle| {
            if (handle.handle_id == handle_id and handle.active) {
                return handle;
            }
        }

        return null;
    }

    /// Close file handle.
    /// Why: Close file handle and free resources.
    /// Contract: handle_id must be valid.
    /// Returns: True if closed successfully, false if handle not found.
    pub fn close_file(self: *Vfs, handle_id: u32) bool {
        if (self.get_file_handle(handle_id)) |handle| {
            if (handle.buffer) |*buf| {
                buf.deinit();
            }
            self.allocator.free(handle.path);
            handle.active = false;
            return true;
        }

        return false;
    }

    /// Read from file handle.
    /// Why: Read data from file at current position.
    /// Contract: handle_id must be valid, buffer must be large enough.
    /// Returns: Number of bytes read.
    pub fn read_file(self: *Vfs, handle_id: u32, buffer: []u8) !u32 {
        if (self.get_file_handle(handle_id)) |handle| {
            std.debug.assert(handle.buffer != null);
            const file_buffer = handle.buffer.?;

            // Read from buffer at current position
            const available = file_buffer.len() - @as(u32, @intCast(handle.position));
            const to_read = @min(available, @as(u32, @intCast(buffer.len)));

            if (to_read > 0) {
                const start_pos = @as(u32, @intCast(handle.position));
                const end_pos = start_pos + to_read;
                const slice = try file_buffer.slice(start_pos, end_pos);
                @memcpy(buffer[0..to_read], slice);
                handle.position += to_read;
            }

            return to_read;
        }

        return error.FileNotFound;
    }

    /// Write to file handle.
    /// Why: Write data to file at current position.
    /// Contract: handle_id must be valid, handle must not be read-only.
    /// Returns: Number of bytes written.
    pub fn write_file(self: *Vfs, handle_id: u32, data: []const u8) !u32 {
        if (self.get_file_handle(handle_id)) |handle| {
            if (handle.readonly) {
                return error.ReadOnlyFile;
            }

            std.debug.assert(handle.buffer != null);
            var file_buffer = handle.buffer.?;

            // Write to buffer at current position
            const position = @as(u32, @intCast(handle.position));
            try file_buffer.insert(position, data);
            handle.position += @as(u64, data.len);

            return @as(u32, @intCast(data.len));
        }

        return error.FileNotFound;
    }

    /// Seek file handle.
    /// Why: Set file position for read/write operations.
    /// Contract: handle_id must be valid, position must be within file bounds.
    /// Returns: True if seek successful, false otherwise.
    pub fn seek_file(self: *Vfs, handle_id: u32, position: u64) bool {
        if (self.get_file_handle(handle_id)) |handle| {
            std.debug.assert(handle.buffer != null);
            const file_buffer = handle.buffer.?;
            const file_len = @as(u64, file_buffer.len());

            if (position <= file_len) {
                handle.position = position;
                return true;
            }
        }

        return false;
    }

    /// Get file size.
    /// Why: Get size of file in bytes.
    /// Contract: handle_id must be valid.
    /// Returns: File size in bytes, or 0 if handle not found.
    pub fn get_file_size(self: *Vfs, handle_id: u32) u64 {
        if (self.get_file_handle(handle_id)) |handle| {
            std.debug.assert(handle.buffer != null);
            const file_buffer = handle.buffer.?;
            return @as(u64, file_buffer.len());
        }

        return 0;
    }
};


