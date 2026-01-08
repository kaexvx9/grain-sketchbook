# Core 1b Network Agent: Auth Middleware Implementation Plan

**Date**: 2026-01-06-093500-pst  
**Agent**: Core 1b Network Agent (L2 Sub-Agent)  
**Parent Agent**: Core 1 Subcore Agent (Agent 1, L1 Subcore)  
**Status**: 🆕 **IMPLEMENTATION PLAN** — Detailed plan for Auth Agent coordination session  
**Voice**: Glow G2 (calm, solution-focused, forward-looking)

---

## Executive Summary

This document provides a detailed implementation plan for Auth middleware integration, prepared for the Auth Agent (1a) coordination session. This plan builds on the design document and provides specific implementation details, code locations, and integration points.

**Goal**: Replace default user_id/group_id (1, 1) with actual user context extracted from authenticated HTTP requests.

**Status**: Implementation plan prepared, ready for coordination session.

---

## Current Implementation Analysis

### File Transfer Handlers Current State

**File**: `src/grain_core/file_transfer_handlers.zig`

**Current Implementation**:
- `FileTransferHandlers` struct has `default_user_id: u32` and `default_group_id: u32` fields
- Helper functions `write_file_data()` and `read_and_stream_file()` use hardcoded values:
  ```zig
  const user_id: u32 = 1;
  const group_id: u32 = 1;
  ```
- These are passed to `IntegratedFileIO` operations

**Integration Points**:
- Line 357-358: `write_file_data()` uses hardcoded user_id/group_id
- Line 382-383: `read_and_stream_file()` uses hardcoded user_id/group_id
- Lines 364-365, 388-389: Fallback to `default_user_id`/`default_group_id` if provided

**What Needs to Change**:
- Extract user_id/group_id from request context (set by auth middleware)
- Replace hardcoded values with extracted user context
- Handle unauthenticated requests gracefully

---

### Middleware Current State

**File**: `src/grain_core/middleware.zig`

**Current Implementation**:
- `auth_middleware()` function exists but only validates token format
- Line 166: `_ = token;` — token is extracted but not validated
- Returns `true` if token format is valid, `false` otherwise
- Does not extract user_id/group_id yet

**What Needs to Change**:
- Call Auth Agent API to validate token
- Extract user_id from validated token
- Lookup group_id from user_id
- Store user context in request for later use

---

## Proposed Implementation

### Step 1: Request Context Structure

**New Structure** (to be added to `api_server.zig` or new module):
```zig
// Request context for storing user authentication information
pub const RequestContext = struct {
    user_id: u32,
    group_id: u32,
    authenticated: bool,
    
    pub fn init() RequestContext {
        return RequestContext{
            .user_id = 0,
            .group_id = 0,
            .authenticated = false,
        };
    }
    
    pub fn set_user_context(self: *RequestContext, user_id: u32, group_id: u32) void {
        std.debug.assert(user_id > 0);
        std.debug.assert(group_id > 0);
        self.user_id = user_id;
        self.group_id = group_id;
        self.authenticated = true;
    }
};
```

**Integration Point**: Add `context: RequestContext` field to `HttpRequest` struct in `api_server.zig`

---

### Step 2: User Context Extraction Function

**Function Signature** (to be coordinated with Auth Agent):
```zig
// Extract user context from HTTP request
// Returns true if authentication successful, false otherwise
pub fn extract_user_context(
    request: *api_server.HttpRequest,
    user_id_out: *u32,
    group_id_out: *u32,
) bool {
    std.debug.assert(request != null);
    std.debug.assert(user_id_out != null);
    std.debug.assert(group_id_out != null);
    
    // 1. Extract Authorization header
    const auth_header = request.get_header("Authorization") orelse {
        return false;
    };
    
    // 2. Extract token (Bearer <token>)
    if (auth_header.len < 7) {
        return false;
    }
    if (!std.mem.startsWith(u8, auth_header, "Bearer ")) {
        return false;
    }
    const token = auth_header[7..];
    if (token.len == 0) {
        return false;
    }
    
    // 3. Validate token with Auth Agent (COORDINATION NEEDED)
    // auth_service.validate_token(token) -> bool
    
    // 4. Extract user_id from token (COORDINATION NEEDED)
    // auth_service.extract_user_id(token) -> ?u32
    
    // 5. Lookup group_id from user_id (COORDINATION NEEDED)
    // auth_service.get_group_id(user_id) -> ?u32
    
    // 6. Return true if successful
    return true;
}
```

**Coordination Points**:
- Auth Agent API for token validation
- Auth Agent API for user_id extraction
- Auth Agent API for group_id lookup

---

### Step 3: Enhanced Auth Middleware

**Updated Function** (in `middleware.zig`):
```zig
// Authentication middleware: Validate token and extract user context
pub fn auth_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
) bool {
    std.debug.assert(request != null);
    std.debug.assert(response != null);
    
    var user_id: u32 = 0;
    var group_id: u32 = 0;
    
    if (!extract_user_context(request, &user_id, &group_id)) {
        write_json_error_response(
            response,
            api_server.HttpStatus.unauthorized,
            "{\"error\":\"unauthorized\",\"message\":\"Authentication failed\"}",
        );
        return false;
    }
    
    // Store user context in request
    request.context.set_user_context(user_id, group_id);
    
    return true;
}
```

**Integration**: Add to middleware chain before file transfer handlers

---

### Step 4: Update File Transfer Handlers

**Updated Helper Functions** (in `file_transfer_handlers.zig`):

**Before**:
```zig
const user_id: u32 = 1;
const group_id: u32 = 1;
```

**After**:
```zig
// Extract user context from request (set by auth middleware)
const user_id: u32 = if (request.context.authenticated)
    request.context.user_id
else
    self.default_user_id;

const group_id: u32 = if (request.context.authenticated)
    request.context.group_id
else
    self.default_group_id;
```

**Integration Points**:
- `write_file_data()` function (line ~357)
- `read_and_stream_file()` function (line ~382)

---

## Coordination Questions for Auth Agent (1a)

### API Contract Questions

1. **Token Validation API**:
   - Function signature for token validation?
   - Return type (bool, error union, result struct)?
   - Error handling approach?

2. **User ID Extraction**:
   - Function signature for extracting user_id from token?
   - What if token is invalid or expired?
   - Error handling approach?

3. **Group ID Lookup**:
   - Function signature for group_id lookup from user_id?
   - What if user_id doesn't exist?
   - Error handling approach?

4. **Token Format**:
   - JWT token format expected?
   - Token claims structure?
   - Token expiration handling?

5. **Integration Pattern**:
   - Direct function calls or service interface?
   - Synchronous or asynchronous?
   - Error propagation approach?

### Implementation Questions

6. **Request Context**:
   - Should user context be stored in HttpRequest struct?
   - Or passed as separate parameter?
   - Thread-safety considerations?

7. **Middleware Chain**:
   - Should auth middleware be required for all routes?
   - Or optional per-route?
   - How to handle public routes?

8. **Error Responses**:
   - Standard error response format?
   - Error codes or messages?
   - Logging requirements?

---

## Implementation Timeline

### Phase 1: API Contract Design (1-2 hours)
- Coordinate with Auth Agent (1a)
- Agree on function signatures
- Design error handling approach
- Document API contracts

### Phase 2: Request Context Implementation (1-2 hours)
- Add RequestContext structure
- Integrate with HttpRequest
- Update request initialization

### Phase 3: User Context Extraction (2-3 hours)
- Implement extract_user_context() function
- Integrate with Auth Agent APIs
- Add error handling

### Phase 4: Auth Middleware Enhancement (1-2 hours)
- Update auth_middleware() function
- Integrate user context extraction
- Add request context storage

### Phase 5: File Transfer Handler Updates (2-3 hours)
- Update write_file_data() function
- Update read_and_stream_file() function
- Replace hardcoded values with extracted context

### Phase 6: Integration Testing (2-3 hours)
- Test authentication middleware
- Test user context extraction
- Test file transfer with authentication
- Test error cases

**Total Estimated Time**: 9-15 hours (1-2 weeks with coordination)

---

## Testing Plan

### Unit Tests

1. **extract_user_context() Tests**:
   - Valid token → success
   - Invalid token → failure
   - Missing header → failure
   - Expired token → failure

2. **auth_middleware() Tests**:
   - Valid token → success, context set
   - Invalid token → 401 Unauthorized
   - Missing header → 401 Unauthorized

### Integration Tests

3. **File Transfer with Authentication**:
   - Upload with valid token → success, correct user_id/group_id
   - Upload with invalid token → 401 Unauthorized
   - Download with valid token → success, correct user_id/group_id
   - Download with invalid token → 401 Unauthorized

4. **Error Cases**:
   - Token validation failure
   - User ID extraction failure
   - Group ID lookup failure

---

## Grain Style Compliance

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

## Security Considerations

### Token Validation
- Validate token signature
- Validate token expiration
- Validate token claims
- Handle token revocation

### User Context
- Verify user_id is valid
- Verify group_id is valid
- Handle missing user/group gracefully
- Clear context after request

### Request Context
- Store user context securely
- Prevent context leakage
- Clear context on error

---

## Summary

**Status**: ✅ **IMPLEMENTATION PLAN PREPARED** — Ready for Auth Agent coordination session

**Current State**:
- Implementation plan created
- Code locations identified
- Integration points documented
- Coordination questions prepared
- Testing plan defined

**Next Steps**:
- Attend Auth Agent coordination session
- Agree on API contracts
- Implement after contracts agreed
- Test integration

**No Blockers**: Implementation plan ready, waiting for coordination session

---

**Date**: 2026-01-06-093500-pst  
**Agent**: Core 1b Network Agent (L2 Sub-Agent)  
**Parent Agent**: Core 1 Subcore Agent (Agent 1, L1 Subcore)  
**Status**: ✅ **IMPLEMENTATION PLAN PREPARED** — Ready for Auth Agent coordination

---

