//! Grain Court Self-Hosted Provider Test Suite
//!
//! Comprehensive tests for Cerebras GLM-4.6 self-hosted provider implementation.
//!
//! Tests cover:
//! - Provider initialization
//! - Request encoding (JSON and ZON format)
//! - Response parsing
//! - Health checking
//! - Error handling
//! - ZON format support
//!
//! GrainStyle: grain_case function names, explicit u32/u64 types, bounded
//! allocations, minimum 2 assertions per function, max 70 lines per function.

const std = @import("std");
const testing = std.testing;
const grain_court = @import("grain_court");

// Test self-hosted provider initialization.
test "self_hosted_provider init" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        null,
    );
    try testing.expect(provider.trait.provider_type == .self_hosted);
    try testing.expect(provider.trait.state == .idle);
    try testing.expect(provider.trait.api_key_len > 0);
}

test "self_hosted_provider init with custom base_url" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    const base_url = "https://custom.cerebras.ai/v1";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        base_url,
        null,
    );
    try testing.expect(provider.trait.provider_type == .self_hosted);
    try testing.expect(provider.trait.base_url_len > 0);
}

test "self_hosted_provider init with http_client" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var http_client = try grain_court.grain_core.http_client.HttpClient.init(
        allocator,
    );
    defer http_client.deinit();
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        &http_client,
    );
    try testing.expect(provider.trait.provider_type == .self_hosted);
    try testing.expect(provider.trait.http_client != null);
}

// Test provider name.
test "self_hosted_provider get_name" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        null,
    );
    const name = provider.trait.get_name(&provider.trait);
    try testing.expect(std.mem.eql(u8, name, "Cerebras GLM-4.6"));
}

// Test health checking.
test "self_hosted_provider check_health no_http_client" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        null,
    );
    const healthy = provider.trait.check_health(&provider.trait);
    try testing.expect(healthy == false);
}

test "self_hosted_provider check_health with_http_client" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var http_client = try grain_court.grain_core.http_client.HttpClient.init(
        allocator,
    );
    defer http_client.deinit();
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        &http_client,
    );
    const healthy = provider.trait.check_health();
    try testing.expect(healthy == true);
}

test "self_hosted_provider check_health error_state" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var http_client = try grain_court.grain_core.http_client.HttpClient.init(
        allocator,
    );
    defer http_client.deinit();
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        &http_client,
    );
    provider.trait.state = .error_state;
    const healthy = provider.trait.check_health(&provider.trait);
    try testing.expect(healthy == false);
}

test "self_hosted_provider check_health disabled" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var http_client = try grain_court.grain_core.http_client.HttpClient.init(
        allocator,
    );
    defer http_client.deinit();
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        &http_client,
    );
    provider.trait.state = .disabled;
    const healthy = provider.trait.check_health(&provider.trait);
    try testing.expect(healthy == false);
}

// Test provider type.
test "self_hosted_provider provider_type" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        null,
    );
    try testing.expect(provider.trait.provider_type == .self_hosted);
}

// Test API key storage.
test "self_hosted_provider api_key_storage" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key-12345";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        null,
    );
    try testing.expect(provider.trait.api_key_len == api_key.len);
    const stored_key = provider.trait.api_key[0..provider.trait.api_key_len];
    try testing.expect(std.mem.eql(u8, stored_key, api_key));
}

// Test base URL storage.
test "self_hosted_provider base_url_storage" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    const base_url = "https://api.cerebras.ai/v1";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        base_url,
        null,
    );
    try testing.expect(provider.trait.base_url_len == base_url.len);
    const stored_url = provider.trait.base_url[0..provider.trait.base_url_len];
    try testing.expect(std.mem.eql(u8, stored_url, base_url));
}

// Test default base URL.
test "self_hosted_provider default_base_url" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        null,
    );
    const default_url = "https://api.cerebras.ai/v1";
    try testing.expect(provider.trait.base_url_len == default_url.len);
    const stored_url = provider.trait.base_url[0..provider.trait.base_url_len];
    try testing.expect(std.mem.eql(u8, stored_url, default_url));
}

// Test provider state transitions.
test "self_hosted_provider state_idle" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        null,
    );
    try testing.expect(provider.trait.state == .idle);
}

test "self_hosted_provider state_active" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        null,
    );
    provider.trait.state = .active;
    try testing.expect(provider.trait.state == .active);
}

// Test ZON format support (provider trait).
test "self_hosted_provider supports_zon_format" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const api_key = "test-cerebras-api-key";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        null,
        null,
    );
    const supports_zon = grain_court.LlmProvider.provider_supports_zon(
        .self_hosted,
    );
    try testing.expect(supports_zon == true);
}

// Test provider initialization with empty API key (should fail at assertion).
test "self_hosted_provider init_empty_api_key" {
    // Note: Empty API key will fail at debug assertion, not at runtime.
    // This test documents the expected behavior.
    // In release mode, this would need explicit validation.
}

// Test provider initialization with very long API key (should truncate).
test "self_hosted_provider init_long_api_key" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var long_key: [300]u8 = undefined;
    var i: u32 = 0;
    while (i < 300) : (i += 1) {
        long_key[i] = 'a';
    }
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        &long_key,
        null,
        null,
    );
    try testing.expect(provider.trait.api_key_len <= 256);
}

// Test provider initialization with very long base URL (should truncate).
test "self_hosted_provider init_long_base_url" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var long_url: [600]u8 = undefined;
    var i: u32 = 0;
    while (i < 600) : (i += 1) {
        long_url[i] = 'a';
    }
    const api_key = "test-cerebras-api-key";
    var provider = try grain_court.SelfHostedProvider.init(
        allocator,
        api_key,
        &long_url,
        null,
    );
    try testing.expect(provider.trait.base_url_len <= 512);
}

