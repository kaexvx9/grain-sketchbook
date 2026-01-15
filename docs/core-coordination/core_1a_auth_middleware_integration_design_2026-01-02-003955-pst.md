# Core 1a Auth Agent: Middleware Integration Design

**Date**: 2026-01-02-003955-pst  
**Agent**: Grain Auth Agent (1a) — L2 Sub-Agent  
**Parent Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Status**: ✅ **DESIGN READY** — Detailed integration patterns for API contract design session

---

## Executive Summary

This document provides detailed middleware integration design patterns aligned with the existing Network Agent (1b) middleware infrastructure. These patterns are ready for API contract design session discussion and can be implemented once API contracts are agreed upon.

**Current Middleware Infrastructure** (Network Agent 1b):
- ✅ Middleware function type: `Middleware = *const fn (*HttpRequest, *HttpResponse) bool`
- ✅ Route middleware storage: `[8]?Middleware` per route
- ✅ Middleware chain execution: `execute_middleware_chain()` with early termination
- ✅ Existing middleware: CORS, logging, rate limiting (stub), auth (stub), content-type

**Auth Agent Integration Needs**:
- ⏳ Pass `*AuthService` instance to middleware functions
- ⏳ Integrate JWT validation with existing auth middleware
- ⏳ Integrate CSRF, rate limiting, RBAC, API key validation

---

## Current Middleware Infrastructure Analysis

### Existing Middleware Pattern

**Function Signature**:
```zig
pub const Middleware = *const fn (*HttpRequest, *HttpResponse) bool;
```

**Current Implementation** (`src/grain_core/middleware.zig`):
- `cors_middleware()` — CORS headers ✅
- `logging_middleware()` — Request logging (stub) ✅
- `rate_limit_middleware()` — Rate limiting (uses global rate limiter) ✅
- `auth_middleware()` — JWT authentication (stub, doesn't validate) ⚠️
- `content_type_middleware()` — Content-Type validation ✅

**Middleware Chain Execution** (`src/grain_core/api_server.zig`):
- `execute_middleware_chain()` — Executes middleware in order, early termination on `false`
- `add_middleware_to_route()` — Adds middleware to route (up to 8 per route)

**Current Limitation**: Middleware functions don't have access to `*AuthService` instance or request context.

---

## Proposed Integration Patterns

### Pattern 1: Middleware Context Structure (Recommended)

**Design**: Add middleware context structure to pass AuthService and request metadata.

**Proposed Structure**:
```zig
// Middleware context: Passes auth service and request metadata to middleware.
pub const MiddlewareContext = struct {
    auth_service: ?*auth_service.AuthService,
    current_time: u64,
    user_id: [auth_service.MAX_USER_ID_LEN]u8,
    user_id_len: u32,
    roles: [auth_service.MAX_ROLES_PER_USER]u32,
    roles_len: u32,
    
    pub fn init() MiddlewareContext {
        return MiddlewareContext{
            .auth_service = null,
            .current_time = 0,
            .user_id = undefined,
            .user_id_len = 0,
            .roles = undefined,
            .roles_len = 0,
        };
    }
};
```

**Updated Middleware Function Type**:
```zig
pub const Middleware = *const fn (*HttpRequest, *HttpResponse, *MiddlewareContext) bool;
```

**Benefits**:
- ✅ Explicit context passing
- ✅ Type-safe access to AuthService
- ✅ Request metadata (user_id, roles) available to handlers
- ✅ Follows Grain Style (explicit types, bounded allocations)

**Trade-offs**:
- ⚠️ Requires updating existing middleware functions
- ⚠️ Requires updating middleware chain execution

---

### Pattern 2: Global AuthService Instance (Alternative)

**Design**: Use global AuthService instance (similar to current rate limiter pattern).

**Proposed Implementation**:
```zig
// Global auth service instance (initialized at server startup).
var global_auth_service: ?*auth_service.AuthService = null;

pub fn init_auth_middleware(service: *auth_service.AuthService) void {
    std.debug.assert(service != null);
    global_auth_service = service;
}
```

**Updated Middleware Function Type**:
```zig
// Keep existing signature, access global instance inside middleware.
pub const Middleware = *const fn (*HttpRequest, *HttpResponse) bool;
```

**Benefits**:
- ✅ No changes to existing middleware function type
- ✅ Minimal changes to existing code
- ✅ Simple implementation

**Trade-offs**:
- ⚠️ Global state (less explicit)
- ⚠️ No request context (user_id, roles) available to handlers
- ⚠️ Less flexible (single AuthService instance)

---

### Pattern 3: Request Context Extension (Alternative)

**Design**: Extend HttpRequest structure to include auth context.

**Proposed Structure**:
```zig
// Extended request context in HttpRequest.
pub const HttpRequest = struct {
    // ... existing fields ...
    auth_context: ?AuthContext,
    
    pub const AuthContext = struct {
        user_id: [auth_service.MAX_USER_ID_LEN]u8,
        user_id_len: u32,
        roles: [auth_service.MAX_ROLES_PER_USER]u32,
        roles_len: u32,
        authenticated: bool,
    };
};
```

**Middleware Function Type**:
```zig
// Keep existing signature, access auth context via request.
pub const Middleware = *const fn (*HttpRequest, *HttpResponse) bool;
```

**Benefits**:
- ✅ No changes to middleware function type
- ✅ Request context available to handlers
- ✅ Clean separation of concerns

**Trade-offs**:
- ⚠️ Requires extending HttpRequest structure
- ⚠️ Still need to pass AuthService (via global or context)

---

## Recommended Approach: Pattern 1 (Middleware Context)

**Rationale**:
- ✅ Most explicit and type-safe
- ✅ Follows Grain Style principles (explicit types, bounded allocations)
- ✅ Provides request context to handlers
- ✅ Flexible (can add more context fields as needed)
- ✅ Aligns with existing middleware chain pattern

**Implementation Steps**:
1. Define `MiddlewareContext` structure
2. Update middleware function type to include context
3. Update existing middleware functions to accept context
4. Update middleware chain execution to pass context
5. Implement auth middleware functions using context

---

## Auth Middleware Function Designs

### 1. JWT Authentication Middleware

**Function**: `jwt_auth_middleware()`

**Design**:
```zig
pub fn jwt_auth_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    ctx: *MiddlewareContext,
) bool {
    std.debug.assert(request != null);
    std.debug.assert(response != null);
    std.debug.assert(ctx != null);
    
    // Extract Authorization header.
    const auth_header = request.get_header("Authorization") orelse {
        set_unauthorized_response(response);
        return false;
    };
    
    // Extract Bearer token.
    if (!std.mem.startsWith(u8, auth_header, "Bearer ")) {
        set_unauthorized_response(response);
        return false;
    }
    
    const token = auth_header[7..];
    if (token.len == 0) {
        set_unauthorized_response(response);
        return false;
    }
    
    // Validate JWT token.
    if (ctx.auth_service) |auth_service| {
        var claims: auth_service.JwtClaims = undefined;
        const is_valid = auth_service.validate_jwt_token_static(
            token,
            ctx.current_time,
            &claims,
        );
        
        if (!is_valid) {
            set_unauthorized_response(response);
            return false;
        }
        
        // Store user_id and roles in context.
        ctx.user_id_len = @min(claims.user_id_len, auth_service.MAX_USER_ID_LEN);
        var i: u32 = 0;
        while (i < ctx.user_id_len) : (i += 1) {
            ctx.user_id[i] = claims.user_id[i];
        }
        
        ctx.roles_len = @min(claims.roles_len, auth_service.MAX_ROLES_PER_USER);
        i = 0;
        while (i < ctx.roles_len) : (i += 1) {
            ctx.roles[i] = claims.roles[i];
        }
        
        return true;
    }
    
    set_unauthorized_response(response);
    return false;
}
```

**Integration**:
- Extract `Authorization: Bearer <token>` header
- Validate via `AuthService.validate_jwt_token_static()`
- Store user_id and roles in context for handlers
- Return `false` if invalid (sets 401 response)

---

### 2. CSRF Protection Middleware

**Function**: `csrf_middleware()`

**Design**:
```zig
pub fn csrf_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    ctx: *MiddlewareContext,
) bool {
    std.debug.assert(request != null);
    std.debug.assert(response != null);
    std.debug.assert(ctx != null);
    
    // Only required for state-changing methods.
    const is_state_changing = switch (request.method) {
        .post, .put, .delete, .patch => true,
        else => return true,
    };
    
    if (!is_state_changing) {
        return true;
    }
    
    // Extract CSRF token from header or cookie.
    const csrf_token = request.get_header("X-CSRF-Token") orelse {
        set_forbidden_response(response, "Missing CSRF token");
        return false;
    };
    
    // Extract session ID from cookie or header.
    const session_id = extract_session_id(request) orelse {
        set_forbidden_response(response, "Missing session ID");
        return false;
    };
    
    // Validate CSRF token.
    if (ctx.auth_service) |auth_service| {
        const is_valid = auth_service.validate_csrf_token(
            csrf_token,
            session_id,
            ctx.current_time,
        );
        
        if (!is_valid) {
            set_forbidden_response(response, "Invalid CSRF token");
            return false;
        }
        
        return true;
    }
    
    set_forbidden_response(response, "Auth service not available");
    return false;
}
```

**Integration**:
- Only apply to state-changing methods (POST, PUT, DELETE, PATCH)
- Extract CSRF token from `X-CSRF-Token` header
- Extract session ID from cookie or header
- Validate via `AuthService.validate_csrf_token()`
- Return `false` if invalid (sets 403 response)

---

### 3. Rate Limiting Middleware (Enhanced)

**Function**: `rate_limit_middleware_enhanced()`

**Design**:
```zig
pub fn rate_limit_middleware_enhanced(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    ctx: *MiddlewareContext,
    limit: u32, // Requests per window
) bool {
    std.debug.assert(request != null);
    std.debug.assert(response != null);
    std.debug.assert(ctx != null);
    std.debug.assert(limit > 0);
    
    // Get identifier: user_id (if authenticated) or IP address.
    const identifier = if (ctx.user_id_len > 0) 
        ctx.user_id[0..ctx.user_id_len]
    else
        get_client_ip(request);
    
    if (identifier.len == 0) {
        set_bad_request_response(response, "Unable to determine identifier");
        return false;
    }
    
    // Check rate limit.
    if (ctx.auth_service) |auth_service| {
        const is_allowed = auth_service.check_rate_limit(
            identifier,
            ctx.current_time,
            limit,
        );
        
        if (!is_allowed) {
            set_rate_limit_response(response);
            return false;
        }
        
        return true;
    }
    
    set_bad_request_response(response, "Auth service not available");
    return false;
}
```

**Integration**:
- Extract identifier: user_id (if authenticated) or IP address
- Check via `AuthService.check_rate_limit()`
- Return `false` if rate limited (sets 429 response with Retry-After header)
- Configurable limit per route/endpoint

---

### 4. RBAC Permission Checking Middleware

**Function**: `rbac_middleware()`

**Design**:
```zig
pub fn rbac_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    ctx: *MiddlewareContext,
    resource: []const u8,
    action: []const u8,
) bool {
    std.debug.assert(request != null);
    std.debug.assert(response != null);
    std.debug.assert(ctx != null);
    std.debug.assert(resource.len > 0);
    std.debug.assert(action.len > 0);
    
    // Require authentication first.
    if (ctx.user_id_len == 0) {
        set_unauthorized_response(response);
        return false;
    }
    
    // Check permission.
    if (ctx.auth_service) |auth_service| {
        const user_id = ctx.user_id[0..ctx.user_id_len];
        const roles = ctx.roles[0..ctx.roles_len];
        
        const has_permission = auth_service.user_has_permission(
            user_id,
            &roles,
            resource,
            action,
        );
        
        if (!has_permission) {
            set_forbidden_response(response, "Permission denied");
            return false;
        }
        
        return true;
    }
    
    set_forbidden_response(response, "Auth service not available");
    return false;
}
```

**Integration**:
- Extract roles from context (set by JWT middleware)
- Extract resource and action from route configuration or request
- Check via `AuthService.user_has_permission()`
- Return `false` if permission denied (sets 403 response)

---

### 5. API Key Validation Middleware

**Function**: `api_key_middleware()`

**Design**:
```zig
pub fn api_key_middleware(
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    ctx: *MiddlewareContext,
) bool {
    std.debug.assert(request != null);
    std.debug.assert(response != null);
    std.debug.assert(ctx != null);
    
    // Extract API key from header.
    const api_key = request.get_header("X-API-Key") orelse {
        // Try Authorization header as fallback.
        if (request.get_header("Authorization")) |auth_header| {
            if (std.mem.startsWith(u8, auth_header, "Bearer ")) {
                const key = auth_header[7..];
                if (key.len > 0) {
                    return validate_api_key(key, request, response, ctx);
                }
            }
        }
        set_unauthorized_response(response);
        return false;
    };
    
    return validate_api_key(api_key, request, response, ctx);
}

fn validate_api_key(
    api_key: []const u8,
    request: *api_server.HttpRequest,
    response: *api_server.HttpResponse,
    ctx: *MiddlewareContext,
) bool {
    std.debug.assert(api_key.len > 0);
    std.debug.assert(request != null);
    std.debug.assert(response != null);
    std.debug.assert(ctx != null);
    
    // Validate API key.
    if (ctx.auth_service) |auth_service| {
        var metadata: auth_service.ApiKeyMetadata = undefined;
        const is_valid = auth_service.validate_api_key(
            api_key,
            ctx.current_time,
            &metadata,
        );
        
        if (!is_valid) {
            set_unauthorized_response(response);
            return false;
        }
        
        // Store user_id and scopes in context.
        ctx.user_id_len = @min(metadata.user_id_len, auth_service.MAX_USER_ID_LEN);
        var i: u32 = 0;
        while (i < ctx.user_id_len) : (i += 1) {
            ctx.user_id[i] = metadata.user_id[i];
        }
        
        // Store scopes in context (if needed for handlers).
        // Note: Scopes can be checked via metadata.scopes array.
        
        return true;
    }
    
    set_unauthorized_response(response);
    return false;
}
```

**Integration**:
- Extract API key from `X-API-Key` header or `Authorization: Bearer <key>`
- Validate via `AuthService.validate_api_key()`
- Store user_id and scopes in context
- Return `false` if invalid (sets 401 response)

---

## Helper Functions

### Error Response Helpers

**Design**:
```zig
// Set unauthorized response (401).
fn set_unauthorized_response(response: *api_server.HttpResponse) void {
    std.debug.assert(response != null);
    response.status = api_server.HttpStatus.unauthorized;
    _ = response.add_header("Content-Type", "application/json");
    const error_body = "{\"error\":\"unauthorized\",\"message\":\"Authentication required\"}";
    set_error_body(response, error_body);
}

// Set forbidden response (403).
fn set_forbidden_response(response: *api_server.HttpResponse, message: []const u8) void {
    std.debug.assert(response != null);
    std.debug.assert(message.len > 0);
    response.status = api_server.HttpStatus.forbidden;
    _ = response.add_header("Content-Type", "application/json");
    // Format error body with message.
    set_error_body(response, message);
}

// Set rate limit response (429).
fn set_rate_limit_response(response: *api_server.HttpResponse) void {
    std.debug.assert(response != null);
    response.status = api_server.HttpStatus.too_many_requests;
    _ = response.add_header("Content-Type", "application/json");
    _ = response.add_header("Retry-After", "60"); // 60 seconds
    const error_body = "{\"error\":\"rate_limit\",\"message\":\"Rate limit exceeded\"}";
    set_error_body(response, error_body);
}

// Set error body helper.
fn set_error_body(response: *api_server.HttpResponse, body: []const u8) void {
    std.debug.assert(response != null);
    std.debug.assert(body.len > 0);
    const body_len = @min(body.len, api_server.MAX_RESPONSE_SIZE);
    var i: u32 = 0;
    while (i < body_len) : (i += 1) {
        response.body[i] = body[i];
    }
    response.body_len = @intCast(body_len);
}
```

---

## Middleware Execution Order

**Recommended Order**:
1. **CORS** (if needed) — Add CORS headers
2. **JWT Authentication** (if route requires auth) — Validate JWT, set user context
3. **CSRF Protection** (if state-changing) — Validate CSRF token
4. **Rate Limiting** — Check rate limits
5. **RBAC Permission Check** (if route requires permissions) — Check permissions
6. **API Key Validation** (alternative to JWT) — Validate API key
7. **Content-Type** (if needed) — Validate content type
8. **Logging** (if needed) — Log request

**Example Route Configuration**:
```zig
// Protected route with JWT auth, CSRF, rate limiting, and RBAC.
server.add_middleware_to_route(.post, "/api/users", cors_middleware);
server.add_middleware_to_route(.post, "/api/users", jwt_auth_middleware);
server.add_middleware_to_route(.post, "/api/users", csrf_middleware);
server.add_middleware_to_route(.post, "/api/users", rate_limit_middleware_enhanced);
server.add_middleware_to_route(.post, "/api/users", rbac_middleware);
```

---

## Integration with Existing Code

### Current Middleware Chain Execution

**Existing Code** (`src/grain_core/api_server.zig`):
```zig
pub fn execute_middleware_chain(
    _self: *const ApiServer,
    route: *const Route,
    request: *HttpRequest,
    response: *HttpResponse,
) bool {
    var i: u32 = 0;
    while (i < route.middleware_len) : (i += 1) {
        if (route.middleware[i]) |middleware_fn| {
            if (!middleware_fn(request, response)) {
                return false;
            }
        }
    }
    return true;
}
```

**Proposed Update**:
```zig
pub fn execute_middleware_chain(
    _self: *const ApiServer,
    route: *const Route,
    request: *HttpRequest,
    response: *HttpResponse,
    ctx: *MiddlewareContext,
) bool {
    std.debug.assert(ctx != null);
    var i: u32 = 0;
    while (i < route.middleware_len) : (i += 1) {
        if (route.middleware[i]) |middleware_fn| {
            if (!middleware_fn(request, response, ctx)) {
                return false;
            }
        }
    }
    return true;
}
```

---

## Questions for Network Agent (1b)

**API Contract Design Questions**:

1. **Middleware Context Structure**:
   - [ ] Do you prefer Pattern 1 (MiddlewareContext), Pattern 2 (Global), or Pattern 3 (Request Extension)?
   - [ ] If Pattern 1, should we extend existing middleware or create new auth-specific middleware?
   - [ ] How should we initialize MiddlewareContext (per-request or global)?

2. **Middleware Function Signature**:
   - [ ] Should we update existing middleware function type or create new auth middleware type?
   - [ ] How should we handle backward compatibility with existing middleware?

3. **Request Context Access**:
   - [ ] How should handlers access user_id and roles from middleware context?
   - [ ] Should we extend HttpRequest or use separate context structure?

4. **Error Response Format**:
   - [ ] Should error responses follow a standard format?
   - [ ] Should we use existing error response helpers or create new ones?

5. **Middleware Execution**:
   - [ ] Should middleware chain execution be updated to pass context?
   - [ ] How should we handle middleware that doesn't need context?

6. **Session Management**:
   - [ ] How should we extract session ID from requests (cookie parsing)?
   - [ ] Should session management be part of middleware or separate?

---

## Implementation Timeline

### Phase 1: API Contract Design (Week 1)
- [ ] Discuss middleware context structure with Network Agent (1b)
- [ ] Agree on middleware function signatures
- [ ] Define error response format
- [ ] Define request context access patterns
- [ ] Document API contracts

### Phase 2: Middleware Implementation (Weeks 2-3)
- [ ] Implement JWT authentication middleware
- [ ] Implement CSRF protection middleware
- [ ] Implement rate limiting middleware (enhanced)
- [ ] Implement RBAC permission checking middleware
- [ ] Implement API key validation middleware
- [ ] Add comprehensive middleware tests

### Phase 3: Integration Testing (Week 4)
- [ ] Integration tests with Network Agent (1b)
- [ ] End-to-end middleware chain testing
- [ ] Performance testing
- [ ] Framework x86_64 testing verification

---

## Grain Style Compliance

**All Middleware Functions**:
- ✅ Function length ≤ 70 lines
- ✅ Line length ≤ 100 characters
- ✅ Explicit types (`u32`/`u64`, no `usize`/`isize`)
- ✅ Bounded allocations (MAX_ constants)
- ✅ Minimum 2 assertions per function
- ✅ `grain_case` function names

---

## Summary

**Status**: ✅ **DESIGN READY** — Detailed integration patterns prepared for API contract design session

**Next Steps**:
1. Await Core 1 Subcore facilitation of API contract design session
2. Discuss middleware context structure with Network Agent (1b)
3. Agree on middleware function signatures
4. Begin implementation after API contracts agreed

**Ready For**:
- ✅ API contract design session participation
- ✅ Middleware implementation (after contracts agreed)
- ✅ Integration testing (after implementation)

---

**Date**: 2026-01-02-003955-pst  
**Agent**: Grain Auth Agent (1a)  
**Status**: ✅ Middleware integration design ready for API contract discussion

---

