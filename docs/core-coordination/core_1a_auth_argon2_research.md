# Argon2 Implementation Research

**Date**: 2025-12-30-235600-pst  
**Agent**: Grain Auth Agent (1a)  
**Purpose**: Research Argon2 implementation options for Phase 2

---

## Executive Summary

**Decision Needed**: Pure Zig Argon2 implementation vs library integration

**Recommendation**: **Pure Zig Implementation** (maintains zero-dependency policy)

**Rationale**: Grain OS has zero-dependency policy. Pure Zig implementation is feasible and maintains project philosophy.

---

## Argon2 Overview

### Specification
- **RFC**: RFC 9106 (https://www.rfc-editor.org/rfc/rfc9106)
- **Purpose**: Memory-hard password hashing function
- **Winner**: Password Hashing Competition (PHC) 2015

### Variants
1. **Argon2id** (Recommended)
   - Hybrid of Argon2i and Argon2d
   - Best security for password hashing
   - Resistant to both side-channel and GPU attacks

2. **Argon2i**
   - Data-independent memory access
   - Resistant to side-channel attacks
   - Slower than Argon2id

3. **Argon2d**
   - Data-dependent memory access
   - Resistant to GPU attacks
   - Faster than Argon2i

### Parameters
- **Memory (m)**: Memory cost (in KB, typically 65536 KB = 64 MB)
- **Time (t)**: Number of iterations (typically 2-3)
- **Parallelism (p)**: Number of threads/lanes (typically 1-4)

---

## Implementation Options

### Option 1: Pure Zig Implementation ✅ **RECOMMENDED**

**Pros**:
- ✅ Maintains zero-dependency policy
- ✅ Full control over implementation
- ✅ No external dependencies
- ✅ Can optimize for RISC-V
- ✅ Follows Grain OS philosophy

**Cons**:
- ❌ Requires implementation work (~2-3 weeks)
- ❌ Need to ensure RFC 9106 compliance
- ❌ More code to maintain

**Implementation Approach**:
1. Use RFC 9106 as reference specification
2. Reference RustCrypto implementation (pure Rust, well-tested)
3. Reference C reference implementation from PHC
4. Implement Argon2id variant first (recommended for passwords)
5. Follow Grain Style strictly (70-line functions, explicit types)

**Estimated Effort**: 2-3 weeks

**Feasibility**: ✅ High (straightforward cryptographic algorithm)

---

### Option 2: Library Integration (libargon2)

**Pros**:
- ✅ Battle-tested implementation
- ✅ Faster to integrate (~1 day)
- ✅ Well-maintained

**Cons**:
- ❌ Violates zero-dependency policy
- ❌ C library dependency (build complexity)
- ❌ Potential security risks (supply chain)
- ❌ Less control over implementation

**Verdict**: ❌ **NOT RECOMMENDED** (violates zero-dependency policy)

---

### Option 3: Zig Package (if available)

**Pros**:
- ✅ Zig-native implementation
- ✅ Easier integration than C library

**Cons**:
- ❌ Still a dependency (violates zero-dependency policy)
- ❌ May not exist or may be incomplete
- ❌ Dependency maintenance overhead

**Verdict**: ❌ **NOT RECOMMENDED** (violates zero-dependency policy)

---

## Pure Zig Implementation Plan

### Phase 2.1: Core Argon2 Algorithm

**Components Needed**:
1. **Blake2b Hash Function**
   - Argon2 uses Blake2b internally
   - Zig standard library has `std.crypto.hash.blake2.Blake2b`
   - ✅ Available in Zig standard library

2. **Argon2 Core Function**
   - Implement Argon2id variant
   - Memory-hard function (fills memory with pseudorandom values)
   - Iterative compression

3. **Parameter Handling**
   - Memory cost (m)
   - Time cost (t)
   - Parallelism (p)
   - Salt and secret handling

4. **Hash Encoding/Decoding**
   - Argon2 hash string format: `$argon2id$v=19$m=65536,t=2,p=1$salt$hash`
   - Parse and generate hash strings

### Implementation Steps

1. **Implement Blake2b wrapper** (if needed)
   - Zig standard library provides `std.crypto.hash.blake2.Blake2b`
   - May need to wrap for Argon2-specific usage

2. **Implement Argon2 core function**
   - Reference RFC 9106 Section 3.2 (Argon2id Algorithm)
   - Implement `argon2id` function
   - Handle memory allocation (bounded with MAX_ constants)

3. **Implement hash generation**
   - `hash_argon2id()` function
   - Takes password, salt, and parameters
   - Returns encoded hash string

4. **Implement hash verification**
   - `verify_argon2id()` function
   - Parses hash string
   - Verifies password against hash

5. **Add migration support**
   - Detect hash format (SHA-256 vs Argon2)
   - Rehash SHA-256 passwords to Argon2 on login

### Code Structure

```
src/grain_core/auth_service.zig
├── Existing SHA-256 functions (for backward compatibility)
├── Argon2 implementation:
│   ├── blake2b_hash_for_argon2() — Blake2b for Argon2
│   ├── argon2id_core() — Core Argon2id algorithm
│   ├── hash_argon2id() — Hash password with Argon2id
│   ├── verify_argon2id() — Verify password against Argon2id hash
│   ├── parse_argon2_hash() — Parse Argon2 hash string
│   └── format_argon2_hash() — Format Argon2 hash string
├── Migration functions:
│   ├── detect_hash_format() — Detect SHA-256 vs Argon2
│   └── rehash_password() — Rehash SHA-256 → Argon2
└── Updated password functions:
    ├── hash_password_static() — Support both formats
    └── verify_password_static() — Support both formats
```

### Constants Needed

```zig
// Argon2 parameters
pub const ARGON2_SALT_LEN: u32 = 16;  // Argon2 salt length (RFC 9106)
pub const ARGON2_HASH_LEN: u32 = 32;  // Argon2 hash output length
pub const ARGON2_MEMORY_DEFAULT: u32 = 65536;  // 64 MB (in KB)
pub const ARGON2_TIME_DEFAULT: u32 = 2;  // 2 iterations
pub const ARGON2_PARALLELISM_DEFAULT: u32 = 1;  // Single-threaded
pub const ARGON2_MAX_MEMORY: u32 = 1048576;  // 1 GB (in KB)
pub const ARGON2_MAX_TIME: u32 = 10;
pub const ARGON2_MAX_PARALLELISM: u32 = 4;

// Hash format detection
pub const HASH_FORMAT_SHA256: u8 = 0;
pub const HASH_FORMAT_ARGON2ID: u8 = 1;
```

### Grain Style Considerations

**Memory Allocation**:
- Argon2 requires significant memory (64 MB default)
- Use static allocation where possible
- Use bounded MAX_ constants for memory usage
- Assert memory bounds in all functions

**Function Length**:
- Argon2 core algorithm may be complex
- Break into smaller helper functions
- Each function ≤ 70 lines
- Focused responsibilities

**Explicit Types**:
- Use `u32`/`u64` consistently
- No `usize`/`isize`
- Clear memory size calculations

---

## Reference Implementations

### C Reference Implementation
- **Source**: https://github.com/P-H-C/phc-winner-argon2
- **License**: CC0 or Apache 2.0
- **Use**: Reference for algorithm correctness

### Rust Implementation (RustCrypto)
- **Source**: https://github.com/RustCrypto/password-hashes/tree/master/argon2
- **License**: Apache 2.0 or MIT
- **Use**: Reference for pure language implementation approach

### RFC 9106
- **Source**: https://www.rfc-editor.org/rfc/rfc9106
- **Use**: Authoritative specification

---

## Security Considerations

### Parameter Selection

**Recommended Parameters** (from OWASP):
- **Memory**: 65536 KB (64 MB)
- **Time**: 2-3 iterations
- **Parallelism**: 1-2 threads

**Why**:
- Balance between security and performance
- ~100ms hashing time (acceptable user experience)
- Resistant to GPU/ASIC attacks

### Constant-Time Operations

- ✅ Password comparison already uses `std.mem.eql()` (constant-time)
- ✅ Argon2 memory access patterns are data-dependent (Argon2id mitigates)
- ⚠️ Need to ensure no timing leaks in hash comparison

---

## Performance Considerations

### Target Performance

- **Hashing**: < 100ms (user experience)
- **Verification**: < 100ms (user experience)
- **Memory Usage**: 64 MB (acceptable for RISC-V systems)

### Optimization Opportunities

- Use SIMD instructions if available on RISC-V
- Optimize Blake2b usage (Zig stdlib may already be optimized)
- Cache-friendly memory access patterns

---

## Testing Strategy

### Unit Tests

1. **Argon2 Core Tests**
   - Test against RFC 9106 test vectors
   - Test against C reference implementation test vectors
   - Test parameter validation

2. **Hash Format Tests**
   - Test hash string generation
   - Test hash string parsing
   - Test invalid hash format handling

3. **Migration Tests**
   - Test hash format detection
   - Test SHA-256 → Argon2 rehashing
   - Test backward compatibility

### Integration Tests

1. **Password Flow Tests**
   - Hash password with Argon2
   - Verify password against Argon2 hash
   - Verify migration path

---

## Coordination Needed

### With Core 1 Subcore (L1)

**Decision Request**:
1. **Approval for pure Zig implementation** (recommended)
2. **Parameter selection** (memory, time, parallelism)
3. **Migration strategy** (immediate vs gradual)

**Questions**:
- Should we implement Argon2id only, or all variants?
- What memory/time parameters for production?
- When to start migration (immediate or after testing)?

### With Storage Agent (1c) (L2)

**Future Coordination**:
- Hash storage format in database
- Migration of existing password hashes
- Hash format metadata storage

---

## Implementation Timeline

### Phase 2.1: Argon2 Core Implementation (1 week)
- Implement Blake2b wrapper for Argon2
- Implement Argon2id core algorithm
- Add comprehensive tests

### Phase 2.2: Hash Format & Migration (3-4 days)
- Implement hash string encoding/decoding
- Implement hash format detection
- Implement SHA-256 → Argon2 migration
- Add migration tests

### Phase 2.3: Integration & Testing (2-3 days)
- Update password hashing API
- Add comprehensive tests
- Performance testing
- Documentation

**Total Estimated Time**: 2 weeks

---

## Recommendation

✅ **Proceed with Pure Zig Implementation**

**Reasons**:
1. Maintains zero-dependency policy
2. Feasible implementation (~2 weeks)
3. Full control over security and performance
4. Follows Grain OS philosophy
5. Zig standard library provides Blake2b (no crypto dependency)

**Next Steps**:
1. Get approval from Core 1 Subcore
2. Start Phase 2.1: Argon2 core implementation
3. Reference RFC 9106 and RustCrypto implementation

---

**Date**: 2025-12-30-235600-pst  
**Agent**: Grain Auth Agent (1a)  
**Status**: Research Complete — Ready for Core 1 Subcore Decision

---
