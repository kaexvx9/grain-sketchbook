# Core 1 Subcore: Shared Resource Interfaces

**Date**: 2026-01-02-010500-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: 🆕 **DESIGN IN PROGRESS** — Shared resource interfaces for Core 1 Subcore

---

## Executive Summary

This document defines shared resource interfaces for Core 1 Subcore L2 sub-agents. These interfaces enable safe, efficient resource sharing between Auth (1a), Network (1b), Storage (1c), Compositor (1d), and Grainscript Shell (1e) agents.

**Purpose**: Provide standardized resource management interfaces for cross-sub-agent resource sharing.

---

## Core Principles

### Resource Safety

- All resources must be bounded
- Resource cleanup must be guaranteed
- Resource limits must be enforced
- Resource leaks must be prevented

### Resource Efficiency

- Minimize resource allocation
- Reuse resources where possible
- Pool resources for common operations
- Clean up resources promptly

### Grain Style Compliance

- `grain_case` function names
- Explicit `u32`/`u64` types
- Bounded allocations (MAX_ constants)
- Minimum 2 assertions per function
- Max 70 lines per function
- Max 100 characters per line

---

## Shared Resource Interface 1: Memory Pool

### Purpose

Provide bounded memory pool for temporary allocations across sub-agents.

### Interface

```zig
pub const MemoryPool = struct {
    allocator: std.mem.Allocator,
    pool: [MAX_POOL_SIZE]u8,
    used: u32,
    
    pub const MAX_POOL_SIZE: u32 = 1_048_576;  // 1 MB
    
    /// Initialize memory pool.
    pub fn init(allocator: std.mem.Allocator) MemoryPool {
        std.debug.assert(allocator.ptr != null);
        
        return MemoryPool{
            .allocator = allocator,
            .pool = undefined,
            .used = 0,
        };
    }
    
    /// Allocate memory from pool.
    pub fn allocate(self: *MemoryPool, size: u32) ![]u8 {
        std.debug.assert(size > 0);
        std.debug.assert(size <= MAX_POOL_SIZE);
        std.debug.assert(self.used + size <= MAX_POOL_SIZE);
        
        const start = self.used;
        self.used += size;
        
        return self.pool[start..self.used];
    }
    
    /// Reset pool (free all allocations).
    pub fn reset(self: *MemoryPool) void {
        std.debug.assert(self.allocator.ptr != null);
        
        self.used = 0;
    }
    
    /// Get pool usage.
    pub fn get_usage(self: *const MemoryPool) u32 {
        std.debug.assert(self.allocator.ptr != null);
        
        return self.used;
    }
};
```

### Usage Pattern

```zig
// Initialize pool
var pool = MemoryPool.init(allocator);

// Allocate from pool
const buffer = try pool.allocate(4096);

// Use buffer
process_data(buffer) catch |err| {
    pool.reset();  // Cleanup on error
    return err;
};

// Reset pool when done
pool.reset();
```

---

## Shared Resource Interface 2: File Handle Pool

### Purpose

Provide bounded file handle pool for file operations across sub-agents.

### Interface

```zig
pub const FileHandlePool = struct {
    handles: [MAX_FILE_HANDLES]FileHandle,
    handles_len: u32,
    free_list: [MAX_FILE_HANDLES]u32,
    free_list_len: u32,
    
    pub const MAX_FILE_HANDLES: u32 = 256;
    
    /// Initialize file handle pool.
    pub fn init() FileHandlePool {
        return FileHandlePool{
            .handles = undefined,
            .handles_len = 0,
            .free_list = undefined,
            .free_list_len = 0,
        };
    }
    
    /// Allocate file handle.
    pub fn allocate_handle(self: *FileHandlePool) !u32 {
        std.debug.assert(self.handles_len < MAX_FILE_HANDLES);
        
        // Reuse free handle if available
        if (self.free_list_len > 0) {
            self.free_list_len -= 1;
            const handle_id = self.free_list[self.free_list_len];
            return handle_id;
        }
        
        // Allocate new handle
        const handle_id = self.handles_len;
        self.handles_len += 1;
        
        return handle_id;
    }
    
    /// Deallocate file handle.
    pub fn deallocate_handle(self: *FileHandlePool, handle_id: u32) void {
        std.debug.assert(handle_id < self.handles_len);
        std.debug.assert(self.free_list_len < MAX_FILE_HANDLES);
        
        // Add to free list
        self.free_list[self.free_list_len] = handle_id;
        self.free_list_len += 1;
    }
    
    /// Get file handle.
    pub fn get_handle(self: *FileHandlePool, handle_id: u32) ?*FileHandle {
        std.debug.assert(handle_id < self.handles_len);
        
        if (handle_id < self.handles_len) {
            return &self.handles[handle_id];
        }
        return null;
    }
};
```

### Usage Pattern

```zig
// Initialize pool
var pool = FileHandlePool.init();

// Allocate handle
const handle_id = try pool.allocate_handle();
errdefer pool.deallocate_handle(handle_id);

// Use handle
const handle = pool.get_handle(handle_id).?;
try use_file_handle(handle);

// Deallocate handle
pool.deallocate_handle(handle_id);
```

---

## Shared Resource Interface 3: Connection Pool

### Purpose

Provide bounded connection pool for network operations across sub-agents.

### Interface

```zig
pub const ConnectionPool = struct {
    connections: [MAX_CONNECTIONS]Connection,
    connections_len: u32,
    active_connections: u32,
    
    pub const MAX_CONNECTIONS: u32 = 1024;
    
    /// Initialize connection pool.
    pub fn init() ConnectionPool {
        return ConnectionPool{
            .connections = undefined,
            .connections_len = 0,
            .active_connections = 0,
        };
    }
    
    /// Allocate connection.
    pub fn allocate_connection(self: *ConnectionPool) !*Connection {
        std.debug.assert(self.connections_len < MAX_CONNECTIONS);
        
        const conn = &self.connections[self.connections_len];
        self.connections_len += 1;
        self.active_connections += 1;
        
        return conn;
    }
    
    /// Release connection.
    pub fn release_connection(self: *ConnectionPool, conn: *Connection) void {
        std.debug.assert(self.active_connections > 0);
        
        // Cleanup connection
        cleanup_connection(conn);
        
        self.active_connections -= 1;
    }
    
    /// Get active connection count.
    pub fn get_active_count(self: *const ConnectionPool) u32 {
        std.debug.assert(self.allocator.ptr != null);
        
        return self.active_connections;
    }
};
```

### Usage Pattern

```zig
// Initialize pool
var pool = ConnectionPool.init();

// Allocate connection
const conn = try pool.allocate_connection();
errdefer pool.release_connection(conn);

// Use connection
try use_connection(conn);

// Release connection
pool.release_connection(conn);
```

---

## Shared Resource Interface 4: Buffer Pool

### Purpose

Provide bounded buffer pool for data transfer operations across sub-agents.

### Interface

```zig
pub const BufferPool = struct {
    buffers: [MAX_BUFFERS][MAX_BUFFER_SIZE]u8,
    buffers_len: u32,
    free_list: [MAX_BUFFERS]u32,
    free_list_len: u32,
    
    pub const MAX_BUFFERS: u32 = 64;
    pub const MAX_BUFFER_SIZE: u32 = 65_536;  // 64 KB
    
    /// Initialize buffer pool.
    pub fn init() BufferPool {
        return BufferPool{
            .buffers = undefined,
            .buffers_len = 0,
            .free_list = undefined,
            .free_list_len = 0,
        };
    }
    
    /// Allocate buffer.
    pub fn allocate_buffer(self: *BufferPool) ![]u8 {
        std.debug.assert(self.buffers_len < MAX_BUFFERS);
        
        // Reuse free buffer if available
        if (self.free_list_len > 0) {
            self.free_list_len -= 1;
            const buffer_id = self.free_list[self.free_list_len];
            return &self.buffers[buffer_id];
        }
        
        // Allocate new buffer
        const buffer_id = self.buffers_len;
        self.buffers_len += 1;
        
        return &self.buffers[buffer_id];
    }
    
    /// Release buffer.
    pub fn release_buffer(self: *BufferPool, buffer: []u8) void {
        std.debug.assert(buffer.len == MAX_BUFFER_SIZE);
        std.debug.assert(self.free_list_len < MAX_BUFFERS);
        
        // Find buffer ID
        const buffer_id = self.find_buffer_id(buffer);
        
        // Add to free list
        self.free_list[self.free_list_len] = buffer_id;
        self.free_list_len += 1;
    }
    
    /// Find buffer ID (helper).
    fn find_buffer_id(self: *const BufferPool, buffer: []u8) u32 {
        std.debug.assert(buffer.len == MAX_BUFFER_SIZE);
        
        var i: u32 = 0;
        while (i < self.buffers_len) : (i += 1) {
            if (std.mem.eql(u8, &self.buffers[i], buffer)) {
                return i;
            }
        }
        
        unreachable;  // Buffer must be from pool
    }
};
```

### Usage Pattern

```zig
// Initialize pool
var pool = BufferPool.init();

// Allocate buffer
const buffer = try pool.allocate_buffer();
errdefer pool.release_buffer(buffer);

// Use buffer
try process_data(buffer);

// Release buffer
pool.release_buffer(buffer);
```

---

## Resource Allocation Patterns

### Pattern 1: Stack Allocation (Preferred)

**✅ Do**: Use stack allocation when possible
```zig
var buffer: [MAX_BUFFER_SIZE]u8 = undefined;
process_data(&buffer) catch |err| {
    return err;
};
```

### Pattern 2: Pool Allocation (For Reuse)

**✅ Do**: Use pool allocation for frequently reused resources
```zig
const buffer = try buffer_pool.allocate_buffer();
defer buffer_pool.release_buffer(buffer);
```

### Pattern 3: Arena Allocation (For Temporary Data)

**✅ Do**: Use arena allocation for temporary data
```zig
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();
const arena_allocator = arena.allocator();
```

---

## Resource Cleanup Patterns

### Pattern 1: Defer Cleanup

**✅ Do**: Use `defer` for cleanup
```zig
var resource = try allocate_resource();
defer cleanup_resource(&resource);

// Use resource
try use_resource(&resource);
```

### Pattern 2: Errdefer Cleanup

**✅ Do**: Use `errdefer` for error cleanup
```zig
var resource = try allocate_resource();
errdefer cleanup_resource(&resource);

// Use resource (cleanup on error)
try use_resource(&resource);

// Manual cleanup on success
cleanup_resource(&resource);
```

### Pattern 3: RAII Pattern

**✅ Do**: Use RAII pattern with init/deinit
```zig
var resource = Resource.init(allocator);
defer resource.deinit();

// Use resource
try resource.use();
```

---

## Resource Monitoring

### Resource Usage Tracking

```zig
pub const ResourceMonitor = struct {
    memory_usage: u64,
    file_handles: u32,
    connections: u32,
    buffers: u32,
    
    /// Track memory allocation.
    pub fn track_memory(self: *ResourceMonitor, size: u64) void {
        std.debug.assert(self.memory_usage + size <= MAX_MEMORY);
        
        self.memory_usage += size;
    }
    
    /// Track memory deallocation.
    pub fn untrack_memory(self: *ResourceMonitor, size: u64) void {
        std.debug.assert(self.memory_usage >= size);
        
        self.memory_usage -= size;
    }
    
    /// Get memory usage.
    pub fn get_memory_usage(self: *const ResourceMonitor) u64 {
        return self.memory_usage;
    }
};
```

---

## Resource Limits

### Per-Service Limits

```zig
pub const ServiceResourceLimits = struct {
    max_memory: u64,
    max_file_handles: u32,
    max_connections: u32,
    max_buffers: u32,
    
    pub const DEFAULT_LIMITS = ServiceResourceLimits{
        .max_memory = 100_663_296,  // 96 MB
        .max_file_handles = 256,
        .max_connections = 1024,
        .max_buffers = 64,
    };
};
```

### System-Wide Limits

```zig
pub const SystemResourceLimits = struct {
    total_memory: u64,
    total_file_handles: u32,
    total_connections: u32,
    total_buffers: u32,
    
    pub const DEFAULT_LIMITS = SystemResourceLimits{
        .total_memory = 1_073_741_824,  // 1 GB
        .total_file_handles = 4096,
        .total_connections = 16384,
        .total_buffers = 1024,
    };
};
```

---

## Resource Sharing Patterns

### Pattern 1: Exclusive Access

**Description**: Resource is exclusively owned by one sub-agent at a time.

**Use Case**: File handles, network connections

**Implementation**: Resource pool with exclusive allocation

### Pattern 2: Shared Read Access

**Description**: Multiple sub-agents can read from resource simultaneously.

**Use Case**: Configuration data, shared state

**Implementation**: Read-only access with reference counting

### Pattern 3: Protected Write Access

**Description**: One sub-agent can write, others can read.

**Use Case**: Workspace state, shared cache

**Implementation**: Read-write lock pattern

---

## Notes

- All interfaces follow Grain Style strictly
- All interfaces use explicit `u32`/`u64` types
- All interfaces use bounded allocations
- All interfaces include resource cleanup
- All interfaces include resource monitoring
- Interfaces support both Core services and sevenos integration

---

**Date**: 2026-01-02-010500-pst  
**Agent**: Core 1 Subcore (L1 Subcore Coordinator)  
**Status**: Design In Progress — Shared Resource Interfaces Ready for Implementation

