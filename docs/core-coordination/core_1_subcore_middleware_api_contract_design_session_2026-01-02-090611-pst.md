# Core 1 Subcore: Middleware API Contract Design Session

**Date**: 2026-01-02-090611-pst  
**Agent**: Grain Core 1 Subcore Agent (facilitating)  
**Participants**: Auth Agent (1a) ↔ Network Agent (1b)  
**Purpose**: Facilitate middleware API contract design session for Auth ↔ Network integration  
**Status**: ✅ **SESSION PLAN READY** — Ready for agent coordination

---

## Executive Summary

This document facilitates a middleware API contract design session between **Auth Agent (1a)** and **Network Agent (1b)** to establish clear API contracts for middleware integration. Both agents have prepared design documents and are ready for coordination.

**Goal**: Design and agree upon middleware API contracts that enable:
- JWT token validation
- CSRF protection
- Rate limiting integration
- RBAC permission checking
- API key validation

**Current Status**:
- ✅ Auth Agent (1a): Middleware integration ready, detailed design patterns prepared
- ✅ Network Agent (1b): Middleware infrastructure ready, integration design prepared
- ⏳ **BLOCKER**: API contract design session needed to agree on contracts

---

## Session Agenda

### 1. Review Current Middleware Infrastructure (15 minutes)

**Network Agent (1b) Presents**:
- Current middleware function signature: `Middleware = *const fn (*HttpRequest, *HttpResponse) bool`
- Middleware chain execution pattern
- Existing middleware (CORS, logging, rate limiting stub, auth stub, content-type)
- Route middleware storage (up to 8 middleware per route)

**Discussion Points**:
- How does current middleware pattern work?
- What are the limitations of current pattern?
- What needs to change for Auth integration?

### 2. Review Auth Agent Middleware Requirements (15 minutes)

**Auth Agent (1a) Presents**:
- 5 middleware functions needed: JWT auth, CSRF, rate limiting, RBAC, API key
- Preferred pattern: Context-based middleware
- Function signature proposal: `fn middleware(request, response, ctx) bool`
- Context requirements: `AuthService`, `current_time`, `user_id`, `roles`

**Discussion Points**:
- What middleware functions are needed?
- What context/data is required?
- How should context be passed to middleware?

### 3. Design Middleware API Contracts (30 minutes)

**Key Design Decisions**:

1. **Middleware Function Signature**:
   - Current: `*const fn (*HttpRequest, *HttpResponse) bool`
   - Proposed: `*const fn (*HttpRequest, *HttpResponse, *MiddlewareContext) bool`
   - **Decision**: Agree on final signature

2. **Middleware Context Structure**:
   - What fields are needed?
   - How is `AuthService` passed?
   - How is user context stored?
   - **Decision**: Define `MiddlewareContext` struct

3. **Middleware Execution Order**:
   - What order should middleware execute?
   - How does early termination work?
   - **Decision**: Define middleware execution order

4. **Error Handling**:
   - How are errors returned from middleware?
   - What error response format?
   - **Decision**: Define error handling pattern

5. **Request Context**:
   - How is user context stored in request?
   - How do handlers access user context?
   - **Decision**: Define request context structure

### 4. Define Integration Points (15 minutes)

**Integration Points to Define**:
1. **JWT Validation Middleware**:
   - How is JWT extracted from Authorization header?
   - How is JWT validated?
   - How is user context stored?

2. **CSRF Protection Middleware**:
   - How is CSRF token extracted?
   - How is CSRF token validated?
   - When is CSRF required?

3. **Rate Limiting Middleware**:
   - How does Auth rate limiting integrate with Network rate limiting?
   - How are rate limits checked?
   - How are rate limit errors returned?

4. **RBAC Permission Checking Middleware**:
   - How are permissions checked?
   - How are permission errors returned?
   - How are roles extracted from JWT?

5. **API Key Validation Middleware**:
   - How are API keys extracted?
   - How are API keys validated?
   - How are scopes checked?

### 5. Create API Contract Document (15 minutes)

**Deliverable**: Agreed-upon API contract document with:
- Middleware function signatures
- Middleware context structure
- Request context structure
- Error handling patterns
- Integration point specifications
- Example usage

---

## Current State Analysis

### Network Agent (1b) - Current Middleware Infrastructure

**Existing Middleware Pattern**:
```zig
pub const Middleware = *const fn (*HttpRequest, *HttpResponse) bool;
```

**Current Implementation**:
- `cors_middleware()` - CORS headers ✅
- `logging_middleware()` - Request logging (stub) ✅
- `rate_limit_middleware()` - Rate limiting (uses global rate limiter) ✅
- `auth_middleware()` - JWT authentication (stub, doesn't validate) ⚠️
- `content_type_middleware()` - Content-Type validation ✅

**Middleware Chain Execution**:
- `execute_middleware_chain()` - Executes middleware in order, early termination on `false`
- `add_middleware_to_route()` - Adds middleware to route (up to 8 per route)

**Limitations**:
- No way to pass `AuthService` instance to middleware
- No request context for storing user information
- Auth middleware is stub (doesn't validate JWT)

### Auth Agent (1a) - Middleware Requirements

**5 Middleware Functions Needed**:
1. **JWT Validation Middleware**: Extract and validate JWT from Authorization header
2. **CSRF Protection Middleware**: Validate CSRF tokens on state-changing requests
3. **Rate Limiting Middleware**: Check rate limits before request processing
4. **RBAC Permission Checking Middleware**: Check permissions for protected routes
5. **API Key Validation Middleware**: Validate API keys for API endpoints

**Preferred Pattern**: Context-based middleware
- Function signature: `fn middleware(request, response, ctx) bool`
- Context includes: `AuthService`, `current_time`, `user_id`, `roles`

**Integration Requirements**:
- `AuthService` instance passed via middleware context
- Current time generated once per request
- User context (user_id, roles) stored in request context
- Error format: `{"error": "error_type", "message": "description"}`
- Performance: JWT < 1ms, rate limiting < 0.1ms

---

## Proposed API Contract Design

### Option A: Context-Based Middleware (Auth Agent Preferred)

**Middleware Function Signature**:
```zig
pub const Middleware = *const fn (
    request: *HttpRequest,
    response: *HttpResponse,
    ctx: *MiddlewareContext,
) bool;
```

**Middleware Context Structure**:
```zig
pub const MiddlewareContext = struct {
    auth_service: *auth.AuthService,
    current_time: u64, // Unix timestamp
    // Additional context as needed
};
```

**Request Context Structure**:
```zig
pub const RequestContext = struct {
    user_id: ?u32,
    group_id: ?u32,
    roles: []const []const u8,
    // Additional context as needed
};
```

**Pros**:
- ✅ Explicit context passing
- ✅ Type-safe context access
- ✅ Easy to extend with new context fields

**Cons**:
- ⚠️ Requires middleware signature change
- ⚠️ Breaking change for existing middleware

### Option B: Request Context Only (Minimal Change)

**Middleware Function Signature** (unchanged):
```zig
pub const Middleware = *const fn (*HttpRequest, *HttpResponse) bool;
```

**Request Context Structure**:
```zig
pub const RequestContext = struct {
    auth_service: *auth.AuthService, // Stored in request
    current_time: u64,
    user_id: ?u32,
    group_id: ?u32,
    roles: []const []const u8,
};
```

**Pros**:
- ✅ No breaking change to middleware signature
- ✅ All context in request
- ✅ Easy to access from handlers

**Cons**:
- ⚠️ Request structure becomes more complex
- ⚠️ Less explicit context passing

### Option C: Hybrid Approach (Recommended)

**Middleware Function Signature**:
```zig
pub const Middleware = *const fn (
    request: *HttpRequest,
    response: *HttpResponse,
    ctx: ?*MiddlewareContext, // Optional for backward compatibility
) bool;
```

**Middleware Context Structure**:
```zig
pub const MiddlewareContext = struct {
    auth_service: *auth.AuthService,
    current_time: u64,
};
```

**Request Context Structure**:
```zig
pub const RequestContext = struct {
    user_id: ?u32,
    group_id: ?u32,
    roles: []const []const u8,
};
```

**Pros**:
- ✅ Backward compatible (optional context)
- ✅ Explicit context for Auth middleware
- ✅ Request context for user information
- ✅ Gradual migration path

**Cons**:
- ⚠️ Slightly more complex

---

## Integration Point Specifications

### 1. JWT Validation Middleware

**Function**: `jwt_validation_middleware(request, response, ctx) bool`

**Behavior**:
1. Extract `Authorization` header from request
2. Parse JWT token from header (format: `Bearer <token>`)
3. Validate JWT using `AuthService.validate_jwt()`
4. Extract user_id and roles from JWT claims
5. Store user context in request context
6. Return `true` if valid, `false` if invalid

**Error Handling**:
- Missing Authorization header → `401 Unauthorized`
- Invalid JWT format → `401 Unauthorized`
- Invalid JWT signature → `401 Unauthorized`
- Expired JWT → `401 Unauthorized`

### 2. CSRF Protection Middleware

**Function**: `csrf_protection_middleware(request, response, ctx) bool`

**Behavior**:
1. Check if request is state-changing (POST, PUT, DELETE, PATCH)
2. Extract CSRF token from header (`X-CSRF-Token`) or form data
3. Validate CSRF token using `AuthService.validate_csrf_token()`
4. Return `true` if valid, `false` if invalid

**Error Handling**:
- Missing CSRF token → `403 Forbidden`
- Invalid CSRF token → `403 Forbidden`
- CSRF token expired → `403 Forbidden`

### 3. Rate Limiting Middleware

**Function**: `rate_limiting_middleware(request, response, ctx) bool`

**Behavior**:
1. Extract user_id from request context (if authenticated)
2. Check rate limit using `AuthService.check_rate_limit()`
3. Return `true` if within limit, `false` if exceeded

**Error Handling**:
- Rate limit exceeded → `429 Too Many Requests`
- Include `Retry-After` header

### 4. RBAC Permission Checking Middleware

**Function**: `rbac_permission_middleware(request, response, ctx) bool`

**Behavior**:
1. Extract user_id and roles from request context
2. Extract required permission from route metadata
3. Check permission using `AuthService.check_permission()`
4. Return `true` if permitted, `false` if not

**Error Handling**:
- Missing user context → `401 Unauthorized`
- Insufficient permissions → `403 Forbidden`

### 5. API Key Validation Middleware

**Function**: `api_key_validation_middleware(request, response, ctx) bool`

**Behavior**:
1. Extract API key from header (`X-API-Key`) or query parameter
2. Validate API key using `AuthService.validate_api_key()`
3. Extract scopes from API key
4. Store API key context in request context
5. Return `true` if valid, `false` if invalid

**Error Handling**:
- Missing API key → `401 Unauthorized`
- Invalid API key → `401 Unauthorized`
- Insufficient scopes → `403 Forbidden`

---

## Middleware Execution Order

**Recommended Order**:
1. **CORS Middleware** (first, handles preflight)
2. **Logging Middleware** (log all requests)
3. **Content-Type Middleware** (validate content type)
4. **JWT Validation Middleware** (authenticate user)
5. **CSRF Protection Middleware** (protect state-changing requests)
6. **Rate Limiting Middleware** (check rate limits)
7. **RBAC Permission Middleware** (check permissions)
8. **API Key Validation Middleware** (validate API keys, if needed)

**Early Termination**:
- If any middleware returns `false`, chain execution stops
- Response is sent with appropriate error status
- Subsequent middleware are not executed

---

## Error Response Format

**Standard Error Response**:
```json
{
  "error": "error_type",
  "message": "human-readable error message",
  "details": {} // Optional additional details
}
```

**Error Types**:
- `unauthorized` - Authentication failed (401)
- `forbidden` - Authorization failed (403)
- `rate_limit_exceeded` - Rate limit exceeded (429)
- `invalid_request` - Invalid request format (400)
- `internal_error` - Internal server error (500)

---

## Request Context Access

**From Handlers**:
```zig
// Access user context from request
const user_id = request.context.user_id orelse return error.Unauthorized;
const roles = request.context.roles;
```

**From Middleware**:
```zig
// Store user context in request
request.context.user_id = user_id;
request.context.roles = roles;
```

---

## Example Usage

### Registering Middleware

```zig
// Add JWT validation middleware to route
try api_server.add_middleware_to_route(
    route,
    auth_middleware.jwt_validation_middleware,
);

// Add RBAC permission middleware
try api_server.add_middleware_to_route(
    route,
    auth_middleware.rbac_permission_middleware,
);
```

### Middleware Implementation

```zig
pub fn jwt_validation_middleware(
    request: *HttpRequest,
    response: *HttpResponse,
    ctx: *MiddlewareContext,
) bool {
    // Extract Authorization header
    const auth_header = request.get_header("Authorization") orelse {
        response.status = 401;
        response.body = "{\"error\":\"unauthorized\",\"message\":\"Missing Authorization header\"}";
        return false;
    };
    
    // Parse JWT token
    const token = extract_bearer_token(auth_header) orelse {
        response.status = 401;
        response.body = "{\"error\":\"unauthorized\",\"message\":\"Invalid Authorization header format\"}";
        return false;
    };
    
    // Validate JWT
    const claims = ctx.auth_service.validate_jwt(token) catch |err| {
        response.status = 401;
        response.body = "{\"error\":\"unauthorized\",\"message\":\"Invalid JWT token\"}";
        return false;
    };
    
    // Store user context
    request.context.user_id = claims.user_id;
    request.context.roles = claims.roles;
    
    return true;
}
```

---

## Session Deliverables

### Immediate Deliverables

1. **Agreed API Contract Document**:
   - Middleware function signature
   - Middleware context structure
   - Request context structure
   - Error handling patterns
   - Integration point specifications

2. **Example Implementation**:
   - Example middleware function
   - Example handler using request context
   - Example error responses

### Post-Session Deliverables

1. **Auth Agent (1a)**:
   - Implement 5 middleware functions
   - Create middleware tests
   - Update coordination documents

2. **Network Agent (1b)**:
   - Update middleware infrastructure (if needed)
   - Integrate Auth middleware
   - Update file transfer handlers to use user context
   - Create integration tests

---

## Questions for Discussion

### Design Questions

1. **Middleware Signature**: Which option (A, B, or C) should we use?
2. **Context Passing**: How should `AuthService` be passed to middleware?
3. **Request Context**: How should user context be stored in request?
4. **Error Handling**: What error response format should we use?
5. **Execution Order**: What order should middleware execute?

### Implementation Questions

1. **Backward Compatibility**: How do we handle existing middleware?
2. **Migration Path**: How do we migrate to new middleware pattern?
3. **Testing**: How do we test middleware integration?
4. **Performance**: What are the performance requirements?

---

## Next Steps

### For Auth Agent (1a)

1. ✅ Review Network Agent middleware infrastructure
2. ✅ Participate in API contract design session
3. ✅ Agree on middleware API contracts
4. ✅ Implement middleware functions
5. ✅ Create middleware tests
6. ✅ Update coordination documents

### For Network Agent (1b)

1. ✅ Review Auth Agent middleware requirements
2. ✅ Participate in API contract design session
3. ✅ Agree on middleware API contracts
4. ✅ Update middleware infrastructure (if needed)
5. ✅ Integrate Auth middleware
6. ✅ Update file transfer handlers
7. ✅ Create integration tests

### For Core 1 Subcore

1. ✅ Facilitate API contract design session
2. ✅ Document agreed-upon API contracts
3. ✅ Monitor implementation progress
4. ✅ Unblock any integration issues

---

## Coordination Schedule

**Session Duration**: 90 minutes

**Session Format**: 
- Virtual coordination session (via documentation and async communication)
- Or synchronous session if agents prefer

**Follow-Up**:
- Weekly check-ins during implementation
- Immediate check-ins for blockers
- Final review when integration complete

---

**Date**: 2026-01-02-090611-pst  
**Agent**: Grain Core 1 Subcore Agent (facilitating)  
**Status**: ✅ **SESSION PLAN COMPLETE** — Ready for agent coordination

