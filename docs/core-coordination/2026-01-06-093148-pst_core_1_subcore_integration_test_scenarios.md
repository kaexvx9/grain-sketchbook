# Core 1 Subcore: Integration Test Scenarios

**Date**: 2026-01-06-093148-pst  
**Agent**: Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **DESIGN COMPLETE** — Comprehensive integration test scenarios for Core services

---

## Executive Summary

This document defines comprehensive integration test scenarios for Core 1 Subcore L2 sub-agents (1a Auth, 1b Network, 1c Storage, 1d Compositor, 1e Grainscript Shell). These scenarios cover cross-sub-agent integration, error handling, performance, and security validation.

**Purpose**: Provide detailed test scenarios for integration testing framework implementation.

---

## Test Scenario Categories

### Category 1: Auth ↔ Network Integration

#### Scenario 1.1: Authentication Middleware Flow

**Objective**: Verify authentication middleware correctly validates requests before network processing.

**Test Steps**:
1. Create authenticated request with valid JWT token
2. Pass request through Auth middleware
3. Verify middleware validates token
4. Forward validated request to Network handler
5. Verify network handler receives authenticated request
6. Verify response includes authentication context

**Expected Results**:
- ✅ Token validation succeeds
- ✅ Request forwarded to Network handler
- ✅ Authentication context preserved
- ✅ Response includes auth metadata

**Error Cases**:
- Invalid token → 401 Unauthorized
- Expired token → 401 Unauthorized
- Missing token → 401 Unauthorized
- Token validation failure → 401 Unauthorized

**Performance Requirements**:
- Token validation: < 10ms
- Middleware overhead: < 5ms
- Total request time: < 50ms (excluding network I/O)

---

#### Scenario 1.2: OAuth Flow Integration

**Objective**: Verify OAuth authentication flow through Auth and Network agents.

**Test Steps**:
1. Initiate OAuth flow via Network endpoint
2. Redirect to OAuth provider (Auth Agent)
3. Handle OAuth callback (Auth Agent)
4. Exchange code for token (Auth Agent)
5. Store token securely (Auth Agent → Storage Agent)
6. Return authenticated session (Network Agent)

**Expected Results**:
- ✅ OAuth flow completes successfully
- ✅ Token stored securely
- ✅ Session established
- ✅ User authenticated

**Error Cases**:
- OAuth provider error → 500 Internal Server Error
- Invalid OAuth code → 400 Bad Request
- Token exchange failure → 500 Internal Server Error
- Storage failure → 500 Internal Server Error

---

### Category 2: Network ↔ Storage Integration

#### Scenario 2.1: File Upload Flow

**Objective**: Verify file upload through Network to Storage.

**Test Steps**:
1. Receive file upload request (Network Agent)
2. Validate file size and type (Network Agent)
3. Stream file data to Storage Agent
4. Store file with metadata (Storage Agent)
5. Return file identifier (Network Agent)
6. Verify file stored correctly (Storage Agent)

**Expected Results**:
- ✅ File uploaded successfully
- ✅ File stored with correct metadata
- ✅ File identifier returned
- ✅ File retrievable by identifier

**Error Cases**:
- File too large → 413 Payload Too Large
- Invalid file type → 400 Bad Request
- Storage quota exceeded → 507 Insufficient Storage
- Storage write failure → 500 Internal Server Error

**Performance Requirements**:
- Small file (< 1MB): < 100ms
- Medium file (1-10MB): < 1s
- Large file (10-100MB): < 10s

---

#### Scenario 2.2: File Download Flow

**Objective**: Verify file download from Storage through Network.

**Test Steps**:
1. Receive file download request (Network Agent)
2. Validate file identifier (Network Agent)
3. Retrieve file metadata (Storage Agent)
4. Stream file data from Storage (Storage Agent)
5. Stream file data to client (Network Agent)
6. Verify file integrity (checksum validation)

**Expected Results**:
- ✅ File retrieved successfully
- ✅ File streamed correctly
- ✅ File integrity verified
- ✅ Download completes successfully

**Error Cases**:
- File not found → 404 Not Found
- File access denied → 403 Forbidden
- Storage read failure → 500 Internal Server Error
- Network stream failure → 500 Internal Server Error

**Performance Requirements**:
- Small file (< 1MB): < 50ms
- Medium file (1-10MB): < 500ms
- Large file (10-100MB): < 5s

---

### Category 3: Storage ↔ Auth Integration

#### Scenario 3.1: Secure Credential Storage

**Objective**: Verify credentials stored securely by Auth Agent using Storage Agent.

**Test Steps**:
1. Create user credentials (Auth Agent)
2. Encrypt credentials (Auth Agent)
3. Store encrypted credentials (Storage Agent)
4. Retrieve encrypted credentials (Storage Agent)
5. Decrypt credentials (Auth Agent)
6. Verify credential integrity

**Expected Results**:
- ✅ Credentials encrypted before storage
- ✅ Credentials stored securely
- ✅ Credentials retrieved correctly
- ✅ Credentials decrypted successfully
- ✅ Credential integrity verified

**Error Cases**:
- Encryption failure → 500 Internal Server Error
- Storage write failure → 500 Internal Server Error
- Storage read failure → 500 Internal Server Error
- Decryption failure → 500 Internal Server Error

**Security Requirements**:
- Credentials encrypted at rest
- Encryption key management secure
- No plaintext credentials in logs
- Credential access audited

---

#### Scenario 3.2: Credential Rotation

**Objective**: Verify credential rotation process through Auth and Storage.

**Test Steps**:
1. Retrieve existing credentials (Storage Agent)
2. Generate new credentials (Auth Agent)
3. Encrypt new credentials (Auth Agent)
4. Store new credentials atomically (Storage Agent)
5. Invalidate old credentials (Auth Agent)
6. Verify new credentials work (Auth Agent)

**Expected Results**:
- ✅ Old credentials retrieved
- ✅ New credentials generated
- ✅ New credentials stored atomically
- ✅ Old credentials invalidated
- ✅ New credentials functional

**Error Cases**:
- Atomic update failure → Rollback, 500 Internal Server Error
- Credential generation failure → 500 Internal Server Error
- Storage update failure → 500 Internal Server Error

---

### Category 4: Compositor ↔ Storage Integration

#### Scenario 4.1: Workspace State Persistence

**Objective**: Verify workspace state saved and restored through Compositor and Storage.

**Test Steps**:
1. Create workspace with windows (Compositor Agent)
2. Save workspace state (Compositor Agent)
3. Store workspace state (Storage Agent)
4. Restore workspace state (Storage Agent)
5. Recreate workspace from state (Compositor Agent)
6. Verify workspace matches original

**Expected Results**:
- ✅ Workspace state saved correctly
- ✅ Workspace state stored successfully
- ✅ Workspace state retrieved correctly
- ✅ Workspace recreated accurately
- ✅ All windows restored correctly

**Error Cases**:
- State serialization failure → 500 Internal Server Error
- Storage write failure → 500 Internal Server Error
- Storage read failure → 500 Internal Server Error
- State deserialization failure → 500 Internal Server Error

**Performance Requirements**:
- Small workspace (< 10 windows): < 50ms save, < 50ms restore
- Medium workspace (10-50 windows): < 200ms save, < 200ms restore
- Large workspace (50+ windows): < 1s save, < 1s restore

---

#### Scenario 4.2: Workspace State Versioning

**Objective**: Verify workspace state versioning and rollback.

**Test Steps**:
1. Save workspace state version 1 (Compositor → Storage)
2. Modify workspace (Compositor Agent)
3. Save workspace state version 2 (Compositor → Storage)
4. Request rollback to version 1 (Compositor Agent)
5. Retrieve version 1 state (Storage Agent)
6. Restore version 1 workspace (Compositor Agent)

**Expected Results**:
- ✅ Version 1 saved
- ✅ Version 2 saved
- ✅ Rollback requested successfully
- ✅ Version 1 retrieved
- ✅ Workspace restored to version 1

**Error Cases**:
- Version not found → 404 Not Found
- Version retrieval failure → 500 Internal Server Error
- Rollback failure → 500 Internal Server Error

---

### Category 5: Shell ↔ Core Services Integration

#### Scenario 5.1: Shell Command with Auth

**Objective**: Verify shell commands that require authentication.

**Test Steps**:
1. Execute authenticated shell command (Shell Agent)
2. Validate user session (Auth Agent)
3. Process command with auth context (Shell Agent)
4. Return authenticated result (Shell Agent)
5. Verify audit log entry (Auth Agent)

**Expected Results**:
- ✅ Command executed with auth context
- ✅ User session validated
- ✅ Result returned correctly
- ✅ Audit log entry created

**Error Cases**:
- Invalid session → 401 Unauthorized
- Session expired → 401 Unauthorized
- Permission denied → 403 Forbidden

---

#### Scenario 5.2: Shell Command with Network

**Objective**: Verify shell commands that use network services.

**Test Steps**:
1. Execute network shell command (Shell Agent)
2. Create network request (Network Agent)
3. Process network request (Network Agent)
4. Return network result (Network Agent)
5. Display result in shell (Shell Agent)

**Expected Results**:
- ✅ Network request created
- ✅ Network request processed
- ✅ Result returned correctly
- ✅ Result displayed in shell

**Error Cases**:
- Network connection failure → Network error message
- Network timeout → Timeout error message
- Network protocol error → Protocol error message

---

#### Scenario 5.3: Shell Command with Storage

**Objective**: Verify shell commands that use storage services.

**Test Steps**:
1. Execute storage shell command (Shell Agent)
2. Parse file path (Shell Agent)
3. Perform storage operation (Storage Agent)
4. Return storage result (Storage Agent)
5. Display result in shell (Shell Agent)

**Expected Results**:
- ✅ File path parsed correctly
- ✅ Storage operation performed
- ✅ Result returned correctly
- ✅ Result displayed in shell

**Error Cases**:
- File not found → File not found error
- Permission denied → Permission denied error
- Storage quota exceeded → Quota exceeded error

---

### Category 6: Error Propagation

#### Scenario 6.1: Cross-Agent Error Propagation

**Objective**: Verify errors propagate correctly across agent boundaries.

**Test Steps**:
1. Trigger error in Agent A
2. Propagate error to Agent B
3. Agent B handles error
4. Agent B propagates error to Agent C
5. Agent C returns error to client
6. Verify error context preserved

**Expected Results**:
- ✅ Error propagated correctly
- ✅ Error context preserved
- ✅ Error handled appropriately
- ✅ Error returned to client

**Error Types**:
- Validation errors
- Permission errors
- Resource errors
- System errors

---

#### Scenario 6.2: Error Recovery

**Objective**: Verify error recovery mechanisms across agents.

**Test Steps**:
1. Trigger transient error (Agent A)
2. Detect retryable error (Agent A)
3. Retry operation (Agent A → Agent B)
4. Operation succeeds on retry (Agent B)
5. Return success result (Agent A)
6. Verify error recovery logged

**Expected Results**:
- ✅ Transient error detected
- ✅ Retry attempted
- ✅ Operation succeeds on retry
- ✅ Success returned
- ✅ Recovery logged

**Retry Patterns**:
- Exponential backoff
- Circuit breaker
- Timeout handling

---

### Category 7: Performance Testing

#### Scenario 7.1: Concurrent Request Handling

**Objective**: Verify system handles concurrent requests correctly.

**Test Steps**:
1. Send 100 concurrent requests
2. Process requests through multiple agents
3. Verify all requests complete
4. Measure response times
5. Verify no resource leaks
6. Verify performance within limits

**Expected Results**:
- ✅ All requests complete
- ✅ Response times within limits
- ✅ No resource leaks
- ✅ System stable under load

**Performance Metrics**:
- Throughput: > 1000 requests/second
- Latency: p95 < 100ms
- Error rate: < 0.1%

---

#### Scenario 7.2: Resource Pool Management

**Objective**: Verify resource pools managed correctly across agents.

**Test Steps**:
1. Allocate resources from pool (Agent A)
2. Use resources (Agent A → Agent B)
3. Return resources to pool (Agent B)
4. Verify pool state correct
5. Stress test pool limits
6. Verify pool recovery

**Expected Results**:
- ✅ Resources allocated correctly
- ✅ Resources used correctly
- ✅ Resources returned correctly
- ✅ Pool state correct
- ✅ Pool handles limits correctly

**Resource Types**:
- Memory pools
- File handle pools
- Connection pools
- Buffer pools

---

### Category 8: Security Testing

#### Scenario 8.1: Authentication Bypass Prevention

**Objective**: Verify authentication cannot be bypassed.

**Test Steps**:
1. Attempt unauthenticated request
2. Verify authentication required
3. Attempt request with invalid token
4. Verify authentication fails
5. Attempt request with expired token
6. Verify authentication fails

**Expected Results**:
- ✅ Unauthenticated requests rejected
- ✅ Invalid tokens rejected
- ✅ Expired tokens rejected
- ✅ No authentication bypass possible

**Security Checks**:
- Token validation
- Session validation
- Permission checks
- Audit logging

---

#### Scenario 8.2: Data Encryption Validation

**Objective**: Verify sensitive data encrypted in transit and at rest.

**Test Steps**:
1. Send sensitive data (Agent A)
2. Verify data encrypted in transit (Network Agent)
3. Store sensitive data (Storage Agent)
4. Verify data encrypted at rest (Storage Agent)
5. Retrieve sensitive data (Storage Agent)
6. Verify data decrypted correctly (Agent A)

**Expected Results**:
- ✅ Data encrypted in transit
- ✅ Data encrypted at rest
- ✅ Data decrypted correctly
- ✅ No plaintext exposure

**Encryption Requirements**:
- TLS for transit
- AES-256 for at rest
- Key management secure
- No key exposure

---

## Test Implementation Guidelines

### Test Structure

**Test File Organization**:
```
tests/integration/core_1_subcore/
├── auth_network/
│   ├── authentication_middleware_test.zig
│   └── oauth_flow_test.zig
├── network_storage/
│   ├── file_upload_test.zig
│   └── file_download_test.zig
├── storage_auth/
│   ├── credential_storage_test.zig
│   └── credential_rotation_test.zig
├── compositor_storage/
│   ├── workspace_persistence_test.zig
│   └── workspace_versioning_test.zig
├── shell_services/
│   ├── shell_auth_test.zig
│   ├── shell_network_test.zig
│   └── shell_storage_test.zig
├── error_propagation/
│   ├── cross_agent_errors_test.zig
│   └── error_recovery_test.zig
├── performance/
│   ├── concurrent_requests_test.zig
│   └── resource_pools_test.zig
└── security/
    ├── auth_bypass_test.zig
    └── encryption_validation_test.zig
```

### Test Execution

**Test Runner Usage**:
```zig
test "authentication middleware flow" {
    const test_runner = try IntegrationTestRunner.init(allocator);
    defer test_runner.deinit();
    
    // Setup
    try test_runner.setup();
    defer test_runner.teardown();
    
    // Execute test steps
    try test_authentication_middleware_flow(test_runner);
    
    // Verify results
    try test_runner.verify_results();
}
```

### Test Data Management

**Test Fixtures**:
- Authentication tokens (valid, expired, invalid)
- File data (small, medium, large)
- Workspace states (simple, complex)
- Error scenarios (validation, permission, resource)

**Test Isolation**:
- Each test runs in isolated environment
- Test data cleaned up after each test
- No shared state between tests
- Parallel test execution safe

---

## Success Criteria

### Functional Requirements

- ✅ All integration scenarios pass
- ✅ Error cases handled correctly
- ✅ Performance requirements met
- ✅ Security requirements validated

### Quality Requirements

- ✅ Test coverage: > 90%
- ✅ Test execution time: < 5 minutes
- ✅ Test reliability: > 99%
- ✅ Test maintainability: Clear, documented

---

## Next Steps

### Immediate (This Week)

1. **Implement Test Scenarios**:
   - Start with Category 1 (Auth ↔ Network)
   - Implement basic test structure
   - Add test fixtures

2. **Test Framework Enhancement**:
   - Add test scenario support
   - Add performance measurement
   - Add security validation helpers

### Short-Term (Next 2 Weeks)

1. **Complete Test Implementation**:
   - Implement all 8 categories
   - Add error case tests
   - Add performance tests

2. **Test Execution**:
   - Run full test suite
   - Document test results
   - Fix any failures

### Medium-Term (Next Month)

1. **Continuous Integration**:
   - Integrate tests into CI/CD
   - Run tests on every commit
   - Report test results

2. **Test Maintenance**:
   - Update tests as APIs evolve
   - Add new test scenarios
   - Improve test coverage

---

**Date**: 2026-01-06-093148-pst  
**Agent**: Core 1 Subcore Agent (1st Agent, L1 Subcore Coordinator)  
**Status**: ✅ **DESIGN COMPLETE** — Integration test scenarios ready for implementation

