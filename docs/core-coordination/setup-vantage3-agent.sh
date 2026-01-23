#!/bin/bash
# Setup script for Vantage 3 Subcore (Rye Compiler Fork Development)
# Usage: ./setup-vantage3-agent.sh

set -e

echo "=========================================="
echo "Vantage 3 Subcore: Rye Compiler Fork"
echo "=========================================="
echo ""

# Check if external repository exists
if [ ! -d "/home/xy/codeberg/ryelang/rye" ]; then
    echo "⚠️  WARNING: External repository not found at /home/xy/codeberg/ryelang/rye"
    echo "   All edits must be made in the external repository!"
    echo ""
fi

# Change to working directory (external repo)
cd /home/xy/codeberg/ryelang/rye 2>/dev/null || {
    echo "⚠️  External repository not accessible. Using monorepo mirror."
    cd /home/xy/ry/grainstore/codeberg/ryelang/rye
}

echo "📁 Working Directory: $(pwd)"
echo ""

# Display current status
echo "📊 Current Status:"
if [ -f "/home/xy/ry/docs/core-coordination/vantage3-progress.md" ]; then
    echo "  - Progress file exists"
    grep -E "^(Phase 2|Phase 3|Current Work)" /home/xy/ry/docs/core-coordination/vantage3-progress.md | head -3 || true
fi
echo ""

# Display shared context reminder
echo "📖 Shared Context:"
echo "  - Read: /home/xy/ry/docs/core-coordination/shared-context.md"
echo "  - Update: /home/xy/ry/docs/core-coordination/vantage3-progress.md"
echo "  - Check: /home/xy/ry/docs/core-coordination/core1-progress.md"
echo ""

# Display agent context
echo "🎯 Agent Context:"
echo "  - Full context: /home/xy/ry/docs/core-coordination/vantage3-agent-context.md"
echo ""

# Display key files
echo "📝 Key Files:"
echo "  - Phase 2: src/arch/riscv64/CodeGen.zig"
echo "  - Phase 3: lib/std/toroidal.zig, lib/std/garden.zig"
echo "  - Basin kernel: /home/xy/ry/src/kernel/"
echo ""

# Display coordination info
echo "🤝 Coordination:"
echo "  - Messages: /home/xy/ry/docs/core-coordination/agent-messages/"
echo "  - Core 1 progress: /home/xy/ry/docs/core-coordination/core1-progress.md"
echo ""

echo "=========================================="
echo "Ready to work! Use this prompt:"
echo "=========================================="
echo ""
cat << 'PROMPT'
You are Vantage 3 Subcore, working on Rye compiler fork development (bottom-up approach).

Current Status:
- Phase 2: 76% complete (frame layout fix done, Issue 2 kernel testing pending)
- Phase 3 Foundation: Complete (toroidal types + garden allocator available)
- Phase 3 Stdlib: Pending (mem, fmt, io modules needed)

Repository:
- External (source of truth): /home/xy/codeberg/ryelang/rye
- Monorepo mirror: /home/xy/ry/grainstore/codeberg/ryelang/rye
- All edits must be made in external repository

Your Goals:
- Complete Phase 2 (Issue 2 kernel integration testing)
- Implement Phase 3 stdlib (mem, fmt, io modules)
- Test with Basin kernel (/home/xy/ry/src/kernel/)
- Prepare for Phase 4 (Rye Style enforcement)

Basin Kernel Goals:
- RISC-V64 kernel with REPL shell
- Expression evaluator
- Variable management
- DAG-based events
- Rye Style compliance

Coordination:
- Core 1 Subcore is converting Skate to Rye Style (top-down)
- Integration point: Week 9+ when Phase 3 stdlib is complete
- Both aware of Rye Style constraints and Basin kernel goals
- Check: /home/xy/ry/docs/core-coordination/core1-progress.md for updates

Key Documentation:
- Agent Context: /home/xy/ry/docs/core-coordination/vantage3-agent-context.md
- Shared Context: /home/xy/ry/docs/core-coordination/shared-context.md
- Progress Update: /home/xy/ry/docs/core-coordination/2026-01-23-143000-pst_rye-compiler-phase2-phase3-progress-update.md
- Skate Porting Roadmap: /home/xy/ry/docs/rye/0021-skate-porting-readiness-roadmap.md
- Rye Compiler Fork Plan: /home/xy/ry/docs/rye/0011-rye-compiler-fork-plan.md

Continue with the best path forward for Rye compiler fork development.
PROMPT
echo ""
echo "=========================================="
