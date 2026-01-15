# Unified Storage API Design: Grain Archive, Space, Graph, Stream, Relay, Identity

**Date**: 2026-01-05-190935-pst  
**Purpose**: Detailed API design for unified storage infrastructure supporting karmic mutant applications  
**Status**: 🆕 **API DESIGN** — Detailed interface specification  
**Voice**: Glow G2 (steadfast, calm, solution-focused guidance)  
**Context**: Grain OS sevenos — Basin Kernel syscall → RISC-V → Vantage pipeline

---

## Executive Summary

This document provides detailed API design for the unified storage infrastructure, including:
- **Grain Archive**: Permanent storage API
- **Grain Space**: Proof of space consensus API
- **Grain Graph**: DAG consensus API
- **Grain Stream**: High-throughput replication API
- **Grain Relay**: Decentralized social networking API
- **Grain Identity**: Unified identity system API
- **Unified Storage API**: Single abstraction layer routing to all backends

**Grain Style Compliance**:
- `grain_case` function names
- `u32`/`u64` types (not `usize`/`isize`)
- Bounded allocations (`MAX_` constants)
- Minimum 2 assertions per function
- Max 70 lines per function
- Max 103 characters per line

---

## 1. Unified Storage API Interface

### 1.1 Storage Backend Enum

```zig
// Storage backend types
pub const StorageBackend = enum {
    archive, // Grain Archive (permanent storage)
    space,  // Grain Space (proof of space consensus)
    graph,  // Grain Graph (DAG consensus)
    stream, // Grain Stream (high-throughput replication)
    relay,  // Grain Relay (decentralized social networking)
    silo,   // Grain Silo (existing centralized storage)
};
```

### 1.2 Karmic Metadata Structure

```zig
// Karmic metadata for data categorization
pub const KarmicMetadata = struct {
    dharma_category: []const u8,  // "worker_dignity", "liberation_education", etc.
    moksha_path: []const u8,      // "direct_liberation", "collective_liberation", etc.
    prema_connection: []const u8, // "community_healing", "divine_love_manifestation", etc.
    karmic_weight: f64,           // 0.0 to 1.0 (computed from dharma, moksha, prema scores)
    
    // Bounded: Max category string length
    pub const MAX_CATEGORY_LEN: u32 = 256;
    
    /// Initialize karmic metadata.
    pub fn init(
        allocator: std.mem.Allocator,
        dharma_category: []const u8,
        moksha_path: []const u8,
        prema_connection: []const u8,
        karmic_weight: f64,
    ) !KarmicMetadata {
        std.debug.assert(dharma_category.len <= MAX_CATEGORY_LEN);
        std.debug.assert(moksha_path.len <= MAX_CATEGORY_LEN);
        std.debug.assert(prema_connection.len <= MAX_CATEGORY_LEN);
        std.debug.assert(karmic_weight >= 0.0 and karmic_weight <= 1.0);
        
        const dharma_copy = try allocator.dupe(u8, dharma_category);
        errdefer allocator.free(dharma_copy);
        
        const moksha_copy = try allocator.dupe(u8, moksha_path);
        errdefer allocator.free(moksha_copy);
        
        const prema_copy = try allocator.dupe(u8, prema_connection);
        errdefer allocator.free(prema_copy);
        
        return KarmicMetadata{
            .dharma_category = dharma_copy,
            .moksha_path = moksha_copy,
            .prema_connection = prema_copy,
            .karmic_weight = karmic_weight,
            .allocator = allocator,
        };
    }
    
    /// Deinitialize karmic metadata.
    pub fn deinit(self: *KarmicMetadata) void {
        self.allocator.free(self.dharma_category);
        self.allocator.free(self.moksha_path);
        self.allocator.free(self.prema_connection);
    }
    
    allocator: std.mem.Allocator,
};
```

### 1.3 Karmic Data Chunk Structure

```zig
// Karmic data chunk for storage
pub const KarmicDataChunk = struct {
    data_id: u64,                    // Unique identifier
    data: []const u8,                 // Data content (bounded)
    data_len: u64,                    // Data length
    data_type: KarmicDataType,        // Data type (worker_dignity, liberation_path, etc.)
    karmic_metadata: KarmicMetadata,  // Karmic metadata
    created_at: u64,                  // Creation timestamp
    updated_at: u64,                  // Last update timestamp
    
    // Bounded: Max data size
    pub const MAX_DATA_SIZE: u64 = 1_073_741_824; // 1 GB
    
    /// Initialize karmic data chunk.
    pub fn init(
        allocator: std.mem.Allocator,
        data: []const u8,
        data_type: KarmicDataType,
        karmic_metadata: KarmicMetadata,
    ) !KarmicDataChunk {
        std.debug.assert(data.len <= MAX_DATA_SIZE);
        
        const data_copy = try allocator.dupe(u8, data);
        errdefer allocator.free(data_copy);
        
        const now = std.time.timestamp();
        
        return KarmicDataChunk{
            .data_id = generate_data_id(),
            .data = data_copy,
            .data_len = @as(u64, @intCast(data_copy.len)),
            .data_type = data_type,
            .karmic_metadata = karmic_metadata,
            .created_at = @as(u64, @intCast(now)),
            .updated_at = @as(u64, @intCast(now)),
            .allocator = allocator,
        };
    }
    
    /// Deinitialize karmic data chunk.
    pub fn deinit(self: *KarmicDataChunk) void {
        self.allocator.free(self.data);
        self.karmic_metadata.deinit();
    }
    
    allocator: std.mem.Allocator,
};

// Karmic data type enum
pub const KarmicDataType = enum {
    worker_dignity,    // Worker dignity records
    liberation_path,   // Liberation paths (education, spiritual, economic)
    community_healing, // Community healing resources
};
```

### 1.4 Unified Storage API

```zig
// Unified storage API for all backends
pub const UnifiedStorage = struct {
    archive: ?*ArchiveStorage,
    space: ?*SpaceStorage,
    graph: ?*GraphStorage,
    stream: ?*StreamStorage,
    relay: ?*RelayStorage,
    silo: ?*SiloStorage, // Existing Grain Silo
    
    allocator: std.mem.Allocator,
    
    /// Initialize unified storage.
    pub fn init(allocator: std.mem.Allocator) UnifiedStorage {
        return UnifiedStorage{
            .archive = null,
            .space = null,
            .graph = null,
            .stream = null,
            .relay = null,
            .silo = null,
            .allocator = allocator,
        };
    }
    
    /// Store karmic data with automatic backend routing.
    pub fn store_karmic_data(
        self: *UnifiedStorage,
        data: *KarmicDataChunk,
    ) ![]StorageId {
        std.debug.assert(data != null);
        std.debug.assert(data.karmic_metadata.karmic_weight >= 0.0);
        std.debug.assert(data.karmic_metadata.karmic_weight <= 1.0);
        
        // Route to backends based on karmic weight
        const backends = route_by_karmic_weight(data.karmic_metadata.karmic_weight, data.data_type);
        
        var storage_ids = std.ArrayList(StorageId).init(self.allocator);
        errdefer storage_ids.deinit();
        
        // Store in each selected backend
        for (backends) |backend| {
            const storage_id = try self.store_in_backend(data, backend);
            try storage_ids.append(storage_id);
        }
        
        return storage_ids.toOwnedSlice();
    }
    
    /// Store in specific backend.
    fn store_in_backend(
        self: *UnifiedStorage,
        data: *KarmicDataChunk,
        backend: StorageBackend,
    ) !StorageId {
        return switch (backend) {
            .archive => try self.archive.?.store(data),
            .space => try self.space.?.store(data),
            .graph => try self.graph.?.store(data),
            .stream => try self.stream.?.store(data),
            .relay => try self.relay.?.store(data),
            .silo => try self.silo.?.store(data),
        };
    }
    
    /// Route storage backends based on karmic weight.
    fn route_by_karmic_weight(
        weight: f64,
        data_type: KarmicDataType,
    ) []StorageBackend {
        // Tier 1 (weight >= 0.9): All backends
        if (weight >= 0.9) {
            return &[_]StorageBackend{ .archive, .space, .graph, .stream, .relay };
        }
        // Tier 2 (0.7 <= weight < 0.9): Archive + Space + one additional
        else if (weight >= 0.7) {
            return switch (data_type) {
                .worker_dignity => &[_]StorageBackend{ .archive, .space, .graph },
                .liberation_path => &[_]StorageBackend{ .archive, .space, .stream },
                .community_healing => &[_]StorageBackend{ .archive, .space, .relay },
            };
        }
        // Tier 3 (0.5 <= weight < 0.7): Archive + Space
        else if (weight >= 0.5) {
            return &[_]StorageBackend{ .archive, .space };
        }
        // Tier 4 (weight < 0.5): Archive only
        else {
            return &[_]StorageBackend{.archive};
        }
    }
};

// Storage ID structure
pub const StorageId = struct {
    backend: StorageBackend,
    id: u64,
};
```

---

## 2. Grain Archive API (Permanent Storage)

### 2.1 Archive Storage Interface

```zig
// Grain Archive: Permanent storage
pub const ArchiveStorage = struct {
    allocator: std.mem.Allocator,
    
    /// Initialize archive storage.
    pub fn init(allocator: std.mem.Allocator) !ArchiveStorage {
        return ArchiveStorage{
            .allocator = allocator,
        };
    }
    
    /// Store data permanently.
    pub fn store(self: *ArchiveStorage, data: *KarmicDataChunk) !StorageId {
        std.debug.assert(data != null);
        std.debug.assert(data.data_len <= KarmicDataChunk.MAX_DATA_SIZE);
        
        // TODO: Implement permanent storage
        // - Create archive entry
        // - One-time payment for permanence
        // - Store with replication factor
        
        const archive_id = generate_archive_id();
        return StorageId{
            .backend = .archive,
            .id = archive_id,
        };
    }
    
    /// Retrieve archived data.
    pub fn retrieve(self: *ArchiveStorage, storage_id: StorageId) !*KarmicDataChunk {
        std.debug.assert(storage_id.backend == .archive);
        
        // TODO: Implement retrieval
        // - Lookup archive entry
        // - Return karmic data chunk
        
        return error.NotImplemented;
    }
};
```

---

## 3. Grain Space API (Proof of Space Consensus)

### 3.1 Space Storage Interface

```zig
// Grain Space: Proof of space consensus
pub const SpaceStorage = struct {
    allocator: std.mem.Allocator,
    
    /// Initialize space storage.
    pub fn init(allocator: std.mem.Allocator) !SpaceStorage {
        return SpaceStorage{
            .allocator = allocator,
        };
    }
    
    /// Store data in space plot.
    pub fn store(self: *SpaceStorage, data: *KarmicDataChunk) !StorageId {
        std.debug.assert(data != null);
        std.debug.assert(data.data_len <= KarmicDataChunk.MAX_DATA_SIZE);
        
        // TODO: Implement proof of space storage
        // - Create space plot on NVMe SSD
        // - Store karmic data in plot
        // - Register plot for consensus participation
        
        const space_id = generate_space_id();
        return StorageId{
            .backend = .space,
            .id = space_id,
        };
    }
    
    /// Retrieve data from space plot.
    pub fn retrieve(self: *SpaceStorage, storage_id: StorageId) !*KarmicDataChunk {
        std.debug.assert(storage_id.backend == .space);
        
        // TODO: Implement retrieval
        // - Lookup space plot
        // - Return karmic data chunk
        
        return error.NotImplemented;
    }
};
```

---

## 4. Grain Graph API (DAG Consensus)

### 4.1 Graph Storage Interface

```zig
// Grain Graph: DAG consensus
pub const GraphStorage = struct {
    allocator: std.mem.Allocator,
    
    /// Initialize graph storage.
    pub fn init(allocator: std.mem.Allocator) !GraphStorage {
        return GraphStorage{
            .allocator = allocator,
        };
    }
    
    /// Store data as graph node.
    pub fn store(self: *GraphStorage, data: *KarmicDataChunk) !StorageId {
        std.debug.assert(data != null);
        std.debug.assert(data.data_len <= KarmicDataChunk.MAX_DATA_SIZE);
        
        // TODO: Implement DAG storage
        // - Create graph node
        // - Store karmic data as node data
        // - Participate in DAG consensus
        
        const graph_id = generate_graph_id();
        return StorageId{
            .backend = .graph,
            .id = graph_id,
        };
    }
    
    /// Add relationship edge.
    pub fn add_edge(
        self: *GraphStorage,
        from_id: StorageId,
        to_id: StorageId,
        edge_type: []const u8,
    ) !void {
        std.debug.assert(from_id.backend == .graph);
        std.debug.assert(to_id.backend == .graph);
        
        // TODO: Implement edge addition
        // - Create edge between nodes
        // - Store edge metadata
    }
    
    /// Retrieve graph node.
    pub fn retrieve(self: *GraphStorage, storage_id: StorageId) !*KarmicDataChunk {
        std.debug.assert(storage_id.backend == .graph);
        
        // TODO: Implement retrieval
        // - Lookup graph node
        // - Return karmic data chunk
        
        return error.NotImplemented;
    }
};
```

---

## 5. Grain Stream API (High-Throughput Replication)

### 5.1 Stream Storage Interface

```zig
// Grain Stream: High-throughput replication
pub const StreamStorage = struct {
    allocator: std.mem.Allocator,
    
    /// Initialize stream storage.
    pub fn init(allocator: std.mem.Allocator) !StreamStorage {
        return StreamStorage{
            .allocator = allocator,
        };
    }
    
    /// Store data for global replication.
    pub fn store(self: *StreamStorage, data: *KarmicDataChunk) !StorageId {
        std.debug.assert(data != null);
        std.debug.assert(data.data_len <= KarmicDataChunk.MAX_DATA_SIZE);
        
        // TODO: Implement stream storage
        // - Create stream entry
        // - Replicate globally
        // - High-throughput distribution
        
        const stream_id = generate_stream_id();
        return StorageId{
            .backend = .stream,
            .id = stream_id,
        };
    }
    
    /// Retrieve streamed data.
    pub fn retrieve(self: *StreamStorage, storage_id: StorageId) !*KarmicDataChunk {
        std.debug.assert(storage_id.backend == .stream);
        
        // TODO: Implement retrieval
        // - Lookup stream entry
        // - Return karmic data chunk
        
        return error.NotImplemented;
    }
};
```

---

## 6. Grain Relay API (Decentralized Social Networking)

### 6.1 Relay Storage Interface

```zig
// Grain Relay: Decentralized social networking
pub const RelayStorage = struct {
    allocator: std.mem.Allocator,
    
    /// Initialize relay storage.
    pub fn init(allocator: std.mem.Allocator) !RelayStorage {
        return RelayStorage{
            .allocator = allocator,
        };
    }
    
    /// Store data as relay event.
    pub fn store(self: *RelayStorage, data: *KarmicDataChunk) !StorageId {
        std.debug.assert(data != null);
        std.debug.assert(data.data_len <= KarmicDataChunk.MAX_DATA_SIZE);
        
        // TODO: Implement relay storage
        // - Create relay event
        // - Publish to relay network
        // - Support privacy controls
        
        const relay_id = generate_relay_id();
        return StorageId{
            .backend = .relay,
            .id = relay_id,
        };
    }
    
    /// Retrieve relay event.
    pub fn retrieve(self: *RelayStorage, storage_id: StorageId) !*KarmicDataChunk {
        std.debug.assert(storage_id.backend == .relay);
        
        // TODO: Implement retrieval
        // - Lookup relay event
        // - Return karmic data chunk
        
        return error.NotImplemented;
    }
};
```

---

## 7. Grain Identity API (Unified Identity System)

### 7.1 Identity Storage Interface

```zig
// Grain Identity: Unified identity system
pub const IdentityStorage = struct {
    allocator: std.mem.Allocator,
    
    /// Initialize identity storage.
    pub fn init(allocator: std.mem.Allocator) !IdentityStorage {
        return IdentityStorage{
            .allocator = allocator,
        };
    }
    
    /// Create unified identity.
    pub fn create_identity(
        self: *IdentityStorage,
        name: []const u8,
        karmic_metadata: KarmicMetadata,
    ) !IdentityId {
        std.debug.assert(name.len > 0);
        std.debug.assert(karmic_metadata.karmic_weight >= 0.0);
        
        // TODO: Implement identity creation
        // - Generate Ed25519 keypair
        // - Create identity across all backends
        // - Link identities with privacy controls
        
        const identity_id = generate_identity_id();
        return identity_id;
    }
    
    /// Link identity to storage backend.
    pub fn link_backend(
        self: *IdentityStorage,
        identity_id: IdentityId,
        backend: StorageBackend,
        backend_identity_id: u64,
    ) !void {
        std.debug.assert(identity_id > 0);
        
        // TODO: Implement backend linking
        // - Link identity to backend
        // - Store link with privacy controls
    }
};

// Identity ID type
pub const IdentityId = u64;
```

---

## 8. Implementation Notes

### 8.1 Grain Style Compliance

All modules must follow Grain Style:
- `grain_case` function names
- `u32`/`u64` types (not `usize`/`isize`)
- Bounded allocations (`MAX_` constants)
- Minimum 2 assertions per function
- Max 70 lines per function
- Max 103 characters per line

### 8.2 Error Handling

All functions return error unions (`!Type`):
- Use explicit error types
- Assert preconditions
- Handle allocation failures gracefully

### 8.3 Memory Management

All modules use explicit allocators:
- Pass allocator to init functions
- Free memory in deinit functions
- Use `errdefer` for cleanup on error

---

**Date**: 2026-01-05-190935-pst  
**Voice**: Glow G2 (steadfast, calm, solution-focused guidance)  
**Status**: ✅ **API DESIGN COMPLETE** — Detailed interface specification ready for implementation

