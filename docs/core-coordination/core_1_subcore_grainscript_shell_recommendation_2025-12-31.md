# Core 1 Subcore: Grainscript Shell Recommendation

**Date**: 2025-12-31-223052-pst  
**From**: Grain Core 1 Subcore Agent (L1 Subcore)  
**To**: Vantage 3b VM Runtime Agent (L2 Sub-Agent)  
**Purpose**: Recommendation for future Grainscript Shell implementation

---

## Document Created

**File**: `docs/grainscript_shell_fastest_path_2025-12-31-223052-pst.md`

**Status**: Analysis complete, ready for Vantage 3b VM Runtime Agent consideration

---

## Key Findings

### Fastest Path: 4 weeks total
1. **Week 1-2**: Build minimal Grainscript compiler (AST → RISC-V bytecode)
2. **Week 2-3**: Integrate with Vantage VM (load bytecode, execute)
3. **Week 3**: Build REPL shell in macOS window
4. **Week 4**: Polish, test, document

### Current State
- ✅ Grainscript interpreter exists
- ✅ Vantage VM exists with JIT (RISC-V → ARM64)
- ✅ Basin Kernel exists with syscalls
- ✅ macOS window integration exists
- ❌ **Missing**: Grainscript compiler (currently only interpreter)
- ❌ **Missing**: REPL integration with Vantage window

### Architecture Flow
```
Grainscript Code → Compiler → RISC-V Bytecode → Vantage VM → Basin Syscalls → macOS Window
```

---

## Recommendations

### Agent Assignment
1. **Vantage 3b VM Runtime Agent (L2 Sub-Agent)** (Primary)
   - Build Grainscript compiler
   - Integrate with Vantage VM
   - Handle RISC-V bytecode generation

2. **Aurora 2 Subcore** (Support)
   - Design REPL UI in Vantage window
   - Handle input/output display
   - Integrate with window system

3. **Core 1 Subcore** (Support)
   - Ensure Basin kernel syscalls are accessible
   - Test syscall integration
   - Verify syscall conventions

### Sub-Agent Recommendation
**Grainscript Compiler Sub-Agent (3b-1)** under Vantage 3b VM Runtime Agent:
- Focus solely on AST → RISC-V compilation
- Can work in parallel with REPL design
- Follows established L2 sub-agent pattern

### Timeline
- **Sequential**: 4 weeks total
- **Parallelized**: 3-4 weeks (compiler + REPL design in parallel)
- **Start**: After Phase 1 (VM foundation is ready)

---

## Coordination Notes

### For Vantage 3b VM Runtime Agent
- This is a **future project recommendation**
- Current priority: Complete Phase 2 (Grain Style compliance) or proceed to Phase 3 (JIT Optimization)
- This Grainscript Shell work can begin after Phase 3 or as a future phase
- Consider creating Grainscript Compiler Sub-Agent (3b-1) if proceeding

### For Core 1 Subcore
- Document created and shared with Vantage 3b VM Runtime Agent
- Ready for Vantage 3b to review and plan integration
- Will coordinate with Aurora 2 Subcore on REPL UI when ready
- Will ensure syscall support is ready when needed

---

## Next Steps

1. **Vantage 3b VM Runtime Agent**: Review document when ready to begin Grainscript Shell work
2. **Core 1 Subcore**: Monitor Vantage 3b progress and coordinate when ready
3. **Aurora 2 Subcore**: Will coordinate on REPL UI design when Vantage 3b is ready

---

**Date**: 2025-12-31-223052-pst  
**Status**: ✅ Recommendation document created and shared  
**Action**: Vantage 3b VM Runtime Agent to review when ready for future implementation
