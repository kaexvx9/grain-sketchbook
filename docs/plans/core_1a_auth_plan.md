# Grain Auth Agent: Implementation Plan

**Agent**: Grain Auth Agent (1a)  
**Parent Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Last Updated**: 2025-12-30-234200-pst  
**Status**: ✅ **INITIALIZED** — Ready for Development

---

## Overview

Grain Auth Agent is responsible for implementing **authentication and authorization services** for the Grain OS ecosystem. This includes JWT token management, OAuth 2.0/OIDC integration, password hashing, session management, 2FA, RBAC, API key management, and security hardening features.

**Key Goals**:
- Provide secure authentication services (JWT, OAuth, magic email, 2FA)
- Implement robust authorization (RBAC, permissions, policies)
- Ensure security best practices (CSRF, rate limiting, audit logging)
- Maintain Grain Style compliance (zero technical debt)
- Coordinate with Network Agent (1b) for middleware
- Coordinate with Storage Agent (1c) for secure credential storage

**Critical Principles**:
- **RISC-V Only**: All code targets RISC-V only (no ARM64-specific code)
- **Grain Style**: Strict compliance with all Grain Style rules
- **Zero Technical Debt**: Do it right the first time, complete implementations only
- **Security First**: Security is non-negotiable, follow best practices

---

## Current Status

**Phase**: ⏳ **ASSESSMENT & PLANNING** — Initial assessment in progress

**Existing Implementation** (`src/grain_core/auth_service.zig`):
- ✅ **Foundation Complete**: Core JWT, password hashing, sessions, OTP/TOTP implemented
- ✅ **Code Quality**: Generally follows Grain Style (explicit types, bounded allocations, assertions)
- ⏳ **Grain Style Validation**: Function/line length validation needed
- ❌ **Missing Features**: OAuth, Argon2, RBAC, API keys, CSRF, rate limiting, audit logging

**Test Coverage** (`tests/114_grain_core_auth_service_test.zig`):
- ✅ **Basic Coverage**: Core features tested
- ⏳ **Enhanced Coverage**: Edge cases, integration tests needed

---

## Development Philosophy: Grain Style

**CRITICAL**: All code must follow **Grain Style** (TigerStyle-compliant). This is non-negotiable.

### Core Principles

1. **Function Naming**: `grain_case` (snake_case)
2. **Explicit Types**: Use `u32`, `u64`, `i64` instead of `usize`/`isize`
3. **No Recursion**: Convert all recursive functions to iterative (stack-based) algorithms
4. **Bounded Allocations**: All dynamic data structures must have `MAX_` constants and assertions
5. **Assertions**: Minimum 2 assertions per function (preconditions, postconditions, invariants)
6. **Compiler Warnings**: All warnings must be enabled and resolved
7. **No Hidden Allocations**: All memory allocation must be explicit
8. **Static Allocation Preferred**: Avoid heap allocation after startup where possible
9. **Function Length**: Maximum 70 lines per function (`grain validate-70`)
10. **Line Length**: Maximum 100 characters per line (`grainwrap-100`)

### Zig Version

- **MUST use Zig 0.15.2** everywhere

### Zero Technical Debt Policy

- Do it right the first time
- No TODOs or FIXMEs in production code
- Complete implementations only (no stubs or placeholders)
- Comprehensive test coverage required

---

## Implementation Phases

### Phase 1: Assessment & Grain Style Compliance ✅ **IN PROGRESS**

**Status**: ⏳ **IN PROGRESS**  
**Priority**: HIGH  
**Estimated Time**: 1-2 days  
**Started**: 2025-12-30-234200-pst

**Goals**:
- Complete initial assessment of existing implementation
- Validate and fix Grain Style compliance issues
- Create comprehensive plan and task breakdown

**Tasks**:
- [ ] Full code review of `auth_service.zig` (1031 lines)
- [ ] Run `grain validate-70` and identify function length violations
- [ ] Run `grainwrap-100` and identify line length violations
- [ ] Fix all Grain Style compliance issues
- [ ] Verify all assertions meet minimum requirements (2 per function)
- [ ] Review test coverage and identify gaps
- [ ] Complete coordination documents
- [ ] Create detailed implementation plan

**Deliverables**:
- ✅ Coordination document (`docs/core-coordination/core_1a_auth_coordination.md`)
- [ ] Plan document (this file, completed)
- [ ] Tasks document (`docs/tasks/core_1a_auth_tasks.md`)
- [ ] Grain Style compliance report
- [ ] Gap analysis document

---

### Phase 2: Enhanced Password Security

**Status**: ⏳ **PLANNED**  
**Priority**: HIGH  
**Estimated Time**: 1 week  
**Dependencies**: Phase 1 complete

**Goals**:
- Replace SHA-256 with Argon2 for password hashing
- Add migration path from SHA-256 to Argon2
- Maintain backward compatibility during transition

**Tasks**:
- [ ] Research Argon2 implementation options (pure Zig vs library)
- [ ] Implement Argon2 password hashing (pure Zig preferred)
- [ ] Add Argon2 configuration (memory, time, parallelism parameters)
- [ ] Implement password hash migration logic
- [ ] Update password verification to support both SHA-256 and Argon2
- [ ] Add Argon2 tests
- [ ] Update documentation

**Coordination**:
- Coordinate with Core 1 Subcore on Argon2 implementation strategy
- Coordinate with Storage Agent (1c) on secure hash storage

---

### Phase 3: API Key Management

**Status**: ⏳ **PLANNED**  
**Priority**: MEDIUM  
**Estimated Time**: 3-5 days  
**Dependencies**: Phase 1 complete

**Goals**:
- Implement API key generation, validation, and revocation
- Support scoped API keys (read, write, admin permissions)
- Add API key expiration and rotation

**Tasks**:
- [ ] Design API key structure and lifecycle
- [ ] Implement API key generation (secure random, prefix-based)
- [ ] Implement API key validation
- [ ] Implement API key revocation (blacklist)
- [ ] Add API key expiration support
- [ ] Add API key scopes/permissions
- [ ] Implement API key rotation
- [ ] Add comprehensive API key tests
- [ ] Update documentation

**Coordination**:
- Coordinate with Core 1 Subcore on API key requirements
- Coordinate with Storage Agent (1c) on secure API key storage

---

### Phase 4: OAuth 2.0 / OIDC Integration

**Status**: ⏳ **PLANNED**  
**Priority**: MEDIUM  
**Estimated Time**: 2-3 weeks  
**Dependencies**: Phase 1 complete, Network Agent (1b) coordination

**Goals**:
- Implement OAuth 2.0 authorization code flow
- Support OIDC (OpenID Connect) for identity
- Integrate with major providers (Google, GitHub, Facebook, Apple)

**Tasks**:
- [ ] Design OAuth flow architecture
- [ ] Implement OAuth authorization request generation
- [ ] Implement OAuth callback handling
- [ ] Implement token exchange (authorization code → access token)
- [ ] Implement user info retrieval (OIDC)
- [ ] Add provider-specific configurations (Google, GitHub, Facebook, Apple)
- [ ] Implement OAuth token refresh
- [ ] Add OAuth state validation (CSRF protection)
- [ ] Add comprehensive OAuth tests
- [ ] Update documentation

**Coordination**:
- Coordinate with Core 1 Subcore on OAuth architecture decisions
- Coordinate with Network Agent (1b) on HTTP client integration
- Coordinate with Storage Agent (1c) on OAuth token storage

---

### Phase 5: Role-Based Access Control (RBAC)

**Status**: ⏳ **PLANNED**  
**Priority**: MEDIUM  
**Estimated Time**: 2 weeks  
**Dependencies**: Phase 1 complete

**Goals**:
- Implement RBAC model (roles, permissions, resources)
- Add role assignment and management
- Implement permission checking middleware
- Support hierarchical roles and inheritance

**Tasks**:
- [ ] Design RBAC model (roles, permissions, resources, policies)
- [ ] Implement role management (create, update, delete roles)
- [ ] Implement permission management (assign permissions to roles)
- [ ] Implement resource access control
- [ ] Implement policy enforcement engine
- [ ] Add role hierarchy support (role inheritance)
- [ ] Integrate RBAC with JWT tokens (role claims)
- [ ] Add comprehensive RBAC tests
- [ ] Update documentation

**Coordination**:
- Coordinate with Core 1 Subcore on RBAC requirements
- Coordinate with Storage Agent (1c) on role/permission storage
- Coordinate with Network Agent (1b) on RBAC middleware

---

### Phase 6: Security Hardening

**Status**: ⏳ **PLANNED**  
**Priority**: HIGH  
**Estimated Time**: 1-2 weeks  
**Dependencies**: Phase 1 complete, Network Agent (1b) coordination

**Goals**:
- Implement CSRF protection
- Implement rate limiting for authentication endpoints
- Add security audit logging
- Enhance token security (secure storage, rotation)

**Tasks**:
- [ ] Implement CSRF token generation and validation
- [ ] Add CSRF protection to authentication endpoints
- [ ] Coordinate with Network Agent (1b) on rate limiting implementation
- [ ] Implement rate limiting for login, registration, OTP endpoints
- [ ] Add security audit logging (login attempts, token revocations, etc.)
- [ ] Implement secure token storage (coordinate with Storage Agent 1c)
- [ ] Add token rotation support
- [ ] Implement security headers (HSTS, CSP, etc.)
- [ ] Add comprehensive security tests
- [ ] Update documentation

**Coordination**:
- Coordinate with Network Agent (1b) on rate limiting and CSRF middleware
- Coordinate with Storage Agent (1c) on audit log storage
- Coordinate with Core 1 Subcore on security requirements

---

### Phase 7: Enhanced Test Coverage

**Status**: ⏳ **PLANNED**  
**Priority**: MEDIUM  
**Estimated Time**: Ongoing (parallel with other phases)  
**Dependencies**: All phases

**Goals**:
- Achieve >90% test coverage
- Add comprehensive edge case testing
- Add integration tests
- Add fuzz testing for security-critical paths

**Tasks**:
- [ ] Review current test coverage
- [ ] Add edge case tests (expired tokens, invalid formats, boundary conditions)
- [ ] Add integration tests (auth service + API server + middleware)
- [ ] Add fuzz tests for JWT parsing and validation
- [ ] Add fuzz tests for password hashing
- [ ] Add fuzz tests for OAuth flows
- [ ] Add performance tests
- [ ] Add security tests (timing attacks, injection attacks)
- [ ] Document test strategy

**Coordination**:
- Coordinate with Core 1 Subcore on test requirements
- Coordinate with Network Agent (1b) on integration test setup

---

## Architecture Decisions

### Password Hashing: Argon2

**Decision**: Implement Argon2 password hashing (pure Zig preferred)

**Rationale**:
- Argon2 is the winner of the Password Hashing Competition (PHC)
- More secure than SHA-256 with salt (resistant to GPU/ASIC attacks)
- Configurable memory/time costs provide future-proofing
- Pure Zig implementation maintains zero-dependency policy

**Alternatives Considered**:
- bcrypt: Well-tested but older, less flexible
- scrypt: Good but Argon2 is newer and more flexible
- Library: Would violate zero-dependency policy

**Status**: ⏳ Decision needed from Core 1 Subcore

---

### OAuth Integration: Authorization Code Flow

**Decision**: Implement OAuth 2.0 authorization code flow (PKCE recommended)

**Rationale**:
- Most secure OAuth flow (no token exposure in redirect)
- Standard flow supported by all major providers
- PKCE adds extra security for public clients

**Alternatives Considered**:
- Implicit flow: Less secure (token in redirect)
- Client credentials: Only for service-to-service

**Status**: ⏳ Decision needed from Core 1 Subcore

---

### RBAC Model: Hierarchical Roles

**Decision**: Implement hierarchical RBAC with role inheritance

**Rationale**:
- More flexible than flat RBAC
- Supports common patterns (admin > manager > user)
- Reduces permission management overhead

**Alternatives Considered**:
- Flat RBAC: Simpler but less flexible
- ABAC (Attribute-Based): More complex, may be overkill

**Status**: ⏳ Decision needed from Core 1 Subcore

---

## Coordination Model: L1/L2 Sub-Agent Pattern

**Parent Agent**: Grain Core 1 Subcore Agent (L1) coordinates overall Core system services architecture

**My Coordination**:
- Coordinate with Core 1 Subcore (L1) weekly/bi-weekly
- Coordinate minimally with Network Agent (1b) and Storage Agent (1c) as needed
- **DO NOT** coordinate directly with other full agents
- All external coordination goes through Core 1 Subcore

---

## Success Metrics

**Code Quality**:
- ✅ 100% Grain Style compliance (function length, line length, assertions)
- ✅ Zero compiler warnings
- ✅ Zero technical debt (no TODOs, FIXMEs)

**Test Coverage**:
- ✅ >90% test coverage
- ✅ All public APIs tested
- ✅ Edge cases tested
- ✅ Integration tests passing

**Security**:
- ✅ All security best practices implemented
- ✅ Security audit logging enabled
- ✅ Rate limiting active
- ✅ CSRF protection enabled

**Performance**:
- ✅ JWT validation < 1ms
- ✅ Password hashing < 100ms (Argon2)
- ✅ Token generation < 1ms

---

## Notes

- All code must target **RISC-V only** (no ARM64-specific code)
- All code must follow **Grain Style** strictly (non-negotiable)
- Zero technical debt policy — do it right the first time
- Coordinate through Core 1 Subcore for all external agent communication
- Update this document as plan evolves

---

**Date**: 2025-12-30-234200-pst  
**Agent**: Grain Auth Agent (1a)  
**Status**: ✅ INITIALIZED  
**Parent Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)

---
