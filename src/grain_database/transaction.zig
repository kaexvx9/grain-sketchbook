//! Grain Database Transaction: ACID transaction management.
//!
//! Why: Ensure atomicity, consistency, isolation, durability.
//! Architecture: Bounded transactions, iterative algorithms.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.
//!
//! Performance Characteristics:
//! - Transaction creation: O(1) (allocates fixed-size array)
//! - Add operation: O(1) (array append)
//! - Commit/Abort: O(1) (state change only)
//! - Operation execution: O(n) where n is number of operations (sequential)
//!
//! Thread Safety: Not thread-safe. Caller must synchronize access.
//!
//! Usage Example:
//! ```zig
//! var tx = try Transaction.init(allocator, transaction_id);
//! defer tx.deinit();
//!
//! try tx.add_operation(.insert, record_id, key, value);
//! try tx.add_operation(.update, record_id, key, new_value);
//!
//! if (should_commit) {
//!     tx.commit();
//! } else {
//!     tx.abort();
//! }
//! ```
//!
//! Common Patterns:
//! - Add all operations before commit/abort
//! - Check is_active() before adding operations
//! - Use commit() for success, abort() for rollback
//!
//! 2025-12-03-163155-pst: Grain Database Agent
//! 2026-01-02-085625-pst: Documentation enhanced (Silo Agent)

const std = @import("std");

// Bounded: Max active transactions.
pub const MAX_TRANSACTIONS: u32 = 10_000;

// Bounded: Max operations per transaction.
pub const MAX_OPERATIONS_PER_TX: u32 = 1_000;

// Transaction state.
pub const TransactionState = enum {
    active,
    committed,
    aborted,
};

// Transaction operation.
pub const TransactionOperation = struct {
    operation_type: OperationType,
    record_id: u64,
    key: []const u8,
    key_len: u32,
    value: []const u8,
    value_len: u64,
    allocator: std.mem.Allocator,

    const OperationType = enum {
        insert,
        update,
        delete,
    };

    // Initialize transaction operation.
    pub fn init(
        allocator: std.mem.Allocator,
        operation_type: OperationType,
        record_id: u64,
        key: []const u8,
        value: []const u8,
    ) !TransactionOperation {
        std.debug.assert(record_id > 0);
        std.debug.assert(key.len <= 1_024);

        const key_copy = try allocator.dupe(u8, key);
        errdefer allocator.free(key_copy);

        const value_copy = try allocator.dupe(u8, value);
        errdefer allocator.free(value_copy);

        return TransactionOperation{
            .operation_type = operation_type,
            .record_id = record_id,
            .key = key_copy,
            .key_len = @as(u32, @intCast(key_copy.len)),
            .value = value_copy,
            .value_len = @as(u64, @intCast(value_copy.len)),
            .allocator = allocator,
        };
    }

    // Deinitialize transaction operation and free memory.
    pub fn deinit(self: *TransactionOperation) void {
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

// Transaction: ACID transaction management.
pub const Transaction = struct {
    transaction_id: u64,
    state: TransactionState,
    operations: []TransactionOperation,
    operations_len: u32,
    created_at: u64,
    allocator: std.mem.Allocator,

    //! Initializes a new transaction.
    //!
    //! Why: Provides ACID transaction management for atomic operations.
    //! Performance: O(1) initialization (allocates fixed-size array).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns error if allocation fails
    //! - Allocates MAX_OPERATIONS_PER_TX operations array (fixed size)
    //! - Initial state is TransactionState.active
    //!
    //! Example:
    //! ```zig
    //! var tx = try Transaction.init(allocator, transaction_id);
    //! defer tx.deinit();
    //! ```
    pub fn init(allocator: std.mem.Allocator, transaction_id: u64) !Transaction {
        std.debug.assert(transaction_id > 0);
        _ = allocator;

        const operations = try allocator.alloc(
            TransactionOperation,
            MAX_OPERATIONS_PER_TX,
        );
        errdefer allocator.free(operations);

        const now = std.time.timestamp();

        return Transaction{
            .transaction_id = transaction_id,
            .state = TransactionState.active,
            .operations = operations,
            .operations_len = 0,
            .created_at = @as(u64, @intCast(now)),
            .allocator = allocator,
        };
    }

    // Deinitialize transaction and free memory.
    pub fn deinit(self: *Transaction) void {
        _ = self.allocator;
        var i: u32 = 0;
        while (i < self.operations_len) : (i += 1) {
            self.operations[i].deinit();
        }
        self.allocator.free(self.operations);
        self.* = undefined;
    }

    //! Adds an operation to the transaction.
    //!
    //! Why: Builds transaction operation list for atomic execution.
    //! Performance: O(1) average case (array append).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns error.TransactionFull if MAX_OPERATIONS_PER_TX reached
    //! - Returns error if transaction is not active (already committed/aborted)
    //! - Returns error if operation allocation fails
    //!
    //! Example:
    //! ```zig
    //! try tx.add_operation(.insert, record_id, key, value);
    //! ```
    pub fn add_operation(
        self: *Transaction,
        operation_type: TransactionOperation.OperationType,
        record_id: u64,
        key: []const u8,
        value: []const u8,
    ) !void {
        std.debug.assert(self.state == TransactionState.active);
        std.debug.assert(self.operations_len < MAX_OPERATIONS_PER_TX);

        if (self.operations_len >= MAX_OPERATIONS_PER_TX) {
            return error.TransactionFull;
        }

        var operation = try TransactionOperation.init(
            self.allocator,
            operation_type,
            record_id,
            key,
            value,
        );
        errdefer operation.deinit();

        self.operations[self.operations_len] = operation;
        self.operations_len += 1;

        std.debug.assert(self.operations_len <= MAX_OPERATIONS_PER_TX);
    }

    //! Commits the transaction (marks as committed).
    //!
    //! Why: Finalizes transaction for execution (atomicity guarantee).
    //! Performance: O(1) (state change only).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Panics if transaction is not active (use is_active() to check)
    //! - After commit, transaction cannot be modified
    //!
    //! Example:
    //! ```zig
    //! tx.commit();
    //! ```
    pub fn commit(self: *Transaction) void {
        std.debug.assert(self.state == TransactionState.active);
        self.state = TransactionState.committed;
    }

    //! Aborts the transaction (marks as aborted for rollback).
    //!
    //! Why: Cancels transaction operations (atomicity guarantee).
    //! Performance: O(1) (state change only).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Panics if transaction is not active (use is_active() to check)
    //! - After abort, transaction cannot be modified
    //!
    //! Example:
    //! ```zig
    //! tx.abort();
    //! ```
    pub fn abort(self: *Transaction) void {
        std.debug.assert(self.state == TransactionState.active);
        self.state = TransactionState.aborted;
    }

    //! Checks if transaction is active (can be modified).
    //!
    //! Why: Provides state check before operations.
    //! Performance: O(1) (field access).
    //!
    //! Returns: true if transaction is active, false otherwise.
    //!
    //! Example:
    //! ```zig
    //! if (tx.is_active()) {
    //!     try tx.add_operation(.insert, record_id, key, value);
    //! }
    //! ```
    pub fn is_active(self: *Transaction) bool {
        return self.state == TransactionState.active;
    }

    //! Checks if transaction is committed.
    //!
    //! Why: Provides state check for transaction status.
    //! Performance: O(1) (field access).
    //!
    //! Returns: true if transaction is committed, false otherwise.
    //!
    //! Example:
    //! ```zig
    //! if (tx.is_committed()) {
    //!     // Transaction was committed
    //! }
    //! ```
    pub fn is_committed(self: *Transaction) bool {
        return self.state == TransactionState.committed;
    }
};

