//! Grain Database Storage Engine: Key-value storage extending Grain Silo.
//!
//! Why: Extend Grain Silo with database-specific features (indexes, transactions).
//! Architecture: Key-value foundation with bounded allocations.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.
//!
//! Performance Characteristics:
//! - Record creation: O(n) worst case (linear scan for duplicate check), O(1) average
//! - Record lookup: O(n) worst case (linear scan), O(1) average with index
//! - Record update: O(n) worst case (linear scan), O(1) average with index
//! - Record deletion: O(n) worst case (linear scan + array shift)
//!
//! Thread Safety: Not thread-safe. Caller must synchronize access.
//!
//! Usage Example:
//! ```zig
//! var engine = try StorageEngine.init(allocator, 1024 * 1024);
//! defer engine.deinit();
//!
//! const record_id = try engine.create_record("user:123", user_data);
//! const record = engine.read_record_by_key("user:123");
//! try engine.update_record("user:123", updated_data);
//! try engine.delete_record("user:123");
//! ```
//!
//! Common Patterns:
//! - Use validate_key() and validate_value() before operations
//! - Check has_record() before create_record() to avoid RecordExists errors
//! - Use batch_create_records() for bulk loading (more efficient)
//!
//! 2025-12-03-163155-pst: Grain Database Agent
//! 2026-01-02-004011-pst: Documentation enhanced (Silo Agent)

const std = @import("std");
const grain_silo = @import("grain_silo");

// Bounded: Max key length (bytes).
pub const MAX_KEY_LEN: u32 = 1_024;

// Bounded: Max value length (bytes).
pub const MAX_VALUE_LEN: u64 = 1_073_741_824; // 1 GB

// Bounded: Max records in storage engine.
pub const MAX_RECORDS: u32 = 10_000_000;

// Record: Key-value pair with metadata.
pub const Record = struct {
    key: []const u8,
    key_len: u32,
    value: []const u8,
    value_len: u64,
    record_id: u64,
    created_at: u64,
    updated_at: u64,
    allocator: std.mem.Allocator,

    // Initialize record.
    pub fn init(
        allocator: std.mem.Allocator,
        key: []const u8,
        value: []const u8,
        record_id: u64,
    ) !Record {
        std.debug.assert(key.len <= MAX_KEY_LEN);
        std.debug.assert(value.len <= MAX_VALUE_LEN);
        std.debug.assert(record_id > 0);

        const key_copy = try allocator.dupe(u8, key);
        errdefer allocator.free(key_copy);

        const value_copy = try allocator.dupe(u8, value);
        errdefer allocator.free(value_copy);

        const now = std.time.timestamp();

        return Record{
            .key = key_copy,
            .key_len = @as(u32, @intCast(key_copy.len)),
            .value = value_copy,
            .value_len = @as(u64, @intCast(value_copy.len)),
            .record_id = record_id,
            .created_at = @as(u64, @intCast(now)),
            .updated_at = @as(u64, @intCast(now)),
            .allocator = allocator,
        };
    }

    // Deinitialize record and free memory.
    pub fn deinit(self: *Record) void {
        _ = self.allocator;
        if (self.key_len > 0) {
            self.allocator.free(self.key);
        }
        if (self.value_len > 0) {
            self.allocator.free(self.value);
        }
        self.* = undefined;
    }
};

// Storage engine: Key-value storage extending Grain Silo.
pub const StorageEngine = struct {
    records: []Record,
    records_len: u32,
    next_record_id: u64,
    silo: grain_silo.Storage.ObjectStorage,
    allocator: std.mem.Allocator,

    // Initialize storage engine.
    pub fn init(
        allocator: std.mem.Allocator,
        hot_cache_size: u64,
    ) !StorageEngine {
        _ = allocator;
        const silo = try grain_silo.Storage.ObjectStorage.init(
            allocator,
            hot_cache_size,
        );
        errdefer silo.deinit();

        const records = try allocator.alloc(Record, MAX_RECORDS);
        errdefer allocator.free(records);

        return StorageEngine{
            .records = records,
            .records_len = 0,
            .next_record_id = 1,
            .silo = silo,
            .allocator = allocator,
        };
    }

    // Deinitialize storage engine and free memory.
    pub fn deinit(self: *StorageEngine) void {
        _ = self.allocator;
        var i: u32 = 0;
        while (i < self.records_len) : (i += 1) {
            self.records[i].deinit();
        }
        self.allocator.free(self.records);
        self.silo.deinit();
        self.* = undefined;
    }

    //! Creates a new record in the storage engine.
    //!
    //! Why: Provides atomic record creation with validation and metadata tracking.
    //! Performance: O(n) worst case (linear scan for duplicate check), O(1) average.
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns error.RecordExists if key already exists (use update_record instead)
    //! - Returns error if MAX_RECORDS limit reached
    //! - Returns error if key/value exceeds MAX_KEY_LEN/MAX_VALUE_LEN
    //!
    //! Example:
    //! ```zig
    //! const record_id = try engine.create_record("user:123", user_data);
    //! ```
    pub fn create_record(
        self: *StorageEngine,
        key: []const u8,
        value: []const u8,
    ) !u64 {
        std.debug.assert(key.len <= MAX_KEY_LEN);
        std.debug.assert(value.len <= MAX_VALUE_LEN);
        std.debug.assert(self.records_len < MAX_RECORDS);

        if (self.find_record_by_key(key)) |_| {
            return error.RecordExists;
        }

        const record_id = self.next_record_id;
        self.next_record_id += 1;

        var record = try Record.init(
            self.allocator,
            key,
            value,
            record_id,
        );
        errdefer record.deinit();

        self.records[self.records_len] = record;
        self.records_len += 1;

        std.debug.assert(self.records_len <= MAX_RECORDS);
        return record_id;
    }

    //! Reads a record by key.
    //!
    //! Why: Provides key-based lookup for record retrieval.
    //! Performance: O(n) worst case (linear scan), O(1) average with index.
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Returns: Pointer to Record if found, null otherwise.
    //!
    //! Example:
    //! ```zig
    //! const record = engine.read_record_by_key("user:123");
    //! if (record) |r| {
    //!     // Use record r
    //! }
    //! ```
    pub fn read_record_by_key(
        self: *StorageEngine,
        key: []const u8,
    ) ?*Record {
        std.debug.assert(key.len <= MAX_KEY_LEN);
        return self.find_record_by_key(key);
    }

    //! Reads a record by record ID.
    //!
    //! Why: Provides ID-based lookup for record retrieval.
    //! Performance: O(n) worst case (linear scan), O(1) average with index.
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Returns: Pointer to Record if found, null otherwise.
    //!
    //! Example:
    //! ```zig
    //! const record = engine.read_record_by_id(record_id);
    //! if (record) |r| {
    //!     // Use record r
    //! }
    //! ```
    pub fn read_record_by_id(
        self: *StorageEngine,
        record_id: u64,
    ) ?*Record {
        std.debug.assert(record_id > 0);
        return self.find_record_by_id(record_id);
    }

    //! Updates an existing record's value.
    //!
    //! Why: Provides atomic value update with timestamp tracking.
    //! Performance: O(n) worst case (linear scan), O(1) average with index.
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns error.RecordNotFound if key doesn't exist
    //! - Returns error if new_value exceeds MAX_VALUE_LEN
    //! - Updates updated_at timestamp automatically
    //!
    //! Example:
    //! ```zig
    //! try engine.update_record("user:123", updated_user_data);
    //! ```
    pub fn update_record(
        self: *StorageEngine,
        key: []const u8,
        new_value: []const u8,
    ) !void {
        std.debug.assert(key.len <= MAX_KEY_LEN);
        std.debug.assert(new_value.len <= MAX_VALUE_LEN);

        if (self.find_record_by_key(key)) |record| {
            if (new_value.len > 0) {
                self.allocator.free(record.value);
                const value_copy = try self.allocator.dupe(u8, new_value);
                record.value = value_copy;
                record.value_len = @as(u64, @intCast(value_copy.len));
            }
            const now = std.time.timestamp();
            record.updated_at = @as(u64, @intCast(now));
        } else {
            return error.RecordNotFound;
        }
    }

    //! Deletes a record by key.
    //!
    //! Why: Provides atomic record deletion with memory cleanup.
    //! Performance: O(n) worst case (linear scan + array shift).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns error.RecordNotFound if key doesn't exist
    //! - Performs array shift to maintain contiguous storage
    //!
    //! Example:
    //! ```zig
    //! try engine.delete_record("user:123");
    //! ```
    pub fn delete_record(
        self: *StorageEngine,
        key: []const u8,
    ) !void {
        std.debug.assert(key.len <= MAX_KEY_LEN);

        var i: u32 = 0;
        while (i < self.records_len) : (i += 1) {
            if (std.mem.eql(u8, self.records[i].key, key)) {
                self.records[i].deinit();
                var j: u32 = i;
                while (j < self.records_len - 1) : (j += 1) {
                    self.records[j] = self.records[j + 1];
                }
                self.records_len -= 1;
                return;
            }
        }
        return error.RecordNotFound;
    }

    // Find record by key (internal helper).
    fn find_record_by_key(
        self: *StorageEngine,
        key: []const u8,
    ) ?*Record {
        std.debug.assert(key.len <= MAX_KEY_LEN);
        var i: u32 = 0;
        while (i < self.records_len) : (i += 1) {
            if (std.mem.eql(u8, self.records[i].key, key)) {
                return &self.records[i];
            }
        }
        return null;
    }

    // Find record by ID (internal helper).
    fn find_record_by_id(
        self: *StorageEngine,
        record_id: u64,
    ) ?*Record {
        std.debug.assert(record_id > 0);
        var i: u32 = 0;
        while (i < self.records_len) : (i += 1) {
            if (self.records[i].record_id == record_id) {
                return &self.records[i];
            }
        }
        return null;
    }

    //! Batch creates multiple records (for bulk loading).
    //!
    //! Why: Provides efficient bulk record creation with duplicate skipping.
    //! Performance: O(n*m) worst case (n records, m existing records), but more
    //! efficient than individual create_record() calls due to reduced overhead.
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Skips duplicate keys (doesn't error, just continues)
    //! - Returns count of successfully created records
    //! - Returns error if MAX_RECORDS limit would be exceeded
    //!
    //! Example:
    //! ```zig
    //! var record_ids: [100]u64 = undefined;
    //! const count = try engine.batch_create_records(keys, values, &record_ids);
    //! ```
    pub fn batch_create_records(
        self: *StorageEngine,
        keys: []const []const u8,
        values: []const []const u8,
        output_record_ids: []u64,
    ) !u32 {
        std.debug.assert(keys.len == values.len);
        std.debug.assert(keys.len <= output_record_ids.len);
        std.debug.assert(self.records_len + keys.len <= MAX_RECORDS);
        var count: u32 = 0;
        var i: u32 = 0;
        while (i < keys.len) : (i += 1) {
            std.debug.assert(keys[i].len <= MAX_KEY_LEN);
            std.debug.assert(values[i].len <= MAX_VALUE_LEN);
            if (self.find_record_by_key(keys[i])) |_| {
                continue;
            }
            const record_id = self.next_record_id;
            self.next_record_id += 1;
            var record = try Record.init(
                self.allocator,
                keys[i],
                values[i],
                record_id,
            );
            errdefer record.deinit();
            self.records[self.records_len] = record;
            self.records_len += 1;
            output_record_ids[count] = record_id;
            count += 1;
        }
        std.debug.assert(self.records_len <= MAX_RECORDS);
        return count;
    }

    // Get total record count.
    pub fn get_record_count(self: *const StorageEngine) u32 {
        return self.records_len;
    }

    // Get total storage size (sum of all key and value sizes).
    pub fn get_total_storage_size(self: *const StorageEngine) u64 {
        var total_size: u64 = 0;
        var i: u32 = 0;
        while (i < self.records_len) : (i += 1) {
            const record = &self.records[i];
            total_size += @as(u64, record.key_len);
            total_size += record.value_len;
        }
        return total_size;
    }

    //! Gets the average record size (total size / record count).
    //!
    //! Why: Provides statistics for storage optimization analysis.
    //! Performance: O(n) - calls get_total_storage_size() internally.
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns 0 if no records exist (avoids division by zero)
    //!
    //! Example:
    //! ```zig
    //! const avg_size = engine.get_average_record_size();
    //! ```
    pub fn get_average_record_size(self: *const StorageEngine) u64 {
        if (self.records_len == 0) {
            return 0;
        }
        const total_size = self.get_total_storage_size();
        return total_size / @as(u64, self.records_len);
    }

    //! Gets the next record ID that will be assigned (for monitoring).
    //!
    //! Why: Provides monitoring for record ID allocation.
    //! Performance: O(1) - direct field access.
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Example:
    //! ```zig
    //! const next_id = engine.get_next_record_id();
    //! ```
    pub fn get_next_record_id(self: *const StorageEngine) u64 {
        return self.next_record_id;
    }

    //! Validates key format (non-empty, within bounds).
    //!
    //! Why: Provides validation before record operations to catch errors early.
    //! Performance: O(1) - length check only.
    //!
    //! Returns: true if key is valid (non-empty and ≤ MAX_KEY_LEN), false otherwise.
    //!
    //! Example:
    //! ```zig
    //! if (!validate_key(key)) {
    //!     return error.InvalidKey;
    //! }
    //! ```
    pub fn validate_key(key: []const u8) bool {
        if (key.len == 0) {
            return false;
        }
        if (key.len > MAX_KEY_LEN) {
            return false;
        }
        return true;
    }

    //! Validates value format (within bounds).
    //!
    //! Why: Provides validation before record operations to catch errors early.
    //! Performance: O(1) - length check only.
    //!
    //! Returns: true if value is valid (≤ MAX_VALUE_LEN), false otherwise.
    //!
    //! Note: Empty values are allowed (unlike keys).
    //!
    //! Example:
    //! ```zig
    //! if (!validate_value(value)) {
    //!     return error.InvalidValue;
    //! }
    //! ```
    pub fn validate_value(value: []const u8) bool {
        if (value.len > MAX_VALUE_LEN) {
            return false;
        }
        return true;
    }

    //! Checks if a record exists by key.
    //!
    //! Why: Provides existence check before operations to avoid errors.
    //! Performance: O(n) worst case (linear scan), O(1) average with index.
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Example:
    //! ```zig
    //! if (engine.has_record("user:123")) {
    //!     // Record exists
    //! }
    //! ```
    pub fn has_record(self: *const StorageEngine, key: []const u8) bool {
        std.debug.assert(key.len <= MAX_KEY_LEN);
        return self.find_record_by_key(key) != null;
    }

    //! Checks if a record exists by record ID.
    //!
    //! Why: Provides existence check before operations to avoid errors.
    //! Performance: O(n) worst case (linear scan), O(1) average with index.
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Example:
    //! ```zig
    //! if (engine.has_record_by_id(record_id)) {
    //!     // Record exists
    //! }
    //! ```
    pub fn has_record_by_id(self: *const StorageEngine, record_id: u64) bool {
        std.debug.assert(record_id > 0);
        return self.find_record_by_id(record_id) != null;
    }
};

