//! Semantic mapping system for Grain Synonym
//! Maps technical concepts to variant-specific aesthetic meanings

const std = @import("std");
const variant_config = @import("variant_config.zig");

/// Semantic mapping structure
/// Maps technical concepts to variant-specific names and meanings
pub const SemanticMap = struct {
    technical_concept: []const u8,  // "LlmProvider"
    variant_name: []const u8,       // "Grain Court" or "Clutch Engine"
    aesthetic_meaning: []const u8,  // Poetic description
    philosophical_alignment: []const u8,  // Energy alignment
    
    // Bounded allocations
    pub const MAX_CONCEPT_LEN: u32 = 128;
    pub const MAX_NAME_LEN: u32 = 128;
    pub const MAX_MEANING_LEN: u32 = 512;
    pub const MAX_ALIGNMENT_LEN: u32 = 512;
    
    /// Validate semantic mapping
    pub fn validate(self: *const SemanticMap) !void {
        std.debug.assert(self.technical_concept.len > 0);
        std.debug.assert(self.technical_concept.len <= MAX_CONCEPT_LEN);
        std.debug.assert(self.variant_name.len > 0);
        std.debug.assert(self.variant_name.len <= MAX_NAME_LEN);
        std.debug.assert(self.aesthetic_meaning.len > 0);
        std.debug.assert(self.aesthetic_meaning.len <= MAX_MEANING_LEN);
        std.debug.assert(self.philosophical_alignment.len > 0);
        std.debug.assert(self.philosophical_alignment.len <= MAX_ALIGNMENT_LEN);
    }
};

/// Clutch OS semantic mappings
/// Maps technical concepts to Clutch OS aesthetic meanings
pub const ClutchOsMappings = struct {
    /// Get semantic mapping for a technical concept
    pub fn get_mapping(concept: []const u8) ?SemanticMap {
        const mappings = get_all_mappings();
        for (mappings) |mapping| {
            if (std.mem.eql(u8, mapping.technical_concept, concept)) {
                return mapping;
            }
        }
        return null;
    }
    
    /// Get all Clutch OS semantic mappings
    pub fn get_all_mappings() []const SemanticMap {
        return &[_]SemanticMap{
            .{
                .technical_concept = "LlmProvider",
                .variant_name = "Clutch Engine",
                .aesthetic_meaning = "The mechanical engine that enables driving the Cursor base, providing LLM infrastructure with mechanical precision and framework-oriented design.",
                .philosophical_alignment = "Virgo Gemini Cancer: Practical precision, communicative enabling, nurturing framework support.",
            },
            .{
                .technical_concept = "TokenEfficiency",
                .variant_name = "Clutch Efficiency",
                .aesthetic_meaning = "Mechanical efficiency optimization, like a well-tuned clutch that transfers power smoothly with minimal loss.",
                .philosophical_alignment = "Virgo: Practical optimization, precision in resource management.",
            },
            .{
                .technical_concept = "ZonFormat",
                .variant_name = "Clutch Transmission",
                .aesthetic_meaning = "Efficient transmission of data, like a clutch that smoothly transfers power from engine to wheels.",
                .philosophical_alignment = "Gemini: Communication, efficient data flow, transmission of meaning.",
            },
            .{
                .technical_concept = "Compute",
                .variant_name = "Clutch Workspace",
                .aesthetic_meaning = "Mechanical workspace for parallel processing, like a workshop where multiple tools work in harmony.",
                .philosophical_alignment = "Cancer: Nurturing workspace, supportive parallel processing environment.",
            },
        };
    }
};

test "semantic map validation" {
    const mappings = ClutchOsMappings.get_all_mappings();
    for (mappings) |mapping| {
        try mapping.validate();
        std.debug.assert(mapping.technical_concept.len > 0);
        std.debug.assert(mapping.variant_name.len > 0);
    }
}

test "semantic map lookup" {
    const mapping = ClutchOsMappings.get_mapping("LlmProvider");
    std.debug.assert(mapping != null);
    if (mapping) |m| {
        std.debug.assert(std.mem.eql(u8, m.variant_name, "Clutch Engine"));
    }
}
