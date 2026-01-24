//! Why: Test format string + Writer interaction for RISC-V freestanding.
//! Verifies format strings with Writer operations work correctly, testing Issue 2 hypothesis.
//! This test combines comptime format strings with runtime Writer operations.

const builtin = @import("builtin");
const std = @import("std");

// Why: Minimal Writer implementation for testing.
const TestWriter = struct {
    buffer: []u8,
    pos: usize = 0,
    
    const Writer = std.io.Writer(*@This(), error{}, writeFn);
    
    fn writeFn(self: *@This(), bytes: []const u8) error{}!usize {
        const to_write = @min(bytes.len, self.buffer.len - self.pos);
        @memcpy(self.buffer[self.pos..][0..to_write], bytes[0..to_write]);
        self.pos += to_write;
        return to_write;
    }
    
    pub fn writer(self: *@This()) Writer {
        return .{ .context = self };
    }
};

// Why: Test format string + Writer interaction.
pub fn test_format_writer() void {
    // Why: Create test writer with buffer.
    var buffer: [200]u8 = undefined;
    var test_writer = TestWriter{ .buffer = &buffer };
    var writer = test_writer.writer();
    
    // Why: Test format string with Writer (comptime format + runtime Writer).
    writer.print("test: {}\n", .{42}) catch {};
    writer.print("value: {d}\n", .{100}) catch {};
    writer.print("hex: {x}\n", .{0xFF}) catch {};
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Obj
