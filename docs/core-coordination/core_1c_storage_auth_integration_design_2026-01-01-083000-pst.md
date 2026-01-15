# Storage Agent (1c) ↔ Auth Agent (1a) Integration Design

**Date**: 2026-01-01-083000-pst  
**From**: Grain Storage Agent (1c)  
**To**: Grain Auth Agent (1a), Grain Core 1 Subcore Agent (L1 Subcore)  
**Purpose**: Design secure credential storage integration and user/group context API

---

## Executive Summary

**Status**: ⏳ **DESIGN PHASE - READY FOR COORDINATION**

The Storage Agent (1c) proposes integration design for secure credential storage with Auth Agent (1a). This document outlines the API contract, integration architecture, and implementation plan.

---

## Integration Objectives

### 1. Secure Credential Storage

**Objective**: Store user credentials securely using Storage Agent encryption at rest

**Requirements**:
- Encrypt credentials using Storage Agent's `encryption_at_rest` module
- Store credentials with proper access control
- Enable Auth Agent to retrieve credentials securely
- Support credential rotation and key management

### 2. User/Group Context API

**Objective**: Extract user_id and group_id from authentication tokens for Storage Agent file operations

**Requirements**:
- Network Agent extracts user_id/group_id from JWT tokens
- Pass real user_id/group_id to Storage Agent APIs
- Enable proper access control and audit logging
- Support file permissions based on user/group

### 3. Key Management Integration

**Objective**: Integrate Storage Agent encryption keys with Auth Agent key management

**Requirements**:
- Auth Agent manages encryption keys
- Storage Agent requests keys from Auth Agent
- Support key rotation
- Secure key storage

---

## API Design

### 1. User/Group Context Extraction

**Current State**: Network Agent uses default `user_id: 1` and `group_id: 1`

**Proposed API** (Auth Agent provides):

```zig
// Extract user_id and group_id from JWT token
pub fn extract_user_context(
    auth_service: *AuthService,
    token: []const u8,
    current_time: u64,
    user_id_out: *u32,
    group_id_out: *u32,
) bool {
    // Validate token
    // Extract user_id from JWT claims
    // Look up group_id from user_id
    // Return user_id and group_id
}
```

**Usage in Network Agent**:
```zig
// In file_transfer_handlers.zig
const auth_header = request.get_header("Authorization");
if (auth_header) |token| {
    var user_id: u32 = 0;
    var group_id: u32 = 0;
    if (auth_service.extract_user_context(token, current_time, &user_id, &group_id)) {
        // Use real user_id and group_id
    } else {
        // Use default or return 401 Unauthorized
    }
}
```

### 2. Secure Credential Storage API

**Storage Agent provides**:

```zig
// Store encrypted credential
pub fn store_credential(
    storage_manager: *IntegratedFileStorageManager,
    credential_path: []const u8,
    credential_data: []const u8,
    user_id: u32,
    group_id: u32,
    current_time: u64,
) bool {
    // Encrypt credential using encryption_at_rest
    // Store with proper permissions
    // Log audit event
}
```

**Auth Agent usage**:
```zig
// Store user password hash
const credential_path = "/secure/credentials/user/{user_id}/password_hash";
storage_manager.store_credential(
    credential_path,
    password_hash,
    user_id,
    group_id,
    current_time,
);
```

### 3. Key Management API

**Auth Agent provides**:

```zig
// Get encryption key for Storage Agent
pub fn get_encryption_key(
    auth_service: *AuthService,
    key_id: []const u8,
    key_out: []u8,
) bool {
    // Retrieve key from secure storage
    // Return key for Storage Agent use
}
```

**Storage Agent usage**:
```zig
// Request encryption key from Auth Agent
var key: [32]u8 = undefined;
if (auth_service.get_encryption_key("storage_default", &key)) {
    // Use key for encryption
}
```

---

## Integration Architecture

### Flow 1: File Upload with Authentication

1. **Network Agent** receives file upload with `Authorization` header
2. **Network Agent** calls **Auth Agent** to extract user_id/group_id from token
3. **Network Agent** calls **Storage Agent** with real user_id/group_id
4. **Storage Agent** applies access control and audit logging with user context

### Flow 2: Secure Credential Storage

1. **Auth Agent** needs to store credential (e.g., password hash)
2. **Auth Agent** calls **Storage Agent** `store_credential()` API
3. **Storage Agent** encrypts credential using `encryption_at_rest`
4. **Storage Agent** stores with proper permissions
5. **Storage Agent** logs audit event

### Flow 3: Key Management

1. **Storage Agent** needs encryption key
2. **Storage Agent** calls **Auth Agent** `get_encryption_key()` API
3. **Auth Agent** retrieves key from secure storage
4. **Storage Agent** uses key for encryption operations

---

## Implementation Plan

### Phase 1: User/Group Context API (Week 1)

**Auth Agent (1a) Tasks**:
1. ⏳ Design `extract_user_context()` API
2. ⏳ Implement user_id extraction from JWT claims
3. ⏳ Implement group_id lookup from user_id
4. ⏳ Add tests for user context extraction

**Network Agent (1b) Tasks**:
1. ⏳ Update `file_transfer_handlers.zig` to use Auth Agent API
2. ⏳ Extract user_id/group_id from Authorization header
3. ⏳ Pass real user_id/group_id to Storage Agent APIs
4. ⏳ Test with authenticated requests

**Storage Agent (1c) Tasks**:
1. ✅ APIs ready to accept user_id/group_id (COMPLETE)
2. ⏳ Verify access control works with real user_id/group_id
3. ⏳ Verify audit logging includes user context

### Phase 2: Secure Credential Storage (Week 2)

**Storage Agent (1c) Tasks**:
1. ⏳ Design `store_credential()` API
2. ⏳ Implement credential encryption and storage
3. ⏳ Implement credential retrieval API
4. ⏳ Add tests for credential storage

**Auth Agent (1a) Tasks**:
1. ⏳ Integrate with Storage Agent credential storage API
2. ⏳ Store password hashes securely
3. ⏳ Store API keys securely
4. ⏳ Test credential storage end-to-end

### Phase 3: Key Management (Week 3)

**Auth Agent (1a) Tasks**:
1. ⏳ Design `get_encryption_key()` API
2. ⏳ Implement secure key storage
3. ⏳ Implement key retrieval
4. ⏳ Add tests for key management

**Storage Agent (1c) Tasks**:
1. ⏳ Integrate with Auth Agent key management API
2. ⏳ Request keys for encryption operations
3. ⏳ Support key rotation
4. ⏳ Test key management integration

---

## API Contracts

### Auth Agent → Storage Agent

**1. User/Group Context** (via Network Agent):
- Input: JWT token
- Output: user_id (u32), group_id (u32)
- Error: Invalid token → return false

**2. Credential Storage**:
- Input: credential_path, credential_data, user_id, group_id
- Output: success (bool)
- Error: Storage full, invalid path → return false

### Storage Agent → Auth Agent

**1. Key Management**:
- Input: key_id
- Output: encryption_key (32 bytes)
- Error: Key not found → return false

---

## Security Considerations

### 1. Credential Encryption

- All credentials encrypted at rest using AES-256-GCM
- Keys managed by Auth Agent
- No plaintext credentials in Storage Agent

### 2. Access Control

- Credentials stored with restrictive permissions
- Only Auth Agent can read/write credentials
- Audit logging for all credential operations

### 3. Key Management

- Keys stored securely by Auth Agent
- Key rotation supported
- Keys never exposed in logs or errors

---

## Testing Plan

### Unit Tests

1. **User Context Extraction**:
   - Valid JWT token → Extract user_id/group_id
   - Invalid token → Return false
   - Expired token → Return false

2. **Credential Storage**:
   - Store credential → Encrypt and store
   - Retrieve credential → Decrypt and return
   - Invalid path → Return error

3. **Key Management**:
   - Get key → Return key
   - Invalid key_id → Return false
   - Key rotation → Update key

### Integration Tests

1. **End-to-End Credential Storage**:
   - Auth Agent stores credential → Storage Agent encrypts → Auth Agent retrieves

2. **End-to-End File Operations with Auth**:
   - Upload with auth token → Extract user_id → Store file with user context

3. **Key Management Integration**:
   - Storage Agent requests key → Auth Agent provides → Storage Agent uses key

---

## Dependencies

### Storage Agent Provides

- ✅ `encryption_at_rest` module (COMPLETE)
- ✅ `access_control` module (COMPLETE)
- ✅ `audit_logger` module (COMPLETE)
- ✅ `integrated_file_storage` module (COMPLETE)
- ⏳ `store_credential()` API (to be implemented)

### Auth Agent Provides

- ✅ JWT token validation (COMPLETE)
- ✅ User authentication (COMPLETE)
- ⏳ `extract_user_context()` API (to be implemented)
- ⏳ `get_encryption_key()` API (to be implemented)

---

## Next Steps

### For Auth Agent (1a)

**Immediate**:
1. ⏳ Review this integration design
2. ⏳ Design `extract_user_context()` API
3. ⏳ Design `get_encryption_key()` API
4. ⏳ Coordinate with Storage Agent on credential storage API

### For Storage Agent (1c)

**Immediate**:
1. ✅ Integration design complete (COMPLETE)
2. ⏳ Wait for Auth Agent coordination
3. ⏳ Implement `store_credential()` API when Auth Agent is ready
4. ⏳ Prepare for key management integration

### For Core 1 Subcore

**Ongoing**:
1. ⏳ Facilitate Auth ↔ Storage coordination
2. ⏳ Review integration design
3. ⏳ Approve API contracts
4. ⏳ Coordinate implementation timeline

---

## Summary

**Storage Agent (1c) Status**: ✅ Integration design complete, APIs ready  
**Auth Agent (1a) Status**: ⏳ Review design, implement APIs  
**Integration Status**: ⏳ Design phase, ready for coordination  

**Next Action**: Auth Agent reviews integration design and coordinates API implementation.

---

**Date**: 2026-01-01-083000-pst  
**Agent**: Grain Storage Agent (1c)  
**Status**: Auth Agent Integration Design Complete - Ready for Coordination  
**Next Update**: After Auth Agent coordination
