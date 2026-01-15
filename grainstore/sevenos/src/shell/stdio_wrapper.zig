//! stdio wrapper for Zig 0.15.2 compatibility
//! Why: std.io.getStdOut() API changed in Zig 0.15.2, need wrapper for compatibility.

const std = @import("std");
const posix = std.posix;

/// Get stdout file.
pub fn getStdOut() std.fs.File {
    return std.fs.File{ .handle = posix.STDOUT_FILENO };
}

/// Get stderr file.
pub fn getStdErr() std.fs.File {
    return std.fs.File{ .handle = posix.STDERR_FILENO };
}

/// Get stdin file.
pub fn getStdIn() std.fs.File {
    return std.fs.File{ .handle = posix.STDIN_FILENO };
}

/// Writer buffer size for stdout/stderr.
const WRITER_BUFFER_SIZE = 4096;

