//! Grain Court Token Efficiency Test Suite
//!
//! Comprehensive tests for token counting, cost tracking, and optimization
//! utilities in the Grain Court LLM infrastructure.
//!
//! Tests cover:
//! - Token estimation
//! - Cost calculation for all providers
//! - Cost tracking and reporting
//! - Provider cost comparison
//! - Token efficiency metrics
//! - Provider recommendations
//!
//! GrainStyle: grain_case function names, explicit u32/u64 types, bounded
//! allocations, minimum 2 assertions per function, max 70 lines per function.

const std = @import("std");
const testing = std.testing;
const grain_court = @import("grain_court");

// Test token estimation.
test "estimate_token_count basic" {
    const text = "Hello, world!";
    const count = grain_court.TokenEfficiency.estimate_token_count(text);
    try testing.expect(count > 0);
    try testing.expect(
        count <= grain_court.TokenEfficiency.MAX_TOKENS_PER_REQUEST,
    );
}

test "estimate_token_count empty" {
    const text = "";
    const count = grain_court.TokenEfficiency.estimate_token_count(text);
    try testing.expect(count == 0);
}

test "estimate_token_count large" {
    var text: [10000]u8 = undefined;
    var i: u32 = 0;
    while (i < 10000) : (i += 1) {
        text[i] = 'a';
    }
    const count = grain_court.TokenEfficiency.estimate_token_count(&text);
    try testing.expect(count > 0);
    try testing.expect(count <= grain_court.TokenEfficiency.MAX_TOKENS_PER_REQUEST);
}

// Test OpenAI cost calculation.
test "calculate_openai_cost basic" {
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const cost = grain_court.TokenEfficiency.calculate_openai_cost(
        input_tokens,
        output_tokens,
    );
    try testing.expect(cost > 0.0);
    try testing.expect(cost < 100.0);
}

test "calculate_openai_cost zero tokens" {
    const cost = grain_court.TokenEfficiency.calculate_openai_cost(0, 0);
    try testing.expect(cost == 0.0);
}

test "calculate_openai_cost large tokens" {
    const input_tokens: u32 = 100000;
    const output_tokens: u32 = 50000;
    const cost = grain_court.TokenEfficiency.calculate_openai_cost(
        input_tokens,
        output_tokens,
    );
    try testing.expect(cost > 0.0);
    try testing.expect(cost < 10000.0);
}

// Test Anthropic cost calculation.
test "calculate_anthropic_cost basic" {
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const cost = grain_court.TokenEfficiency.calculate_anthropic_cost(
        input_tokens,
        output_tokens,
    );
    try testing.expect(cost > 0.0);
    try testing.expect(cost < 100.0);
}

test "calculate_anthropic_cost zero tokens" {
    const cost = grain_court.TokenEfficiency.calculate_anthropic_cost(0, 0);
    try testing.expect(cost == 0.0);
}

// Test Mistral cost calculation.
test "calculate_mistral_cost basic" {
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const cost = grain_court.TokenEfficiency.calculate_mistral_cost(
        input_tokens,
        output_tokens,
    );
    try testing.expect(cost > 0.0);
    try testing.expect(cost < 100.0);
}

test "calculate_mistral_cost zero tokens" {
    const cost = grain_court.TokenEfficiency.calculate_mistral_cost(0, 0);
    try testing.expect(cost == 0.0);
}

// Test Cerebras cost calculation.
test "calculate_cerebras_cost basic" {
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const cost = grain_court.TokenEfficiency.calculate_cerebras_cost(
        input_tokens,
        output_tokens,
    );
    try testing.expect(cost > 0.0);
    try testing.expect(cost < 100.0);
}

test "calculate_cerebras_cost zero tokens" {
    const cost = grain_court.TokenEfficiency.calculate_cerebras_cost(0, 0);
    try testing.expect(cost == 0.0);
}

// Test provider cost calculation.
test "calculate_provider_cost openai" {
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const cost = grain_court.TokenEfficiency.calculate_provider_cost(
        .openai,
        input_tokens,
        output_tokens,
    );
    try testing.expect(cost > 0.0);
}

test "calculate_provider_cost anthropic" {
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const cost = grain_court.TokenEfficiency.calculate_provider_cost(
        .anthropic,
        input_tokens,
        output_tokens,
    );
    try testing.expect(cost > 0.0);
}

test "calculate_provider_cost mistral" {
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const cost = grain_court.TokenEfficiency.calculate_provider_cost(
        .mistral,
        input_tokens,
        output_tokens,
    );
    try testing.expect(cost > 0.0);
}

test "calculate_provider_cost self_hosted" {
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const cost = grain_court.TokenEfficiency.calculate_provider_cost(
        .self_hosted,
        input_tokens,
        output_tokens,
    );
    try testing.expect(cost > 0.0);
}

// Test cost tracker initialization.
test "cost_tracker init" {
    var tracker = grain_court.TokenEfficiency.CostTracker.init();
    try testing.expect(tracker.entries_len == 0);
    try testing.expect(tracker.get_total_cost() == 0.0);
    try testing.expect(tracker.get_request_count() == 0);
}

// Test cost tracker add entry.
test "cost_tracker add_cost_entry" {
    var tracker = grain_court.TokenEfficiency.CostTracker.init();
    const model = "gpt-4o";
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const cost: f64 = 5.0;
    const success = tracker.add_cost_entry(
        .openai,
        model,
        input_tokens,
        output_tokens,
        cost,
    );
    try testing.expect(success == true);
    try testing.expect(tracker.entries_len == 1);
    try testing.expect(tracker.get_total_cost() == cost);
    try testing.expect(tracker.get_request_count() == 1);
}

test "cost_tracker add_multiple_entries" {
    var tracker = grain_court.TokenEfficiency.CostTracker.init();
    const model = "gpt-4o";
    var i: u32 = 0;
    while (i < 10) : (i += 1) {
        const success = tracker.add_cost_entry(
            .openai,
            model,
            1000,
            500,
            5.0,
        );
        try testing.expect(success == true);
    }
    try testing.expect(tracker.entries_len == 10);
    try testing.expect(tracker.get_total_cost() == 50.0);
    try testing.expect(tracker.get_request_count() == 10);
}

// Test cost tracker provider filtering.
test "cost_tracker get_cost_by_provider" {
    var tracker = grain_court.TokenEfficiency.CostTracker.init();
    const model = "gpt-4o";
    _ = tracker.add_cost_entry(.openai, model, 1000, 500, 5.0);
    _ = tracker.add_cost_entry(.anthropic, model, 1000, 500, 6.0);
    _ = tracker.add_cost_entry(.openai, model, 1000, 500, 5.0);
    const openai_cost = tracker.get_cost_by_provider(.openai);
    const anthropic_cost = tracker.get_cost_by_provider(.anthropic);
    try testing.expect(openai_cost == 10.0);
    try testing.expect(anthropic_cost == 6.0);
}

test "cost_tracker get_request_count_by_provider" {
    var tracker = grain_court.TokenEfficiency.CostTracker.init();
    const model = "gpt-4o";
    _ = tracker.add_cost_entry(.openai, model, 1000, 500, 5.0);
    _ = tracker.add_cost_entry(.anthropic, model, 1000, 500, 6.0);
    _ = tracker.add_cost_entry(.openai, model, 1000, 500, 5.0);
    const openai_count = tracker.get_request_count_by_provider(.openai);
    const anthropic_count = tracker.get_request_count_by_provider(.anthropic);
    try testing.expect(openai_count == 2);
    try testing.expect(anthropic_count == 1);
}

// Test cost tracker average cost.
test "cost_tracker get_average_cost_per_request" {
    var tracker = grain_court.TokenEfficiency.CostTracker.init();
    const model = "gpt-4o";
    _ = tracker.add_cost_entry(.openai, model, 1000, 500, 5.0);
    _ = tracker.add_cost_entry(.openai, model, 1000, 500, 10.0);
    _ = tracker.add_cost_entry(.openai, model, 1000, 500, 15.0);
    const avg = tracker.get_average_cost_per_request();
    try testing.expect(avg == 10.0);
}

test "cost_tracker get_average_cost_per_request empty" {
    var tracker = grain_court.TokenEfficiency.CostTracker.init();
    const avg = tracker.get_average_cost_per_request();
    try testing.expect(avg == 0.0);
}

// Test token efficiency calculation.
test "calculate_token_efficiency" {
    const text = "Hello, world!";
    const token_count: u32 = 3;
    const efficiency = grain_court.TokenEfficiency.calculate_token_efficiency(
        text,
        token_count,
    );
    try testing.expect(efficiency > 0.0);
}

test "calculate_token_efficiency empty" {
    const text = "";
    const token_count: u32 = 0;
    const efficiency = grain_court.TokenEfficiency.calculate_token_efficiency(
        text,
        token_count,
    );
    try testing.expect(efficiency == 0.0);
}

// Test provider cost comparison.
test "compare_provider_costs" {
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const comparisons = grain_court.TokenEfficiency.compare_provider_costs(
        input_tokens,
        output_tokens,
    );
    var cheapest_found: bool = false;
    var i: u32 = 0;
    while (i < 4) : (i += 1) {
        try testing.expect(comparisons[i].cost_usd > 0.0);
        if (comparisons[i].is_cheapest) {
            cheapest_found = true;
        }
    }
    try testing.expect(cheapest_found == true);
}

// Test provider recommendation.
test "recommend_cheapest_provider" {
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const recommendation = grain_court.TokenEfficiency.recommend_cheapest_provider(
        input_tokens,
        output_tokens,
    );
    try testing.expect(recommendation.estimated_cost_usd > 0.0);
    try testing.expect(
        recommendation.estimated_input_tokens == input_tokens,
    );
    try testing.expect(
        recommendation.estimated_output_tokens == output_tokens,
    );
    try testing.expect(recommendation.savings_vs_most_expensive >= 0.0);
}

// Test token savings calculation.
test "calculate_token_savings_percent" {
    const original: u32 = 1000;
    const optimized: u32 = 800;
    const savings = grain_court.TokenEfficiency.calculate_token_savings_percent(
        original,
        optimized,
    );
    try testing.expect(savings == 20.0);
}

test "calculate_token_savings_percent zero original" {
    const original: u32 = 0;
    const optimized: u32 = 0;
    const savings = grain_court.TokenEfficiency.calculate_token_savings_percent(
        original,
        optimized,
    );
    try testing.expect(savings == 0.0);
}

// Test cost savings calculation.
test "calculate_cost_savings" {
    const input_tokens: u32 = 1000;
    const output_tokens: u32 = 500;
    const savings = grain_court.TokenEfficiency.calculate_cost_savings(
        .anthropic,
        .mistral,
        input_tokens,
        output_tokens,
    );
    try testing.expect(savings != 0.0);
}

// Test cost report generation.
test "generate_cost_report" {
    var tracker = grain_court.TokenEfficiency.CostTracker.init();
    const model = "gpt-4o";
    _ = tracker.add_cost_entry(.openai, model, 1000, 500, 5.0);
    _ = tracker.add_cost_entry(.anthropic, model, 1000, 500, 6.0);
    _ = tracker.add_cost_entry(.openai, model, 1000, 500, 5.0);
    const report = grain_court.TokenEfficiency.generate_cost_report(&tracker);
    try testing.expect(report.total_cost_usd == 16.0);
    try testing.expect(report.total_requests == 3);
    try testing.expect(report.average_cost_per_request > 0.0);
    try testing.expect(report.cost_by_provider[0] == 10.0);
    try testing.expect(report.cost_by_provider[1] == 6.0);
}

test "generate_cost_report empty" {
    var tracker = grain_court.TokenEfficiency.CostTracker.init();
    const report = grain_court.TokenEfficiency.generate_cost_report(&tracker);
    try testing.expect(report.total_cost_usd == 0.0);
    try testing.expect(report.total_requests == 0);
    try testing.expect(report.average_cost_per_request == 0.0);
}

