# Phase 4: Rye Style Enforcement - Integration Note

**Date**: 2026-01-23-200000-pst  
**Status**: 🚧 **INTEGRATION STARTED** — Basic structure in place

---

## Integration Status

### ✅ Completed

1. **Rye Style Module Created**: `src/Sema/rye_style.zig`
   - Function length validation structure (placeholder)
   - Line length validation (ready for integration)
   - Proper error reporting using `sema.fail()`

2. **Integration Hook Added**: `src/Sema.zig::analyzeFnBody()`
   - Validation call added before body analysis
   - Uses proper Sema context

3. **Test Cases Created**: `test/cases/rye_style/`
   - `function_too_long.zig` - Tests function length violation
   - `valid_function.zig` - Tests valid code

### ⏳ Pending

1. **Function Length Validation**: Needs AST node access
   - Current: Placeholder using instruction count
   - Needed: Access to function declaration AST node
   - Needed: Count lines between function start/end tokens

2. **Line Length Validation**: Needs file-level integration
   - Current: Function ready but not called
   - Needed: Integration point for file-level validation
   - Needed: Call during file parsing/analysis

---

## Implementation Approach

### Current Strategy

**Incremental Implementation**:
1. ✅ Create validation module structure
2. ✅ Add integration hook in `analyzeFnBody()`
3. ⏳ Implement function length check (needs AST access)
4. ⏳ Implement line length check (needs file-level hook)
5. ⏳ Add remaining checks (why comments, types, recursion)

### Function Length Check Challenge

**Problem**: Need to access AST node from semantic analysis context.

**Current State**: 
- `analyzeFnBody()` receives ZIR body, not AST node
- Function declaration info is in `sema.owner` but needs extraction
- AST tree access requires file scope and node index

**Solution Path**:
1. Get function declaration from `sema.owner`
2. Extract AST node index from declaration
3. Get AST tree from file scope
4. Count lines between function start/end tokens

### Line Length Check Challenge

**Problem**: Need to validate at file level, not function level.

**Current State**:
- Validation function exists but needs integration point
- File-level validation should run once per file, not per function

**Solution Path**:
1. Find file parsing/analysis entry point
2. Add validation call after AST is loaded
3. Validate all lines in source file

---

## Next Steps

### Immediate

1. **Research AST Access**: Understand how to get function AST node from `sema.owner`
2. **Implement Function Length**: Count actual source lines from AST
3. **Find File Integration Point**: Locate where files are analyzed
4. **Integrate Line Length**: Add file-level validation

### Short-Term

5. **Test Integration**: Verify validation works with test cases
6. **Refine Error Messages**: Improve clarity and suggestions
7. **Add Remaining Checks**: Why comments, explicit types, recursion

---

## Files Modified

- `src/Sema/rye_style.zig` - Validation module
- `src/Sema.zig` - Integration hook in `analyzeFnBody()`
- `test/cases/rye_style/function_too_long.zig` - Test case
- `test/cases/rye_style/valid_function.zig` - Test case

---

## Notes

- Current implementation is a foundation that compiles
- Function length check is placeholder - needs AST access refinement
- Line length check is ready but needs file-level integration point
- Error reporting uses correct `sema.fail()` pattern
- All code follows Rye Style constraints (64 lines, 128 chars, "why" comments)

---

**Status**: 🚧 **INTEGRATION STARTED** — Foundation in place, refinement needed for full functionality
