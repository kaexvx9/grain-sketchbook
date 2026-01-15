# Grain Carry Agent: Offline Support Design

**Date**: 2025-12-31-174330-pst  
**Agent**: Grain Carry Agent (Mobile Framework)  
**Status**: Design Document — Offline Support Architecture  
**Voice**: Grain Glow G2 (positive, first-principles, helpful, succinct yet complete)

---

## Executive Summary

This document defines the offline support architecture for Grain Carry Agent's mobile applications. The design enables mobile apps to function fully offline with automatic synchronization when connectivity is restored, ensuring a seamless user experience even in areas with poor or intermittent network connectivity.

**Key Principles**:
- **Offline-First**: Core functionality works without network connectivity
- **Automatic Sync**: Seamless synchronization when connectivity is restored
- **Conflict Resolution**: Last-write-wins with manual override for critical data
- **Data Freshness**: Configurable expiration policies per data type
- **Efficient Storage**: Minimal local storage footprint with smart caching

**Target Use Cases**:
- JG Project mobile apps (Worker, Resident, Cooperative apps)
- General mobile framework for all Carry Agent applications
- Areas with poor network connectivity (construction sites, rural areas)

---

## Architecture Overview

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│  Mobile App (Kotlin/Swift UI)                           │
│  - Native UI components                                 │
│  - User interactions                                    │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│  Grain Carry Core (Zig FFI)                             │
│  - Business logic                                        │
│  - Data validation                                       │
│  - Authentication                                        │
└──────────────────┬──────────────────────────────────────┘
                   │
┌──────────────────▼──────────────────────────────────────┐
│  Offline Support Layer (NEW)                            │
│  - Local storage manager                                │
│  - Sync queue manager                                   │
│  - Conflict resolver                                    │
│  - Data freshness manager                               │
└───────┬───────────────────────────────┬─────────────────┘
        │                               │
┌───────▼──────────┐      ┌────────────▼──────────────┐
│  Local Storage   │      │  Sync Queue                │
│  (SQLite/Embedded│      │  (Pending Operations)       │
│   Database)      │      │                            │
└──────────────────┘      └────────────┬───────────────┘
                                        │
                           ┌────────────▼───────────────┐
                           │  Network Layer              │
                           │  (HTTP Client Integration)  │
                           │  - Sync when online         │
                           │  - Retry failed operations  │
                           └────────────────────────────┘
```

### Component Responsibilities

1. **Local Storage Manager**: Manages SQLite/embedded database for offline data
2. **Sync Queue Manager**: Tracks pending operations for synchronization
3. **Conflict Resolver**: Handles data conflicts during sync
4. **Data Freshness Manager**: Manages expiration policies and cache invalidation
5. **Network Layer**: Handles HTTP requests with offline queue integration

---

## Local Storage Strategy

### Storage Backend: SQLite (Recommended)

**Rationale**:
- **Cross-platform**: Works on both Android and iOS
- **Mature & Reliable**: Battle-tested, widely used
- **ACID Compliance**: Ensures data integrity
- **Lightweight**: Minimal overhead for mobile apps
- **Query Support**: SQL queries for complex data retrieval
- **FFI Integration**: C-compatible, easy to integrate with Zig

**Alternative**: Embedded database (custom implementation)
- **Pros**: Full control, Grain Style compliance, no external dependencies
- **Cons**: More development time, less mature, limited query support
- **Recommendation**: Start with SQLite, consider embedded database later if needed

### Database Schema Design

#### Core Tables

**1. `local_users`** (User data cache)
```sql
CREATE TABLE local_users (
    user_id TEXT PRIMARY KEY,
    email TEXT NOT NULL,
    username TEXT,
    password_hash BLOB,
    created_at INTEGER,
    updated_at INTEGER,
    synced_at INTEGER,
    sync_status INTEGER,  -- 0: synced, 1: pending_create, 2: pending_update, 3: pending_delete
    expires_at INTEGER
);
```

**2. `sync_queue`** (Pending operations)
```sql
CREATE TABLE sync_queue (
    queue_id INTEGER PRIMARY KEY AUTOINCREMENT,
    operation_type INTEGER,  -- 0: create, 1: update, 2: delete
    entity_type TEXT,         -- "user", "task", "time_log", etc.
    entity_id TEXT,
    payload BLOB,            -- JSON-encoded operation data
    created_at INTEGER,
    retry_count INTEGER,
    last_retry_at INTEGER,
    max_retries INTEGER DEFAULT 3
);
```

**3. `data_freshness`** (Expiration tracking)
```sql
CREATE TABLE data_freshness (
    entity_type TEXT PRIMARY KEY,
    last_synced_at INTEGER,
    expires_at INTEGER,
    ttl_seconds INTEGER  -- Time-to-live in seconds
);
```

**4. `conflict_log`** (Conflict resolution history)
```sql
CREATE TABLE conflict_log (
    conflict_id INTEGER PRIMARY KEY AUTOINCREMENT,
    entity_type TEXT,
    entity_id TEXT,
    local_version BLOB,
    server_version BLOB,
    resolution_strategy TEXT,  -- "last_write_wins", "manual", "server_wins"
    resolved_at INTEGER,
    resolved_by TEXT  -- "auto" or user_id
);
```

### Storage Limits

**Grain Style Compliance**:
- Maximum database size: 100 MB (configurable)
- Maximum record size: 1 MB per record
- Maximum sync queue size: 10,000 pending operations
- Maximum conflict log entries: 1,000 entries

**Bounded Allocations**:
```zig
pub const MAX_LOCAL_DB_SIZE: u64 = 104857600;  // 100 MB
pub const MAX_RECORD_SIZE: u32 = 1048576;      // 1 MB
pub const MAX_SYNC_QUEUE_SIZE: u32 = 10000;
pub const MAX_CONFLICT_LOG_SIZE: u32 = 1000;
```

---

## Sync Mechanisms

### Sync Strategy: Event-Driven with Periodic Polling

**Primary**: Event-driven sync (when network connectivity is restored)
- Triggered by network state change events
- Immediate sync for critical operations
- Background sync for non-critical data

**Fallback**: Periodic polling (every 5 minutes when online)
- Ensures data freshness even if events are missed
- Configurable interval per data type

### Sync Process Flow

```
1. Network Available?
   ├─ YES → Check sync queue
   │         ├─ Has pending operations? → Sync queue
   │         └─ No pending? → Check data freshness
   │                           ├─ Data expired? → Refresh from server
   │                           └─ Data fresh? → Skip
   └─ NO → Use local storage only

2. Sync Queue Processing:
   ├─ For each pending operation:
   │   ├─ Execute operation on server
   │   ├─ Success? → Remove from queue, update local data
   │   ├─ Conflict? → Trigger conflict resolution
   │   └─ Failure? → Increment retry count
   │                   ├─ Retry count < max? → Retry later
   │                   └─ Retry count >= max? → Mark as failed, notify user
   └─ Update sync timestamps

3. Conflict Resolution:
   ├─ Last-write-wins (default for most data)
   ├─ Server-wins (for critical server-managed data)
   └─ Manual resolution (for user-critical data like time logs)
```

### Sync Queue Operations

**Operation Types**:
- `CREATE`: New entity created offline
- `UPDATE`: Entity modified offline
- `DELETE`: Entity deleted offline

**Retry Logic**:
- Exponential backoff: 1s, 2s, 4s, 8s (capped at 8s)
- Maximum retries: 3 attempts
- After max retries: Mark as failed, notify user for manual intervention

**Priority Levels**:
- `HIGH`: Critical operations (time logs, payments, task completions)
- `MEDIUM`: User data updates
- `LOW`: Non-critical data (preferences, cached data)

---

## Conflict Resolution

### Conflict Detection

**When conflicts occur**:
1. Local data modified while offline
2. Server data modified by another client/process
3. Sync attempts to update server with stale local data

**Conflict Detection Strategy**:
- Compare `updated_at` timestamps
- Compare version numbers (if available)
- Compare data hashes (for complex data structures)

### Resolution Strategies

#### 1. Last-Write-Wins (Default)

**Use Cases**: User profile updates, preferences, non-critical data

**Process**:
```
1. Compare local.updated_at vs server.updated_at
2. If local > server: Use local version (update server)
3. If server > local: Use server version (update local)
4. Log conflict resolution
```

#### 2. Server-Wins (For Server-Managed Data)

**Use Cases**: Task assignments, project data, system configurations

**Process**:
```
1. Always use server version
2. Overwrite local data with server data
3. Log conflict resolution
4. Notify user if local changes were discarded
```

#### 3. Manual Resolution (For Critical User Data)

**Use Cases**: Time logs, wage payments, critical user inputs

**Process**:
```
1. Detect conflict
2. Store both versions in conflict_log
3. Notify user with conflict details
4. User chooses which version to keep
5. Apply user's choice
6. Log manual resolution
```

### Conflict Resolution Implementation

```zig
pub const ConflictResolutionStrategy = enum(u8) {
    last_write_wins,  // Default: Use most recent timestamp
    server_wins,      // Always use server version
    manual,           // Require user intervention
};

pub const ConflictInfo = struct {
    entity_type: []const u8,
    entity_id: []const u8,
    local_version: []const u8,      // JSON-encoded local data
    server_version: []const u8,     // JSON-encoded server data
    local_updated_at: u64,
    server_updated_at: u64,
    strategy: ConflictResolutionStrategy,
};
```

---

## Data Freshness & Expiration Policies

### Time-to-Live (TTL) Configuration

**Per-Entity-Type TTL**:

| Entity Type | TTL | Rationale |
|------------|-----|-----------|
| User Profile | 24 hours | Changes infrequently |
| Task Assignments | 1 hour | Frequently updated, critical for workers |
| Time Logs | 5 minutes | Real-time data, must be fresh |
| Wage Payments | 1 hour | Financial data, needs accuracy |
| Project Data | 4 hours | Changes moderately |
| Training/Certifications | 12 hours | Changes infrequently |
| Community Posts | 30 minutes | Social data, needs freshness |

### Expiration Policies

**Policy Types**:
1. **Strict Expiration**: Data considered stale after TTL, must refresh
2. **Soft Expiration**: Data may be stale, but usable until refresh succeeds
3. **No Expiration**: Data never expires (user preferences, cached static data)

**Implementation**:
```zig
pub const ExpirationPolicy = enum(u8) {
    strict,      // Must refresh after TTL
    soft,        // Prefer refresh, but allow stale data
    never,       // Never expires
};

pub const DataFreshnessConfig = struct {
    entity_type: []const u8,
    ttl_seconds: u64,
    policy: ExpirationPolicy,
};
```

### Cache Invalidation

**Triggers**:
- TTL expiration
- Manual refresh (pull-to-refresh)
- Server push notification (when implemented)
- App foreground (refresh stale data)

**Process**:
```
1. Check expires_at for entity type
2. If expired:
   ├─ Policy = strict? → Block access, force refresh
   ├─ Policy = soft? → Allow access, refresh in background
   └─ Policy = never? → No action
3. Refresh from server
4. Update expires_at = now + ttl_seconds
```

---

## Offline Queue Implementation

### Queue Structure

**Queue Entry**:
```zig
pub const SyncQueueEntry = struct {
    queue_id: u32,
    operation_type: OperationType,
    entity_type: [32]u8,      // "user", "task", etc.
    entity_type_len: u32,
    entity_id: [64]u8,        // Entity identifier
    entity_id_len: u32,
    payload: [MAX_RECORD_SIZE]u8,  // JSON-encoded operation data
    payload_len: u32,
    created_at: u64,
    retry_count: u32,
    last_retry_at: u64,
    max_retries: u32,
    priority: Priority,
};

pub const OperationType = enum(u8) {
    create,
    update,
    delete,
};

pub const Priority = enum(u8) {
    high,    // Critical operations
    medium,  // User data updates
    low,     // Non-critical data
};
```

### Queue Management

**Adding to Queue**:
- When offline operation is performed
- Store operation details in sync_queue table
- Set priority based on operation type
- Set created_at timestamp

**Processing Queue**:
- Process high-priority operations first
- Process in chronological order within priority level
- Retry failed operations with exponential backoff
- Remove successful operations from queue

**Queue Limits**:
- Maximum queue size: 10,000 operations
- When limit reached: Notify user, prevent new offline operations
- Cleanup: Remove operations older than 7 days (even if failed)

---

## Integration with Existing Code

### FFI Integration

**New FFI Functions** (to be added to `database_api.zig`):

```zig
// Offline support FFI exports
export fn grain_carry_enable_offline_mode(enabled: bool) void;
export fn grain_carry_is_offline_mode_enabled() bool;
export fn grain_carry_get_sync_queue_size() u32;
export fn grain_carry_force_sync() c_int;
export fn grain_carry_get_data_freshness(entity_type_ptr: [*c]const u8, entity_type_len: u32) u64;
```

### Database Integration Updates

**Modify `database_integration.zig`**:
- Add offline mode check before HTTP requests
- If offline: Store operation in sync queue, return success
- If online: Execute HTTP request, handle sync queue processing

**Example Integration**:
```zig
pub fn create_user(user_data: *const UserData) DatabaseResult {
    // Check offline mode
    if (offline_support.is_offline_mode_enabled()) {
        // Store in local database
        const local_result = offline_support.store_user_local(user_data);
        if (local_result != .success) {
            return local_result;
        }
        // Add to sync queue
        offline_support.add_to_sync_queue(.create, "user", user_data.user_id, user_data);
        return .success;
    }
    
    // Online mode: execute HTTP request
    // ... existing HTTP request code ...
}
```

### API Client Integration

**Modify `api_client_api.zig`**:
- Add offline queue support for HTTP requests
- Store requests in sync queue when offline
- Process queue when network is available

---

## Implementation Plan

### Phase 1: Local Storage Foundation (Week 1-2)
- [ ] SQLite integration (FFI bindings)
- [ ] Database schema creation
- [ ] Local storage manager implementation
- [ ] Basic CRUD operations for local storage
- [ ] Unit tests for local storage

### Phase 2: Sync Queue (Week 3-4)
- [ ] Sync queue manager implementation
- [ ] Queue persistence (SQLite)
- [ ] Queue processing logic
- [ ] Retry logic with exponential backoff
- [ ] Unit tests for sync queue

### Phase 3: Conflict Resolution (Week 5)
- [ ] Conflict detection logic
- [ ] Last-write-wins implementation
- [ ] Server-wins implementation
- [ ] Manual resolution framework
- [ ] Conflict logging
- [ ] Unit tests for conflict resolution

### Phase 4: Data Freshness (Week 6)
- [ ] TTL configuration system
- [ ] Expiration policy implementation
- [ ] Cache invalidation logic
- [ ] Background refresh mechanism
- [ ] Unit tests for data freshness

### Phase 5: Integration (Week 7-8)
- [ ] Integrate with database_integration.zig
- [ ] Integrate with api_client_api.zig
- [ ] FFI exports for offline support
- [ ] End-to-end testing
- [ ] Performance testing

### Phase 6: JG Project Integration (Week 9+)
- [ ] Worker app offline support
- [ ] Resident app offline support
- [ ] Cooperative app offline support
- [ ] JG-specific data models
- [ ] JG-specific conflict resolution rules

---

## Testing Strategy

### Unit Tests
- Local storage operations
- Sync queue management
- Conflict resolution strategies
- Data freshness policies
- Sync queue processing

### Integration Tests
- Offline → Online transition
- Sync queue processing
- Conflict resolution scenarios
- Data freshness expiration
- End-to-end user workflows

### Performance Tests
- Large sync queue processing (10,000 operations)
- Database size limits (100 MB)
- Concurrent operations
- Memory usage under load

---

## Security Considerations

### Local Storage Security
- **Encryption**: Encrypt sensitive data (passwords, payment info) before storing locally
- **Access Control**: Use SQLite encryption (SQLCipher) for database file
- **Data Sanitization**: Validate all data before storing locally

### Sync Security
- **Authentication**: All sync operations require valid JWT tokens
- **Authorization**: Verify user permissions before syncing data
- **Data Integrity**: Verify data integrity with checksums/hashes

### Conflict Resolution Security
- **Audit Logging**: Log all conflict resolutions for security audit
- **User Verification**: Require user confirmation for critical conflict resolutions
- **Tamper Detection**: Detect and prevent tampering with conflict logs

---

## Future Enhancements

### Phase 2 Features (Post-MVP)
- **Incremental Sync**: Only sync changed data, not full records
- **Compression**: Compress sync payloads for bandwidth efficiency
- **Delta Sync**: Sync only differences between local and server data
- **Multi-Device Sync**: Sync across multiple devices for same user
- **Background Sync**: Background sync even when app is closed (platform-specific)

### Advanced Features
- **Conflict Visualization**: UI for users to see and resolve conflicts
- **Sync Analytics**: Track sync performance, success rates, conflict frequency
- **Custom TTL Policies**: Allow apps to configure custom TTL per entity type
- **Selective Sync**: Allow users to choose which data to sync

---

## Dependencies

### External Dependencies
- **SQLite**: C library for embedded database (via FFI)
- **SQLCipher**: Optional encryption for SQLite (for sensitive data)

### Internal Dependencies
- **Grain Carry Core**: Existing database integration, API client
- **Grain Core**: HTTP client, authentication service
- **Grain Flow**: Event Bus (for network state changes)

### Coordination Needs
- **Silo Agent**: Confirm sync API endpoints, conflict resolution support
- **Core Agent**: Confirm HTTP event publishing for sync triggers
- **Flow Agent**: Network state change events for sync triggers

---

## Success Metrics

### Performance Metrics
- **Sync Latency**: < 5 seconds for queue processing (100 operations)
- **Storage Efficiency**: < 50 MB local storage for typical user
- **Conflict Rate**: < 1% of sync operations result in conflicts
- **Sync Success Rate**: > 99% of operations sync successfully

### User Experience Metrics
- **Offline Functionality**: 100% of core features work offline
- **Sync Transparency**: Users don't notice sync process (seamless)
- **Conflict Resolution**: < 5 seconds for automatic conflict resolution
- **Data Freshness**: 95% of data is fresh (within TTL) when accessed

---

## Conclusion

This offline support design provides a comprehensive architecture for enabling offline functionality in Grain Carry Agent's mobile applications. The design balances user experience (seamless offline operation) with technical requirements (data consistency, conflict resolution, storage efficiency).

**Next Steps**:
1. Review and approve design with Core Agent coordination
2. Begin Phase 1 implementation (Local Storage Foundation)
3. Coordinate with Silo Agent on sync API endpoints
4. Coordinate with Flow Agent on network state change events

**Status**: ✅ **DESIGN COMPLETE** — Ready for implementation
