//! Realidream Toroidal Integration
//! Why: Connect Realidream browser to garden-allocated UnifiedDag.
//!
//! This replaces the allocator-based BrowserDagIntegration with a
//! toroidal, garden-allocated approach for the Realidream browser.

const std = @import("std");
const adapter = @import("kernel/dag_toroidal_adapter.zig");
const UnifiedDag = adapter.UnifiedDag;
const UnifiedNodeType = adapter.UnifiedNodeType;
const UnifiedEventType = adapter.UnifiedEventType;
const NodeHandle = adapter.NodeHandle;

/// Why: Maximum DOM nodes per page (bounded).
pub const MAX_DOM_NODES: u32 = 5_000;

/// Why: Maximum pending DOM mutations.
pub const MAX_MUTATIONS: u32 = 100;

/// Why: DOM element representation for Realidream.
pub const DomElement = struct {
    handle: NodeHandle,
    tag: Tag,
    parent: NodeHandle,
    first_child: NodeHandle,
    next_sibling: NodeHandle,

    /// Why: Common HTML tags as enum for efficiency.
    pub const Tag = enum(u8) {
        unknown,
        html,
        head,
        body,
        div,
        span,
        p,
        a,
        img,
        input,
        button,
        form,
        ul,
        ol,
        li,
        h1,
        h2,
        h3,
        table,
        tr,
        td,
        script,
        style,
        link,
        meta,
    };

    /// Why: Initialize empty element.
    pub fn init() DomElement {
        return DomElement{
            .handle = NodeHandle.invalid(),
            .tag = .unknown,
            .parent = NodeHandle.invalid(),
            .first_child = NodeHandle.invalid(),
            .next_sibling = NodeHandle.invalid(),
        };
    }

    /// Why: Parse tag name to enum.
    pub fn parse_tag(name: []const u8) Tag {
        if (std.mem.eql(u8, name, "div")) return .div;
        if (std.mem.eql(u8, name, "span")) return .span;
        if (std.mem.eql(u8, name, "p")) return .p;
        if (std.mem.eql(u8, name, "a")) return .a;
        if (std.mem.eql(u8, name, "img")) return .img;
        if (std.mem.eql(u8, name, "body")) return .body;
        if (std.mem.eql(u8, name, "html")) return .html;
        if (std.mem.eql(u8, name, "head")) return .head;
        if (std.mem.eql(u8, name, "button")) return .button;
        if (std.mem.eql(u8, name, "input")) return .input;
        if (std.mem.eql(u8, name, "form")) return .form;
        return .unknown;
    }
};

/// Why: Realidream browser integration with toroidal DAG.
pub const RealidreamIntegration = struct {
    dag: UnifiedDag,
    elements: [MAX_DOM_NODES]DomElement,
    element_count: u32,
    root: NodeHandle,

    /// Why: Initialize browser integration.
    pub fn init() RealidreamIntegration {
        var ri = RealidreamIntegration{
            .dag = UnifiedDag.init(),
            .elements = undefined,
            .element_count = 0,
            .root = NodeHandle.invalid(),
        };
        for (&ri.elements) |*e| e.* = DomElement.init();
        return ri;
    }

    /// Why: Create document root (html element).
    pub fn create_document(self: *RealidreamIntegration) ?NodeHandle {
        const handle = self.dag.create_node(.dom_element) orelse return null;
        const slot = self.find_free_slot() orelse return null;
        self.elements[slot].handle = handle;
        self.elements[slot].tag = .html;
        self.element_count += 1;
        self.root = handle;
        return handle;
    }

    /// Why: Create DOM element with parent.
    pub fn create_element(self: *RealidreamIntegration, tag: []const u8, parent: NodeHandle) ?NodeHandle {
        if (self.element_count >= MAX_DOM_NODES) return null;
        const handle = self.dag.create_node(.dom_element) orelse return null;
        const slot = self.find_free_slot() orelse return null;
        self.elements[slot].handle = handle;
        self.elements[slot].tag = DomElement.parse_tag(tag);
        self.elements[slot].parent = parent;
        self.element_count += 1;
        _ = self.dag.add_edge(parent, handle);
        return handle;
    }

    /// Why: Create text node.
    pub fn create_text(self: *RealidreamIntegration, parent: NodeHandle) ?NodeHandle {
        if (self.element_count >= MAX_DOM_NODES) return null;
        const handle = self.dag.create_node(.dom_text) orelse return null;
        const slot = self.find_free_slot() orelse return null;
        self.elements[slot].handle = handle;
        self.elements[slot].tag = .unknown;
        self.elements[slot].parent = parent;
        self.element_count += 1;
        _ = self.dag.add_edge(parent, handle);
        return handle;
    }

    fn find_free_slot(self: *RealidreamIntegration) ?usize {
        for (&self.elements, 0..) |*e, i| {
            if (e.handle.raw() == NodeHandle.invalid().raw()) return i;
        }
        return null;
    }

    /// Why: Get element by handle.
    pub fn get_element(self: *RealidreamIntegration, handle: NodeHandle) ?*DomElement {
        for (&self.elements) |*e| {
            if (e.handle.raw() == handle.raw()) return e;
        }
        return null;
    }

    /// Why: Push DOM mutation event.
    pub fn push_mutation(self: *RealidreamIntegration, target: NodeHandle) void {
        self.dag.push_event(target, .dom_mutation);
    }

    /// Why: Process pending mutations.
    pub fn process_mutations(self: *RealidreamIntegration) u32 {
        return self.dag.process_events();
    }

    /// Why: Get DOM element count.
    pub fn dom_count(self: *const RealidreamIntegration) u32 {
        return self.element_count;
    }

    /// Why: Get DAG node count.
    pub fn node_count(self: *const RealidreamIntegration) u32 {
        return self.dag.count();
    }

    /// Why: Remove element from DOM.
    pub fn remove_element(self: *RealidreamIntegration, handle: NodeHandle) bool {
        const elem = self.get_element(handle) orelse return false;
        elem.* = DomElement.init();
        self.element_count -= 1;
        return self.dag.release_node(handle);
    }
};

/// Why: Aurora integration with toroidal DAG.
pub const AuroraIntegration = struct {
    dag: UnifiedDag,
    node_count: u32,

    /// Why: Initialize Aurora editor integration.
    pub fn init() AuroraIntegration {
        return AuroraIntegration{
            .dag = UnifiedDag.init(),
            .node_count = 0,
        };
    }

    /// Why: Create AST function node.
    pub fn create_function(self: *AuroraIntegration) ?NodeHandle {
        const handle = self.dag.create_node(.ast_function) orelse return null;
        self.node_count += 1;
        return handle;
    }

    /// Why: Create AST statement node.
    pub fn create_statement(self: *AuroraIntegration, parent: NodeHandle) ?NodeHandle {
        const handle = self.dag.create_node(.ast_statement) orelse return null;
        _ = self.dag.add_edge(parent, handle);
        self.node_count += 1;
        return handle;
    }

    /// Why: Create AST expression node.
    pub fn create_expression(self: *AuroraIntegration, parent: NodeHandle) ?NodeHandle {
        const handle = self.dag.create_node(.ast_expression) orelse return null;
        _ = self.dag.add_edge(parent, handle);
        self.node_count += 1;
        return handle;
    }

    /// Why: Push code edit event.
    pub fn push_edit(self: *AuroraIntegration, target: NodeHandle) void {
        self.dag.push_event(target, .code_edit);
    }

    /// Why: Process pending edits.
    pub fn process_edits(self: *AuroraIntegration) u32 {
        return self.dag.process_events();
    }

    /// Why: Get AST node count.
    pub fn count(self: *const AuroraIntegration) u32 {
        return self.node_count;
    }
};

/// Why: Skate visual integration with toroidal DAG.
pub const SkateIntegration = struct {
    dag: UnifiedDag,
    node_count: u32,

    /// Why: Initialize Skate visual programming integration.
    pub fn init() SkateIntegration {
        return SkateIntegration{
            .dag = UnifiedDag.init(),
            .node_count = 0,
        };
    }

    /// Why: Create visual node.
    pub fn create_visual_node(self: *SkateIntegration) ?NodeHandle {
        const handle = self.dag.create_node(.visual_node) orelse return null;
        self.node_count += 1;
        return handle;
    }

    /// Why: Create visual edge between nodes.
    pub fn create_visual_edge(self: *SkateIntegration, from: NodeHandle, to: NodeHandle) bool {
        return self.dag.add_edge(from, to);
    }

    /// Why: Create visual group containing nodes.
    pub fn create_group(self: *SkateIntegration) ?NodeHandle {
        const handle = self.dag.create_node(.visual_group) orelse return null;
        self.node_count += 1;
        return handle;
    }

    /// Why: Push visual change event.
    pub fn push_change(self: *SkateIntegration, target: NodeHandle) void {
        self.dag.push_event(target, .visual_change);
    }

    /// Why: Process pending changes.
    pub fn process_changes(self: *SkateIntegration) u32 {
        return self.dag.process_events();
    }

    /// Why: Get visual node count.
    pub fn count(self: *const SkateIntegration) u32 {
        return self.node_count;
    }
};
