//! Kernel panic output.
const std = @import("std");
const RawIO = @import("uart.zig");

/// Why: Output panic message to UART for debugging.
pub fn write(msg: []const u8) void {
    RawIO.write(msg);
}
