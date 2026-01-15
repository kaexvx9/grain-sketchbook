# Core 1b Network Agent: Auth Middleware Integration Design

**Date**: 2026-01-02-003500-pst  
**Agent**: Core 1b Network Agent (L2 Sub-Agent)  
**Parent Agent**: Core 1 Subcore Agent (Agent 1, L1 Subcore)  
**Status**: 🆕 **DESIGN DOCUMENT** — Prepared for Auth Agent (1a) coordination  
**Voice**: Glow G2 (calm, solution-focused, forward-looking)

---

## Executive Summary

This document designs the authentication middleware integration between Network Agent (1b) and Auth Agent (1a). This is preparation work that can proceed independently while waiting for Auth Agent coordination facilitation. The design will be refined during the API contract design session.

**Goal**: Enable HTTP server to extract user/group IDs from authenticated requests for file transfer operations, replacing default values (1, 1) with actual user context.

**Status**: Design prepared, ready for coordination session with Auth Agent (1a).

---

## Current State

### Network Agent Side

**Current Implementation**:
- Rate limiting middleware implemented (`src/grain_core/middleware.zig`)
- Middleware chain execution ready (`src/grain_core/api_server.zig`)
- File transfer handlers use default user_id/group_id (1, 1)
- HTTP request structure ready for header extraction

**What's Needed**:
- User context extraction from JWT token
- Group ID lookup from user ID
- Authentication validation
- Middleware integration point

---

## Proposed API Contract

### User Context Extraction Function

**Function Signature** (proposed):
```zig
// Extract user context from HTTP request
// Returns true if authentication successful, false otherwise
pub fn extract_user_context(
    request: *api_server.HttpRequest,
    user_id_out: *u32,
    group_id_out: *u32,
) bool {
    // Implementation will:
    // 1. Extract Authorization header
    // 2. Parse JWT token
    // 3. Validate token with Auth Agent
    // 4. Extract user_id from token
    // 5. Lookup group_id from user_id (via Auth Agent)
    // 6. Return true if successful, false if authentication fails
}
```

**Error Handling**:
- Return `false` if Authorization header missing
- Return `false` if JWT token invalid
- Return `false` if token validation fails
- Return `false` if user_id/group_id lookup fails

**Integration Point**:
- Called before file transfer handlers
- Passes user_id/group_id to `IntegratedFileIO` operations
- Replaces default values (1, 1)

---

### Authentication Middleware Function

**Function Signature** (proposed):
```zig
// Authentication middleware for HTTP server
pub fn auth_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
) bool {
    // Implementation will:
    // 1. Extract user context (using extract_user_context)
    // 2. Attach user context to request (via request context)
    // 3. Return true to continue, false to return 401 Unauthorized
}
```

**Integration**:
- Added to middleware chain before file transfer handlers
- Can be applied to specific routes or globally
- Returns 401 Unauthorized if authentication fails

---

## Integration Approach

### Step 1: API Contract Design Session

**What We Need**:
- Coordinate with Auth Agent (1a) on function signatures
- Agree on error handling approach
- Design request context structure for user_id/group_id
- Plan token validation API

**Timeline**: When Core 1 Subcore facilitates coordination session

---

### Step 2: Implementation

**Network Agent Side**:
1. Implement `extract_user_context()` function
2. Implement `auth_middleware()` function
3. Update file transfer handlers to use extracted user/group IDs
4. Add middleware to API server middleware chain
5. Create integration tests

**Auth Agent Side** (coordination needed):
1. Provide token validation API
2. Provide user_id extraction from JWT
3. Provide group_id lookup from user_id

**Timeline**: 1-2 weeks after API contract agreed

---

### Step 3: Testing

**Integration Tests**:
- Test authentication middleware with valid tokens
- Test authentication middleware with invalid tokens
- Test file transfer with authenticated users
- Test file transfer with unauthenticated requests (should fail)
- Test user/group ID extraction accuracy

**Timeline**: After implementation complete

---

## Design Considerations

### Grain Style Compliance

**All Functions**:
- ≤ 70 lines (`grain validate-70`)
- ≤ 100 characters per line (`grainwrap-100`)
- Explicit `u32`/`u64` types (no `usize`/`isize`)
- Minimum 2 assertions per function
- Bounded allocations with MAX_ constants

**Error Handling**:
- Explicit error types
- Clear error propagation
- Graceful degradation

---

### Security Considerations

**Token Validation**:
- Validate token signature
- Validate token expiration
- Validate token claims
- Handle token revocation

**User Context**:
- Verify user_id is valid
- Verify group_id is valid
- Handle missing user/group gracefully

**Request Context**:
- Store user context securely
- Clear user context after request
- Prevent context leakage

---

## Coordination Points

### With Auth Agent (1a)

**API Contract Design**:
- Function signatures
- Error handling approach
- Token validation API
- User/group ID lookup API

**Implementation Coordination**:
- Token validation implementation
- User context extraction implementation
- Integration testing approach

**Timeline**: When Core 1 Subcore facilitates coordination

---

### With Core 1 Subcore

**Coordination Facilitation**:
- Facilitate API contract design session
- Review and approve API contracts
- Coordinate integration timeline

**Check-In**: Will check in before starting integration work

---

## Next Steps

### Immediate (Independent Work)

1. **Refine Design Document**:
   - Add more detail to API contract proposals
   - Design request context structure
   - Plan error handling approach

2. **Prepare for Coordination Session**:
   - List questions for Auth Agent
   - Prepare integration scenarios
   - Design test cases

3. **Continue Network Services Development**:
   - Work on other network services independently
   - Framework x86 adaptation as needed

---

### After Coordination Session

1. **Implement API Contract**:
   - Implement agreed-upon function signatures
   - Integrate with Auth Agent APIs
   - Update file transfer handlers

2. **Create Integration Tests**:
   - Test authentication middleware
   - Test user context extraction
   - Test file transfer with authentication

3. **Document Integration**:
   - Document API contracts
   - Document integration patterns
   - Update coordination documents

---

## Summary

**Status**: ✅ **DESIGN DOCUMENT PREPARED** — Ready for Auth Agent coordination

**Current State**:
- Design document created
- API contract proposals prepared
- Integration approach planned
- Ready for coordination session

**Next Steps**:
- Await Core 1 Subcore facilitation of coordination session
- Refine design based on coordination feedback
- Implement after API contracts agreed

**No Blockers**: Design work can proceed independently, implementation blocked on coordination

---

**Date**: 2026-01-02-003500-pst  
**Agent**: Core 1b Network Agent (L2 Sub-Agent)  
**Parent Agent**: Core 1 Subcore Agent (Agent 1, L1 Subcore)  
**Status**: ✅ **DESIGN DOCUMENT PREPARED** — Ready for Auth Agent coordination

---

