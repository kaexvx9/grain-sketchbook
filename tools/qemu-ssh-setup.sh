#!/bin/bash
# QEMU SSH Key Setup Script
#
# Why: Generate or configure ed25519 SSH keys for QEMU guest access.
# Enables secure file transfer and remote access to QEMU RISC-V environment.
#
# Agent: Vantage 3 (Systems Implementation)

set -e

SSH_KEY_NAME="${SSH_KEY_NAME:-id_ed25519_qemu}"
SSH_KEY_PATH="${HOME}/.ssh/${SSH_KEY_NAME}"
SSH_PUBKEY_PATH="${SSH_KEY_PATH}.pub"
QEMU_USER="${QEMU_USER:-root}"
QEMU_HOST="${QEMU_HOST:-localhost}"
QEMU_PORT="${QEMU_PORT:-2222}"

echo "=== QEMU SSH Key Setup ==="
echo ""

# Why: Check if QEMU SSH key already exists.
if [ -f "$SSH_KEY_PATH" ]; then
    echo "✅ QEMU SSH key already exists: $SSH_KEY_PATH"
    echo ""
    echo "Key fingerprint:"
    ssh-keygen -lf "$SSH_PUBKEY_PATH" 2>/dev/null || true
    echo ""
    echo "To use this key with QEMU:"
    echo "  ssh -i $SSH_KEY_PATH -p $QEMU_PORT $QEMU_USER@$QEMU_HOST"
    echo ""
    echo "To copy files:"
    echo "  scp -i $SSH_KEY_PATH -P $QEMU_PORT file.txt $QEMU_USER@$QEMU_HOST:/path/"
    echo ""
    exit 0
fi

# Why: Generate new ed25519 SSH key for QEMU.
echo "Generating new ed25519 SSH key for QEMU..."
echo ""

ssh-keygen -t ed25519 -f "$SSH_KEY_PATH" -N "" -C "qemu-riscv-grain-os-$(date +%Y%m%d)" << EOF
y
EOF

echo ""
echo "✅ SSH key generated: $SSH_KEY_PATH"
echo ""

# Why: Display public key for QEMU guest configuration.
echo "=== Public Key (add to QEMU guest authorized_keys) ==="
cat "$SSH_PUBKEY_PATH"
echo ""

# Why: Display connection instructions.
echo "=== Connection Instructions ==="
echo ""
echo "1. Add public key to QEMU guest authorized_keys:"
echo "   cat $SSH_PUBKEY_PATH >> /path/to/guest/home/.ssh/authorized_keys"
echo ""
echo "2. Connect to QEMU guest:"
echo "   ssh -i $SSH_KEY_PATH -p $QEMU_PORT $QEMU_USER@$QEMU_HOST"
echo ""
echo "3. Copy files to QEMU guest:"
echo "   scp -i $SSH_KEY_PATH -P $QEMU_PORT file.txt $QEMU_USER@$QEMU_HOST:/path/"
echo ""
echo "4. Copy directories to QEMU guest:"
echo "   scp -i $SSH_KEY_PATH -P $QEMU_PORT -r directory/ $QEMU_USER@$QEMU_HOST:/path/"
echo ""

# Why: Create SSH config entry for convenience.
SSH_CONFIG="${HOME}/.ssh/config"
if [ ! -f "$SSH_CONFIG" ]; then
    touch "$SSH_CONFIG"
    chmod 600 "$SSH_CONFIG"
fi

if ! grep -q "Host qemu-grain" "$SSH_CONFIG" 2>/dev/null; then
    echo "" >> "$SSH_CONFIG"
    echo "# QEMU RISC-V Grain OS" >> "$SSH_CONFIG"
    echo "Host qemu-grain" >> "$SSH_CONFIG"
    echo "    HostName $QEMU_HOST" >> "$SSH_CONFIG"
    echo "    Port $QEMU_PORT" >> "$SSH_CONFIG"
    echo "    User $QEMU_USER" >> "$SSH_CONFIG"
    echo "    IdentityFile $SSH_KEY_PATH" >> "$SSH_CONFIG"
    echo "    StrictHostKeyChecking no" >> "$SSH_CONFIG"
    echo "    UserKnownHostsFile /dev/null" >> "$SSH_CONFIG"
    echo ""
    echo "✅ Added SSH config entry: ssh qemu-grain"
fi

echo "=== Setup Complete ==="