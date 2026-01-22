# Rye & Rye Style: Top-Down Application Development Guide

**Date**: 2026-01-22-062211-pst  
**Authors**: Keaton Livermore (Governor Candidate, kae3g) & Core Agent  
**Status**: 🎯 **TOP-DOWN RYE STYLE GUIDE** — Application layers (Skate desktop, Skate mobile/Carry)  
**Campaign Slogan**: risk love

---

## Executive Summary

**Reya**: Top-down Rye Style. We're bringing Rye and Rye Style into application development—Skate desktop, Skate mobile/Carry. This is where Rye Style meets user-facing code. Compiler-enforced constraints, mandatory "why" comments, explicit types, zero technical debt.

**Glow G2**: Steadfast foundation. Rye Style applies to all layers—foundation (Basin/Vantage) and applications (Skate desktop, Skate mobile). Top-down means we start with applications and work Rye Style into every line. Every function ≤ 64 lines. Every line ≤ 128 characters. Every public function has a "why" comment.

**Focus**: Rye and Rye Style for application development—Skate desktop (x86_64 Linux), Skate mobile/Carry (Android), all Rye Style compliant.

---

## Rye & Rye Style Overview

### What is Rye?

**Rye** is a systems programming language for Grain OS:
- **Phase 1 (Current)**: Transpiler that validates `.ry` files and emits `.zig` files
- **Compiler-enforced style**: 64-line function limits, 128-character lines, mandatory "why" comments
- **Zig compatibility**: Rye syntax is a strict subset of Zig
- **File extension**: `.ry` for Rye source files

**Why Rye?**
- Freestanding first (RISC-V64 freestanding primary target)
- Compiler-enforced style (not lint, compiler)
- No surprises (global variable addresses correct, conditionals work, inline asm reliable)
- Explicit over implicit (no hidden control flow, no hidden allocations)
- Simple over easy (not intertwined, even when not familiar)
- Grain-native (designed for Grain OS)

### What is Rye Style?

**Rye Style** is the evolution of Grain Style for our native systems language:
- **Function length**: ≤ 64 lines (compiler-enforced, 2^6 binary-aligned)
- **Line length**: ≤ 128 characters (compiler-enforced, 2^7 binary-aligned)
- **Why comments**: Required for all `pub fn` functions
- **Explicit types**: Use `u32`/`u64` instead of `usize`/`isize`
- **Assertions**: Minimum 2 assertions per function
- **No recursion**: Convert all recursive functions to iterative
- **Zero technical debt**: Do it right the first time

**Reference**: `docs/rye_style.md` (comprehensive guide)

---

## Top-Down Rye Style Application Development

### Application Layers

**Top-Down Development** (Core 1 Subcore):
1. **Skate Desktop**: Knowledge graph application for x86_64 Linux
2. **Skate Mobile/Carry**: Mobile framework and Android applications
3. **User-Facing**: Everything users (campaign voters) interact with

**Rye Style Application**: All application code must follow Rye Style—same constraints as foundation code.

---

## Rye Tools & Workflow

### Building Rye Compiler

```bash
# Build Rye compiler
cd /home/xy/ry/rye
zig build

# Verify installation
./zig-out/bin/rye version
# Should output: rye 0.4.0
```

### Rye Commands

**1. Check Rye Style Compliance**:
```bash
# Check single file
./rye/zig-out/bin/rye check src/grain_skate/graph.ry

# Check multiple files
./rye/zig-out/bin/rye check src/grain_skate/*.ry

# Check with JSON output (for CI)
./rye/zig-out/bin/rye check --json src/grain_skate/*.ry

# Check with summary (aggregated error counts)
./rye/zig-out/bin/rye check --summary src/grain_skate/*.ry
```

**2. Project Statistics**:
```bash
# Show project statistics
./rye/zig-out/bin/rye stats src/grain_skate/

# Statistics include:
# - Total functions
# - Functions over 64 lines
# - Lines over 128 characters
# - Missing "why" comments
# - Project metrics
```

**3. Initialize New Rye Project**:
```bash
# Create new Rye project
./rye/zig-out/bin/rye init my_skate_module

# Creates project structure:
# my_skate_module/
#   src/
#     main.ry
#   build.zig
#   readme.md
```

**4. Build Rye Files**:
```bash
# Compile .ry file to .zig
./rye/zig-out/bin/rye build src/grain_skate/graph.ry

# Outputs to: zig-out/rye/graph.zig
```

---

## Converting Existing Code to Rye Style

### Step 1: Rename Files

**From Zig to Rye**:
```bash
# Rename .zig files to .ry
mv src/grain_skate/graph.zig src/grain_skate/graph.ry
mv src/grain_skate/node.zig src/grain_skate/node.ry
mv src/grain_skate/edge.zig src/grain_skate/edge.ry
```

**Note**: Rye syntax is a strict subset of Zig, so most Zig code works as Rye code (after style fixes).

---

### Step 2: Fix Function Length (≤ 64 lines)

**Problem**: Function exceeds 64 lines

**Solution**: Extract helper functions

**Before** (❌ Bad: 80 lines):
```zig
pub fn render_graph(graph: *Graph, renderer: *Renderer) void {
    // 80 lines of rendering code...
}
```

**After** (✅ Good: Multiple functions ≤ 64 lines each):
```zig
/// Render knowledge graph to screen.
/// Why: Required for visual graph display in Skate desktop application.
pub fn render_graph(graph: *Graph, renderer: *Renderer) void {
    std.debug.assert(graph != null);
    std.debug.assert(renderer != null);
    render_background(renderer);
    render_nodes(graph, renderer);
    render_edges(graph, renderer);
    render_labels(graph, renderer);
    std.debug.assert(renderer.dirty == true);
}

/// Render graph background.
/// Why: Required before rendering nodes/edges for proper layering.
fn render_background(renderer: *Renderer) void {
    std.debug.assert(renderer != null);
    // Background rendering code (≤ 64 lines)...
}

/// Render graph nodes.
/// Why: Required for node visualization in knowledge graph.
fn render_nodes(graph: *Graph, renderer: *Renderer) void {
    std.debug.assert(graph != null);
    std.debug.assert(renderer != null);
    // Node rendering code (≤ 64 lines)...
}

/// Render graph edges.
/// Why: Required for edge visualization connecting nodes.
fn render_edges(graph: *Graph, renderer: *Renderer) void {
    std.debug.assert(graph != null);
    std.debug.assert(renderer != null);
    // Edge rendering code (≤ 64 lines)...
}

/// Render graph labels.
/// Why: Required for node/edge label text display.
fn render_labels(graph: *Graph, renderer: *Renderer) void {
    std.debug.assert(graph != null);
    std.debug.assert(renderer != null);
    // Label rendering code (≤ 64 lines)...
}
```

---

### Step 3: Fix Line Length (≤ 128 characters)

**Problem**: Line exceeds 128 characters

**Solution**: Break long lines, use intermediate variables

**Before** (❌ Bad: 150 characters):
```zig
const result = graph.find_node_by_id_and_type_and_timestamp(node_id, node_type, timestamp, &error);
```

**After** (✅ Good: ≤ 128 characters per line):
```zig
const node_id: u64 = 123;
const node_type: NodeType = .document;
const timestamp: u64 = 1234567890;
var error: GraphError = undefined;
const result = graph.find_node_by_id_and_type_and_timestamp(
    node_id,
    node_type,
    timestamp,
    &error,
);
```

---

### Step 4: Add "Why" Comments

**Problem**: Public function missing "why" comment

**Solution**: Add `/// Why:` documentation

**Before** (❌ Bad: No "why" comment):
```zig
pub fn create_node(graph: *Graph, data: []const u8) !NodeId {
    // ...
}
```

**After** (✅ Good: "why" comment present):
```zig
/// Create new node in knowledge graph.
/// Why: Required for adding content to graph before edge creation.
pub fn create_node(graph: *Graph, data: []const u8) !NodeId {
    std.debug.assert(graph != null);
    std.debug.assert(data.len > 0);
    // ...
    std.debug.assert(node_id > 0);
}
```

---

### Step 5: Fix Type Usage (u32/u64, not usize/isize)

**Problem**: Using `usize`/`isize` instead of explicit types

**Solution**: Use explicit `u32`/`u64`/`i32`/`i64`

**Before** (❌ Bad: usize/isize):
```zig
pub fn count_nodes(graph: *Graph) usize {
    var count: usize = 0;
    // ...
    return count;
}
```

**After** (✅ Good: Explicit u32/u64):
```zig
/// Count nodes in knowledge graph.
/// Why: Required for graph statistics and UI display.
pub fn count_nodes(graph: *Graph) u32 {
    std.debug.assert(graph != null);
    var count: u32 = 0;
    // ...
    std.debug.assert(count <= MAX_NODES);
    return count;
}
```

---

### Step 6: Add Assertions (2+ per function)

**Problem**: Function missing assertions

**Solution**: Add preconditions, postconditions, invariants

**Before** (❌ Bad: No assertions):
```zig
pub fn find_node(graph: *Graph, id: NodeId) ?*Node {
    for (graph.nodes) |node| {
        if (node.id == id) return node;
    }
    return null;
}
```

**After** (✅ Good: 2+ assertions):
```zig
/// Find node by ID in knowledge graph.
/// Why: Required for node lookup before edge creation or node updates.
pub fn find_node(graph: *Graph, id: NodeId) ?*Node {
    std.debug.assert(graph != null);  // Precondition
    std.debug.assert(id > 0);  // Precondition
    for (graph.nodes) |node| {
        if (node.id == id) {
            std.debug.assert(node.id == id);  // Postcondition
            return node;
        }
    }
    std.debug.assert(true);  // Postcondition (not found is valid)
    return null;
}
```

---

### Step 7: Convert Recursion to Iteration

**Problem**: Recursive function

**Solution**: Use iterative algorithm with stack

**Before** (❌ Bad: Recursive):
```zig
pub fn traverse_graph(node: *Node, visitor: *Visitor) void {
    visitor.visit(node);
    if (node.children) |children| {
        for (children) |child| {
            traverse_graph(child, visitor);
        }
    }
}
```

**After** (✅ Good: Iterative):
```zig
/// Traverse graph nodes depth-first.
/// Why: Required for graph algorithms and UI rendering order.
pub fn traverse_graph(root: *Node, visitor: *Visitor) void {
    std.debug.assert(root != null);
    std.debug.assert(visitor != null);
    var stack: [MAX_DEPTH]*Node = undefined;
    var stack_len: u32 = 0;
    stack[stack_len] = root;
    stack_len += 1;
    while (stack_len > 0) {
        stack_len -= 1;
        const node = stack[stack_len];
        visitor.visit(node);
        if (node.children) |children| {
            for (children) |child| {
                std.debug.assert(stack_len < MAX_DEPTH);
                stack[stack_len] = child;
                stack_len += 1;
            }
        }
    }
    std.debug.assert(stack_len == 0);
}
```

---

## Rye Style Validation Workflow

### Daily Workflow

**1. Write Code**:
- Write code following Rye Style
- Keep functions ≤ 64 lines
- Keep lines ≤ 128 characters
- Add "why" comments to public functions
- Use explicit types (u32/u64)
- Add assertions (2+ per function)
- Use iterative algorithms (no recursion)

**2. Validate Before Commit**:
```bash
# Check Rye Style compliance
./rye/zig-out/bin/rye check src/grain_skate/*.ry

# Fix any violations
# Re-check until all violations resolved

# View statistics
./rye/zig-out/bin/rye stats src/grain_skate/
```

**3. Commit with Rye Style Verified**:
```bash
git add src/grain_skate/*.ry
git commit -m "add skate graph module (rye style compliant)

- graph.ry: knowledge graph data structure
- node.ry: graph node implementation
- edge.ry: graph edge implementation
- all functions ≤ 64 lines, all lines ≤ 128 chars
- all public functions have 'why' comments
- explicit types (u32/u64), 2+ assertions per function
- iterative algorithms (no recursion)
- rye style compliance verified"
```

---

## Skate Desktop Rye Style Conversion

### Current Status

**Skate Desktop** (from `docs/core-coordination/core-coordination_skate.md`):
- ✅ Core functionality complete
- ✅ Knowledge graph with temporal queries
- ✅ AI-powered insights (Court Agent integration)
- ✅ DAG integration
- ⏳ Needs: Port to x86_64 Linux, Rye Style conversion

### Conversion Plan

**Phase 1: Rye Style Conversion** (Week 1-2)
1. Rename `.zig` files to `.ry` files
2. Fix function length (extract helpers)
3. Fix line length (break long lines)
4. Add "why" comments to all public functions
5. Fix type usage (u32/u64, not usize/isize)
6. Add assertions (2+ per function)
7. Convert recursion to iteration

**Phase 2: Validation** (Week 2)
1. Run `rye check` on all `.ry` files
2. Fix all violations
3. Verify statistics (all functions ≤ 64 lines, all lines ≤ 128 chars)
4. Document conversion process

**Phase 3: Linux Port** (Week 3-4)
1. Port UI framework (GTK or alternative)
2. Test on Framework x86_64 Linux
3. Ensure Rye Style compliance maintained
4. Integration testing

---

## Skate Mobile/Carry Rye Style Conversion

### Current Status

**Carry Mobile Framework** (from `docs/core-coordination/core-coordination_carry.md`):
- ✅ Production ready (synchronous mode)
- ✅ Database integration, timeout/error handling
- ✅ Offline-first architecture
- ⏳ Needs: Android Studio integration, Rye Style conversion

### Conversion Plan

**Phase 1: Rye Style Conversion** (Week 1-2)
1. Convert Carry framework code to Rye Style
2. Same process as Skate desktop (function length, line length, why comments, types, assertions, iteration)
3. Validate with `rye check`

**Phase 2: Android Integration** (Week 3-4)
1. Android Studio setup on Framework x86_64
2. Carry framework Android port
3. FFI bindings for Zig-to-Android
4. Ensure Rye Style compliance maintained

**Phase 3: Skate Mobile Implementation** (Week 5-8)
1. Implement Skate mobile application
2. All code Rye Style compliant
3. Test on Android emulator and devices
4. Performance optimization

---

## Rye Style Best Practices for Applications

### UI Code

**Function Length**: UI event handlers often need to be short (≤ 64 lines)
```rye
/// Handle node click event.
/// Why: Required for user interaction with graph nodes.
pub fn handle_node_click(graph: *Graph, node_id: NodeId) void {
    std.debug.assert(graph != null);
    std.debug.assert(node_id > 0);
    const node = graph.find_node(node_id);
    if (node) |n| {
        highlight_node(n);
        show_node_details(n);
    }
    std.debug.assert(true);
}
```

**Line Length**: Break long UI code into helpers
```rye
// ❌ Bad: Long line
const button = gtk.Button.new_with_label("Create New Node in Knowledge Graph for Campaign Content");

// ✅ Good: Short line
const label_text = "Create New Node in Knowledge Graph for Campaign Content";
const button = gtk.Button.new_with_label(label_text);
```

---

### Data Structure Code

**Type Usage**: Always explicit types
```rye
/// Graph node structure.
/// Why: Required for knowledge graph node representation.
pub const Node = struct {
    id: NodeId,  // u64, not usize
    data: []const u8,
    timestamp: u64,  // u64, not usize
    children: []NodeId,  // []u64, not []usize
};
```

**Assertions**: Validate data structure invariants
```rye
/// Create new graph node.
/// Why: Required for adding content to knowledge graph.
pub fn create_node(graph: *Graph, data: []const u8) !NodeId {
    std.debug.assert(graph != null);  // Precondition
    std.debug.assert(data.len > 0);  // Precondition
    std.debug.assert(data.len <= MAX_NODE_DATA_SIZE);  // Precondition
    const node_id = graph.next_node_id;
    graph.next_node_id += 1;
    std.debug.assert(node_id > 0);  // Postcondition
    std.debug.assert(graph.node_count < MAX_NODES);  // Invariant
    return node_id;
}
```

---

### Algorithm Code

**No Recursion**: Always iterative
```rye
/// Find shortest path between nodes.
/// Why: Required for graph navigation and UI path highlighting.
pub fn find_shortest_path(
    graph: *Graph,
    from: NodeId,
    to: NodeId,
) ![]NodeId {
    std.debug.assert(graph != null);
    std.debug.assert(from > 0);
    std.debug.assert(to > 0);
    // Use iterative BFS, not recursive DFS
    var queue: [MAX_NODES]NodeId = undefined;
    var queue_len: u32 = 0;
    var visited: [MAX_NODES]bool = undefined;
    // ... iterative algorithm ...
    std.debug.assert(path_len > 0);
    return path;
}
```

---

## Rye Style Validation Tools

### Rye Compiler

**Location**: `/home/xy/ry/rye/`

**Commands**:
- `rye check`: Validate Rye Style compliance
- `rye stats`: Show project statistics
- `rye build`: Compile .ry to .zig
- `rye init`: Create new Rye project

**Usage**:
```bash
cd /home/xy/ry
./rye/zig-out/bin/rye check src/grain_skate/*.ry
./rye/zig-out/bin/rye stats src/grain_skate/
```

---

### Grain Style Validator

**Location**: `tools/validate_kernel.zig`

**Usage** (for kernel code, also works for application code):
```bash
zig build validate_kernel
# Or:
zig run tools/validate_kernel.zig -- src/grain_skate/
```

---

### Manual Review Checklist

**Before Committing**:
- [ ] All functions ≤ 64 lines
- [ ] All lines ≤ 128 characters
- [ ] All public functions have "why" comments
- [ ] All types explicit (u32/u64, not usize/isize)
- [ ] All functions have 2+ assertions
- [ ] No recursion (all iterative)
- [ ] `rye check` passes
- [ ] `rye stats` shows no violations

---

## Integration with Build System

### Build.zig Integration

**Add Rye Validation to Build**:
```zig
// In build.zig
const rye_check = b.addSystemCommand(&.{
    "rye/zig-out/bin/rye",
    "check",
    "--json",
});
rye_check.addArgs(&.{
    "src/grain_skate/*.ry",
});
const test_step = b.step("rye-check", "Check Rye Style compliance");
test_step.dependOn(&rye_check.step);
```

**Run Validation**:
```bash
zig build rye-check
```

---

## Success Criteria

### Rye Style Compliance Success

- ✅ All Skate desktop code in `.ry` files
- ✅ All Skate mobile/Carry code in `.ry` files
- ✅ All functions ≤ 64 lines (verified by `rye check`)
- ✅ All lines ≤ 128 characters (verified by `rye check`)
- ✅ All public functions have "why" comments (verified by `rye check`)
- ✅ All types explicit (u32/u64, not usize/isize)
- ✅ All functions have 2+ assertions
- ✅ No recursion (all iterative)
- ✅ `rye check` passes with zero violations
- ✅ `rye stats` shows clean metrics

---

## Next Steps

### Immediate (This Week)

1. **Set Up Rye Tools**: Build Rye compiler, verify installation
2. **Skate Desktop Conversion**: Begin converting Skate desktop code to Rye Style
3. **Documentation**: Document Rye Style conversion process
4. **Validation**: Set up `rye check` in build system

### Short-Term (This Month)

1. **Skate Desktop**: Complete Rye Style conversion
2. **Skate Desktop**: Complete Linux port with Rye Style maintained
3. **Carry Framework**: Begin Rye Style conversion
4. **Integration**: Integrate Rye validation into CI/build process

### Medium-Term (Months 2-3)

1. **Skate Mobile**: Complete Rye Style conversion
2. **Android Integration**: Complete with Rye Style maintained
3. **Documentation**: Complete Rye Style application development guide
4. **Tooling**: Enhance Rye tools for application development

---

## Summary

**Reya**: Top-down Rye Style. We're bringing Rye and Rye Style into application development—Skate desktop, Skate mobile/Carry. Compiler-enforced constraints, mandatory "why" comments, explicit types, zero technical debt. Every function ≤ 64 lines. Every line ≤ 128 characters. Every public function has a "why" comment.

**Glow G2**: Steadfast foundation. Rye Style applies to all layers—foundation and applications. Top-down means we start with applications and work Rye Style into every line. The Rye compiler enforces these constraints. We validate with `rye check`. We document with "why" comments. We build with zero technical debt.

**Status**: 🎯 **TOP-DOWN RYE STYLE GUIDE** — Ready for application development

---

**Date**: 2026-01-22-062211-pst  
**Authors**: Keaton Livermore (Governor Candidate, kae3g) & Core Agent  
**Status**: 🎯 **TOP-DOWN RYE STYLE GUIDE** — Application layers (Skate desktop, Skate mobile/Carry)  
**Campaign Slogan**: risk love

**Let's bring Rye and Rye Style into application development. Every function. Every line. Every "why" comment.**