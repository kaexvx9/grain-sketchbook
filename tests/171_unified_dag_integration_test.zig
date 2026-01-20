//! Unified DAG Integration Test
//! Why: Verify Aurora, Skate, and Realidream use toroidal DAG correctly.

const std = @import("std");
const testing = std.testing;

const integration = @import("realidream_toroidal_integration");
const RealidreamIntegration = integration.RealidreamIntegration;
const AuroraIntegration = integration.AuroraIntegration;
const SkateIntegration = integration.SkateIntegration;
const DomElement = integration.DomElement;

// === Realidream Browser Tests ===

test "realidream: create document" {
    var ri = RealidreamIntegration.init();
    
    const root = ri.create_document();
    try testing.expect(root != null);
    try testing.expectEqual(@as(u32, 1), ri.dom_count());
    try testing.expectEqual(@as(u32, 1), ri.node_count());
}

test "realidream: create elements" {
    var ri = RealidreamIntegration.init();
    
    const html = ri.create_document().?;
    const body = ri.create_element("body", html).?;
    const div = ri.create_element("div", body).?;
    _ = ri.create_element("span", div).?;
    
    try testing.expectEqual(@as(u32, 4), ri.dom_count());
    try testing.expectEqual(@as(u32, 4), ri.node_count());
    
    // Check element exists
    const elem = ri.get_element(div);
    try testing.expect(elem != null);
    try testing.expectEqual(DomElement.Tag.div, elem.?.tag);
}

test "realidream: create text node" {
    var ri = RealidreamIntegration.init();
    
    const html = ri.create_document().?;
    const body = ri.create_element("body", html).?;
    const p = ri.create_element("p", body).?;
    const text = ri.create_text(p);
    
    try testing.expect(text != null);
    try testing.expectEqual(@as(u32, 4), ri.dom_count());
}

test "realidream: DOM mutations" {
    var ri = RealidreamIntegration.init();
    
    const html = ri.create_document().?;
    const body = ri.create_element("body", html).?;
    
    // Push mutations
    ri.push_mutation(body);
    ri.push_mutation(html);
    
    // Process
    const processed = ri.process_mutations();
    try testing.expectEqual(@as(u32, 2), processed);
}

test "realidream: remove element" {
    var ri = RealidreamIntegration.init();
    
    const html = ri.create_document().?;
    const body = ri.create_element("body", html).?;
    
    try testing.expectEqual(@as(u32, 2), ri.dom_count());
    
    const removed = ri.remove_element(body);
    try testing.expect(removed);
    try testing.expectEqual(@as(u32, 1), ri.dom_count());
}

test "realidream: tag parsing" {
    try testing.expectEqual(DomElement.Tag.div, DomElement.parse_tag("div"));
    try testing.expectEqual(DomElement.Tag.span, DomElement.parse_tag("span"));
    try testing.expectEqual(DomElement.Tag.body, DomElement.parse_tag("body"));
    try testing.expectEqual(DomElement.Tag.unknown, DomElement.parse_tag("custom"));
}

// === Aurora Editor Tests ===

test "aurora: create AST nodes" {
    var ai = AuroraIntegration.init();
    
    const func = ai.create_function();
    try testing.expect(func != null);
    
    const stmt = ai.create_statement(func.?);
    try testing.expect(stmt != null);
    
    const expr = ai.create_expression(stmt.?);
    try testing.expect(expr != null);
    
    try testing.expectEqual(@as(u32, 3), ai.count());
}

test "aurora: code edits" {
    var ai = AuroraIntegration.init();
    
    const func = ai.create_function().?;
    const stmt = ai.create_statement(func).?;
    
    // Push edits
    ai.push_edit(func);
    ai.push_edit(stmt);
    ai.push_edit(func);
    
    // Process
    const processed = ai.process_edits();
    try testing.expectEqual(@as(u32, 3), processed);
}

// === Skate Visual Programming Tests ===

test "skate: create visual nodes" {
    var si = SkateIntegration.init();
    
    const node1 = si.create_visual_node();
    const node2 = si.create_visual_node();
    const node3 = si.create_visual_node();
    
    try testing.expect(node1 != null);
    try testing.expect(node2 != null);
    try testing.expect(node3 != null);
    try testing.expectEqual(@as(u32, 3), si.count());
}

test "skate: create visual edges" {
    var si = SkateIntegration.init();
    
    const n1 = si.create_visual_node().?;
    const n2 = si.create_visual_node().?;
    const n3 = si.create_visual_node().?;
    
    // Create flow: n1 -> n2 -> n3
    try testing.expect(si.create_visual_edge(n1, n2));
    try testing.expect(si.create_visual_edge(n2, n3));
}

test "skate: create groups" {
    var si = SkateIntegration.init();
    
    const group = si.create_group();
    try testing.expect(group != null);
    
    const node1 = si.create_visual_node().?;
    const node2 = si.create_visual_node().?;
    
    // Add nodes to group
    try testing.expect(si.create_visual_edge(group.?, node1));
    try testing.expect(si.create_visual_edge(group.?, node2));
    
    try testing.expectEqual(@as(u32, 3), si.count());
}

test "skate: visual changes" {
    var si = SkateIntegration.init();
    
    const n1 = si.create_visual_node().?;
    const n2 = si.create_visual_node().?;
    
    si.push_change(n1);
    si.push_change(n2);
    si.push_change(n1);
    
    const processed = si.process_changes();
    try testing.expectEqual(@as(u32, 3), processed);
}

// === Cross-Backend Integration ===

test "unified: all backends use toroidal DAG" {
    // Each backend has its own DAG instance
    var realidream = RealidreamIntegration.init();
    var aurora = AuroraIntegration.init();
    var skate = SkateIntegration.init();
    
    // Create nodes in each
    _ = realidream.create_document();
    _ = aurora.create_function();
    _ = skate.create_visual_node();
    
    // Each is independent
    try testing.expectEqual(@as(u32, 1), realidream.node_count());
    try testing.expectEqual(@as(u32, 1), aurora.count());
    try testing.expectEqual(@as(u32, 1), skate.count());
}
