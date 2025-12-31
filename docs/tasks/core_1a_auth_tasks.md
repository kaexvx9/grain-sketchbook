# Grain Auth Agent: Task List

**Agent**: Grain Auth Agent (1a)  
**Parent Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Status**: ✅ **PHASE 1 COMPLETE** — Ready for Phase 2  
**Last Updated**: 2025-12-30-235500-pst

---

## Completed: Phase 1 - Assessment & Grain Style Compliance

**Status**: ✅ **COMPLETE**  
**Date Started**: 2025-12-30-234200-pst  
**Date Completed**: 2025-12-30-235500-pst  
**Priority**: HIGH  
**Estimated Time**: 1-2 days ✅ **COMPLETE** (completed on schedule)

### Phase 1 Tasks

- [✅] Read and understand agent prompt
- [✅] Review existing auth service code (`src/grain_core/auth_service.zig`)
- [✅] Review test coverage (`tests/114_grain_core_auth_service_test.zig`)
- [✅] Review Grain Style guide
- [✅] Create coordination document (`docs/core-coordination/core_1a_auth_coordination.md`)
- [ ] Create plan document (`docs/plans/core_1a_auth_plan.md`) — **IN PROGRESS**
- [ ] Create tasks document (this file) — **IN PROGRESS**
- [ ] Full code review of `auth_service.zig` (1031 lines)
  - [ ] Document all functions and their purposes
  - [ ] Identify all constants and their usage
  - [ ] Review data structures and their constraints
  - [ ] Document integration points
- [ ] Run Grain Style validation tools
  - [ ] Run `grain validate-70` on `auth_service.zig`
  - [ ] Identify all functions exceeding 70 lines
  - [ ] Run `grainwrap-100` on `auth_service.zig`
  - [ ] Identify all lines exceeding 100 characters
  - [ ] Create refactoring plan for violations
- [ ] Fix Grain Style compliance issues
  - [ ] Refactor functions exceeding 70 lines
  - [ ] Wrap lines exceeding 100 characters
  - [ ] Verify all assertions meet minimum (2 per function)
  - [ ] Ensure all types are explicit (`u32`/`u64`, no `usize`/`isize`)
  - [ ] Verify all allocations are bounded with `MAX_` constants
- [ ] Review test coverage
  - [ ] List all test cases in `tests/114_grain_core_auth_service_test.zig`
  - [ ] Identify missing test cases
  - [ ] Document edge cases that need testing
  - [ ] Document integration test needs
- [ ] Complete gap analysis
  - [ ] List all features from prompt requirements
  - [ ] Compare with existing implementation
  - [ ] Prioritize missing features
  - [ ] Create feature implementation roadmap
- [ ] Initial coordination with Core 1 Subcore
  - [ ] Share coordination document
  - [ ] Request architecture decisions (OAuth, Argon2, RBAC)
  - [ ] Confirm priorities and roadmap
  - [ ] Schedule regular coordination check-ins

---

## Phase 2: Enhanced Password Security

**Status**: ⏳ **PLANNED**  
**Priority**: HIGH  
**Estimated Time**: 1 week  
**Dependencies**: Phase 1 complete

### Phase 2 Tasks

- [ ] Research Argon2 implementation
  - [ ] Review Argon2 specification (RFC 9106)
  - [ ] Evaluate pure Zig implementation options
  - [ ] Evaluate library options (if pure Zig not feasible)
  - [ ] Make implementation recommendation
- [ ] Coordinate with Core 1 Subcore
  - [ ] Present Argon2 implementation options
  - [ ] Get approval for implementation approach
  - [ ] Confirm zero-dependency policy (pure Zig preferred)
- [ ] Implement Argon2 password hashing
  - [ ] Implement Argon2id variant (recommended)
  - [ ] Add Argon2 configuration (memory, time, parallelism)
  - [ ] Add Argon2 hash generation function
  - [ ] Add Argon2 hash verification function
  - [ ] Add Argon2 parameter validation
- [ ] Add migration support
  - [ ] Implement hash format detection (SHA-256 vs Argon2)
  - [ ] Implement password rehashing on login (SHA-256 → Argon2)
  - [ ] Add migration configuration
- [ ] Update password hashing API
  - [ ] Update `hash_password_static` to use Argon2
  - [ ] Update `verify_password_static` to support both formats
  - [ ] Maintain backward compatibility during migration
- [ ] Add Argon2 tests
  - [ ] Test Argon2 hash generation
  - [ ] Test Argon2 hash verification
  - [ ] Test parameter validation
  - [ ] Test migration logic
  - [ ] Test backward compatibility
  - [ ] Add performance tests
- [ ] Update documentation
  - [ ] Document Argon2 configuration
  - [ ] Document migration process
  - [ ] Update API documentation

---

## Phase 3: API Key Management

**Status**: ⏳ **PLANNED**  
**Priority**: MEDIUM  
**Estimated Time**: 3-5 days  
**Dependencies**: Phase 1 complete

### Phase 3 Tasks

- [ ] Design API key structure
  - [ ] Define API key format (prefix + random)
  - [ ] Define API key metadata (user_id, scopes, expiration)
  - [ ] Define API key lifecycle (active, revoked, expired)
- [ ] Implement API key generation
  - [ ] Generate secure random API keys
  - [ ] Add API key prefix support (e.g., "grain_live_", "grain_test_")
  - [ ] Hash API keys for storage (use secure hash)
  - [ ] Store API key metadata
- [ ] Implement API key validation
  - [ ] Validate API key format
  - [ ] Lookup API key by hash
  - [ ] Check API key expiration
  - [ ] Check API key revocation status
  - [ ] Return API key metadata (user_id, scopes)
- [ ] Implement API key scopes/permissions
  - [ ] Define scope model (read, write, admin, custom)
  - [ ] Implement scope validation
  - [ ] Add scope-based access control
- [ ] Implement API key revocation
  - [ ] Add API key to revocation list
  - [ ] Implement revocation lookup
  - [ ] Add revocation expiration (cleanup old revocations)
- [ ] Implement API key expiration
  - [ ] Add expiration time to API keys
  - [ ] Validate expiration on lookup
  - [ ] Implement automatic cleanup of expired keys
- [ ] Implement API key rotation
  - [ ] Generate new API key
  - [ ] Revoke old API key
  - [ ] Support grace period for rotation
- [ ] Add API key management API
  - [ ] `generate_api_key()` — Generate new API key
  - [ ] `validate_api_key()` — Validate API key
  - [ ] `revoke_api_key()` — Revoke API key
  - [ ] `list_api_keys()` — List user's API keys
  - [ ] `rotate_api_key()` — Rotate API key
- [ ] Add API key tests
  - [ ] Test API key generation
  - [ ] Test API key validation
  - [ ] Test API key revocation
  - [ ] Test API key expiration
  - [ ] Test API key scopes
  - [ ] Test API key rotation
  - [ ] Test edge cases (invalid format, expired, revoked)
- [ ] Coordinate with Storage Agent (1c)
  - [ ] Design secure API key storage
  - [ ] Coordinate on hash storage requirements
- [ ] Update documentation
  - [ ] Document API key structure
  - [ ] Document API key lifecycle
  - [ ] Document API key scopes
  - [ ] Update API documentation

---

## Phase 4: OAuth 2.0 / OIDC Integration

**Status**: ⏳ **PLANNED**  
**Priority**: MEDIUM  
**Estimated Time**: 2-3 weeks  
**Dependencies**: Phase 1 complete, Network Agent (1b) coordination

### Phase 4 Tasks

- [ ] Design OAuth flow architecture
  - [ ] Review OAuth 2.0 specification (RFC 6749)
  - [ ] Review OIDC specification (OpenID Connect Core 1.0)
  - [ ] Design authorization code flow (PKCE recommended)
  - [ ] Design token storage strategy
  - [ ] Design user info retrieval strategy
- [ ] Coordinate with Core 1 Subcore
  - [ ] Present OAuth architecture design
  - [ ] Get approval for OAuth flow implementation
  - [ ] Confirm provider requirements
- [ ] Coordinate with Network Agent (1b)
  - [ ] Design HTTP client integration for OAuth
  - [ ] Coordinate on redirect handling
  - [ ] Coordinate on HTTPS requirements
- [ ] Implement OAuth authorization request
  - [ ] Generate authorization URL
  - [ ] Add OAuth state parameter (CSRF protection)
  - [ ] Add PKCE code challenge (if using PKCE)
  - [ ] Add provider-specific parameters
- [ ] Implement OAuth callback handling
  - [ ] Validate OAuth state parameter
  - [ ] Extract authorization code from callback
  - [ ] Validate callback parameters
  - [ ] Handle OAuth errors
- [ ] Implement token exchange
  - [ ] Exchange authorization code for access token
  - [ ] Handle token response (access token, refresh token, ID token)
  - [ ] Validate token response
  - [ ] Store OAuth tokens securely
- [ ] Implement OIDC user info retrieval
  - [ ] Retrieve user info from OIDC provider
  - [ ] Parse user info response
  - [ ] Validate user info claims
  - [ ] Map provider user info to Grain OS user
- [ ] Implement OAuth token refresh
  - [ ] Refresh access token using refresh token
  - [ ] Handle refresh token expiration
  - [ ] Update stored tokens
- [ ] Implement provider configurations
  - [ ] Google OAuth configuration
  - [ ] GitHub OAuth configuration
  - [ ] Facebook OAuth configuration
  - [ ] Apple OAuth configuration
  - [ ] Provider-specific parameter handling
- [ ] Add OAuth state management
  - [ ] Generate and store OAuth state
  - [ ] Validate OAuth state on callback
  - [ ] Clean up expired OAuth state
- [ ] Add OAuth management API
  - [ ] `initiate_oauth_login()` — Start OAuth flow
  - [ ] `handle_oauth_callback()` — Handle OAuth callback
  - [ ] `refresh_oauth_token()` — Refresh OAuth token
  - [ ] `revoke_oauth_token()` — Revoke OAuth token
- [ ] Add OAuth tests
  - [ ] Test OAuth authorization request generation
  - [ ] Test OAuth callback handling
  - [ ] Test token exchange
  - [ ] Test user info retrieval
  - [ ] Test token refresh
  - [ ] Test provider-specific configurations
  - [ ] Test OAuth state validation
  - [ ] Test error handling
- [ ] Coordinate with Storage Agent (1c)
  - [ ] Design secure OAuth token storage
  - [ ] Coordinate on user mapping storage
- [ ] Update documentation
  - [ ] Document OAuth flow
  - [ ] Document provider configurations
  - [ ] Document OAuth API
  - [ ] Update API documentation

---

## Phase 5: Role-Based Access Control (RBAC)

**Status**: ⏳ **PLANNED**  
**Priority**: MEDIUM  
**Estimated Time**: 2 weeks  
**Dependencies**: Phase 1 complete

### Phase 5 Tasks

- [ ] Design RBAC model
  - [ ] Define role model (roles, permissions, resources)
  - [ ] Define permission model (actions on resources)
  - [ ] Define resource model (hierarchical resources)
  - [ ] Define policy model (role → permissions mapping)
  - [ ] Design role hierarchy (role inheritance)
- [ ] Coordinate with Core 1 Subcore
  - [ ] Present RBAC model design
  - [ ] Get approval for RBAC implementation
  - [ ] Confirm role and permission requirements
- [ ] Implement role management
  - [ ] `create_role()` — Create new role
  - [ ] `update_role()` — Update role
  - [ ] `delete_role()` — Delete role
  - [ ] `list_roles()` — List all roles
  - [ ] `get_role()` — Get role details
- [ ] Implement permission management
  - [ ] `create_permission()` — Create new permission
  - [ ] `assign_permission_to_role()` — Assign permission to role
  - [ ] `remove_permission_from_role()` — Remove permission from role
  - [ ] `list_role_permissions()` — List role's permissions
- [ ] Implement resource management
  - [ ] `define_resource()` — Define resource type
  - [ ] `check_resource_access()` — Check resource access
  - [ ] `list_user_resources()` — List user's accessible resources
- [ ] Implement role hierarchy
  - [ ] `set_role_parent()` — Set role parent (inheritance)
  - [ ] `get_role_permissions()` — Get role permissions (with inheritance)
  - [ ] `validate_role_hierarchy()` — Validate no circular dependencies
- [ ] Implement policy enforcement
  - [ ] `check_permission()` — Check if user has permission
  - [ ] `check_resource_permission()` — Check resource-specific permission
  - [ ] `evaluate_policy()` — Evaluate policy rules
- [ ] Integrate RBAC with JWT tokens
  - [ ] Add role claims to JWT tokens
  - [ ] Add permission claims to JWT tokens (optional, for performance)
  - [ ] Validate role/permission claims in JWT
- [ ] Add RBAC management API
  - [ ] Role management endpoints
  - [ ] Permission management endpoints
  - [ ] User role assignment endpoints
- [ ] Add RBAC tests
  - [ ] Test role creation, update, deletion
  - [ ] Test permission assignment
  - [ ] Test role hierarchy and inheritance
  - [ ] Test policy enforcement
  - [ ] Test JWT integration
  - [ ] Test edge cases (circular dependencies, invalid permissions)
- [ ] Coordinate with Storage Agent (1c)
  - [ ] Design role/permission storage
  - [ ] Coordinate on user-role mapping storage
- [ ] Coordinate with Network Agent (1b)
  - [ ] Design RBAC middleware
  - [ ] Coordinate on permission checking in middleware
- [ ] Update documentation
  - [ ] Document RBAC model
  - [ ] Document role hierarchy
  - [ ] Document RBAC API
  - [ ] Update API documentation

---

## Phase 6: Security Hardening

**Status**: ⏳ **PLANNED**  
**Priority**: HIGH  
**Estimated Time**: 1-2 weeks  
**Dependencies**: Phase 1 complete, Network Agent (1b) coordination

### Phase 6 Tasks

- [ ] Implement CSRF protection
  - [ ] Generate CSRF tokens
  - [ ] Validate CSRF tokens
  - [ ] Add CSRF token to authentication endpoints
  - [ ] Store CSRF tokens securely (session-based)
- [ ] Coordinate with Network Agent (1b) on rate limiting
  - [ ] Design rate limiting strategy
  - [ ] Define rate limit rules (login, registration, OTP)
  - [ ] Implement rate limiting middleware (or coordinate with 1b)
- [ ] Implement rate limiting for auth endpoints
  - [ ] Rate limit login attempts (e.g., 5 per minute per IP)
  - [ ] Rate limit registration attempts (e.g., 3 per hour per IP)
  - [ ] Rate limit OTP requests (e.g., 3 per hour per email)
  - [ ] Rate limit password reset requests
  - [ ] Implement sliding window or token bucket algorithm
- [ ] Add security audit logging
  - [ ] Log login attempts (success, failure, IP, user agent)
  - [ ] Log token generation and revocation
  - [ ] Log permission denials
  - [ ] Log suspicious activity (brute force, token abuse)
  - [ ] Design audit log format
- [ ] Implement secure token storage
  - [ ] Coordinate with Storage Agent (1c) on secure token storage
  - [ ] Design token encryption strategy (if needed)
  - [ ] Implement token rotation
  - [ ] Implement token cleanup (expired tokens)
- [ ] Implement security headers
  - [ ] Add HSTS (HTTP Strict Transport Security)
  - [ ] Add CSP (Content Security Policy)
  - [ ] Add X-Frame-Options
  - [ ] Add X-Content-Type-Options
  - [ ] Coordinate with Network Agent (1b) on header injection
- [ ] Add security tests
  - [ ] Test CSRF protection
  - [ ] Test rate limiting
  - [ ] Test audit logging
  - [ ] Test token security
  - [ ] Test security headers
  - [ ] Add penetration testing scenarios
- [ ] Coordinate with Storage Agent (1c)
  - [ ] Design audit log storage
  - [ ] Coordinate on secure token storage
- [ ] Update documentation
  - [ ] Document CSRF protection
  - [ ] Document rate limiting
  - [ ] Document audit logging
  - [ ] Document security best practices

---

## Phase 7: Enhanced Test Coverage

**Status**: ⏳ **PLANNED**  
**Priority**: MEDIUM  
**Estimated Time**: Ongoing (parallel with other phases)

### Phase 7 Tasks

- [ ] Review current test coverage
  - [ ] Calculate test coverage percentage
  - [ ] Identify untested code paths
  - [ ] Identify missing edge cases
- [ ] Add edge case tests
  - [ ] Test expired tokens
  - [ ] Test invalid token formats
  - [ ] Test boundary conditions (MAX_ constants)
  - [ ] Test error handling
  - [ ] Test concurrent access (if applicable)
- [ ] Add integration tests
  - [ ] Test auth service + API server integration
  - [ ] Test auth service + middleware integration
  - [ ] Test auth service + database integration (if applicable)
  - [ ] Test end-to-end authentication flows
- [ ] Add fuzz tests
  - [ ] Fuzz JWT parsing and validation
  - [ ] Fuzz password hashing inputs
  - [ ] Fuzz OAuth callback parameters
  - [ ] Fuzz RBAC policy evaluation
- [ ] Add performance tests
  - [ ] Benchmark JWT generation/validation
  - [ ] Benchmark password hashing (Argon2)
  - [ ] Benchmark token lookup
  - [ ] Benchmark permission checking
- [ ] Add security tests
  - [ ] Test timing attacks (password comparison)
  - [ ] Test injection attacks (SQL, NoSQL, XSS)
  - [ ] Test token manipulation attacks
  - [ ] Test privilege escalation attempts
- [ ] Document test strategy
  - [ ] Document test organization
  - [ ] Document test coverage goals
  - [ ] Document test execution

---

## Coordination Tasks

### With Core 1 Subcore (L1)

- [ ] Initial check-in (schedule weekly/bi-weekly)
- [ ] Request architecture decisions (OAuth, Argon2, RBAC)
- [ ] Share progress updates
- [ ] Request priorities confirmation
- [ ] Report blockers

### With Network Agent (1b) (L2)

- [ ] Coordinate on authentication middleware
- [ ] Coordinate on rate limiting implementation
- [ ] Coordinate on CSRF protection integration
- [ ] Coordinate on OAuth HTTP client integration

**Frequency**: As-needed when work intersects

### With Storage Agent (1c) (L2)

- [ ] Coordinate on secure credential storage
- [ ] Coordinate on API key storage
- [ ] Coordinate on OAuth token storage
- [ ] Coordinate on audit log storage
- [ ] Coordinate on session persistence (if needed)

**Frequency**: As-needed when secure storage work intersects

---

## Notes

- All tasks must follow Grain Style strictly
- All tasks must target RISC-V only (no ARM64-specific code)
- Zero technical debt policy — do it right the first time
- Update this document as tasks are completed
- Mark tasks as complete with ✅ when done

---

**Date**: 2025-12-30-234200-pst  
**Agent**: Grain Auth Agent (1a)  
**Status**: ✅ INITIALIZED  
**Parent Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)

---
