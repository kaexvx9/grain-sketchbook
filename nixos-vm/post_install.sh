#!/bin/bash
# Post-Installation Setup Script for NixOS VM
# Run this AFTER first boot into installed NixOS
# Usage: bash post_install.sh

set -e

echo "=========================================="
echo "  NixOS Post-Installation Setup"
echo "=========================================="
echo ""

# Check if we're in installed NixOS (not ISO)
if [ ! -f /etc/nixos/configuration.nix ]; then
    echo "ERROR: This script should be run in installed NixOS, not the ISO"
    exit 1
fi

# Step 1: Update system
echo "Step 1: Updating NixOS packages..."
sudo nixos-rebuild switch --upgrade

# Step 2: Clone xy-mathematics repository
echo ""
echo "Step 2: Setting up xy-mathematics repository..."
cd ~

if [ ! -d "xy-mathematics" ]; then
    echo "  Cloning repository..."
    if [ -f ~/.ssh/id_ed25519_codeberg ]; then
        # Use SSH
        GIT_SSH_COMMAND="ssh -i ~/.ssh/id_ed25519_codeberg" git clone git@codeberg.org:teamcarry11/xy-mathematics.git
    else
        echo "  WARNING: SSH key not found, using HTTPS (may need authentication)"
        git clone https://codeberg.org/teamcarry11/xy-mathematics.git
    fi
    echo "  ✓ Repository cloned"
else
    echo "  Repository already exists, pulling latest changes..."
    cd xy-mathematics
    git pull
    echo "  ✓ Repository updated"
fi

# Step 3: Configure Git
echo ""
echo "Step 3: Configuring Git..."
git config --global user.name "kae3g"
git config --global user.email "kj3x39@gmail.com"
echo "  ✓ Git configured"

# Step 4: Verify development tools
echo ""
echo "Step 4: Verifying development tools..."
echo "  Zig version:"
zig version || echo "  ⚠ Zig not found (should be in configuration.nix)"
echo ""
echo "  Git version:"
git --version
echo ""
echo "  Other tools:"
which make cmake gcc || echo "  Build tools available"

# Step 5: Test build system
echo ""
echo "Step 5: Testing build system..."
cd ~/xy-mathematics
if [ -f "build.zig" ]; then
    echo "  Found build.zig"
    echo "  Running: zig build --help"
    zig build --help > /dev/null 2>&1 && echo "  ✓ Build system ready" || echo "  ⚠ Build system may need configuration"
else
    echo "  ⚠ build.zig not found"
fi

# Step 6: Set up SSH keys (if needed)
echo ""
echo "Step 6: SSH key setup..."
if [ ! -f ~/.ssh/id_ed25519_codeberg ]; then
    echo "  Codeberg SSH key not found in VM"
    echo "  You may want to copy your SSH keys from the host:"
    echo "    From host: scp -P 2222 ~/.ssh/id_ed25519_codeberg* xy@localhost:~/.ssh/"
else
    echo "  ✓ SSH keys found"
fi

# Step 7: Summary
echo ""
echo "=========================================="
echo "  Post-Installation Complete!"
echo "=========================================="
echo ""
echo "Your NixOS development environment is ready!"
echo ""
echo "Next steps:"
echo "  - Edit ~/xy-mathematics files"
echo "  - Run: cd ~/xy-mathematics && zig build"
echo "  - Access from host: ssh -p 2222 xy@localhost"
echo ""

