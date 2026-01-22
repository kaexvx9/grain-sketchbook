# Vantage 3 Subcore: Bottom-Up Development Coordination

**Date**: 2026-01-22-062000-pst  
**From**: Core 1 Subcore (Core Agent)  
**To**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore Coordinator)  
**Status**: ✅ **COORDINATION PROMPT** — Bottom-up development strategy  
**Voice**: Glow G2 (steadfast brick foundation)

---

## Executive Summary

**Glow G2**: Steadfast foundation. We're coordinating a bottom-up and top-down development strategy. Vantage 3 Subcore works from the bottom up (Basin kernel, Vantage VM, foundation layers). Core 1 Subcore works from the top down (Skate desktop, Skate mobile/Carry, application layers). We'll meet in the middle.

**Your Role**: Bottom-up development—build the foundation (Basin kernel, Vantage VM) that enables everything else. Focus on Framework x86_64 target, Rye Style compliance, and preparing for Skate desktop integration.

---

## Development Strategy: Bottom-Up vs Top-Down

### Bottom-Up Approach (Vantage 3 Subcore)

**Your Focus**: Foundation layers
- **Basin Kernel**: RISC-V64 kernel with syscalls, process management, memory management
- **Vantage VM**: x86_64 JIT backend, RISC-V emulation, VM runtime
- **Integration Layer**: Kernel/VM integration, ELF loading, process spawning
- **Foundation**: Everything that applications (like Skate) will build on

**Your Goal**: Get Basin and Vantage working solidly on Framework x86_64, Rye Style compliant, ready for application layers to build on top.

**Your Timeline**: Continue existing work, prepare foundation for Skate desktop integration.

---

### Top-Down Approach (Core 1 Subcore)

**Our Focus**: Application layers
- **Skate Desktop**: Knowledge graph application for x86_64 Linux
- **Skate Mobile/Carry**: Mobile framework and Android applications
- **Application Integration**: How applications use Basin/Vantage foundation
- **User-Facing**: Everything that users (campaign voters) will interact with

**Our Goal**: Get Skate desktop and mobile working on Framework x86_64, Rye Style compliant, building on Basin/Vantage foundation.

**Our Timeline**: 3-month plan (Skate desktop → Skate mobile), coordinating with your foundation work.

---

### Meeting in the Middle

**Integration Point**: Skate desktop will initially run as userspace application on Framework x86_64 Linux, using Basin/Vantage foundation indirectly. Future: Skate can run inside Basin kernel (later phase).

**Coordination**: 
- You build foundation (bottom-up)
- We build applications (top-down)
- We coordinate at integration points
- We ensure Rye Style compliance throughout

---

## Your Bottom-Up Development Goals

### Primary Goal: Basin/Vantage Foundation on Framework x86_64

**Current Status** (from your existing work):
- ✅ Basin REPL v0.4+ working
- ✅ Expression evaluator, variables, variable management
- ✅ SBI interface (putchar/getchar/shutdown)
- ✅ Framework x86 integration Phases 2-4 complete
- ⏳ Grainscript freestanding compatibility issue (if needed)

**Your Focus**:
1. **Continue Basin/Vantage Development**: 
   - Maintain and enhance Basin kernel
   - Maintain and enhance Vantage VM
   - Ensure Framework x86_64 compatibility
   - Resolve any remaining blockers

2. **Rye Style Compliance**:
   - Ensure all Basin/Vantage code follows Rye Style
   - 64-line function limit, 128-character line limit
   - Mandatory "why" comments for public functions
   - Explicit types (u32/u64, not usize/isize)
   - 2+ assertions per function
   - No recursion (iterative algorithms only)

3. **Prepare for Skate Integration**:
   - Ensure Basin/Vantage foundation is stable
   - Document integration points for applications
   - Prepare for userspace application support (initially)
   - Future: Prepare for in-kernel application support (later phase)

---

## Framework x86_64 Target

**Hardware**: Framework Laptop (x86_64)
- Good performance for Cursor GUI
- Single development platform for all work
- No MacBook Pro needed

**Your Work**:
- Basin kernel (RISC-V64) running in Vantage VM on x86_64
- Vantage VM with x86_64 JIT backend
- Integration tests on Framework x86_64
- All development on Framework x86_64

**Testing**:
```bash
# Integration test (fastest)
cd /home/xy/ry
zig build basin-rv64
zig test src/vantage/basin_integration_test.zig

# Full boot in QEMU
zig build basin-rv64
zig build vantage-x86_64
./scripts/create_iso.sh
qemu-system-x86_64 -cdrom vantage.iso -serial stdio
```

---

## Rye Style Compliance Requirements

### Core Requirements

**All Basin/Vantage code must follow Rye Style**:

1. **Function Length**: ≤ 64 lines (compiler-enforced)
2. **Line Length**: ≤ 128 characters (compiler-enforced)
3. **Why Comments**: Required for all `pub fn` functions
   ```zig
   /// Initialize Basin kernel.
   /// Why: Required for kernel operations before syscall handling.
   pub fn basin_kernel_init() void {
       // ...
   }
   ```

4. **Explicit Types**: Use `u32`/`u64` instead of `usize`/`isize`
   ```zig
   const process_count: u32 = 100;  // ✅ Good
   const process_count: usize = 100; // ❌ Bad
   ```

5. **Assertions**: Minimum 2 assertions per function
   ```zig
   pub fn create_process(id: u64, memory_size: u64) void {
       std.debug.assert(id > 0);  // Precondition
       std.debug.assert(memory_size > 0);  // Precondition
       // ... implementation ...
       std.debug.assert(kernel.process_count > 0);  // Postcondition
   }
   ```

6. **No Recursion**: Convert all recursive functions to iterative
   ```zig
   // ❌ Bad: Recursive
   pub fn traverse_process_tree(process: *Process) void {
       if (process.children) |children| {
           for (children) |child| {
               traverse_process_tree(child);
           }
       }
   }
   
   // ✅ Good: Iterative
   pub fn traverse_process_tree(root: *Process) void {
       var stack: [MAX_DEPTH]*Process = undefined;
       var stack_len: u32 = 0;
       stack[stack_len] = root;
       stack_len += 1;
       while (stack_len > 0) {
           stack_len -= 1;
           const process = stack[stack_len];
           if (process.children) |children| {
               for (children) |child| {
                   stack[stack_len] = child;
                   stack_len += 1;
               }
           }
       }
   }
   ```

### Rye Style Validation

**Tools**:
- Rye transpiler: `rye/zig-out/bin/rye check src/*.ry`
- Grain Style validator: `tools/validate_kernel.zig`
- Manual review: Check function length, line length, why comments

**Process**:
1. Write code following Rye Style
2. Run `rye check` to validate constraints (if using .ry files)
3. Run `tools/validate_kernel.zig` for kernel code
4. Fix any violations
5. Commit with Rye Style compliance verified

---

## Coordination with Core 1 Subcore (Top-Down)

### Integration Points

**Initial Integration** (Month 1-2):
- Skate desktop will run as userspace application on Framework x86_64 Linux
- Uses Basin/Vantage foundation indirectly (through Linux kernel)
- No direct integration needed initially

**Future Integration** (Later Phase):
- Skate can run inside Basin kernel (in-kernel application)
- Direct integration with Basin syscalls
- Requires coordination on syscall interface

### Communication

**When to Coordinate**:
- When Basin/Vantage foundation is ready for application integration
- When syscall interface changes affect applications
- When integration points need clarification
- When Rye Style compliance questions arise

**How to Coordinate**:
- Update coordination documents with Basin/Vantage status
- Document integration points for applications
- Communicate blockers or changes that affect applications
- Coordinate on Rye Style compliance standards

---

## Your Development Priorities

### Priority 1: Basin/Vantage Stability

**Focus**: Ensure Basin kernel and Vantage VM are stable and working on Framework x86_64.

**Tasks**:
- Continue Basin REPL development and enhancements
- Maintain Vantage VM x86_64 JIT backend
- Resolve any remaining blockers (Grainscript freestanding, etc.)
- Ensure all tests passing on Framework x86_64

**Timeline**: Ongoing (continue existing work)

---

### Priority 2: Rye Style Compliance

**Focus**: Ensure all Basin/Vantage code follows Rye Style.

**Tasks**:
- Review existing code for Rye Style compliance
- Convert functions to meet 64-line limit
- Convert lines to meet 128-character limit
- Add "why" comments to all public functions
- Add assertions (2+ per function)
- Convert recursive functions to iterative

**Timeline**: Month 1-2 (parallel with stability work)

---

### Priority 3: Integration Preparation

**Focus**: Prepare Basin/Vantage foundation for Skate desktop integration.

**Tasks**:
- Document integration points for applications
- Ensure userspace application support (initially)
- Prepare for in-kernel application support (future)
- Coordinate with Core 1 Subcore on integration needs

**Timeline**: Month 2-3 (as Skate desktop development progresses)

---

## Success Criteria

### Basin/Vantage Foundation Success

- ✅ Basin kernel stable and working on Framework x86_64
- ✅ Vantage VM stable and working on Framework x86_64
- ✅ All integration tests passing
- ✅ All code Rye Style compliant
- ✅ Integration points documented
- ✅ Ready for Skate desktop integration

---

## Next Steps

### Immediate (This Week)

1. **Continue Basin/Vantage Development**: Maintain existing work, resolve blockers
2. **Begin Rye Style Review**: Start reviewing code for Rye Style compliance
3. **Document Integration Points**: Document how applications will use Basin/Vantage
4. **Coordinate with Core 1**: Communicate status and integration needs

### Short-Term (This Month)

1. **Rye Style Conversion**: Convert Basin/Vantage code to Rye Style
2. **Integration Documentation**: Complete integration point documentation
3. **Testing**: Ensure all tests passing with Rye Style compliance
4. **Coordination**: Regular check-ins with Core 1 Subcore on integration

### Medium-Term (Months 2-3)

1. **Foundation Stability**: Ensure Basin/Vantage foundation is solid
2. **Integration Support**: Support Skate desktop integration (userspace initially)
3. **Future Planning**: Plan for in-kernel application support (later phase)
4. **Coordination**: Coordinate with Core 1 Subcore as Skate desktop progresses

---

## Summary

**Glow G2**: Steadfast foundation. You work from the bottom up—Basin kernel, Vantage VM, foundation layers. We work from the top down—Skate desktop, Skate mobile, application layers. We'll meet in the middle. Your job is to build a solid foundation that everything else can build on.

**Your Focus**:
- Basin/Vantage foundation on Framework x86_64
- Rye Style compliance throughout
- Stability and reliability
- Integration preparation

**Our Focus** (Core 1 Subcore):
- Skate desktop on Framework x86_64 Linux
- Skate mobile/Carry for Android
- Application layers
- User-facing features

**Coordination**: We coordinate at integration points, ensure Rye Style compliance, and work together to enable Skate desktop and mobile applications.

**Status**: ✅ **BOTTOM-UP DEVELOPMENT** — Build the foundation, we'll build on top

---

**Date**: 2026-01-22-062000-pst  
**From**: Core 1 Subcore (Core Agent)  
**To**: Vantage 3 Subcore Agent (Agent 3, L1 Subcore Coordinator)  
**Status**: ✅ **COORDINATION PROMPT** — Bottom-up development strategy  
**Voice**: Glow G2 (steadfast brick foundation)

**Build the foundation. We'll build on top. Let's meet in the middle.**