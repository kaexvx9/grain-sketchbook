#!/bin/bash
# Create bootable ISO for Vantage VM with Limine
# Why: Test Vantage VM (RISC-V emulator for Basin) in QEMU and on real hardware.
# Usage: ./scripts/create_iso.sh
#
# Architecture:
#   Vantage VM boots on x86_64 via Limine
#   Vantage loads Basin kernel (RISC-V ELF) from module
#   Vantage emulates RISC-V64 to run Basin

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
ISO_ROOT="$PROJECT_DIR/iso_root"
LIMINE_DIR="$PROJECT_DIR/limine"

echo "[BUILD] Building Vantage VM for x86_64..."
cd "$PROJECT_DIR"
zig build vantage-x86_64

echo "[LIMINE] Checking for Limine..."
if [ ! -d "$LIMINE_DIR" ]; then
    echo "[LIMINE] Cloning Limine v10.x binary release..."
    git clone https://codeberg.org/Limine/Limine.git "$LIMINE_DIR" --branch=v10.x-binary --depth=1
    echo "[LIMINE] Building Limine utility..."
    make -C "$LIMINE_DIR"
fi

echo "[ISO] Creating ISO root directory..."
rm -rf "$ISO_ROOT"
mkdir -p "$ISO_ROOT/boot/limine"
mkdir -p "$ISO_ROOT/EFI/BOOT"

echo "[ISO] Copying Vantage VM..."
cp "$PROJECT_DIR/zig-out/bin/vantage" "$ISO_ROOT/boot/"

# TODO: Also copy Basin kernel (RISC-V) as module
# echo "[ISO] Copying Basin kernel (RISC-V)..."
# cp "$PROJECT_DIR/zig-out/bin/grain-rv64" "$ISO_ROOT/boot/basin-rv64"

echo "[ISO] Copying Limine configuration..."
cp "$PROJECT_DIR/limine.conf" "$ISO_ROOT/boot/limine/"

echo "[ISO] Copying Limine files..."
cp "$LIMINE_DIR/limine-bios.sys" "$ISO_ROOT/boot/limine/"
cp "$LIMINE_DIR/limine-bios-cd.bin" "$ISO_ROOT/boot/limine/"
cp "$LIMINE_DIR/limine-uefi-cd.bin" "$ISO_ROOT/boot/limine/"
cp "$LIMINE_DIR/BOOTX64.EFI" "$ISO_ROOT/EFI/BOOT/"
cp "$LIMINE_DIR/BOOTIA32.EFI" "$ISO_ROOT/EFI/BOOT/"

echo "[ISO] Creating bootable ISO..."
xorriso -as mkisofs -R -r -J \
    -b boot/limine/limine-bios-cd.bin \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -hfsplus -apm-block-size 2048 \
    --efi-boot boot/limine/limine-uefi-cd.bin \
    -efi-boot-part --efi-boot-image --protective-msdos-label \
    "$ISO_ROOT" -o "$PROJECT_DIR/vantage.iso"

echo "[ISO] Installing Limine BIOS stages..."
"$LIMINE_DIR/limine" bios-install "$PROJECT_DIR/vantage.iso"

echo ""
echo "[DONE] Created: $PROJECT_DIR/vantage.iso"
echo ""
echo "Vantage VM boots on x86_64 and emulates RISC-V64 to run Basin kernel."
echo ""
echo "To test in QEMU (UEFI):"
echo "  qemu-system-x86_64 -bios /usr/share/ovmf/OVMF.fd -cdrom vantage.iso -serial stdio"
echo ""
echo "To test in QEMU (BIOS):"
echo "  qemu-system-x86_64 -cdrom vantage.iso -serial stdio"
echo ""
