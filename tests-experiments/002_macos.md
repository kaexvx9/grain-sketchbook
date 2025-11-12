# Platform Abstraction Boundary Fuzz — macOS Experiment 002

Date: 12025-11-12--0937-pst  
Operator: Glow G2 (Stoic Aquarian cadence)  
Platform: macOS Tahoe (native)

## Objective
Fuzz macOS platform abstraction boundaries to ensure deterministic behavior
across window initialization, buffer operations, and platform vtable dispatch
paths. Validates TigerStyle safety: no unexpected panics, deterministic vtable
selection, correct buffer alignment, and single-level pointer usage.

## Method
- Added Zig test harness (`test "macos platform abstraction boundary fuzz"`)
  in `src/platform.zig`.
  - Custom LCG PRNG generates random window titles and buffer operations.
  - Tests macOS platform implementation via compile-time target selection.
  - Randomly exercises window lifecycle: init → show → getBuffer → present →
    width/height → deinit.
  - Validates buffer RGBA alignment, dimension consistency, and vtable dispatch
    correctness.
  - Uses Arena allocator + deterministic RNG seed for reproducible runs.
- Executed via `zig test src/platform.zig -target native-macos`.

## Test Cases
1. **Window Initialization Fuzz**
   - Random titles (1-256 chars), validates platform.init() returns valid
     Platform struct with non-null vtable and impl pointers.
   - Asserts buffer allocation succeeds and dimensions match (1024x768).

2. **Buffer Operations Fuzz**
   - Random pixel writes to buffer, validates RGBA alignment
     (buffer.len % 4 == 0).
   - Tests getBuffer() returns slice matching window dimensions.
   - Validates buffer.len == width * height * 4.

3. **VTable Dispatch Fuzz**
   - Random sequence of vtable calls: show, getBuffer, present, width, height.
   - Validates all vtable functions dispatch correctly without panics.
   - Ensures width/height return values match initialized dimensions.

4. **Platform Lifecycle Fuzz**
   - Random sequences of init/deinit cycles to stress allocator behavior.
   - Validates deinit cleans up all resources without leaks.
   - Tests error paths (invalid titles) handled gracefully.

## Results
```
$ zig test src/platform.zig -target native-macos
1/2 platform.test.macos platform abstraction boundary fuzz...OK
2/2 platform.test.macos platform error paths...OK
All 2 tests passed.
```

Test executed successfully: 100 iterations of random window lifecycle operations
across platform abstraction boundaries. All assertions passed, validating:
- Window initialization with random titles (1-256 chars)
- Buffer operations with RGBA alignment checks
- Buffer content validation via checksum (FNV-1a hash)
- Memory leak detection via GeneralPurposeAllocator
- VTable dispatch correctness (show, getBuffer, present, width, height)
- Dimension consistency across all operations
- Single-level pointer usage throughout (TigerStyle compliance)

## Improvements Implemented
1. **Buffer Content Validation** ✅
   - FNV-1a checksum computed before/after buffer operations
   - Validates buffer content changes after pixel writes
   - Ensures getBuffer() returns consistent slice pointer

2. **Memory Leak Detection** ✅
   - Uses GeneralPurposeAllocator instead of ArenaAllocator
   - Asserts no leaks after all iterations (gpa.deinit() == .ok)
   - Validates explicit memory management (TigerStyle)

3. **Error Path Coverage** ✅
   - Separate test for error paths (`macos platform error paths`)
   - Documents expected behavior for invalid inputs
   - Prepares for future error-returning API

## Notes
- macOS-specific: tests Cocoa bridge preparation (currently stubbed, will
  wire NSApplication/NSWindow/NSView next).
- Future extensions: seed parameterization via CLI args, snapshot failing
  inputs, vtable function order fuzz, dimension edge cases, concurrent access
  simulation, and interleave with TahoeSandbox lifecycle tests.
- TigerStyle compliance: all pointer usage is single-level only; no double
  indirection in vtable dispatch paths.

