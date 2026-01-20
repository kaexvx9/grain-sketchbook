//! Basin Kernel File Syscalls
//! Why: File system syscalls (open, read, write, close, unlink, rename, mkdir, opendir, readdir, closedir).
//! Grain Style: Explicit types, static allocation, comprehensive assertions.

const std = @import("std");
const Debug = @import("debug.zig");

// Import types
const types = @import("basin_kernel_types.zig");
const BasinError = types.BasinError;
const SyscallResult = types.SyscallResult;
const OpenFlags = types.OpenFlags;
const DirectoryHandle = types.DirectoryHandle;
const MAX_PROCESSES = types.MAX_PROCESSES;
const MAX_HANDLES = types.MAX_HANDLES;
const MAX_DIR_HANDLES = types.MAX_DIR_HANDLES;

// Import core
const core = @import("basin_kernel_core.zig");
const BasinKernel = core.BasinKernel;
const can_open_file_descriptor = core.can_open_file_descriptor;

/// File syscall handlers for BasinKernel.
/// Why: Extract file system syscalls to separate module for organization.
pub const FileSyscalls = struct {
    const VM_MEMORY_SIZE: u64 = 4 * 1024 * 1024;

    /// Validate path arguments for file syscalls.
    /// Why: Common validation for open, read, write syscalls.
    fn validate_path_args(path_ptr: u64, path_len: u64) ?BasinError {
        if (path_ptr == 0) return BasinError.invalid_argument;
        if (path_ptr >= VM_MEMORY_SIZE) return BasinError.invalid_argument;
        if (path_len == 0 or path_len > 4096) return BasinError.invalid_argument;
        if (path_ptr + path_len > VM_MEMORY_SIZE) return BasinError.invalid_argument;
        if (path_len > 255) return BasinError.invalid_argument;
        return null;
    }

    /// Validate and decode open flags.
    /// Why: Check flags have valid permissions and no reserved bits.
    fn validate_open_flags(flags: u64) ?OpenFlags {
        const open_flags = @as(OpenFlags, @bitCast(@as(u32, @truncate(flags))));
        if (open_flags._padding != 0) return null;
        if (!open_flags.read and !open_flags.write) return null;
        return open_flags;
    }

    /// Allocate and initialize a file handle.
    /// Why: Common handle setup for open syscall.
    fn allocate_handle(
        self: *BasinKernel,
        handle_idx: usize,
        path_len: u64,
        open_flags: OpenFlags,
        owner_process_id: u32,
    ) u32 {
        var file_handle = &self.handles[handle_idx];
        const handle_id = self.next_handle_id;
        self.next_handle_id += 1;
        Debug.kassert(handle_id != 0, "Handle ID is 0", .{});

        file_handle.id = handle_id;
        file_handle.path_len = @as(u32, @intCast(path_len));
        file_handle.flags = open_flags;
        file_handle.position = 0;
        file_handle.buffer_size = 0;
        file_handle.allocated = true;
        file_handle.owner_process_id = owner_process_id;

        self.update_handle_hash_table(handle_id, handle_idx);
        if (open_flags.truncate) file_handle.buffer_size = 0;
        return handle_id;
    }

    /// Why: Open a file, return handle ID.
    pub fn syscall_open(
        self: *BasinKernel,
        path_ptr: u64,
        path_len: u64,
        flags: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg4;
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});

        if (validate_path_args(path_ptr, path_len)) |err| return SyscallResult.fail(err);

        const open_flags = validate_open_flags(flags) orelse {
            return SyscallResult.fail(BasinError.invalid_argument);
        };

        const handle_idx = self.find_free_handle() orelse {
            return SyscallResult.fail(BasinError.out_of_memory);
        };

        const current_process_idx = self.find_current_process_index();
        const owner_pid = if (current_process_idx) |i| @as(u32, @truncate(self.processes[i].id)) else 0;

        if (current_process_idx) |idx| {
            if (!self.can_open_file_descriptor(&self.processes[idx])) {
                return SyscallResult.fail(BasinError.resource_exhausted);
            }
        }

        const handle_id = allocate_handle(self, handle_idx, path_len, open_flags, owner_pid);

        if (current_process_idx) |idx| self.processes[idx].open_file_descriptors += 1;

        Debug.kassert(self.handles[handle_idx].allocated, "Handle not allocated", .{});
        return SyscallResult.ok(handle_id);
    }
    
    /// Validate file buffer arguments.
    fn validate_file_buffer(handle: u64, ptr: u64, len: u64) ?SyscallResult {
        if (handle == 0) return SyscallResult.fail(BasinError.invalid_argument);
        if (ptr == 0 or ptr >= VM_MEMORY_SIZE) return SyscallResult.fail(BasinError.invalid_argument);
        if (len == 0 or len > 1024 * 1024) return SyscallResult.fail(BasinError.invalid_argument);
        if (ptr + len > VM_MEMORY_SIZE) return SyscallResult.fail(BasinError.invalid_argument);
        return null;
    }

    /// Why: Read data from an open file handle into a buffer.
    pub fn syscall_read(
        self: *BasinKernel,
        handle: u64,
        buffer_ptr: u64,
        buffer_len: u64,
        timeout_ns: u64,
    ) BasinError!SyscallResult {
        if (validate_file_buffer(handle, buffer_ptr, buffer_len)) |err| return err;

        const start_ns = self.timer.get_monotonic_ns();
        const idx = self.find_handle_by_id(handle) orelse {
            return SyscallResult.fail(BasinError.invalid_handle);
        };

        var fh = &self.handles[idx];
        if (!fh.flags.read) return SyscallResult.fail(BasinError.permission_denied);
        if (self.check_timeout(start_ns, timeout_ns)) {
            return SyscallResult.fail(BasinError.file_io_timeout);
        }

        const avail = if (fh.position < fh.buffer_size) fh.buffer_size - fh.position else 0;
        const to_read = @min(avail, @as(u32, @intCast(buffer_len)));
        fh.position += to_read;

        if (self.check_timeout(start_ns, timeout_ns)) {
            return SyscallResult.fail(BasinError.file_io_timeout);
        }

        return SyscallResult.ok(@as(u64, to_read));
    }

    /// Why: Write data from a buffer to an open file handle.
    pub fn syscall_write(
        self: *BasinKernel,
        handle: u64,
        data_ptr: u64,
        data_len: u64,
        timeout_ns: u64,
    ) BasinError!SyscallResult {
        if (validate_file_buffer(handle, data_ptr, data_len)) |err| return err;

        const start_ns = self.timer.get_monotonic_ns();
        const idx = self.find_handle_by_id(handle) orelse {
            return SyscallResult.fail(BasinError.invalid_handle);
        };

        var fh = &self.handles[idx];
        if (!fh.flags.write) return SyscallResult.fail(BasinError.permission_denied);
        if (self.check_timeout(start_ns, timeout_ns)) {
            return SyscallResult.fail(BasinError.file_io_timeout);
        }

        const max_buf = fh.buffer.len;
        const avail = if (fh.position < max_buf) @as(u32, @intCast(max_buf - fh.position)) else 0;
        const to_write = @min(@as(u32, @intCast(data_len)), avail);

        fh.position += to_write;
        if (fh.position > fh.buffer_size) fh.buffer_size = @as(u32, @intCast(fh.position));

        if (self.check_timeout(start_ns, timeout_ns)) {
            return SyscallResult.fail(BasinError.file_io_timeout);
        }

        return SyscallResult.ok(@as(u64, to_write));
    }

    /// Deallocate a handle and update process resources.
    /// Why: Common cleanup logic for syscall_close.
    fn deallocate_handle(self: *BasinKernel, handle_idx: usize) void {
        var file_handle = &self.handles[handle_idx];
        const owner_pid = file_handle.owner_process_id;
        const closed_id = file_handle.id;

        self.invalidate_handle_hash_table(closed_id);
        file_handle.allocated = false;
        file_handle.id = 0;
        file_handle.path_len = 0;
        file_handle.position = 0;
        file_handle.buffer_size = 0;
        file_handle.owner_process_id = 0;

        if (self.mru_handle_id == closed_id) self.invalidate_mru_handle_cache();

        if (owner_pid > 0) {
            for (0..MAX_PROCESSES) |i| {
                if (self.processes[i].allocated and self.processes[i].id == owner_pid) {
                    if (self.processes[i].open_file_descriptors > 0) {
                        self.processes[i].open_file_descriptors -= 1;
                    }
                    break;
                }
            }
        }
    }

    /// Why: Close an open file handle and release resources.
    pub fn syscall_close(
        self: *BasinKernel,
        handle: u64,
        _arg2: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        _ = _arg2;
        _ = _arg3;
        _ = _arg4;

        if (handle == 0) return SyscallResult.fail(BasinError.invalid_argument);

        const handle_idx = self.find_handle_by_id(handle) orelse {
            return SyscallResult.fail(BasinError.invalid_handle);
        };

        Debug.kassert(self.handles[handle_idx].allocated, "Handle not allocated", .{});
        deallocate_handle(self, handle_idx);
        Debug.kassert(!self.handles[handle_idx].allocated, "Handle still allocated", .{});

        return SyscallResult.ok(0);
    }

    /// Why: Delete a file from the filesystem.
    pub fn syscall_unlink(
        self: *BasinKernel,
        path_ptr: u64,
        path_len: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg3;
        _ = _arg4;
        
        // Assert: path pointer must be valid (non-zero, within VM memory).
        if (path_ptr == 0) {
            return SyscallResult.fail(BasinError.invalid_argument); // Null pointer
        }
        
        if (path_ptr >= VM_MEMORY_SIZE) {
            return SyscallResult.fail(BasinError.invalid_argument); // Path pointer exceeds VM memory
        }
        
        // Assert: path length must be reasonable (max 4096 bytes).
        if (path_len == 0) {
            return SyscallResult.fail(BasinError.invalid_argument); // Empty path
        }
        if (path_len > 4096) {
            return SyscallResult.fail(BasinError.invalid_argument); // Path too long
        }
        
        // Assert: path must fit within VM memory.
        if (path_ptr + path_len > VM_MEMORY_SIZE) {
            return SyscallResult.fail(BasinError.invalid_argument); // Path exceeds VM memory
        }
        
        // Find handle by path and remove it (simulated file deletion).
        // For now, search for handle with matching path and mark as deleted.
        var found: bool = false;
        for (0..MAX_HANDLES) |i| {
            if (self.handles[i].allocated and self.handles[i].path_len == @as(u32, @intCast(path_len))) {
                // In real implementation, would compare path strings.
                // For now, just mark as deleted if path length matches.
                self.handles[i].allocated = false;
                self.handles[i].id = 0;
                found = true;
                break;
            }
        }
        
        if (!found) {
            return SyscallResult.fail(BasinError.not_found); // File not found
        }
        
        const result = SyscallResult.ok(0);
        return result;
    }

    /// Why: Rename or move a file in the filesystem.
    pub fn syscall_rename(
        self: *BasinKernel,
        old_path_ptr: u64,
        old_path_len: u64,
        new_path_ptr: u64,
        new_path_len: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        // Assert: old path pointer must be valid (non-zero, within VM memory).
        if (old_path_ptr == 0) {
            return SyscallResult.fail(BasinError.invalid_argument); // Null pointer
        }
        
        if (old_path_ptr >= VM_MEMORY_SIZE) {
            return SyscallResult.fail(BasinError.invalid_argument); // Old path pointer exceeds VM memory
        }
        
        // Assert: new path pointer must be valid (non-zero, within VM memory).
        if (new_path_ptr == 0) {
            return SyscallResult.fail(BasinError.invalid_argument); // Null pointer
        }
        if (new_path_ptr >= VM_MEMORY_SIZE) {
            return SyscallResult.fail(BasinError.invalid_argument); // New path pointer exceeds VM memory
        }
        
        // Assert: path lengths must be reasonable (max 4096 bytes).
        if (old_path_len == 0 or old_path_len > 4096) {
            return SyscallResult.fail(BasinError.invalid_argument); // Invalid old path length
        }
        if (new_path_len == 0 or new_path_len > 4096) {
            return SyscallResult.fail(BasinError.invalid_argument); // Invalid new path length
        }
        
        // Assert: paths must fit within VM memory.
        if (old_path_ptr + old_path_len > VM_MEMORY_SIZE) {
            return SyscallResult.fail(BasinError.invalid_argument); // Old path exceeds VM memory
        }
        if (new_path_ptr + new_path_len > VM_MEMORY_SIZE) {
            return SyscallResult.fail(BasinError.invalid_argument); // New path exceeds VM memory
        }
        
        // Find handle by old path and update to new path (simulated rename).
        // For now, search for handle with matching path length and update.
        var found: bool = false;
        for (0..MAX_HANDLES) |i| {
            if (self.handles[i].allocated and self.handles[i].path_len == @as(u32, @intCast(old_path_len))) {
                // In real implementation, would compare path strings and update.
                // For now, just update path length if it matches.
                self.handles[i].path_len = @as(u32, @intCast(new_path_len));
                found = true;
                break;
            }
        }
        
        if (!found) {
            return SyscallResult.fail(BasinError.not_found); // File not found
        }
        
        const result = SyscallResult.ok(0);
        return result;
    }

    /// Why: Create a new directory in the filesystem.
    pub fn syscall_mkdir(
        self: *BasinKernel,
        path_ptr: u64,
        path_len: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg3;
        _ = _arg4;
        
        // Assert: path pointer must be valid (non-zero, within VM memory).
        if (path_ptr == 0) {
            return SyscallResult.fail(BasinError.invalid_argument); // Null pointer
        }
        
        if (path_ptr >= VM_MEMORY_SIZE) {
            return SyscallResult.fail(BasinError.invalid_argument); // Path pointer exceeds VM memory
        }
        
        // Assert: path length must be reasonable (max 4096 bytes).
        if (path_len == 0) {
            return SyscallResult.fail(BasinError.invalid_argument); // Empty path
        }
        if (path_len > 4096) {
            return SyscallResult.fail(BasinError.invalid_argument); // Path too long
        }
        
        // Assert: path must fit within VM memory.
        if (path_ptr + path_len > VM_MEMORY_SIZE) {
            return SyscallResult.fail(BasinError.invalid_argument); // Path exceeds VM memory
        }
        
        // Check if directory already exists (simulated).
        // For now, just check if handle with same path exists.
        for (0..MAX_HANDLES) |i| {
            if (self.handles[i].allocated and self.handles[i].path_len == @as(u32, @intCast(path_len))) {
                // In real implementation, would compare path strings.
                // For now, return error if path length matches (directory exists).
                return SyscallResult.fail(BasinError.invalid_argument); // Directory already exists
            }
        }
        
        // Create directory (simulated - in real implementation, would create directory entry).
        // For now, just return success (directory created).
        const result = SyscallResult.ok(0);
        return result;
    }

    /// Why: Open a directory for reading entries.
    pub fn syscall_opendir(
        self: *BasinKernel,
        path_ptr: u64,
        path_len: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg3;
        _ = _arg4;
        
        // Assert: path pointer must be valid (non-zero, within VM memory).
        if (path_ptr == 0) {
            return SyscallResult.fail(BasinError.invalid_argument);
        }
        
        if (path_ptr >= VM_MEMORY_SIZE) {
            return SyscallResult.fail(BasinError.invalid_argument);
        }
        
        // Assert: path length must be reasonable (max 256 bytes).
        if (path_len == 0 or path_len > 256) {
            return SyscallResult.fail(BasinError.invalid_argument);
        }
        
        // Find free directory handle slot.
        var slot: ?usize = null;
        for (0..MAX_DIR_HANDLES) |i| {
            if (!self.dir_handles[i].allocated) {
                slot = i;
                break;
            }
        }
        
        if (slot == null) {
            return SyscallResult.fail(BasinError.out_of_memory);
        }
        
        const idx = slot.?;
        
        // Allocate directory handle.
        const handle_id = self.next_dir_handle_id;
        self.next_dir_handle_id += 1;
        
        // Copy path (simulated - in real implementation, would read from VM memory).
        self.dir_handles[idx].id = handle_id;
        self.dir_handles[idx].path_len = @as(u32, @intCast(path_len));
        self.dir_handles[idx].position = 0;
        self.dir_handles[idx].allocated = true;
        
        // Return directory handle ID.
        const result = SyscallResult.ok(handle_id);
        return result;
    }

    /// Why: Read the next entry from an open directory.
    pub fn syscall_readdir(
        self: *BasinKernel,
        dir_handle: u64,
        entry_ptr: u64,
        entry_len: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg4;
        
        // Assert: directory handle must be valid (non-zero).
        if (dir_handle == 0) {
            return SyscallResult.fail(BasinError.invalid_argument);
        }
        
        // Assert: entry pointer must be valid (non-zero, within VM memory).
        if (entry_ptr == 0) {
            return SyscallResult.fail(BasinError.invalid_argument);
        }
        
        if (entry_ptr >= VM_MEMORY_SIZE) {
            return SyscallResult.fail(BasinError.invalid_argument);
        }
        
        // Assert: entry length must be reasonable (max 256 bytes).
        if (entry_len == 0 or entry_len > 256) {
            return SyscallResult.fail(BasinError.invalid_argument);
        }
        
        // Find directory handle.
        var found: ?usize = null;
        for (0..MAX_DIR_HANDLES) |i| {
            if (self.dir_handles[i].allocated and self.dir_handles[i].id == dir_handle) {
                found = i;
                break;
            }
        }
        
        if (found == null) {
            return SyscallResult.fail(BasinError.invalid_argument);
        }
        
        const idx = found.?;
        
        // Simulated directory reading: return empty (end of directory).
        // In real implementation, would read directory entries from file system.
        // For now, return 0 (no more entries) after first read.
        if (self.dir_handles[idx].position > 0) {
            return SyscallResult.ok(0); // End of directory
        }
        
        // First read: return stub entry name "."
        // In real implementation, would write entry name to entry_ptr.
        self.dir_handles[idx].position += 1;
        
        // Return bytes written (simulated - would be actual entry name length).
        const result = SyscallResult.ok(1); // 1 byte for "."
        return result;
    }

    /// Why: Close an open directory handle.
    pub fn syscall_closedir(
        self: *BasinKernel,
        dir_handle: u64,
        _arg2: u64,
        _arg3: u64,
        _arg4: u64,
    ) BasinError!SyscallResult {
        // Assert: self pointer must be valid.
        const self_ptr = @intFromPtr(self);
        Debug.kassert(self_ptr != 0, "Self ptr is null", .{});
        Debug.kassert(self_ptr % @alignOf(BasinKernel) == 0, "Self ptr unaligned", .{});
        
        _ = _arg2;
        _ = _arg3;
        _ = _arg4;
        
        // Assert: directory handle must be valid (non-zero).
        if (dir_handle == 0) {
            return SyscallResult.fail(BasinError.invalid_argument);
        }
        
        // Find and free directory handle.
        var found: bool = false;
        for (0..MAX_DIR_HANDLES) |i| {
            if (self.dir_handles[i].allocated and self.dir_handles[i].id == dir_handle) {
                self.dir_handles[i] = DirectoryHandle.init();
                found = true;
                break;
            }
        }
        
        if (!found) {
            return SyscallResult.fail(BasinError.invalid_argument);
        }
        
        const result = SyscallResult.ok(0);
        return result;
    }
};
