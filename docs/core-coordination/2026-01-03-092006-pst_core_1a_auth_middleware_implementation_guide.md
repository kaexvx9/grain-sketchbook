# Core 1a Auth Agent: Middleware Implementation Guide

**Date**: 2026-01-03-092006-pst  
**Agent**: Grain Auth Agent (1a) — L2 Sub-Agent  
**Parent Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Status**: ✅ **IMPLEMENTATION GUIDE READY** — Detailed patterns for middleware implementation after API contracts agreed

---

## Executive Summary

This document provides detailed implementation patterns and test patterns for middleware integration, prepared for when API contracts are agreed upon with Network Agent (1b). This guide complements the middleware integration design document and provides concrete implementation examples.

**Reference Documents**:
- Middleware Integration Design: `docs/core-coordination/core_1a_auth_middleware_integration_design_2026-01-02-003955-pst.md`
- Middleware Readiness Response: `docs/agent-communications/l2-subagents/core_1/1a_auth/communications/core_1a_auth_middleware_readiness_response_2026-01-01-085326-pst.md`

**Status**: ⏳ Awaiting API contract design session with Network Agent (1b)

---

## Implementation Patterns

### Pattern 1: MiddlewareContext Structure (Recommended)

**Design**: MiddlewareContext structure to pass AuthService and request metadata.

**Implementation**:
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
    
    pub fn set_user_context(
        self: *MiddlewareContext,
        user_id: []const u8,
        roles: []const u32,
    ) void {
        std.debug.assert(user_id.len > 0);
        std.debug.assert(user_id.len <= auth_service.MAX_USER_ID_LEN);
        std.debug.assert(roles.len <= auth_service.MAX_ROLES_PER_USER);
        
        self.user_id_len = @min(user_id.len, auth_service.MAX_USER_ID_LEN);
        std.mem.copyForwards(u8, &self.user_id, user_id[0..self.user_id_len]);
        
        self.roles_len = @min(roles.len, auth_service.MAX_ROLES_PER_USER);
        var i: u32 = 0;
        while (i < self.roles_len) : (i += 1) {
            self.roles[i] = roles[i];
        }
    }
    
    pub fn get_user_id(self: *const MiddlewareContext) ?[]const u8 {
        if (self.user_id_len > 0) {
            return self.user_id[0..self.user_id_len];
        }
        return null;
    }
    
    pub fn has_role(self: *const MiddlewareContext, role_id: u32) bool {
        var i: u32 = 0;
        while (i < self.roles_len) : (i += 1) {
            if (self.roles[i] == role_id) {
                return true;
            }
        }
        return false;
    }
};
```

---

### Pattern 2: JWT Authentication Middleware Implementation

**Function**: `jwt_auth_middleware()`

**Complete Implementation**:
```zig
// JWT authentication middleware: Validate JWT token and set user context.
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
        set_unauthorized_response(response, "Missing Authorization header");
        return false;
    };
    
    // Extract Bearer token.
    if (auth_header.len < 7) {
        set_unauthorized_response(response, "Invalid Authorization header");
        return false;
    }
    
    if (!std.mem.startsWith(u8, auth_header, "Bearer ")) {
        set_unauthorized_response(response, "Invalid Authorization format");
        return false;
    }
    
    const token = auth_header[7..];
    if (token.len == 0) {
        set_unauthorized_response(response, "Missing token");
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
            set_unauthorized_response(response, "Invalid or expired token");
            return false;
        }
        
        // Store user_id and roles in context.
        ctx.user_id_len = @min(claims.user_id_len, auth_service.MAX_USER_ID_LEN);
        var i: u32 = 0;
        while (i < ctx.user_id_len) : (i += 1) {
            ctx.user_id[i] = claims.user_id[i];
        }
        
        ctx.roles_len = @min(claims.role_count, auth_service.MAX_ROLES_PER_USER);
        i = 0;
        while (i < ctx.roles_len) : (i += 1) {
            ctx.roles[i] = claims.roles[i];
        }
        
        return true;
    }
    
    set_unauthorized_response(response, "Auth service not available");
    return false;
}
```

---

### Pattern 3: Error Response Helpers

**Implementation**:
```zig
// Set unauthorized response (401).
fn set_unauthorized_response(
    response: *api_server.HttpResponse,
    message: []const u8,
) void {
    std.debug.assert(response != null);
    std.debug.assert(message.len > 0);
    
    response.status = api_server.HttpStatus.unauthorized;
    _ = response.add_header("Content-Type", "application/json");
    
    var error_body: [256]u8 = undefined;
    const body = std.fmt.bufPrint(
        &error_body,
        "{{\"error\":\"unauthorized\",\"message\":\"{s}\"}}",
        .{message},
    ) catch {
        const fallback = "{\"error\":\"unauthorized\"}";
        set_error_body(response, fallback);
        return;
    };
    
    set_error_body(response, body);
}

// Set forbidden response (403).
fn set_forbidden_response(
    response: *api_server.HttpResponse,
    message: []const u8,
) void {
    std.debug.assert(response != null);
    std.debug.assert(message.len > 0);
    
    response.status = api_server.HttpStatus.forbidden;
    _ = response.add_header("Content-Type", "application/json");
    
    var error_body: [256]u8 = undefined;
    const body = std.fmt.bufPrint(
        &error_body,
        "{{\"error\":\"forbidden\",\"message\":\"{s}\"}}",
        .{message},
    ) catch {
        const fallback = "{\"error\":\"forbidden\"}";
        set_error_body(response, fallback);
        return;
    };
    
    set_error_body(response, body);
}

// Set rate limit response (429).
fn set_rate_limit_response(response: *api_server.HttpResponse) void {
    std.debug.assert(response != null);
    
    response.status = api_server.HttpStatus.too_many_requests;
    _ = response.add_header("Content-Type", "application/json");
    _ = response.add_header("Retry-After", "60");
    
    const error_body = "{\"error\":\"rate_limit\",\"message\":\"Rate limit exceeded\"}";
    set_error_body(response, error_body);
}

// Set error body helper.
fn set_error_body(
    response: *api_server.HttpResponse,
    body: []const u8,
) void {
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

## Test Patterns

### Test Pattern 1: JWT Authentication Middleware Test

**Implementation**:
```zig
test "jwt_auth_middleware_valid_token" {
    const secret = "test_secret_key_for_jwt_signing";
    var auth_service_instance = auth_service.AuthService.init(secret);
    const current_time: u64 = 1000000;
    
    // Generate JWT token.
    const user_id = "user123";
    var token: [auth_service.MAX_JWT_LEN]u8 = undefined;
    const token_len = auth_service_instance.generate_access_token(
        user_id,
        current_time,
        &token,
    );
    std.debug.assert(token_len > 0);
    
    // Create request with Authorization header.
    var request = api_server.HttpRequest.init();
    var auth_header_buf: [512]u8 = undefined;
    const auth_header = std.fmt.bufPrint(
        &auth_header_buf,
        "Bearer {s}",
        .{token[0..token_len]},
    ) catch return;
    _ = request.add_header("Authorization", auth_header);
    
    // Create response and context.
    var response = api_server.HttpResponse.init();
    var ctx = MiddlewareContext.init();
    ctx.auth_service = &auth_service_instance;
    ctx.current_time = current_time;
    
    // Execute middleware.
    const result = jwt_auth_middleware(&request, &response, &ctx);
    
    // Verify result.
    std.debug.assert(result == true);
    std.debug.assert(ctx.user_id_len > 0);
    std.debug.assert(std.mem.eql(u8, ctx.user_id[0..ctx.user_id_len], user_id));
}

test "jwt_auth_middleware_invalid_token" {
    const secret = "test_secret_key_for_jwt_signing";
    var auth_service_instance = auth_service.AuthService.init(secret);
    const current_time: u64 = 1000000;
    
    // Create request with invalid token.
    var request = api_server.HttpRequest.init();
    _ = request.add_header("Authorization", "Bearer invalid_token");
    
    // Create response and context.
    var response = api_server.HttpResponse.init();
    var ctx = MiddlewareContext.init();
    ctx.auth_service = &auth_service_instance;
    ctx.current_time = current_time;
    
    // Execute middleware.
    const result = jwt_auth_middleware(&request, &response, &ctx);
    
    // Verify result.
    std.debug.assert(result == false);
    std.debug.assert(response.status == api_server.HttpStatus.unauthorized);
}
```

---

### Test Pattern 2: CSRF Protection Middleware Test

**Implementation**:
```zig
test "csrf_middleware_valid_token" {
    const secret = "test_secret_key_for_jwt_signing";
    var auth_service_instance = auth_service.AuthService.init(secret);
    const current_time: u64 = 1000000;
    
    // Generate CSRF token.
    const session_id = "session123";
    var csrf_token: [auth_service.CSRF_TOKEN_STRING_LEN]u8 = undefined;
    const token_len = auth_service_instance.generate_csrf_token(
        session_id,
        current_time,
        &csrf_token,
    );
    std.debug.assert(token_len > 0);
    
    // Create POST request with CSRF token.
    var request = api_server.HttpRequest.init();
    request.method = api_server.HttpMethod.post;
    _ = request.add_header("X-CSRF-Token", csrf_token[0..token_len]);
    _ = request.add_header("X-Session-ID", session_id);
    
    // Create response and context.
    var response = api_server.HttpResponse.init();
    var ctx = MiddlewareContext.init();
    ctx.auth_service = &auth_service_instance;
    ctx.current_time = current_time;
    
    // Execute middleware.
    const result = csrf_middleware(&request, &response, &ctx);
    
    // Verify result.
    std.debug.assert(result == true);
}

test "csrf_middleware_invalid_token" {
    const secret = "test_secret_key_for_jwt_signing";
    var auth_service_instance = auth_service.AuthService.init(secret);
    const current_time: u64 = 1000000;
    
    // Create POST request with invalid CSRF token.
    var request = api_server.HttpRequest.init();
    request.method = api_server.HttpMethod.post;
    _ = request.add_header("X-CSRF-Token", "invalid_token");
    _ = request.add_header("X-Session-ID", "session123");
    
    // Create response and context.
    var response = api_server.HttpResponse.init();
    var ctx = MiddlewareContext.init();
    ctx.auth_service = &auth_service_instance;
    ctx.current_time = current_time;
    
    // Execute middleware.
    const result = csrf_middleware(&request, &response, &ctx);
    
    // Verify result.
    std.debug.assert(result == false);
    std.debug.assert(response.status == api_server.HttpStatus.forbidden);
}
```

---

## Integration Testing Patterns

### Integration Test Pattern: Middleware Chain Execution

**Implementation**:
```zig
test "middleware_chain_jwt_csrf_rbac" {
    const secret = "test_secret_key_for_jwt_signing";
    var auth_service_instance = auth_service.AuthService.init(secret);
    const current_time: u64 = 1000000;
    
    // Setup: Create user with role.
    const user_id = "user123";
    const role_id: u32 = 1;
    _ = auth_service_instance.create_role("admin", role_id, null);
    var user_roles = [_]u32{role_id};
    _ = auth_service_instance.assign_roles_to_user(user_id, &user_roles, 1);
    
    // Generate JWT token with roles.
    var token: [auth_service.MAX_JWT_LEN]u8 = undefined;
    const token_len = auth_service_instance.generate_access_token(
        user_id,
        current_time,
        &token,
    );
    
    // Generate CSRF token.
    const session_id = "session123";
    var csrf_token: [auth_service.CSRF_TOKEN_STRING_LEN]u8 = undefined;
    const csrf_len = auth_service_instance.generate_csrf_token(
        session_id,
        current_time,
        &csrf_token,
    );
    
    // Create POST request.
    var request = api_server.HttpRequest.init();
    request.method = api_server.HttpMethod.post;
    var auth_header_buf: [512]u8 = undefined;
    const auth_header = std.fmt.bufPrint(
        &auth_header_buf,
        "Bearer {s}",
        .{token[0..token_len]},
    ) catch return;
    _ = request.add_header("Authorization", auth_header);
    _ = request.add_header("X-CSRF-Token", csrf_token[0..csrf_len]);
    _ = request.add_header("X-Session-ID", session_id);
    
    // Create response and context.
    var response = api_server.HttpResponse.init();
    var ctx = MiddlewareContext.init();
    ctx.auth_service = &auth_service_instance;
    ctx.current_time = current_time;
    
    // Execute middleware chain: JWT → CSRF → RBAC.
    const jwt_result = jwt_auth_middleware(&request, &response, &ctx);
    std.debug.assert(jwt_result == true);
    
    const csrf_result = csrf_middleware(&request, &response, &ctx);
    std.debug.assert(csrf_result == true);
    
    const rbac_result = rbac_middleware(
        &request,
        &response,
        &ctx,
        "resource1",
        "action1",
    );
    std.debug.assert(rbac_result == true);
    
    // Verify context.
    std.debug.assert(ctx.user_id_len > 0);
    std.debug.assert(ctx.roles_len > 0);
}
```

---

## Performance Considerations

### Optimization Pattern 1: Early Termination

**Design**: Middleware functions should return `false` immediately on failure to avoid unnecessary processing.

**Implementation**: All middleware functions already implement early termination.

### Optimization Pattern 2: Context Caching

**Design**: Cache validated user context in MiddlewareContext to avoid re-validation in subsequent middleware.

**Implementation**: MiddlewareContext stores user_id and roles after JWT validation, available to all subsequent middleware.

### Optimization Pattern 3: Rate Limit Lookup Optimization

**Design**: Use efficient data structure for rate limit lookups (current implementation uses linear search, acceptable for bounded MAX_RATE_LIMIT_ENTRIES).

**Future Enhancement**: Consider hash table for O(1) lookups if rate limit entries exceed 1000.

---

## Error Handling Patterns

### Pattern 1: Consistent Error Response Format

**Design**: All middleware errors return consistent JSON error response format.

**Format**:
```json
{
  "error": "error_type",
  "message": "Human-readable error message"
}
```

**Error Types**:
- `unauthorized` — 401 (authentication required)
- `forbidden` — 403 (permission denied)
- `rate_limit` — 429 (rate limit exceeded)
- `bad_request` — 400 (invalid request)

### Pattern 2: Error Logging

**Design**: Log middleware errors for debugging and monitoring.

**Implementation**: Use audit logging for middleware failures:
```zig
// Log middleware failure.
auth_service.log_audit_event(
    &auth_service_instance,
    auth_service.AuditEventType.permission_denied,
    current_time,
    user_id,
    "Middleware: CSRF validation failed",
    ip_address,
    user_agent,
    false,
);
```

---

## Security Considerations

### Pattern 1: Token Validation Order

**Design**: Validate tokens in order: JWT → CSRF → Rate Limit → RBAC.

**Rationale**: 
- JWT validation is fastest (can fail early)
- CSRF validation requires session (after JWT)
- Rate limiting should happen after authentication
- RBAC requires user context (after JWT)

### Pattern 2: Timing Attack Prevention

**Design**: Use constant-time comparisons for sensitive operations.

**Implementation**: Use `std.mem.eql()` which is constant-time for fixed-length comparisons.

### Pattern 3: Token Expiration Handling

**Design**: Check token expiration before expensive operations.

**Implementation**: JWT validation checks expiration first, before signature verification.

---

## Integration Checklist

### Before Implementation

- [ ] API contracts agreed with Network Agent (1b)
- [ ] MiddlewareContext structure finalized
- [ ] Error response format standardized
- [ ] Middleware execution order confirmed
- [ ] Request context access pattern agreed

### During Implementation

- [ ] Implement JWT authentication middleware
- [ ] Implement CSRF protection middleware
- [ ] Implement rate limiting middleware
- [ ] Implement RBAC permission checking middleware
- [ ] Implement API key validation middleware
- [ ] Add comprehensive unit tests
- [ ] Add integration tests
- [ ] Add performance tests

### After Implementation

- [ ] All tests passing
- [ ] Grain Style compliance verified
- [ ] Documentation updated
- [ ] Integration with Network Agent (1b) verified
- [ ] Framework x86_64 testing verified

---

## Summary

**Status**: ✅ **IMPLEMENTATION GUIDE READY** — Detailed patterns prepared for middleware implementation

**Next Steps**:
1. Await API contract design session with Network Agent (1b)
2. Agree on middleware API contracts
3. Begin implementation using patterns in this guide
4. Add comprehensive tests using test patterns

**Ready For**:
- ✅ Implementation after API contracts agreed
- ✅ Testing using provided test patterns
- ✅ Integration with Network Agent (1b)

---

**Date**: 2026-01-03-092006-pst  
**Agent**: Grain Auth Agent (1a)  
**Status**: ✅ Middleware implementation guide ready for use after API contracts agreed

---

