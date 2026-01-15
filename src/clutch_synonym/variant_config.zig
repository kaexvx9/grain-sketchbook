//! Variant configuration system for Grain Synonym
//! Enables multi-aesthetic OS variants with shared technical codebase

const std = @import("std");

/// Variant configuration structure
/// Defines aesthetic identity for OS variants
pub const VariantConfig = struct {
    name: []const u8,              // "Grain OS" or "Clutch OS"
    org: []const u8,                // "teamcarry11" or "teambrick06"
    repo: []const u8,               // "xy-mathematics" or "yz"
    aesthetic: []const u8,          // "growth" or "mechanical"
    energy: []const u8,             // "Aquarius" or "Virgo Gemini Cancer"
    philosophy: []const u8,         // Variant philosophy description
    
    // Bounded allocations
    pub const MAX_NAME_LEN: u32 = 64;
    pub const MAX_ORG_LEN: u32 = 64;
    pub const MAX_REPO_LEN: u32 = 128;
    pub const MAX_AESTHETIC_LEN: u32 = 128;
    pub const MAX_ENERGY_LEN: u32 = 128;
    pub const MAX_PHILOSOPHY_LEN: u32 = 512;
    
    /// Validate variant configuration
    pub fn validate(self: *const VariantConfig) !void {
        std.debug.assert(self.name.len > 0);
        std.debug.assert(self.name.len <= MAX_NAME_LEN);
        std.debug.assert(self.org.len > 0);
        std.debug.assert(self.org.len <= MAX_ORG_LEN);
        std.debug.assert(self.repo.len > 0);
        std.debug.assert(self.repo.len <= MAX_REPO_LEN);
        std.debug.assert(self.aesthetic.len > 0);
        std.debug.assert(self.aesthetic.len <= MAX_AESTHETIC_LEN);
        std.debug.assert(self.energy.len > 0);
        std.debug.assert(self.energy.len <= MAX_ENERGY_LEN);
        std.debug.assert(self.philosophy.len > 0);
        std.debug.assert(self.philosophy.len <= MAX_PHILOSOPHY_LEN);
    }
    
    /// Get current variant configuration
    /// Returns Clutch OS configuration for teambrick06/yz
    pub fn get_clutch_os() VariantConfig {
        return VariantConfig{
            .name = "Clutch OS",
            .org = "teambrick06",
            .repo = "yz",
            .aesthetic = "mechanical",
            .energy = "Virgo Gemini Cancer",
            .philosophy = "Framework-oriented, enabling-focused, mechanical precision. Clutch OS is the framework that enables driving the Cursor base, inspired by brick-and-mortar foundations and clutches as enabling mechanisms.",
        };
    }
    
    /// Get Grain OS configuration (reference)
    pub fn get_grain_os() VariantConfig {
        return VariantConfig{
            .name = "Grain OS",
            .org = "teamcarry11",
            .repo = "xy-mathematics",
            .aesthetic = "growth",
            .energy = "Aquarius",
            .philosophy = "Service-oriented, growth-focused, organic evolution. Grain OS emphasizes cultivation, harvest, and organic development.",
        };
    }
};

test "variant config validation" {
    var config = VariantConfig.get_clutch_os();
    try config.validate();
    std.debug.assert(std.mem.eql(u8, config.name, "Clutch OS"));
    std.debug.assert(std.mem.eql(u8, config.org, "teambrick06"));
}

test "variant config bounds" {
    var config = VariantConfig.get_clutch_os();
    try config.validate();
    std.debug.assert(config.name.len <= VariantConfig.MAX_NAME_LEN);
    std.debug.assert(config.org.len <= VariantConfig.MAX_ORG_LEN);
}
