# ApiKeyManager Module Design

**Date**: 2025-12-30-110000-pst  
**Agent**: Grain Court Agent (11th Agent)  
**Status**: Design Phase — Ready for Implementation (Pending Dependencies)  
**Dependencies**: 
- ⏳ Silo Agent `PasswordStorage` helper API (after Core Agent storage schema approval)
- ⏳ Core Agent `grain_passwords` module implementation

---

## Overview

The `ApiKeyManager` module provides secure, encrypted storage and management of LLM provider API keys. It replaces the current plaintext storage (security vulnerability) with encrypted storage via Grain Passwords and Silo Agent's `PasswordStorage` helper API.

**Key Features**:
- Encrypted API key storage and retrieval
- Key rotation support (active/inactive keys)
- Environment separation (dev, staging, prod)
- Provider-specific key management
- Access control integration (Security Manager)
- Audit logging for key access

**Location**: `src/grain_court/api_key_manager.zig`

---

## Design Principles

**Grain Style Compliance**:
- `grain_case` function names
- Explicit `u32`/`u64` types (not `usize`/`isize`)
- Bounded allocations (`MAX_` constants)
- Minimum 2 assertions per function
- Max 70 lines per function
- Max 100 characters per line
- No recursion

**Security Principles**:
- API keys never stored in plaintext
- Keys encrypted before storage (via Grain Passwords)
- Keys decrypted only when needed (in-memory, short-lived)
- Key rotation support for security updates
- Environment isolation for dev/staging/prod

**Integration Principles**:
- Follows SLC helper pattern (similar to `NostrProfileStorage`, `WorkspaceFileStorage`)
- Integrates with Silo Agent's `PasswordStorage` helper
- Integrates with Core Agent's `grain_passwords` module
- Integrates with Security Manager for access control

---

## Data Structures

### ApiKeyIdentifier

**Purpose**: Unique identifier for an API key in storage.

```zig
pub const ApiKeyIdentifier = struct {
    provider_type: ProviderType,
    environment: Environment,
    key_id: [64]u8,
    key_id_len: u32,
    
    // Initialize identifier from components.
    pub fn init(
        provider: ProviderType,
        env: Environment,
        key_id_str: []const u8,
    ) ApiKeyIdentifier {
        std.debug.assert(key_id_str.len > 0);
        std.debug.assert(key_id_str.len <= 64);
        var id = ApiKeyIdentifier{
            .provider_type = provider,
            .environment = env,
            .key_id = undefined,
            .key_id_len = 0,
        };
        var i: u32 = 0;
        while (i < 64) : (i += 1) {
            id.key_id[i] = 0;
        }
        i = 0;
        const len = @min(key_id_str.len, 64);
        while (i < len) : (i += 1) {
            id.key_id[i] = key_id_str[i];
        }
        id.key_id_len = len;
        std.debug.assert(id.key_id_len > 0);
        return id;
    }
    
    // Convert to storage key format: "password:court:{provider}:{env}:{key_id}".
    pub fn to_storage_key(self: *const ApiKeyIdentifier, allocator: std.mem.Allocator) ![]const u8 {
        std.debug.assert(self.key_id_len > 0);
        const provider_str = switch (self.provider_type) {
            .openai => "openai",
            .anthropic => "anthropic",
            .mistral => "mistral",
            .self_hosted => "self_hosted",
        };
        const env_str = switch (self.environment) {
            .dev => "dev",
            .staging => "staging",
            .prod => "prod",
        };
        const key_id_str = self.key_id[0..self.key_id_len];
        const key = std.fmt.allocPrint(
            allocator,
            "password:court:{s}:{s}:{s}",
            .{ provider_str, env_str, key_id_str },
        ) catch return error.OutOfMemory;
        std.debug.assert(key.len > 0);
        return key;
    }
};

pub const ProviderType = enum(u8) {
    openai,
    anthropic,
    mistral,
    self_hosted,
};

pub const Environment = enum(u8) {
    dev,
    staging,
    prod,
};
```

### ApiKeyMetadata

**Purpose**: Metadata for an API key (status, rotation info, timestamps).

```zig
pub const ApiKeyMetadata = struct {
    is_active: bool,
    created_at: u64, // Unix timestamp (seconds)
    updated_at: u64, // Unix timestamp (seconds)
    last_used_at: ?u64, // Unix timestamp (seconds), null if never used
    rotation_period_days: u32, // Days until rotation recommended
    description: [128]u8,
    description_len: u32,
    
    // Initialize metadata.
    pub fn init(
        active: bool,
        description_str: []const u8,
        rotation_days: u32,
    ) ApiKeyMetadata {
        std.debug.assert(description_str.len <= 128);
        const now = std.time.timestamp();
        var meta = ApiKeyMetadata{
            .is_active = active,
            .created_at = @as(u64, @intCast(now)),
            .updated_at = @as(u64, @intCast(now)),
            .last_used_at = null,
            .rotation_period_days = rotation_days,
            .description = undefined,
            .description_len = 0,
        };
        var i: u32 = 0;
        while (i < 128) : (i += 1) {
            meta.description[i] = 0;
        }
        i = 0;
        const len = @min(description_str.len, 128);
        while (i < len) : (i += 1) {
            meta.description[i] = description_str[i];
        }
        meta.description_len = len;
        std.debug.assert(meta.rotation_period_days > 0);
        return meta;
    }
    
    // Mark key as used (update last_used_at).
    pub fn mark_used(self: *ApiKeyMetadata) void {
        const now = std.time.timestamp();
        self.last_used_at = @as(u64, @intCast(now));
        self.updated_at = @as(u64, @intCast(now));
    }
    
    // Check if key should be rotated (past rotation period).
    pub fn should_rotate(self: *const ApiKeyMetadata) bool {
        std.debug.assert(self.rotation_period_days > 0);
        if (!self.is_active) return false;
        const now = std.time.timestamp();
        const age_seconds = @as(u64, @intCast(now)) - self.created_at;
        const age_days = age_seconds / 86400; // 86400 seconds per day
        return age_days >= self.rotation_period_days;
    }
};
```

### ApiKeyManager

**Purpose**: Main manager for API key storage and retrieval.

```zig
pub const ApiKeyManager = struct {
    password_storage: *PasswordStorage, // From Silo Agent
    password_module: *grain_passwords.PasswordModule, // From Core Agent
    security_manager: ?*security_manager.SecurityManager, // Optional access control
    allocator: std.mem.Allocator,
    
    // Maximum number of keys per provider/environment.
    const MAX_KEYS_PER_PROVIDER: u32 = 10;
    
    // Maximum key length (API keys are typically 32-256 chars).
    const MAX_KEY_LENGTH: u32 = 512;
    
    // Default rotation period (90 days).
    const DEFAULT_ROTATION_PERIOD_DAYS: u32 = 90;
    
    // Initialize API key manager.
    pub fn init(
        storage: *PasswordStorage,
        passwords: *grain_passwords.PasswordModule,
        security: ?*security_manager.SecurityManager,
        alloc: std.mem.Allocator,
    ) ApiKeyManager {
        std.debug.assert(storage != null);
        std.debug.assert(passwords != null);
        return ApiKeyManager{
            .password_storage = storage,
            .password_module = passwords,
            .security_manager = security,
            .allocator = alloc,
        };
    }
    
    // Store encrypted API key.
    pub fn store_key(
        self: *ApiKeyManager,
        identifier: *const ApiKeyIdentifier,
        api_key: []const u8,
        metadata: *const ApiKeyMetadata,
    ) !void {
        std.debug.assert(api_key.len > 0);
        std.debug.assert(api_key.len <= MAX_KEY_LENGTH);
        std.debug.assert(identifier.key_id_len > 0);
        
        // Check access control (if Security Manager available).
        if (self.security_manager) |sm| {
            // TODO: Check permissions for key storage.
            // sm.check_permission(user_id, "api_key:store") catch return error.AccessDenied;
        }
        
        // Encrypt API key via Grain Passwords module.
        const encrypted_data = try self.password_module.encrypt(
            api_key,
            self.allocator,
        );
        defer self.allocator.free(encrypted_data);
        
        // Convert identifier to storage key.
        const storage_key = try identifier.to_storage_key(self.allocator);
        defer self.allocator.free(storage_key);
        
        // Serialize metadata to JSON.
        const metadata_json = try self.serialize_metadata(metadata, self.allocator);
        defer self.allocator.free(metadata_json);
        
        // Store via PasswordStorage helper.
        try self.password_storage.store_secret(
            storage_key,
            encrypted_data,
            metadata_json,
        );
        
        // TODO: Audit log (if Security Manager available).
    }
    
    // Retrieve and decrypt API key.
    pub fn get_key(
        self: *ApiKeyManager,
        identifier: *const ApiKeyIdentifier,
        active_only: bool,
    ) ![]const u8 {
        std.debug.assert(identifier.key_id_len > 0);
        
        // Check access control (if Security Manager available).
        if (self.security_manager) |sm| {
            // TODO: Check permissions for key retrieval.
            // sm.check_permission(user_id, "api_key:get") catch return error.AccessDenied;
        }
        
        // Convert identifier to storage key.
        const storage_key = try identifier.to_storage_key(self.allocator);
        defer self.allocator.free(storage_key);
        
        // Retrieve from PasswordStorage helper.
        const record = self.password_storage.get_secret(storage_key) orelse {
            return error.KeyNotFound;
        };
        
        // Deserialize metadata.
        const metadata = try self.deserialize_metadata(record.metadata, self.allocator);
        defer self.allocator.free(metadata);
        
        // Check if active (if active_only is true).
        if (active_only and !metadata.is_active) {
            return error.KeyInactive;
        }
        
        // Decrypt API key via Grain Passwords module.
        const decrypted_key = try self.password_module.decrypt(
            record.encrypted_data,
            self.allocator,
        );
        
        // Update last_used_at (if metadata available).
        // TODO: Update metadata in storage.
        
        // TODO: Audit log (if Security Manager available).
        
        return decrypted_key;
    }
    
    // Get active key for provider/environment.
    pub fn get_active_key(
        self: *ApiKeyManager,
        provider: ProviderType,
        environment: Environment,
    ) ![]const u8 {
        std.debug.assert(@intFromEnum(provider) < 4);
        std.debug.assert(@intFromEnum(environment) < 3);
        
        // List all keys for provider/environment.
        const keys = try self.list_keys(provider, environment, true);
        defer {
            for (keys) |key| {
                self.allocator.free(key);
            }
            self.allocator.free(keys);
        }
        
        // Find first active key.
        for (keys) |key_id| {
            const identifier = ApiKeyIdentifier.init(provider, environment, key_id);
            const key = self.get_key(&identifier, true) catch |err| {
                if (err == error.KeyInactive) continue;
                return err;
            };
            return key;
        }
        
        return error.NoActiveKey;
    }
    
    // List keys for provider/environment.
    pub fn list_keys(
        self: *ApiKeyManager,
        provider: ProviderType,
        environment: Environment,
        active_only: bool,
    ) ![][]const u8 {
        std.debug.assert(@intFromEnum(provider) < 4);
        std.debug.assert(@intFromEnum(environment) < 3);
        
        // Build pattern: "password:court:{provider}:{env}:*".
        const provider_str = switch (provider) {
            .openai => "openai",
            .anthropic => "anthropic",
            .mistral => "mistral",
            .self_hosted => "self_hosted",
        };
        const env_str = switch (environment) {
            .dev => "dev",
            .staging => "staging",
            .prod => "prod",
        };
        const pattern = try std.fmt.allocPrint(
            self.allocator,
            "password:court:{s}:{s}:*",
            .{ provider_str, env_str },
        );
        defer self.allocator.free(pattern);
        
        // List secrets matching pattern.
        const secret_ids = try self.password_storage.list_secrets(pattern, self.allocator);
        defer {
            for (secret_ids) |id| {
                self.allocator.free(id);
            }
            self.allocator.free(secret_ids);
        }
        
        // Filter by active status if needed.
        var active_keys = std.ArrayList([]const u8).init(self.allocator);
        errdefer {
            for (active_keys.items) |key| {
                self.allocator.free(key);
            }
            active_keys.deinit();
        }
        
        for (secret_ids) |secret_id| {
            // Extract key_id from secret_id.
            // Format: "password:court:{provider}:{env}:{key_id}"
            const key_id = try self.extract_key_id(secret_id, self.allocator);
            defer self.allocator.free(key_id);
            
            if (active_only) {
                // Check if key is active.
                const identifier = ApiKeyIdentifier.init(provider, environment, key_id);
                const metadata = try self.get_metadata(&identifier);
                defer self.allocator.free(metadata);
                
                if (!metadata.is_active) continue;
            }
            
            const key_id_copy = try self.allocator.dupe(u8, key_id);
            try active_keys.append(key_id_copy);
        }
        
        return active_keys.toOwnedSlice();
    }
    
    // Rotate key (mark old as inactive, store new as active).
    pub fn rotate_key(
        self: *ApiKeyManager,
        identifier: *const ApiKeyIdentifier,
        new_api_key: []const u8,
        new_metadata: *const ApiKeyMetadata,
    ) !void {
        std.debug.assert(new_api_key.len > 0);
        std.debug.assert(new_api_key.len <= MAX_KEY_LENGTH);
        std.debug.assert(identifier.key_id_len > 0);
        
        // Check access control (if Security Manager available).
        if (self.security_manager) |sm| {
            // TODO: Check permissions for key rotation.
            // sm.check_permission(user_id, "api_key:rotate") catch return error.AccessDenied;
        }
        
        // Mark old key as inactive.
        try self.deactivate_key(identifier);
        
        // Generate new key_id (e.g., "secondary" if old was "primary").
        const new_key_id = try self.generate_rotation_key_id(identifier, self.allocator);
        defer self.allocator.free(new_key_id);
        
        const new_identifier = ApiKeyIdentifier.init(
            identifier.provider_type,
            identifier.environment,
            new_key_id,
        );
        
        // Store new key as active.
        try self.store_key(&new_identifier, new_api_key, new_metadata);
        
        // TODO: Audit log (if Security Manager available).
    }
    
    // Deactivate key (mark as inactive).
    pub fn deactivate_key(
        self: *ApiKeyManager,
        identifier: *const ApiKeyIdentifier,
    ) !void {
        std.debug.assert(identifier.key_id_len > 0);
        
        // Get current metadata.
        const metadata = try self.get_metadata(identifier);
        defer self.allocator.free(metadata);
        
        // Update metadata (mark as inactive).
        var updated_metadata = metadata.*;
        updated_metadata.is_active = false;
        updated_metadata.updated_at = @as(u64, @intCast(std.time.timestamp()));
        
        // Update in storage.
        const storage_key = try identifier.to_storage_key(self.allocator);
        defer self.allocator.free(storage_key);
        
        const metadata_json = try self.serialize_metadata(&updated_metadata, self.allocator);
        defer self.allocator.free(metadata_json);
        
        // Get encrypted data (keep same).
        const record = self.password_storage.get_secret(storage_key) orelse {
            return error.KeyNotFound;
        };
        
        try self.password_storage.update_secret(
            storage_key,
            record.encrypted_data,
            metadata_json,
        );
        
        // TODO: Audit log (if Security Manager available).
    }
    
    // Delete inactive key (after rotation period).
    pub fn delete_inactive_key(
        self: *ApiKeyManager,
        identifier: *const ApiKeyIdentifier,
    ) !void {
        std.debug.assert(identifier.key_id_len > 0);
        
        // Check access control (if Security Manager available).
        if (self.security_manager) |sm| {
            // TODO: Check permissions for key deletion.
            // sm.check_permission(user_id, "api_key:delete") catch return error.AccessDenied;
        }
        
        // Get metadata to verify inactive.
        const metadata = try self.get_metadata(identifier);
        defer self.allocator.free(metadata);
        
        if (metadata.is_active) {
            return error.KeyStillActive;
        }
        
        // Delete from storage.
        const storage_key = try identifier.to_storage_key(self.allocator);
        defer self.allocator.free(storage_key);
        
        try self.password_storage.delete_secret(storage_key);
        
        // TODO: Audit log (if Security Manager available).
    }
    
    // Helper: Get metadata for key.
    fn get_metadata(
        self: *ApiKeyManager,
        identifier: *const ApiKeyIdentifier,
    ) !*ApiKeyMetadata {
        std.debug.assert(identifier.key_id_len > 0);
        
        const storage_key = try identifier.to_storage_key(self.allocator);
        defer self.allocator.free(storage_key);
        
        const record = self.password_storage.get_secret(storage_key) orelse {
            return error.KeyNotFound;
        };
        
        return self.deserialize_metadata(record.metadata, self.allocator);
    }
    
    // Helper: Serialize metadata to JSON.
    fn serialize_metadata(
        self: *ApiKeyManager,
        metadata: *const ApiKeyMetadata,
        allocator: std.mem.Allocator,
    ) ![]const u8 {
        _ = self;
        std.debug.assert(metadata.rotation_period_days > 0);
        
        // TODO: Use JSON serialization library.
        // For now, return placeholder.
        const json = try std.fmt.allocPrint(
            allocator,
            "{{\"is_active\":{},\"created_at\":{},\"updated_at\":{},\"rotation_period_days\":{}}}",
            .{ metadata.is_active, metadata.created_at, metadata.updated_at, metadata.rotation_period_days },
        );
        return json;
    }
    
    // Helper: Deserialize metadata from JSON.
    fn deserialize_metadata(
        self: *ApiKeyManager,
        json: []const u8,
        allocator: std.mem.Allocator,
    ) !*ApiKeyMetadata {
        _ = self;
        std.debug.assert(json.len > 0);
        
        // TODO: Use JSON deserialization library.
        // For now, return placeholder.
        _ = allocator;
        return error.NotImplemented;
    }
    
    // Helper: Extract key_id from storage key.
    fn extract_key_id(
        self: *ApiKeyManager,
        storage_key: []const u8,
        allocator: std.mem.Allocator,
    ) ![]const u8 {
        _ = self;
        std.debug.assert(storage_key.len > 0);
        
        // Format: "password:court:{provider}:{env}:{key_id}"
        // Extract key_id (after last colon).
        const last_colon = std.mem.lastIndexOfScalar(u8, storage_key, ':') orelse {
            return error.InvalidKeyFormat;
        };
        
        const key_id = storage_key[last_colon + 1..];
        return allocator.dupe(u8, key_id);
    }
    
    // Helper: Generate rotation key_id.
    fn generate_rotation_key_id(
        self: *ApiKeyManager,
        old_identifier: *const ApiKeyIdentifier,
        allocator: std.mem.Allocator,
    ) ![]const u8 {
        _ = self;
        std.debug.assert(old_identifier.key_id_len > 0);
        
        // If old key_id is "primary", new is "secondary".
        // If old key_id is "secondary", new is "tertiary".
        // Otherwise, append "_rotated_{timestamp}".
        const old_key_id = old_identifier.key_id[0..old_identifier.key_id_len];
        
        if (std.mem.eql(u8, old_key_id, "primary")) {
            return allocator.dupe(u8, "secondary");
        } else if (std.mem.eql(u8, old_key_id, "secondary")) {
            return allocator.dupe(u8, "tertiary");
        } else {
            const timestamp = std.time.timestamp();
            return std.fmt.allocPrint(
                allocator,
                "{s}_rotated_{}",
                .{ old_key_id, timestamp },
            );
        }
    }
};
```

---

## Integration Points

### 1. Provider Initialization Integration

**Current State** (plaintext):
```zig
// src/grain_court/provider_openai.zig
pub fn init(
    api_key: []const u8,
    allocator: std.mem.Allocator,
) !OpenAIProvider {
    // Store plaintext key (SECURITY VULNERABILITY).
    var provider = OpenAIProvider{
        .api_key = undefined,
        .allocator = allocator,
    };
    // ... copy api_key to provider.api_key ...
}
```

**Target State** (encrypted):
```zig
// src/grain_court/provider_openai.zig
pub fn init(
    key_manager: *ApiKeyManager,
    environment: Environment,
    allocator: std.mem.Allocator,
) !OpenAIProvider {
    // Retrieve encrypted key from ApiKeyManager.
    const api_key = try key_manager.get_active_key(
        .openai,
        environment,
    );
    defer allocator.free(api_key);
    
    // Store key in provider (still in memory, but retrieved securely).
    var provider = OpenAIProvider{
        .api_key = undefined,
        .allocator = allocator,
    };
    // ... copy api_key to provider.api_key ...
}
```

### 2. ProviderPool Integration

**Current State**:
```zig
// src/grain_court/llm_provider.zig
pub const ProviderPool = struct {
    providers: [MAX_PROVIDERS]?*dyn ProviderTrait,
    provider_count: u32,
    allocator: std.mem.Allocator,
    
    pub fn add_openai_provider(
        self: *ProviderPool,
        api_key: []const u8,
    ) !void {
        const provider = try provider_openai.init(api_key, self.allocator);
        // ... add to pool ...
    }
};
```

**Target State**:
```zig
// src/grain_court/llm_provider.zig
pub const ProviderPool = struct {
    providers: [MAX_PROVIDERS]?*dyn ProviderTrait,
    provider_count: u32,
    key_manager: ?*ApiKeyManager, // Optional key manager
    environment: Environment, // Environment for key retrieval
    allocator: std.mem.Allocator,
    
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
};
```

---

## Key Rotation Patterns

### Pattern 1: Scheduled Rotation

**Use Case**: Rotate keys every 90 days for security.

**Implementation**:
1. Check `metadata.should_rotate()` periodically (e.g., daily cron job).
2. If rotation needed:
   - Generate new API key (via provider dashboard or API).
   - Call `rotate_key()` to store new key and deactivate old.
   - Keep old key inactive for 7 days (for in-flight requests).
   - After 7 days, call `delete_inactive_key()` to clean up.

**Example**:
```zig
// Check rotation status for all providers.
pub fn check_and_rotate_keys(
    manager: *ApiKeyManager,
    provider: ProviderType,
    environment: Environment,
) !void {
    const keys = try manager.list_keys(provider, environment, false);
    defer {
        for (keys) |key| manager.allocator.free(key);
        manager.allocator.free(keys);
    }
    
    for (keys) |key_id| {
        const identifier = ApiKeyIdentifier.init(provider, environment, key_id);
        const metadata = try manager.get_metadata(&identifier);
        defer manager.allocator.free(metadata);
        
        if (metadata.should_rotate()) {
            // TODO: Generate new API key (via provider API or manual).
            const new_key = "new_api_key_from_provider";
            const new_metadata = ApiKeyMetadata.init(
                true,
                "Rotated key",
                90,
            );
            
            try manager.rotate_key(&identifier, new_key, &new_metadata);
        }
    }
}
```

### Pattern 2: Manual Rotation

**Use Case**: Rotate keys immediately (e.g., key compromised).

**Implementation**:
1. User/admin triggers rotation via API or CLI.
2. Call `rotate_key()` with new key.
3. Old key deactivated immediately.
4. New key becomes active.

**Example**:
```zig
// Manual rotation.
pub fn rotate_key_manual(
    manager: *ApiKeyManager,
    provider: ProviderType,
    environment: Environment,
    new_api_key: []const u8,
) !void {
    const identifier = ApiKeyIdentifier.init(provider, environment, "primary");
    const new_metadata = ApiKeyMetadata.init(true, "Manually rotated", 90);
    
    try manager.rotate_key(&identifier, new_api_key, &new_metadata);
}
```

### Pattern 3: Zero-Downtime Rotation

**Use Case**: Rotate keys without interrupting service.

**Implementation**:
1. Store new key as active (parallel to old key).
2. Update provider to use new key for new requests.
3. Keep old key active for in-flight requests (grace period).
4. After grace period (e.g., 1 hour), deactivate old key.
5. After rotation period (e.g., 7 days), delete old key.

**Example**:
```zig
// Zero-downtime rotation.
pub fn rotate_key_zero_downtime(
    manager: *ApiKeyManager,
    provider: ProviderType,
    environment: Environment,
    new_api_key: []const u8,
) !void {
    // Store new key as active (parallel to old).
    const new_identifier = ApiKeyIdentifier.init(provider, environment, "secondary");
    const new_metadata = ApiKeyMetadata.init(true, "Zero-downtime rotation", 90);
    
    try manager.store_key(&new_identifier, new_api_key, &new_metadata);
    
    // ProviderPool will use new key for new requests.
    // Old key remains active for in-flight requests.
    
    // After grace period, deactivate old key.
    // (This would be done by a background task.)
}
```

---

## Environment Separation

### Environment-Based Key Selection

**Pattern**: Different API keys for dev, staging, prod environments.

**Implementation**:
1. Store keys with environment in identifier: `password:court:{provider}:{env}:{key_id}`.
2. ProviderPool initialized with environment.
3. `get_active_key()` retrieves key for specific environment.

**Example**:
```zig
// Initialize ProviderPool with environment.
pub fn init_provider_pool(
    key_manager: *ApiKeyManager,
    environment: Environment,
    allocator: std.mem.Allocator,
) !ProviderPool {
    var pool = ProviderPool{
        .providers = undefined,
        .provider_count = 0,
        .key_manager = key_manager,
        .environment = environment,
        .allocator = allocator,
    };
    
    // Add providers (keys retrieved from key_manager for environment).
    try pool.add_openai_provider(null); // null = use key_manager
    try pool.add_anthropic_provider(null);
    try pool.add_mistral_provider(null);
    
    return pool;
}
```

### Environment Isolation

**Pattern**: Ensure dev keys cannot be used in prod (and vice versa).

**Implementation**:
1. Environment passed as parameter (not derived from runtime).
2. Access control checks environment (if Security Manager available).
3. Audit logging includes environment.

**Example**:
```zig
// Environment isolation check.
pub fn get_key_with_isolation(
    manager: *ApiKeyManager,
    identifier: *const ApiKeyIdentifier,
    requested_env: Environment,
) ![]const u8 {
    // Verify environment matches.
    if (identifier.environment != requested_env) {
        return error.EnvironmentMismatch;
    }
    
    return manager.get_key(identifier, true);
}
```

---

## Access Control Integration

### Security Manager Integration

**Pattern**: Use Security Manager for role-based access control.

**Implementation**:
1. Check permissions before key operations:
   - `api_key:store` — Store new key
   - `api_key:get` — Retrieve key
   - `api_key:rotate` — Rotate key
   - `api_key:delete` — Delete key
2. Audit log all key operations.

**Example**:
```zig
// Access control check (in store_key).
if (self.security_manager) |sm| {
    const user_id = try sm.get_current_user_id();
    try sm.check_permission(user_id, "api_key:store") catch |err| {
        // Audit log failure.
        try sm.audit_log(user_id, "api_key:store", "denied", self.allocator);
        return err;
    };
    
    // Audit log success.
    try sm.audit_log(user_id, "api_key:store", "allowed", self.allocator);
}
```

---

## Implementation Notes

### Phase 1: Core Functionality (2-3 days)

**Day 1**:
1. Create `api_key_manager.zig` module structure.
2. Implement `ApiKeyIdentifier` and `ApiKeyMetadata` structs.
3. Implement basic `ApiKeyManager` struct (without full implementation).
4. Add tests for data structures.

**Day 2**:
1. Implement `store_key()` and `get_key()` functions.
2. Integrate with `PasswordStorage` helper (once API available).
3. Integrate with `grain_passwords` module (once available).
4. Add tests for storage/retrieval.

**Day 3**:
1. Implement key rotation functions (`rotate_key()`, `deactivate_key()`).
2. Implement environment separation.
3. Integrate with ProviderPool.
4. Add integration tests.

### Phase 2: Advanced Features (1-2 days)

**Day 4**:
1. Implement access control integration (Security Manager).
2. Implement audit logging.
3. Add background task for key rotation checks.
4. Add cleanup task for inactive keys.

**Day 5**:
1. Documentation and examples.
2. Performance testing.
3. Security review.

### Dependencies Checklist

**Before Implementation**:
- ⏳ Core Agent: Storage schema approval (4-7 hours)
- ⏳ Silo Agent: `PasswordStorage` helper API design (~1 day after approval)
- ⏳ Core Agent: `grain_passwords` module implementation (2-3 days)
- ⏳ Core Agent: Security Manager integration (if needed)

**During Implementation**:
- JSON serialization library (for metadata)
- Time utilities (for timestamps)
- Pattern matching utilities (for key listing)

---

## Testing Strategy

### Unit Tests

**Test File**: `tests/151_grain_court_api_key_manager_test.zig`

**Test Cases**:
1. `ApiKeyIdentifier` initialization and storage key conversion.
2. `ApiKeyMetadata` initialization and rotation checks.
3. `ApiKeyManager.store_key()` and `get_key()`.
4. Key rotation (`rotate_key()`, `deactivate_key()`).
5. Environment separation.
6. Key listing and filtering.

### Integration Tests

**Test Cases**:
1. Integration with `PasswordStorage` helper.
2. Integration with `grain_passwords` module.
3. Integration with ProviderPool.
4. End-to-end key storage and retrieval.

### Security Tests

**Test Cases**:
1. Keys never stored in plaintext.
2. Keys decrypted only when needed.
3. Access control enforcement.
4. Audit logging verification.

---

## Migration Plan

### Step 1: Prepare Migration

1. Review all provider initialization code.
2. Identify all API key storage locations.
3. Create migration script to extract existing keys (if any).

### Step 2: Implement ApiKeyManager

1. Implement module (as designed above).
2. Test with mock `PasswordStorage` and `grain_passwords`.
3. Verify Grain Style compliance.

### Step 3: Migrate Providers

1. Update `ProviderPool` to use `ApiKeyManager`.
2. Update provider `init()` functions to accept `ApiKeyManager`.
3. Migrate existing keys (if any) to encrypted storage.

### Step 4: Cleanup

1. Remove plaintext key storage.
2. Update documentation.
3. Add migration guide for users.

---

## Summary

The `ApiKeyManager` module provides secure, encrypted API key storage and management for Court Agent's LLM providers. It integrates with Silo Agent's `PasswordStorage` helper and Core Agent's `grain_passwords` module to replace the current plaintext storage (security vulnerability) with encrypted storage.

**Key Features**:
- ✅ Encrypted storage and retrieval
- ✅ Key rotation support
- ✅ Environment separation
- ✅ Access control integration
- ✅ Audit logging

**Implementation Timeline**: 2-3 days (Phase 1) + 1-2 days (Phase 2) = 4-5 days total (after dependencies available).

**Dependencies**: 
- ⏳ Silo Agent `PasswordStorage` helper API (after Core Agent storage schema approval)
- ⏳ Core Agent `grain_passwords` module implementation

---

**Date**: 2025-12-30-110000-pst  
**Agent**: Grain Court Agent (11th Agent)  
**Status**: Design Complete — Ready for Implementation (Pending Dependencies)
