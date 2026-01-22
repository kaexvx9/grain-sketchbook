# Rye Style Compiler Enforcement Plan

**Date**: 2026-01-22-062923-pst  
**Status**: 🆕 **ENFORCEMENT PLAN** — Integrate Rye Style constraints into compiler  
**Reference**: `docs/rye_style.md`, Phase 1 validator in `rye/src/validator.zig`

---

## Overview

Rye Style constraints will be enforced at the compiler level (not just linting). This ensures all Rye code follows the toroidal bounded programming model for safety and performance.

---

## Constraints to Enforce

### 1. Function Length: ≤ 64 Lines

**Current**: Phase 1 validator checks this  
**Future**: Compiler error (not warning) if exceeded

**Implementation**:
```zig
// In src/frontend/validator.ry (or equivalent)

fn validateFunctionLength(func: Function, max_lines: u32) !void {
    const line_count = countLines(func);
    if (line_count > max_lines) {
        return error.FunctionTooLong;
        // Error message: "Function '{name}' is {line_count} lines, maximum is {max_lines}"
    }
}
```

**Error Message**:
```
error: Function 'process_scheduler' is 68 lines, maximum is 64
  --> src/kernel/scheduler.ry:42:1
   |
42 | pub fn process_scheduler(self: *Scheduler) void {
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   |
   = help: Split function into smaller functions (extract helpers)
```

---

### 2. Line Length: ≤ 128 Characters

**Current**: Phase 1 validator checks this  
**Future**: Compiler error (not warning) if exceeded

**Implementation**:
```zig
// In src/frontend/validator.ry

fn validateLineLength(file: File, max_chars: u32) !void {
    var line_num: u32 = 1;
    for (file.lines) |line| {
        if (line.len > max_chars) {
            return error.LineTooLong;
            // Error message: "Line {line_num} is {line.len} characters, maximum is {max_chars}"
        }
        line_num += 1;
    }
}
```

**Error Message**:
```
error: Line 45 is 135 characters, maximum is 128
  --> src/kernel/scheduler.ry:45:1
   |
45 |     const next_process = self.find_next_runnable_process_in_queue_with_priority_and_timeout();
   |     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   |
   = help: Break line into multiple lines or shorten variable names
```

---

### 3. Why Comments: Required for `pub fn`

**Current**: Phase 1 validator checks this  
**Future**: Compiler error (not warning) if missing

**Implementation**:
```zig
// In src/frontend/validator.ry

fn validateWhyComment(func: Function) !void {
    if (func.is_public and !func.has_why_comment) {
        return error.MissingWhyComment;
        // Error message: "Public function '{name}' must have '/// Why:' comment"
    }
}
```

**Error Message**:
```
error: Public function 'process_scheduler' must have '/// Why:' comment
  --> src/kernel/scheduler.ry:42:1
   |
42 | pub fn process_scheduler(self: *Scheduler) void {
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   |
   = help: Add '/// Why: [explanation]' comment before function
```

**Why Comment Format**:
```rye
/// Why: Schedule next runnable process using toroidal round-robin.
pub fn schedule_next(self: *Scheduler) ?u32 {
    // ...
}
```

---

### 4. Explicit Types: No `usize`/`isize` Inference

**Current**: Style guide recommends explicit types  
**Future**: Compiler error on `usize`/`isize` (must use `u32`/`u64`/`i32`/`i64`)

**Implementation**:
```zig
// In src/frontend/type_checker.ry

fn validateExplicitTypes(expr: Expression) !void {
    if (expr.type == .usize or expr.type == .isize) {
        return error.ImplicitType;
        // Error message: "Type 'usize' not allowed, use explicit 'u32' or 'u64'"
    }
}
```

**Error Message**:
```
error: Type 'usize' not allowed, use explicit 'u32' or 'u64'
  --> src/kernel/scheduler.ry:45:1
   |
45 |     const count: usize = self.process_count;
   |                ^^^^^^
   |
   = help: Use 'u32' for 32-bit values, 'u64' for 64-bit values
```

---

### 5. Assertions: Minimum 2 per Function

**Current**: Style guide recommends 2+ assertions  
**Future**: Compiler warning (can be error with flag)

**Implementation**:
```zig
// In src/frontend/validator.ry

fn validateAssertions(func: Function) !void {
    const assertion_count = countAssertions(func);
    if (assertion_count < 2) {
        return error.InsufficientAssertions;
        // Warning: "Function '{name}' has {count} assertion(s), minimum is 2"
    }
}
```

**Warning Message**:
```
warning: Function 'process_scheduler' has 1 assertion, minimum is 2
  --> src/kernel/scheduler.ry:42:1
   |
42 | pub fn process_scheduler(self: *Scheduler) void {
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   |
   = help: Add assertions for preconditions and postconditions
```

---

### 6. No Recursion: Iterative Only

**Current**: Style guide prohibits recursion  
**Future**: Compiler error on recursive functions

**Implementation**:
```zig
// In src/frontend/call_graph.ry

fn validateNoRecursion(func: Function, call_graph: CallGraph) !void {
    if (call_graph.isRecursive(func)) {
        return error.RecursiveFunction;
        // Error message: "Function '{name}' is recursive, convert to iterative"
    }
}
```

**Error Message**:
```
error: Function 'traverse_tree' is recursive, convert to iterative
  --> src/kernel/tree.ry:42:1
   |
42 | pub fn traverse_tree(node: *Node) void {
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   |
   = help: Use iterative algorithm with stack (see docs/rye_style.md)
```

---

## Integration with Compiler

### Phase 1: Validator Integration (Current)

**Location**: `rye/src/validator.zig` (Phase 1 transpiler)  
**Status**: ✅ Implemented (checks constraints, emits errors)

### Phase 2: Compiler Integration (Future)

**Location**: `src/frontend/validator.ry` (Rye compiler)  
**Status**: ⏳ To be implemented

**Integration Points**:
1. **Parser**: Check line length during tokenization
2. **AST Validation**: Check function length, why comments
3. **Type Checker**: Check explicit types, no recursion
4. **Codegen**: Verify assertions present (optional)

---

## Error vs Warning

### Compiler Errors (Must Fix)

- Function length > 64 lines
- Line length > 128 characters
- Missing "why" comment on `pub fn`
- Using `usize`/`isize` (must use explicit types)
- Recursive functions

### Compiler Warnings (Should Fix)

- Insufficient assertions (< 2 per function)
- Can be promoted to errors with `--strict` flag

---

## Command-Line Options

```bash
# Strict mode (warnings become errors)
rye build --strict src/main.ry

# Relaxed mode (warnings only)
rye build --relaxed src/main.ry

# Default: errors for constraints, warnings for assertions
rye build src/main.ry
```

---

## Migration from Phase 1

**Current Phase 1**:
```bash
rye check src/*.ry  # Validates constraints
rye build src/main.ry  # Transpiles to Zig
```

**Future Phase 2**:
```bash
rye build src/main.ry  # Compiles directly, enforces constraints
rye check src/*.ry  # Still available for linting
```

**Backward Compatibility**: Phase 1 validator logic will be integrated into Phase 2 compiler.

---

## Test Suite

### Constraint Violation Tests

```
rye/test/rye_style/
├── function_too_long.ry          # Should error: > 64 lines
├── line_too_long.ry              # Should error: > 128 chars
├── missing_why_comment.ry        # Should error: pub fn without why
├── implicit_type.ry              # Should error: usize/isize
├── recursive_function.ry         # Should error: recursion
└── insufficient_assertions.ry   # Should warn: < 2 assertions
```

### Valid Code Tests

```
rye/test/rye_style/
├── valid_function.ry             # Should compile: all constraints met
├── valid_toroidal.ry             # Should compile: uses toroidal types
└── valid_garden.ry                # Should compile: uses garden allocation
```

---

## Performance Considerations

**Validation Overhead**:
- Line length: O(n) where n = file lines (fast)
- Function length: O(m) where m = functions (fast)
- Why comments: O(m) where m = public functions (fast)
- Type checking: Already done (no extra cost)
- Recursion detection: O(f²) where f = functions (acceptable)

**Optimization**: Cache validation results, only re-validate on file changes.

---

## References

- **Rye Style Guide**: `docs/rye_style.md`
- **Phase 1 Validator**: `rye/src/validator.zig`
- **Toroidal Architecture**: `docs/rye/0003-toroidal-garden-architecture.md`

---

**Date**: 2026-01-22-062923-pst  
**Status**: 🆕 **ENFORCEMENT PLAN** — Integrate Rye Style constraints into compiler
