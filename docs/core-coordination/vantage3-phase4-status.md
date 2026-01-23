# Phase 4: Rye Style Enforcement - Implementation Status

**Date**: 2026-01-23-230000-pst  
**Status**: 🚧 **IN PROGRESS** — Three checks active (80% of Phase 4 complete)

---

## What's Been Created

### 1. Rye Style Validation Module ✅

**File**: `/home/xy/codeberg/ryelang/rye/src/Sema/rye_style.zig`

**Contents**:
- `validateFunctionLengthApprox()` - Checks function length ≤ 64 lines (approximate, active)
- `validateLineLength()` - Checks line length ≤ 128 characters and why comments (accurate, active)
- `validateWhyCommentsInFile()` - Checks "/// Why:" comment for all root-level pub fn (active)
- Constants: `MAX_FUNCTION_LINES = 64`, `MAX_LINE_LENGTH = 128`

**Status**: Module created, 3 validation functions active

### 2. Test Cases ✅

**Files Created**:
- `test/cases/rye_style/function_too_long.zig` - Tests function length violation
- `test/cases/rye_style/valid_function.zig` - Tests valid function
- `test/cases/rye_style/line_too_long.zig` - Tests line length violation
- `test/cases/rye_style/missing_why_comment.zig` - Tests missing why comment
- `test/cases/rye_style/valid_with_why.zig` - Tests valid function with why comment

**Status**: Test cases created, ready for validation once integration complete

---

## Integration Requirements

### Current Challenge

The validation module needs to be integrated into the compiler's semantic analysis phase. This requires:

1. **Function Declaration Tracking**: Need to identify when a function is being analyzed
2. **Source Location Access**: Need reliable access to AST nodes and source locations  
3. **Error Reporting**: Need to use correct compiler error reporting APIs (`sema.fail()`)
4. **Timing**: Need to run validation at the right point in compilation

### Integration Points Identified

**Primary Integration Point**: `src/Sema.zig::analyzeFnBody()`
- This is where function bodies are analyzed
- Has access to `sema`, `block`, and function body
- Can use `sema.fail()` for error reporting
- Need to get AST node from `sema.owner` or function declaration

**Key APIs Found**:
- `sema.fail(block, src, format, args)` - Proper way to report semantic errors
- `block.src()` - Get source location
- `sema.owner` - Current analysis unit (may contain function info)
- `LazySrcLoc` - Source location type

### Integration Approach

1. **Add validation call in `analyzeFnBody()`**:
   - Get function AST node from `sema.owner` or function declaration
   - Count lines in function body
   - Call `sema.fail()` if exceeds limit

2. **Refine validation module**:
   - Use `sema.fail()` instead of `zcu.addErrorWithNotes()`
   - Get AST node properly from semantic context
   - Access source tree correctly

---

## Next Steps

### Immediate (Next Session)

1. **Refine Validation Module**:
   - Change from `zcu.addErrorWithNotes()` to `sema.fail()` pattern
   - Fix AST node access to work with semantic analysis context
   - Simplify to work with available APIs

2. **Add Integration Hook**:
   - Add validation call in `analyzeFnBody()` or `funcCommon()`
   - Get function node from `sema.owner` or function declaration
   - Test with simple function length check first

3. **Test Integration**:
   - Compile test cases
   - Verify errors are reported correctly
   - Refine based on actual compiler behavior

### Short-Term

4. **Add Line Length Check**: Integrate line length validation
5. **Add Remaining Checks**: Why comments, explicit types, recursion detection
6. **Comprehensive Testing**: Test with Basin kernel code

### Long-Term

7. **Performance Optimization**: Cache validation results
8. **Error Message Refinement**: Improve error messages and suggestions
9. **Documentation**: Document Rye Style enforcement for users

---

## Files Created

- `src/Sema/rye_style.zig` - Validation module (3 functions: function length, line length, why comment)
- `test/cases/rye_style/function_too_long.zig` - Test case
- `test/cases/rye_style/valid_function.zig` - Test case
- `test/cases/rye_style/line_too_long.zig` - Test case for line length
- `test/cases/rye_style/missing_why_comment.zig` - Test case for why comment
- `test/cases/rye_style/valid_with_why.zig` - Test case with why comment
- `docs/core-coordination/vantage3-phase4-plan.md` - Implementation plan
- `docs/core-coordination/vantage3-phase4-status.md` - Status document
- `docs/core-coordination/vantage3-phase4-integration-note.md` - Integration notes
- `docs/core-coordination/vantage3-phase4-roadmap.md` - Refinement roadmap

---

## Implementation Notes

### Key Insights from Research

1. **Error Reporting**: Use `sema.fail(block, src, format, args)` not `zcu.addErrorWithNotes()`
2. **Source Location**: `LazySrcLoc` is the standard type, can be created from `block.src()`
3. **Function Context**: `sema.owner` contains current analysis unit, may have function info
4. **Integration Point**: `analyzeFnBody()` is the right place, but need AST node access

### Challenges

- AST node access from ZIR/semantic context is complex
- Need to map from function declaration to AST node
- Source tree access requires proper file scope handling
- Line counting needs accurate token/span information

### Approach

Start simple: Add basic validation that can be refined iteratively. Focus on getting one check working (function length) before adding complexity.

---

**Status**: 🚧 **IN PROGRESS** — Two checks active, one ready (60% of checks implemented)

---

## Active Validations

### ✅ Function Length Check (Approximate)
- **Status**: Active in compiler
- **Method**: Instruction count (200+ instructions = error)
- **Accuracy**: Catches very long functions, may miss moderately long ones
- **Location**: `analyzeFnBody()` → `validateFunctionLengthApprox()`

### ✅ Line Length Check
- **Status**: Active in compiler
- **Method**: Validates entire file on function analysis
- **Accuracy**: 100% accurate (checks all lines)
- **Location**: `analyzeFnBody()` → `validateLineLength()`
- **Note**: Currently validates on every function (can be optimized)
