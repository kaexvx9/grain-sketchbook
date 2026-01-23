# Phase 4: Rye Style Enforcement - Implementation Plan

**Date**: 2026-01-23-170000-pst  
**Agent**: Vantage 3 Subcore (Rye Compiler Fork Development)  
**Status**: 🎨 **PLANNING** — Rye Style enforcement implementation plan

---

## Overview

Phase 4 implements compiler-enforced Rye Style constraints. This ensures all Rye code follows the toroidal bounded programming model for safety and performance.

**Current Status**: Phase 2 and Phase 3 complete. Ready to begin Phase 4.

---

## Implementation Strategy

### Approach: Incremental Implementation

Start with simplest checks, add complexity gradually:

1. **Function Length Check** (≤64 lines) - Simplest, most visible
2. **Line Length Check** (≤128 chars) - Simple, fast
3. **Why Comment Check** (pub fn) - Requires doc comment parsing
4. **Explicit Type Check** (no usize/isize) - Requires type system integration
5. **Recursion Detection** - Most complex, requires call graph

---

## Implementation Details

### 1. Function Length Check (Priority 1)

**Location**: `src/Sema.zig` - `analyzeFnBody()` function

**Implementation**:
- Count source lines in function body
- Check against 64-line limit
- Emit compiler error if exceeded

**Integration Point**: After function body parsing, before semantic analysis

**Error Format**:
```
error: Function 'process_scheduler' is 68 lines, maximum is 64
  --> src/kernel/scheduler.ry:42:1
   |
42 | pub fn process_scheduler(self: *Scheduler) void {
   | ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
   |
   = help: Split function into smaller functions (extract helpers)
```

### 2. Line Length Check (Priority 2)

**Location**: `src/zig/tokenizer.zig` or parser

**Implementation**:
- Check each line during tokenization/parsing
- Track line length
- Emit compiler error if > 128 characters

**Integration Point**: During source file parsing

### 3. Why Comment Check (Priority 3)

**Location**: `src/Sema.zig` - Function declaration analysis

**Implementation**:
- Check for `/// Why:` doc comment before `pub fn`
- Emit compiler error if missing

**Integration Point**: During function declaration analysis

### 4. Explicit Type Check (Priority 4)

**Location**: `src/Sema.zig` - Type checking phase

**Implementation**:
- Detect `usize`/`isize` type usage
- Emit compiler error
- Suggest explicit `u32`/`u64`/`i32`/`i64`

**Integration Point**: During type checking

### 5. Recursion Detection (Priority 5)

**Location**: `src/Sema.zig` - Call graph analysis

**Implementation**:
- Build call graph during semantic analysis
- Detect recursive calls
- Emit compiler error

**Integration Point**: After semantic analysis, before codegen

---

## Test Strategy

### Test Files Structure

```
test/cases/rye_style/
├── function_too_long.ry          # Should error: > 64 lines
├── line_too_long.ry              # Should error: > 128 chars
├── missing_why_comment.ry       # Should error: pub fn without why
├── implicit_type.ry              # Should error: usize/isize
├── recursive_function.ry         # Should error: recursion
└── valid_code.ry                 # Should compile: all constraints met
```

### Test Execution

```bash
# Test Rye Style enforcement
rye build test/cases/rye_style/*.ry

# Expected: Errors for violations, success for valid code
```

---

## Timeline

**Week 9-10**: Function length + Line length checks  
**Week 11**: Why comment check  
**Week 12**: Explicit type check + Recursion detection

**Target**: Phase 4 complete by end of Week 12

---

## Success Criteria

✅ Function length check implemented and tested  
✅ Line length check implemented and tested  
✅ Why comment check implemented and tested  
✅ Explicit type check implemented and tested  
✅ Recursion detection implemented and tested  
✅ All test cases pass  
✅ Basin kernel compiles with Rye Style enforcement enabled

---

## Next Steps

1. Implement function length check (proof of concept)
2. Add test cases
3. Integrate into compiler pipeline
4. Iterate on remaining checks

---

**Status**: 🎨 **PLANNING** — Ready to begin implementation
