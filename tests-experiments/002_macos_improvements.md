# macOS Platform Fuzz Test Improvements — TigerStyle

Date: 12025-11-12--0945-pst  
Operator: Glow G2 (Stoic Aquarian cadence)

## Suggested Improvements

### 1. Seed Parameterization
- Add CLI argument support for RNG seed via `@import("builtin").test_framework`.
- Why: Enables reproducible failure reproduction and deterministic test runs.
- Implementation: Parse seed from test args, default to fixed seed for CI.

### 2. Buffer Content Validation
- Compare buffer contents before/after operations to detect corruption.
- Why: Catches silent buffer corruption that assertions might miss.
- Implementation: Hash buffer contents (CRC32 or simple checksum) and assert
  consistency across getBuffer() calls.

### 3. Error Path Coverage
- Test invalid inputs: empty titles, zero-length buffers, out-of-bounds writes.
- Why: Validates error handling paths follow TigerStyle safety guarantees.
- Implementation: Separate test cases for negative paths with expected errors.

### 4. Memory Leak Detection
- Track allocator allocations/deallocations across lifecycle cycles.
- Why: Ensures deinit() properly cleans up all resources (TigerStyle explicit
  memory management).
- Implementation: Use test allocator with allocation counting, assert zero
  leaks after deinit.

### 5. VTable Function Order Fuzz
- Randomize order of vtable calls (not just sequence, but also repetition).
- Why: Tests that vtable functions are idempotent and order-independent.
- Implementation: Generate random call sequences with repetition, validate
  consistency.

### 6. Dimension Edge Cases
- Test minimum/maximum valid dimensions, power-of-two sizes, odd dimensions.
- Why: Validates platform handles edge cases correctly (currently fixed 1024x768).
- Implementation: Extend platform API to accept dimensions, fuzz various sizes.

### 7. Concurrent Access Simulation
- Simulate concurrent buffer access patterns (read-while-write scenarios).
- Why: Prepares for future multi-threaded rendering (though currently single-threaded).
- Implementation: Track buffer access patterns, validate no corruption.

### 8. Integration with TahoeSandbox
- Interleave platform fuzz with TahoeSandbox lifecycle tests.
- Why: Ensures end-to-end correctness from platform abstraction to Aurora UI.
- Implementation: Create combined test that exercises both layers together.

## Priority Order (TigerStyle: Safety First)
1. **Buffer Content Validation** (highest priority: catches silent bugs)
2. **Memory Leak Detection** (critical: ensures resource cleanup)
3. **Error Path Coverage** (safety: validates error handling)
4. **Seed Parameterization** (developer experience: enables debugging)
5. **VTable Function Order Fuzz** (robustness: tests idempotency)
6. **Dimension Edge Cases** (future-proofing: prepares for dynamic sizes)
7. **Concurrent Access Simulation** (future-proofing: prepares for threading)
8. **Integration with TahoeSandbox** (end-to-end: validates full stack)

