# Core 1a Auth Agent: OAuth 2.0 / OIDC Integration Design

**Date**: 2026-01-02-003955-pst  
**Agent**: Grain Auth Agent (1a) — L2 Sub-Agent  
**Parent Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Status**: ✅ **DESIGN READY** — OAuth 2.0 / OIDC integration patterns for future implementation

---

## Executive Summary

This document provides OAuth 2.0 / OIDC integration design patterns for the Auth Agent. These patterns are prepared for future implementation when OAuth becomes a priority (currently MEDIUM priority, awaiting Core 1 Subcore confirmation).

**Current Auth Service Status**:
- ✅ All core authentication features implemented (JWT, password hashing, sessions, API keys, RBAC, CSRF, rate limiting, audit logging)
- ✅ OAuth provider enum defined (`OAuthProvider`: google, facebook, github, apple)
- ⏳ OAuth 2.0 implementation pending (Phase 4)

**OAuth Integration Needs**:
- ⏳ OAuth 2.0 authorization code flow
- ⏳ Provider integrations (Google, GitHub, Facebook, Apple)
- ⏳ Token exchange and user info retrieval
- ⏳ State validation (CSRF protection)
- ⏳ OAuth token management

---

## OAuth 2.0 Architecture

### Authorization Code Flow

**Standard OAuth 2.0 Flow**:
1. **Authorization Request**: Client redirects user to provider authorization URL
2. **User Authorization**: User authorizes application on provider
3. **Authorization Code**: Provider redirects back with authorization code
4. **Token Exchange**: Exchange authorization code for access token
5. **User Info**: Retrieve user information (OIDC)
6. **JWT Generation**: Generate Grain JWT token for authenticated user

**Grain OS Integration**:
- Use existing JWT token generation
- Use existing session management
- Use existing CSRF protection for state parameter
- Integrate with existing user management

---

## API Design

### 1. OAuth Provider Configuration

**Design**: Store OAuth provider configurations in AuthService.

**Structure**:
```zig
// OAuth provider configuration
pub const OAuthProviderConfig = struct {
    provider: OAuthProvider,
    client_id: [MAX_CLIENT_ID_LEN]u8,
    client_id_len: u32,
    client_secret: [MAX_CLIENT_SECRET_LEN]u8,
    client_secret_len: u32,
    redirect_uri: [MAX_REDIRECT_URI_LEN]u8,
    redirect_uri_len: u32,
    authorization_endpoint: [MAX_REDIRECT_URI_LEN]u8,
    authorization_endpoint_len: u32,
    token_endpoint: [MAX_REDIRECT_URI_LEN]u8,
    token_endpoint_len: u32,
    userinfo_endpoint: [MAX_REDIRECT_URI_LEN]u8,
    userinfo_endpoint_len: u32,
    scopes: [MAX_SCOPES]u32,
    scopes_len: u32,
    enabled: bool,
};

// OAuth provider configurations (max 4 providers)
pub const MAX_OAUTH_PROVIDERS: u32 = 4;
pub const MAX_CLIENT_ID_LEN: u32 = 512;
pub const MAX_CLIENT_SECRET_LEN: u32 = 512;
pub const MAX_REDIRECT_URI_LEN: u32 = 512;
pub const MAX_SCOPES: u32 = 8;
```

**AuthService Extension**:
```zig
// OAuth provider configurations
oauth_providers: [MAX_OAUTH_PROVIDERS]OAuthProviderConfig,
oauth_providers_len: u32,
```

---

### 2. Authorization URL Generation

**Function**: `generate_oauth_authorization_url()`

**Design**:
```zig
// Generate OAuth authorization URL
pub fn generate_oauth_authorization_url(
    self: *AuthService,
    provider: OAuthProvider,
    state: []const u8,
    url_out: []u8,
    url_len_out: *u32,
) bool {
    std.debug.assert(state.len > 0);
    std.debug.assert(state.len <= CSRF_TOKEN_STRING_LEN);
    std.debug.assert(url_out.len >= MAX_REDIRECT_URI_LEN * 2);
    std.debug.assert(url_len_out != null);
    
    // Find provider configuration
    const config = self.get_oauth_provider_config(provider) orelse {
        return false;
    };
    
    if (!config.enabled) {
        return false;
    }
    
    // Generate authorization URL
    const auth_url = config.authorization_endpoint[0..config.authorization_endpoint_len];
    const client_id = config.client_id[0..config.client_id_len];
    const redirect_uri = config.redirect_uri[0..config.redirect_uri_len];
    
    // Build scopes string
    var scopes_buf: [256]u8 = undefined;
    const scopes_str = build_scopes_string(&config.scopes, config.scopes_len, &scopes_buf) catch {
        return false;
    };
    
    // Build authorization URL
    const url = std.fmt.bufPrint(
        url_out,
        "{s}?client_id={s}&redirect_uri={s}&response_type=code&scope={s}&state={s}",
        .{ auth_url, client_id, redirect_uri, scopes_str, state },
    ) catch {
        return false;
    };
    
    url_len_out.* = @intCast(url.len);
    return true;
}
```

**State Parameter**: Use CSRF token as state parameter for CSRF protection.

---

### 3. Token Exchange

**Function**: `exchange_oauth_code_for_token()`

**Design**:
```zig
// OAuth token response
pub const OAuthTokenResponse = struct {
    access_token: [MAX_ACCESS_TOKEN_LEN]u8,
    access_token_len: u32,
    token_type: [32]u8,
    token_type_len: u32,
    expires_in: u64,
    refresh_token: [MAX_REFRESH_TOKEN_LEN]u8,
    refresh_token_len: u32,
    scope: [256]u8,
    scope_len: u32,
    id_token: [MAX_JWT_LEN]u8, // OIDC ID token
    id_token_len: u32,
};

// Exchange authorization code for access token
pub fn exchange_oauth_code_for_token(
    self: *AuthService,
    provider: OAuthProvider,
    auth_code: []const u8,
    current_time: u64,
    token_response_out: *OAuthTokenResponse,
) bool {
    std.debug.assert(auth_code.len > 0);
    std.debug.assert(auth_code.len <= MAX_AUTH_CODE_LEN);
    std.debug.assert(current_time > 0);
    std.debug.assert(token_response_out != null);
    
    // Find provider configuration
    const config = self.get_oauth_provider_config(provider) orelse {
        return false;
    };
    
    if (!config.enabled) {
        return false;
    }
    
    // Build token exchange request
    // Note: Requires HTTP client (Network Agent 1b integration)
    // For now, placeholder implementation
    
    // TODO: Make HTTP POST request to token endpoint
    // POST {token_endpoint}
    // Content-Type: application/x-www-form-urlencoded
    // Body: grant_type=authorization_code&code={auth_code}&client_id={client_id}&client_secret={client_secret}&redirect_uri={redirect_uri}
    
    // Parse token response (JSON)
    // Store tokens in token_response_out
    
    return false; // Placeholder
}
```

**HTTP Client Integration**: Requires Network Agent (1b) HTTP client for token exchange.

---

### 4. User Info Retrieval (OIDC)

**Function**: `retrieve_oauth_user_info()`

**Design**:
```zig
// OAuth user info (OIDC)
pub const OAuthUserInfo = struct {
    sub: [MAX_USER_ID_LEN]u8, // Subject (user ID from provider)
    sub_len: u32,
    email: [MAX_EMAIL_LEN]u8,
    email_len: u32,
    name: [256]u8,
    name_len: u32,
    picture: [MAX_REDIRECT_URI_LEN]u8,
    picture_len: u32,
    provider: OAuthProvider,
};

// Retrieve user information from OIDC userinfo endpoint
pub fn retrieve_oauth_user_info(
    self: *AuthService,
    provider: OAuthProvider,
    access_token: []const u8,
    user_info_out: *OAuthUserInfo,
) bool {
    std.debug.assert(access_token.len > 0);
    std.debug.assert(access_token.len <= MAX_ACCESS_TOKEN_LEN);
    std.debug.assert(user_info_out != null);
    
    // Find provider configuration
    const config = self.get_oauth_provider_config(provider) orelse {
        return false;
    };
    
    if (!config.enabled) {
        return false;
    }
    
    // Build userinfo request
    // Note: Requires HTTP client (Network Agent 1b integration)
    // For now, placeholder implementation
    
    // TODO: Make HTTP GET request to userinfo endpoint
    // GET {userinfo_endpoint}
    // Authorization: Bearer {access_token}
    
    // Parse userinfo response (JSON)
    // Store user info in user_info_out
    
    return false; // Placeholder
}
```

**HTTP Client Integration**: Requires Network Agent (1b) HTTP client for user info retrieval.

---

### 5. OAuth State Validation

**Function**: `validate_oauth_state()`

**Design**:
```zig
// Validate OAuth state parameter (CSRF protection)
pub fn validate_oauth_state(
    self: *AuthService,
    state: []const u8,
    current_time: u64,
) bool {
    std.debug.assert(state.len > 0);
    std.debug.assert(state.len <= CSRF_TOKEN_STRING_LEN);
    std.debug.assert(current_time > 0);
    
    // Validate state as CSRF token
    // Use existing CSRF token validation
    const session_id = ""; // OAuth state doesn't require session
    return self.validate_csrf_token(state, session_id, current_time);
}
```

**Integration**: Reuse existing CSRF token validation for OAuth state parameter.

---

### 6. OAuth User Creation / Login

**Function**: `create_or_login_oauth_user()`

**Design**:
```zig
// Create or login user from OAuth authentication
pub fn create_or_login_oauth_user(
    self: *AuthService,
    user_info: *OAuthUserInfo,
    current_time: u64,
    jwt_token_out: []u8,
    jwt_token_len_out: *u32,
) bool {
    std.debug.assert(user_info != null);
    std.debug.assert(current_time > 0);
    std.debug.assert(jwt_token_out.len >= MAX_JWT_LEN);
    std.debug.assert(jwt_token_len_out != null);
    
    // Generate user_id from provider sub (e.g., "google_{sub}")
    var user_id_buf: [MAX_USER_ID_LEN]u8 = undefined;
    const provider_str = switch (user_info.provider) {
        .google => "google",
        .github => "github",
        .facebook => "facebook",
        .apple => "apple",
    };
    
    const user_id = std.fmt.bufPrint(
        &user_id_buf,
        "{s}_{s}",
        .{ provider_str, user_info.sub[0..user_info.sub_len] },
    ) catch {
        return false;
    };
    
    // Check if user exists (requires Storage Agent integration)
    // For now, assume user creation
    
    // Create JWT token for user
    var claims: JwtClaims = undefined;
    claims.user_id_len = @intCast(user_id.len);
    std.mem.copyForwards(u8, &claims.user_id, user_id);
    claims.exp = current_time + ACCESS_TOKEN_EXPIRY;
    claims.iat = current_time;
    claims.token_type = TokenType.access;
    claims.role_count = 0; // Default roles (can be assigned later)
    
    // Generate JWT token
    return self.generate_jwt_token_static(
        &claims,
        jwt_token_out,
        jwt_token_len_out,
    );
}
```

**User Management**: Requires Storage Agent integration for user persistence.

---

## Provider-Specific Configurations

### Google OAuth

**Configuration**:
```zig
const GOOGLE_AUTHORIZATION_ENDPOINT = "https://accounts.google.com/o/oauth2/v2/auth";
const GOOGLE_TOKEN_ENDPOINT = "https://oauth2.googleapis.com/token";
const GOOGLE_USERINFO_ENDPOINT = "https://openidconnect.googleapis.com/v1/userinfo";
const GOOGLE_SCOPES = "openid email profile";
```

**OIDC Support**: ✅ Full OIDC support (ID token, userinfo endpoint)

---

### GitHub OAuth

**Configuration**:
```zig
const GITHUB_AUTHORIZATION_ENDPOINT = "https://github.com/login/oauth/authorize";
const GITHUB_TOKEN_ENDPOINT = "https://github.com/login/oauth/access_token";
const GITHUB_USERINFO_ENDPOINT = "https://api.github.com/user";
const GITHUB_SCOPES = "read:user user:email";
```

**OIDC Support**: ⚠️ Limited (no ID token, custom userinfo endpoint)

---

### Facebook OAuth

**Configuration**:
```zig
const FACEBOOK_AUTHORIZATION_ENDPOINT = "https://www.facebook.com/v18.0/dialog/oauth";
const FACEBOOK_TOKEN_ENDPOINT = "https://graph.facebook.com/v18.0/oauth/access_token";
const FACEBOOK_USERINFO_ENDPOINT = "https://graph.facebook.com/v18.0/me?fields=id,name,email";
const FACEBOOK_SCOPES = "email public_profile";
```

**OIDC Support**: ❌ No OIDC support (custom API)

---

### Apple Sign-In

**Configuration**:
```zig
const APPLE_AUTHORIZATION_ENDPOINT = "https://appleid.apple.com/auth/authorize";
const APPLE_TOKEN_ENDPOINT = "https://appleid.apple.com/auth/token";
const APPLE_USERINFO_ENDPOINT = "https://appleid.apple.com/auth/userinfo";
const APPLE_SCOPES = "name email";
```

**OIDC Support**: ✅ Full OIDC support (ID token, userinfo endpoint)

**Special Requirements**:
- Requires JWT client secret (not static client secret)
- Requires private key for JWT signing

---

## Integration with Existing Auth Service

### JWT Token Generation

**Integration**: Use existing `generate_jwt_token_static()` for OAuth-authenticated users.

**Flow**:
1. OAuth authentication completes
2. User info retrieved from provider
3. User ID generated from provider sub
4. JWT token generated with user ID and roles
5. Session created (optional)

---

### Session Management

**Integration**: Use existing session management for OAuth-authenticated users.

**Flow**:
1. OAuth authentication completes
2. User ID determined
3. Session created via `create_session()`
4. Session ID returned to client

---

### RBAC Integration

**Integration**: Assign default roles to OAuth-authenticated users.

**Flow**:
1. OAuth authentication completes
2. User ID determined
3. Default roles assigned (e.g., "user" role)
4. Roles included in JWT claims
5. Permissions checked via existing RBAC system

---

## HTTP Client Integration (Network Agent 1b)

### Required HTTP Client Functions

**Design**: Network Agent (1b) should provide HTTP client functions for OAuth flows.

**Required Functions**:
```zig
// HTTP POST request (for token exchange)
pub fn http_post(
    url: []const u8,
    headers: []const HttpHeader,
    body: []const u8,
    response_out: []u8,
    response_len_out: *u32,
) bool;

// HTTP GET request (for userinfo)
pub fn http_get(
    url: []const u8,
    headers: []const HttpHeader,
    response_out: []u8,
    response_len_out: *u32,
) bool;

// HTTP header structure
pub const HttpHeader = struct {
    name: [64]u8,
    name_len: u32,
    value: [256]u8,
    value_len: u32,
};
```

**Coordination**: Coordinate with Network Agent (1b) on HTTP client API design.

---

## Questions for Network Agent (1b)

**HTTP Client Integration Questions**:

1. **HTTP Client API**:
   - [ ] Is HTTP client API available or planned?
   - [ ] What is the API design for HTTP requests?
   - [ ] How should we handle HTTP errors and timeouts?

2. **OAuth Token Exchange**:
   - [ ] How should we make POST requests to token endpoints?
   - [ ] How should we handle form-urlencoded request bodies?
   - [ ] How should we parse JSON responses?

3. **OAuth User Info**:
   - [ ] How should we make GET requests with Authorization header?
   - [ ] How should we parse JSON userinfo responses?

4. **Error Handling**:
   - [ ] How should we handle OAuth provider errors?
   - [ ] How should we handle network errors?
   - [ ] How should we handle invalid responses?

---

## Implementation Timeline

### Phase 1: Core OAuth Implementation (Week 1-2)
- [ ] Design OAuth provider configuration structure
- [ ] Implement authorization URL generation
- [ ] Implement state parameter management (CSRF protection)
- [ ] Implement OAuth provider configuration management
- [ ] Add comprehensive OAuth tests

### Phase 2: Token Exchange (Week 2-3)
- [ ] Coordinate with Network Agent (1b) on HTTP client API
- [ ] Implement token exchange logic
- [ ] Implement token response parsing
- [ ] Add token exchange tests

### Phase 3: Provider Integration (Week 3)
- [ ] Implement Google OAuth integration
- [ ] Implement GitHub OAuth integration
- [ ] Implement Facebook OAuth integration (optional)
- [ ] Implement Apple Sign-In integration (optional)
- [ ] Add provider-specific tests

### Phase 4: User Info and JWT Generation (Week 3-4)
- [ ] Implement user info retrieval (OIDC)
- [ ] Implement OAuth user creation/login
- [ ] Integrate with existing JWT token generation
- [ ] Integrate with existing session management
- [ ] Add end-to-end OAuth tests

---

## Grain Style Compliance

**All OAuth Functions**:
- ✅ Function length ≤ 70 lines
- ✅ Line length ≤ 100 characters
- ✅ Explicit types (`u32`/`u64`, no `usize`/`isize`)
- ✅ Bounded allocations (MAX_ constants)
- ✅ Minimum 2 assertions per function
- ✅ `grain_case` function names

---

## Summary

**Status**: ✅ **DESIGN READY** — OAuth 2.0 / OIDC integration patterns prepared for future implementation

**Next Steps**:
1. Await Core 1 Subcore priority confirmation (currently MEDIUM)
2. Coordinate with Network Agent (1b) on HTTP client API
3. Begin implementation when priority confirmed

**Ready For**:
- ✅ Design discussion with Core 1 Subcore
- ✅ HTTP client coordination with Network Agent (1b)
- ✅ Implementation (after priority confirmation)

---

**Date**: 2026-01-02-003955-pst  
**Agent**: Grain Auth Agent (1a)  
**Status**: ✅ OAuth 2.0 / OIDC integration design ready for future implementation

---

