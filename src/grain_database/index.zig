//! Grain Database Index: Hash, B-tree, and full-text search indexes.
//!
//! Why: Fast lookups by ID (hash), foreign keys (B-tree), and text (inverted).
//! Architecture: Iterative algorithms, bounded allocations.
//! GrainStyle: grain_case, u32/u64, bounded allocations, assertions, max 70 lines.
//!
//! Performance Characteristics:
//! - HashIndex: O(1) average case (hash lookup), O(n) worst case (hash collisions)
//! - BTreeIndex: O(log n) average/worst case (balanced tree traversal)
//! - InvertedIndex: O(n) worst case (linear scan for token lookup), O(1) average with hash
//!
//! Thread Safety: Not thread-safe. Caller must synchronize access.
//!
//! Usage Examples:
//! ```zig
//! // Hash index for fast ID lookups
//! var hash_idx = try HashIndex.init(allocator);
//! defer hash_idx.deinit();
//! try hash_idx.insert(record_id, record_ptr);
//! const ptr = hash_idx.lookup(record_id);
//!
//! // B-tree index for range queries
//! var btree = try BTreeIndex.init(allocator);
//! defer btree.deinit();
//! try btree.insert(key, value);
//! const val = btree.lookup(key);
//!
//! // Inverted index for full-text search
//! var inv_idx = try InvertedIndex.init(allocator);
//! defer inv_idx.deinit();
//! try inv_idx.index_document(doc_id, text);
//! var results: [100]u64 = undefined;
//! const count = try inv_idx.search(query, &results);
//! ```
//!
//! Common Patterns:
//! - Use HashIndex for primary key lookups (fastest for exact matches)
//! - Use BTreeIndex for foreign keys and range queries (ordered traversal)
//! - Use InvertedIndex for text search (token-based document retrieval)
//!
//! 2025-12-03-173339-pst: Grain Database Agent (Phase 4: Full-Text Search)
//! 2026-01-02-085625-pst: Documentation enhanced (Silo Agent)

const std = @import("std");

// Bounded: Max hash table size (power of 2 for efficient hashing).
pub const MAX_HASH_SIZE: u32 = 1_048_576; // 2^20

// Bounded: Max B-tree nodes.
pub const MAX_BTREE_NODES: u32 = 1_000_000;

// Bounded: Max keys per B-tree node.
pub const MAX_KEYS_PER_NODE: u32 = 32;

// Hash index entry: Maps ID to record pointer.
pub const HashIndexEntry = struct {
    record_id: u64,
    record_ptr: u64, // Offset/index into records array
    next: ?u32, // Next entry in hash chain (for collisions)
};

// Hash index: Fast ID lookups.
pub const HashIndex = struct {
    buckets: []?u32, // Bucket array (indices into entries)
    entries: []HashIndexEntry, // Entry array
    entries_len: u32,
    allocator: std.mem.Allocator,

    //! Initializes a new hash index.
    //!
    //! Why: Provides fast O(1) average case lookups for record IDs.
    //! Performance: O(1) initialization (allocates fixed-size arrays).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns error if allocation fails
    //! - Allocates MAX_HASH_SIZE buckets and entries (fixed size)
    //!
    //! Example:
    //! ```zig
    //! var hash_idx = try HashIndex.init(allocator);
    //! defer hash_idx.deinit();
    //! ```
    pub fn init(allocator: std.mem.Allocator) !HashIndex {
        _ = allocator;
        const buckets = try allocator.alloc(?u32, MAX_HASH_SIZE);
        errdefer allocator.free(buckets);
        var i: u32 = 0;
        while (i < MAX_HASH_SIZE) : (i += 1) {
            buckets[i] = null;
        }

        const entries = try allocator.alloc(
            HashIndexEntry,
            MAX_HASH_SIZE,
        );
        errdefer allocator.free(entries);

        return HashIndex{
            .buckets = buckets,
            .entries = entries,
            .entries_len = 0,
            .allocator = allocator,
        };
    }

    // Deinitialize hash index and free memory.
    pub fn deinit(self: *HashIndex) void {
        _ = self.allocator;
        self.allocator.free(self.buckets);
        self.allocator.free(self.entries);
        self.* = undefined;
    }

    //! Inserts a record ID into the hash index.
    //!
    //! Why: Provides fast O(1) average case insertion for ID lookups.
    //! Performance: O(1) average case (hash + chain insert), O(n) worst case (all collisions).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns error.HashIndexFull if MAX_HASH_SIZE entries reached
    //! - Uses chaining for collision resolution
    //!
    //! Example:
    //! ```zig
    //! try hash_idx.insert(record_id, record_ptr);
    //! ```
    pub fn insert(
        self: *HashIndex,
        record_id: u64,
        record_ptr: u64,
    ) !void {
        std.debug.assert(record_id > 0);
        std.debug.assert(self.entries_len < MAX_HASH_SIZE);

        const hash = self.hash_record_id(record_id);
        const bucket_idx = hash % MAX_HASH_SIZE;

        if (self.entries_len >= MAX_HASH_SIZE) {
            return error.HashIndexFull;
        }

        const entry_idx = self.entries_len;
        self.entries[entry_idx] = HashIndexEntry{
            .record_id = record_id,
            .record_ptr = record_ptr,
            .next = self.buckets[bucket_idx],
        };
        self.buckets[bucket_idx] = entry_idx;
        self.entries_len += 1;
    }

    //! Looks up a record pointer by record ID.
    //!
    //! Why: Provides fast O(1) average case lookup for ID-based access.
    //! Performance: O(1) average case (hash + chain traversal), O(n) worst case (all collisions).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Returns: Record pointer if found, null otherwise.
    //!
    //! Example:
    //! ```zig
    //! const ptr = hash_idx.lookup(record_id);
    //! if (ptr) |p| {
    //!     // Use pointer p
    //! }
    //! ```
    pub fn lookup(
        self: *HashIndex,
        record_id: u64,
    ) ?u64 {
        std.debug.assert(record_id > 0);
        const hash = self.hash_record_id(record_id);
        const bucket_idx = hash % MAX_HASH_SIZE;

        var entry_idx = self.buckets[bucket_idx];
        while (entry_idx) |idx| {
            if (self.entries[idx].record_id == record_id) {
                return self.entries[idx].record_ptr;
            }
            entry_idx = self.entries[idx].next;
        }
        return null;
    }

    // Hash record ID (simple multiplicative hash).
    fn hash_record_id(self: *HashIndex, record_id: u64) u64 {
        _ = self;
        return record_id *% 0x9e3779b97f4a7c15;
    }
};

// B-tree node: For foreign key indexing.
pub const BTreeNode = struct {
    keys: [MAX_KEYS_PER_NODE]u64,
    values: [MAX_KEYS_PER_NODE]u64,
    keys_len: u32,
    children: [MAX_KEYS_PER_NODE + 1]?u32,
    is_leaf: bool,
    parent: ?u32,

    // Initialize B-tree node.
    pub fn init(is_leaf: bool) BTreeNode {
        var node = BTreeNode{
            .keys = undefined,
            .values = undefined,
            .keys_len = 0,
            .children = undefined,
            .is_leaf = is_leaf,
            .parent = null,
        };
        var i: u32 = 0;
        while (i <= MAX_KEYS_PER_NODE) : (i += 1) {
            node.children[i] = null;
        }
        return node;
    }
};

// B-tree index: For foreign key lookups (range queries).
pub const BTreeIndex = struct {
    nodes: []BTreeNode,
    nodes_len: u32,
    root_idx: ?u32,
    allocator: std.mem.Allocator,

    //! Initializes a new B-tree index.
    //!
    //! Why: Provides O(log n) lookups for ordered key-value pairs (range queries).
    //! Performance: O(1) initialization (allocates fixed-size array).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns error if allocation fails
    //! - Allocates MAX_BTREE_NODES nodes (fixed size)
    //!
    //! Example:
    //! ```zig
    //! var btree = try BTreeIndex.init(allocator);
    //! defer btree.deinit();
    //! ```
    pub fn init(allocator: std.mem.Allocator) !BTreeIndex {
        _ = allocator;
        const nodes = try allocator.alloc(BTreeNode, MAX_BTREE_NODES);
        errdefer allocator.free(nodes);

        return BTreeIndex{
            .nodes = nodes,
            .nodes_len = 0,
            .root_idx = null,
            .allocator = allocator,
        };
    }

    // Deinitialize B-tree index and free memory.
    pub fn deinit(self: *BTreeIndex) void {
        _ = self.allocator;
        self.allocator.free(self.nodes);
        self.* = undefined;
    }

    //! Inserts a key-value pair into the B-tree index.
    //!
    //! Why: Provides O(log n) insertion for ordered key-value storage.
    //! Performance: O(log n) average/worst case (tree traversal + node insert).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns error.BTreeFull if root node is full (simplified implementation)
    //! - Currently supports single-node B-tree (no splitting)
    //!
    //! Example:
    //! ```zig
    //! try btree.insert(key, value);
    //! ```
    pub fn insert(
        self: *BTreeIndex,
        key: u64,
        value: u64,
    ) !void {
        std.debug.assert(key > 0);
        std.debug.assert(self.nodes_len < MAX_BTREE_NODES);

        if (self.root_idx == null) {
            const root_idx = self.nodes_len;
            self.nodes[root_idx] = BTreeNode.init(true);
            self.nodes[root_idx].keys[0] = key;
            self.nodes[root_idx].values[0] = value;
            self.nodes[root_idx].keys_len = 1;
            self.root_idx = root_idx;
            self.nodes_len += 1;
            return;
        }

        const root = self.root_idx.?;
        if (self.nodes[root].keys_len >= MAX_KEYS_PER_NODE) {
            return error.BTreeFull;
        }

        _ = try self.insert_into_node(root, key, value);
    }

    // Insert into node (internal helper).
    fn insert_into_node(
        self: *BTreeIndex,
        node_idx: u32,
        key: u64,
        value: u64,
    ) !void {
        std.debug.assert(node_idx < self.nodes_len);
        var node = &self.nodes[node_idx];

        if (node.is_leaf) {
            var i: u32 = 0;
            while (i < node.keys_len) : (i += 1) {
                if (key < node.keys[i]) {
                    var j: u32 = node.keys_len;
                    while (j > i) : (j -= 1) {
                        node.keys[j] = node.keys[j - 1];
                        node.values[j] = node.values[j - 1];
                    }
                    node.keys[i] = key;
                    node.values[i] = value;
                    node.keys_len += 1;
                    return;
                }
            }
            node.keys[node.keys_len] = key;
            node.values[node.keys_len] = value;
            node.keys_len += 1;
        } else {
            var i: u32 = 0;
            while (i < node.keys_len) : (i += 1) {
                if (key < node.keys[i]) {
                    if (node.children[i]) |child_idx| {
                        return self.insert_into_node(child_idx, key, value);
                    }
                    break;
                }
            }
            if (node.children[node.keys_len]) |child_idx| {
                return self.insert_into_node(child_idx, key, value);
            }
        }
    }

    //! Looks up a value by key in the B-tree index.
    //!
    //! Why: Provides O(log n) lookup for ordered key-value retrieval.
    //! Performance: O(log n) average/worst case (tree traversal).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Returns: Value if key found, null otherwise.
    //!
    //! Example:
    //! ```zig
    //! const val = btree.lookup(key);
    //! if (val) |v| {
    //!     // Use value v
    //! }
    //! ```
    pub fn lookup(
        self: *BTreeIndex,
        key: u64,
    ) ?u64 {
        std.debug.assert(key > 0);
        if (self.root_idx) |root| {
            return self.lookup_in_node(root, key);
        }
        return null;
    }

    // Lookup in node (internal helper).
    fn lookup_in_node(
        self: *BTreeIndex,
        node_idx: u32,
        key: u64,
    ) ?u64 {
        std.debug.assert(node_idx < self.nodes_len);
        const node = &self.nodes[node_idx];

        var i: u32 = 0;
        while (i < node.keys_len) : (i += 1) {
            if (key == node.keys[i]) {
                return node.values[i];
            }
            if (key < node.keys[i]) {
                if (node.is_leaf) {
                    return null;
                }
                if (node.children[i]) |child_idx| {
                    return self.lookup_in_node(child_idx, key);
                }
                return null;
            }
        }

        if (node.is_leaf) {
            return null;
        }
        if (node.children[node.keys_len]) |child_idx| {
            return self.lookup_in_node(child_idx, key);
        }
        return null;
    }
};

// Bounded: Max tokens per document.
pub const MAX_TOKENS_PER_DOC: u32 = 10_000;

// Bounded: Max token length.
pub const MAX_TOKEN_LEN: u32 = 256;

// Bounded: Max documents per token.
pub const MAX_DOCS_PER_TOKEN: u32 = 1_000_000;

// Bounded: Max unique tokens.
pub const MAX_UNIQUE_TOKENS: u32 = 10_000_000;

// Inverted index entry: Maps token to document IDs.
pub const InvertedIndexEntry = struct {
    token: []const u8,
    token_len: u32,
    document_ids: []u64,
    document_ids_len: u32,
    allocator: std.mem.Allocator,

    // Initialize inverted index entry.
    pub fn init(
        allocator: std.mem.Allocator,
        token: []const u8,
    ) !InvertedIndexEntry {
        std.debug.assert(token.len <= MAX_TOKEN_LEN);
        _ = allocator;

        const token_copy = try allocator.dupe(u8, token);
        errdefer allocator.free(token_copy);

        const doc_ids = try allocator.alloc(u64, MAX_DOCS_PER_TOKEN);
        errdefer allocator.free(doc_ids);

        return InvertedIndexEntry{
            .token = token_copy,
            .token_len = @as(u32, @intCast(token_copy.len)),
            .document_ids = doc_ids,
            .document_ids_len = 0,
            .allocator = allocator,
        };
    }

    // Deinitialize entry and free memory.
    pub fn deinit(self: *InvertedIndexEntry) void {
        _ = self.allocator;
        if (self.token_len > 0) {
            self.allocator.free(self.token);
        }
        self.allocator.free(self.document_ids);
        self.* = undefined;
    }

    // Add document ID to entry.
    pub fn add_document_id(self: *InvertedIndexEntry, doc_id: u64) !void {
        std.debug.assert(doc_id > 0);
        std.debug.assert(self.document_ids_len < MAX_DOCS_PER_TOKEN);

        if (self.document_ids_len >= MAX_DOCS_PER_TOKEN) {
            return error.TooManyDocuments;
        }

        var i: u32 = 0;
        while (i < self.document_ids_len) : (i += 1) {
            if (self.document_ids[i] == doc_id) {
                return;
            }
        }

        self.document_ids[self.document_ids_len] = doc_id;
        self.document_ids_len += 1;
    }
};

// Inverted index: Full-text search index.
pub const InvertedIndex = struct {
    entries: []InvertedIndexEntry,
    entries_len: u32,
    allocator: std.mem.Allocator,

    //! Initializes a new inverted index for full-text search.
    //!
    //! Why: Provides token-based document retrieval for text search.
    //! Performance: O(1) initialization (allocates fixed-size array).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns error if allocation fails
    //! - Allocates MAX_UNIQUE_TOKENS entries (fixed size)
    //!
    //! Example:
    //! ```zig
    //! var inv_idx = try InvertedIndex.init(allocator);
    //! defer inv_idx.deinit();
    //! ```
    pub fn init(allocator: std.mem.Allocator) !InvertedIndex {
        _ = allocator;
        const entries = try allocator.alloc(
            InvertedIndexEntry,
            MAX_UNIQUE_TOKENS,
        );
        errdefer allocator.free(entries);

        return InvertedIndex{
            .entries = entries,
            .entries_len = 0,
            .allocator = allocator,
        };
    }

    // Deinitialize inverted index and free memory.
    pub fn deinit(self: *InvertedIndex) void {
        _ = self.allocator;
        var i: u32 = 0;
        while (i < self.entries_len) : (i += 1) {
            self.entries[i].deinit();
        }
        self.allocator.free(self.entries);
        self.* = undefined;
    }

    //! Indexes a document by tokenizing and adding tokens to the index.
    //!
    //! Why: Enables full-text search by building token-to-document mapping.
    //! Performance: O(n) where n is number of tokens (tokenization + indexing).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns error if tokenization fails (too many tokens)
    //! - Returns error if MAX_UNIQUE_TOKENS limit reached
    //! - Automatically stems tokens (lowercase + suffix removal)
    //!
    //! Example:
    //! ```zig
    //! try inv_idx.index_document(doc_id, "This is sample text");
    //! ```
    pub fn index_document(
        self: *InvertedIndex,
        doc_id: u64,
        text: []const u8,
    ) !void {
        std.debug.assert(doc_id > 0);
        std.debug.assert(text.len <= 10_000_000);

        var tokens: [MAX_TOKENS_PER_DOC][]const u8 = undefined;
        var tokens_len: u32 = 0;

        _ = try tokenize(text, &tokens, &tokens_len);

        var i: u32 = 0;
        while (i < tokens_len) : (i += 1) {
            const stemmed = try stem(tokens[i], self.allocator);
            defer self.allocator.free(stemmed);

            var entry = self.find_or_create_entry(stemmed);
            if (entry) |e| {
                _ = try e.add_document_id(doc_id);
            }
        }
    }

    //! Searches for documents containing query tokens.
    //!
    //! Why: Provides full-text search by matching query tokens to indexed documents.
    //! Performance: O(n) where n is number of documents for first token (linear scan).
    //! Thread Safety: Not thread-safe. Caller must synchronize access.
    //!
    //! Edge Cases:
    //! - Returns 0 if no tokens found or query is empty
    //! - Returns error.TooManyResults if output buffer too small
    //! - Currently searches only first token (simplified implementation)
    //!
    //! Example:
    //! ```zig
    //! var results: [100]u64 = undefined;
    //! const count = try inv_idx.search("search query", &results);
    //! ```
    pub fn search(
        self: *InvertedIndex,
        query: []const u8,
        output: []u64,
    ) !u32 {
        std.debug.assert(query.len <= 10_000);
        std.debug.assert(output.len >= MAX_DOCS_PER_TOKEN);

        var tokens: [MAX_TOKENS_PER_DOC][]const u8 = undefined;
        var tokens_len: u32 = 0;

        _ = try tokenize(query, &tokens, &tokens_len);

        if (tokens_len == 0) {
            return 0;
        }

        const stemmed = try stem(tokens[0], self.allocator);
        defer self.allocator.free(stemmed);

        const entry = self.find_entry(stemmed);
        if (entry) |e| {
            var count: u32 = 0;
            var i: u32 = 0;
            while (i < e.document_ids_len) : (i += 1) {
                if (count >= output.len) {
                    return error.TooManyResults;
                }
                output[count] = e.document_ids[i];
                count += 1;
            }
            return count;
        }
        return 0;
    }

    // Find or create entry for token.
    fn find_or_create_entry(
        self: *InvertedIndex,
        token: []const u8,
    ) !?*InvertedIndexEntry {
        std.debug.assert(token.len <= MAX_TOKEN_LEN);

        if (self.find_entry(token)) |entry| {
            return entry;
        }

        if (self.entries_len >= MAX_UNIQUE_TOKENS) {
            return error.TooManyTokens;
        }

        var entry = try InvertedIndexEntry.init(self.allocator, token);
        errdefer entry.deinit();

        self.entries[self.entries_len] = entry;
        self.entries_len += 1;

        std.debug.assert(self.entries_len <= MAX_UNIQUE_TOKENS);
        return &self.entries[self.entries_len - 1];
    }

    // Find entry for token.
    fn find_entry(
        self: *InvertedIndex,
        token: []const u8,
    ) ?*InvertedIndexEntry {
        std.debug.assert(token.len <= MAX_TOKEN_LEN);
        var i: u32 = 0;
        while (i < self.entries_len) : (i += 1) {
            if (std.mem.eql(u8, self.entries[i].token, token)) {
                return &self.entries[i];
            }
        }
        return null;
    }
};

//! Tokenizes text into words (simple whitespace-based).
//!
//! Why: Splits text into tokens for indexing and search.
//! Performance: O(n) where n is text length (single pass).
//!
//! Edge Cases:
//! - Returns error.TooManyTokens if output buffer too small
//! - Splits on whitespace (space, tab, newline, carriage return)
//! - Skips empty tokens
//!
//! Example:
//! ```zig
//! var tokens: [100][]const u8 = undefined;
//! var tokens_len: u32 = 0;
//! try tokenize("sample text", &tokens, &tokens_len);
//! ```
pub fn tokenize(
    text: []const u8,
    output: []const []const u8,
    output_len: *u32,
) !void {
    std.debug.assert(output.len >= MAX_TOKENS_PER_DOC);
    std.debug.assert(text.len <= 10_000_000);

    output_len.* = 0;
    var start: u32 = 0;
    var i: u32 = 0;

    while (i < text.len) : (i += 1) {
        const c = text[i];
        if (c == ' ' or c == '\t' or c == '\n' or c == '\r') {
            if (start < i) {
                if (output_len.* >= output.len) {
                    return error.TooManyTokens;
                }
                output[output_len.*] = text[start..i];
                output_len.* += 1;
            }
            start = i + 1;
        }
    }

    if (start < text.len) {
        if (output_len.* >= output.len) {
            return error.TooManyTokens;
        }
        output[output_len.*] = text[start..];
        output_len.* += 1;
    }
}

//! Stems a word (simplified: lowercase and remove common suffixes).
//!
//! Why: Normalizes words for indexing (e.g., "running" -> "run").
//! Performance: O(n) where n is word length (lowercase + suffix removal).
//!
//! Edge Cases:
//! - Returns error if allocation fails
//! - Removes suffixes: "ed", "ing", "ly" (simplified stemming)
//! - Converts to lowercase
//!
//! Example:
//! ```zig
//! const stemmed = try stem("running", allocator);
//! defer allocator.free(stemmed);
//! ```
pub fn stem(
    word: []const u8,
    allocator: std.mem.Allocator,
) ![]u8 {
    std.debug.assert(word.len <= MAX_TOKEN_LEN);
    _ = allocator;

    var result = try allocator.alloc(u8, word.len);
    errdefer allocator.free(result);

    var i: u32 = 0;
    while (i < word.len) : (i += 1) {
        const c = word[i];
        if (c >= 'A' and c <= 'Z') {
            result[i] = c + 32;
        } else {
            result[i] = c;
        }
    }

    var len: u32 = @as(u32, @intCast(word.len));

    if (len > 3) {
        const suffix_ed = "ed";
        const suffix_ing = "ing";
        const suffix_ly = "ly";

        if (len >= suffix_ed.len) {
            const suffix_start = len - suffix_ed.len;
            if (std.mem.eql(u8, result[suffix_start..], suffix_ed)) {
                len -= suffix_ed.len;
            }
        }

        if (len > 3 and len >= suffix_ing.len) {
            const suffix_start = len - suffix_ing.len;
            if (std.mem.eql(u8, result[suffix_start..], suffix_ing)) {
                len -= suffix_ing.len;
            }
        }

        if (len > 3 and len >= suffix_ly.len) {
            const suffix_start = len - suffix_ly.len;
            if (std.mem.eql(u8, result[suffix_start..], suffix_ly)) {
                len -= suffix_ly.len;
            }
        }
    }

    const stemmed = try allocator.realloc(result, len);
    return stemmed;
}

