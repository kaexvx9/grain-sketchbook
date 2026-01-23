# Phase 4: Rye Style Enforcement - Refinement Roadmap

**Date**: 2026-01-23-210000-pst  
**Status**: 🚧 **REFINEMENT ROADMAP** — Clear path for completing Phase 4

---

## Current State

### ✅ What's Working

1. **Function Length Check (Approximate)**
   - Integrated into `analyzeFnBody()` in `Sema.zig`
   - Uses instruction count (200+ = likely >64 lines)
   - Active in compiler, catches very long functions
   - Error reporting works correctly

2. **Line Length Validation Function**
   - Complete implementation in `rye_style.zig`
   - Checks all lines in source file
   - Proper error reporting
   - Ready for integration

3. **Infrastructure**
   - Validation module structure complete
   - Test cases created
   - Documentation comprehensive

---

## Refinement Plan

### Step 1: Accurate Function Length Check (Priority: High)

**Current**: Uses instruction count approximation  
**Goal**: Count actual source lines from AST

**Approach**:
1. Get function declaration AST node from `sema.owner`
2. Extract node index from function declaration
3. Get AST tree from file scope
4. Count lines between function start/end tokens

**Implementation Location**: `src/Sema/rye_style.zig::validateFunctionLengthApprox()`

**Key APIs Needed**:
- `sema.owner` → function declaration → AST node
- `file_scope.getTree(zcu)` → AST tree
- `tree.tokens.items(.start)[node.firstToken()].line` → start line
- `tree.tokens.items(.start)[node.lastToken()].line` → end line

**Estimated Effort**: Medium (requires understanding function declaration structure)

---

### Step 2: File-Level Line Length Validation (Priority: High)

**Current**: Function ready, needs integration point  
**Goal**: Validate all lines when file is analyzed

**Approach Options**:

**Option A**: During AST parsing (in `File.getTree()`)
- Pros: Early validation, catches issues immediately
- Cons: Might be too early, before semantic context

**Option B**: During file analysis (when declarations are analyzed)
- Pros: Has semantic context, can use `sema.fail()`
- Cons: Need to find right hook point

**Option C**: Separate validation pass
- Pros: Clean separation, easy to test
- Cons: Additional compilation phase

**Recommended**: Option B - Add validation when first function in file is analyzed

**Implementation**:
```zig
// In analyzeFnBody or similar, check if this is first function in file
// If so, validate line length for entire file
if (is_first_function_in_file) {
    try rye_style.validateLineLength(sema, block, file_scope);
}
```

**Estimated Effort**: Low-Medium (need to track file validation state)

---

### Step 3: Why Comment Check (Priority: Medium)

**Goal**: Require `/// Why:` comment for all `pub fn`

**Approach**:
1. Check function declaration for doc comments
2. Verify `/// Why:` format
3. Report error if missing

**Implementation Location**: During function declaration analysis

**Key APIs**:
- AST node for function declaration
- Check for doc comments before function
- Parse doc comment for "Why:" prefix

**Estimated Effort**: Medium

---

### Step 4: Explicit Type Check (Priority: Medium)

**Goal**: Disallow `usize`/`isize`, require explicit types

**Approach**:
1. During type checking, detect `usize`/`isize` usage
2. Report error with suggestion for explicit type
3. Handle edge cases (C interop, system types)

**Implementation Location**: Type checking phase in `Sema.zig`

**Key APIs**:
- Type checking infrastructure
- Error reporting for type violations

**Estimated Effort**: Medium-High (needs careful handling of edge cases)

---

### Step 5: Recursion Detection (Priority: Low)

**Goal**: Detect and reject recursive functions

**Approach**:
1. Build call graph during semantic analysis
2. Detect cycles (recursive calls)
3. Report error for recursive functions

**Implementation Location**: After semantic analysis, before codegen

**Key APIs**:
- Call graph analysis
- Cycle detection algorithm

**Estimated Effort**: High (most complex check)

---

## Implementation Order

### Immediate (This Week)
1. ✅ Basic function length check (DONE - approximate)
2. ⏳ File-level line length validation (HIGH PRIORITY)
3. ⏳ Refine function length check (HIGH PRIORITY)

### Short-Term (Next 2 Weeks)
4. Why comment check
5. Explicit type check

### Medium-Term (Weeks 3-4)
6. Recursion detection
7. Performance optimization
8. Comprehensive testing

---

## Testing Strategy

### Unit Tests
- Test each validation function independently
- Test error reporting
- Test edge cases

### Integration Tests
- Test with Basin kernel code
- Test with test cases in `test/cases/rye_style/`
- Verify errors are reported correctly

### Performance Tests
- Measure validation overhead
- Optimize if needed
- Cache results where possible

---

## Success Criteria

✅ Function length check accurate (uses AST line count)  
✅ Line length check active (validates all files)  
✅ Why comment check working  
✅ Explicit type check working  
✅ Recursion detection working  
✅ All test cases pass  
✅ Basin kernel compiles with Rye Style enforcement  
✅ Performance acceptable (validation overhead < 5%)

---

## Next Session Goals

1. **Add File-Level Line Length Validation**
   - Find integration point
   - Add validation call
   - Test with long lines

2. **Refine Function Length Check**
   - Get AST node access
   - Count actual lines
   - Test accuracy

3. **Test Implementation**
   - Compile test cases
   - Verify errors reported
   - Refine based on results

---

**Status**: 🚧 **REFINEMENT ROADMAP** — Clear path forward for completing Phase 4
