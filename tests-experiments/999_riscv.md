# Platform Abstraction Boundary Fuzz — RISC-V Experiment 999

Date: 12025-11-12--0937-pst  
Operator: Glow G2 (Stoic Aquarian cadence)  
Platform: RISC-V freestanding (kernel mode)

## Objective
Fuzz RISC-V platform abstraction boundaries to ensure deterministic behavior
across framebuffer initialization, buffer operations, and platform vtable
dispatch paths. Validates TigerStyle safety: no unexpected panics,
deterministic vtable selection, correct buffer alignment, and single-level
pointer usage.

## Method
- Added Zig test harness (`test "riscv platform abstraction boundary fuzz"`)
  in `src/platform.zig`.
  - Custom LCG PRNG generates random window titles and buffer operations.
  - Tests RISC-V platform implementation via compile-time target selection.
  - Randomly exercises window lifecycle: init → show → getBuffer → present →
    width/height → deinit.
  - Validates buffer RGBA alignment, dimension consistency, and vtable dispatch
    correctness.
  - Uses Arena allocator + deterministic RNG seed for reproducible runs.
- Executed via `zig test src/platform.zig -target riscv64-freestanding`.

## Test Cases
1. **Framebuffer Initialization Fuzz**
   - Random titles (1-256 chars), validates platform.init() returns valid
     Platform struct with non-null vtable and impl pointers.
   - Asserts framebuffer allocation succeeds and dimensions match (1024x768).

2. **Buffer Operations Fuzz**
   - Random pixel writes to framebuffer, validates RGBA alignment
     (buffer.len % 4 == 0).
   - Tests getBuffer() returns slice matching framebuffer dimensions.
   - Validates buffer.len == width * height * 4.

3. **VTable Dispatch Fuzz**
   - Random sequence of vtable calls: show, getBuffer, present, width, height.
   - Validates all vtable functions dispatch correctly without panics.
   - Ensures width/height return values match initialized dimensions.

4. **Platform Lifecycle Fuzz**
   - Random sequences of init/deinit cycles to stress allocator behavior.
   - Validates deinit cleans up all resources without leaks.
   - Tests error paths (invalid titles) handled gracefully.

## Status
**Deferred**: RISC-V testing requires QEMU setup and Framework 13 RISC-V board
or VPS. Resume once hardware/approvals arrive. Until then, focus on macOS Tahoe
Aurora work via the MacBook Air / Framework 16 host.

## Notes
- RISC-V-specific: tests framebuffer-based rendering for kernel mode.
- Future extensions: seed parameterization via CLI args, snapshot failing
  inputs, compare framebuffer contents before/after operations, and integrate
  with kernel boot tests once QEMU is available.
- TigerStyle compliance: all pointer usage is single-level only; no double
  indirection in vtable dispatch paths.

