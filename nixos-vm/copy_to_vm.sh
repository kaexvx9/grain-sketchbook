#!/bin/bash
# Helper script to copy files to NixOS VM
# Run this from the HOST machine to copy files to the VM

VM_USER="nixos"
VM_HOST="localhost"
VM_PORT="2222"
VM_TMP="/tmp"

echo "Copying files to NixOS VM..."
echo "VM: ${VM_USER}@${VM_HOST}:${VM_PORT}"
echo ""

# Check if VM is accessible
if ! ssh -p ${VM_PORT} -o ConnectTimeout=2 ${VM_USER}@${VM_HOST} "echo 'Connected'" 2>/dev/null; then
    echo "ERROR: Cannot connect to VM"
    echo "Make sure:"
    echo "  1. VM is running"
    echo "  2. SSH is enabled in VM (set password: passwd)"
    echo "  3. Port forwarding is correct (2222 -> 22)"
    exit 1
fi

# Copy configuration
echo "Copying configuration.nix..."
scp -P ${VM_PORT} configuration.nix ${VM_USER}@${VM_HOST}:${VM_TMP}/

# Copy installation script
echo "Copying install_nixos.sh..."
scp -P ${VM_PORT} install_nixos.sh ${VM_USER}@${VM_HOST}:${VM_TMP}/

# Copy post-installation script
echo "Copying post_install.sh..."
scp -P ${VM_PORT} post_install.sh ${VM_USER}@${VM_HOST}:~/

echo ""
echo "Files copied successfully!"
echo ""
echo "In the VM, run:"
echo "  sudo bash /tmp/install_nixos.sh"

