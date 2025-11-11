#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
KERNEL="$ROOT/zig-out/bin/grain-rv64"

if [ ! -f "$KERNEL" ]; then
  echo "Kernel image not found at $KERNEL" >&2
  echo "Run 'zig build kernel-rv64' first." >&2
  exit 1
fi

qemu-system-riscv64 \
  -machine virt \
  -cpu rv64 \
  -m 512M \
  -nographic \
  -bios default \
  -kernel "$KERNEL" \
  -serial mon:stdio \
  -monitor telnet:127.0.0.1:5555,server,nowait
