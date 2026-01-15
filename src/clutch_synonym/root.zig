//! Grain Synonym module root
//! Multi-aesthetic OS variant system

pub const variant_config = @import("variant_config.zig");
pub const semantic_map = @import("semantic_map.zig");

pub const VariantConfig = variant_config.VariantConfig;
pub const SemanticMap = semantic_map.SemanticMap;
pub const ClutchOsMappings = semantic_map.ClutchOsMappings;
