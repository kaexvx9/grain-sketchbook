# Core 1a Auth Agent: Storage Integration Design

**Date**: 2026-01-02-003955-pst  
**Agent**: Grain Auth Agent (1a) — L2 Sub-Agent  
**Parent Agent**: Grain Core 1 Subcore Agent (1st Agent, L1 Subcore)  
**Status**: ✅ **DESIGN READY** — Storage integration patterns for persistent auth data

---

## Executive Summary

This document provides Auth Agent's perspective on storage integration with Storage Agent (1c) for persistent storage of authentication and authorization data. This complements the Storage Agent's integration design document (`core_1c_storage_auth_integration_design_2026-01-01-083000-pst.md`).

**Current Auth Service Status**:
- ✅ All authentication features implemented (JWT, password hashing, sessions, API keys, RBAC, CSRF, rate limiting, audit logging)
- ✅ In-memory storage for all data structures
- ⏳ Persistent storage integration pending (Storage Agent 1c)

**Storage Integration Needs**:
- ⏳ API key persistent storage
- ⏳ RBAC roles and permissions persistent storage
- ⏳ Audit log persistent storage
- ⏳ User credential storage (password hashes)
- ⏳ Session persistence (optional, for distributed systems)

---

## Storage Integration Objectives

### 1. API Key Persistent Storage

**Objective**: Store API keys persistently for long-term access and key management.

**Current State**: API keys stored in-memory (`api_keys` array in `AuthService`).

**Requirements**:
- Store API keys with encryption at rest
- Support API key lookup by key string (for validation)
- Support API key lookup by user_id (for key management)
- Support API key revocation and expiration
- Enable API key rotation

**Storage Schema**:
```
/secure/auth/api_keys/{key_id}
  - key_hash: [32]u8 (SHA-256 hash of API key)
  - user_id: [64]u8
  - scopes: [16][32]u8 (scope names)
  - scopes_len: u32
  - created_at: u64
  - expires_at: u64
  - is_active: bool
  - metadata: [256]u8 (JSON metadata)
```

---

### 2. RBAC Roles and Permissions Persistent Storage

**Objective**: Store RBAC roles and permissions persistently for role management.

**Current State**: Roles and permissions stored in-memory (`roles` and `permissions` arrays in `AuthService`).

**Requirements**:
- Store roles with role name, role ID, and permissions
- Store permissions with permission name, resource, and action
- Support role lookup by role ID
- Support role lookup by role name
- Support permission lookup by permission ID
- Enable role assignment to users
- Support role and permission updates

**Storage Schema**:
```
/secure/auth/roles/{role_id}
  - role_name: [64]u8
  - permissions: [64]u32 (permission IDs)
  - permissions_len: u32
  - created_at: u64
  - updated_at: u64

/secure/auth/permissions/{permission_id}
  - permission_name: [64]u8
  - resource: [128]u8
  - action: [64]u8
  - created_at: u64

/secure/auth/user_roles/{user_id}
  - roles: [16]u32 (role IDs)
  - roles_len: u32
  - updated_at: u64
```

---

### 3. Audit Log Persistent Storage

**Objective**: Store audit logs persistently for security auditing and compliance.

**Current State**: Audit logs stored in-memory (`audit_logs` array in `AuthService`).

**Requirements**:
- Store audit log entries with rotation (oldest entries removed when limit reached)
- Support audit log querying by user_id, timestamp range, event type
- Enable audit log export for compliance
- Support audit log retention policies

**Storage Schema**:
```
/secure/auth/audit_logs/{timestamp}_{log_id}
  - timestamp: u64
  - user_id: [64]u8
  - event_type: [32]u8 (e.g., "login", "logout", "permission_denied")
  - ip_address: [45]u8 (IPv6 max length)
  - user_agent: [256]u8
  - message: [512]u8
  - success: bool
```

**Storage Pattern**: Time-based directory structure for efficient querying:
```
/secure/auth/audit_logs/{year}/{month}/{day}/{timestamp}_{log_id}
```

---

### 4. User Credential Storage

**Objective**: Store user credentials (password hashes) securely.

**Current State**: Password hashing implemented, but no persistent storage (users managed externally).

**Requirements**:
- Store password hashes with encryption at rest
- Support password hash lookup by user_id
- Support password hash updates (password changes)
- Enable password hash rotation
- Support user metadata storage

**Storage Schema**:
```
/secure/auth/users/{user_id}
  - password_hash: [64]u8 (Argon2 hash format)
  - hash_format: u8 (HashFormat enum)
  - created_at: u64
  - updated_at: u64
  - last_login: u64
  - metadata: [512]u8 (JSON metadata: email, username, etc.)
```

---

### 5. Session Persistence (Optional)

**Objective**: Store sessions persistently for distributed systems and session recovery.

**Current State**: Sessions stored in-memory (`sessions` array in `AuthService`).

**Requirements**:
- Store sessions with encryption at rest
- Support session lookup by session_id
- Support session lookup by user_id (for session management)
- Enable session expiration and cleanup
- Support session revocation

**Storage Schema**:
```
/secure/auth/sessions/{session_id}
  - user_id: [64]u8
  - created_at: u64
  - expires_at: u64
  - is_active: bool
  - ip_address: [45]u8
  - user_agent: [256]u8
```

**Note**: Session persistence is optional. In-memory sessions are sufficient for single-instance deployments. Persistent sessions enable distributed systems and session recovery after restarts.

---

## API Design

### 1. API Key Storage API

**Storage Agent provides** (from Storage Agent design):
```zig
// Store encrypted credential
pub fn store_credential(
    storage_manager: *IntegratedFileStorageManager,
    credential_path: []const u8,
    credential_data: []const u8,
    user_id: u32,
    group_id: u32,
    current_time: u64,
) bool;
```

**Auth Agent usage**:
```zig
// Store API key
pub fn store_api_key_persistent(
    self: *AuthService,
    storage_manager: *storage.IntegratedFileStorageManager,
    api_key: *ApiKey,
    current_time: u64,
) bool {
    std.debug.assert(api_key != null);
    std.debug.assert(storage_manager != null);
    std.debug.assert(current_time > 0);
    
    // Serialize API key to JSON or binary format.
    var key_data: [512]u8 = undefined;
    const key_data_len = serialize_api_key(api_key, &key_data);
    
    // Construct storage path.
    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(
        &path_buf,
        "/secure/auth/api_keys/{s}",
        .{api_key.key_id},
    ) catch return false;
    
    // Store via Storage Agent.
    const user_id_u32: u32 = 0; // System user for auth storage
    const group_id_u32: u32 = 0; // System group for auth storage
    return storage_manager.store_credential(
        path,
        key_data[0..key_data_len],
        user_id_u32,
        group_id_u32,
        current_time,
    );
}

// Load API key from storage
pub fn load_api_key_persistent(
    self: *AuthService,
    storage_manager: *storage.IntegratedFileStorageManager,
    key_id: []const u8,
    api_key_out: *ApiKey,
) bool {
    std.debug.assert(key_id.len > 0);
    std.debug.assert(storage_manager != null);
    std.debug.assert(api_key_out != null);
    
    // Construct storage path.
    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(
        &path_buf,
        "/secure/auth/api_keys/{s}",
        .{key_id},
    ) catch return false;
    
    // Load from Storage Agent.
    var key_data: [512]u8 = undefined;
    const key_data_len = storage_manager.load_credential(
        path,
        &key_data,
    ) orelse return false;
    
    // Deserialize API key.
    return deserialize_api_key(key_data[0..key_data_len], api_key_out);
}
```

---

### 2. RBAC Storage API

**Auth Agent usage**:
```zig
// Store role persistently
pub fn store_role_persistent(
    self: *AuthService,
    storage_manager: *storage.IntegratedFileStorageManager,
    role: *Role,
    current_time: u64,
) bool {
    std.debug.assert(role != null);
    std.debug.assert(storage_manager != null);
    std.debug.assert(current_time > 0);
    
    // Serialize role to JSON or binary format.
    var role_data: [1024]u8 = undefined;
    const role_data_len = serialize_role(role, &role_data);
    
    // Construct storage path.
    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(
        &path_buf,
        "/secure/auth/roles/{d}",
        .{role.role_id},
    ) catch return false;
    
    // Store via Storage Agent.
    const user_id_u32: u32 = 0; // System user
    const group_id_u32: u32 = 0; // System group
    return storage_manager.store_credential(
        path,
        role_data[0..role_data_len],
        user_id_u32,
        group_id_u32,
        current_time,
    );
}

// Load role from storage
pub fn load_role_persistent(
    self: *AuthService,
    storage_manager: *storage.IntegratedFileStorageManager,
    role_id: u32,
    role_out: *Role,
) bool {
    std.debug.assert(storage_manager != null);
    std.debug.assert(role_out != null);
    
    // Construct storage path.
    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(
        &path_buf,
        "/secure/auth/roles/{d}",
        .{role_id},
    ) catch return false;
    
    // Load from Storage Agent.
    var role_data: [1024]u8 = undefined;
    const role_data_len = storage_manager.load_credential(
        path,
        &role_data,
    ) orelse return false;
    
    // Deserialize role.
    return deserialize_role(role_data[0..role_data_len], role_out);
}
```

---

### 3. Audit Log Storage API

**Auth Agent usage**:
```zig
// Store audit log entry persistently
pub fn store_audit_log_persistent(
    self: *AuthService,
    storage_manager: *storage.IntegratedFileStorageManager,
    log_entry: *AuditLogEntry,
    current_time: u64,
) bool {
    std.debug.assert(log_entry != null);
    std.debug.assert(storage_manager != null);
    std.debug.assert(current_time > 0);
    
    // Serialize audit log entry.
    var log_data: [1024]u8 = undefined;
    const log_data_len = serialize_audit_log(log_entry, &log_data);
    
    // Construct time-based storage path.
    var path_buf: [512]u8 = undefined;
    const path = construct_audit_log_path(log_entry.timestamp, &path_buf) catch return false;
    
    // Store via Storage Agent.
    const user_id_u32: u32 = 0; // System user
    const group_id_u32: u32 = 0; // System group
    return storage_manager.store_credential(
        path,
        log_data[0..log_data_len],
        user_id_u32,
        group_id_u32,
        current_time,
    );
}

// Query audit logs by time range
pub fn query_audit_logs_persistent(
    self: *AuthService,
    storage_manager: *storage.IntegratedFileStorageManager,
    start_time: u64,
    end_time: u64,
    logs_out: []AuditLogEntry,
    logs_len_out: *u32,
) bool {
    std.debug.assert(storage_manager != null);
    std.debug.assert(start_time <= end_time);
    std.debug.assert(logs_out.len > 0);
    std.debug.assert(logs_len_out != null);
    
    // Query Storage Agent for audit logs in time range.
    // Implementation depends on Storage Agent query API.
    // For now, placeholder.
    logs_len_out.* = 0;
    return true;
}
```

---

### 4. User Credential Storage API

**Auth Agent usage**:
```zig
// Store user password hash persistently
pub fn store_user_password_hash(
    self: *AuthService,
    storage_manager: *storage.IntegratedFileStorageManager,
    user_id: []const u8,
    password_hash: []const u8,
    hash_format: HashFormat,
    current_time: u64,
) bool {
    std.debug.assert(user_id.len > 0);
    std.debug.assert(user_id.len <= MAX_USER_ID_LEN);
    std.debug.assert(password_hash.len > 0);
    std.debug.assert(storage_manager != null);
    std.debug.assert(current_time > 0);
    
    // Serialize user credential.
    var cred_data: [256]u8 = undefined;
    const cred_data_len = serialize_user_credential(
        password_hash,
        hash_format,
        current_time,
        &cred_data,
    );
    
    // Construct storage path.
    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(
        &path_buf,
        "/secure/auth/users/{s}",
        .{user_id},
    ) catch return false;
    
    // Store via Storage Agent.
    const user_id_u32: u32 = 0; // System user
    const group_id_u32: u32 = 0; // System group
    return storage_manager.store_credential(
        path,
        cred_data[0..cred_data_len],
        user_id_u32,
        group_id_u32,
        current_time,
    );
}

// Load user password hash from storage
pub fn load_user_password_hash(
    self: *AuthService,
    storage_manager: *storage.IntegratedFileStorageManager,
    user_id: []const u8,
    password_hash_out: []u8,
    hash_format_out: *HashFormat,
) bool {
    std.debug.assert(user_id.len > 0);
    std.debug.assert(user_id.len <= MAX_USER_ID_LEN);
    std.debug.assert(storage_manager != null);
    std.debug.assert(password_hash_out.len >= HASH_OUTPUT_LEN);
    std.debug.assert(hash_format_out != null);
    
    // Construct storage path.
    var path_buf: [256]u8 = undefined;
    const path = std.fmt.bufPrint(
        &path_buf,
        "/secure/auth/users/{s}",
        .{user_id},
    ) catch return false;
    
    // Load from Storage Agent.
    var cred_data: [256]u8 = undefined;
    const cred_data_len = storage_manager.load_credential(
        path,
        &cred_data,
    ) orelse return false;
    
    // Deserialize user credential.
    return deserialize_user_credential(
        cred_data[0..cred_data_len],
        password_hash_out,
        hash_format_out,
    );
}
```

---

## Integration Architecture

### Hybrid Storage Model

**Design**: Use hybrid storage model (in-memory + persistent) for performance and persistence.

**Architecture**:
1. **In-Memory Cache**: Keep frequently accessed data in memory for fast access
2. **Persistent Storage**: Store all data persistently via Storage Agent
3. **Lazy Loading**: Load data from storage on-demand
4. **Write-Through**: Write changes to storage immediately
5. **Cache Invalidation**: Invalidate cache on updates

**Benefits**:
- ✅ Fast access for frequently used data
- ✅ Persistent storage for durability
- ✅ Supports distributed systems (shared storage)
- ✅ Enables data recovery after restarts

---

### Data Serialization

**Design**: Use binary serialization for efficiency (JSON for human-readable metadata).

**Serialization Format**:
- **API Keys**: Binary format (key_hash, user_id, scopes, timestamps, flags)
- **Roles**: Binary format (role_id, role_name, permission_ids)
- **Permissions**: Binary format (permission_id, resource, action)
- **Audit Logs**: Binary format (timestamp, user_id, event_type, metadata)
- **User Credentials**: Binary format (password_hash, hash_format, timestamps)

**Metadata**: Use JSON for human-readable metadata (API key metadata, user metadata).

---

## Questions for Storage Agent (1c)

**Integration Design Questions**:

1. **Storage API**:
   - [ ] Is `store_credential()` and `load_credential()` API finalized?
   - [ ] What is the maximum credential data size?
   - [ ] How should we handle credential updates (overwrite or version)?

2. **Query API**:
   - [ ] Is there a query API for time-based queries (audit logs)?
   - [ ] How should we query by user_id or other fields?
   - [ ] What is the query performance for large datasets?

3. **Encryption**:
   - [ ] How is encryption at rest handled (automatic or explicit)?
   - [ ] Should Auth Agent provide encryption keys or use Storage Agent keys?
   - [ ] How should key rotation be handled?

4. **Access Control**:
   - [ ] How should access control be enforced (Storage Agent or Auth Agent)?
   - [ ] What user_id/group_id should be used for auth storage (system user)?
   - [ ] How should permissions be managed for auth storage paths?

5. **Performance**:
   - [ ] What is the expected performance for read/write operations?
   - [ ] Should we use caching or direct storage access?
   - [ ] How should we handle concurrent access?

6. **Data Format**:
   - [ ] Should we use JSON, binary, or custom format for serialization?
   - [ ] What is the recommended path structure for auth data?
   - [ ] How should we handle data migration and versioning?

---

## Implementation Timeline

### Phase 1: API Contract Design (Week 1)
- [ ] Coordinate with Storage Agent (1c) on API contracts
- [ ] Agree on storage schema and data formats
- [ ] Define serialization formats
- [ ] Design query patterns

### Phase 2: Core Storage Integration (Weeks 2-3)
- [ ] Implement API key persistent storage
- [ ] Implement RBAC persistent storage
- [ ] Implement audit log persistent storage
- [ ] Implement user credential storage
- [ ] Add comprehensive storage tests

### Phase 3: Hybrid Storage Model (Week 3-4)
- [ ] Implement in-memory cache
- [ ] Implement lazy loading
- [ ] Implement write-through updates
- [ ] Implement cache invalidation
- [ ] Add performance tests

### Phase 4: Integration Testing (Week 4)
- [ ] Integration tests with Storage Agent
- [ ] End-to-end storage testing
- [ ] Performance testing
- [ ] Framework x86_64 testing verification

---

## Grain Style Compliance

**All Storage Integration Functions**:
- ✅ Function length ≤ 70 lines
- ✅ Line length ≤ 100 characters
- ✅ Explicit types (`u32`/`u64`, no `usize`/`isize`)
- ✅ Bounded allocations (MAX_ constants)
- ✅ Minimum 2 assertions per function
- ✅ `grain_case` function names

---

## Summary

**Status**: ✅ **DESIGN READY** — Storage integration patterns prepared for Storage Agent (1c) coordination

**Next Steps**:
1. Coordinate with Storage Agent (1c) on API contracts
2. Agree on storage schema and data formats
3. Design serialization formats
4. Begin implementation after coordination complete

**Ready For**:
- ✅ Design discussion with Storage Agent (1c)
- ✅ API contract finalization
- ✅ Implementation (after coordination complete)

---

**Date**: 2026-01-02-003955-pst  
**Agent**: Grain Auth Agent (1a)  
**Status**: ✅ Storage integration design ready for Storage Agent (1c) coordination

---

