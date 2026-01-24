# Rye Style Quick Reference

**Date**: 2026-01-23-161055-pst  
**Purpose**: Quick reference guide for Rye Style constraints enforced by the compiler

---

## Overview

The Rye compiler automatically enforces Rye Style constraints during compilation. No separate `rye check` command needed - validation is built-in.

---

## Active Checks

### 1. Function Length Check ✅
**Constraint**: Maximum 64 lines per function body

**What it checks**:
- Counts actual source lines in function body (AST-based, accurate)
- Excludes opening/closing braces from count
- Validates all functions (public and private)
- Validates nested functions in containers (structs, enums, unions)

**Error message**:
```
Function has {d} lines, maximum is {d}. Split into smaller functions
```

**How to fix**:
- Extract helper functions
- Split large functions into smaller, focused functions
- Refactor complex logic into separate functions

---

### 2. Line Length Check ✅
**Constraint**: Maximum 128 characters per line

**What it checks**:
- Validates every line in the source file
- Checks once per file (optimized)
- Reports line number and character count

**Error message**:
```
Line {d} is {d} characters, maximum is {d}. Break line into multiple lines or shorten variable names
```

**How to fix**:
- Split long function signatures across multiple lines
- Break long expressions into multiple lines
- Shorten variable names if appropriate
- Use line continuation where appropriate

---

### 3. Why Comment Check ✅
**Constraint**: All public functions must have "/// Why:" documentation comment

**What it checks**:
- Validates all `pub fn` declarations
- Checks for "Why:" text in doc comments before function
- Validates nested public functions in containers
- Recursively checks containers (structs, enums, unions)

**Error message**:
```
Public function missing '/// Why:' documentation comment
```

**How to fix**:
- Add `/// Why: <explanation>` comment before public function
- Explain the function's purpose and why it exists
- Place comment immediately before function declaration

**Example**:
```zig
/// Why: Required for initializing undo operation with operation details and text copy.
pub fn init(allocator: std.mem.Allocator, op: Operation, text: []const u8) !UndoOperation {
    // ...
}
```

---

### 4. Explicit Type Check ✅
**Constraint**: No `usize` or `isize` types allowed

**What it checks**:
- Function return types
- Function parameter types
- Variable declaration types
- Validates at declaration level (not usage)

**Error message**:
```
Function return type cannot be usize or isize. Use explicit size like u32 or u64
Function parameter type cannot be usize or isize. Use explicit size like u32 or u64
Variable type cannot be usize or isize. Use explicit size like u32 or u64
```

**How to fix**:
- Replace `usize` with `u32` or `u64` (or appropriate size)
- Replace `isize` with `i32` or `i64` (or appropriate size)
- Choose size based on actual requirements

**Example**:
```zig
// ❌ Bad
pub fn process(data: usize) void { }

// ✅ Good
pub fn process(data: u32) void { }
```

---

## Validation Flow

1. **Automatic**: Checks run during semantic analysis (compilation phase)
2. **File-level**: Line length, why comments, explicit types, function lengths validated once per file
3. **Function-level**: Function length also checked per function (as fallback)
4. **Optimized**: Files tracked to avoid redundant validation

---

## Error Reporting

- **Clear messages**: Each error explains the constraint and how to fix it
- **Source locations**: Errors point to exact line/column in source
- **Actionable**: Error messages suggest specific fixes

---

## Test Cases

11 comprehensive test cases in `test/cases/rye_style/`:
- `function_too_long.zig` - Tests function length violation
- `line_too_long.zig` - Tests line length violation
- `valid_function.zig` - Tests valid function
- `missing_why_comment.zig` - Tests missing why comment
- `valid_with_why.zig` - Tests valid function with why comment
- `usize_not_allowed.zig` - Tests usize in parameter
- `isize_not_allowed.zig` - Tests isize in return type
- `usize_var_not_allowed.zig` - Tests usize in variable
- `valid_explicit_types.zig` - Tests valid explicit types
- `nested_function_missing_why.zig` - Tests nested function missing why
- `nested_function_valid.zig` - Tests valid nested function

---

## Integration Status

✅ **All 4 core checks are active, accurate, optimized, and comprehensive**

- Function length: AST-based, accurate line counting
- Line length: Optimized, validates once per file
- Why comments: Comprehensive, validates nested functions
- Explicit types: Validates all type declarations

---

## Future Work (Optional)

- ⏳ Recursion detection (complex, requires control flow analysis)

---

**Status**: ✅ **PRODUCTION READY** — All core Rye Style checks active and validated
