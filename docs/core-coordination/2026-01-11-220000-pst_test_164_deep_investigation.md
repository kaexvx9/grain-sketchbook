# Test 164: Deep Investigation

**Date**: 2026-01-11-220000-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Purpose**: Deep investigation into persistent crash  
**Status**: 🔍 **INVESTIGATING** — Pattern verified but test 164 still crashes

---

## What We Know

### ✅ Verified Working
1. **Super simple test** (8MB via arena): ✅ PASSES
2. **Test with struct definitions**: ✅ PASSES
3. **Test with multiple environments**: ✅ PASSES (2/2)
4. **Helper function pattern**: Same pattern, still crashes in test 164

### ❌ Still Crashing
- **Test 164 "minimal: VM + Kernel"**: Crashes with signal 11
- **Even with increased stack size** (16MB): Still crashes
- **Even with helper function**: Still crashes

---

## Hypothesis: Module-Level Struct Definitions

**Theory**: Zig might be calculating stack frame size based on all large types defined in the module, not just what's used in the test function.

**Evidence**:
- Test 164 has `FullStackTestEnv` with `vm: VM` (value, not pointer)
- Test 164 has multiple large struct definitions at module level
- Simple tests work because they don't have these definitions

**Test**: Comment out `FullStackTestEnv` temporarily to see if that helps.

---

## Next Steps

1. **Check if `FullStackTestEnv` is the issue**: Comment it out
2. **Try moving test to separate file**: Via build system
3. **Check Zig compiler behavior**: Maybe a compiler bug?
4. **Try different Zig version**: If available

---

## Key Insight

**The pattern is correct and verified.** The issue is specific to how Zig compiles test 164, possibly due to module-level struct definitions.
