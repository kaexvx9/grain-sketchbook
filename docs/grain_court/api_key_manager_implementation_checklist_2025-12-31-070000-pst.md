# ApiKeyManager Implementation Checklist

**Date**: 2025-12-31-070000-pst  
**Agent**: Grain Court Agent (11th Agent)  
**Status**: Preparation Phase — Ready for Implementation (Pending Dependencies)  
**Design Document**: `docs/grain_court/api_key_manager_design_2025-12-30-110000-pst.md`

---

## Overview

This checklist breaks down the ApiKeyManager module implementation into daily tasks. Implementation can begin immediately once dependencies are available (Core Agent storage schema approval, Silo Agent PasswordStorage API, Core Agent Grain Passwords module).

**Estimated Timeline**: 2-3 days (Phase 1: Core Functionality) + 1-2 days (Phase 2: Advanced Features) = 4-5 days total

**Dependencies**:
- ⏳ Core Agent: Payment/Vault/Bank storage schema approval (IMMEDIATE, HIGH priority, 4-7 hours)
- ⏳ Silo Agent: PasswordStorage helper API design (~1 day after Core Agent approval)
- ⏳ Core Agent: Grain Passwords module implementation (2-3 days)

---

## Phase 1: Core Functionality (2-3 days)

### Day 1: Module Structure & Data Structures

**Estimated Time**: 4-6 hours

#### Task 1.1: Create Module File Structure
- [ ] Create `src/grain_court/api_key_manager.zig`
- [ ] Add module documentation header (purpose, architecture, Grain Style compliance)
- [ ] Add imports: `std`, `grain_core` (for PasswordStorage, Security Manager)
- [ ] Add error types: `ApiKeyManagerError` enum
- [ ] Add bounded constants: `MAX_KEYS_PER_PROVIDER`, `MAX_KEY_LENGTH`, `DEFAULT_ROTATION_PERIOD_DAYS`

**Grain Style Requirements**:
- [ ] Verify `grain_case` function names
- [ ] Verify explicit `u32`/`u64` types (no `usize`/`isize`)
- [ ] Verify bounded allocations (`MAX_` constants)
- [ ] Verify max 100 characters per line (`grainwrap-100`)
- [ ] Verify max 70 lines per function (`grain validate-70`)

#### Task 1.2: Implement ApiKeyIdentifier Struct
- [ ] Define `ApiKeyIdentifier` struct with fields:
  - `provider_type: ProviderType`
  - `environment: Environment`
  - `key_id: [64]u8`
  - `key_id_len: u32`
- [ ] Implement `init()` function (with assertions)
- [ ] Implement `to_storage_key()` function (with allocator)
- [ ] Add minimum 2 assertions per function
- [ ] Add comprehensive tests in `tests/151_grain_court_api_key_manager_test.zig`

**Test Cases**:
- [ ] Test `init()` with valid inputs
- [ ] Test `init()` with invalid inputs (empty key_id, too long)
- [ ] Test `to_storage_key()` with all provider types
- [ ] Test `to_storage_key()` with all environments
- [ ] Test `to_storage_key()` output format correctness

#### Task 1.3: Implement ProviderType and Environment Enums
- [ ] Define `ProviderType` enum (openai, anthropic, mistral, self_hosted)
- [ ] Define `Environment` enum (dev, staging, prod)
- [ ] Add string conversion helpers (`provider_to_string()`, `environment_to_string()`)
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test enum values correctness
- [ ] Test string conversion for all enum values
- [ ] Test enum parsing (if needed)

#### Task 1.4: Implement ApiKeyMetadata Struct
- [ ] Define `ApiKeyMetadata` struct with fields:
  - `is_active: bool`
  - `created_at: u64`
  - `updated_at: u64`
  - `last_used_at: ?u64`
  - `rotation_period_days: u32`
  - `description: [128]u8`
  - `description_len: u32`
- [ ] Implement `init()` function (with assertions)
- [ ] Implement `mark_used()` function
- [ ] Implement `should_rotate()` function
- [ ] Add minimum 2 assertions per function
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test `init()` with valid inputs
- [ ] Test `init()` with invalid inputs (empty description, zero rotation period)
- [ ] Test `mark_used()` updates timestamps
- [ ] Test `should_rotate()` with various ages
- [ ] Test `should_rotate()` with inactive keys (should return false)

#### Task 1.5: Code Review & Grain Style Verification
- [ ] Run `grainwrap-100` to verify line length compliance
- [ ] Run `grain validate-70` to verify function length compliance
- [ ] Verify all compiler warnings enabled and resolved
- [ ] Verify explicit `u32`/`u64` types (no `usize`/`isize`)
- [ ] Verify minimum 2 assertions per function
- [ ] Verify bounded allocations

**Completion Criteria**: All data structures implemented, tested, and Grain Style compliant.

---

### Day 2: Core Storage & Retrieval Functions

**Estimated Time**: 6-8 hours

#### Task 2.1: Implement ApiKeyManager Struct
- [ ] Define `ApiKeyManager` struct with fields:
  - `password_storage: *PasswordStorage`
  - `password_module: *grain_passwords.PasswordModule`
  - `security_manager: ?*security_manager.SecurityManager`
  - `allocator: std.mem.Allocator`
- [ ] Implement `init()` function
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test `init()` with valid inputs
- [ ] Test `init()` with null pointers (should assert)

#### Task 2.2: Implement store_key() Function
- [ ] Implement `store_key()` function:
  - Validate inputs (api_key length, identifier validity)
  - Check access control (if Security Manager available)
  - Encrypt API key via Grain Passwords module
  - Convert identifier to storage key
  - Serialize metadata to JSON
  - Store via PasswordStorage helper
  - Audit log (if Security Manager available)
- [ ] Add error handling (OutOfMemory, AccessDenied, etc.)
- [ ] Add minimum 2 assertions
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test `store_key()` with valid inputs
- [ ] Test `store_key()` with invalid inputs (empty key, too long key)
- [ ] Test `store_key()` with access control (should check permissions)
- [ ] Test `store_key()` encryption (verify key is encrypted)
- [ ] Test `store_key()` storage key format correctness

#### Task 2.3: Implement get_key() Function
- [ ] Implement `get_key()` function:
  - Validate inputs (identifier validity)
  - Check access control (if Security Manager available)
  - Convert identifier to storage key
  - Retrieve from PasswordStorage helper
  - Deserialize metadata
  - Check active status (if active_only is true)
  - Decrypt API key via Grain Passwords module
  - Update last_used_at (if metadata available)
  - Audit log (if Security Manager available)
- [ ] Add error handling (KeyNotFound, KeyInactive, etc.)
- [ ] Add minimum 2 assertions
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test `get_key()` with valid inputs (active key)
- [ ] Test `get_key()` with invalid inputs (non-existent key)
- [ ] Test `get_key()` with active_only=true (inactive key should fail)
- [ ] Test `get_key()` with active_only=false (inactive key should succeed)
- [ ] Test `get_key()` decryption (verify key is decrypted correctly)
- [ ] Test `get_key()` access control (should check permissions)

#### Task 2.4: Implement Helper Functions (serialize_metadata, deserialize_metadata)
- [ ] Implement `serialize_metadata()` function (JSON serialization)
- [ ] Implement `deserialize_metadata()` function (JSON deserialization)
- [ ] Use JSON library (or implement simple JSON serialization)
- [ ] Add error handling
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test `serialize_metadata()` with valid metadata
- [ ] Test `deserialize_metadata()` with valid JSON
- [ ] Test `deserialize_metadata()` with invalid JSON (should return error)
- [ ] Test round-trip serialization/deserialization

#### Task 2.5: Code Review & Integration Testing
- [ ] Test integration with mock PasswordStorage (if available)
- [ ] Test integration with mock Grain Passwords module (if available)
- [ ] Run all tests (should pass)
- [ ] Verify Grain Style compliance
- [ ] Verify error handling correctness

**Completion Criteria**: Core storage and retrieval functions implemented, tested, and integrated.

---

### Day 3: Key Rotation & Environment Separation

**Estimated Time**: 6-8 hours

#### Task 3.1: Implement get_active_key() Function
- [ ] Implement `get_active_key()` function:
  - List all keys for provider/environment
  - Filter by active status
  - Return first active key
  - Add error handling (NoActiveKey)
- [ ] Add minimum 2 assertions
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test `get_active_key()` with active key available
- [ ] Test `get_active_key()` with no active key (should return NoActiveKey)
- [ ] Test `get_active_key()` with multiple active keys (should return first)

#### Task 3.2: Implement list_keys() Function
- [ ] Implement `list_keys()` function:
  - Build pattern for provider/environment
  - List secrets matching pattern via PasswordStorage
  - Extract key_id from storage keys
  - Filter by active status (if active_only is true)
  - Return list of key_ids
- [ ] Implement `extract_key_id()` helper function
- [ ] Add error handling
- [ ] Add minimum 2 assertions
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test `list_keys()` with multiple keys (all active)
- [ ] Test `list_keys()` with active_only=true (should filter inactive)
- [ ] Test `list_keys()` with active_only=false (should return all)
- [ ] Test `extract_key_id()` with valid storage key format
- [ ] Test `extract_key_id()` with invalid format (should return error)

#### Task 3.3: Implement rotate_key() Function
- [ ] Implement `rotate_key()` function:
  - Validate inputs
  - Check access control
  - Mark old key as inactive (via deactivate_key)
  - Generate new key_id (via generate_rotation_key_id)
  - Store new key as active
  - Audit log
- [ ] Implement `generate_rotation_key_id()` helper function
- [ ] Add error handling
- [ ] Add minimum 2 assertions
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test `rotate_key()` with valid inputs
- [ ] Test `rotate_key()` marks old key as inactive
- [ ] Test `rotate_key()` stores new key as active
- [ ] Test `generate_rotation_key_id()` with "primary" (should return "secondary")
- [ ] Test `generate_rotation_key_id()` with "secondary" (should return "tertiary")
- [ ] Test `generate_rotation_key_id()` with other key_id (should append timestamp)

#### Task 3.4: Implement deactivate_key() Function
- [ ] Implement `deactivate_key()` function:
  - Get current metadata
  - Update metadata (mark as inactive, update timestamp)
  - Update in storage
  - Audit log
- [ ] Implement `get_metadata()` helper function
- [ ] Add error handling
- [ ] Add minimum 2 assertions
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test `deactivate_key()` with active key (should mark as inactive)
- [ ] Test `deactivate_key()` with inactive key (should update timestamp)
- [ ] Test `deactivate_key()` with non-existent key (should return KeyNotFound)
- [ ] Test `get_metadata()` with valid identifier
- [ ] Test `get_metadata()` with invalid identifier

#### Task 3.5: Implement delete_inactive_key() Function
- [ ] Implement `delete_inactive_key()` function:
  - Validate inputs
  - Check access control
  - Get metadata to verify inactive
  - Delete from storage
  - Audit log
- [ ] Add error handling (KeyStillActive)
- [ ] Add minimum 2 assertions
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test `delete_inactive_key()` with inactive key (should delete)
- [ ] Test `delete_inactive_key()` with active key (should return KeyStillActive)
- [ ] Test `delete_inactive_key()` with non-existent key (should return KeyNotFound)

#### Task 3.6: Code Review & Integration Testing
- [ ] Test key rotation flow (store → rotate → deactivate → delete)
- [ ] Test environment separation (dev, staging, prod)
- [ ] Run all tests (should pass)
- [ ] Verify Grain Style compliance
- [ ] Verify error handling correctness

**Completion Criteria**: Key rotation and environment separation functions implemented, tested, and integrated.

---

## Phase 2: Advanced Features (1-2 days)

### Day 4: Access Control & Audit Logging

**Estimated Time**: 4-6 hours

#### Task 4.1: Integrate Security Manager for Access Control
- [ ] Add Security Manager integration to `store_key()`
- [ ] Add Security Manager integration to `get_key()`
- [ ] Add Security Manager integration to `rotate_key()`
- [ ] Add Security Manager integration to `delete_inactive_key()`
- [ ] Define required permissions:
  - `api_key:store`
  - `api_key:get`
  - `api_key:rotate`
  - `api_key:delete`
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test access control enforcement (should check permissions)
- [ ] Test access denied scenarios (should return AccessDenied)
- [ ] Test access allowed scenarios (should succeed)

#### Task 4.2: Implement Audit Logging
- [ ] Add audit logging to `store_key()`
- [ ] Add audit logging to `get_key()`
- [ ] Add audit logging to `rotate_key()`
- [ ] Add audit logging to `delete_inactive_key()`
- [ ] Log actions: "store", "get", "rotate", "delete"
- [ ] Log user_id, timestamp, result (success/failure)
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test audit logging for successful operations
- [ ] Test audit logging for failed operations
- [ ] Test audit log format correctness

#### Task 4.3: Code Review & Testing
- [ ] Test access control integration
- [ ] Test audit logging integration
- [ ] Run all tests (should pass)
- [ ] Verify Grain Style compliance

**Completion Criteria**: Access control and audit logging implemented and tested.

---

### Day 5: ProviderPool Integration & Migration

**Estimated Time**: 6-8 hours

#### Task 5.1: Update ProviderPool to Use ApiKeyManager
- [ ] Add `key_manager: ?*ApiKeyManager` field to ProviderPool
- [ ] Add `environment: Environment` field to ProviderPool
- [ ] Update `add_openai_provider()` to use ApiKeyManager (if available)
- [ ] Update `add_anthropic_provider()` to use ApiKeyManager (if available)
- [ ] Update `add_mistral_provider()` to use ApiKeyManager (if available)
- [ ] Update `add_self_hosted_provider()` to use ApiKeyManager (if available)
- [ ] Maintain backward compatibility (optional api_key parameter)
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test ProviderPool with ApiKeyManager (should retrieve keys from manager)
- [ ] Test ProviderPool without ApiKeyManager (should use provided api_key)
- [ ] Test ProviderPool with both ApiKeyManager and api_key (should prefer ApiKeyManager)

#### Task 5.2: Update Provider init() Functions
- [ ] Update `provider_openai.init()` to accept ApiKeyManager (optional)
- [ ] Update `provider_anthropic.init()` to accept ApiKeyManager (optional)
- [ ] Update `provider_mistral.init()` to accept ApiKeyManager (optional)
- [ ] Update `provider_self_hosted.init()` to accept ApiKeyManager (optional)
- [ ] Maintain backward compatibility (optional api_key parameter)
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test provider initialization with ApiKeyManager
- [ ] Test provider initialization without ApiKeyManager (backward compatibility)
- [ ] Test provider initialization with both (should prefer ApiKeyManager)

#### Task 5.3: Create Migration Script (if needed)
- [ ] Review existing API key storage locations
- [ ] Create migration script to extract existing keys (if any)
- [ ] Create migration script to store keys in encrypted storage
- [ ] Add migration validation checks
- [ ] Add comprehensive tests

**Test Cases**:
- [ ] Test migration script with valid keys
- [ ] Test migration script with invalid keys (should handle errors)
- [ ] Test migration script validation checks

#### Task 5.4: Integration Testing & Documentation
- [ ] Test end-to-end flow (store → get → use in ProviderPool)
- [ ] Test key rotation flow (rotate → update ProviderPool)
- [ ] Test environment separation (dev, staging, prod)
- [ ] Update API documentation
- [ ] Create migration guide document
- [ ] Run all tests (should pass)
- [ ] Verify Grain Style compliance

**Completion Criteria**: ProviderPool integration complete, migration ready, documentation updated.

---

## Testing Strategy

### Unit Tests

**Test File**: `tests/151_grain_court_api_key_manager_test.zig`

**Test Coverage**:
- [ ] ApiKeyIdentifier tests (init, to_storage_key)
- [ ] ApiKeyMetadata tests (init, mark_used, should_rotate)
- [ ] ApiKeyManager.store_key() tests
- [ ] ApiKeyManager.get_key() tests
- [ ] ApiKeyManager.get_active_key() tests
- [ ] ApiKeyManager.list_keys() tests
- [ ] ApiKeyManager.rotate_key() tests
- [ ] ApiKeyManager.deactivate_key() tests
- [ ] ApiKeyManager.delete_inactive_key() tests
- [ ] Helper function tests (serialize_metadata, deserialize_metadata, extract_key_id, generate_rotation_key_id)

### Integration Tests

**Test Coverage**:
- [ ] Integration with PasswordStorage helper (mock)
- [ ] Integration with Grain Passwords module (mock)
- [ ] Integration with Security Manager (mock)
- [ ] Integration with ProviderPool
- [ ] End-to-end key storage and retrieval
- [ ] End-to-end key rotation flow

### Security Tests

**Test Coverage**:
- [ ] Keys never stored in plaintext (verify encryption)
- [ ] Keys decrypted only when needed (verify decryption timing)
- [ ] Access control enforcement (verify permissions checked)
- [ ] Audit logging verification (verify logs created)

---

## Grain Style Compliance Checklist

For each function:
- [ ] Function name uses `grain_case`
- [ ] Explicit `u32`/`u64` types (no `usize`/`isize`)
- [ ] Bounded allocations (use `MAX_` constants)
- [ ] Minimum 2 assertions per function
- [ ] Max 70 lines per function (`grain validate-70`)
- [ ] Max 100 characters per line (`grainwrap-100`)
- [ ] No recursion (use iteration)
- [ ] All compiler warnings enabled and resolved

---

## Dependencies Checklist

**Before Starting Implementation**:
- [ ] Core Agent: Payment/Vault/Bank storage schema approved
- [ ] Silo Agent: PasswordStorage helper API designed and documented
- [ ] Core Agent: Grain Passwords module implemented
- [ ] Security Manager integration available (if needed)

**During Implementation**:
- [ ] JSON serialization library available (or implement simple JSON)
- [ ] Time utilities available (for timestamps)
- [ ] Pattern matching utilities available (for key listing)

---

## Progress Tracking

**Phase 1: Core Functionality (2-3 days)**
- Day 1: [ ] Module Structure & Data Structures (Task 1.1-1.5)
- Day 2: [ ] Core Storage & Retrieval Functions (Task 2.1-2.5)
- Day 3: [ ] Key Rotation & Environment Separation (Task 3.1-3.6)

**Phase 2: Advanced Features (1-2 days)**
- Day 4: [ ] Access Control & Audit Logging (Task 4.1-4.3)
- Day 5: [ ] ProviderPool Integration & Migration (Task 5.1-5.4)

**Completion Criteria**:
- [ ] All functions implemented and tested
- [ ] All tests passing
- [ ] Grain Style compliance verified
- [ ] Integration with ProviderPool complete
- [ ] Documentation updated
- [ ] Migration guide created

---

**Date**: 2025-12-31-070000-pst  
**Agent**: Grain Court Agent (11th Agent)  
**Status**: Implementation Checklist Complete — Ready for Implementation (Pending Dependencies)

This checklist provides a detailed breakdown of ApiKeyManager module implementation tasks. Implementation can begin immediately once Core Agent approves storage schema, Silo Agent provides PasswordStorage API, and Core Agent implements Grain Passwords module.
