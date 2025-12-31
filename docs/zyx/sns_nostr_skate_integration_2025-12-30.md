# SNS .sol Domain → Nostr → Skate Knowledge Graph Integration

**Date**: 2025-12-30  
**Agent**: Grain Free Agent (Glow G2)  
**Status**: Design Proposal  
**Integration Points**: SNS (.sol domains), Solana L1 Identity, Nostr relays, Skate knowledge graph

---

## Executive Summary

This document proposes integrating **Solana Name Service (SNS) .sol domains** with **Nostr relay software** and the **Skate knowledge graph** in Grain OS. The integration enables automatic resolution of `.sol` domain names to Nostr addresses (`npub`), creating a seamless bridge between Solana identity, Nostr social networking, and Skate's block-based knowledge graph.

**Key Innovation**: `.sol` domains (human-readable Solana identity) automatically resolve to Nostr `npub` addresses, enabling users to:
- Use their `.sol` domain (e.g., "keaton.sol") as their identity across Grain OS
- Automatically connect to Nostr relays using their `.sol` domain
- Link Nostr events to Skate knowledge graph blocks
- Create a unified social network across Solana, Nostr, and Skate

---

## 1. Architecture Overview

### 1.1 Integration Flow

```
User Input: "keaton.sol"
    ↓
SNS Resolution (via Solana RPC)
    ↓
Solana L1 Identity Contract
    ↓
Identity Account (contains Nostr npub)
    ↓
Nostr Relay Connection (using npub)
    ↓
Nostr Events (notes, profiles, replies)
    ↓
Skate Knowledge Graph Blocks
    ↓
Social Threading & Replies
```

### 1.2 Component Integration

**Three-Layer Integration**:
1. **SNS Layer**: `.sol` domain registration and resolution (Solana blockchain)
2. **Nostr Layer**: Nostr relay communication and event handling (decentralized social)
3. **Skate Layer**: Knowledge graph blocks with social threading (local-first)

**Unified Identity**:
- **Primary Identity**: `.sol` domain (e.g., "keaton.sol")
- **Solana Address**: 32-byte Ed25519 public key (from SNS resolution)
- **Nostr npub**: Bech32-encoded Ed25519 public key (stored in Identity Contract)
- **Skate Block ID**: Local block identifier (linked to identity)

---

## 2. Enhanced Identity Contract

### 2.1 Identity Account Structure

**Updated Identity Account** (extends existing Solana L1 Identity Contract):

```zig
// Identity Account (Solana Program)
pub const IdentityAccount = struct {
    identity_pubkey: [32]u8,        // Solana public key (Ed25519)
    sns_domain: [64]u8,             // SNS .sol domain (e.g., "keaton.sol")
    sns_domain_len: u32,
    
    // Nostr Integration
    nostr_npub: [64]u8,              // Nostr npub (Bech32-encoded, e.g., "npub1...")
    nostr_npub_len: u32,
    nostr_relays: [MAX_NOSTR_RELAYS][256]u8, // Preferred Nostr relay URLs
    nostr_relays_len: u32,
    
    // Standard Identity Fields
    name: [64]u8,
    name_len: u32,
    email: [256]u8,
    email_len: u32,
    avatar_hash: [32]u8,
    signing_key: [32]u8,            // Ed25519
    encryption_key: [32]u8,         // X25519
    created_at: i64,
    updated_at: i64,
    active: bool,
    verified: bool,
    grain_os_version: [16]u8,
    device_ids: [MAX_DEVICES][32]u8,
    device_ids_len: u32,
    
    // Skate Integration
    skate_block_id: ?u32,           // Primary Skate block ID (optional)
    skate_blocks_count: u32,        // Number of Skate blocks linked to this identity
};

// Bounded: Max Nostr relays per identity
pub const MAX_NOSTR_RELAYS: u32 = 10;
```

### 2.2 Identity Operations

**New Operations** (extend existing contract):

```zig
// Link Nostr npub to identity
pub fn link_nostr_npub(
    identity_pubkey: [32]u8,
    nostr_npub: []const u8,         // Bech32-encoded npub
    relays: []const []const u8,     // Preferred relay URLs
    signature: [64]u8,
) !void;

// Update Nostr relays
pub fn update_nostr_relays(
    identity_pubkey: [32]u8,
    relays: []const []const u8,
    signature: [64]u8,
) !void;

// Link Skate block to identity
pub fn link_skate_block(
    identity_pubkey: [32]u8,
    skate_block_id: u32,
    signature: [64]u8,
) !void;

// Resolve .sol domain to Nostr npub
pub fn resolve_sns_to_nostr(
    sns_domain: []const u8,         // e.g., "keaton.sol"
) ?[]const u8;                       // Returns npub if found

// Resolve Nostr npub to .sol domain (reverse lookup)
pub fn resolve_nostr_to_sns(
    nostr_npub: []const u8,         // e.g., "npub1..."
) ?[]const u8;                       // Returns .sol domain if found
```

---

## 3. SNS → Nostr Resolution

### 3.1 Automatic Resolution Module

**File**: `src/grain_solana/sns_nostr_resolver.zig`

```zig
/// SNS → Nostr Resolver: Automatically resolve .sol domains to Nostr npub addresses.
/// Why: Enable seamless identity resolution across Solana and Nostr ecosystems.
/// GrainStyle: Explicit types, bounded allocations, deterministic behavior.
pub const SnsNostrResolver = struct {
    rpc_client: *GrainSolanaRpcClient,
    identity_manager: *GlobalIdentityManager,
    allocator: std.mem.Allocator,
    
    /// Bounded: Max resolution cache entries (100).
    /// Why: Limit cache size, ensure deterministic behavior.
    pub const MAX_CACHE_ENTRIES: u32 = 100;
    
    /// Resolution cache entry.
    pub const CacheEntry = struct {
        sns_domain: [64]u8,
        sns_domain_len: u32,
        nostr_npub: [64]u8,
        nostr_npub_len: u32,
        cached_at: u64,              // Unix timestamp
    };
    
    cache: []CacheEntry,
    cache_len: u32,
    
    /// Initialize SNS → Nostr resolver.
    pub fn init(
        allocator: std.mem.Allocator,
        rpc_client: *GrainSolanaRpcClient,
        identity_manager: *GlobalIdentityManager,
    ) !SnsNostrResolver {
        const cache = try allocator.alloc(CacheEntry, MAX_CACHE_ENTRIES);
        
        return SnsNostrResolver{
            .allocator = allocator,
            .rpc_client = rpc_client,
            .identity_manager = identity_manager,
            .cache = cache,
            .cache_len = 0,
        };
    }
    
    /// Deinitialize resolver and free memory.
    pub fn deinit(self: *SnsNostrResolver) void {
        self.allocator.free(self.cache);
        self.* = undefined;
    }
    
    /// Resolve .sol domain to Nostr npub.
    /// Why: Enable automatic resolution of .sol domains to Nostr addresses.
    /// Contract: sns_domain must be valid .sol domain (e.g., "keaton.sol").
    pub fn resolve_sns_to_nostr(
        self: *SnsNostrResolver,
        sns_domain: []const u8,
    ) !?[]const u8 {
        // Assert: Domain must be non-empty (precondition).
        std.debug.assert(sns_domain.len > 0);
        std.debug.assert(sns_domain.len <= 64);
        
        // Check cache first
        if (self.get_from_cache(sns_domain)) |cached_npub| {
            return cached_npub;
        }
        
        // Resolve .sol domain to Solana address (via SNS RPC)
        const solana_address = try self.rpc_client.sns.resolve_sns_domain(sns_domain);
        
        // Load identity account (via RPC)
        const identity = try self.rpc_client.identity.get_identity_account(solana_address);
        
        // Extract Nostr npub from identity account
        if (identity.nostr_npub_len > 0) {
            const npub = try self.allocator.dupe(
                u8,
                identity.nostr_npub[0..identity.nostr_npub_len],
            );
            
            // Cache result
            try self.add_to_cache(sns_domain, npub);
            
            return npub;
        }
        
        // No Nostr npub linked to this identity
        return null;
    }
    
    /// Resolve Nostr npub to .sol domain (reverse lookup).
    /// Why: Enable reverse resolution for Nostr → Solana identity mapping.
    pub fn resolve_nostr_to_sns(
        self: *SnsNostrResolver,
        nostr_npub: []const u8,
    ) !?[]const u8 {
        // Assert: npub must be valid (precondition).
        std.debug.assert(nostr_npub.len > 0);
        std.debug.assert(nostr_npub.len <= 64);
        
        // Query identity accounts for matching npub (via RPC)
        // Note: This requires indexing by npub, which may need additional RPC methods
        const sns_domain = try self.rpc_client.identity.reverse_lookup_nostr(nostr_npub);
        
        return sns_domain;
    }
    
    /// Get from cache (helper).
    fn get_from_cache(self: *SnsNostrResolver, sns_domain: []const u8) ?[]const u8 {
        var i: u32 = 0;
        while (i < self.cache_len) : (i += 1) {
            const entry = &self.cache[i];
            if (std.mem.eql(
                u8,
                sns_domain,
                entry.sns_domain[0..entry.sns_domain_len],
            )) {
                // Check cache expiration (1 hour)
                const now = std.time.timestamp();
                if (now - entry.cached_at < 3600) {
                    return entry.nostr_npub[0..entry.nostr_npub_len];
                }
            }
        }
        return null;
    }
    
    /// Add to cache (helper).
    fn add_to_cache(
        self: *SnsNostrResolver,
        sns_domain: []const u8,
        nostr_npub: []const u8,
    ) !void {
        if (self.cache_len >= MAX_CACHE_ENTRIES) {
            // Evict oldest entry (simple LRU)
            std.mem.copy(
                u8,
                &self.cache[0].sns_domain,
                &self.cache[1].sns_domain,
            );
            self.cache_len -= 1;
        }
        
        const entry = &self.cache[self.cache_len];
        std.mem.copy(u8, entry.sns_domain[0..], sns_domain);
        entry.sns_domain_len = @intCast(sns_domain.len);
        std.mem.copy(u8, entry.nostr_npub[0..], nostr_npub);
        entry.nostr_npub_len = @intCast(nostr_npub.len);
        entry.cached_at = @intCast(std.time.timestamp());
        
        self.cache_len += 1;
    }
};
```

---

## 4. Nostr Relay Integration

### 4.1 Enhanced Dream Browser Nostr Module

**File**: `src/dream_browser_nostr.zig` (extend existing)

**New Features**:
- Accept `.sol` domain as input (in addition to `npub`)
- Automatically resolve `.sol` → `npub` before connecting to relays
- Use preferred relays from Identity Contract

```zig
/// Enhanced Nostr URL parsing (supports .sol domains).
pub fn parse_nostr_url_enhanced(
    self: *DreamBrowserNostr,
    url: []const u8,
    sns_resolver: *SnsNostrResolver,
) !NostrUrl {
    // Check if URL is .sol domain
    if (std.mem.endsWith(u8, url, ".sol")) {
        // Resolve .sol domain to npub
        const npub = try sns_resolver.resolve_sns_to_nostr(url);
        if (npub) |resolved_npub| {
            // Parse as npub URL
            return self.parse_nostr_url(resolved_npub);
        } else {
            return error.NostrNpubNotFound;
        }
    }
    
    // Standard Nostr URL parsing (existing implementation)
    return self.parse_nostr_url(url);
}

/// Subscribe to Nostr events using .sol domain.
pub fn subscribe_to_sns_domain(
    self: *DreamBrowserNostr,
    sns_domain: []const u8,         // e.g., "keaton.sol"
    sns_resolver: *SnsNostrResolver,
) ![]const u8 {
    // Resolve .sol domain to npub
    const npub = try sns_resolver.resolve_sns_to_nostr(sns_domain);
    if (npub) |resolved_npub| {
        // Subscribe using resolved npub
        const url = try self.parse_nostr_url(resolved_npub);
        return self.subscribeToNostr(url, null); // Use default relays
    } else {
        return error.NostrNpubNotFound;
    }
}
```

---

## 5. Skate Knowledge Graph Integration

### 5.1 Nostr → Skate Block Mapping

**File**: `src/grain_skate/nostr_integration.zig`

```zig
/// Nostr → Skate Integration: Link Nostr events to Skate knowledge graph blocks.
/// Why: Enable social networking across Nostr and Skate knowledge graphs.
/// GrainStyle: Explicit types, bounded allocations, deterministic behavior.
pub const NostrSkateIntegration = struct {
    social_manager: *Social.SocialManager,
    block_storage: *Block.BlockStorage,
    sns_resolver: *SnsNostrResolver,
    allocator: std.mem.Allocator,
    
    /// Bounded: Max Nostr events per block (100).
    /// Why: Limit event associations, ensure deterministic behavior.
    pub const MAX_NOSTR_EVENTS_PER_BLOCK: u32 = 100;
    
    /// Nostr event → Skate block mapping.
    pub const NostrBlockMapping = struct {
        nostr_event_id: [64]u8,     // Nostr event ID (hex)
        skate_block_id: u32,         // Skate block ID
        created_at: u64,              // Mapping creation timestamp
    };
    
    mappings: []NostrBlockMapping,
    mappings_len: u32,
    
    /// Initialize Nostr → Skate integration.
    pub fn init(
        allocator: std.mem.Allocator,
        social_manager: *Social.SocialManager,
        block_storage: *Block.BlockStorage,
        sns_resolver: *SnsNostrResolver,
    ) !NostrSkateIntegration {
        const mappings = try allocator.alloc(
            NostrBlockMapping,
            MAX_NOSTR_EVENTS_PER_BLOCK * 1000, // Max 1000 blocks with Nostr events
        );
        
        return NostrSkateIntegration{
            .allocator = allocator,
            .social_manager = social_manager,
            .block_storage = block_storage,
            .sns_resolver = sns_resolver,
            .mappings = mappings,
            .mappings_len = 0,
        };
    }
    
    /// Deinitialize integration and free memory.
    pub fn deinit(self: *NostrSkateIntegration) void {
        self.allocator.free(self.mappings);
        self.* = undefined;
    }
    
    /// Create Skate block from Nostr event.
    /// Why: Enable Nostr events to become Skate knowledge graph blocks.
    pub fn create_block_from_nostr_event(
        self: *NostrSkateIntegration,
        nostr_event: DreamProtocol.Event,
        sns_domain: ?[]const u8,    // Optional .sol domain for author
    ) !u32 {
        // Assert: Event must be valid (precondition).
        std.debug.assert(nostr_event.id.len > 0);
        
        // Create new Skate block
        const block_id = try self.block_storage.create_block(
            nostr_event.content,
            null, // No title initially
        );
        
        // Link Nostr event to Skate block
        try self.link_nostr_event_to_block(nostr_event.id, block_id);
        
        // If .sol domain provided, resolve to identity and link
        if (sns_domain) |domain| {
            const npub = try self.sns_resolver.resolve_sns_to_nostr(domain);
            if (npub) |resolved_npub| {
                // Link block to identity (via .sol domain)
                try self.link_block_to_identity(block_id, domain);
            }
        }
        
        return block_id;
    }
    
    /// Link Nostr event to Skate block.
    fn link_nostr_event_to_block(
        self: *NostrSkateIntegration,
        nostr_event_id: []const u8,
        skate_block_id: u32,
    ) !void {
        // Assert: Mapping limit (precondition).
        if (self.mappings_len >= self.mappings.len) {
            return error.MappingLimitReached;
        }
        
        const mapping = &self.mappings[self.mappings_len];
        std.mem.copy(u8, mapping.nostr_event_id[0..], nostr_event_id);
        mapping.skate_block_id = skate_block_id;
        mapping.created_at = @intCast(std.time.timestamp());
        
        self.mappings_len += 1;
    }
    
    /// Link Skate block to identity (via .sol domain).
    fn link_block_to_identity(
        self: *NostrSkateIntegration,
        skate_block_id: u32,
        sns_domain: []const u8,
    ) !void {
        // Resolve .sol domain to Solana address
        const solana_address = try self.sns_resolver.rpc_client.sns.resolve_sns_domain(sns_domain);
        
        // Link block to identity (via RPC)
        try self.sns_resolver.rpc_client.identity.link_skate_block(
            solana_address,
            skate_block_id,
        );
    }
    
    /// Find Skate block by Nostr event ID.
    pub fn find_block_by_nostr_event(
        self: *NostrSkateIntegration,
        nostr_event_id: []const u8,
    ) ?u32 {
        var i: u32 = 0;
        while (i < self.mappings_len) : (i += 1) {
            const mapping = &self.mappings[i];
            if (std.mem.eql(u8, nostr_event_id, mapping.nostr_event_id[0..])) {
                return mapping.skate_block_id;
            }
        }
        return null;
    }
    
    /// Create reply thread from Nostr event chain.
    /// Why: Enable Nostr reply chains to become Skate social threads.
    pub fn create_reply_thread_from_nostr(
        self: *NostrSkateIntegration,
        nostr_events: []DreamProtocol.Event,
    ) !void {
        // Assert: Events must be non-empty (precondition).
        std.debug.assert(nostr_events.len > 0);
        
        // Create blocks for each Nostr event
        var block_ids: [MAX_NOSTR_EVENTS_PER_BLOCK]u32 = undefined;
        var block_ids_len: u32 = 0;
        
        for (nostr_events) |event| {
            const block_id = try self.create_block_from_nostr_event(event, null);
            block_ids[block_ids_len] = block_id;
            block_ids_len += 1;
        }
        
        // Create reply relationships (chain events)
        var i: u32 = 1;
        while (i < block_ids_len) : (i += 1) {
            const reply_block_id = block_ids[i];
            const parent_block_id = block_ids[i - 1];
            
            // Create reply relationship
            try self.social_manager.create_reply(reply_block_id, parent_block_id);
        }
    }
};
```

---

## 6. Unified Identity Flow

### 6.1 User Experience

**Scenario 1: User creates identity with .sol domain and Nostr npub**

```
1. User registers "keaton.sol" via SNS
2. User creates Solana L1 Identity Contract
3. User links Nostr npub to identity (via Identity Contract)
4. User links preferred Nostr relays
5. Identity is now unified: .sol domain → Solana address → Nostr npub
```

**Scenario 2: User subscribes to Nostr feed using .sol domain**

```
1. User enters "keaton.sol" in Dream Browser
2. SNS → Nostr resolver resolves "keaton.sol" → npub
3. Dream Browser connects to Nostr relays (using npub)
4. Nostr events are received and displayed
5. User can create Skate blocks from Nostr events
```

**Scenario 3: User creates Skate block linked to .sol domain**

```
1. User creates Skate block in knowledge graph
2. User links block to their .sol domain identity
3. Block is stored locally (Skate)
4. Block can be published to Nostr (optional)
5. Block appears in social network (via .sol domain)
```

---

## 7. Implementation Plan

### 7.1 Phase 1: Enhanced Identity Contract (Weeks 1-2)

**Priority**: **HIGHEST** — Foundation for integration

**Tasks**:
- Extend Identity Account structure (add Nostr npub, relays, Skate block ID)
- Implement `link_nostr_npub` contract operation
- Implement `link_skate_block` contract operation
- Implement `resolve_sns_to_nostr` contract operation
- Deploy updated contract to Solana devnet
- Test contract operations

**Deliverables**:
- ✅ Enhanced Identity Account structure
- ✅ Contract operations for Nostr/Skate linking
- ✅ RPC methods for resolution
- ✅ Tests and documentation

---

### 7.2 Phase 2: SNS → Nostr Resolver (Weeks 3-4)

**Priority**: **HIGH** — Core resolution functionality

**Tasks**:
- Implement `SnsNostrResolver` module
- Implement resolution cache (LRU)
- Integrate with existing SNS RPC methods
- Integrate with Identity RPC methods
- Test resolution (with and without cache)
- Performance optimization

**Deliverables**:
- ✅ SNS → Nostr resolver module
- ✅ Resolution cache
- ✅ Integration with RPC client
- ✅ Tests and documentation

---

### 7.3 Phase 3: Dream Browser Nostr Enhancement (Weeks 5-6)

**Priority**: **HIGH** — User-facing functionality

**Tasks**:
- Extend `DreamBrowserNostr` to accept .sol domains
- Implement automatic .sol → npub resolution
- Use preferred relays from Identity Contract
- Update UI to show .sol domain (instead of npub)
- Test end-to-end flow (user enters .sol domain → Nostr feed)

**Deliverables**:
- ✅ Enhanced Dream Browser Nostr module
- ✅ .sol domain support in UI
- ✅ Automatic resolution
- ✅ Tests and documentation

---

### 7.4 Phase 4: Skate Knowledge Graph Integration (Weeks 7-8)

**Priority**: **MEDIUM** — Social networking features

**Tasks**:
- Implement `NostrSkateIntegration` module
- Implement Nostr event → Skate block mapping
- Implement reply thread creation from Nostr events
- Integrate with Skate social manager
- Test Nostr → Skate block creation
- Test reply threading

**Deliverables**:
- ✅ Nostr → Skate integration module
- ✅ Event → block mapping
- ✅ Reply threading
- ✅ Tests and documentation

---

### 7.5 Phase 5: End-to-End Integration (Weeks 9-10)

**Priority**: **HIGH** — Complete user experience

**Tasks**:
- Integrate all components (SNS, Nostr, Skate)
- Test complete user flows
- Performance optimization
- Error handling and edge cases
- Documentation and examples

**Deliverables**:
- ✅ Complete integration
- ✅ End-to-end tests
- ✅ User documentation
- ✅ Developer documentation

---

## 8. Technical Considerations

### 8.1 Key Format Differences

**Solana vs. Nostr Keys**:
- **Solana**: 32-byte Ed25519 public key (base58 encoded)
- **Nostr**: 32-byte Ed25519 public key (Bech32 encoded as `npub`)
- **Note**: Both use Ed25519, but they are **different keypairs** (cannot directly convert)

**Solution**: Store Nostr npub in Identity Contract (separate from Solana address)

### 8.2 Resolution Performance

**Caching Strategy**:
- **LRU Cache**: Cache .sol → npub resolutions (1-hour TTL)
- **Cache Size**: Bounded (100 entries)
- **Cache Hit Rate Target**: >80% for repeated lookups

**RPC Optimization**:
- Batch resolution requests when possible
- Use connection pooling (from existing RPC client)
- Cache identity account data locally

### 8.3 Error Handling

**Resolution Failures**:
- `.sol` domain not found → Return error, suggest domain registration
- `npub` not linked → Return error, suggest linking npub to identity
- Relay connection failure → Fallback to default relays
- Cache miss → Query RPC, update cache

**Edge Cases**:
- Domain expired (SNS renewal)
- Identity account deleted
- Nostr relay offline
- Skate block storage full

---

## 9. Benefits

### 9.1 User Experience

**Unified Identity**:
- Single `.sol` domain works across Solana, Nostr, and Skate
- Human-readable names (easier to remember/share)
- Automatic resolution (no manual npub lookup)

**Social Networking**:
- Nostr events automatically linked to Skate blocks
- Reply threads work across Nostr and Skate
- Unified social graph (Solana + Nostr + Skate)

### 9.2 Technical Benefits

**Decentralization**:
- Solana blockchain (identity)
- Nostr relays (social networking)
- Local-first Skate (knowledge graph)

**Interoperability**:
- Bridge between Solana and Nostr ecosystems
- Enable cross-platform social networking
- Unified identity across protocols

---

## 10. Future Enhancements

### 10.1 Bidirectional Sync

**Nostr → Skate**:
- Automatically create Skate blocks from Nostr events
- Sync reply threads
- Sync profile updates

**Skate → Nostr**:
- Publish Skate blocks to Nostr (optional)
- Share knowledge graph blocks
- Enable social discovery

### 10.2 Advanced Features

**Multi-Identity Support**:
- Link multiple Nostr npubs to single .sol domain
- Link multiple .sol domains to single Nostr npub
- Identity aggregation

**Social Graph Analysis**:
- Analyze connections across Solana, Nostr, and Skate
- Discover related identities
- Recommend connections

---

## 11. Conclusion

This integration proposal enables seamless identity resolution across Solana (SNS), Nostr (social networking), and Skate (knowledge graph). By automatically resolving `.sol` domains to Nostr addresses, users can use a single human-readable identity across all three systems, creating a unified social network experience.

**Key Innovation**: `.sol` domains automatically resolve to Nostr `npub` addresses, enabling users to:
- Use their `.sol` domain as their identity across Grain OS
- Automatically connect to Nostr relays
- Link Nostr events to Skate knowledge graph blocks
- Create a unified social network

**Implementation Timeline**: 10 weeks (2.5 months)

**Next Steps**:
1. Review proposal with Core Agent and Skate Agent
2. Begin Phase 1: Enhanced Identity Contract
3. Coordinate with existing SNS integration work
4. Test with Nostr relays and Skate knowledge graph

---

**Date**: 2025-12-30  
**Agent**: Grain Free Agent (Glow G2)  
**Status**: Design Proposal — Ready for Review
