// Grain Storage Unified: Unified storage API for all backends
// Re-exports all unified storage components

pub const UnifiedStorage = @import("unified.zig").UnifiedStorage;
pub const StorageBackend = @import("unified.zig").StorageBackend;
pub const KarmicMetadata = @import("unified.zig").KarmicMetadata;
pub const KarmicDataChunk = @import("unified.zig").KarmicDataChunk;
pub const KarmicDataType = @import("unified.zig").KarmicDataType;
pub const StorageId = @import("unified.zig").StorageId;

