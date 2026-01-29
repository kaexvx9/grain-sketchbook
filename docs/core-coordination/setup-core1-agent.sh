#!/bin/bash
# Setup script for Core 1 Subcore (Rye Style Conversion)
# Usage: ./setup-core1-agent.sh

set -e

echo "=========================================="
echo "Core 1 Subcore: Rye Style Conversion"
echo "=========================================="
echo ""

# Change to working directory
cd /home/xy/grain-sketchbook

echo "📁 Working Directory: $(pwd)"
echo ""

# Display current status
echo "📊 Current Status:"
if [ -f "docs/core-coordination/core1-progress.md" ]; then
    echo "  - Progress file exists"
    grep -E "^(Overall Progress|Current Work|Remaining Modules)" docs/core-coordination/core1-progress.md | head -3 || true
fi
echo ""

# Display shared context reminder
echo "📖 Shared Context:"
echo "  - Read: docs/core-coordination/shared-context.md"
echo "  - Update: docs/core-coordination/core1-progress.md"
echo "  - Check: docs/core-coordination/vantage3-progress.md"
echo ""

# Display agent context
echo "🎯 Agent Context:"
echo "  - Full context: docs/core-coordination/core1-agent-context.md"
echo ""

# Display key files
echo "📝 Key Files:"
echo "  - Current work: src/grain_skate/ai_insights.zig"
echo "  - Rye checker: ./rye/zig-out/bin/rye check"
echo ""

# Display coordination info
echo "🤝 Coordination:"
echo "  - Messages: docs/core-coordination/agent-messages/"
echo "  - Vantage 3 progress: docs/core-coordination/vantage3-progress.md"
echo ""

echo "=========================================="
echo "Ready to work! Use this prompt:"
echo "=========================================="
echo ""
cat << 'PROMPT'
You are Core 1 Subcore, working on Rye Style conversion of Skate desktop modules.

Current Status:
- 9 modules converted to Rye Style (block.ry, bracket_matching.ry, etc.)
- Current work: Converting ai_insights.zig → ai_insights.ry
- Issues: 3 functions exceed 64-line limit (send_llm_request, suggest_connections, summarize_subgraph)

Your Goal:
- Continue converting remaining Skate modules to Rye Style
- Use `./rye/zig-out/bin/rye check` to validate
- Ensure all code meets Rye Style constraints (64 lines, 128 chars, "why" comments)
- Prepare code for Rye compiler fork (Week 9+ integration point)

Key Documentation:
- Rye Style Guide: docs/rye_style.md
- Top-Down Guide: docs/rye/0023-rye-style-top-down-application-guide.md
- Agent Context: docs/core-coordination/core1-agent-context.md
- Shared Context: docs/core-coordination/shared-context.md
- Progress: docs/core-coordination/core1-progress.md

Coordination:
- Vantage 3 Subcore is working on Rye compiler fork (bottom-up)
- Integration point: Week 9+ when Phase 3 stdlib is complete
- Both aware of Rye Style constraints and Basin kernel goals
- Check: docs/core-coordination/vantage3-progress.md for updates

Continue with the best path forward for Rye Style conversion.
PROMPT
echo ""
echo "=========================================="
