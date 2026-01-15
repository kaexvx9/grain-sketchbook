# Core 1 Subcore: Integration Best Practices

**Date**: 2026-01-02-005500-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: 🆕 **GUIDE CREATED** — Best practices for Core 1 Subcore integration

---

## Executive Summary

This document provides best practices for integrating Core 1 Subcore L2 sub-agents (1a Auth, 1b Network, 1c Storage, 1d Compositor, 1e Grainscript Shell) and coordinating with other agents.

**Purpose**: Provide guidance and best practices for L2 sub-agents when implementing cross-sub-agent integration.

---

## Grain Style Best Practices

### Function Naming

**✅ Do**:
```zig
pub fn authenticate_user(...) !AuthResult { }
pub fn transfer_file(...) !void { }
pub fn save_workspace_state(...) !void { }
```

**❌ Don't**:
```zig
pub fn AuthenticateUser(...) !AuthResult { }  // PascalCase
pub fn transferFile(...) !void { }  // camelCase
```

### Type Usage

**✅ Do**:
```zig
const buffer_size: u32 = 4096;
const file_size: u64 = 1_048_576;
const user_id: u64 = 12345;
```

**❌ Don't**:
```zig
const buffer_size: usize = 4096;  // Platform-dependent
const file_size: isize = 1_048_576;  // Signed, platform-dependent
```

### Bounded Allocations

**✅ Do**:
```zig
pub const MAX_BUFFER_SIZE: u32 = 4096;
pub const MAX_FILE_SIZE: u64 = 10_485_760;  // 10 MB

var buffer: [MAX_BUFFER_SIZE]u8 = undefined;
```

**❌ Don't**:
```zig
var buffer = try allocator.alloc(u8, size);  // Unbounded
```

### Assertions

**✅ Do**:
```zig
pub fn process_data(data: []const u8) !void {
    std.debug.assert(data.len > 0);  // Precondition
    std.debug.assert(data.len <= MAX_DATA_SIZE);  // Precondition
    
    // Process data
    
    std.debug.assert(result.len <= MAX_RESULT_SIZE);  // Postcondition
}
```

**❌ Don't**:
```zig
pub fn process_data(data: []const u8) !void {
    // No assertions
    // Process data
}
```

### Function Length

**✅ Do**: Keep functions ≤70 lines
```zig
pub fn authenticate_user(...) !AuthResult {
    // Function body ≤70 lines
    // Extract helpers if needed
}
```

**❌ Don't**: Functions >70 lines
```zig
pub fn authenticate_user(...) !AuthResult {
    // 100+ lines of code
    // Should be refactored
}
```

### Line Length

**✅ Do**: Keep lines ≤100 characters
```zig
pub fn transfer_file(
    source: []const u8,
    destination: []const u8,
) !void {
    // Lines ≤100 characters
}
```

**❌ Don't**: Lines >100 characters
```zig
pub fn transfer_file(source_path: []const u8, destination_path: []const u8, options: TransferOptions) !void {
    // Line >100 characters
}
```

---

## Integration Best Practices

### API Contract Design

**✅ Do**:
- Define explicit function signatures
- Use bounded types (`u32`/`u64`)
- Include error handling
- Document all parameters and return values
- Provide examples

**❌ Don't**:
- Use platform-dependent types (`usize`/`isize`)
- Skip error handling
- Leave parameters undocumented
- Use unbounded allocations

### Error Handling

**✅ Do**:
```zig
pub const IntegrationError = error{
    AuthValidationFailed,
    FileTransferFailed,
    CredentialStorageFailed,
};

pub fn transfer_file(...) IntegrationError!void {
    // Explicit error handling
    validate_input() catch |err| {
        return err;
    };
}
```

**❌ Don't**:
```zig
pub fn transfer_file(...) !void {
    // Silent error handling
    validate_input() catch {
        return;  // No error information
    };
}
```

### Resource Management

**✅ Do**:
```zig
pub fn process_with_cleanup(...) !void {
    var resource = try allocate_resource();
    errdefer cleanup_resource(&resource);
    
    // Use resource
    try use_resource(&resource);
    
    // Cleanup on success
    cleanup_resource(&resource);
}
```

**❌ Don't**:
```zig
pub fn process_with_cleanup(...) !void {
    var resource = try allocate_resource();
    // Use resource
    // No cleanup on error
}
```

### Input Validation

**✅ Do**:
```zig
pub fn process_input(input: []const u8) !void {
    std.debug.assert(input.len > 0);
    std.debug.assert(input.len <= MAX_INPUT_SIZE);
    
    // Validate input format
    if (!is_valid_format(input)) {
        return error.InvalidInput;
    }
    
    // Process input
}
```

**❌ Don't**:
```zig
pub fn process_input(input: []const u8) !void {
    // No validation
    // Process input directly
}
```

---

## Coordination Best Practices

### Check-In Before Integration

**✅ Do**:
- Check in with Core 1 Subcore before starting integration work
- Coordinate API contract changes
- Discuss breaking changes early
- Provide status updates regularly

**❌ Don't**:
- Start integration work without coordination
- Make breaking changes without notice
- Skip status updates
- Work in isolation

### Documentation Updates

**✅ Do**:
- Update coordination documents after each work session
- Update plan documents as implementation evolves
- Update tasks documents as tasks are completed
- Inform Core 1 Subcore about general summary updates

**❌ Don't**:
- Skip documentation updates
- Leave outdated information
- Forget to inform Core 1 Subcore
- Document inconsistently

### Test Requirements

**✅ Do**:
- Write integration tests for all API contracts
- Ensure all tests pass before integration
- Test error handling paths
- Test resource cleanup
- Test performance characteristics

**❌ Don't**:
- Skip integration tests
- Ignore failing tests
- Test only happy paths
- Skip performance testing

---

## Performance Best Practices

### Minimize Allocations

**✅ Do**:
```zig
// Use stack-allocated buffers
var buffer: [MAX_BUFFER_SIZE]u8 = undefined;
process_data(&buffer) catch |err| {
    return err;
};
```

**❌ Don't**:
```zig
// Unnecessary heap allocation
var buffer = try allocator.alloc(u8, size);
defer allocator.free(buffer);
```

### Use Zero-Copy Patterns

**✅ Do**:
```zig
// Use slices and references
pub fn process_request(request: *HttpRequest) !void {
    const body = request.body;  // Reference, no copy
    process_body(body) catch |err| {
        return err;
    };
}
```

**❌ Don't**:
```zig
// Unnecessary copying
pub fn process_request(request: *HttpRequest) !void {
    var body_copy = try allocator.dupe(u8, request.body);
    defer allocator.free(body_copy);
    process_body(body_copy) catch |err| {
        return err;
    };
}
```

### Connection Pooling

**✅ Do**:
```zig
// Reuse connections
pub const ConnectionPool = struct {
    connections: [MAX_CONNECTIONS]Connection,
    connections_len: u32,
    
    pub fn get_connection(self: *ConnectionPool) !*Connection {
        // Reuse existing connection if available
        if (self.connections_len < MAX_CONNECTIONS) {
            return &self.connections[self.connections_len];
        }
        return error.ConnectionPoolExhausted;
    }
};
```

**❌ Don't**:
```zig
// Create new connection for each request
pub fn make_request(...) !void {
    var conn = try create_connection();  // New connection each time
    defer close_connection(&conn);
    // Use connection
}
```

---

## Security Best Practices

### Input Validation

**✅ Do**:
```zig
pub fn validate_input(input: []const u8) !void {
    std.debug.assert(input.len <= MAX_INPUT_SIZE);
    
    // Check for malicious patterns
    if (contains_malicious_pattern(input)) {
        return error.InvalidInput;
    }
    
    // Validate format
    if (!is_valid_format(input)) {
        return error.InvalidFormat;
    }
}
```

**❌ Don't**:
```zig
pub fn validate_input(input: []const u8) !void {
    // No validation
    // Trust input blindly
}
```

### Secure Storage

**✅ Do**:
```zig
// Encrypt before storage
pub fn store_credentials(
    credentials: []const u8,
    key: [32]u8,
) !void {
    var encrypted: [MAX_ENCRYPTED_SIZE]u8 = undefined;
    encrypt_data(credentials, key, &encrypted) catch |err| {
        return err;
    };
    
    // Store encrypted data
    try storage.save(&encrypted);
}
```

**❌ Don't**:
```zig
// Store plaintext
pub fn store_credentials(credentials: []const u8) !void {
    // Store without encryption
    try storage.save(credentials);
}
```

### Authentication

**✅ Do**:
```zig
// Validate token before processing
pub fn process_authenticated_request(
    request: *HttpRequest,
    auth_service: *AuthService,
) !void {
    const token = extract_token(request) orelse {
        return error.MissingToken;
    };
    
    const auth_result = try auth_service.validate_token(token);
    if (!auth_result.authenticated) {
        return error.AuthenticationFailed;
    }
    
    // Process authenticated request
}
```

**❌ Don't**:
```zig
// Skip authentication
pub fn process_authenticated_request(request: *HttpRequest) !void {
    // No authentication check
    // Process request directly
}
```

---

## Testing Best Practices

### Test Structure

**✅ Do**:
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
    try testing.expect(route_registered);
}
```

**❌ Don't**:
```zig
test "auth network integration" {
    // No setup
    // No cleanup
    // No verification
    // Just call functions
}
```

### Test Isolation

**✅ Do**:
```zig
// Use test isolation
var isolation = TestIsolation.init(allocator, setup_fn, teardown_fn);
try isolation.run_isolated(test_fn);
```

**❌ Don't**:
```zig
// Share state between tests
var global_state: GlobalState = undefined;

test "test 1" {
    global_state.value = 1;
}

test "test 2" {
    // Depends on test 1
    try testing.expect(global_state.value == 1);
}
```

### Error Path Testing

**✅ Do**:
```zig
test "auth validation failure" {
    // Test error handling
    const result = auth_service.validate_token(invalid_token);
    try testing.expectError(error.InvalidToken, result);
}
```

**❌ Don't**:
```zig
test "auth validation" {
    // Only test happy path
    const result = try auth_service.validate_token(valid_token);
    try testing.expect(result.authenticated == true);
}
```

---

## Documentation Best Practices

### Function Documentation

**✅ Do**:
```zig
/// Authenticate user with credentials.
///
/// Parameters:
/// - username: User username (max 256 characters)
/// - password: User password (max 256 characters)
///
/// Returns:
/// - AuthResult with authentication status and user_id
///
/// Errors:
/// - InvalidCredentials: Username or password incorrect
/// - AccountLocked: Account locked due to too many failed attempts
///
/// Example:
/// ```zig
/// const result = try auth_service.authenticate_user("user", "pass");
/// if (result.authenticated) {
///     std.debug.print("User ID: {}\n", .{result.user_id});
/// }
/// ```
pub fn authenticate_user(
    self: *AuthService,
    username: []const u8,
    password: []const u8,
) !AuthResult {
    // Implementation
}
```

**❌ Don't**:
```zig
// Authenticate user
pub fn authenticate_user(...) !AuthResult {
    // No documentation
}
```

### API Contract Documentation

**✅ Do**:
- Document purpose and flow
- Document function signatures
- Document error handling
- Document resource management
- Provide examples

**❌ Don't**:
- Skip documentation
- Leave parameters undocumented
- Skip error documentation
- Skip examples

---

## Common Pitfalls to Avoid

### ❌ Platform-Dependent Types

**Problem**: Using `usize`/`isize` causes cross-platform issues.

**Solution**: Always use explicit `u32`/`u64` types.

### ❌ Unbounded Allocations

**Problem**: Unbounded allocations can cause memory exhaustion.

**Solution**: Always use bounded allocations with MAX_ constants.

### ❌ Missing Error Handling

**Problem**: Missing error handling causes silent failures.

**Solution**: Always handle errors explicitly.

### ❌ Resource Leaks

**Problem**: Not cleaning up resources causes leaks.

**Solution**: Always use `errdefer` and cleanup functions.

### ❌ Skipping Tests

**Problem**: Skipping tests causes integration issues.

**Solution**: Always write and run integration tests.

### ❌ Breaking Changes Without Coordination

**Problem**: Breaking changes without coordination causes conflicts.

**Solution**: Always coordinate breaking changes with Core 1 Subcore.

---

## Summary

**Key Best Practices**:
1. ✅ Follow Grain Style strictly
2. ✅ Use explicit `u32`/`u64` types
3. ✅ Use bounded allocations
4. ✅ Handle errors explicitly
5. ✅ Clean up resources
6. ✅ Write integration tests
7. ✅ Coordinate before integration
8. ✅ Update documentation
9. ✅ Validate input
10. ✅ Secure storage and authentication

**Reference Documents**:
- Grain Style: `~/xy-mathematics/docs/grain_style.md`
- API Contract Patterns: `docs/core-coordination/core_1_subcore_api_contract_patterns_2026-01-02-004500-pst.md`
- Architecture Overview: `docs/core-coordination/core_1_subcore_architecture_overview_2026-01-02-005000-pst.md`

---

**Date**: 2026-01-02-005500-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: Guide Complete — Ready for L2 Sub-Agent Reference

