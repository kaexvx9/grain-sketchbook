const std = @import("std");

/// Grain Storage Unified: Unified storage API for all backends.
/// ~<~ Glow Airbend: explicit storage state, bounded object management.
/// ~~~~ Glow Waterbend: deterministic storage operations, iterative algorithms.
///
/// Provides single API abstraction for Grain Archive, Space, Graph, Stream, Relay, Identity.
///
/// GrainStyle compliance:
/// - grain_case function names
/// - u32/u64 types (not usize/isize)
/// - MAX_ constants for bounded allocations
/// - Assertions for preconditions/postconditions
/// - No recursion (iterative algorithms, stack-based)
///
/// 2026-01-05-190935-pst: Initial implementation

// Storage backend types
pub const StorageBackend = enum {
    archive, // Grain Archive (permanent storage)
    space,  // Grain Space (proof of space consensus)
    graph,  // Grain Graph (DAG consensus)
    stream, // Grain Stream (high-throughput replication)
    relay,  // Grain Relay (decentralized social networking)
    silo,   // Grain Silo (existing centralized storage)
};

// Karmic data type enum
pub const KarmicDataType = enum {
    worker_dignity,    // Worker dignity records
    liberation_path,   // Liberation paths (education, spiritual, economic)
    community_healing, // Community healing resources
};

// Karmic metadata for data categorization
pub const KarmicMetadata = struct {
    dharma_category: []const u8,  // "worker_dignity", "liberation_education", etc.
    moksha_path: []const u8,      // "direct_liberation", "collective_liberation", etc.
    prema_connection: []const u8, // "community_healing", "divine_love_manifestation", etc.
    karmic_weight: f64,           // 0.0 to 1.0 (computed from dharma, moksha, prema scores)
    allocator: std.mem.Allocator,
    
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
};

// Karmic data chunk for storage
pub const KarmicDataChunk = struct {
    data_id: u64,                    // Unique identifier
    data: []const u8,                 // Data content (bounded)
    data_len: u64,                    // Data length
    data_type: KarmicDataType,        // Data type
    karmic_metadata: KarmicMetadata,  // Karmic metadata
    created_at: u64,                  // Creation timestamp
    updated_at: u64,                  // Last update timestamp
    allocator: std.mem.Allocator,
    
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
};

// Storage ID structure
pub const StorageId = struct {
    backend: StorageBackend,
    id: u64,
};

// Unified storage API for all backends
pub const UnifiedStorage = struct {
    archive: ?*@import("../grain_archive/archive.zig").ArchiveStorage,
    space: ?*@import("../grain_space/space.zig").SpaceStorage,
    graph: ?*@import("../grain_graph/graph.zig").GraphStorage,
    stream: ?*@import("../grain_stream/stream.zig").StreamStorage,
    relay: ?*@import("../grain_relay/relay.zig").RelayStorage,
    allocator: std.mem.Allocator,
    
    /// Initialize unified storage.
    pub fn init(allocator: std.mem.Allocator) UnifiedStorage {
        return UnifiedStorage{
            .archive = null,
            .space = null,
            .graph = null,
            .stream = null,
            .relay = null,
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
        const backends = route_by_karmic_weight(
            data.karmic_metadata.karmic_weight,
            data.data_type,
        );
        
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
            .silo => return error.SiloNotSupported, // Grain Silo handled separately
        };
    }
    
    /// Route storage backends based on karmic weight.
    pub fn route_by_karmic_weight(
        weight: f64,
        data_type: KarmicDataType,
    ) []const StorageBackend {
        std.debug.assert(weight >= 0.0 and weight <= 1.0);
        
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

// Generate unique data ID (placeholder)
fn generate_data_id() u64 {
    // TODO: Implement proper ID generation
    return 0;
}

