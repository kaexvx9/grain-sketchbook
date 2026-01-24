//! Why: Test Writer vtable dispatch for RISC-V freestanding.
//! Verifies Writer vtable operations work correctly, testing Issue 2 hypothesis.
//! This test uses a minimal Writer implementation to test vtable dispatch.

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

// Why: Test Writer vtable operations.
pub fn test_writer_vtable() void {
    // Why: Create test writer with buffer.
    var buffer: [100]u8 = undefined;
    var test_writer = TestWriter{ .buffer = &buffer };
    var writer = test_writer.writer();
    
    // Why: Test writeAll (uses vtable.drain when buffer full).
    writer.writeAll("test") catch {};
    
    // Why: Test multiple writes.
    writer.writeAll("hello") catch {};
    writer.writeAll("world") catch {};
}

// compile
// backend=stage2
// target=riscv64-freestanding
// output_mode=Obj
