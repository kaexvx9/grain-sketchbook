const std = @import("std");
const BrowserDagIntegration = @import("dream_browser_dag_integration.zig").BrowserDagIntegration;

/// Dream Browser Parser: HTML/CSS parser for Zig-native browser.
/// ~<~ Glow Airbend: explicit parsing, bounded tree depth.
/// ~~~~ Glow Waterbend: parsing flows deterministically through DAG.
///
/// This implements a subset of HTML5 and CSS3:
/// - HTML parser (subset: div, span, p, a, img, etc.)
/// - CSS parser (subset: color, background, font-size, etc.)
/// - DOM tree construction (bounded depth, explicit nodes)
/// - Style computation (cascade, specificity)
pub const DreamBrowserParser = struct {
    allocator: std.mem.Allocator,
    
    // Bounded: Max 100 tree depth
    pub const MAX_TREE_DEPTH: u32 = 100;
    
    // Bounded: Max 10,000 DOM nodes per page
    pub const MAX_DOM_NODES: u32 = 10_000;
    
    // Bounded: Max 1,000 CSS rules per stylesheet
    pub const MAX_CSS_RULES: u32 = 1_000;
    
    // Bounded: Max HTML input size (10MB)
    pub const MAX_HTML_SIZE: u32 = 10 * 1024 * 1024;
    
    // Bounded: Max tag name length (64 chars)
    pub const MAX_TAG_NAME_LEN: u32 = 64;
    
    // Bounded: Max 100 attributes per tag
    pub const MAX_ATTRIBUTES: u32 = 100;
    
    // Bounded: Max attribute name length (256 chars)
    pub const MAX_ATTR_NAME_LEN: u32 = 256;
    
    // Bounded: Max attribute value length (4KB)
    pub const MAX_ATTR_VALUE_LEN: u32 = 4 * 1024;
    
    /// HTML element node (DOM node).
    pub const HtmlNode = struct {
        tag_name: []const u8, // "div", "span", "p", etc.
        attributes: []const Attribute,
        children: []const HtmlNode,
        text_content: []const u8, // Text content (for text nodes)
        parent: ?*HtmlNode = null,
        depth: u32 = 0, // Tree depth (for bounds checking)
    };
    
    /// HTML attribute.
    pub const Attribute = struct {
        name: []const u8,
        value: []const u8,
    };
    
    /// CSS rule (selector + declarations).
    pub const CssRule = struct {
        selector: []const u8, // "div", ".class", "#id", etc.
        declarations: []const Declaration,
    };
    
    /// CSS declaration (property + value).
    pub const Declaration = struct {
        property: []const u8, // "color", "background", "font-size", etc.
        value: []const u8, // "red", "#ff0000", "16px", etc.
    };
    
    /// Initialize parser.
    pub fn init(allocator: std.mem.Allocator) DreamBrowserParser {
        return DreamBrowserParser{
            .allocator = allocator,
        };
    }
    
    /// Deinitialize parser.
    pub fn deinit(self: *DreamBrowserParser) void {
        // No dynamic allocation to clean up
        _ = self;
    }
    
    /// Parse HTML string into DOM tree (iterative, supports nested tags).
    pub fn parseHtml(
        self: *DreamBrowserParser,
        html: []const u8,
    ) !HtmlNode {
        // Assert: HTML must be non-empty
        std.debug.assert(html.len > 0);
        
        // Bounded: Max HTML input size
        if (html.len > MAX_HTML_SIZE) {
            return error.HtmlTooLarge;
        }
        
        // Parse root node (iterative stack-based parsing for nested tags)
        return try self.parseHtmlNode(html, 0, null);
    }
    
    /// Parse single HTML node (helper for nested parsing).
    fn parseHtmlNode(
        self: *DreamBrowserParser,
        html: []const u8,
        start_pos: u32,
        parent_node: ?*HtmlNode,
    ) !HtmlNode {
        // Assert: Start position must be valid
        std.debug.assert(start_pos < html.len);
        
        // Bounded: Tree depth check (via parent depth)
        const current_depth: u32 = if (parent_node) |p| p.depth + 1 else 0;
        if (current_depth >= MAX_TREE_DEPTH) {
            return error.TreeTooDeep;
        }
        
        // Find opening tag
        const html_slice = html[start_pos..];
        const tag_start_offset = std.mem.indexOf(u8, html_slice, "<") orelse return error.InvalidHtml;
        const tag_start = start_pos + tag_start_offset;
        const tag_end_offset = std.mem.indexOf(u8, html_slice[tag_start_offset + 1..], ">") orelse return error.InvalidHtml;
        const tag_end = tag_start + 1 + tag_end_offset;
        
        // Assert: Tag must be valid
        std.debug.assert(tag_end > tag_start);
        
        const tag_str = html[tag_start + 1..tag_end];
        
        // Assert: Tag string must be non-empty
        std.debug.assert(tag_str.len > 0);
        
        // Check for self-closing tag or closing tag
        if (tag_str[0] == '/' or tag_str[tag_str.len - 1] == '/') {
            return error.InvalidHtml; // Handle closing tags separately
        }
        
        // Parse tag name and attributes
        const parse_result = try self.parseTagNameAndAttributes(tag_str);
        const tag_name = parse_result.tag_name;
        const attributes = parse_result.attributes;
        
        // Check for self-closing tags (br, img, etc.)
        const is_self_closing = self.isSelfClosingTag(tag_name);
        
        if (is_self_closing) {
            // Self-closing tag: no children or closing tag
            return HtmlNode{
                .tag_name = tag_name,
                .attributes = attributes,
                .children = &.{},
                .text_content = "",
                .parent = parent_node,
                .depth = current_depth,
            };
        }
        
        // Find content and closing tag
        const content_start = tag_end + 1;
        const closing_tag_str = try std.fmt.allocPrint(self.allocator, "</{s}>", .{tag_name});
        defer self.allocator.free(closing_tag_str);
        
        const html_remaining = html[content_start..];
        const closing_tag_offset = std.mem.indexOf(u8, html_remaining, closing_tag_str) orelse html_remaining.len;
        const closing_tag_pos = content_start + closing_tag_offset;
        const content = html[content_start..closing_tag_pos];
        
        // Parse children (nested tags and text nodes)
        const children = try self.parseChildren(content, current_depth);
        
        // Extract text content (text between tags)
        const text_content = try self.extractTextContent(content, children);
        
        return HtmlNode{
            .tag_name = tag_name,
            .attributes = attributes,
            .children = children,
            .text_content = text_content,
            .parent = parent_node,
            .depth = current_depth,
        };
    }
    
    /// Parse tag name and attributes from tag string.
    const ParseTagResult = struct {
        tag_name: []const u8,
        attributes: []const Attribute,
    };
    
    fn parseTagNameAndAttributes(
        self: *DreamBrowserParser,
        tag_str: []const u8,
    ) !ParseTagResult {
        // Assert: Tag string must be non-empty
        std.debug.assert(tag_str.len > 0);
        
        // Bounded: Max tag name length
        if (tag_str.len > MAX_TAG_NAME_LEN) {
            return error.TagNameTooLong;
        }
        
        // Parse tag name (first word)
        const space_idx = std.mem.indexOfScalar(u8, tag_str, ' ') orelse tag_str.len;
        const tag_name = tag_str[0..space_idx];
        
        // Assert: Tag name must be non-empty
        std.debug.assert(tag_name.len > 0);
        
        // Parse attributes
        var attributes = std.ArrayList(Attribute){ .items = &.{}, .capacity = 0 };
        defer attributes.deinit(self.allocator);
        try attributes.ensureTotalCapacity(self.allocator, 10);
        
        var attr_start = space_idx;
        while (attr_start < tag_str.len) {
            // Bounded: Max attributes
            if (attributes.items.len >= MAX_ATTRIBUTES) {
                break;
            }
            
            // Skip whitespace
            while (attr_start < tag_str.len and tag_str[attr_start] == ' ') {
                attr_start += 1;
            }
            if (attr_start >= tag_str.len) break;
            
            // Find attribute name (until '=' or whitespace)
            const attr_name_start = attr_start;
            var attr_name_end = attr_name_start;
            while (attr_name_end < tag_str.len and tag_str[attr_name_end] != '=' and tag_str[attr_name_end] != ' ') {
                attr_name_end += 1;
            }
            
            if (attr_name_end == attr_name_start) break; // No attribute name found
            
            const attr_name = tag_str[attr_name_start..attr_name_end];
            
            // Bounded: Max attribute name length
            if (attr_name.len > MAX_ATTR_NAME_LEN) {
                return error.AttributeNameTooLong;
            }
            
            // Check for boolean attribute (no value)
            if (attr_name_end >= tag_str.len or tag_str[attr_name_end] != '=') {
                // Boolean attribute (e.g., disabled, checked)
                try attributes.append(Attribute{
                    .name = try self.allocator.dupe(u8, attr_name),
                    .value = "", // Empty value for boolean attributes
                });
                attr_start = attr_name_end;
                continue;
            }
            
            // Find attribute value (quoted or unquoted)
            var value_start = attr_name_end + 1;
            while (value_start < tag_str.len and tag_str[value_start] == ' ') {
                value_start += 1;
            }
            if (value_start >= tag_str.len) break;
            
            var attr_value: []const u8 = undefined;
            var value_end: u32 = value_start;
            
            // Check for quoted value
            if (value_start < tag_str.len and (tag_str[value_start] == '"' or tag_str[value_start] == '\'')) {
                const quote_char = tag_str[value_start];
                value_start += 1; // Skip opening quote
                const quote_search = tag_str[value_start..];
                const quote_offset = std.mem.indexOfScalar(u8, quote_search, quote_char) orelse quote_search.len;
                value_end = value_start + quote_offset;
                attr_value = tag_str[value_start..value_end];
                value_end += 1; // Include closing quote
            } else {
                // Unquoted value (until whitespace or end)
                while (value_end < tag_str.len and tag_str[value_end] != ' ') {
                    value_end += 1;
                }
                attr_value = tag_str[value_start..value_end];
            }
            
            // Bounded: Max attribute value length
            if (attr_value.len > MAX_ATTR_VALUE_LEN) {
                return error.AttributeValueTooLong;
            }
            
            try attributes.append(Attribute{
                .name = try self.allocator.dupe(u8, attr_name),
                .value = try self.allocator.dupe(u8, attr_value),
            });
            
            attr_start = value_end;
        }
        
        return ParseTagResult{
            .tag_name = try self.allocator.dupe(u8, tag_name),
            .attributes = try attributes.toOwnedSlice(),
        };
    }
    
    /// Check if tag is self-closing.
    fn isSelfClosingTag(self: *DreamBrowserParser, tag_name: []const u8) bool {
        _ = self; // Not used, but required for method signature
        const self_closing_tags = [_][]const u8{ "br", "img", "hr", "input", "meta", "link", "area", "base", "col", "embed", "source", "track", "wbr" };
        for (self_closing_tags) |tag| {
            if (std.mem.eql(u8, tag_name, tag)) {
                return true;
            }
        }
        return false;
    }
    
    /// Parse children (nested tags and text nodes) - iterative approach.
    fn parseChildren(
        self: *DreamBrowserParser,
        content: []const u8,
        parent_depth: u32,
    ) ![]const HtmlNode {
        // Assert: Parent depth must be within bounds
        std.debug.assert(parent_depth < MAX_TREE_DEPTH);
        
        var children = std.ArrayList(HtmlNode){ .items = &.{}, .capacity = 0 };
        defer children.deinit(self.allocator);
        try children.ensureTotalCapacity(self.allocator, 10);
        
        var pos: u32 = 0;
        while (pos < content.len) {
            // Skip whitespace
            while (pos < content.len and (content[pos] == ' ' or content[pos] == '\n' or content[pos] == '\t')) {
                pos += 1;
            }
            if (pos >= content.len) break;
            
            // Check for opening tag
            if (content[pos] == '<') {
                // Check for closing tag (skip it)
                if (pos + 1 < content.len and content[pos + 1] == '/') {
                    // Found closing tag - skip to end
                    const closing_end = std.mem.indexOfScalar(u8, content[pos + 2..], '>') orelse content.len;
                    pos = pos + 2 + closing_end + 1;
                    continue;
                }
                
                // Find tag end
                const tag_end_offset = std.mem.indexOfScalar(u8, content[pos + 1..], '>') orelse break;
                const tag_end = pos + 1 + tag_end_offset;
                const tag_str = content[pos + 1..tag_end];
                
                // Parse tag name
                const space_idx = std.mem.indexOfScalar(u8, tag_str, ' ') orelse tag_str.len;
                const tag_name = tag_str[0..space_idx];
                
                // Check for self-closing tag
                const is_self_closing = self.isSelfClosingTag(tag_name);
                
                if (is_self_closing) {
                    // Self-closing tag - create node and move past tag
                    const parse_result = try self.parseTagNameAndAttributes(tag_str);
                    const self_closing_node = HtmlNode{
                        .tag_name = parse_result.tag_name,
                        .attributes = parse_result.attributes,
                        .children = &.{},
                        .text_content = "",
                        .parent = null,
                        .depth = parent_depth + 1,
                    };
                    try children.append(self_closing_node);
                    pos = tag_end + 1;
                    continue;
                }
                
                // Find closing tag for this element
                const closing_tag_str = try std.fmt.allocPrint(self.allocator, "</{s}>", .{tag_name});
                defer self.allocator.free(closing_tag_str);
                
                const content_remaining = content[tag_end + 1..];
                const closing_offset = std.mem.indexOf(u8, content_remaining, closing_tag_str) orelse break;
                const closing_pos = tag_end + 1 + closing_offset;
                const child_content = content[tag_end + 1..closing_pos];
                
                // Parse this child element
                const parse_result = try self.parseTagNameAndAttributes(tag_str);
                const child_children = try self.parseChildren(child_content, parent_depth + 1);
                const child_text = try self.extractTextContent(child_content, child_children);
                
                const child_node = HtmlNode{
                    .tag_name = parse_result.tag_name,
                    .attributes = parse_result.attributes,
                    .children = child_children,
                    .text_content = child_text,
                    .parent = null,
                    .depth = parent_depth + 1,
                };
                try children.append(child_node);
                
                pos = closing_pos + closing_tag_str.len;
            } else {
                // Text node - find next tag or end
                const text_start = pos;
                var text_end = pos;
                while (text_end < content.len and content[text_end] != '<') {
                    text_end += 1;
                }
                
                if (text_end > text_start) {
                    // Trim whitespace from text nodes
                    var trimmed_start = text_start;
                    var trimmed_end = text_end;
                    while (trimmed_start < trimmed_end and (content[trimmed_start] == ' ' or content[trimmed_start] == '\n' or content[trimmed_start] == '\t')) {
                        trimmed_start += 1;
                    }
                    while (trimmed_end > trimmed_start and (content[trimmed_end - 1] == ' ' or content[trimmed_end - 1] == '\n' or content[trimmed_end - 1] == '\t')) {
                        trimmed_end -= 1;
                    }
                    
                    if (trimmed_end > trimmed_start) {
                        // Create text node
                        const text_content = content[trimmed_start..trimmed_end];
                        const text_node = HtmlNode{
                            .tag_name = "", // Empty tag name for text nodes
                            .attributes = &.{},
                            .children = &.{},
                            .text_content = try self.allocator.dupe(u8, text_content),
                            .parent = null,
                            .depth = parent_depth + 1,
                        };
                        try children.append(text_node);
                    }
                }
                
                pos = text_end;
            }
        }
        
        return try children.toOwnedSlice();
    }
    
    /// Extract text content (text not in child nodes).
    fn extractTextContent(
        self: *DreamBrowserParser,
        content: []const u8,
        children: []const HtmlNode,
    ) ![]const u8 {
        _ = content; // For now, return empty - text is in child nodes
        _ = children;
        _ = self;
        return "";
    }
    
    /// Parse CSS string into rules.
    pub fn parseCss(
        self: *DreamBrowserParser,
        css: []const u8,
    ) ![]const CssRule {
        // Assert: CSS must be non-empty
        std.debug.assert(css.len > 0);
        
        // Simple CSS parser (subset of CSS3)
        // For now, parse basic structure: selector { property: value; }
        // TODO: Implement full CSS3 parser
        
        // Pre-allocate capacity (optimization: reduce reallocations)
        var rules = std.ArrayList(CssRule){ .items = &.{}, .capacity = 0 };
        defer rules.deinit(self.allocator);
        try rules.ensureTotalCapacity(self.allocator, @min(MAX_CSS_RULES, 50)); // Pre-allocate for common case
        
        // Find first rule
        var pos: usize = 0;
        while (pos < css.len) {
            // Skip whitespace
            while (pos < css.len and (css[pos] == ' ' or css[pos] == '\n' or css[pos] == '\t')) {
                pos += 1;
            }
            if (pos >= css.len) break;
            
            // Find selector
            const selector_start = pos;
            const selector_end = std.mem.indexOfScalar(u8, css[selector_start..], '{') orelse break;
            const selector = css[selector_start..selector_start + selector_end];
            
            // Find declarations
            const decl_start = selector_start + selector_end + 1;
            const decl_end = std.mem.indexOfScalar(u8, css[decl_start..], '}') orelse break;
            const decl_str = css[decl_start..decl_start + decl_end];
            
            // Parse declarations (simple: property: value;)
            // Pre-allocate capacity (optimization: reduce reallocations)
            var declarations = std.ArrayList(Declaration){ .items = &.{}, .capacity = 0 };
            defer declarations.deinit(self.allocator);
            try declarations.ensureTotalCapacity(self.allocator, 10); // Pre-allocate for common case
            
            var decl_pos: usize = 0;
            while (decl_pos < decl_str.len) {
                // Skip whitespace
                while (decl_pos < decl_str.len and (decl_str[decl_pos] == ' ' or decl_str[decl_pos] == '\n' or decl_str[decl_pos] == '\t')) {
                    decl_pos += 1;
                }
                if (decl_pos >= decl_str.len) break;
                
                // Find property
                const prop_start = decl_pos;
                const prop_end = std.mem.indexOfScalar(u8, decl_str[prop_start..], ':') orelse break;
                const property = decl_str[prop_start..prop_start + prop_end];
                
                // Find value
                const value_start = prop_start + prop_end + 1;
                const value_end = std.mem.indexOfScalar(u8, decl_str[value_start..], ';') orelse decl_str.len;
                const value = decl_str[value_start..value_start + value_end];
                
                try declarations.append(Declaration{
                    .property = try self.allocator.dupe(u8, property),
                    .value = try self.allocator.dupe(u8, value),
                });
                
                decl_pos = value_start + value_end + 1;
            }
            
            // Create CSS rule
            try rules.append(CssRule{
                .selector = try self.allocator.dupe(u8, selector),
                .declarations = try declarations.toOwnedSlice(),
            });
            
            // Assert: Rule count must be within bounds
            std.debug.assert(rules.items.len <= MAX_CSS_RULES);
            
            pos = decl_start + decl_end + 1;
        }
        
        return try rules.toOwnedSlice();
    }
    
    /// CSS selector type.
    const SelectorType = enum {
        tag, // "div", "span", etc.
        class, // ".class"
        id, // "#id"
        tag_class, // "div.class"
        tag_id, // "div#id"
        pseudo_class, // ":hover", "div:hover"
    };
    
    /// Parsed selector information.
    const ParsedSelector = struct {
        selector_type: SelectorType,
        tag_name: []const u8, // Empty if not specified
        class_name: []const u8, // Empty if not specified
        id_name: []const u8, // Empty if not specified
        pseudo_class: []const u8, // Empty if not specified
        specificity: u32, // Calculated specificity (higher = more specific)
    };
    
    /// Parse CSS selector into components.
    fn parseSelector(self: *DreamBrowserParser, selector: []const u8) !ParsedSelector {
        _ = self; // Not used but required for method signature
        
        // Trim whitespace from selector
        var trimmed = selector;
        while (trimmed.len > 0 and (trimmed[0] == ' ' or trimmed[0] == '\t')) {
            trimmed = trimmed[1..];
        }
        while (trimmed.len > 0 and (trimmed[trimmed.len - 1] == ' ' or trimmed[trimmed.len - 1] == '\t')) {
            trimmed = trimmed[0..trimmed.len - 1];
        }
        
        var result = ParsedSelector{
            .selector_type = .tag,
            .tag_name = "",
            .class_name = "",
            .id_name = "",
            .pseudo_class = "",
            .specificity = 0,
        };
        
        // Check for class selector (.class)
        const class_idx = std.mem.indexOfScalar(u8, trimmed, '.');
        // Check for ID selector (#id)
        const id_idx = std.mem.indexOfScalar(u8, trimmed, '#');
        // Check for pseudo-class selector (:pseudo)
        const pseudo_idx = std.mem.indexOfScalar(u8, trimmed, ':');
        
        // Parse tag name (before class/id/pseudo)
        var tag_end: u32 = trimmed.len;
        if (class_idx) |idx| {
            tag_end = @min(tag_end, idx);
        }
        if (id_idx) |idx| {
            tag_end = @min(tag_end, idx);
        }
        if (pseudo_idx) |idx| {
            tag_end = @min(tag_end, idx);
        }
        
        if (tag_end > 0) {
            result.tag_name = trimmed[0..tag_end];
        }
        
        // Parse class name
        if (class_idx) |idx| {
            const class_start = idx + 1;
            var class_end = class_start;
            while (class_end < trimmed.len and trimmed[class_end] != ' ' and trimmed[class_end] != '#' and trimmed[class_end] != ':' and trimmed[class_end] != '.') {
                class_end += 1;
            }
            result.class_name = trimmed[class_start..class_end];
        }
        
        // Parse ID name
        if (id_idx) |idx| {
            const id_start = idx + 1;
            var id_end = id_start;
            while (id_end < trimmed.len and trimmed[id_end] != ' ' and trimmed[id_end] != '.' and trimmed[id_end] != ':') {
                id_end += 1;
            }
            result.id_name = trimmed[id_start..id_end];
        }
        
        // Parse pseudo-class
        if (pseudo_idx) |idx| {
            const pseudo_start = idx + 1;
            var pseudo_end = pseudo_start;
            while (pseudo_end < trimmed.len and trimmed[pseudo_end] != ' ' and trimmed[pseudo_end] != '.' and trimmed[pseudo_end] != '#') {
                pseudo_end += 1;
            }
            result.pseudo_class = trimmed[pseudo_start..pseudo_end];
        }
        
        // Determine selector type
        if (result.class_name.len > 0 and result.id_name.len > 0) {
            result.selector_type = if (result.tag_name.len > 0) .tag_class else .class;
            // Both class and ID - use tag_class for now
        } else if (result.id_name.len > 0) {
            result.selector_type = if (result.tag_name.len > 0) .tag_id else .id;
        } else if (result.class_name.len > 0) {
            result.selector_type = if (result.tag_name.len > 0) .tag_class else .class;
        } else if (result.pseudo_class.len > 0) {
            result.selector_type = .pseudo_class;
        } else {
            result.selector_type = .tag;
        }
        
        // Calculate specificity: (id_count * 100) + (class_count * 10) + (tag_count * 1)
        var specificity: u32 = 0;
        if (result.id_name.len > 0) {
            specificity += 100;
        }
        if (result.class_name.len > 0) {
            specificity += 10;
        }
        if (result.tag_name.len > 0) {
            specificity += 1;
        }
        if (result.pseudo_class.len > 0) {
            specificity += 10; // Pseudo-class counts as class
        }
        result.specificity = specificity;
        
        return result;
    }
    
    /// Check if selector matches HTML node.
    fn selectorMatches(self: *DreamBrowserParser, parsed: ParsedSelector, node: *const HtmlNode) bool {
        _ = self; // Not used but required for method signature
        
        // Match tag name (if specified)
        if (parsed.tag_name.len > 0) {
            if (!std.mem.eql(u8, parsed.tag_name, node.tag_name)) {
                return false;
            }
        }
        
        // Match class (if specified)
        if (parsed.class_name.len > 0) {
            var found_class = false;
            for (node.attributes) |attr| {
                if (std.mem.eql(u8, attr.name, "class")) {
                    // Check if class value contains the class name
                    if (std.mem.indexOf(u8, attr.value, parsed.class_name)) |_| {
                        found_class = true;
                        break;
                    }
                }
            }
            if (!found_class) {
                return false;
            }
        }
        
        // Match ID (if specified)
        if (parsed.id_name.len > 0) {
            var found_id = false;
            for (node.attributes) |attr| {
                if (std.mem.eql(u8, attr.name, "id")) {
                    if (std.mem.eql(u8, attr.value, parsed.id_name)) {
                        found_id = true;
                        break;
                    }
                }
            }
            if (!found_id) {
                return false;
            }
        }
        
        // Pseudo-class matching (simplified - always matches for now)
        // TODO: Implement actual pseudo-class state checking
        if (parsed.pseudo_class.len > 0) {
            // For now, always match pseudo-classes (hover, focus, etc.)
            // In a real browser, this would check element state
        }
        
        return true;
    }
    
    /// Compute styles for HTML node (cascade, specificity).
    pub fn computeStyles(
        self: *DreamBrowserParser,
        node: *const HtmlNode,
        css_rules: []const CssRule,
    ) ![]const Declaration {
        // Assert: Node and CSS rules must be valid
        std.debug.assert(node.tag_name.len > 0);
        
        // Parse all selectors and match against node
        var matched_rules = std.ArrayList(struct {
            rule: *const CssRule,
            specificity: u32,
        }){ .items = &.{}, .capacity = 0 };
        defer matched_rules.deinit(self.allocator);
        try matched_rules.ensureTotalCapacity(self.allocator, @min(css_rules.len, 100));
        
        // Match CSS rules to node
        for (css_rules) |*rule| {
            const parsed = try self.parseSelector(rule.selector);
            if (self.selectorMatches(parsed, node)) {
                try matched_rules.append(.{
                    .rule = rule,
                    .specificity = parsed.specificity,
                });
            }
        }
        
        // Sort by specificity (higher specificity first)
        // Simple bubble sort (for small arrays, this is fine)
        var sort_i: u32 = 0;
        while (sort_i < matched_rules.items.len) {
            var sort_j: u32 = 0;
            while (sort_j < matched_rules.items.len - sort_i - 1) {
                if (matched_rules.items[sort_j].specificity < matched_rules.items[sort_j + 1].specificity) {
                    const temp = matched_rules.items[sort_j];
                    matched_rules.items[sort_j] = matched_rules.items[sort_j + 1];
                    matched_rules.items[sort_j + 1] = temp;
                }
                sort_j += 1;
            }
            sort_i += 1;
        }
        
        // Apply styles in cascade order (later rules override earlier ones)
        var styles = std.ArrayList(Declaration).init(self.allocator);
        defer styles.deinit();
        try styles.ensureTotalCapacity(self.allocator, 50);
        
        // Apply declarations from matched rules (in specificity order)
        for (matched_rules.items) |matched| {
            try styles.appendSlice(matched.rule.declarations);
        }
        
        // Remove duplicate properties (keep last one - cascade)
        // Process in order, keeping last declaration for each property
        var final_styles = std.ArrayList(Declaration).init(self.allocator);
        defer final_styles.deinit();
        try final_styles.ensureTotalCapacity(self.allocator, styles.items.len);
        
        // Track which properties we've seen (simple linear search for small sets)
        // Process styles in order, but only keep the last occurrence of each property
        var seen_props = std.ArrayList([]const u8).init(self.allocator);
        defer seen_props.deinit();
        try seen_props.ensureTotalCapacity(self.allocator, styles.items.len);
        
        // Process in reverse order (so last one wins)
        var idx: i32 = @intCast(styles.items.len - 1);
        while (idx >= 0) {
            const decl = styles.items[@intCast(idx)];
            
            // Check if we've already seen this property
            var found = false;
            for (seen_props.items) |seen_prop| {
                if (std.mem.eql(u8, seen_prop, decl.property)) {
                    found = true;
                    break;
                }
            }
            
            if (!found) {
                try final_styles.append(decl);
                try seen_props.append(decl.property);
            }
            
            idx -= 1;
        }
        
        // Reverse to get correct order (most specific first, but last property wins)
        var reversed = std.ArrayList(Declaration).init(self.allocator);
        defer reversed.deinit();
        try reversed.ensureTotalCapacity(self.allocator, final_styles.items.len);
        
        idx = @intCast(final_styles.items.len - 1);
        while (idx >= 0) {
            try reversed.append(final_styles.items[@intCast(idx)]);
            idx -= 1;
        }
        
        return try reversed.toOwnedSlice();
    }
    
    /// Convert HTML node to BrowserDagIntegration.DomNode (for DAG integration).
    pub fn toDomNode(
        self: *DreamBrowserParser,
        html_node: *const HtmlNode,
    ) !BrowserDagIntegration.DomNode {
        // Assert: HTML node must be valid
        std.debug.assert(html_node.tag_name.len > 0);
        
        // Convert attributes
        var attributes = std.ArrayList(BrowserDagIntegration.DomNode.Attribute).init(self.allocator);
        defer attributes.deinit();
        
        for (html_node.attributes) |attr| {
            try attributes.append(BrowserDagIntegration.DomNode.Attribute{
                .name = attr.name,
                .value = attr.value,
            });
        }
        
        // Convert children (recursive)
        var children = std.ArrayList(BrowserDagIntegration.DomNode).init(self.allocator);
        defer children.deinit();
        
        for (html_node.children) |child| {
            const child_dom = try self.toDomNode(&child);
            try children.append(child_dom);
        }
        
        return BrowserDagIntegration.DomNode{
            .tag_name = html_node.tag_name,
            .attributes = try attributes.toOwnedSlice(),
            .children = try children.toOwnedSlice(),
            .text_content = html_node.text_content,
            .parent_id = null, // Will be set by DAG integration
        };
    }
};

test "browser parser initialization" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    
    var parser = DreamBrowserParser.init(arena.allocator());
    defer parser.deinit();
    
    // Assert: Parser initialized (check via usage)
    _ = parser.allocator;
}

test "browser parser parse html" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    
    var parser = DreamBrowserParser.init(arena.allocator());
    defer parser.deinit();
    
    const html = "<div>Hello, World!</div>";
    const node = try parser.parseHtml(html);
    defer {
        parser.allocator.free(node.tag_name);
        parser.allocator.free(node.text_content);
        for (node.attributes) |attr| {
            parser.allocator.free(attr.name);
            parser.allocator.free(attr.value);
        }
        parser.allocator.free(node.attributes);
    }
    
    // Assert: Node parsed correctly
    try std.testing.expect(std.mem.eql(u8, node.tag_name, "div"));
    try std.testing.expect(std.mem.eql(u8, node.text_content, "Hello, World!"));
}

test "browser parser parse css" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    
    var parser = DreamBrowserParser.init(arena.allocator());
    defer parser.deinit();
    
    const css = "div { color: red; background: blue; }";
    const rules = try parser.parseCss(css);
    defer {
        for (rules) |rule| {
            parser.allocator.free(rule.selector);
            for (rule.declarations) |decl| {
                parser.allocator.free(decl.property);
                parser.allocator.free(decl.value);
            }
            parser.allocator.free(rule.declarations);
        }
        parser.allocator.free(rules);
    }
    
    // Assert: Rules parsed correctly
    try std.testing.expect(rules.len == 1);
    try std.testing.expect(std.mem.eql(u8, rules[0].selector, "div"));
    try std.testing.expect(rules[0].declarations.len == 2);
}

