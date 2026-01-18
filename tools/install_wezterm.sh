#!/bin/bash
# Install WezTerm on Ubuntu 24.04 LTS via official APT repository
# Run this script with: bash tools/install_wezterm.sh

set -e

echo "Installing WezTerm terminal emulator..."

# Step 1: Add GPG key
echo "Adding WezTerm GPG key..."
curl -fsSL https://apt.fury.io/wez/gpg.key | sudo gpg --yes --dearmor -o /usr/share/keyrings/wezterm-fury.gpg

# Step 2: Add APT repository
echo "Adding WezTerm APT repository..."
echo 'deb [signed-by=/usr/share/keyrings/wezterm-fury.gpg] https://apt.fury.io/wez/ * *' | sudo tee /etc/apt/sources.list.d/wezterm.list

# Step 3: Set correct permissions
echo "Setting keyring permissions..."
sudo chmod 644 /usr/share/keyrings/wezterm-fury.gpg

# Step 4: Update package lists
echo "Updating package lists..."
sudo apt update

# Step 5: Install WezTerm
echo "Installing WezTerm (stable build)..."
sudo apt install -y wezterm

echo ""
echo "✓ WezTerm installed successfully!"
echo ""
echo "You can launch WezTerm by:"
echo "  - Running: wezterm"
echo "  - Or from your application launcher"
echo ""
echo "To test with Cursor CLI:"
echo "  1. Open WezTerm: wezterm"
echo "  2. Install Cursor CLI: curl -fsSL https://cursor.sh/install | sh"
echo "  3. Test: cursor --help"
echo ""