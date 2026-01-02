# Core 1 Subcore: API Contract Patterns for Cross-Sub-Agent Integration

**Date**: 2026-01-02-004500-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: 🆕 **DESIGN IN PROGRESS** — API contract patterns for Core 1 Subcore L2 sub-agents

---

## Executive Summary

This document defines API contract patterns for cross-sub-agent integration within Core 1 Subcore. These patterns ensure consistent, safe, and efficient integration between Auth (1a), Network (1b), Storage (1c), Compositor (1d), and Grainscript Shell (1e) agents.

**Purpose**: Provide design patterns and best practices for L2 sub-agents when implementing cross-sub-agent integration.

---

## Core Principles

### Grain Style Compliance

All API contracts must follow Grain Style:
- `grain_case` function names
- Explicit `u32`/`u64` types (no `usize`/`isize`)
- Bounded allocations (MAX_ constants)
- Minimum 2 assertions per function
- Max 70 lines per function
- Max 100 characters per line
- All compiler warnings addressed

### Safety First

- All operations must be bounded
- Error handling must be explicit
- Resource cleanup must be guaranteed
- No unbounded recursion

### Performance

- Minimize allocations
- Use stack-allocated buffers where possible
- Avoid unnecessary copies
- Profile integration points

---

## API Contract Pattern 1: Auth ↔ Network (Authentication Middleware)

### Pattern Overview

**Purpose**: Network Agent uses Auth Agent's authentication middleware to protect routes.

**Flow**:
1. Network Agent registers route with optional auth requirement
2. Network Agent receives request
3. Network Agent calls Auth Agent middleware to validate token
4. Auth Agent returns validation result
5. Network Agent proceeds or rejects based on result

### API Contract

```zig
// Auth Agent provides middleware function
pub fn create_auth_middleware(
    allocator: std.mem.Allocator,
    auth_service: *AuthService,
) AuthMiddleware {
    // Returns middleware function pointer
}

// Middleware function signature
pub const AuthMiddleware = *const fn (
    request: *HttpRequest,
    auth_service: *AuthService,
) AuthResult;

// Auth result
pub const AuthResult = struct {
    authenticated: bool,
    user_id: ?u64,
    error_message: ?[]const u8,
};

// Network Agent uses middleware
pub fn register_route_with_auth(
    self: *NetworkManager,
    method: HttpMethod,
    path: []const u8,
    handler: RouteHandler,
    auth_middleware: ?AuthMiddleware,
) !void {
    // Register route with optional auth middleware
}
```

### Error Handling

- Auth validation failures return `AuthResult` with `authenticated = false`
- Network Agent handles auth failures by returning 401 Unauthorized
- All errors are bounded and explicit

### Resource Management

- Auth middleware uses bounded token storage
- No unbounded allocations
- Token validation is stateless (no session storage in middleware)

---

## API Contract Pattern 2: Network ↔ Storage (File Transfer)

### Pattern Overview

**Purpose**: Network Agent uploads/downloads files via Storage Agent.

**Flow**:
1. Network Agent receives file upload request
2. Network Agent calls Storage Agent to create file
3. Storage Agent returns file handle
4. Network Agent streams data to Storage Agent
5. Storage Agent writes data to file
6. Network Agent confirms completion

### API Contract

```zig
// Storage Agent provides file transfer interface
pub fn create_file_for_upload(
    self: *StorageManager,
    filename: []const u8,
    size: u64,
) !FileHandle {
    // Create file and return handle
}

pub fn write_file_chunk(
    self: *StorageManager,
    handle: FileHandle,
    data: []const u8,
    offset: u64,
) !void {
    // Write chunk to file at offset
}

pub fn finalize_file_upload(
    self: *StorageManager,
    handle: FileHandle,
) !void {
    // Finalize file upload
}

// Network Agent uses file transfer
pub fn handle_file_upload(
    self: *NetworkManager,
    request: *HttpRequest,
    storage: *StorageManager,
) !void {
    // Parse upload request
    // Create file via Storage Agent
    // Stream data to Storage Agent
    // Finalize upload
}
```

### Error Handling

- File creation failures return explicit errors
- Chunk write failures are handled with retry logic
- All errors are bounded and explicit

### Resource Management

- File handles are bounded (MAX_FILE_HANDLES)
- Chunk sizes are bounded (MAX_CHUNK_SIZE)
- File sizes are bounded (MAX_FILE_SIZE)

---

## API Contract Pattern 3: Storage ↔ Auth (Credential Storage)

### Pattern Overview

**Purpose**: Auth Agent stores and retrieves credentials via Storage Agent.

**Flow**:
1. Auth Agent needs to store credentials
2. Auth Agent calls Storage Agent to store encrypted credentials
3. Storage Agent stores credentials securely
4. Auth Agent retrieves credentials when needed
5. Storage Agent returns encrypted credentials
6. Auth Agent decrypts credentials

### API Contract

```zig
// Storage Agent provides secure storage interface
pub fn store_credentials(
    self: *StorageManager,
    user_id: u64,
    credential_type: CredentialType,
    encrypted_data: []const u8,
) !void {
    // Store encrypted credentials
}

pub fn retrieve_credentials(
    self: *StorageManager,
    user_id: u64,
    credential_type: CredentialType,
) ![]const u8 {
    // Retrieve encrypted credentials
}

// Auth Agent uses secure storage
pub fn save_user_credentials(
    self: *AuthService,
    user_id: u64,
    password_hash: []const u8,
    storage: *StorageManager,
) !void {
    // Encrypt credentials
    // Store via Storage Agent
}
```

### Error Handling

- Storage failures return explicit errors
- Credential retrieval failures are handled gracefully
- All errors are bounded and explicit

### Resource Management

- Credential storage is bounded (MAX_CREDENTIALS_PER_USER)
- Encrypted data sizes are bounded (MAX_CREDENTIAL_SIZE)
- Storage operations are atomic

---

## API Contract Pattern 4: Compositor ↔ Storage (Workspace State Persistence)

### Pattern Overview

**Purpose**: Compositor Agent saves and loads workspace state via Storage Agent.

**Flow**:
1. Compositor Agent needs to save workspace state
2. Compositor Agent serializes workspace state
3. Compositor Agent calls Storage Agent to save state
4. Storage Agent persists state
5. Compositor Agent loads workspace state on startup
6. Storage Agent returns persisted state
7. Compositor Agent deserializes state

### API Contract

```zig
// Storage Agent provides workspace state storage
pub fn save_workspace_state(
    self: *StorageManager,
    workspace_id: u64,
    state_data: []const u8,
) !void {
    // Save workspace state
}

pub fn load_workspace_state(
    self: *StorageManager,
    workspace_id: u64,
) ![]const u8 {
    // Load workspace state
}

// Compositor Agent uses workspace state storage
pub fn save_current_workspace(
    self: *Compositor,
    storage: *StorageManager,
) !void {
    // Serialize workspace state
    // Save via Storage Agent
}

pub fn load_workspace(
    self: *Compositor,
    workspace_id: u64,
    storage: *StorageManager,
) !void {
    // Load state via Storage Agent
    // Deserialize workspace state
}
```

### Error Handling

- State save failures return explicit errors
- State load failures are handled gracefully (default state)
- All errors are bounded and explicit

### Resource Management

- Workspace state sizes are bounded (MAX_WORKSPACE_STATE_SIZE)
- State storage is atomic
- State operations are idempotent

---

## API Contract Pattern 5: Shell ↔ Core Services (Command Execution)

### Pattern Overview

**Purpose**: Grainscript Shell executes commands that interact with Core services.

**Flow**:
1. Shell receives command from user
2. Shell parses command
3. Shell identifies which Core service handles command
4. Shell calls Core service command handler
5. Core service executes command
6. Core service returns result
7. Shell displays result to user

### API Contract

```zig
// Core services provide command handlers
pub const CommandHandler = struct {
    name: []const u8,
    handler: *const fn (
        allocator: std.mem.Allocator,
        args: []const []const u8,
    ) !CommandResult,
};

pub const CommandResult = struct {
    success: bool,
    output: []const u8,
    error_message: ?[]const u8,
};

// Shell uses command handlers
pub fn execute_command(
    self: *Shell,
    command: []const u8,
    core_services: *CoreServicesRegistry,
) !CommandResult {
    // Parse command
    // Find command handler
    // Execute via Core service
    // Return result
}
```

### Error Handling

- Command parsing failures return explicit errors
- Command execution failures return `CommandResult` with `success = false`
- All errors are bounded and explicit

### Resource Management

- Command output sizes are bounded (MAX_COMMAND_OUTPUT_SIZE)
- Command arguments are bounded (MAX_COMMAND_ARGS)
- Command handlers are stateless

---

## Shared Resource Interfaces

### Resource Allocation Pattern

```zig
pub const ResourceAllocator = struct {
    allocator: std.mem.Allocator,
    max_resources: u32,
    current_count: u32,
    
    pub fn allocate(self: *ResourceAllocator) !ResourceHandle {
        std.debug.assert(self.current_count < self.max_resources);
        // Allocate resource
        self.current_count += 1;
        return handle;
    }
    
    pub fn deallocate(self: *ResourceAllocator, handle: ResourceHandle) void {
        std.debug.assert(self.current_count > 0);
        // Deallocate resource
        self.current_count -= 1;
    }
};
```

### Resource Cleanup Pattern

```zig
pub const ResourceManager = struct {
    resources: [MAX_RESOURCES]Resource,
    resources_len: u32,
    
    pub fn cleanup_all(self: *ResourceManager) void {
        var i: u32 = 0;
        while (i < self.resources_len) : (i += 1) {
            self.resources[i].cleanup();
        }
        self.resources_len = 0;
    }
};
```

---

## Error Propagation Patterns

### Explicit Error Types

```zig
pub const IntegrationError = error{
    AuthValidationFailed,
    FileTransferFailed,
    CredentialStorageFailed,
    WorkspaceStateFailed,
    CommandExecutionFailed,
};
```

### Error Handling Strategy

1. **Immediate Errors**: Return error immediately
2. **Retryable Errors**: Use retry logic with exponential backoff
3. **Fatal Errors**: Log and propagate to caller
4. **Recoverable Errors**: Return default/fallback value

---

## Performance Optimization Patterns

### Bounded Buffers

```zig
pub const BoundedBuffer = struct {
    buffer: [MAX_BUFFER_SIZE]u8,
    len: u32,
    
    pub fn append(self: *BoundedBuffer, data: []const u8) !void {
        std.debug.assert(self.len + data.len <= MAX_BUFFER_SIZE);
        // Append data
        self.len += @as(u32, @intCast(data.len));
    }
};
```

### Zero-Copy Patterns

```zig
pub fn process_request_zero_copy(
    request: *HttpRequest,
    handler: RouteHandler,
) !void {
    // Process request without copying data
    // Use slices and references
}
```

---

## Security Patterns

### Input Validation

```zig
pub fn validate_input(
    input: []const u8,
    max_len: u32,
) !void {
    std.debug.assert(input.len <= max_len);
    // Validate input format
    // Check for malicious patterns
}
```

### Secure Storage

```zig
pub fn encrypt_before_storage(
    data: []const u8,
    key: [32]u8,
) ![MAX_ENCRYPTED_SIZE]u8 {
    // Encrypt data before storage
    // Use authenticated encryption
}
```

---

## Testing Patterns

### Integration Test Structure

```zig
test "auth network integration" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    
    // Setup
    var auth_service = try AuthService.init(allocator);
    defer auth_service.deinit();
    
    var network_manager = try NetworkManager.init(allocator);
    defer network_manager.deinit();
    
    // Test
    const middleware = try auth_service.create_auth_middleware(allocator);
    try network_manager.register_route_with_auth(
        .POST,
        "/api/protected",
        handler_fn,
        middleware,
    );
    
    // Verify
    // ...
}
```

---

## Documentation Requirements

### API Contract Documentation

Each API contract must document:
1. **Purpose**: What the contract enables
2. **Flow**: Step-by-step interaction
3. **Function Signatures**: Complete function signatures
4. **Error Handling**: Error types and handling strategies
5. **Resource Management**: Resource allocation and cleanup
6. **Performance**: Performance characteristics and optimizations
7. **Security**: Security considerations
8. **Testing**: Test patterns and examples

---

## Implementation Checklist

### For Each API Contract

- [ ] Define function signatures
- [ ] Define error types
- [ ] Define resource management strategy
- [ ] Implement input validation
- [ ] Implement error handling
- [ ] Implement resource cleanup
- [ ] Write integration tests
- [ ] Document API contract
- [ ] Verify Grain Style compliance
- [ ] Profile performance
- [ ] Review security implications

---

## Notes

- All patterns follow Grain Style strictly
- All patterns use explicit `u32`/`u64` types
- All patterns use bounded allocations
- All patterns include error handling
- All patterns include resource cleanup
- Patterns are designed for cross-sub-agent integration
- Patterns support both Core services and sevenos integration

---

**Date**: 2026-01-02-004500-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: Design In Progress — Patterns Ready for L2 Sub-Agent Implementation

