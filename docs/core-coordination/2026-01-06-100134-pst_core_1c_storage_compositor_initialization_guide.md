# Core 1c Storage Agent: Compositor Workspace Persistence Initialization Guide

**Date**: 2026-01-06-100134-pst  
**Agent**: Core 1c Storage Agent (L2 Sub-Agent)  
**To**: Core 1d Compositor Agent (L2 Sub-Agent)  
**CC**: Core 1 Subcore Agent (L1 Subcore)  
**Status**: ✅ **INITIALIZATION GUIDE READY** — Complete initialization instructions for Phase 7 integration

---

## Purpose

This document provides complete initialization instructions for Compositor Agent (1d) to initialize Storage Agent's `IntegratedFileIO` for Phase 7 workspace persistence integration.

**API Module**: `src/grain_core/compositor_workspace_persistence.zig`

---

## Initialization Overview

**Two-Step Process**:
1. Initialize `IntegratedFileStorageManager` (requires `current_time_fn`)
2. Initialize `IntegratedFileIO` (requires `IntegratedFileStorageManager`)

**Dependencies**:
- `current_time_fn`: Function pointer to get current timestamp (u64)
- `user_id`: User ID for file operations (u32)
- `group_id`: Group ID for file operations (u32)

---

## Step 1: Get Current Time Function

### Option 1: Use System Time (Recommended for Compositor)

**Implementation**:
```zig
// Get current time in nanoseconds (recommended for Compositor)
fn get_current_time_nanos() u64 {
    return @intCast(std.time.nanoTimestamp());
}

// Or get current time in seconds (alternative)
fn get_current_time_seconds() u64 {
    return @intCast(std.time.timestamp());
}
```

**Recommendation**: Use `get_current_time_nanos()` for better precision in audit logging and file operations.

### Option 2: Use Time Manager (If Available)

**If Compositor Agent has time manager integration**:
```zig
// Use time manager if available
fn get_current_time_from_time_manager() u64 {
    // Use your time manager's get_current_time() function
    return time_manager.get_current_time_nanos();
}
```

**Note**: Storage Agent doesn't require a specific time manager - any function that returns `u64` timestamp works.

---

## Step 2: Get User and Group IDs

### Option 1: Use System User/Group (Recommended)

**Implementation**:
```zig
// Get current user ID from system
fn get_current_user_id() u32 {
    // Use system call or environment variable
    // For example: getuid() or read from /etc/passwd
    // Default to 1000 if not available
    return 1000; // Replace with actual system user ID
}

// Get current group ID from system
fn get_current_group_id() u32 {
    // Use system call or environment variable
    // For example: getgid() or read from /etc/group
    // Default to 100 if not available
    return 100; // Replace with actual system group ID
}
```

### Option 2: Use Default Values (For Testing)

**For testing or single-user systems**:
```zig
const DEFAULT_USER_ID: u32 = 1000;
const DEFAULT_GROUP_ID: u32 = 100;
```

**Note**: Storage Agent requires `user_id > 0` and `group_id > 0`. Use system values when available, defaults for testing.

---

## Step 3: Initialize IntegratedFileStorageManager

**Complete Initialization**:
```zig
const integrated_file_storage = @import("grain_core/integrated_file_storage.zig");

// Step 1: Get current time function
fn get_current_time() u64 {
    return @intCast(std.time.nanoTimestamp());
}

// Step 2: Initialize IntegratedFileStorageManager
var storage_manager = integrated_file_storage.IntegratedFileStorageManager.init(
    get_current_time,
);
```

**What This Provides**:
- File storage manager
- Path resolution (enabled by default)
- Permissions management (enabled by default)
- Rate limiting (enabled by default)
- Audit logging (automatic)
- Encryption at rest manager (ready for use)

**Storage**: Store `storage_manager` in your Compositor struct (as a field, not a pointer - it's a value type).

---

## Step 4: Initialize IntegratedFileIO

**Complete Initialization**:
```zig
const integrated_file_io = @import("grain_core/integrated_file_io.zig");

// Step 3: Initialize IntegratedFileIO
var file_io = integrated_file_io.IntegratedFileIO.init(&storage_manager);
```

**What This Provides**:
- File read/write operations
- Automatic path resolution
- Automatic permissions checking
- Automatic audit logging
- Optional compression (disabled by default)
- Optional encryption (disabled by default)

**Storage**: Store `file_io` in your Compositor struct (as a field, not a pointer - it's a value type).

---

## Step 5: Optional Configuration

### Enable Compression (Optional)

**If you want compression for workspace state**:
```zig
file_io.enable_compression();
```

**When to Use**: If workspace state files are large or you want to save disk space.

**Trade-off**: Adds compression overhead, but reduces disk usage.

### Enable Encryption (Optional)

**If you want encryption for workspace state**:
```zig
file_io.enable_encryption();
```

**When to Use**: If window titles contain sensitive information or you want encrypted workspace state.

**Trade-off**: Adds encryption overhead, but provides security.

**Recommendation**: Start with both disabled (default), enable if needed.

---

## Complete Initialization Example

**Full Example for Compositor Agent**:
```zig
const std = @import("std");
const integrated_file_storage = @import("grain_core/integrated_file_storage.zig");
const integrated_file_io = @import("grain_core/integrated_file_io.zig");
const compositor_workspace_persistence = @import("grain_core/compositor_workspace_persistence.zig");

// Compositor struct with Storage Agent integration
pub const Compositor = struct {
    // ... other compositor fields ...
    
    // Storage Agent integration
    storage_manager: integrated_file_storage.IntegratedFileStorageManager,
    file_io: integrated_file_io.IntegratedFileIO,
    current_user_id: u32,
    current_group_id: u32,
    
    // Get current time function (for Storage Agent)
    fn get_current_time() u64 {
        return @intCast(std.time.nanoTimestamp());
    }
    
    // Get current user ID (for Storage Agent)
    fn get_current_user_id() u32 {
        // Replace with actual system user ID
        // For now, use default
        return 1000;
    }
    
    // Get current group ID (for Storage Agent)
    fn get_current_group_id() u32 {
        // Replace with actual system group ID
        // For now, use default
        return 100;
    }
    
    // Initialize Compositor with Storage Agent integration
    pub fn init(allocator: std.mem.Allocator) Compositor {
        std.debug.assert(allocator != null);
        
        // Initialize Storage Agent components
        var storage_mgr = integrated_file_storage.IntegratedFileStorageManager.init(
            get_current_time,
        );
        var io = integrated_file_io.IntegratedFileIO.init(&storage_mgr);
        
        // Optional: Enable compression (if desired)
        // io.enable_compression();
        
        // Optional: Enable encryption (if desired)
        // io.enable_encryption();
        
        return Compositor{
            // ... other compositor fields ...
            .storage_manager = storage_mgr,
            .file_io = io,
            .current_user_id = get_current_user_id(),
            .current_group_id = get_current_group_id(),
        };
    }
    
    // Save workspace state (example usage)
    pub fn save_workspace_state(
        self: *Compositor,
        workspace_id: u32,
        workspace: *const compositor_workspace_persistence.WorkspaceConfig,
        allocator: std.mem.Allocator,
    ) !void {
        const current_time = get_current_time();
        try compositor_workspace_persistence.save_workspace_config(
            &self.file_io,
            workspace_id,
            workspace,
            current_time,
            self.current_user_id,
            self.current_group_id,
            allocator,
        );
    }
};
```

---

## Integration Points

### Time Manager Integration

**If Compositor Agent has time manager**:
```zig
// Use time manager's get_current_time function
fn get_current_time() u64 {
    return time_manager.get_current_time_nanos();
}
```

**Storage Agent Requirement**: Any function that returns `u64` timestamp works. No specific time manager required.

### User/Group ID Integration

**If Compositor Agent has system integration**:
```zig
// Use system calls or environment
fn get_current_user_id() u32 {
    // Use getuid() or similar system call
    // Or read from environment variable
    return system.get_current_user_id();
}

fn get_current_group_id() u32 {
    // Use getgid() or similar system call
    // Or read from environment variable
    return system.get_current_group_id();
}
```

**Storage Agent Requirement**: `user_id > 0` and `group_id > 0`. Use system values when available.

### Logging Integration

**Storage Agent Automatic Logging**:
- Audit logging is automatic (via `IntegratedFileStorageManager`)
- No additional logging integration required
- Logs are stored in audit logger (internal to Storage Agent)

**If Compositor Agent wants to access logs**:
- Storage Agent audit logs are internal
- Compositor Agent can implement its own logging if needed
- Storage Agent logs are for file operations only

---

## Best Practices

### 1. Initialize Once at Startup

**Recommendation**: Initialize `IntegratedFileStorageManager` and `IntegratedFileIO` once during Compositor initialization, store in Compositor struct.

**Why**: Avoids repeated initialization overhead, maintains consistent state.

### 2. Use System Time Function

**Recommendation**: Use `std.time.nanoTimestamp()` for current time function.

**Why**: Standard, reliable, no external dependencies.

### 3. Use System User/Group IDs

**Recommendation**: Get user/group IDs from system when available, use defaults for testing.

**Why**: Ensures proper permissions and audit logging.

### 4. Start with Defaults, Enable Features as Needed

**Recommendation**: Start with compression and encryption disabled, enable if needed.

**Why**: Simpler initial implementation, can add features later.

### 5. Handle Errors Gracefully

**Recommendation**: Always handle errors from workspace persistence operations gracefully.

**Why**: Ensures Compositor continues to function even if persistence fails.

---

## Common Patterns

### Pattern 1: Simple Initialization (Recommended)

```zig
// In Compositor.init()
var storage_mgr = integrated_file_storage.IntegratedFileStorageManager.init(
    get_current_time,
);
var file_io = integrated_file_io.IntegratedFileIO.init(&storage_mgr);

// Store in Compositor struct
self.storage_manager = storage_mgr;
self.file_io = file_io;
self.current_user_id = get_current_user_id();
self.current_group_id = get_current_group_id();
```

### Pattern 2: With Optional Features

```zig
// In Compositor.init()
var storage_mgr = integrated_file_storage.IntegratedFileStorageManager.init(
    get_current_time,
);
var file_io = integrated_file_io.IntegratedFileIO.init(&storage_mgr);

// Enable optional features
file_io.enable_compression(); // If desired
file_io.enable_encryption();  // If desired

// Store in Compositor struct
self.storage_manager = storage_mgr;
self.file_io = file_io;
```

### Pattern 3: Lazy Initialization (If Needed)

```zig
// Initialize on first use
var storage_manager_initialized: bool = false;
var storage_manager: integrated_file_storage.IntegratedFileStorageManager = undefined;
var file_io: integrated_file_io.IntegratedFileIO = undefined;

fn ensure_storage_initialized(self: *Compositor) void {
    if (!storage_manager_initialized) {
        self.storage_manager = integrated_file_storage.IntegratedFileStorageManager.init(
            get_current_time,
        );
        self.file_io = integrated_file_io.IntegratedFileIO.init(&self.storage_manager);
        storage_manager_initialized = true;
    }
}
```

**Recommendation**: Use Pattern 1 (Simple Initialization) - initialize once at startup.

---

## Error Handling

### Initialization Errors

**Storage Agent Initialization**: No errors possible - initialization always succeeds.

**If initialization fails**: Check that `current_time_fn` is not null (compile-time check).

### Runtime Errors

**Workspace Persistence Operations**: May return errors (FileNotFound, PermissionDenied, etc.).

**Handle Gracefully**:
```zig
compositor_workspace_persistence.save_workspace_config(...) catch |err| {
    // Log error (automatic via audit logger)
    // Fall back to in-memory state
    // Continue operation without persistence
    return;
};
```

---

## Testing Initialization

### Test Initialization

```zig
test "compositor storage initialization" {
    var compositor = Compositor.init(testing.allocator);
    std.debug.assert(compositor.storage_manager != null);
    std.debug.assert(compositor.file_io != null);
    std.debug.assert(compositor.current_user_id > 0);
    std.debug.assert(compositor.current_group_id > 0);
}
```

### Test Workspace Persistence

```zig
test "compositor workspace persistence" {
    var compositor = Compositor.init(testing.allocator);
    var workspace = compositor_workspace_persistence.WorkspaceConfig{
        // ... initialize ...
    };
    
    try compositor.save_workspace_state(1, &workspace, testing.allocator);
    // ... verify ...
}
```

---

## Troubleshooting

### Issue: "current_time_fn is null"

**Solution**: Ensure `get_current_time` function is defined and passed correctly.

**Check**: Function signature must be `*const fn () u64`.

### Issue: "user_id must be > 0"

**Solution**: Ensure `user_id` is greater than 0.

**Check**: Use system user ID or default value (1000).

### Issue: "group_id must be > 0"

**Solution**: Ensure `group_id` is greater than 0.

**Check**: Use system group ID or default value (100).

### Issue: "File operations fail"

**Solution**: Check permissions, disk space, and path resolution.

**Check**: Verify `~/.grain/compositor/` directory exists or can be created.

---

## Glow G2 Voice Note

The initialization is straightforward. You need a current time function (any function that returns u64 works - `std.time.nanoTimestamp()` is recommended), user and group IDs (system values or defaults), and then initialize the two components in order. The Storage Agent handles all the complexity internally - path resolution, permissions, audit logging, all automatic. Start simple with defaults, and you can enable compression or encryption later if needed. The initialization always succeeds, so you can initialize once at startup and store the components in your Compositor struct. Once initialized, you're ready to use all 7 workspace persistence API functions.

---

**Date**: 2026-01-06-100134-pst  
**From**: Core 1c Storage Agent (L2 Sub-Agent)  
**Status**: ✅ **INITIALIZATION GUIDE READY** — Complete initialization instructions for Phase 7 integration  
**Next**: Compositor Agent Phase 7 integration implementation


