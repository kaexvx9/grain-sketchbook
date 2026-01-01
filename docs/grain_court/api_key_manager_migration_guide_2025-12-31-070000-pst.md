# ApiKeyManager Migration Guide

**Date**: 2025-12-31-070000-pst  
**Agent**: Grain Court Agent (11th Agent)  
**Status**: Migration Planning — Ready for Implementation (Pending Dependencies)  
**Related Documents**:
- Design Document: `docs/grain_court/api_key_manager_design_2025-12-30-110000-pst.md`
- Implementation Checklist: `docs/grain_court/api_key_manager_implementation_checklist_2025-12-31-070000-pst.md`

---

## Overview

This guide provides step-by-step instructions for migrating from plaintext API key storage to encrypted API key storage using the ApiKeyManager module. The migration addresses a critical security vulnerability where API keys are currently stored as plaintext in memory.

**Migration Goal**: Replace plaintext API key storage with encrypted storage via Grain Passwords and Silo Agent's PasswordStorage helper API.

**Security Issue**: API keys are currently stored as plaintext in `ProviderTrait.api_key: [256]u8` and passed as plaintext `[]const u8` to provider `init()` functions. This is a security vulnerability as keys are exposed in memory and could be exposed in core dumps.

---

## Pre-Migration Checklist

**Before Starting Migration**:
- [ ] Core Agent: Payment/Vault/Bank storage schema approved
- [ ] Silo Agent: PasswordStorage helper API implemented and tested
- [ ] Core Agent: Grain Passwords module implemented and tested
- [ ] ApiKeyManager module implemented and tested (Phase 1: Core Functionality)
- [ ] All ApiKeyManager tests passing
- [ ] Integration tests with mock dependencies passing
- [ ] Backup of current API keys (if any stored in configuration files)
- [ ] Migration plan reviewed and approved

---

## Migration Strategy

### Strategy: Phased Migration with Backward Compatibility

**Approach**: Implement ApiKeyManager with backward compatibility, allowing gradual migration from plaintext to encrypted storage. This minimizes risk and allows testing at each step.

**Phases**:
1. **Phase 1**: Implement ApiKeyManager (no migration yet)
2. **Phase 2**: Update ProviderPool to support both plaintext and ApiKeyManager
3. **Phase 3**: Migrate providers one-by-one (OpenAI → Anthropic → Mistral → Self-Hosted)
4. **Phase 4**: Remove plaintext support (cleanup)

---

## Step-by-Step Migration Process

### Step 1: Prepare Migration Environment

**Time Estimate**: 30 minutes

#### 1.1: Review Current API Key Storage Locations

**Action**: Identify all locations where API keys are currently stored or used.

**Locations to Check**:
- [ ] `src/grain_court/llm_provider.zig` — ProviderPool initialization
- [ ] `src/grain_court/provider_openai.zig` — OpenAI provider init()
- [ ] `src/grain_court/provider_anthropic.zig` — Anthropic provider init()
- [ ] `src/grain_court/provider_mistral.zig` — Mistral provider init()
- [ ] `src/grain_court/provider_self_hosted.zig` — Self-hosted provider init()
- [ ] Configuration files (if any) — Check for API keys in config files
- [ ] Environment variables (if any) — Check for API keys in environment variables

**Documentation**: Create a list of all locations where API keys are used.

#### 1.2: Create Migration Branch

**Action**: Create a git branch for migration work.

```bash
git checkout -b court-agent/api-key-manager-migration
```

#### 1.3: Set Up Test Environment

**Action**: Prepare test environment for migration testing.

- [ ] Create test API keys (use test keys, not production)
- [ ] Set up test database/storage (for PasswordStorage testing)
- [ ] Set up test Grain Passwords module (for encryption testing)
- [ ] Prepare test scenarios (store, retrieve, rotate, delete)

---

### Step 2: Implement ApiKeyManager Module

**Time Estimate**: 2-3 days (Phase 1: Core Functionality)

**Action**: Follow the implementation checklist to implement ApiKeyManager module.

**Checklist**: See `docs/grain_court/api_key_manager_implementation_checklist_2025-12-31-070000-pst.md`

**Key Tasks**:
- [ ] Implement data structures (ApiKeyIdentifier, ApiKeyMetadata, ApiKeyManager)
- [ ] Implement core functions (store_key, get_key, get_active_key)
- [ ] Implement key rotation functions (rotate_key, deactivate_key, delete_inactive_key)
- [ ] Implement helper functions (serialize_metadata, deserialize_metadata, extract_key_id, generate_rotation_key_id)
- [ ] Add comprehensive tests
- [ ] Verify Grain Style compliance

**Completion Criteria**:
- [ ] All functions implemented and tested
- [ ] All tests passing
- [ ] Integration tests with mock dependencies passing
- [ ] Grain Style compliance verified

---

### Step 3: Update ProviderPool with Backward Compatibility

**Time Estimate**: 2-3 hours

**Action**: Update ProviderPool to support both plaintext and ApiKeyManager (backward compatible).

#### 3.1: Update ProviderPool Struct

**File**: `src/grain_court/llm_provider.zig`

**Changes**:
```zig
pub const ProviderPool = struct {
    providers: [MAX_PROVIDERS]?*dyn ProviderTrait,
    provider_count: u32,
    key_manager: ?*ApiKeyManager, // NEW: Optional key manager
    environment: Environment, // NEW: Environment for key retrieval
    allocator: std.mem.Allocator,
    
    // Initialize ProviderPool with optional ApiKeyManager.
    pub fn init(
        alloc: std.mem.Allocator,
        key_mgr: ?*ApiKeyManager,
        env: Environment,
    ) ProviderPool {
        return ProviderPool{
            .providers = undefined,
            .provider_count = 0,
            .key_manager = key_mgr,
            .environment = env,
            .allocator = alloc,
        };
    }
    
    // Add OpenAI provider (backward compatible).
    pub fn add_openai_provider(
        self: *ProviderPool,
        api_key: ?[]const u8, // Optional (if key_manager provided)
    ) !void {
        const key = if (self.key_manager) |km| blk: {
            // Retrieve from key manager.
            break :blk try km.get_active_key(.openai, self.environment);
        } else if (api_key) |key| key else {
            return error.ApiKeyRequired;
        };
        defer if (self.key_manager != null) {
            self.allocator.free(key);
        };
        
        const provider = try provider_openai.init(key, self.allocator);
        // ... add to pool ...
    }
    
    // Similar updates for add_anthropic_provider, add_mistral_provider, add_self_hosted_provider
};
```

**Checklist**:
- [ ] Update ProviderPool struct (add key_manager, environment fields)
- [ ] Update init() function (accept optional ApiKeyManager)
- [ ] Update add_openai_provider() (use ApiKeyManager if available, fallback to api_key)
- [ ] Update add_anthropic_provider() (use ApiKeyManager if available, fallback to api_key)
- [ ] Update add_mistral_provider() (use ApiKeyManager if available, fallback to api_key)
- [ ] Update add_self_hosted_provider() (use ApiKeyManager if available, fallback to api_key)
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test ProviderPool with ApiKeyManager (should retrieve keys from manager)
- [ ] Test ProviderPool without ApiKeyManager (should use provided api_key) — **Backward Compatibility**
- [ ] Test ProviderPool with both ApiKeyManager and api_key (should prefer ApiKeyManager)

#### 3.2: Verify Backward Compatibility

**Action**: Ensure existing code continues to work without ApiKeyManager.

**Test Cases**:
- [ ] Test ProviderPool initialization without ApiKeyManager
- [ ] Test provider addition with plaintext api_key (should work as before)
- [ ] Test existing integration tests (should still pass)

**Completion Criteria**:
- [ ] All existing tests passing (backward compatibility verified)
- [ ] New tests passing (ApiKeyManager integration)
- [ ] No breaking changes to existing API

---

### Step 4: Migrate API Keys to Encrypted Storage

**Time Estimate**: 1-2 hours per provider (4-8 hours total)

**Action**: Migrate API keys from plaintext to encrypted storage, one provider at a time.

#### 4.1: Migrate OpenAI Provider Keys

**Steps**:
1. **Extract existing API keys** (if stored in configuration files or environment variables)
2. **Store keys in encrypted storage** using ApiKeyManager:
   ```zig
   // Example: Store OpenAI production key
   const identifier = ApiKeyIdentifier.init(.openai, .prod, "primary");
   const metadata = ApiKeyMetadata.init(true, "OpenAI production primary key", 90);
   try key_manager.store_key(&identifier, "sk-...", &metadata);
   ```
3. **Update ProviderPool initialization** to use ApiKeyManager:
   ```zig
   // Before (plaintext):
   var pool = ProviderPool.init(allocator);
   try pool.add_openai_provider("sk-...");
   
   // After (encrypted):
   var pool = ProviderPool.init(allocator, key_manager, .prod);
   try pool.add_openai_provider(null); // null = use key_manager
   ```
4. **Test OpenAI provider** (verify it still works)
5. **Verify encryption** (check that key is encrypted in storage)

**Checklist**:
- [ ] Extract OpenAI API keys (if stored externally)
- [ ] Store OpenAI keys in encrypted storage (dev, staging, prod environments)
- [ ] Update ProviderPool initialization to use ApiKeyManager for OpenAI
- [ ] Test OpenAI provider functionality
- [ ] Verify keys are encrypted in storage
- [ ] Remove plaintext keys from configuration files (if any)

**Test Cases**:
- [ ] Test OpenAI provider with encrypted keys (should work normally)
- [ ] Test OpenAI provider key retrieval (should decrypt correctly)
- [ ] Test OpenAI provider in all environments (dev, staging, prod)

#### 4.2: Migrate Anthropic Provider Keys

**Steps**: Same as Step 4.1, but for Anthropic provider.

**Checklist**:
- [ ] Extract Anthropic API keys (if stored externally)
- [ ] Store Anthropic keys in encrypted storage (dev, staging, prod environments)
- [ ] Update ProviderPool initialization to use ApiKeyManager for Anthropic
- [ ] Test Anthropic provider functionality
- [ ] Verify keys are encrypted in storage
- [ ] Remove plaintext keys from configuration files (if any)

#### 4.3: Migrate Mistral Provider Keys

**Steps**: Same as Step 4.1, but for Mistral provider.

**Checklist**:
- [ ] Extract Mistral API keys (if stored externally)
- [ ] Store Mistral keys in encrypted storage (dev, staging, prod environments)
- [ ] Update ProviderPool initialization to use ApiKeyManager for Mistral
- [ ] Test Mistral provider functionality
- [ ] Verify keys are encrypted in storage
- [ ] Remove plaintext keys from configuration files (if any)

#### 4.4: Migrate Self-Hosted Provider Keys

**Steps**: Same as Step 4.1, but for Self-Hosted provider.

**Checklist**:
- [ ] Extract Self-Hosted API keys (if stored externally)
- [ ] Store Self-Hosted keys in encrypted storage (dev, staging, prod environments)
- [ ] Update ProviderPool initialization to use ApiKeyManager for Self-Hosted
- [ ] Test Self-Hosted provider functionality
- [ ] Verify keys are encrypted in storage
- [ ] Remove plaintext keys from configuration files (if any)

---

### Step 5: Remove Plaintext Support (Cleanup)

**Time Estimate**: 2-3 hours

**Action**: Remove plaintext API key support after all providers are migrated.

#### 5.1: Update Provider init() Functions

**Action**: Update provider init() functions to require ApiKeyManager (remove plaintext api_key parameter).

**File**: `src/grain_court/provider_openai.zig`

**Changes**:
```zig
// Before (backward compatible):
pub fn init(
    api_key: []const u8, // Plaintext key
    allocator: std.mem.Allocator,
) !OpenAIProvider { ... }

// After (encrypted only):
pub fn init(
    key_manager: *ApiKeyManager,
    environment: Environment,
    allocator: std.mem.Allocator,
) !OpenAIProvider {
    const api_key = try key_manager.get_active_key(.openai, environment);
    defer allocator.free(api_key);
    // ... rest of implementation ...
}
```

**Checklist**:
- [ ] Update provider_openai.init() (require ApiKeyManager)
- [ ] Update provider_anthropic.init() (require ApiKeyManager)
- [ ] Update provider_mistral.init() (require ApiKeyManager)
- [ ] Update provider_self_hosted.init() (require ApiKeyManager)
- [ ] Update ProviderPool.add_*_provider() functions (remove api_key parameter)
- [ ] Add comprehensive tests

#### 5.2: Remove Plaintext API Key Fields

**Action**: Remove plaintext API key storage from ProviderTrait (if no longer needed).

**File**: `src/grain_court/llm_provider.zig`

**Changes**:
```zig
// Before:
pub const ProviderTrait = struct {
    api_key: [256]u8, // Plaintext key storage (SECURITY VULNERABILITY)
    // ... other fields ...
};

// After:
pub const ProviderTrait = struct {
    // api_key field removed (keys retrieved via ApiKeyManager when needed)
    // ... other fields ...
};
```

**Note**: This change may require updating provider implementations to retrieve keys on-demand rather than storing them.

**Checklist**:
- [ ] Review ProviderTrait usage (verify api_key field can be removed)
- [ ] Update provider implementations (retrieve keys on-demand if needed)
- [ ] Remove api_key field from ProviderTrait
- [ ] Update all provider structs (remove api_key field)
- [ ] Add comprehensive tests

#### 5.3: Update Documentation

**Action**: Update documentation to reflect encrypted storage.

**Checklist**:
- [ ] Update API documentation (remove plaintext api_key parameters)
- [ ] Update integration guides (show ApiKeyManager usage)
- [ ] Update README files (document encrypted storage)
- [ ] Update migration guide (mark migration complete)

---

### Step 6: Testing & Validation

**Time Estimate**: 4-6 hours

**Action**: Comprehensive testing of migrated system.

#### 6.1: Unit Tests

**Checklist**:
- [ ] Run all ApiKeyManager unit tests (should pass)
- [ ] Run all ProviderPool tests (should pass)
- [ ] Run all provider tests (should pass)
- [ ] Run all integration tests (should pass)

#### 6.2: Integration Tests

**Checklist**:
- [ ] Test ProviderPool with ApiKeyManager (all providers)
- [ ] Test key storage and retrieval (all providers, all environments)
- [ ] Test key rotation (all providers)
- [ ] Test environment separation (dev, staging, prod)
- [ ] Test access control (if Security Manager integrated)
- [ ] Test audit logging (if Security Manager integrated)

#### 6.3: Security Validation

**Checklist**:
- [ ] Verify keys are encrypted in storage (check database/storage)
- [ ] Verify keys are never stored in plaintext (grep codebase for plaintext patterns)
- [ ] Verify keys are decrypted only when needed (check decryption timing)
- [ ] Verify access control enforcement (if Security Manager integrated)
- [ ] Verify audit logging (if Security Manager integrated)

#### 6.4: Performance Testing

**Checklist**:
- [ ] Test key retrieval performance (should be acceptable)
- [ ] Test provider initialization performance (should be acceptable)
- [ ] Test key rotation performance (should be acceptable)

---

### Step 7: Deployment & Rollback Plan

**Time Estimate**: 1-2 hours

**Action**: Prepare deployment and rollback plan.

#### 7.1: Deployment Plan

**Steps**:
1. **Deploy ApiKeyManager module** (new code, no breaking changes yet)
2. **Deploy updated ProviderPool** (backward compatible, supports both plaintext and encrypted)
3. **Migrate API keys** (store in encrypted storage)
4. **Update ProviderPool usage** (use ApiKeyManager)
5. **Remove plaintext support** (cleanup)

**Checklist**:
- [ ] Deployment plan documented
- [ ] Deployment steps tested in staging environment
- [ ] Deployment checklist created
- [ ] Deployment timeline estimated

#### 7.2: Rollback Plan

**Steps** (if migration fails):
1. **Revert ProviderPool changes** (restore plaintext support)
2. **Revert provider init() changes** (restore plaintext api_key parameter)
3. **Restore plaintext API keys** (from backup or configuration files)
4. **Verify system functionality** (should work as before migration)

**Checklist**:
- [ ] Rollback plan documented
- [ ] Rollback steps tested
- [ ] Backup of plaintext keys created (if needed)
- [ ] Rollback checklist created

---

## Migration Timeline

**Estimated Total Time**: 6-10 days

**Breakdown**:
- Step 1: Prepare Migration Environment — 30 minutes
- Step 2: Implement ApiKeyManager Module — 2-3 days
- Step 3: Update ProviderPool with Backward Compatibility — 2-3 hours
- Step 4: Migrate API Keys to Encrypted Storage — 4-8 hours (1-2 hours per provider)
- Step 5: Remove Plaintext Support (Cleanup) — 2-3 hours
- Step 6: Testing & Validation — 4-6 hours
- Step 7: Deployment & Rollback Plan — 1-2 hours

---

## Risk Mitigation

### Risks & Mitigations

**Risk 1: Breaking Changes During Migration**
- **Mitigation**: Implement backward compatibility (support both plaintext and encrypted)
- **Mitigation**: Migrate providers one-by-one (minimize impact)
- **Mitigation**: Comprehensive testing at each step

**Risk 2: Key Loss During Migration**
- **Mitigation**: Backup all API keys before migration
- **Mitigation**: Test migration in staging environment first
- **Mitigation**: Rollback plan prepared

**Risk 3: Performance Degradation**
- **Mitigation**: Performance testing during migration
- **Mitigation**: Key caching (if needed)
- **Mitigation**: Optimize key retrieval (minimize decryption overhead)

**Risk 4: Security Issues**
- **Mitigation**: Security validation at each step
- **Mitigation**: Verify encryption in storage
- **Mitigation**: Verify access control enforcement

---

## Success Criteria

**Migration is complete when**:
- [ ] All API keys stored in encrypted storage
- [ ] All providers use ApiKeyManager for key retrieval
- [ ] Plaintext API key support removed
- [ ] All tests passing
- [ ] Security validation passed
- [ ] Performance acceptable
- [ ] Documentation updated
- [ ] No breaking changes (or breaking changes documented and communicated)

---

## Post-Migration Tasks

**After Migration**:
- [ ] Monitor system for issues (first week after migration)
- [ ] Review access logs (verify proper access control)
- [ ] Review audit logs (verify proper audit logging)
- [ ] Performance monitoring (verify acceptable performance)
- [ ] Update team documentation (communicate changes)
- [ ] Clean up migration branch (merge to main)

---

**Date**: 2025-12-31-070000-pst  
**Agent**: Grain Court Agent (11th Agent)  
**Status**: Migration Guide Complete — Ready for Implementation (Pending Dependencies)

This migration guide provides step-by-step instructions for migrating from plaintext to encrypted API key storage. The migration should be performed carefully with comprehensive testing at each step to ensure security and reliability.
