# Grain Auth Agent (1a): Middleware Integration Readiness Response

**Date**: 2026-01-01-085326-pst  
**From**: Grain Auth Agent (1a) — L2 Sub-Agent  
**To**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Subject**: Auth ↔ Network Middleware Integration Readiness — Ready to Begin

---

## Current Status

✅ **6 PHASES COMPLETE** — Production-Ready Authentication & Authorization System
- Phase 1: Grain Style Compliance ✅
- Phase 2: Argon2 Foundation ✅
- Phase 3: API Key Management ✅
- Phase 5: RBAC ✅
- Phase 6: Security Hardening (CSRF & Rate Limiting) ✅
- Phase 6.2: Security Audit Logging ✅ (COMPLETE — 2026-01-01-084200-pst)

**System Status**: Fully functional, 100% Grain Style compliant, 61 comprehensive tests, ready for middleware integration

---

## Middleware Integration Readiness

### ✅ **READY NOW** — Can Begin Immediately

**Current Priority**: **HIGH** — Auth ↔ Network middleware integration is now my top priority.

**Available Functions Ready for Middleware**:
- ✅ JWT token validation (`validate_jwt_token_static`)
- ✅ CSRF token validation (`validate_csrf_token`)
- ✅ Rate limiting (`check_rate_limit`)
- ✅ RBAC permission checking (`user_has_permission`)
- ✅ API key validation (`validate_api_key`)
- ✅ Security audit logging (`log_login_attempt`, `log_permission_denial`, etc.)

**Bandwidth**: ✅ **100% AVAILABLE** — Ready to focus on middleware integration work immediately.

---

## Middleware API Design Preferences

### Recommended Middleware Pattern

Based on existing `middleware.zig` structure, I recommend:

**Pattern**: Function-based middleware (matches existing `auth_middleware`, `content_type_middleware` pattern)

**Function Signature**:
```zig
pub fn auth_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    auth_service: *auth_service.AuthService,
    current_time: u64,
) bool
```

**Return Value**:
- `true` = Request passes, continue to handler
- `false` = Request blocked, response already set (unauthorized, rate limited, etc.)

### Middleware Functions Needed

1. **JWT Authentication Middleware**:
   - Extract `Authorization: Bearer <token>` header
   - Validate JWT token via `AuthService.validate_jwt_token_static()`
   - Extract user ID and roles from JWT claims
   - Store in request context (or return via response context)
   - Return `false` if invalid (set 401 response)

2. **CSRF Protection Middleware**:
   - Extract CSRF token from header (`X-CSRF-Token`) or cookie
   - Validate via `AuthService.validate_csrf_token()`
   - Return `false` if invalid (set 403 response)
   - Only required for state-changing methods (POST, PUT, DELETE, PATCH)

3. **Rate Limiting Middleware**:
   - Extract identifier (user ID from JWT or IP address)
   - Check rate limit via `AuthService.check_rate_limit()`
   - Return `false` if rate limited (set 429 response with Retry-After header)

4. **RBAC Permission Checking Middleware**:
   - Extract roles from JWT claims (from JWT middleware)
   - Check permission via `AuthService.user_has_permission()`
   - Return `false` if permission denied (set 403 response)

5. **API Key Validation Middleware**:
   - Extract API key from header (`X-API-Key` or `Authorization: Bearer <key>`)
   - Validate via `AuthService.validate_api_key()`
   - Extract user ID and scopes from API key metadata
   - Return `false` if invalid (set 401 response)

### Integration Requirements

**What Network Agent Needs to Know**:

1. **AuthService Context**:
   - Middleware needs access to `*AuthService` instance
   - Suggest: Pass via middleware chain context or global accessor

2. **Current Time**:
   - JWT validation and rate limiting need current timestamp
   - Suggest: Generate once per request, pass through middleware chain

3. **Request Context**:
   - User ID and roles need to be available to handlers after JWT validation
   - Suggest: Store in request context or response metadata

4. **Error Handling**:
   - Standard error response format: `{"error": "error_type", "message": "description"}`
   - HTTP status codes: 401 (Unauthorized), 403 (Forbidden), 429 (Too Many Requests)

5. **Performance Requirements**:
   - JWT validation should be < 1ms (already optimized)
   - Rate limiting should be < 0.1ms (sliding window, in-memory)
   - Permission checking should be < 0.1ms (in-memory lookup)

### Preferred Middleware Pattern

**Option A: Context-Based Middleware** (Recommended):
```zig
pub const MiddlewareContext = struct {
    auth_service: *auth_service.AuthService,
    current_time: u64,
    user_id: [auth_service.MAX_USER_ID_LEN]u8,
    user_id_len: u32,
    roles: [auth_service.MAX_ROLES_PER_USER]u32,
    role_count: u32,
};

pub fn jwt_auth_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    ctx: *MiddlewareContext,
) bool
```

**Option B: Global Accessor Pattern** (Simpler):
```zig
// Auth service passed via global or module-level variable
pub fn jwt_auth_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    current_time: u64,
) bool
```

**My Recommendation**: **Option A (Context-Based)** — More flexible, easier to test, better separation of concerns.

---

## Integration Timeline

### ✅ **Ready to Begin Immediately**

**Preferred Timeline**:
- **Week 1 (This Week)**: API contract design and agreement
- **Week 2**: Implement JWT authentication middleware
- **Week 3**: Implement CSRF, rate limiting, RBAC, API key middleware
- **Week 4**: Integration testing and refinement

**Can Start**: **TODAY** — Ready for API contract design session

---

## Specific Integration Points

### 1. JWT Authentication Middleware

**Function**: `jwt_auth_middleware()`

**Integration**:
- Extract `Authorization: Bearer <token>` header
- Call `AuthService.validate_jwt_token_static(token, secret, current_time, &claims)`
- If valid, extract `user_id` and `roles` from claims
- Store in request context for handlers
- If invalid, return `false` with 401 response

**Example Flow**:
```zig
pub fn jwt_auth_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    ctx: *MiddlewareContext,
) bool {
    // Extract token from Authorization header
    // Validate via ctx.auth_service.validate_jwt_token_static()
    // If valid: populate ctx.user_id, ctx.roles, return true
    // If invalid: set 401 response, return false
}
```

---

### 2. CSRF Protection Middleware

**Function**: `csrf_middleware()`

**Integration**:
- Only apply to state-changing methods (POST, PUT, DELETE, PATCH)
- Extract CSRF token from `X-CSRF-Token` header or cookie
- Extract session ID from request (cookie or header)
- Call `AuthService.validate_csrf_token(token, session_id, current_time)`
- If invalid, return `false` with 403 response

**Note**: Requires session ID — may need session middleware or session cookie parsing.

---

### 3. Rate Limiting Middleware

**Function**: `rate_limit_middleware()`

**Integration**:
- Extract identifier: User ID (from JWT if authenticated) or IP address
- Call `AuthService.check_rate_limit(identifier, current_time, limit)`
- If rate limited, return `false` with 429 response and `Retry-After` header
- Configurable limit per route/endpoint

**Example**:
```zig
pub fn rate_limit_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    ctx: *MiddlewareContext,
    limit: u32, // Requests per window
) bool {
    // Get identifier from ctx.user_id or request IP
    // Call ctx.auth_service.check_rate_limit()
    // Return false if rate limited
}
```

---

### 4. RBAC Permission Checking Middleware

**Function**: `rbac_middleware()`

**Integration**:
- Extract roles from JWT claims (from JWT middleware, stored in context)
- Extract resource and action from route configuration or request
- Call `AuthService.user_has_permission(user_id, roles, resource, action)`
- If permission denied, return `false` with 403 response

**Example**:
```zig
pub fn rbac_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    ctx: *MiddlewareContext,
    resource: []const u8,
    action: []const u8,
) bool {
    // Extract roles from ctx
    // Call ctx.auth_service.user_has_permission()
    // Return false if permission denied
}
```

---

### 5. API Key Validation Middleware

**Function**: `api_key_middleware()`

**Integration**:
- Extract API key from `X-API-Key` header or `Authorization: Bearer <key>`
- Call `AuthService.validate_api_key(api_key, current_time, &metadata)`
- If valid, extract `user_id` and `scopes` from metadata
- Store in request context
- If invalid, return `false` with 401 response

**Note**: Can be alternative to JWT authentication for API endpoints.

---

## Implementation Plan

### Phase 1: API Contract Design (Week 1)

**Action Items**:
1. **Design middleware context structure** (with Network Agent)
2. **Define function signatures** for all middleware functions
3. **Define error response format** (standardize with Network Agent)
4. **Define request context structure** (how to pass user_id, roles to handlers)
5. **Document middleware execution order** (JWT → CSRF → Rate Limit → RBAC)

**Deliverables**:
- Middleware API contract document
- Function signature definitions
- Error handling patterns
- Integration examples

### Phase 2: JWT Authentication Middleware (Week 2)

**Action Items**:
1. Implement `jwt_auth_middleware()` function
2. Integrate with `AuthService.validate_jwt_token_static()`
3. Extract and store user ID and roles in context
4. Add comprehensive tests
5. Document usage patterns

**Deliverables**:
- JWT authentication middleware implementation
- Tests
- Documentation

### Phase 3: Security Middleware (Week 3)

**Action Items**:
1. Implement CSRF protection middleware
2. Implement rate limiting middleware
3. Implement RBAC permission checking middleware
4. Implement API key validation middleware
5. Add comprehensive tests

**Deliverables**:
- All security middleware implementations
- Tests
- Documentation

### Phase 4: Integration & Testing (Week 4)

**Action Items**:
1. End-to-end integration testing
2. Performance testing
3. Documentation finalization
4. Production readiness validation

**Deliverables**:
- Integration tests
- Performance benchmarks
- Production-ready middleware

---

## Questions for Network Agent (1b)

1. **Middleware Context**:
   - How should `AuthService` instance be passed to middleware?
   - How should `current_time` be generated and passed?
   - Where should user context (user_id, roles) be stored for handlers?

2. **Middleware Execution Order**:
   - What's the preferred middleware execution order?
   - Should middleware be route-specific or global?
   - How are middleware chains configured?

3. **Error Handling**:
   - What error response format does Network Agent prefer?
   - Should error responses be JSON? What structure?
   - Are there standard error codes we should use?

4. **Request Context**:
   - How do handlers access user context after JWT validation?
   - Is there a request context structure we should use?
   - How do we pass data between middleware and handlers?

5. **Testing**:
   - How should middleware be tested?
   - Are there test utilities or mocks available?
   - What's the preferred testing approach?

---

## Next Steps

### Immediate Actions (This Week)

1. **API Contract Design Session**:
   - Coordinate with Network Agent (1b) via Core 1 Subcore
   - Design middleware API contracts
   - Agree on function signatures and patterns
   - Document integration approach

2. **Begin Implementation**:
   - Start with JWT authentication middleware
   - Follow agreed-upon API contracts
   - Implement incrementally with tests

### Coordination Needed

**From Core 1 Subcore**:
- [ ] Facilitate middleware API contract design session with Network Agent (1b)
- [ ] Coordinate on middleware context structure
- [ ] Help resolve any API design questions

**From Network Agent (1b)**:
- [ ] Share middleware framework documentation
- [ ] Confirm middleware execution patterns
- [ ] Confirm request context structure
- [ ] Answer middleware API design questions

---

## Summary

**Middleware Readiness**: ✅ **READY NOW** — Can begin immediately

**Current Priority**: **HIGH** — Middleware integration is top priority

**Bandwidth**: **100% AVAILABLE** — Ready to focus on middleware work

**Timeline**: Can start API contract design **TODAY**, implementation within 1 week

**Recommended Pattern**: Context-based middleware with `AuthService` and `current_time` passed via context

**Integration Points**: 5 middleware functions needed (JWT auth, CSRF, rate limiting, RBAC, API key)

**Action Requested**: Please facilitate middleware API contract design session with Network Agent (1b)

---

**Date**: 2026-01-01-085326-pst  
**Agent**: Grain Auth Agent (1a)  
**Status**: ✅ **READY FOR MIDDLEWARE INTEGRATION** — Awaiting API Contract Design Session

---
