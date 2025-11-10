const std = @import("std");

pub const MMTCurrencyPayload = struct {
    npub: [32]u8,
    title: []const u8,
    policy: Policy,
    action: Action,

    pub fn toBytes(self: MMTCurrencyPayload, allocator: std.mem.Allocator) ![]u8 {
        var buffer = std.ArrayList(u8).init(allocator);
        errdefer buffer.deinit();

        try buffer.appendSlice(&self.npub);
        try writeSlice(&buffer, self.title);
        try writePolicy(&buffer, self.policy);
        try writeAction(&buffer, self.action);
        return buffer.toOwnedSlice();
    }
};

pub const Policy = struct {
    base_rate_bps: i32,
    tax_rate_bps: i32,
};

pub const Action = union(enum) {
    mint: u128,
    burn: u128,
    loan: LoanTerms,
    collect_tax: u128,
};

pub const LoanTerms = struct {
    principal: u128,
    rate_bps: i32,
    duration_seconds: u64,
};

fn writeSlice(buffer: *std.ArrayList(u8), data: []const u8) !void {
    const len = @intCast(u32, data.len);
    try buffer.appendSlice(std.mem.asBytes(&len));
    try buffer.appendSlice(data);
}

fn writePolicy(buffer: *std.ArrayList(u8), policy: Policy) !void {
    try buffer.appendSlice(std.mem.asBytes(&policy.base_rate_bps));
    try buffer.appendSlice(std.mem.asBytes(&policy.tax_rate_bps));
}

fn writeAction(buffer: *std.ArrayList(u8), action: Action) !void {
    const tag = @enumToInt(action);
    try buffer.appendSlice(std.mem.asBytes(&tag));
    switch (action) {
        .mint => |amt| try buffer.appendSlice(std.mem.asBytes(&amt)),
        .burn => |amt| try buffer.appendSlice(std.mem.asBytes(&amt)),
        .collect_tax => |amt| try buffer.appendSlice(std.mem.asBytes(&amt)),
        .loan => |terms| {
            try buffer.appendSlice(std.mem.asBytes(&terms.principal));
            try buffer.appendSlice(std.mem.asBytes(&terms.rate_bps));
            try buffer.appendSlice(std.mem.asBytes(&terms.duration_seconds));
        },
    }
}

test "MMT payload serialization" {
    var payload = MMTCurrencyPayload{
        .npub = [_]u8{0} ** 32,
        .title = "SolsticeCredits",
        .policy = .{ .base_rate_bps = 150, .tax_rate_bps = 200 },
        .action = .{ .mint = 1_000_000 },
    };
    var bytes = try payload.toBytes(std.testing.allocator);
    defer std.testing.allocator.free(bytes);
    try std.testing.expect(bytes.len > 0);
}

