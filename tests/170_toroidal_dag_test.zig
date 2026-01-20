//! Toroidal DAG UI Backend Test
//! Why: Verify toroidal data structures work for unified UI backend.
//!
//! Tests the core toroidal primitives and DAG operations that will
//! power Aurora, Skate, and Realidream unified backend.

const std = @import("std");
const testing = std.testing;

// Import toroidal types
const toroidal = @import("toroidal");
const ToroidalIndex = toroidal.ToroidalIndex;
const ToroidalBuffer = toroidal.ToroidalBuffer;
const BoundedParam = toroidal.BoundedParam;
const ToroidalGrid = toroidal.ToroidalGrid;

// === ToroidalIndex Tests ===

test "toroidal index wraps at boundary" {
    const Idx = ToroidalIndex(10);
    
    // Basic init wraps
    try testing.expectEqual(@as(u32, 0), Idx.init(0).get());
    try testing.expectEqual(@as(u32, 5), Idx.init(5).get());
    try testing.expectEqual(@as(u32, 0), Idx.init(10).get()); // wraps
    try testing.expectEqual(@as(u32, 5), Idx.init(15).get()); // wraps
}

test "toroidal index increment wraps" {
    const Idx = ToroidalIndex(4);
    var idx = Idx.init(0);
    
    idx.inc(); try testing.expectEqual(@as(u32, 1), idx.get());
    idx.inc(); try testing.expectEqual(@as(u32, 2), idx.get());
    idx.inc(); try testing.expectEqual(@as(u32, 3), idx.get());
    idx.inc(); try testing.expectEqual(@as(u32, 0), idx.get()); // wrapped!
    idx.inc(); try testing.expectEqual(@as(u32, 1), idx.get());
}

test "toroidal index decrement wraps" {
    const Idx = ToroidalIndex(4);
    var idx = Idx.init(1);
    
    idx.dec(); try testing.expectEqual(@as(u32, 0), idx.get());
    idx.dec(); try testing.expectEqual(@as(u32, 3), idx.get()); // wrapped!
    idx.dec(); try testing.expectEqual(@as(u32, 2), idx.get());
}

test "toroidal index distance is symmetric" {
    const Idx = ToroidalIndex(10);
    const a = Idx.init(2);
    const b = Idx.init(8);
    
    // Distance should be 4 (shorter path: 2->1->0->9->8)
    try testing.expectEqual(@as(u32, 4), a.distance(b));
    try testing.expectEqual(@as(u32, 4), b.distance(a)); // symmetric
}

// === ToroidalBuffer Tests ===

test "toroidal buffer push and pop" {
    var buf = ToroidalBuffer(u32, 4).init();
    
    try testing.expect(buf.is_empty());
    try testing.expect(!buf.is_full());
    
    buf.push(10);
    buf.push(20);
    buf.push(30);
    
    try testing.expectEqual(@as(u32, 3), buf.len());
    try testing.expectEqual(@as(u32, 10), buf.pop().?);
    try testing.expectEqual(@as(u32, 20), buf.pop().?);
    try testing.expectEqual(@as(u32, 30), buf.pop().?);
    try testing.expectEqual(@as(?u32, null), buf.pop());
}

test "toroidal buffer overwrites oldest when full" {
    var buf = ToroidalBuffer(u32, 3).init();
    
    buf.push(1);
    buf.push(2);
    buf.push(3);
    try testing.expect(buf.is_full());
    
    // Push when full - overwrites oldest (1)
    buf.push(4);
    try testing.expect(buf.is_full());
    try testing.expectEqual(@as(u32, 3), buf.len());
    
    // Pop should give 2, 3, 4 (1 was overwritten)
    try testing.expectEqual(@as(u32, 2), buf.pop().?);
    try testing.expectEqual(@as(u32, 3), buf.pop().?);
    try testing.expectEqual(@as(u32, 4), buf.pop().?);
}

test "toroidal buffer peek" {
    var buf = ToroidalBuffer(u32, 4).init();
    
    buf.push(100);
    buf.push(200);
    buf.push(300);
    
    try testing.expectEqual(@as(u32, 100), buf.peek(0).?);
    try testing.expectEqual(@as(u32, 200), buf.peek(1).?);
    try testing.expectEqual(@as(u32, 300), buf.peek(2).?);
    try testing.expectEqual(@as(?u32, null), buf.peek(3)); // out of range
}

// === BoundedParam Tests ===

test "bounded param clamps to range" {
    const Param = BoundedParam(0, 100);
    
    try testing.expectEqual(@as(i64, 50), Param.init(50).get());
    try testing.expectEqual(@as(i64, 0), Param.init(-10).get()); // clamped
    try testing.expectEqual(@as(i64, 100), Param.init(200).get()); // clamped
}

test "bounded param wraps in toroidal mode" {
    const Param = BoundedParam(0, 9);
    
    try testing.expectEqual(@as(i64, 5), Param.init_wrap(5).get());
    try testing.expectEqual(@as(i64, 0), Param.init_wrap(10).get()); // wrapped
    try testing.expectEqual(@as(i64, 5), Param.init_wrap(15).get()); // wrapped
    try testing.expectEqual(@as(i64, 9), Param.init_wrap(-1).get()); // wrapped negative
}

test "bounded param normalize" {
    const Param = BoundedParam(0, 100);
    
    try testing.expectApproxEqAbs(@as(f64, 0.0), Param.init(0).normalize(), 0.01);
    try testing.expectApproxEqAbs(@as(f64, 0.5), Param.init(50).normalize(), 0.01);
    try testing.expectApproxEqAbs(@as(f64, 1.0), Param.init(100).normalize(), 0.01);
}

// === ToroidalGrid Tests ===

test "toroidal grid wraps in both dimensions" {
    var grid = ToroidalGrid(u8, 4, 4).init(0);
    
    grid.set(0, 0, 1);
    grid.set(3, 3, 2);
    
    try testing.expectEqual(@as(u8, 1), grid.get(0, 0));
    try testing.expectEqual(@as(u8, 2), grid.get(3, 3));
    
    // Wrapping access
    try testing.expectEqual(@as(u8, 1), grid.get(4, 4)); // wraps to (0,0)
    try testing.expectEqual(@as(u8, 2), grid.get(7, 7)); // wraps to (3,3)
}

test "toroidal grid neighbor with wrap" {
    var grid = ToroidalGrid(u8, 4, 4).init(0);
    
    grid.set(0, 0, 42);
    
    // Neighbor at (-1, -1) from (0,0) should wrap to (3,3)
    // But (3,3) is 0, and we're checking neighbor of (1,1) at offset (-1,-1)
    grid.set(1, 1, 99);
    try testing.expectEqual(@as(u8, 99), grid.neighbor(2, 2, -1, -1));
    
    // Wrap around: neighbor of (0,0) at offset (-1,0) is (3,0)
    grid.set(3, 0, 77);
    try testing.expectEqual(@as(u8, 77), grid.neighbor(0, 0, -1, 0));
}

// === UI Event Queue Simulation ===

test "toroidal event queue for UI updates" {
    // Simulate a UI event queue like Aurora/Skate/Realidream would use
    const Event = struct {
        id: u32,
        event_type: u8,
        data: u32,
    };
    
    var queue = ToroidalBuffer(Event, 8).init();
    
    // Push some UI events
    queue.push(.{ .id = 1, .event_type = 1, .data = 100 }); // click
    queue.push(.{ .id = 2, .event_type = 2, .data = 200 }); // keypress
    queue.push(.{ .id = 3, .event_type = 1, .data = 300 }); // click
    
    try testing.expectEqual(@as(u32, 3), queue.len());
    
    // Process events
    const evt1 = queue.pop().?;
    try testing.expectEqual(@as(u32, 1), evt1.id);
    try testing.expectEqual(@as(u32, 100), evt1.data);
    
    const evt2 = queue.pop().?;
    try testing.expectEqual(@as(u32, 2), evt2.id);
}

// === DAG Node Indexing Simulation ===

test "toroidal node index for DAG" {
    // Simulate how DAG nodes would use toroidal indexing
    const NodeIdx = ToroidalIndex(1000); // Max 1000 nodes
    
    var nodes_used: u32 = 0;
    var next_idx = NodeIdx.init(0);
    
    // "Allocate" some nodes
    inline for (0..5) |_| {
        _ = next_idx.get();
        next_idx.inc();
        nodes_used += 1;
    }
    
    try testing.expectEqual(@as(u32, 5), nodes_used);
    try testing.expectEqual(@as(u32, 5), next_idx.get());
    
    // Test wrap at boundary
    var boundary_idx = NodeIdx.init(999);
    boundary_idx.inc();
    try testing.expectEqual(@as(u32, 0), boundary_idx.get()); // wrapped
}
