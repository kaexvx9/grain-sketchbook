#!/bin/bash
# Deploy to RISC-V VM Script
# Date: 2026-01-05-170300-pst
# Purpose: Deploy built binaries to RISC-V VM for testing

set -e

echo "=== Deploy to RISC-V VM ==="
echo "Date: $(date +"%Y-%m-%d-%H%M%S-pst")"

# Configuration
VM_USER=${VM_USER:-ubuntu}
VM_HOST=${VM_HOST:-localhost}
VM_PORT=${VM_PORT:-2222}
DEPLOY_PATH=${DEPLOY_PATH:-/home/ubuntu/grain-os}

# Check for SSH
if ! command -v ssh &> /dev/null; then
    echo "❌ SSH not found"
    exit 1
fi

# Check for built binaries
if [ ! -d "zig-out/bin" ]; then
    echo "⚠️  No built binaries found"
    echo "   Run: zig build first"
    exit 1
fi

echo "📦 Deploying to RISC-V VM..."
echo "   Host: $VM_HOST:$VM_PORT"
echo "   User: $VM_USER"
echo "   Path: $DEPLOY_PATH"

# Create deployment directory on VM
ssh -p $VM_PORT $VM_USER@$VM_HOST "mkdir -p $DEPLOY_PATH/bin"

# Copy binaries
scp -P $VM_PORT zig-out/bin/* $VM_USER@$VM_HOST:$DEPLOY_PATH/bin/

echo "✅ Deployment complete"
echo "   SSH into VM: ssh -p $VM_PORT $VM_USER@$VM_HOST"
echo "   Run: cd $DEPLOY_PATH/bin && ./grainflow"

