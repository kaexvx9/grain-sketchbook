#!/bin/bash
# QEMU RISC-V Setup Script for Grain OS Testing
#
# Why: Configure QEMU RISC-V environment for Grain OS validation and testing.
# Sets up framebuffer, memory, display, and SSH for complete system testing.
#
# Agent: Vantage 3 (Systems Implementation)
#
# Usage:
#   Terminal mode: ./qemu-riscv-setup.sh
#   GUI mode: ./qemu-riscv-setup.sh --gui
#   SSH setup: ./qemu-ssh-setup.sh (run first)

set -e

QEMU_BIN="${QEMU_BIN:-qemu-system-riscv64}"
KERNEL_IMAGE="${KERNEL_IMAGE:-build/grain_os_kernel}"
MEMORY_SIZE="512M"
FRAMEBUFFER_ADDR="0x10000000"
SSH_PORT="${SSH_PORT:-2222}"
SSH_KEY="${SSH_KEY:-${HOME}/.ssh/id_ed25519_qemu}"

# Why: Parse command line arguments.
GUI_MODE=false
if [ "$1" = "--gui" ] || [ "$1" = "-g" ]; then
    GUI_MODE=true
fi

echo "=== QEMU RISC-V Setup for Grain OS ==="
echo ""

# Why: Check if QEMU is available.
if ! command -v "$QEMU_BIN" &> /dev/null; then
    echo "ERROR: QEMU not found. Please install qemu-system-riscv64"
    echo "  Ubuntu/Debian: sudo apt install qemu-system-riscv64"
    exit 1
fi

# Why: Check if SSH key exists, prompt to create if missing.
if [ ! -f "$SSH_KEY" ]; then
    echo "⚠️  SSH key not found: $SSH_KEY"
    echo "   Run './tools/qemu-ssh-setup.sh' to generate SSH keys"
    echo "   Or set SSH_KEY environment variable to your key path"
    echo ""
    read -p "Continue without SSH? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
    SSH_KEY=""
fi

echo "QEMU binary: $QEMU_BIN"
echo "Kernel image: $KERNEL_IMAGE"
echo "Memory: $MEMORY_SIZE"
echo "Framebuffer: $FRAMEBUFFER_ADDR"
if [ -n "$SSH_KEY" ]; then
    echo "SSH port: $SSH_PORT"
    echo "SSH key: $SSH_KEY"
fi
echo "Mode: $([ "$GUI_MODE" = true ] && echo "GUI" || echo "Terminal (nographic)")"
echo ""

# Why: Build QEMU command with proper configuration.
QEMU_CMD=(
    "$QEMU_BIN"
    -machine virt
    -cpu rv64
    -m "$MEMORY_SIZE"
    -kernel "$KERNEL_IMAGE"
    -device virtio-gpu-pci
    -device ramfb,addr="$FRAMEBUFFER_ADDR"
)

# Why: Add SSH support if key is available.
if [ -n "$SSH_KEY" ]; then
    QEMU_CMD+=(
        -netdev user,id=net0,hostfwd=tcp::$SSH_PORT-:22
        -device virtio-net-device,netdev=net0
    )
fi

# Why: Add display mode based on argument.
if [ "$GUI_MODE" = true ]; then
    # GUI mode: Use SDL or GTK display
    if command -v qemu-system-riscv64 | grep -q qemu; then
        QEMU_CMD+=(-display sdl)
    else
        QEMU_CMD+=(-display gtk)
    fi
    echo "Starting QEMU in GUI mode..."
    echo "  - Display window will open"
    echo "  - Close window or Ctrl+Alt+G to release mouse"
else
    # Terminal mode: No graphics, serial console
    QEMU_CMD+=(-nographic -serial stdio)
    echo "Starting QEMU in terminal mode..."
    echo "  - Serial console output"
    echo "  - Ctrl+A then X to exit"
fi

echo ""
echo "QEMU command:"
echo "${QEMU_CMD[@]}"
echo ""

if [ -n "$SSH_KEY" ]; then
    echo "=== SSH Connection Info ==="
    echo "  Host: localhost"
    echo "  Port: $SSH_PORT"
    echo "  User: root (or as configured in guest)"
    echo "  Key: $SSH_KEY"
    echo ""
    echo "  Connect: ssh -i $SSH_KEY -p $SSH_PORT root@localhost"
    echo "  Or use: ssh qemu-grain (if SSH config set up)"
    echo ""
    echo "  Copy files: scp -i $SSH_KEY -P $SSH_PORT file.txt root@localhost:/path/"
    echo ""
fi

echo "=== Starting QEMU ==="
echo ""

# Why: Execute QEMU with configured parameters.
exec "${QEMU_CMD[@]}"