#!/bin/bash
# Helper script to copy files to NixOS VM
# Run this from the HOST machine to copy files to the VM

VM_USER="nixos"
VM_HOST="localhost"
VM_PORT="2222"
VM_TMP="/tmp"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=========================================="
echo "  Copy Files to NixOS VM"
echo "=========================================="
echo "VM: ${VM_USER}@${VM_HOST}:${VM_PORT}"
echo ""

# Check if VM is accessible
echo "Checking VM connectivity..."
if ! ssh -p ${VM_PORT} -o ConnectTimeout=5 -o StrictHostKeyChecking=no -o PreferredAuthentications=password ${VM_USER}@${VM_HOST} "echo 'Connected'" 2>/dev/null; then
    echo ""
    echo "ERROR: Cannot connect to VM"
    echo ""
    echo "Make sure:"
    echo "  1. VM is running"
    echo "  2. Password is set in VM (run 'passwd' in VM terminal)"
    echo "  3. Port forwarding is correct (host:2222 -> guest:22)"
    echo ""
    echo "To set password in VM:"
    echo "  In VM terminal, run: passwd"
    echo ""
    echo "If password is set, you may need to enter it interactively."
    echo "Alternatively, use the download method from within the VM."
    exit 1
fi

echo "✓ VM is accessible"
echo ""

# Copy configuration
echo "Copying configuration.nix..."
scp -P ${VM_PORT} -o StrictHostKeyChecking=no -o PreferredAuthentications=password "${SCRIPT_DIR}/configuration.nix" ${VM_USER}@${VM_HOST}:${VM_TMP}/ || {
    echo "ERROR: Failed to copy configuration.nix"
    echo "Make sure password is set in VM (run 'passwd' in VM terminal)"
    exit 1
}

# Copy installation script
echo "Copying install_nixos.sh..."
scp -P ${VM_PORT} -o StrictHostKeyChecking=no -o PreferredAuthentications=password "${SCRIPT_DIR}/install_nixos.sh" ${VM_USER}@${VM_HOST}:${VM_TMP}/ || {
    echo "ERROR: Failed to copy install_nixos.sh"
    exit 1
}

# Copy post-installation script
echo "Copying post_install.sh..."
scp -P ${VM_PORT} -o StrictHostKeyChecking=no -o PreferredAuthentications=password "${SCRIPT_DIR}/post_install.sh" ${VM_USER}@${VM_HOST}:~/ || {
    echo "ERROR: Failed to copy post_install.sh"
    exit 1
}

# Make scripts executable
echo "Making scripts executable..."
ssh -p ${VM_PORT} -o StrictHostKeyChecking=no ${VM_USER}@${VM_HOST} "chmod +x ${VM_TMP}/install_nixos.sh ~/post_install.sh" || {
    echo "WARNING: Failed to make scripts executable (you can do this manually)"
}

echo ""
echo "=========================================="
echo "  Files Copied Successfully!"
echo "=========================================="
echo ""
echo "Files copied to VM:"
echo "  /tmp/configuration.nix"
echo "  /tmp/install_nixos.sh"
echo "  ~/post_install.sh"
echo ""
echo "In the VM terminal, run:"
echo "  sudo bash /tmp/install_nixos.sh"
echo ""

