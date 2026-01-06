#!/bin/bash
# Cursor CLI Setup Script (Grain Style)
# Date: 2026-01-05-170300-pst
# Purpose: Install and configure Cursor CLI for autonomous work
# Architecture: Uses GrainVault for API key management

set -e

echo "=== Cursor CLI Setup ==="
echo "Date: $(date +"%Y-%m-%d-%H%M%S-pst")"

# Check if Cursor CLI is already installed
if command -v cursor-agent &> /dev/null; then
    echo "✅ Cursor CLI already installed"
    cursor-agent --version || true
else
    echo "📦 Installing Cursor CLI..."
    curl https://cursor.com/install -fsS | bash
    
    # Add to PATH if needed
    if [ -f "$HOME/.local/bin/cursor-agent" ]; then
        export PATH="$HOME/.local/bin:$PATH"
        echo "✅ Cursor CLI installed to ~/.local/bin/"
    fi
fi

# Check for API key
if [ -z "$CURSOR_API_TOKEN" ]; then
    echo "⚠️  CURSOR_API_TOKEN not set"
    echo "   Set it via: export CURSOR_API_TOKEN='your-key'"
    echo "   Or use GrainVault: tools/grain_conductor.zig conduct ai --tool=cursor"
else
    echo "✅ CURSOR_API_TOKEN is set"
fi

# Test Cursor CLI
echo "🧪 Testing Cursor CLI..."
if command -v cursor-agent &> /dev/null; then
    echo "✅ Cursor CLI is available"
    echo "   Usage: cursor-agent chat 'your prompt'"
else
    echo "❌ Cursor CLI not found in PATH"
    echo "   Try: export PATH=\"\$HOME/.local/bin:\$PATH\""
fi

echo "=== Setup Complete ==="

