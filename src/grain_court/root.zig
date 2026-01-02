//! Grain Court: LLM Infrastructure for Grain OS.
//!
//! This module provides a unified interface for LLM operations across multiple providers,
//! enabling agents to use AI capabilities with automatic provider switching, cost tracking,
//! and token efficiency optimization.
//!
//! Components:
//! - LlmProvider: Multi-provider abstraction with automatic fallback
//! - TokenEfficiency: Cost tracking and optimization utilities
//! - ZonFormat: Efficient serialization format for LLM communication
//! - Compute: WSE-wafer-scale spatial computing abstraction
//! - Provider implementations: OpenAI, Anthropic, Mistral, Self-hosted
//!
//! 2025-12-05-145359-pst: Renamed from Grain Field to Grain Court

pub const Compute = @import("compute.zig").Compute;
pub const LlmProvider = @import("llm_provider.zig");
pub const OpenAIProvider = @import("provider_openai.zig").OpenAIProvider;
pub const AnthropicProvider = @import("provider_anthropic.zig").AnthropicProvider;
pub const MistralProvider = @import("provider_mistral.zig").MistralProvider;
pub const SelfHostedProvider = @import("provider_self_hosted.zig").SelfHostedProvider;
pub const ZonFormat = @import("zon_format.zig");
pub const TokenEfficiency = @import("token_efficiency.zig");

