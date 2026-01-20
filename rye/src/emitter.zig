//! Rye Emitter
//! Why: Emit validated Rye AST as Zig source code.
//!
//! Phase 1: Since Rye syntax ≈ Zig syntax, we mostly just copy the source.
//! Future phases may add transformations.

const std = @import("std");

/// Rye emitter.
pub const Emitter = struct {
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize emitter.
    pub fn init(allocator: std.mem.Allocator) Self {
        return Self{
            .allocator = allocator,
        };
    }

    /// Emit source as Zig.
    /// Why: Phase 1 just copies source since Rye ≈ Zig.
    pub fn emit(self: *Self, source: []const u8) ![]const u8 {
        // For Phase 1, Rye is a strict subset of Zig, so we just return the source.
        // Future phases may:
        // - Add Rye-specific syntax transformations
        // - Insert runtime assertions
        // - Generate additional debug info
        const result = try self.allocator.alloc(u8, source.len);
        @memcpy(result, source);
        return result;
    }

    /// Emit to file.
    pub fn emitToFile(self: *Self, source: []const u8, output_path: []const u8) !void {
        const emitted = try self.emit(source);
        defer self.allocator.free(emitted);

        try std.fs.cwd().writeFile(.{ .sub_path = output_path, .data = emitted });
    }
};
