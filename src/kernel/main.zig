const std = @import("std");

pub fn main() !void {
    // Glow G2 placeholder: boot strap will be replaced once VPS path opens.
    const stdout = std.io.getStdOut().writer();
    try stdout.print("Grain kernel bootstrap stub\n", .{});
}
