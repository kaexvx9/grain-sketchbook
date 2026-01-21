#!/bin/bash
# Run Basin UEFI bootloader in QEMU x86_64
# Why: Test x86_64 boot path without real hardware.
# Usage: ./scripts/run_uefi_qemu.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Build the bootloader
echo "[BUILD] Building UEFI bootloader..."
cd "$PROJECT_DIR"
zig build uefi-boot

# Check if OVMF (UEFI firmware) is available
OVMF_CODE=""
OVMF_PATHS=(
    "/usr/share/OVMF/OVMF_CODE.fd"
    "/usr/share/edk2/ovmf/OVMF_CODE.fd"
    "/usr/share/qemu/OVMF.fd"
    "/usr/share/edk2-ovmf/x64/OVMF_CODE.fd"
)

for path in "${OVMF_PATHS[@]}"; do
    if [ -f "$path" ]; then
        OVMF_CODE="$path"
        break
    fi
done

if [ -z "$OVMF_CODE" ]; then
    echo "[ERROR] OVMF not found. Install UEFI firmware:"
    echo "  Ubuntu/Debian: sudo apt install ovmf"
    echo "  Fedora: sudo dnf install edk2-ovmf"
    echo "  Arch: sudo pacman -S edk2-ovmf"
    exit 1
fi

echo "[INFO] Using OVMF: $OVMF_CODE"

# Create ESP (EFI System Partition) directory structure
ESP_DIR="$PROJECT_DIR/zig-out/esp"
mkdir -p "$ESP_DIR/EFI/BOOT"
cp "$PROJECT_DIR/zig-out/efi/boot/bootx64.efi" "$ESP_DIR/EFI/BOOT/BOOTX64.EFI"

echo "[INFO] ESP directory: $ESP_DIR"
echo "[INFO] Bootloader: $ESP_DIR/EFI/BOOT/BOOTX64.EFI"

# Run QEMU
echo "[RUN] Starting QEMU x86_64 with UEFI..."
echo "      Press Ctrl+A, X to exit QEMU"
echo ""

qemu-system-x86_64 \
    -machine q35 \
    -cpu qemu64 \
    -m 256M \
    -bios "$OVMF_CODE" \
    -drive format=raw,file=fat:rw:"$ESP_DIR" \
    -serial stdio \
    -display none \
    -no-reboot \
    -no-shutdown

echo ""
echo "[DONE] QEMU exited."
